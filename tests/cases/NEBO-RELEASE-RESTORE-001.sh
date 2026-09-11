#!/usr/bin/env bash
set -euo pipefail
source "${NEBO_REPO_ROOT:?}/scripts/mf062/release-case-lib.sh"
report="$MF062_EVIDENCE/DETERMINISM-BUILDS.tsv"
mf062_require_file "$report"
python3 -B - "$report" <<'PY2'
from pathlib import Path
import re, sys
p=Path(sys.argv[1]); lines=p.read_text().splitlines()
header='run\tsource_commit\tbinary_sha256\tsize_bytes\tcli_version\ttarget\tstatus'
if not lines or lines[0]!=header:
    raise SystemExit('NEBO_RELEASE_RESTORE_001_FAIL header')
rows=[line.split('\t') for line in lines[1:] if line]
if len(rows)!=3:
    raise SystemExit(f'NEBO_RELEASE_RESTORE_001_FAIL runs={len(rows)}')
if [r[0] for r in rows]!=['1','2','3']:
    raise SystemExit('NEBO_RELEASE_RESTORE_001_FAIL sequence')
if any(len(r)!=7 or r[4]!='neboc 0.1.0' or r[5]!='x86_64-systemv-elf-linux' or r[6]!='PASS' for r in rows):
    raise SystemExit('NEBO_RELEASE_RESTORE_001_FAIL row contract')
if len({r[2] for r in rows})!=1 or not re.fullmatch(r'[0-9a-f]{64}',rows[0][2]):
    raise SystemExit('NEBO_RELEASE_RESTORE_001_FAIL nondeterministic binary')
if len({r[1] for r in rows})!=1 or any(not re.fullmatch(r'[0-9a-f]{40}',r[1]) for r in rows):
    raise SystemExit('NEBO_RELEASE_RESTORE_001_FAIL source commit')
print('NEBO_RELEASE_RESTORE_001_GREEN clean_builds=3 unique_binary_hashes=1')
PY2
