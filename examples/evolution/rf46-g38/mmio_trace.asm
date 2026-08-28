; LEXER-PARSER-GRAMATICA-E-SOURCE-INFRASTRUCTURE-F02 bounded native composition example.
bits 64
default rel
%include "runtime/embedded/mmio_trace.inc"
extern nebo_mmio_trace_evaluate
section .data
example_records dq 3,6,9,12
section .bss
example_report resb NEBO_MMIO_TRACE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_mmio_trace_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
