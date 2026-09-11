#!/usr/bin/env python3
"""Deterministic metadata-only renderer for Nebo public documentation."""
from __future__ import annotations
import argparse, html, json, os, re, tempfile, sys, hashlib, importlib.util, struct, subprocess, shutil, ctypes, fcntl
from pathlib import Path
sys.dont_write_bytecode = True
ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT))
from compiler.docs.provenance import read as bounded_read, tsv_records

REQUIRED = ("symbol_id", "canonical_identity", "title", "kind", "owner", "edition", "targets", "summary", "provenance", "examples", "tests")
PUBLIC_REQUIRED = (
    "document_id", "document_path", "canonical_identity", "title", "kind",
    "signature_or_grammar", "owner", "edition", "stability", "target", "summary",
    "ownership", "effects", "capabilities", "errors", "limits", "examples",
    "negative_examples", "migration", "provenance", "tests", "known_limitations",
    "canonical_document",
)
SID = re.compile(r"^0x[0-9a-f]{16}$")

def load_metadata(path: Path):
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list) or not raw:
        raise ValueError("metadata must be a non-empty array")
    seen_ids, seen_paths, rows = set(), set(), []
    for source in raw:
        if not isinstance(source, dict) or set(REQUIRED) - set(source):
            raise ValueError("missing canonical document field")
        row = {key: source[key] for key in REQUIRED}
        sid = row["symbol_id"]
        if not isinstance(sid, str) or not SID.fullmatch(sid):
            raise ValueError("invalid SymbolId")
        output = sid[2:]
        if sid in seen_ids or output in seen_paths:
            raise ValueError("duplicate identity or output path")
        if any(not isinstance(row[key], list) for key in ("targets", "provenance", "examples", "tests")):
            raise ValueError("invalid array field")
        if row["edition"] != "1.0" or not row["owner"]:
            raise ValueError("invalid edition or owner")
        seen_ids.add(sid); seen_paths.add(output); rows.append(row)
    return sorted(rows, key=lambda row: row["symbol_id"])

def render_one(row):
    sid, title, summary = row["symbol_id"], row["title"], row["summary"]
    # Keep the frozen G184 pilot renderer byte-for-byte compatible.  P04's
    # public renderer is additive and must not stale the predecessor corpus.
    markdown = f"# {title}\n\nSymbolId: `{sid}`\n\n{summary}\n\nOwner: `{row['owner']}`\nEdition: `1.0`\n"
    man = f".TH NEBO-{sid[2:].upper()} 1\n.SH NAME\n{title}\n.SH DESCRIPTION\n{summary}\n.SH OWNER\n{row['owner']}\n"
    machine = json.dumps(row, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n"
    search = {"id": sid, "title": html.escape(title), "summary": html.escape(summary), "kind": row["kind"], "edition": "1.0"}
    return markdown, man, machine, search

def expected(metadata):
    result, index = {}, []
    for row in metadata:
        output = row["symbol_id"][2:]
        md, man, machine, search = render_one(row)
        result[f"markdown/{output}.md"] = md
        result[f"man/{output}.1"] = man
        result[f"json/{output}.json"] = machine
        index.append(search)
    result["search-index.json"] = json.dumps(index, ensure_ascii=False, sort_keys=True, indent=2) + "\n"
    return result

def publish(metadata_path: Path, output: Path):
    rendered = expected(load_metadata(metadata_path))
    output.parent.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".doc-factory-", dir=output.parent))
    try:
        for rel, content in rendered.items():
            target = stage / rel; target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8", newline="\n")
        for rel in sorted(rendered):
            target = output / rel; target.parent.mkdir(parents=True, exist_ok=True)
            os.replace(stage / rel, target)
    finally:
        for path in sorted(stage.rglob("*"), reverse=True):
            if path.is_dir(): path.rmdir()
        stage.rmdir()
    return sorted(rendered)

def check(metadata_path: Path, output: Path):
    rendered = expected(load_metadata(metadata_path))
    actual = {p.relative_to(output).as_posix(): p.read_text(encoding="utf-8") for p in output.rglob("*") if p.is_file() and p.name != "PILOT-CORPUS-MANIFEST.json"}
    if actual != rendered:
        raise ValueError("generated corpus is stale")
    return sorted(rendered)

def load_public(path: Path):
    raw = json.loads(path.read_text(encoding="utf-8"))
    if not isinstance(raw, list) or not raw:
        raise ValueError("public metadata must be a non-empty array")
    seen_ids, seen_paths, rows = set(), set(), []
    for source in raw:
        if not isinstance(source, dict) or set(PUBLIC_REQUIRED) - set(source):
            raise ValueError("missing public document field")
        row = {key: source[key] for key in PUBLIC_REQUIRED}
        rel = Path(row["document_path"])
        if rel.is_absolute() or ".." in rel.parts or rel.suffix != ".md":
            raise ValueError("unsafe public document path")
        if row["document_id"] in seen_ids or row["document_path"] in seen_paths:
            raise ValueError("duplicate public document identity or path")
        if row["edition"] != "1.0" or not row["owner"]:
            raise ValueError("invalid public edition or owner")
        if any(not isinstance(row[key], list) for key in ("examples", "negative_examples", "provenance", "tests")):
            raise ValueError("invalid public list field")
        seen_ids.add(row["document_id"]); seen_paths.add(row["document_path"]); rows.append(row)
    return sorted(rows, key=lambda row: row["document_path"])

