#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
: "${PYTHONPYCACHEPREFIX:?external Python cache prefix required}"
case "$PYTHONPYCACHEPREFIX" in "$repo"/*) echo 'repository Python cache prefix forbidden' >&2; exit 1;; esac
export PYTHONDONTWRITEBYTECODE=1
work="$(mktemp -d "$repo/build/tmp/c08-f13.XXXXXX")"
trap 'rm -rf -- "$work"' EXIT
export TMPDIR="$work/tmp"
mkdir -p "$TMPDIR" "$work/obj-a" "$work/obj-b" "$work/bin-a" "$work/bin-b"

ninja -f build.ninja -j1 c08-f13-tests
for front in 02 03 04 05 06 07 08 09 10 11 12; do
  bash "tests/c08/f$front/validate.sh" >/dev/null
done

python3 -B tests/c08/f13/collection_corpus.py "$work/corpus" >"$work/corpus.log"
grep -Fq 'positive=16 boundary=16 fuzz=32 traces=64 operations=2048' "$work/corpus.log"
start_ns="$(date +%s%N)"
positive=0; boundary=0; fuzz=0; traces=0; operations=0
while IFS=$'\t' read -r case_id family category relative count; do
  [[ $case_id == case_id ]] && continue
  source="$work/corpus/$relative"
  nasm -f elf64 -Wall -Werror -I. -o "$work/obj-a/$case_id.o" "$source"
  nasm -f elf64 -Wall -Werror -I. -o "$work/obj-b/$case_id.o" "$source"
  cmp "$work/obj-a/$case_id.o" "$work/obj-b/$case_id.o"
  case "$family" in
    list) objects=(build/obj/list_runtime.o build/obj/list_semantic.o);;
    stack) objects=(build/obj/stack.o build/obj/list_runtime.o build/obj/list_semantic.o);;
    queue|deque) objects=(build/obj/ring.o);;
    *) exit 1;;
  esac
  ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$work/bin-a/$case_id" "$work/obj-a/$case_id.o" "${objects[@]}"
  ld -m elf_x86_64 -nostdlib -z noexecstack --build-id=none -o "$work/bin-b/$case_id" "$work/obj-b/$case_id.o" "${objects[@]}"
  cmp "$work/bin-a/$case_id" "$work/bin-b/$case_id"
  timeout 5 "$work/bin-a/$case_id"
  ! readelf -lW "$work/bin-a/$case_id" | grep -q INTERP
  ! readelf -dW "$work/bin-a/$case_id" | grep -q '(NEEDED)'
  traces=$((traces + 1)); operations=$((operations + count))
  case "$category" in POSITIVE) positive=$((positive + 1));; BOUNDARY) boundary=$((boundary + 1));; FUZZ) fuzz=$((fuzz + 1));; esac
done < "$work/corpus/MANIFEST.tsv"
elapsed_ns=$(( $(date +%s%N) - start_ns ))
test "$positive" -eq 16
test "$boundary" -eq 16
test "$fuzz" -eq 32
test "$traces" -eq 64
test "$operations" -eq 2048
test "$elapsed_ns" -lt 30000000000

python3 -B compiler/sdk/sdk_builder.py build --repo "$repo" --neboc "$repo/build/bin/neboc" --output "$work/sdk-a" --profile sdk >"$work/sdk-a.json"
python3 -B compiler/sdk/sdk_builder.py build --repo "$repo" --neboc "$repo/build/bin/neboc" --output "$work/sdk-b" --profile sdk >"$work/sdk-b.json"
python3 -B compiler/sdk/sdk_builder.py verify "$work/sdk-a" >"$work/sdk-a.verify.json"
python3 -B compiler/sdk/sdk_builder.py verify "$work/sdk-b" >"$work/sdk-b.verify.json"
diff -qr "$work/sdk-a" "$work/sdk-b"
python3 -B compiler/sdk/sdk_builder.py archive "$work/sdk-a" "$work/sdk-a.tar" >"$work/sdk-a.archive.json"
python3 -B compiler/sdk/sdk_builder.py archive "$work/sdk-b" "$work/sdk-b.tar" >"$work/sdk-b.archive.json"
cmp "$work/sdk-a.tar" "$work/sdk-b.tar"
test "$(python3 -B -c 'import json,sys; print(json.load(open(sys.argv[1]))["network_required"])' "$work/sdk-a/MANIFEST.json")" = False
test -z "$(nm -u "$work/sdk-a/build/bin/neboc")"
! readelf -lW "$work/sdk-a/build/bin/neboc" | grep -q INTERP
! readelf -dW "$work/sdk-a/build/bin/neboc" | grep -q '(NEEDED)'

mkdir -p "$work/clean-root"
cp "$work/sdk-a/share/examples/sdk/determinism.no" "$work/clean-root/main.no"
(cd "$work/clean-root" && "$work/sdk-a/bin/neboc" check main.no)
(cd "$work/clean-root" && "$work/sdk-a/bin/neboc" emit-asm main.no -o main.asm)
(cd "$work/clean-root" && TMPDIR="$TMPDIR" "$work/sdk-a/bin/neboc" build main.no -o main.elf)
test -s "$work/clean-root/main.asm"
test -x "$work/clean-root/main.elf"
status=0
"$work/clean-root/main.elf" || status=$?
test "$status" -eq 113

test -z "$(find . -path ./.git -prune -o \( -type d -name __pycache__ -o -type f -name '*.pyc' -o -type f -name '*.pyo' \) -print -quit)"
printf 'C08_F13_GREEN positive=%s boundary=%s fuzz=%s traces=%s operations=%s elapsed_ns=%s sdk_bundle_deterministic=yes sdk_archive_deterministic=yes clean_root=yes static_elf=yes native_object_and_elf_deterministic=yes hidden_allocation=no\n' "$positive" "$boundary" "$fuzz" "$traces" "$operations" "$elapsed_ns"
