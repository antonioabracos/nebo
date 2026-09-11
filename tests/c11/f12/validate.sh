#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb PYTHONDONTWRITEBYTECODE=1
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja build/tests/c11/f12/matrix_i64_adapter_test >/dev/null
build/tests/c11/f12/matrix_i64_adapter_test
tests/c11/f11/validate.sh >/dev/null
printf '%s\n' 'C11_F12_GREEN NBM1=stable headless_shape=stable Console=experimental-native heatmap=experimental-native live2D=target-gated display_used=no'
