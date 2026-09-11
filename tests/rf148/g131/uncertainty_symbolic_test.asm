bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

extern nebo_uncertain_measurement_create
extern nebo_uncertainty_add_checked
extern nebo_uncertainty_product_bound
extern nebo_approx_equal_i64
extern nebo_not_approx_equal_i64
extern nebo_rational_equivalent_i64
extern nebo_pair_proportional_i64
extern nebo_divisible_i64
extern nebo_not_divisible_i64
extern nebo_measurement_metadata_plan

section .text
global _start
_start:
    mov ebx, 1
    mov rdi, 100
    mov rsi, 5
    mov edx, NEBO_UNIT_MILLIDEGREE
    call nebo_uncertain_measurement_create
    cmp rax, 100
    jne fail
    cmp rdx, 5
    jne fail
    cmp ecx, NEBO_UNIT_MILLIDEGREE
    jne fail
    test r8d, r8d
    jnz fail

    mov ebx, 2
    mov rdi, 5
    mov rsi, 7
    call nebo_uncertainty_add_checked
    cmp rax, 12
    jne fail
    mov rdi, 10
    mov rsi, 1
    mov rdx, 20
    mov rcx, 2
    call nebo_uncertainty_product_bound
    cmp rax, 42
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 3
    mov rdi, 100
    mov rsi, 104
    mov rdx, 4
    call nebo_approx_equal_i64
    cmp eax, 1
    jne fail
    mov rdi, 100
    mov rsi, 104
    mov rdx, 3
    call nebo_not_approx_equal_i64
    cmp eax, 1
    jne fail

    mov ebx, 4
    mov rdi, 1
    mov rsi, 2
    mov rdx, 2
    mov rcx, 4
    call nebo_rational_equivalent_i64
    cmp eax, 1
    jne fail
    mov rdi, 2
    mov rsi, 4
    mov rdx, 3
    mov rcx, 6
    call nebo_pair_proportional_i64
    cmp eax, 1
    jne fail

    mov ebx, 5
    mov rdi, 12
    mov rsi, 3
    call nebo_divisible_i64
    cmp eax, 1
    jne fail
    mov rdi, 12
    mov rsi, 5
    call nebo_not_divisible_i64
    cmp eax, 1
    jne fail
    mov rdi, 12
    xor esi, esi
    call nebo_divisible_i64
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail

    mov ebx, 6
    mov edi, NEBO_UNIT_PERCENT
    mov esi, 2
    call nebo_measurement_metadata_plan
    cmp eax, 7
    jne fail
    test edx, edx
    jnz fail

    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, ebx
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
