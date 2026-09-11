; G009 bounded relational helpers not covered by the original RF27 runtime.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/graph/graph_contract.inc"

extern neboc_tree_validate
extern neboc_tree_validate_handle
extern neboc_graph_validate
extern neboc_graph_validate_handle
extern neboc_graph_topological_sort

section .text

; root(tree*, out_handle*, found*)
NEBOC_ABI_FUNCTION neboc_tree_root
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r13],NEBO_INVALID_HANDLE
 mov qword [r14],0
 call neboc_tree_validate
 test eax,eax
 jnz .done
 mov rsi,[r12+NEBO_TREE_ROOT]
 cmp rsi,NEBO_INVALID_HANDLE
 je .ok
 mov rdi,r12
 call neboc_tree_validate_handle
 test eax,eax
 jnz .done
 mov rax,[r12+NEBO_TREE_ROOT]
 mov [r13],rax
 mov qword [r14],1
.ok:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; degree(tree*, handle, out_count*) counts parent plus live children.
NEBOC_ABI_FUNCTION neboc_tree_degree
 test rdx,rdx
 jz .bad
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
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .done
 mov r15,[r12+NEBO_TREE_ALIVE]
 mov rbp,[r12+NEBO_TREE_PARENTS]
 xor ecx,ecx
 cmp qword [rbp+rdx*8],NEBO_INVALID_HANDLE
 je .children
 inc rcx
.children:
 xor edx,edx
.scan:
 cmp rdx,[r12+NEBO_TREE_CAPACITY]
 jae .publish
 cmp byte [r15+rdx],1
 jne .next
 cmp [rbp+rdx*8],r13
 jne .next
 inc rcx
.next:
 inc rdx
 jmp .scan
.publish:
 mov [r14],rcx
 xor eax,eax
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; children(tree*, parent, out_handles[capacity], out_length*) in slot order.
NEBOC_ABI_FUNCTION neboc_tree_children
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
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
 call neboc_tree_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .done
 mov rbp,[r12+NEBO_TREE_ALIVE]
 xor ecx,ecx
 xor edx,edx
.scan:
 cmp rdx,[r12+NEBO_TREE_CAPACITY]
 jae .publish
 cmp byte [rbp+rdx],1
 jne .next
 mov rax,[r12+NEBO_TREE_PARENTS]
 cmp [rax+rdx*8],r13
 jne .next
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+rdx*4]
 shl rax,32
 or rax,rdx
 mov [r14+rcx*8],rax
 inc rcx
.next:
 inc rdx
 jmp .scan
.publish:
 mov [r15],rcx
 xor eax,eax
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; height(tree*, out_height*): empty=0, root-only=1.
NEBOC_ABI_FUNCTION neboc_tree_height
 test rsi,rsi
 jz .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov qword [r13],0
 call neboc_tree_validate
 test eax,eax
 jnz .done
 mov r14,[r12+NEBO_TREE_ALIVE]
 xor r15d,r15d
 xor ebp,ebp
.node:
 cmp r15,[r12+NEBO_TREE_CAPACITY]
 jae .publish
 cmp byte [r14+r15],1
 jne .next_node
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+r15*4]
 shl rax,32
 or rax,r15
 mov rcx,1
.climb:
 mov edx,eax
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov rax,[rax+rdx*8]
 cmp rax,NEBO_INVALID_HANDLE
 je .depth
 inc rcx
 cmp rcx,[r12+NEBO_TREE_CAPACITY]
 jbe .climb
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 cmp rcx,rbp
 cmova rbp,rcx
.next_node:
 inc r15
 jmp .node
.publish:
 mov [r13],rbp
 xor eax,eax
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; preorder(tree*, out_handles[capacity], out_length*) in child slot order.
NEBOC_ABI_FUNCTION neboc_tree_preorder
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,256
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_tree_validate
 test eax,eax
 jnz .done
 cmp qword [r12+NEBO_TREE_LENGTH],0
 je .ok
 mov rax,[r12+NEBO_TREE_ROOT]
 cmp rax,NEBO_INVALID_HANDLE
 je .source
 mov [rsp],rax
 mov r15d,1
 xor ebp,ebp
.pop:
 test r15,r15
 jz .publish
 dec r15
 mov r10,[rsp+r15*8]
 mov [r13+rbp*8],r10
 inc rbp
 mov rcx,[r12+NEBO_TREE_CAPACITY]
