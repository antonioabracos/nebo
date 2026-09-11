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
    mov edi, 7
    call integration_front_state
    cmp eax, 2
    jne fail

    call neboc_unicode_table_version
    cmp eax, NEBO_UNICODE_PROFILE_VERSION
    jne fail
    xor edi, edi
    call neboc_unicode_locale_supported
    cmp eax, 1
    jne fail
    mov edi, 1
    call neboc_unicode_locale_supported
    test eax, eax
    jnz fail
    mov edi, 100
    mov esi, 150
    call neboc_unicode_budget_check
    test eax, eax
    jnz fail
    mov edi, 100
    mov esi, 151
    call neboc_unicode_budget_check
    test eax, eax
    jz fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
