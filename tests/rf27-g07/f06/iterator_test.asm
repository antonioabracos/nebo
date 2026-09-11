bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_ring_init
extern neboc_ring_push_back
extern neboc_ring_pop_front
extern neboc_iterator_init
extern neboc_iterator_next
extern neboc_iterator_release
extern neboc_iterator_mutation_gate
global _start
section .text
_start:
 lea rdi,[rel list]
 lea rsi,[rel lstore]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 lea rdi,[rel list]
 lea rsi,[rel v1]
 call neboc_list_push
 lea rdi,[rel list]
 lea rsi,[rel v2]
 call neboc_list_push
 lea rdi,[rel list]
 lea rsi,[rel iter]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail1
 lea rdi,[rel list]
 lea rsi,[rel iter]
 call neboc_iterator_mutation_gate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail2
 call next_expect1
 call next_expect2
 call next_expect_end
 lea rdi,[rel iter]
 call neboc_iterator_release
 lea rdi,[rel iter]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 ; Live shared borrow rejects mutation and a second iterator.
 lea rdi,[rel list]
 lea rsi,[rel iter]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 lea rdi,[rel list]
 lea rsi,[rel v3]
 call neboc_list_push
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel iter]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 test eax,eax
 jne fail4
 cmp qword [rel out],1
 jne fail4
 lea rdi,[rel list]
 lea rsi,[rel iter2]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel iter]
 call neboc_iterator_release
 test eax,eax
 jnz fail4
 lea rdi,[rel list]
 lea rsi,[rel v3]
 call neboc_list_push
 test eax,eax
 jnz fail4
 ; Wrapped ring order 2,3.
 lea rdi,[rel ring]
 lea rsi,[rel rstore]
 mov edx,2
 mov ecx,8
 mov r8d,1
 mov r9d,NEBOC_RING_KIND_QUEUE
 call neboc_ring_init
 lea rdi,[rel ring]
 lea rsi,[rel v1]
 call neboc_ring_push_back
 lea rdi,[rel ring]
 lea rsi,[rel v2]
 call neboc_ring_push_back
 lea rdi,[rel ring]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 lea rdi,[rel ring]
 lea rsi,[rel v3]
 call neboc_ring_push_back
 lea rdi,[rel ring]
 lea rsi,[rel iter]
 mov edx,NEBOC_ITER_KIND_RING
 call neboc_iterator_init
 call next_expect2
 call next_expect3
 lea rdi,[rel iter]
 call neboc_iterator_release
 test eax,eax
 jnz fail5
 ; Slice order 5,6.
 lea rdi,[rel slice]
 lea rsi,[rel iter]
 mov edx,NEBOC_ITER_KIND_SLICE
 call neboc_iterator_init
 lea rdi,[rel iter]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 cmp qword [rel out],5
 jne fail5
 call next_raw
 cmp qword [rel out],6
 jne fail5
 xor edi,edi
 jmp exit
next_expect1: call next_raw
 cmp qword [rel out],1
 jne fail6
 ret
next_expect2: call next_raw
 cmp qword [rel out],2
 jne fail6
 ret
next_expect3: call next_raw
 cmp qword [rel out],3
 jne fail6
 ret
next_expect_end: call next_raw
 cmp qword [rel found],0
 jne fail6
 ret
next_raw:
 lea rdi,[rel iter]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 test eax,eax
 jnz fail6
 ret
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
v1: dq 1
v2: dq 2
v3: dq 3
sdata: dq 5,6
align 8
slice: dq sdata,2,8,13,7
section .bss
align 8
list: resb NEBOC_LIST_SIZE
ring: resb NEBOC_RING_SIZE
iter: resb NEBOC_ITER_SIZE
iter2: resb NEBOC_ITER_SIZE
lstore: resq 3
rstore: resq 2
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
