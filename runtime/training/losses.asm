bits 64
default rel
%define NEBO_LOSSES_IMPLEMENTATION 1
%include "runtime/training/losses.inc"
%include "runtime/math/transcendental.inc"
section .rodata align=16
l_exp dq 0x7ff0000000000000,0
l_abs dq 0x7fffffffffffffff,0
l_zero dq 0.0
l_one dq 1.0
section .text
global nebo_loss_mse
global nebo_loss_cross_entropy
global nebo_loss_binary_cross_entropy
global nebo_loss_nll
global nebo_metric_accuracy
global nebo_metric_precision_recall
global nebo_metric_confusion_matrix

; rdi=predictions, rsi=targets, rdx=count, rcx=mean output.
nebo_loss_mse:
 test rdi,rdi
 jz .mse_arg
 test rsi,rsi
 jz .mse_arg
 test rcx,rcx
 jz .mse_arg
 test rdx,rdx
 jz .mse_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .mse_limit
 xorpd xmm1,xmm1
 xor r8d,r8d
.mse_loop:
 cmp r8,rdx
 jae .mse_done
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel l_exp]
 cmp r9,[rel l_exp]
 je .mse_nonfinite
 mov rax,[rsi+r8*8]
 mov r9,rax
 and r9,[rel l_exp]
 cmp r9,[rel l_exp]
 je .mse_nonfinite
 movsd xmm0,[rdi+r8*8]
 subsd xmm0,[rsi+r8*8]
 mulsd xmm0,xmm0
 addsd xmm1,xmm0
 inc r8
 jmp .mse_loop
.mse_done:
 cvtsi2sd xmm0,rdx
 divsd xmm1,xmm0
 movq rax,xmm1
 and rax,[rel l_exp]
 cmp rax,[rel l_exp]
 je .mse_nonfinite
 movsd [rcx],xmm1
 xor eax,eax
 ret
.mse_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.mse_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.mse_nonfinite:
 mov eax,NEBO_LOSS_E_NONFINITE
 ret

; rdi=logits, rsi=targets in [0,1], rdx=count, rcx=mean output.
nebo_loss_binary_cross_entropy:
 test rdi,rdi
 jz .bce_arg
 test rsi,rsi
 jz .bce_arg
 test rcx,rcx
 jz .bce_arg
 test rdx,rdx
 jz .bce_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .bce_limit
 xor r8d,r8d
.bce_check:
 cmp r8,rdx
 jae .bce_compute
 mov rax,[rdi+r8*8]
 mov r9,rax
 and r9,[rel l_exp]
 cmp r9,[rel l_exp]
 je .bce_nonfinite
 mov rax,[rsi+r8*8]
 mov r9,rax
 and r9,[rel l_exp]
 cmp r9,[rel l_exp]
 je .bce_nonfinite
 movsd xmm0,[rsi+r8*8]
 ucomisd xmm0,[rel l_zero]
 jb .bce_target
 ucomisd xmm0,[rel l_one]
 ja .bce_target
 inc r8
 jmp .bce_check
.bce_compute:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rcx
 mov r14,rdx
 xor r15d,r15d
 mov qword [rsp],0
.bce_loop:
 cmp r15,r14
 jae .bce_done
 movsd xmm2,[rbx+r15*8]
 movsd [rsp+8],xmm2
 andpd xmm2,[rel l_abs]
 xorpd xmm0,xmm0
 subsd xmm0,xmm2
 call nebo_math_exp_f64
 addsd xmm0,[rel l_one]
 call nebo_math_log_f64
 movsd xmm2,[rsp+8]
 xorpd xmm1,xmm1
 maxsd xmm1,xmm2
 mulsd xmm2,[r12+r15*8]
 subsd xmm1,xmm2
 addsd xmm1,xmm0
 addsd xmm1,[rsp]
 movsd [rsp],xmm1
 inc r15
 jmp .bce_loop
.bce_done:
 movsd xmm0,[rsp]
 cvtsi2sd xmm1,r14
 divsd xmm0,xmm1
 movq rax,xmm0
 and rax,[rel l_exp]
 cmp rax,[rel l_exp]
 je .bce_computed_nonfinite
 movsd [r13],xmm0
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.bce_computed_nonfinite:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 mov eax,NEBO_LOSS_E_NONFINITE
 ret
.bce_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.bce_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.bce_target:
 mov eax,NEBO_LOSS_E_TARGET
 ret
.bce_nonfinite:
 mov eax,NEBO_LOSS_E_NONFINITE
 ret

; rdi=logits, rsi=class targets, rdx=samples, rcx=classes, r8=mean output.
nebo_loss_cross_entropy:
 test rdi,rdi
 jz .ce_arg
 test rsi,rsi
 jz .ce_arg
 test r8,r8
 jz .ce_arg
 test rdx,rdx
 jz .ce_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .ce_limit
 test rcx,rcx
 jz .ce_shape
 cmp rcx,NEBO_LOSS_MAX_CLASSES
 ja .ce_shape
 mov rax,rdx
 imul rax,rcx
 mov r9,rax
 xor r10d,r10d
