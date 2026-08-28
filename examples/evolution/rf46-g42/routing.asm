; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F06 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/routing.inc"
extern nebo_routing_evaluate
section .data
example_records dq 27,54,81,108
section .bss
example_report resb NEBO_ROUTING_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_routing_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
