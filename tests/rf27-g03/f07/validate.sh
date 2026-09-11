#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
ninja -f build.ninja build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g03-f07.XXXXXX)
positive_count=0

expected_exit() {
  case "$1" in
    bounded-parameters) echo 6 ;;
    bounded-overload) echo 20 ;;
    bounded-callable) echo 33 ;;
    *) return 1 ;;
  esac
}

for source in tests/rf27-g03/f07/positive/*.no; do
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

echo 'RF27_G03_F07_STAGE=f02'
bash tests/rf27-g03/f02/validate.sh >/dev/null
echo 'RF27_G03_F07_STAGE=f03'
bash tests/rf27-g03/f03/validate.sh >/dev/null
echo 'RF27_G03_F07_STAGE=f04'
bash tests/rf27-g03/f04/validate.sh >/dev/null
echo 'RF27_G03_F07_STAGE=f05'
bash tests/rf27-g03/f05/validate.sh >/dev/null
echo 'RF27_G03_F07_STAGE=f06'
bash tests/rf27-g03/f06/validate.sh >/dev/null

public_count=0
while IFS= read -r source; do
  build/bin/neboc check "$source" >"$tmp_root/public-$public_count.stdout" 2>"$tmp_root/public-$public_count.stderr"
  test ! -s "$tmp_root/public-$public_count.stdout"
  test ! -s "$tmp_root/public-$public_count.stderr"
  public_count=$((public_count+1))
done < <(find examples/minimal examples/evolution -type f -name '*.no' | sort)
test "$public_count" -eq 39

ladder_result=$(python3 tests/post-rc1-coherence/ladder-v12.py)
test "$ladder_result" = 'POST_RC1_LADDER_V12_GREEN steps=36 blocks=16 executable_pass=16 non_executable=0'
bash scripts/rf27-g01/validate-successor-boundary.sh >/dev/null

echo "RF27_G03_F07_GREEN integration=$positive_count deterministic_asm=$positive_count deterministic_elf=$positive_count static_elf=$positive_count full_g03=yes units=3 static_objects=5 cache_max=12 public_examples=$public_count ladder=16/16 rc2=yes tmp=$tmp_root"
