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
ninja -f build.ninja -j1 c08-f04-tests
build/tests/c08/f04/list_access_test
test -z "$(nm -u build/tests/c08/f04/list_access_test)"
printf '%s\n' 'C08_F04_GREEN queries=length_capacity_empty_first_last access=at_get oob=checked empty=found0 payload_atomic=yes'
