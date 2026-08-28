; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F03 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/control_core.inc"
extern nebo_control_core_evaluate
section .data
example_records dq 17,34,51,68
section .bss
example_report resb NEBO_CONTROL_CORE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_control_core_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
