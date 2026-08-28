; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F02 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/filter_estimator.inc"
extern nebo_filter_estimator_evaluate
section .data
example_records dq 16,32,48,64
section .bss
example_report resb NEBO_FILTER_ESTIMATOR_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_filter_estimator_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
