#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo"
ninja -f build.ninja -j1 rf27-g10-f06
build/tests/rf27-g10/f06/stream_test
bash tests/rf27-g10/f05/validate.sh >/dev/null
printf '%s\n' 'RF27_G10_F06_GREEN native=7 event=24/8 flow=48/8 stream=72/8 capacity=64 operations=flowNext_streamMapFilterNext_consume order=source completion=explicit callbacks=lazy_typed_error cleanup=bounded external_g13=yes f05=yes'
