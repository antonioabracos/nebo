; GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-F03 bounded generic List algorithms with explicit callbacks.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_validate
section .text

; find(desc*, needle*, eq_fn, out_index*, out_found*)
; eq_fn(a*, b*, out_equal*) -> Status
NEBOC_ABI_FUNCTION neboc_list_find
 test rsi,rsi
 jz .find_invalid
 test rdx,rdx
 jz .find_invalid
 test rcx,rcx
 jz .find_invalid
 test r8,r8
 jz .find_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov qword [rbx],0
 mov qword [r15],0
 call neboc_list_validate
 test eax,eax
 jnz .find_done
 xor r9d,r9d
.find_loop:
 cmp r9,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .find_ok
 mov rax,r9
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,r13
 lea rdx,[rsp]
 mov qword [rsp],0
 mov [rsp+8],r9
 call r14
 test eax,eax
 jnz .find_done
 cmp qword [rsp],1
 je .find_found
 cmp qword [rsp],0
 jne .find_callback
 mov r9,[rsp+8]
 inc r9
 jmp .find_loop
.find_found:
 mov r9,[rsp+8]
 mov [r15],r9
 mov qword [rbx],1
.find_ok:
 xor eax,eax
 jmp .find_done
.find_callback:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.find_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.find_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; contains(desc*, needle*, eq_fn, out_bool*)
NEBOC_ABI_FUNCTION neboc_list_contains
 test rcx,rcx
 jz .contains_invalid
 push r12
 sub rsp,16
 mov r12,rcx
 mov rcx,rsp
 lea r8,[rsp+8]
 call neboc_list_find
 test eax,eax
 jnz .contains_done
 mov rax,[rsp+8]
 mov [r12],rax
.contains_done:
 add rsp,16
 pop r12
 ret
.contains_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; map(input*, output_empty*, transform_fn)
; transform_fn(src*, dst*) -> Status
NEBOC_ABI_FUNCTION neboc_list_map
 test rdx,rdx
 jz .map_invalid
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .map_done
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .map_done
 cmp qword [r13+NEBOC_LIST_LENGTH_OFFSET],0
 jne .map_profile
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r13+NEBOC_LIST_CAPACITY_OFFSET]
 ja .map_profile
 mov rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 cmp rax,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 jne .map_profile
 xor r15d,r15d
.map_loop:
 cmp r15,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .map_commit
 mov rax,r15
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,[r13+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 call r14
 test eax,eax
 jnz .map_rollback
 inc r15
 jmp .map_loop
.map_commit:
 mov [r13+NEBOC_LIST_LENGTH_OFFSET],r15
 test r15,r15
 jz .map_ok
 inc qword [r13+NEBOC_LIST_GENERATION_OFFSET]
.map_ok:
 xor eax,eax
 jmp .map_done
.map_rollback:
 mov rdi,[r13+NEBOC_LIST_DATA_OFFSET]
 mov rcx,r15
 imul rcx,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 xor eax,eax
 rep stosb
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .map_done
.map_profile:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.map_done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.map_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; filter(input*, output_empty*, predicate_fn)
; predicate_fn(element*, out_bool*) -> Status
NEBOC_ABI_FUNCTION neboc_list_filter
 test rdx,rdx
 jz .filter_invalid
 push r12
 push r13
 push r14
 push r15
 push rbx
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_list_validate
 test eax,eax
 jnz .filter_done
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .filter_done
 cmp qword [r13+NEBOC_LIST_LENGTH_OFFSET],0
 jne .filter_profile
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rax,[r13+NEBOC_LIST_CAPACITY_OFFSET]
 ja .filter_profile
 mov rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 cmp rax,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 jne .filter_profile
 xor r15d,r15d
 xor ebx,ebx
.filter_loop:
 cmp r15,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .filter_commit
 mov rax,r15
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rsi,rsp
 mov qword [rsp],0
 call r14
 test eax,eax
 jnz .filter_rollback
 cmp qword [rsp],0
 je .filter_next
 cmp qword [rsp],1
 jne .filter_rollback
 mov rax,r15
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 add rsi,rax
 mov rax,rbx
 imul rax,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 mov rdi,[r13+NEBOC_LIST_DATA_OFFSET]
 add rdi,rax
 mov rcx,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 inc rbx
.filter_next:
 inc r15
 jmp .filter_loop
.filter_commit:
 mov [r13+NEBOC_LIST_LENGTH_OFFSET],rbx
 test rbx,rbx
 jz .filter_ok
 inc qword [r13+NEBOC_LIST_GENERATION_OFFSET]
.filter_ok:
 xor eax,eax
 jmp .filter_done
.filter_rollback:
 mov rdi,[r13+NEBOC_LIST_DATA_OFFSET]
 mov rcx,rbx
 imul rcx,[r13+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 xor eax,eax
 rep stosb
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .filter_done
.filter_profile:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.filter_done:
 add rsp,16
 pop rbx
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.filter_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; stable_sort(desc*, comparator_fn, scratch*, scratch_bytes)
; comparator_fn(a*, b*, out_cmp*) -> Status, cmp in {-1,0,1}.
NEBOC_ABI_FUNCTION neboc_list_stable_sort
 test rsi,rsi
 jz .sort_invalid
 test rdx,rdx
 jz .sort_invalid
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_list_validate
 test eax,eax
 jnz .sort_done
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 jo .sort_profile
 cmp r15,rax
 jb .sort_profile
 mov rdi,r14
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rcx,rax
 rep movsb
 mov rbx,1
.sort_outer:
 cmp rbx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .sort_commit
 mov rax,rbx
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 lea rdi,[rsp+16]
 lea rsi,[r14+rax]
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 mov r15,rbx
.sort_inner:
 test r15,r15
 jz .sort_place
 mov rax,r15
 dec rax
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 lea rdi,[r14+rax]
 lea rsi,[rsp+16]
 lea rdx,[rsp]
 mov qword [rsp],0
 call r13
 test eax,eax
 jnz .sort_callback
 mov rax,[rsp]
 cmp rax,-1
 jl .sort_comparator
 cmp rax,1
 jg .sort_comparator
 cmp rax,0
 jle .sort_place
 mov rax,r15
 dec rax
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 lea rsi,[r14+rax]
 add rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 lea rdi,[r14+rax]
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 dec r15
 jmp .sort_inner
.sort_place:
 mov rax,r15
 imul rax,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 lea rdi,[r14+rax]
 lea rsi,[rsp+16]
 mov rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 inc rbx
 jmp .sort_outer
.sort_commit:
 mov rdi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rsi,r14
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 imul rcx,[r12+NEBOC_LIST_ELEMENT_SIZE_OFFSET]
 rep movsb
 cmp qword [r12+NEBOC_LIST_LENGTH_OFFSET],1
 jbe .sort_ok
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
.sort_ok:
 xor eax,eax
 jmp .sort_done
.sort_callback:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sort_done
.sort_comparator:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .sort_done
.sort_profile:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.sort_done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.sort_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
