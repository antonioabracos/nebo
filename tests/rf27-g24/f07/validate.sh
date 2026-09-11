#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f07-tests >/dev/null
build/tests/rf27-g24/f07/debug_metadata_test
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
python3 tests/rf27-g24/f07/debug_metadata_oracle.py > "$tmp_root/a"
python3 tests/rf27-g24/f07/debug_metadata_oracle.py > "$tmp_root/b"
cmp "$tmp_root/a" "$tmp_root/b"
cat "$tmp_root/a"
file build/tests/rf27-g24/f07/debug_metadata_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f07/debug_metadata_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f07/debug_metadata_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/debug_metadata.o
test -z "$(find tests/rf27-g24/f07 -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G24_F07_GREEN native_assertions=28 spans_oracle=10000 sources_max=4096 frames_max=64 bindings_max=256 source_map=yes nonoverlap=yes pointer_free_encoding=yes version=1 redacted_secret_binding=yes deterministic_object_metadata=yes stack_alignment=yes static_elf=yes no_c_no_libc=yes source_syntax=not_activated'
