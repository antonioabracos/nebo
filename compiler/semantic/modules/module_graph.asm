; IDENTIDADE-DE-MODULOS-SOURCE-UNITS-ROOTS-E-MODULE-GRAPH-DETERMINISTICO-F04 bounded deterministic module graph and topological order.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/modules/modules.inc"

section .text

; graph_order(nodes*, node_count, edges*, edge_count, out_indices*, cap)
; -> status. Nodes carry stable ModuleId digests; edges carry from/to indices.
NEBOC_ABI_FUNCTION neboc_module_graph_order
 test rdi,rdi
 jz .invalid_argument
 test rdi,7
 jnz .invalid_argument
 test rdx,rdx
 jz .invalid_argument
 test rdx,7
 jnz .invalid_argument
 test r8,r8
 jz .invalid_argument
 test r8,7
 jnz .invalid_argument
 test rsi,rsi
 jz .invalid_source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .limit
 cmp rcx,NEBOC_MODULE_MAX_EDGES
 ja .limit
 cmp r9,rsi
 jb .limit
 mov rax,rsi
 shl rax,3
 lea r11,[rdi+rax]
 mov rax,rcx
 shl rax,4
 lea r10,[rdx+rax]
 mov rax,rsi
 shl rax,3
 lea rax,[r8+rax]
 cmp rdi,rax
 jae .nodes_output_ok
 cmp r8,r11
 jb .invalid_argument
.nodes_output_ok:
 cmp rdx,rax
 jae .ranges_ok
 cmp r8,r10
 jb .invalid_argument
.ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,576                 ; 64 indegree bytes + 64 qword order slots
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbp,rcx
 mov r10,r8
 mov r11,r9
 xor eax,eax
 mov ecx,72
 mov rdi,rsp
 rep stosq
 ; Validate nonzero unique ModuleId digests.
 xor ebx,ebx
.node_outer:
 cmp rbx,r13
 jae .edges
 mov rax,[r12+rbx*8]
 test rax,rax
 jz .bad_source
 lea r8,[rbx+1]
.node_inner:
 cmp r8,r13
 jae .node_next
 cmp rax,[r12+r8*8]
 je .bad_source
 inc r8
 jmp .node_inner
.node_next:
 inc rbx
 jmp .node_outer
 ; Validate edges, reject duplicates/self edges and calculate indegree.
.edges:
 xor ebx,ebx
.edge_loop:
 cmp rbx,rbp
 jae .kahn
 mov rax,rbx
 shl rax,4
 mov r8,[r14+rax+NEBOC_GRAPH_EDGE_FROM]
 mov r9,[r14+rax+NEBOC_GRAPH_EDGE_TO]
 cmp r8,r13
 jae .bad_source
 cmp r9,r13
 jae .bad_source
 cmp r8,r9
 je .cycle
 mov rdx,rbx
 inc rdx
.duplicate_edge:
 cmp rdx,rbp
 jae .edge_unique
 mov rcx,rdx
 shl rcx,4
 cmp r8,[r14+rcx+NEBOC_GRAPH_EDGE_FROM]
 jne .duplicate_next
 cmp r9,[r14+rcx+NEBOC_GRAPH_EDGE_TO]
 je .bad_source
.duplicate_next:
 inc rdx
 jmp .duplicate_edge
.edge_unique:
 cmp byte [rsp+r9],255
 je .limit_local
 inc byte [rsp+r9]
 inc rbx
 jmp .edge_loop

.kahn:
 xor r15d,r15d
 xor ebx,ebx
.position:
 cmp rbx,r13
 jae .publish
 mov r8,-1
 xor r9d,r9d
.candidate:
 cmp r9,r13
 jae .candidate_done
 bt r15,r9
 jc .candidate_next
 cmp byte [rsp+r9],0
 jne .candidate_next
 cmp r8,-1
 je .choose
 mov rax,[r12+r9*8]
 cmp rax,[r12+r8*8]
 jae .candidate_next
