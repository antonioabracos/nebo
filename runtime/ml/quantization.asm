bits 64
default rel
%define NEBO_QUANTIZATION_IMPLEMENTATION 1
%include "runtime/ml/quantization.inc"

section .rodata align=8
q_abs_mask dq 0x7fffffffffffffff
q_exp_mask dq 0x7ff0000000000000
q_127 dq 127.0
q_neg127 dq -127.0
q_half dq 0.5
q_one dq 1.0
q_zero dq 0.0

section .text
global nebo_int8_calibrate
global nebo_int8_quantize
global nebo_int8_dequantize
global nebo_int8_compare_accuracy
global nebo_int8_features

; rdi=F64 samples, rsi=count, rdx=Params32.
nebo_int8_calibrate:
 test rdi,rdi
 jz .cal_argument
 test rdx,rdx
 jz .cal_argument
 test rsi,rsi
 jz .cal_limit
 cmp rsi,NEBO_QUANT_MAX_ELEMENTS
 ja .cal_limit
 xorpd xmm0,xmm0
 xor ecx,ecx
.cal_loop:
 cmp rcx,rsi
 jae .cal_ready
 mov rax,[rdi+rcx*8]
 mov r8,rax
 and r8,[rel q_exp_mask]
 cmp r8,[rel q_exp_mask]
 je .cal_nonfinite
 and rax,[rel q_abs_mask]
 movq xmm1,rax
 maxsd xmm0,xmm1
 inc rcx
 jmp .cal_loop
.cal_ready:
 movapd xmm1,xmm0
 ucomisd xmm1,[rel q_zero]
 jne .cal_nonzero
 movsd xmm1,[rel q_one]
 jmp .cal_publish
.cal_nonzero:
 divsd xmm1,[rel q_127]
.cal_publish:
 movsd xmm2,[rel q_one]
 divsd xmm2,xmm1
 movsd [rdx+NEBO_QUANT_PARAMS_SCALE],xmm1
 movsd [rdx+NEBO_QUANT_PARAMS_INVERSE],xmm2
 movsd [rdx+NEBO_QUANT_PARAMS_MAX_ABS],xmm0
 mov [rdx+NEBO_QUANT_PARAMS_SAMPLES],rsi
 xor eax,eax
 ret
.cal_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 ret
.cal_limit: mov eax,NEBO_QUANT_E_LIMIT
 ret
.cal_nonfinite: mov eax,NEBO_QUANT_E_NONFINITE
 ret

; rdi=F64 input, rsi=count, rdx=Params32, rcx=I8 output, r8=capacity.
nebo_int8_quantize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .quant_argument
 test r15,r15
 jz .quant_argument
 test r13,r13
 jz .quant_limit
 cmp r13,NEBO_QUANT_MAX_ELEMENTS
 ja .quant_limit
 cmp rbx,r13
 jb .quant_capacity
 mov rdi,r14
 call quant_validate_params
 test eax,eax
 jnz .quant_return
 mov rax,r12
 mov rcx,r13
 shl rcx,3
 add rax,rcx
 jc .quant_overlap
 mov rdx,r15
 add rdx,r13
 jc .quant_overlap
 cmp r12,rdx
 jae .quant_preflight
 cmp r15,rax
 jae .quant_preflight
 jmp .quant_overlap
.quant_preflight:
 xor ecx,ecx
.quant_finite:
 cmp rcx,r13
 jae .quant_convert
 mov rax,[r12+rcx*8]
 mov rdx,rax
 and rdx,[rel q_exp_mask]
 cmp rdx,[rel q_exp_mask]
 je .quant_nonfinite
 inc rcx
 jmp .quant_finite
.quant_convert:
 movsd xmm3,[r14+NEBO_QUANT_PARAMS_INVERSE]
 xor ecx,ecx
.quant_loop:
 cmp rcx,r13
 jae .quant_ok
 movsd xmm0,[r12+rcx*8]
 mulsd xmm0,xmm3
 ucomisd xmm0,[rel q_127]
 jae .quant_high
 ucomisd xmm0,[rel q_neg127]
 jbe .quant_low
 ucomisd xmm0,[rel q_zero]
 jb .quant_negative
 addsd xmm0,[rel q_half]
 jmp .quant_truncate
.quant_negative:
 subsd xmm0,[rel q_half]
.quant_truncate:
 cvttsd2si eax,xmm0
 mov [r15+rcx],al
 inc rcx
 jmp .quant_loop
.quant_high:
 mov byte [r15+rcx],127
 inc rcx
 jmp .quant_loop
.quant_low:
 mov byte [r15+rcx],-127
 inc rcx
 jmp .quant_loop
.quant_ok: xor eax,eax
 jmp .quant_return
.quant_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 jmp .quant_return
.quant_limit: mov eax,NEBO_QUANT_E_LIMIT
 jmp .quant_return
.quant_nonfinite: mov eax,NEBO_QUANT_E_NONFINITE
 jmp .quant_return
.quant_capacity: mov eax,NEBO_QUANT_E_CAPACITY
 jmp .quant_return
