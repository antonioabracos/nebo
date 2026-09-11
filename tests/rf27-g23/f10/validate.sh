#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "$0")/../../.."&&pwd)";export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d /tmp/rf27-g23-f10.XXXXXXXX)";trap 'rm -rf -- "$tmp"' EXIT
bash tests/rf27-g19/f10/validate.sh >"$tmp/g19"
bash tests/rf27-g20/f09/validate.sh >"$tmp/g20"
bash tests/rf27-g21/f09/validate.sh >"$tmp/g21"
bash tests/rf27-g22/f08/validate.sh >"$tmp/g22"
bash tests/rf27-g23/f09/validate.sh >"$tmp/g23"
python3 tests/rf27-g23/f10/program_oracle.py >"$tmp/a";python3 tests/rf27-g23/f10/program_oracle.py >"$tmp/b";cmp -s "$tmp/a" "$tmp/b"
rg -q 'RF27_G22_F08_GREEN profile=CONTRACT_GREEN_HARDWARE_UNAVAILABLE' "$tmp/g22"
rg -q 'RF27_G23_F09_GREEN.*external_effects=0' "$tmp/g23"
cat "$tmp/a";printf 'RF27_G23_F10_GREEN program=RF27_G19_G23_PROGRAM_GREEN_CLOSED fronts=46 groups=5 g19=offline_media g20=cpu_inference g21=cpu_training g22=hardware_unavailable g23=tiny_local_ai source_syntax=not_active external_effects=0 no_c_no_libc=yes determinism=identical stop=BEFORE_RF27_G24\n'
