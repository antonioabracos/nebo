; RESOLVER-TYPECHECKER-E-SEMANTICA-F03 bounded native composition example.
bits 64
default rel
%include "runtime/portable/components.inc"
extern nebo_components_evaluate
section .data
example_records dq 11,22,33,44
section .bss
example_report resb NEBO_COMPONENTS_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_components_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
