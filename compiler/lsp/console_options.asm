; Nebo Assembly — CONSOLECALL-CONSOLEOPTION-REGISTRY-E-NORMALIZACAO bounded ConsoleOption schema information
bits 64
default rel
%include "runtime/console_option_registry.inc"
%include "runtime/console_options.inc"
%include "compiler/lsp/console_options.inc"
extern nebo_option_registry_lookup_name
global neboc_lsp_option_schema_info
section .text
; rdi=registry, rsi=count, rdx=name, rcx=len, r8=out info.
neboc_lsp_option_schema_info:
    test r8, r8
    jz .invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r15, r8
    lea r8, [rsp]
    call nebo_option_registry_lookup_name
    test eax, eax
    jnz .done
    mov rax, [rsp]
    mov rdx, [rax + NEBO_OPTION_SCHEMA_KIND_OFFSET]
    mov [r15 + NEBOC_LSP_OPTION_KIND_OFFSET], rdx
    mov rdx, [rax + NEBO_OPTION_SCHEMA_MIN_ARGS_OFFSET]
    mov [r15 + NEBOC_LSP_OPTION_MIN_ARGS_OFFSET], rdx
    mov rdx, [rax + NEBO_OPTION_SCHEMA_MAX_ARGS_OFFSET]
    mov [r15 + NEBOC_LSP_OPTION_MAX_ARGS_OFFSET], rdx
    xor eax, eax
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBO_OPTIONS_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
