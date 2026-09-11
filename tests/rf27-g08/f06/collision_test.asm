bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_get
extern neboc_dict_remove
extern neboc_dict_rehash
extern neboc_dict_validate_invariants
extern neboc_dict_collision_count
extern neboc_dict_max_probe_length
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
 lea r12,[rel keys]
 xor r13d,r13d
.insert:
 lea rdi,[rel dict]
 mov rsi,[r12+r13*8]
 lea rdx,[rsi+100]
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail2
 inc r13
 cmp r13,6
 jb .insert
 lea rdi,[rel dict]
 call neboc_dict_max_probe_length
 cmp rax,6
 jb fail3
 lea rdi,[rel dict]
 call neboc_dict_collision_count
 cmp rax,5
 jb fail4
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail5
 mov r14,[rel dict+NEBO_DICT_GENERATION]
 lea rdi,[rel dict]
 mov esi,49
 mov edx,149
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail6
 cmp qword [rel dict+NEBO_DICT_LENGTH],6
 jne fail6
 cmp [rel dict+NEBO_DICT_GENERATION],r14
 jne fail6
 lea rdi,[rel dict]
 mov esi,25
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_remove
 test eax,eax
 jnz fail7
 lea rdi,[rel dict]
 mov esi,49
 mov edx,149
 lea rcx,[rel out]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail7
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail8
 mov rax,[rel dict+NEBO_DICT_STORAGE]
.find_occ:
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 je .corrupt
 add rax,NEBO_DICT_U64_SLOT_SIZE
 jmp .find_occ
.corrupt:
 xor qword [rax+NEBO_DICT_SLOT_HASH],1
 push rax
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9_pop
 pop rax
 xor qword [rax+NEBO_DICT_SLOT_HASH],1
 lea rdi,[rel dict]
 lea rsi,[rel store2]
 mov edx,16
 mov ecx,99
 call neboc_dict_rehash
 test eax,eax
 jnz fail10
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail10
 xor edi,edi
 jmp exit
fail9_pop: pop rax
fail9: mov edi,9
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
fail10: mov edi,10
exit: mov eax,60
 syscall
section .data
keys: dq 1,9,17,25,33,41
section .bss
align 8
dict: resb NEBO_DICT_SIZE
store1: resb NEBO_DICT_U64_SLOT_SIZE*8
store2: resb NEBO_DICT_U64_SLOT_SIZE*16
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
