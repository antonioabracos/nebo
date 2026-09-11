#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g09-f05
build/tests/rf27-g09/f05/algorithms_test
bash tests/rf27-g09/f04/validate.sh >/dev/null
printf '%s\n' 'RF27_G09_F05_GREEN native=11 scratch=40/8 capacity=32 reachable=BFS topological=Kahn_slot_order cycle=typed_error shortest=unweighted_BFS canonical_tie=yes unreachable=empty self_path=one failure_atomic_length=yes f04=yes'
