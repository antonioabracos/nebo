bits 64
default rel

%include "compiler/semantic/types/typed_quantity_contract.inc"
%include "compiler/tokens/operator_registry.inc"

extern neboc_typed_quantity_registry_at
extern neboc_typed_quantity_registry_count
extern nebo_postfix_percent_classify
extern nebo_postfix_percent_ratio
extern nebo_postfix_ratio_unit
extern nebo_angle_normalize
extern nebo_angle_add_checked
extern nebo_angle_suffix_classify
extern nebo_temperature_c_to_f_exact
extern nebo_temperature_f_to_c_exact
extern nebo_temperature_suffix_classify
extern nebo_quantity_add_checked
extern nebo_quantity_sub_checked
extern nebo_quantity_rescale_exact
extern nebo_quantity_format_suffix
extern nebo_quantity_serialization_tag
extern nebo_quantity_format_plan
extern nebo_quantity_console_label

section .rodata
expected_registry_ids:
    dq NEBOC_OPERATOR_ID_NSR_CORE_042
    dq NEBOC_OPERATOR_ID_NSR_DOM_019
    dq NEBOC_OPERATOR_ID_NSR_DOM_020
    dq NEBOC_OPERATOR_ID_NSR_DOM_021
    dq NEBOC_OPERATOR_ID_NSR_DOM_022
    dq NEBOC_OPERATOR_ID_NSR_DOM_023
expected_lexeme_lengths: db 1, 2, 3, 3, 3, 3

section .bss
format_plan: resb NEBO_QUANTITY_FORMAT_SIZE
failure_plan: resb NEBO_QUANTITY_FORMAT_SIZE

section .text
global _start
_start:
    ; S01/S08: the live Registry slice carries six stable, distinct identities.
    mov ebx, 1
    call neboc_typed_quantity_registry_count
    cmp eax, 6
    jne fail
    xor r12d, r12d
.registry_loop:
    mov edi, r12d
    call neboc_typed_quantity_registry_at
    test rax, rax
    jz fail
    mov rdx, [expected_registry_ids + r12 * 8]
    cmp [rax + NEBOC_OPERATOR_ENTRY_ID_OFFSET], rdx
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_STATE_OFFSET], NEBOC_OPERATOR_STATE_APPROVED_TARGET
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_CONTEXTS_OFFSET], NEBOC_OPERATOR_CONTEXT_EXPRESSION | NEBOC_OPERATOR_CONTEXT_BINDING
    jne fail
    movzx edx, byte [expected_lexeme_lengths + r12]
    cmp [rax + NEBOC_OPERATOR_ENTRY_LEXEME_COUNT_OFFSET], rdx
    jne fail
    test r12d, r12d
    jnz .domain_registry_row
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_CLASS_OFFSET], NEBOC_OPERATOR_CLASS_CORE_ALWAYS_ON
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_FIXITY_OFFSET], NEBOC_OPERATOR_FIXITY_CONTEXTUAL
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_PRECEDENCE_OFFSET], 120
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_FLAGS_OFFSET], NEBOC_OPERATOR_FLAG_CONTEXTUAL
    jne fail
    jmp .next_registry_row
.domain_registry_row:
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_CLASS_OFFSET], NEBOC_OPERATOR_CLASS_DOMAIN_GATED
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_FIXITY_OFFSET], NEBOC_OPERATOR_FIXITY_POSTFIX
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_PRECEDENCE_OFFSET], 170
    jne fail
    cmp qword [rax + NEBOC_OPERATOR_ENTRY_FLAGS_OFFSET], NEBOC_OPERATOR_FLAG_DOMAIN_GATE_REQUIRED
    jne fail
