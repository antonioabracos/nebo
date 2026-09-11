#!/usr/bin/env bash
set -euo pipefail
export PYTHONDONTWRITEBYTECODE=1 LC_ALL=C LANG=C TZ=UTC
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)
cd "$root"
ninja -j2 build/bin/neboc >/dev/null
exec python3 tests/rf204/G170/runner.py "$@"
