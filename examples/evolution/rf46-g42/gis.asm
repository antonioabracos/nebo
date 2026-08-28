; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F05 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/gis.inc"
extern nebo_gis_evaluate
section .data
example_records dq 22,44,66,88
section .bss
example_report resb NEBO_GIS_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_gis_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
