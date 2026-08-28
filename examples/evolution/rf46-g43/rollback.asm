; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F05 bounded native composition example.
bits 64
default rel
%include "runtime/simulation/rollback.inc"
extern nebo_rollback_evaluate
section .data
example_records dq 33,66,99,132
section .bss
example_report resb NEBO_ROLLBACK_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_rollback_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
