bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_clear
extern neboc_dict_view_init
extern neboc_dict_view_next
extern neboc_dict_view_release
global _start

section .text
_start:
 lea rdi,[rel dict]
 lea rsi,[rel storage]
 mov edx,8
 mov ecx,42
 xor r8d,r8d
 call neboc_dict_init
 test eax,eax
 jnz fail1
 mov r12,1
.insert:
 mov rdx,r12
 imul rdx,100
 lea rdi,[rel dict]
 mov rsi,r12
 lea rcx,[rel scratch]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail1
 inc r12
 cmp r12,5
 jb .insert

 ; Three simultaneous views are shared borrows of the same owner.
 lea rdi,[rel keys_view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_KEYS
 call neboc_dict_view_init
 test eax,eax
 jnz fail2
 lea rdi,[rel values_view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_VALUES
 call neboc_dict_view_init
 test eax,eax
 jnz fail2
 lea rdi,[rel entries_view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz fail2
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],3
 jne fail2

 ; Same-instance bucket order aligns keys, values, and entries views.
 xor r12d,r12d
.next:
 mov qword [rel key1],0xaaaa
 mov qword [rel value1],0xbbbb
 lea rdi,[rel keys_view]
 lea rsi,[rel key1]
 lea rdx,[rel value1]
 lea rcx,[rel found1]
 call neboc_dict_view_next
 test eax,eax
 jnz fail3
 mov qword [rel key2],0xcccc
 mov qword [rel value2],0xdddd
 lea rdi,[rel values_view]
 lea rsi,[rel key2]
 lea rdx,[rel value2]
 lea rcx,[rel found2]
 call neboc_dict_view_next
 test eax,eax
 jnz fail3
 lea rdi,[rel entries_view]
 lea rsi,[rel key3]
 lea rdx,[rel value3]
 lea rcx,[rel found3]
 call neboc_dict_view_next
 test eax,eax
 jnz fail3
 mov rax,[rel found1]
 cmp rax,[rel found2]
 jne fail3
 cmp rax,[rel found3]
 jne fail3
 test rax,rax
 jz .ended
 mov rax,[rel key1]
 cmp rax,[rel key3]
 jne fail3
 cmp qword [rel value1],0xbbbb
 jne fail3
 cmp qword [rel key2],0xcccc
 jne fail3
 mov rax,[rel value2]
 cmp rax,[rel value3]
 jne fail3
 mov rax,[rel key1]
 imul rax,100
 cmp rax,[rel value2]
 jne fail3
 inc r12
 jmp .next
.ended:
 cmp r12,4
 jne fail3
 ; End publishes only found=0.
 cmp qword [rel key1],0xaaaa
 jne fail3
 cmp qword [rel value1],0xbbbb
 jne fail3
 cmp qword [rel key2],0xcccc
 jne fail3
 cmp qword [rel value2],0xdddd
 jne fail3

 ; Live views exclude mutation until all three releases succeed.
 lea rdi,[rel dict]
 call neboc_dict_clear
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 lea rdi,[rel keys_view]
 call neboc_dict_view_release
 test eax,eax
 jnz fail4
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],2
 jne fail4
 lea rdi,[rel values_view]
 call neboc_dict_view_release
 test eax,eax
 jnz fail4
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],1
 jne fail4

 ; Stale generation and bad token fail without publishing or decrementing.
 inc qword [rel dict+NEBO_DICT_GENERATION]
 mov qword [rel key3],0xaaaa
 mov qword [rel value3],0xbbbb
 mov qword [rel found3],0xcccc
 lea rdi,[rel entries_view]
 lea rsi,[rel key3]
 lea rdx,[rel value3]
 lea rcx,[rel found3]
 call neboc_dict_view_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 cmp qword [rel key3],0xaaaa
 jne fail5
 cmp qword [rel value3],0xbbbb
 jne fail5
 cmp qword [rel found3],0xcccc
 jne fail5
 lea rdi,[rel entries_view]
 call neboc_dict_view_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],1
 jne fail5
 dec qword [rel dict+NEBO_DICT_GENERATION]
 mov rax,[rel entries_view+NEBO_DICT_VIEW_TOKEN]
 mov [rel saved_token],rax
 xor qword [rel entries_view+NEBO_DICT_VIEW_TOKEN],1
 lea rdi,[rel entries_view]
 call neboc_dict_view_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 mov rax,[rel saved_token]
 mov [rel entries_view+NEBO_DICT_VIEW_TOKEN],rax
 lea rdi,[rel entries_view]
 call neboc_dict_view_release
 test eax,eax
 jnz fail5
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],0
 jne fail5

 ; A view is one-shot and its descriptor must be initially zeroed.
 lea rdi,[rel entries_view]
 call neboc_dict_view_release
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 mov qword [rel bad_view+NEBO_DICT_VIEW_TOKEN],1
 lea rdi,[rel bad_view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_KEYS
 call neboc_dict_view_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],0
 jne fail6

 ; Once all genuine views are released, mutation is eligible again.
 lea rdi,[rel dict]
 call neboc_dict_clear
 test eax,eax
 jnz fail7
 cmp qword [rel dict+NEBO_DICT_LENGTH],0
 jne fail7

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
exit:
 mov eax,60
 syscall

section .bss
align 8
dict: resb NEBO_DICT_SIZE
storage: resb NEBO_DICT_U64_SLOT_SIZE*8
keys_view: resb NEBO_DICT_ITERATOR_SIZE
values_view: resb NEBO_DICT_ITERATOR_SIZE
entries_view: resb NEBO_DICT_ITERATOR_SIZE
bad_view: resb NEBO_DICT_ITERATOR_SIZE
key1: resq 1
key2: resq 1
key3: resq 1
value1: resq 1
value2: resq 1
value3: resq 1
found1: resq 1
found2: resq 1
found3: resq 1
scratch: resq 1
found: resq 1
saved_token: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
