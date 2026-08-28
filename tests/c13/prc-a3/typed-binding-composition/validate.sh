#!/usr/bin/env bash
set -euo pipefail
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy
repo=$(cd "$(dirname "$0")/../../../.." && pwd)
neboc=${NEBOC:-$repo/build/bin/neboc}
fixture=$repo/tests/c13/prc-a3/typed-binding-composition/prefix-051.no
tmp=$(mktemp -d /tmp/nebo-c13-prc-a3-typed-binding-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT
"$neboc" check "$fixture"
"$neboc" emit-asm "$fixture" -o "$tmp/prefix-051.asm"
"$neboc" build "$fixture" -o "$tmp/prefix-051.elf"
printf 'start(){ 1.value; Text declared; value.declared; 0.return; }\n' > "$tmp/mismatched.no"
if "$neboc" check "$tmp/mismatched.no" >"$tmp/mismatched.stdout" 2>"$tmp/mismatched.stderr"; then
    echo 'typed-binding mismatch unexpectedly accepted' >&2
    exit 1
fi
test -s "$tmp/mismatched.stderr"
printf 'A3_TYPED_BINDING_COMPOSITION=PASS\n'
