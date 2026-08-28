; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F01 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/geometry2d.inc"
extern nebo_geometry2d_evaluate
section .data
example_records dq 18,36,54,72
section .bss
example_report resb NEBO_GEOMETRY2D_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_geometry2d_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