.children_desc:
 test rcx,rcx
 jz .pop
 dec rcx
 mov rax,[r12+NEBO_TREE_ALIVE]
 cmp byte [rax+rcx],1
 jne .children_desc
 mov rax,[r12+NEBO_TREE_PARENTS]
 cmp [rax+rcx*8],r10
 jne .children_desc
 cmp r15,[r12+NEBO_TREE_CAPACITY]
 jae .limit
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov [rsp+r15*8],rax
 inc r15
 jmp .children_desc
.publish:
 mov [r14],rbp
.ok:
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,256
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; postorder(tree*, out_handles[capacity], out_length*) in child slot order.
NEBOC_ABI_FUNCTION neboc_tree_postorder
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,256
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_tree_validate
 test eax,eax
 jnz .done
 cmp qword [r12+NEBO_TREE_LENGTH],0
 je .ok
 mov rax,[r12+NEBO_TREE_ROOT]
 cmp rax,NEBO_INVALID_HANDLE
 je .source
 mov [rsp],rax
 mov r15d,1
 xor ebp,ebp
.pop:
 test r15,r15
 jz .reverse
 dec r15
 mov r10,[rsp+r15*8]
 mov [r13+rbp*8],r10
 inc rbp
 xor ecx,ecx
.children_asc:
 cmp rcx,[r12+NEBO_TREE_CAPACITY]
 jae .pop
 mov rax,[r12+NEBO_TREE_ALIVE]
 cmp byte [rax+rcx],1
 jne .next_child
 mov rax,[r12+NEBO_TREE_PARENTS]
 cmp [rax+rcx*8],r10
 jne .next_child
 cmp r15,[r12+NEBO_TREE_CAPACITY]
 jae .limit
 mov rax,[r12+NEBO_TREE_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov [rsp+r15*8],rax
 inc r15
.next_child:
 inc rcx
 jmp .children_asc
.reverse:
 xor ecx,ecx
 mov rdx,rbp
 test rdx,rdx
 jz .publish
 dec rdx
.swap:
 cmp rcx,rdx
 jae .publish
 mov rax,[r13+rcx*8]
 mov r8,[r13+rdx*8]
 mov [r13+rcx*8],r8
 mov [r13+rdx*8],rax
 inc rcx
 dec rdx
 jmp .swap
.publish:
 mov [r14],rbp
.ok:
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,256
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; lowest_common_ancestor(tree*, a, b, out_handle*, found*)
NEBOC_ABI_FUNCTION neboc_tree_lowest_common_ancestor
 test rcx,rcx
 jz .bad
 test r8,r8
 jz .bad
 push rbx
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov qword [r15],NEBO_INVALID_HANDLE
 mov qword [rbx],0
 call neboc_tree_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_tree_validate_handle
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 call neboc_tree_validate_handle
 test eax,eax
 jnz .done
 mov r10,r13
 xor ebp,ebp
.outer:
 mov r11,r14
 xor ecx,ecx
.inner:
 cmp r10,r11
 je .found
 cmp r11,NEBO_INVALID_HANDLE
 je .next_outer
 mov edx,r11d
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov r11,[rax+rdx*8]
 inc rcx
 cmp rcx,[r12+NEBO_TREE_CAPACITY]
 jbe .inner
 jmp .source
.next_outer:
 cmp r10,NEBO_INVALID_HANDLE
 je .source
 mov edx,r10d
 mov rax,[r12+NEBO_TREE_PARENTS]
 mov r10,[rax+rdx*8]
 inc rbp
 cmp rbp,[r12+NEBO_TREE_CAPACITY]
 jbe .outer
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.found:
 mov [r15],r10
 mov qword [rbx],1
 xor eax,eax
.done:
 add rsp,8
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; degree(graph*, node, out_count*) counts incident relations.
NEBOC_ABI_FUNCTION neboc_graph_degree
 test rdx,rdx
 jz .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_graph_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .done
 mov r15,rdx
 xor ebp,ebp
 xor ecx,ecx
.scan:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .publish
 mov rax,r15
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rcx
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .incoming
 inc rbp
.incoming:
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_DIRECTED
 jz .next
 cmp rcx,r15
 je .next
 mov rax,rcx
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,r15
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .next
 inc rbp
.next:
 inc rcx
 jmp .scan
.publish:
 mov [r14],rbp
 xor eax,eax
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; neighbors(graph*, node, out_handles[capacity], out_length*) outgoing slot order.
NEBOC_ABI_FUNCTION neboc_graph_neighbors
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
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
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .done
 mov rbp,rdx
 xor ecx,ecx
 xor r10d,r10d
.scan:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .publish
 mov rax,rbp
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rcx
 mov rdx,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdx+rax],0
 je .next
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rcx],1
 jne .next
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov [r14+r10*8],rax
 inc r10
