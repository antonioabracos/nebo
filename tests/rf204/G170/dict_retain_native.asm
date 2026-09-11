; Supplemental owner-level failure atomicity. Public proof lives in dict_test.py.
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_retain
global _start
section .text
_start:
 lea rdi,[rel dictionary]
 lea rsi,[rel buckets]
 mov edx,8
 xor ecx,ecx
 xor r8d,r8d
 call neboc_dict_init
 test eax,eax
 jnz fail
 ; Empty dictionaries invoke no callback.
 lea rdi,[rel dictionary]
 lea rsi,[rel invalid_bool]
 call neboc_dict_retain
 test eax,eax
 jnz fail
 cmp qword [rel calls],0
 jne fail
 mov r12d,17
.insert:
 lea rdi,[rel dictionary]
 mov rsi,r12
 lea rdx,[r12+36]
 lea rcx,[rel previous]
 lea r8,[rel present]
 call neboc_dict_insert
 test eax,eax
 jnz fail
 add r12,12
 cmp r12,41
 jb .insert
 ; Borrow conflicts reject before evaluating the predicate.
 mov dword [rel dictionary+NEBO_DICT_BORROW_COUNT],1
 call snapshot
 lea rdi,[rel dictionary]
 lea rsi,[rel invalid_bool]
 call neboc_dict_retain
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 call unchanged
 cmp qword [rel calls],0
 jne fail
 mov dword [rel dictionary+NEBO_DICT_BORROW_COUNT],0
 ; The first false result must not be committed if the second is invalid.
 call snapshot
 lea rdi,[rel dictionary]
 lea rsi,[rel invalid_bool]
 call neboc_dict_retain
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 call unchanged
 cmp qword [rel calls],2
 jne fail
 ; Insufficient generation budget must not perform partial removals.
 mov rax,NEBO_DICT_GENERATION_MASK-1
 mov [rel dictionary+NEBO_DICT_GENERATION],rax
 call snapshot
 lea rdi,[rel dictionary]
 lea rsi,[rel remove_all]
 call neboc_dict_retain
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 call unchanged
 ; Keeping all entries needs no generation increment even at the limit.
 mov rax,NEBO_DICT_GENERATION_MASK
 mov [rel dictionary+NEBO_DICT_GENERATION],rax
 call snapshot
 lea rdi,[rel dictionary]
 lea rsi,[rel keep_all]
 call neboc_dict_retain
 test eax,eax
 jnz fail
 call unchanged
 ; The callback cannot mutate the borrowed owner. Both inputs stay live.
 mov qword [rel dictionary+NEBO_DICT_GENERATION],3
 call snapshot
 lea rdi,[rel dictionary]
 lea rsi,[rel attempt_mutation]
 call neboc_dict_retain
 test eax,eax
 jnz fail
 call unchanged
 ; With sufficient budget both native removals are committed.
 lea rdi,[rel dictionary]
 lea rsi,[rel remove_all]
 call neboc_dict_retain
 test eax,eax
 jnz fail
 cmp qword [rel dictionary+NEBO_DICT_LENGTH],0
 jne fail
 cmp qword [rel dictionary+NEBO_DICT_GENERATION],5
 jne fail
 cmp qword [rel dictionary+NEBO_DICT_TOMBSTONES],2
 jne fail
 xor edi,edi
 jmp exit
snapshot:
 lea rsi,[rel dictionary]
 lea rdi,[rel saved]
 mov ecx,(NEBO_DICT_SIZE+8*NEBO_DICT_U64_SLOT_SIZE)/8
 rep movsq
 ret
unchanged:
 lea rsi,[rel dictionary]
 lea rdi,[rel saved]
 mov ecx,(NEBO_DICT_SIZE+8*NEBO_DICT_U64_SLOT_SIZE)/8
 repe cmpsq
 jne fail
 ret
invalid_bool:
 inc qword [rel calls]
 xor eax,eax
 cmp qword [rel calls],1
 je .done
 mov eax,2
.done:
 ret
remove_all:
 xor eax,eax
 ret
keep_all:
 mov eax,1
 ret
attempt_mutation:
 sub rsp,8
 lea rdi,[rel dictionary]
 mov esi,31
 mov edx,83
 lea rcx,[rel previous]
 lea r8,[rel present]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 add rsp,8
 mov eax,1
 ret
fail:
 mov edi,1
exit:
 mov eax,60
 syscall
section .bss
align 8
dictionary: resb NEBO_DICT_SIZE
buckets: resb 8*NEBO_DICT_U64_SLOT_SIZE
saved: resb NEBO_DICT_SIZE+8*NEBO_DICT_U64_SLOT_SIZE
calls: resq 1
previous: resq 1
present: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
