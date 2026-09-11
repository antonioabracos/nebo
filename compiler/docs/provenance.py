"""Bounded, read-only provenance extraction; historical claims never grant APIs.

Record IDs identify evidence, not Nebo SymbolIds. Resolution is conservative:
only exact spellings may establish a candidate relation, and all conflicting
claims retain their own source spans and an explicit disposition.
"""
from __future__ import annotations
import csv, hashlib, io, json, os, re, stat
from pathlib import Path, PurePosixPath

MAX_BYTES = 16 * 1024 * 1024
MAX_ROWS = 250000
csv.field_size_limit(MAX_BYTES)
class ProvenanceError(ValueError): pass

def require(condition, message):
    if not condition: raise ProvenanceError(message)

def digest(data): return hashlib.sha256(data).hexdigest()
def canonical(value): return json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':'))
def identity(kind, *values): return kind + ':' + digest(canonical(values).encode())[:24]

def read(root, relative, limit=MAX_BYTES):
    """Open each component without following links; never traverse outside root."""
    parts = PurePosixPath(relative).parts
    require(parts and not relative.startswith('/') and all(p not in ('.', '..') for p in parts), 'INVALID_PATH')
    require(str(PurePosixPath(relative)) == relative, 'NONCANONICAL_PATH')
    fd = os.open(root, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    try:
        for part in parts[:-1]:
            child = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW, dir_fd=fd)
            os.close(fd); fd = child
        child = os.open(parts[-1], os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=fd)
        try:
            info = os.fstat(child)
            require(stat.S_ISREG(info.st_mode) and info.st_size <= limit, 'UNBOUNDED_OR_NONREGULAR_INPUT')
            with os.fdopen(child, 'rb', closefd=False) as stream: data = stream.read(limit + 1)
            require(len(data) == info.st_size and len(data) <= limit, 'INPUT_CHANGED_OR_OVERSIZED')
            return data
        finally: os.close(child)
    finally: os.close(fd)

def text_lines(data):
    try: return data.decode('utf-8').splitlines(keepends=True)
    except UnicodeError as error: raise ProvenanceError('INVALID_UTF8') from error

def reference(path, data, start=1, end=None):
    lines = text_lines(data)
    if end is None: end = len(lines)
    require(1 <= start <= end <= len(lines), 'INVALID_SOURCE_SPAN')
    return dict(path=path, source_sha256=digest(data), start_line=start, end_line=end,
                span_sha256=digest(''.join(lines[start-1:end]).encode()))

def tsv_records(data):
    """CSV logical records retain their exact physical line extent."""
    text_lines(data)
    reader = csv.reader(io.StringIO(data.decode(), newline=''), delimiter='\t', strict=True)
    try:
        header = next(reader)
        require(header and len(set(header)) == len(header) and all(header), 'INVALID_TSV_HEADER')
        previous = reader.line_num
        for index, values in enumerate(reader):
            require(index < MAX_ROWS, 'ROW_BUDGET')
            start = previous + 1; previous = reader.line_num
            require(len(values) == len(header), 'INVALID_TSV_WIDTH')
            yield start, previous, dict(zip(header, values))
    except (StopIteration, csv.Error) as error: raise ProvenanceError('INVALID_TSV') from error

def table(rows, fields=None):
    rows = list(rows)
    if fields is None:
        require(bool(rows), 'EMPTY_TABLE_WITHOUT_SCHEMA'); fields = list(rows[0])
    require(len(rows) <= MAX_ROWS, 'ROW_BUDGET')
    stream = io.StringIO(newline='')
    writer = csv.DictWriter(stream, fields, delimiter='\t', lineterminator='\n', extrasaction='raise')
    writer.writeheader(); writer.writerows(rows)
    return stream.getvalue().encode()

def markdown_cells(line):
    # Escaped pipes and pipes inside code spans are not cell separators.
    cells=[]; text=''; ticks=False; escaped=False
    for char in line.strip():
        if escaped: text += char; escaped=False; continue
        if char == '\\': text += char; escaped=True; continue
        if char == '`': ticks=not ticks; text+=char; continue
        if char == '|' and not ticks: cells.append(text.strip()); text=''
        else: text += char
    cells.append(text.strip())
    return cells[1:-1] if line.strip().startswith('|') and line.strip().endswith('|') else []

