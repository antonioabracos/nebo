#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=${NEBO_REPO_ROOT:-$(cd -- "$(dirname -- "$0")/../.." && pwd)}
cd "$root"
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT HUP INT TERM
source=tests/e2e/core/control/if-labels.no
pattern=tests/codegen/goldens/005-if-branches.pattern
build/bin/neboc check "$source" >"$tmp/check.out" 2>"$tmp/check.err"
test ! -s "$tmp/check.out"; test ! -s "$tmp/check.err"
build/bin/neboc emit-asm "$source" -o "$tmp/if-a.asm"
build/bin/neboc emit-asm "$source" -o "$tmp/if-b.asm"
cmp -s "$tmp/if-a.asm" "$tmp/if-b.asm"
python3 -B - "$tmp/if-a.asm" "$pattern" <<'PY'
import re,sys
from pathlib import Path
asm=Path(sys.argv[1]).read_text(encoding='utf-8')
pat=Path(sys.argv[2]).read_text(encoding='utf-8')
ids=re.findall(r'\.nebo_if_(?:else|end)_(\d+)',asm)
if not ids or len(set(ids)) != 1:
    raise SystemExit('if label IDs are absent or inconsistent')
normalized=re.sub(r'(\.nebo_if_(?:else|end)_)\d+',r'\1@IF@',asm)
if normalized != pat:
    import difflib
    sys.stderr.writelines(difflib.unified_diff(pat.splitlines(True),normalized.splitlines(True),fromfile='golden',tofile='actual'))
    raise SystemExit(1)
print(f'MF039_IF_LABEL_ID={ids[0]}')
PY
nasm -f elf64 -Wall -Werror -o "$tmp/if.o" "$tmp/if-a.asm"
echo NEBO_CODEGEN_GOLDEN_005_GREEN
