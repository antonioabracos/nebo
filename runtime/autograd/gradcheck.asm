bits 64
default rel
%define NEBO_GRADCHECK_IMPLEMENTATION 1
%include "runtime/autograd/gradcheck.inc"
section .rodata align=16
g_exp dq 0x7ff0000000000000,0
g_abs dq 0x7fffffffffffffff,0
g_two dq 2.0
g_zero dq 0.0
section .text
global nebo_grad_check
global nebo_gradient_clip_value
global nebo_gradient_clip_norm
global nebo_gradient_checkpoint

; Request64: analytic*,loss_plus*,loss_minus*,count,step*,tolerance*,Report32*,reserved.
; plus/minus contain one scalar loss evaluation per parameter.
nebo_grad_check:
 test rdi,rdi
 jz .gc_arg
 cmp qword [rdi+56],0
 jne .gc_arg
 mov r8,[rdi+24]
 test r8,r8
 jz .gc_limit
 cmp r8,NEBO_GRADVERIFY_MAX_ELEMENTS
 ja .gc_limit
 mov r9,[rdi]
 mov r10,[rdi+8]
 mov r11,[rdi+16]
 test r9,r9
 jz .gc_arg
 test r10,r10
 jz .gc_arg
 test r11,r11
 jz .gc_arg
 cmp qword [rdi+32],0
 je .gc_arg
 cmp qword [rdi+40],0
 je .gc_arg
 cmp qword [rdi+48],0
 je .gc_arg
 mov rax,[rdi+32]
 movsd xmm4,[rax]
 mov rax,[rdi+40]
 movsd xmm5,[rax]
 ucomisd xmm4,[rel g_zero]
 jbe .gc_step
 ucomisd xmm5,[rel g_zero]
 jb .gc_step
 movapd xmm6,xmm4
 addsd xmm6,xmm4
 xorpd xmm1,xmm1
 xorpd xmm2,xmm2
 xor ecx,ecx
.gc_loop:
 cmp rcx,r8
 jae .gc_done
 mov rax,[r9+rcx*8]
 mov rdx,rax
 and rdx,[rel g_exp]
 cmp rdx,[rel g_exp]
 je .gc_nonfinite
 mov rax,[r10+rcx*8]
 mov rdx,rax
 and rdx,[rel g_exp]
 cmp rdx,[rel g_exp]
 je .gc_nonfinite
 mov rax,[r11+rcx*8]
 mov rdx,rax
 and rdx,[rel g_exp]
 cmp rdx,[rel g_exp]
 je .gc_nonfinite
 movsd xmm0,[r10+rcx*8]
 subsd xmm0,[r11+rcx*8]
 divsd xmm0,xmm6
 subsd xmm0,[r9+rcx*8]
 andpd xmm0,[rel g_abs]
 maxsd xmm1,xmm0
 addsd xmm2,xmm0
 inc rcx
 jmp .gc_loop
.gc_done:
 cvtsi2sd xmm3,r8
 divsd xmm2,xmm3
 mov rax,[rdi+48]
 movsd [rax],xmm1
 movsd [rax+8],xmm2
 mov [rax+16],r8
 xor edx,edx
 ucomisd xmm1,xmm5
 setbe dl
 mov [rax+24],rdx
 xor eax,eax
 ret
.gc_arg: mov eax,NEBO_GRADVERIFY_E_ARGUMENT
 ret
.gc_limit: mov eax,NEBO_GRADVERIFY_E_LIMIT
 ret
.gc_nonfinite: mov eax,NEBO_GRADVERIFY_E_NONFINITE
 ret
.gc_step: mov eax,NEBO_GRADVERIFY_E_STEP
 ret

; rdi=gradients,rsi=count,rdx=*absolute limit. In-place after full validation.
nebo_gradient_clip_value:
 test rdi,rdi
 jz .cv_arg
 test rdx,rdx
 jz .cv_arg
 test rsi,rsi
 jz .cv_limit
 cmp rsi,NEBO_GRADVERIFY_MAX_ELEMENTS
 ja .cv_limit
 movsd xmm2,[rdx]
 ucomisd xmm2,[rel g_zero]
 jbe .cv_step
 xor ecx,ecx
.cv_check:
 cmp rcx,rsi
 jae .cv_apply
 mov rax,[rdi+rcx*8]
 mov r8,rax
 and r8,[rel g_exp]
 cmp r8,[rel g_exp]
 je .cv_nonfinite
 inc rcx
 jmp .cv_check
