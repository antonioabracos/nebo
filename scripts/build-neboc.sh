#!/usr/bin/env bash
set -euo pipefail
export LC_ALL=C LANG=C TERM=dumb TZ=UTC PYTHONDONTWRITEBYTECODE=1
source_root=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)
cd "$source_root"
test "$(python3 -c 'import json; print(json.load(open("version/NEBO-VERSION.json", encoding="utf-8"))["version"])')" = 1.0.1
ninja -f build.ninja -j1 neboc
test "$(build/bin/neboc --version)" = "neboc 1.0.1"
