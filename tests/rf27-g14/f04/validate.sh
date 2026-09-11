#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f04-tests >/dev/null
build/tests/rf27-g14/f04/vector_test
file build/tests/rf27-g14/f04/vector_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g14/f04/vector_test)"
! readelf -lW build/tests/rf27-g14/f04/vector_test | rg -q INTERP
bash tests/rf27-g14/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G14_F04_GREEN native=18 vector=Int64+Float64 N=1..64 construction=copy at=bounds_checked add=checked scale=checked dot=scalar norm=sse2 normalize=zero_rejected alias=in_place_safe static_elf=yes'
