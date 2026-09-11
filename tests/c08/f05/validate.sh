#!/usr/bin/env bash
set -euo pipefail
script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
source_root="${NEBO_REPO_ROOT-$script_dir/../../..}"
if [[ -z "$source_root" || ! -d "$source_root" ]]; then
    printf '%s\n' 'nebo: invalid source root' >&2
    exit 2
fi
repo="$(CDPATH= cd -- "$source_root" && pwd -P)"
if [[ ! -f "$repo/build.ninja" || ! -d "$repo/runtime/collections" ]]; then
    printf '%s\n' 'nebo: source root is missing build.ninja or collection sources' >&2
    exit 2
fi
cd -- "$repo"
export PYTHONDONTWRITEBYTECODE=1
export PYTHONPYCACHEPREFIX="$repo/build/python-cache"
ninja -f build.ninja -j1 c08-f05-tests
build/tests/c08/f05/list_mutation_test
test -z "$(nm -u build/tests/c08/f05/list_mutation_test)"
printf '%s\n' 'C08_F05_GREEN mutations=append_insert_set_remove_pop_swap_clear scratch=64 alias_insert=yes zero_removed=yes failure_atomic=yes'
