bits 64
default rel
%include "compiler/semantic/const_binding.inc"
%include "compiler/formatter/const_binding.inc"
%include "compiler/lsp/const_binding.inc"
%include "compiler/diagnostics/p01.inc"
extern neboc_const_symbol_resolve
extern neboc_format_const_name
extern neboc_lsp_const_rename
extern neboc_diag_from_const_status
global _start
section .text
_start:
    lea rdi, [rel old_name]
    mov esi, old_len
    mov edx, 6
    lea rcx, [rel old_symbol]
    call neboc_const_symbol_resolve
    test eax, eax
    jnz fail
    lea rdi, [rel old_name]
    mov esi, old_len
    lea rdx, [rel formatted]
    mov ecx, old_len
    call neboc_format_const_name
    test eax, eax
    jnz fail
    mov rax, [rel old_name]
    cmp rax, [rel formatted]
    jne fail

    lea rdi, [rel old_symbol]
    lea rsi, [rel new_name]
    mov edx, new_len
    mov ecx, 6
    lea r8, [rel new_symbol]
    call neboc_lsp_const_rename
    test eax, eax
    jnz fail
    lea rdi, [rel old_symbol]
    lea rsi, [rel bad_name]
    mov edx, bad_len
    mov ecx, 6
    lea r8, [rel untouched]
    call neboc_lsp_const_rename
    cmp eax, NEBOC_CONST_RENAME_CATEGORY_CHANGE
    jne fail

    mov edi, NEBOC_CONST_WRITE_FORBIDDEN
    mov esi, 10
    mov edx, 14
    lea rcx, [rel diagnostic]
    call neboc_diag_from_const_status
    test eax, eax
    jnz fail
    cmp qword [rel diagnostic + NEBOC_DIAG_CODE_OFFSET], NEBOC_DIAG_CONST_WRITE
    jne fail
    cmp qword [rel diagnostic + NEBOC_DIAG_START_OFFSET], 10
    jne fail
    cmp qword [rel diagnostic + NEBOC_DIAG_END_OFFSET], 14
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
old_name: db "MAX_SIZE"
old_len equ $ - old_name
new_name: db "MAX_BYTES"
new_len equ $ - new_name
bad_name: db "maxBytes"
bad_len equ $ - bad_name
section .bss
old_symbol: resb NEBOC_CONST_SYMBOL_SIZE
new_symbol: resb NEBOC_CONST_SYMBOL_SIZE
formatted: resb old_len
diagnostic: resb NEBOC_DIAG_SIZE
section .data
untouched: times NEBOC_CONST_SYMBOL_SIZE db 0xaa
section .note.GNU-stack noalloc noexec nowrite progbits
