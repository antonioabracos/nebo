"""Migration projection over the bounded native three-module/.ni graph.

No second Nebo parser: token positions are projected only after the complete
native graph accepts them. The present native profile has one Int export per
unit. Ambiguous homonymous exports require manual review, never global rename.
"""
from __future__ import annotations
import json, re, tempfile
from pathlib import Path
from compiler.sdk import package_manager as package
from compiler.migration.semantic_migration import native,read,decode,require,tokens,Edit,one_edit,render

def fnv(data):
    x=0xcbf29ce484222325
    for b in data:x=((x^b)*0x100000001b3)&((1<<64)-1)
    return x or 1

def graph(base,names):
    require(len(names)==3,'NATIVE_MODULE_BOUND')
    infos={}
    with tempfile.TemporaryDirectory(prefix='nebo-migrate-ni-') as raw:
        for i,n in enumerate(names):
            args=[base/n]
            for u in names:
                if u!=n:args+=['--unit',base/u]
            info=dict(line.split('=',1) for line in native(['module-info',*args],'NATIVE_MODULE').decode().splitlines())
            require(info.get('graph.units')=='3','NATIVE_MODULE_BOUND')
            interface=Path(raw)/(str(i)+'.ni')
            native(['emit-interface',*args,'-o',interface],'NATIVE_INTERFACE')
            report=decode(native(['interface','inspect',interface,'--json'],'NATIVE_INTERFACE'))
            require(report['moduleId']==int(info['module.id']),'NATIVE_INTERFACE_IDENTITY')
            info['interface']=report;infos[n]=info
    require(len({i['graph.snapshot'] for i in infos.values()})==1,'NATIVE_GRAPH_DRIFT')
    return infos

def project_inputs(root,workspace):
    raw,_=read(root,workspace);ws=decode(raw)
    # Canonical package owner validates closed fields, roots, pins and graph.
    package.workspace(root/workspace)
    names=[];metadata=[workspace]
    prefix=Path(workspace).parent
    for member in ws['members']:
        manifest=(prefix/member/package.MANIFEST).as_posix();m=package.manifest(decode(read(root,manifest)[0]))
        metadata.append(manifest)
        names.extend((prefix/member/mod['source']).as_posix() for mod in m['modules'])
    return names,metadata

def workspace_check(root,workspace):
    _,entry,manifests,payloads=package.workspace(root/workspace)
    with tempfile.TemporaryDirectory(prefix='nebo-migrate-package-') as raw:
        base=Path(raw)
        for pid,files in payloads.items():
            for name,data in files.items():
                path=base/pid/name;path.parent.mkdir(parents=True,exist_ok=True);path.write_bytes(data)
        package.analyze(base,manifests,entry)

def identifier(s):
    require(isinstance(s,str) and re.fullmatch(r'[A-Za-z_][A-Za-z0-9_]{0,31}',s),'RENAME_IDENTIFIER')
    ts=tokens(s.encode());require(len(ts)==1 and ts[0].kind==2,'RENAME_IDENTIFIER')
    return s

