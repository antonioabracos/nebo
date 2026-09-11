bits 64
default rel
extern nebo_runtime_trap_overflow
extern nebo_runtime_trap_division_by_zero
global _start
extern nebo_runtime_start

section .text
_start:
    lea rdi, [rel nebo_fn_1]
    call nebo_runtime_start
    ud2

section .text
global nebo_fn_1
nebo_fn_1:
    mov rax, 7
    push rax
    mov rax, 5
    push rax
    mov rax, 3
    mov rcx, rax
    pop rax
    imul rax, rcx
    jo .nebo_trap_overflow
    mov rcx, rax
    pop rax
    add rax, rcx
    jo .nebo_trap_overflow
    xor eax, eax
    ret
.nebo_trap_overflow:
    jmp nebo_runtime_trap_overflow

section .note.GNU-stack noalloc noexec nowrite progbits
