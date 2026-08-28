bits 64
default rel
%include "runtime/probabilistic/decision_risk.inc"
extern nebo_prob_expected_utility_choose_f64
section .rodata
p dq 0.25,0.75
u dq 4.0,0.0,0.0,2.0
section .bss
report resb NEBO_DECISION_REPORT_MAX_SIZE
section .text
global _start
_start:
    lea rdi,[p]
    mov esi,2
    lea rdx,[u]
    mov ecx,2
    lea r8,[report]
    mov r9d,NEBO_DECISION_REPORT_MAX_SIZE
    call nebo_prob_expected_utility_choose_f64
    mov edi,eax
    mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
