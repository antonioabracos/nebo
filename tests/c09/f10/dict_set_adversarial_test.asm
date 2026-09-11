bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_insert
extern neboc_dict_get
extern neboc_dict_remove
extern neboc_dict_rehash
extern neboc_dict_validate
extern neboc_dict_validate_invariants
extern neboc_set_init
extern neboc_set_insert
extern neboc_set_remove
extern neboc_set_contains
global _start

section .text
_start:
 ; Deterministic Dict trace against an independent bounded reference model.
 lea rdi,[rel dict]
 lea rsi,[rel dict_store_a]
 mov edx,64
 mov ecx,42
 xor r8d,r8d
 call neboc_dict_init
 test eax,eax
 jnz fail1
 mov r15,0x9e3779b97f4a7c15
 xor r12d,r12d
 xor r14d,r14d
.dict_trace:
 mov rax,r15
 shl rax,13
 xor r15,rax
 mov rax,r15
 shr rax,7
 xor r15,rax
 mov rax,r15
 shl rax,17
 xor r15,rax
 mov r13,r15
 and r13,31
 mov rax,r15
 shr rax,8
 and eax,3
 cmp eax,2
 je .dict_remove
 cmp eax,3
 je .dict_get
.dict_insert:
 mov qword [rel old],0x0aaaaaaa
 mov qword [rel found],0x0bbbbbbb
 lea rdi,[rel dict]
 mov rsi,r13
 mov rdx,r15
 xor rdx,r12
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail2
 lea rbx,[rel ref_present]
 cmp qword [rbx+r13*8],0
 je .dict_insert_new
 cmp qword [rel found],1
 jne fail2
 lea rbx,[rel ref_values]
 mov rax,[rbx+r13*8]
 cmp [rel old],rax
 jne fail2
 jmp .dict_insert_store
.dict_insert_new:
 cmp qword [rel found],0
 jne fail2
 cmp qword [rel old],0x0aaaaaaa
 jne fail2
 lea rbx,[rel ref_present]
 mov qword [rbx+r13*8],1
 inc r14
.dict_insert_store:
 mov rax,r15
 xor rax,r12
 lea rbx,[rel ref_values]
 mov [rbx+r13*8],rax
 jmp .dict_step
.dict_remove:
 mov qword [rel old],0x0aaaaaaa
 mov qword [rel found],0x0bbbbbbb
 lea rdi,[rel dict]
 mov rsi,r13
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_remove
 test eax,eax
 jnz fail3
 lea rbx,[rel ref_present]
 cmp qword [rbx+r13*8],0
 je .dict_remove_missing
 cmp qword [rel found],1
 jne fail3
 lea rbx,[rel ref_values]
 mov rax,[rbx+r13*8]
 cmp [rel old],rax
 jne fail3
 lea rbx,[rel ref_present]
 mov qword [rbx+r13*8],0
 dec r14
 jmp .dict_step
.dict_remove_missing:
 cmp qword [rel found],0
 jne fail3
 cmp qword [rel old],0x0aaaaaaa
 jne fail3
 jmp .dict_step
.dict_get:
 mov qword [rel old],0x0aaaaaaa
 mov qword [rel found],0x0bbbbbbb
 lea rdi,[rel dict]
 mov rsi,r13
 lea rdx,[rel old]
 lea rcx,[rel found]
 call neboc_dict_get
 test eax,eax
 jnz fail4
 lea rbx,[rel ref_present]
 cmp qword [rbx+r13*8],0
 je .dict_get_missing
 cmp qword [rel found],1
 jne fail4
 lea rbx,[rel ref_values]
 mov rax,[rbx+r13*8]
 cmp [rel old],rax
 jne fail4
 jmp .dict_step
.dict_get_missing:
 cmp qword [rel found],0
 jne fail4
 cmp qword [rel old],0x0aaaaaaa
 jne fail4
.dict_step:
 inc r12
 test r12,63
 jnz .dict_no_invariant
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail5
.dict_no_invariant:
 cmp r12,2048
 jb .dict_trace
 cmp [rel dict+NEBO_DICT_LENGTH],r14
 jne fail5
 call check_dict_reference
 test eax,eax
 jnz fail5

 ; Rehash repeatedly between two distinct caller-owned buffers.
 xor r12d,r12d
.rehash_loop:
 test r12,1
 jz .rehash_b
 lea rsi,[rel dict_store_a]
 jmp .rehash_call
.rehash_b:
 lea rsi,[rel dict_store_b]
.rehash_call:
 lea rdi,[rel dict]
 mov edx,64
 lea rcx,[r12+100]
 call neboc_dict_rehash
 test eax,eax
 jnz fail6
 lea rdi,[rel dict]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail6
 call check_dict_reference
 test eax,eax
 jnz fail6
 inc r12
 cmp r12,16
 jb .rehash_loop

 ; Exact 3/4 high-load boundary and atomic rejection.
 lea rdi,[rel high_dict]
 lea rsi,[rel high_store]
 mov edx,64
 mov ecx,42
 xor r8d,r8d
 call neboc_dict_init
 test eax,eax
 jnz fail7
 xor r12d,r12d