def render_public(row):
    lines = [
        f"# {row['title']}", "",
        f"Document identity: {row['document_id']}",
        f"Canonical identity: {row['canonical_identity']}",
        f"Kind: {row['kind']}",
        f"Edition: {row['edition']}",
        f"Stability: {row['stability']}",
        f"Target: {row['target']}",
        f"Owner: {row['owner']}",
        f"Canonical document: {row['canonical_document']}", "",
        "## Summary", "", row["summary"], "",
        "## Signature or grammar", "", row["signature_or_grammar"], "",
        "## Ownership and lifecycle", "", row["ownership"], "",
        "## Effects and capabilities", "", f"Effects: {row['effects']}", f"Capabilities: {row['capabilities']}", "",
        "## Errors and failure atomicity", "", row["errors"], "",
        "## Limits and resource behavior", "", row["limits"], "",
        "## Positive examples", "",
    ]
    lines.extend(f"- {item}" for item in row["examples"])
    lines.extend(["", "## Misuse and negative examples", ""])
    lines.extend(f"- {item}" for item in row["negative_examples"])
    lines.extend(["", "## Migration", "", row["migration"], "", "## Provenance", ""])
    lines.extend(f"- {item}" for item in row["provenance"])
    lines.extend(["", "## Tests and oracles", ""])
    lines.extend(f"- {item}" for item in row["tests"])
    lines.extend(["", "## Known limitations", "", row["known_limitations"], ""])
    return "\n".join(lines)

def expected_public(metadata):
    return {row["document_path"]: render_public(row) for row in metadata}

def publish_public(metadata_path: Path, output: Path):
    rendered = expected_public(load_public(metadata_path))
    output.mkdir(parents=True, exist_ok=True)
    stage = Path(tempfile.mkdtemp(prefix=".public-doc-factory-", dir=output))
    try:
        for rel, content in rendered.items():
            target = stage / rel; target.parent.mkdir(parents=True, exist_ok=True)
            target.write_text(content, encoding="utf-8", newline="\n")
        for rel in sorted(rendered):
            target = output / rel; target.parent.mkdir(parents=True, exist_ok=True)
            os.replace(stage / rel, target)
    finally:
        for path in sorted(stage.rglob("*"), reverse=True):
            if path.is_dir(): path.rmdir()
        stage.rmdir()
    return sorted(rendered)

def check_public(metadata_path: Path, output: Path):
    rendered = expected_public(load_public(metadata_path))
    for rel, expected_text in rendered.items():
        path = output / rel
        if not path.is_file() or path.read_text(encoding="utf-8") != expected_text:
            raise ValueError(f"public document is stale: {rel}")
    return sorted(rendered)

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("mode", choices=("render", "check", "render-public", "check-public"))
    parser.add_argument("metadata")
    parser.add_argument("output")
    args = parser.parse_args()
    modes = {"render": publish, "check": check, "render-public": publish_public, "check-public": check_public}
    paths = modes[args.mode](Path(args.metadata), Path(args.output))
    print(f"DOC_FACTORY={args.mode.upper()} FILES={len(paths)}")

# The canonical profile extends this factory. Legacy metadata renderers above
# remain import-compatible, but are not accepted as authenticated documents.
SCHEMA = 'nebo.public-document.v1'
KINDS = {'feature', 'type', 'module', 'function', 'method', 'operator', 'diagnostic', 'CLI', 'target'}
RELATIONS = {'type', 'member', 'module', 'error', 'example', 'migration'}
TARGET = 'x86_64-systemv-elf-linux'
MAX_DOCUMENTS = 256
MAX_INPUT = 16 * 1024 * 1024
MAX_CORPUS = 64 * 1024 * 1024
FIELDS = {'schema', 'symbol_id', 'kind', 'name', 'title', 'summary', 'signature',
          'signature_hash', 'content_hash', 'owner', 'edition', 'version', 'since',
          'stability', 'targets', 'availability', 'ownership', 'effects',
          'capabilities', 'errors', 'limits', 'provenance', 'examples', 'laws',
          'tests', 'relations', 'interface_sha256', 'identity_origin'}


class FactoryError(ValueError):
    def __init__(self, code, message):
        self.code = 'NEBO_DOC_' + code
        super().__init__(message)


def need(value, code, message):
    if not value:
        raise FactoryError(code, message)


def blob(value):
    return (json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(',', ':')) + '\n').encode()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def unique_object(pairs):
    result = {}
    for key, value in pairs:
        need(key not in result, 'SCHEMA', 'duplicate JSON key')
        result[key] = value
    return result


def parse_json(data):
    try:
        return json.loads(data, object_pairs_hook=unique_object)
    except (UnicodeError, json.JSONDecodeError, RecursionError) as error:
        raise FactoryError('SCHEMA', 'invalid bounded JSON') from error


def load_owner(name, relative):
    spec = importlib.util.spec_from_file_location(name, ROOT / relative)
    module = importlib.util.module_from_spec(spec)
    sys.modules[name] = module
    spec.loader.exec_module(module)
    return module


def authority_call(action, code):
    try:
        return action()
    except (SystemExit, Exception) as error:
        raise FactoryError(code, 'native authority rejected the bounded input') from error


def checked_ref(root, ref, limit=MAX_INPUT):
    need(isinstance(ref, dict) and set(ref) == {'path', 'sha256'}, 'SCHEMA', 'invalid file reference')
    need(isinstance(ref['path'], str) and isinstance(ref['sha256'], str)
         and re.fullmatch('[0-9a-f]{64}', ref['sha256']), 'SCHEMA', 'invalid provenance digest')
    try:
        data = bounded_read(root, ref['path'], limit)
    except (OSError, ValueError) as error:
        raise FactoryError('INPUT', 'unreadable, unsafe or unbounded input reference') from error
    need(digest(data) == ref['sha256'], 'STALE', 'source/provenance hash changed: ' + ref['path'])
    return data


def safe_directory(path):
    path = path.absolute()
    current = Path(path.anchor)
    for part in path.parts[1:]:
        current /= part
        need(current.is_dir() and not current.is_symlink(), 'INPUT', 'unsafe directory component')


