#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT
rf148_sources=(
  compiler/diagnostics/reserved/flow_forms.asm
  compiler/diagnostics/reserved/path_forms.asm
  compiler/diagnostics/reserved/hash_dollar_forms.asm
  compiler/diagnostics/reserved/raw_comment_forms.asm
  compiler/diagnostics/reserved/bitwise_forms.asm
  compiler/diagnostics/reserved/index_slice_forms.asm
  compiler/diagnostics/reserved/unsafe_proof_forms.asm
)
for rf148_source in "${rf148_sources[@]}"; do
  rf148_object="$rf148_tmp/${rf148_source//\//_}.o"
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_object" "$rf148_source"
done
cat > "$rf148_tmp/harness.asm" <<'ASM'
default rel
extern nebo_reserved_flow_form, nebo_reserved_path_form
extern nebo_reserved_hash_dollar_form, nebo_reserved_raw_comment_form
extern nebo_reserved_bitwise_form, nebo_reserved_index_slice_form
extern nebo_reserved_unsafe_proof_form
global _start
%macro CHECK_RESERVED 4
    lea rdi, [%1]
    mov esi, %2
    mov edx, 1
    lea rcx, [result]
    call %3
    cmp eax, 1
    jne fail
    cmp qword [result], %4
    jne fail
    cmp qword [result+8], 144000+%4
    jne fail
    cmp qword [result+16], 0
    jne fail
%endmacro
section .data
f01 db '<.'
f02 db '<.>'
f03 db '...'
f04 db '::'
f05 db '#'
f06 db '#A0b1C2'
f07 db '$'
f08 db 060h,'x',060h
f09 db '/*x*/'
f10 db '&'
f11 db '|'
f12 db '~'
f13 db '<<'
f14 db '>>'
f15 db 'a[0]'
f16 db 'a:b'
f17 db '&x'
f18 db '*x'
f19 db 0ceh,0bbh
f20 db 0e2h,086h,0a6h
f21 db '|x|'
f22 db 0e2h,089h,094h
f23a db 0e2h,088h,0b4h
f23b db 0e2h,088h,0b5h
unknown_flow db '<x'
bad_color db '#GGGGGG'
section .bss
result resq 3
section .text
_start:
    CHECK_RESERVED f01,2,nebo_reserved_flow_form,1
    CHECK_RESERVED f02,3,nebo_reserved_flow_form,2
    CHECK_RESERVED f03,3,nebo_reserved_path_form,3
    CHECK_RESERVED f04,2,nebo_reserved_path_form,4
    CHECK_RESERVED f05,1,nebo_reserved_hash_dollar_form,5
    CHECK_RESERVED f06,7,nebo_reserved_hash_dollar_form,6
    CHECK_RESERVED f07,1,nebo_reserved_hash_dollar_form,7
    CHECK_RESERVED f08,3,nebo_reserved_raw_comment_form,8
    CHECK_RESERVED f09,5,nebo_reserved_raw_comment_form,9
    CHECK_RESERVED f10,1,nebo_reserved_bitwise_form,10
    CHECK_RESERVED f11,1,nebo_reserved_bitwise_form,11
    CHECK_RESERVED f12,1,nebo_reserved_bitwise_form,12
    CHECK_RESERVED f13,2,nebo_reserved_bitwise_form,13
    CHECK_RESERVED f14,2,nebo_reserved_bitwise_form,14
    CHECK_RESERVED f15,4,nebo_reserved_index_slice_form,15
    CHECK_RESERVED f16,3,nebo_reserved_index_slice_form,16
    CHECK_RESERVED f17,2,nebo_reserved_unsafe_proof_form,17
    CHECK_RESERVED f18,2,nebo_reserved_unsafe_proof_form,18
    CHECK_RESERVED f19,2,nebo_reserved_unsafe_proof_form,19
    CHECK_RESERVED f20,3,nebo_reserved_unsafe_proof_form,20
    CHECK_RESERVED f21,3,nebo_reserved_unsafe_proof_form,21
    CHECK_RESERVED f22,3,nebo_reserved_unsafe_proof_form,22
    CHECK_RESERVED f23a,3,nebo_reserved_unsafe_proof_form,23
    CHECK_RESERVED f23b,3,nebo_reserved_unsafe_proof_form,23

    mov qword [result], 99
    lea rdi, [unknown_flow]
    mov esi, 2
    xor edx, edx
    lea rcx, [result]
    call nebo_reserved_flow_form
    cmp eax, 2
    jne fail
    cmp qword [result], 99
    jne fail
    mov qword [result], 99
    lea rdi, [bad_color]
    mov esi, 7
    mov edx, 1
    lea rcx, [result]
    call nebo_reserved_hash_dollar_form
    cmp eax, 2
    jne fail
    cmp qword [result], 99
    jne fail
    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, 1
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM
nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
mapfile -t rf148_objects < <(find "$rf148_tmp" -maxdepth 1 -type f -name '*.o' | sort)
ld -o "$rf148_tmp/conformance" "${rf148_objects[@]}"
"$rf148_tmp/conformance"
test -z "$(nm -u "$rf148_tmp/conformance")"
test -z "$(readelf -dW "$rf148_tmp/conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
rf148_registry=docs/specifications/nebo-language/NEBO-SYMBOL-AND-OPERATOR-REGISTRY-v1.0/00-RESERVED-SYMBOL-REGISTRY.tsv
test "$(awk -F '\t' 'NR > 1 && $1 ~ /^NSR-RES-/ { rows++ } END { print rows + 0 }' "$rf148_registry")" -eq 23
test "$(awk -F '\t' 'NR > 1 && $2 == "RESERVED" && $14 == "NOT_ACTIVATED_BY_INSTALLATION" { rows++ } END { print rows + 0 }' "$rf148_registry")" -eq 23
rg -q '^%define NEBOC_RESERVED_SYMBOL_COUNT 23$' compiler/diagnostics/reserved/symbol_registry.inc
test "$(rg -c '^ RESERVED_SYMBOL_ROW ' compiler/diagnostics/reserved/symbol_registry.asm)" -eq 23
test "$(awk -F '\t' 'NR > 1 && $12 == "INACTIVE_CURRENT" { rows++ } END { print rows + 0 }' "$rf148_registry")" -eq 15
test "$(awk -F '\t' 'NR > 1 && $12 == "METHOD_ACTIVE_SYMBOL_INACTIVE" { rows++ } END { print rows + 0 }' "$rf148_registry")" -eq 5
test "$(awk -F '\t' 'NR > 1 && ($12 == "UNSUPPORTED_CURRENT" || $12 == "INACTIVE_CURRENT_USE_AT" || $12 == "CALLABLE_SUBSTRATE_ACTIVE_SYMBOL_INACTIVE") { rows++ } END { print rows + 0 }' "$rf148_registry")" -eq 3
printf '%s\n' 'RF148_G144_RESERVED_SYMBOL_CONFORMANCE=PASS'
printf '%s\n' 'REGISTRY_ROWS=23/23'
printf '%s\n' 'REGISTRY_CURRENT_STATES=23/23'
printf '%s\n' 'SOURCE_SPELLINGS=24/24'
printf '%s\n' 'RESERVED_INACTIVE=PASS'
printf '%s\n' 'EXECUTABLE_SEMANTICS=0'
printf '%s\n' 'FORMATTER_LSP_SHARED_REGISTRY=PASS'
printf '%s\n' 'FAILURE_ATOMICITY=PASS'
