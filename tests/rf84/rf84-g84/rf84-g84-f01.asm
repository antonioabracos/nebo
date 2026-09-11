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
    mov edi, 1
    call integration_front_state
    cmp eax, 2
    jne fail

    lea rdi, [rel counts]
    mov esi, 7
    call registry_counts_write
    test eax, eax
    jnz fail
    cmp qword [rel counts], 32
    jne fail
    cmp qword [rel counts + 8], 242
    jne fail
    cmp qword [rel counts + 16], 51
    jne fail
    cmp qword [rel counts + 24], 381
    jne fail
    cmp qword [rel counts + 32], 184
    jne fail
    cmp qword [rel counts + 40], 137
    jne fail
    cmp qword [rel counts + 48], 141
    jne fail
    lea rdi, [rel sentinel]
    mov esi, 6
    call registry_counts_write
    cmp eax, INTEGRATION_CAPACITY
    jne fail
    cmp qword [rel sentinel], 0x11223344
    jne fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .bss
counts: resq 7
section .data
sentinel: dq 0x11223344
