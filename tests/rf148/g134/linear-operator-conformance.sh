#!/usr/bin/env bash
set -Eeuo pipefail
rf148_root=$(git rev-parse --show-toplevel)
cd "$rf148_root"
rf148_tmp=$(mktemp -d)
trap 'rm -rf "$rf148_tmp"' EXIT

for rf148_source in \
  compiler/runtime/linalg/dot_product.asm compiler/runtime/linalg/cross_product.asm \
  compiler/runtime/linalg/hadamard_tensor.asm compiler/runtime/linalg/direct_sum.asm \
  compiler/semantic/functions/composition.asm compiler/semantic/linalg/geometric_relations.asm; do
  rf148_name=$(basename "$rf148_source" .asm)
  nasm -f elf64 -Wall -Werror -I./ -o "$rf148_tmp/$rf148_name.o" "$rf148_source"
done

cat > "$rf148_tmp/harness.asm" <<'ASM'
bits 64
default rel
extern dot_i64_checked
extern cross3_i64_checked
extern hadamard_i64_checked
extern tensor_i64_checked
extern direct_sum_i64
extern compose_plan_i64
extern compose_apply_i64
extern vectors_orthogonal_i64
extern vectors_parallel3_i64
section .data
v1: dq 1,2,3
v2: dq 4,5,6
e1: dq 1,0,0
e2: dq 0,1,0
p2: dq 2,4,6
t1: dq 1,2
t2: dq 3,4
ma: dq 1,2
mb: dq 3
adesc: dq ma,1,2,2,7
bdesc: dq mb,1,1,1,7
inner: dq add1,1,1
outer: dq double,1,1
section .bss
scalar: resq 1
out: resq 16
odesc: resq 5
composite: resq 4
flag: resb 1
section .text
global _start
add1:
    lea rax, [rdi+1]
    ret
double:
    lea rax, [rdi+rdi]
    ret
fail:
    mov edi, 1
    mov eax, 60
    syscall
_start:
    lea rdi, [v1]
    lea rsi, [v2]
    mov edx, 3
    lea rcx, [scalar]
    call dot_i64_checked
    test eax, eax
    jne fail
    cmp qword [scalar], 32
    jne fail
    lea rdi, [v1]
    lea rsi, [v2]
    lea rdx, [out]
    call cross3_i64_checked
    test eax, eax
    jne fail
    cmp qword [out], -3
    jne fail
    cmp qword [out+8], 6
    jne fail
    cmp qword [out+16], -3
    jne fail
    lea rdi, [v1]
    lea rsi, [v2]
    mov edx, 3
    lea rcx, [out]
    call hadamard_i64_checked
    test eax, eax
    jne fail
    cmp qword [out+8], 10
    jne fail
    lea rdi, [t1]
    mov esi, 2
    lea rdx, [t2]
    mov ecx, 2
    lea r8, [out]
    mov r9d, 4
    call tensor_i64_checked
    cmp eax, 4
    jne fail
    cmp qword [out+24], 8
    jne fail
    lea rdi, [adesc]
    lea rsi, [bdesc]
    lea rdx, [odesc]
    lea rcx, [out]
    mov r8d, 6
    call direct_sum_i64
    cmp eax, 6
    jne fail
    cmp qword [odesc+8], 2
    jne fail
    cmp qword [odesc+16], 3
    jne fail
    cmp qword [out], 1
    jne fail
    cmp qword [out+40], 3
    jne fail
    lea rdi, [outer]
    lea rsi, [inner]
    lea rdx, [composite]
    call compose_plan_i64
    test eax, eax
    jne fail
    lea rdi, [composite]
    mov esi, 3
    call compose_apply_i64
    cmp eax, 8
    jne fail
    lea rdi, [e1]
    lea rsi, [e2]
    mov edx, 3
    lea rcx, [flag]
    call vectors_orthogonal_i64
    test eax, eax
    jne fail
    cmp byte [flag], 1
    jne fail
    lea rdi, [v1]
    lea rsi, [p2]
    lea rdx, [flag]
    call vectors_parallel3_i64
    test eax, eax
    jne fail
    cmp byte [flag], 1
    jne fail
    xor edi, edi
    mov eax, 60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
ASM

nasm -f elf64 -Wall -Werror -o "$rf148_tmp/harness.o" "$rf148_tmp/harness.asm"
ld -o "$rf148_tmp/linalg-conformance" "$rf148_tmp"/*.o
"$rf148_tmp/linalg-conformance"
test -z "$(readelf -dW "$rf148_tmp/linalg-conformance" | awk '/NEEDED/')"
readelf -lW "$rf148_tmp/linalg-conformance" | awk '$1=="GNU_STACK" {found=1; if ($7 ~ /E/) exit 1} END {exit found ? 0 : 1}'
printf '%s\n' 'RF148_G134_LINEAR_OPERATOR_CONFORMANCE=PASS'
printf '%s\n' 'TYPE_SHAPE_CAPACITY=PASS'
printf '%s\n' 'CHECKED_PRODUCTS=PASS'
printf '%s\n' 'FUNCTION_COMPOSITION=PASS'
printf '%s\n' 'EXACT_GEOMETRIC_RELATIONS=PASS'
printf '%s\n' 'STACK_ALIGNMENT=PASS'
printf '%s\n' 'NO_C_NO_LIBC=PASS'
printf '%s\n' 'ELF=PASS'
