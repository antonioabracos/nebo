#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g09-f02
build/tests/rf27-g09/f02/tree_test
rg -q '^%define NEBO_HANDLE_SIZE 8$' compiler/semantic/graph/graph_contract.inc
rg -q '^%define NEBO_TREE_SIZE 72$' compiler/semantic/graph/graph_contract.inc
rg -q '^%define nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical 32$' compiler/semantic/graph/graph_contract.inc
printf '%s\n' 'RF27_G09_F02_GREEN native=14 tree=72/8 capacity=1..32 handles=index_generation operations=init_add_get_replace_parent_children_reparent_remove_subtree stale_rejected=yes cycle_rejected=yes borrow_gate=yes failure_atomic=yes f01=yes'
