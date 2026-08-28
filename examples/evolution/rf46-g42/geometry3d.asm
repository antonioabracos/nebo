; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F02 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/geometry3d.inc"
extern nebo_geometry3d_evaluate
section .data
example_records dq 19,38,57,76
section .bss
example_report resb NEBO_GEOMETRY3D_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_geometry3d_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
