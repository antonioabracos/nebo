; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-F02 bounded u64 Node/Tree.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
section .text
; init(tree*, values*, generations_u32*, alive_u8*, parents_u64*, capacity)
NEBOC_ABI_FUNCTION neboc_tree_init
 test rdi,rdi
 jz .init_invalid
 test rdi,7
 jnz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 test rcx,rcx
 jz .init_invalid
 test r8,r8
 jz .init_invalid
 test r9,r9
 jz .init_limit
 cmp r9,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 ja .init_limit
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
 mov rdi,r12
 mov ecx,NEBO_TREE_SIZE/8
 xor eax,eax
 rep stosq
 mov [r12+NEBO_TREE_VALUES],r13
 mov [r12+NEBO_TREE_GENERATIONS],r14
 mov [r12+NEBO_TREE_ALIVE],r15
 mov [r12+NEBO_TREE_PARENTS],rbp
 mov [r12+NEBO_TREE_CAPACITY],r9
 mov qword [r12+NEBO_TREE_GENERATION],1
 mov qword [r12+NEBO_TREE_ROOT],NEBO_INVALID_HANDLE
 xor r10d,r10d
.zero:
 cmp r10,r9
 jae .init_ok
 mov qword [r13+r10*8],0
 mov dword [r14+r10*4],1
 mov byte [r15+r10],0
 mov qword [rbp+r10*8],NEBO_INVALID_HANDLE
 inc r10
 jmp .zero
.init_ok:
 xor eax,eax
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.init_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_tree_validate
 test rdi,rdi
 jz .tv_invalid
 mov rax,[rdi+NEBO_TREE_CAPACITY]
 test rax,rax
 jz .tv_source
 cmp rax,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 ja .tv_source
 cmp [rdi+NEBO_TREE_LENGTH],rax
 ja .tv_source
 cmp qword [rdi+NEBO_TREE_VALUES],0
 je .tv_source
 cmp qword [rdi+NEBO_TREE_GENERATIONS],0
 je .tv_source
 cmp qword [rdi+NEBO_TREE_ALIVE],0
 je .tv_source
 cmp qword [rdi+NEBO_TREE_PARENTS],0
 je .tv_source
 xor eax,eax
 ret
.tv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.tv_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; validate_handle(tree*, handle) -> status eax, index rdx
NEBOC_ABI_FUNCTION neboc_tree_validate_handle
 mov rax,rsi
 mov edx,eax
 shr rax,32
 cmp rdx,[rdi+NEBO_TREE_CAPACITY]
 jae .vh_bad
 mov rcx,[rdi+NEBO_TREE_ALIVE]
 cmp byte [rcx+rdx],0
 je .vh_bad
 mov rcx,[rdi+NEBO_TREE_GENERATIONS]
 cmp eax,[rcx+rdx*4]
 jne .vh_bad
 xor eax,eax
 ret
.vh_bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; add(tree*, parent_handle|INVALID, value, out_handle*)
NEBOC_ABI_FUNCTION neboc_tree_add
 test rcx,rcx
 jz .add_invalid
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],NEBO_INVALID_HANDLE
 call neboc_tree_validate
 test eax,eax
 jnz .add_done
 cmp qword [r12+NEBO_TREE_BORROW],0
 jne .add_borrow
 cmp r13,NEBO_INVALID_HANDLE
 jne .parent
 cmp qword [r12+NEBO_TREE_LENGTH],0
 jne .add_invalid_state
 jmp .find
.parent:
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .add_done
.find:
 mov rbp,[r12+NEBO_TREE_ALIVE]
 xor edx,edx
.find_loop:
 cmp rdx,[r12+NEBO_TREE_CAPACITY]
 jae .add_full
 cmp byte [rbp+rdx],0
 je .slot
 inc rdx
 jmp .find_loop
.slot:
 mov rax,[r12+NEBO_TREE_VALUES]
 mov [rax+rdx*8],r14
 mov byte [rbp+rdx],1
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov [rax+rdx*8],r13
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+rdx*4]
 shl rax,32
 or rax,rdx
 mov [r15],rax
 inc qword [r12+NEBO_TREE_LENGTH]
 inc qword [r12+NEBO_TREE_GENERATION]
 cmp r13,NEBO_INVALID_HANDLE
 jne .add_ok
 mov [r12+NEBO_TREE_ROOT],rax
.add_ok: xor eax,eax
 jmp .add_done
.add_full: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .add_done
.add_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .add_done
.add_invalid_state: mov eax,NEBOC_STATUS_INVALID_SOURCE
.add_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.add_invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_tree_get
 test rdx,rdx
 jz .get_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_tree_validate
 test eax,eax
 jnz .get_done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .get_done
 mov rax,[r12+NEBO_TREE_VALUES]
 mov rax,[rax+rdx*8]
 mov [r14],rax
 xor eax,eax
.get_done: pop r14
 pop r13
 pop r12
 ret
.get_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; replace(tree*, handle, value, old*)
NEBOC_ABI_FUNCTION neboc_tree_replace
 test rcx,rcx
 jz .replace_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_tree_validate
 test eax,eax
 jnz .replace_done
 cmp qword [r12+NEBO_TREE_BORROW],0
 jne .replace_borrow
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .replace_done
 mov rax,[r12+NEBO_TREE_VALUES]
 mov rcx,[rax+rdx*8]
 mov [r15],rcx
 mov [rax+rdx*8],r14
 inc qword [r12+NEBO_TREE_GENERATION]
 xor eax,eax
 jmp .replace_done
