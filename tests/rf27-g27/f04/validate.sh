#!/usr/bin/env bash
set -euo pipefail
cd "$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
export LC_ALL=C LANG=C TZ=UTC TERM=dumb PYTHONDONTWRITEBYTECODE=1
tmp="$(mktemp -d)"; trap 'rm -rf -- "$tmp"' EXIT
python3 tests/rf27-g27/f04/target_decision_oracle.py >"$tmp/a"
python3 tests/rf27-g27/f04/target_decision_oracle.py >"$tmp/b"
cmp -s "$tmp/a" "$tmp/b"; cat "$tmp/a"
clang --print-targets | rg -q '^    aarch64 '
! ld -V | rg -q 'aarch64|elf64.*littleaarch64'
! command -v aarch64-linux-gnu-ld >/dev/null 2>&1
! command -v qemu-aarch64 >/dev/null 2>&1
test "$(build/bin/neboc --version)" = 'neboc 0.2.0-rc.2'
bash tests/rf27-g27/f02/validate.sh >"$tmp/g27-f02"
rg -q 'certified=x86_64-systemv-elf-linux.*aarch64=unavailable' "$tmp/g27-f02"
bash tests/rf27-g26/f09/validate.sh >/dev/null
printf '%s\n' 'RF27_G27_F04_GREEN decision=CONTRACT_GREEN_TARGET_UNAVAILABLE certified=x86_64-systemv-elf-linux candidate=aarch64-linux clang_assembler=available gnu_linker=unavailable emulator=unavailable backend_registry=absent conformance=unavailable install=no invented_support=no'
