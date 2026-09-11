"""Typed compatibility contracts and conservative, directional CI decisions.

Inputs describe frozen contracts, not attestations that an implementation obeys
them. Native interfaces have a separate authenticated projection. No operation
publishes a release, mutates sources, or infers ABI from source signatures.
"""
from __future__ import annotations
import hashlib
import json
import re
from pathlib import Path

from compiler.docs.provenance import read

FORMAT = 'nebo-compatibility-contract-v1'
REPORT = 'nebo-compatibility-vector-v2'
SECTIONS = ('api', 'abi', 'ni', 'diagnostics', 'package', 'target', 'source', 'security')
RANK = {'NONE': 0, 'PATCH': 1, 'MINOR': 2, 'MAJOR': 3}
CLASS_RANK = {'UNCHANGED': 0, 'COMPATIBLE': 1, 'BREAKING': 2,
              'REVIEW_REQUIRED': 3, 'SECURITY_REVOKED': 4}
MAX_BYTES = 16 << 20
MAX_RECORDS = 20000
MAX_NODES = 300000


class Invalid(ValueError):
    def __init__(self, pointer, message):
        self.pointer = pointer
        self.code = 'NEBO_COMPAT_INVALID'
        super().__init__(message)


def require(condition, pointer, message):
    if not condition:
        raise Invalid(pointer, message)


def canonical(value):
    return (json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',', ':'), allow_nan=False)+'\n').encode()


def digest(value):
    return hashlib.sha256(canonical(value)).hexdigest()


def equal(a, b):
    return canonical(a) == canonical(b)


def bounded(value):
    todo = [(value, 0)]; count = 0
    while todo:
        item, depth = todo.pop(); count += 1
        require(depth <= 48 and count <= MAX_NODES, '/', 'structured input budget exceeded')
        if isinstance(item, dict):
            require(all(isinstance(k, str) and 0 < len(k) <= 256 for k in item), '/', 'invalid object key')
            todo.extend((v, depth+1) for v in item.values())
        elif isinstance(item, list):
            todo.extend((v, depth+1) for v in item)
        elif isinstance(item, str):
            require(len(item.encode()) <= (1 << 20), '/', 'text budget exceeded')
        else:
            require(item is None or type(item) in (bool, int), '/', 'only integer JSON numbers are supported')
    return value


def parse(data):
    require(len(data) <= MAX_BYTES, '/', 'input exceeds 16 MiB')
    def pairs(items):
        out = {}
        for k, v in items:
            require(k not in out, '/', 'duplicate JSON key: '+k)
            out[k] = v
        return out
    try:
        return bounded(json.loads(data, object_pairs_hook=pairs,
            parse_constant=lambda _: (_ for _ in ()).throw(ValueError('nonfinite number'))))
    except (UnicodeError, json.JSONDecodeError, RecursionError, ValueError) as error:
        if isinstance(error, Invalid): raise
        raise Invalid('/', 'invalid bounded JSON') from error


def read_path(path):
    path = Path(path).absolute()
    # Start at / so intermediate symlinks cannot escape the selected path.
    return read(Path(path.anchor), path.relative_to(path.anchor).as_posix(), MAX_BYTES)


TEXT = {'type': 'string', 'minLength': 1, 'maxLength': 4096}
INTEGER = {'type': 'integer', 'minimum': 0, 'maximum': (1 << 64)-1}
STRINGS = {'type': 'array', 'items': TEXT, 'uniqueItems': True, 'maxItems': 20000}
MAP = {'type': 'object', 'additionalProperties': TEXT, 'maxProperties': MAX_RECORDS}


def obj(properties):
    return {'type': 'object', 'properties': properties, 'required': list(properties), 'additionalProperties': False}


