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
 cmp r8,NEBO_HASH_MODE_PROCESS_SEEDED
 jne .init_seed_ok
 test rcx,rcx
 jz .init_invalid
.init_seed_ok:
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
 mov r10,rcx
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
 mov [r9+NEBO_DICT_SEED],r10
 mov qword [r9+NEBO_DICT_KEY_TYPE],1
 mov qword [r9+NEBO_DICT_VALUE_TYPE],1
 mov dword [r9+NEBO_DICT_MAGIC_OFFSET],NEBO_DICT_MAGIC
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
 cmp dword [rdi+NEBO_DICT_MAGIC_OFFSET],NEBO_DICT_MAGIC
 jne .val_source
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
 cmp qword [rdi+NEBO_DICT_HASH_MODE],NEBO_HASH_MODE_PROCESS_SEEDED
 jne .val_seed_ok
 cmp qword [rdi+NEBO_DICT_SEED],0
 je .val_source
.val_seed_ok:
 cmp qword [rdi+NEBO_DICT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 jne .val_source
 cmp qword [rdi+NEBO_DICT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 jne .val_source
 cmp qword [rdi+NEBO_DICT_GENERATION],0
 je .val_source
 mov rcx,[rdi+NEBO_DICT_TOMBSTONES]
 add rcx,[rdi+NEBO_DICT_LENGTH]
 jc .val_source
 cmp rcx,rax
 ja .val_source
 xor eax,eax
 ret
.val_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.val_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; construct(desc*, request*) with fully prevalidated caller storage and entries.
NEBOC_ABI_FUNCTION neboc_dict_construct
 test rdi,rdi
 jz .construct_invalid
 test rsi,rsi
 jz .construct_invalid
 mov rax,rdi
 or rax,rsi
 test rax,7
 jnz .construct_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rbx,[r13+NEBO_DICT_CONSTRUCT_MODE]
 cmp rbx,NEBO_DICT_CONSTRUCT_FROM_ENTRIES
 ja .construct_invalid_saved
 cmp qword [r13+NEBO_DICT_CONSTRUCT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 jne .construct_type
 cmp qword [r13+NEBO_DICT_CONSTRUCT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 jne .construct_type
 mov r14,[r13+NEBO_DICT_CONSTRUCT_CAPACITY]
 cmp r14,NEBO_DICT_MIN_CAPACITY
 jb .construct_limit
 cmp r14,NEBO_DICT_MAX_CAPACITY
 ja .construct_limit
 mov rax,r14
 dec rax
 test r14,rax
 jnz .construct_invalid_saved
 mov rax,[r13+NEBO_DICT_CONSTRUCT_STORAGE]
 test rax,rax
 jz .construct_oom
 test rax,7
 jnz .construct_invalid_saved
 mov rax,[r13+NEBO_DICT_CONSTRUCT_HASH_MODE]
 cmp rax,NEBO_HASH_MODE_PROCESS_SEEDED
 ja .construct_invalid_saved
 cmp rax,NEBO_HASH_MODE_PROCESS_SEEDED
 jne .construct_count
 cmp qword [r13+NEBO_DICT_CONSTRUCT_SEED],0
 je .construct_invalid_saved
.construct_count:
 mov r15,[r13+NEBO_DICT_CONSTRUCT_COUNT]
 mov rax,r15
 shl rax,2
 mov rcx,r14
 imul rcx,NEBO_DICT_MAX_LOAD_NUMERATOR
 cmp rax,rcx
 ja .construct_limit
 cmp rbx,NEBO_DICT_CONSTRUCT_EMPTY
 jne .construct_allocated
 cmp r14,NEBO_DICT_MIN_CAPACITY
 jne .construct_invalid_saved
.construct_allocated:
 cmp rbx,NEBO_DICT_CONSTRUCT_FROM_ENTRIES
 je .construct_entries
 test r15,r15
 jnz .construct_invalid_saved
 cmp qword [r13+NEBO_DICT_CONSTRUCT_ENTRIES],0
 jne .construct_invalid_saved
 jmp .construct_init
.construct_entries:
 test r15,r15
 jz .construct_init
 mov rax,[r13+NEBO_DICT_CONSTRUCT_ENTRIES]
 test rax,rax
 jz .construct_invalid_saved
 test rax,7
 jnz .construct_invalid_saved
 xor ebx,ebx
.construct_unique_outer:
 cmp rbx,r15
 jae .construct_init
 mov rdx,rbx
 shl rdx,4
 mov rdx,[rax+rdx+NEBO_DICT_INPUT_ENTRY_KEY]
 lea rcx,[rbx+1]
.construct_unique_inner:
 cmp rcx,r15
 jae .construct_unique_next
 mov r10,rcx
 shl r10,4
 cmp rdx,[rax+r10+NEBO_DICT_INPUT_ENTRY_KEY]
 je .construct_duplicate
 inc rcx
 jmp .construct_unique_inner
.construct_unique_next:
 inc rbx
 jmp .construct_unique_outer
.construct_init:
 mov rdi,r12
 mov rsi,[r13+NEBO_DICT_CONSTRUCT_STORAGE]
 mov rdx,r14
 mov rcx,[r13+NEBO_DICT_CONSTRUCT_SEED]
 mov r8,[r13+NEBO_DICT_CONSTRUCT_HASH_MODE]
 call neboc_dict_init
 test eax,eax
 jnz .construct_done
 xor ebx,ebx
.construct_insert_loop:
 cmp rbx,r15
 jae .construct_ok
 mov rax,[r13+NEBO_DICT_CONSTRUCT_ENTRIES]
 mov r10,rbx
 shl r10,4
 mov rdi,r12
 mov rsi,[rax+r10+NEBO_DICT_INPUT_ENTRY_KEY]
 mov rdx,[rax+r10+NEBO_DICT_INPUT_ENTRY_VALUE]
 lea rcx,[rsp]
 lea r8,[rsp+8]
 call neboc_dict_insert
 test eax,eax
 jnz .construct_internal
 cmp qword [rsp+8],0
 jne .construct_internal
 inc rbx
 jmp .construct_insert_loop
.construct_ok:
 xor eax,eax
 jmp .construct_done
.construct_duplicate:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .construct_done
.construct_internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .construct_done
.construct_type:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .construct_done
.construct_oom:
 mov eax,NEBOC_STATUS_OUT_OF_MEMORY
 jmp .construct_done
.construct_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .construct_done
.construct_invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.construct_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.construct_invalid:
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
 call neboc_dict_validate
 test eax,eax
 jnz .ins_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .ins_borrowed
 mov rax,NEBO_DICT_GENERATION_MASK
 cmp [r12+NEBO_DICT_GENERATION],rax
 jae .ins_full
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 call dict_commit_probed_slot
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

; Shared commit for an authenticated probe. Both insert and exclusive Entry
; write use this leaf; hashing/probing is never repeated by an Entry update.
; R12 descriptor, R13 key, R14 value, R15 old output, RBP had-old output;
; RAX slot, RDX found, RCX probe count, R8 hash. Caller validated the generation.
dict_commit_probed_slot:
 test rax,rax
 jz .full
 test edx,edx
 jnz .update
 mov r9,[r12+NEBO_DICT_LENGTH]
 inc r9
 mov r10,r9
 shl r10,2
 mov r11,[r12+NEBO_DICT_CAPACITY]
 imul r11,3
 cmp r10,r11
 ja .full
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_TOMBSTONE
 jne .new
 dec qword [r12+NEBO_DICT_TOMBSTONES]
.new:
 mov qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 mov [rax+NEBO_DICT_SLOT_HASH],r8
 mov [rax+NEBO_DICT_SLOT_KEY],r13
 mov [rax+NEBO_DICT_SLOT_VALUE],r14
 mov [r12+NEBO_DICT_LENGTH],r9
 mov qword [rbp],0
 cmp rcx,[r12+NEBO_DICT_MAX_PROBE]
 cmova rdx,rcx
 jbe .generation
 mov [r12+NEBO_DICT_MAX_PROBE],rcx
.generation:
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .done
.update:
 mov r9,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r15],r9
 mov qword [rbp],1
 mov [rax+NEBO_DICT_SLOT_VALUE],r14
 inc qword [r12+NEBO_DICT_GENERATION]
 xor eax,eax
 jmp .done
.full:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 ret

; entry_commit(reference*, value, old_out*, had_old*). The private reference
; carries one native probe under an exclusive generation-bound borrow.
NEBOC_ABI_FUNCTION neboc_dict_entry_commit
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov [rsp],rdi
 mov r14,rsi
 mov r15,rdx
 mov rbp,rcx
 cmp qword [rdi+NEBO_DICT_VIEW_KIND],5
 jne .stale
 cmp qword [rdi+NEBO_DICT_VIEW_RELEASED],0
 jne .stale
 mov r12,[rdi+NEBO_DICT_VIEW_OWNER]
 mov rdi,r12
 call neboc_dict_validate
 test eax,eax
 jnz .done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0xffffffff
 jne .stale
 mov r11,[rsp]
 mov rax,[r12+NEBO_DICT_GENERATION]
 cmp rax,[r11+NEBO_DICT_VIEW_GENERATION]
 jne .stale
 mov rdx,NEBO_DICT_GENERATION_MASK
 cmp rax,rdx
 jae .limit
 mov rax,[r11+NEBO_DICT_VIEW_INDEX]
 sub rax,NEBO_DICT_SLOT_VALUE
 mov rdx,rax
 sub rdx,[r12+NEBO_DICT_STORAGE]
 jc .stale
 test rdx,NEBO_DICT_U64_SLOT_SIZE-1
 jnz .stale
 mov rcx,[r12+NEBO_DICT_CAPACITY]
 shl rcx,5
 cmp rdx,rcx
 jae .stale
 mov r13,[r11+56]
 mov r8,[r11+32]
 mov rcx,[r11+40]
 test rcx,rcx
 jz .stale
 cmp rcx,[r12+NEBO_DICT_CAPACITY]
 ja .stale
 xor edx,edx
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .commit
 cmp [rax+NEBO_DICT_SLOT_KEY],r13
 jne .stale
 cmp [rax+NEBO_DICT_SLOT_HASH],r8
 jne .stale
 mov edx,1
.commit:
 call dict_commit_probed_slot
 test eax,eax
 jnz .done
 mov r11,[rsp]
 mov rdx,[r12+NEBO_DICT_GENERATION]
 mov [r11+NEBO_DICT_VIEW_GENERATION],rdx
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.invalid:
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
 call neboc_dict_validate
 test eax,eax
 jnz .get_done
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test edx,edx
 jz .get_missing
 mov r9,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r14],r9
 mov qword [r15],1
 jmp .get_ok
.get_missing:
 mov qword [r15],0
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

; contains_checked(desc*, key, out_bool*) -> Status.
NEBOC_ABI_FUNCTION neboc_dict_contains_checked
 test rdx,rdx
 jz .contains_checked_invalid
 push r12
 push r13
 push r14
 push rbp
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_dict_validate
 test eax,eax
 jnz .contains_checked_done
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 mov [r14],rdx
 xor eax,eax
.contains_checked_done:
 add rsp,8
 pop rbp
 pop r14
 pop r13
 pop r12
 ret
.contains_checked_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; get_or(desc*, key, default_value, out_value*, used_default*) -> Status.
NEBOC_ABI_FUNCTION neboc_dict_get_or
 test rcx,rcx
 jz .get_or_invalid
 test r8,r8
 jz .get_or_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 call neboc_dict_validate
 test eax,eax
 jnz .get_or_done
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test edx,edx
 jz .get_or_default
 mov rax,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r15],rax
 mov r8,[rsp]
 mov qword [r8],0
 jmp .get_or_ok
.get_or_default:
 mov [r15],r14
 mov r8,[rsp]
 mov qword [r8],1
.get_or_ok:
 xor eax,eax
.get_or_done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.get_or_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; entry_snapshot(desc*, key, key_out*, value_out*, found*) returns copies only.
NEBOC_ABI_FUNCTION neboc_dict_entry_snapshot
 test rdx,rdx
 jz .entry_invalid
 test rcx,rcx
 jz .entry_invalid
 test r8,r8
 jz .entry_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 call neboc_dict_validate
 test eax,eax
 jnz .entry_done
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 mov r8,[rsp]
 test edx,edx
 jz .entry_missing
 mov [r14],r13
 mov rax,[rax+NEBO_DICT_SLOT_VALUE]
 mov [r15],rax
 mov qword [r8],1
 jmp .entry_ok
.entry_missing:
 mov qword [r8],0
.entry_ok:
 xor eax,eax
.entry_done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.entry_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
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
 call neboc_dict_validate
 test eax,eax
 jnz .rem_done
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .rem_borrowed
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test edx,edx
 jz .rem_missing
 mov r10,NEBO_DICT_GENERATION_MASK
 cmp [r12+NEBO_DICT_GENERATION],r10
 jae .rem_limit
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
 jmp .rem_ok
.rem_missing:
 mov qword [r15],0
.rem_ok:
 xor eax,eax
 jmp .rem_done
.rem_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .rem_done
.rem_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
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
 mov rax,[r12+NEBO_DICT_LENGTH]
 or rax,[r12+NEBO_DICT_TOMBSTONES]
 jz .clear_ok
 mov rax,NEBO_DICT_GENERATION_MASK
 cmp [r12+NEBO_DICT_GENERATION],rax
 jae .clear_limit
 mov rdi,[r12+NEBO_DICT_STORAGE]
 mov rcx,[r12+NEBO_DICT_CAPACITY]
 shl rcx,2
 xor eax,eax
 rep stosq
 mov qword [r12+NEBO_DICT_LENGTH],0
 mov qword [r12+NEBO_DICT_TOMBSTONES],0
 mov qword [r12+NEBO_DICT_MAX_PROBE],0
 inc qword [r12+NEBO_DICT_GENERATION]
.clear_ok:
 xor eax,eax
 jmp .clear_done
.clear_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .clear_done
.clear_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
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
 mov rax,NEBO_DICT_GENERATION_MASK
 cmp [r12+NEBO_DICT_GENERATION],rax
 jae .rehash_limit_saved
 cmp qword [r12+NEBO_DICT_HASH_MODE],NEBO_HASH_MODE_PROCESS_SEEDED
 jne .rehash_seed_ok
 test r15,r15
 jz .rehash_invalid_saved
.rehash_seed_ok:
 mov rax,[r12+NEBO_DICT_STORAGE]
 mov rcx,[r12+NEBO_DICT_CAPACITY]
 shl rcx,5
 add rcx,rax
 jc .rehash_invalid_saved
 mov rdx,r14
 shl rdx,5
 add rdx,r13
 jc .rehash_invalid_saved
 cmp r13,rcx
 jae .rehash_nonoverlap
 cmp rax,rdx
 jae .rehash_nonoverlap
 jmp .rehash_invalid_saved
.rehash_nonoverlap:
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
 jmp .rehash_done
.rehash_limit_saved:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .rehash_done
.rehash_invalid_saved:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
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

; retain(desc*, predicate(key, value) -> Bool). Evaluate each occupied entry
; exactly once under an exclusive borrow, then commit removals through the
; canonical mutation owner. A bad Bool or exhausted generation leaves the
; dictionary unchanged. The public bounded layout has at most 64 buckets.
NEBOC_ABI_FUNCTION neboc_dict_retain
 test rsi,rsi
 jz .retain_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 call neboc_dict_validate
 test eax,eax
 jnz .retain_done
 cmp qword [r12+NEBO_DICT_CAPACITY],64
 ja .retain_limit
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .retain_borrowed
 mov dword [r12+NEBO_DICT_BORROW_COUNT],0xffffffff
 xor r14d,r14d
 xor r15d,r15d
 xor ebp,ebp
.retain_scan:
 cmp r14,[r12+NEBO_DICT_CAPACITY]
 jae .retain_evaluated
 mov rax,r14
 shl rax,5
 add rax,[r12+NEBO_DICT_STORAGE]
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .retain_next
 mov rdi,[rax+NEBO_DICT_SLOT_KEY]
 mov rsi,[rax+NEBO_DICT_SLOT_VALUE]
 call r13
 cmp rax,1
 ja .retain_bad_bool
 test eax,eax
 jnz .retain_next
 bts r15,r14
 inc rbp
.retain_next:
 inc r14
 jmp .retain_scan
.retain_evaluated:
 mov dword [r12+NEBO_DICT_BORROW_COUNT],0
 mov rax,[r12+NEBO_DICT_GENERATION]
 add rax,rbp
 jc .retain_limit
 mov rdx,NEBO_DICT_GENERATION_MASK
 cmp rax,rdx
 ja .retain_limit
 xor r14d,r14d
.retain_commit:
 cmp r14,[r12+NEBO_DICT_CAPACITY]
 jae .retain_ok
 bt r15,r14
 jnc .retain_commit_next
 mov rax,r14
 shl rax,5
 add rax,[r12+NEBO_DICT_STORAGE]
 mov rsi,[rax+NEBO_DICT_SLOT_KEY]
 mov rdi,r12
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_dict_remove
 test eax,eax
 jnz .retain_done
.retain_commit_next:
 inc r14
 jmp .retain_commit
.retain_bad_bool:
 mov dword [r12+NEBO_DICT_BORROW_COUNT],0
.retain_borrowed:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .retain_done
.retain_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .retain_done
.retain_ok:
 xor eax,eax
.retain_done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.retain_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