.replace_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.replace_done: pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.replace_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; parent(tree*, handle, out*, found*)
NEBOC_ABI_FUNCTION neboc_tree_parent
 test rdx,rdx
 jz .parent_bad
 test rcx,rcx
 jz .parent_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r14],NEBO_INVALID_HANDLE
 mov qword [r15],0
 call neboc_tree_validate
 test eax,eax
 jnz .parent_done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .parent_done
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov rax,[rax+rdx*8]
 cmp rax,NEBO_INVALID_HANDLE
 je .parent_ok
 mov [r14],rax
 mov qword [r15],1
.parent_ok: xor eax,eax
.parent_done: pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.parent_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; reparent(tree*, node, new_parent), rejects cycles.
NEBOC_ABI_FUNCTION neboc_tree_reparent
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_tree_validate
 test eax,eax
 jnz .rp_done
 cmp qword [r12+NEBO_TREE_BORROW],0
 jne .rp_borrow
 cmp r13,[r12+NEBO_TREE_ROOT]
 je .rp_bad
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .rp_done
 mov rdi,r12
 mov rsi,r14
 call neboc_tree_validate_handle
 test eax,eax
 jnz .rp_done
 mov rax,r14
 xor ebp,ebp
.climb:
 cmp rax,r13
 je .rp_cycle
 cmp rax,NEBO_INVALID_HANDLE
 je .rp_commit
 mov rdi,r12
 mov rsi,rax
 call neboc_tree_validate_handle
 test eax,eax
 jnz .rp_done
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov rax,[rax+rdx*8]
 inc rbp
 cmp rbp,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 jb .climb
.rp_cycle: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .rp_done
.rp_commit:
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov [rax+rdx*8],r14
 inc qword [r12+NEBO_TREE_GENERATION]
 xor eax,eax
 jmp .rp_done
.rp_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .rp_done
.rp_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.rp_done: pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; child_count(tree*, handle, out_count*)
NEBOC_ABI_FUNCTION neboc_tree_child_count
 test rdx,rdx
 jz .cc_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_tree_validate
 test eax,eax
 jnz .cc_done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .cc_done
 mov r15,[r12+NEBO_TREE_ALIVE]
 mov rbp,[r12+NEBO_TREE_PARENTS]
 xor ecx,ecx
 xor edx,edx
.cc_loop:
 cmp rdx,[r12+NEBO_TREE_CAPACITY]
 jae .cc_ok
 cmp byte [r15+rdx],0
 je .cc_next
 cmp [rbp+rdx*8],r13
 jne .cc_next
 inc rcx
.cc_next:
 inc rdx
 jmp .cc_loop
.cc_ok:
 mov [r14],rcx
 xor eax,eax
.cc_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.cc_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; remove_subtree(tree*, handle)
NEBOC_ABI_FUNCTION neboc_tree_remove_subtree
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 call neboc_tree_validate
 test eax,eax
 jnz .remove_done
 cmp qword [r12+NEBO_TREE_BORROW],0
 jne .remove_borrow
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .remove_done
 mov r14,[r12+NEBO_TREE_ALIVE]
 xor r15d,r15d
.candidate:
 cmp r15,[r12+NEBO_TREE_CAPACITY]
 jae .remove_finish
 cmp byte [r14+r15],0
 je .candidate_next
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+r15*4]
 shl rax,32
 or rax,r15
 mov rbp,rax
 xor r11d,r11d
.ancestor:
 cmp rbp,r13
 je .delete
 cmp rbp,NEBO_INVALID_HANDLE
 je .candidate_next
 mov rdi,r12
 mov rsi,rbp
 call neboc_tree_validate_handle
 test eax,eax
 jnz .candidate_next
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov rbp,[rax+rdx*8]
 inc r11
 cmp r11,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 jb .ancestor
 jmp .candidate_next
.delete:
 mov byte [r14+r15],2
.candidate_next:
 inc r15
 jmp .candidate
.remove_finish:
 xor r15d,r15d
.delete_loop:
 cmp r15,[r12+NEBO_TREE_CAPACITY]
 jae .delete_done
 cmp byte [r14+r15],2
 jne .delete_next
 mov byte [r14+r15],0
 mov rax,[r12+NEBO_TREE_VALUES]
 mov qword [rax+r15*8],0
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov qword [rax+r15*8],NEBO_INVALID_HANDLE
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 inc dword [rax+r15*4]
 jnz .gen_ok
 inc dword [rax+r15*4]
.gen_ok:
 dec qword [r12+NEBO_TREE_LENGTH]
.delete_next:
 inc r15
 jmp .delete_loop
.delete_done:
 cmp r13,[r12+NEBO_TREE_ROOT]
 jne .not_root
 mov qword [r12+NEBO_TREE_ROOT],NEBO_INVALID_HANDLE
.not_root:
 inc qword [r12+NEBO_TREE_GENERATION]
 xor eax,eax
 jmp .remove_done
.remove_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.remove_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
