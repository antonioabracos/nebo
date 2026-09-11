"""Extract current public claims; do not turn a registry entry into runtime proof."""
import hashlib
import csv
import json
import re
import sys
from harness import ROOT, Failure

REGISTRIES = (
    'collections/associative_collections_source_vertical.inc',
    'graph/graph_tree_source_vertical.inc',
    'data/typed_data_source_vertical.inc',
    'numeric/scalar_vector_math_source_vertical.inc',
    'matrix/dense_matrix_source_vertical.inc',
    'tensor/tensor_source_vertical.inc',
    'visual/visual_console_source_vertical.inc',
    'visual/console_scan_source_vertical.inc',
)

def inventory():
    records = []
    registry_path = 'sdk/interfaces/prelude/stdlib-registry.json'
    registry = json.loads((ROOT / registry_path).read_text())
    if registry.get('schema') != 1:
        raise Failure('STDLIB_REGISTRY_SCHEMA')
    for module in registry['modules']:
        for name in module['exports']:
            records.append(dict(authority=registry_path, name=name, module=module['name'],
                                stability=module['stability'], targets=module['targets'],
                                capabilities=module['capabilities'], symbol_id=None,
                                proof='UNRECONCILED'))
    prelude_path = 'sdk/interfaces/prelude/std.prelude.ni'
    prelude = json.loads((ROOT / prelude_path).read_text())
    if str(ROOT) not in sys.path:
        sys.path.insert(0, str(ROOT))
    from compiler.sdk.prelude import PreludeInterface, PreludeProfile
    interfaces = {edition['edition']: PreludeInterface.load(PreludeProfile.forEdition(edition['edition']), 'x86_64-systemv-elf-linux') for edition in prelude['editions']}
    declared = {(edition, record['name']): record for edition, interface in interfaces.items() for record in interface.symbol_records}
    for record in records:
        match = declared.get(('1', record['name']))
        if match and match['origin'] == record['module']:
            record['symbol_id'] = match['symbolId']
            record['kind'] = match['kind']
    for edition in prelude['editions']:
        for symbol in edition['symbols']:
            records.append(dict(authority=prelude_path, name=symbol['name'],
                                module=symbol['origin'], component=symbol['component'],
                                edition=edition['edition'], symbol_id=declared[(edition['edition'],symbol['name'])]['symbolId'],
                                kind=symbol['kind'], stability=next(row['stability'] for row in registry['modules'] if row['name']==symbol['origin']),
                                targets=interfaces[edition['edition']].target.split(','),
                                proof='UNRECONCILED'))
    for relative in REGISTRIES:
        path = 'compiler/semantic/' + relative
        data = (ROOT / path).read_bytes()
        names = re.findall(rb"^G[0-9]+_NAME\s+[^,]+,'([^']+)'", data, re.M)
        if not names:
            raise Failure('EMPTY_PUBLIC_OWNER_REGISTRY:' + path)
        for name in sorted(set(names)):
            records.append(dict(authority=path, name=name.decode('ascii'), module=None,
                                symbol_id=None, proof='UNRECONCILED',
                                authority_sha256=hashlib.sha256(data).hexdigest()))
    for group in ('G054','G055','G056','G057'):
        path=f'tests/rf204/{group}/API-REGISTRY.tsv'
        data=(ROOT/path).read_bytes()
        for row in csv.DictReader(data.decode().splitlines(),delimiter='\t'):
            name=row.get('api',row.get('spelling'))
            receiver=row.get('receiver','Text')
            records.append(dict(authority=path,name=receiver+'.'+name,module='builtin',
                                stability=row['maturity'],signature=row['signature'],
                                limits=row.get('limits',row.get('limit','')),
                                profile=row.get('profile',''),ownership=row['ownership'],
                                symbol_id=None,proof='UNRECONCILED',
                                authority_sha256=hashlib.sha256(data).hexdigest()))
    # A source-owner atom is not a serialized SymbolId or maturity record.
    # coverage.py joins it to receiver-qualified current declarations and
    # published profiles; unresolved claims block F01/F12.
    return records
