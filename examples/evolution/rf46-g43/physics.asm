; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F03 bounded native composition example.
bits 64
default rel
%include "runtime/simulation/physics.inc"
extern nebo_physics_evaluate
section .data
example_records dq 31,62,93,124
section .bss
example_report resb NEBO_PHYSICS_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_physics_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
