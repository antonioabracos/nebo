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
    xor eax, eax
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
