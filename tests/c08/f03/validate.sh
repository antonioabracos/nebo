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
ninja -f build.ninja -j1 c08-f03-tests
build/tests/c08/f03/list_capacity_test
file build/tests/c08/f03/list_capacity_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/c08/f03/list_capacity_test)"
printf '%s\n' 'C08_F03_GREEN growth=max_4_double_required limits=64_elements_4096_bytes reserve=explicit_storage oom_atomic=yes overflow_atomic=yes'
