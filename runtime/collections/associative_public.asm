; Public typed-expression ABI adapter. Hashing, bucket initialization and all
; associative mutations delegate to the canonical native Dict/Set owners.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_validate
extern nebo_tagged_public_sret
extern neboc_dict_construct
extern neboc_dict_validate
extern neboc_dict_probe
extern neboc_dict_insert
extern neboc_dict_remove
extern neboc_dict_clear
extern neboc_dict_contains_checked
extern neboc_set_insert
extern neboc_set_remove
extern neboc_set_union
extern neboc_set_intersection
extern neboc_set_difference
extern neboc_set_subset
extern neboc_dict_rehash
extern neboc_dict_validate_invariants
extern neboc_dict_collision_count
extern neboc_dict_max_probe_length
extern neboc_dict_view_init
extern neboc_dict_view_next
extern neboc_dict_view_release
extern neboc_hasher_init
extern neboc_hasher_write_bytes
extern neboc_hasher_finish
extern neboc_dict_entry_commit
extern neboc_dict_retain
extern nebo_runtime_trap
extern nebo_runtime_hash_observe
extern nebo_sequential_call
extern nebo_relational_call
extern nebo_data_call

section .bss
align 8
associative_hash_mode: resq 1
associative_hash_seed: resq 1

section .rodata
iteration_order_bytes: db 'unspecified'
align 8
iteration_order_text:
 dq iteration_order_bytes,11
 dd 0
 dw 1,1

section .text
; Return an owned collection into caller storage before the callee frame is
; reclaimed. Native validators remain authoritative for both layouts. Payload
; bytes are copied and descriptor pointers rebound; no pointer into the
; returning function survives. Active views cannot cross this ownership edge.
; RDI destination (4256 bytes), RSI source, EDX layout kind 32/33/34.
NEBOC_ABI_FUNCTION nebo_collection_public_sret
 cmp edx,35000
 jae nebo_tagged_public_sret
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13d,edx
 mov rdi,rsi
 cmp r13d,32
 je .list_validate
 cmp r13d,34
 ja .bad
 cmp r13d,33
 jb .bad
 call neboc_dict_validate
 test eax,eax
 jnz .bad
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .bad
 mov rdi,rbx
 xor eax,eax
 mov ecx,4256/8
 rep stosq
 mov rdi,rbx
 mov rsi,r12
 mov ecx,NEBO_DICT_SIZE/8
 rep movsq
 lea rdi,[rbx+NEBO_DICT_SIZE]
 mov [rbx+NEBO_DICT_STORAGE],rdi
 mov rsi,[r12+NEBO_DICT_STORAGE]
 mov rcx,[r12+NEBO_DICT_CAPACITY]
 shl rcx,2
 rep movsq
 jmp .ok
.list_validate:
 call neboc_list_validate
 test eax,eax
 jnz .bad
 cmp qword [r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET],8
 jne .bad
 cmp qword [r12+NEBOC_LIST_CAPACITY_OFFSET],16
 ja .bad
 bt qword [r12+NEBOC_LIST_GENERATION_OFFSET],63
 jc .bad
 mov rdi,rbx
 xor eax,eax
 mov ecx,4256/8
 rep stosq
 mov rdi,rbx
 mov rsi,r12
 mov ecx,NEBOC_LIST_QWORDS
 rep movsq
 lea rdi,[rbx+80]
 mov [rbx+NEBOC_LIST_DATA_OFFSET],rdi
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 rep movsq
.ok:
 mov rdx,rbx
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

