bits 64
default rel
%define NEBO_OPTIMIZERS_IMPLEMENTATION 1
%include "runtime/training/optimizers.inc"
section .rodata align=16
o_exp dq 0x7ff0000000000000,0
o_zero dq 0.0
o_one dq 1.0
section .text
global nebo_optimizer_sgd
global nebo_optimizer_momentum
global nebo_optimizer_adam
global nebo_optimizer_zero_grad
global nebo_schedule_step_decay
global nebo_schedule_linear_decay
global nebo_optimizer_state_copy

; rdi=params, rsi=gradients, rdx=count, rcx=*learning_rate.
nebo_optimizer_sgd:
 test rdi,rdi
 jz .sgd_arg
 test rsi,rsi
 jz .sgd_arg
 test rcx,rcx
 jz .sgd_arg
 test rdx,rdx
 jz .sgd_limit
 cmp rdx,NEBO_OPTIMIZER_MAX_PARAMS
 ja .sgd_limit
 movsd xmm3,[rcx]
 movq rax,xmm3
 mov r8,rax
 and r8,[rel o_exp]
 cmp r8,[rel o_exp]
 je .sgd_hyper
 ucomisd xmm3,[rel o_zero]
 jbe .sgd_hyper
 xor r8d,r8d
.sgd_check:
 cmp r8,rdx
 jae .sgd_apply
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .sgd_nonfinite
 mov rax,[rsi+r8*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .sgd_nonfinite
 movsd xmm0,[rsi+r8*8]
 mulsd xmm0,xmm3
 movsd xmm1,[rdi+r8*8]
 subsd xmm1,xmm0
 movq rax,xmm1
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .sgd_nonfinite
 inc r8
 jmp .sgd_check
.sgd_apply:
 xor r8d,r8d
.sgd_loop:
 cmp r8,rdx
 jae .sgd_ok
 movsd xmm0,[rsi+r8*8]
 mulsd xmm0,xmm3
 movsd xmm1,[rdi+r8*8]
 subsd xmm1,xmm0
 movsd [rdi+r8*8],xmm1
 inc r8
 jmp .sgd_loop
.sgd_ok:
 xor eax,eax
 ret
.sgd_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.sgd_limit:
 mov eax,NEBO_OPTIMIZER_E_LIMIT
 ret
.sgd_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret
.sgd_hyper:
 mov eax,NEBO_OPTIMIZER_E_HYPERPARAMETER
 ret

; rdi=params, rsi=gradients, rdx=velocity, rcx=count, r8=*lr, r9=*momentum.
nebo_optimizer_momentum:
 test rdi,rdi
 jz .mom_arg
 test rsi,rsi
 jz .mom_arg
 test rdx,rdx
 jz .mom_arg
 test r8,r8
 jz .mom_arg
 test r9,r9
 jz .mom_arg
 test rcx,rcx
 jz .mom_limit
 cmp rcx,NEBO_OPTIMIZER_MAX_PARAMS
 ja .mom_limit
 movsd xmm4,[r8]
 movsd xmm5,[r9]
 movq rax,xmm4
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .mom_hyper
 movq rax,xmm5
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .mom_hyper
 ucomisd xmm4,[rel o_zero]
 jbe .mom_hyper
 ucomisd xmm5,[rel o_zero]
 jb .mom_hyper
 ucomisd xmm5,[rel o_one]
 jae .mom_hyper
 xor r10d,r10d
.mom_check:
 cmp r10,rcx
 jae .mom_apply
 mov rax,[rdi+r10*8]
 mov r11,rax
 and r11,[rel o_exp]
 cmp r11,[rel o_exp]
 je .mom_nonfinite
 mov rax,[rsi+r10*8]
 mov r11,rax
 and r11,[rel o_exp]
 cmp r11,[rel o_exp]
 je .mom_nonfinite
 mov rax,[rdx+r10*8]
 mov r11,rax
 and r11,[rel o_exp]
 cmp r11,[rel o_exp]
 je .mom_nonfinite
 movsd xmm0,[rdx+r10*8]
 mulsd xmm0,xmm5
 addsd xmm0,[rsi+r10*8]
 movsd xmm1,xmm0
 mulsd xmm1,xmm4
 movsd xmm2,[rdi+r10*8]
 subsd xmm2,xmm1
 movq rax,xmm0
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .mom_nonfinite
 movq rax,xmm2
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .mom_nonfinite
 inc r10
 jmp .mom_check
.mom_apply:
 xor r10d,r10d
.mom_loop:
 cmp r10,rcx
 jae .mom_ok
 movsd xmm0,[rdx+r10*8]
 mulsd xmm0,xmm5
 addsd xmm0,[rsi+r10*8]
 movsd [rdx+r10*8],xmm0
 mulsd xmm0,xmm4
 movsd xmm1,[rdi+r10*8]
 subsd xmm1,xmm0
 movsd [rdi+r10*8],xmm1
 inc r10
 jmp .mom_loop
.mom_ok:
 xor eax,eax
 ret
.mom_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.mom_limit:
 mov eax,NEBO_OPTIMIZER_E_LIMIT
 ret
.mom_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret
.mom_hyper:
 mov eax,NEBO_OPTIMIZER_E_HYPERPARAMETER
 ret

; Request96: params*,grad*,m*,v*,count,step,lr*,beta1*,beta2*,eps*,beta1pow*,beta2pow*.
nebo_optimizer_adam:
 test rdi,rdi
 jz .adam_arg
 mov rax,[rdi]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+8]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+16]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+24]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+48]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+56]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+64]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+72]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+80]
 test rax,rax
 jz .adam_arg
 mov rax,[rdi+88]
 test rax,rax
 jz .adam_arg
 mov r8,[rdi+32]
 test r8,r8
 jz .adam_limit
 cmp r8,NEBO_OPTIMIZER_MAX_PARAMS
 ja .adam_limit
 mov r9,[rdi+40]
 test r9,r9
 jz .adam_step
 cmp r9,NEBO_OPTIMIZER_MAX_STEPS
 ja .adam_step
 mov rax,[rdi+48]
 movsd xmm7,[rax]
 ucomisd xmm7,[rel o_zero]
 jbe .adam_hyper
 mov rax,[rdi+56]
 movsd xmm2,[rax]
 ucomisd xmm2,[rel o_zero]
 jb .adam_hyper
 ucomisd xmm2,[rel o_one]
 jae .adam_hyper
 mov rax,[rdi+64]
 movsd xmm3,[rax]
 ucomisd xmm3,[rel o_zero]
 jb .adam_hyper
 ucomisd xmm3,[rel o_one]
 jae .adam_hyper
 mov rax,[rdi+72]
 movsd xmm6,[rax]
 ucomisd xmm6,[rel o_zero]
 jbe .adam_hyper
 mov rax,[rdi+80]
 movsd xmm4,[rax]
 ucomisd xmm4,[rel o_zero]
 jb .adam_hyper
 ucomisd xmm4,[rel o_one]
 jae .adam_hyper
 mov rax,[rdi+88]
 movsd xmm5,[rax]
 ucomisd xmm5,[rel o_zero]
 jb .adam_hyper
 ucomisd xmm5,[rel o_one]
 jae .adam_hyper
 movq rax,xmm7
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 movq rax,xmm2
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 movq rax,xmm3
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 movq rax,xmm6
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 movq rax,xmm4
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 movq rax,xmm5
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_hyper
 xor r10d,r10d
