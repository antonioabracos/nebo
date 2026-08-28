; TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-F05 bounded u64 Set over the Dict substrate.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/hash_map_contract.inc"
extern neboc_dict_init
extern neboc_dict_validate
extern neboc_dict_insert
extern neboc_dict_contains
extern neboc_dict_remove

section .text
NEBOC_ABI_FUNCTION neboc_set_init
 jmp neboc_dict_init

; insert(set*, value, inserted*)
NEBOC_ABI_FUNCTION neboc_set_insert
 test rdx,rdx
 jz .insert_invalid
 push r12
 push r13
 push rbp
 sub rsp,16
 mov r12,rdx
 mov rdx,1
 lea rcx,[rsp]
 lea r8,[rsp+8]
 call neboc_dict_insert
 test eax,eax
 jnz .insert_done
 mov rax,[rsp+8]
 xor rax,1
 mov [r12],rax
 xor eax,eax
.insert_done:
 add rsp,16
 pop rbp
 pop r13
 pop r12
 ret
.insert_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_set_contains
 jmp neboc_dict_contains

; remove(set*, value, removed*)
NEBOC_ABI_FUNCTION neboc_set_remove
 test rdx,rdx
 jz .remove_invalid
 push r12
 push r13
 push rbp
 sub rsp,16
 mov r12,rdx
 lea rdx,[rsp]
 lea rcx,[rsp+8]
 call neboc_dict_remove
 test eax,eax
 jnz .remove_done
 mov rax,[rsp+8]
 mov [r12],rax
 xor eax,eax
.remove_done:
 add rsp,16
 pop rbp
 pop r13
 pop r12
 ret
.remove_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_set_union
 mov ecx,1
 jmp neboc_set_algebra
NEBOC_ABI_FUNCTION neboc_set_intersection
 mov ecx,2
 jmp neboc_set_algebra
NEBOC_ABI_FUNCTION neboc_set_difference
 mov ecx,3
 jmp neboc_set_algebra

; subset(left*, right*, out_bool*) -> Status.
NEBOC_ABI_FUNCTION neboc_set_subset
 test rdx,rdx
 jz .subset_invalid
 test rdx,7
 jnz .subset_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_dict_validate
 test eax,eax
 jnz .subset_done
 mov rdi,r13
 call neboc_dict_validate
 test eax,eax
 jnz .subset_done
 xor r15d,r15d
