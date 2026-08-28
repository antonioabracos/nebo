; RESOLVER-TYPECHECKER-E-SEMANTICA-F06 bounded native composition example.
bits 64
default rel
%include "runtime/portable/portability.inc"
extern nebo_portability_evaluate
section .data
example_records dq 14,28,42,56
section .bss
example_report resb NEBO_PORTABILITY_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_portability_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
