bits 64
default rel
global _start
extern nebo_runtime_start
section .text
_start:
    lea rdi, [rel nebo_fn_1]
    call nebo_runtime_start
    ud2

nebo_fn_1:
    xor eax, eax
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
