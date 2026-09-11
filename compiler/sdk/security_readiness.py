"""Read-only security records. Trusted pins are supplied by the local caller.

Evidence integrity is not reviewer authenticity or release authorization. The
caller must independently authorize each review receipt pin; this module never
contacts reviewers, signs records, writes waivers or promotes a domain pack.
"""
from __future__ import annotations
import argparse,csv,hashlib,io,json,re,sys
from pathlib import Path
from compiler.sdk import package_manager as fs

FILES=('NEBO-1.0-THREAT-MODEL.md','SECURITY-CONTROL-MATRIX.tsv',
       'EXTERNAL-SECURITY-REVIEW-GATES.tsv','SECURITY-WAIVER-REGISTER.tsv',
       'SECURITY-READINESS-REPORT.md')
INDEX='SECURITY-PROFILE.json'
MAX_BYTES=262144
GATES={'RELEASE-SECURITY','RELEASE-LEGAL','RELEASE-SIGNING','RELEASE-CANDIDATE',
       'CRYPTO_IMPLEMENTATION_REVIEW','PRIVATE_X11_EVIDENCE_ONLY',
       'NETWORK_NOT_AUTHORIZED','GPU_BACKEND_UNAVAILABLE'}
GATE_POLICY={
 'RELEASE-SECURITY':('FINAL_RELEASE','INDEPENDENT_SECURITY_REVIEWER'),
 'RELEASE-LEGAL':('FINAL_RELEASE','AUTHORIZED_LICENSE_REVIEWER'),
 'RELEASE-SIGNING':('FINAL_RELEASE','AUTHORIZED_RELEASE_MAINTAINER'),
 'RELEASE-CANDIDATE':('FINAL_RELEASE','AUTHORIZED_RELEASE_MAINTAINER'),
 'CRYPTO_IMPLEMENTATION_REVIEW':('OPTIONAL_ADVANCED_CRYPTO','INDEPENDENT_CRYPTO_REVIEWER'),
 'PRIVATE_X11_EVIDENCE_ONLY':('OPTIONAL_TARGET','AUTHORIZED_TARGET_OPERATOR'),
 'NETWORK_NOT_AUTHORIZED':('OPTIONAL_NETWORK','AUTHORIZED_NETWORK_OPERATOR'),
 'GPU_BACKEND_UNAVAILABLE':('OPTIONAL_ACCELERATOR','AUTHORIZED_TARGET_REVIEWER'),
}
STATES={'PENDING_EXTERNAL','OPEN','TARGET_GATED','UNAVAILABLE','PASS','FAIL','REVOKED'}
CONTROL_FIELDS='id subgroup boundary owner evidence scope claim status limitation'.split()
GATE_FIELDS='id scope state reviewer_role evidence required_action release_impact'.split()
WAIVER_FIELDS='id gate scope owner rationale expires status'.split()

def require(ok, code):
    if not ok: raise ValueError('NEBO-SECURITY-'+code)

def sha(raw):return hashlib.sha256(raw).hexdigest()
def digest(value):return isinstance(value,str) and re.fullmatch('[a-f0-9]{64}',value) is not None

def decode(raw):
    require(len(raw)<=MAX_BYTES,'INPUT_LIMIT')
    return fs.decode(raw)

def table(raw,fields):
    require(len(raw)<=MAX_BYTES,'INPUT_LIMIT')
    try:
        text=raw.decode('utf-8'); reader=csv.DictReader(io.StringIO(text),delimiter='\t')
        require(reader.fieldnames==fields,'TABLE_SCHEMA')
        result=list(reader)
        require(len(result)<=256,'ROW_LIMIT')
        for row in result:
            require(set(row)==set(fields) and all(isinstance(v,str) and 0<len(v)<=2048 and
                    not any(ord(c)<32 or ord(c)==127 for c in v) for v in row.values()),'ROW_SCHEMA')
        require(len({r['id'] for r in result})==len(result),'DUPLICATE_ID')
        return result
    except (UnicodeError,csv.Error):raise ValueError('NEBO-SECURITY-TABLE_ENCODING') from None

