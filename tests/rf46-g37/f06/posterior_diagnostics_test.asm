bits 64
default rel
%include "runtime/probabilistic/posterior_diagnostics.inc"
extern nebo_prob_rank_normalized_diagnostics_f64
section .data
scores dq -1.0,1.0,-1.0,1.0,-0.9,1.1,-0.9,1.1
one dq 1.0
eight dq 8.0
section .bss
report resb NEBO_DIAG_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[scores]
    mov esi,4
    lea rdx,[report]
    call nebo_prob_rank_normalized_diagnostics_f64
    test eax,eax
    jnz fail
    mov rax,[one]
    cmp [report+NEBO_DIAG_REPORT_SPLIT_RHAT],rax
    jne fail
    mov rax,[eight]
    cmp [report+NEBO_DIAG_REPORT_BULK_ESS],rax
    jne fail
    mov qword [report],0x1234
    lea rdi,[scores]
    mov esi,2
    lea rdx,[report]
    call nebo_prob_rank_normalized_diagnostics_f64
    cmp eax,NEBO_DIAG_INSUFFICIENT
    jne fail
    cmp qword [report],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
