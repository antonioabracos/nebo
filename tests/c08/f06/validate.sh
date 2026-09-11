#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
work="$repo/build/tmp/c08-f06-validate"
mkdir -p "$work"
ninja -f build.ninja -j1 c08-f06-tests
build/tests/c08/f06/list_algorithms_test
build/tests/rf27-g07/f03/list_algorithms_test
nasm -f elf64 -I. -o "$work/a.o" runtime/collections/list_algorithms.asm
nasm -f elf64 -I. -o "$work/b.o" runtime/collections/list_algorithms.asm
cmp "$work/a.o" "$work/b.o"
if readelf -Ws "$work/a.o" | awk '$7 == "UND" && $8 != "" && $8 !~ /^neboc_list_validate$/ { bad=1 } END { exit bad ? 0 : 1 }'; then
  echo 'unexpected undefined symbol in list algorithms' >&2
  exit 1
fi
if readelf -d build/tests/c08/f06/list_algorithms_test | grep -q '(NEEDED)'; then
  echo 'hidden dynamic dependency in list algorithms test' >&2
  exit 1
fi
printf '%s\n' 'C08_F06_GREEN operations=find_contains_map_filter_stableSort callback_abi=internal source_function_values=deferred scratch=caller_bounded hidden_allocation=no failure_atomic=yes deterministic_object=yes'
