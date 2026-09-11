bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_stack_init
extern neboc_stack_push
extern neboc_stack_pop
extern neboc_stack_peek
extern neboc_stack_length
extern neboc_stack_is_empty
extern neboc_stack_clear
extern neboc_iterator_init
extern neboc_iterator_release
global _start
section .text
_start:
 lea rdi,[rel stack]
 lea rsi,[rel storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,21
 call neboc_stack_init
 test eax,eax
 jnz fail1
 lea rdi,[rel stack]
 lea rsi,[rel flag]
 call neboc_stack_is_empty
 test eax,eax
 jnz fail1
 cmp qword [rel flag],1
 jne fail1
 lea rdi,[rel stack]
 lea rsi,[rel one]
 call neboc_stack_push
 lea rdi,[rel stack]
 lea rsi,[rel two]
 call neboc_stack_push
 lea rdi,[rel stack]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_stack_peek
 test eax,eax
 jnz fail2
 cmp qword [rel out],2
 jne fail2
 cmp qword [rel found],1
 jne fail2
 lea rdi,[rel stack]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail3
 lea rdi,[rel stack]
 lea rsi,[rel three]
 call neboc_stack_push
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail3
 lea rdi,[rel stack]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_stack_pop
 test eax,eax
 jnz fail4
 cmp qword [rel out],2
 jne fail4
 cmp qword [rel storage+8],0
 jne fail4
 lea rdi,[rel stack]
 lea rsi,[rel length]
 call neboc_stack_length
 test eax,eax
 jnz fail4
 cmp qword [rel length],1
 jne fail4
 lea rdi,[rel stack]
 call neboc_stack_clear
 test eax,eax
 jnz fail5
 cmp qword [rel storage],0
 jne fail5
 lea rdi,[rel stack]
 lea rsi,[rel flag]
 call neboc_stack_is_empty
 test eax,eax
 jnz fail5
 cmp qword [rel flag],1
 jne fail5
 lea rdi,[rel stack]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_stack_pop
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5
 xor edi,edi
 jmp exit
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
exit: mov eax,60
 syscall
section .data
one: dq 1
two: dq 2
three: dq 3
section .bss
align 8
stack: resb NEBOC_LIST_SIZE
iterator: resb NEBOC_ITER_SIZE
storage: resq 3
out: resq 1
found: resq 1
length: resq 1
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
