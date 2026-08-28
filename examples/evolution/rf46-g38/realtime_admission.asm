; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F06 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/realtime_admission.inc"
extern nebo_realtime_admission_evaluate
section .data
example_records dq 7,14,21,28
section .bss
example_report resb NEBO_REALTIME_ADMISSION_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_realtime_admission_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
