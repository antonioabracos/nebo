bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_construct
extern neboc_dict_get
global _start
section .text
_start:
 ; Empty is the exact minimum-capacity caller-storage form.
 lea rax,[rel storage8]
 mov [rel request+NEBO_DICT_CONSTRUCT_STORAGE],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_CAPACITY],8
 mov qword [rel request+NEBO_DICT_CONSTRUCT_SEED],42
 mov qword [rel request+NEBO_DICT_CONSTRUCT_HASH_MODE],NEBO_HASH_MODE_DETERMINISTIC
 mov qword [rel request+NEBO_DICT_CONSTRUCT_ENTRIES],0
 mov qword [rel request+NEBO_DICT_CONSTRUCT_COUNT],0
 mov qword [rel request+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_EMPTY
 mov qword [rel request+NEBO_DICT_CONSTRUCT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 mov qword [rel request+NEBO_DICT_CONSTRUCT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 test eax,eax
 jnz fail1
 cmp qword [rel dict+NEBO_DICT_CAPACITY],8
 jne fail1
 cmp dword [rel dict+NEBO_DICT_MAGIC_OFFSET],NEBO_DICT_MAGIC
 jne fail1

 ; withCapacity accepts the remaining powers of two.
 lea rax,[rel storage16]
 mov [rel request+NEBO_DICT_CONSTRUCT_STORAGE],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_CAPACITY],16
 mov qword [rel request+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_WITH_CAPACITY
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 test eax,eax
 jnz fail2
 cmp qword [rel dict+NEBO_DICT_CAPACITY],16
 jne fail2

 ; fromEntries evaluates three unique inline u64 pairs exactly once.
 lea rax,[rel storage8]
 mov [rel request+NEBO_DICT_CONSTRUCT_STORAGE],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_CAPACITY],8
 lea rax,[rel entries]
 mov [rel request+NEBO_DICT_CONSTRUCT_ENTRIES],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_COUNT],3
 mov qword [rel request+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_FROM_ENTRIES
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 test eax,eax
 jnz fail3
 cmp qword [rel dict+NEBO_DICT_LENGTH],3
 jne fail3
 lea rdi,[rel dict]
 mov esi,2
 lea rdx,[rel out]
 lea rcx,[rel found]
 call neboc_dict_get
 test eax,eax
 jnz fail3
 cmp qword [rel found],1
 jne fail3
 cmp qword [rel out],20
 jne fail3

 ; Duplicate and over-load failures precede all destination/storage writes.
 mov rax,0x1122334455667788
 mov [rel dict],rax
 mov [rel storage8],rax
 lea rax,[rel duplicate_entries]
 mov [rel request+NEBO_DICT_CONSTRUCT_ENTRIES],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_COUNT],2
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail4
 mov rax,0x1122334455667788
 cmp [rel dict],rax
 jne fail4
 cmp [rel storage8],rax
 jne fail4
 lea rax,[rel entries7]
 mov [rel request+NEBO_DICT_CONSTRUCT_ENTRIES],rax
 mov qword [rel request+NEBO_DICT_CONSTRUCT_COUNT],7
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail5
 mov rax,0x1122334455667788
 cmp [rel dict],rax
 jne fail5
 cmp [rel storage8],rax
 jne fail5

 ; Process-seeded Dict requires an explicit nonzero effective seed.
 mov qword [rel request+NEBO_DICT_CONSTRUCT_COUNT],0
 mov qword [rel request+NEBO_DICT_CONSTRUCT_ENTRIES],0
 mov qword [rel request+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_WITH_CAPACITY
 mov qword [rel request+NEBO_DICT_CONSTRUCT_HASH_MODE],NEBO_HASH_MODE_PROCESS_SEEDED
 mov qword [rel request+NEBO_DICT_CONSTRUCT_SEED],0
 lea rdi,[rel dict]
 lea rsi,[rel request]
 call neboc_dict_construct
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail6
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
exit: mov eax,60
 syscall
section .data
entries: dq 1,10,2,20,3,30
duplicate_entries: dq 1,10,1,20
entries7: dq 1,10,2,20,3,30,4,40,5,50,6,60,7,70
section .bss
align 8
dict: resb NEBO_DICT_SIZE
request: resb NEBO_DICT_CONSTRUCT_SIZE
storage8: resb NEBO_DICT_U64_SLOT_SIZE*8
storage16: resb NEBO_DICT_U64_SLOT_SIZE*16
out: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
