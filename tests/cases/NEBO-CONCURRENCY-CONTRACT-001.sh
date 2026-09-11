#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
exec "$ROOT/tests/stress/console/mf050_concurrency_stress.sh" "001"
