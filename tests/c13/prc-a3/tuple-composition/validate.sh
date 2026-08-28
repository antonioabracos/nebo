#!/usr/bin/env bash
set -euo pipefail
unset DISPLAY XAUTHORITY WAYLAND_DISPLAY HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy
repo=$(cd "$(dirname "$0")/../../../.." && pwd)
neboc=${NEBOC:-$repo/build/bin/neboc}
tmp=$(mktemp -d /tmp/nebo-c13-prc-a3-tuple-XXXXXXXX)
trap 'rm -rf -- "$tmp"' EXIT
printf 'start(){ Tuple.of(2,3).pair; pair.at<0>().return; }\n' > "$tmp/tuple.no"
"$neboc" check "$tmp/tuple.no"
"$neboc" emit-asm "$tmp/tuple.no" -o "$tmp/tuple.asm"
"$neboc" build "$tmp/tuple.no" -o "$tmp/tuple.elf"
set +e
"$tmp/tuple.elf"
rc=$?
set -e
test "$rc" -eq 2
printf 'start(){ Tuple.of(2,3).pair; pair.at<2>().return; }\n' > "$tmp/out-of-range.no"
if "$neboc" check "$tmp/out-of-range.no" >"$tmp/out.stdout" 2>"$tmp/out.stderr"; then
    echo 'tuple projection outside arity unexpectedly accepted' >&2
    exit 1
fi
test -s "$tmp/out.stderr"
printf 'A3_TUPLE_COMPOSITION=PASS\n'
