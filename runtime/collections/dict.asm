; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-F03 bounded u64/u64 Dict substrate.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_hash_u64

section .text
; init(desc*, storage*, capacity, seed, mode)
NEBOC_ABI_FUNCTION neboc_dict_init
 test rdi,rdi
 jz .init_invalid
 test rdi,7
 jnz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rsi,7
 jnz .init_invalid
 cmp rdx,NEBO_DICT_MIN_CAPACITY
 jb .init_limit
 cmp rdx,NEBO_DICT_MAX_CAPACITY
 ja .init_limit
 mov rax,rdx
 dec rax
 test rdx,rax
 jnz .init_invalid
 cmp r8,NEBO_HASH_MODE_PROCESS_SEEDED
 ja .init_invalid
 push rdi
 push rdx
 push rcx
 push r8
 mov rdi,rsi
 mov rcx,rdx
 shl rcx,2
 xor eax,eax
 rep stosq
 pop r8
 pop rcx
 pop rdx
 pop rdi
 mov r9,rdi
 mov rdi,r9
 mov ecx,NEBO_DICT_SIZE/8
 xor eax,eax
 rep stosq
 mov [r9+NEBO_DICT_STORAGE],rsi
 mov qword [r9+NEBO_DICT_KEY_STRIDE],8
 mov qword [r9+NEBO_DICT_VALUE_STRIDE],8
 mov [r9+NEBO_DICT_CAPACITY],rdx
 mov qword [r9+NEBO_DICT_GENERATION],1
 mov [r9+NEBO_DICT_HASH_MODE],r8
 mov [r9+NEBO_DICT_SEED],rcx
 mov qword [r9+NEBO_DICT_KEY_TYPE],1
 mov qword [r9+NEBO_DICT_VALUE_TYPE],1
 xor eax,eax
 ret
.init_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dict_validate
 test rdi,rdi
 jz .val_invalid
 test rdi,7
 jnz .val_invalid
 cmp qword [rdi+NEBO_DICT_STORAGE],0
 je .val_source
 mov rax,[rdi+NEBO_DICT_CAPACITY]
 cmp rax,NEBO_DICT_MIN_CAPACITY
 jb .val_source
 cmp rax,NEBO_DICT_MAX_CAPACITY
 ja .val_source
 mov rcx,rax
 dec rcx
 test rax,rcx
 jnz .val_source
 cmp [rdi+NEBO_DICT_LENGTH],rax
 ja .val_source
 cmp qword [rdi+NEBO_DICT_KEY_STRIDE],8
 jne .val_source
 cmp qword [rdi+NEBO_DICT_VALUE_STRIDE],8
 jne .val_source
 cmp qword [rdi+NEBO_DICT_HASH_MODE],NEBO_HASH_MODE_PROCESS_SEEDED
 ja .val_source
 xor eax,eax
 ret
.val_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.val_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; probe(desc*, key) -> rax slot or 0, rdx found, rcx probes, r8 hash.
NEBOC_ABI_FUNCTION neboc_dict_probe
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov rdi,rsi
 mov rsi,[r12+NEBO_DICT_SEED]
 call neboc_hash_u64
 mov r8,rax
 mov r14,[r12+NEBO_DICT_CAPACITY]
 mov r15,[r12+NEBO_DICT_STORAGE]
 mov r9,r8
 dec r14
 and r9,r14
 inc r14
 xor r10d,r10d
 xor ebp,ebp
.probe_loop:
 mov rax,r9
 shl rax,5
 add rax,r15
 mov r11,[rax+NEBO_DICT_SLOT_STATE]
 cmp r11,NEBO_DICT_EMPTY
 je .probe_empty
 cmp r11,NEBO_DICT_TOMBSTONE
 je .probe_tomb
 cmp [rax+NEBO_DICT_SLOT_HASH],r8
 jne .probe_next
 cmp [rax+NEBO_DICT_SLOT_KEY],r13
 je .probe_found
 jmp .probe_next
.probe_tomb:
 test rbp,rbp
 cmovz rbp,rax
