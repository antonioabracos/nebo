bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"
%include "compiler/tokens/operator_registry.inc"

extern nebo_root_exact_u64
extern nebo_factorial_u64_checked
extern nebo_contextual_infinity_f64
extern nebo_is_infinity_f64_bits
extern nebo_precision_constant_bits
extern nebo_floor_rational_i64
extern nebo_ceil_rational_i64
extern nebo_math_domain_result_variant
extern nebo_math_constant_fold_i64
extern neboc_typed_math_registry_at
extern neboc_typed_math_registry_count
extern nebo_math_symbol_format

section .rodata
expected_registry_ids:
    dq NEBOC_OPERATOR_ID_NSR_DOM_001,NEBOC_OPERATOR_ID_NSR_DOM_002
    dq NEBOC_OPERATOR_ID_NSR_DOM_003,NEBOC_OPERATOR_ID_NSR_DOM_004
    dq NEBOC_OPERATOR_ID_NSR_DOM_005,NEBOC_OPERATOR_ID_NSR_DOM_006
    dq NEBOC_OPERATOR_ID_NSR_DOM_007,NEBOC_OPERATOR_ID_NSR_DOM_016
    dq NEBOC_OPERATOR_ID_NSR_DOM_017
expected_lengths: db 3,3,3,1,3,2,2,7,7
expected_sqrt:        db 0xe2,0x88,0x9a
expected_cube_root:   db 0xe2,0x88,0x9b
expected_fourth_root: db 0xe2,0x88,0x9c
expected_factorial:   db "!"
expected_infinity:    db 0xe2,0x88,0x9e
expected_pi:          db 0xcf,0x80
expected_tau:         db 0xcf,0x84
expected_floor:       db 0xe2,0x8c,0x8a,"x",0xe2,0x8c,0x8b
expected_ceil:        db 0xe2,0x8c,0x88,"x",0xe2,0x8c,0x89
align 8
expected_lexeme_pointers:
    dq expected_sqrt,expected_cube_root,expected_fourth_root
    dq expected_factorial,expected_infinity,expected_pi,expected_tau
    dq expected_floor,expected_ceil

section .bss
format_pointer: resq 1
format_length:  resq 1

section .text
global _start
_start:
    ; S01/S08: all and only the nine authorized Registry rows are exposed.
    mov ebx, 8
    call neboc_typed_math_registry_count
    cmp eax, 9
    jne fail
    xor r12d, r12d
