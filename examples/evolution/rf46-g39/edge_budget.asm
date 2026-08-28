; RESOLVER-TYPECHECKER-E-SEMANTICA-F05 bounded native composition example.
bits 64
default rel
%include "runtime/portable/edge_budget.inc"
extern nebo_edge_budget_evaluate
section .data
example_records dq 13,26,39,52
section .bss
example_report resb NEBO_EDGE_BUDGET_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_edge_budget_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