.choose:
 mov r8,r9
.candidate_next:
 inc r9
 jmp .candidate
.candidate_done:
 cmp r8,-1
 je .cycle
 mov [rsp+64+rbx*8],r8
 bts r15,r8
 ; Remove outgoing edges from the selected node.
 xor r9d,r9d
.remove_edges:
 cmp r9,rbp
 jae .position_next
 mov rax,r9
 shl rax,4
 cmp r8,[r14+rax+NEBOC_GRAPH_EDGE_FROM]
 jne .remove_next
 mov rdx,[r14+rax+NEBOC_GRAPH_EDGE_TO]
 cmp byte [rsp+rdx],0
 je .internal
 dec byte [rsp+rdx]
.remove_next:
 inc r9
 jmp .remove_edges
.position_next:
 inc rbx
 jmp .position

.publish:
 xor ebx,ebx
.publish_loop:
 cmp rbx,r13
 jae .ok
 mov rax,[rsp+64+rbx*8]
 mov [r10+rbx*8],rax
 inc rbx
 jmp .publish_loop
.ok:
 xor eax,eax
 jmp .done
.cycle:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit_local:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,576
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_argument:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.invalid_source:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; graph_build(nodes*, node_count, edges*, edge_count, out_snapshot*) -> status.
; The digest is normalized through the deterministic topological order and an
; adjacency matrix, so input enumeration order cannot affect the snapshot.
NEBOC_ABI_FUNCTION neboc_module_graph_build
 test rdi,rdi
 jz .build_arg
 test rdx,rdx
 jz .build_arg
 test r8,r8
 jz .build_arg
 test r8,7
 jnz .build_arg
 test rsi,rsi
 jz .build_source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .build_limit
 cmp rcx,NEBOC_MODULE_MAX_EDGES
 ja .build_limit
 mov rax,rsi
 shl rax,3
 mov r9,rdi
 add r9,rax
 jc .build_arg
 mov rax,rcx
 shl rax,4
 mov r10,rdx
 add r10,rax
 jc .build_arg
 mov r11,r8
 add r11,8
 jc .build_arg
 cmp rdi,r11
 jae .build_nodes_range_ok
 cmp r8,r9
 jb .build_arg
.build_nodes_range_ok:
 cmp rdx,r11
 jae .build_ranges_ok
 cmp r8,r10
 jb .build_arg
.build_ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,520
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 lea r8,[rsp]
 mov r9,r13
 call neboc_module_graph_order
 test eax,eax
 jnz .build_done
 mov rbx,0xcbf29ce484222325
 mov r11,0x100000001b3
 xor ecx,ecx
.build_nodes:
 cmp rcx,r13
 jae .build_edges
 mov rax,[rsp+rcx*8]
 mov rax,[r12+rax*8]
 xor rbx,rax
 imul rbx,r11
 inc rcx
 jmp .build_nodes
.build_edges:
 xor ecx,ecx
.build_from:
 cmp rcx,r13
 jae .build_publish
 xor edx,edx
.build_to:
 cmp rdx,r13
 jae .build_next_from
 mov r8,[rsp+rcx*8]
 mov r9,[rsp+rdx*8]
 xor r10d,r10d
 xor eax,eax
.build_edge_scan:
 cmp rax,r15
 jae .build_edge_bit
 mov rsi,rax
 shl rsi,4
 cmp r8,[r14+rsi+NEBOC_GRAPH_EDGE_FROM]
 jne .build_edge_next
 cmp r9,[r14+rsi+NEBOC_GRAPH_EDGE_TO]
 jne .build_edge_next
 mov r10d,1
.build_edge_next:
 inc rax
 jmp .build_edge_scan
.build_edge_bit:
 xor rbx,r10
 imul rbx,r11
 inc rdx
 jmp .build_to
.build_next_from:
 inc rcx
 jmp .build_from
.build_publish:
 xor rbx,r13
 imul rbx,r11
 xor rbx,r15
 test rbx,rbx
 jnz .build_store
 mov ebx,1