WIRE = obj({'required': MAP, 'optional': MAP})
FIELDS = {
    'api': dict(name=TEXT, module=TEXT, signature=TEXT, constraints=STRINGS,
                errors=STRINGS, effects=STRINGS, capabilities=STRINGS,
                stability={'enum': ['EXPERIMENTAL','TARGET_GATED','STABLE','DEPRECATED','REMOVED']},
                target=STRINGS, ownership=TEXT),
    'abi': dict(layout=MAP, tags=MAP, alignment=INTEGER, calling_convention=TEXT,
                mangling=TEXT, runtime_version=TEXT, object_version=TEXT),
    'ni': dict(schema=INTEGER, reader_min=INTEGER, reader_max=INTEGER,
               required_features=STRINGS, supported_features=STRINGS,
               exports=MAP, dependencies=MAP, docs=MAP, target=TEXT, fingerprints=MAP),
    'diagnostics': dict(code=TEXT, severity={'enum':['error','warning','note','help','fatal']},
                        stage=TEXT, spans=TEXT, json=WIRE, sarif=WIRE, lsp=WIRE,
                        exit=INTEGER, wording=TEXT),
    'package': dict(identity=TEXT, version=TEXT, pins=MAP, hashes=MAP,
                    capabilities=STRINGS, targets=STRINGS, dependencies=MAP,
                    modules=MAP, manifest_schema=TEXT, lock_schema=TEXT),
    'target': dict(profile=TEXT, tcb=STRINGS, syscalls=STRINGS, console_backend=TEXT,
                   sdk_contents=MAP, claims=MAP, runtime_version=TEXT,
                   object_version=TEXT, toolchain=MAP),
    'source': dict(edition=INTEGER, forms=STRINGS),
    'security': dict(revoked={'type':'boolean'}, requirements=STRINGS),
}
CONTRACT_SCHEMA = obj({'format': {'const': FORMAT}, 'sections': obj({
    name: {'type':'object', 'additionalProperties':obj(fields), 'maxProperties':MAX_RECORDS}
    for name, fields in FIELDS.items()})})


def validate(value, schema, pointer='/'):
    if 'const' in schema: require(equal(value, schema['const']), pointer, 'unexpected schema identity')
    if 'enum' in schema: require(any(equal(value, v) for v in schema['enum']), pointer, 'unknown enum value')
    typ = schema.get('type')
    types = {'object':dict, 'array':list, 'string':str, 'integer':int, 'boolean':bool}
    if typ: require(type(value) is types[typ], pointer, 'expected '+typ)
    if typ == 'object':
        require(len(value) <= schema.get('maxProperties', MAX_RECORDS), pointer, 'record budget exceeded')
        props = schema.get('properties', {})
        require(set(schema.get('required', [])) <= set(value), pointer, 'missing required fields')
        for k, v in value.items():
            require(isinstance(k,str) and 0 < len(k) <= 256, pointer, 'invalid identity')
            child = props.get(k, schema.get('additionalProperties', False))
            require(child is not False, pointer+k, 'unclassified field')
            validate(v, child, pointer+k.replace('~','~0').replace('/','~1')+'/')
    if typ == 'array':
        require(len(value) <= schema.get('maxItems', MAX_RECORDS), pointer, 'array budget exceeded')
        if schema.get('uniqueItems'): require(len({canonical(v) for v in value}) == len(value), pointer, 'duplicate set element')
        for i,v in enumerate(value): validate(v,schema['items'],pointer+str(i)+'/')
    if typ == 'integer': require(schema.get('minimum',0) <= value <= schema.get('maximum',(1<<64)-1), pointer, 'integer outside bounds')
    if typ == 'string': require(schema.get('minLength',0) <= len(value) <= schema.get('maxLength',4096), pointer, 'text outside bounds')


def contract(value):
    bounded(value); validate(value, CONTRACT_SCHEMA)
    for identity,row in value['sections']['abi'].items():
        alignment=row['alignment']
        require(0 < alignment <= (1 << 20) and not alignment & (alignment-1),
                '/sections/abi/'+identity+'/alignment','alignment must be a bounded power of two')
    for identity, row in value['sections']['ni'].items():
        require(row['reader_min'] <= row['schema'] <= row['reader_max'], '/sections/ni/'+identity, 'writer schema outside reader range')
        require(set(row['required_features']) <= set(row['supported_features']), '/sections/ni/'+identity, 'unsupported required feature')
    from compiler.sdk.package_manager import version
    for identity,row in value['sections']['package'].items():
        try: version(row['version'])
        except ValueError as error: raise Invalid('/sections/package/'+identity+'/version','invalid SemVer') from error
    return value['sections']


