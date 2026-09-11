"""Read-only projections of material native interfaces and frozen artifacts."""
import importlib.util
import struct
import sys
from pathlib import Path
from compiler.compat import structural as s

ROOT=Path(__file__).resolve().parents[2]


def owner(name, path):
    if name not in sys.modules:
        spec=importlib.util.spec_from_file_location(name,ROOT/path)
        module=importlib.util.module_from_spec(spec);sys.modules[name]=module;spec.loader.exec_module(module)
    return sys.modules[name]


def ni_projection(data):
    codec=owner('nebo_compat_native_ni','tools/rf204-g154.py')
    try:
        meta=codec.interface_report(data,'<compatibility interface>')
        exports,metadata=codec.records_from_validated(data,codec.native_inspect(data,'<compatibility interface>'))
    except codec.InterfaceError as error:
        raise s.Invalid('/interface',error.code) from error
    require=s.require
    require(meta['target']==codec.TARGET,'/interface/target','unsupported native target')
    # Native layoutDigest is an opaque layout identity, never a source-derived layout.
    symbols={str(r['symbolId']):r for r in meta['symbolRecords']}
    return dict(schema=meta['schema'],edition=meta['edition'],target=meta['target'],module_id=meta['moduleId'],
        exports=symbols,dependencies={str(r[0]):list(r[5:8]) for r in metadata},
        material_value=meta['materialModuleValue'],optional_sections=meta['unknownOptionalSections'],
        fingerprints={k:meta[k] for k in ('apiFingerprint','abiFingerprint','behaviorFingerprint','typedHirDigest')})


def compare_ni(before, after):
    b,a=ni_projection(before),ni_projection(after); changes=[]
    def add(dimension,identity,field,old,new,classification,bump,reason):
        changes.append(dict(dimension=dimension,identity=identity,field=field,before=old,after=new,
            classification=classification,required_bump=bump,reason=reason))
    for field in ('schema','edition','target','module_id','dependencies','material_value','optional_sections'):
        if s.equal(b[field],a[field]):continue
        cls,bump,reason=('COMPATIBLE','NONE','native reader accepts and skips optional sections') if field=='optional_sections' else ('REVIEW_REQUIRED','NONE','dependency fingerprints need the referenced structural contracts') if field=='dependencies' else ('BREAKING','MAJOR','native serialized contract changed')
        add('ni','interface',field,b[field],a[field],cls,bump,reason)
    for sid in sorted(b['exports'].keys()|a['exports'].keys()):
        old,new=b['exports'].get(sid),a['exports'].get(sid)
        if old is None or new is None:
            add('api',sid,'/',old,new,'COMPATIBLE' if old is None else 'BREAKING','MINOR' if old is None else 'MAJOR','native export identity added or removed');continue
        for field in sorted(old):
            if s.equal(old[field],new[field]):continue
            dim='abi' if field=='layoutDigest' else 'ni' if field=='docDigest' else 'api'
            if field=='docDigest':cls,bump,reason='COMPATIBLE','NONE','documentation identity changed'
            elif field in ('typeDigest','layoutDigest','constantDigest'):
                if field=='constantDigest' and b['material_value'] is not None and a['material_value'] is not None:
                    cls,bump,reason='BREAKING','MAJOR','constant change corroborated by native typed payload'
                else:cls,bump,reason='REVIEW_REQUIRED','NONE','opaque type/layout/value identity requires structural evidence'
            elif field in ('effects','capabilities') and not new[field]&~old[field]:cls,bump,reason='COMPATIBLE','MINOR','required effect bits reduced'
            else:cls,bump,reason='BREAKING','MAJOR','native export contract changed'
            add(dim,sid,field,old[field],new[field],cls,bump,reason)
    if not changes and not s.equal(b['fingerprints'],a['fingerprints']):
        add('ni','interface','fingerprints',b['fingerprints'],a['fingerprints'],'REVIEW_REQUIRED','NONE','unexplained native fingerprint drift')
    return s.report(changes,s.digest(b),s.digest(a),'NATIVE_NI',('api','abi','ni'))


def compare_freeze(kind, before_path, after_path):
    freeze=owner('nebo_compat_freeze','scripts/rf204/freeze_diff.py')
    b,a=s.read_path(before_path),s.read_path(after_path)
    left,right=freeze.project(Path(before_path),b),freeze.project(Path(after_path),a)
    changes=[]
    for c in freeze.changes(left,right):
        changes.append(dict(dimension={'manifest':'package','diagnostic':'diagnostics'}.get(kind,kind),
            identity='freeze',field=c['path'],before=c['before'],after=c['after'],
            classification='REVIEW_REQUIRED',required_bump='NONE',
            reason='freeze structural drift requires a complete typed compatibility contract'))
    section={'manifest':'package','diagnostic':'diagnostics'}.get(kind,kind)
    return s.report(changes,s.digest(left),s.digest(right),'FREEZE_STRUCTURE',(section,))


def compare_packages(before_path, after_path):
    from compiler.sdk import package_manager as packages
    def project(path):
        path=Path(path)
        raw=s.read_path(path/packages.LOCK)
        sha=packages.sha(raw)
        lock,manifests,payloads=packages.load_store(path,raw,sha)
        packages.verify(path,raw,sha)
        return lock,manifests,payloads
    b,bm,bp=project(before_path);a,am,ap=project(after_path);changes=[]
    freeze=owner('nebo_compat_freeze','scripts/rf204/freeze_diff.py')
    for field in ('root','entry','edition','target','features','toolchain','packages','package_order','module_order'):
        for c in freeze.changes(b[field],a[field]):
            changes.append(dict(dimension='package',identity='verified-store',field=field+c['path'],
                before=c['before'],after=c['after'],classification='BREAKING',required_bump='MAJOR',
                reason='exact lock/store consumer contract changed'))
    for pid in sorted(bp.keys() & ap.keys()):
        for name in sorted(bp[pid].keys() & ap[pid].keys()):
            if name.endswith('.ni'):
                for c in compare_ni(bp[pid][name],ap[pid][name])['changes']:
                    changes.append(dict(c,identity=pid+'/'+name+':'+c['identity']))
    return s.report(changes,s.digest(b),s.digest(a),'NATIVE_PACKAGE',('api','abi','ni','package','target'))
