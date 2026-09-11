#!/usr/bin/env bash
set -euo pipefail
root="$(cd -- "$(dirname -- "$0")/../.." && pwd)"
exec "$root/scripts/mf053/run-case.sh" NEBO-PLATFORM-NATIVE-008
