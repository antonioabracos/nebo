#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf060/run-historical-case.sh" "NEBO-DOC-DOC_AUDIT-001"
