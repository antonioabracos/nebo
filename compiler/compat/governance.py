"""Bounded, read-only change governance. Decisions are dry-run, never releases.

Structural compatibility reuses the existing diff owner. Review attestations
bind exact inputs; they are local evidence, not authenticated human signatures.
"""
from __future__ import annotations

import copy
import hashlib
import importlib.util
import json
import re
import sys
from pathlib import Path

from compiler.compat.compatibility_diff import DIMENSIONS, compare
from compiler.docs.provenance import read
from compiler.sdk.package_manager import version, satisfies, load_store, verify
from compiler.sdk.prelude import PreludeInterface, PreludeProfile, TARGET

MAX_FILE = 1 << 20
MAX_INPUT = 16 << 20
ROOT = Path(__file__).resolve().parents[2]
STATES = ('EXPERIMENTAL', 'TARGET_GATED', 'STABLE', 'DEPRECATED', 'REMOVED', 'REVOKED_SECURITY')
EDITION_STATES = ('PROPOSED', 'RESERVED', 'PREVIEW', 'ACTIVE', 'MAINTENANCE', 'RETIRED')
EDGES = {('EXPERIMENTAL','TARGET_GATED'), ('EXPERIMENTAL','STABLE'),
         ('TARGET_GATED','EXPERIMENTAL'), ('TARGET_GATED','STABLE'),
         ('STABLE','DEPRECATED'), ('DEPRECATED','REMOVED')}
EDGES |= {(s,'REVOKED_SECURITY') for s in STATES[:4]}
RANK = {'NONE':0, 'PATCH':1, 'MINOR':2, 'MAJOR':3}
CLASSES = {'UNCHANGED','COMPATIBLE','BREAKING','SECURITY_REVOKED'}
CODE = re.compile(r'[A-Za-z][A-Za-z0-9_.:-]{0,127}')
SID = re.compile(r'0x[0-9a-f]{16}')


class GovernanceError(ValueError):
    def __init__(self, code, pointer, message):
        self.code = 'NEBO_GOV_' + code
        self.pointer = pointer
        super().__init__(message)


def require(ok, code, pointer, message):
    if not ok:
        raise GovernanceError(code, pointer, message)


def canonical(value):
    return (json.dumps(value, sort_keys=True, ensure_ascii=False, separators=(',',':'))+'\n').encode()


def digest(data):
    return hashlib.sha256(data).hexdigest()


def native_interface(data, pointer):
    name='nebo_governance_native_interface'
    if name not in sys.modules:
        spec=importlib.util.spec_from_file_location(name,ROOT/'tools/rf204-g154.py')
        owner=importlib.util.module_from_spec(spec);sys.modules[name]=owner;spec.loader.exec_module(owner)
    try:
        report=sys.modules[name].interface_report(data,'<governance interface>')
        require(report['target']==TARGET,'SUPPORT',pointer,'native interface target is unsupported')
        return report
    except GovernanceError:raise
    except Exception as error:raise GovernanceError('INTERFACE',pointer,'native interface reader rejected input') from error


def runtime_identity():
    source=(ROOT/'compiler/abi/abi_versioning.inc').read_text()
    constants={k:int(v) for k,v in re.findall(r'^%define (NEBO_(?:ABI|RUNTIME)_CURRENT_(?:MAJOR|MINOR)) ([0-9]+)$',source,re.M)}
    return dict(architecture='x86_64',calling_convention='systemv',object_format='elf',
        abi=f"{constants['NEBO_ABI_CURRENT_MAJOR']}.{constants['NEBO_ABI_CURRENT_MINOR']}",
        runtime_abi=f"{constants['NEBO_RUNTIME_CURRENT_MAJOR']}.{constants['NEBO_RUNTIME_CURRENT_MINOR']}")


def object_fields(value, fields, pointer):
    require(isinstance(value,dict) and set(value)==set(fields.split()), 'SCHEMA',pointer,'unknown or missing fields')


