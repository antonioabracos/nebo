bits 64
default rel
%include "runtime/probabilistic/mcmc_smc.inc"
extern nebo_prob_mh_accept_u64
extern nebo_prob_smc_systematic_u64
section .data
state dq 42
weights dq 1,3
bad_weights dq 1,0
section .bss
accepted resq 1
indices resq 2
section .text
global _start
_start:
    lea rdi,[state]
    mov esi,3
    mov edx,5
    lea rcx,[accepted]
    call nebo_prob_mh_accept_u64
    test eax,eax
    jnz fail
    cmp qword [accepted],1
    jne fail
    lea rdi,[weights]
    mov esi,2
    xor edx,edx
    lea rcx,[indices]
    call nebo_prob_smc_systematic_u64
    test eax,eax
    jnz fail
    cmp qword [indices],0
    jne fail
    cmp qword [indices+8],1
    jne fail
    mov qword [indices],0x1234
    lea rdi,[bad_weights]
    mov esi,2
    xor edx,edx
    lea rcx,[indices]
    call nebo_prob_smc_systematic_u64
    cmp eax,NEBO_MC_INVALID
    jne fail
    cmp qword [indices],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
