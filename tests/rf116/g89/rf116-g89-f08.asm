bits 64
default rel
%include "runtime/console_options.inc"
%include "runtime/console_option_registry.inc"
%include "compiler/diagnostics/p01.inc"
%include "compiler/formatter/console_options.inc"
%include "compiler/lsp/console_options.inc"
extern neboc_diag_from_option_status
extern neboc_format_option_schema_key
extern neboc_lsp_option_schema_info
global _start
section .text
_start:
    mov edi, NEBO_OPTIONS_CONFLICT
    mov esi, 20
    mov edx, 25
    lea rcx, [rel diagnostic]
    call neboc_diag_from_option_status
    test eax, eax
    jnz fail
    cmp qword [rel diagnostic + NEBOC_DIAG_CODE_OFFSET], NEBOC_DIAG_OPTION_CONFLICT
    jne fail
    lea rdi, [rel title]
    mov esi, 5
    lea rdx, [rel formatted]
    mov ecx, 5
    call neboc_format_option_schema_key
    test eax, eax
    jnz fail
    mov eax, [rel title]
    cmp eax, [rel formatted]
    jne fail
    mov al, [rel title + 4]
    cmp al, [rel formatted + 4]
    jne fail
    lea rdi, [rel schema]
    mov esi, 1
    lea rdx, [rel title]
    mov ecx, 5
    lea r8, [rel info]
    call neboc_lsp_option_schema_info
    test eax, eax
    jnz fail
    cmp qword [rel info + NEBOC_LSP_OPTION_KIND_OFFSET], 2
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
title: db "title"
schema: dq 2, 1, 1, 0, 0, title, 5
section .bss
diagnostic: resb NEBOC_DIAG_SIZE
formatted: resb 5
info: resb NEBOC_LSP_OPTION_INFO_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
