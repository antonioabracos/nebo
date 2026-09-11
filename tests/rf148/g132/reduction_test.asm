bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"

extern nebo_reduction_binder_classify
extern nebo_reduce_i64_sum_checked
extern nebo_reduce_i64_product_checked
extern nebo_reduce_i128_sum_checked
extern nebo_reduce_decimal_sum_checked
extern nebo_reduce_rational_sum_checked
extern nebo_reduce_f64_sum_stable
extern nebo_reduce_f64_product_stable
extern nebo_reduce_f64_sum_pairwise
extern nebo_reduce_f64_sum_kahan
extern nebo_reduce_f64_sum_neumaier
extern nebo_reduce_i64_affine_map_sum
extern nebo_reduce_i64_filter_map_sum
extern nebo_reduce_struct_i64_field_sum
extern nebo_reduce_struct_i64_field_product
extern nebo_deterministic_parallel_plan
extern nebo_reduce_i64_sum_parallel_deterministic
extern nebo_reduction_result_init
extern nebo_reduction_result_is_ok
extern nebo_reduction_result_value_or
extern nebo_reduction_result_explain

section .rodata align=16
integers: dq 1, 2, 3, 4
overflow_values: dq 0x7fffffffffffffff, 2
floats: dq 0x3ff0000000000000, 0x4000000000000000, 0x4008000000000000
records: dq 10, 100, 20, 200, 30, 300
i128_values: dq 2, 0, 3, 0
i128_overflow_values: dq 0xffffffffffffffff, 0x7fffffffffffffff, 1, 0
decimals: dq 125, 2, 275, 2
rationals: dq 1, 2, 1, 3
invalid_rational: dq 7, 0
cancellation: dq 0x4341c37937e08000, 0x3ff0000000000000, 0xc341c37937e08000
not_a_number: dq 0x7ff8000000000001
positive_infinity: dq 0x7ff0000000000000

section .bss align=16
wide_result: resq 2
decimal_result: resq 1
rational_result: resq 2
parallel_report: resq 3
reduction_result: resq 7