.probe_next:
 inc r10
 inc r9
 cmp r9,r14
 jb .probe_index_ok
 xor r9d,r9d
.probe_index_ok:
 cmp r10,r14
 jb .probe_loop
 mov rax,rbp
 xor edx,edx
 mov rcx,r10
 jmp .probe_done
.probe_empty:
 test rbp,rbp
 cmovnz rax,rbp
 xor edx,edx
 lea rcx,[r10+1]
 jmp .probe_done
.probe_found:
 mov edx,1
 lea rcx,[r10+1]
.probe_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; insert(desc*, key, value, old_out*, had_old*)
NEBOC_ABI_FUNCTION neboc_dict_insert
 test rcx,rcx
 jz .ins_invalid
 test r8,r8
 jz .ins_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov qword [r15],0
 mov qword [rbp],0
 call neboc_dict_validate
 test eax,eax
 jnz .ins_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .ins_borrowed
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test rax,rax
 jz .ins_full
 test edx,edx
 jnz .ins_update
 mov r9,[r12+NEBO_DICT_LENGTH]
 inc r9
 mov r10,r9
 shl r10,2
 mov r11,[r12+NEBO_DICT_CAPACITY]
 imul r11,3
 cmp r10,r11
 ja .ins_full
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_TOMBSTONE
 jne .ins_new
 dec qword [r12+NEBO_DICT_TOMBSTONES]
.ins_new:
 mov qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 mov [rax+NEBO_DICT_SLOT_HASH],r8
 mov [rax+NEBO_DICT_SLOT_KEY],r13
 mov [rax+NEBO_DICT_SLOT_VALUE],r14
 mov [r12+NEBO_DICT_LENGTH],r9
 cmp rcx,[r12+NEBO_DICT_MAX_PROBE]
 cmova rdx,rcx
 jbe .ins_gen
 mov [r12+NEBO_DICT_MAX_PROBE],rcx
.ins_gen:
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .ins_done
.ins_update:
 mov r9,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r15],r9
 mov qword [rbp],1
 mov [rax+NEBO_DICT_SLOT_VALUE],r14
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .ins_done
.ins_full:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .ins_done
.ins_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.ins_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.ins_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; get(desc*, key, value_out*, found*)
NEBOC_ABI_FUNCTION neboc_dict_get
 test rdx,rdx
 jz .get_invalid
 test rcx,rcx
 jz .get_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 call neboc_dict_validate
 test eax,eax
 jnz .get_done
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test edx,edx
 jz .get_ok
 mov r9,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r14],r9
 mov qword [r15],1
.get_ok:
 xor eax,eax
.get_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.get_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; contains(desc*, key) -> Bool
NEBOC_ABI_FUNCTION neboc_dict_contains
 push r12
 push r13
 push rbp
 mov r12,rdi
 mov r13,rsi
 call neboc_dict_validate
 test eax,eax
 jnz .contains_no
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 mov eax,edx
 jmp .contains_done
.contains_no:
 xor eax,eax
.contains_done:
 pop rbp
 pop r13
 pop r12
 ret

; remove(desc*, key, old_out*, found*)
NEBOC_ABI_FUNCTION neboc_dict_remove
 test rdx,rdx
 jz .rem_invalid
 test rcx,rcx
 jz .rem_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],0
 mov qword [r15],0
 call neboc_dict_validate
 test eax,eax
 jnz .rem_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .rem_borrowed
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test edx,edx
 jz .rem_ok
 mov r9,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r14],r9
 mov qword [r15],1
 mov qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_TOMBSTONE
 mov qword [rax+NEBO_DICT_SLOT_HASH],0
 mov qword [rax+NEBO_DICT_SLOT_KEY],0
 mov qword [rax+NEBO_DICT_SLOT_VALUE],0
 dec qword [r12+NEBO_DICT_LENGTH]
 inc qword [r12+NEBO_DICT_TOMBSTONES]
 inc qword [r12+NEBO_DICT_GENERATION]
