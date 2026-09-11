#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f02-tests >/dev/null
build/tests/rf27-g14/f02/scalar_test
file build/tests/rf27-g14/f02/scalar_test | rg -q 'statically linked'
! readelf -lW build/tests/rf27-g14/f02/scalar_test | rg -q INTERP
test -z "$(nm -u build/tests/rf27-g14/f02/scalar_test)"
! rg -qi 'extern.*(libm|sqrt|pow|hypot)|call.*(libm|sqrt@|pow@|hypot@)' runtime/math/scalar.asm
bash tests/rf27-g14/f01/validate.sh >/dev/null
printf '%s\n' 'RF27_G14_F02_GREEN native=18 min=exact abs=checked clamp=failure_atomic sqrt=sse2 pow=x87_binary64_positive_base hypot=scaled ieee_special=explicit static_elf=yes no_libm=yes'