def compatible_map(before, after):
    return set(before) <= set(after) and all(equal(v, after[k]) for k,v in before.items())


def classify(section, field, before, after, old, new):
    if section == 'security' and new['revoked']: return 'SECURITY_REVOKED','MAJOR','security revocation'
    if (section,field) in {('ni','docs'),('diagnostics','wording')}:
        return 'COMPATIBLE','NONE','human documentation changed'
    if section == 'ni' and field == 'fingerprints':
        return 'REVIEW_REQUIRED','NONE','opaque fingerprint drift needs the native artifact or structural derivation'
    if section == 'ni' and field in ('reader_min','reader_max','schema','required_features','supported_features'):
        safe = (new['reader_min'] <= old['schema'] <= new['reader_max'] and
                old['reader_min'] <= new['schema'] <= old['reader_max'] and
                set(new['required_features']) <= set(old['supported_features']) and
                set(old['required_features']) <= set(new['supported_features']))
        return ('COMPATIBLE','MINOR','bidirectional reader range and feature proof') if safe else ('BREAKING','MAJOR','reader compatibility lost')
    if section == 'diagnostics' and field in ('json','sarif','lsp'):
        safe = equal(before['required'],after['required']) and compatible_map(before['optional'],after['optional'])
        return ('COMPATIBLE','MINOR','only optional wire fields added') if safe else ('BREAKING','MAJOR','machine diagnostic schema changed')
    if section == 'api' and field == 'stability' and (before,after) in {('EXPERIMENTAL','STABLE'),('TARGET_GATED','STABLE')}:
        return 'COMPATIBLE','MINOR','explicit stability promotion'
    if isinstance(before,list):
        b,a = set(before),set(after)
        requirements = field in ('constraints','errors','effects','capabilities','requirements')
        if section == 'target' and field in ('tcb','syscalls') and a-b:
            return 'REVIEW_REQUIRED','NONE','trusted execution or syscall surface expanded'
        safe = a <= b if requirements or (section=='target' and field in ('tcb','syscalls')) else b <= a
        return ('COMPATIBLE','MINOR','directional set inclusion') if safe else ('BREAKING','MAJOR','consumer requirement increased or support removed')
    if (section,field) in {('ni','exports'),('target','sdk_contents')} and compatible_map(before,after):
        return 'COMPATIBLE','MINOR','existing entries retained exactly'
    if section == 'target' and field in ('tcb','toolchain','claims','sdk_contents'):
        return 'REVIEW_REQUIRED','NONE','implementation or assurance change requires independent review'
    return 'BREAKING','MAJOR','exact frozen consumer contract changed'


def report(changes, baseline, candidate, scope='FULL_CONTRACT', assessed=SECTIONS):
    vector = {s:('UNCHANGED' if s in assessed else 'UNASSESSED') for s in SECTIONS}
    bump = 'NONE'
    for c in changes:
        if CLASS_RANK[c['classification']] > CLASS_RANK.get(vector[c['dimension']],0): vector[c['dimension']] = c['classification']
        if RANK[c['required_bump']] > RANK[bump]: bump = c['required_bump']
    blockers=[dict(dimension=c['dimension'],identity=c['identity'],field=c['field'],reason=c['reason'])
              for c in changes if c['classification'] in ('BREAKING','REVIEW_REQUIRED','SECURITY_REVOKED')]
    if scope != 'FULL_CONTRACT': blockers.append(dict(dimension='scope',identity=scope,field='coverage',reason='other release dimensions remain unassessed'))
    security = any(c['classification']=='SECURITY_REVOKED' or (c['dimension'] in ('security','target') and c['classification']=='REVIEW_REQUIRED') for c in changes)
    return dict(format=REPORT,scope=scope,baseline=baseline,candidate=candidate,
        compatibility_vector=vector,changes=changes,required_bump=bump,
        blockers=blockers,migrations=[dict(dimension=c['dimension'],identity=c['identity'],field=c['field']) for c in changes if c['required_bump']=='MAJOR'],
        approvals_required=['owner','reviewer']+(['security'] if security else []),
        release_authorized=False)


