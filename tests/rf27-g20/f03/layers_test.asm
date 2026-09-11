bits 64
default rel
%include "runtime/ml/layers.inc"
section .data
same dq 2.0,2.0
ab dq 1.0,2.0
cd dq 3.0,4.0
zero dq 0.0,0.0
one dq 1.0,1.0
eps dq 0.00001
table dq 1.0,2.0,3.0,4.0
section .bss
result resq 4
req resq 8
section .text
global _start
_start:
 lea rdi,[rel result]
 lea rsi,[rel same]
 mov edx,2
 call nebo_layer_sequential_relu
 test eax,eax
 jnz .fail1
 lea rax,[rel result]
 mov [rel req],rax
 lea rax,[rel same]
 mov [rel req+8],rax
 mov qword [rel req+16],2
 mov rax,[rel eps]
 mov [rel req+24],rax
 lea rdi,[rel req]
 call nebo_layer_norm
 test eax,eax
 jnz .fail2
 movq xmm0,[rel result]
 pxor xmm1,xmm1
 ucomisd xmm0,xmm1
 jne .fail3
 lea rax,[rel result]
 mov [rel req],rax
 lea rax,[rel ab]
 mov [rel req+8],rax
 lea rax,[rel zero]
 mov [rel req+16],rax
 lea rax,[rel one]
 mov [rel req+24],rax
 mov [rel req+32],rax
 lea rax,[rel zero]
 mov [rel req+40],rax
 mov qword [rel req+48],2
 mov rax,[rel eps]
 mov [rel req+56],rax
 lea rdi,[rel req]
 call nebo_layer_batch_norm_eval
 test eax,eax
 jnz .fail4
 lea rdi,[rel result]
 lea rsi,[rel ab]
 mov edx,2
 mov ecx,1
 call nebo_layer_dropout_eval
 cmp eax,NEBO_LAYER_E_TRAINING
 jne .fail5
 lea rdi,[rel result]
 lea rsi,[rel ab]
 mov edx,2
 xor ecx,ecx
 call nebo_layer_dropout_eval
 test eax,eax
 jnz .fail6
 mov rax,0x3ff0000000000000
 cmp qword [rel result],rax
 jne .fail7
 lea rdi,[rel result]
 lea rsi,[rel ab]
 lea rdx,[rel cd]
 mov ecx,2
 call nebo_layer_residual
 test eax,eax
 jnz .fail8
 mov rax,0x4010000000000000
 cmp qword [rel result],rax
 jne .fail9
 lea rdi,[rel result]
 lea rsi,[rel cd]
 mov edx,2
 call nebo_layer_flatten
 test eax,eax
 jnz .fail10
 lea rax,[rel result]
 mov [rel req],rax
 lea rax,[rel table]
 mov [rel req+8],rax
 mov qword [rel req+16],2
 mov qword [rel req+24],2
 mov qword [rel req+32],1
 mov qword [rel req+40],2
 lea rdi,[rel req]
 call nebo_layer_embedding
 test eax,eax
 jnz .fail11
 mov rax,0x4008000000000000
 cmp qword [rel result],rax
 jne .fail12
 mov qword [rel req+32],2
 lea rdi,[rel req]
 call nebo_layer_embedding
 cmp eax,NEBO_LAYER_E_INDEX
 jne .fail13
 mov qword [rel req+32],1
 mov qword [rel req+24],65
 lea rdi,[rel req]
 call nebo_layer_embedding
 cmp eax,NEBO_LAYER_E_LIMIT
 jne .fail14
 mov qword [rel req+24],2
 mov qword [rel req+16],0
 lea rdi,[rel req]
 call nebo_layer_embedding
 cmp eax,NEBO_LAYER_E_LIMIT
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
