; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES ConstBinding storage metadata materialization
bits 64
default rel

%include "compiler/semantic/const_binding.inc"
%include "compiler/codegen/const_binding.inc"

global neboc_const_codegen_materialize

section .text
; rdi=symbol record, rsi=value, rdx=storage class, rcx=out metadata
neboc_const_codegen_materialize:
    test rdi, rdi
    jz .invalid
    test rcx, rcx
    jz .invalid
    cmp qword [rdi + NEBOC_CONST_SYMBOL_KIND_OFFSET], NEBOC_BINDING_KIND_CONST
    jne .invalid
    cmp edx, NEBOC_CONST_STORAGE_LOCAL
    je .commit
    cmp edx, NEBOC_CONST_STORAGE_MODULE_RODATA
    jne .invalid
.commit:
    mov rax, [rdi + NEBOC_CONST_SYMBOL_ID_OFFSET]
    mov [rcx + NEBOC_CONST_STORAGE_SYMBOL_ID_OFFSET], rax
    mov [rcx + NEBOC_CONST_STORAGE_VALUE_OFFSET], rsi
    mov [rcx + NEBOC_CONST_STORAGE_CLASS_OFFSET], rdx
    mov qword [rcx + NEBOC_CONST_STORAGE_FLAGS_OFFSET], \
        NEBOC_CONST_STORAGE_IMMUTABLE | NEBOC_CONST_STORAGE_INITIALIZED
    xor eax, eax
    ret
.invalid:
    mov eax, NEBOC_CONST_INVALID_ARGUMENT
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