.registry:
    mov edi, r12d
    call neboc_typed_math_registry_at
    test rax, rax
    jz fail
    mov rdx, [expected_registry_ids + r12 * 8]
    cmp [rax + NEBOC_OPERATOR_ENTRY_ID_OFFSET], rdx
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_CLASS_OFFSET], NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_STATE_OFFSET], NEBOC_OPERATOR_STATE_APPROVED_TARGET
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_DOMAIN_OFFSET], NEBOC_OPERATOR_DOMAIN_TYPED_MATH
    jne fail
    movzx edx, byte [expected_lengths + r12]
    cmp [rax + NEBOC_OPERATOR_ENTRY_LEXEME_COUNT_OFFSET], rdx
    jne fail
    mov rdi, [rax + NEBOC_OPERATOR_ENTRY_LEXEME_START_OFFSET]
    mov rsi, [expected_lexeme_pointers + r12 * 8]
    mov ecx, edx
    repe cmpsb
    jne fail
    inc r12d
    cmp r12d, 9
    jb .registry
    mov edi, 9
    call neboc_typed_math_registry_at
    test rax, rax
    jnz fail

    mov ebx, 1
    mov edi, 81
    mov esi, 2
    call nebo_root_exact_u64
    cmp rax, 9
    jne fail
    test edx, edx
    jnz fail
    mov edi, 27
    mov esi, 3
    call nebo_root_exact_u64
    cmp rax, 3
    jne fail
    mov edi, 80
    mov esi, 4
    call nebo_root_exact_u64
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    mov edi, 256
    mov esi, 4
    call nebo_root_exact_u64
    cmp rax, 4
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 2
    mov edi, 20
    call nebo_factorial_u64_checked
    mov r8, 2432902008176640000
    cmp rax, r8
    jne fail
    test edx, edx
    jnz fail
    mov edi, 21
    call nebo_factorial_u64_checked
    cmp edx, NEBO_QUANTITY_ERR_OVERFLOW
    jne fail
    xor edi, edi
    call nebo_factorial_u64_checked
    cmp rax, 1
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 3
    mov edi, 1
    xor esi, esi
    call nebo_contextual_infinity_f64
    test edx, edx
    jnz fail
    mov rdi, rax
    call nebo_is_infinity_f64_bits
    cmp eax, 1
    jne fail
    xor edi, edi
    call nebo_contextual_infinity_f64
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    mov edi, 2
    mov esi, 1
    call nebo_contextual_infinity_f64
    mov r8, 0xfff0000000000000
    cmp rax, r8
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 4
    mov edi, 1
    mov esi, 64
    call nebo_precision_constant_bits
    mov r8, 0x400921fb54442d18
    cmp rax, r8
    jne fail
    test edx, edx
    jnz fail
    mov edi, 2
    mov esi, 64
    call nebo_precision_constant_bits
    mov r8, 0x401921fb54442d18
    cmp rax, r8
    jne fail
    test edx, edx
    jnz fail

    mov ebx, 5
    mov rdi, -7
    mov rsi, 3
    call nebo_floor_rational_i64
    cmp rax, -3
    jne fail
    mov rdi, -7
    mov rsi, 3
    call nebo_ceil_rational_i64
    cmp rax, -2
    jne fail
    mov rdi, 7
    mov rsi, 3
    call nebo_floor_rational_i64
    cmp rax, 2
    jne fail
    mov rdi, 7
    mov rsi, 3
    call nebo_ceil_rational_i64
    cmp rax, 3
    jne fail
    mov rdi, 1
    xor esi, esi
    call nebo_floor_rational_i64
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail

    mov ebx, 6
    mov edi, NEBO_QUANTITY_ERR_OVERFLOW
    call nebo_math_domain_result_variant
    cmp eax, 2
    jne fail
    test edx, edx
    jnz fail
    mov edi, NEBO_QUANTITY_ERR_PRECISION
    call nebo_math_domain_result_variant
    cmp eax, 3
    jne fail
    mov edi, NEBO_QUANTITY_ERR_UNIT
    call nebo_math_domain_result_variant
    cmp eax, 4
    jne fail

    mov ebx, 7
    mov edi, 4                    ; fold factorial
    mov esi, 5
    xor edx, edx
    call nebo_math_constant_fold_i64
    cmp rax, 120
    jne fail
    test edx, edx
    jnz fail
    mov edi, 1                    ; fold exact square root
    mov esi, 144
    xor edx, edx
    call nebo_math_constant_fold_i64
    cmp rax, 12
    jne fail
    test edx, edx
    jnz fail
    mov edi, 5                    ; fold floor(-7/3)
    mov rsi, -7
    mov edx, 3
    call nebo_math_constant_fold_i64
    cmp rax, -3
    jne fail

    ; S07: formatter obtains exact bytes from the Registry and failure leaves
    ; caller state untouched.
    mov ebx, 7
    mov edi, 7
    lea rsi, [format_pointer]
    lea rdx, [format_length]
    call nebo_math_symbol_format
    test eax, eax
    jnz fail
    cmp qword [format_length], 7
    jne fail
    mov rax, [format_pointer]
    cmp byte [rax], 0xe2
    jne fail
    cmp byte [rax + 3], 'x'
    jne fail
    cmp byte [rax + 6], 0x8b
    jne fail
    mov rax, 0x1111222233334444
    mov [format_pointer], rax
    mov rax, 0x5555666677778888
    mov [format_length], rax
    mov edi, 9
    lea rsi, [format_pointer]
    lea rdx, [format_length]
    call nebo_math_symbol_format
    test eax, eax
    jz fail
    mov rax, 0x1111222233334444
    cmp [format_pointer], rax
    jne fail
    mov rax, 0x5555666677778888
    cmp [format_length], rax
    jne fail

    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, ebx
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