.ce_check_values:
 cmp r10,r9
 jae .ce_check_targets
 mov rax,[rdi+r10*8]
 mov r11,rax
 and r11,[rel l_exp]
 cmp r11,[rel l_exp]
 je .ce_nonfinite
 inc r10
 jmp .ce_check_values
.ce_check_targets:
 xor r10d,r10d
.ce_target_loop:
 cmp r10,rdx
 jae .ce_compute
 cmp qword [rsi+r10*8],rcx
 jae .ce_target
 inc r10
 jmp .ce_target_loop
.ce_compute:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 mov qword [rsp+8],0
 mov qword [rsp+16],0
.ce_sample:
 mov rax,[rsp+8]
 cmp rax,r14
 jae .ce_done
 imul rax,r15
 lea rbx,[r12+rax*8]
 movsd xmm0,[rbx]
 mov ecx,1
.ce_max:
 cmp rcx,r15
 jae .ce_max_done
 maxsd xmm0,[rbx+rcx*8]
 inc rcx
 jmp .ce_max
.ce_max_done:
 movsd [rsp+24],xmm0
 mov rax,[rsp+8]
 mov rax,[r13+rax*8]
 movsd xmm1,[rbx+rax*8]
 movsd [rsp+32],xmm1
 mov qword [rsp+40],0
 xor ecx,ecx
.ce_exp:
 cmp rcx,r15
 jae .ce_log
 movsd xmm0,[rbx+rcx*8]
 subsd xmm0,[rsp+24]
 call nebo_math_exp_f64
 addsd xmm0,[rsp+40]
 movsd [rsp+40],xmm0
 inc rcx
 jmp .ce_exp
.ce_log:
 movsd xmm0,[rsp+40]
 call nebo_math_log_f64
 addsd xmm0,[rsp+24]
 subsd xmm0,[rsp+32]
 addsd xmm0,[rsp+16]
 movsd [rsp+16],xmm0
 inc qword [rsp+8]
 jmp .ce_sample
.ce_done:
 movsd xmm0,[rsp+16]
 cvtsi2sd xmm1,r14
 divsd xmm0,xmm1
 movq rdx,xmm0
 and rdx,[rel l_exp]
 cmp rdx,[rel l_exp]
 je .ce_computed_nonfinite
 mov rax,[rsp]
 movsd [rax],xmm0
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 xor eax,eax
 ret
.ce_computed_nonfinite:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 mov eax,NEBO_LOSS_E_NONFINITE
 ret
.ce_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.ce_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.ce_shape:
 mov eax,NEBO_LOSS_E_SHAPE
 ret
.ce_target:
 mov eax,NEBO_LOSS_E_TARGET
 ret
.ce_nonfinite:
 mov eax,NEBO_LOSS_E_NONFINITE
 ret

; rdi=log probabilities, rsi=class targets, rdx=samples, rcx=classes, r8=mean output.
nebo_loss_nll:
 test rdi,rdi
 jz .nll_arg
 test rsi,rsi
 jz .nll_arg
 test r8,r8
 jz .nll_arg
 test rdx,rdx
 jz .nll_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .nll_limit
 test rcx,rcx
 jz .nll_shape
 cmp rcx,NEBO_LOSS_MAX_CLASSES
 ja .nll_shape
 mov rax,rdx
 imul rax,rcx
 mov r9,rax
 xor r10d,r10d
.nll_values:
 cmp r10,r9
 jae .nll_compute
 mov rax,[rdi+r10*8]
 mov r11,rax
 and r11,[rel l_exp]
 cmp r11,[rel l_exp]
 je .nll_nonfinite
 inc r10
 jmp .nll_values
.nll_compute:
 xorpd xmm1,xmm1
 xor r10d,r10d
.nll_loop:
 cmp r10,rdx
 jae .nll_done
 mov rax,[rsi+r10*8]
 cmp rax,rcx
 jae .nll_target
 mov r11,r10
 imul r11,rcx
 add r11,rax
 subsd xmm1,[rdi+r11*8]
 inc r10
 jmp .nll_loop
.nll_done:
 cvtsi2sd xmm0,rdx
 divsd xmm1,xmm0
 movq rax,xmm1
 and rax,[rel l_exp]
 cmp rax,[rel l_exp]
 je .nll_nonfinite
 movsd [r8],xmm1
 xor eax,eax
 ret
.nll_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.nll_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.nll_shape:
 mov eax,NEBO_LOSS_E_SHAPE
 ret
.nll_target:
 mov eax,NEBO_LOSS_E_TARGET
 ret
.nll_nonfinite:
 mov eax,NEBO_LOSS_E_NONFINITE
 ret

; rdi=predicted classes, rsi=targets, rdx=samples, rcx=F64 output.
nebo_metric_accuracy:
 test rdi,rdi
 jz .acc_arg
 test rsi,rsi
 jz .acc_arg
 test rcx,rcx
 jz .acc_arg
 test rdx,rdx
 jz .acc_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .acc_limit
 xor r8d,r8d
 xor r9d,r9d
