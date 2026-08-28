; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F07 bounded native composition example.
bits 64
default rel
%include "runtime/simulation/particles.inc"
extern nebo_particles_evaluate
section .data
example_records dq 35,70,105,140
section .bss
example_report resb NEBO_PARTICLES_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_particles_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