.high_fill:
 lea rdi,[rel high_dict]
 mov rsi,r12
 lea rdx,[r12+1000]
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 test eax,eax
 jnz fail7
 inc r12
 cmp r12,48
 jb .high_fill
 mov r14,[rel high_dict+NEBO_DICT_GENERATION]
 mov qword [rel old],0x0aaaaaaa
 mov qword [rel found],0x0bbbbbbb
 lea rdi,[rel high_dict]
 mov esi,48
 mov edx,1048
 lea rcx,[rel old]
 lea r8,[rel found]
 call neboc_dict_insert
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail7
 cmp qword [rel high_dict+NEBO_DICT_LENGTH],48
 jne fail7
 cmp [rel high_dict+NEBO_DICT_GENERATION],r14
 jne fail7
 cmp qword [rel old],0x0aaaaaaa
 jne fail7
 cmp qword [rel found],0x0bbbbbbb
 jne fail7

 ; Malformed descriptor fields are rejected and restored one at a time.
 mov dword [rel high_dict+NEBO_DICT_MAGIC_OFFSET],0
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov dword [rel high_dict+NEBO_DICT_MAGIC_OFFSET],NEBO_DICT_MAGIC
 mov qword [rel high_dict+NEBO_DICT_CAPACITY],12
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov qword [rel high_dict+NEBO_DICT_CAPACITY],64
 mov qword [rel high_dict+NEBO_DICT_LENGTH],65
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov qword [rel high_dict+NEBO_DICT_LENGTH],48
 mov qword [rel high_dict+NEBO_DICT_TOMBSTONES],17
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov qword [rel high_dict+NEBO_DICT_TOMBSTONES],0
 mov qword [rel high_dict+NEBO_DICT_HASH_MODE],2
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov qword [rel high_dict+NEBO_DICT_HASH_MODE],0
 mov qword [rel high_dict+NEBO_DICT_GENERATION],0
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov [rel high_dict+NEBO_DICT_GENERATION],r14
 mov qword [rel high_dict+NEBO_DICT_KEY_TYPE],2
 call validate_high_reject
 test eax,eax
 jnz fail8
 mov qword [rel high_dict+NEBO_DICT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT

 ; Slot-state and slot-hash corruption are detected by the invariant oracle.
 lea rbx,[rel high_store]
.find_occupied:
 cmp qword [rbx+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 je .found_occupied
 add rbx,NEBO_DICT_U64_SLOT_SIZE
 jmp .find_occupied
.found_occupied:
 mov qword [rbx+NEBO_DICT_SLOT_STATE],3
 lea rdi,[rel high_dict]
 call neboc_dict_validate_invariants
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9
 mov qword [rbx+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 xor qword [rbx+NEBO_DICT_SLOT_HASH],1
 lea rdi,[rel high_dict]
 call neboc_dict_validate_invariants
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail9
 xor qword [rbx+NEBO_DICT_SLOT_HASH],1

 ; Deterministic Set trace against a separate presence oracle.
 lea rdi,[rel set]
 lea rsi,[rel set_store]
 mov edx,64
 mov ecx,77
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz fail10
 xor r12d,r12d
.set_trace:
 mov r13,r12
 and r13,31
 bt r12,5
 jc .set_remove
 lea rdi,[rel set]
 mov rsi,r13
 lea rdx,[rel found]
 call neboc_set_insert
 test eax,eax
 jnz fail10
 lea rbx,[rel set_present]
 cmp qword [rbx+r13*8],0
 jne .set_insert_old
 cmp qword [rel found],1
 jne fail10
 mov qword [rbx+r13*8],1
 jmp .set_check
.set_insert_old:
 cmp qword [rel found],0
 jne fail10
 jmp .set_check
.set_remove:
 lea rdi,[rel set]
 mov rsi,r13
 lea rdx,[rel found]
 call neboc_set_remove
 test eax,eax
 jnz fail10
 lea rbx,[rel set_present]
 mov rax,[rbx+r13*8]
 cmp [rel found],rax
 jne fail10
 mov qword [rbx+r13*8],0
.set_check:
 lea rdi,[rel set]
 mov rsi,r13
 call neboc_set_contains
 lea rbx,[rel set_present]
 cmp rax,[rbx+r13*8]
 jne fail10
 inc r12
 cmp r12,1024
 jb .set_trace
 lea rdi,[rel set]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz fail10

 xor edi,edi
 jmp exit

; Returns zero iff the 32-key reference model matches Dict lookups and length.
check_dict_reference:
 push r12
 push r13
 push rbp
 sub rsp,16
 xor r12d,r12d
.check_loop:
 mov qword [rsp],0x0aaaaaaa
 mov qword [rsp+8],0x0bbbbbbb
 lea rdi,[rel dict]
 mov rsi,r12
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_dict_get
 test eax,eax
 jnz .check_bad
 lea rbx,[rel ref_present]
 mov r13,[rbx+r12*8]
 cmp [rsp+8],r13
 jne .check_bad
 test r13,r13
 jz .check_missing
 lea rbx,[rel ref_values]
 mov rax,[rbx+r12*8]
 cmp [rsp],rax
 jne .check_bad
 jmp .check_next
.check_missing:
 cmp qword [rsp],0x0aaaaaaa
 jne .check_bad
.check_next:
 inc r12
 cmp r12,32
 jb .check_loop
 xor eax,eax
 jmp .check_done
.check_bad:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.check_done:
 add rsp,16
 pop rbp
 pop r13
 pop r12
 ret

validate_high_reject:
 lea rdi,[rel high_dict]
 call neboc_dict_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .reject_bad
 xor eax,eax
 ret
.reject_bad:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret

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
exit:
 mov eax,60
 syscall

section .bss
align 8
dict: resb NEBO_DICT_SIZE
dict_store_a: resb NEBO_DICT_U64_SLOT_SIZE*64
dict_store_b: resb NEBO_DICT_U64_SLOT_SIZE*64
high_dict: resb NEBO_DICT_SIZE
high_store: resb NEBO_DICT_U64_SLOT_SIZE*64
set: resb NEBO_DICT_SIZE
set_store: resb NEBO_DICT_U64_SLOT_SIZE*64
ref_present: resq 32
ref_values: resq 32
set_present: resq 32
old: resq 1
found: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
