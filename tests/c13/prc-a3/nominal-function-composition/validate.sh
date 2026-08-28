#!/usr/bin/env bash
set -euo pipefail
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy
repo=$(cd "$(dirname "$0")/../../../.." && pwd)
neboc=${NEBOC:-$repo/build/bin/neboc}
fixture=$repo/tests/c13/prc-a3/nominal-function-composition/prefix-085.no
tmp=$(mktemp -d /tmp/nebo-c13-prc-a3-nominal-function-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT
"$neboc" check "$fixture"
"$neboc" emit-asm "$fixture" -o "$tmp/prefix-085.asm"
"$neboc" build "$fixture" -o "$tmp/prefix-085.elf"
printf 'enum State { Idle, Idle }\n(Int.self)helper(){0.return;}\nstart(){0.helper();0.return;}\n' > "$tmp/duplicate.no"
if "$neboc" check "$tmp/duplicate.no" >"$tmp/duplicate.stdout" 2>"$tmp/duplicate.stderr"; then
    echo 'duplicate nominal declaration unexpectedly accepted' >&2
    exit 1
fi
test -s "$tmp/duplicate.stderr"
printf 'A3_NOMINAL_FUNCTION_COMPOSITION=PASS\n'
