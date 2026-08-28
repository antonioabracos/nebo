; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F04 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/peripherals.inc"
extern nebo_peripherals_evaluate
section .data
example_records dq 5,10,15,20
section .bss
example_report resb NEBO_PERIPHERALS_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_peripherals_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
