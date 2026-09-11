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
    mov edi, 5
    call integration_front_state
    cmp eax, 2
    jne fail

    mov edi, FMT_CSV
    call format_validate_kind
    test eax, eax
    jnz fail
    lea rdi, [rel descriptors]
    mov esi, 1
    call ascii_upper_vector
    test eax, eax
    jnz fail
    cmp dword [rel output], 'DATA'
    jne fail
    mov edi, INTEGRATION_FORMAT_DATA | INTEGRATION_TEXT
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
input: db 'data'
descriptors: dq input, 4, output, 4
section .bss
output: resb 4
