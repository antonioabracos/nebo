#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf057/run-case.sh" "NEBO-SECURITY-FUZZ-007"
