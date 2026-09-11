; Typed source bridge to the canonical bounded G009 owners. Node values are
; {owner pointer, generation-tagged handle, owner kind}; no raw source integer
; can masquerade as a handle, including a handle from a different structure.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/semantic/graph/graph_contract.inc"
extern neboc_tree_init
extern neboc_tree_add
extern neboc_tree_validate
extern neboc_tree_validate_handle
extern neboc_tree_get
extern neboc_tree_replace
extern neboc_tree_root
extern neboc_tree_height
extern neboc_tree_parent
extern neboc_tree_children
extern neboc_tree_remove_subtree
extern neboc_tree_lowest_common_ancestor
extern neboc_tree_degree
extern neboc_tree_preorder
extern neboc_tree_postorder
extern neboc_graph_init
extern neboc_graph_validate
extern neboc_graph_validate_handle
extern neboc_graph_get_node
extern neboc_graph_replace_node
extern neboc_graph_degree
extern neboc_graph_add_node
extern neboc_graph_add_edge
extern neboc_graph_remove_node
extern neboc_graph_remove_edge
extern neboc_graph_neighbors
extern neboc_graph_connected_components
extern neboc_graph_has_cycle
extern neboc_graph_topological_sort
extern neboc_graph_shortest_path_unweighted
extern neboc_graph_dijkstra
extern neboc_traversal_begin
extern neboc_traversal_next
extern neboc_traversal_release
extern nebo_runtime_trap
section .text
NEBOC_ABI_FUNCTION nebo_relational_call
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp+48],r9
 cmp ebx,250
 jae .graph
 cmp ebx,201
 jbe .tree_new
 cmp ebx,220
 jb .tree
 cmp ebx,223
 jbe .node
 cmp ebx,241
 je .option_some
 cmp ebx,242
 je .option_none
 cmp ebx,243
 je .option_expect
 cmp ebx,244
 je .sequence_next
 cmp ebx,245
 je .sequence_length
 jmp .trap
.tree_new:
 mov rdi,r15
 lea rsi,[r15+80]
 lea rdx,[r15+336]
 lea rcx,[r15+464]
 lea r8,[r15+496]
 mov r9d,32
 call neboc_tree_init
 test eax,eax
 jnz .trap
 mov rdi,r15
 mov rsi,NEBO_INVALID_HANDLE
 mov rdx,r13
 lea rcx,[rsp]
 call neboc_tree_add
 test eax,eax
 jnz .trap
 cmp ebx,200
 je .result
 mov r12,r15
 add r15,768
 mov rax,[rsp]
 jmp .node_result
.tree:
 mov rdi,r12
 call neboc_tree_validate
 test eax,eax
 jnz .trap
 cmp ebx,202
 je .root
 cmp ebx,203
 je .height
 cmp ebx,209
 je .preorder
 cmp ebx,210
 je .postorder
 ; All mutators and ancestry queries authenticate the source handle's owner.
 cmp [r13],r12
 jne .trap
 cmp qword [r13+16],1
 jne .trap
 mov rsi,[r13+8]
 cmp ebx,204
 je .add
 cmp ebx,205
 je .remove
 cmp ebx,206
 je .parent
 cmp ebx,207
 je .children
 cmp ebx,208
 je .lca
 jmp .trap
.root:
 lea rsi,[rsp]
 lea rdx,[rsp+8]
 call neboc_tree_root
 test eax,eax
 jnz .trap
 cmp qword [rsp+8],1
 jne .trap
 mov rax,[rsp]
 jmp .node_result
.height:
 mov rsi,r15
 call neboc_tree_height
 jmp .scalar_status
.add:
 mov rdx,r14
 lea rcx,[rsp]
 call neboc_tree_add
 test eax,eax
 jnz .trap
 mov rax,[rsp]
 jmp .node_result
.remove:
 mov rax,[r12+NEBO_TREE_LENGTH]
 mov [rsp],rax
 call neboc_tree_remove_subtree
 test eax,eax
 jnz .trap
 mov rax,[rsp]
 sub rax,[r12+NEBO_TREE_LENGTH]
 jmp .done
.parent:
 lea rdx,[r15+16]
 mov rcx,r15
 call neboc_tree_parent
 jmp .optional_status
