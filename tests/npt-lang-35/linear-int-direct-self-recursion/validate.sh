#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
fixture_root="$repo_root/tests/npt-lang-35/linear-int-direct-self-recursion"
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
work=$(mktemp -d /tmp/nebo-npt-lang-35-test.XXXXXX)
trap 'rm -rf -- "$work"' EXIT INT TERM HUP

accept_case() {
  local name=$1 expected=$2 source="$fixture_root/positive/$1.no" actual
  "$compiler" check "$source" --message-format json-lines --color never >"$work/$name.check"
  "$compiler" emit-asm "$source" -o "$work/$name.asm"
  "$compiler" build "$source" -o "$work/$name.elf" --quiet
  set +e
  timeout 5s "$work/$name.elf" >"$work/$name.stdout" 2>"$work/$name.stderr"
  actual=$?
  set -e
  [[ $actual -eq $expected ]] || {
    echo "FAIL $name: exit=$actual expected=$expected" >&2
    exit 1
  }
  [[ ! -s $work/$name.stdout && ! -s $work/$name.stderr ]] || {
    echo "FAIL $name: recursion produced output" >&2
    exit 1
  }
}

reject_case() {
  local name=$1 expected=$2 source="$fixture_root/negative/$1.no" mode status artifact code first=
  for mode in check emit-asm build; do
    artifact="$work/$name.$mode.out"
    set +e
    if [[ $mode == check ]]; then
      "$compiler" check "$source" --message-format json-lines --color never >"$work/$name.$mode.log" 2>&1
    else
      "$compiler" "$mode" "$source" -o "$artifact" >"$work/$name.$mode.log" 2>&1
    fi
    status=$?
    set -e
    [[ $status -ne 0 && ! -e $artifact ]] || {
      echo "FAIL $name: $mode did not reject atomically" >&2
      exit 1
    }
    code=$(rg -o 'NEBO_[A-Z0-9_]+' "$work/$name.$mode.log" | sed -n '1p')
    [[ -n $code ]] || { echo "FAIL $name: missing diagnostic" >&2; exit 1; }
    [[ -z $first || $code == "$first" ]] || {
      echo "FAIL $name: diagnostic drift $first/$code" >&2
      exit 1
    }
    first=$code
  done
  [[ $first == "$expected" ]] || {
    echo "FAIL $name: diagnostic=$first expected=$expected" >&2
    exit 1
  }
}

accept_case terminating 7
accept_case depth-zero 7
accept_case depth-one 7
accept_case depth-last 7
accept_case depth-exhausted 175
accept_case sequential-roots 7
accept_case two-callers 7

reject_case mutual NEBO_CALL_RECURSION
reject_case two-self-sites NEBO_CALL_RECURSION_SHAPE
reject_case nontail NEBO_CALL_RECURSION_NONTAIL
reject_case recursive-start NEBO_PARSE_EXPECTED_TOKEN
reject_case wrong-type NEBO_CALL_RECURSION_SURFACE

asm="$work/terminating.asm"
[[ $(rg -c 'mov qword \[rsp\], 63' "$asm") -eq 1 ]]
[[ $(rg -c 'mov r10, \[rbp \+ 16\]' "$asm") -eq 1 ]]
[[ $(rg -c 'test r10, r10' "$asm") -eq 1 ]]
[[ $(rg -c 'dec r10' "$asm") -eq 1 ]]
[[ $(rg -c 'mov \[rsp\], r10' "$asm") -eq 1 ]]
[[ $(rg -c 'mov qword \[rsp \+ 8\], 0' "$asm") -eq 2 ]]
[[ $(rg -c 'call nebo_fn_2' "$asm") -eq 2 ]]
[[ $(rg -c 'add rsp, 16' "$asm") -eq 2 ]]
[[ $(rg -c 'mov eax, 60' "$asm") -eq 1 ]]
[[ $(rg -c 'mov edi, 175' "$asm") -eq 1 ]]
[[ $(rg -c '^    syscall$' "$asm") -eq 1 ]]
rg -q '^    sub rsp, 16$' "$asm"
rg -q '^    mov \[rbp-8\], rdi$' "$asm"
! rg -qi 'recursion.*runtime|__tls|getauxval|tailcall|jmp r[a-z0-9]+' "$asm"

guard_line=$(rg -n 'test r10, r10' "$asm" | cut -d: -f1)
self_block_line=$(rg -n 'mov \[rsp\], r10' "$asm" | cut -d: -f1)
(( guard_line < self_block_line ))

echo 'NPT_LANG_35_LINEAR_INT_DIRECT_SELF_RECURSION=PASS'
