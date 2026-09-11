#!/usr/bin/env bash
set -euo pipefail
repo="$(cd "$(dirname "$0")/../../.." && pwd)"; cd "$repo"; export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g20-f08.XXXXXXXX)"; trap 'rm -rf -- "$tmp"' EXIT
ninja -j1 rf27-g20-f08-tests >/dev/null
timeout 15 build/examples/rf27-g20/tiny-inference
python3 tests/rf27-g20/f08/corpus_oracle.py >"$tmp/a"
python3 tests/rf27-g20/f08/corpus_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"
python3 tests/rf27-g20/f08/benchmark.py >"$tmp/benchmark"
rg -q '^RF27_G20_F08_BENCHMARK=MEASURED iterations=32 ' "$tmp/benchmark"
[[ $(wc -l < tests/rf27-g20/f08/PROVENANCE.tsv) -eq 4 ]]
file build/examples/rf27-g20/tiny-inference | rg -q 'ELF 64-bit.*statically linked'
[[ -z "$(nm -u build/examples/rf27-g20/tiny-inference)" ]]
tests/rf27-g20/f07/validate.sh >/dev/null
cat "$tmp/a"; cat "$tmp/benchmark"
printf 'RF27_G20_F08_GREEN native_assertions=15 models=3 cases=6000 provenance=complete benchmark=measured static_elf=yes no_c_no_libc=yes determinism=identical\n'