.lca:
 cmp [r14],r12
 jne .trap
 cmp qword [r14+16],1
 jne .trap
 mov rdx,[r14+8]
 lea rcx,[r15+16]
 mov r8,r15
 call neboc_tree_lowest_common_ancestor
.optional_status:
 test eax,eax
 jnz .trap
 mov [r15+8],r12
 mov qword [r15+24],1
 jmp .result
.children:
 lea rdx,[r15+32]
 lea rcx,[r15+16]
 call neboc_tree_children
 jmp .sequence_status
.preorder:
 lea rsi,[r15+32]
 lea rdx,[r15+16]
 call neboc_tree_preorder
 jmp .sequence_status
.postorder:
 lea rsi,[r15+32]
 lea rdx,[r15+16]
 call neboc_tree_postorder
.sequence_status:
 test eax,eax
 jnz .trap
 mov [r15],r12
 mov qword [r15+8],1
 mov qword [r15+24],0
 jmp .result
.sequence_length:
 mov rax,[r12+16]
 jmp .done
.sequence_next:
 mov qword [r15],0
 mov rax,[r12+24]
 cmp rax,[r12+16]
 jae .result
 mov rdx,[r12+32+rax*8]
 inc qword [r12+24]
 mov qword [r15],1
 mov [r15+16],rdx
 mov rax,[r12]
 mov [r15+8],rax
 mov rax,[r12+8]
 mov [r15+24],rax
 jmp .result
.option_some:
 mov rax,[r12]
 jmp .done
.option_none:
 xor eax,eax
 cmp qword [r12],0
 sete al
 jmp .done
.option_expect:
 cmp qword [r12],1
 jne .trap
 lea rax,[r12+8]
 jmp .done
.node:
 cmp qword [r12+16],2
 je .graph_node
 cmp qword [r12+16],1
 jne .trap
 mov rdi,[r12]
 call neboc_tree_validate
 test eax,eax
 jnz .trap
 mov rdi,[r12]
 mov rsi,[r12+8]
 call neboc_tree_validate_handle
 test eax,eax
 jnz .trap
 mov rdi,[r12]
 mov rsi,[r12+8]
 cmp ebx,221
 je .node_id
 cmp ebx,222
 je .node_replace
 mov rdx,r15
 cmp ebx,223
 je .node_degree
 call neboc_tree_get
 jmp .scalar_status
.node_degree:
 call neboc_tree_degree
 jmp .scalar_status
.node_replace:
 mov rdx,r13
 mov rcx,r15
 call neboc_tree_replace
 jmp .scalar_status
.node_id:
 mov rax,rsi
 jmp .done
.graph_node:
 mov rdi,[r12]
 call neboc_graph_validate
 test eax,eax
 jnz .trap
 mov rdi,[r12]
 mov rsi,[r12+8]
 call neboc_graph_validate_handle
 test eax,eax
 jnz .trap
 mov rdi,[r12]
 mov rsi,[r12+8]
 cmp ebx,221
 je .node_id
 cmp ebx,222
 je .graph_node_replace
 mov rdx,r15
 cmp ebx,223
 je .graph_node_degree
 call neboc_graph_get_node
 jmp .scalar_status
.graph_node_degree:
 call neboc_graph_degree
 jmp .scalar_status
.graph_node_replace:
 mov rdx,r13
 mov rcx,r15
 call neboc_graph_replace_node
 jmp .scalar_status
.node_result:
 mov [r15],r12
 mov [r15+8],rax
 mov qword [r15+16],1
.result:
 mov rax,r15
 jmp .done

.graph:
 cmp ebx,280
 je .components_next
 cmp ebx,270
 jae .traversal
 cmp ebx,251
 jbe .graph_new
 mov rdi,r12
 call neboc_graph_validate
 test eax,eax
 jnz .trap
 cmp ebx,260
 jae .graph_algorithm
 cmp ebx,252
 je .graph_add_node
 cmp [r13],r12
 jne .trap
 cmp ebx,255
 je .graph_remove_edge
 cmp qword [r13+16],2
 jne .trap
 mov rsi,[r13+8]
 cmp ebx,253
 je .graph_add_edge
 cmp ebx,254
 je .graph_remove_node
 cmp ebx,256
 je .graph_neighbors
 jmp .trap
