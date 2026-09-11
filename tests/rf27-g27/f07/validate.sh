#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.."&&pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
ninja -j1 rf27-g27-f07-tests >/dev/null
build/tests/rf27-g27/f07/supply_chain_test
t="$(mktemp -d)";trap 'rm -rf -- "$t"' EXIT
tools/rf27-doctor.py >"$t/doctor-a";tools/rf27-doctor.py >"$t/doctor-b";cmp -s "$t/doctor-a" "$t/doctor-b"
python3 tests/rf27-g27/f07/supply_chain_oracle.py >"$t/a";python3 tests/rf27-g27/f07/supply_chain_oracle.py >"$t/b";cmp -s "$t/a" "$t/b";cat "$t/a"
rg -q 'Report suspected vulnerabilities privately' docs/public/SECURITY.md
file build/tests/rf27-g27/f07/supply_chain_test|rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g27/f07/supply_chain_test|rg -q INTERP
test -z "$(nm -u build/tests/rf27-g27/f07/supply_chain_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/supply_chain.o
bash tests/rf27-g27/f06/validate.sh >/dev/null
bash tests/rf27-g25/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G27_F07_GREEN native_assertions=13 fuzz_cases=80000 sbom_version=1 entries_max=8192 actual_inventory=4 doctor=green provenance_digest=yes content_digest=yes disclosure=yes private_keys=0 signature_claim=no drift_missing_hash_size_kind_denied=yes deterministic=yes static_elf=yes no_c_no_libc=yes network=no RC2=preserved'
