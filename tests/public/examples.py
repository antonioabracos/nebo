#!/usr/bin/env python3
"""Execute admitted public examples against fixed source and result oracles."""
import argparse, hashlib, json, subprocess, sys, tempfile
from pathlib import Path
ROOT = Path(__file__).resolve().parents[2]
sys.path[:0] = [str(ROOT), str(ROOT/'tests/rf204/G170')]
from harness import pipeline
from compiler.sdk import package_manager as pkg

def sha(raw): return hashlib.sha256(raw).hexdigest()

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--report',type=Path,required=True);args=parser.parse_args()
    rows=json.loads((ROOT/'tests/public/example-oracles.json').read_bytes())['cases'];results=[]
    compiler=ROOT/'build/bin/neboc'
    with tempfile.TemporaryDirectory(prefix='nebo-public-examples-') as directory:
        work=Path(directory)
        env=dict(PATH='/usr/bin:/bin',LANG='C',LC_ALL='C',TZ='UTC',NEBO_CONSOLE_TRACE='1')
        for i,row in enumerate(rows):
            source=ROOT/row['path'];assert sha(source.read_bytes())==row['source_sha256']
            out=work/'program';assembly=work/'program.asm'
            for argv in ([compiler,'check',source],[compiler,'emit-asm',source,'-o',assembly],[compiler,'build',source,'-o',out,'--quiet']):
                observed=subprocess.run(list(map(str,argv)),capture_output=True,timeout=15,env=env,cwd=work)
                assert observed.returncode==0 and not observed.stderr,(row['path'],observed.stderr)
            observed=subprocess.run([str(out)],capture_output=True,timeout=15,env=env,cwd=work)
            assert observed.returncode==row['expected_exit'] and not observed.stderr,(row['path'],observed.returncode)
            assert sha(observed.stdout)==row['stdout_sha256'],row['path']
            results.append(dict(path=row['path'],status='PASS',exit=observed.returncode))
        projects=ROOT/'docs/public/v1.0/examples/projects'
        for context_file in sorted(projects.glob('*/context.json')):
            context=json.loads(context_file.read_bytes());source=context_file.parent/'main.no'
            case=work/context_file.parent.name;case.mkdir();options={}
            if 'units' in context: options['units']=[context_file.parent/name for name in context['units']]
            for key in ('inputs','expected_files'):
                if key in context:options[key]={name:bytes.fromhex(v['bytes_hex']) for name,v in context[key].items()}
            if 'kinds' in context:options.update(kinds=context['kinds'],text=bytes.fromhex(context['text']['bytes_hex']))
            pipeline(source,case,context['expected_exit'],**options)
            results.append(dict(path=source.relative_to(ROOT).as_posix(),status='PASS',exit=context['expected_exit']))
        store=work/'store';pkg.freeze(projects/'packages/workspace.json',store)
        lock=(store/'nebo.lock.json').read_bytes();pkg.verify(store,lock,sha(lock));output=work/'package-consumer'
        pkg.restore(store,lock,sha(lock),output,build=True)
        observed=subprocess.run([str(output/'bin/program')],capture_output=True,timeout=15)
        assert observed.returncode==108 and not observed.stdout and not observed.stderr
        results.append(dict(path='docs/public/v1.0/examples/projects/packages/workspace.json',status='PASS',exit=108))
    args.report.write_text(json.dumps(dict(status='PASS',passed=len(results),total=len(results),cases=results),indent=2)+'\n')
    print('PUBLIC_EXAMPLES='+str(len(results))+'/'+str(len(results))+' PASS')

if __name__=='__main__':main()