.next_registry_row:
    inc r12d
    cmp r12d, 6
    jb .registry_loop
    mov edi, 6
    call neboc_typed_quantity_registry_at
    test rax, rax
    jnz fail

    ; S01/S02: percent has postfix, infix-remainder and format contexts.
    mov ebx, 2
    mov edi, NEBO_QCTX_HAS_COMPLETE_OPERAND
    call nebo_postfix_percent_classify
    cmp eax, 1
    jne fail
    test edx, edx
    jnz fail
    mov edi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_EXPECTS_INFIX
    call nebo_postfix_percent_classify
    test eax, eax
    jnz fail
    test edx, edx
    jnz fail
    mov edi, NEBO_QCTX_FORMAT_PLACEHOLDER
    call nebo_postfix_percent_classify
    cmp eax, 2
    jne fail
    xor edi, edi
    call nebo_postfix_percent_classify
    cmp edx, NEBO_QUANTITY_ERR_SYNTAX
    jne fail
    mov rdi, -25
    call nebo_postfix_percent_ratio
    cmp rax, -25
    jne fail
    cmp rdx, 100
    jne fail
    test ecx, ecx
    jnz fail

    ; S03: Unicode ratios are exact and domain-gated.
    mov ebx, 3
    mov edi, 0x2030
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_postfix_ratio_unit
    cmp eax, NEBO_UNIT_PER_MILLE
    jne fail
    cmp rdx, 1000
    jne fail
    test ecx, ecx
    jnz fail
    mov edi, 0x2031
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_postfix_ratio_unit
    cmp eax, NEBO_UNIT_BASIS_POINTS
    jne fail
    cmp rdx, 10000
    jne fail
    mov edi, 0x2030
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND
    call nebo_postfix_ratio_unit
    cmp ecx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    mov edi, 'x'
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_postfix_ratio_unit
    cmp ecx, NEBO_QUANTITY_ERR_SYNTAX
    jne fail

    ; S04: Angle has exact millidegree normalization and checked arithmetic.
    mov ebx, 4
    mov rdi, -1000
    call nebo_angle_normalize
    cmp rax, 359000
    jne fail
    test edx, edx
    jnz fail
    mov rdi, 721000
    call nebo_angle_normalize
    cmp rax, 1000
    jne fail
    mov rdi, 120000
    mov rsi, 240000
    call nebo_angle_add_checked
    cmp rax, 360000
    jne fail
    test edx, edx
    jnz fail
    mov rdi, 0x7fffffffffffffff
    mov rsi, 1
    call nebo_angle_add_checked
    cmp edx, NEBO_QUANTITY_ERR_OVERFLOW
    jne fail
    mov edi, 0x00b0
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_angle_suffix_classify
    cmp eax, NEBO_UNIT_MILLIDEGREE
    jne fail
    test edx, edx
    jnz fail
    mov edi, 0x00b0
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND
    call nebo_angle_suffix_classify
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail

    ; S05: temperatures use exact affine conversion and report precision loss.
    mov ebx, 5
    xor edi, edi
    call nebo_temperature_c_to_f_exact
    cmp rax, 32000
    jne fail
    test edx, edx
    jnz fail
    mov edi, 100000
    call nebo_temperature_c_to_f_exact
    cmp rax, 212000
    jne fail
    mov edi, 32000
    call nebo_temperature_f_to_c_exact
    test rax, rax
    jnz fail
    test edx, edx
    jnz fail
    mov edi, 212000
    call nebo_temperature_f_to_c_exact
    cmp rax, 100000
    jne fail
    mov edi, 33000
    call nebo_temperature_f_to_c_exact
    cmp edx, NEBO_QUANTITY_ERR_PRECISION
    jne fail
    mov edi, 'C'
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_temperature_suffix_classify
    cmp eax, NEBO_UNIT_MILLI_CELSIUS
    jne fail
    mov edi, 'F'
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_temperature_suffix_classify
    cmp eax, NEBO_UNIT_MILLI_FAHRENHEIT
    jne fail
    mov edi, 'c'
    mov esi, NEBO_QCTX_HAS_COMPLETE_OPERAND | NEBO_QCTX_DOMAIN_ENABLED
    call nebo_temperature_suffix_classify
    cmp edx, NEBO_QUANTITY_ERR_SYNTAX
    jne fail

    ; S06: arithmetic is unit-safe, checked and exact under rescaling.
    mov ebx, 6
    mov rdi, 100
    mov esi, NEBO_UNIT_PERCENT
    mov rdx, 25
    mov ecx, NEBO_UNIT_PERCENT
    call nebo_quantity_add_checked
    cmp rax, 125
    jne fail
    test edx, edx
    jnz fail
    mov rdi, 100
    mov esi, NEBO_UNIT_PERCENT
    mov rdx, 25
    mov ecx, NEBO_UNIT_PERCENT
    call nebo_quantity_sub_checked
    cmp rax, 75
    jne fail
    mov rdi, 100
    mov esi, NEBO_UNIT_PERCENT
    mov rdx, 25
    mov ecx, NEBO_UNIT_MILLIDEGREE
    call nebo_quantity_add_checked
    cmp edx, NEBO_QUANTITY_ERR_UNIT
    jne fail
    mov rdi, 25
    mov rsi, 100
    mov rdx, 1
    call nebo_quantity_rescale_exact
    cmp rax, 2500
    jne fail
    test edx, edx
    jnz fail
    mov rdi, 1
    mov rsi, 1
    mov rdx, 3
    call nebo_quantity_rescale_exact
    cmp edx, NEBO_QUANTITY_ERR_PRECISION
    jne fail
    mov rdi, 1
    mov rsi, 1
    xor edx, edx
    call nebo_quantity_rescale_exact
    cmp edx, NEBO_QUANTITY_ERR_DOMAIN
    jne fail

    ; S07: formatting preserves the canonical UTF-8 symbol and stable unit tag.
    mov ebx, 7
    mov edi, NEBO_UNIT_PERCENT
    call nebo_quantity_format_suffix
    test ecx, ecx
    jnz fail
    cmp edx, 1
    jne fail
    cmp byte [rax], '%'
    jne fail
    mov edi, NEBO_UNIT_PER_MILLE
    call nebo_quantity_format_suffix
    cmp edx, 3
    jne fail
    cmp word [rax], 0x80e2
    jne fail
    cmp byte [rax + 2], 0xb0
    jne fail
    mov edi, NEBO_UNIT_BASIS_POINTS
    call nebo_quantity_format_suffix
    cmp byte [rax + 2], 0xb1
    jne fail
    mov edi, NEBO_UNIT_MILLIDEGREE
    call nebo_quantity_format_suffix
    cmp edx, 2
    jne fail
    cmp word [rax], 0xb0c2
    jne fail
    mov edi, NEBO_UNIT_MILLI_CELSIUS
    call nebo_quantity_format_suffix
    cmp edx, 3
    jne fail
    cmp byte [rax + 2], 'C'
    jne fail
    mov edi, NEBO_UNIT_MILLI_FAHRENHEIT
    call nebo_quantity_format_suffix
    cmp byte [rax + 2], 'F'
    jne fail
    mov r12d, NEBO_UNIT_PERCENT
