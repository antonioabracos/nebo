bits 64
default rel
%include "runtime/ml/conv.inc"
section .data
input dq 1.0,2.0,3.0,4.0
weight dq 2.0
bias dq 1.0
two_half dq 2.5
four dq 4.0
one dq 1.0
section .bss
result resq 16
req resq 16
section .text
global _start
_start:
 lea rax,[rel result]
 mov [rel req],rax
 lea rax,[rel input]
 mov [rel req+8],rax
 lea rax,[rel weight]
 mov [rel req+16],rax
 lea rax,[rel bias]
 mov [rel req+24],rax
 mov qword [rel req+32],1
 mov qword [rel req+40],2
 mov qword [rel req+48],2
 mov qword [rel req+56],1
 mov qword [rel req+64],1
 mov qword [rel req+72],1
 mov qword [rel req+80],1
 mov qword [rel req+88],0
 mov qword [rel req+96],1
 mov qword [rel req+104],2
 mov qword [rel req+112],2
 mov qword [rel req+120],4
 lea rdi,[rel req]
 call nebo_conv2d
 test eax,eax
 jnz .fail1
 mov rax,0x4008000000000000
 cmp [rel result],rax
 jne .fail2
 mov rax,0x4022000000000000
 cmp [rel result+24],rax
 jne .fail3
 mov qword [rel req+40],1
 mov qword [rel req+104],1
 mov qword [rel req+120],2
 lea rdi,[rel req]
 call nebo_conv1d
 test eax,eax
 jnz .fail4
 mov qword [rel req+40],2
 mov qword [rel req+104],2
 ; Pool request reuses first eight qwords.
 lea rax,[rel result]
 mov [rel req],rax
 lea rax,[rel input]
 mov [rel req+8],rax
 mov qword [rel req+16],1
 mov qword [rel req+24],2
 mov qword [rel req+32],2
 mov qword [rel req+40],2
 mov qword [rel req+48],1
 mov qword [rel req+56],1
 lea rdi,[rel req]
 call nebo_max_pool2d
 test eax,eax
 jnz .fail5
 movsd xmm0,[rel result]
 ucomisd xmm0,[rel four]
 jne .fail6
 lea rdi,[rel req]
 call nebo_avg_pool2d
 test eax,eax
 jnz .fail7
 movsd xmm0,[rel result]
 ucomisd xmm0,[rel two_half]
 jne .fail8
 ; Global average request.
 mov qword [rel req+40],1
 lea rdi,[rel req]
 call nebo_global_avg_pool2d
 test eax,eax
 jnz .fail9
 movsd xmm0,[rel result]
 ucomisd xmm0,[rel two_half]
 jne .fail10
 ; Padding 1x1 by one.
 mov qword [rel req+24],1
 mov qword [rel req+32],1
 mov qword [rel req+40],1
 mov qword [rel req+48],9
 lea rdi,[rel req]
 call nebo_padding2d
 test eax,eax
 jnz .fail11
 movsd xmm0,[rel result+32]
 ucomisd xmm0,[rel one]
 jne .fail12
 mov qword [rel req+40],8
 lea rdi,[rel req]
 call nebo_padding2d
 cmp eax,NEBO_CONV_E_LIMIT
 jne .fail13
 xor edi,edi
 jmp .exit
%assign i 1
%rep 13
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
