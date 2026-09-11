"""Read the relocatable Edition 1 functional Standard Library freeze.

This metadata consumer never resolves source imports or grants capabilities.
Content fingerprints detect drift; they are not a release signature.
"""
from __future__ import annotations
import csv
import hashlib
import io
import json
from pathlib import Path
import re

TARGET='x86_64-systemv-elf-linux'
FILES=('STDLIB-STABLE-CATALOG.tsv','STDLIB-TARGET-AVAILABILITY.tsv',
       'STDLIB-LIMITS-AND-ERRORS.tsv','STDLIB-PROFILE-BOUNDARIES.tsv','STDLIB-REFERENCE.md')
MANIFEST='STDLIB-API-ABI-MANIFEST.json'

class FreezeError(ValueError):
    """Malformed, inconsistent or unsupported functional freeze."""

def require(test,code):
    if not test:raise FreezeError(code)

def digest(raw):return hashlib.sha256(raw).hexdigest()
def canonical(value):return json.dumps(value,ensure_ascii=False,sort_keys=True,separators=(',',':')).encode()
def unique(pairs):
    result={}
    for key,value in pairs:
        require(key not in result,'DUPLICATE_JSON_FIELD')
        result[key]=value
    return result

def read(directory:Path,name:str)->bytes:
    path=directory/name
    require(path.is_file() and not path.is_symlink(),'NON_REGULAR_FREEZE_FILE')
    require(path.stat().st_size<=16*1024*1024,'FREEZE_FILE_BUDGET')
    with path.open('rb') as stream:raw=stream.read(16*1024*1024+1)
    require(len(raw)<=16*1024*1024,'FREEZE_FILE_BUDGET')
    return raw

def table(raw):
    stream=io.StringIO(raw.decode('utf-8'),newline='')
    reader=csv.DictReader(stream,delimiter='\t')
    require(reader.fieldnames and len(set(reader.fieldnames))==len(reader.fieldnames),'DUPLICATE_TSV_FIELD')
    rows=list(reader)
    require(0<len(rows)<=4096 and all(None not in r and None not in r.values() for r in rows),'TSV_SCHEMA')
    require(all('identity' in r and r['identity'] for r in rows),'MISSING_IDENTITY')
    require(len({r['identity'] for r in rows})==len(rows),'DUPLICATE_IDENTITY')
    return rows

