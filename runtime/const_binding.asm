; Nebo Assembly — CONSTBINDING-POR-ALL-CAPS-E-IDENTIDADE-DE-NOMES immutable ConstBinding runtime access
bits 64
default rel

%include "compiler/codegen/const_binding.inc"
%include "runtime/const_binding.inc"

global nebo_const_load

section .text
; rdi=storage metadata, rsi=out qword; output is untouched on failure.
nebo_const_load:
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov rax, [rdi + NEBOC_CONST_STORAGE_FLAGS_OFFSET]
    and eax, NEBOC_CONST_STORAGE_IMMUTABLE | NEBOC_CONST_STORAGE_INITIALIZED
    cmp eax, NEBOC_CONST_STORAGE_IMMUTABLE | NEBOC_CONST_STORAGE_INITIALIZED
    jne .uninitialized
    mov rax, [rdi + NEBOC_CONST_STORAGE_VALUE_OFFSET]
    mov [rsi], rax
    xor eax, eax
    ret
.uninitialized:
    mov eax, NEBOC_CONST_RUNTIME_UNINITIALIZED
    ret
.invalid:
    mov eax, NEBOC_CONST_RUNTIME_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
