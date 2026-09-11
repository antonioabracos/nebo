#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g09-f03
build/tests/rf27-g09/f03/graph_test
bash tests/rf27-g09/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G09_F03_GREEN native=15 graph=96/8 storage=40/8 nodes=1..32 edges=256 directed=yes undirected=yes self=explicit duplicate=reject multi=deferred weights=nonnegative incident_cleanup=yes generation_handles=yes borrow_gate=yes f02=yes'