; operation, receiver, argument1, argument2, caller-owned result storage -> RAX.
; Caller storage lasts for the lexical function frame; no heap or hidden seed.
NEBOC_ABI_FUNCTION nebo_associative_call
 cmp edi,300
 jae nebo_data_call
 cmp edi,200
 jae nebo_relational_call
 cmp edi,100
 jae nebo_sequential_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,57
 je .hash_deterministic
 cmp ebx,58
 je .hash_randomized
 cmp ebx,69
 je .sorted_at
 cmp ebx,70
 je .sorted_length
 cmp ebx,59
 je .view_auto_release
 cmp ebx,65
 je .view_auto_release
 cmp ebx,60
 je .view_slot_init
 cmp ebx,62
 je .unique_ref
 cmp ebx,63
 je .unique_ref
 cmp ebx,64
 je .unique_ref
 cmp ebx,50
 je .hasher_new
 cmp ebx,51
 je .hasher_write
 cmp ebx,52
 je .hasher_finish
 cmp ebx,53
 je .int_equals
 cmp ebx,54
 je .int_feed_hash
 cmp ebx,55
 je .int_hash_stable
 cmp ebx,2
 jbe .new
 cmp ebx,15
 je .new
 cmp ebx,16
 je .new
 cmp ebx,26
 je .release
 cmp ebx,40
 je .view_next
 cmp ebx,43
 je .view_next
 cmp ebx,41
 je .view_release
 cmp ebx,44
 je .pair_expect
 cmp ebx,45
 je .pair_at
 cmp ebx,46
 je .pair_length
 cmp ebx,47
 je .pair_is_some
 cmp ebx,48
 je .pair_is_none
 cmp ebx,21
 je .is_moved
 cmp ebx,11
 jb .dictionary
 cmp ebx,14
 jbe .option
 cmp ebx,27
 jb .dictionary
 cmp ebx,30
 jbe .option
.dictionary:
 mov rdi,r12
 call neboc_dict_validate
 test eax,eax
 jnz .trap
 cmp ebx,3
 je .length
 cmp ebx,4
 je .capacity
 cmp ebx,5
 je .insert
 cmp ebx,6
 je .get
 cmp ebx,7
 je .contains
 cmp ebx,8
 je .remove
 cmp ebx,9
 je .clear
 cmp ebx,17
 je .set_insert
 cmp ebx,18
 je .set_remove
 cmp ebx,19
 je .move
 cmp ebx,20
 je .drop
 cmp ebx,22
 jb .trap
 cmp ebx,24
 jbe .set_algebra
 cmp ebx,25
 je .subset
 cmp ebx,31
 je .reserve
 cmp ebx,33
 je .invariants
 cmp ebx,34
 je .collisions
 cmp ebx,35
 je .max_probe
 cmp ebx,37
 je .load_factor
 cmp ebx,38
 je .view_init
 cmp ebx,39
 je .view_init
 cmp ebx,42
 je .view_init
 cmp ebx,56
 je .reseed
 cmp ebx,61
 je .get_mutable
 cmp ebx,66
 je .get_mutable
 cmp ebx,67
 je .retain
 cmp ebx,68
 je .sorted_entries
 cmp ebx,71
 je .iteration_order
 jmp .trap
.retain:
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_retain
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.iteration_order:
 lea rax,[rel iteration_order_text]
 jmp .done
.sorted_at:
 cmp r13,[r12]
 jae .trap
 shl r13,4
 lea rax,[r12+r13+8]
 jmp .done
.sorted_length:
 mov rax,[r12]
 jmp .done
.sorted_entries:
 ; Copy through the canonical generation-bound native entries view. Sorting
 ; owns its distinct caller buffer and never changes Dict bucket order.
 lea r13,[r15+784]
 mov rdi,r13
 mov ecx,NEBO_DICT_ITERATOR_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,r13
 mov rsi,r12
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz .trap
 xor r14d,r14d
.sorted_collect:
 cmp r14,NEBO_DICT_MAX_CAPACITY*3/4
 ja .trap
 mov rsi,r14
 shl rsi,4
 lea rsi,[r15+rsi+8]
 lea rdx,[rsi+8]
 mov rcx,rsp
 mov rdi,r13
 call neboc_dict_view_next
 test eax,eax
 jnz .trap
 cmp qword [rsp],0
 je .sorted_collected
 inc r14
 jmp .sorted_collect
.sorted_collected:
 mov [r15],r14
 mov rdi,r13
 call neboc_dict_view_release
 test eax,eax
 jnz .trap
 mov r8d,1
.sort_outer:
 cmp r8,r14
 jae .sorted_done
 mov rax,r8
 shl rax,4
 mov r10,[r15+rax+8]
 mov r11,[r15+rax+16]
 mov r9,r8
