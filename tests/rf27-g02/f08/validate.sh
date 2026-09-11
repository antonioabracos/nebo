#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
ninja -f build.ninja build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g02-f08.XXXXXX)
positive_count=0

expected_exit() {
  case "$1" in
    bounded-mutable-control) echo 0 ;;
    bounded-range-for) echo 2 ;;
    non-local-return-cleanup) echo 22 ;;
    *) return 1 ;;
  esac
}

for source in tests/rf27-g02/f08/positive/*.no; do
  name=$(basename "$source" .no)
  asm_a="$tmp_root/$name.a.asm"
  asm_b="$tmp_root/$name.b.asm"
  elf_a="$tmp_root/$name.a"
  elf_b="$tmp_root/$name.b"
  build/bin/neboc check "$source" >"$tmp_root/$name.check.stdout" 2>"$tmp_root/$name.check.stderr"
  test ! -s "$tmp_root/$name.check.stdout"
  test ! -s "$tmp_root/$name.check.stderr"
  build/bin/neboc emit-asm "$source" -o "$asm_a" >"$tmp_root/$name.emit.stdout" 2>"$tmp_root/$name.emit.stderr"
  build/bin/neboc emit-asm "$source" -o "$asm_b" >"$tmp_root/$name.emit2.stdout" 2>"$tmp_root/$name.emit2.stderr"
  test ! -s "$tmp_root/$name.emit.stdout"
  test ! -s "$tmp_root/$name.emit.stderr"
  test ! -s "$tmp_root/$name.emit2.stdout"
  test ! -s "$tmp_root/$name.emit2.stderr"
  cmp -s "$asm_a" "$asm_b"
  build/bin/neboc build "$source" -o "$elf_a" >"$tmp_root/$name.build.stdout" 2>"$tmp_root/$name.build.stderr"
  build/bin/neboc build "$source" -o "$elf_b" >"$tmp_root/$name.build2.stdout" 2>"$tmp_root/$name.build2.stderr"
  test ! -s "$tmp_root/$name.build.stdout"
  test ! -s "$tmp_root/$name.build.stderr"
  test ! -s "$tmp_root/$name.build2.stdout"
  test ! -s "$tmp_root/$name.build2.stderr"
  cmp -s "$elf_a" "$elf_b"
  set +e
  "$elf_a" >"$tmp_root/$name.native.stdout" 2>"$tmp_root/$name.native.stderr"
  native_exit=$?
  set -e
  test "$native_exit" -eq "$(expected_exit "$name")"
  test ! -s "$tmp_root/$name.native.stdout"
  test ! -s "$tmp_root/$name.native.stderr"
  file "$elf_a" | rg -q 'ELF 64-bit.*x86-64.*statically linked'
  ! readelf -lW "$elf_a" | rg -q INTERP
  test -z "$(nm -u "$elf_a")"
  positive_count=$((positive_count+1))
done

rg -q '^\._loop_header' "$tmp_root/bounded-mutable-control.a.asm"
rg -q '^\._loop_exit' "$tmp_root/bounded-mutable-control.a.asm"
rg -q '^\._for_header' "$tmp_root/bounded-range-for.a.asm"
rg -q '^\._for_latch' "$tmp_root/bounded-range-for.a.asm"
rg -q '^\._for_exit' "$tmp_root/bounded-range-for.a.asm"
rg -q '^    mov rax, 22$' "$tmp_root/non-local-return-cleanup.a.asm"

echo 'RF27_G02_F08_STAGE=f02'
bash scripts/rf27-g02/validate-f02.sh >/dev/null
echo 'RF27_G02_F08_STAGE=f03'
bash scripts/rf27-g02/validate-f03.sh >/dev/null
echo 'RF27_G02_F08_STAGE=f04'
bash scripts/rf27-g02/validate-f04.sh >/dev/null
echo 'RF27_G02_F08_STAGE=f06'
bash scripts/rf27-g02/validate-f06.sh >/dev/null
echo 'RF27_G02_F08_STAGE=f07'
bash tests/rf27-g02/f07/validate.sh >/dev/null
echo 'RF27_G02_F08_STAGE=g04_f04_cleanup'
bash tests/rf27-g04/f04/validate.sh >/dev/null
echo 'RF27_G02_F08_STAGE=successor_public_ladder'
bash scripts/rf27-g01/validate-successor-boundary.sh >/dev/null

public_count=0
while IFS= read -r source; do
  build/bin/neboc check "$source" >"$tmp_root/public-$public_count.stdout" 2>"$tmp_root/public-$public_count.stderr"
  test ! -s "$tmp_root/public-$public_count.stdout"
  test ! -s "$tmp_root/public-$public_count.stderr"
  public_count=$((public_count+1))
done < <(find examples/minimal examples/evolution -type f -name '*.no' | sort)
test "$public_count" -eq 36

ladder_result=$(python3 tests/post-rc1-coherence/ladder-v12.py)
test "$ladder_result" = 'POST_RC1_LADDER_V12_GREEN steps=36 blocks=16 executable_pass=16 non_executable=0'

echo "RF27_G02_F08_GREEN integration=$positive_count deterministic_asm=$positive_count deterministic_elf=$positive_count static_elf=$positive_count full_g02=yes g04_cleanup=yes public_examples=$public_count ladder=16/16 successor_boundary=yes rc2=yes tmp=$tmp_root"