def source_metadata(record_owner, example_owner, data, expected):
    # All compiler passes see the same immutable bytes, even if the caller swaps
    # a source path while generation is in flight. No filename selects a route.
    with tempfile.TemporaryDirectory(prefix='nebo-doc-input-') as raw:
        path = Path(raw)/'source.no'
        path.write_bytes(data)
        ast = authority_call(lambda: record_owner.canonical_ast(path), 'INPUT')
        binary, texts = authority_call(lambda: record_owner.build_record(ast, data), 'INPUT')
        record = record_owner.decode(binary, ast, texts)
        need(f"0x{record['symbolId']:016x}" == expected['symbol_id']
             and record['signatureHash'] == expected['signature_hash']
             and record['contentHash'] == expected['content_hash'], 'STALE', 'SymbolId, signature or documentation changed')
        verified = authority_call(lambda: example_owner.verify_source(path, data, 'docs --verify', 17, 2, 1000, 1024, {}, {}), 'EXAMPLE')
    return ast, binary, texts, record, verified


def validate_document(row):
    need(isinstance(row, dict) and set(row) == FIELDS, 'SCHEMA', 'document fields must match schema v1')
    need(row['schema'] == SCHEMA and row['kind'] in KINDS, 'SCHEMA', 'unsupported document schema or kind')
    need(isinstance(row['symbol_id'], str) and SID.fullmatch(row['symbol_id'])
         and int(row['symbol_id'], 16) != 0, 'IDENTITY', 'a real nonzero SymbolId is required')
    need(row['edition'] == 1 and not isinstance(row['edition'], bool), 'TARGET', 'only Edition 1 is material')
    need(isinstance(row['version'], str) and re.fullmatch(r'\d+\.\d+\.\d+', row['version']), 'SCHEMA', 'version must be explicit')
    need(row['targets'] == [TARGET], 'TARGET', 'unsupported target facet')
    need(row['stability'] in {'stable', 'deprecated', 'experimental'}, 'SCHEMA', 'invalid stability')
    need(row['identity_origin'] in {'NATIVE_DOCRECORD', 'SERIALIZED_REGISTRY'}, 'IDENTITY', 'untrusted SymbolId origin')
    for field in FIELDS - {'schema', 'edition', 'targets', 'provenance', 'examples', 'laws', 'tests', 'relations'}:
        value = row[field]
        need(isinstance(value, str) and value.strip() and 0 < len(value.encode()) <= 16384
             and not any(ord(c) < 32 and c not in '\n\t' for c in value), 'SCHEMA', 'invalid text field: ' + field)
    for field in ('provenance', 'examples', 'laws', 'tests', 'relations'):
        need(isinstance(row[field], list) and len(row[field]) <= 256, 'LIMIT', 'invalid bounded list: ' + field)
    need(row['provenance'] and row['tests'], 'SCHEMA', 'provenance and test linkage are mandatory')
    for ref in row['provenance'] + row['tests']:
        need(isinstance(ref, dict) and set(ref) == {'path', 'sha256'}, 'SCHEMA', 'invalid provenance/test link')
        need(isinstance(ref['path'], str) and ref['path'] and not Path(ref['path']).is_absolute()
             and '..' not in Path(ref['path']).parts and isinstance(ref['sha256'], str)
             and re.fullmatch('[0-9a-f]{64}',ref['sha256']), 'SCHEMA', 'invalid provenance path or hash')
    for link in row['relations']:
        need(isinstance(link, dict) and set(link) == {'kind', 'symbol_id'}
             and link['kind'] in RELATIONS and isinstance(link['symbol_id'], str)
             and SID.fullmatch(link['symbol_id']), 'LINK', 'invalid typed cross-link')
    for fixture in row['examples'] + row['laws']:
        need(isinstance(fixture, dict) and set(fixture) == {'name', 'source', 'sha256', 'expected_exit', 'cases'}, 'SCHEMA', 'invalid executable linkage')
        need(isinstance(fixture['name'], str) and fixture['name'].strip() and isinstance(fixture['sha256'], str), 'SCHEMA', 'invalid fixture name or digest')
        need(isinstance(fixture['source'], str) and digest(fixture['source'].encode()) == fixture['sha256'], 'STALE', 'example snippet mismatch')
        need(type(fixture['expected_exit']) is int and 0 <= fixture['expected_exit'] <= 255
             and type(fixture['cases']) is int and 1 <= fixture['cases'] <= 64, 'SCHEMA', 'invalid example oracle')
    return row


