bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_queue_init
extern neboc_queue_enqueue
extern neboc_queue_dequeue
extern neboc_queue_front
extern neboc_queue_back
extern neboc_queue_length
extern neboc_queue_is_empty
extern neboc_queue_clear
extern neboc_iterator_init
extern neboc_iterator_release
global _start
section .text
_start:
 lea rdi,[rel queue]
 lea rsi,[rel storage]
 mov edx,3
 mov ecx,8
 mov r8d,31
 call neboc_queue_init
 test eax,eax
 jnz fail1
 lea rdi,[rel queue]
 lea rsi,[rel flag]
 call neboc_queue_is_empty
 test eax,eax
 jnz fail1
 cmp qword [rel flag],1
 jne fail1
 lea rdi,[rel queue]
 lea rsi,[rel one]
 call neboc_queue_enqueue
 lea rdi,[rel queue]
 lea rsi,[rel two]
 call neboc_queue_enqueue
 lea rdi,[rel queue]
 lea rsi,[rel three]
 call neboc_queue_enqueue
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 test eax,eax
 jnz fail2
 cmp qword [rel out],1
 jne fail2
 cmp qword [rel storage],0
 jne fail2
 ; Tail wraps to physical slot zero; logical FIFO remains 2,3,4.
 lea rdi,[rel queue]
 lea rsi,[rel four]
 call neboc_queue_enqueue
 test eax,eax
 jnz fail2
 cmp qword [rel storage],4
 jne fail2
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_front
 test eax,eax
 jnz fail3
 cmp qword [rel out],2
 jne fail3
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_back
 test eax,eax
 jnz fail3
 cmp qword [rel out],4
 jne fail3
 lea rdi,[rel queue]
 lea rsi,[rel length]
 call neboc_queue_length
 test eax,eax
 jnz fail3
 cmp qword [rel length],3
 jne fail3

 lea rdi,[rel queue]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_RING
 call neboc_iterator_init
 test eax,eax
 jnz fail4
 lea rdi,[rel queue]
 lea rsi,[rel one]
 call neboc_queue_enqueue
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail4

 ; Drain in FIFO order and prove empty Option semantics.
 lea rbx,[rel expected]
 xor r12d,r12d
.drain:
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 test eax,eax
 jnz fail5
 cmp qword [rel found],1
 jne fail5
 mov rax,[rbx+r12*8]
 cmp [rel out],rax
 jne fail5
 inc r12
 cmp r12,3
 jb .drain
 mov qword [rel out],99
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5
 cmp qword [rel out],99
 jne fail5
 lea rdi,[rel queue]
 call neboc_queue_clear
 test eax,eax
 jnz fail6
 cmp qword [rel queue+NEBOC_RING_HEAD_OFFSET],0
 jne fail6
 cmp qword [rel queue+NEBOC_RING_TAIL_OFFSET],0
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
one: dq 1
two: dq 2
three: dq 3
four: dq 4
expected: dq 2,3,4
section .bss
align 8
queue: resb NEBOC_RING_SIZE
iterator: resb NEBOC_ITER_SIZE
storage: resq 3
out: resq 1
found: resq 1
length: resq 1
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
