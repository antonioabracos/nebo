; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F05 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/sensor_fusion.inc"
extern nebo_sensor_fusion_evaluate
section .data
example_records dq 24,48,72,96
section .bss
example_report resb NEBO_SENSOR_FUSION_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_sensor_fusion_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
