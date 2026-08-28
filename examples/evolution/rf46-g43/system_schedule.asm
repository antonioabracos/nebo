; LSP-EDITOR-E-EXPERIENCIA-DE-DESENVOLVIMENTO-F02 bounded native composition example.
bits 64
default rel
%include "runtime/simulation/system_schedule.inc"
extern nebo_system_schedule_evaluate
section .data
example_records dq 30,60,90,120
section .bss
example_report resb NEBO_SYSTEM_SCHEDULE_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[example_records]
    mov esi,4
    lea rdx,[example_report]
    call nebo_system_schedule_evaluate
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
