bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
%include "compiler/semantic/collections/iterator.inc"

extern neboc_list_init
extern neboc_list_push
extern neboc_list_swap_remove
extern neboc_list_retain
extern neboc_list_deduplicate
extern neboc_list_at
extern neboc_iterator_init
extern neboc_iterator_enumerate
extern neboc_iterator_next_enumerated
extern neboc_iterator_skip
extern neboc_iterator_take
extern neboc_iterator_collect_list
extern neboc_iterator_release
extern neboc_list_configure_lifecycle
extern neboc_list_move_push
extern neboc_list_move_pop
extern neboc_list_drop_clear

global _start

section .text

; predicate(element*, out_bool*) -> Status
keep_greater_than_two:
 mov rax,[rdi]
 cmp rax,2
 setg al
 movzx eax,al
 mov [rsi],rax
 xor eax,eax
 ret

; Reject 13 after earlier elements have already been inspected. This is the
; failure-atomicity oracle for retain's snapshot/commit boundary.
fail_on_thirteen:
 cmp qword [rdi],13
 je .fail
 mov rax,[rdi]
 cmp rax,2
 setg al
 movzx eax,al
 mov [rsi],rax
 xor eax,eax
 ret
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

equal_i64:
 mov rax,[rdi]
 cmp rax,[rsi]
 sete al
 movzx eax,al
 mov [rdx],rax
 xor eax,eax
 ret

; A move consumes both qwords in the source and publishes them in the target.
; first=-1 is an adversarial transfer failure and must leave both sides intact.
move_pair:
 cmp qword [rdi],-1
 je .reject
 mov rax,[rdi]
 mov rdx,[rdi+8]
 mov [rsi],rax
 mov [rsi+8],rdx
 mov qword [rdi],0
 mov qword [rdi+8],0
 xor eax,eax
 ret
.reject:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

drop_pair:
 inc qword [rel drop_count]
 ret

_start:
 ; [1,3,3,5] exercises O(1) swap removal, stable retain, and adjacent dedup.
 lea rdi,[rel list]
 lea rsi,[rel list_storage]
 mov edx,8
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail1
 lea rbx,[rel values]
 xor r12d,r12d
.push_values:
 lea rdi,[rel list]
 lea rsi,[rbx+r12*8]
 call neboc_list_push
 test eax,eax
 jnz fail2
 inc r12
 cmp r12,4
 jb .push_values
 lea rdi,[rel list]
 xor esi,esi
 lea rdx,[rel scalar_out]
 lea rcx,[rel found]
 call neboc_list_swap_remove
 test eax,eax
 jnz fail3
 cmp qword [rel found],1
 jne fail3
 cmp qword [rel scalar_out],1
 jne fail3
 cmp qword [rel list+NEBOC_LIST_LENGTH_OFFSET],3
 jne fail3
 cmp qword [rel list_storage],5
 jne fail3
 lea rdi,[rel list]
 lea rsi,[rel keep_greater_than_two]
 call neboc_list_retain
 test eax,eax
 jnz fail4
 lea rdi,[rel list]
 lea rsi,[rel equal_i64]
 call neboc_list_deduplicate
 test eax,eax
 jnz fail5
 cmp qword [rel list+NEBOC_LIST_LENGTH_OFFSET],2
 jne fail5
 cmp qword [rel list_storage],5
 jne fail5
 cmp qword [rel list_storage+8],3
 jne fail5

 ; A rejecting callback after a removable prefix must not publish compaction.
 lea rdi,[rel atomic_list]
 lea rsi,[rel atomic_storage]
 mov edx,4
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 lea rbx,[rel atomic_values]
 xor r12d,r12d