.graph_new:
 lea rax,[r15+96]
 mov [rsp],rax
 lea rax,[r15+352]
 mov [rsp+8],rax
 lea rax,[r15+480]
 mov [rsp+16],rax
 lea rax,[r15+512]
 mov [rsp+24],rax
 lea rax,[r15+1536]
 mov [rsp+32],rax
 mov rdi,r15
 mov rsi,rsp
 mov edx,32
 mov ecx,NEBO_GRAPH_DIRECTED
 cmp ebx,250
 je .graph_flags_ready
 mov ecx,NEBO_GRAPH_UNDIRECTED
.graph_flags_ready:
 call neboc_graph_init
 test eax,eax
 jnz .trap
 jmp .result
.graph_add_node:
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_graph_add_node
 test eax,eax
 jnz .trap
 mov [r15],r12
 mov rax,[rsp]
 mov [r15+8],rax
 mov qword [r15+16],2
 jmp .result
.graph_add_edge:
 cmp [r14],r12
 jne .trap
 cmp qword [r14+16],2
 jne .trap
 mov rdx,[r14+8]
 mov rcx,[rsp+48]
 call neboc_graph_add_edge
 test eax,eax
 jnz .trap
 mov [r15],r12
 mov rax,[r13+8]
 mov [r15+8],rax
 mov rax,[r14+8]
 mov [r15+16],rax
 jmp .result
.graph_remove_node:
 call neboc_graph_remove_node
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.graph_remove_edge:
 mov rsi,[r13+8]
 mov rdx,[r13+16]
 mov rcx,r15
 call neboc_graph_remove_edge
 jmp .scalar_status
.graph_neighbors:
 lea rdx,[r15+32]
 lea rcx,[r15+16]
 call neboc_graph_neighbors
 test eax,eax
 jnz .trap
 mov [r15],r12
 mov qword [r15+8],2
 mov qword [r15+24],0
 jmp .result

; A private aligned result region supplies the existing algorithm scratch
; bundle. Published paths are independently owned generation-tagged handles.
.algorithm_storage:
 mov [r15],r12
 mov qword [r15+8],2
 mov qword [r15+16],0
 mov qword [r15+24],0
 lea rax,[r15+336]
 mov [r15+288],rax
 lea rax,[r15+592]
 mov [r15+296],rax
 lea rax,[r15+848]
 mov [r15+304],rax
 lea rax,[r15+32]
 mov [r15+312],rax
 lea rax,[r15+16]
 mov [r15+320],rax
 mov rdi,r12
 lea rsi,[r15+288]
 ret
.graph_algorithm:
 call .algorithm_storage
 cmp ebx,260
 je .graph_cycle
 cmp ebx,261
 je .graph_topological
 cmp ebx,264
 je .graph_components
 cmp [r13],r12
 jne .trap
 cmp [r14],r12
 jne .trap
 cmp qword [r13+16],2
 jne .trap
 cmp qword [r14+16],2
 jne .trap
 mov rcx,rsi
 mov rsi,[r13+8]
 mov rdx,[r14+8]
 cmp ebx,262
 je .graph_shortest
 cmp ebx,263
 jne .trap
 lea r8,[r15+880]
 call neboc_graph_dijkstra
 jmp .path_status
.graph_shortest:
 call neboc_graph_shortest_path_unweighted
 jmp .path_status
.graph_cycle:
 lea rdx,[r15+888]
 call neboc_graph_has_cycle
 test eax,eax
 jnz .trap
 mov rax,[r15+888]
 jmp .done

.graph_components:
 lea rdx,[r15+16]
 call neboc_graph_connected_components
 test eax,eax
 jnz .trap
 xor ecx,ecx
.component_snapshot:
 cmp rcx,[r12+NEBO_GRAPH_CAPACITY]
 jae .result
 mov rax,[r15+592+rcx*8]
 mov [r15+32+rcx*8],rax
 mov rax,[r12+NEBO_GRAPH_GENERATIONS]
 mov eax,[rax+rcx*4]
 shl rax,32
 or rax,rcx
 mov [r15+288+rcx*8],rax
 inc rcx
 jmp .component_snapshot