def extract(root, manifest):
    """Join native identities and pinned evidence; never parse Nebo source here."""
    safe_directory(root)
    need(isinstance(manifest, dict) and set(manifest) == {'schema', 'edition', 'version', 'target', 'authorities', 'documents'}, 'SCHEMA', 'invalid factory manifest')
    need(manifest['schema'] == 1 and type(manifest['schema']) is int, 'SCHEMA', 'unsupported input schema')
    need(manifest['edition'] == 1 and type(manifest['edition']) is int and manifest['target'] == TARGET, 'TARGET', 'unsupported edition or target')
    entries = manifest['documents']
    need(isinstance(entries, list) and 1 <= len(entries) <= MAX_DOCUMENTS, 'LIMIT', 'document count must be 1..256')
    need(isinstance(manifest['authorities'], list) and 1 <= len(manifest['authorities']) <= 16, 'LIMIT', 'bounded authority references required')
    authorities = manifest['authorities']
    # Reject contradictory pins and bound the total unique input bytes up front.
    pins = {}
    references = list(authorities)
    for item in entries:
        need(isinstance(item, dict), 'SCHEMA', 'document selector must be an object')
        for key in ('source', 'registry', 'interface'):
            if key in item:
                references.append(item[key])
        need(isinstance(item.get('tests'), list), 'SCHEMA', 'test list required')
        references.extend(item['tests'])
    input_size = 0
    for ref in references:
        data = checked_ref(root, ref)
        path = ref['path']
        need(path not in pins or pins[path] == ref['sha256'], 'STALE', 'contradictory input hashes')
        if path not in pins:
            input_size += len(data)
        pins[path] = ref['sha256']
        need(input_size <= MAX_CORPUS, 'LIMIT', 'aggregate input budget exceeded')
    for ref in authorities:
        checked_ref(root, ref)
    record_owner = load_owner('nebo_factory_record', 'tools/rf204-g156.py')
    example_owner = load_owner('nebo_factory_examples', 'tools/rf204-g158.py')
    docs_owner = load_owner('nebo_factory_graph', 'tools/rf204-g159.py')
    rows = []
    all_refs = list(authorities)
    for item in entries:
        need(isinstance(item, dict) and set(item) <= {'source', 'registry', 'registry_identity', 'symbol_id', 'signature_hash', 'content_hash', 'kind', 'tests', 'relations', 'interface'}
             and {'symbol_id', 'signature_hash', 'content_hash', 'tests', 'relations'} <= set(item), 'SCHEMA', 'invalid document selector')
        need(('source' in item) != ('registry' in item), 'SCHEMA', 'exactly one metadata authority required')
        need(isinstance(item['tests'], list) and 1 <= len(item['tests']) <= 16, 'LIMIT', 'test references required')
        refs = list(authorities) + item['tests']
        for ref in item['tests']:
            checked_ref(root, ref)
        snippets = {'example': [], 'law': []}
        if 'source' in item:
            data = checked_ref(root, item['source'], record_owner.MAX_SOURCE_BYTES)
            ast, binary, texts, record, verified = source_metadata(record_owner, example_owner, data, item)
            interface = record_owner.native('--serialize', binary, record_owner.INTERFACE_BYTES)
            need(record_owner.native('--deserialize', interface, record_owner.RECORD_BYTES) == binary, 'INTERFACE', 'native interface round-trip mismatch')
            if 'interface' in item:
                supplied = checked_ref(root, item['interface'], record_owner.INTERFACE_BYTES)
                need(authority_call(lambda: record_owner.native('--deserialize', supplied, record_owner.RECORD_BYTES), 'INTERFACE') == binary
                     and supplied == interface, 'INTERFACE', 'interface and source DocRecord diverged')
                refs.append(item['interface'])
            symbol = f"0x{record['symbolId']:016x}"
            need(symbol == item['symbol_id'] and record['signatureHash'] == item['signature_hash']
                 and record['contentHash'] == item['content_hash'], 'STALE', 'SymbolId, signature or documentation changed')
            embedded = sorted(ast['embeddedCode'], key=lambda v: v['kind'])
            need(len(embedded) == len(verified['fixtures']), 'EXAMPLE', 'missing executable fixture')
            for node, evidence in zip(embedded, verified['fixtures']):
                start, size = node['span']; snippet = data[start:start + size]
                need(digest(snippet) == evidence['snippetSha256'], 'EXAMPLE', 'executed snippet mismatch')
                snippets[node['kind']].append(dict(name=node['name'], source=snippet.decode(), sha256=digest(snippet), expected_exit=evidence['expectedExit'], cases=evidence['cases']))
            kind = {'struct': 'type', 'enum': 'type', 'behavior': 'type'}.get(ast['attachment']['kind'], ast['attachment']['kind'])
            need('kind' not in item or item['kind'] == kind, 'IDENTITY', 'source attachment kind cannot be relabelled')
            row = dict(symbol_id=symbol, kind=kind, name=ast['attachment']['name'],
                       title=texts.get('title', ''), summary=texts.get('summary', ''),
                       signature=json.dumps({k: texts[k] for k in sorted(record_owner.SIGNATURE_FIELDS) if k in texts}, sort_keys=True),
                       signature_hash=record['signatureHash'], content_hash=record['contentHash'],
                       owner=record['owners']['semantic'], since=texts.get('since', 'Edition 1'),
                       stability='stable' if texts.get('deprecated', 'never') == 'never' else 'deprecated',
                       availability='BOUNDED_PUBLIC', interface_sha256=digest(interface), identity_origin='NATIVE_DOCRECORD')
            for field in ('ownership', 'effects', 'capabilities', 'errors'):
                row[field] = texts.get(field, 'not declared; no additional grant')
            row['limits'] = 'DocRecordV1: 16384 source bytes; 4 parameters; 3832 text bytes; examples 1000ms/1024 bytes; laws 2 cases, not universal proofs'
            refs.append(item['source'])
        else:
            need('interface' not in item and item.get('kind') in KINDS, 'SCHEMA', 'registry kind required')
            records = [v for _, _, v in tsv_records(checked_ref(root, item['registry']))
                       if v.get('symbol_id') == item['symbol_id'] and v.get('canonical_identity') == item.get('registry_identity')]
            need(len(records) == 1, 'IDENTITY', 'registry must resolve one serialized SymbolId')
            v = records[0]
            need(v.get('identity_kind') == 'SERIALIZED_SYMBOL_ID' and v.get('target') == TARGET, 'IDENTITY', 'registry identity is not a serialized target symbol')
            need(v.get('api_fingerprint') == item['signature_hash'] and digest(blob(v)) == item['content_hash'], 'STALE', 'registry signature or content changed')
            declaration = parse_json(v['declaration'])
            from compiler.sdk.prelude import PreludeInterface, PreludeProfile, Prelude, PRELUDE_PATH, REGISTRY_PATH
            prelude = PreludeInterface.load(PreludeProfile.forEdition('1'), TARGET)
            actual = [s for s in Prelude.symbols(prelude) if s['symbolId'] == v['symbol_id']]
            need(len(actual) == 1 and actual[0]['name'] == v['name'] and actual[0]['origin'] == v['module']
                 and actual[0]['kind'] == item['kind'],
                 'IDENTITY', 'registry and current prelude interface identity diverged')
            for path in (PRELUDE_PATH, REGISTRY_PATH):
                rel = path.relative_to(ROOT).as_posix()
                ref = dict(path=rel, sha256=digest(path.read_bytes()))
                checked_ref(root, ref); refs.append(ref)
            row = dict(symbol_id=v['symbol_id'], kind=item['kind'], name=v['name'], title=v['name'],
                       summary=declaration.get('limits', v['declaration']), signature=v['declaration'],
                       signature_hash=v['api_fingerprint'], content_hash=item['content_hash'], owner=v['origin'],
                       since='Edition 1', stability='stable' if v['maturity'] == 'STABLE_1_0' else 'experimental',
                       availability=declaration.get('classification', v['maturity']), interface_sha256='NOT_A_DOCRECORD_SECTION', identity_origin='SERIALIZED_REGISTRY',
                       ownership='As declared in the cited registry', effects='No grant from documentation', capabilities='No grant from documentation',
                       errors='As declared in the cited registry', limits=declaration.get('limits', 'Registry evidence only; no execution claim'))
            refs.append(item['registry'])
        row.update(schema=SCHEMA, edition=manifest['edition'], version=manifest['version'], targets=[TARGET],
                   provenance=sorted({r['path']: r for r in refs}.values(), key=lambda r: r['path']),
                   tests=sorted(item['tests'], key=lambda r: r['path']), examples=snippets['example'], laws=snippets['law'],
                   relations=sorted(item['relations'], key=lambda v: (v['kind'], v['symbol_id'])))
        validate_document(row); rows.append(row); all_refs.extend(refs)
    rows.sort(key=lambda row: row['symbol_id'])
    known = {row['symbol_id'] for row in rows}
    need(len(known) == len(rows), 'IDENTITY', 'duplicate document owner or overload identity')
    for row in rows:
        need(all(link['symbol_id'] in known for link in row['relations']), 'LINK', 'unresolved typed SymbolId link')
    # Native graph/link/target gates consume measured facts, not caller claims.
    graph = dict(graphDigestFNV=f"0x{docs_owner.fnv(blob(rows)):016x}", symbols=rows,
                 modules=sorted({r['owner'] for r in rows}), publicSymbols=len(rows), privateSymbols=0)
    links = sum(len(r['relations']) for r in rows)
    docs_owner.native(docs_owner.request(docs_owner.OP_GRAPH, graph, flags=docs_owner.FLAG_PUBLIC_ONLY | docs_owner.FLAG_PATHS_REDACTED), 'NEBO_DOC_GRAPH')
    docs_owner.native(docs_owner.request(docs_owner.OP_LINKS, graph, flags=docs_owner.FLAG_PATHS_REDACTED, links=links, resolved=links), 'NEBO_DOC_LINK')
    for ref in all_refs:
        checked_ref(root, ref)
    need(len(blob(rows)) <= MAX_CORPUS, 'LIMIT', 'corpus byte budget exceeded')
    return rows


