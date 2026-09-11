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
    mov edi, 4
    call integration_front_state
    cmp eax, 2
    jne fail

    mov edi, 7501
    call neboc_scan_feature_available
    cmp eax, 1
    jne fail
    mov edi, 6801
    call neboc_render_feature_available
    cmp eax, 1
    jne fail
    mov edi, INTEGRATION_SCAN | INTEGRATION_RENDER_CONSOLE
    mov esi, edi
    call pipeline_require
    test eax, eax
    jnz fail
    mov edi, INTEGRATION_SCAN
    mov esi, INTEGRATION_SCAN | INTEGRATION_RENDER_CONSOLE
    call pipeline_require
    cmp eax, INTEGRATION_INVALID
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
