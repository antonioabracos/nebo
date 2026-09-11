#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
t="$(mktemp -d)"; trap 'rm -rf -- "$t"' EXIT
python3 tests/rf27-g27/f09/verify_documentation.py >"$t/docs-a"
python3 tests/rf27-g27/f09/verify_documentation.py >"$t/docs-b"
cmp -s "$t/docs-a" "$t/docs-b"; cat "$t/docs-a"
python3 tests/rf27-g27/f09/documentation_oracle.py >"$t/oracle-a"
python3 tests/rf27-g27/f09/documentation_oracle.py >"$t/oracle-b"
cmp -s "$t/oracle-a" "$t/oracle-b"; cat "$t/oracle-a"
test "$(build/bin/neboc --version)" = 'neboc 0.2.0-rc.2'
build/bin/neboc --help | rg -q 'Target: x86_64-systemv-elf-linux'
python3 tools/rf27-package.py --help | rg -q 'init,add,remove,resolve,audit,vendor,package'
bash tests/rf27-g27/f08/validate.sh >/dev/null
git diff --check
printf '%s\n' 'RF27_G27_F09_GREEN documents=8 verified_examples=2 deterministic_builds=4 block_cases=50000 CLI_docs_match=yes certified_target=x86_64-systemv-elf-linux unsafe_claims=0 predecessor=PASS network=no'
