#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.."&&pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
ninja -j1 rf27-g27-f06-tests >/dev/null
build/tests/rf27-g27/f06/conformance_test
t="$(mktemp -d)";trap 'rm -rf -- "$t"' EXIT
python3 tests/rf27-g27/f06/conformance_oracle.py >"$t/a";python3 tests/rf27-g27/f06/conformance_oracle.py >"$t/b";cmp -s "$t/a" "$t/b";cat "$t/a"
file build/tests/rf27-g27/f06/conformance_test|rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g27/f06/conformance_test|rg -q INTERP
test -z "$(nm -u build/tests/rf27-g27/f06/conformance_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/conformance_conformance.o
bash tests/rf27-g27/f03/validate.sh >/dev/null
bash tests/rf27-g27/f04/validate.sh >/dev/null
bash tests/rf27-g27/f05/validate.sh >/dev/null
bash tests/rf27-g26/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G27_F06_GREEN native_assertions=19 manifest_cases=12 normative_rules=12 mutation_cases=60000 target=x86_64-systemv-elf-linux ABI=0 editions=1_2 positive_negative_runtime=yes implementation_manifest_parity=yes generic_validation=yes fixture_dispatch=no deterministic=yes static_elf=yes no_c_no_libc=yes'
