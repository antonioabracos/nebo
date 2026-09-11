bits 64
default rel
%include "runtime/ml/inference.inc"

section .data
scale dq 2.0,-1.0
bias dq 1.0,0.5
input dq 1.0,2.0,-3.0,4.0,0.0,0.0,0.0,0.0
input_one dq 2.0,-2.0
three dq 3.0
zero dq 0.0
infinity dq 0x7ff0000000000000
ops:
 dq NEBO_INFERENCE_OP_SCALE_BIAS,scale,bias,2
 dq NEBO_INFERENCE_OP_RELU,0,0,2

section .bss
session resb NEBO_INFERENCE_SESSION_SIZE
workspace resb 1024
output resq 8
plan resb NEBO_INFERENCE_PLAN_SIZE
profile resb NEBO_INFERENCE_PROFILE_SIZE

section .text
global _start
_start:
 mov rax,NEBO_INFERENCE_SESSION_MAGIC
 mov [rel session+NEBO_INFERENCE_SESSION_MAGIC_OFF],rax
 mov qword [rel session+NEBO_INFERENCE_SESSION_STATE],NEBO_INFERENCE_SESSION_STATE_READY
 lea rax,[rel ops]
 mov [rel session+NEBO_INFERENCE_SESSION_OPS],rax
 mov qword [rel session+NEBO_INFERENCE_SESSION_OP_COUNT],2
 mov qword [rel session+NEBO_INFERENCE_SESSION_FEATURES],2
 mov qword [rel session+NEBO_INFERENCE_SESSION_BATCH_LIMIT],16
 lea rax,[rel workspace]
 mov [rel session+NEBO_INFERENCE_SESSION_WORKSPACE],rax
 mov qword [rel session+NEBO_INFERENCE_SESSION_WORKSPACE_CAP],1024
 mov qword [rel session+NEBO_INFERENCE_SESSION_PROFILE],1

 lea rdi,[rel session]
 lea rsi,[rel plan]
 call nebo_inference_memory_plan
 test eax,eax
 jnz .fail1
 cmp qword [rel plan],256
 jne .fail2
 cmp qword [rel plan+16],256
 jne .fail3
 cmp qword [rel plan+24],2
 jne .fail4
 cmp qword [rel plan+32],16
 jne .fail5
 cmp qword [rel plan+40],2
 jne .fail6

 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel output]
 mov ecx,2
 mov r8d,4
 mov r9d,4
 call nebo_inference_batch
 test eax,eax
 jnz .fail7
 movsd xmm0,[rel output]
 ucomisd xmm0,[rel three]
 jne .fail8
 movsd xmm0,[rel output+8]
 ucomisd xmm0,[rel zero]
 jne .fail9
 cmp qword [rel output+16],0
 jne .fail10
 cmp qword [rel output+24],0
 jne .fail11

 lea rdi,[rel session]
 lea rsi,[rel profile]
 call nebo_inference_profile
 test eax,eax
 jnz .fail12
 cmp qword [rel profile],1
 jne .fail13
 cmp qword [rel profile+8],2
 jne .fail14
 cmp qword [rel profile+16],4
 jne .fail15
 cmp qword [rel profile+24],64
 jne .fail16

 lea rdi,[rel session]
 mov esi,2
 call nebo_inference_warmup
 test eax,eax
 jnz .fail17
 lea rdi,[rel session]
 lea rsi,[rel profile]
 call nebo_inference_profile
 test eax,eax
 jnz .fail18
 cmp qword [rel profile],1
 jne .fail19

 lea rdi,[rel session]
 lea rsi,[rel input_one]
 lea rdx,[rel output]
 mov ecx,2
 call nebo_inference_run
 test eax,eax
 jnz .fail20
 mov rax,0x4014000000000000
 cmp [rel output],rax
 jne .fail21
 mov rax,0x4004000000000000
 cmp [rel output+8],rax
 jne .fail22

 mov qword [rel output],0x11223344
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel output]
 mov ecx,2
 mov r8d,4
 mov r9d,3
 call nebo_inference_run_into
 cmp eax,NEBO_INFERENCE_E_CAPACITY
 jne .fail23
 cmp qword [rel output],0x11223344
 jne .fail24
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel input+8]
 mov ecx,2
 mov r8d,4
 mov r9d,4
 call nebo_inference_run_into
 cmp eax,NEBO_INFERENCE_E_OVERLAP
 jne .fail25

 mov rax,[rel input]
 mov [rel input+32],rax
 mov rax,[rel input+8]
 mov [rel input+40],rax
 lea rdi,[rel session]
 lea rsi,[rel input+32]
 lea rdx,[rel input+32]
 mov ecx,1
 mov r8d,2
 mov r9d,2
 call nebo_inference_run_into
 test eax,eax
 jnz .fail26
 mov rax,0x4008000000000000
 cmp [rel input+32],rax
 jne .fail27

 mov rax,[rel infinity]
 mov [rel input+48],rax
 mov eax,0x99887766
 mov [rel output],rax
 lea rdi,[rel session]
 lea rsi,[rel input+48]
 lea rdx,[rel output]
 mov ecx,1
 mov r8d,2
 mov r9d,2
 call nebo_inference_run_into
 cmp eax,NEBO_INFERENCE_E_NONFINITE
 jne .fail28
 mov rax,0x99887766
 cmp [rel output],rax
 jne .fail29
 mov qword [rel session+NEBO_INFERENCE_SESSION_STATE],NEBO_INFERENCE_SESSION_STATE_CANCELLED
 lea rdi,[rel session]
 lea rsi,[rel input_one]
 lea rdx,[rel output]
 mov ecx,2
 call nebo_inference_run
 cmp eax,NEBO_INFERENCE_E_CANCELLED
 jne .fail30
 mov qword [rel session+NEBO_INFERENCE_SESSION_STATE],NEBO_INFERENCE_SESSION_STATE_READY
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel output]
 mov ecx,17
 mov r8d,34
 mov r9d,34
 call nebo_inference_batch
 cmp eax,NEBO_INFERENCE_E_LIMIT
 jne .fail31
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel output]
 mov ecx,2
 mov r8d,3
 mov r9d,4
 call nebo_inference_batch
 cmp eax,NEBO_INFERENCE_E_SHAPE
 jne .fail32
 lea rax,[rel input]
 mov [rel session+NEBO_INFERENCE_SESSION_WORKSPACE],rax
 lea rdi,[rel session]
 lea rsi,[rel input]
 lea rdx,[rel output]
 mov ecx,2
 mov r8d,4
 mov r9d,4
 call nebo_inference_batch
 cmp eax,NEBO_INFERENCE_E_OVERLAP
 jne .fail33

 xor edi,edi
 jmp .exit
%assign i 1
%rep 33
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
