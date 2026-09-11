#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "${BASH_SOURCE[0]}")/../../.."
python3 -B scripts/check-version-consistency.py --binary
python3 -B tests/release/version-consistency/selftest.py
