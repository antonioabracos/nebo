bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_remove
extern neboc_dict_clear
extern neboc_dict_rehash
extern neboc_dict_get
extern neboc_dict_view_init
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

 ; New insertion publishes only had_old; replacement publishes both outputs.
 mov qword [rel old],0xaaaa
 mov qword [rel found],0xbbbb
 lea rdi,[rel dict]
 mov esi,1
 mov edx,10
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail2
 cmp qword [rel found],0
 jne fail2
 cmp qword [rel old],0xaaaa
 jne fail2
 mov rax,[rel dict+NEBO_DICT_GENERATION]
 mov [rel saved_generation],rax
 mov qword [rel old],0
 lea rdi,[rel dict]
 mov esi,1
 mov edx,11
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail2
 cmp qword [rel found],1
 jne fail2
 cmp qword [rel old],10
 jne fail2
 cmp qword [rel dict+NEBO_DICT_LENGTH],1
 jne fail2
 mov rax,[rel saved_generation]
 inc rax
 cmp [rel dict+NEBO_DICT_GENERATION],rax
 jne fail2

 ; A live shared view excludes every mutation and preserves output canaries.
 lea rdi,[rel view]
 lea rsi,[rel dict]
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz fail3
 mov qword [rel old],0xaaaa
 mov qword [rel found],0xbbbb
 lea rdi,[rel dict]
 mov esi,2
 mov edx,22
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 cmp qword [rel old],0xaaaa
 jne fail3
 cmp qword [rel found],0xbbbb
 jne fail3
 lea rdi,[rel dict]
 mov esi,1
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_remove
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 cmp qword [rel old],0xaaaa
 jne fail3
 cmp qword [rel found],0xbbbb
 jne fail3
 lea rdi,[rel dict]
 call neboc_dict_clear
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 lea rdi,[rel dict]
 lea rsi,[rel replacement]
 mov edx,16
 mov ecx,77
 call neboc_dict_rehash
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail3
 lea rdi,[rel view]
 call neboc_dict_view_release
 test eax,eax
 jnz fail3

 ; Fill exactly to the 3/4 load limit.
 mov r12,2
.fill:
 cmp r12,7
 jae .filled
 mov rdx,r12
 imul rdx,10
 lea rdi,[rel dict]
 mov rsi,r12
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail4
 inc r12
 jmp .fill
