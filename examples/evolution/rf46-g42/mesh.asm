; CLI-NEBOC-BUILD-REPL-E-FERRAMENTAS-F03 bounded native composition example.
bits 64
default rel
%include "runtime/spatial/mesh.inc"
extern nebo_mesh_evaluate
section .data
example_records dq 20,40,60,80
section .bss
example_report resb NEBO_MESH_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_mesh_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