def markdown_text(value):
    # Escape HTML and all Markdown syntax, including image/link destinations.
    # Presentation whitespace is normalized; canonical JSON retains native bytes.
    value = '\n'.join(line.rstrip() for line in value.split('\n')).strip()
    return ''.join('\\' + c if c in '\\`*_{}[]()#+-.!|>' else c for c in html.escape(value, quote=True))


def roff_text(value):
    return '\n'.join('\\&' + line.rstrip().replace('\\', '\\e') for line in value.split('\n'))


def canonical_files(rows):
    need(isinstance(rows, list) and 1 <= len(rows) <= MAX_DOCUMENTS, 'LIMIT', 'document count must be 1..256')
    need(len({r['symbol_id'] for r in rows}) == len(rows), 'IDENTITY', 'duplicate canonical owner')
    need(all(v['symbol_id'] in {r['symbol_id'] for r in rows} for r in rows for v in r['relations']), 'LINK', 'unresolved rendered SymbolId')
    rows = sorted(rows, key=lambda r: r['symbol_id'])
    files = {}; search = []; owners = []
    for row in rows:
        validate_document(row)
        stem = row['symbol_id'][2:]
        md = f"# {markdown_text(row['title'])}\n\n"
        for field in sorted(FIELDS - {'schema', 'title'}):
            value = row[field] if isinstance(row[field], str) else json.dumps(row[field], ensure_ascii=False, sort_keys=True)
            md += f"## {field}\n\n{markdown_text(value)}\n\n"
        if row['relations']:
            md += '## Resolved links\n\n'
            md += ''.join(f"- [{link['kind']} {link['symbol_id']}]({link['symbol_id'][2:]}.md)\n" for link in row['relations'])
        for kind in ('examples', 'laws'):
            for fixture in row[kind]:
                # The code fence grows if a snippet contains backticks.
                fence = '`' * max(3, max((len(v) + 1 for v in re.findall(r'`+', fixture['source'])), default=3))
                # Only surrounding fixture whitespace is omitted from display;
                # interior code and the canonical snippet/hash remain unchanged.
                md += f"\n{fence}nebo\n{fixture['source'].strip()}\n{fence}\n"
        md = md.rstrip() + '\n'
        man = f'.TH NEBO-{stem.upper()} 1 "" "Nebo {row["version"]}"\n'
        for key in ('title', 'summary', 'signature', 'owner', 'edition', 'targets', 'availability', 'ownership', 'effects', 'capabilities', 'errors', 'limits', 'provenance', 'tests'):
            value = row[key] if isinstance(row[key], str) else json.dumps(row[key], ensure_ascii=False, sort_keys=True)
            man += '.SH ' + key.upper() + '\n' + roff_text(value) + '\n'
        for name, data in ((f'markdown/{stem}.md', md.encode()), (f'man/{stem}.1', man.encode()), (f'json/{stem}.json', blob(row))):
            need(name.casefold() not in {v.casefold() for v in files}, 'IDENTITY', 'document path collision')
            files[name] = data
        search.append(dict(symbol_id=row['symbol_id'], title=html.escape(row['title']), summary=html.escape(row['summary']),
                           path=f'markdown/{stem}.md', tokens=sorted(set(re.findall(r'\w+', (row['name']+' '+row['title']+' '+row['summary']).casefold())))))
        owners.append(dict(symbol_id=row['symbol_id'], edition=row['edition'], owner=row['owner'], path=f'json/{stem}.json'))
    files['search-index.json'] = blob(search)
    files['owners.json'] = blob(owners)
    files['manifest.json'] = blob(dict(schema=SCHEMA, documents=len(rows), files={k: digest(v) for k, v in sorted(files.items())}))
    need(sum(map(len, files.values())) <= MAX_CORPUS, 'LIMIT', 'rendered byte budget exceeded')
    return files


