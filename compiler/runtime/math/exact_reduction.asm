bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; rdi=pointer to i64, rsi=count, rdx=identity. Stable left-to-right sum.
global nebo_reduce_i64_sum_checked
nebo_reduce_i64_sum_checked:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .domain
    mov r8, rdx
    xor r9d, r9d
.sum_loop:
    add r8, [rdi + r9*8]
    jo .overflow
    inc r9
    cmp r9, rsi
    jb .sum_loop
    mov rax, r8
    xor edx, edx
    ret
.empty:
    mov rax, rdx
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

; rdi=pointer to i64, rsi=count, rdx=identity. Checked product.
global nebo_reduce_i64_product_checked
nebo_reduce_i64_product_checked:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .domain
    mov r8, rdx
    xor r9d, r9d
.product_loop:
    imul r8, [rdi + r9*8]
    jo .overflow
    inc r9
    cmp r9, rsi
    jb .product_loop
    mov rax, r8
    xor edx, edx
    ret
.empty:
    mov rax, rdx
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
