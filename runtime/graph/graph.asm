; STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-F03 bounded u64 Graph nodes and weighted edges.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"
section .text

; init(graph*, storage_bundle*, capacity, flags)
NEBOC_ABI_FUNCTION neboc_graph_init
 test rdi,rdi
 jz .init_bad
 test rdi,7
 jnz .init_bad
 test rsi,rsi
 jz .init_bad
 test rsi,7
 jnz .init_bad
 test rdx,rdx
 jz .init_limit
 cmp rdx,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 ja .init_limit
 mov eax,ecx
 and eax,NEBO_GRAPH_DIRECTED | NEBO_GRAPH_UNDIRECTED
 cmp eax,NEBO_GRAPH_DIRECTED
 je .flags_base_ok
 cmp eax,NEBO_GRAPH_UNDIRECTED
 jne .init_bad
.flags_base_ok:
 test ecx,NEBO_GRAPH_ALLOW_MULTI
 jnz .init_bad
 mov eax,ecx
 and eax,~(NEBO_GRAPH_DIRECTED | NEBO_GRAPH_UNDIRECTED | NEBO_GRAPH_ALLOW_SELF)
 jnz .init_bad
 cmp qword [rsi+NEBO_GRAPH_STORAGE_VALUES],0
 je .init_bad
 cmp qword [rsi+NEBO_GRAPH_STORAGE_GENERATIONS],0
 je .init_bad
 cmp qword [rsi+NEBO_GRAPH_STORAGE_ALIVE],0
 je .init_bad
 cmp qword [rsi+NEBO_GRAPH_STORAGE_ADJACENCY],0
 je .init_bad
 cmp qword [rsi+NEBO_GRAPH_STORAGE_WEIGHTS],0
 je .init_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rdi,r12
 mov ecx,nebo_graph_GRAPH_SIZE_semantic_graph_native_vertical/8
 xor eax,eax
 rep stosq
 mov rax,[r13+NEBO_GRAPH_STORAGE_VALUES]
 mov [r12+NEBO_GRAPH_VALUES],rax
 mov rax,[r13+NEBO_GRAPH_STORAGE_GENERATIONS]
 mov [r12+NEBO_GRAPH_GENERATIONS],rax
 mov rax,[r13+NEBO_GRAPH_STORAGE_ALIVE]
 mov [r12+NEBO_GRAPH_ALIVE],rax
 mov rax,[r13+NEBO_GRAPH_STORAGE_ADJACENCY]
 mov [r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical],rax
 mov rax,[r13+NEBO_GRAPH_STORAGE_WEIGHTS]
 mov [r12+NEBO_GRAPH_WEIGHTS],rax
 mov [r12+NEBO_GRAPH_CAPACITY],r14
 mov qword [r12+NEBO_GRAPH_GENERATION],1
 mov [r12+NEBO_GRAPH_FLAGS],r15
 xor ebp,ebp
.zero_nodes:
 cmp rbp,r14
 jae .zero_matrix_start
 mov rax,[r12+NEBO_GRAPH_VALUES]
 mov qword [rax+rbp*8],0
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov dword [rax+rbp*4],1
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 mov byte [rax+rbp],0
 inc rbp
 jmp .zero_nodes
.zero_matrix_start:
 mov rax,r14
 imul rax,r14
 xor ebp,ebp
.zero_matrix:
 cmp rbp,rax
 jae .init_ok
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 mov byte [rcx+rbp],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rbp*8],0
 inc rbp
 jmp .zero_matrix
.init_ok:
 xor eax,eax
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.init_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.init_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_graph_validate
 test rdi,rdi
 jz .gv_bad
 mov rax,[rdi+NEBO_GRAPH_CAPACITY]
 test rax,rax
 jz .gv_source
 cmp rax,nebo_graph_GRAPH_MAX_NODES_semantic_graph_native_vertical
 ja .gv_source
 cmp [rdi+NEBO_GRAPH_LENGTH],rax
 ja .gv_source
 cmp qword [rdi+NEBO_GRAPH_EDGE_COUNT],NEBO_GRAPH_MAX_EDGES
 ja .gv_source
 cmp qword [rdi+NEBO_GRAPH_VALUES],0
 je .gv_source
 cmp qword [rdi+NEBO_GRAPH_GENERATIONS],0
 je .gv_source
 cmp qword [rdi+NEBO_GRAPH_ALIVE],0
 je .gv_source
 cmp qword [rdi+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical],0
 je .gv_source
 cmp qword [rdi+NEBO_GRAPH_WEIGHTS],0
 je .gv_source
 mov rcx,[rdi+NEBO_GRAPH_FLAGS]
 mov edx,ecx
 and edx,NEBO_GRAPH_DIRECTED | NEBO_GRAPH_UNDIRECTED
 cmp edx,NEBO_GRAPH_DIRECTED
 je .gv_ok
 cmp edx,NEBO_GRAPH_UNDIRECTED
 jne .gv_source