def compare_contracts(base, candidate):
    left,right = contract(base),contract(candidate); changes=[]
    for section in SECTIONS:
        for identity in sorted(left[section].keys() | right[section].keys()):
            b,a=left[section].get(identity),right[section].get(identity)
            if b is None or a is None:
                revoked=section=='security' and a is not None and a['revoked']
                cls,bump,why=('SECURITY_REVOKED','MAJOR','new security revocation') if revoked else ('COMPATIBLE','MINOR','new independent identity') if b is None else ('BREAKING','MAJOR','identity removed')
                changes.append(dict(dimension=section,identity=identity,field='/',classification=cls,required_bump=bump,reason=why,before=b,after=a))
                continue
            for field in sorted(b):
                # Set order has no contract significance.
                bv,av=b[field],a[field]
                if isinstance(bv,list): bv,av=sorted(bv),sorted(av)
                if equal(bv,av): continue
                cls,bump,why=classify(section,field,bv,av,b,a)
                changes.append(dict(dimension=section,identity=identity,field=field,classification=cls,required_bump=bump,reason=why,before=bv,after=av))
    return report(changes,digest(base),digest(candidate))


def policy(report_value, value):
    """A local dry-run attestation cannot waive an opaque or incomplete diff."""
    validate(value,obj({'baseline_version':TEXT,'proposed_version':TEXT,
        'change_kind':{'enum':['DOCUMENTATION','FIX','CHANGE']},'migrations':STRINGS,
        'approvals':{'type':'array','maxItems':3,'items':obj({'role':{'enum':['owner','reviewer','security']},'actor':TEXT,'report_sha256':TEXT})}}))
    from compiler.sdk.package_manager import version
    try: old,new=version(value['baseline_version']),version(value['proposed_version'])
    except ValueError as error: raise Invalid('/policy/version','invalid SemVer') from error
    minimum=report_value['required_bump']
    if value['change_kind']=='FIX' and minimum=='NONE': minimum='PATCH'
    actual='NONE' if new==old else 'MAJOR' if new[0]>old[0] else 'MINOR' if new[:1]==old[:1] and new[1]>old[1] else 'PATCH'
    blockers=[]
    if new<old or RANK[actual]<RANK[minimum]: blockers.append('INSUFFICIENT_VERSION_BUMP')
    if value['change_kind']=='DOCUMENTATION' and minimum!='NONE': blockers.append('DOCUMENTATION_CHANGES_CONTRACT')
    if report_value['scope']!='FULL_CONTRACT': blockers.append('INCOMPLETE_RELEASE_SCOPE')
    if any(c['classification']=='REVIEW_REQUIRED' for c in report_value['changes']): blockers.append('UNPROVEN_COMPATIBILITY')
    expected={c['dimension']+':'+c['identity']+':'+c['field'] for c in report_value['migrations']}
    if not expected <= set(value['migrations']): blockers.append('MISSING_MIGRATION_DECISION')
    roles=set();actors=set();bound=digest(report_value)
    for a in value['approvals']:
        if a['role'] in roles or a['actor'] in actors or a['report_sha256']!=bound: blockers.append('INVALID_OR_STALE_APPROVAL')
        roles.add(a['role']);actors.add(a['actor'])
    if not set(report_value['approvals_required'])<=roles: blockers.append('MISSING_APPROVAL')
    return dict(decision='BLOCKED' if blockers else 'VALID_DRY_RUN',required_bump=minimum,
                actual_bump=actual,blockers=sorted(set(blockers)),report_sha256=bound,release_authorized=False)
