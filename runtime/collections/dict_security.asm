; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-F06 bounded invariant and collision metrics.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_validate
extern neboc_hash_u64

section .text
NEBOC_ABI_FUNCTION neboc_dict_validate_invariants
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 call neboc_dict_validate
 test eax,eax
 jnz .done
 xor r13d,r13d
 xor r14d,r14d
 xor r15d,r15d
 mov rbp,[r12+NEBO_DICT_STORAGE]
.scan:
 cmp r13,[r12+NEBO_DICT_CAPACITY]
 jae .counts
 mov rax,r13
 shl rax,5
 add rax,rbp
 mov rcx,[rax+NEBO_DICT_SLOT_STATE]
 cmp rcx,NEBO_DICT_EMPTY
 je .next
 cmp rcx,NEBO_DICT_TOMBSTONE
 je .tomb
 cmp rcx,NEBO_DICT_OCCUPIED
 jne .bad
 inc r14
 push rax
 mov rdi,[rax+NEBO_DICT_SLOT_KEY]
 mov rsi,[r12+NEBO_DICT_SEED]
 call neboc_hash_u64
 mov rcx,rax
 pop rax
 cmp rcx,[rax+NEBO_DICT_SLOT_HASH]
 jne .bad
 jmp .next
.tomb:
 inc r15
 cmp qword [rax+NEBO_DICT_SLOT_HASH],0
 jne .bad
 cmp qword [rax+NEBO_DICT_SLOT_KEY],0
 jne .bad
 cmp qword [rax+NEBO_DICT_SLOT_VALUE],0
 jne .bad
.next:
 inc r13
 jmp .scan
.counts:
 cmp r14,[r12+NEBO_DICT_LENGTH]
 jne .bad
 cmp r15,[r12+NEBO_DICT_TOMBSTONES]
 jne .bad
 mov rax,[r12+NEBO_DICT_MAX_PROBE]
 cmp rax,[r12+NEBO_DICT_CAPACITY]
 ja .bad
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_dict_collision_count
 push r12
 push r13
 push r14
 mov r12,rdi
 call neboc_dict_validate
 test eax,eax
 jnz .collision_zero
 xor r13d,r13d
 xor r14d,r14d
.collision_scan:
 cmp r13,[r12+NEBO_DICT_CAPACITY]
 jae .collision_done
 mov rax,r13
 shl rax,5
 add rax,[r12+NEBO_DICT_STORAGE]
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .collision_next
 mov rcx,[rax+NEBO_DICT_SLOT_HASH]
 mov rdx,[r12+NEBO_DICT_CAPACITY]
 dec rdx
 and rcx,rdx
 cmp rcx,r13
 je .collision_next
 inc r14
.collision_next:
 inc r13
 jmp .collision_scan
.collision_done:
 mov rax,r14
 jmp .collision_return
.collision_zero:
 xor eax,eax
.collision_return:
 pop r14
 pop r13
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_dict_max_probe_length
 test rdi,rdi
 jz .max_zero
 mov rax,[rdi+NEBO_DICT_MAX_PROBE]
 ret
.max_zero:
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
