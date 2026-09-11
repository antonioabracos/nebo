#!/usr/bin/env bash
set -euo pipefail
repo=$(cd "$(dirname "$0")/../../.." && pwd)
root=${TMPDIR:-/tmp}/nebo-c11-f13-renamed-root
mkdir -p "$root/arbitrary/location"
source="$root/arbitrary/location/not-a-fixture.no"
cp "$repo/tests/c11/f13/positive/filled.no" "$source"
sed -i 's/filled(2, 3, 7)/filled(3, 2, 5)/' "$source"
"$repo/build/bin/neboc" check "$source"
"$repo/build/bin/neboc" emit-asm "$source" -o "$root/renamed.asm"
TMPDIR="$root" "$repo/build/bin/neboc" build "$source" -o "$root/renamed.elf"
set +e
"$root/renamed.elf"
actual=$?
set -e
test "$actual" -eq 30
! rg -q 'not-a-fixture|arbitrary/location|filled\(3, 2, 5\)' "$repo/compiler" "$repo/build.ninja"
