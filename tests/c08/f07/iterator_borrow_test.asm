bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/ring_core.inc"
%include "compiler/semantic/collections/iterator.inc"
extern neboc_list_init
extern neboc_list_push
extern neboc_list_set
extern neboc_list_clear
extern neboc_list_stable_sort
extern neboc_ring_init
extern neboc_ring_push_back
extern neboc_ring_pop_front
extern neboc_ring_clear
extern neboc_iterator_init
extern neboc_iterator_next
extern neboc_iterator_size_hint
extern neboc_iterator_release
global _start

section .text
_start:
 lea rdi,[rel list]
 lea rsi,[rel list_storage]
 mov edx,3
 mov ecx,8
 mov r8d,8
 mov r9d,11
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rdi,[rel list]
 lea rsi,[rel one]
 call neboc_list_push
 lea rdi,[rel list]
 lea rsi,[rel two]
 call neboc_list_push
 mov rax,[rel list+NEBOC_LIST_GENERATION_OFFSET]
 mov [rel low_generation],rax

 lea rdi,[rel list]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail2
 bt qword [rel list+NEBOC_LIST_GENERATION_OFFSET],63
 jnc fail2
 lea rdi,[rel iterator]
 lea rsi,[rel hint]
 call neboc_iterator_size_hint
 test eax,eax
 jnz fail2
 cmp qword [rel hint],2
 jne fail2

 ; Exactly one live shared iterator per owner.
 mov rax,0x1122334455667788
 mov [rel iterator2],rax
 lea rdi,[rel list]
 lea rsi,[rel iterator2]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 mov rax,0x1122334455667788
 cmp [rel iterator2],rax
 jne fail3

 ; Both structural and non-structural mutations are excluded.
 lea rdi,[rel list]
 lea rsi,[rel three]
 call neboc_list_push
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel list]
 xor esi,esi
 lea rdx,[rel three]
 call neboc_list_set
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel list]
 call neboc_list_clear
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel list]
 lea rsi,[rel compare_int]
 lea rdx,[rel scratch]
 mov ecx,16
 call neboc_list_stable_sort
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 cmp qword [rel list_storage],1
 jne fail4
 cmp qword [rel list_storage+8],2
 jne fail4

 lea rdi,[rel iterator]
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 test eax,eax
 jnz fail5
 cmp qword [rel found],1
 jne fail5
 cmp qword [rel out],1
 jne fail5
 lea rdi,[rel iterator]
 lea rsi,[rel hint]
 call neboc_iterator_size_hint
 test eax,eax
 jnz fail5
 cmp qword [rel hint],1
 jne fail5
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail6
 mov rax,[rel list+NEBOC_LIST_GENERATION_OFFSET]
 cmp rax,[rel low_generation]
 jne fail6
 lea rdi,[rel iterator]
 call neboc_iterator_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 lea rdi,[rel list]
 lea rsi,[rel three]
 call neboc_list_push
 test eax,eax
 jnz fail6

 ; The same borrow bit governs ring-backed Queue/Deque iteration.
 lea rdi,[rel ring]
 mov qword [rel stage],71
 lea rsi,[rel ring_storage]
 mov edx,2
 mov ecx,8
 mov r8d,12
 mov r9d,NEBOC_RING_KIND_QUEUE
 call neboc_ring_init
 test eax,eax
 jnz fail7
 lea rdi,[rel ring]
 mov qword [rel stage],72
 lea rsi,[rel one]
 call neboc_ring_push_back
 lea rdi,[rel ring]
 mov qword [rel stage],73
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_RING
 call neboc_iterator_init
 test eax,eax
 jnz fail7
 lea rdi,[rel ring]
 mov qword [rel stage],74
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 lea rdi,[rel ring]
 mov qword [rel stage],75
 call neboc_ring_clear
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 lea rdi,[rel iterator]
 mov qword [rel stage],76
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_iterator_next
 test eax,eax
 jnz fail7
 cmp qword [rel out],1
 jne fail7
 lea rdi,[rel iterator]
 mov qword [rel stage],77
 call neboc_iterator_release
 test eax,eax
 jnz fail7
 lea rdi,[rel ring]
 mov qword [rel stage],78
 lea rsi,[rel out]
 lea rdx,[rel found]
 call neboc_ring_pop_front
 test eax,eax
 jnz fail_status
 mov qword [rel stage],79
 cmp qword [rel found],1
 jne fail7
 xor edi,edi
 jmp exit

compare_int:
 mov rax,[rdi]
 cmp rax,[rsi]
 jl .less
 jg .greater
 mov qword [rdx],0
 xor eax,eax
 ret
.less:
 mov qword [rdx],-1
 xor eax,eax
 ret
.greater:
 mov qword [rdx],1
 xor eax,eax
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
 jmp exit
fail7: mov edi,[rel stage]
 jmp exit
fail_status: mov edi,eax
 add edi,80
exit:
 mov eax,60
 syscall

section .data
one: dq 1
two: dq 2
three: dq 3
section .bss
align 8
list: resb NEBOC_LIST_SIZE
ring: resb NEBOC_RING_SIZE
iterator: resb NEBOC_ITER_SIZE
iterator2: resb NEBOC_ITER_SIZE
list_storage: resq 3
ring_storage: resq 2
scratch: resq 2
out: resq 1
found: resq 1
hint: resq 1
low_generation: resq 1
stage: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
