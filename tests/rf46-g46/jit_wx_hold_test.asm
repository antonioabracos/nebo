bits 64
default rel

extern nebo_jit_new
extern nebo_jit_compile_i64_v0
extern nebo_jit_call_i64_v0
extern nebo_jit_collect

section .data
delay: dq 1,0

section .bss align=16
session: resb 48

section .text
global _start
_start:
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_new
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,0x4634
    mov edx,42
    call nebo_jit_compile_i64_v0
    test rax,rax
    jnz .fail
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_call_i64_v0
    cmp rax,42
    jne .fail
    mov eax,35
    lea rdi,[rel delay]
    xor esi,esi
    syscall
    lea rdi,[rel session]
    mov esi,0x4634
    call nebo_jit_collect
    test rax,rax
    jnz .fail
    xor edi,edi
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall

section .note.GNU-stack noalloc noexec nowrite progbits
