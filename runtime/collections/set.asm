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
 mov qword [r12],0
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
 mov qword [r12],0
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

; algebra(left*, right*, empty_dest*, kind)
NEBOC_ABI_FUNCTION neboc_set_algebra
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
 jnz .alg_done
 mov rdi,r13
 call neboc_dict_validate
 test eax,eax
 jnz .alg_done
 mov rdi,r14
 call neboc_dict_validate
 test eax,eax
 jnz .alg_done
 cmp qword [r14+NEBO_DICT_LENGTH],0
 jne .alg_invalid
 cmp dword [r14+NEBO_DICT_BORROW_COUNT],0
 jne .alg_invalid
 cmp r15,1
 jb .alg_invalid
 cmp r15,3
 ja .alg_invalid
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
 shl rax,2
 mov rcx,[r14+NEBO_DICT_CAPACITY]
 imul rcx,3
 cmp rax,rcx
 ja .alg_limit
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
 jnz .alg_done
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
.alg_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .alg_done
.alg_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.alg_done:
 add rsp,32
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
