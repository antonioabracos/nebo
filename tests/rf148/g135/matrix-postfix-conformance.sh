#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

for rf148_source in \
  compiler/parser/expression/matrix_postfix_binder.asm compiler/runtime/linalg/transpose.asm \
  compiler/runtime/linalg/adjoint.asm compiler/runtime/linalg/inverse.asm \
  compiler/runtime/linalg/norm_inner_product.asm compiler/runtime/linalg/kernel_contract.asm \
  compiler/format/linalg_result.asm compiler/runtime/linalg/dot_product.asm; do
  rf148_name=$(basename "$rf148_source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name.o" "$rf148_source"
done

cat > "$rf148_tmp/harness.asm" <<'ASM'
bits 64
default rel
extern matrix_postfix_plan
extern transpose_i64
extern adjoint_complex_i64
extern inverse2_i64_result
extern norm_squared_i64_checked
extern linalg_validate_kernel_desc
extern linalg_status_name
section .data
matrix: dq 1,2,3,4,5,6
mdesc: dq matrix,2,3,3,7
complex: dq 1,2,3,-4
inverse_ok: dq 1,2,3,4
inverse_singular: dq 1,2,2,4
identity: dq 1,0,0,1
vector: dq 3,4
section .bss
plan: resq 2
out: resq 16
odesc: resq 5
result: resq 8
section .text
global _start
fail:
    mov edi, 1
    mov eax, 60
    syscall
_start:
    mov edi, 1
    mov esi, 1
    lea rdx, [plan]
    call matrix_postfix_plan
    test eax, eax
    jne fail
    cmp qword [plan], 1
    jne fail
    cmp qword [plan+8], 170
    jne fail
    mov edi, 4
    call matrix_postfix_plan
    cmp eax, -1
    jne fail

    lea rdi, [mdesc]
    lea rsi, [odesc]
    lea rdx, [out]
    mov ecx, 6
    call transpose_i64
    cmp eax, 6
    jne fail
    cmp qword [odesc+8], 3
    jne fail
    cmp qword [odesc+16], 2
    jne fail
    cmp qword [out+8], 4
    jne fail
    cmp qword [out+32], 3
    jne fail

    lea rdi, [complex]
    mov esi, 2
    mov edx, 1
    lea rcx, [out]
    mov r8d, 2
    call adjoint_complex_i64
    cmp eax, 2
    jne fail
    cmp qword [out+8], -2
    jne fail
    cmp qword [out+24], 4
    jne fail

    lea rdi, [inverse_ok]
    lea rsi, [result]
    mov edx, 1
    call inverse2_i64_result
    test eax, eax
    jne fail
    cmp qword [result+8], -2
    jne fail
    cmp qword [result+16], 4
    jne fail
    cmp qword [result+24], -2
    jne fail
    lea rdi, [inverse_singular]
    call inverse2_i64_result
    cmp eax, -5
    jne fail
    lea rdi, [identity]
    mov edx, 2
    call inverse2_i64_result
    cmp eax, -6
    jne fail

    lea rdi, [vector]
    mov esi, 2
    lea rdx, [result]
    call norm_squared_i64_checked
    test eax, eax
    jne fail
    cmp qword [result], 25
    jne fail
    lea rdi, [mdesc]
    mov esi, 7
    mov edx, 6
    mov ecx, 8
    call linalg_validate_kernel_desc
    cmp eax, 6
    jne fail
    mov rdi, -5
    call linalg_status_name
    cmp edx, 8
    jne fail
    cmp byte [rax], 's'
    jne fail
    xor edi, edi
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM

nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
ld -o "$rf148_tmp/matrix-conformance" "$rf148_tmp"/*.o
"$rf148_tmp/matrix-conformance"
test -z "$(readelf -dW "$rf148_tmp/matrix-conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/matrix-conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
printf '%s\n' 'RF148_G135_MATRIX_POSTFIX_CONFORMANCE=PASS'
printf '%s\n' 'POSTFIX_PLAN_SOURCE_INTEGRATED=PASS'
printf '%s\n' 'TRANSPOSE_ADJOINT=PASS'
printf '%s\n' 'INVERSE_RESULT_STATES=PASS'
printf '%s\n' 'NORM_INNER_PRODUCT=PASS'
printf '%s\n' 'CALLER_OWNED_KERNELS=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
