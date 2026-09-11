#!/usr/bin/env sh
set -eu
root=${NEBO_REPO_ROOT:?NEBO_REPO_ROOT is required}; cd "$root"
ninja neboc >/dev/null
tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
cp tests/cli/fixtures/valid.no "$tmp/input.no"
build/bin/neboc emit-asm "$tmp/input.no" -o "$tmp/a.asm"
build/bin/neboc emit-asm -o "$tmp/b.asm" "$tmp/input.no"
cmp -s "$tmp/a.asm" "$tmp/b.asm"
[ "$(sha256sum "$tmp/a.asm" | awk '{print $1}')" = "$(sha256sum "$tmp/b.asm" | awk '{print $1}')" ]
