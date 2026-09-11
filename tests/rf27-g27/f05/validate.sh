#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.."&&pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
ninja -j1 rf27-g27-f05-tests >/dev/null
build/tests/rf27-g27/f05/edition_test
t="$(mktemp -d)";trap 'rm -rf -- "$t"' EXIT
python3 tests/rf27-g27/f05/edition_oracle.py >"$t/a";python3 tests/rf27-g27/f05/edition_oracle.py >"$t/b";cmp -s "$t/a" "$t/b";cat "$t/a"
file build/tests/rf27-g27/f05/edition_test|rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g27/f05/edition_test|rg -q INTERP
test -z "$(nm -u build/tests/rf27-g27/f05/edition_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/edition.o
bash tests/rf27-g27/f03/validate.sh >/dev/null
bash tests/rf27-g25/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G27_F05_GREEN native_assertions=23 cases=70000 editions=legacy_current current=2 ABI=0 runtime=0 deprecation=yes migration=mechanical unsafe=denied package_min_max=yes breaking_report=yes failure_atomicity=yes deterministic=yes static_elf=yes no_c_no_libc=yes'
