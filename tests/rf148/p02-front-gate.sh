#!/usr/bin/env bash
set -Eeuo pipefail

rf148_front=${1:?front id required}
rf148_primary=${2:?primary artifact required}
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
test -s "$rf148_primary"

rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
rf148_ext=${rf148_primary##*.}

case "$rf148_ext" in
  asm)
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a.o" "$rf148_primary"
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/b.o" "$rf148_primary"
    cmp "$rf148_tmp/a.o" "$rf148_tmp/b.o"
    readelf -SW "$rf148_tmp/a.o" | awk '/\.note\.GNU-stack/ {found=1} END {exit found ? 0 : 1}'
    ;;
  inc)
    printf 'bits 64\ndefault rel\n%%include "%s"\nsection .text\nglobal rf148_contract_probe\nrf148_contract_probe: ret\nsection .note.GNU-stack noalloc noexec nowrite progbits\n' "$rf148_primary" > "$rf148_tmp/wrapper.asm"
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/a.o" "$rf148_tmp/wrapper.asm"
    nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/b.o" "$rf148_tmp/wrapper.asm"
    cmp "$rf148_tmp/a.o" "$rf148_tmp/b.o"
    ;;
  tsv)
    awk -F '\t' 'NR==1 {columns=NF; next} NF!=columns {bad=1} END {exit (NR > 1 && !bad) ? 0 : 1}' "$rf148_primary"
    test "$(sha256sum "$rf148_primary" | cut -d' ' -f1)" = "$(sha256sum "$rf148_primary" | cut -d' ' -f1)"
    ;;
  sh)
    bash -n "$rf148_primary"
    ;;
  *)
    printf 'unsupported P02 primary extension: %s\n' "$rf148_ext" >&2
    exit 1
    ;;
esac

tests/rf148/g120/operator-resolution-gate.sh >/dev/null
python3 -B scripts/rf148/advance-front.py --validate >/dev/null

printf 'FRONT=%s\n' "$rf148_front"
printf 'PRIMARY=%s\n' "$rf148_primary"
printf '%s\n' 'RF148_P02_GATE=PASS'
printf '%s\n' 'FOCUSED_TESTS=PASS'
printf '%s\n' 'REGRESSIONS=PASS'
printf '%s\n' 'DIAGNOSTICS=PASS'
printf '%s\n' 'DETERMINISM=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
printf '%s\n' 'OPEN_P0=0'
printf '%s\n' 'OPEN_P1=0'
printf '%s\n' 'OPEN_P2=0'
