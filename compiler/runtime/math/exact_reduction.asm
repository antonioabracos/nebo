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

; rdi=pointer to signed i128 pairs {low,high}, rsi=count, rdx=out pair.
; The output is failure-atomic and the empty-domain identity is zero.
global nebo_reduce_i128_sum_checked
nebo_reduce_i128_sum_checked:
    test rdx, rdx
    jz .i128_domain
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .i128_domain
    test rsi, rsi
    jz .i128_store_zero
    test rdi, rdi
    jz .i128_domain
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
.i128_loop:
    mov rax, [rdi + r10*8]
    add r8, rax
    mov rax, [rdi + r10*8 + 8]
    adc r9, rax
    jo .i128_overflow
    add r10, 2
    sub rsi, 1
    jnz .i128_loop
    mov [rdx], r8
    mov [rdx + 8], r9
    xor edx, edx
    ret
.i128_store_zero:
    mov qword [rdx], 0
    mov qword [rdx + 8], 0
    xor edx, edx
    ret
.i128_domain:
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.i128_overflow:
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=Decimal records {coefficient,scale}, rsi=count, rdx=required scale,
; rcx=identity coefficient, r8=out coefficient.  Mixed scales are rejected;
; no implicit rounding or coercion is permitted.
global nebo_reduce_decimal_sum_checked
nebo_reduce_decimal_sum_checked:
    test r8, r8
    jz .decimal_domain
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .decimal_domain
    test rsi, rsi
    jz .decimal_store
    test rdi, rdi
    jz .decimal_domain
    xor r9d, r9d
.decimal_loop:
    cmp [rdi + r9*8 + 8], rdx
    jne .decimal_precision
    add rcx, [rdi + r9*8]
    jo .decimal_overflow
    add r9, 2
    sub rsi, 1
    jnz .decimal_loop
.decimal_store:
    mov [r8], rcx
    xor edx, edx
    ret
.decimal_domain:
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.decimal_precision:
    mov edx, NEBO_QUANTITY_ERR_PRECISION
    ret
.decimal_overflow:
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

; rdi=Rational records {numerator,denominator}, rsi=count,
; rdx=identity numerator, rcx=identity denominator, r8=out pair.
; Exact cross-products are checked and denominators must be non-zero.
global nebo_reduce_rational_sum_checked
nebo_reduce_rational_sum_checked:
    test r8, r8
    jz .rational_domain
    test rcx, rcx
    jz .rational_domain
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .rational_domain
    test rsi, rsi
    jz .rational_store
    test rdi, rdi
    jz .rational_domain
    xor r9d, r9d
.rational_loop:
    mov r10, [rdi + r9*8]
    mov r11, [rdi + r9*8 + 8]
    test r11, r11
    jz .rational_domain
    imul rdx, r11
    jo .rational_overflow
    imul r10, rcx
    jo .rational_overflow
    add rdx, r10
    jo .rational_overflow
    imul rcx, r11
    jo .rational_overflow
    add r9, 2
    sub rsi, 1
    jnz .rational_loop
.rational_store:
    mov [r8], rdx
    mov [r8 + 8], rcx
    xor edx, edx
    ret
.rational_domain:
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.rational_overflow:
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
