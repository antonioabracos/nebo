#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../../.." && pwd)
cd "$repo_root"
ninja -f build.ninja build/bin/neboc >/dev/null
tmp_root=$(mktemp -d /tmp/neboc-rf27-g05-f07.XXXXXX)
positive_count=0

expected_exit() {
  case "$1" in
    option-some) echo 42 ;;
    result-map) echo 7 ;;
    typed-propagation|exhaustive-match) echo 9 ;;
    structured-error) echo 2 ;;
    *) return 1 ;;
  esac
}

for source in tests/rf27-g05/f07/positive/*.no; do
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
  cmp -s "$asm_a" "$asm_b"
  build/bin/neboc build "$source" -o "$elf_a" >"$tmp_root/$name.build.stdout" 2>"$tmp_root/$name.build.stderr"
  build/bin/neboc build "$source" -o "$elf_b" >"$tmp_root/$name.build2.stdout" 2>"$tmp_root/$name.build2.stderr"
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

for front in f02 f03 f04 f05 f06; do
  echo "RF27_G05_F07_STAGE=$front"
  bash "tests/rf27-g05/$front/validate.sh" >/dev/null
done

public_count=0
while IFS= read -r source; do
  build/bin/neboc check "$source" >"$tmp_root/public-$public_count.stdout" 2>"$tmp_root/public-$public_count.stderr"
  test ! -s "$tmp_root/public-$public_count.stdout"
  test ! -s "$tmp_root/public-$public_count.stderr"
  public_count=$((public_count+1))
done < <(find examples/minimal examples/evolution/rf27-g05 -type f -name '*.no' | sort)
# This historical closeout owns the minimal and RF27-G05 examples only.
# Later evolution fixtures have their own authorities and may intentionally
# demonstrate syntax that a subsequent Registry group made non-canonical.
test "$public_count" -eq 8
# Historical roadmap code blocks are not a current G005 authority. The live
# example corpus and corrected catalog sources are validated directly above.
ninja -f build.ninja -j2 rf204-g005-integration-tests >/dev/null
build/tests/rf204/G005/system_error_integration_test

echo "RF27_G05_F07_GREEN integration=$positive_count deterministic_asm=$positive_count deterministic_elf=$positive_count static_elf=$positive_count full_g05=yes lazy_cleanup_match_error=yes public_examples=$public_count historical_roadmap=not_authoritative historical_release_inventory=not_authoritative external_file_network=2/2 tmp=$tmp_root"
