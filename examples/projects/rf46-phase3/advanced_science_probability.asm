bits 64
default rel
%include "runtime/probabilistic/decision_risk.inc"
extern nebo_bigint_gcd_u64
extern nebo_scientific_context_digest
extern nebo_prob_expected_utility_choose_f64
section .rodata
context db "RF46-PHASE3-v1;deterministic=1;seed=42"
context_len equ $-context
p dq 0.25,0.75
u dq 4.0,0.0,0.0,2.0
section .bss
digest resq 1
report resb NEBO_DECISION_REPORT_MAX_SIZE
section .text
global _start
_start:
    mov edi,84
    mov esi,30
    call nebo_bigint_gcd_u64
    cmp rax,6
    jne fail
    lea rdi,[context]
    mov esi,context_len
    lea rdx,[digest]
    call nebo_scientific_context_digest
    test eax,eax
    jnz fail
    lea rdi,[p]
    mov esi,2
    lea rdx,[u]
    mov ecx,2
    lea r8,[report]
    mov r9d,NEBO_DECISION_REPORT_MAX_SIZE
    call nebo_prob_expected_utility_choose_f64
    test eax,eax
    jnz fail
    cmp qword [report+NEBO_DECISION_REPORT_ACTION],1
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
