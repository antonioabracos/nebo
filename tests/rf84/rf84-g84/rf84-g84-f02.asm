bits 64
default rel
%include "runtime/textual/integration.inc"
%include "runtime/textual/text_core.inc"
%include "runtime/textual/scan_plan.inc"
%include "runtime/textual/format_data.inc"
%include "runtime/textual/unicode.inc"
%include "runtime/textual/text_privacy.inc"
extern neboc_text_builder_init
extern neboc_text_builder_append
extern neboc_format_feature_available
extern neboc_render_feature_available
extern neboc_privacy_label_valid
extern neboc_privacy_join
extern neboc_unicode_locale_supported
extern neboc_unicode_table_version
extern neboc_unicode_budget_check
global _start

section .text
_start:
    mov edi, 2
    call integration_front_state
    cmp eax, 2
    jne fail

    lea rdi, [rel result_a]
    mov esi, result_len
    lea rdx, [rel result_b]
    mov ecx, result_len
    mov r8d, 0x84
    mov r9d, 0x84
    call ab_semantic_equal
    cmp eax, 1
    jne fail
    lea rdx, [rel result_c]
    call ab_semantic_equal
    test eax, eax
    jnz fail
    mov edi, 3
    xor esi, esi
    call console_options_validate
    test eax, eax
    jnz fail
    xor edi, edi
    mov esi, 1
    call console_options_validate
    cmp eax, INTEGRATION_CONSOLE_DATA
    jne fail
    mov edi, INTEGRATION_CONSOLE_DATA
    call integration_diagnostic
    cmp eax, 0x848408
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
result_a: db 'value=42'
result_b: db 'value=42'
result_c: db 'value=43'
result_len equ $ - result_c
