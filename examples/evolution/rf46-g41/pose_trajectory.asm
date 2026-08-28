; BACKEND-NATIVO-ASSEMBLY-ABI-TARGETS-E-LINKING-F04 bounded native composition example.
bits 64
default rel
%include "runtime/robotics/pose_trajectory.inc"
extern nebo_pose_trajectory_evaluate
section .data
example_records dq 23,46,69,92
section .bss
example_report resb NEBO_POSE_TRAJECTORY_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_pose_trajectory_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
