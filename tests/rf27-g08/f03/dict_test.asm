bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_get
extern neboc_dict_contains
extern neboc_dict_remove
extern neboc_dict_clear
extern neboc_dict_rehash
global _start
section .text
_start:
 lea rdi,[rel dict]
 lea rsi,[rel store1]
 mov edx,8
 mov ecx,42
 xor r8d,r8d
 call neboc_dict_init
 test eax,eax
 jnz fail1
 cmp qword [rel dict+NEBO_DICT_CAPACITY],8
 jne fail1
 lea rdi,[rel dict]
 mov esi,1
 mov edx,10
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail2
 cmp qword [rel dict+NEBO_DICT_LENGTH],1
 jne fail2
 lea rdi,[rel dict]
 mov esi,1
 mov edx,11
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail3
 cmp qword [rel found],1
 jne fail3
 cmp qword [rel out],10
 jne fail3
 lea rdi,[rel dict]
 mov esi,1
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_get
 cmp qword [rel found],1
 jne fail4
 cmp qword [rel out],11
 jne fail4
 lea rdi,[rel dict]
 mov esi,1
 call neboc_dict_contains
 cmp eax,1
 jne fail5
 lea rdi,[rel dict]
 mov esi,9
 mov edx,90
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail6
 cmp qword [rel dict+NEBO_DICT_MAX_PROBE],2
 jb fail6
 lea rdi,[rel dict]
 mov esi,1
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_remove
 test eax,eax
 jnz fail7
 cmp qword [rel out],11
 jne fail7
 cmp qword [rel dict+NEBO_DICT_TOMBSTONES],1
 jne fail7
 lea rdi,[rel dict]
 mov esi,33
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_remove
 test eax,eax
 jnz fail8
 cmp qword [rel found],0
 jne fail8
 lea rdi,[rel dict]
 lea rsi,[rel store2]
 mov edx,16
 mov ecx,77
 call neboc_dict_rehash
 test eax,eax
 jnz fail9
 cmp qword [rel dict+NEBO_DICT_CAPACITY],16
 jne fail9
 cmp qword [rel dict+NEBO_DICT_SEED],77
 jne fail9
 lea rdi,[rel dict]
 mov esi,9
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_get
 cmp qword [rel found],1
 jne fail10
 cmp qword [rel out],90
 jne fail10
 lea rdi,[rel dict]
 call neboc_dict_clear
 test eax,eax
 jnz fail11
 cmp qword [rel dict+NEBO_DICT_LENGTH],0
 jne fail11
 lea rdi,[rel dict]
 lea rsi,[rel store1]
 mov edx,7
 xor ecx,ecx
 xor r8d,r8d
 call neboc_dict_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail12
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
 jmp exit
fail12: mov edi,12
exit: mov eax,60
 syscall
section .bss
align 8
dict: resb NEBO_DICT_SIZE
store1: resb NEBO_DICT_U64_SLOT_SIZE*8
store2: resb NEBO_DICT_U64_SLOT_SIZE*16
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
