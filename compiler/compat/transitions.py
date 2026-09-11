"""Read-only admission for bounded local compatibility transitions.

Release versions, source Editions and serialized schemas are separate axes.
Successful admission is scoped evidence, never an assertion that arbitrary
historical programs preserve behavior or that a release may be published.
"""
from __future__ import annotations
import argparse
import json
import re
import sys
from pathlib import Path
from compiler.sdk import package_manager as package
from compiler.migration import semantic_migration as migration
from compiler.compat.artifacts import ni_projection

FORMAT = 'NEBO-COMPAT-TRANSITION-v1'
from compiler.sdk.version_identity import VERSION as CURRENT
VERSION = re.compile(r'(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)(?:-rc\.([1-9][0-9]*))?')


class TransitionError(ValueError):
    def __init__(self, code, path, pointer, message, remediation, *, related=(), native=''):
        self.diagnostic = dict(code='NEBO_COMPAT_'+code, phase='compatibility', severity='error',
            location=dict(path=str(path), pointer=pointer), related_locations=list(related),
            message=message, required_tool='neboc', required_version=CURRENT,
            remediation=remediation, native_diagnostic=native, mutated=False, release_authorized=False)
        match=re.search(r':([0-9]+):([0-9]+): error ([A-Za-z0-9_-]+)',native)
        if match:
            self.diagnostic['location'].update(line=int(match[1]),column=int(match[2]))
            self.diagnostic['native_code']=match[3]
        super().__init__(message)


def fail(code, path, pointer, message, remediation, **kw):
    raise TransitionError(code, path, pointer, message, remediation, **kw)


def direction(old, new, path):
    def parse(value):
        match=VERSION.fullmatch(value) if isinstance(value,str) and len(value)<=64 else None
        if not match:fail('VERSION',path,'/version','Invalid bounded release version.','Use MAJOR.MINOR.PATCH or MAJOR.MINOR.PATCH-rc.N.')
        parts=match.groups();values=tuple(int(x) for x in parts[:3])
        if any(x>65535 for x in values) or parts[3] and int(parts[3])>65535:
            fail('VERSION',path,'/version','Release version exceeds bounds.','Use components at most 65535.')
        return (*values,1 if parts[3] is None else 0,int(parts[3] or 0))
    before,after=parse(old),parse(new)
    if after<before:fail('DOWNGRADE',path,'/to_version','Implicit downgrade is unsupported.',
        'Restore the verified source journal, exact lock/cache and retained SDK rollback point; do not down-convert .ni.')
    if new!=CURRENT or before[:2] not in ((0,1),(0,2),(1,0),(1,1)) or before>parse(CURRENT):
        fail('UNSUPPORTED_VERSION',path,'/to_version','Transition is outside the current local support window.',
             f'Use a supported 0.1, 0.2, 1.0 or 1.1 baseline and target {CURRENT}; retain the original bytes.')
    return 'SAME_VERSION' if before==after else 'UPGRADE'


