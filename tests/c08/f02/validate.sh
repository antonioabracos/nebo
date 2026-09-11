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
ninja -f build.ninja -j1 c08-f02-tests
build/tests/c08/f02/list_construction_test
test "$(nm -u build/tests/c08/f02/list_construction_test | wc -l)" -eq 0
file build/tests/c08/f02/list_construction_test | rg -q 'statically linked'
! readelf -lW build/tests/c08/f02/list_construction_test | rg -q INTERP
printf '%s\n' 'C08_F02_GREEN constructors=4 modes=new_withCapacity_from_fill storage=caller_bounded type=Int_trivial failure_atomic=yes static_elf=yes'