.gv_ok: xor eax,eax
 ret
.gv_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.gv_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; validate_handle(graph*, handle) -> status eax, index rdx
NEBOC_ABI_FUNCTION neboc_graph_validate_handle
 mov rax,rsi
 mov edx,eax
 shr rax,32
 cmp rdx,[rdi+NEBO_GRAPH_CAPACITY]
 jae .gh_bad
 mov rcx,[rdi+NEBO_GRAPH_ALIVE]
 cmp byte [rcx+rdx],1
 jne .gh_bad
 mov rcx,[rdi+NEBO_GRAPH_GENERATIONS]
 cmp eax,[rcx+rdx*4]
 jne .gh_bad
 xor eax,eax
 ret
.gh_bad: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; add_node(graph*, value, out_handle*)
NEBOC_ABI_FUNCTION neboc_graph_add_node
 test rdx,rdx
 jz .an_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],NEBO_INVALID_HANDLE
 call neboc_graph_validate
 test eax,eax
 jnz .an_done
 cmp qword [r12+NEBO_GRAPH_BORROW],0
 jne .an_borrow
 mov r15,[r12+NEBO_GRAPH_ALIVE]
 xor ebp,ebp
.an_find:
 cmp rbp,[r12+NEBO_GRAPH_CAPACITY]
 jae .an_full
 cmp byte [r15+rbp],0
 je .an_slot
 inc rbp
 jmp .an_find
.an_slot:
 mov rax,[r12+NEBO_GRAPH_VALUES]
 mov [rax+rbp*8],r13
 mov byte [r15+rbp],1
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rbp*4]
 shl rax,32
 or rax,rbp
 mov [r14],rax
 inc qword [r12+NEBO_GRAPH_LENGTH]
 inc qword [r12+NEBO_GRAPH_GENERATION]
 xor eax,eax
 jmp .an_done
.an_full: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .an_done
.an_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.an_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.an_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; get_node(graph*, handle, out_value*)
NEBOC_ABI_FUNCTION neboc_graph_get_node
 test rdx,rdx
 jz .gn_bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_graph_validate
 test eax,eax
 jnz .gn_done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .gn_done
 mov rax,[r12+NEBO_GRAPH_VALUES]
 mov rax,[rax+rdx*8]
 mov [r14],rax
 xor eax,eax
.gn_done: pop r14
 pop r13
 pop r12
 ret
.gn_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; replace_node(graph*, handle, value, old*)
NEBOC_ABI_FUNCTION neboc_graph_replace_node
 test rcx,rcx
 jz .rn_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call neboc_graph_validate
 test eax,eax
 jnz .rn_done
 cmp qword [r12+NEBO_GRAPH_BORROW],0
 jne .rn_borrow
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .rn_done
 mov rax,[r12+NEBO_GRAPH_VALUES]
 mov rcx,[rax+rdx*8]
 mov [r15],rcx
 mov [rax+rdx*8],r14
 inc qword [r12+NEBO_GRAPH_GENERATION]
 xor eax,eax
 jmp .rn_done
.rn_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.rn_done: pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.rn_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; add_edge(graph*, from, to, nonnegative_weight)
NEBOC_ABI_FUNCTION neboc_graph_add_edge
 test rcx,rcx
 js .ae_weight
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbp,rcx
 call neboc_graph_validate
 test eax,eax
 jnz .ae_done
 cmp qword [r12+NEBO_GRAPH_BORROW],0
 jne .ae_borrow
 cmp qword [r12+NEBO_GRAPH_EDGE_COUNT],NEBO_GRAPH_MAX_EDGES
 jae .ae_limit
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .ae_done
 mov r15,rdx
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .ae_done
 cmp r15,rdx
 jne .ae_indices
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_ALLOW_SELF
 jz .ae_policy
