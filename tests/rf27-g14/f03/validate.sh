#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"; cd "$repo"
ninja rf27-g14-f03-tests >/dev/null
build/tests/rf27-g14/f03/transcendental_test
file build/tests/rf27-g14/f03/transcendental_test | rg -q 'statically linked'
test -z "$(nm -u build/tests/rf27-g14/f03/transcendental_test)"
! readelf -lW build/tests/rf27-g14/f03/transcendental_test | rg -q INTERP
! rg -qi 'extern.*(libm|sin|cos|tan|exp|log)|call.*@' runtime/math/transcendental.asm
bash tests/rf27-g14/f02/validate.sh >/dev/null
printf '%s\n' 'RF27_G14_F03_GREEN native=20 transcendental=x87 rounding=bounded classification=bit_exact approximate=abs+relative special=nan_inf_signed_zero_subnormal static_elf=yes no_libm=yes'
