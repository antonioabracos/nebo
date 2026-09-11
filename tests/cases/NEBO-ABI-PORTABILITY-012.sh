#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf059/run-case.sh" "NEBO-ABI-PORTABILITY-012"
