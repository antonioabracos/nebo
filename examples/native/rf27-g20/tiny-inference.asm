bits 64
default rel
%include "runtime/ml/dense.inc"
%include "runtime/ml/conv.inc"
%include "runtime/ml/inference.inc"
%include "runtime/ml/quantization.inc"
section .data
input dq 1.0,2.0,3.0,4.0
identity_weights dq 1.0,0.0,0.0,1.0
bias dq 0.5,-0.5
conv_weight dq 2.0
conv_bias dq 1.0
scale dq 2.0,-1.0
session_bias dq 1.0,0.5
three dq 3.0
one_half dq 1.5
ops dq NEBO_INFERENCE_OP_SCALE_BIAS,scale,session_bias,2
    dq NEBO_INFERENCE_OP_RELU,0,0,2
section .bss
dense_req resq 8
conv_req resq 16
session resb NEBO_INFERENCE_SESSION_SIZE
workspace resb 256
dense_out resq 4
conv_out resq 4
session_out resq 4
qparams resb NEBO_QUANT_PARAMS_SIZE
qout resb 8
section .text
global _start
_start:
 ; Model A: two-feature identity Linear with bias.
 lea rax,[rel dense_out]
 mov [rel dense_req],rax
 lea rax,[rel input]
 mov [rel dense_req+8],rax
 lea rax,[rel identity_weights]
 mov [rel dense_req+16],rax
 lea rax,[rel bias]
 mov [rel dense_req+24],rax
 mov qword [rel dense_req+32],1
 mov qword [rel dense_req+40],2
 mov qword [rel dense_req+48],2
 mov qword [rel dense_req+56],2
 lea rdi,[rel dense_req]
 call nebo_dense_linear
 test eax,eax
 jnz .fail1
 movsd xmm0,[rel dense_out]
 ucomisd xmm0,[rel one_half]
 jne .fail2
 movsd xmm0,[rel dense_out+8]
 ucomisd xmm0,[rel one_half]
 jne .fail3
 ; Model B: 1x1 Conv2D with weight 2 and bias 1.
 lea rax,[rel conv_out]
 mov [rel conv_req],rax
 lea rax,[rel input]
 mov [rel conv_req+8],rax
 lea rax,[rel conv_weight]
 mov [rel conv_req+16],rax
 lea rax,[rel conv_bias]
 mov [rel conv_req+24],rax
 mov qword [rel conv_req+32],1
 mov qword [rel conv_req+40],2
 mov qword [rel conv_req+48],2
 mov qword [rel conv_req+56],1
 mov qword [rel conv_req+64],1
 mov qword [rel conv_req+72],1
 mov qword [rel conv_req+80],1
 mov qword [rel conv_req+88],0
 mov qword [rel conv_req+96],1
 mov qword [rel conv_req+104],2
 mov qword [rel conv_req+112],2
 mov qword [rel conv_req+120],4
 lea rdi,[rel conv_req]
 call nebo_conv2d
 test eax,eax
 jnz .fail4
 movsd xmm0,[rel conv_out]
 ucomisd xmm0,[rel three]
 jne .fail5
 ; Model C: bounded session ScaleBias -> ReLU, then calibrated Int8.
 mov rax,NEBO_INFERENCE_SESSION_MAGIC
 mov [rel session],rax
 mov qword [rel session+8],NEBO_INFERENCE_SESSION_STATE_READY
 lea rax,[rel ops]
 mov [rel session+16],rax
 mov qword [rel session+24],2
 mov qword [rel session+32],2
 mov qword [rel session+40],2
 lea rax,[rel workspace]
 mov [rel session+48],rax
 mov qword [rel session+56],256
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel session_out]
 mov ecx,2
 mov r8d,4
 mov r9d,4
 call nebo_inference_batch
 test eax,eax
 jnz .fail6
 movsd xmm0,[rel session_out]
 ucomisd xmm0,[rel three]
 jne .fail7
 cmp qword [rel session_out+8],0
 jne .fail8
 lea rdi,[rel session_out]
 mov esi,4
 lea rdx,[rel qparams]
 call nebo_int8_calibrate
 test eax,eax
 jnz .fail9
 lea rdi,[rel session_out]
 mov esi,4
 lea rdx,[rel qparams]
 lea rcx,[rel qout]
 mov r8d,4
 call nebo_int8_quantize
 test eax,eax
 jnz .fail10
 cmp byte [rel qout],54
 jne .fail11
 cmp byte [rel qout+1],0
 jne .fail12
 cmp byte [rel qout+2],127
 jne .fail13
 ; Frozen negative corpus: budget, cancellation and malformed input.
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel session_out]
 mov ecx,17
 mov r8d,34
 mov r9d,34
 call nebo_inference_batch
 cmp eax,NEBO_INFERENCE_E_LIMIT
 jne .fail14
 mov qword [rel session+8],NEBO_INFERENCE_SESSION_STATE_CANCELLED
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel session_out]
 mov ecx,2
 call nebo_inference_run
 cmp eax,NEBO_INFERENCE_E_CANCELLED
 jne .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