.components_next:
 mov qword [r15],0
 mov rax,[r12+24]
 cmp rax,[r12+16]
 jae .result
 inc rax
 mov [r12+24],rax
 mov qword [r15],1
 mov rdx,[r12]
 mov [r15+8],rdx
 mov qword [r15+16],2
 mov qword [r15+24],0
 mov qword [r15+32],0
 xor ecx,ecx
 xor edx,edx
.component_members:
 cmp ecx,32
 jae .component_published
 cmp [r12+32+rcx*8],rax
 jne .component_member_next
 mov rsi,[r12+288+rcx*8]
 mov [r15+40+rdx*8],rsi
 inc rdx
.component_member_next:
 inc ecx
 jmp .component_members
.component_published:
 mov [r15+24],rdx
 jmp .result
.graph_topological:
 call neboc_graph_topological_sort
.path_status:
 test eax,eax
 jnz .trap
 jmp .result
.traversal:
 cmp ebx,275
 je .traversal_slot_init
 cmp ebx,274
 je .traversal_auto_release
 cmp ebx,271
 jbe .traversal_new
 cmp qword [r12+NEBO_TRAVERSAL_RELEASED],0
 jne .trap
 cmp ebx,272
 je .traversal_next
 cmp ebx,273
 je .traversal_release
 cmp ebx,276
 je .traversal_stop
 cmp ebx,277
 je .traversal_path
 jmp .trap
.traversal_slot_init:
 mov qword [r12+NEBO_TRAVERSAL_RELEASED],1
 xor eax,eax
 jmp .done
.traversal_auto_release:
 cmp qword [r12+NEBO_TRAVERSAL_RELEASED],0
 jne .traversal_void
.traversal_release:
 mov rdi,r12
 call neboc_traversal_release
 test eax,eax
 jnz .trap
.traversal_void:
 xor eax,eax
 jmp .done
.traversal_new:
 cmp [r13],r12
 jne .trap
 cmp qword [r13+16],2
 jne .trap
 mov rdi,r15
 mov rsi,r12
 mov rdx,[r13+8]
 lea rcx,[r15+80]
 lea r8,[r15+336]
 mov r9d,NEBO_TRAVERSAL_BFS
 cmp ebx,270
 je .traversal_kind
 mov r9d,NEBO_TRAVERSAL_DFS
.traversal_kind:
 call neboc_traversal_begin
 test eax,eax
 jnz .trap
 mov rax,[r13+8]
 mov [r15+368],rax
 mov qword [r15+376],NEBO_INVALID_HANDLE
 mov qword [r15+384],0
 mov qword [r15+392],0
 jmp .result
.traversal_next:
 mov qword [r15],0
 cmp qword [r12+392],0
 jne .result
 mov rdi,r12
 lea rsi,[r15+16]
 mov rdx,r15
 call neboc_traversal_next
 test eax,eax
 jnz .trap
 mov rax,[r12+NEBO_TRAVERSAL_OWNER]
 mov [r15+8],rax
 mov qword [r15+24],2
 cmp qword [r15],1
 jne .result
 mov rsi,[r15+16]
 mov [r12+376],rsi
 cmp qword [r12+384],0
 je .result
 mov rdi,rax
 mov rdx,rsp
 call neboc_graph_get_node
 test eax,eax
 jnz .trap
 mov rdi,[rsp]
 call [r12+384]
 cmp rax,1
 ja .trap
 mov [r12+392],rax
 jmp .result
.traversal_stop:
 mov [r12+384],r13
 jmp .traversal_void
.traversal_path:
 ; The bounded path observation is defined for BFS. Its independent native
 ; shortest-path owner reconstructs the current route from the original start.
 cmp qword [r12+NEBO_TRAVERSAL_KIND],NEBO_TRAVERSAL_BFS
 jne .trap
 mov r13,[r12+368]
 mov r14,[r12+376]
 cmp r14,NEBO_INVALID_HANDLE
 je .trap
 mov r12,[r12+NEBO_TRAVERSAL_OWNER]
 call .algorithm_storage
 mov rcx,rsi
 mov rsi,r13
 mov rdx,r14
 call neboc_graph_shortest_path_unweighted
 jmp .path_status
.scalar_status:
 test eax,eax
 jnz .trap
 mov rax,[r15]
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.trap:
 mov edi,49 ; canonical runtime trap adapter publishes 128 + trap class
 call nebo_runtime_trap
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