def inspect(kind, path, old, new, *, store=None, lock_sha256=None):
    path=Path(path).absolute();way=direction(old,new,path)
    try:
        raw=package.read(path.parent,path.name,package.MAX_FILE)
        proof={}
        if kind=='source':
            plan=migration.plan_files([path],root=path.parent)
            if plan['files'][0]['sha256_before']!=package.sha(raw):raise ValueError('source changed during admission')
            proof=dict(plan_id=plan['plan_id'],files=plan['files'],verification=plan.get('verification',{}))
            decision='SOURCE_VERIFIED_REPLAY_REQUIRED'
        elif kind=='ni':
            try:proof=ni_projection(raw)
            except ValueError as error:
                fail('NI_REBUILD_REQUIRED',path,'/schema','The native interface reader rejected this serialized interface.',
                     'Recover the matching source and dependencies, then run neboc emit-interface with the required tool; preserve the old .ni.',native=str(error))
            decision='NATIVE_INTERFACE_VERIFIED'
        elif kind=='lock':
            try:
                value=package.decode(raw)
                if not isinstance(value,dict) or value.get('schema')!=package.LOCK_SCHEMA:raise ValueError('legacy lock schema')
            except ValueError as error:
                fail('LOCK_RELOCK_REQUIRED',path,'/schema','Lock cannot be interpreted by the current resolver.',
                     'Preserve this lock. Reconstruct explicit package manifests and pins from authenticated sources, then neboc package freeze into a fresh store.',native=str(error))
            if store is None or lock_sha256 is None:
                fail('LOCK_EVIDENCE',path,'/lock_sha256','Lock verification requires its independently supplied digest and store.',
                     'Supply --store and --lock-sha256; a self-hashed lock is not a trusted pin.')
            proof=package.verify(Path(store),raw,lock_sha256);decision='LOCK_STORE_VERIFIED'
        elif kind=='workspace':
            workspace=package.decode(raw)
            if not isinstance(workspace,dict) or workspace.get('schema')!=package.WORKSPACE_SCHEMA:
                fail('WORKSPACE_SCHEMA',path,'/schema','Legacy workspace needs an explicit manifest migration.',
                     'Keep the old workspace and create a current workspace with explicit members, root, entry and exact dependency pins.')
            # Give useful member locations before the strict native owner checks
            # the complete graph. No Edition is silently converted to another.
            members=workspace.get('members')
            if not isinstance(members,list) or not 1<=len(members)<=3:raise ValueError('workspace member bound')
            locations=[]
            for member in members:
                package.relative(member)
                manifest_path=path.parent/member/package.MANIFEST
                item=package.decode(package.read(manifest_path.parent,manifest_path.name,package.MAX_JSON))
                location=dict(path=str(manifest_path),pointer='/edition');locations.append(location)
                if not isinstance(item,dict) or item.get('edition')!='1':
                    fail('EDITION_BOUNDARY',manifest_path,'/edition','Only materialized source Edition 1 may cross this package boundary.',
                         'Migrate and verify the dependency source under Edition 1, rebuild its native .ni and explicitly freeze new pins; older readers cannot consume newer schemas.',related=locations[:-1]+[dict(path=str(path),pointer='/members')])
            _,entry,manifests,payloads=package.workspace(path)
            from compiler.migration.project import workspace_check
            workspace_check(path.parent,path.name)
            proof=dict(package_order=package.graph(manifests,workspace['root']),entry=entry,
                       editions={pid:m['edition'] for pid,m in sorted(manifests.items())})
            decision='WORKSPACE_VERIFIED'
        else:raise ValueError('unknown transition kind')
    except TransitionError:raise
    except (ValueError,OSError,KeyError,TypeError) as error:
        code='SOURCE_MIGRATION_REQUIRED' if kind=='source' else 'PACKAGE_REBUILD_REQUIRED' if kind=='lock' else 'INPUT'
        fail(code,path,'/','Admission failed; no input was modified.',
             'Retain the baseline and resolve the attached native diagnostic. Preview neboc migrate for source; explicitly rebuild interfaces and relock packages in a new root.',native=str(error))
    return dict(format=FORMAT,kind=kind,from_version=old,to_version=new,direction=way,
                input_sha256=package.sha(raw),decision=decision,proof=proof,
                behavior_compatibility='UNASSESSED_REQUIRES_INDEPENDENT_REPLAY',mutated=False,release_authorized=False)


def main(argv=None):
    p=argparse.ArgumentParser(prog='nebo-compat-transition')
    p.add_argument('kind',choices=('source','ni','lock','workspace'));p.add_argument('path',type=Path)
    p.add_argument('--from-version',required=True);p.add_argument('--to-version',required=True)
    p.add_argument('--store',type=Path);p.add_argument('--lock-sha256')
    a=p.parse_args(argv)
    try:result=inspect(a.kind,a.path,a.from_version,a.to_version,store=a.store,lock_sha256=a.lock_sha256)
    except TransitionError as error:
        sys.stderr.buffer.write(package.canonical(error.diagnostic));return 2
    sys.stdout.buffer.write(package.canonical(result));return 0


if __name__=='__main__':raise SystemExit(main())