.next:
 inc rcx
 jmp .scan
.publish:
 mov [r15],r10
 xor eax,eax
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; connected_components(graph*, scratch*, out_count*) for undirected graphs.
; When the optional AUX workspace is present, publish stable 1-based component
; labels per live node slot (zero for absent slots). Count and labels share the
; same canonical traversal, so public partition results do not duplicate BFS.
NEBOC_ABI_FUNCTION neboc_graph_connected_components
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_FRONTIER],0
 je .bad
 cmp qword [rsi+NEBO_GRAPH_ALGO_VISITED],0
 je .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_graph_validate
 test eax,eax
 jnz .done
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jz .source
 mov r15,[r13+NEBO_GRAPH_ALGO_VISITED]
 mov rbp,[r13+NEBO_GRAPH_ALGO_FRONTIER]
 xor ecx,ecx
.zero:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .seeds
 mov byte [r15+rcx],0
 mov rax,[r13+NEBO_GRAPH_ALGO_AUX]
 test rax,rax
 jz .label_zero_done
 mov qword [rax+rcx*8],0
.label_zero_done:
 inc rcx
 jmp .zero
.seeds:
 xor r11d,r11d
 xor ecx,ecx
.seed:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .publish
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rcx],1
 jne .next_seed
 cmp byte [r15+rcx],0
 jne .next_seed
 inc r11
 mov rax,[r13+NEBO_GRAPH_ALGO_AUX]
 test rax,rax
 jz .seed_label_done
 mov [rax+rcx*8],r11
.seed_label_done:
 mov byte [r15+rcx],1
 mov [rbp],rcx
 xor r8d,r8d
 mov r9d,1
.bfs:
 cmp r8,r9
 jae .next_seed
 mov r10,[rbp+r8*8]
 inc r8
 xor edx,edx
.neighbors:
 cmp rdx,[r12+NEBO_GRAPH_CAPACITY]
 jae .bfs
 mov rax,r10
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rdx
 mov rsi,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rsi+rax],0
 je .neighbor_next
 cmp byte [r15+rdx],0
 jne .neighbor_next
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rdx],1
 jne .neighbor_next
 cmp r9,[r12+NEBO_GRAPH_CAPACITY]
 jae .limit
 mov byte [r15+rdx],1
 mov rax,[r13+NEBO_GRAPH_ALGO_AUX]
 test rax,rax
 jz .neighbor_label_done
 mov [rax+rdx*8],r11
.neighbor_label_done:
 mov [rbp+r9*8],rdx
 inc r9
.neighbor_next:
 inc rdx
 jmp .neighbors
.next_seed:
 inc rcx
 jmp .seed
.publish:
 mov [r14],r11
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; has_cycle(graph*, scratch*, out_bool*) for directed or undirected graphs.
NEBOC_ABI_FUNCTION neboc_graph_has_cycle
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 push r12
 push r13
 push r14
 push r15
 push rbp
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [r14],0
 call neboc_graph_validate
 test eax,eax
 jnz .done
 test qword [r12+NEBO_GRAPH_FLAGS],NEBO_GRAPH_UNDIRECTED
 jnz .undirected
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_topological_sort
 test eax,eax
 jz .ok
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .done
 mov qword [r14],1
 xor eax,eax
 jmp .done
.undirected:
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_graph_connected_components
 test eax,eax
 jnz .done
 mov rax,[r12+NEBO_GRAPH_LENGTH]
 sub rax,[rsp]
 cmp [r12+NEBO_GRAPH_EDGE_COUNT],rax
 jbe .ok
 mov qword [r14],1
.ok:
 xor eax,eax
