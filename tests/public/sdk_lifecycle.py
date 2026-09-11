#!/usr/bin/env python3
"""Two clean source-closure builds, independent inventories and SDK lifecycle."""
import argparse,copy,hashlib,json,os,subprocess,sys,tempfile
from pathlib import Path
ROOT=Path(__file__).resolve().parents[2]
sys.path[:0]=[str(ROOT),str(ROOT/'tests/public')]
from support import process,independent,EXAMPLES,WORKSPACE
from compiler.sdk import supply_chain as chain,sdk_builder as sdk,sdk_lifecycle as life
from compiler.sdk.version_identity import CURRENT

def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def inventory(root):
    return {p.relative_to(root).as_posix():dict(sha256=sha(p),mode=oct(p.stat().st_mode&0o777)) for p in root.rglob('*') if p.is_file()}
def name_assets(work, result):
    recipe=json.loads((ROOT/'version/RELEASE-ASSET-NAMES.json').read_bytes())
    assert recipe['version']==CURRENT['version'] and recipe['edition']==CURRENT['edition']
    assets=work/'assets';assets.mkdir(mode=0o700);rows=[]
    for asset in recipe['assets']:
        profile=asset['profile'];name=asset['name'];assert '/' not in name and name.startswith('nebo-'+CURRENT['version']+'-')
        original=work/'source.tar' if profile=='source' else work/'profiles-0'/(profile+'.tar')
        destination=assets/name;original.rename(destination)
        subject=next(s for s in result['subjects'] if s['profile']==profile)
        assert sha(destination)==subject['sha256'];chain.verify(destination,subject['sha256'],profile)
        rows.append(dict(name=name,profile=profile,sha256=sha(destination),bytes=destination.stat().st_size))
    result['named_assets']=rows
    result['cases'].append(dict(id='release-asset-filenames-and-digests',status='PASS',assets=rows))

