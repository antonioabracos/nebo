"""Local performance measurements and fail-closed, comparable regression gates.

A measurement is evidence about a declared command and oracle, never a universal
speed claim. Callers freeze policy before collection and retain raw samples.
"""
import datetime
import hashlib
import json
import math
import os
from pathlib import Path
import platform
import resource
import select
import shutil
import signal
import statistics
import subprocess
import tempfile
import time

SCHEMA = 'NEBO-PERFORMANCE-v1'
METHOD = dict(warmup=1, repetitions=7, percentile='nearest-rank',
              clock='monotonic_ns', rss='GNU-time-child-maxrss-KiB',
              cold='fresh-process-and-output; OS page cache uncontrolled',
              warm='one discarded execution; no global cache manipulation',
              timeout_seconds=30, address_space_bytes=1073741824,
              output_bytes=16777216, open_files=256, noise_relative=.30, noise_floor_ns=5000000,
              variance_relative=.20, variance_floor_ns=20000000)

class MeasurementError(ValueError):
    pass

def canonical(value):
    return (json.dumps(value,sort_keys=True,separators=(',', ':'),allow_nan=False)+'\n').encode()

def digest(value):
    return hashlib.sha256(value).hexdigest()

def number(value):
    if isinstance(value,bool) or not isinstance(value,(int,float)) or not math.isfinite(value) or value < 0:
        raise MeasurementError('NEBO-PERF-NUMBER')
    return value

def summarize(samples):
    if not isinstance(samples,list) or not 3 <= len(samples) <= 31:
        raise MeasurementError('NEBO-PERF-SAMPLES')
    ordered=sorted(number(x) for x in samples); median=statistics.median(ordered)
    return dict(count=len(samples),median=median,p95=ordered[math.ceil(.95*len(ordered))-1],
                mad=statistics.median(abs(x-median) for x in ordered),minimum=ordered[0],maximum=ordered[-1])

def manifest(repo, sources):
    cpu=Path('/proc/cpuinfo').read_text()
    cpu_model=next(x.split(':',1)[1].strip() for x in cpu.splitlines() if x.startswith('model name'))
    tools={}
    for name in ('nasm','ld','python3','ninja','time','objcopy'):
        path=Path(shutil.which(name)).resolve(); tools[name]=dict(path=str(path),sha256=digest(path.read_bytes()))
    affinity=sorted(os.sched_getaffinity(0))
    governors=[]
    for cpu_id in affinity:
        path=Path(f'/sys/devices/system/cpu/cpu{cpu_id}/cpufreq/scaling_governor')
        governors.append(path.read_text().strip() if path.exists() else 'unavailable')
    environment=dict(machine=platform.machine(),kernel=platform.release(),cpu_model=cpu_model,
                     affinity=affinity,governors=sorted(set(governors)),page_size=os.sysconf('SC_PAGE_SIZE'),
                     cpu_count=os.cpu_count(),memory_total_kib=int(next(x.split()[1] for x in
                     Path('/proc/meminfo').read_text().splitlines() if x.startswith('MemTotal:'))),
                     tools=tools,method=METHOD,instrument_sha256=digest(Path(__file__).read_bytes()),target='x86_64-systemv-elf-linux')
    return dict(schema=SCHEMA,environment=environment,compatibility=digest(canonical(environment)),
                compiler_sha256=digest((repo/'build/bin/neboc').read_bytes()),
                sources={p.name:digest(p.read_bytes()) for p in sources},
                timestamp=datetime.datetime.now(datetime.timezone.utc).isoformat(),
                load_average=os.getloadavg(),os_page_cache='uncontrolled')

