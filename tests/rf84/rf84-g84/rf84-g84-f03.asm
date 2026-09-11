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
    mov edi, 3
    call integration_front_state
    cmp eax, 2
    jne fail

    lea rdi, [rel builder]
    lea rsi, [rel text_out]
    mov edx, 32
    call neboc_text_builder_init
    test eax, eax
    jnz fail
    lea rdi, [rel builder]
    lea rsi, [rel text_in]
    mov edx, text_len
    call neboc_text_builder_append
    test eax, eax
    jnz fail
    mov edi, 5901
    call neboc_format_feature_available
    cmp eax, 1
    jne fail
    mov edi, 6601
    call neboc_render_feature_available
    cmp eax, 1
    jne fail
    mov edi, INTEGRATION_TEXT | INTEGRATION_FORMAT | INTEGRATION_RENDER_CONSOLE
    mov esi, edi
    call pipeline_require
    test eax, eax
    jnz fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
text_in: db 'value=42'
text_len equ $ - text_in
section .bss
builder: resb 32
text_out: resb 32
