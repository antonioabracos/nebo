#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g09-f04
build/tests/rf27-g09/f04/traversal_test
bash tests/rf27-g09/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G09_F04_GREEN native=12 traversal=80/8 kinds=BFS_DFS capacity=32 deterministic=slot_order scratch=caller handles=authenticated graph_generation=authenticated borrow=lexical mutation_gate=yes release=yes f03=yes'
