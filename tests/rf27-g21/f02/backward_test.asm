bits 64
default rel
%include "runtime/autograd/backward.inc"
section .data
x dq 2.0,3.0
y dq 4.0
xy dq 8.0,12.0
loss dq 20.0
seed2 dq 2.0
four dq 4.0
five dq 5.0
eight dq 8.0
ten dq 10.0
acc_a dq 1.0,2.0
acc_b dq 3.0,4.0
infinity dq 0x7ff0000000000000
section .bss
graph resq 8
nodes resb NEBO_BACKWARD_NODE_SIZE*4
workspace resq 8
gx resq 2
gy resq 1
gxy resq 2
gloss resq 1
section .text
global _start
_start:
 lea rax,[rel nodes]
mov [rel graph],rax
 mov qword [rel graph+8],4
 mov qword [rel graph+16],3
 mov qword [rel graph+24],1
 lea rax,[rel workspace]
mov [rel graph+32],rax
 mov qword [rel graph+40],6
 lea rdi,[rel nodes]
lea rax,[rel x]
mov [rdi],rax
lea rax,[rel gx]
mov [rdi+8],rax
 mov qword [rdi+16],2
mov qword [rdi+24],NEBO_BACKWARD_OP_LEAF
mov qword [rdi+32],-1
mov qword [rdi+40],-1
mov qword [rdi+48],1
mov qword [rdi+56],0
 add rdi,NEBO_BACKWARD_NODE_SIZE
lea rax,[rel y]
mov [rdi],rax
lea rax,[rel gy]
mov [rdi+8],rax
 mov qword [rdi+16],1
mov qword [rdi+24],NEBO_BACKWARD_OP_LEAF
mov qword [rdi+32],-1
mov qword [rdi+40],-1
mov qword [rdi+48],1
mov qword [rdi+56],2
 add rdi,NEBO_BACKWARD_NODE_SIZE
lea rax,[rel xy]
mov [rdi],rax
lea rax,[rel gxy]
mov [rdi+8],rax
 mov qword [rdi+16],2
mov qword [rdi+24],NEBO_BACKWARD_OP_MUL
mov qword [rdi+32],0
mov qword [rdi+40],1
mov qword [rdi+48],1
mov qword [rdi+56],3
 add rdi,NEBO_BACKWARD_NODE_SIZE
lea rax,[rel loss]
mov [rdi],rax
lea rax,[rel gloss]
mov [rdi+8],rax
 mov qword [rdi+16],1
mov qword [rdi+24],NEBO_BACKWARD_OP_SUM
mov qword [rdi+32],2
mov qword [rdi+40],-1
mov qword [rdi+48],1
mov qword [rdi+56],5
 lea rdi,[rel graph]
 call nebo_loss_backward
 test eax,eax
 jnz .fail1
 movsd xmm0,[rel gx]
ucomisd xmm0,[rel four]
jne .fail2
 movsd xmm0,[rel gx+8]
ucomisd xmm0,[rel four]
jne .fail3
 movsd xmm0,[rel gy]
ucomisd xmm0,[rel five]
jne .fail4
 mov rax,0x3ff0000000000000
 cmp [rel gxy],rax
jne .fail5
 cmp [rel gxy+8],rax
jne .fail6
 cmp [rel gloss],rax
jne .fail7
 cmp qword [rel workspace],0
jne .fail8
 cmp qword [rel workspace+40],0
jne .fail9
 lea rdi,[rel graph]
lea rsi,[rel seed2]
mov edx,1
 call nebo_tensor_backward
 test eax,eax
jnz .fail10
 movsd xmm0,[rel gx]
ucomisd xmm0,[rel eight]
jne .fail11
 movsd xmm0,[rel gy]
ucomisd xmm0,[rel ten]
jne .fail12
 lea rdi,[rel acc_a]
lea rsi,[rel acc_b]
mov edx,2
 call nebo_gradient_accumulate
 test eax,eax
jnz .fail13
 movsd xmm0,[rel acc_a]
ucomisd xmm0,[rel four]
jne .fail14
 mov rax,0x4018000000000000
cmp [rel acc_a+8],rax
jne .fail15
 lea rdi,[rel acc_a]
mov esi,2
 call nebo_gradient_zero
 test eax,eax
jnz .fail16
 cmp qword [rel acc_a],0
jne .fail17
 cmp qword [rel acc_a+8],0
jne .fail18
 mov qword [rel graph+16],2
 lea rdi,[rel graph]
 call nebo_loss_backward
 cmp eax,NEBO_BACKWARD_E_SHAPE
jne .fail19
 mov qword [rel graph+16],3
 lea rdi,[rel graph]
xor esi,esi
mov edx,1
 call nebo_tensor_backward
 cmp eax,NEBO_BACKWARD_E_ARGUMENT
jne .fail20
 mov qword [rel nodes+48],2
 lea rdi,[rel graph]
 call nebo_loss_backward
 cmp eax,NEBO_BACKWARD_E_GENERATION
jne .fail21
 mov qword [rel nodes+48],1
 mov rax,[rel infinity]
mov [rel x],rax
 mov qword [rel gx],0x55
 lea rdi,[rel graph]
 call nebo_loss_backward
 cmp eax,NEBO_BACKWARD_E_NONFINITE
jne .fail22
 cmp qword [rel gx],0x55
jne .fail23
 mov rax,0x4000000000000000
mov [rel x],rax
 mov qword [rel nodes+NEBO_BACKWARD_NODE_SIZE*2+32],2
 lea rdi,[rel graph]
 call nebo_loss_backward
 cmp eax,NEBO_BACKWARD_E_GRAPH
jne .fail24
 xor edi,edi
 jmp .exit
%assign i 1
%rep 24
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