.sort_inner:
 test r9,r9
 jz .sort_store
 lea rax,[r9-1]
 shl rax,4
 mov rdx,[r15+rax+8]
 cmp rdx,r10
 jle .sort_store
 mov rcx,[r15+rax+16]
 mov [r15+rax+24],rdx
 mov [r15+rax+32],rcx
 dec r9
 jmp .sort_inner
.sort_store:
 mov rax,r9
 shl rax,4
 mov [r15+rax+8],r10
 mov [r15+rax+16],r11
 inc r8
 jmp .sort_outer
.sorted_done:
 mov rax,r15
 jmp .done
.hasher_new:
 mov rdi,r15
 mov rsi,r13
 mov rdx,[rel associative_hash_mode]
 xor ecx,ecx
 test rdx,rdx
 jz .hasher_seed_ready
 mov rcx,[rel associative_hash_seed]
.hasher_seed_ready:
 call neboc_hasher_init
 jmp .option_result
.hasher_write:
 mov rdi,r12
 mov rsi,[r13]
 mov rdx,[r13+8]
 call neboc_hasher_write_bytes
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.hasher_finish:
 mov rdi,r12
 call neboc_hasher_finish
 mov [rsp+64],rax
 mov rdx,rax
 mov rsi,[r12+8]
 mov edi,52
 call nebo_runtime_hash_observe
 mov rax,[rsp+64]
 jmp .done
.hash_deterministic:
 mov qword [rel associative_hash_mode],0
 mov [rel associative_hash_seed],r13
 jmp .hash_policy_observe
.hash_randomized:
 ; Explicit policy selection obtains its own process seed. No constructor
 ; reads entropy implicitly, and no seed enters compilation or linking.
 mov r14d,2
.random_retry:
 mov eax,318
 mov rdi,rsp
 mov esi,8
 xor edx,edx
 syscall
 cmp rax,-4
 jne .random_result
 dec r14d
 jnz .random_retry
.random_result:
 cmp rax,8
 jne .trap
 mov rax,[rsp]
 test rax,rax
 jz .trap
 mov [rel associative_hash_seed],rax
 mov qword [rel associative_hash_mode],1
.hash_policy_observe:
 mov rdi,rbx
 mov rsi,[rel associative_hash_mode]
 mov rdx,[rel associative_hash_seed]
 call nebo_runtime_hash_observe
 xor eax,eax
 jmp .done
.int_equals:
 xor eax,eax
 cmp r12,r13
 sete al
 jmp .done
.int_hash_stable:
 ; The selected exact Int encoding and versioned FNV algorithm are stable
 ; for the same explicit seed; this does not describe randomized instances.
 mov eax,1
 jmp .done
.int_feed_hash:
 mov [rsp],r12
 mov rdi,r13
 mov rsi,rsp
 mov edx,8
 call neboc_hasher_write_bytes
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.reseed:
 mov rdi,r12
 mov rsi,r15
 cmp rsi,[r12+NEBO_DICT_STORAGE]
 jne .reseed_storage_ready
 add rsi,NEBO_DICT_MAX_CAPACITY*NEBO_DICT_U64_SLOT_SIZE
.reseed_storage_ready:
 mov rdx,[r12+NEBO_DICT_CAPACITY]
 mov rcx,0x9e3779b97f4a7c15
 add rcx,[r12+NEBO_DICT_SEED]
 call neboc_dict_rehash
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.view_init:
 mov rdi,r15
 mov ecx,NEBO_DICT_ITERATOR_SIZE/8
 xor eax,eax
 rep stosq
 mov rdi,r15
 mov rsi,r12
 lea edx,[ebx-37]
 cmp ebx,42
 jne .view_kind_ready
 mov edx,NEBO_DICT_VIEW_ENTRIES
.view_kind_ready:
 call neboc_dict_view_init
 jmp .option_result
.view_next:
 mov qword [r15],0
 mov qword [r15+8],0
 mov rdi,r12
 lea rsi,[r15+8]
 lea rdx,[r15+16]
 mov rcx,r15
 call neboc_dict_view_next
 test eax,eax
 jnz .trap
 cmp qword [r12+NEBO_DICT_VIEW_KIND],NEBO_DICT_VIEW_VALUES
 jne .view_result
 mov rax,[r15+16]
 mov [r15+8],rax
