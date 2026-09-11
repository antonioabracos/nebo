bits 64
default rel
%include "runtime/training/optimizers.inc"
section .data
sgd_params dq 1.0,2.0
sgd_grads dq 0.5,-1.0
mom_params dq 1.0,2.0
mom_grads dq 0.5,-1.0
velocity dq 0.0,0.0
adam_params dq 1.0,-2.0
adam_grads dq 0.1,-0.2
adam_m dq 0.0,0.0
adam_v dq 0.0,0.0
learning_rate dq 0.1
adam_lr dq 0.01
momentum dq 0.9
beta1 dq 0.9
beta2 dq 0.999
epsilon dq 0.00000001
beta1_power dq 0.9
beta2_power dq 0.999
zero dq 0.0
half dq 0.5
minus_one dq -1.0
sgd_p0_expected dq 0.95
sgd_p1_expected dq 2.1
adam_p0_low dq 0.989999999
adam_p0_high dq 0.990000001
adam_p1_low dq -1.990000001
adam_p1_high dq -1.989999999
initial_lr dq 0.1
gamma dq 0.5
step_expected dq 0.025
linear_expected_low dq 0.074999999999
linear_expected_high dq 0.075000000001
state_source dq 1.0,2.0,3.0
bad_state dq 1.0,0x7ff0000000000000
infinity dq 0x7ff0000000000000
sentinel dq 0x55aa55aa55aa55aa
section .bss
adam_request resq 12
schedule_out resq 1
state_destination resq 3
section .text
global _start
_start:
 lea rdi,[rel sgd_params]
 lea rsi,[rel sgd_grads]
 mov edx,2
 lea rcx,[rel learning_rate]
 call nebo_optimizer_sgd
 test eax,eax
 jnz .fail1
 mov rax,[rel sgd_p0_expected]
 cmp [rel sgd_params],rax
 jne .fail2
 mov rax,[rel sgd_p1_expected]
 cmp [rel sgd_params+8],rax
 jne .fail3
 mov rax,[rel infinity]
 mov [rel sgd_grads+8],rax
 mov rax,[rel sgd_params]
 push rax
 lea rdi,[rel sgd_params]
 lea rsi,[rel sgd_grads]
 mov edx,2
 lea rcx,[rel learning_rate]
 call nebo_optimizer_sgd
 cmp eax,NEBO_OPTIMIZER_E_NONFINITE
 jne .fail4
 pop rax
 cmp [rel sgd_params],rax
 jne .fail5
 mov rax,0xbff0000000000000
 mov [rel sgd_grads+8],rax
 lea rdi,[rel mom_params]
 lea rsi,[rel mom_grads]
 lea rdx,[rel velocity]
 mov ecx,2
 lea r8,[rel learning_rate]
 lea r9,[rel momentum]
 call nebo_optimizer_momentum
 test eax,eax
 jnz .fail6
 mov rax,[rel sgd_p0_expected]
 cmp [rel mom_params],rax
 jne .fail7
 mov rax,[rel sgd_p1_expected]
 cmp [rel mom_params+8],rax
 jne .fail8
 mov rax,[rel half]
 cmp [rel velocity],rax
 jne .fail9
 mov rax,[rel minus_one]
 cmp [rel velocity+8],rax
 jne .fail10
 lea rax,[rel adam_params]
 mov [rel adam_request],rax
 lea rax,[rel adam_grads]
 mov [rel adam_request+8],rax
 lea rax,[rel adam_m]
 mov [rel adam_request+16],rax
 lea rax,[rel adam_v]
 mov [rel adam_request+24],rax
 mov qword [rel adam_request+32],2
 mov qword [rel adam_request+40],1
 lea rax,[rel adam_lr]
 mov [rel adam_request+48],rax
 lea rax,[rel beta1]
 mov [rel adam_request+56],rax
 lea rax,[rel beta2]
 mov [rel adam_request+64],rax
 lea rax,[rel epsilon]
 mov [rel adam_request+72],rax
 lea rax,[rel beta1_power]
 mov [rel adam_request+80],rax
 lea rax,[rel beta2_power]
 mov [rel adam_request+88],rax
 lea rdi,[rel adam_request]
 call nebo_optimizer_adam
 test eax,eax
 jnz .fail11
 movsd xmm0,[rel adam_params]
 ucomisd xmm0,[rel adam_p0_low]
 jb .fail12
 ucomisd xmm0,[rel adam_p0_high]
 ja .fail12
 movsd xmm0,[rel adam_params+8]
 ucomisd xmm0,[rel adam_p1_low]
 jb .fail13
 ucomisd xmm0,[rel adam_p1_high]
 ja .fail13
 movsd xmm0,[rel adam_m]
 ucomisd xmm0,[rel zero]
 jbe .fail14
 movsd xmm0,[rel adam_v]
 ucomisd xmm0,[rel zero]
 jbe .fail15
 mov qword [rel adam_request+40],0
 mov rax,[rel adam_params]
 push rax
 lea rdi,[rel adam_request]
 call nebo_optimizer_adam
 cmp eax,NEBO_OPTIMIZER_E_STEP
 jne .fail16
 pop rax
 cmp [rel adam_params],rax
 jne .fail17
 mov qword [rel adam_request+40],1
 mov rax,[rel infinity]
 mov [rel adam_grads],rax
 mov rax,[rel adam_params]
 push rax
 lea rdi,[rel adam_request]
 call nebo_optimizer_adam
 cmp eax,NEBO_OPTIMIZER_E_NONFINITE
 jne .fail18
 pop rax
 cmp [rel adam_params],rax
 jne .fail19
 mov rax,0x3fb999999999999a
 mov [rel adam_grads],rax
 lea rdi,[rel sgd_grads]
 mov esi,2
 call nebo_optimizer_zero_grad
 test eax,eax
 jnz .fail20
 cmp qword [rel sgd_grads],0
 jne .fail21
 cmp qword [rel sgd_grads+8],0
 jne .fail22
 lea rdi,[rel initial_lr]
 lea rsi,[rel gamma]
 mov edx,20
 mov ecx,10
 lea r8,[rel schedule_out]
 call nebo_schedule_step_decay
 test eax,eax
 jnz .fail23
 mov rax,[rel step_expected]
 cmp [rel schedule_out],rax
 jne .fail24
 lea rdi,[rel initial_lr]
 mov esi,25
 mov edx,100
 lea rcx,[rel schedule_out]
 call nebo_schedule_linear_decay
 test eax,eax
 jnz .fail25
 movsd xmm0,[rel schedule_out]
 ucomisd xmm0,[rel linear_expected_low]
 jb .fail26
 ucomisd xmm0,[rel linear_expected_high]
 ja .fail26
 mov rax,[rel sentinel]
 mov [rel schedule_out],rax
 lea rdi,[rel initial_lr]
 mov esi,101
 mov edx,100
 lea rcx,[rel schedule_out]
 call nebo_schedule_linear_decay
 cmp eax,NEBO_OPTIMIZER_E_STEP
 jne .fail27
 mov rax,[rel sentinel]
 cmp [rel schedule_out],rax
 jne .fail28
 lea rdi,[rel state_source]
 lea rsi,[rel state_destination]
 mov edx,3
 mov ecx,3
 call nebo_optimizer_state_copy
 test eax,eax
 jnz .fail29
 mov rax,[rel state_source]
 cmp [rel state_destination],rax
 jne .fail30
 mov rax,[rel state_source+16]
 cmp [rel state_destination+16],rax
 jne .fail31
 lea rdi,[rel state_source]
 lea rsi,[rel state_destination]
 mov edx,3
 mov ecx,2
 call nebo_optimizer_state_copy
 cmp eax,NEBO_OPTIMIZER_E_CAPACITY
 jne .fail32
 lea rdi,[rel state_source]
 lea rsi,[rel state_source+8]
 mov edx,2
 mov ecx,2
 call nebo_optimizer_state_copy
 cmp eax,NEBO_OPTIMIZER_E_OVERLAP
 jne .fail33
 mov rax,[rel sentinel]
 mov [rel state_destination],rax
 lea rdi,[rel bad_state]
 lea rsi,[rel state_destination]
 mov edx,2
 mov ecx,2
 call nebo_optimizer_state_copy
 cmp eax,NEBO_OPTIMIZER_E_NONFINITE
 jne .fail34
 mov rax,[rel sentinel]
 cmp [rel state_destination],rax
 jne .fail35
 xor edi,edi
 jmp .exit
%assign i 1
%rep 35
.fail%+i:
 mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
