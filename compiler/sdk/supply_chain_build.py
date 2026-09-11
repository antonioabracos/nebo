"""Rebuild a previously authenticated source closure with installed host tools.

The caller must verify and restore the pinned source archive first. This command
executes that trusted build recipe, so it is separate from read-only verification.
"""
import json,subprocess,sys,tempfile
from pathlib import Path
from compiler.sdk import supply_chain as chain, sdk_builder as sdk, package_manager as pkg

def build(root,output):
    root=Path(root).absolute();output=Path(output).absolute()
    chain.require(root==Path(__file__).resolve().parents[2],'RELOCATED_OWNER_REQUIRED')
    p=chain.validate_provenance(chain.decode(chain.read(root,chain.PROVENANCE)[0]))
    chain.require(not (root/'build').exists(),'CLEAN_BUILD_REQUIRED')
    chain.require(not output.exists() and not output.is_symlink(),'DESTINATION_EXISTS')
    chain.require(not output.is_relative_to(root),'OUTPUT_OVERLAP')
    for row in p['inputs']:
        raw,mode=chain.read(root,row['path']);chain.require(sha(raw)==row['sha256'] and format(mode,'04o')==row['mode'],'SOURCE_CHANGED')
    chain.require(chain.tools()==p['toolchain'],'HOST_TOOLCHAIN_DRIFT')
    proc=subprocess.run(['ninja','-j2',*sdk.NATIVE],cwd=root,capture_output=True,timeout=180)
    chain.require(proc.returncode==0,'NATIVE_BUILD: '+(proc.stdout+proc.stderr)[-3000:].decode(errors='replace'))
    return compose(root,output,p)

def compose(root,output,p):
    """Publish all profiles together, preserving the destination on failure."""
    root=Path(root).absolute();output=Path(output).absolute()
    chain.require(not output.exists() and not output.is_symlink(),'DESTINATION_EXISTS')
    sdk.prepare_parent(output)
    with tempfile.TemporaryDirectory(prefix='.nebo-supply-profiles-',dir=output.parent) as tmp:
        stage=Path(tmp)/'profiles';stage.mkdir()
        subjects=[]
        for profile in ('sdk','docs','tooling'):
            bundle=stage/profile;sdk.build_bundle(root,bundle,root/'build/bin/neboc',profile)
            subjects.append(chain.archive(bundle,stage/(profile+'.tar'),profile,p))
        package=stage/'package';package.mkdir()
        chain.require(p['package_workspace'] is not None,'PACKAGE_WORKSPACE')
        pkg.freeze(root/p['package_workspace'],package/'store')
        chain.write(package,'LICENSE',chain.read(root,'LICENSE')[0])
        for name in ('THIRD-PARTY-NOTICES.md','NeboConsoleMonoAtlas-OFL-1.1.md','NeboConsoleMonoAtlas-PROVENANCE.md'):
            chain.write(package,name,chain.read(root,'sdk/nebo-1.0/licenses/'+name)[0])
        subjects.append(chain.archive(package,stage/'package.tar','package',p))
        result=dict(native={n:sha((root/n).read_bytes()) for n in sdk.NATIVE},subjects=subjects)
        chain.write(stage,'BUILD.json',chain.canonical(result))
        pkg.publish(stage,output);return result

def sha(raw):return chain.sha(raw)
if __name__=='__main__':
    try:build(Path(sys.argv[1]),Path(sys.argv[2]))
    except (ValueError,OSError,subprocess.SubprocessError) as e:sys.exit(str(e))
