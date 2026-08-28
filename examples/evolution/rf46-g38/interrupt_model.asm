; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F03 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/interrupt_model.inc"
extern nebo_interrupt_model_evaluate
section .data
example_records dq 4,8,12,16
section .bss
example_report resb NEBO_INTERRUPT_MODEL_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_interrupt_model_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
