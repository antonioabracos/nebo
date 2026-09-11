#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g25-f06-tests >/dev/null
build/tests/rf27-g25/f06/observability_test
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
python3 tests/rf27-g25/f06/observability_oracle.py >"$tmp_root/oracle-a"
python3 tests/rf27-g25/f06/observability_oracle.py >"$tmp_root/oracle-b"
cmp "$tmp_root/oracle-a" "$tmp_root/oracle-b"
cat "$tmp_root/oracle-a"
file build/tests/rf27-g25/f06/observability_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g25/f06/observability_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g25/f06/observability_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/observability.o
mf056_full="$(python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g25/f06/observability_test 2>&1 || true)"
test "$(printf '%s\n' "$mf056_full" | rg -c 'MF056_STACK_ALIGNMENT_FAIL')" -eq 6
test -z "$(printf '%s\n' "$mf056_full" | rg 'MF056_STACK_ALIGNMENT_FAIL' | rg -v ' in nebo_sha256_(update|final|hash)$')"
printf '%s\n' 'RF27_G25_F06_DEPENDENCY_MF056=KNOWN_G12_SHA256_6_CALLS FRONT_OBJECT=GREEN'
test -z "$(find tools tests/rf27-g25/f06 -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G25_F06_GREEN native_assertions=38 events_max=4096 fields_max=32 labels_max=8 metrics_max=64 histogram_buckets=16 spans_max=128 local_sink_capability=yes logs=yes counters=yes histograms=yes nested_spans=yes double_close_denied=yes drop_counter=yes redaction_pre_sink=yes remote_telemetry=no raw_secret_leaks=0 deterministic=yes stack_front_object_green=yes stack_combined_historical_g12_red=6 static_elf=yes no_c_no_libc=yes'