def text(value, pointer):
    require(isinstance(value,str) and value.strip() and len(value.encode())<=4096
            and not any(ord(c)<32 for c in value), 'SCHEMA',pointer,'bounded nonempty text required')


def identity(value, pointer):
    require(isinstance(value,str) and CODE.fullmatch(value), 'SCHEMA',pointer,'invalid stable record identity')


def symbol(value, pointer):
    require(isinstance(value,str) and SID.fullmatch(value) and int(value,16), 'IDENTITY',pointer,'nonzero serialized SymbolId required')


def integer(value, pointer, minimum=0, maximum=65535):
    require(type(value) is int and minimum<=value<=maximum, 'SCHEMA',pointer,'integer outside bounded range')


def semver(value, pointer):
    try:
        return version(value)
    except ValueError as error:
        raise GovernanceError('VERSION',pointer,'invalid bounded package SemVer') from error


def parse(data):
    require(len(data)<=MAX_FILE,'LIMIT','/','record exceeds 1 MiB')
    def pairs(items):
        result={}
        for key,value in items:
            require(key not in result,'SCHEMA','/','duplicate JSON key: '+key)
            result[key]=value
        return result
    try:
        return json.loads(data,object_pairs_hook=pairs,
                          parse_constant=lambda _: (_ for _ in ()).throw(ValueError('nonfinite number')))
    except (UnicodeError,json.JSONDecodeError,RecursionError,ValueError) as error:
        if isinstance(error,GovernanceError):raise
        raise GovernanceError('SCHEMA','/','invalid bounded JSON') from error


class Inputs:
    def __init__(self, root):
        self.root=Path(root).absolute();self.pins={};self.total=0
        current=Path(self.root.anchor)
        for part in self.root.parts[1:]:
            current/=part
            require(current.is_dir() and not current.is_symlink(),'INPUT','/root','unsafe input root')

    def get(self, ref, pointer):
        object_fields(ref,'path sha256',pointer)
        require(isinstance(ref['path'],str) and isinstance(ref['sha256'],str)
                and re.fullmatch('[0-9a-f]{64}',ref['sha256']), 'SCHEMA',pointer,'invalid pinned reference')
        try:data=read(self.root,ref['path'],MAX_FILE)
        except (OSError,ValueError) as error:
            raise GovernanceError('INPUT',pointer,'unsafe, missing or unbounded reference') from error
        require(digest(data)==ref['sha256'],'STALE',pointer,'input digest differs from pinned evidence')
        require(ref['path'] not in self.pins or self.pins[ref['path']]==ref['sha256'],'STALE',pointer,'contradictory pins')
        if ref['path'] not in self.pins:self.total+=len(data)
        self.pins[ref['path']]=ref['sha256']
        require(len(self.pins)<=256 and self.total<=MAX_INPUT,'LIMIT',pointer,'aggregate evidence budget exceeded')
        return data

    def refs(self, refs, pointer, minimum=1):
        require(isinstance(refs,list) and minimum<=len(refs)<=32,'SCHEMA',pointer,'bounded evidence list required')
        for i,ref in enumerate(refs):self.get(ref,f'{pointer}/{i}')

    def recheck(self):
        for path,sha in list(self.pins.items()):self.get(dict(path=path,sha256=sha),'/evidence')


