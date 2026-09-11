#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
cd "$root"
ninja mf049-console-lifecycle-tests
timeout 15s build/tests/mf049/lifecycle_test 8
echo NEBO_LIFECYCLE_SECURITY_008_GREEN
