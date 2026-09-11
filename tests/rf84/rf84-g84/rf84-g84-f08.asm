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
    mov edi, 8
    call integration_front_state
    cmp eax, 2
    jne fail

    mov edi, 1000
    mov esi, 2000
    mov edx, 4096
    mov ecx, 8192
    mov r8d, 100
    call performance_budget_check
    test eax, eax
    jnz fail
    mov edi, INTEGRATION_MAX_COMPILE_TICKS + 1
    xor esi, esi
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    call performance_budget_check
    cmp eax, INTEGRATION_LIMIT
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
