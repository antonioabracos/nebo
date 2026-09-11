bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/ring_core.inc"
extern neboc_ring_init
extern neboc_ring_push_back
extern neboc_ring_push_front
extern neboc_ring_pop_front
extern neboc_ring_pop_back
extern neboc_ring_peek_front
extern neboc_ring_clear
global _start
section .text
_start:
 lea rdi,[rel queue]
 lea rsi,[rel qstore]
 mov edx,3
 mov ecx,8
 mov r8d,1
 mov r9d,NEBOC_RING_KIND_QUEUE
 call neboc_ring_init
 test eax,eax
 jnz fail1
 lea rbx,[rel values]
 xor r12d,r12d
.qpush:
 lea rdi,[rel queue]
 lea rsi,[rbx+r12*8]
 call neboc_ring_push_back
 test eax,eax
 jnz fail2
 inc r12
 cmp r12,3
 jb .qpush
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 test eax,eax
 jnz fail3
 cmp qword [rel out],1
 jne fail3
 lea rdi,[rel queue]
 lea rsi,[rel value4]
 call neboc_ring_push_back
 test eax,eax
 jnz fail4
 mov r12d,2
.qpop:
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 test eax,eax
 jnz fail5
 cmp [rel out],r12
 jne fail5
 inc r12
 cmp r12,5
 jb .qpop
 lea rdi,[rel deque]
 lea rsi,[rel dstore]
 mov edx,3
 mov ecx,8
 mov r8d,1
 mov r9d,NEBOC_RING_KIND_DEQUE
 call neboc_ring_init
 test eax,eax
 jnz fail6
 lea rdi,[rel deque]
 lea rsi,[rel value2]
 call neboc_ring_push_back
 lea rdi,[rel deque]
 lea rsi,[rel value1]
 call neboc_ring_push_front
 lea rdi,[rel deque]
 lea rsi,[rel value3]
 call neboc_ring_push_back
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_back
 test eax,eax
 jnz fail7
 cmp qword [rel out],3
 jne fail7
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 cmp qword [rel out],1
 jne fail8
 lea rdi,[rel deque]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_peek_front
 cmp qword [rel out],2
 jne fail9
 lea rdi,[rel deque]
 call neboc_ring_clear
 test eax,eax
 jnz fail10
 cmp qword [rel deque+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail10
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
 jmp exit
fail7: mov edi,7
 jmp exit
fail8: mov edi,8
 jmp exit
fail9: mov edi,9
 jmp exit
fail10: mov edi,10
exit: mov eax,60
 syscall
section .data
values: dq 1,2,3
value1: dq 1
value2: dq 2
value3: dq 3
value4: dq 4
section .bss
align 8
queue: resb NEBOC_RING_SIZE
deque: resb NEBOC_RING_SIZE
qstore: resq 3
dstore: resq 3
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