.cv_apply:
 xorpd xmm3,xmm3
 subsd xmm3,xmm2
 xor ecx,ecx
.cv_loop:
 cmp rcx,rsi
 jae .cv_ok
 movsd xmm0,[rdi+rcx*8]
 maxsd xmm0,xmm3
 minsd xmm0,xmm2
 movsd [rdi+rcx*8],xmm0
 inc rcx
 jmp .cv_loop
.cv_ok: xor eax,eax
 ret
.cv_arg: mov eax,NEBO_GRADVERIFY_E_ARGUMENT
 ret
.cv_limit: mov eax,NEBO_GRADVERIFY_E_LIMIT
 ret
.cv_nonfinite: mov eax,NEBO_GRADVERIFY_E_NONFINITE
 ret
.cv_step: mov eax,NEBO_GRADVERIFY_E_STEP
 ret

; rdi=gradients,rsi=count,rdx=*max norm,rcx=*observed norm.
nebo_gradient_clip_norm:
 test rdi,rdi
 jz .cn_arg
 test rdx,rdx
 jz .cn_arg
 test rcx,rcx
 jz .cn_arg
 test rsi,rsi
 jz .cn_limit
 cmp rsi,NEBO_GRADVERIFY_MAX_ELEMENTS
 ja .cn_limit
 movsd xmm3,[rdx]
 ucomisd xmm3,[rel g_zero]
 jbe .cn_step
 xorpd xmm1,xmm1
 xor r8d,r8d
.cn_sum:
 cmp r8,rsi
 jae .cn_norm
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel g_exp]
 cmp r9,[rel g_exp]
 je .cn_nonfinite
 movq xmm0,rax
 mulsd xmm0,xmm0
 addsd xmm1,xmm0
 inc r8
 jmp .cn_sum
.cn_norm:
 sqrtsd xmm1,xmm1
 movsd [rcx],xmm1
 ucomisd xmm1,xmm3
 jbe .cn_ok
 divsd xmm3,xmm1
 xor r8d,r8d
.cn_loop:
 cmp r8,rsi
 jae .cn_ok
 movsd xmm0,[rdi+r8*8]
 mulsd xmm0,xmm3
 movsd [rdi+r8*8],xmm0
 inc r8
 jmp .cn_loop
.cn_ok: xor eax,eax
 ret
.cn_arg: mov eax,NEBO_GRADVERIFY_E_ARGUMENT
 ret
.cn_limit: mov eax,NEBO_GRADVERIFY_E_LIMIT
 ret
.cn_nonfinite: mov eax,NEBO_GRADVERIFY_E_NONFINITE
 ret
.cn_step: mov eax,NEBO_GRADVERIFY_E_STEP
 ret

; rdi=values,rsi=count,rdx=checkpoint,rcx=capacity. Disjoint exact snapshot.
nebo_gradient_checkpoint:
 test rdi,rdi
 jz .cp_arg
 test rdx,rdx
 jz .cp_arg
 test rsi,rsi
 jz .cp_limit
 cmp rsi,NEBO_GRADVERIFY_MAX_ELEMENTS
 ja .cp_limit
 cmp rcx,rsi
 jb .cp_capacity
 mov r8,rsi
 shl r8,3
 mov r9,rdi
 add r9,r8
 jc .cp_arg
 mov r10,rdx
 add r10,r8
 jc .cp_arg
 cmp rdi,r10
 jae .cp_disjoint
 cmp rdx,r9
 jb .cp_overlap
.cp_disjoint:
 xor r8d,r8d
.cp_check:
 cmp r8,rsi
 jae .cp_copy
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel g_exp]
 cmp r9,[rel g_exp]
 je .cp_nonfinite
 inc r8
 jmp .cp_check
.cp_copy:
 mov rcx,rsi
 mov rsi,rdi
 mov rdi,rdx
 rep movsq
 xor eax,eax
 ret
.cp_arg: mov eax,NEBO_GRADVERIFY_E_ARGUMENT
 ret
.cp_limit: mov eax,NEBO_GRADVERIFY_E_LIMIT
 ret
.cp_nonfinite: mov eax,NEBO_GRADVERIFY_E_NONFINITE
 ret
.cp_capacity: mov eax,NEBO_GRADVERIFY_E_CAPACITY
 ret
.cp_overlap: mov eax,NEBO_GRADVERIFY_E_OVERLAP
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
