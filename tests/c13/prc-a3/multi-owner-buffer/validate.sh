#!/usr/bin/env bash
set -euo pipefail
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy

repo=$(cd "$(dirname "$0")/../../../.." && pwd)
neboc=${NEBOC:-$repo/build/bin/neboc}
fixture=$repo/tests/c13/prc-a3/multi-owner-buffer/prefix-006.no
tmp=$(mktemp -d /tmp/nebo-c13-prc-a3-buffer-test-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT

"$neboc" check "$fixture"
"$neboc" emit-asm "$fixture" -o "$tmp/prefix-006.asm"
"$neboc" build "$fixture" -o "$tmp/prefix-006.elf"
"$tmp/prefix-006.elf"

for count in 1 2 4 5 6 7 8 16 32 64 100 128 207 256; do
  source=$tmp/owners-$count.no
  {
    printf 'start(){\n'
    owner=0
    while (( owner < count )); do
      printf 'Buffer.zeroed(0).owner%03d;\n' "$owner"
      owner=$((owner + 1))
    done
    printf '0.return;\n}\n'
  } > "$source"
  "$neboc" check "$source"
done

cat > "$tmp/interleaved.no" <<'SOURCE'
start(){
    Buffer.zeroed(1).first;
    Buffer.zeroed(4).second;
    second.set(3, 99).priorSecond;
    first.set(0, 7).priorFirst;
    second.freeze().frozenSecond;
    first.at(0).observedFirst;
    frozenSecond.at(3).observedSecond;
    0.return;
}
SOURCE
"$neboc" check "$tmp/interleaved.no"
"$neboc" build "$tmp/interleaved.no" -o "$tmp/interleaved.elf"
set +e
"$tmp/interleaved.elf"
interleaved_exit=$?
set -e
test "$interleaved_exit" -eq 7

cat > "$tmp/duplicate.no" <<'SOURCE'
start(){
    Buffer.zeroed(1).sameOwner;
    Buffer.zeroed(4).sameOwner;
    0.return;
}
SOURCE
if "$neboc" check "$tmp/duplicate.no" >"$tmp/duplicate.stdout" 2>"$tmp/duplicate.stderr"; then
  echo 'duplicate owner unexpectedly accepted' >&2
  exit 1
fi
test -s "$tmp/duplicate.stderr"

cat > "$tmp/receiver-sensitive-invalid.no" <<'SOURCE'
start(){
    Buffer.zeroed(1).first;
    Buffer.zeroed(4).second;
    second.set(3, 99).priorSecond;
    first.at(3).invalidFirstRead;
    0.return;
}
SOURCE
if "$neboc" check "$tmp/receiver-sensitive-invalid.no" >"$tmp/invalid.stdout" 2>"$tmp/invalid.stderr"; then
  echo 'receiver-sensitive bounds violation unexpectedly accepted' >&2
  exit 1
fi
test -s "$tmp/invalid.stderr"

source=$tmp/owners-257.no
{
  printf 'start(){\n'
  owner=0
  while (( owner < 257 )); do
    printf 'Buffer.zeroed(0).owner%03d;\n' "$owner"
    owner=$((owner + 1))
  done
  printf '0.return;\n}\n'
} > "$source"
if "$neboc" check "$source" >"$tmp/capacity.stdout" 2>"$tmp/capacity.stderr"; then
  echo 'owner capacity + 1 unexpectedly accepted' >&2
  exit 1
fi
test -s "$tmp/capacity.stderr"
rejected_asm=$tmp/owners-257.asm
if "$neboc" emit-asm "$source" -o "$rejected_asm" >"$tmp/capacity-emit.stdout" 2>"$tmp/capacity-emit.stderr"; then
  echo 'owner capacity + 1 unexpectedly emitted ASM' >&2
  exit 1
fi
test ! -e "$rejected_asm"

printf 'A3_MULTI_OWNER_BUFFER=PASS\n'