def load(directory:Path,*,target:str=TARGET)->dict:
    """Authenticate tables, source specimens, lifecycle and profile boundaries."""
    require(target==TARGET,'UNSUPPORTED_FREEZE_TARGET')
    directory=Path(directory)
    require(directory.is_dir() and not directory.is_symlink(),'NON_REGULAR_FREEZE_ROOT')
    try:
        manifest_raw=read(directory,MANIFEST)
        manifest=json.loads(manifest_raw,object_pairs_hook=unique,
                            parse_constant=lambda _:(_ for _ in ()).throw(FreezeError('NONFINITE_JSON')))
        require(type(manifest['schema']) is int and manifest['schema']==1,'FREEZE_SCHEMA')
        require(manifest['edition']=='1' and manifest['target']==target,'FREEZE_PROFILE')
        require(all(re.fullmatch('[0-9a-f]{40}', manifest[k]) for k in ('public_base_commit', 'public_base_tree')),'PUBLIC_BASE_IDENTITY')
        require(all(re.fullmatch('[0-9a-f]{64}',manifest[k]) for k in
                    ('contract_sha256','inherited_api_sha256','inherited_abi_sha256')),'AUTHORITY_IDENTITY')
        require(manifest['import_grants_capability'] is False,'IMPORT_CAPABILITY_GRANT')
        require(set(manifest['files'])==set(FILES),'FREEZE_FILE_SET')
        payload={name:read(directory,name) for name in FILES}
        require(all(digest(raw)==manifest['files'][name] for name,raw in payload.items()),'FREEZE_CONTENT_DRIFT')
        rows=table(payload[FILES[0]]);targets=table(payload[FILES[1]]);limits=table(payload[FILES[2]])
        boundaries=table(payload[FILES[3]])
        ids={r['identity'] for r in rows}
        require(manifest['stable_identities']==sorted(ids),'FREEZE_IDENTITY_SET')
        require(type(manifest['stable_count']) is int and manifest['stable_count']==len(rows),'FREEZE_CARDINALITY')
        require({r['identity'] for r in targets}=={r['identity'] for r in limits}==ids,'INCOMPLETE_PROJECTIONS')
        require(not ids&{r['identity'] for r in boundaries},'STABLE_BOUNDARY_OVERLAP')
        require(all(r['tier'] in {'EXPERIMENTAL','TARGET_GATED','EXCLUDED_1_0','POST_1_0',
                    'MATERIAL_BOUNDED_NOT_PROMOTED','INTERNAL_OR_NON_STABLE_PROFILE'} and r['target'] in {target,'UNDECLARED'}
                    and (r['target']!='UNDECLARED' or r['tier'] in {'EXCLUDED_1_0','POST_1_0'})
                    and r['limits'] and r['proof'] for r in boundaries),'INVALID_PROFILE_BOUNDARY')
        target_map={r['identity']:r for r in targets};limit_map={r['identity']:r for r in limits}
        doc=payload['STDLIB-REFERENCE.md'].decode()
        for row in rows:
            require(row['tier']=='STABLE_1_0' and row['edition']=='1' and row['since'],'STABLE_LIFECYCLE')
            require(row['target']==target,'TARGET_OVERCLAIM')
            require(row['profile'] in {'STABLE_PUBLIC_ATOMICALLY_EXECUTED','BOUNDED_PUBLIC_EXECUTED_WITHIN_LIMITS'},'NONPUBLIC_STABLE_PROFILE')
            require(row['import_grants_capability']=='NO','IMPORT_CAPABILITY_GRANT')
            require(row['positive_cases'] and row['negative_cases'] and row['limits'] and row['ownership'],'MISSING_STABLE_CONTRACT')
            witness_cases=row['source_witness_cases'].split(',')
            require(row['primary_witness'] in witness_cases and set(row['positive_cases'].split(','))<=set(witness_cases)
                    and row['declaration_kind'],'WITNESS_NOT_ASSOCIATED')
            source=json.loads(row['source_form'])
            require(isinstance(source,str) and digest(source.encode())==row['source_sha256'],'SOURCE_SPECIMEN_DRIFT')
            atom='symbol-'+digest(row['identity'].encode())[:24]
            require(row['doc_ref']=='STDLIB-REFERENCE.md#'+atom and doc.count('<a id="'+atom+'"></a>')==1,'MISSING_OR_AMBIGUOUS_DOCUMENTATION')
            require(source in doc,'DOCUMENTATION_SOURCE_MISSING')
            content={k:v for k,v in row.items() if k!='api_fingerprint'}
            require(digest(canonical(content))==row['api_fingerprint'],'API_FINGERPRINT_DRIFT')
            require(all(row[k]==v for k,v in target_map[row['identity']].items()),'TARGET_PROJECTION_DRIFT')
            require(all(row[k]==v for k,v in limit_map[row['identity']].items()),'LIMIT_PROJECTION_DRIFT')
        require(isinstance(manifest['owner_fingerprints'],dict) and manifest['owner_fingerprints']
                and all(re.fullmatch('[0-9a-f]{64}',v) for v in manifest['owner_fingerprints'].values()),'OWNER_ABI_FINGERPRINTS')
        require(read(directory,MANIFEST)==manifest_raw,'FREEZE_CHANGED_DURING_READ')
        return dict(schema=1,target=target,edition='1',stable=rows,boundaries=boundaries,
                    manifest_sha256=digest(manifest_raw),import_grants_capability=False)
    except (KeyError,TypeError,UnicodeError,json.JSONDecodeError,csv.Error) as error:
        raise FreezeError('MALFORMED_FREEZE') from error