section .text
global _start
_start:
    mov ebx, 1
    mov edi, 0x2211
    mov esi, NEBO_QCTX_DOMAIN_ENABLED
    mov edx, 4
    call nebo_reduction_binder_classify
    cmp eax, 1
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 2
    lea rdi, [integers]
    mov esi, 4
    xor edx, edx
    call nebo_reduce_i64_sum_checked
    cmp rax, 10
    jne fail
    lea rdi, [integers]
    mov esi, 4
    mov edx, 1
    call nebo_reduce_i64_product_checked
    cmp rax, 24
    jne fail
    lea rdi, [overflow_values]
    mov esi, 2
    xor edx, edx
    call nebo_reduce_i64_sum_checked
    cmp edx, NEBO_QUANTITY_ERR_OVERFLOW
    jne fail
    lea rdi, [i128_values]
    mov esi, 2
    lea rdx, [wide_result]
    call nebo_reduce_i128_sum_checked
    test edx, edx
    jnz fail
    cmp qword [wide_result], 5
    jne fail
    cmp qword [wide_result + 8], 0
    jne fail
    lea rdi, [decimals]
    mov esi, 2
    mov edx, 2
    xor ecx, ecx
    lea r8, [decimal_result]
    call nebo_reduce_decimal_sum_checked
    test edx, edx
    jnz fail
    cmp qword [decimal_result], 400
    jne fail
    lea rdi, [rationals]
    mov esi, 2
    xor edx, edx
    mov ecx, 1
    lea r8, [rational_result]
    call nebo_reduce_rational_sum_checked
    test edx, edx
    jnz fail
    cmp qword [rational_result], 5
    jne fail
    cmp qword [rational_result + 8], 6
    jne fail
    mov qword [wide_result], 123
    mov qword [wide_result + 8], 456
    xor edi, edi
    mov esi, 1
    lea rdx, [wide_result]
    call nebo_reduce_i128_sum_checked
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    cmp qword [wide_result], 123
    jne fail
    cmp qword [wide_result + 8], 456
    jne fail
    lea rdi, [i128_overflow_values]
    mov esi, 2
    lea rdx, [wide_result]
    call nebo_reduce_i128_sum_checked
    cmp edx, NEBO_QUANTITY_ERR_OVERFLOW
    jne fail
    cmp qword [wide_result], 123
    jne fail
    cmp qword [wide_result + 8], 456
    jne fail
    mov qword [decimal_result], 789
    lea rdi, [decimals]
    mov esi, 2
    mov edx, 3
    xor ecx, ecx
    lea r8, [decimal_result]
    call nebo_reduce_decimal_sum_checked
    cmp edx, NEBO_QUANTITY_ERR_PRECISION
    jne fail
    cmp qword [decimal_result], 789
    jne fail
    mov qword [rational_result], 321
    mov qword [rational_result + 8], 654
    lea rdi, [invalid_rational]
    mov esi, 1
    xor edx, edx
    mov ecx, 1
    lea r8, [rational_result]
    call nebo_reduce_rational_sum_checked
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    cmp qword [rational_result], 321
    jne fail
    cmp qword [rational_result + 8], 654
    jne fail

    mov ebx, 3
    lea rdi, [floats]
    mov esi, 3
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_stable
    test eax, eax
    jnz fail
    movq r8, xmm0
    mov r9, 0x4018000000000000
    cmp r8, r9
    jne fail
    lea rdi, [floats]
    mov esi, 3
    mov r8, 0x3ff0000000000000
    movq xmm0, r8
    call nebo_reduce_f64_product_stable
    movq r8, xmm0
    cmp r8, r9
    jne fail
    lea rdi, [floats]
    mov esi, 3
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_pairwise
    test eax, eax
    jnz fail
    movq r8, xmm0
    cmp r8, r9
    jne fail
    lea rdi, [floats]
    mov esi, 3
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_kahan
    test eax, eax
    jnz fail
    movq r8, xmm0
    cmp r8, r9
    jne fail
    lea rdi, [cancellation]
    mov esi, 3
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_neumaier
    test eax, eax
    jnz fail
    movq r8, xmm0
    mov r9, 0x3ff0000000000000
    cmp r8, r9
    jne fail
    lea rdi, [not_a_number]
    mov esi, 1
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_pairwise
    cmp eax, NEBO_QUANTITY_ERR_PRECISION
    jne fail
    movq r8, xmm0
    test r8, r8
    jnz fail
    lea rdi, [positive_infinity]
    mov esi, 1
    pxor xmm0, xmm0
    call nebo_reduce_f64_sum_stable
    cmp eax, NEBO_QUANTITY_ERR_PRECISION
    jne fail
    movq r8, xmm0
    test r8, r8
    jnz fail

    mov ebx, 4
    lea rdi, [integers]
    mov esi, 4
    mov edx, 2
    mov ecx, 1
    xor r8d, r8d
    call nebo_reduce_i64_affine_map_sum
    cmp rax, 24
    jne fail
    lea rdi, [integers]
    mov esi, 4
    mov edx, 2
    mov ecx, 1
    mov r8d, 2
    xor r9d, r9d
    call nebo_reduce_i64_filter_map_sum
    cmp rax, 8
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 5
    lea rdi, [records]
    mov esi, 3
    mov edx, 16
    mov ecx, 8
    xor r8d, r8d
    call nebo_reduce_struct_i64_field_sum
    cmp rax, 600
    jne fail
    test edx, edx
    jnz fail
    lea rdi, [records]
    mov esi, 3
    mov edx, 16
    mov ecx, 8
    mov r8d, 1
    call nebo_reduce_struct_i64_field_product
    cmp rax, 6000000
    jne fail
    test edx, edx
    jnz fail
    lea rdi, [records]
    mov esi, 3
    mov edx, 8
    mov ecx, 8
    xor r8d, r8d
    call nebo_reduce_struct_i64_field_sum
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail

    mov ebx, 6
    mov edi, 10
    mov esi, 4
    mov edx, 1
    call nebo_deterministic_parallel_plan
    cmp eax, 4
    jne fail
    cmp edx, 2
    jne fail
    test ecx, ecx
    jnz fail
    mov edi, 10
    mov esi, 4
    xor edx, edx
    call nebo_deterministic_parallel_plan
    cmp ecx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    lea rdi, [integers]
    mov esi, 4
    mov edx, 3
    mov ecx, 1
    lea r8, [parallel_report]
    call nebo_reduce_i64_sum_parallel_deterministic
    cmp rax, 10
    jne fail
    test edx, edx
    jnz fail
    cmp qword [parallel_report], 3
    jne fail
    cmp qword [parallel_report + 8], 2
    jne fail
    cmp qword [parallel_report + 16], 4
    jne fail
    mov qword [parallel_report], 91
    mov qword [parallel_report + 8], 92
    mov qword [parallel_report + 16], 93
    lea rdi, [integers]
    mov esi, 4
    mov edx, 3
    xor ecx, ecx
    lea r8, [parallel_report]
    call nebo_reduce_i64_sum_parallel_deterministic
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    cmp qword [parallel_report], 91
    jne fail
    cmp qword [parallel_report + 8], 92
    jne fail
    cmp qword [parallel_report + 16], 93
    jne fail

    mov ebx, 7
    mov edi, 1
    mov esi, NEBO_QUANTITY_ERR_OVERFLOW
    mov edx, 2
    mov ecx, 4
    call nebo_reduction_result_explain
    cmp eax, 148132003
    jne fail
    cmp rdx, 2
    jne fail
    cmp ecx, 5
    jne fail
    test r8d, r8d
    jnz fail
    lea rdi, [reduction_result]
    mov esi, 10
    xor edx, edx
    xor ecx, ecx
    mov r8d, 4
    mov r9d, 1
    call nebo_reduction_result_init
    test eax, eax
    jnz fail
    lea rdi, [reduction_result]
    call nebo_reduction_result_is_ok
    cmp eax, 1
    jne fail
    lea rdi, [reduction_result]
    mov esi, 99
    call nebo_reduction_result_value_or
    cmp rax, 10
    jne fail
    mov qword [reduction_result], 777
    lea rdi, [reduction_result]
    mov esi, 55
    xor edx, edx
    xor ecx, ecx
    mov r8d, 1
    mov r9d, 99
    call nebo_reduction_result_init
    cmp eax, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    cmp qword [reduction_result], 777
    jne fail
    mov qword [reduction_result + 32], 99
    lea rdi, [reduction_result]
    call nebo_reduction_result_is_ok
    test eax, eax
    jnz fail
    lea rdi, [reduction_result]
    mov esi, 88
    call nebo_reduction_result_value_or
    cmp rax, 88
    jne fail
    mov edi, 1
    mov esi, NEBO_QUANTITY_ERR_PRECISION
    mov edx, 1
    mov ecx, 3
    call nebo_reduction_result_explain
    cmp eax, 148132005
    jne fail
    cmp ecx, 5
    jne fail

    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, ebx
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
