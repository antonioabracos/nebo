bits 64
default rel
%include "runtime/probabilistic/distributions.inc"
extern nebo_prob_splitmix64_next
extern nebo_prob_xorshift64star_next
extern nebo_prob_normal_unit_logpdf_f64
extern nebo_prob_categorical_u64
section .data
s1 dq 42
s2 dq 42
x0 dq 0.0
mean0 dq 0.0
expected_log dq -0.91893853320467274178
weights dq 1,3
zero_state dq 0
section .bss
r1 resq 1
r2 resq 1
logp resq 1
category resq 1
section .text
global _start
_start:
    lea rdi,[s1]
    lea rsi,[r1]
    call nebo_prob_xorshift64star_next
    test eax,eax
    jnz fail
    lea rdi,[s2]
    lea rsi,[r2]
    call nebo_prob_xorshift64star_next
    test eax,eax
    jnz fail
    mov rax,[r1]
    cmp [r2],rax
    jne fail
    lea rdi,[logp]
    lea rsi,[x0]
    lea rdx,[mean0]
    call nebo_prob_normal_unit_logpdf_f64
    test eax,eax
    jnz fail
    mov rax,[expected_log]
    cmp [logp],rax
    jne fail
    lea rdi,[s1]
    lea rsi,[weights]
    mov edx,2
    lea rcx,[category]
    call nebo_prob_categorical_u64
    test eax,eax
    jnz fail
    cmp qword [category],2
    jae fail
    mov qword [r1],0x1234
    lea rdi,[zero_state]
    lea rsi,[r1]
    call nebo_prob_xorshift64star_next
    cmp eax,NEBO_PROB_INVALID
    jne fail
    cmp qword [r1],0x1234
    jne fail
    xor edi,edi
    jmp exit
fail: mov edi,1
exit: mov eax,60
    syscall
section .note.GNU-stack noalloc noexec nowrite progbits