.adam_check:
 cmp r10,r8
 jae .adam_apply
 mov r11,[rdi]
 mov rax,[r11+r10*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .adam_nonfinite
 mov r11,[rdi+8]
 mov rax,[r11+r10*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .adam_nonfinite
 mov r11,[rdi+16]
 mov rax,[r11+r10*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .adam_nonfinite
 mov r11,[rdi+24]
 mov rax,[r11+r10*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .adam_nonfinite
 call adam_compute
 movq rax,xmm0
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_nonfinite
 movq rax,xmm1
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_nonfinite
 movq rax,xmm2
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .adam_nonfinite
 inc r10
 jmp .adam_check
.adam_apply:
 xor r10d,r10d
.adam_loop:
 cmp r10,r8
 jae .adam_ok
 call adam_compute
 mov r11,[rdi]
 movsd [r11+r10*8],xmm0
 mov r11,[rdi+16]
 movsd [r11+r10*8],xmm1
 mov r11,[rdi+24]
 movsd [r11+r10*8],xmm2
 inc r10
 jmp .adam_loop
.adam_ok:
 xor eax,eax
 ret
.adam_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.adam_limit:
 mov eax,NEBO_OPTIMIZER_E_LIMIT
 ret
.adam_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret
.adam_hyper:
 mov eax,NEBO_OPTIMIZER_E_HYPERPARAMETER
 ret
.adam_step:
 mov eax,NEBO_OPTIMIZER_E_STEP
 ret

; Internal: rdi=request, r10=index; xmm0=pnew, xmm1=mnew, xmm2=vnew.
adam_compute:
 mov r11,[rdi+8]
 movsd xmm0,[r11+r10*8]
 mov r11,[rdi+16]
 movsd xmm1,[r11+r10*8]
 mov rax,[rdi+56]
 movsd xmm2,[rax]
 mulsd xmm1,xmm2
 movsd xmm2,[rel o_one]
 mov rax,[rdi+56]
 subsd xmm2,[rax]
 mulsd xmm0,xmm2
 addsd xmm1,xmm0
 mov r11,[rdi+8]
 movsd xmm0,[r11+r10*8]
 mulsd xmm0,xmm0
 movsd xmm2,[rel o_one]
 mov rax,[rdi+64]
 subsd xmm2,[rax]
 mulsd xmm0,xmm2
 mov r11,[rdi+24]
 movsd xmm2,[r11+r10*8]
 mov rax,[rdi+64]
 mulsd xmm2,[rax]
 addsd xmm2,xmm0
 movsd xmm3,[rel o_one]
 mov rax,[rdi+80]
 subsd xmm3,[rax]
 movsd xmm4,xmm1
 divsd xmm4,xmm3
 movsd xmm3,[rel o_one]
 mov rax,[rdi+88]
 subsd xmm3,[rax]
 movsd xmm5,xmm2
 divsd xmm5,xmm3
 sqrtsd xmm5,xmm5
 mov rax,[rdi+72]
 addsd xmm5,[rax]
 divsd xmm4,xmm5
 mov rax,[rdi+48]
 mulsd xmm4,[rax]
 mov r11,[rdi]
 movsd xmm0,[r11+r10*8]
 subsd xmm0,xmm4
 ret

; rdi=gradients, rsi=count.
nebo_optimizer_zero_grad:
 test rdi,rdi
 jz .zg_arg
 test rsi,rsi
 jz .zg_limit
 cmp rsi,NEBO_OPTIMIZER_MAX_PARAMS
 ja .zg_limit
 xor eax,eax
 mov rcx,rsi
 rep stosq
 xor eax,eax
 ret
.zg_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.zg_limit:
 mov eax,NEBO_OPTIMIZER_E_LIMIT
 ret

; rdi=*initial, rsi=*gamma, rdx=step, rcx=interval, r8=*output.
nebo_schedule_step_decay:
 test rdi,rdi
 jz .sd_arg
 test rsi,rsi
 jz .sd_arg
 test r8,r8
 jz .sd_arg
 test rcx,rcx
 jz .sd_step
 cmp rdx,NEBO_OPTIMIZER_MAX_STEPS
 ja .sd_step
 movsd xmm0,[rdi]
 movsd xmm1,[rsi]
 ucomisd xmm0,[rel o_zero]
 jbe .sd_hyper
 ucomisd xmm1,[rel o_zero]
 jbe .sd_hyper
 ucomisd xmm1,[rel o_one]
 ja .sd_hyper
 mov rax,rdx
 xor edx,edx
 div rcx
 xor ecx,ecx
.sd_loop:
 cmp rcx,rax
 jae .sd_done
 mulsd xmm0,xmm1
 inc rcx
 jmp .sd_loop
.sd_done:
 movq rax,xmm0
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .sd_nonfinite
 movsd [r8],xmm0
 xor eax,eax
 ret
.sd_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.sd_step:
 mov eax,NEBO_OPTIMIZER_E_STEP
 ret
.sd_hyper:
 mov eax,NEBO_OPTIMIZER_E_HYPERPARAMETER
 ret
.sd_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret

; rdi=*initial, rsi=step, rdx=total_steps, rcx=*output.
nebo_schedule_linear_decay:
 test rdi,rdi
 jz .ld_arg
 test rcx,rcx
 jz .ld_arg
 test rdx,rdx
 jz .ld_step
 cmp rdx,NEBO_OPTIMIZER_MAX_STEPS
 ja .ld_step
 cmp rsi,rdx
 ja .ld_step
 movsd xmm0,[rdi]
 ucomisd xmm0,[rel o_zero]
 jbe .ld_hyper
 cvtsi2sd xmm1,rsi
 cvtsi2sd xmm2,rdx
 divsd xmm1,xmm2
 movsd xmm2,[rel o_one]
 subsd xmm2,xmm1
 mulsd xmm0,xmm2
 movq rax,xmm0
 and rax,[rel o_exp]
 cmp rax,[rel o_exp]
 je .ld_nonfinite
 movsd [rcx],xmm0
 xor eax,eax
 ret
.ld_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.ld_step:
 mov eax,NEBO_OPTIMIZER_E_STEP
 ret
.ld_hyper:
 mov eax,NEBO_OPTIMIZER_E_HYPERPARAMETER
 ret
.ld_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret

; rdi=source, rsi=destination, rdx=count, rcx=capacity.
nebo_optimizer_state_copy:
 test rdi,rdi
 jz .sc_arg
 test rsi,rsi
 jz .sc_arg
 test rdx,rdx
 jz .sc_limit
 cmp rdx,NEBO_OPTIMIZER_MAX_PARAMS
 ja .sc_limit
 cmp rcx,rdx
 jb .sc_capacity
 mov r8,rdx
 shl r8,3
 mov r9,rdi
 add r9,r8
 jc .sc_arg
 mov r10,rsi
 add r10,r8
 jc .sc_arg
 cmp rdi,r10
 jae .sc_disjoint
 cmp rsi,r9
 jb .sc_overlap
.sc_disjoint:
 xor r8d,r8d
.sc_check:
 cmp r8,rdx
 jae .sc_copy
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel o_exp]
 cmp r9,[rel o_exp]
 je .sc_nonfinite
 inc r8
 jmp .sc_check
.sc_copy:
 mov rcx,rdx
 mov rdx,rsi
 mov rsi,rdi
 mov rdi,rdx
 rep movsq
 xor eax,eax
 ret
.sc_arg:
 mov eax,NEBO_OPTIMIZER_E_ARGUMENT
 ret
.sc_limit:
 mov eax,NEBO_OPTIMIZER_E_LIMIT
 ret
.sc_nonfinite:
 mov eax,NEBO_OPTIMIZER_E_NONFINITE
 ret
.sc_capacity:
 mov eax,NEBO_OPTIMIZER_E_CAPACITY
 ret
.sc_overlap:
 mov eax,NEBO_OPTIMIZER_E_OVERLAP
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
