; WHOLE-PROGRAM-GRAPH-F01 bounded explainable conservative reachability graph.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/reachability/whole_program_graph.inc"
section .text
; rdi=graph rsi=id -> rax=node.
wpg_find:
 mov rax,[rdi+NEBOC_WPG_NODES_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_WPG_NODE_COUNT_OFFSET]
 jae .missing
 cmp [rax+NEBOC_WPG_NODE_ID_OFFSET],rsi
 je .done
 add rax,NEBOC_WPG_NODE_SIZE
 inc rcx
 jmp .loop
.missing: xor eax,eax
.done: ret

; Propagate all known and conservative-target edges from reachable nodes.
wpg_propagate:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
.again:
 xor r14d,r14d
 xor r15d,r15d
.edge:
 cmp r15,[rbx+NEBOC_WPG_EDGE_COUNT_OFFSET]
 jae .round
 mov rax,r15
 shl rax,5
 add rax,[rbx+NEBOC_WPG_EDGES_OFFSET]
 mov r12,[rax+NEBOC_WPG_EDGE_FROM_OFFSET]
 mov r13,[rax+NEBOC_WPG_EDGE_TO_OFFSET]
 test r13,r13
 jz .next
 mov rdi,rbx
 mov rsi,r12
 call wpg_find
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 jne .next
 mov rdi,rbx
 mov rsi,r13
 call wpg_find
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 je .next
 mov qword [rax+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 mov [rax+NEBOC_WPG_NODE_PARENT_OFFSET],r12
 inc qword [rbx+NEBOC_WPG_REACHABLE_OFFSET]
 mov r14d,1
.next: inc r15
 jmp .edge
.round:
 test r14,r14
 jnz .again
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_whole_program_graph_build
 ; rdi=graph rsi=config.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_WPG_CONFIG_NODES_OFFSET],0
 je .invalid
 mov r8,[rsi+NEBOC_WPG_CONFIG_NODE_COUNT_OFFSET]
 test r8,r8
 jz .invalid
 cmp r8,NEBOC_WPG_MAX_NODES
 ja .limit
 mov r9,[rsi+NEBOC_WPG_CONFIG_EDGE_COUNT_OFFSET]
 cmp r9,NEBOC_WPG_MAX_EDGES
 ja .limit
 test r9,r9
 jz .policy
 cmp qword [rsi+NEBOC_WPG_CONFIG_EDGES_OFFSET],0
 je .invalid
.policy:
 mov rax,[rsi+NEBOC_WPG_CONFIG_POLICY_OFFSET]
 cmp rax,NEBOC_WPG_POLICY_CLOSED
 je .publish
 cmp rax,NEBOC_WPG_POLICY_OPEN
 jne .invalid
.publish:
 mov r10,rdi
 xor eax,eax
 mov ecx,NEBOC_WPG_SIZE/8
 rep stosq
 mov rax,[rsi+NEBOC_WPG_CONFIG_NODES_OFFSET]
 mov [r10+NEBOC_WPG_NODES_OFFSET],rax
 mov [r10+NEBOC_WPG_NODE_COUNT_OFFSET],r8
 mov rax,[rsi+NEBOC_WPG_CONFIG_EDGES_OFFSET]
 mov [r10+NEBOC_WPG_EDGES_OFFSET],rax
 mov [r10+NEBOC_WPG_EDGE_COUNT_OFFSET],r9
 mov rax,[rsi+NEBOC_WPG_CONFIG_TARGET_OFFSET]
 mov [r10+NEBOC_WPG_TARGET_OFFSET],rax
 mov rax,[rsi+NEBOC_WPG_CONFIG_POLICY_OFFSET]
 mov [r10+NEBOC_WPG_POLICY_OFFSET],rax
 ; Validate canonical nodes and reset execution fields.
 mov rdi,[r10+NEBOC_WPG_NODES_OFFSET]
 xor ecx,ecx
.nodes:
 cmp rcx,r8
 jae .edges
 cmp qword [rdi+NEBOC_WPG_NODE_ID_OFFSET],0
 je .invalid_published
 test rcx,rcx
 jz .node_ok
 mov rax,[rdi-NEBOC_WPG_NODE_SIZE+NEBOC_WPG_NODE_ID_OFFSET]
 cmp rax,[rdi+NEBOC_WPG_NODE_ID_OFFSET]
 jae .invalid_published
.node_ok:
 mov qword [rdi+NEBOC_WPG_NODE_REACHABLE_OFFSET],0
 mov qword [rdi+NEBOC_WPG_NODE_PARENT_OFFSET],0
 mov qword [rdi+NEBOC_WPG_NODE_ROOT_REASON_OFFSET],0
 add rdi,NEBOC_WPG_NODE_SIZE
 inc rcx
 jmp .nodes
.edges:
 xor r11d,r11d
