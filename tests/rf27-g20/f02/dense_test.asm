bits 64
default rel
%include "runtime/ml/dense.inc"
section .data
input dq 1.0,2.0,-1.0,3.0
weights dq 1.0,0.0, 0.5,2.0
bias dq 0.5,-1.0
zeros dq 0.0,0.0
pair dq 1000.0,1000.0
nan dq 0x7ff8000000000000
half dq 0.5
one dq 1.0
one_half dq 1.5
minus_one dq -1.0
section .bss
dense_out resq 8
req resq 8
section .text
global _start
_start:
 lea rax,[rel dense_out]
 mov [rel req],rax
 lea rax,[rel input]
 mov [rel req+8],rax
 lea rax,[rel weights]
 mov [rel req+16],rax
 lea rax,[rel bias]
 mov [rel req+24],rax
 mov qword [rel req+32],2
 mov qword [rel req+40],2
 mov qword [rel req+48],2
 mov qword [rel req+56],4
 lea rdi,[rel req]
 call nebo_dense_linear
 test eax,eax
 jnz .fail1
 movsd xmm0,[rel dense_out]
 ucomisd xmm0,[rel one_half]
 jne .fail2
 movsd xmm0,[rel dense_out+8]
 movsd xmm1,[rel input+8]
 addsd xmm1,xmm1
 subsd xmm1,[rel half]
 ucomisd xmm0,xmm1
 jne .fail3
 lea rdi,[rel dense_out]
 lea rsi,[rel input]
 mov edx,4
 call nebo_dense_relu
 test eax,eax
 jnz .fail4
 movsd xmm0,[rel dense_out+16]
 xorpd xmm1,xmm1
 ucomisd xmm0,xmm1
 jne .fail5
 lea rdi,[rel dense_out]
 lea rsi,[rel zeros]
 mov edx,2
 call nebo_dense_sigmoid
 test eax,eax
 jnz .fail6
 movsd xmm0,[rel dense_out]
 ucomisd xmm0,[rel half]
 jne .fail7
 lea rdi,[rel dense_out]
 lea rsi,[rel zeros]
 mov edx,2
 call nebo_dense_tanh
 test eax,eax
 jnz .fail8
 movsd xmm0,[rel dense_out]
 xorpd xmm1,xmm1
 ucomisd xmm0,xmm1
 jne .fail9
 lea rdi,[rel dense_out]
 lea rsi,[rel zeros]
 mov edx,2
 call nebo_dense_gelu
 test eax,eax
 jnz .fail10
 movsd xmm0,[rel dense_out]
 xorpd xmm1,xmm1
 ucomisd xmm0,xmm1
 jne .fail11
 lea rdi,[rel dense_out]
 lea rsi,[rel pair]
 mov edx,2
 call nebo_dense_softmax
 test eax,eax
 jnz .fail12
 movsd xmm0,[rel dense_out]
 ucomisd xmm0,[rel half]
 jne .fail13
 movsd xmm0,[rel dense_out+8]
 ucomisd xmm0,[rel half]
 jne .fail14
 mov rax,0x5555555555555555
 mov [rel dense_out],rax
 lea rdi,[rel dense_out]
 lea rsi,[rel nan]
 mov edx,1
 call nebo_dense_relu
 cmp eax,NEBO_DENSE_E_NONFINITE
 jne .fail15
 mov rax,0x5555555555555555
 cmp [rel dense_out],rax
 jne .fail16
 lea rdi,[rel input+8]
 lea rsi,[rel input]
 mov edx,2
 call nebo_dense_relu
 cmp eax,NEBO_DENSE_E_OVERLAP
 jne .fail17
 mov qword [rel req+32],17
 lea rdi,[rel req]
 call nebo_dense_linear
 cmp eax,NEBO_DENSE_E_LIMIT
 jne .fail18
 mov qword [rel req+32],2
 mov qword [rel req+56],3
 lea rdi,[rel req]
 call nebo_dense_linear
 cmp eax,NEBO_DENSE_E_LIMIT
 jne .fail19
 xor edi,edi
 jmp .exit
%assign i 1
%rep 19
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