.quant_overlap: mov eax,NEBO_QUANT_E_OVERLAP
.quant_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=I8 input, rsi=count, rdx=Params32, rcx=F64 output, r8=capacity.
nebo_int8_dequantize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .deq_argument
 test r15,r15
 jz .deq_argument
 test r13,r13
 jz .deq_limit
 cmp r13,NEBO_QUANT_MAX_ELEMENTS
 ja .deq_limit
 cmp rbx,r13
 jb .deq_capacity
 mov rdi,r14
 call quant_validate_params
 test eax,eax
 jnz .deq_return
 mov rax,r15
 mov rcx,r13
 shl rcx,3
 add rax,rcx
 jc .deq_overlap
 mov rdx,r12
 add rdx,r13
 jc .deq_overlap
 cmp r15,rdx
 jae .deq_convert
 cmp r12,rax
 jae .deq_convert
 jmp .deq_overlap
.deq_convert:
 movsd xmm1,[r14+NEBO_QUANT_PARAMS_SCALE]
 xor ecx,ecx
.deq_loop:
 cmp rcx,r13
 jae .deq_ok
 movsx eax,byte [r12+rcx]
 cvtsi2sd xmm0,eax
 mulsd xmm0,xmm1
 movsd [r15+rcx*8],xmm0
 inc rcx
 jmp .deq_loop
.deq_ok: xor eax,eax
 jmp .deq_return
.deq_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 jmp .deq_return
.deq_limit: mov eax,NEBO_QUANT_E_LIMIT
 jmp .deq_return
.deq_capacity: mov eax,NEBO_QUANT_E_CAPACITY
 jmp .deq_return
.deq_overlap: mov eax,NEBO_QUANT_E_OVERLAP
.deq_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=reference, rsi=candidate, rdx=count, rcx=Report40, r8=*tolerance.
nebo_int8_compare_accuracy:
 test rdi,rdi
 jz .cmp_argument
 test rsi,rsi
 jz .cmp_argument
 test rcx,rcx
 jz .cmp_argument
 test r8,r8
 jz .cmp_argument
 test rdx,rdx
 jz .cmp_limit
 cmp rdx,NEBO_QUANT_MAX_ELEMENTS
 ja .cmp_limit
 mov rax,[r8]
 mov r9,rax
 and r9,[rel q_exp_mask]
 cmp r9,[rel q_exp_mask]
 je .cmp_nonfinite
 test rax,rax
 js .cmp_argument
 xorpd xmm1,xmm1
 xorpd xmm2,xmm2
 xorpd xmm3,xmm3
 xor r9d,r9d
.cmp_loop:
 cmp r9,rdx
 jae .cmp_finish
 mov rax,[rdi+r9*8]
 mov r10,rax
 and r10,[rel q_exp_mask]
 cmp r10,[rel q_exp_mask]
 je .cmp_nonfinite
 mov rax,[rsi+r9*8]
 mov r10,rax
 and r10,[rel q_exp_mask]
 cmp r10,[rel q_exp_mask]
 je .cmp_nonfinite
 movsd xmm0,[rdi+r9*8]
 subsd xmm0,[rsi+r9*8]
 andpd xmm0,[rel q_abs_mask]
 maxsd xmm1,xmm0
 addsd xmm2,xmm0
 mulsd xmm0,xmm0
 addsd xmm3,xmm0
 inc r9
 jmp .cmp_loop
.cmp_finish:
 cvtsi2sd xmm4,rdx
 divsd xmm2,xmm4
 divsd xmm3,xmm4
 movsd [rcx],xmm1
 movsd [rcx+8],xmm2
 movsd [rcx+16],xmm3
 mov [rcx+24],rdx
 xor eax,eax
 ucomisd xmm1,[r8]
 seta al
 xor eax,1
 mov [rcx+32],rax
 xor eax,eax
 ret
.cmp_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 ret
.cmp_limit: mov eax,NEBO_QUANT_E_LIMIT
 ret
.cmp_nonfinite: mov eax,NEBO_QUANT_E_NONFINITE
 ret

; rdi=two qwords: scalar_int8, retained_f64_reference.
nebo_int8_features:
 test rdi,rdi
 jz .features_argument
 mov qword [rdi],1
 mov qword [rdi+8],1
 xor eax,eax
 ret
.features_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 ret

quant_validate_params:
 test rdi,rdi
 jz .params_argument
 mov rax,[rdi+NEBO_QUANT_PARAMS_SCALE]
 mov rcx,rax
 and rcx,[rel q_exp_mask]
 cmp rcx,[rel q_exp_mask]
 je .params_nonfinite
 test rax,rax
 jle .params_scale
 mov rax,[rdi+NEBO_QUANT_PARAMS_INVERSE]
 mov rcx,rax
 and rcx,[rel q_exp_mask]
 cmp rcx,[rel q_exp_mask]
 je .params_nonfinite
 test rax,rax
 jle .params_scale
 mov rax,[rdi+NEBO_QUANT_PARAMS_MAX_ABS]
 mov rcx,rax
 and rcx,[rel q_exp_mask]
 cmp rcx,[rel q_exp_mask]
 je .params_nonfinite
 test rax,rax
 js .params_scale
 mov rax,[rdi+NEBO_QUANT_PARAMS_SAMPLES]
 test rax,rax
 jz .params_scale
 cmp rax,NEBO_QUANT_MAX_ELEMENTS
 ja .params_scale
 xor eax,eax
 ret
.params_argument: mov eax,NEBO_QUANT_E_ARGUMENT
 ret
.params_nonfinite: mov eax,NEBO_QUANT_E_NONFINITE
 ret
.params_scale: mov eax,NEBO_QUANT_E_SCALE
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
