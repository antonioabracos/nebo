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
 test rdx,rdx
 jz .invalid_argument
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
