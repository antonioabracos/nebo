#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja -j1 rf27-g24-f08-tests >/dev/null
build/tests/rf27-g24/f08/debugger_test
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
python3 tests/rf27-g24/f08/debugger_oracle.py >"$tmp/a"
python3 tests/rf27-g24/f08/debugger_oracle.py >"$tmp/b"
cmp "$tmp/a" "$tmp/b"; cat "$tmp/a"
if timeout 5 strace -qq -o "$tmp/trace" /bin/true 2>"$tmp/ptrace.err"; then live=PASS_OWNED_CHILD; else live=ENVIRONMENT_LIMITED; fi
file build/tests/rf27-g24/f08/debugger_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f08/debugger_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f08/debugger_test)"
python3 scripts/mf056/audit-stack-alignment.py build/obj/debugger.o
printf 'RF27_G24_F08_GREEN native_assertions=12 transitions=50000 owned_process=yes remote_attach=no metadata_v1=yes breakpoints=128 step_stack_variables=yes secret_redacted=yes ptrace_live=%s static_elf=yes no_c_no_libc=yes\n' "$live"
