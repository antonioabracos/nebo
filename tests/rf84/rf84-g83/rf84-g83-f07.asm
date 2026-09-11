bits 64
default rel
%include "runtime/textual/format_data.inc"
%include "runtime/textual/tooling.inc"
global _start

section .text
_start:
    mov edi, 41
    call format_front_state
    cmp eax, FMT_STATE_PUBLIC
    jne fail
    mov edi, 7
    mov esi, 8307
    call nebo_g083_source_probe
    cmp eax, 115
    jne fail

    lea rdi, [rel haystack]
    mov esi, haystack_len
    lea rdx, [rel needle]
    mov ecx, needle_len
    mov r8d, 64
    call pattern_find
    test eax, eax
    jnz fail
    cmp edx, 6
    jne fail
    lea rdi, [rel haystack]
    mov esi, haystack_len
    lea rdx, [rel needle]
    mov ecx, needle_len
    mov r8d, 1
    call pattern_find
    cmp eax, FMT_LIMIT
    jne fail
    lea rdi, [rel dirty]
    mov esi, dirty_len
    lea rdx, [rel clean]
    mov ecx, 32
    call format_normalize
    test eax, eax
    jnz fail
    cmp edx, clean_len
    jne fail
    lea rdi, [rel clean]
    mov rsi, rdx
    call lint_text
    test eax, eax
    jnz fail
    test edx, edx
    jnz fail
    lea rdi, [rel dirty]
    mov esi, dirty_len
    call lint_text
    test eax, eax
    jnz fail
    test edx, edx
    jz fail

success:
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
haystack: db 'alpha beta'
haystack_len equ $ - haystack
needle: db 'beta'
needle_len equ $ - needle
dirty: db 'a  ', 13, 10, 'b', 9, 10
dirty_len equ $ - dirty
section .bss
clean: resb 32
clean_len equ 4
