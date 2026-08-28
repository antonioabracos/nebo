; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F04 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/spatial_index.inc"
extern nebo_spatial_index_evaluate
section .data
example_records dq 21,42,63,84
section .bss
example_report resb NEBO_SPATIAL_INDEX_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_spatial_index_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