.ae_indices:
 mov rax,r15
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rdx
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rcx+rax],0
 jne .ae_policy
 mov byte [rcx+rax],1
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov [rcx+rax*8],rbp
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jz .ae_commit
 cmp r15,rdx
 je .ae_commit
 mov rax,rdx
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r15
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 mov byte [rcx+rax],1
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov [rcx+rax*8],rbp
.ae_commit:
 inc qword [r12+NEBO_GRAPH_EDGE_COUNT]
 inc qword [r12+NEBO_GRAPH_GENERATION]
 xor eax,eax
 jmp .ae_done
.ae_weight: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.ae_policy: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .ae_done
.ae_limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .ae_done
.ae_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.ae_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret

; edge_weight(graph*, from, to, out_weight*, found*)
NEBOC_ABI_FUNCTION neboc_graph_edge_weight
 test rcx,rcx
 jz .ew_bad
 test r8,r8
 jz .ew_bad
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
 call neboc_graph_validate
 test eax,eax
 jnz .ew_done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .ew_done
 mov r13,rdx
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .ew_done
 mov rax,r13
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rdx
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rcx+rax],0
 je .ew_ok
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov rcx,[rcx+rax*8]
 mov [r15],rcx
 mov qword [rbp],1
.ew_ok: xor eax,eax
.ew_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.ew_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; remove_edge(graph*, from, to, removed*)
NEBOC_ABI_FUNCTION neboc_graph_remove_edge
 test rcx,rcx
 jz .re_bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
 call neboc_graph_validate
 test eax,eax
 jnz .re_done
 cmp qword [r12+NEBO_GRAPH_BORROW],0
 jne .re_borrow
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .re_done
 mov r13,rdx
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .re_done
 mov rbp,rdx
 mov rax,r13
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rbp
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rcx+rax],0
 je .re_ok
 mov byte [rcx+rax],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rax*8],0
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jz .re_commit
 cmp r13,rbp
 je .re_commit
 mov rax,rbp
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r13
 mov rcx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 mov byte [rcx+rax],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rax*8],0
.re_commit:
 dec qword [r12+NEBO_GRAPH_EDGE_COUNT]
 inc qword [r12+NEBO_GRAPH_GENERATION]
 mov qword [r15],1
.re_ok: xor eax,eax
 jmp .re_done
.re_borrow: mov eax,NEBOC_STATUS_INVALID_SOURCE
.re_done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.re_bad: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; remove_node(graph*, handle), clears all incident edges.
NEBOC_ABI_FUNCTION neboc_graph_remove_node
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 call neboc_graph_validate
 test eax,eax
 jnz .remove_done
 cmp qword [r12+NEBO_GRAPH_BORROW],0
 jne .remove_borrow
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .remove_done
 mov r14,rdx
 xor r15d,r15d
.incident:
 cmp r15,[r12+NEBO_GRAPH_CAPACITY]
 jae .remove_slot
 mov rax,r14
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r15
 mov rbp,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rbp+rax],0
 je .incoming
 mov byte [rbp+rax],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rax*8],0
 dec qword [r12+NEBO_GRAPH_EDGE_COUNT]
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jz .incoming
 cmp r14,r15
 je .incident_next
 mov rax,r15
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r14
 mov byte [rbp+rax],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rax*8],0
 jmp .incident_next
.incoming:
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jnz .incident_next
 cmp r14,r15
 je .incident_next
 mov rax,r15
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r14
 cmp byte [rbp+rax],0
 je .incident_next
 mov byte [rbp+rax],0
 mov rcx,[r12+NEBO_GRAPH_WEIGHTS]
 mov qword [rcx+rax*8],0
 dec qword [r12+NEBO_GRAPH_EDGE_COUNT]
.incident_next:
 inc r15
 jmp .incident
.remove_slot:
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 mov byte [rax+r14],0
 mov rax,[r12+NEBO_GRAPH_VALUES]
 mov qword [rax+r14*8],0
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 inc dword [rax+r14*4]
 jnz .remove_gen_ok
 inc dword [rax+r14*4]
.remove_gen_ok:
 dec qword [r12+NEBO_GRAPH_LENGTH]
 inc qword [r12+NEBO_GRAPH_GENERATION]
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
