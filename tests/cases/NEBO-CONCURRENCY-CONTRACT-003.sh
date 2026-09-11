#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf055/run-case.sh" NEBO-CONCURRENCY-CONTRACT-003