.acc_loop:
 cmp r8,rdx
 jae .acc_done
 mov rax,[rdi+r8*8]
 cmp rax,[rsi+r8*8]
 jne .acc_next
 inc r9
.acc_next:
 inc r8
 jmp .acc_loop
.acc_done:
 cvtsi2sd xmm0,r9
 cvtsi2sd xmm1,rdx
 divsd xmm0,xmm1
 movsd [rcx],xmm0
 xor eax,eax
 ret
.acc_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.acc_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret

; rdi=predicted, rsi=targets, rdx=samples, rcx=positive class, r8=Report40.
nebo_metric_precision_recall:
 test rdi,rdi
 jz .pr_arg
 test rsi,rsi
 jz .pr_arg
 test r8,r8
 jz .pr_arg
 test rdx,rdx
 jz .pr_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .pr_limit
 cmp rcx,NEBO_LOSS_MAX_CLASSES
 jae .pr_target
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 xor r9d,r9d
 xor r10d,r10d
 xor r11d,r11d
 xor eax,eax
.pr_loop:
 cmp rax,rdx
 jae .pr_done
 mov rdi,[rbx+rax*8]
 mov rsi,[r12+rax*8]
 cmp rdi,rcx
 jne .pr_not_predicted
 cmp rsi,rcx
 jne .pr_fp
 inc r9
 jmp .pr_next
.pr_fp:
 inc r10
 jmp .pr_next
.pr_not_predicted:
 cmp rsi,rcx
 jne .pr_next
 inc r11
.pr_next:
 inc rax
 jmp .pr_loop
.pr_done:
 xorpd xmm0,xmm0
 mov rax,r9
 add rax,r10
 jz .pr_precision_done
 cvtsi2sd xmm0,r9
 cvtsi2sd xmm1,rax
 divsd xmm0,xmm1
.pr_precision_done:
 xorpd xmm2,xmm2
 mov rax,r9
 add rax,r11
 jz .pr_recall_done
 cvtsi2sd xmm2,r9
 cvtsi2sd xmm1,rax
 divsd xmm2,xmm1
.pr_recall_done:
 movsd [r8],xmm0
 movsd [r8+8],xmm2
 mov [r8+16],r9
 mov [r8+24],r10
 mov [r8+32],r11
 pop r12
 pop rbx
 xor eax,eax
 ret
.pr_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.pr_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.pr_target:
 mov eax,NEBO_LOSS_E_TARGET
 ret

; rdi=predicted, rsi=targets, rdx=samples, rcx=classes, r8=matrix, r9=capacity.
nebo_metric_confusion_matrix:
 test rdi,rdi
 jz .cm_arg
 test rsi,rsi
 jz .cm_arg
 test r8,r8
 jz .cm_arg
 test rdx,rdx
 jz .cm_limit
 cmp rdx,NEBO_LOSS_MAX_SAMPLES
 ja .cm_limit
 test rcx,rcx
 jz .cm_shape
 cmp rcx,NEBO_LOSS_MAX_CLASSES
 ja .cm_shape
 mov rax,rcx
 imul rax,rcx
 cmp r9,rax
 jb .cm_capacity
 mov r10,rax
 shl r10,3
 mov r11,r8
 add r11,r10
 jc .cm_arg
 mov rax,rdx
 shl rax,3
 mov r9,rdi
 add r9,rax
 jc .cm_arg
 cmp rdi,r11
 jae .cm_target_overlap
 cmp r8,r9
 jb .cm_overlap
.cm_target_overlap:
 mov r9,rsi
 add r9,rax
 jc .cm_arg
 cmp rsi,r11
 jae .cm_validate
 cmp r8,r9
 jb .cm_overlap
.cm_validate:
 xor r9d,r9d
.cm_check:
 cmp r9,rdx
 jae .cm_zero
 cmp qword [rdi+r9*8],rcx
 jae .cm_target
 cmp qword [rsi+r9*8],rcx
 jae .cm_target
 inc r9
 jmp .cm_check
.cm_zero:
 mov r10,rcx
 imul r10,rcx
 xor r9d,r9d
.cm_zero_loop:
 cmp r9,r10
 jae .cm_count
 mov qword [r8+r9*8],0
 inc r9
 jmp .cm_zero_loop
.cm_count:
 xor r9d,r9d
.cm_loop:
 cmp r9,rdx
 jae .cm_ok
 mov rax,[rsi+r9*8]
 imul rax,rcx
 add rax,[rdi+r9*8]
 inc qword [r8+rax*8]
 inc r9
 jmp .cm_loop
.cm_ok:
 xor eax,eax
 ret
.cm_arg:
 mov eax,NEBO_LOSS_E_ARGUMENT
 ret
.cm_limit:
 mov eax,NEBO_LOSS_E_LIMIT
 ret
.cm_shape:
 mov eax,NEBO_LOSS_E_SHAPE
 ret
.cm_target:
 mov eax,NEBO_LOSS_E_TARGET
 ret
.cm_capacity:
 mov eax,NEBO_LOSS_E_CAPACITY
 ret
.cm_overlap:
 mov eax,NEBO_LOSS_E_OVERLAP
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
