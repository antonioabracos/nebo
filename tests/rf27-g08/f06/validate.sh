#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g08-f06
build/tests/rf27-g08/f06/collision_test
build/tests/rf27-g08/f06/collision_test
bash tests/rf27-g08/f05/validate.sh >/dev/null
tmp="$(mktemp -d /tmp/neboc-rf27-g08-f06.XXXXXX)"
trap 'rm -rf -- "$tmp"' EXIT
nasm -f elf64 -I. -o "$tmp/a.o" tests/rf27-g08/f06/collision_test.asm
nasm -f elf64 -I. -o "$tmp/b.o" tests/rf27-g08/f06/collision_test.asm
cmp -s "$tmp/a.o" "$tmp/b.o"
printf '%s\n' 'RF27_G08_F06_GREEN native=10 collision_cluster=6 probe_exhaustion=atomic tombstone_reuse=yes reseed_rehash=yes invariants=counts_states_hashes deterministic_replay=2 security_claim=bounded_non_crypto f05=yes'
