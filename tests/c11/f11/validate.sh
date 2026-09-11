#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f11/matrix_i64_abi_test >/dev/null
build/tests/c11/f11/matrix_i64_abi_test
expected=75db9f8312f19dbb56b31d7f180d7266f8655b03997e5641524bed1019454fd0
actual="$(head -c -1 sdk/interfaces/scientific/matrix-int-v1.ni.identity | sha256sum | cut -d' ' -f1)"
test "$actual" = "$expected"
tests/c11/f09/validate.sh >/dev/null
printf '%s\n' "C11_F11_GREEN borrowed_descriptor_copy=1 payload_copy=0 sret_identity=yes failure_atomic=yes ni_sha256=$actual"