.serialization_loop:
    mov edi, r12d
    call nebo_quantity_serialization_tag
    cmp eax, r12d
    jne fail
    test edx, edx
    jnz fail
    inc r12d
    cmp r12d, NEBO_UNIT_MILLI_FAHRENHEIT
    jbe .serialization_loop
    mov edi, 99
    call nebo_quantity_serialization_tag
    cmp edx, NEBO_QUANTITY_ERR_UNIT
    jne fail
    mov rdi, 2500
    mov esi, NEBO_UNIT_PERCENT
    mov edx, NEBO_QUANTITY_LOCALE_FR
    lea rcx, [format_plan]
    call nebo_quantity_format_plan
    test eax, eax
    jnz fail
    cmp qword [format_plan + NEBO_QUANTITY_FORMAT_VALUE_OFFSET], 2500
    jne fail
    cmp qword [format_plan + NEBO_QUANTITY_FORMAT_UNIT_OFFSET], NEBO_UNIT_PERCENT
    jne fail
    cmp qword [format_plan + NEBO_QUANTITY_FORMAT_SUFFIX_LENGTH_OFFSET], 1
    jne fail
    cmp qword [format_plan + NEBO_QUANTITY_FORMAT_LOCALE_OFFSET], NEBO_QUANTITY_LOCALE_FR
    jne fail
    mov qword [failure_plan], 0x5a5a5a5a
    mov rdi, 2500
    mov esi, NEBO_UNIT_PERCENT
    mov edx, 99
    lea rcx, [failure_plan]
    call nebo_quantity_format_plan
    cmp eax, NEBO_QUANTITY_ERR_DOMAIN
    jne fail
    cmp qword [failure_plan], 0x5a5a5a5a
    jne fail
    mov edi, NEBO_UNIT_MILLI_FAHRENHEIT
    call nebo_quantity_console_label
    cmp edx, 3
    jne fail
    cmp byte [rax + 2], 'F'
    jne fail

    xor edi, edi
    mov eax, 60
    syscall
fail:
    mov edi, ebx
    mov eax, 60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