.filled:
 cmp qword [rel dict+NEBO_DICT_LENGTH],6
 jne fail4
 mov rax,[rel dict+NEBO_DICT_GENERATION]
 mov [rel saved_generation],rax
 mov qword [rel old],0xaaaa
 mov qword [rel found],0xbbbb
 lea rdi,[rel dict]
 mov esi,7
 mov edx,70
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail4
 cmp qword [rel old],0xaaaa
 jne fail4
 cmp qword [rel found],0xbbbb
 jne fail4
 mov rax,[rel saved_generation]
 cmp [rel dict+NEBO_DICT_GENERATION],rax
 jne fail4
 cmp qword [rel dict+NEBO_DICT_LENGTH],6
 jne fail4

 ; Missing remove is a successful no-op and publishes only found=0.
 mov qword [rel old],0xaaaa
 mov qword [rel found],0xbbbb
 lea rdi,[rel dict]
 mov esi,99
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_remove
 test eax,eax
 jnz fail5
 cmp qword [rel found],0
 jne fail5
 cmp qword [rel old],0xaaaa
 jne fail5

 ; Generation exhaustion is fail-closed and preserves outputs.
 mov rax,NEBO_DICT_GENERATION_MASK
 mov [rel dict+NEBO_DICT_GENERATION],rax
 mov qword [rel old],0xaaaa
 mov qword [rel found],0xbbbb
 lea rdi,[rel dict]
 mov esi,1
 mov edx,12
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail6
 cmp qword [rel old],0xaaaa
 jne fail6
 cmp qword [rel found],0xbbbb
 jne fail6
 lea rdi,[rel dict]
 mov esi,1
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_remove
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail6
 cmp qword [rel old],0xaaaa
 jne fail6
 cmp qword [rel found],0xbbbb
 jne fail6
 mov qword [rel dict+NEBO_DICT_GENERATION],20

 ; Rehash rejects alias and partial overlap before any live-state write.
 mov rax,[rel dict+NEBO_DICT_STORAGE]
 mov [rel saved_storage],rax
 mov rax,[rel dict+NEBO_DICT_LENGTH]
 mov [rel saved_length],rax
 lea rdi,[rel dict]
 mov rsi,[rel saved_storage]
 mov edx,8
 mov ecx,77
 call neboc_dict_rehash
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail7
 mov rax,[rel saved_storage]
 cmp [rel dict+NEBO_DICT_STORAGE],rax
 jne fail7
 mov rsi,rax
 add rsi,32
 lea rdi,[rel dict]
 mov edx,8
 mov ecx,77
 call neboc_dict_rehash
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail7
 mov rax,[rel saved_length]
 cmp [rel dict+NEBO_DICT_LENGTH],rax
 jne fail7

 ; Distinct larger caller storage commits once and retains all entries.
 mov rax,[rel dict+NEBO_DICT_GENERATION]
 mov [rel saved_generation],rax
 lea rdi,[rel dict]
 lea rsi,[rel replacement]
 mov edx,16
 mov ecx,77
 call neboc_dict_rehash
 test eax,eax
 jnz fail8
 lea rax,[rel replacement]
 cmp [rel dict+NEBO_DICT_STORAGE],rax
 jne fail8
 cmp qword [rel dict+NEBO_DICT_CAPACITY],16
 jne fail8
 cmp qword [rel dict+NEBO_DICT_SEED],77
 jne fail8
 cmp qword [rel dict+NEBO_DICT_TOMBSTONES],0
 jne fail8
 mov rax,[rel saved_generation]
 inc rax
 cmp [rel dict+NEBO_DICT_GENERATION],rax
 jne fail8
 lea rdi,[rel dict]
 mov esi,1
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_get
 test eax,eax
 jnz fail8
 cmp qword [rel found],1
 jne fail8
 cmp qword [rel old],11
 jne fail8

 ; Process-seeded mode never synthesizes a replacement seed.
 lea rdi,[rel process_dict]
 lea rsi,[rel process_storage]
 mov edx,8
 mov ecx,1
 mov r8d,NEBO_HASH_MODE_PROCESS_SEEDED
 call neboc_dict_init
 test eax,eax
 jnz fail91
 lea rdi,[rel process_dict]
 lea rsi,[rel process_replacement]
 mov edx,8
 xor ecx,ecx
 call neboc_dict_rehash
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail92

 ; Clear exhaustion preserves the live Dict; normal clear commits once.
 mov rax,NEBO_DICT_GENERATION_MASK
 mov [rel dict+NEBO_DICT_GENERATION],rax
 lea rdi,[rel dict]
 call neboc_dict_clear
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail10
 mov rax,[rel saved_length]
 cmp [rel dict+NEBO_DICT_LENGTH],rax
 jne fail10
 mov qword [rel dict+NEBO_DICT_GENERATION],30
 lea rdi,[rel dict]
 call neboc_dict_clear
 test eax,eax
 jnz fail10
 cmp qword [rel dict+NEBO_DICT_LENGTH],0
 jne fail10
 cmp qword [rel dict+NEBO_DICT_TOMBSTONES],0
 jne fail10
 cmp qword [rel dict+NEBO_DICT_GENERATION],31
 jne fail10

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
fail91: mov edi,91
 jmp exit
fail92: mov edi,92
 jmp exit
fail10: mov edi,10
exit:
 mov eax,60
 syscall

section .bss
align 8
dict: resb NEBO_DICT_SIZE
storage: resb NEBO_DICT_U64_SLOT_SIZE*8
replacement: resb NEBO_DICT_U64_SLOT_SIZE*16
process_dict: resb NEBO_DICT_SIZE
process_storage: resb NEBO_DICT_U64_SLOT_SIZE*8
process_replacement: resb NEBO_DICT_U64_SLOT_SIZE*8
view: resb NEBO_DICT_ITERATOR_SIZE
old: resq 1
found: resq 1
saved_generation: resq 1
saved_storage: resq 1
saved_length: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
