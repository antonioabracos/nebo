#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -j1 rf27-g24-f03-tests >/dev/null
build/tests/rf27-g24/f03/repl_test
python3 tests/rf27-g24/f03/session_oracle.py

temp_root="$(mktemp -d /tmp/rf27-g24-f03.XXXXXX)"
trap 'rm -rf "$temp_root"' EXIT
valid="$repo/tests/cli/fixtures/valid.no"
invalid="$repo/tests/cli/fixtures/invalid.no"
{
  printf 'load %q\n' "$valid"
  printf 'typeOf %q\n' "$valid"
  printf 'ast %q\n' "$valid"
  printf 'evaluate %q\n' "$valid"
  printf 'history\nreset\nhistory\nquit\n'
} > "$temp_root/session.txt"
tools/rf27-repl.py --script "$temp_root/session.txt" > "$temp_root/run-a.txt"
tools/rf27-repl.py --script "$temp_root/session.txt" > "$temp_root/run-b.txt"
cmp "$temp_root/run-a.txt" "$temp_root/run-b.txt"
rg -q 'type=Program.*authority=neboc-check' "$temp_root/run-a.txt"
rg -q 'ast .*status=compiler-accepted.*span=0:' "$temp_root/run-a.txt"
rg -q 'evaluate ok.*exit=0' "$temp_root/run-a.txt"
rg -q 'history count=4 generation=1' "$temp_root/run-a.txt"
rg -q 'history count=0 generation=2' "$temp_root/run-a.txt"

printf 'load %q\n' "$invalid" > "$temp_root/invalid-session.txt"
if tools/rf27-repl.py --script "$temp_root/invalid-session.txt" >/dev/null 2>&1; then
  echo 'REPL_INVALID_EXPECTED_REJECTION_RED' >&2
  exit 1
fi
truncate -s 65537 "$temp_root/oversize.no"
printf 'load %q\n' "$temp_root/oversize.no" > "$temp_root/oversize-session.txt"
if tools/rf27-repl.py --script "$temp_root/oversize-session.txt" >/dev/null 2>&1; then
  echo 'REPL_OVERSIZE_EXPECTED_REJECTION_RED' >&2
  exit 1
fi

file build/tests/rf27-g24/f03/repl_test | rg -q 'ELF 64-bit.*x86-64.*statically linked'
! readelf -lW build/tests/rf27-g24/f03/repl_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g24/f03/repl_test)"
python3 scripts/mf056/audit-stack-alignment.py build/tests/rf27-g24/f03/repl_test
test -z "$(find tools -type d -name __pycache__ -print)"
printf '%s\n' 'RF27_G24_F03_GREEN native_assertions=16 lifecycle_cases=10000 evaluate=compiler_build_execute typeOf=Program ast=compiler_admission_snapshot reset=yes history=memory_only load=bounded static_elf=yes no_c_no_libc=yes'
