; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F07 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/robot_simulation.inc"
extern nebo_robot_simulation_evaluate
section .data
example_records dq 26,52,78,104
section .bss
example_report resb NEBO_ROBOT_SIMULATION_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_robot_simulation_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
