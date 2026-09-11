bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_get
extern neboc_list_remove
extern neboc_list_pop
extern neboc_queue_init
extern neboc_queue_enqueue
extern neboc_queue_dequeue
extern neboc_queue_front
extern neboc_queue_clear
extern neboc_iterator_init
extern neboc_iterator_release
global _start
section .text
_start:
 lea rdi,[rel list]
 lea rsi,[rel list_storage]
 mov edx,2
 mov ecx,8
 mov r8d,8
 mov r9d,61
 call neboc_list_init
 lea rdi,[rel list]
 lea rsi,[rel one]
 call neboc_list_push

 ; Invalid descriptor errors publish neither payload nor found.
 mov qword [rel out],88
 mov qword [rel found],77
 mov qword [rel list+NEBOC_LIST_FLAGS_OFFSET],0
 lea rdi,[rel list]
 xor esi,esi
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_list_get
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail1
 cmp qword [rel out],88
 jne fail1
 cmp qword [rel found],77
 jne fail1
 mov rax,NEBOC_LIST_MAGIC
 mov [rel list+NEBOC_LIST_FLAGS_OFFSET],rax

 ; A live shared borrow makes pop fail atomically, including outputs.
 lea rdi,[rel list]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail2
 mov qword [rel out],88
 mov qword [rel found],77
 lea rdi,[rel list]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_list_pop
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail2
 cmp qword [rel out],88
 jne fail2
 cmp qword [rel found],77
 jne fail2
 lea rdi,[rel iterator]
 call neboc_iterator_release

 ; Exhausted generation is also failure-atomic.
 mov rax,NEBOC_LIST_GENERATION_MASK
 mov [rel list+NEBOC_LIST_GENERATION_OFFSET],rax
 lea rdi,[rel list]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_list_pop
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail3
 cmp qword [rel out],88
 jne fail3
 cmp qword [rel found],77
 jne fail3
 mov qword [rel list+NEBOC_LIST_GENERATION_OFFSET],2
 ; Option-style OOB is success, found=0, payload unchanged.
 lea rdi,[rel list]
 mov esi,9
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_list_remove
 test eax,eax
 jnz fail3
 cmp qword [rel found],0
 jne fail3
 cmp qword [rel out],88
 jne fail3

 ; Ring mutation under borrow obeys the same output rule.
 lea rdi,[rel queue]
 lea rsi,[rel ring_storage]
 mov edx,2
 mov ecx,8
 mov r8d,62
 call neboc_queue_init
 lea rdi,[rel queue]
 lea rsi,[rel one]
 call neboc_queue_enqueue
 lea rdi,[rel queue]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_RING
 call neboc_iterator_init
 test eax,eax
 jnz fail4
 mov qword [rel out],88
 mov qword [rel found],77
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 cmp qword [rel out],88
 jne fail4
 cmp qword [rel found],77
 jne fail4
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail4

 ; Invalid ring metadata preserves read outputs; empty success writes only found.
 mov qword [rel queue+NEBOC_LIST_FLAGS_OFFSET],0
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_front
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 cmp qword [rel out],88
 jne fail5
 cmp qword [rel found],77
 jne fail5
 mov rax,NEBOC_RING_QUEUE_MAGIC
 mov [rel queue+NEBOC_LIST_FLAGS_OFFSET],rax
 lea rdi,[rel queue]
 call neboc_queue_clear
 test eax,eax
 jnz fail5
 mov qword [rel out],88
 mov qword [rel found],77
 lea rdi,[rel queue]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_queue_dequeue
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5
 cmp qword [rel out],88
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
section .bss
align 8
list: resb NEBOC_LIST_SIZE
queue: resb NEBOC_RING_SIZE
iterator: resb NEBOC_ITER_SIZE
list_storage: resq 2
ring_storage: resq 2
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
