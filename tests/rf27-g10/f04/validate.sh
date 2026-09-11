#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g10-f04
build/tests/rf27-g10/f04/validation_test
bash tests/rf27-g10/f03/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F04_GREEN native=7 semantics=missing_default_error validators=schema_table_required operations=applyDefaults_invalidRows_fillMissing_coalesce typed=yes failure_atomic=yes f03=yes'