.rem_ok:
 xor eax,eax
 jmp .rem_done
.rem_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.rem_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rem_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_dict_clear
 push r12
 push rbp
 push r13
 mov r12,rdi
 call neboc_dict_validate
 test eax,eax
 jnz .clear_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .clear_borrowed
 mov rdi,[r12+NEBO_DICT_STORAGE]
 mov rcx,[r12+NEBO_DICT_CAPACITY]
 shl rcx,2
 xor eax,eax
 rep stosq
 mov qword [r12+NEBO_DICT_LENGTH],0
 mov qword [r12+NEBO_DICT_TOMBSTONES],0
 mov qword [r12+NEBO_DICT_MAX_PROBE],0
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .clear_done
.clear_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.clear_done:
 pop r13
 pop rbp
 pop r12
 ret

; rehash(desc*, new_storage*, new_capacity, new_seed), caller scratch.
NEBOC_ABI_FUNCTION neboc_dict_rehash
 test rdi,rdi
 jz .rehash_invalid
 test rdi,7
 jnz .rehash_invalid
 test rsi,rsi
 jz .rehash_invalid
 test rsi,7
 jnz .rehash_invalid
 cmp rdx,NEBO_DICT_MIN_CAPACITY
 jb .rehash_limit
 cmp rdx,NEBO_DICT_MAX_CAPACITY
 ja .rehash_limit
 mov rax,rdx
 dec rax
 test rdx,rax
 jnz .rehash_invalid
 mov rax,[rdi+NEBO_DICT_LENGTH]
 shl rax,2
 mov r8,rdx
 imul r8,3
 cmp rax,r8
 ja .rehash_limit
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_dict_validate
 test eax,eax
 jnz .rehash_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .rehash_borrowed
 mov rdi,r13
 mov rcx,r14
 shl rcx,2
 xor eax,eax
 rep stosq
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov rbp,[r12+NEBO_DICT_STORAGE]
 mov qword [rsp+16],0
.rehash_scan:
 mov rax,[rsp+16]
 cmp rax,[r12+NEBO_DICT_CAPACITY]
 jae .rehash_commit
 mov rdx,rax
 shl rdx,5
 add rdx,rbp
 cmp qword [rdx+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .rehash_next
 mov rdi,[rdx+NEBO_DICT_SLOT_KEY]
 mov rsi,r15
 mov [rsp+24],rdx
 call neboc_hash_u64
 mov r8,rax
 mov r9,rax
 mov r10,r14
 dec r10
 and r9,r10
 xor r11d,r11d
.rehash_probe:
 mov rax,r9
 shl rax,5
 add rax,r13
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_EMPTY
 je .rehash_place
 inc r11
 inc r9
 cmp r9,r14
 jb .rehash_wrap_ok
 xor r9d,r9d
.rehash_wrap_ok:
 cmp r11,r14
 jb .rehash_probe
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .rehash_done
.rehash_place:
 mov rdx,[rsp+24]
 mov qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 mov [rax+NEBO_DICT_SLOT_HASH],r8
 mov rcx,[rdx+NEBO_DICT_SLOT_KEY]
 mov [rax+NEBO_DICT_SLOT_KEY],rcx
 mov rcx,[rdx+NEBO_DICT_SLOT_VALUE]
 mov [rax+NEBO_DICT_SLOT_VALUE],rcx
 inc r11
 cmp r11,[rsp+8]
 jbe .rehash_next
 mov [rsp+8],r11
.rehash_next:
 inc qword [rsp+16]
 jmp .rehash_scan
.rehash_commit:
 mov [r12+NEBO_DICT_STORAGE],r13
 mov [r12+NEBO_DICT_CAPACITY],r14
 mov qword [r12+NEBO_DICT_TOMBSTONES],0
 mov rax,[rsp+8]
 mov [r12+NEBO_DICT_MAX_PROBE],rax
 mov [r12+NEBO_DICT_SEED],r15
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .rehash_done
.rehash_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.rehash_done:
 add rsp,32
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rehash_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.rehash_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
