bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_set_init
extern neboc_set_insert
extern neboc_set_contains
extern neboc_set_remove
extern neboc_set_union
extern neboc_set_intersection
extern neboc_set_difference
extern neboc_set_subset
extern neboc_dict_clear
global _start

%macro INIT_SET 3
 lea rdi,[rel %1]
 lea rsi,[rel %2]
 mov edx,8
 mov ecx,%3
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz fail1
%endmacro

%macro INSERT 2
 lea rdi,[rel %1]
 mov esi,%2
 lea rdx,[rel flag]
 call neboc_set_insert
 test eax,eax
 jnz fail2
%endmacro

section .text
_start:
 INIT_SET a,astore,1
 INIT_SET b,bstore,2
 INIT_SET dest,dstore,3
 INSERT a,1
 cmp qword [rel flag],1
 jne fail2
 INSERT a,2
 INSERT a,3
 INSERT a,2
 cmp qword [rel flag],0
 jne fail2
 INSERT b,2
 INSERT b,4

 lea rdi,[rel a]
 mov esi,2
 call neboc_set_contains
 cmp eax,1
 jne fail3
 lea rdi,[rel a]
 mov esi,9
 call neboc_set_contains
 test eax,eax
 jnz fail3
 mov qword [rel flag],0xaaaa
 lea rdi,[rel a]
 mov esi,9
 lea rdx,[rel flag]
 call neboc_set_remove
 test eax,eax
 jnz fail3
 cmp qword [rel flag],0
 jne fail3

 ; Union, intersection, difference, and subset use bounded empty destinations.
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_union
 test eax,eax
 jnz fail4
 cmp qword [rel dest+NEBO_DICT_LENGTH],4
 jne fail4
 lea rdi,[rel a]
 lea rsi,[rel dest]
 lea rdx,[rel flag]
 call neboc_set_subset
 test eax,eax
 jnz fail4
 cmp qword [rel flag],1
 jne fail4
 lea rdi,[rel dest]
 lea rsi,[rel a]
 lea rdx,[rel flag]
 call neboc_set_subset
 test eax,eax
 jnz fail4
 cmp qword [rel flag],0
 jne fail4

 lea rdi,[rel dest]
 call neboc_dict_clear
 test eax,eax
 jnz fail5
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_intersection
 test eax,eax
 jnz fail5
 cmp qword [rel dest+NEBO_DICT_LENGTH],1
 jne fail5
 lea rdi,[rel dest]
 mov esi,2
 call neboc_set_contains
 cmp eax,1
 jne fail5

 lea rdi,[rel dest]
 call neboc_dict_clear
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_difference
 test eax,eax
 jnz fail6
 cmp qword [rel dest+NEBO_DICT_LENGTH],2
 jne fail6
 lea rdi,[rel dest]
 mov esi,1
 call neboc_set_contains
 cmp eax,1
 jne fail6
 lea rdi,[rel dest]
 mov esi,3
 call neboc_set_contains
 cmp eax,1
 jne fail6

 ; Error paths preserve outputs and destination state.
 mov qword [rel flag],0xaaaa
 mov dword [rel a+NEBO_DICT_MAGIC_OFFSET],0
 lea rdi,[rel a]
 mov esi,8
 lea rdx,[rel flag]
 call neboc_set_insert
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail7
 cmp qword [rel flag],0xaaaa
 jne fail7
 mov dword [rel a+NEBO_DICT_MAGIC_OFFSET],NEBO_DICT_MAGIC
 lea rdi,[rel dest]
 call neboc_dict_clear
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel a]
 call neboc_set_union
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail7
 cmp qword [rel a+NEBO_DICT_LENGTH],3
 jne fail7

 ; Tombstoned or generation-exhausted destinations fail before writes.
 INSERT dest,99
 lea rdi,[rel dest]
 mov esi,99
 lea rdx,[rel flag]
 call neboc_set_remove
 test eax,eax
 jnz fail8
 cmp qword [rel dest+NEBO_DICT_LENGTH],0
 jne fail8
 cmp qword [rel dest+NEBO_DICT_TOMBSTONES],1
 jne fail8
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_union
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail8
 cmp qword [rel dest+NEBO_DICT_TOMBSTONES],1
 jne fail8
 lea rdi,[rel dest]
 call neboc_dict_clear
 mov rax,NEBO_DICT_GENERATION_MASK
 mov [rel dest+NEBO_DICT_GENERATION],rax
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel dest]
 call neboc_set_union
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail8
 cmp qword [rel dest+NEBO_DICT_LENGTH],0
 jne fail8

 ; Subset errors preserve the result canary.
 mov qword [rel flag],0xaaaa
 mov dword [rel b+NEBO_DICT_MAGIC_OFFSET],0
 lea rdi,[rel a]
 lea rsi,[rel b]
 lea rdx,[rel flag]
 call neboc_set_subset
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9
 cmp qword [rel flag],0xaaaa
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
exit:
 mov eax,60
 syscall

section .bss
align 8
a: resb NEBO_DICT_SIZE
b: resb NEBO_DICT_SIZE
dest: resb NEBO_DICT_SIZE
astore: resb NEBO_DICT_U64_SLOT_SIZE*8
bstore: resb NEBO_DICT_U64_SLOT_SIZE*8
dstore: resb NEBO_DICT_U64_SLOT_SIZE*8
flag: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
