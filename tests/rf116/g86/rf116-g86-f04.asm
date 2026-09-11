bits 64
default rel
%include "compiler/semantic/console_calls.inc"
%include "compiler/semantic/console_effects.inc"
extern neboc_console_option_effect_check
global _start
section .text
_start:
    lea rdi, [rel option]
    mov esi, NEBOC_EFFECT_TIME | NEBOC_EFFECT_RANDOM
    lea rdx, [rel proof]
    call neboc_console_option_effect_check
    test eax, eax
    jnz fail
    cmp qword [rel proof + NEBOC_EFFECT_REQUIRED_OFFSET], NEBOC_EFFECT_TIME
    jne fail
    lea rdi, [rel option]
    xor esi, esi
    lea rdx, [rel untouched]
    call neboc_console_option_effect_check
    cmp eax, NEBOC_OPTION_EFFECT_FORBIDDEN
    jne fail
    mov rax, 0xaaaaaaaaaaaaaaaa
    cmp qword [rel untouched], rax
    jne fail
    lea rdi, [rel pure_option]
    xor esi, esi
    lea rdx, [rel pure_proof]
    call neboc_console_option_effect_check
    test eax, eax
    jnz fail
    mov eax, 60
    xor edi, edi
    syscall
fail:
    mov eax, 60
    mov edi, 1
    syscall
section .rodata
name: db "timeout"
name_len equ $ - name
section .data
option: dq name, name_len, 0, 0, 1, 0, 7, NEBOC_EFFECT_TIME
pure_option: dq name, name_len, 0, 0, 1, 0, 7, 0
untouched: times NEBOC_EFFECT_SIZE db 0xaa
section .bss
proof: resb NEBOC_EFFECT_SIZE
pure_proof: resb NEBOC_EFFECT_SIZE
section .note.GNU-stack noalloc noexec nowrite progbits
