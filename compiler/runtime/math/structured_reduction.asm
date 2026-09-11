bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

%define NEBO_REDUCTION_MAX_COUNT 1048576

section .text

; rdi=records, rsi=count, rdx=stride, rcx=i64 field offset, r8=identity.
; rax=sum, edx=status. Layout is validated before the first read.
global nebo_reduce_struct_i64_field_sum
nebo_reduce_struct_i64_field_sum:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .domain
    test rsi, rsi
    jz .empty
    test rdi, rdi
    jz .domain
    cmp rdx, 8
    jb .domain
    mov r9, rdx
    sub r9, 8
    cmp rcx, r9
    ja .domain
    mov r9, rdx
    mov r10, rcx
    mov r11, r8
    lea rax, [rdi + r10]
    xor ecx, ecx
.loop:
    add r11, [rax]
    jo .overflow
    inc rcx
    cmp rcx, rsi
    jae .done
    add rax, r9
    jc .overflow
    jmp .loop
.done:
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

; Same validated Matrix/Tensor/Column record traversal with checked product.
global nebo_reduce_struct_i64_field_product
nebo_reduce_struct_i64_field_product:
    cmp rsi, NEBO_REDUCTION_MAX_COUNT
    ja .product_domain
    test rsi, rsi
    jz .product_empty
    test rdi, rdi
    jz .product_domain
    cmp rdx, 8
    jb .product_domain
    mov r9, rdx
    sub r9, 8
    cmp rcx, r9
    ja .product_domain
    mov r9, rdx
    mov r10, rcx
    mov r11, r8
    lea rax, [rdi + r10]
    xor ecx, ecx
.product_loop:
    imul r11, [rax]
    jo .product_overflow
    inc rcx
    cmp rcx, rsi
    jae .product_done
    add rax, r9
    jc .product_overflow
    jmp .product_loop
.product_done:
    mov rax, r11
    xor edx, edx
    ret
.product_empty:
    mov rax, r8
    xor edx, edx
    ret
.product_domain:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_DOMAIN
    ret
.product_overflow:
    xor eax, eax
    mov edx, NEBO_QUANTITY_ERR_OVERFLOW
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
