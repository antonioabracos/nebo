bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_deque_init
extern neboc_deque_push_front
extern neboc_deque_push_back
extern neboc_deque_pop_front
extern neboc_deque_pop_back
extern neboc_deque_front
extern neboc_deque_back
extern neboc_deque_length
extern neboc_deque_is_empty
extern neboc_deque_clear
extern neboc_iterator_init
extern neboc_iterator_release
global _start
section .text
_start:
 lea rdi,[rel deque]
 lea rsi,[rel storage]
 mov edx,4
 mov ecx,8
 mov r8d,41
 call neboc_deque_init
 test eax,eax
 jnz fail1
 lea rdi,[rel deque]
 lea rsi,[rel two]
 call neboc_deque_push_back
 lea rdi,[rel deque]
 lea rsi,[rel three]
 call neboc_deque_push_back
 lea rdi,[rel deque]
 lea rsi,[rel one]
 call neboc_deque_push_front
 test eax,eax
 jnz fail1
 ; head wrapped to the last physical slot.
 cmp qword [rel deque+NEBOC_RING_HEAD_OFFSET],3
 jne fail1
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_front
 cmp qword [rel out],1
 jne fail2
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_back
 cmp qword [rel out],3
 jne fail2
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_pop_back
 test eax,eax
 jnz fail3
 cmp qword [rel out],3
 jne fail3
 cmp qword [rel storage+8],0
 jne fail3
 lea rdi,[rel deque]
 lea rsi,[rel zero]
 call neboc_deque_push_front
 test eax,eax
 jnz fail3

 lea rdi,[rel deque]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_RING
 call neboc_iterator_init
 test eax,eax
 jnz fail4
 lea rdi,[rel deque]
 lea rsi,[rel three]
 call neboc_deque_push_front
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_pop_back
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail4

 ; Logical order is now 0,1,2; remove from alternating ends.
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_pop_front
 test eax,eax
 jnz fail5
 cmp qword [rel out],0
 jne fail5
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_pop_back
 test eax,eax
 jnz fail5
 cmp qword [rel out],2
 jne fail5
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_deque_front
 cmp qword [rel out],1
 jne fail5
 lea rdi,[rel deque]
 lea rsi,[rel length]
 call neboc_deque_length
 cmp qword [rel length],1
 jne fail5
 lea rdi,[rel deque]
 call neboc_deque_clear
 test eax,eax
 jnz fail6
 lea rdi,[rel deque]
 lea rsi,[rel flag]
 call neboc_deque_is_empty
 test eax,eax
 jnz fail6
 cmp qword [rel flag],1
 jne fail6
 cmp qword [rel deque+NEBOC_RING_HEAD_OFFSET],0
 jne fail6
 cmp qword [rel deque+NEBOC_RING_TAIL_OFFSET],0
 jne fail6
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
 jmp exit
fail6: mov edi,6
exit: mov eax,60
 syscall
section .data
zero: dq 0
one: dq 1
two: dq 2
three: dq 3
section .bss
align 8
deque: resb NEBOC_RING_SIZE
iterator: resb NEBOC_ITER_SIZE
storage: resq 4
out: resq 1
found: resq 1
length: resq 1
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
