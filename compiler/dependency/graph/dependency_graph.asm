; Nebo Assembly — MF029 deterministic Pending dependency graph
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/graph/dependency_graph.inc"

extern neboc_pending_table_get
extern neboc_pending_record_compute_hash
extern neboc_pending_table_freeze

section .text

; dependency_graph_init(graph*, nodes*, node_capacity, edges*, edge_capacity)
NEBOC_ABI_FUNCTION neboc_dependency_graph_init
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp rdx,NEBOC_DEPENDENCY_GRAPH_MAX_NODES
 ja .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov [rdi+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET],rsi
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET],0
 mov [rdi+NEBOC_DEPENDENCY_GRAPH_NODE_CAPACITY_OFFSET],rdx
 mov [rdi+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET],rcx
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET],0
 mov [rdi+NEBOC_DEPENDENCY_GRAPH_EDGE_CAPACITY_OFFSET],r8
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_MUTABLE
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_HASH_OFFSET],0
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_CYCLE_FROM_OFFSET],0
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_CYCLE_TO_OFFSET],0
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_ORPHAN_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_FLAGS_OFFSET],NEBOC_DEPENDENCY_GRAPH_FLAG_NONE
 mov qword [rdi+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET],0
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; dependency_graph_register_pending(graph*, pending_table*, pending_id)
NEBOC_ABI_FUNCTION neboc_dependency_graph_register_pending
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .register_invalid
 test r13,r13
 jz .register_invalid
 test r14,r14
 jz .register_invalid
 cmp qword [r12+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_MUTABLE
 jne .register_invalid
 cmp qword [r13+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_MUTABLE
 jne .register_invalid
 mov rax,[r12+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET]
 test rax,rax
 jz .set_pending_table
 cmp rax,r13
 jne .register_invalid
 jmp .table_ok
.set_pending_table:
 mov [r12+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET],r13
.table_ok:
 mov rax,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 inc rax
 cmp r14,rax
 jne .register_invalid
 cmp r14,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_CAPACITY_OFFSET]
 ja .register_limit
 sub rsp,8
 mov qword [rsp],0
 mov rdi,r13
 mov rsi,r14
 mov rdx,rsp
 call neboc_pending_table_get
 test eax,eax
 jnz .register_stack_invalid
 mov rbx,[rsp]
 add rsp,8
 mov rax,r14
 dec rax
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 add rax,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET]
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_DEPENDENCY_NODE_QWORDS
.register_zero:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .register_zero
 mov rax,r14
 dec rax
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 add rax,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET]
 mov [rax+NEBOC_DEPENDENCY_NODE_ID_OFFSET],r14
 mov [rax+NEBOC_DEPENDENCY_NODE_PENDING_ID_OFFSET],r14
 mov rdx,[rbx+NEBOC_PENDING_RECORD_PRODUCER_SCAN_NODE_OFFSET]
 mov [rax+NEBOC_DEPENDENCY_NODE_PRODUCER_SCAN_NODE_OFFSET],rdx
 mov rdx,[rbx+NEBOC_PENDING_RECORD_SOURCE_ORDER_OFFSET]
 mov [rax+NEBOC_DEPENDENCY_NODE_SOURCE_ORDER_OFFSET],rdx
 mov qword [rax+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET],NEBOC_DEPENDENCY_NODE_FLAG_INDEPENDENT | NEBOC_DEPENDENCY_NODE_FLAG_ORPHAN
 mov [r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET],r14
 xor eax,eax
 jmp .register_done
.register_stack_invalid:
 add rsp,8
