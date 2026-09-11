#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g24-f10-tests >/dev/null
build/tests/rf27-g24/f10/test_tooling_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g24/f10/test_tooling_oracle.py >"$tmp/oracle-a"
PYTHONDONTWRITEBYTECODE=1 python3 tests/rf27-g24/f10/test_tooling_oracle.py >"$tmp/oracle-b"
cmp "$tmp/oracle-a" "$tmp/oracle-b"; cat "$tmp/oracle-a"
mkdir -p "$tmp/suite"
printf 'start() {\n  1;\n}\n' >"$tmp/suite/basic.pass.no"
printf 'start( {\n' >"$tmp/suite/broken.fail.no"
tools/rf27-test.py test "$tmp/suite" >"$tmp/test-a"
tools/rf27-test.py test "$tmp/suite" >"$tmp/test-b"
cmp "$tmp/test-a" "$tmp/test-b"
rg -q '"count":2' "$tmp/test-a"
printf '{"schema":1,"cases":[{"path":"basic.pass.no","expect":"pass"},{"path":"broken.fail.no","expect":"fail"}]}' >"$tmp/suite/conformance.json"
tools/rf27-test.py conformance "$tmp/suite/conformance.json" >"$tmp/conformance"
rg -q '"count":2' "$tmp/conformance"
printf '{"schema":1,"cases":[{"path":"../outside.no","expect":"pass"}]}' >"$tmp/suite/traversal.json"
if tools/rf27-test.py conformance "$tmp/suite/traversal.json" >/dev/null 2>&1; then exit 1; fi
tools/rf27-test.py fuzz "$tmp/suite/basic.pass.no" --cases 64 --seed 24010 >"$tmp/fuzz-a"
tools/rf27-test.py fuzz "$tmp/suite/basic.pass.no" --cases 64 --seed 24010 >"$tmp/fuzz-b"
cmp "$tmp/fuzz-a" "$tmp/fuzz-b"
if tools/rf27-test.py fuzz "$tmp/suite/basic.pass.no" --cases 4097 >/dev/null 2>&1; then exit 1; fi
tools/rf27-test.py snapshot "$tmp/suite/basic.pass.no" --output "$tmp/suite/basic.snapshot.json" --accept >"$tmp/snapshot-accept"
tools/rf27-test.py snapshot "$tmp/suite/basic.pass.no" --output "$tmp/suite/basic.snapshot.json" >"$tmp/snapshot-check"
snapshot_before="$(sha256sum "$tmp/suite/basic.snapshot.json")"
printf '{}\n' >"$tmp/suite/basic.snapshot.json"
tampered="$(sha256sum "$tmp/suite/basic.snapshot.json")"
if tools/rf27-test.py snapshot "$tmp/suite/basic.pass.no" --output "$tmp/suite/basic.snapshot.json" >/dev/null 2>&1; then exit 1; fi
test "$tampered" = "$(sha256sum "$tmp/suite/basic.snapshot.json")"
test "$snapshot_before" != "$tampered"
file build/tests/rf27-g24/f10/test_tooling_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f10/test_tooling_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f10/test_tooling_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/test_tooling.o
test -z "$(find tools -type d -name __pycache__ -print)"
printf 'RF27_G24_F10_GREEN native_assertions=22 plans=30000 discovery=lexical cases_max=1024 conformance_v1=yes fuzz_max=4096 deterministic_seed=yes timeout=5 snapshot_v1_atomic=yes traversal_denied=yes arbitrary_command=no network=no static_elf=yes no_c_no_libc=yes\n'