def snapshot(inputs, ref, pointer):
    value=parse(inputs.get(ref,pointer))
    object_fields(value,'schema dimensions provenance interface',pointer)
    require(type(value['schema']) is int and value['schema']==1,'SCHEMA',pointer,'snapshot schema must be 1')
    inputs.refs(value['provenance'],pointer+'/provenance')
    dimensions=value['dimensions']
    require(isinstance(dimensions,dict) and set(dimensions)==set(DIMENSIONS),'DIMENSION',pointer,'all twelve dimensions must be explicit')
    for name,records in dimensions.items():
        require(isinstance(records,dict) and len(records)<=256,'LIMIT',pointer+'/'+name,'bounded symbol map required')
        for key,fields in records.items():
            identity(key,pointer+'/'+name)
            require(not key.startswith('native.'),'IDENTITY',pointer+'/'+name,'native facts cannot be supplied as claims')
            require(isinstance(fields,dict) and 1<=len(fields)<=32,'SCHEMA',pointer+'/'+name+'/'+key,'typed contract fields required')
            for field,data in fields.items():
                identity(field,pointer+'/'+name+'/'+key)
                require(type(data) in (str,int,bool) and (type(data)!=int or 0<=data<=65535),
                        'SCHEMA',pointer+'/'+name+'/'+key+'/'+field,'only bounded scalar contract fields are supported')
                if isinstance(data,str):text(data,pointer+'/'+name+'/'+key+'/'+field)
    native=native_interface(inputs.get(value['interface'],pointer+'/interface'),pointer+'/interface')
    result=copy.deepcopy(dimensions)
    for dimension,field in [('api','apiFingerprint'),('abi','abiFingerprint'),('source','typedHirDigest'),
                            ('effects','effects'),('capabilities','capabilities'),('ownership','ownership'),('target','target')]:
        result[dimension]['native.interface']={field:json.dumps(native[field],sort_keys=True)}
    return result


def diagnostic_projection(records):
    projected={}
    for code,row in records.items():
        required={'stage','severity','exit_class','primary_span','wording'}
        require(required<=set(row) and all(k in required or k.startswith(('required.','optional.')) for k in row),
                'DIAGNOSTIC','/diagnostics/'+code,'diagnostic machine contract is incomplete')
        require(row['severity'] in ('error','warning','note') and row['exit_class'] in ('error','success'),
                'DIAGNOSTIC','/diagnostics/'+code,'invalid diagnostic severity or exit class')
        projected[code]={k:v for k,v in row.items() if k!='wording'}
    return projected


def vector(before, after, kind):
    require(kind in ('DOCUMENTATION','FIX','CHANGE'),'SCHEMA','/change_kind','unknown change kind')
    left=copy.deepcopy(before);right=copy.deepcopy(after)
    left['diagnostics']=diagnostic_projection(left['diagnostics'])
    right['diagnostics']=diagnostic_projection(right['diagnostics'])
    structural=compare(left,right)
    result={d:'UNCHANGED' for d in DIMENSIONS};minimum='NONE';security=False
    for change in structural['changes']:
        dimension=change['dimension'];classification=change['classification']
        # A new required diagnostic field changes the consumer contract; only
        # optional additions are compatible. Human wording is absent above.
        if dimension=='diagnostics' and change['before'] is not None and change['after'] is not None:
            old=change['before'];new=change['after']
            if any(k not in old and not k.startswith('optional.') for k in new):classification='BREAKING'
        if classification=='SECURITY_REVOKED':security=True
        ranking={'UNCHANGED':0,'COMPATIBLE':1,'BREAKING':2,'SECURITY_REVOKED':3}
        if ranking[classification]>ranking[result[dimension]]:result[dimension]=classification
        bump='MINOR' if classification=='COMPATIBLE' else 'MAJOR'
        if RANK[bump]>RANK[minimum]:minimum=bump
    if kind=='FIX' and minimum=='NONE':minimum='PATCH'
    require(kind!='DOCUMENTATION' or minimum=='NONE','CLASSIFICATION','/change_kind','documentation-only record changes a machine contract')
    return result,minimum,security