def project_edits(base,names,metadata,rename,module_rename,package_rename,workspace):
    require(not (package_rename and (rename or module_rename)),'RENAME_COMPOSITION')
    data={n:(base/n).read_bytes() for n in [*names,*metadata]};edits={n:[] for n in data};facts=[]
    infos=graph(base,names)
    models={n:tokens(data[n]) for n in names}
    words={n:[data[n][t.start:t.end].decode() for t in models[n]] for n in names}
    metadata_values={n:decode(data[n]) for n in metadata}
    if rename or module_rename:
        parts=(rename or module_rename).split(':')
        require(len(parts)==(3 if rename else 2),'RENAME_SELECTOR')
        require(parts[0].isdigit() and 0<int(parts[0])<1<<64,'RENAME_SELECTOR')
        mid=int(parts[0]);new=identifier(parts[-1]);owners=[n for n,i in infos.items() if int(i['module.id'])==mid]
        if not owners and module_rename:
            require(sum(i['module.logical']==new for i in infos.values())==1,'RENAME_IDENTITY')
            return edits,[dict(kind='module',module_id=mid,new_name=new,state='ALREADY_CURRENT')]
        require(len(owners)==1,'RENAME_IDENTITY');owner=owners[0];info=infos[owner]
        if rename:
            require(parts[1].isdigit() and 0<int(parts[1])<1<<64,'RENAME_SELECTOR');sid=int(parts[1])
            if int(info['module.exportSymbolId'])!=sid:
                require(int(info['module.exportSymbolId'])==fnv(new.encode()),'RENAME_IDENTITY')
                return edits,[dict(kind='api',module_id=mid,symbol_id=sid,new_name=new,state='ALREADY_CURRENT')]
            require(sum(int(i['module.exportSymbolId'])==sid for i in infos.values())==1,'HOMONYMOUS_EXPORT')
            require(all(int(i['module.exportSymbolId'])!=fnv(new.encode()) for i in infos.values()),'RENAME_COLLISION')
            candidates=[w for t,w in zip(models[owner],words[owner]) if t.kind==2 and fnv(w.encode())==sid]
            require(len(set(candidates))==1,'RENAME_IDENTITY');old=candidates[0]
            for n in names:
                ts=models[n];ws=words[n];start=ws.index('start') if 'start' in ws else len(ws)
                for i,(t,w) in enumerate(zip(ts,ws)):
                    if t.kind!=2 or w!=old:continue
                    prev=ws[i-1] if i else '';nxt=ws[i+1] if i+1<len(ws) else ''
                    declaration=(n==owner and nxt=='=')
                    reference=(i>=2 and prev=='.' and ts[i-2].kind==2 and i>=start)
                    selection=(i<start and prev in ('{',';') and nxt==';')
                    if declaration or reference or selection:edits[n].append(Edit('NEBO-MIG-API-002',f'{mid}:{sid}',t.start,t.end,old,new))
            require(any(e.before==old for e in edits[owner]),'RENAME_DECLARATION')
            facts.append(dict(kind='api',module_id=mid,symbol_id=sid,new_symbol_id=fnv(new.encode()),new_name=new,api_impact='BREAKING_EXPLICIT'))
        else:
            old=info['module.logical'];require(old!=new and all(i['module.logical']!=new for i in infos.values()),'RENAME_COLLISION')
            for n in names:
                ts=models[n];ws=words[n]
                classic={ws[i+1] for i,w in enumerate(ws[:-1]) if w=='import' and ts[i+1].kind==2}
                for i,(t,w) in enumerate(zip(ts,ws)):
                    prev=ws[i-1] if i else '';nxt=ws[i+1] if i+1<len(ws) else '';replacement=None
                    if t.kind==2 and w==old and (prev in ('module','import') or (w in classic and nxt=='.')):replacement=new
                    if t.kind==4 and prev=='import':
                        path=w[1:-1]
                        if path.split('.')[-1]==old:replacement='"'+path[:-len(old)]+new+'"'
                    if replacement is not None:edits[n].append(Edit('NEBO-MIG-MODULE-002',str(mid),t.start,t.end,w,replacement))
            for n,m in metadata_values.items():
                if m.get('schema')==package.MANIFEST_SCHEMA:
                    for mod in m['modules']:
                        if mod['logical']==old:mod['logical']=new
                elif m.get('schema')==package.WORKSPACE_SCHEMA and m['entry']['module']==old:m['entry']['module']=new
            facts.append(dict(kind='module',module_id=mid,new_name=new,api_impact='BREAKING_EXPLICIT'))
    if package_rename:
        require(workspace,'PACKAGE_REQUIRES_WORKSPACE');parts=package_rename.split(':');require(len(parts)==2,'RENAME_SELECTOR')
        old,new=map(package.package_id,parts);require(old!=new,'RENAME_COLLISION')
        manifests=[v for v in metadata_values.values() if v.get('schema')==package.MANIFEST_SCHEMA]
        if not any(m['package']==old for m in manifests):
            require(sum(m['package']==new for m in manifests)==1,'RENAME_IDENTITY')
            return edits,[dict(kind='package',old_name=old,new_name=new,state='ALREADY_CURRENT')]
        require(not any(m['package']==new for m in manifests),'RENAME_COLLISION')
        bound=[int(infos[n]['module.id']) for n in names]
        for n,m in metadata_values.items():
            if m.get('schema')==package.MANIFEST_SCHEMA:
                if m['package']==old:m['package']=new
                if old in m['dependencies']:m['dependencies'][new]=m['dependencies'].pop(old)
            elif m.get('schema')==package.WORKSPACE_SCHEMA:
                if m['root']==old:m['root']=new
                if m['entry']['package']==old:m['entry']['package']=new
        facts.append(dict(kind='package',old_name=old,new_name=new,module_ids=sorted(bound),api_impact='BREAKING_EXPLICIT'))
    for n,m in metadata_values.items():
        if m!=decode(data[n]):edits[n]=one_edit(data[n],package.canonical(m),'NEBO-MIG-METADATA-002','validated-package-graph')
    return edits,facts