def evaluate(root,expected_sha256,*,accepted_reviews=None,candidate_sha256=None):
    require(digest(expected_sha256),'PIN_REQUIRED')
    root=Path(root).absolute(); raw=fs.read(root,INDEX,MAX_BYTES)
    require(sha(raw)==expected_sha256,'PIN_MISMATCH'); index=decode(raw)
    require(type(index) is dict and set(index)=={'format','files','surface_count','external_assurance'},'INDEX_SCHEMA')
    require(index['format']=='NEBO-SECURITY-PROFILE-v1' and type(index['surface_count']) is int and
            index['surface_count']==40 and index['external_assurance']=='NOT_CERTIFIED','INDEX_PROFILE')
    require(type(index['files']) is dict and set(index['files'])==set(FILES),'FILE_SET')
    payload={}
    for name in FILES:
        require(digest(index['files'][name]),'FILE_DIGEST')
        payload[name]=fs.read(root,name,MAX_BYTES)
        require(sha(payload[name])==index['files'][name],'CONTENT_DRIFT')
    controls=table(payload[FILES[1]],CONTROL_FIELDS)
    require(bool(controls) and re.fullmatch(r'G[0-9]{3}-S[0-9]{2}-F[0-9]{3}',controls[0]['id']),'CONTROL_ID')
    prefix=controls[0]['id'][:4]
    expected={f'{prefix}-S{s:02}-F{n:03}' for s in range(1,9) for n in range(1,6)}
    require({r['id'] for r in controls}==expected,'CONTROL_SET')
    for row in controls:
        require(row['subgroup']==row['id'][:8] and row['scope'] in {'LOCAL_FUNCTIONAL','INTERNAL_OWNER','REFERENCE_MODEL','PROCESS_RECORD'},'CONTROL_SCOPE')
        require(row['claim']=='BOUNDED_CONFORMANCE' and row['status']=='VERIFIED_LOCAL','UNPROVEN_CLAIM')
        require(row['limitation']!='NONE' and row['owner']!='NONE' and row['evidence']!='NONE','CONTROL_EVIDENCE')
    gates=table(payload[FILES[2]],GATE_FIELDS)
    require({r['id'] for r in gates}==GATES,'GATE_SET')
    accepted_reviews={} if accepted_reviews is None else accepted_reviews
    require(type(accepted_reviews) is dict and set(accepted_reviews)<=GATES and
            all(digest(v) for v in accepted_reviews.values()),'REVIEW_PINS')
    require(candidate_sha256 is None or digest(candidate_sha256),'CANDIDATE_PIN')
    blockers=[];accepted=[]
    for gate in gates:
        ident=gate['id'];require(gate['state'] in STATES,'GATE_STATE')
        scope,role=GATE_POLICY[ident]
        impact='BLOCKS_FINAL_RELEASE' if scope=='FINAL_RELEASE' else 'EXCLUDES_OPTIONAL_SURFACE'
        require(gate['scope']==scope and gate['reviewer_role']==role and gate['release_impact']==impact,'GATE_AUTHORITY')
        if gate['state']=='PASS':
            require(ident in accepted_reviews and candidate_sha256 is not None,'EXTERNAL_ACCEPTANCE_REQUIRED')
            data=fs.read(root,ident+'.review.json',65536)
            require(sha(data)==accepted_reviews[ident],'REVIEW_DRIFT')
            receipt=decode(data)
            require(type(receipt) is dict and set(receipt)=={'gate','decision','reviewer','role','candidate_sha256','scope','exclusions'},'RECEIPT_SCHEMA')
            require(receipt['gate']==ident and receipt['decision']=='PASS' and receipt['role']==gate['reviewer_role'] and
                    receipt['scope']==gate['scope'] and receipt['candidate_sha256']==candidate_sha256,'RECEIPT_BINDING')
            require(isinstance(receipt['reviewer'],str) and re.fullmatch(r'[A-Za-z0-9_.-]{1,100}',receipt['reviewer']) and
                    receipt['reviewer'].upper() not in {'SELF','AUTOMATED_AGENT'} and receipt['exclusions']==[], 'RECEIPT_AUTHORITY')
            accepted.append(ident)
        else:
            require(ident not in accepted_reviews,'STALE_REVIEW_PIN')
            blockers.append(dict(id=ident,state=gate['state'],impact=gate['release_impact']))
    waivers=table(payload[FILES[3]],WAIVER_FIELDS)
    for waiver in waivers:
        # A waiver is an explicit risk record. It cannot satisfy a review gate
        # or excuse an unproven mandatory security claim.
        require(waiver['gate'] in GATES and GATE_POLICY[waiver['gate']][0]!='FINAL_RELEASE' and waiver['scope']=='OPTIONAL_EXCLUDED' and
                waiver['owner'] not in {'NONE','SELF','AUTOMATED_AGENT'} and
                waiver['status'] in {'PROPOSED','ACCEPTED','REVOKED','EXPIRED'} and
                re.fullmatch(r'\d{4}-\d{2}-\d{2}',waiver['expires']), 'WAIVER_POLICY')
    return dict(format='NEBO-SECURITY-READINESS-v1',record_integrity='VALID',
                controls=len(controls),subgroups=8,external_assurance='NOT_CERTIFIED',
                accepted_reviews=sorted(accepted),blockers=sorted(blockers,key=lambda r:r['id']),
                waivers=len(waivers),waivers_satisfy_gates=False,release_authorized=False,
                external_network_used=False,redacted=True)

def main(argv=None):
    parser=argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--profile',type=Path,default=Path(__file__).resolve().parents[2]/'sdk/nebo-1.0/security')
    parser.add_argument('--profile-sha256',required=True)
    parser.add_argument('--candidate-sha256')
    parser.add_argument('--accept-review',action='append',default=[],metavar='GATE=TRUSTED_RECEIPT_SHA256')
    a=parser.parse_args(argv)
    try:
        pins={}
        for item in a.accept_review:
            parts=item.split('=');require(len(parts)==2 and parts[0] not in pins,'REVIEW_PINS');pins[parts[0]]=parts[1]
        result=evaluate(a.profile,a.profile_sha256,accepted_reviews=pins,candidate_sha256=a.candidate_sha256)
    except (ValueError,OSError,TypeError,KeyError):
        print(json.dumps({'diagnostic':'NEBO-SECURITY-INPUT_REJECTED','redacted':True}),file=sys.stderr);return 2
    print(json.dumps(result,sort_keys=True))
    return 3 if any(r['impact']=='BLOCKS_FINAL_RELEASE' for r in result['blockers']) else 0

if __name__=='__main__':raise SystemExit(main())
