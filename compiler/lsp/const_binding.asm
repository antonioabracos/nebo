; Nebo Assembly — RF116 ConstBinding category-safe rename
bits 64
default rel
%include "compiler/semantic/const_binding.inc"
%include "compiler/lsp/const_binding.inc"
extern neboc_const_symbol_resolve
global neboc_lsp_const_rename
section .text
; rdi=old symbol, rsi=new spelling, rdx=len, rcx=scope id, r8=out symbol
neboc_lsp_const_rename:
    test rdi, rdi
    jz .invalid
    test r8, r8
    jz .invalid
    cmp qword [rdi + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne .invalid
    mov rdi, rsi
    mov rsi, rdx
    mov rdx, rcx
    mov rcx, r8
    sub rsp, 8
    call neboc_const_symbol_resolve
    add rsp, 8
    cmp eax, NEBOC_CONST_NAME_NOT_ALL_CAPS
    jne .done
    mov eax, NEBOC_CONST_RENAME_CATEGORY_CHANGE
.done:
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
