bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_construct
extern neboc_dict_get
extern neboc_dict_insert
extern neboc_dict_view_init
extern neboc_dict_view_next
extern neboc_dict_view_release
global _start

section .text
; borrowed_get(dict*, key, copied_value_out*)
borrowed_get:
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_dict_get
 test eax,eax
 jnz .get_done
 cmp qword [rsp+8],1
 jne .get_missing
 mov rax,[rsp]
 mov [r14],rax
 xor eax,eax
 jmp .get_done
.get_missing:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.get_done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 ret

; local_view_sum(dict*, sum_out*) keeps and releases the view in this frame.
local_view_sum:
 push r12
 push r13
 push rbp
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsp
 mov ecx,10
 xor eax,eax
 rep stosq
 mov rdi,rsp
 mov rsi,r12
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz .sum_done
 xor ebp,ebp
.sum_next:
 mov rdi,rsp
 lea rsi,[rsp+56]
 lea rdx,[rsp+64]
 lea rcx,[rsp+72]
 call neboc_dict_view_next
 test eax,eax
 jnz .sum_release_error
 cmp qword [rsp+72],0
 je .sum_release_ok
 add rbp,[rsp+56]
 add rbp,[rsp+64]
 jmp .sum_next
.sum_release_ok:
 mov rdi,rsp
 call neboc_dict_view_release
 test eax,eax
 jnz .sum_done
 mov [r13],rbp
 xor eax,eax
 jmp .sum_done
.sum_release_error:
 mov rbp,rax
 mov rdi,rsp
 call neboc_dict_view_release
 mov rax,rbp
.sum_done:
 add rsp,80
 pop rbp
 pop r13
 pop r12
 ret

; caller_construct(dict*, storage*) writes only into caller-provided outputs.
caller_construct:
 push r12
 push r13
 push rbp
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsp
 mov ecx,10
 xor eax,eax
 rep stosq
 mov [rsp+NEBO_DICT_CONSTRUCT_STORAGE],r13
 mov qword [rsp+NEBO_DICT_CONSTRUCT_CAPACITY],8
 mov qword [rsp+NEBO_DICT_CONSTRUCT_SEED],42
 mov qword [rsp+NEBO_DICT_CONSTRUCT_HASH_MODE],NEBO_HASH_MODE_DETERMINISTIC
 lea rax,[rel entries]
 mov [rsp+NEBO_DICT_CONSTRUCT_ENTRIES],rax
 mov qword [rsp+NEBO_DICT_CONSTRUCT_COUNT],2
 mov qword [rsp+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_FROM_ENTRIES
 mov qword [rsp+NEBO_DICT_CONSTRUCT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 mov qword [rsp+NEBO_DICT_CONSTRUCT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 mov rdi,r12
 mov rsi,rsp
 call neboc_dict_construct
 add rsp,80
 pop rbp
 pop r13
 pop r12
 ret

_start:
 lea rdi,[rel dict]
 lea rsi,[rel storage]
 call caller_construct
 test eax,eax
 jnz fail1
 cmp qword [rel dict+NEBO_DICT_LENGTH],2
 jne fail1
 cmp qword [rel entries],5
 jne fail1
 cmp qword [rel entries+8],50
 jne fail1

 mov qword [rel result],0xaaaa
 lea rdi,[rel dict]
 mov esi,5
 lea rdx,[rel result]
 call borrowed_get
 test eax,eax
 jnz fail2
 cmp qword [rel result],50
 jne fail2
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],0
 jne fail2

 mov qword [rel result],0
 lea rdi,[rel dict]
 lea rsi,[rel result]
 call local_view_sum
 test eax,eax
 jnz fail3
 cmp qword [rel result],132
 jne fail3
 cmp dword [rel dict+NEBO_DICT_BORROW_COUNT],0
 jne fail3

 ; Returning from the borrowed helper leaves mutation eligible and no escape.
 lea rdi,[rel dict]
 mov esi,9
 mov edx,90
 lea rcx,[rel scratch]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail4
 cmp qword [rel dict+NEBO_DICT_LENGTH],3
 jne fail4

 ; Missing borrowed lookup is an error and preserves the caller output.
 mov qword [rel result],0xaaaa
 lea rdi,[rel dict]
 mov esi,99
 lea rdx,[rel result]
 call borrowed_get
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail5
 cmp qword [rel result],0xaaaa
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
exit:
 mov eax,60
 syscall

section .rodata
align 8
entries:
 dq 5,50
 dq 7,70
section .bss
align 8
dict: resb NEBO_DICT_SIZE
storage: resb NEBO_DICT_U64_SLOT_SIZE*8
result: resq 1
scratch: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
