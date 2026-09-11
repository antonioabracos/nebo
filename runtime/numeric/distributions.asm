; RF27-G14-F06 explicit-PRNG bounded distributions
bits 64
default rel
%define NEBO_DISTRIBUTIONS_IMPLEMENTATION 1
%include "runtime/numeric/distributions.inc"
%include "runtime/math/transcendental.inc"
section .rodata
align 8
dist_zero dq 0.0
dist_one dq 1.0
dist_two dq 2.0
dist_neg_two dq -2.0
dist_two_pi dq 6.2831853071795864769
dist_2pow53 dq 9007199254740992.0
dist_exp_mask dq 0x7ff0000000000000
section .text
global nebo_distribution_uniform01_f64
global nebo_distribution_uniform_f64
global nebo_distribution_normal_f64
global nebo_distribution_normal_params_f64
global nebo_distribution_bernoulli
global nebo_distribution_categorical
global nebo_distribution_shuffle_i64
global nebo_distribution_sample_i64

; Random* rdi -> eax status, xmm0 in [0,1).
nebo_distribution_uniform01_f64:
 call nebo_random_next_u64
 test eax,eax
 jnz .u01_ret
 shr rdx,11
 cvtsi2sd xmm0,rdx
 divsd xmm0,[rel dist_2pow53]
.u01_ret: ret

; Random* rdi, low xmm0, high xmm1 -> bounded uniform.
nebo_distribution_uniform_f64:
 movq rax,xmm0
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .uniform_domain
 movq rax,xmm1
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .uniform_domain
 ucomisd xmm0,xmm0
 jp .uniform_domain
 ucomisd xmm1,xmm1
 jp .uniform_domain
 ucomisd xmm0,xmm1
 jae .uniform_domain
 ; A finite span is part of the bounded binary64 distribution profile.
 movapd xmm2,xmm1
 subsd xmm2,xmm0
 movq rax,xmm2
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .uniform_domain
 sub rsp,16
 movsd [rsp],xmm0
 movsd [rsp+8],xmm1
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .uniform_ret_stack
 movsd xmm1,[rsp+8]
 subsd xmm1,[rsp]
 mulsd xmm0,xmm1
 addsd xmm0,[rsp]
.uniform_ret_stack:
 add rsp,16
 ret
.uniform_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; Box-Muller v1, no cached pair. Random* rdi -> standard normal xmm0.
nebo_distribution_normal_f64:
 push r12
 mov r12,rdi
.normal_retry:
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .normal_ret
 ucomisd xmm0,[rel dist_zero]
 je .normal_retry
 sub rsp,16
 movsd [rsp],xmm0
 mov rdi,r12
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .normal_stack_ret
 mulsd xmm0,[rel dist_two_pi]
 movsd [rsp+8],xmm0
 movsd xmm0,[rsp]
 call nebo_math_log_f64
 test eax,eax
 jnz .normal_stack_ret
 mulsd xmm0,[rel dist_neg_two]
 sqrtsd xmm0,xmm0
 movsd [rsp],xmm0
 movsd xmm0,[rsp+8]
 call nebo_math_cos_f64
 mulsd xmm0,[rsp]
.normal_stack_ret:
 add rsp,16
.normal_ret:
 pop r12
 ret

; Random* rdi, mean xmm0, standard deviation xmm1 -> N(mean,stddev).
nebo_distribution_normal_params_f64:
 movq rax,xmm0
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .normal_params_domain
 movq rax,xmm1
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .normal_params_domain
 ucomisd xmm0,xmm0
 jp .normal_params_domain
 ucomisd xmm1,xmm1
 jp .normal_params_domain
 ucomisd xmm1,[rel dist_zero]
 jbe .normal_params_domain
 sub rsp,16
 movsd [rsp],xmm0
 movsd [rsp+8],xmm1
 call nebo_distribution_normal_f64
 test eax,eax
 jnz .normal_params_ret
 mulsd xmm0,[rsp+8]
 addsd xmm0,[rsp]
.normal_params_ret:
 add rsp,16
 ret
.normal_params_domain:
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; Random* rdi, probability xmm0 -> status eax, bool rdx.
nebo_distribution_bernoulli:
 ucomisd xmm0,[rel dist_zero]
 jp .bernoulli_domain
 jb .bernoulli_domain
 ucomisd xmm0,[rel dist_one]
 ja .bernoulli_domain
 sub rsp,8
 movsd [rsp],xmm0
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .bernoulli_stack
 xor edx,edx
 ucomisd xmm0,[rsp]
 setb dl