def actual_files(output, *, max_documents=MAX_DOCUMENTS):
    need(type(max_documents) is int and 1 <= max_documents <= 4096, 'LIMIT', 'reader document budget')
    need(output.is_dir() and not output.is_symlink(), 'OUTPUT', 'corpus must be a real directory')
    files = {}; total = 0
    for base, dirs, names in os.walk(output, followlinks=False):
        need(not any((Path(base)/d).is_symlink() for d in dirs), 'OUTPUT', 'output directory symlink')
        for name in names:
            rel = (Path(base)/name).relative_to(output).as_posix()
            data = bounded_read(output, rel, MAX_CORPUS)
            total += len(data)
            need(total <= MAX_CORPUS and len(files) < max_documents*3+3, 'LIMIT', 'output budget')
            files[rel] = data
    return files


def compare_files(expected_files, observed):
    return dict(added=sorted(set(expected_files)-set(observed)), removed=sorted(set(observed)-set(expected_files)),
                changed=sorted(k for k in set(observed)&set(expected_files) if observed[k] != expected_files[k]))


def stage_file(path, data):
    with path.open('xb') as out:
        out.write(data); out.flush(); os.fsync(out.fileno())


def atomic_corpus(output, files, *, prior_files=None, max_documents=MAX_DOCUMENTS):
    """One renameat2 commit point; an I/O failure cannot publish half a corpus."""
    output = output.absolute()
    need(output.name not in {'', '.', '..'}, 'OUTPUT', 'invalid output root')
    current = Path(output.anchor)
    for part in output.parent.parts[1:]:
        current /= part
        need(current.is_dir() and not current.is_symlink(), 'OUTPUT', 'unsafe output parent')
    parent_fd = os.open(output.parent, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    temporary = None
    try:
        fcntl.flock(parent_fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        exists = output.exists() or output.is_symlink()
        if exists:
            old = actual_files(output, max_documents=max_documents)
            if prior_files is not None:
                # Explicit migration of a previously authenticated generated tree.
                # The public CLI never opts into this library-only operation.
                need(old == prior_files, 'OUTPUT', 'prior generated tree changed')
            else:
                need('manifest.json' in old, 'OUTPUT', 'refusing an unowned corpus')
                manifest = parse_json(old['manifest.json'])
                need(isinstance(manifest, dict) and manifest.get('schema') == SCHEMA
                     and isinstance(manifest.get('files'), dict)
                     and set(manifest['files']) == set(old)-{'manifest.json'}, 'OUTPUT', 'unowned or extra output files')
        temporary = Path(tempfile.mkdtemp(prefix='.nebo-doc-stage-', dir=output.parent))
        for name, data in sorted(files.items()):
            target = temporary/name; target.parent.mkdir(parents=True, exist_ok=True)
            stage_file(target, data)
        rename = getattr(ctypes.CDLL(None, use_errno=True), 'renameat2', None)
        need(rename is not None, 'OUTPUT', 'atomic directory exchange is unavailable')
        rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
        rename.restype = ctypes.c_int
        status = rename(parent_fd, temporary.name.encode(), parent_fd, output.name.encode(), 2 if exists else 1)
        need(status == 0, 'OUTPUT', 'atomic directory publication failed')
        # After the commit point cleanup is best effort; no false failure verdict.
        try: os.fsync(parent_fd)
        except OSError: pass
    finally:
        if temporary is not None and temporary.exists():
            shutil.rmtree(temporary, ignore_errors=True)
        os.close(parent_fd)


def reference_files(root, documents, *, title='Individual core reference',
                    profile='nebo.core-reference.v1', max_documents=MAX_DOCUMENTS-1):
    """Render a bounded reference corpus with explicit non-SymbolId identities.

    Grammar productions, intrinsic Registry entries and diagnostic codes are
    not serialized declarations. Callers join their current authorities and
    executed oracles before rendering; this function validates and pins those
    inputs and never manufactures a DocRecord or claims a runtime observation.
    The existing native DocRecord profile and its bytes are unchanged.
    """
    need(type(max_documents) is int and 1 <= max_documents <= 1024, 'LIMIT', 'reference document budget')
    need(isinstance(title,str) and 0 < len(title) <= 256 and '\n' not in title,
         'SCHEMA', 'reference title')
    need(profile in {'nebo.core-reference.v1','nebo.stdlib-reference.v1','nebo.domain-reference.v1'}, 'SCHEMA', 'reference profile')
    need(isinstance(documents, list) and 0 < len(documents) <= max_documents,
         'LIMIT', 'reference corpus document count')
    fields = {'identity', 'identity_kind', 'symbol_ids', 'name', 'title', 'kind',
              'subgroup', 'slug', 'summary', 'signature', 'sections', 'provenance',
              'examples', 'negative_examples', 'observations', 'test_ids', 'links',
              'availability', 'target', 'edition'}
    identities = {r.get('identity') for r in documents}
    slugs = {r.get('slug') for r in documents}
    need(len(identities) == len(slugs) == len(documents), 'IDENTITY', 'duplicate reference owner')
    result, search = {}, []
    for row in sorted(documents, key=lambda r: r['identity']):
        need(set(row) == fields, 'SCHEMA', 'reference fields differ')
        need(row['identity_kind'] in {'GRAMMAR_PRODUCTION', 'REGISTRY_ID', 'INTRINSIC_TYPE',
             'NORMATIVE_RULE', 'SERIALIZED_SYMBOL_ID', 'DIAGNOSTIC_CODE', 'CLI_FORM',
             'QUALIFIED_INTRINSIC_OR_REGISTRY_ID', 'MODULE_IDENTITY', 'DOMAIN_CONTRACT_ID'},
             'IDENTITY', 'unknown identity namespace')
        need(bool(row['symbol_ids']) == (row['identity_kind'] == 'SERIALIZED_SYMBOL_ID') and
             all(SID.fullmatch(s) for s in row['symbol_ids']), 'IDENTITY', 'counterfeit serialized identity')
        need(isinstance(row['slug'], str) and re.fullmatch(r'[A-Za-z0-9_-]{1,160}', row['slug']),
             'PATH', 'unsafe reference slug')
        targets = {TARGET, 'PYTHON_CPU_REFERENCE', 'UNDECLARED'} if profile == 'nebo.domain-reference.v1' else {TARGET}
        need(row['target'] in targets and row['edition'] == '1', 'SCHEMA', 'reference profile')
        need(row['identity_kind'] != 'DOMAIN_CONTRACT_ID' or profile == 'nebo.domain-reference.v1',
             'IDENTITY', 'domain contract requires the domain reference profile')
        for key in ('identity','name','title','summary','signature','availability'):
            need(isinstance(row[key], str) and 0 < len(row[key].encode()) <= 16384,
                 'SCHEMA', 'empty or oversized reference field '+key)
        need(all('\n' not in row[key] and '\r' not in row[key] for key in ('identity','name','title','availability')),
             'SCHEMA', 'multiline reference identity or heading')
        need(row['provenance'] and row['test_ids'] and row['sections'], 'SCHEMA', 'missing reference evidence')
        need(len(row['provenance']) <= 32 and len(row['test_ids']) <= 8192, 'LIMIT', 'reference evidence budget')
        for ref in row['provenance']: checked_ref(root, ref)
        need(all(isinstance(s, dict) and set(s) == {'heading','text'} and s['heading'] and s['text'] for s in row['sections']),
             'SCHEMA', 'reference section')
        need(len(row['sections']) <= 16 and all(isinstance(s[k],str) and len(s[k].encode()) <= 16384
             for s in row['sections'] for k in ('heading','text')), 'LIMIT', 'reference section bounds')
        need(all('\n' not in s['heading'] and '\r' not in s['heading'] for s in row['sections']),
             'SCHEMA', 'multiline reference section heading')
        need(len(blob(row['observations'])) <= MAX_INPUT, 'LIMIT', 'reference observation bounds')
        need(all(link in slugs for link in row['links']), 'LINK', 'unknown reference relation')
        for negative, examples in ((False,row['examples']), (True,row['negative_examples'])):
            need(isinstance(examples,list) and len(examples) <= 8, 'LIMIT', 'reference examples')
            for example in examples:
                need(set(example) == {'case_id','source','source_sha256','expected','oracle','units'},
                     'SCHEMA', 'reference example fields')
                need(example['case_id'] in row['test_ids'] and example['source_sha256'] == digest(example['source'].encode()),
                     'STALE', 'reference example source or proof changed')
                need(0 < len(example['source'].encode()) <= 16384, 'LIMIT', 'reference example source bounds')
                need((isinstance(example['expected'],str) and example['expected'].startswith('NEBO')) if negative else
                     (type(example['expected']) is int and 0 <= example['expected'] <= 255),
                     'SCHEMA', 'reference example expected result')
                need(isinstance(example['oracle'],dict) and isinstance(example['units'],list), 'SCHEMA', 'example context')
                for unit in example['units']:
                    need(isinstance(unit,dict) and set(unit) in ({'name','source'},{'name','bytes_hex'}) and
                         re.fullmatch(r'[A-Za-z0-9_-]+\.(no|ni)',unit.get('name','')), 'SCHEMA', 'provider context')
                    if 'bytes_hex' in unit:
                        need(unit['name'].endswith('.ni') and len(unit['bytes_hex'])<=32768 and
                             re.fullmatch(r'(?:[0-9a-f]{2})+',unit['bytes_hex']), 'SCHEMA', 'material interface bytes')
                    else:need(unit['name'].endswith('.no') and isinstance(unit['source'],str), 'SCHEMA', 'provider source')
        need(row['examples'] or row['negative_examples'] or row['observations'], 'SCHEMA', 'unproved reference')
        slug=row['slug']; esc=lambda v: html.escape(str(v), quote=True)
        # HTML is escaped separately; Markdown code fences exceed any run in
        # source, so a doc payload cannot terminate a fence and inject markup.
        def fence(text, language='text'):
            marker='`'*max(3, 1+max((len(x) for x in re.findall(r'`+', text)), default=0))
            return marker+language+'\n'+text+'\n'+marker+'\n'
        def mdtext(text):
            return html.escape(str(text), quote=False).replace('[','\\[').replace(']','\\]').replace('`','\\`')
        md='# '+mdtext(row['title'])+'\n\n'+mdtext(row['summary'])+'\n\n'
        body='<h1>'+esc(row['title'])+'</h1><p>'+esc(row['summary'])+'</p>'
        facts=f"Identity: {row['identity']} ({row['identity_kind']})\nEdition: 1\nTarget: {row['target']}\nAvailability: {row['availability']}"
        if row['symbol_ids']: facts+='\nSerialized SymbolId: '+', '.join(row['symbol_ids'])
        md+=fence(facts)+'\n## Syntax or signature\n\n'+fence(row['signature'])
        body+='<pre>'+esc(facts)+'</pre><h2>Syntax or signature</h2><pre>'+esc(row['signature'])+'</pre>'
        for section in row['sections']:
            md+='\n## '+mdtext(section['heading'])+'\n\n'+mdtext(section['text'])+'\n'
            body+='<h2>'+esc(section['heading'])+'</h2><p>'+esc(section['text'])+'</p>'
        for heading, examples in [('Executed examples',row['examples']),('Rejected examples',row['negative_examples'])]:
            if not examples: continue
            md+='\n## '+heading+'\n';body+='<h2>'+heading+'</h2>'
            for example in examples:
                label=example['case_id']+'; expected '+str(example['expected'])
                md+='\n### '+mdtext(label)+'\n\n'+fence(example['source'],'nebo')
                body+='<h3>'+esc(label)+'</h3><pre><code>'+esc(example['source'])+'</code></pre>'
                details=json.dumps(example['oracle'],ensure_ascii=False,sort_keys=True)
                md+='\nOracle: '+mdtext(details)+'\n';body+='<p>Oracle: '+esc(details)+'</p>'
                for unit in example['units']:
                    if 'source' in unit:
                        content=unit['source'];language='nebo';label='Provider '+unit['name']
                    else:
                        content="from pathlib import Path\nPath("+repr(unit['name'])+").write_bytes(bytes.fromhex("+repr(unit['bytes_hex'])+"))"
                        language='python';label='Material interface '+unit['name']+' (write these exact bytes beside the consumer)'
                    md+='\n'+mdtext(label)+'\n\n'+fence(content,language)
                    body+='<h4>'+esc(label)+'</h4><pre><code>'+esc(content)+'</code></pre>'
        if row['observations']:
            evidence=json.dumps(row['observations'],ensure_ascii=False,sort_keys=True,indent=2)
            md+='\n## Additional observations and limits\n\n'+fence(evidence)
            body+='<h2>Additional observations and limits</h2><pre>'+esc(evidence)+'</pre>'
        md+='\n## Related entries\n\n[Index](index.md)\n'
        body+='<nav aria-label="Related entries"><a href="index.html">Index</a>'
        for link in row['links']:
            md+='\n- ['+link+']('+link+'.md)\n'
            body+=' <a href="'+link+'.html">'+esc(link)+'</a>'
        body+='</nav><h2>Provenance</h2><ul>';md+='\n## Provenance\n'
        for ref in row['provenance']:
            # Public references can be moved only with their declared repo path.
            md+='\n- '+mdtext(ref['path'])+' — SHA-256 '+ref['sha256']+'\n'
            body+='<li>'+esc(ref['path'])+' — SHA-256 '+ref['sha256']+'</li>'
        body+='</ul>'
        result[slug+'.md']=md.encode()
        result[slug+'.json']=blob(row)
        result[slug+'.html']=('<!doctype html><html lang="en"><head><meta charset="utf-8">'
            '<meta name="viewport" content="width=device-width,initial-scale=1"><title>'+esc(row['title'])+
            '</title></head><body><a href="#main">Skip to content</a><main id="main">'+body+'</main></body></html>\n').encode()
        search.append(dict(identity=row['identity'],name=row['name'],title=row['title'],path=slug+'.html',
                           markdown=slug+'.md',availability=row['availability']))
    result['search-index.json']=blob(search)
    result['index.md']=('# '+html.escape(title)+'\n\n'+''.join('- ['+html.escape(r['title']).replace('[','\\[').replace(']','\\]')+']('+r['markdown']+')\n' for r in search)).encode()
    links=''.join('<li><a href="'+r['path']+'">'+html.escape(r['title'])+'</a> — '+html.escape(r['availability'])+'</li>' for r in search)
    result['index.html']=('<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">'
      '<title>'+html.escape(title)+'</title></head><body><a href="#main">Skip to content</a><main id="main"><h1>'+html.escape(title)+'</h1>'
      '<p>Use browser Find to search this complete offline list. Each entry has its own page.</p><nav aria-label="Reference entries"><ul>'+links+'</ul></nav></main></body></html>\n').encode()
    result['manifest.json']=blob(dict(schema=SCHEMA,profile=profile,documents=len(documents),
                                     files={k:digest(v) for k,v in sorted(result.items())}))
    need(sum(map(len,result.values())) <= MAX_CORPUS, 'LIMIT', 'reference corpus bytes')
    return result


def canonical_command(arguments):
    parser = argparse.ArgumentParser(prog='neboc docs factory')
    parser.add_argument('mode', choices=('build', 'check', 'diff'))
    parser.add_argument('manifest')
    parser.add_argument('-o', '--output', required=True)
    parser.add_argument('--root', required=True)
    options = parser.parse_args(arguments)
    root = Path(options.root).absolute()
    try:
        manifest_bytes = bounded_read(root, options.manifest, MAX_INPUT)
        manifest = parse_json(manifest_bytes)
        rows = extract(root, manifest)
        files = canonical_files(rows)
        need(bounded_read(root, options.manifest, MAX_INPUT) == manifest_bytes, 'STALE', 'manifest changed during generation')
        output = Path(options.output)
        difference = compare_files(files, actual_files(output)) if output.exists() else dict(added=sorted(files), removed=[], changed=[])
        if options.mode == 'build':
            atomic_corpus(output, files)
        elif options.mode == 'check':
            need(not any(difference.values()), 'STALE', 'generated corpus differs from current authorities')
        result = dict(schema=SCHEMA, command=options.mode, documents=len(rows), files=len(files),
                      corpus_sha256=digest(blob({k:digest(v) for k,v in sorted(files.items())})), diff=difference,
                      examples=sum(len(r['examples']) for r in rows), law_cases=sum(f['cases'] for r in rows for f in r['laws']))
        print(blob(result).decode(), end='')
        return 0
    except FactoryError:
        raise
    except (ValueError, OSError, KeyError, TypeError, subprocess.TimeoutExpired) as error:
        raise FactoryError('INPUT', 'canonical metadata authority rejected input: '+type(error).__name__) from error


if __name__ == '__main__':
    try:
        if len(sys.argv)>1 and sys.argv[1]=='canonical':
            raise SystemExit(canonical_command(sys.argv[2:]))
        main()
    except FactoryError as error:
        print(f'{error.code}: {error}', file=sys.stderr)
        raise SystemExit(1)
