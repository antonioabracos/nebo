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
 mov r12d,1
.insert:
 lea rdi,[rel dict]
 mov rsi,r12
 lea rdx,[r12+100]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail1
 inc r12
 cmp r12,4
 jb .insert
 lea rdi,[rel view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz fail2
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],1
 jne fail2
 xor r12d,r12d
 xor r13d,r13d
.next:
 lea rdi,[rel view]
 lea rsi,[rel key]
 lea rdx,[rel value]
 lea rcx,[rel found]
 call neboc_dict_view_next
 test eax,eax
 jnz fail3
 cmp qword [rel found],0
 je .end
 mov rax,[rel key]
 add r12,rax
 mov rax,[rel value]
 add r13,rax
 jmp .next
.end:
 cmp r12,6
 jne fail4
 cmp r13,306
 jne fail4
 lea rdi,[rel dict]
 call neboc_dict_clear
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 lea rdi,[rel view]
 call neboc_dict_view_release
 test eax,eax
 jnz fail6
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],0
 jne fail6
 lea rdi,[rel dict]
 call neboc_dict_clear
 test eax,eax
 jnz fail7
 lea rdi,[rel view]
 lea rsi,[rel key]
 lea rdx,[rel value]
 lea rcx,[rel found]
 call neboc_dict_view_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail8
 lea rdi,[rel view]
 lea rsi,[rel dict]
 mov edx,4
 call neboc_dict_view_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
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
exit: mov eax,60
 syscall
section .bss
align 8
dict: resb NEBO_DICT_SIZE
view: resb NEBO_DICT_ITERATOR_SIZE
storage: resb NEBO_DICT_U64_SLOT_SIZE*8
key: resq 1
value: resq 1
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
