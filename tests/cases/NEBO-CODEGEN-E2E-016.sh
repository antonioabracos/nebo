#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root=$(cd "$(dirname "$0")/../.." && pwd)
cd "$root"
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT HUP INT TERM
build/bin/neboc build tests/e2e/core/arithmetic/division-zero.no -o "$tmp/program"
status=0
if timeout 5s "$tmp/program" >"$tmp/stdout" 2>"$tmp/stderr"; then
    status=0
else
    status=$?
fi
[ "$status" -eq 173 ]
[ ! -s "$tmp/stdout" ]
[ ! -s "$tmp/stderr" ]
./scripts/mf037/verify-no-c-structural.sh "$tmp/program" >/dev/null
echo NEBO_CODEGEN_E2E_016_GREEN