def edition_policy(value, inputs, migrations):
    object_fields(value,'id from to prelude support reserved_syntax_active', '/edition')
    integer(value['id'],'/edition/id',1)
    require(value['from'] in EDITION_STATES and value['to'] in EDITION_STATES,'EDITION','/edition','unknown lifecycle state')
    start=EDITION_STATES.index(value['from']);end=EDITION_STATES.index(value['to'])
    require(end==start or end==start+1,'EDITION','/edition/to','only an adjacent forward lifecycle transition is defined')
    require(value['reserved_syntax_active'] is False,'EDITION','/edition/reserved_syntax_active','a governance decision cannot activate reserved syntax')
    window=value['support'];object_fields(window,'basis decision minimum maximum','/edition/support')
    require(window['basis']=='EXPLICIT_VERSION_RANGE','SUPPORT','/edition/support','no implicit calendar support promise')
    low=semver(window['minimum'],'/edition/support/minimum');high=semver(window['maximum'],'/edition/support/maximum')
    require(low<=high,'SUPPORT','/edition/support','reversed support window')
    inputs.get(window['decision'],'/edition/support/decision')
    inputs.get(value['prelude'],'/edition/prelude')
    if end>=3:
        try:actual=PreludeInterface.load(PreludeProfile.forEdition(str(value['id'])),TARGET)
        except Exception as error:raise GovernanceError('EDITION','/edition/prelude','no material prelude for active Edition') from error
        require(actual.interface_hash==value['prelude']['sha256'],'EDITION','/edition/prelude','Edition and current prelude identity differ')
    if value['from']!=value['to'] and end>=3:
        require(migrations,'MIGRATION','/edition','activation/support changes require a migration decision')
    return dict(id=value['id'],state=value['to'],prelude_sha256=value['prelude']['sha256'],support=window['basis'])


def transition(value, minimum, security, migrations, inputs, proposed):
    object_fields(value,'symbol_id from to evidence deprecation','/stability')
    symbol(value['symbol_id'],'/stability/symbol_id')
    old,new=value['from'],value['to']
    require(old in STATES and new in STATES,'STABILITY','/stability','unknown stability tier')
    require(old==new or (old,new) in EDGES,'STABILITY','/stability/to','undefined stability transition')
    inputs.refs(value['evidence'],'/stability/evidence')
    require(new!='REVOKED_SECURITY' or security,'SECURITY','/stability','revocation needs an actual security change and review')
    if new in ('DEPRECATED','REMOVED','REVOKED_SECURITY'):
        dep=value['deprecation']
        object_fields(dep,'replacement warning_since remove_not_before warning_id migration docs package_metadata introduced_edition deprecated_edition removal_edition','/stability/deprecation')
        symbol(dep['replacement'],'/stability/deprecation/replacement')
        require(dep['replacement']!=value['symbol_id'],'MIGRATION','/stability/deprecation/replacement','replacement must be distinct')
        warning=semver(dep['warning_since'],'/stability/deprecation/warning_since')
        removal=semver(dep['remove_not_before'],'/stability/deprecation/remove_not_before')
        require(warning<=proposed and removal>warning and removal[0]>warning[0],
                'DEPRECATION','/stability/deprecation','warning and removal require distinct release gates and a later major')
        for k in ('introduced_edition','deprecated_edition','removal_edition'):integer(dep[k],'/stability/deprecation/'+k,1)
        require(dep['deprecated_edition']>dep['introduced_edition'] and dep['removal_edition']>=dep['deprecated_edition']+2,
                'DEPRECATION','/stability/deprecation','native Registry ordinal window requires one complete intermediate Edition')
        identity(dep['warning_id'],'/stability/deprecation/warning_id')
        for k in ('migration','docs','package_metadata'):inputs.get(dep[k],'/stability/deprecation/'+k)
        require(migrations and dep['migration'] in migrations,'MIGRATION','/stability/deprecation/migration','migration must be part of the reviewed change')
        if new=='REMOVED':
            require(minimum=='MAJOR' and proposed>=removal,'DEPRECATION','/stability','stable removal requires major and elapsed warning gate')
    else:require(value['deprecation'] is None,'DEPRECATION','/stability/deprecation','unexpected tombstone on active tier')
    if new=='STABLE' and old!=new:
        require(minimum in ('MINOR','MAJOR'),'STABILITY','/stability','promotion needs a public version decision')
    return dict(symbol_id=value['symbol_id'],state=new)


