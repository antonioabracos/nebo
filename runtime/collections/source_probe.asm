; G008 source-to-effect probe. Source-derived subgroup and seed values reach
; the real bounded hashing, Dict, view, Set and collision owners.
bits 64
default rel
%include "compiler/semantic/collections/hash_map_contract.inc"

extern neboc_hasher_init
extern neboc_hasher_write_bytes
extern neboc_hasher_finish
extern neboc_hash_u64
extern neboc_dict_init
extern neboc_dict_validate
extern neboc_dict_insert
extern neboc_dict_get
extern neboc_dict_contains
extern neboc_dict_entry_snapshot
extern neboc_dict_remove
extern neboc_dict_clear
extern neboc_dict_rehash
extern neboc_dict_view_init
extern neboc_dict_view_next
extern neboc_dict_view_release
extern neboc_set_init
extern neboc_set_insert
extern neboc_set_contains
extern neboc_set_remove
extern neboc_set_union
extern neboc_set_intersection
extern neboc_set_difference
extern neboc_set_subset
extern neboc_dict_validate_invariants
extern neboc_dict_collision_count
extern neboc_dict_max_probe_length

%define P_HASHER 0
%define P_DICT_A 64
%define P_DICT_B 176
%define P_DICT_C 288
%define P_STORE_A 512
%define P_STORE_B 768
%define P_STORE_C 1280
%define P_VIEW 1536
%define P_OUT_A 1600
%define P_OUT_B 1608
%define P_OUT_C 1616
%define P_OUT_D 1624

section .text
global nebo_g008_source_probe
nebo_g008_source_probe:
 push rbx
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 sub rsp,2048
 cmp r12d,1
 je .hash
 cmp r12d,2
 je .construction
 cmp r12d,3
 je .mutation
 cmp r12d,4
 je .views
 cmp r12d,5
 je .sets
 cmp r12d,6
 je .security
 jmp .failure

.hash:
 lea rdi,[rsp+P_HASHER]
 mov esi,r13d
 mov edx,NEBO_HASH_MODE_DETERMINISTIC
 xor ecx,ecx
 call neboc_hasher_init
 test eax,eax
 jnz .failure
 mov [rsp+P_OUT_A],r13
 lea rdi,[rsp+P_HASHER]
 lea rsi,[rsp+P_OUT_A]
 mov edx,8
 call neboc_hasher_write_bytes
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_HASHER]
 call neboc_hasher_finish
 test rax,rax
 jz .failure
 mov edi,r13d
 mov esi,r13d
 call neboc_hash_u64
 test rax,rax
 jz .failure
 jmp .success

.construction:
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_STORE_A]
 mov edx,NEBO_DICT_MIN_CAPACITY
 mov ecx,r13d
 mov r8d,NEBO_HASH_MODE_DETERMINISTIC
 call neboc_dict_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_validate
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_DICT_A+NEBO_DICT_LENGTH],0
 jne .failure
 cmp qword [rsp+P_DICT_A+NEBO_DICT_CAPACITY],NEBO_DICT_MIN_CAPACITY
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_STORE_B]
 mov edx,16
 mov ecx,r13d
 call neboc_dict_rehash
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_DICT_A+NEBO_DICT_CAPACITY],16
 jne .failure
 jmp .success

.mutation:
 call .init_a
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea edx,[r13d+7]
 lea rcx,[rsp+P_OUT_A]
 lea r8,[rsp+P_OUT_B]
 call neboc_dict_insert
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_B],0
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_C]
 lea rcx,[rsp+P_OUT_D]
 call neboc_dict_get
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_D],1
 jne .failure
 lea eax,[r13d+7]
 cmp [rsp+P_OUT_C],rax
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 call neboc_dict_contains
 cmp eax,1
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 lea r8,[rsp+P_OUT_D]
 call neboc_dict_entry_snapshot
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_D],1
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 lea rcx,[rsp+P_OUT_B]
 call neboc_dict_remove
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_B],1
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_clear
 test eax,eax
 jnz .failure
 jmp .success

.views:
 call .init_a
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea edx,[r13d+3]
 lea rcx,[rsp+P_OUT_A]
 lea r8,[rsp+P_OUT_B]
 call neboc_dict_insert
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_VIEW]
 xor eax,eax
 mov ecx,NEBO_DICT_ITERATOR_SIZE/8
 rep stosq
 lea rdi,[rsp+P_VIEW]
 lea rsi,[rsp+P_DICT_A]
 mov edx,NEBO_DICT_VIEW_ENTRIES
 call neboc_dict_view_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_VIEW]
 lea rsi,[rsp+P_OUT_A]
 lea rdx,[rsp+P_OUT_B]
 lea rcx,[rsp+P_OUT_C]
 call neboc_dict_view_next
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_C],1
 jne .failure
 mov eax,r13d
 cmp [rsp+P_OUT_A],rax
 jne .failure
 lea rdi,[rsp+P_VIEW]
 call neboc_dict_view_release
 test eax,eax
 jnz .failure
 jmp .success

.sets:
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_STORE_A]
 mov edx,8
 mov ecx,r13d
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_B]
 lea rsi,[rsp+P_STORE_B]
 mov edx,8
 mov ecx,r13d
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_C]
 lea rsi,[rsp+P_STORE_C]
 mov edx,8
 mov ecx,r13d
 xor r8d,r8d
 call neboc_set_init
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_set_insert
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_B]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_set_insert
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_DICT_B]
 lea rdx,[rsp+P_DICT_C]
 call neboc_set_union
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_C]
 mov esi,r13d
 call neboc_set_contains
 cmp eax,1
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_DICT_C]
 lea rdx,[rsp+P_OUT_A]
 call neboc_set_subset
 test eax,eax
 jnz .failure
 cmp qword [rsp+P_OUT_A],1
 jne .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea rdx,[rsp+P_OUT_A]
 call neboc_set_remove
 test eax,eax
 jnz .failure
 jmp .success

.security:
 call .init_a
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 mov esi,r13d
 lea edx,[r13d+9]
 lea rcx,[rsp+P_OUT_A]
 lea r8,[rsp+P_OUT_B]
 call neboc_dict_insert
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_collision_count
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_max_probe_length
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 lea rsi,[rsp+P_STORE_B]
 mov edx,8
 lea ecx,[r13d+1]
 call neboc_dict_rehash
 test eax,eax
 jnz .failure
 lea rdi,[rsp+P_DICT_A]
 call neboc_dict_validate_invariants
 test eax,eax
 jnz .failure
 ; Process-seeded construction is separate from deterministic replay.
 lea rdi,[rsp+P_DICT_B]
 lea rsi,[rsp+P_STORE_A]
 mov edx,8
 mov ecx,r13d
 mov r8d,NEBO_HASH_MODE_PROCESS_SEEDED
 call neboc_dict_init
 test eax,eax
 jnz .failure
 jmp .success

.init_a:
 sub rsp,8
 lea rdi,[rsp+P_DICT_A+16]
 lea rsi,[rsp+P_STORE_A+16]
 ; Account for the return address and keep external calls ABI-aligned.
 mov edx,8
 mov ecx,r13d
 xor r8d,r8d
 call neboc_dict_init
 add rsp,8
 ret

.success:
 mov eax,r13d
 jmp .done
.failure:
 mov eax,111
.done:
 add rsp,2048
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
