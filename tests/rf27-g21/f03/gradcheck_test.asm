bits 64
default rel
%include "runtime/autograd/gradcheck.inc"
section .data
analytic dq 2.0,4.0
loss_plus dq 1.002001,4.004001
loss_minus dq 0.998001,3.996001
step dq 0.001
tolerance dq 0.000000001
zero dq 0.0
one dq 1.0
minus_one dq -1.0
minus_half dq -0.5
one_point_two_low dq 1.199999999999
one_point_two_high dq 1.200000000001
one_point_six_low dq 1.599999999999
one_point_six_high dq 1.600000000001
two dq 2.0
five dq 5.0
seven dq 7.0
infinity dq 0x7ff0000000000000
clip_values dq -3.0,-0.5,2.0
clip_bad dq 7.0,0x7ff0000000000000
norm_values dq 3.0,4.0
norm_bad dq 3.0,0x7ff0000000000000
checkpoint_values dq 1.0,2.0,3.0
checkpoint_bad dq 1.0,0x7ff0000000000000
sentinel dq 0x55aa55aa55aa55aa
section .bss
request resq 8
report resq 4
observed resq 1
snapshot resq 3
section .text
global _start
_start:
 lea rax,[rel analytic]
 mov [rel request],rax
 lea rax,[rel loss_plus]
 mov [rel request+8],rax
 lea rax,[rel loss_minus]
 mov [rel request+16],rax
 mov qword [rel request+24],2
 lea rax,[rel step]
 mov [rel request+32],rax
 lea rax,[rel tolerance]
 mov [rel request+40],rax
 lea rax,[rel report]
 mov [rel request+48],rax
 mov qword [rel request+56],0
 lea rdi,[rel request]
 call nebo_grad_check
 test eax,eax
 jnz .fail1
 cmp qword [rel report+16],2
 jne .fail2
 cmp qword [rel report+24],1
 jne .fail3
 movsd xmm0,[rel report]
 ucomisd xmm0,[rel tolerance]
 ja .fail4
 movsd xmm0,[rel report+8]
 ucomisd xmm0,[rel tolerance]
 ja .fail5
 lea rax,[rel zero]
 mov [rel request+32],rax
 mov rax,[rel sentinel]
 mov [rel report],rax
 lea rdi,[rel request]
 call nebo_grad_check
 cmp eax,NEBO_GRADVERIFY_E_STEP
 jne .fail6
 mov rax,[rel sentinel]
 cmp [rel report],rax
 jne .fail7
 lea rax,[rel step]
 mov [rel request+32],rax
 mov rax,[rel infinity]
 mov [rel analytic],rax
 lea rdi,[rel request]
 call nebo_grad_check
 cmp eax,NEBO_GRADVERIFY_E_NONFINITE
 jne .fail8
 mov rax,[rel sentinel]
 cmp [rel report],rax
 jne .fail9
 mov rax,0x4000000000000000
 mov [rel analytic],rax
 lea rdi,[rel clip_values]
 mov esi,3
 lea rdx,[rel one]
 call nebo_gradient_clip_value
 test eax,eax
 jnz .fail10
 mov rax,[rel minus_one]
 cmp [rel clip_values],rax
 jne .fail11
 mov rax,[rel minus_half]
 cmp [rel clip_values+8],rax
 jne .fail12
 mov rax,[rel one]
 cmp [rel clip_values+16],rax
 jne .fail13
 lea rdi,[rel clip_bad]
 mov esi,2
 lea rdx,[rel one]
 call nebo_gradient_clip_value
 cmp eax,NEBO_GRADVERIFY_E_NONFINITE
 jne .fail14
 mov rax,[rel seven]
 cmp [rel clip_bad],rax
 jne .fail15
 lea rdi,[rel clip_bad]
 mov esi,2
 lea rdx,[rel zero]
 call nebo_gradient_clip_value
 cmp eax,NEBO_GRADVERIFY_E_STEP
 jne .fail16
 lea rdi,[rel norm_values]
 mov esi,2
 lea rdx,[rel two]
 lea rcx,[rel observed]
 call nebo_gradient_clip_norm
 test eax,eax
 jnz .fail17
 mov rax,[rel five]
 cmp [rel observed],rax
 jne .fail18
 movsd xmm0,[rel norm_values]
 ucomisd xmm0,[rel one_point_two_low]
 jb .fail19
 ucomisd xmm0,[rel one_point_two_high]
 ja .fail19
 movsd xmm0,[rel norm_values+8]
 ucomisd xmm0,[rel one_point_six_low]
 jb .fail20
 ucomisd xmm0,[rel one_point_six_high]
 ja .fail20
 mov rax,[rel sentinel]
 mov [rel observed],rax
 lea rdi,[rel norm_values]
 mov esi,2
 lea rdx,[rel zero]
 lea rcx,[rel observed]
 call nebo_gradient_clip_norm
 cmp eax,NEBO_GRADVERIFY_E_STEP
 jne .fail21
 mov rax,[rel sentinel]
 cmp [rel observed],rax
 jne .fail22
 mov rax,[rel sentinel]
 mov [rel observed],rax
 lea rdi,[rel norm_bad]
 mov esi,2
 lea rdx,[rel two]
 lea rcx,[rel observed]
 call nebo_gradient_clip_norm
 cmp eax,NEBO_GRADVERIFY_E_NONFINITE
 jne .fail23
 mov rax,[rel sentinel]
 cmp [rel observed],rax
 jne .fail24
 lea rdi,[rel checkpoint_values]
 mov esi,3
 lea rdx,[rel snapshot]
 mov ecx,3
 call nebo_gradient_checkpoint
 test eax,eax
 jnz .fail25
 mov rax,[rel one]
 cmp [rel snapshot],rax
 jne .fail26
 mov rax,[rel two]
 cmp [rel snapshot+8],rax
 jne .fail27
 mov rax,0x4008000000000000
 cmp [rel snapshot+16],rax
 jne .fail28
 mov rax,[rel sentinel]
 mov [rel snapshot],rax
 lea rdi,[rel checkpoint_values]
 mov esi,3
 lea rdx,[rel snapshot]
 mov ecx,2
 call nebo_gradient_checkpoint
 cmp eax,NEBO_GRADVERIFY_E_CAPACITY
 jne .fail29
 mov rax,[rel sentinel]
 cmp [rel snapshot],rax
 jne .fail30
 lea rdi,[rel checkpoint_values]
 mov esi,3
 lea rdx,[rel checkpoint_values]
 mov ecx,3
 call nebo_gradient_checkpoint
 cmp eax,NEBO_GRADVERIFY_E_OVERLAP
 jne .fail31
 lea rdi,[rel checkpoint_values]
 mov esi,2
 lea rdx,[rel checkpoint_values+8]
 mov ecx,2
 call nebo_gradient_checkpoint
 cmp eax,NEBO_GRADVERIFY_E_OVERLAP
 jne .fail32
 mov rax,[rel sentinel]
 mov [rel snapshot],rax
 lea rdi,[rel checkpoint_bad]
 mov esi,2
 lea rdx,[rel snapshot]
 mov ecx,2
 call nebo_gradient_checkpoint
 cmp eax,NEBO_GRADVERIFY_E_NONFINITE
 jne .fail33
 mov rax,[rel sentinel]
 cmp [rel snapshot],rax
 jne .fail34
 lea rdi,[rel checkpoint_values]
 xor esi,esi
 lea rdx,[rel snapshot]
 xor ecx,ecx
 call nebo_gradient_checkpoint
 cmp eax,NEBO_GRADVERIFY_E_LIMIT
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
