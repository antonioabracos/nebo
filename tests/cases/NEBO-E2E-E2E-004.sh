#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf054/run-case.sh" NEBO-E2E-E2E-004
