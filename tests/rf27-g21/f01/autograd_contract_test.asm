bits 64
default rel
%include "compiler/semantic/autograd/autograd_contract.inc"
section .data
gradient dq 1.0
section .bss
tape resb NEBO_AUTOGRAD_TAPE_SIZE
nodes resb NEBO_AUTOGRAD_NODE_SIZE*4
edges resq 4
summary resq 6
result resq 1
section .text
global _start
_start:
 mov rax,NEBO_AUTOGRAD_MAGIC
 mov [rel tape],rax
 mov qword [rel tape+8],NEBO_AUTOGRAD_STATE_ACTIVE
 mov qword [rel tape+16],1
 lea rax,[rel nodes]
 mov [rel tape+24],rax
 mov qword [rel tape+40],4
 lea rax,[rel edges]
 mov [rel tape+48],rax
 mov qword [rel tape+64],4
 mov qword [rel tape+80],8
 mov qword [rel tape+88],1
 lea rdi,[rel tape]
 mov esi,NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD | NEBO_AUTOGRAD_FLAG_HAS_GRAD
 lea rdx,[rel gradient]
 mov ecx,2
 mov r8,NEBO_AUTOGRAD_NO_PARENT
 call nebo_autograd_record
 test eax,eax
 jnz .fail1
 test edx,edx
 jnz .fail2
 lea rdi,[rel tape]
 mov esi,NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD
 xor edx,edx
 mov ecx,1
 xor r8d,r8d
 call nebo_autograd_record
 test eax,eax
 jnz .fail3
 cmp edx,1
 jne .fail4
 lea rdi,[rel tape]
 xor esi,esi
 lea rdx,[rel result]
 call nebo_autograd_requires_gradient
 test eax,eax
 jnz .fail5
 cmp qword [rel result],1
 jne .fail6
 lea rdi,[rel tape]
 xor esi,esi
 lea rdx,[rel result]
 call nebo_autograd_gradient
 test eax,eax
 jnz .fail7
 lea rax,[rel gradient]
 cmp [rel result],rax
 jne .fail8
 lea rdi,[rel tape]
 lea rsi,[rel summary]
 call nebo_autograd_graph
 test eax,eax
 jnz .fail9
 cmp qword [rel summary],2
 jne .fail10
 cmp qword [rel summary+8],1
 jne .fail11
 cmp qword [rel summary+16],3
 jne .fail12
 cmp qword [rel summary+40],2
 jne .fail13
 lea rdi,[rel tape]
 mov esi,1
 call nebo_autograd_detach
 test eax,eax
 jnz .fail14
 lea rdi,[rel tape]
 mov esi,1
 lea rdx,[rel result]
 call nebo_autograd_requires_gradient
 test eax,eax
 jnz .fail15
 cmp qword [rel result],0
 jne .fail16
 lea rdi,[rel tape]
 mov esi,1
 lea rdx,[rel result]
 call nebo_autograd_gradient
 cmp eax,NEBO_AUTOGRAD_E_GRADIENT
 jne .fail17
 lea rdi,[rel tape]
 call nebo_autograd_clear
 test eax,eax
 jnz .fail18
 cmp qword [rel tape+16],2
 jne .fail19
 cmp qword [rel tape+32],0
 jne .fail20
 cmp qword [rel tape+56],0
 jne .fail21
 cmp qword [rel tape+72],0
 jne .fail22
 lea rdi,[rel tape]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 mov r8,NEBO_AUTOGRAD_NO_PARENT
 call nebo_autograd_record
 cmp eax,NEBO_AUTOGRAD_E_STATE
 jne .fail23
 mov qword [rel tape+88],1
 lea rdi,[rel tape]
 mov esi,NEBO_AUTOGRAD_FLAG_REQUIRES_GRAD
 xor edx,edx
 xor ecx,ecx
 mov r8,NEBO_AUTOGRAD_NO_PARENT
 call nebo_autograd_record
 test eax,eax
 jnz .fail24
 test edx,edx
 jnz .fail25
 cmp dword [rel nodes+4],2
 jne .fail26
 mov qword [rel tape+40],0
 lea rdi,[rel tape]
 xor esi,esi
 xor edx,edx
 xor ecx,ecx
 mov r8,NEBO_AUTOGRAD_NO_PARENT
 call nebo_autograd_record
 cmp eax,NEBO_AUTOGRAD_E_LIMIT
 jne .fail27
 xor edi,edi
 jmp .exit
%assign i 1
%rep 27
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