def extract(data):
    """Retain technical table records and headings without executing their text."""
    lines = text_lines(data); header=None; section=''
    for number, line in enumerate(lines, 1):
        if line.lstrip().startswith('#'):
            section=line.strip().lstrip('# ').strip(); header=None
        cells=markdown_cells(line)
        if cells:
            if all(re.fullmatch(r':?-{2,}:?', c.replace(' ','')) for c in cells): continue
            if header is None: header=cells; continue
            if len(cells) != len(header):
                # Preserve unusual historical tables; never silently drop a row.
                yield number, number, dict(section=section, columns=canonical(cells), schema_state='IRREGULAR_HISTORICAL_TABLE')
            else: yield number, number, dict(section=section, **{f'{i}:{k}':v for i,(k,v) in enumerate(zip(header,cells))})
        else: header=None

def prose_records(data):
    """Preserve historical objectives, decisions and limits outside tables."""
    lines=text_lines(data);start=None;block=[];section='';fenced=False
    for number,line in enumerate(lines,1):
        boundary=(not line.strip() or (line.startswith('#') and not fenced) or (line.lstrip().startswith('|') and not fenced))
        if boundary:
            if block:
                yield start,number-1,dict(section=section,text=''.join(block).strip(),record_kind='HISTORICAL_PROSE_OR_CODE_DATA')
                block=[];start=None
            if line.startswith('#') and not fenced:section=line.lstrip('# ').strip()
            continue
        if start is None:start=number
        block.append(line)
        if line.lstrip().startswith(('```','~~~')):fenced=not fenced
    if block:yield start,len(lines),dict(section=section,text=''.join(block).strip(),record_kind='HISTORICAL_PROSE_OR_CODE_DATA')

def spelling(value):
    """Ignore formatting whitespace only; never infer overload/receiver aliases."""
    return re.sub(r'\s+', '', value.strip().strip('`'))

def candidates(name, public):
    wanted = spelling(name)
    return sorted(row['identity'] for row in public if spelling(row['name']) == wanted)

def resolve(name, public, historical=True, native_c=False, migration=None):
    if native_c: return 'EXCLUDED', [], 'Historical C corpus is not a native Nebo authority'
    if migration:
        return 'SUPERSEDED', [], migration
    found=candidates(name, public) if name else []
    if len(found)>1: return 'UNRESOLVED', found, 'Multiple current identities share this spelling; no implicit merge'
    if found:
        row=next(r for r in public if r['identity']==found[0])
        if row.get('layer')=='INTERNAL_TOOLING': return 'INTERNAL', found, 'Current taxonomy explicitly identifies tooling'
        if row.get('layer')=='EXCLUDED': return 'EXCLUDED', found, 'Current taxonomy excludes the claim from language release'
        return 'CURRENT_CANDIDATE', found, 'Exact spelling links evidence only; current limits and identity remain authoritative'
    return 'UNRESOLVED', [], 'No exact current declaration; historical intent is not an implementation claim'

def reconcile(left, right, left_rank, right_rank):
    """Always return an explicit record for any divergent declaration."""
    if left == right: return dict(state='AGREES', winner='BOTH', reason='Identical declarations')
    if left_rank == right_rank:
        return dict(state='OPEN_CURRENT_CONFLICT', winner='NONE', reason='Equal trust requires explicit technical or human resolution')
    return dict(state='RESOLVED_PRECEDENCE', winner='LEFT' if left_rank<right_rank else 'RIGHT',
                reason='Current authority outranks historical claim; both original records retained')

def native_crosswalk(ast, record, interface, expected_symbol):
    """Join only matching native identities; modules and their exports differ."""
    require(ast['attachment']['symbolId'] == record['symbolId'] == expected_symbol, 'DOC_SYMBOL_MISMATCH')
    require(record['interface']['roundTrip']=='BYTE_IDENTICAL', 'DOC_INTERFACE_ROUNDTRIP')
    require(interface['materialModuleValue'] is not None, 'NI_MATERIAL_VALUE_MISSING')
    require(bool(interface['symbolIds']), 'NI_EXPORT_ID_MISSING')
    require(record['sourceSpan']==ast['span'], 'DOC_ATTACHMENT_SPAN_MISMATCH')
    return dict(module_symbol_id=f'0x{expected_symbol:016x}', export_symbol_ids=canonical(interface['symbolIds']),
                doc_content_hash=record['contentHash'], api_fingerprint=interface['apiFingerprint'],
                abi_fingerprint=interface['abiFingerprint'], relation='MODULE_DOC_AND_MATERIAL_EXPORTS',
                parser=record['owners']['parser'], semantic=record['owners']['semantic'],
                interface_owner=record['owners']['interface'])
