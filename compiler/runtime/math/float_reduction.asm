bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; rdi=pointer to binary64, rsi=count, xmm0=identity.
; xmm0=result, eax=status. Order is always increasing source index.
global nebo_reduce_f64_sum_stable
nebo_reduce_f64_sum_stable:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .domain
    xor ecx, ecx
.loop:
    addsd xmm0, [rdi + rcx*8]
    inc rcx
    cmp rcx, rsi
    jb .loop
.ok:
    xor eax, eax
    ret
.domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret

global nebo_reduce_f64_product_stable
nebo_reduce_f64_product_stable:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .ok
    test rdi, rdi
    jz .domain
    xor ecx, ecx
.loop:
    mulsd xmm0, [rdi + rcx*8]
    inc rcx
    cmp rcx, rsi
    jb .loop
.ok:
    xor eax, eax
    ret
.domain:
    pxor xmm0, xmm0
    mov eax, NEBO_QUANTITY_ERR_DOMAIN
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