def support_policy(value, inputs):
    object_fields(value,'package ni runtime','/support')
    package=value['package'];object_fields(package,'id pin range content_sha256 lock store','/support/package')
    semver(package['pin'],'/support/package/pin')
    try:compatible=satisfies(package['pin'],package['range'])
    except ValueError as error:raise GovernanceError('SUPPORT','/support/package/range','unsupported package range') from error
    require(compatible,'SUPPORT','/support/package','exact pin falls outside declared support range')
    require(isinstance(package['content_sha256'],str) and re.fullmatch('[0-9a-f]{64}',package['content_sha256']),
            'SCHEMA','/support/package/content_sha256','exact content digest required')
    raw=inputs.get(package['lock'],'/support/package/lock')
    store=package['store']
    require(isinstance(store,str) and store and not Path(store).is_absolute()
            and all(p not in ('','.','..') for p in store.split('/')),'INPUT','/support/package/store','relative store required')
    try:
        lock,_,payloads=load_store(inputs.root/store,raw,package['lock']['sha256'])
        verify(inputs.root/store,raw,package['lock']['sha256'])
    except (OSError,ValueError) as error:
        raise GovernanceError('SUPPORT','/support/package/lock','native package owner rejected lock, store or interface') from error
    selected=[row for row in lock['packages'] if row['id']==package['id']]
    require(len(selected)==1 and selected[0]['version']==package['pin']
            and selected[0]['content_sha256']==package['content_sha256'],
            'SUPPORT','/support/package/lock','exact package pin and content must match verified lock')
    for row in lock['packages']:
        for name,data in payloads[row['id']].items():
            path=f"{store}/packages/{row['id']}/{row['version']}/{row['content_sha256']}/{name}"
            inputs.get(dict(path=path,sha256=digest(data)),'/support/package/store')
    ni=value['ni'];object_fields(ni,'schema reader_min reader_max required_features supported_features interface','/support/ni')
    for k in set(ni)-{'interface'}:integer(ni[k],'/support/ni/'+k)
    actual_ni=native_interface(inputs.get(ni['interface'],'/support/ni/interface'),'/support/ni/interface')
    require(any(digest(data)==ni['interface']['sha256'] for name,data in payloads[package['id']].items()
                if name.endswith('.ni')),'SUPPORT','/support/ni/interface','interface is not in selected package')
    require(ni['schema']==actual_ni['schema'],'SUPPORT','/support/ni/schema','claimed schema differs from native reader')
    require(ni['reader_min']<=ni['schema']<=ni['reader_max'] and not ni['required_features'] & ~ni['supported_features'],
            'SUPPORT','/support/ni','reader schema range or required feature mismatch')
    runtime=value['runtime'];object_fields(runtime,'required available','/support/runtime')
    for k in runtime:
        object_fields(runtime[k],'architecture calling_convention object_format abi runtime_abi','/support/runtime/'+k)
        for key,v in runtime[k].items():text(v,'/support/runtime/'+k+'/'+key)
    require(runtime['required']==runtime['available'],'SUPPORT','/support/runtime','runtime identity negotiation failed')
    require(runtime['available']==runtime_identity(),'SUPPORT','/support/runtime/available','available runtime differs from current ABI owner')
    symbols=set()
    for name,data in payloads[package['id']].items():
        if name.endswith('.ni'):
            symbols.update(native_interface(data,'/support/package/interface')['symbolIds'])
    return dict(package_pin=package['pin'],ni_schema=ni['schema'],runtime=runtime['available'],
                symbol_ids=[f'0x{s:016x}' for s in sorted(symbols) if s])


def approval_digest(record):
    return digest(canonical({k:v for k,v in record.items() if k!='approvals'}))


