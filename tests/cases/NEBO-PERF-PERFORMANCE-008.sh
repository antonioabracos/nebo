#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"
python3 -B tests/performance/run_mf058_benchmarks.py --verify "NEBO-PERF-PERFORMANCE-008"
