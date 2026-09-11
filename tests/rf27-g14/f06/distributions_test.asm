bits 64
default rel
%include "runtime/numeric/distributions.inc"
section .data
align 8
weights dq 1.0,2.0,3.0
badweights dq 1.0,-1.0,1.0
zeros dq 0.0,0.0
values dq 1,2,3,4,5
sample dq 0,0,0
workspace times 5 dq 0
zero dq 0.0
one dq 1.0
fneg dq -0.1
two dq 2.0
infinity dq 0x7ff0000000000000
maximum dq 0x7fefffffffffffff
minimum dq 0xffefffffffffffff
overflow_weights dq 0x7fefffffffffffff,0x7fefffffffffffff
section .bss
align 8
rng resb NEBO_RANDOM_SIZE
rng2 resb NEBO_RANDOM_SIZE
section .text
global _start
_start:
 lea rdi,[rng]
 mov esi,123
 call nebo_random_seed
 test eax,eax
 jnz .fail1
 lea rdi,[rng]
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .fail2
 ucomisd xmm0,[rel zero]
 jb .fail3
 ucomisd xmm0,[rel one]
 jae .fail4
 lea rdi,[rng]
 movsd xmm0,[rel one]
 movsd xmm1,[rel two]
 call nebo_distribution_uniform_f64
 ucomisd xmm0,[rel one]
 jb .fail5
 ucomisd xmm0,[rel two]
 jae .fail6
 lea rdi,[rng]
 movsd xmm0,[rel two]
 movsd xmm1,[rel one]
 call nebo_distribution_uniform_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail7
 lea rdi,[rng]
 movsd xmm0,[rel one]
 call nebo_distribution_bernoulli
 cmp edx,1
 jne .fail8
 lea rdi,[rng]
 movsd xmm0,[rel zero]
 call nebo_distribution_bernoulli
 test edx,edx
 jnz .fail9
 lea rdi,[rng]
 movsd xmm0,[rel fneg]
 call nebo_distribution_bernoulli
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail10
 lea rdi,[rng]
 lea rsi,[weights]
 mov edx,3
 call nebo_distribution_categorical
 test eax,eax
 jnz .fail11
 cmp rdx,3
 jae .fail12
 lea rdi,[rng]
 lea rsi,[badweights]
 mov edx,3
 call nebo_distribution_categorical
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail13
 lea rdi,[rng]
 lea rsi,[zeros]
 mov edx,2
 call nebo_distribution_categorical
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail14
 lea rdi,[rng2]
 mov esi,123
 call nebo_random_seed
 lea rdi,[rng2]
 call nebo_distribution_uniform01_f64
 movq r8,xmm0
 lea rdi,[rng]
 mov esi,123
 call nebo_random_seed
 lea rdi,[rng]
 call nebo_distribution_uniform01_f64
 movq rax,xmm0
 cmp rax,r8
 jne .fail15
 lea rdi,[rng]
 lea rsi,[values]
 mov edx,5
 call nebo_distribution_shuffle_i64
 test eax,eax
 jnz .fail16
 xor r8d,r8d
 xor ecx,ecx
.sum:
 add r8,[values+rcx*8]
 inc rcx
 cmp rcx,5
 jb .sum
 cmp r8,15
 jne .fail17
 lea rdi,[rng]
 lea rsi,[values]
 mov edx,5
 mov ecx,3
 lea r8,[sample]
 lea r9,[workspace]
 call nebo_distribution_sample_i64
 test eax,eax
 jnz .fail18
 cmp qword [sample],0
 je .fail19
 lea rdi,[rng]
 call nebo_distribution_normal_f64
 test eax,eax
 jnz .fail20
 ucomisd xmm0,xmm0
 jp .fail21
 lea rdi,[rng]
 lea rsi,[values]
 mov edx,5
 mov ecx,6
 lea r8,[sample]
 lea r9,[workspace]
 call nebo_distribution_sample_i64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail22
 ; Invalid distribution domains must leave the explicit state unconsumed.
 lea rdi,[rng]
 mov esi,17
 call nebo_random_seed
 lea rdi,[rng]
 movsd xmm0,[rel zero]
 movsd xmm1,[rel infinity]
 call nebo_distribution_uniform_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail23
 lea rdi,[rng]
 movsd xmm0,[rel infinity]
 movsd xmm1,[rel one]
 call nebo_distribution_normal_params_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail24
 lea rdi,[rng]
 lea rsi,[overflow_weights]
 mov edx,2
 call nebo_distribution_categorical
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail25
 lea rdi,[rng]
 movsd xmm0,[rel minimum]
 movsd xmm1,[rel maximum]
 call nebo_distribution_uniform_f64
 cmp eax,NEBO_NUMERIC_ERROR_DOMAIN
 jne .fail26
 cmp qword [rng+NEBO_RANDOM_STATE],17
 jne .fail27
 cmp qword [rng+NEBO_RANDOM_CALLS],0
 jne .fail28
 xor edi,edi
 jmp .exit
%assign i 1
%rep 28
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
