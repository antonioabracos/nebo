#!/usr/bin/env python3
"""Check the reviewed source inventory, integrity, privacy and license pins."""
import csv, hashlib, json, re, stat, subprocess, unicodedata
from pathlib import Path
from privacy import scan_files
ROOT=Path(__file__).resolve().parents[2]

def sha(raw): return hashlib.sha256(raw).hexdigest()
def source_files():
    names=subprocess.check_output(['git','ls-files','-z','--cached','--others','--exclude-standard'],cwd=ROOT).decode().split('\0')
    return sorted({n for n in names if n and (ROOT/n).exists()})
def main():
    names=source_files();assert names and len(names)==len(set(names))
    policy=json.loads((ROOT/'tests/public/policy-pins.json').read_bytes())
    denied_prefixes=[('/'.join(parts)+'/') for parts in [('.agents',),('.codex',),('docs','implementation'),('docs','rf204'),('release','remediation'),('release','version-harmonization'),('build',),('out',),('.cache',)]]
    scan_files(ROOT,names)
    seen={};total=0;local_only={}
    forbidden_suffixes={'.pyc','.pyo','.o','.obj','.elf','.exe','.zip','.tar','.gz','.xz','.7z','.pem','.key'}
    for name in names:
        parts=Path(name).parts
        assert not Path(name).is_absolute() and not any(x in {'.','..','.git','__pycache__'} for x in parts),name
        assert '\\' not in name and ':' not in name and not any(ord(c)<32 for c in name),name
        assert not name.startswith(tuple(denied_prefixes)),name
        key=unicodedata.normalize('NFC',name).casefold();assert key not in seen,(name,seen.get(key));seen[key]=name
        p=ROOT/name;mode=p.lstat().st_mode
        assert stat.S_ISREG(mode) and not p.is_symlink(),name
        assert stat.S_IMODE(mode) in {0o644,0o755},(name,oct(mode))
        assert p.suffix.lower() not in forbidden_suffixes,name
        raw=p.read_bytes();total+=len(raw);assert len(raw)<=10*1024*1024,name
        if p.suffix==".py" and mode&0o111:assert raw.startswith(b"#!"),("Python executable lacks interpreter",name)
        assert not raw.startswith((b'\x7fELF',b'PK\x03\x04',b'!<arch>\n')),name
        for prefix in denied_prefixes[2:6]: assert prefix.encode() not in raw,('internal reference',name)
        if b'--local-only' in raw:local_only[name]=raw.count(b'--local-only')
    # Semantic CLI spelling is part of the public compatibility inventory.
    assert local_only==policy['local_only_occurrences'],('local-only inventory changed',local_only)
    for name,digest in policy['license_and_asset_sha256'].items():assert sha((ROOT/name).read_bytes())==digest,name
    checks={}
    for line in (ROOT/'SHA256SUMS').read_text().splitlines():
        digest,name=line.split('  ',1);assert re.fullmatch('[0-9a-f]{64}',digest) and name not in checks;checks[name]=digest
    assert set(checks)==set(names)-{'SHA256SUMS'},'checksum inventory mismatch'
    for name,digest in checks.items():assert sha((ROOT/name).read_bytes())==digest,('checksum',name)
    content=(ROOT/'release/PUBLIC-CONTENT-SHA256SUMS').read_bytes()
    provenance=json.loads((ROOT/'SOURCE-PROVENANCE.json').read_bytes())
    assert provenance['content_manifest_sha256']==sha(content)
    omitted={'SHA256SUMS','SOURCE-PROVENANCE.json','release/PUBLIC-CONTENT-SHA256SUMS'}
    records=dict((line.split('  ',1)[1],line.split('  ',1)[0]) for line in content.decode().splitlines())
    assert set(records)==set(names)-omitted
    assert all(records[n]==checks[n] for n in records)
    canonical=[dict(path=n,mode='100755' if (ROOT/n).stat().st_mode&0o111 else '100644',sha256=records[n]) for n in sorted(records)]
    assert provenance['canonical_public_tree_digest']==sha((json.dumps(canonical,sort_keys=True,separators=(',',':'))+'\n').encode())
    assert provenance['version']=='1.1.0' and provenance['edition']=='1.0'
    env=dict(line.split('=',1) for line in (ROOT/'release/PUBLIC-RELEASE-CANDIDATE.env').read_text().splitlines() if line and not line.startswith('#'))
    assert env['STATUS']=='PULL_REQUEST_CANDIDATE' and env['VERSION']=='1.1.0' and env['EDITION']=='1.0'
    assert env['PREVIOUS_PUBLIC_VERSION']=='1.0.1' and env['OPEN_FINDINGS']=='0'
    with (ROOT/'release/PUBLIC-PR-CHANGE-MANIFEST.tsv').open() as f:
        rows=list(csv.DictReader(f,delimiter='\t'))
    assert rows and len({x['path'] for x in rows})==len(rows)
    assert all(x['classification'] and x['classification']!='UNCLASSIFIED' and x['public_reason'] and x['validation'] for x in rows)
    print(json.dumps(dict(status='PASS',source_files=len(names),source_bytes=total,unclassified=0,unsafe_paths=0,private_paths=0,credential_patterns=0,license_pins=len(policy['license_and_asset_sha256']),local_only_occurrences=sum(local_only.values()))))
if __name__=='__main__':main()