def main():
    ap=argparse.ArgumentParser();ap.add_argument('--old-sdk',type=Path);ap.add_argument('--work',type=Path,required=True);ap.add_argument('--report',type=Path,required=True);a=ap.parse_args()
    work=a.work.resolve();work.mkdir(mode=0o700);work.chmod(0o700);rows=[]
    import shutil
    assert shutil.disk_usage(work).free >= 2*1024**3, 'Insufficient temporary capacity for two clean builds'
    def note(name,**facts):rows.append(dict(id=name,status='PASS',**facts));print(name,flush=True)
    source=work/'source';examples=[*EXAMPLES,'examples/evolution/g10-array-int4.no']
    provenance=chain.snapshot(ROOT,source,examples,chain.tools(),package_workspace=WORKSPACE)
    source_archive=work/'source.tar';subject=chain.archive(source,source_archive,'source',provenance)
    independent(source_archive,'source');builds=[]
    note('source-closure-authenticated',inputs=len(provenance['inputs']),input_digest=provenance['input_digest'])
    for variant in range(2):
        root=work/f'clean-{variant}';out=work/f'profiles-{variant}'
        chain.restore(source_archive,root,subject['sha256'])
        process(['/usr/bin/python3','-B','-m','compiler.sdk.supply_chain_build',root,out],root,variant=variant,allowed=(root,out.parent),timeout=240)
        build=json.loads((out/'BUILD.json').read_bytes());builds.append(build)
        for profile in ('sdk','docs','tooling','package'):
            s,p=independent(out/(profile+'.tar'),profile);assert p==provenance
            chain.verify(out/(profile+'.tar'),sha(out/(profile+'.tar')),profile)
        assert subprocess.check_output([str(root/'build/bin/neboc'),'--version']).decode().strip()==CURRENT['cli']
        assert json.loads(subprocess.check_output([str(root/'build/bin/neboc'),'--version-json']))==CURRENT
        note('clean-build-'+str(variant),native=build['native'],subjects=build['subjects'])
    assert builds[0]==builds[1]
    assert builds[0]['native']=={n:sha(ROOT/n) for n in sdk.NATIVE}
    other=work/'source-again.tar';chain.archive(source,other,'source',provenance);assert sha(other)==sha(source_archive)
    for profile in ('sdk','docs','tooling','package'):assert sha(work/'profiles-0'/(profile+'.tar'))==sha(work/'profiles-1'/(profile+'.tar'))
    note('two-roots-byte-identical',archives=5,native_outputs=len(sdk.NATIVE),variations=['locale','timezone','umask','source-date-epoch','physical-root'])
    candidate=work/'profiles-0/sdk';manifest=sdk.verify_bundle(candidate)
    assert manifest['version']==CURRENT['version']
    for name in ('SBOM.json','PROVENANCE.json'):
        metadata=json.loads((candidate/name).read_bytes());assert metadata['version']==CURRENT['version'] and metadata['edition']==CURRENT['edition']
    note('sdk-manifest-sbom-provenance',files=len(manifest['files']))
    for name in ('SBOM.json','PROVENANCE.json'):
        path=candidate/name;original=path.read_bytes();manifest_path=candidate/'MANIFEST.json';original_manifest=manifest_path.read_bytes()
        try:
            bad=json.loads(original);bad['version']='9.9.9';path.write_bytes(sdk.canonical(bad))
            revised=copy.deepcopy(manifest)
            for row in revised['files']:
                if row['path']==name:row.update(sha256=sha(path),size=path.stat().st_size)
            manifest_path.write_bytes(sdk.canonical(revised))
            try:sdk.verify_bundle(candidate)
            except ValueError as error:assert 'product metadata identity' in str(error),str(error)
            else:raise AssertionError('rehashed metadata drift accepted')
            note('rehashed-'+name+'-version-drift-rejected')
        finally:path.write_bytes(original);manifest_path.write_bytes(original_manifest)

    if a.old_sdk is not None:
        prefix=work/'installed';life.install(a.old_sdk,prefix);before=inventory(prefix);installed=life.verify_install(prefix)
        # Admission adversaries use verified inventory shapes with one changed field.
        def denied(name,candidate_manifest,**kwargs):
            try:life.compatible_sdk(installed,candidate_manifest,**kwargs)
            except ValueError:note(name)
            else:raise AssertionError('known bad accepted: '+name)
        kwargs=dict(installed_root=prefix,candidate_root=candidate)
        bad=copy.deepcopy(manifest);bad['profile']='tooling';denied('cross-profile-rejected',bad,**kwargs)
        bad=copy.deepcopy(manifest);bad['version']='9.9.9';denied('identity-spoof-rejected',bad,**kwargs)
        bad=copy.deepcopy(manifest);bad['files']=[r for r in bad['files'] if r['path']!='share/nebo/freeze/SYMBOLID-EXPORT-INVENTORY.tsv'];denied('missing-public-inventory-rejected',bad,**kwargs)
        denied('cross-version-without-identities-rejected',manifest)
        assert inventory(prefix)==before
        assert life.upgrade(prefix,candidate)==dict(active=CURRENT['version'],rollback='1.0.1')
        assert life.verify_install(prefix)['version']==CURRENT['version']
        assert subprocess.check_output([str(prefix/'bin/neboc'),'--version']).decode().strip()==CURRENT['cli']
        source_test=ROOT/'tests/public/public-1.0.1-array.no';executable=work/'array.elf'
        for command in ([str(prefix/'bin/neboc'),'check',str(source_test)], [str(prefix/'bin/neboc'),'build',str(source_test),'-o',str(executable),'--quiet']):subprocess.run(command,check=True,capture_output=True,timeout=30)
        assert subprocess.run([str(executable)]).returncode==5
        note('installed-sdk-1.0.1-to-current-upgrade',old='1.0.1',new=CURRENT['version'],original_array_result=5)
        assert life.rollback(prefix)==dict(active='1.0.1');assert inventory(prefix)==before
        note('rollback-byte-and-mode-exact',files=len(before))
        assert not life.uninstall(prefix)['preserved'];assert not prefix.exists()
        life.install(candidate,prefix);life.verify_install(prefix);assert not life.uninstall(prefix)['preserved'];assert not prefix.exists()
        note('old-and-new-sdk-install-verify-uninstall')
    else:
        prefix=work/'installed'
        life.install(candidate,prefix);life.verify_install(prefix)
        assert not life.uninstall(prefix)['preserved'] and not prefix.exists()
        note('current-sdk-install-verify-uninstall')
    subjects=[subject,*builds[0]['subjects']];attestation=chain.attest(subjects,provenance)
    result=dict(schema='nebo.public-sdk-validation.v1',status='PASS',version=CURRENT['version'],edition=CURRENT['edition'],cases=rows,subjects=subjects,provenance=provenance,attestation=attestation,remote_mutation=False)
    name_assets(work,result)
    a.report.write_text(json.dumps(result,indent=2)+'\n')
if __name__=='__main__':main()