.bernoulli_stack:
 add rsp,8
 ret
.bernoulli_domain:
 xor edx,edx
 mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 ret

; Random rdi, weights rsi, count rdx -> selected index rdx.
nebo_distribution_categorical:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r13,r13
 jz .cat_arg
 test r14,r14
 jz .cat_domain
 cmp r14,NEBO_NUMERIC_MAX_ELEMENTS
 ja .cat_bounds
 xorpd xmm4,xmm4
 xor ecx,ecx
.cat_sum:
 movsd xmm0,[r13+rcx*8]
 ucomisd xmm0,xmm0
 jp .cat_domain
 ucomisd xmm0,[rel dist_zero]
 jb .cat_domain
 movq rax,xmm0
 mov rdx,rax
 and rdx,[rel dist_exp_mask]
 cmp rdx,[rel dist_exp_mask]
 je .cat_domain
 addsd xmm4,xmm0
 inc rcx
 cmp rcx,r14
 jb .cat_sum
 ucomisd xmm4,[rel dist_zero]
 jbe .cat_domain
 movq rax,xmm4
 and rax,[rel dist_exp_mask]
 cmp rax,[rel dist_exp_mask]
 je .cat_domain
 mov rdi,r12
 call nebo_distribution_uniform01_f64
 test eax,eax
 jnz .cat_ret
 mulsd xmm0,xmm4
 xorpd xmm1,xmm1
 xor ecx,ecx
.cat_pick:
 addsd xmm1,[r13+rcx*8]
 ucomisd xmm0,xmm1
 jb .cat_found
 inc rcx
 cmp rcx,r14
 jb .cat_pick
 mov rcx,r14
 dec rcx
.cat_found:
 mov rdx,rcx
 xor eax,eax
.cat_ret:
 pop r14
 pop r13
 pop r12
 ret
.cat_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .cat_ret
.cat_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .cat_ret
.cat_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .cat_ret

; Random rdi, values rsi, count rdx. In-place Fisher-Yates.
nebo_distribution_shuffle_i64:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r13,r13
 jz .shuffle_arg
 cmp r14,NEBO_NUMERIC_MAX_ELEMENTS
 ja .shuffle_bounds
 cmp r14,2
 jb .shuffle_ok
 dec r14
.shuffle_loop:
 mov rdi,r12
 xor esi,esi
 lea rdx,[r14+1]
 call nebo_random_next_range
 test eax,eax
 jnz .shuffle_ret
 mov rax,[r13+r14*8]
 mov rcx,[r13+rdx*8]
 mov [r13+r14*8],rcx
 mov [r13+rdx*8],rax
 dec r14
 jnz .shuffle_loop
.shuffle_ok: xor eax,eax
.shuffle_ret:
 pop r14
 pop r13
 pop r12
 ret
.shuffle_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .shuffle_ret
.shuffle_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .shuffle_ret

; Random rdi, input rsi, count rdx, k rcx, out r8, workspace r9.
nebo_distribution_sample_i64:
 push r12
 push r13
 push r14
 push r15
 push rbx
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r13,r13
 jz .sample_arg
 test rbx,rbx
 jz .sample_arg
 test r9,r9
 jz .sample_arg
 cmp r14,NEBO_NUMERIC_MAX_ELEMENTS
 ja .sample_bounds
 cmp r15,r14
 ja .sample_domain
 xor ecx,ecx
.sample_copy:
 cmp rcx,r14
 jae .sample_choose
 mov rax,[r13+rcx*8]
 mov [r9+rcx*8],rax
 inc rcx
 jmp .sample_copy
.sample_choose:
 xor r13d,r13d
.sample_loop:
 cmp r13,r15
 jae .sample_ok
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call nebo_random_next_range
 test eax,eax
 jnz .sample_ret
 mov rax,[r9+r13*8]
 mov rcx,[r9+rdx*8]
 mov [r9+r13*8],rcx
 mov [r9+rdx*8],rax
 mov [rbx+r13*8],rcx
 inc r13
 jmp .sample_loop
.sample_ok: xor eax,eax
.sample_ret:
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.sample_arg: mov eax,NEBO_NUMERIC_ERROR_ARGUMENT
 jmp .sample_ret
.sample_bounds: mov eax,NEBO_NUMERIC_ERROR_BOUNDS
 jmp .sample_ret
.sample_domain: mov eax,NEBO_NUMERIC_ERROR_DOMAIN
 jmp .sample_ret
section .note.GNU-stack noalloc noexec nowrite progbits
