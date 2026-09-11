#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf051/run-case.sh" "NEBO-PLATFORM-CONTRACT-001"
