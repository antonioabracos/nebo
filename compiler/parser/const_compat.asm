; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES explicit const compatibility classification
bits 64
default rel

%include "compiler/semantic/name_style.inc"
%include "compiler/semantic/const_binding.inc"
%include "compiler/parser/const_compat.inc"

extern neboc_name_style_classify
global neboc_const_parse_classify

section .text

; rdi=syntax kind, rsi=name, rdx=name length, rcx=out parse annotation
neboc_const_parse_classify:
    cmp edi, NEBOC_CONST_SYNTAX_FLOW
    je .syntax_ok
    cmp edi, NEBOC_CONST_SYNTAX_EXPLICIT
    jne .invalid
.syntax_ok:
    test rsi, rsi
    jz .invalid
    test rdx, rdx
    jz .invalid
    test rcx, rcx
    jz .invalid
    push rbx
    push r12
    push r13
    mov ebx, edi
    mov r12, rcx
    mov rdi, rsi
    mov rsi, rdx
    call neboc_name_style_classify
    test eax, eax
    jz .invalid_saved
    mov r13d, eax
    cmp ebx, NEBOC_CONST_SYNTAX_EXPLICIT
    je .explicit
    cmp r13d, NEBOC_NAME_ALL_CAPS
    jne .ordinary
    mov r8d, NEBOC_BINDING_KIND_CONST
    mov r9d, NEBOC_CONST_COMPAT_PREFERRED_FLOW
    jmp .commit
.explicit:
    mov r8d, NEBOC_BINDING_KIND_CONST
    mov r9d, NEBOC_CONST_COMPAT_EXPLICIT
    jmp .commit
.ordinary:
    mov r8d, NEBOC_BINDING_KIND_ORDINARY
    xor r9d, r9d
.commit:
    mov [r12 + NEBOC_CONST_PARSE_KIND_OFFSET], r8
    mov [r12 + NEBOC_CONST_PARSE_COMPAT_OFFSET], r9
    mov [r12 + NEBOC_CONST_PARSE_NAME_STYLE_OFFSET], r13
    xor eax, eax
    jmp .done
.invalid_saved:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
.done:
    pop r13
    pop r12
    pop rbx
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
