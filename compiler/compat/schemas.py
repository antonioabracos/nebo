"""Versioned schemas shared by the CLI report and its documented consumers."""
from compiler.compat.structural import obj,TEXT,STRINGS,INTEGER,CONTRACT_SCHEMA,REPORT,SECTIONS,FIELDS

CLASS={'enum':['COMPATIBLE','BREAKING','REVIEW_REQUIRED','SECURITY_REVOKED']}
BUMP={'enum':['NONE','PATCH','MINOR','MAJOR']}
CHANGE=obj(dict(dimension={'enum':list(SECTIONS)},identity=TEXT,field=TEXT,
                before={},after={},classification=CLASS,required_bump=BUMP,reason=TEXT))
BLOCKER=obj(dict(dimension=TEXT,identity=TEXT,field=TEXT,reason=TEXT))
MIGRATION=obj(dict(dimension=TEXT,identity=TEXT,field=TEXT))
POLICY=obj(dict(decision={'enum':['BLOCKED','VALID_DRY_RUN']},required_bump=BUMP,actual_bump=BUMP,
                blockers=STRINGS,report_sha256=TEXT,release_authorized={'const':False}))
VECTOR=obj(dict(format={'const':REPORT},scope={'enum':['FULL_CONTRACT','NATIVE_NI','NATIVE_PACKAGE','FREEZE_STRUCTURE']},
    baseline=TEXT,candidate=TEXT,
    compatibility_vector=obj({d:{'enum':['UNCHANGED','UNASSESSED',*CLASS['enum']]} for d in SECTIONS}),
    changes={'type':'array','items':CHANGE,'maxItems':300000},required_bump=BUMP,
    blockers={'type':'array','items':BLOCKER,'maxItems':300000},
    migrations={'type':'array','items':MIGRATION,'maxItems':300000},
    approvals_required={'type':'array','items':{'enum':['owner','reviewer','security']},'uniqueItems':True,'maxItems':3},
    release_authorized={'const':False}))
VECTOR['properties']['ci_policy']=POLICY

def documents():
    import copy
    docs={'COMPATIBILITY-CONTRACT-SCHEMA.json':copy.deepcopy(CONTRACT_SCHEMA),
          'COMPATIBILITY-VECTOR-SCHEMA.json':copy.deepcopy(VECTOR)}
    for dim in ('api','abi','ni'):
        schema=copy.deepcopy(CHANGE);schema['properties']['dimension']={'const':dim}
        schema['description']='One structural '+dim+' change in the compatibility vector; before/after preserve the field value or entire added/removed record.'
        schema['$defs']={'contract_record':obj(FIELDS[dim])}
        docs[dim.upper()+'-DIFF-SCHEMA.json']=schema
    for name,schema in docs.items():
        schema['$schema']='https://json-schema.org/draft/2020-12/schema'
        schema['$id']='nebo://compat/'+name.lower().replace('.json','-v2')
    return docs