.atomic_push:
 lea rdi,[rel atomic_list]
 lea rsi,[rbx+r12*8]
 call neboc_list_push
 inc r12
 cmp r12,3
 jb .atomic_push
 mov r15,[rel atomic_list+NEBOC_LIST_GENERATION_OFFSET]
 lea rdi,[rel atomic_list]
 lea rsi,[rel fail_on_thirteen]
 call neboc_list_retain
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp qword [rel atomic_list+NEBOC_LIST_LENGTH_OFFSET],3
 jne fail6
 cmp [rel atomic_list+NEBOC_LIST_GENERATION_OFFSET],r15
 jne fail6
 cmp qword [rel atomic_storage],1
 jne fail6
 cmp qword [rel atomic_storage+8],3
 jne fail6
 cmp qword [rel atomic_storage+16],13
 jne fail6

 ; enumerate/skip/take/collect retain one authenticated live borrow.
 lea rdi,[rel list]
 lea rsi,[rel iterator]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail7
 lea rdi,[rel iterator]
 call neboc_iterator_enumerate
 test eax,eax
 jnz fail7
 lea rdi,[rel iterator]
 lea rsi,[rel index_out]
 lea rdx,[rel scalar_out]
 lea rcx,[rel found]
 call neboc_iterator_next_enumerated
 test eax,eax
 jnz fail7
 cmp qword [rel index_out],0
 jne fail7
 cmp qword [rel scalar_out],5
 jne fail7
 lea rdi,[rel iterator]
 xor esi,esi
 call neboc_iterator_skip
 lea rdi,[rel iterator]
 mov esi,1
 call neboc_iterator_take
 lea rdi,[rel collected]
 lea rsi,[rel collected_storage]
 mov edx,2
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 lea rdi,[rel iterator]
 lea rsi,[rel collected]
 call neboc_iterator_collect_list
 test eax,eax
 jnz fail7
 cmp qword [rel collected+NEBOC_LIST_LENGTH_OFFSET],1
 jne fail7
 cmp qword [rel collected_storage],3
 jne fail7
 lea rdi,[rel iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail7

 ; A too-small collect target preserves both iterator position and target state.
 lea rdi,[rel empty_target]
 xor esi,esi
 xor edx,edx
 mov ecx,8
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail10
 lea rdi,[rel list]
 lea rsi,[rel failure_iterator]
 mov edx,NEBOC_ITER_KIND_LIST
 call neboc_iterator_init
 test eax,eax
 jnz fail10
 mov r15,[rel empty_target+NEBOC_LIST_GENERATION_OFFSET]
 lea rdi,[rel failure_iterator]
 lea rsi,[rel empty_target]
 call neboc_iterator_collect_list
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail10
 cmp qword [rel failure_iterator+NEBOC_ITER_INDEX_OFFSET],0
 jne fail10
 cmp qword [rel empty_target+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail10
 cmp [rel empty_target+NEBOC_LIST_GENERATION_OFFSET],r15
 jne fail10
 lea rdi,[rel failure_iterator]
 call neboc_iterator_release
 test eax,eax
 jnz fail10

 ; Public iterator extensions reject null owners instead of dereferencing them.
 xor edi,edi
 lea rsi,[rel empty_target]
 call neboc_iterator_collect_list
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail11
 xor edi,edi
 lea rsi,[rel index_out]
 lea rdx,[rel scalar_out]
 lea rcx,[rel found]
 call neboc_iterator_next_enumerated
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail11

 ; The optional lifecycle trailer validates a real two-qword move-only value.
 lea rdi,[rel owned_list]
 lea rsi,[rel owned_storage]
 mov edx,2
 mov ecx,16
 mov r8d,8
 mov r9d,1
 call neboc_list_init
 test eax,eax
 jnz fail8
 lea rdi,[rel owned_list]
 lea rsi,[rel move_pair]
 lea rdx,[rel drop_pair]
 call neboc_list_configure_lifecycle
 test eax,eax
 jnz fail8
 lea rdi,[rel owned_list]
 lea rsi,[rel pair_one]
 call neboc_list_move_push
 test eax,eax
 jnz fail8
 cmp qword [rel pair_one],0
 jne fail8
 cmp qword [rel pair_one+8],0
 jne fail8
 cmp qword [rel owned_storage],41
 jne fail8
 cmp qword [rel owned_storage+8],43
 jne fail8
 lea rdi,[rel owned_list]
 lea rsi,[rel pair_out]
 lea rdx,[rel found]
 call neboc_list_move_pop
 test eax,eax
 jnz fail8
 cmp qword [rel found],1
 jne fail8
 cmp qword [rel pair_out],41
 jne fail8
 cmp qword [rel pair_out+8],43
 jne fail8
 cmp qword [rel owned_list+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail8

 ; Failed move is atomic; successful clear invokes drop exactly once.
 lea rdi,[rel owned_list]
 lea rsi,[rel rejected_pair]
 call neboc_list_move_push
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9
 cmp qword [rel owned_list+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail9
 cmp qword [rel rejected_pair],-1
 jne fail9
 lea rdi,[rel owned_list]
 lea rsi,[rel pair_two]
 call neboc_list_move_push
 test eax,eax
 jnz fail9
 lea rdi,[rel owned_list]
 call neboc_list_drop_clear
 test eax,eax
 jnz fail9
 cmp qword [rel drop_count],1
 jne fail9
 cmp qword [rel owned_list+NEBOC_LIST_LENGTH_OFFSET],0
 jne fail9
 cmp qword [rel owned_storage],0
 jne fail9
 cmp qword [rel owned_storage+8],0
 jne fail9

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
 jmp exit
fail11: mov edi,11
exit:
 mov eax,60
 syscall

section .data
values: dq 1,3,3,5
atomic_values: dq 1,3,13
pair_one: dq 41,43
pair_two: dq 47,53
rejected_pair: dq -1,59

section .bss align=16
list: resb NEBOC_LIST_SIZE
atomic_list: resb NEBOC_LIST_SIZE
collected: resb NEBOC_LIST_SIZE
owned_list: resb NEBOC_LIST_OWNED_SIZE
empty_target: resb NEBOC_LIST_SIZE
iterator: resb NEBOC_ITER_SIZE
failure_iterator: resb NEBOC_ITER_SIZE
list_storage: resq 8
atomic_storage: resq 4
collected_storage: resq 2
owned_storage: resq 4
scalar_out: resq 1
index_out: resq 1
found: resq 1
pair_out: resq 2
drop_count: resq 1

section .note.GNU-stack noalloc noexec nowrite progbits
