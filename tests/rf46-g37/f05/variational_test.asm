bits 64
default rel
%include "runtime/probabilistic/variational.inc"
extern nebo_prob_vi_normal_meanfield_update
section .data
prior_mean dq 0.0
prior_precision dq 1.0
bad_precision dq 0.0
observation_sum dq 6.0
observation_count dq 3
expected_mean dq 1.5
expected_precision dq 4.0
expected_variance dq 0.25
ctx dq prior_mean,prior_precision,observation_sum,observation_count
badctx dq prior_mean,bad_precision,observation_sum,observation_count
section .bss
report resb NEBO_VI_REPORT_SIZE
section .text
global _start
_start:
    lea rdi,[ctx]
    lea rsi,[report]
    call nebo_prob_vi_normal_meanfield_update
    test eax,eax
    jnz fail
    mov rax,[expected_mean]
    cmp [report+NEBO_VI_REPORT_MEAN],rax
    jne fail
    mov rax,[expected_precision]
    cmp [report+NEBO_VI_REPORT_PRECISION],rax
    jne fail
    mov rax,[expected_variance]
    cmp [report+NEBO_VI_REPORT_VARIANCE],rax
    jne fail
    mov qword [report],0x1234
    lea rdi,[badctx]
    lea rsi,[report]
    call nebo_prob_vi_normal_meanfield_update
    cmp eax,NEBO_VI_INVALID
    jne fail
    cmp qword [report],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
