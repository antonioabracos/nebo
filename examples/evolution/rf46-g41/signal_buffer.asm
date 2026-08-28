; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F01 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/signal_buffer.inc"
extern nebo_signal_buffer_evaluate
section .data
example_records dq 15,30,45,60
section .bss
example_report resb NEBO_SIGNAL_BUFFER_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_signal_buffer_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