.view_result:
 mov rax,r15
 jmp .done
.view_release:
 mov rdi,r12
 call neboc_dict_view_release
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.view_slot_init:
 mov qword [r12+NEBO_DICT_VIEW_RELEASED],1
 xor eax,eax
 jmp .done
.view_auto_release:
 cmp qword [r12+NEBO_DICT_VIEW_RELEASED],0
 jne .view_already_released
 cmp qword [r12+NEBO_DICT_VIEW_KIND],4
 jb .view_release
 mov ebx,64
 jmp .unique_ref
.view_already_released:
 xor eax,eax
 jmp .done
.get_mutable:
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .trap
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test rax,rax
 jz .trap
 cmp ebx,66
 je .unique_probe_ready
 test rdx,rdx
 jz .trap
.unique_probe_ready:
 mov [r15+56],r13
 mov [rsp+72],rcx
 lea r13,[rax+NEBO_DICT_SLOT_VALUE]
 mov rdi,r15
 mov ecx,NEBO_DICT_ITERATOR_SIZE/8
 xor eax,eax
 rep stosq
 mov [r15+NEBO_DICT_VIEW_OWNER],r12
 mov [r15+NEBO_DICT_VIEW_INDEX],r13
 mov rax,[r12+NEBO_DICT_GENERATION]
 mov [r15+NEBO_DICT_VIEW_GENERATION],rax
 mov qword [r15+NEBO_DICT_VIEW_KIND],4
 cmp ebx,66
 jne .unique_initialized
 mov qword [r15+NEBO_DICT_VIEW_KIND],5
 mov [r15+32],r8
 mov rax,[rsp+72]
 mov [r15+40],rax
.unique_initialized:
 mov dword [r12+NEBO_DICT_BORROW_COUNT],0xffffffff
 mov rax,r15
 jmp .done
.unique_ref:
 cmp qword [r12+NEBO_DICT_VIEW_RELEASED],0
 jne .trap
 cmp qword [r12+NEBO_DICT_VIEW_KIND],4
 jb .trap
 cmp qword [r12+NEBO_DICT_VIEW_KIND],5
 ja .trap
 mov r14,[r12+NEBO_DICT_VIEW_OWNER]
 mov rdi,r14
 call neboc_dict_validate
 test eax,eax
 jnz .trap
 cmp dword [r14+NEBO_DICT_BORROW_COUNT],0xffffffff
 jne .trap
 mov rax,[r14+NEBO_DICT_GENERATION]
 cmp rax,[r12+NEBO_DICT_VIEW_GENERATION]
 jne .trap
 cmp ebx,64
 je .unique_release
 mov rdx,[r12+NEBO_DICT_VIEW_INDEX]
 cmp ebx,62
 je .unique_read
 cmp qword [r12+NEBO_DICT_VIEW_KIND],5
 je .entry_write
 mov rax,NEBO_DICT_GENERATION_MASK
 cmp [r14+NEBO_DICT_GENERATION],rax
 jae .trap
 mov [rdx],r13
 inc qword [r14+NEBO_DICT_GENERATION]
 mov rax,[r14+NEBO_DICT_GENERATION]
 mov [r12+NEBO_DICT_VIEW_GENERATION],rax
 xor eax,eax
 jmp .done