.register_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .register_done
.register_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.register_done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; dependency_graph_get_node(graph*, node_id, out_node_ptr*)
NEBOC_ABI_FUNCTION neboc_dependency_graph_get_node
 test rdi,rdi
 jz .node_invalid
 test rdx,rdx
 jz .node_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .node_invalid
 cmp rsi,[rdi+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 ja .node_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 add rax,[rdi+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.node_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; dependency_graph_get_edge(graph*, edge_id, out_edge_ptr*)
NEBOC_ABI_FUNCTION neboc_dependency_graph_get_edge
 test rdi,rdi
 jz .edge_invalid
 test rdx,rdx
 jz .edge_invalid
 mov qword [rdx],0
 test rsi,rsi
 jz .edge_invalid
 cmp rsi,[rdi+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 ja .edge_invalid
 mov rax,rsi
 dec rax
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 add rax,[rdi+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
 mov [rdx],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.edge_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; dependency_graph_add_edge(graph*, request*)
NEBOC_ABI_FUNCTION neboc_dependency_graph_add_edge
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .bad_request_no_output
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_OUT_EDGE_ID_OFFSET],0
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_OUT_CONTINUATION_SEED_ID_OFFSET],0
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_NONE
 test r12,r12
 jz .bad_graph
 cmp qword [r12+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_MUTABLE
 jne .bad_graph
 mov r15,[r12+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET]
 test r15,r15
 jz .bad_graph
 mov r14,[r13+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET]
 test r14,r14
 jz .unknown_producer
 cmp r14,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 ja .unknown_producer
 mov rdx,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET]
 test rdx,rdx
 jz .consumer_ok
 cmp rdx,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 ja .unknown_consumer
.consumer_ok:
 cmp qword [r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET],0
 je .bad_request
 cmp qword [r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET],0
 je .bad_request
 cmp qword [r13+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET],0
 je .bad_request
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET]
 cmp rax,4
 ja .bad_captures
 mov rcx,rax
 mov rax,1
 shl rax,cl
 dec rax
 mov rbx,[r13+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET]
 not rax
 test rbx,rax
 jnz .bad_captures

 mov rdi,r12
 mov rsi,r14
 mov rdx,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET]
 call neboc_dependency_graph_would_cycle
 cmp eax,1
 je .cycle
 test eax,eax
 js .bad_graph

 mov rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_CAPACITY_OFFSET]
 jae .limit
 mov r14,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
 test r14,r14
 jz .bad_graph

 ; Find canonical insertion position by producer PendingId, source order, consumer NodeId.
 xor ebx,ebx
.find_position:
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .position_found
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea r10,[r14+rax]
 mov rax,[r10+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET]
 cmp rax,[r13+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET]
 ja .position_found
 jb .next_position
 mov rax,[r10+NEBOC_DEPENDENCY_EDGE_SOURCE_ORDER_OFFSET]
 cmp rax,[r13+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET]
 ja .position_found
 jb .next_position
 mov rax,[r10+NEBOC_DEPENDENCY_EDGE_CONSUMER_NODE_ID_OFFSET]
 cmp rax,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET]
 ja .position_found
.next_position:
 inc rbx
 jmp .find_position
.position_found:
 ; Shift complete entries upward, copying qwords from high to low.
 mov rcx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
.shift_entries:
 cmp rcx,rbx
 jbe .shift_done
 mov rax,rcx
 dec rax
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea rsi,[r14+rax]
 mov rax,rcx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea rdi,[r14+rax]
 mov edx,NEBOC_DEPENDENCY_EDGE_QWORDS-1
.shift_qwords:
 mov r8,[rsi+rdx*8]
 mov [rdi+rdx*8],r8
 dec edx
 jns .shift_qwords
 dec rcx
 jmp .shift_entries
.shift_done:
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea r10,[r14+rax]
 mov rdi,r10
 xor eax,eax
 mov ecx,NEBOC_DEPENDENCY_EDGE_QWORDS