def evaluate(record, root):
    object_fields(record,'schema mode id owner change_kind baseline_version proposed_version baseline candidate compatibility_vector required_bump authorities tests migration threat_review release_notes approvals edition stability support','/')
    require(type(record['schema']) is int and record['schema']==1,'SCHEMA','/schema','change schema must be 1')
    require(record['mode']=='DRY_RUN','ACTION','/mode','only local dry-run evaluation is implemented')
    identity(record['id'],'/id');identity(record['owner'],'/owner')
    inputs=Inputs(root)
    inputs.refs(record['authorities'],'/authorities');inputs.refs(record['tests'],'/tests')
    inputs.refs(record['migration'],'/migration',minimum=0)
    for k in ('threat_review','release_notes'):inputs.get(record[k],'/'+k)
    before=snapshot(inputs,record['baseline'],'/baseline');after=snapshot(inputs,record['candidate'],'/candidate')
    classified,minimum,security=vector(before,after,record['change_kind'])
    require(record['compatibility_vector']==classified,'CLASSIFICATION','/compatibility_vector','claimed vector differs from structural contracts or has unclassified dimensions')
    require(record['required_bump']==minimum,'VERSION','/required_bump','required SemVer bump differs from derived minimum')
    old=semver(record['baseline_version'],'/baseline_version');new=semver(record['proposed_version'],'/proposed_version')
    actual='NONE' if old==new else 'MAJOR' if new[0]>old[0] else 'MINOR' if new[:1]==old[:1] and new[1]>old[1] else 'PATCH'
    require(new>=old and RANK[actual]>=RANK[minimum],'VERSION','/proposed_version','downgrade or insufficient bump')
    if minimum=='MAJOR':require(record['migration'],'MIGRATION','/migration','breaking changes require an explicit tested migration decision')
    edition=edition_policy(record['edition'],inputs,record['migration'])
    stability=transition(record['stability'],minimum,security,record['migration'],inputs,new)
    support=support_policy(record['support'],inputs)
    candidate=parse(inputs.get(record['candidate'],'/candidate'))
    require(candidate['interface']==record['support']['ni']['interface'],'SUPPORT','/support/ni/interface','support must describe the candidate interface')
    known_symbols=set(support['symbol_ids'])
    if record['stability']['to']=='REMOVED':
        baseline=parse(inputs.get(record['baseline'],'/baseline'))
        native=native_interface(inputs.get(baseline['interface'],'/baseline/interface'),'/baseline/interface')
        known_symbols.update(f'0x{s:016x}' for s in native['symbolIds'])
    require(record['stability']['symbol_id'] in known_symbols,'IDENTITY','/stability/symbol_id','governed declaration must resolve in the native package or removal baseline')
    dep=record['stability']['deprecation']
    if dep:
        require(dep['replacement'] in support['symbol_ids'],'IDENTITY','/stability/deprecation/replacement','replacement must resolve in the native package')
    approvals=record['approvals'];require(isinstance(approvals,list) and 2<=len(approvals)<=16,'APPROVAL','/approvals','owner and independent reviewer attestations required')
    roles=set();actors=set();bound=approval_digest(record)
    for i,approval in enumerate(approvals):
        p=f'/approvals/{i}';object_fields(approval,'role actor decision record_sha256 evidence',p)
        require(approval['role'] in ('owner','reviewer','security') and approval['role'] not in roles,'APPROVAL',p,'unknown or duplicate approval role')
        identity(approval['actor'],p+'/actor')
        require(approval['actor'] not in actors,'APPROVAL',p,'review must be independent')
        require(approval['decision']=='APPROVE_DRY_RUN' and approval['record_sha256']==bound,'APPROVAL',p,'stale or non-dry-run approval')
        if approval['role']=='owner':require(approval['actor']==record['owner'],'APPROVAL',p,'owner approval identity differs')
        inputs.get(approval['evidence'],p+'/evidence');roles.add(approval['role']);actors.add(approval['actor'])
    require({'owner','reviewer'}<=roles and (not security or 'security' in roles),'APPROVAL','/approvals','required approval role missing')
    inputs.recheck()
    return dict(schema=1,id=record['id'],mode='DRY_RUN',decision='VALID',record_sha256=bound,
                compatibility_vector=classified,required_bump=minimum,security_review_required=security,
                proposed_version=record['proposed_version'],edition=edition,stability=stability,support=support,
                evidence={k:inputs.pins[k] for k in sorted(inputs.pins)},release_authorized=False,files_changed=0)
