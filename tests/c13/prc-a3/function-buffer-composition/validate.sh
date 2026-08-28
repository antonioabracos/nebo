#!/usr/bin/env bash
set -euo pipefail
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy
repo=$(cd "$(dirname "$0")/../../../.." && pwd)
neboc=${NEBOC:-$repo/build/bin/neboc}
fixture=$repo/tests/c13/prc-a3/function-buffer-composition/prefix-017.no
tmp=$(mktemp -d /tmp/nebo-c13-prc-a3-function-buffer-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT
"$neboc" check "$fixture"
"$neboc" emit-asm "$fixture" -o "$tmp/prefix-017.asm"
"$neboc" build "$fixture" -o "$tmp/prefix-017.elf"
test "$(grep -c '^start(){' "$fixture")" -eq 1
test "$(grep -c '^global nebo_fn_' "$tmp/prefix-017.asm")" -eq 16
printf 'A3_FUNCTION_BUFFER_COMPOSITION=PASS\n'