.zero_edge:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .zero_edge
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET]
 mov [r10+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET],rax
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET]
 mov [r10+NEBOC_DEPENDENCY_EDGE_CONSUMER_PENDING_ID_OFFSET],rax
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_NODE_ID_OFFSET]
 mov [r10+NEBOC_DEPENDENCY_EDGE_CONSUMER_NODE_ID_OFFSET],rax
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_SYMBOL_ID_OFFSET]
 mov [r10+NEBOC_DEPENDENCY_EDGE_CONSUMER_SYMBOL_ID_OFFSET],rax
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_SOURCE_ORDER_OFFSET]
 mov [r10+NEBOC_DEPENDENCY_EDGE_SOURCE_ORDER_OFFSET],rax
 mov qword [r10+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_SOURCE_ORDERED
 cmp qword [r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET],0
 jne .feeds_pending
 or qword [r10+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_TERMINAL_CONSUMER
 jmp .captures
.feeds_pending:
 or qword [r10+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_FEEDS_PENDING

.captures:
 xor r9d,r9d
 xor ecx,ecx
 mov r8,[r13+NEBOC_DEPENDENCY_REQUEST_CAPTURE_USED_MASK_OFFSET]
.capture_loop:
 cmp rcx,[r13+NEBOC_DEPENDENCY_REQUEST_CAPTURE_CANDIDATE_COUNT_OFFSET]
 jae .captures_done
 bt r8,rcx
 jnc .capture_next
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CAPTURE_0_OFFSET+rcx*8]
 test rax,rax
 jz .bad_captures_after_shift
 xor edx,edx
.capture_duplicate_loop:
 cmp rdx,r9
 jae .capture_store
 cmp [r10+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET+rdx*8],rax
 je .capture_next
 inc rdx
 jmp .capture_duplicate_loop
.capture_store:
 cmp r9,4
 jae .bad_captures_after_shift
 mov [r10+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET+r9*8],rax
 inc r9
.capture_next:
 inc rcx
 jmp .capture_loop
.captures_done:
 mov [r10+NEBOC_DEPENDENCY_EDGE_CAPTURE_COUNT_OFFSET],r9
 test r9,r9
 jz .edge_inserted
 or qword [r10+NEBOC_DEPENDENCY_EDGE_FLAGS_OFFSET],NEBOC_DEPENDENCY_EDGE_FLAG_HAS_CAPTURES
.edge_inserted:
 inc qword [r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 mov rdi,r12
 call neboc_dependency_graph_reindex
 test eax,eax
 jnz .bad_graph_after_insert
 mov rax,rbx
 inc rax
 mov [r13+NEBOC_DEPENDENCY_REQUEST_OUT_EDGE_ID_OFFSET],rax
 mov [r13+NEBOC_DEPENDENCY_REQUEST_OUT_CONTINUATION_SEED_ID_OFFSET],rax
 xor eax,eax
 jmp .done

.bad_captures_after_shift:
 ; Restore count by discarding the shifted uncommitted slot.
 mov rcx,rbx
.restore_shift:
 cmp rcx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .bad_captures
 mov rax,rcx
 inc rax
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea rsi,[r14+rax]
 mov rax,rcx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea rdi,[r14+rax]
 xor edx,edx
.restore_qwords:
 cmp edx,NEBOC_DEPENDENCY_EDGE_QWORDS
 jae .restore_next
 mov r8,[rsi+rdx*8]
 mov [rdi+rdx*8],r8
 inc edx
 jmp .restore_qwords
.restore_next:
 inc rcx
 jmp .restore_shift

.cycle:
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_PRODUCER_PENDING_ID_OFFSET]
 mov [r12+NEBOC_DEPENDENCY_GRAPH_CYCLE_FROM_OFFSET],rax
 mov rax,[r13+NEBOC_DEPENDENCY_REQUEST_CONSUMER_PENDING_ID_OFFSET]
 mov [r12+NEBOC_DEPENDENCY_GRAPH_CYCLE_TO_OFFSET],rax
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_CYCLE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unknown_producer:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_UNKNOWN_PRODUCER
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unknown_consumer:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_UNKNOWN_CONSUMER
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_captures:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_BAD_CAPTURES
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad_request:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_BAD_REQUEST
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_graph:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_BAD_GRAPH
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.bad_graph_after_insert:
 mov qword [r13+NEBOC_DEPENDENCY_REQUEST_ERROR_CODE_OFFSET],NEBOC_DEPENDENCY_ERROR_BAD_GRAPH
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.bad_request_no_output:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; dependency_graph_would_cycle(graph*, producer_pending_id, consumer_pending_id)
; Returns eax=1 for a cycle, eax=0 for no cycle, eax=-1 for invalid graph.
NEBOC_ABI_FUNCTION neboc_dependency_graph_would_cycle
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .cycle_invalid
 test r13,r13
 jz .cycle_invalid
 test r14,r14
 jz .cycle_no
 cmp r13,r14
 je .cycle_yes
 cmp r13,NEBOC_DEPENDENCY_GRAPH_MAX_NODES
 ja .cycle_invalid
 cmp r14,NEBOC_DEPENDENCY_GRAPH_MAX_NODES
 ja .cycle_invalid
 mov rcx,r14
 dec rcx
 mov r8,1
 shl r8,cl
.closure_loop:
 mov r9,r8
 xor ebx,ebx
 mov r10,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
.edge_loop:
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .closure_check
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea r11,[r10+rax]
 mov rax,[r11+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET]
 test rax,rax
 jz .edge_next
 mov rcx,rax
 dec rcx
 mov rdx,1
 shl rdx,cl
 test r8,rdx
 jz .edge_next
 mov rax,[r11+NEBOC_DEPENDENCY_EDGE_CONSUMER_PENDING_ID_OFFSET]
 test rax,rax
 jz .edge_next
 mov rcx,rax
 dec rcx
 mov rdx,1
 shl rdx,cl
 or r8,rdx
.edge_next:
 inc rbx
 jmp .edge_loop
.closure_check:
 cmp r8,r9
 jne .closure_loop
 mov rcx,r13
 dec rcx
 mov rax,1
 shl rax,cl
 test r8,rax
 jnz .cycle_yes
.cycle_no:
 xor eax,eax
 jmp .cycle_done
.cycle_yes:
 mov eax,1
 jmp .cycle_done
.cycle_invalid:
 mov eax,-1
.cycle_done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; dependency_graph_reindex(graph*)
; Reassigns stable EdgeId/ContinuationSeedId and rebuilds all Pending/Node metadata.
NEBOC_ABI_FUNCTION neboc_dependency_graph_reindex
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .reindex_invalid
 mov r13,[r12+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET]
 test r13,r13
 jz .reindex_invalid
 mov r14,[r13+NEBOC_PENDING_TABLE_DATA_OFFSET]
 mov r15,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET]
 test r14,r14
 jz .reindex_invalid
 test r15,r15
 jz .reindex_invalid
 xor ebx,ebx
.reset_loop:
 cmp rbx,[r13+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 jae .edge_reindex_start
 mov rax,rbx
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea r8,[r14+rax]
 mov qword [r8+NEBOC_PENDING_RECORD_STATE_OFFSET],NEBOC_PENDING_STATE_PRODUCED
 mov qword [r8+NEBOC_PENDING_RECORD_FLAGS_OFFSET],NEBOC_PENDING_REQUIRED_FLAGS
 mov qword [r8+NEBOC_PENDING_RECORD_FIRST_EDGE_ID_OFFSET],0
 mov qword [r8+NEBOC_PENDING_RECORD_EDGE_COUNT_OFFSET],0
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 lea r9,[r15+rax]
 mov rdi,r9
 xor eax,eax
 mov ecx,NEBOC_DEPENDENCY_NODE_QWORDS
.reset_node_zero:
 mov [rdi],rax
 add rdi,8
 dec ecx
 jnz .reset_node_zero
 lea rax,[rbx+1]
 mov [r9+NEBOC_DEPENDENCY_NODE_ID_OFFSET],rax
 mov [r9+NEBOC_DEPENDENCY_NODE_PENDING_ID_OFFSET],rax
 mov rax,[r8+NEBOC_PENDING_RECORD_PRODUCER_SCAN_NODE_OFFSET]
 mov [r9+NEBOC_DEPENDENCY_NODE_PRODUCER_SCAN_NODE_OFFSET],rax
 mov rax,[r8+NEBOC_PENDING_RECORD_SOURCE_ORDER_OFFSET]
 mov [r9+NEBOC_DEPENDENCY_NODE_SOURCE_ORDER_OFFSET],rax
 inc rbx
 jmp .reset_loop

.edge_reindex_start:
 xor ebx,ebx
 mov r10,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
.edge_reindex_loop:
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .classify_nodes
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_EDGE_SIZE
 lea r11,[r10+rax]
 lea rax,[rbx+1]
 mov [r11+NEBOC_DEPENDENCY_EDGE_ID_OFFSET],rax
 mov [r11+NEBOC_DEPENDENCY_EDGE_CONTINUATION_SEED_ID_OFFSET],rax
 mov rdi,r11
 call neboc_dependency_edge_compute_hashes
 test eax,eax
 jz .reindex_invalid
 mov rax,[r11+NEBOC_DEPENDENCY_EDGE_PRODUCER_PENDING_ID_OFFSET]
 dec rax
 mov rcx,rax
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea r8,[r14+rax]
 mov rax,rcx
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 lea r9,[r15+rax]
 cmp qword [r8+NEBOC_PENDING_RECORD_FIRST_EDGE_ID_OFFSET],0
 jne .producer_first_done
 lea rax,[rbx+1]
 mov [r8+NEBOC_PENDING_RECORD_FIRST_EDGE_ID_OFFSET],rax
 mov [r9+NEBOC_DEPENDENCY_NODE_FIRST_EDGE_ID_OFFSET],rax
.producer_first_done:
 inc qword [r8+NEBOC_PENDING_RECORD_EDGE_COUNT_OFFSET]
 mov qword [r8+NEBOC_PENDING_RECORD_STATE_OFFSET],NEBOC_PENDING_STATE_CONNECTED
 or qword [r8+NEBOC_PENDING_RECORD_FLAGS_OFFSET],NEBOC_PENDING_FLAG_HAS_CONSUMER
 inc qword [r9+NEBOC_DEPENDENCY_NODE_EDGE_COUNT_OFFSET]
 or qword [r9+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET],NEBOC_DEPENDENCY_NODE_FLAG_HAS_DEPENDENTS
 mov rax,[r11+NEBOC_DEPENDENCY_EDGE_CONSUMER_PENDING_ID_OFFSET]
 test rax,rax
 jz .edge_reindex_next
 dec rax
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 lea r9,[r15+rax]
 inc qword [r9+NEBOC_DEPENDENCY_NODE_INDEGREE_OFFSET]
 or qword [r9+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET],NEBOC_DEPENDENCY_NODE_FLAG_HAS_PREREQUISITES
.edge_reindex_next:
 inc rbx
 jmp .edge_reindex_loop

.classify_nodes:
 xor ebx,ebx
 xor r10d,r10d
.classify_loop:
 cmp rbx,[r13+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 jae .classify_done
 mov rax,rbx
 imul rax,NEBOC_PENDING_RECORD_SIZE
 lea r8,[r14+rax]
 mov rax,rbx
 imul rax,NEBOC_DEPENDENCY_NODE_SIZE
 lea r9,[r15+rax]
 cmp qword [r8+NEBOC_PENDING_RECORD_EDGE_COUNT_OFFSET],0
 jne .not_orphan
 mov qword [r8+NEBOC_PENDING_RECORD_STATE_OFFSET],NEBOC_PENDING_STATE_ORPHAN
 or qword [r8+NEBOC_PENDING_RECORD_FLAGS_OFFSET],NEBOC_PENDING_FLAG_ORPHAN
 or qword [r9+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET],NEBOC_DEPENDENCY_NODE_FLAG_ORPHAN
 inc r10
.not_orphan:
 cmp qword [r9+NEBOC_DEPENDENCY_NODE_INDEGREE_OFFSET],0
 jne .not_independent
 or qword [r9+NEBOC_DEPENDENCY_NODE_FLAGS_OFFSET],NEBOC_DEPENDENCY_NODE_FLAG_INDEPENDENT
.not_independent:
 mov rdi,r8
 call neboc_pending_record_compute_hash
 mov [r8+NEBOC_PENDING_RECORD_HASH_OFFSET],rax
 mov rdi,r9
 call neboc_dependency_node_compute_hash
 mov [r9+NEBOC_DEPENDENCY_NODE_HASH_OFFSET],rax
 inc rbx
 jmp .classify_loop
.classify_done:
 mov [r13+NEBOC_PENDING_TABLE_ORPHAN_COUNT_OFFSET],r10
 mov [r12+NEBOC_DEPENDENCY_GRAPH_ORPHAN_COUNT_OFFSET],r10
 mov qword [r12+NEBOC_DEPENDENCY_GRAPH_FLAGS_OFFSET],NEBOC_DEPENDENCY_GRAPH_REQUIRED_FLAGS
 xor eax,eax
 jmp .reindex_done
.reindex_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.reindex_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; dependency_edge_compute_hashes(edge*) -> eax edge hash, zero invalid
NEBOC_ABI_FUNCTION neboc_dependency_edge_compute_hashes
 sub rsp,8
 test rdi,rdi
 jz .edge_hash_invalid
 mov r8,rdi
 mov eax,NEBOC_DEPENDENCY_HASH_FNV1A32_OFFSET_BASIS
 mov rdx,[r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_COUNT_OFFSET]
 call .edge_hash_qword
 mov rdx,[r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_0_OFFSET]
 call .edge_hash_qword
 mov rdx,[r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_1_OFFSET]
 call .edge_hash_qword
 mov rdx,[r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_2_OFFSET]
 call .edge_hash_qword
 mov rdx,[r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_3_OFFSET]
 call .edge_hash_qword
 mov [r8+NEBOC_DEPENDENCY_EDGE_CAPTURE_HASH_OFFSET],rax
 mov eax,NEBOC_DEPENDENCY_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.edge_hash_fields:
 cmp ecx,14
 jae .edge_hash_done
 mov rdx,[r8+rcx*8]
 call .edge_hash_qword
 inc ecx
 jmp .edge_hash_fields
.edge_hash_done:
 mov [r8+NEBOC_DEPENDENCY_EDGE_HASH_OFFSET],rax
 add rsp,8
 ret
.edge_hash_invalid:
 xor eax,eax
 add rsp,8
 ret
.edge_hash_qword:
 push rcx
 mov ecx,8
.edge_hash_byte:
 movzx esi,dl
 xor eax,esi
 imul eax,eax,NEBOC_DEPENDENCY_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .edge_hash_byte
 pop rcx
 ret

; dependency_node_compute_hash(node*) -> eax
NEBOC_ABI_FUNCTION neboc_dependency_node_compute_hash
 sub rsp,8
 test rdi,rdi
 jz .node_hash_invalid
 mov r8,rdi
 mov eax,NEBOC_DEPENDENCY_HASH_FNV1A32_OFFSET_BASIS
 xor ecx,ecx
.node_hash_fields:
 cmp ecx,8
 jae .node_hash_done
 mov rdx,[r8+rcx*8]
 call .node_hash_qword
 inc ecx
 jmp .node_hash_fields
.node_hash_done:
 add rsp,8
 ret
.node_hash_invalid:
 xor eax,eax
 add rsp,8
 ret
.node_hash_qword:
 push rcx
 mov ecx,8
.node_hash_byte:
 movzx esi,dl
 xor eax,esi
 imul eax,eax,NEBOC_DEPENDENCY_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .node_hash_byte
 pop rcx
 ret

; dependency_graph_compute_hash(graph*) -> eax
NEBOC_ABI_FUNCTION neboc_dependency_graph_compute_hash
 push rbx
 push r12
 push r13
 mov r12,rdi
 test r12,r12
 jz .graph_hash_invalid
 mov eax,NEBOC_DEPENDENCY_HASH_FNV1A32_OFFSET_BASIS
 mov rdx,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 call .graph_hash_qword
 mov rdx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 call .graph_hash_qword
 mov rdx,[r12+NEBOC_DEPENDENCY_GRAPH_ORPHAN_COUNT_OFFSET]
 call .graph_hash_qword
 mov rdx,[r12+NEBOC_DEPENDENCY_GRAPH_FLAGS_OFFSET]
 call .graph_hash_qword
 xor ebx,ebx
 mov r13,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_DATA_OFFSET]
.graph_nodes:
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 jae .graph_edges_start
 mov rcx,rbx
 imul rcx,NEBOC_DEPENDENCY_NODE_SIZE
 mov rdx,[r13+rcx+NEBOC_DEPENDENCY_NODE_HASH_OFFSET]
 call .graph_hash_qword
 inc rbx
 jmp .graph_nodes
.graph_edges_start:
 xor ebx,ebx
 mov r13,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_DATA_OFFSET]
.graph_edges:
 cmp rbx,[r12+NEBOC_DEPENDENCY_GRAPH_EDGE_COUNT_OFFSET]
 jae .graph_hash_done
 mov rcx,rbx
 imul rcx,NEBOC_DEPENDENCY_EDGE_SIZE
 mov rdx,[r13+rcx+NEBOC_DEPENDENCY_EDGE_HASH_OFFSET]
 call .graph_hash_qword
 inc rbx
 jmp .graph_edges
.graph_hash_done:
 mov [r12+NEBOC_DEPENDENCY_GRAPH_HASH_OFFSET],rax
 jmp .graph_hash_return
.graph_hash_invalid:
 xor eax,eax
.graph_hash_return:
 pop r13
 pop r12
 pop rbx
 ret
.graph_hash_qword:
 push rcx
 mov ecx,8
.graph_hash_byte:
 movzx esi,dl
 xor eax,esi
 imul eax,eax,NEBOC_DEPENDENCY_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .graph_hash_byte
 pop rcx
 ret

; dependency_graph_freeze(graph*, pending_table*)
NEBOC_ABI_FUNCTION neboc_dependency_graph_freeze
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r12,r12
 jz .freeze_invalid
 test r13,r13
 jz .freeze_invalid
 cmp qword [r12+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_MUTABLE
 jne .freeze_invalid
 cmp [r12+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET],r13
 jne .freeze_invalid
 cmp qword [r13+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_MUTABLE
 jne .freeze_invalid
 mov rdi,r12
 call neboc_dependency_graph_reindex
 test eax,eax
 jnz .freeze_invalid
 mov rdi,r13
 call neboc_pending_table_freeze
 test eax,eax
 jnz .freeze_invalid
 mov rdi,r12
 call neboc_dependency_graph_compute_hash
 test eax,eax
 jz .freeze_invalid
 mov qword [r12+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_FROZEN
 xor eax,eax
 jmp .freeze_done
.freeze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.freeze_done:
 add rsp,8
 pop r13
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