def measure(argv, cwd, *, expected=0, stdout=b'', env=None, oracle=None, repetitions=7):
    if not 3 <= repetitions <= 31: raise MeasurementError('NEBO-PERF-SAMPLES')
    cwd=Path(cwd)
    selected=dict(PATH='/usr/bin:/bin',HOME=str(cwd),TMPDIR=str(cwd),LC_ALL='C',LANG='C',TZ='UTC',PYTHONDONTWRITEBYTECODE='1')
    selected.update(env or {})
    def limits():
        resource.setrlimit(resource.RLIMIT_CORE,(0,0))
        resource.setrlimit(resource.RLIMIT_AS,(METHOD['address_space_bytes'],)*2)
        resource.setrlimit(resource.RLIMIT_CPU,(31,31))
        resource.setrlimit(resource.RLIMIT_FSIZE,(METHOD['output_bytes'],)*2)
        resource.setrlimit(resource.RLIMIT_NOFILE,(256,256))
    values=[]; rss=[]; cpu=[]
    for i in range(repetitions+1):
        with tempfile.TemporaryDirectory(prefix='.measurement-',dir=cwd) as directory:
            work=Path(directory)
            with (work/'stdout').open('wb') as out,(work/'stderr').open('wb') as err:
                started=time.monotonic_ns()
                p=subprocess.Popen(['/usr/bin/time','-f','%M %U %S','-o',str(work/'usage'),'--',*map(str,argv)],
                    cwd=cwd,env=selected,stdin=subprocess.DEVNULL,stdout=out,stderr=err,preexec_fn=limits,start_new_session=True)
                fd=os.pidfd_open(p.pid)
                try:
                    poll=select.poll();poll.register(fd,select.POLLIN)
                    if not poll.poll(METHOD['timeout_seconds']*1000):
                        raise MeasurementError('NEBO-PERF-TIMEOUT')
                    p.wait()
                finally:
                    os.close(fd)

                    try:os.killpg(p.pid,signal.SIGKILL)
                    except ProcessLookupError:pass
                    p.wait()
                elapsed=time.monotonic_ns()-started
            raw=(work/'stdout').read_bytes(); error=(work/'stderr').read_bytes()
            if p.returncode != expected or raw != stdout or error:
                raise MeasurementError(f'NEBO-PERF-ORACLE rc={p.returncode} stdout={raw[:200]!r} stderr={error[-4000:]!r}')
            if oracle:oracle()
            usage=(work/'usage').read_text().strip().splitlines()[-1].split()
            if len(usage)!=3: raise MeasurementError('NEBO-PERF-RUSAGE')
            if i:
                values.append(elapsed);rss.append(int(usage[0])*1024);cpu.append(round((float(usage[1])+float(usage[2]))*1e9))
    return dict(wall_ns=values,peak_rss_bytes=rss,cpu_ns=cpu,statistics=summarize(values),
                warmup=1,oracle=dict(exit=expected,stdout_sha256=digest(stdout)))

def compare(baseline, current, budgets, waivers, today, approvals=()):
    """No implicit waiver; every metric needs a finite threshold and explanation.

    Waivers are externally approved, exact metric/scope/digest records with an
    expiry <=30 days after issuance. The evaluator cannot mint an approval.
    """
    if not all(isinstance(x,dict) for x in (baseline,current,budgets)) or not isinstance(waivers,list):
        raise MeasurementError('NEBO-PERF-SCHEMA')
    for report in (baseline,current):
        if report.get('schema') != SCHEMA or not isinstance(report.get('metrics'),dict) or not report['metrics']:
            raise MeasurementError('NEBO-PERF-SCHEMA')
        manifest=report.get('manifest',{})
        if (not isinstance(manifest,dict) or not isinstance(manifest.get('environment'),dict) or
            not {'cpu_model','kernel','machine','affinity','memory_total_kib','tools','method','target','instrument_sha256'} <= set(manifest['environment']) or
            manifest.get('compatibility') != digest(canonical(manifest.get('environment')))):
            raise MeasurementError('NEBO-PERF-MANIFEST')
    if baseline['manifest']['compatibility'] != current['manifest']['compatibility']:
        raise MeasurementError('NEBO-PERF-INCOMPARABLE')
    bm,cm=baseline['metrics'],current['metrics']
    if set(bm)!=set(cm) or set(cm)!=set(budgets): raise MeasurementError('NEBO-PERF-COVERAGE')
    day=datetime.date.fromisoformat(today); approved={}
    for waiver in waivers:
        try:
            if digest(canonical(waiver)) not in approvals:raise ValueError()
            key=waiver['metric']; issued=datetime.date.fromisoformat(waiver['issued']);expiry=datetime.date.fromisoformat(waiver['expiry'])
            if (key in approved or key not in cm or not waiver['owner'] or not waiver['approval'] or
                not waiver['reason'] or waiver['baseline_sha256']!=digest(canonical(baseline)) or
                not issued<=day<=expiry or (expiry-issued).days>30):raise ValueError()
            approved[key]=number(waiver['maximum'])
        except (KeyError,ValueError,TypeError):raise MeasurementError('NEBO-PERF-WAIVER')
    result=[]
    for key in sorted(cm):
        b,c=bm[key],cm[key]; policy=budgets[key]
        if not all(isinstance(x,dict) for x in (b,c,policy)):
            raise MeasurementError('NEBO-PERF-SCHEMA')
        if b.get('unit')!=c.get('unit') or c.get('unit') not in ('ns','bytes','count'):
            raise MeasurementError('NEBO-PERF-UNIT')
        old,new=number(b['value']),number(c['value'])
        relative=number(policy['relative']);floor=number(policy['floor']);absolute=number(policy['absolute'])
        if relative>1 or not policy.get('classification'):raise MeasurementError('NEBO-PERF-POLICY')
        threshold=min(absolute,old*(1+relative)+floor)
        exceeded=new>threshold
        waived=exceeded and new<=approved.get(key,-1)
        result.append(dict(metric=key,baseline=old,current=new,delta=new-old,threshold=threshold,
                           classification=policy['classification'],status='WAIVED' if waived else 'BLOCK' if exceeded else 'PASS'))
    return dict(schema=SCHEMA,status='BLOCK' if any(x['status']=='BLOCK' for x in result) else 'PASS',rows=result)
