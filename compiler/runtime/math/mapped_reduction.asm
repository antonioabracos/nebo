bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; rdi=i64 pointer, rsi=count, rdx=scale, rcx=bias, r8=identity.
; Applies value*scale+bias exactly once, then sums in source order.
global nebo_reduce_i64_affine_map_sum
nebo_reduce_i64_affine_map_sum:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .domain
    mov r9, rdx
    mov r10, rcx
    mov r11, r8
    xor ecx, ecx
.loop:
    mov rax, [rdi + rcx*8]
    imul rax, r9
    jo .overflow
    add rax, r10
    jo .overflow
    add r11, rax
    jo .overflow
    inc rcx
    cmp rcx, rsi
    jb .loop
    mov rax, r11
    xor edx, edx
    ret
.empty:
    mov rax, r8
    xor edx, edx
    ret
.domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