.subset_scan:
 cmp r15,[r12+NEBO_DICT_CAPACITY]
 jae .subset_yes
 mov rax,r15
 shl rax,5
 add rax,[r12+NEBO_DICT_STORAGE]
 inc r15
 cmp qword [rax+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .subset_scan
 mov rdi,r13
 mov rsi,[rax+NEBO_DICT_SLOT_KEY]
 call neboc_dict_contains
 test eax,eax
 jz .subset_no
 jmp .subset_scan
.subset_yes:
 mov qword [r14],1
 xor eax,eax
 jmp .subset_done
.subset_no:
 mov qword [r14],0
 xor eax,eax
.subset_done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.subset_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; algebra(left*, right*, empty_dest*, kind)
NEBOC_ABI_FUNCTION neboc_set_algebra
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_dict_validate
 test eax,eax
 jnz .alg_done
 mov rdi,r13
 call neboc_dict_validate
 test eax,eax
 jnz .alg_done
 mov rdi,r14
 call neboc_dict_validate
 test eax,eax
 jnz .alg_done
 cmp r14,r12
 je .alg_invalid
 cmp r14,r13
 je .alg_invalid
 cmp qword [r14+NEBO_DICT_LENGTH],0
 jne .alg_invalid
 cmp qword [r14+NEBO_DICT_TOMBSTONES],0
 jne .alg_invalid
 cmp qword [r14+NEBO_DICT_MAX_PROBE],0
 jne .alg_invalid
 cmp dword [r14+NEBO_DICT_BORROW_COUNT],0
 jne .alg_invalid
 cmp r15,1
 jb .alg_invalid
 cmp r15,3
 ja .alg_invalid
 ; Destination storage must be disjoint from both input storage ranges.
 mov rax,[r14+NEBO_DICT_STORAGE]
 mov rcx,[r14+NEBO_DICT_CAPACITY]
 shl rcx,5
 add rcx,rax
 mov rdx,[r12+NEBO_DICT_STORAGE]
 mov r8,[r12+NEBO_DICT_CAPACITY]
 shl r8,5
 add r8,rdx
 cmp rax,r8
 jae .alg_left_disjoint
 cmp rdx,rcx
 jb .alg_invalid
.alg_left_disjoint:
 mov rdx,[r13+NEBO_DICT_STORAGE]
 mov r8,[r13+NEBO_DICT_CAPACITY]
 shl r8,5
 add r8,rdx
 cmp rax,r8
 jae .alg_storage_disjoint
 cmp rdx,rcx
 jb .alg_invalid
.alg_storage_disjoint:
 mov rax,[r12+NEBO_DICT_LENGTH]
 cmp r15,1
 jne .not_union_bound
 add rax,[r13+NEBO_DICT_LENGTH]
 jmp .bound
.not_union_bound:
 cmp r15,2
 jne .bound
 mov rcx,[r13+NEBO_DICT_LENGTH]
 cmp rax,rcx
 cmova rax,rcx
.bound:
 mov [rsp+32],rax
 shl rax,2
 mov rcx,[r14+NEBO_DICT_CAPACITY]
 imul rcx,3
 cmp rax,rcx
 ja .alg_limit
 mov rax,[rsp+32]
 mov rcx,NEBO_DICT_GENERATION_MASK
 sub rcx,rax
 cmp [r14+NEBO_DICT_GENERATION],rcx
 ja .alg_limit
 mov rax,[r14+NEBO_DICT_GENERATION]
 mov [rsp+40],rax
 mov [rsp],r12
 mov qword [rsp+8],0
.scan:
 mov rbp,[rsp]
 mov rax,[rsp+8]
 cmp rax,[rbp+NEBO_DICT_CAPACITY]
 jae .source_done
 mov rcx,rax
 shl rcx,5
 add rcx,[rbp+NEBO_DICT_STORAGE]
 inc qword [rsp+8]
 cmp qword [rcx+NEBO_DICT_SLOT_STATE],NEBO_DICT_OCCUPIED
 jne .scan
 mov rax,[rcx+NEBO_DICT_SLOT_KEY]
 mov [rsp+16],rax
 cmp r15,1
 je .include
 mov rdi,r13
 mov rsi,rax
 call neboc_dict_contains
 cmp r15,2
 je .intersection
 test eax,eax
 jz .include
 jmp .scan
.intersection:
 test eax,eax
 jz .scan
.include:
 mov rdi,r14
 mov rsi,[rsp+16]
 mov rdx,1
 lea rcx,[rsp+16]
 lea r8,[rsp+24]
 call neboc_dict_insert
 test eax,eax
 jnz .alg_rollback
 jmp .scan
.source_done:
 cmp r15,1
 jne .alg_ok
 cmp rbp,r12
 jne .alg_ok
 mov [rsp],r13
 mov qword [rsp+8],0
 jmp .scan
.alg_ok:
 xor eax,eax
 jmp .alg_done
.alg_rollback:
 mov [rsp+48],rax
 mov rdi,[r14+NEBO_DICT_STORAGE]
 mov rcx,[r14+NEBO_DICT_CAPACITY]
 shl rcx,2
 xor eax,eax
 rep stosq
 mov qword [r14+NEBO_DICT_LENGTH],0
 mov qword [r14+NEBO_DICT_TOMBSTONES],0
 mov qword [r14+NEBO_DICT_MAX_PROBE],0
 mov rax,[rsp+40]
 mov [r14+NEBO_DICT_GENERATION],rax
 mov rax,[rsp+48]
 jmp .alg_done
.alg_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .alg_done
.alg_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.alg_done:
 add rsp,64
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