.done:
 add rsp,16
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; dijkstra(graph*, from, to, scratch*, out_cost*); path uses scratch output.
NEBOC_ABI_FUNCTION neboc_graph_dijkstra
 test rcx,rcx
 jz .bad
 test r8,r8
 jz .bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_FRONTIER],0
 je .bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_AUX],0
 je .bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_VISITED],0
 je .bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_OUTPUT],0
 je .bad
 cmp qword [rcx+NEBO_GRAPH_ALGO_OUT_LENGTH],0
 je .bad
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
 mov qword [rbp],-1
 mov rax,[r15+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov qword [rax],0
 call neboc_graph_validate
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 call neboc_graph_validate_handle
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r14
 call neboc_graph_validate_handle
 test eax,eax
 jnz .done
 mov r8,[r15+NEBO_GRAPH_ALGO_AUX]
 mov r9,[r15+NEBO_GRAPH_ALGO_VISITED]
 mov r10,[r15+NEBO_GRAPH_ALGO_FRONTIER]
 xor ecx,ecx
.zero:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .seed
 mov qword [r8+rcx*8],-1
 mov byte [r9+rcx],0
 mov qword [r10+rcx*8],NEBO_INVALID_HANDLE
 inc rcx
 jmp .zero
.seed:
 mov ecx,r13d
 mov qword [r8+rcx*8],0
 xor r11d,r11d
.outer:
 cmp r11,[r12+NEBO_GRAPH_LENGTH]
 jae .finish
 mov rcx,NEBO_INVALID_HANDLE
 mov rdx,-1
 xor esi,esi
.select:
 cmp rsi,[r12+NEBO_GRAPH_CAPACITY]
 jae .selected
 mov rax,[r12+NEBO_GRAPH_ALIVE]
 cmp byte [rax+rsi],1
 jne .select_next
 cmp byte [r9+rsi],0
 jne .select_next
 mov rax,[r8+rsi*8]
 cmp rax,rdx
 jae .select_next
 mov rdx,rax
 mov rcx,rsi
.select_next:
 inc rsi
 jmp .select
.selected:
 cmp rcx,NEBO_INVALID_HANDLE
 je .finish
 cmp rdx,-1
 je .finish
 mov byte [r9+rcx],1
 cmp ecx,r14d
 je .finish
 xor esi,esi
.relax:
 cmp rsi,[r12+NEBO_GRAPH_CAPACITY]
 jae .outer_next
 mov rax,rcx
 imul rax,[r12+NEBO_GRAPH_CAPACITY]
 add rax,rsi
 mov rdi,[r12+nebo_graph_GRAPH_ADJACENCY_semantic_graph_native_vertical]
 cmp byte [rdi+rax],0
 je .relax_next
 mov rdi,[r12+NEBO_GRAPH_WEIGHTS]
 mov rdi,[rdi+rax*8]
 mov rax,rdx
 add rax,rdi
 jc .limit
 cmp rax,[r8+rsi*8]
 jae .relax_next
 mov [r8+rsi*8],rax
 mov [r10+rsi*8],rcx
.relax_next:
 inc rsi
 jmp .relax
.outer_next:
 inc r11
 jmp .outer
.finish:
 mov ecx,r14d
 mov rax,[r8+rcx*8]
 cmp rax,-1
 je .ok
 mov [rbp],rax
 xor r11d,r11d
.back:
 cmp r11,[r12+NEBO_GRAPH_CAPACITY]
 jae .limit
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov rdx,[r15+NEBO_GRAPH_ALGO_OUTPUT]
 mov [rdx+r11*8],rax
 inc r11
 cmp ecx,r13d
 je .reverse
 mov rcx,[r10+rcx*8]
 cmp rcx,NEBO_INVALID_HANDLE
 je .source
 jmp .back
.reverse:
 xor ecx,ecx
 mov rdx,r11
 dec rdx
 mov rsi,[r15+NEBO_GRAPH_ALGO_OUTPUT]
.swap:
 cmp rcx,rdx
 jae .publish
 mov rax,[rsi+rcx*8]
 mov rdi,[rsi+rdx*8]
 mov [rsi+rcx*8],rdi
 mov [rsi+rdx*8],rax
 inc rcx
 dec rdx
 jmp .swap
.publish:
 mov rax,[r15+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov [rax],r11
.ok:
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov rax,[r15+NEBO_GRAPH_ALGO_OUT_LENGTH]
 mov qword [rax],0
 mov qword [rbp],-1
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 pop rbp
 pop r15
 pop r14
 pop r13
 pop r12
 ret
.bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
