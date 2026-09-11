bits 64
default rel

section .text
global nebo_fn_1
nebo_fn_1:

section .rodata
align 8
nebo_int_1: dq 42

section .note.GNU-stack noalloc noexec nowrite progbits