.build_store:
 mov [rbp],rbx
 xor eax,eax
.build_done:
 add rsp,520
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.build_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.build_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.build_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; graph_detect_cycles uses the graph owner itself and never publishes output.
NEBOC_ABI_FUNCTION neboc_module_graph_detect_cycles
 test rsi,rsi
 jz .detect_source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .detect_limit
 sub rsp,520
 lea r8,[rsp]
 mov r9,rsi
 call neboc_module_graph_order
 add rsp,520
 ret
.detect_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.detect_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED

; graph_explain(nodes*, node_count, edges*, edge_count, module_id, out*)
; publishes identity, deterministic topological rank and degree facts.
NEBOC_ABI_FUNCTION neboc_module_graph_explain
 test rdi,rdi
 jz .explain_arg
 test rdi,7
 jnz .explain_arg
 test rdx,rdx
 jz .explain_arg
 test rdx,7
 jnz .explain_arg
 test r9,r9
 jz .explain_arg
 test r9,7
 jnz .explain_arg
 test r8,r8
 jz .explain_source
 test rsi,rsi
 jz .explain_source
 cmp rsi,NEBOC_MODULE_MAX_NODES
 ja .explain_limit
 cmp rcx,NEBOC_MODULE_MAX_EDGES
 ja .explain_limit
 mov rax,rsi
 shl rax,3
 mov r10,rdi
 add r10,rax
 jc .explain_arg
 mov rax,rcx
 shl rax,4
 mov r11,rdx
 add r11,rax
 jc .explain_arg
 mov rax,r9
 add rax,NEBOC_MODULE_EXPLAIN_SIZE
 jc .explain_arg
 cmp rdi,rax
 jae .explain_nodes_range_ok
 cmp r9,r10
 jb .explain_arg
.explain_nodes_range_ok:
 cmp rdx,rax
 jae .explain_ranges_ok
 cmp r9,r11
 jb .explain_arg
.explain_ranges_ok:
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 sub rsp,552
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbp,r8
 mov [rsp+520],r9
 mov [rsp+528],r8
 lea r8,[rsp]
 mov r9,r13
 call neboc_module_graph_order
 test eax,eax
 jnz .explain_done
 mov r10,-1
 xor ecx,ecx
.explain_rank_scan:
 cmp rcx,r13
 jae .explain_rank_done
 mov rax,[rsp+rcx*8]
 cmp rbp,[r12+rax*8]
 jne .explain_rank_next
 mov r10,rcx
 mov r11,rax
.explain_rank_next:
 inc rcx
 jmp .explain_rank_scan
.explain_rank_done:
 cmp r10,-1
 je .explain_source_status
 xor ebx,ebx
 xor ebp,ebp
 xor ecx,ecx
.explain_edge_scan:
 cmp rcx,r15
 jae .explain_publish
 mov rax,rcx
 shl rax,4
 cmp r11,[r14+rax+NEBOC_GRAPH_EDGE_FROM]
 jne .explain_not_outgoing
 inc rbp
.explain_not_outgoing:
 cmp r11,[r14+rax+NEBOC_GRAPH_EDGE_TO]
 jne .explain_edge_next
 inc rbx
.explain_edge_next:
 inc rcx
 jmp .explain_edge_scan
.explain_publish:
 mov r9,[rsp+520]
 mov rax,[rsp+528]
 mov [r9+NEBOC_MODULE_EXPLAIN_ID],rax
 mov [r9+NEBOC_MODULE_EXPLAIN_TOPOLOGICAL_RANK],r10
 mov [r9+NEBOC_MODULE_EXPLAIN_INCOMING],rbx
 mov [r9+NEBOC_MODULE_EXPLAIN_OUTGOING],rbp
 xor eax,eax
 jmp .explain_done
.explain_source_status:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.explain_done:
 add rsp,552
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.explain_arg: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.explain_source: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_SOURCE
.explain_limit: NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