.unique_read:
 cmp qword [rdx-NEBO_DICT_SLOT_VALUE+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .trap
 mov rax,[rdx]
 jmp .done
.entry_write:
 mov rdi,r12
 mov rsi,r13
 mov rdx,rsp
 lea rcx,[rsp+8]
 call neboc_dict_entry_commit
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.unique_release:
 mov dword [r14+NEBO_DICT_BORROW_COUNT],0
 mov qword [r12+NEBO_DICT_VIEW_RELEASED],1
 xor eax,eax
 jmp .done
.pair_expect:
 cmp qword [r12],1
 jne .trap
 lea rax,[r12+8]
 jmp .done
.pair_is_some:
 mov rax,[r12]
 cmp rax,1
 ja .trap
 jmp .done
.pair_is_none:
 mov rax,[r12]
 cmp rax,1
 ja .trap
 xor eax,1
 jmp .done
.pair_at:
 cmp r13,2
 jae .trap
 mov rax,[r12+r13*8]
 jmp .done
.pair_length:
 mov eax,2
 jmp .done
.set_algebra:
 mov rdi,rsp
 mov ecx,NEBO_DICT_CONSTRUCT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[r15+NEBO_DICT_SIZE]
 mov [rsp+NEBO_DICT_CONSTRUCT_STORAGE],rax
 mov qword [rsp+NEBO_DICT_CONSTRUCT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 mov qword [rsp+NEBO_DICT_CONSTRUCT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 mov qword [rsp+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_WITH_CAPACITY
 mov qword [rsp+NEBO_DICT_CONSTRUCT_CAPACITY],NEBO_DICT_MAX_CAPACITY
 mov rax,[rel associative_hash_seed]
 mov [rsp+NEBO_DICT_CONSTRUCT_SEED],rax
 mov rax,[rel associative_hash_mode]
 mov [rsp+NEBO_DICT_CONSTRUCT_HASH_MODE],rax
 mov rdi,r15
 mov rsi,rsp
 call neboc_dict_construct
 test eax,eax
 jnz .trap
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 cmp ebx,22
 je .union
 cmp ebx,23
 je .intersection
 call neboc_set_difference
 jmp .option_result
.union:
 call neboc_set_union
 jmp .option_result
.intersection:
 call neboc_set_intersection
 jmp .option_result
.subset:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call neboc_set_subset
 jmp .scalar_result
.reserve:
 test r13,r13
 js .trap
 mov rax,[r12+NEBO_DICT_LENGTH]
 add rax,r13
 jc .trap
 cmp rax,NEBO_DICT_MAX_CAPACITY*3/4
 ja .trap
 shl rax,2
 mov rdx,[r12+NEBO_DICT_CAPACITY]
.grow:
 lea rcx,[rdx+rdx*2]
 cmp rax,rcx
 jbe .growth_ready
 shl rdx,1
 jmp .grow
.growth_ready:
 cmp rdx,[r12+NEBO_DICT_CAPACITY]
 je .reserve_done
 mov rsi,r15
 cmp rsi,[r12+NEBO_DICT_STORAGE]
 jne .scratch_ready
 add rsi,NEBO_DICT_MAX_CAPACITY*NEBO_DICT_U64_SLOT_SIZE
.scratch_ready:
 mov rdi,r12
 mov rcx,[r12+NEBO_DICT_SEED]
 call neboc_dict_rehash
 test eax,eax
 jnz .trap
.reserve_done:
 xor eax,eax
 jmp .done
.invariants:
 mov rdi,r12
 call neboc_dict_validate_invariants
 test eax,eax
 jnz .trap
 mov eax,1
 jmp .done
.collisions:
 mov rdi,r12
 call neboc_dict_collision_count
 jmp .done
.load_factor:
 cvtsi2sd xmm0,qword [r12+NEBO_DICT_LENGTH]
 cvtsi2sd xmm1,qword [r12+NEBO_DICT_CAPACITY]
 divsd xmm0,xmm1
 movq rax,xmm0
 jmp .done
.max_probe:
 mov rdi,r12
 call neboc_dict_max_probe_length
 jmp .done
.move:
 cmp dword [r12+NEBO_DICT_BORROW_COUNT],0
 jne .trap
 mov rdi,r15
 mov rsi,r12
 mov ecx,NEBO_DICT_SIZE/8
 rep movsq
 mov dword [r12+NEBO_DICT_MAGIC_OFFSET],0
 mov rax,r15
 jmp .done
.drop:
 mov rdi,r12
 call neboc_dict_clear
 test eax,eax
 jnz .trap
 mov dword [r12+NEBO_DICT_MAGIC_OFFSET],0
 xor eax,eax
 jmp .done
.is_moved:
 xor eax,eax
 cmp dword [r12+NEBO_DICT_MAGIC_OFFSET],0
 sete al
 jmp .done
.new:
 mov rdi,rsp
 mov ecx,NEBO_DICT_CONSTRUCT_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[r15+NEBO_DICT_SIZE]
 mov [rsp+NEBO_DICT_CONSTRUCT_STORAGE],rax
 mov qword [rsp+NEBO_DICT_CONSTRUCT_KEY_TYPE],NEBO_DICT_KEY_U64_EXACT
 mov qword [rsp+NEBO_DICT_CONSTRUCT_VALUE_TYPE],NEBO_DICT_VALUE_U64_TRIVIAL
 mov qword [rsp+NEBO_DICT_CONSTRUCT_CAPACITY],NEBO_DICT_MIN_CAPACITY
 cmp ebx,2
 jbe .construct
 mov qword [rsp+NEBO_DICT_CONSTRUCT_MODE],NEBO_DICT_CONSTRUCT_WITH_CAPACITY
 mov [rsp+NEBO_DICT_CONSTRUCT_CAPACITY],r13
.construct:
 mov rax,[rel associative_hash_seed]
 mov [rsp+NEBO_DICT_CONSTRUCT_SEED],rax
 mov rax,[rel associative_hash_mode]
 mov [rsp+NEBO_DICT_CONSTRUCT_HASH_MODE],rax
 mov rdi,r15
 mov rsi,rsp
 call neboc_dict_construct
 test eax,eax
 jnz .trap
 mov edi,1
 mov rsi,[r15+NEBO_DICT_HASH_MODE]
 mov rdx,[r15+NEBO_DICT_SEED]
 call nebo_runtime_hash_observe
 mov rax,r15
 jmp .done
.length:
 mov rax,[r12+NEBO_DICT_LENGTH]
 jmp .done
.capacity:
 mov rax,[r12+NEBO_DICT_CAPACITY]
 jmp .done
.insert:
 mov qword [r15],0
 mov qword [r15+8],0
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 lea rcx,[r15+8]
 mov r8,r15
 call neboc_dict_insert
 jmp .option_result
.remove:
 mov qword [r15],0
 mov qword [r15+8],0
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r15+8]
 mov rcx,r15
 call neboc_dict_remove
.option_result:
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.get:
 mov qword [r15+32],0
 mov qword [r15],0
 mov qword [r15+8],0
 mov [r15+16],r12
 mov rax,[r12+NEBO_DICT_GENERATION]
 mov [r15+24],rax
 mov rdi,r12
 mov rsi,r13
 call neboc_dict_probe
 test rdx,rdx
 jz .reference_ready
 mov qword [r15],1
 add rax,NEBO_DICT_SLOT_VALUE
 mov [r15+8],rax
.reference_ready:
 mov rax,r15
 jmp .done
.contains:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call neboc_dict_contains_checked
 jmp .scalar_result
.set_insert:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call neboc_set_insert
 jmp .scalar_result
.set_remove:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call neboc_set_remove
.scalar_result:
 test eax,eax
 jnz .trap
 mov rax,[r15]
 jmp .done
.clear:
 mov rdi,r12
 call neboc_dict_clear
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.release:
 cmp qword [r12+32],0
 jne .trap
 mov qword [r12+32],1
 xor eax,eax
 jmp .done
.option:
 cmp qword [r12],1
 ja .trap
 cmp ebx,27
 jb .option_owned
 cmp qword [r12+32],0
 jne .trap
 ; A reference contains an actual native value pointer. Its descriptor and
 ; generation are checked before observation; mutation cannot expose stale data.
 mov rdi,[r12+16]
 call neboc_dict_validate
 test eax,eax
 jnz .trap
 mov rax,[r12+16]
 mov rax,[rax+NEBO_DICT_GENERATION]
 cmp rax,[r12+24]
 jne .trap
 sub ebx,16
 mov r14d,1
 jmp .option_dispatch
.option_owned:
 xor r14d,r14d
.option_dispatch:
 mov rax,[r12]
 cmp ebx,11
 je .done
 cmp ebx,12
 je .is_none
 test rax,rax
 jnz .some
 cmp ebx,13
 jne .trap
 mov rax,r13
 jmp .done
.is_none:
 xor eax,1
 jmp .done
.some:
 mov rax,[r12+8]
 test r14,r14
 jz .done
 mov rax,[rax]
 jmp .done
.trap:
 mov edi,49
 call nebo_runtime_trap
 ud2
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