.edge_loop:
 cmp r11,r9
 jae .active
 mov rax,r11
 shl rax,5
 add rax,[r10+NEBOC_WPG_EDGES_OFFSET]
 mov rdi,r10
 mov rsi,[rax+NEBOC_WPG_EDGE_FROM_OFFSET]
 call wpg_find
 test rax,rax
 jz .invalid_published
 mov rax,r11
 shl rax,5
 add rax,[r10+NEBOC_WPG_EDGES_OFFSET]
 cmp qword [rax+NEBOC_WPG_EDGE_UNKNOWN_OFFSET],0
 je .known_target
 inc qword [r10+NEBOC_WPG_UNKNOWN_OFFSET]
 cmp qword [rax+NEBOC_WPG_EDGE_TO_OFFSET],0
 je .edge_next
.known_target:
 mov rdi,r10
 mov rsi,[rax+NEBOC_WPG_EDGE_TO_OFFSET]
 call wpg_find
 test rax,rax
 jz .invalid_published
.edge_next: inc r11
 jmp .edge_loop
.active:
 mov qword [r10+NEBOC_WPG_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.invalid_published:
 mov qword [r10+NEBOC_WPG_ACTIVE_OFFSET],0
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_add_root
 ; rdi=graph rsi=symbol rdx=reason.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r8,rdi
 call wpg_find
 test rax,rax
 jz .invalid_source
 cmp qword [rax+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 je .propagate
 mov qword [rax+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 mov [rax+NEBOC_WPG_NODE_ROOT_REASON_OFFSET],rdx
 inc qword [r8+NEBOC_WPG_ROOTS_OFFSET]
 inc qword [r8+NEBOC_WPG_REACHABLE_OFFSET]
.propagate:
 mov rdi,r8
 sub rsp,8
 call wpg_propagate
 add rsp,8
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; rdi=graph rsi=source rdx=kind rcx=out r8=capacity r9=out count.
wpg_edges_by_kind:
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r9,r9
 jz .invalid
 xor r10d,r10d
 xor r11d,r11d
.loop:
 cmp r10,[rdi+NEBOC_WPG_EDGE_COUNT_OFFSET]
 jae .done
 mov rax,r10
 shl rax,5
 add rax,[rdi+NEBOC_WPG_EDGES_OFFSET]
 cmp [rax+NEBOC_WPG_EDGE_FROM_OFFSET],rsi
 jne .next
 cmp [rax+NEBOC_WPG_EDGE_KIND_OFFSET],rdx
 jne .next
 cmp qword [rax+NEBOC_WPG_EDGE_UNKNOWN_OFFSET],0
 jne .next
 cmp r11,r8
 jae .limit
 mov rax,[rax+NEBOC_WPG_EDGE_TO_OFFSET]
 mov [rcx+r11*8],rax
 inc r11
.next: inc r10
 jmp .loop
.done: mov [r9],r11
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_direct_calls
 mov r9,r8
 mov r8,rcx
 mov rcx,rdx
 mov edx,NEBOC_WPG_EDGE_CALL
 jmp wpg_edges_by_kind

NEBOC_ABI_FUNCTION neboc_program_graph_indirect_targets
 ; rdi=graph rsi=site rdx=out rcx=capacity r8=count r9=unknown count.
 test rdx,rdx
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 xor r10d,r10d
 xor r11d,r11d
 mov qword [r9],0
.loop:
 cmp r10,[rdi+NEBOC_WPG_EDGE_COUNT_OFFSET]
 jae .done
 mov rax,r10
 shl rax,5
 add rax,[rdi+NEBOC_WPG_EDGES_OFFSET]
 cmp [rax],rsi
 jne .next
 cmp qword [rax+16],NEBOC_WPG_EDGE_INDIRECT
 jne .next
 cmp qword [rax+24],0
 je .known
 inc qword [r9]
 jmp .next
.known:
 cmp r11,rcx
 jae .limit
 mov rax,[rax+8]
 mov [rdx+r11*8],rax
 inc r11
.next: inc r10
 jmp .loop
.done: mov [r8],r11
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_data_references
 mov r9,r8
 mov r8,rcx
 mov rcx,rdx
 mov edx,NEBOC_WPG_EDGE_DATA
 jmp wpg_edges_by_kind
NEBOC_ABI_FUNCTION neboc_program_graph_runtime_dependencies
 mov r9,r8
 mov r8,rcx
 mov rcx,rdx
 mov edx,NEBOC_WPG_EDGE_RUNTIME
 jmp wpg_edges_by_kind

NEBOC_ABI_FUNCTION neboc_program_graph_capability_roots
 ; rdi=graph rsi=out count.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov r8,[rdi+NEBOC_WPG_NODES_OFFSET]
 xor ecx,ecx
 xor r9d,r9d
.loop:
 cmp rcx,[rdi+NEBOC_WPG_NODE_COUNT_OFFSET]
 jae .propagate
 cmp qword [r8+NEBOC_WPG_NODE_TYPE_OFFSET],NEBOC_WPG_NODE_CAPABILITY
 jne .next
 test qword [r8+NEBOC_WPG_NODE_FLAGS_OFFSET],1
 jz .next
 cmp qword [r8+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 je .next
 mov qword [r8+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 mov qword [r8+NEBOC_WPG_NODE_ROOT_REASON_OFFSET],NEBOC_WPG_REASON_CAPABILITY
 inc r9
 inc qword [rdi+NEBOC_WPG_ROOTS_OFFSET]
 inc qword [rdi+NEBOC_WPG_REACHABLE_OFFSET]
.next: add r8,NEBOC_WPG_NODE_SIZE
 inc rcx
 jmp .loop
.propagate:
 mov [rsi],r9
 sub rsp,8
 call wpg_propagate
 add rsp,8
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_unreachable_symbols
 ; rdi=graph rsi=out rdx=capacity rcx=count.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rcx,rcx
 jz .invalid
 mov r8,[rdi+NEBOC_WPG_NODES_OFFSET]
 xor r9d,r9d
 xor r10d,r10d
.loop:
 cmp r9,[rdi+NEBOC_WPG_NODE_COUNT_OFFSET]
 jae .done
 cmp qword [r8+NEBOC_WPG_NODE_REACHABLE_OFFSET],1
 je .next
 cmp r10,rdx
 jae .limit
 mov rax,[r8+NEBOC_WPG_NODE_ID_OFFSET]
 mov [rsi+r10*8],rax
 inc r10
.next: add r8,NEBOC_WPG_NODE_SIZE
 inc r9
 jmp .loop
.done: mov [rcx],r10
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_why_reachable
 ; rdi=graph rsi=symbol rdx=report.
 test rdx,rdx
 jz .invalid
 call wpg_find
 test rax,rax
 jz .invalid_source
 mov rcx,[rax+NEBOC_WPG_NODE_REACHABLE_OFFSET]
 mov [rdx+NEBOC_WPG_WHY_REACHABLE_OFFSET],rcx
 mov rcx,[rax+NEBOC_WPG_NODE_PARENT_OFFSET]
 mov [rdx+NEBOC_WPG_WHY_PARENT_OFFSET],rcx
 mov rcx,[rax+NEBOC_WPG_NODE_ROOT_REASON_OFFSET]
 mov [rdx+NEBOC_WPG_WHY_REASON_OFFSET],rcx
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_validate_closed_world
 ; rdi=graph rsi=classification.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_WPG_POLICY_OFFSET],NEBOC_WPG_POLICY_OPEN
 je .unsupported
 cmp qword [rdi+NEBOC_WPG_UNKNOWN_OFFSET],0
 jne .conservative
 mov qword [rsi],NEBOC_WPG_WORLD_COMPLETE
 xor eax,eax
 ret
.conservative: mov qword [rsi],NEBOC_WPG_WORLD_CONSERVATIVE
 xor eax,eax
 ret
.unsupported: mov qword [rsi],NEBOC_WPG_WORLD_UNSUPPORTED
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_program_graph_digest
 ; rdi=graph rsi=out digest.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,0x4752415048524632
 xor rax,[rdi+NEBOC_WPG_TARGET_OFFSET]
 xor rax,[rdi+NEBOC_WPG_POLICY_OFFSET]
 mov r8,[rdi+NEBOC_WPG_NODES_OFFSET]
 xor ecx,ecx
.nodes:
 cmp rcx,[rdi+NEBOC_WPG_NODE_COUNT_OFFSET]
 jae .edges
 rol rax,7
 xor rax,[r8]
 xor rax,[r8+24]
 xor rax,[r8+32]
 add r8,NEBOC_WPG_NODE_SIZE
 inc rcx
 jmp .nodes
.edges:
 mov r8,[rdi+NEBOC_WPG_EDGES_OFFSET]
 xor ecx,ecx
.edge:
 cmp rcx,[rdi+NEBOC_WPG_EDGE_COUNT_OFFSET]
 jae .done
 rol rax,11
 xor rax,[r8]
 xor rax,[r8+8]
 xor rax,[r8+16]
 xor rax,[r8+24]
 add r8,NEBOC_WPG_EDGE_SIZE
 inc rcx
 jmp .edge
.done: mov [rdi+NEBOC_WPG_DIGEST_OFFSET],rax
 mov [rsi],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_reachability_report
 ; rdi=graph rsi=report.
 test rsi,rsi
 jz .invalid
 mov r10,rdi
 mov r11,rsi
 lea rsi,[r11+NEBOC_WPG_REPORT_DIGEST_OFFSET]
 sub rsp,8
 call neboc_program_graph_digest
 add rsp,8
 test eax,eax
 jne .return
 mov rax,[r10+NEBOC_WPG_ROOTS_OFFSET]
 mov [r11+NEBOC_WPG_REPORT_ROOTS_OFFSET],rax
 mov rax,[r10+NEBOC_WPG_REACHABLE_OFFSET]
 mov [r11+NEBOC_WPG_REPORT_REACHABLE_OFFSET],rax
 mov rax,[r10+NEBOC_WPG_NODE_COUNT_OFFSET]
 sub rax,[r10+NEBOC_WPG_REACHABLE_OFFSET]
 mov [r11+NEBOC_WPG_REPORT_UNREACHABLE_OFFSET],rax
 mov rax,[r10+NEBOC_WPG_UNKNOWN_OFFSET]
 mov [r11+NEBOC_WPG_REPORT_UNKNOWN_OFFSET],rax
 xor eax,eax
.return: ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
