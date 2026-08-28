; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F04 bounded native composition example.
bits 64
default rel
%include "runtime/simulation/fixed_step.inc"
extern nebo_fixed_step_evaluate
section .data
example_records dq 32,64,96,128
section .bss
example_report resb NEBO_FIXED_STEP_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_fixed_step_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
