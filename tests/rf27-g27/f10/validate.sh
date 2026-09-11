#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
ninja -j1 rf27-g27-f10-tests >/dev/null
t="$(mktemp -d)"; trap 'rm -rf -- "$t"' EXIT
python3 tests/rf27-g27/f10/project_harness.py >"$t/projects-a"
python3 tests/rf27-g27/f10/project_harness.py >"$t/projects-b"
cmp -s "$t/projects-a" "$t/projects-b"; cat "$t/projects-a"
python3 tests/rf27-g27/f10/integration_fault_oracle.py >"$t/oracle-a"
python3 tests/rf27-g27/f10/integration_fault_oracle.py >"$t/oracle-b"
cmp -s "$t/oracle-a" "$t/oracle-b"; cat "$t/oracle-a"
bash tests/rf27-g24/f11/validate.sh >/dev/null
bash tests/rf27-g25/f09/validate.sh >/dev/null
bash tests/rf27-g26/f09/validate.sh >/dev/null
bash tests/rf27-g27/f09/validate.sh >/dev/null
git diff --check
test -z "$(find examples/projects/rf27-g27 tests/rf27-g27/f10 -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G27_F10_GREEN projects=5 units=15 builds=15 runs=5 migrations=5 deterministic_packages=15 restores=5 fault_cases=80000 static_elf=yes no_c_no_libc=yes external_user_claim=no predecessors=PASS network=no'
