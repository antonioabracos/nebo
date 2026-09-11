#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
compiler=${NEBOC:-"$repo_root/build/bin/neboc"}
if [[ -z ${NEBOC:-} ]]; then
  ninja -C "$repo_root" -f build.ninja build/bin/neboc >/dev/null
fi

tmp_base=${TMPDIR:-/tmp}
work=$(mktemp -d "$tmp_base/nebo-c02-f10-persistent.XXXXXX")
positive_count=0

expected_exit() {
  case "$1" in
    array-sret-branch-return) echo 4 ;;
    branch-both-return) echo 3 ;;
    early-plus-final-return) echo 5 ;;
    multiple-functions) echo 1 ;;
    nested-all-paths-return) echo 2 ;;
    terminating) echo 7 ;;
    *) return 1 ;;
  esac
}

run_case() {
  local source=$1 name asm_a asm_b elf_a elf_b native_exit label_result
  name=$(basename "$source" .no)
  asm_a="$work/$name.a.asm"
  asm_b="$work/$name.b.asm"
  elf_a="$work/$name.a.elf"
  elf_b="$work/$name.b.elf"

  "$compiler" check "$source" >"$work/$name.check.stdout" 2>"$work/$name.check.stderr"
  test ! -s "$work/$name.check.stdout"
  test ! -s "$work/$name.check.stderr"
  "$compiler" emit-asm "$source" -o "$asm_a" >"$work/$name.emit-a.stdout" 2>"$work/$name.emit-a.stderr"
  "$compiler" emit-asm "$source" -o "$asm_b" >"$work/$name.emit-b.stdout" 2>"$work/$name.emit-b.stderr"
  test ! -s "$work/$name.emit-a.stdout"
  test ! -s "$work/$name.emit-a.stderr"
  test ! -s "$work/$name.emit-b.stdout"
  test ! -s "$work/$name.emit-b.stderr"
  cmp -s "$asm_a" "$asm_b"

  awk -f "$repo_root/tests/rf27-g02/f10/audit-return-labels.awk" "$asm_a" >"$work/$name.labels"
  label_result=$(cat "$work/$name.labels")
  case "$name" in
    branch-both-return)
      test "$label_result" = 'SUMMARY refs=2 defs=1 unresolved=0 duplicate=0 cross_function=0'
      ;;
  esac

  "$compiler" build "$source" -o "$elf_a" >"$work/$name.build-a.stdout" 2>"$work/$name.build-a.stderr"
  "$compiler" build "$source" -o "$elf_b" >"$work/$name.build-b.stdout" 2>"$work/$name.build-b.stderr"
  test ! -s "$work/$name.build-a.stdout"
  test ! -s "$work/$name.build-a.stderr"
  test ! -s "$work/$name.build-b.stdout"
  test ! -s "$work/$name.build-b.stderr"
  cmp -s "$elf_a" "$elf_b"

  set +e
  timeout 5s "$elf_a" >"$work/$name.native.stdout" 2>"$work/$name.native.stderr"
  native_exit=$?
  set -e
  test "$native_exit" -eq "$(expected_exit "$name")"
  test ! -s "$work/$name.native.stdout"
  test ! -s "$work/$name.native.stderr"
  file "$elf_a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$elf_a" | rg -q INTERP
  test -z "$(nm -u "$elf_a")"
  positive_count=$((positive_count+1))
}

for source in "$repo_root"/tests/rf27-g02/f10/positive/*.no; do
  run_case "$source"
done
run_case "$repo_root/tests/npt-lang-35/linear-int-direct-self-recursion/positive/terminating.no"

test "$positive_count" -eq 6
echo "C02_F10_PERSISTENT_GREEN positives=$positive_count deterministic_asm=$positive_count deterministic_elf=$positive_count label_def_use=$positive_count static_elf=$positive_count runtime=$positive_count tmp=$work"
