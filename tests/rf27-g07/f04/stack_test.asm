bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_stack_init
extern neboc_stack_push
extern neboc_stack_pop
extern neboc_stack_peek
extern neboc_stack_length
extern neboc_stack_clear
global _start
section .text
_start:
 lea rdi,[rel stack]
 lea rsi,[rel storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_stack_init
 test eax,eax
 jnz fail1
 lea rbx,[rel values]
 xor r12d,r12d
.push:
 lea rdi,[rel stack]
 lea rsi,[rbx+r12*8]
 call neboc_stack_push
 test eax,eax
 jnz fail2
 inc r12
 cmp r12,3
 jb .push
 lea rdi,[rel stack]
 lea rsi,[rel values]
 call neboc_stack_push
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail3
 lea rdi,[rel stack]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_stack_peek
 test eax,eax
 jnz fail4
 cmp qword [rel output],3
 jne fail4
 cmp qword [rel found],1
 jne fail4
 lea rdi,[rel stack]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_stack_pop
 test eax,eax
 jnz fail5
 cmp qword [rel output],3
 jne fail5
 cmp qword [rel storage+16],0
 jne fail5
 lea rdi,[rel stack]
 lea rsi,[rel length]
 call neboc_stack_length
 test eax,eax
 jnz fail6
 cmp qword [rel length],2
 jne fail6
 lea rdi,[rel stack]
 call neboc_stack_clear
 test eax,eax
 jnz fail7
 cmp qword [rel storage],0
 jne fail7
 cmp qword [rel storage+8],0
 jne fail7
 lea rdi,[rel stack]
 lea rsi,[rel output]
 lea rdx,[rel found]
 call neboc_stack_pop
 test eax,eax
 jnz fail8
 cmp qword [rel found],0
 jne fail8
 xor edi,edi
 mov eax,60
 syscall
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
 jmp exit
fail8: mov edi,8
exit: mov eax,60
 syscall
section .data
values: dq 1,2,3
section .bss
align 8
stack: resb NEBOC_LIST_SIZE
storage: resq 3
output: resq 1
found: resq 1
length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
