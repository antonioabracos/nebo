; ANALYSIS-F01 read-only, snapshot-bound analysis substrate.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"

section .text
analysis_validate_session:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_ANALYSIS_SESSION_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_ANALYSIS_SESSION_COMPILER_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [rax+NEBOC_COMPILER_SNAPSHOT_VALID_OFFSET],1
 jne .stale
 mov rcx,[rax+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET]
 cmp rcx,[rdi+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov rcx,[rax+NEBOC_COMPILER_SNAPSHOT_REVISION_OFFSET]
 cmp rcx,[rdi+NEBOC_ANALYSIS_SESSION_REVISION_OFFSET]
 jne .stale
 xor eax,eax
 ret
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_analysis_session_new
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 cmp qword [rsi+NEBOC_COMPILER_SNAPSHOT_VALID_OFFSET],1
 jne .invalid
 cmp qword [rsi+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_COMPILER_SNAPSHOT_REVISION_OFFSET],0
 je .invalid
 mov rax,[rdx+NEBOC_ANALYSIS_OPTIONS_MAX_ITERATIONS_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_ANALYSIS_MAX_ITERATIONS
 ja .limit
 mov rcx,[rdx+NEBOC_ANALYSIS_OPTIONS_MAX_QUERY_DEPTH_OFFSET]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBOC_ANALYSIS_MAX_QUERY_DEPTH
 ja .limit
 mov r8,[rdx+NEBOC_ANALYSIS_OPTIONS_MEMORY_BUDGET_OFFSET]
 cmp r8,1024
 jb .invalid
 mov r9,[rdx+NEBOC_ANALYSIS_OPTIONS_CACHE_OFFSET]
 test r9,r9
 jz .invalid
 mov r10,[rdx+NEBOC_ANALYSIS_OPTIONS_CACHE_CAPACITY_OFFSET]
 test r10,r10
 jz .invalid
 cmp r10,NEBOC_ANALYSIS_MAX_QUERIES
 ja .limit
 mov [rdi+NEBOC_ANALYSIS_SESSION_COMPILER_OFFSET],rsi
 mov r11,[rsi+NEBOC_COMPILER_SNAPSHOT_DIGEST_OFFSET]
 mov [rdi+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET],r11
 mov r11,[rsi+NEBOC_COMPILER_SNAPSHOT_REVISION_OFFSET]
 mov [rdi+NEBOC_ANALYSIS_SESSION_REVISION_OFFSET],r11
 mov [rdi+NEBOC_ANALYSIS_SESSION_MAX_ITERATIONS_OFFSET],rax
 mov [rdi+NEBOC_ANALYSIS_SESSION_MAX_QUERY_DEPTH_OFFSET],rcx
 mov [rdi+NEBOC_ANALYSIS_SESSION_MEMORY_BUDGET_OFFSET],r8
 mov [rdi+NEBOC_ANALYSIS_SESSION_CACHE_OFFSET],r9
 mov [rdi+NEBOC_ANALYSIS_SESSION_CACHE_CAPACITY_OFFSET],r10
 mov qword [rdi+NEBOC_ANALYSIS_SESSION_CACHE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_ANALYSIS_SESSION_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_analysis_control_flow
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov r8,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCK_COUNT_OFFSET]
 test r8,r8
 jz .invalid
 cmp r8,NEBOC_ANALYSIS_MAX_BLOCKS
 ja .limit
 cmp qword [r13+NEBOC_ANALYSIS_FUNCTION_BLOCKS_OFFSET],0
 je .invalid
 mov r9,[r13+NEBOC_ANALYSIS_FUNCTION_EDGE_COUNT_OFFSET]
 cmp r9,NEBOC_ANALYSIS_MAX_EDGES
 ja .limit
 test r9,r9
 jz .blocks
 cmp qword [r13+NEBOC_ANALYSIS_FUNCTION_EDGES_OFFSET],0
 je .invalid
.blocks:
 mov r10,[r13+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 cmp r10,NEBOC_ANALYSIS_MAX_EVENTS
 ja .limit
 xor ebx,ebx
.block_loop:
 cmp rbx,r8
 jae .edges
 mov rsi,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCKS_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_BLOCK_SIZE
 add rsi,rax
 cmp [rsi+NEBOC_ANALYSIS_BLOCK_ID_OFFSET],rbx
 jne .invalid
 mov rax,[rsi+NEBOC_ANALYSIS_BLOCK_FIRST_EVENT_OFFSET]
 add rax,[rsi+NEBOC_ANALYSIS_BLOCK_EVENT_COUNT_OFFSET]
 jc .invalid
 cmp rax,r10
 ja .invalid
 inc rbx
 jmp .block_loop
.edges:
 xor ebx,ebx
.edge_loop:
 cmp rbx,r9
 jae .store
 mov rsi,[r13+NEBOC_ANALYSIS_FUNCTION_EDGES_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_EDGE_SIZE
 add rsi,rax
 cmp qword [rsi+NEBOC_ANALYSIS_EDGE_KIND_OFFSET],NEBOC_ANALYSIS_EDGE_KNOWN
 jne .invalid
 cmp [rsi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET],r8
 jae .invalid
 cmp [rsi+NEBOC_ANALYSIS_EDGE_TO_OFFSET],r8
 jae .invalid
 inc rbx
 jmp .edge_loop
.store:
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [r14+NEBOC_ANALYSIS_CFG_SNAPSHOT_OFFSET],rax
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_ID_OFFSET]
 mov [r14+NEBOC_ANALYSIS_CFG_FUNCTION_OFFSET],rax
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCKS_OFFSET]
 mov [r14+NEBOC_ANALYSIS_CFG_BLOCKS_OFFSET],rax
 mov [r14+NEBOC_ANALYSIS_CFG_BLOCK_COUNT_OFFSET],r8
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_EDGES_OFFSET]
 mov [r14+NEBOC_ANALYSIS_CFG_EDGES_OFFSET],rax
 mov [r14+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET],r9
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_REVISION_OFFSET]
 mov [r14+NEBOC_ANALYSIS_CFG_VERSION_OFFSET],rax
 mov qword [r14+NEBOC_ANALYSIS_CFG_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; result already contains caller-owned dominator/post-dominator arrays.
NEBOC_ABI_FUNCTION neboc_analysis_dominators
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,[r13+NEBOC_ANALYSIS_CFG_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov r15,[r13+NEBOC_ANALYSIS_CFG_BLOCK_COUNT_OFFSET]
 test r15,r15
 jz .invalid
 cmp r15,[r14+NEBOC_ANALYSIS_DOM_CAPACITY_OFFSET]
 ja .limit
 mov r8,[r14+NEBOC_ANALYSIS_DOM_MASKS_OFFSET]
 mov r9,[r14+NEBOC_ANALYSIS_POSTDOM_MASKS_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 mov r10,-1
 cmp r15,64
 je .mask_ready
 mov ecx,r15d
 mov r10,1
 shl r10,cl
 dec r10
.mask_ready:
 xor ebx,ebx
.init:
 cmp rbx,r15
 jae .dom_iter_start
 mov rax,r10
 test rbx,rbx
 jnz .init_dom
 mov eax,1
.init_dom:
 mov [r8+rbx*8],rax
 mov [r9+rbx*8],r10
 inc rbx
 jmp .init
.dom_iter_start:
 xor ebx,ebx
.dom_iteration:
 inc rbx
 cmp rbx,[r12+NEBOC_ANALYSIS_SESSION_MAX_ITERATIONS_OFFSET]
 ja .budget
 xor r11d,r11d
 mov rcx,1
.dom_node:
 cmp rcx,r15
 jae .dom_changed
 mov rax,r10
 xor edx,edx
 xor esi,esi
.dom_edge:
 cmp rsi,[r13+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET]
 jae .dom_pred_done
 mov rdi,[r13+NEBOC_ANALYSIS_CFG_EDGES_OFFSET]
 mov r8,rsi
 imul r8,NEBOC_ANALYSIS_EDGE_SIZE
 add rdi,r8
 cmp [rdi+NEBOC_ANALYSIS_EDGE_TO_OFFSET],rcx
 jne .dom_next_edge
 mov r8,[r14+NEBOC_ANALYSIS_DOM_MASKS_OFFSET]
 mov rdi,[rdi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET]
 and rax,[r8+rdi*8]
 inc edx
.dom_next_edge:
 inc rsi
 jmp .dom_edge
.dom_pred_done:
 test edx,edx
 jnz .dom_add_self
 xor eax,eax
.dom_add_self:
 bts rax,rcx
 mov r8,[r14+NEBOC_ANALYSIS_DOM_MASKS_OFFSET]
 cmp [r8+rcx*8],rax
 je .dom_next_node
 mov [r8+rcx*8],rax
 mov r11d,1
.dom_next_node:
 inc rcx
 jmp .dom_node
.dom_changed:
 test r11d,r11d
 jnz .dom_iteration

 ; Initialize exits for post-dominators.
 xor ecx,ecx
.post_init:
 cmp rcx,r15
 jae .post_iter_start
 xor edx,edx
 xor esi,esi
.post_exit_edge:
 cmp rsi,[r13+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET]
 jae .post_exit_done
 mov rdi,[r13+NEBOC_ANALYSIS_CFG_EDGES_OFFSET]
 mov rax,rsi
 imul rax,NEBOC_ANALYSIS_EDGE_SIZE
 add rdi,rax
 cmp [rdi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET],rcx
 jne .post_exit_next
 inc edx
.post_exit_next:
 inc rsi
 jmp .post_exit_edge
.post_exit_done:
 test edx,edx
 jnz .post_nonexit
 mov rax,1
 shl rax,cl
 mov r8,[r14+NEBOC_ANALYSIS_POSTDOM_MASKS_OFFSET]
 mov [r8+rcx*8],rax
.post_nonexit:
 inc rcx
 jmp .post_init
.post_iter_start:
 xor r11d,r11d
.post_iteration:
 inc r11
 mov rax,rbx
 add rax,r11
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_MAX_ITERATIONS_OFFSET]
 ja .budget
 xor r9d,r9d
 xor ecx,ecx
.post_node:
 cmp rcx,r15
 jae .post_changed
 xor edx,edx
 xor esi,esi
 mov rax,r10
.post_edge:
 cmp rsi,[r13+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET]
 jae .post_succ_done
 mov rdi,[r13+NEBOC_ANALYSIS_CFG_EDGES_OFFSET]
 mov r8,rsi
 imul r8,NEBOC_ANALYSIS_EDGE_SIZE
 add rdi,r8
 cmp [rdi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET],rcx
 jne .post_next_edge
 mov r8,[r14+NEBOC_ANALYSIS_POSTDOM_MASKS_OFFSET]
 mov rdi,[rdi+NEBOC_ANALYSIS_EDGE_TO_OFFSET]
 and rax,[r8+rdi*8]
 inc edx
.post_next_edge:
 inc rsi
 jmp .post_edge
.post_succ_done:
 test edx,edx
 jz .post_next_node
 bts rax,rcx
 mov r8,[r14+NEBOC_ANALYSIS_POSTDOM_MASKS_OFFSET]
 cmp [r8+rcx*8],rax
 je .post_next_node
 mov [r8+rcx*8],rax
 mov r9d,1
.post_next_node:
 inc rcx
 jmp .post_node
.post_changed:
 test r9d,r9d
 jnz .post_iteration
 mov [r14+NEBOC_ANALYSIS_DOM_CFG_OFFSET],r13
 mov [r14+NEBOC_ANALYSIS_DOM_COUNT_OFFSET],r15
 add rbx,r11
 mov [r14+NEBOC_ANALYSIS_DOM_ITERATIONS_OFFSET],rbx
 mov qword [r14+NEBOC_ANALYSIS_DOM_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.budget:
 mov qword [r14+NEBOC_ANALYSIS_DOM_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_analysis_use_def
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 mov r8,[r13+NEBOC_ANALYSIS_USEDEF_FUNCTION_OFFSET]
 test r8,r8
 jz .invalid
 mov rax,[r8+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 cmp qword [r13+NEBOC_ANALYSIS_USEDEF_DEFS_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_ANALYSIS_USEDEF_USES_OFFSET],0
 je .invalid
 mov qword [r13+NEBOC_ANALYSIS_USEDEF_DEF_COUNT_OFFSET],0
 mov qword [r13+NEBOC_ANALYSIS_USEDEF_USE_COUNT_OFFSET],0
 xor ebx,ebx
.loop:
 cmp rbx,[r8+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 jae .ok
 mov r9,[r8+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add r9,rax
 mov rax,[r9+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 cmp rax,[r13+NEBOC_ANALYSIS_USEDEF_SYMBOL_OFFSET]
 jne .next
 mov rax,[r9+NEBOC_ANALYSIS_EVENT_FLAGS_OFFSET]
 test rax,NEBOC_ANALYSIS_EVENT_DEFINE
 jz .use
 mov rcx,[r13+NEBOC_ANALYSIS_USEDEF_DEF_COUNT_OFFSET]
 cmp rcx,[r13+NEBOC_ANALYSIS_USEDEF_DEF_CAPACITY_OFFSET]
 jae .limit
 mov rdx,[r13+NEBOC_ANALYSIS_USEDEF_DEFS_OFFSET]
 mov rsi,[r9+NEBOC_ANALYSIS_EVENT_NODE_OFFSET]
 mov [rdx+rcx*8],rsi
 inc qword [r13+NEBOC_ANALYSIS_USEDEF_DEF_COUNT_OFFSET]
.use:
 test rax,NEBOC_ANALYSIS_EVENT_USE
 jz .next
 mov rcx,[r13+NEBOC_ANALYSIS_USEDEF_USE_COUNT_OFFSET]
 cmp rcx,[r13+NEBOC_ANALYSIS_USEDEF_USE_CAPACITY_OFFSET]
 jae .limit
 mov rdx,[r13+NEBOC_ANALYSIS_USEDEF_USES_OFFSET]
 mov rsi,[r9+NEBOC_ANALYSIS_EVENT_NODE_OFFSET]
 mov [rdx+rcx*8],rsi
 inc qword [r13+NEBOC_ANALYSIS_USEDEF_USE_COUNT_OFFSET]
.next:
 inc rbx
 jmp .loop
.ok:
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [r13+NEBOC_ANALYSIS_USEDEF_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_analysis_live_ranges
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 mov r14,[r13+NEBOC_ANALYSIS_RANGES_FUNCTION_OFFSET]
 test r14,r14
 jz .invalid
 mov rax,[r14+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 cmp qword [r13+NEBOC_ANALYSIS_RANGES_OUTPUT_OFFSET],0
 je .invalid
 mov qword [r13+NEBOC_ANALYSIS_RANGES_COUNT_OFFSET],0
 xor ebx,ebx
.event:
 cmp rbx,[r14+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 jae .ok
 mov r8,[r14+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add r8,rax
 mov r9,[r8+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 test r9,r9
 jz .next
 xor ecx,ecx
.find:
 cmp rcx,[r13+NEBOC_ANALYSIS_RANGES_COUNT_OFFSET]
 jae .add
 mov rdx,[r13+NEBOC_ANALYSIS_RANGES_OUTPUT_OFFSET]
 mov rax,rcx
 imul rax,NEBOC_ANALYSIS_RANGE_SIZE
 add rdx,rax
 cmp [rdx+NEBOC_ANALYSIS_RANGE_SYMBOL_OFFSET],r9
 je .update
 inc rcx
 jmp .find
.add:
 cmp rcx,[r13+NEBOC_ANALYSIS_RANGES_CAPACITY_OFFSET]
 jae .limit
 cmp rcx,NEBOC_ANALYSIS_MAX_SYMBOLS
 jae .limit
 mov rdx,[r13+NEBOC_ANALYSIS_RANGES_OUTPUT_OFFSET]
 mov rax,rcx
 imul rax,NEBOC_ANALYSIS_RANGE_SIZE
 add rdx,rax
 mov [rdx+NEBOC_ANALYSIS_RANGE_SYMBOL_OFFSET],r9
 mov [rdx+NEBOC_ANALYSIS_RANGE_FIRST_OFFSET],rbx
 mov [rdx+NEBOC_ANALYSIS_RANGE_LAST_OFFSET],rbx
 inc qword [r13+NEBOC_ANALYSIS_RANGES_COUNT_OFFSET]
 jmp .next
.update:
 mov [rdx+NEBOC_ANALYSIS_RANGE_LAST_OFFSET],rbx
.next:
 inc rbx
 jmp .event
.ok:
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [r13+NEBOC_ANALYSIS_RANGES_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_analysis_data_flow
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 mov r14,[r13+NEBOC_ANALYSIS_DATAFLOW_CFG_OFFSET]
 test r14,r14
 jz .invalid
 mov rax,[r14+NEBOC_ANALYSIS_CFG_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov r15,[r14+NEBOC_ANALYSIS_CFG_BLOCK_COUNT_OFFSET]
 cmp r15,[r13+NEBOC_ANALYSIS_DATAFLOW_CAPACITY_OFFSET]
 ja .limit
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_GEN_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_KILL_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET],0
 je .invalid
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET],0
 je .invalid
 mov rax,[r13+NEBOC_ANALYSIS_DATAFLOW_MAX_ITERATIONS_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_MAX_ITERATIONS_OFFSET]
 ja .limit
 mov rcx,[r13+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET]
 cmp rcx,NEBOC_ANALYSIS_DIRECTION_FORWARD
 je .init
 cmp rcx,NEBOC_ANALYSIS_DIRECTION_BACKWARD
 jne .invalid
.init:
 xor ebx,ebx
.clear:
 cmp rbx,r15
 jae .seed
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET]
 mov qword [r8+rbx*8],0
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET]
 mov qword [r8+rbx*8],0
 inc rbx
 jmp .clear
.seed:
 cmp rcx,NEBOC_ANALYSIS_DIRECTION_FORWARD
 jne .seed_back
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET]
 mov rax,[r13+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET]
 mov [r8],rax
 jmp .iterate_start
.seed_back:
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET]
 mov rax,[r13+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET]
 mov [r8+r15*8-8],rax
.iterate_start:
 xor ebx,ebx
.iteration:
 inc rbx
 cmp rbx,[r13+NEBOC_ANALYSIS_DATAFLOW_MAX_ITERATIONS_OFFSET]
 ja .budget
 xor r11d,r11d
 xor ecx,ecx
.node:
 cmp rcx,r15
 jae .changed
 xor r9d,r9d
 xor esi,esi
.edge:
 cmp rsi,[r14+NEBOC_ANALYSIS_CFG_EDGE_COUNT_OFFSET]
 jae .meet_done
 mov rdi,[r14+NEBOC_ANALYSIS_CFG_EDGES_OFFSET]
 mov rax,rsi
 imul rax,NEBOC_ANALYSIS_EDGE_SIZE
 add rdi,rax
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_FORWARD
 jne .back_edge
 cmp [rdi+NEBOC_ANALYSIS_EDGE_TO_OFFSET],rcx
 jne .next_edge
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET]
 mov rax,[rdi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET]
 or r9,[r8+rax*8]
 jmp .next_edge
.back_edge:
 cmp [rdi+NEBOC_ANALYSIS_EDGE_FROM_OFFSET],rcx
 jne .next_edge
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET]
 mov rax,[rdi+NEBOC_ANALYSIS_EDGE_TO_OFFSET]
 or r9,[r8+rax*8]
.next_edge:
 inc rsi
 jmp .edge
.meet_done:
 cmp qword [r13+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_FORWARD
 jne .transfer_back
 test rcx,rcx
 jnz .store_forward_in
 or r9,[r13+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET]
.store_forward_in:
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET]
 cmp [r8+rcx*8],r9
 je .forward_transfer
 mov [r8+rcx*8],r9
 mov r11d,1
.forward_transfer:
 mov rax,r9
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_KILL_OFFSET]
 mov rdx,[r8+rcx*8]
 not rdx
 and rax,rdx
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_GEN_OFFSET]
 or rax,[r8+rcx*8]
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET]
 cmp [r8+rcx*8],rax
 je .next_node
 mov [r8+rcx*8],rax
 mov r11d,1
 jmp .next_node
.transfer_back:
 mov rax,r15
 dec rax
 cmp rcx,rax
 jne .store_back_out
 or r9,[r13+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET]
.store_back_out:
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET]
 cmp [r8+rcx*8],r9
 je .back_transfer
 mov [r8+rcx*8],r9
 mov r11d,1
.back_transfer:
 mov rax,r9
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_KILL_OFFSET]
 mov rdx,[r8+rcx*8]
 not rdx
 and rax,rdx
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_GEN_OFFSET]
 or rax,[r8+rcx*8]
 mov r8,[r13+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET]
 cmp [r8+rcx*8],rax
 je .next_node
 mov [r8+rcx*8],rax
 mov r11d,1
.next_node:
 inc rcx
 jmp .node
.changed:
 test r11d,r11d
 jnz .iteration
 mov [r13+NEBOC_ANALYSIS_DATAFLOW_ITERATIONS_OFFSET],rbx
 mov qword [r13+NEBOC_ANALYSIS_DATAFLOW_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.budget:
 mov [r13+NEBOC_ANALYSIS_DATAFLOW_ITERATIONS_OFFSET],rbx
 mov qword [r13+NEBOC_ANALYSIS_DATAFLOW_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_analysis_effects
 push r12
 mov r12,rdi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rsi+NEBOC_ANALYSIS_NODE_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_ID_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_NODE_OFFSET],rcx
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_EFFECTS_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_PRIMARY_OFFSET],rcx
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_CAPABILITIES_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_SECONDARY_OFFSET],rcx
 mov [rdx+NEBOC_ANALYSIS_FACT_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_analysis_ownership
 push r12
 mov r12,rdi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[rsi+NEBOC_ANALYSIS_NODE_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_ID_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_NODE_OFFSET],rcx
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_OWNERSHIP_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_PRIMARY_OFFSET],rcx
 mov rcx,[rsi+NEBOC_ANALYSIS_NODE_LIFETIME_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_FACT_SECONDARY_OFFSET],rcx
 mov [rdx+NEBOC_ANALYSIS_FACT_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_analysis_call_graph
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 mov r8,[r13+NEBOC_ANALYSIS_FUNCTION_CALL_COUNT_OFFSET]
 cmp r8,NEBOC_ANALYSIS_MAX_CALLS
 ja .limit
 xor r9d,r9d
 test r8,r8
 jz .store
 cmp qword [r13+NEBOC_ANALYSIS_FUNCTION_CALLS_OFFSET],0
 je .invalid
 xor ebx,ebx
.loop:
 cmp rbx,r8
 jae .store
 mov r10,[r13+NEBOC_ANALYSIS_FUNCTION_CALLS_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_CALL_SIZE
 add r10,rax
 mov rax,[r10+NEBOC_ANALYSIS_CALL_KIND_OFFSET]
 cmp rax,NEBOC_ANALYSIS_EDGE_KNOWN
 je .known
 cmp rax,NEBOC_ANALYSIS_EDGE_UNKNOWN
 jne .invalid
 cmp qword [r10+NEBOC_ANALYSIS_CALL_CALLEE_OFFSET],0
 jne .invalid
 inc r9
 jmp .next
.known:
 cmp qword [r10+NEBOC_ANALYSIS_CALL_CALLEE_OFFSET],0
 je .invalid
.next:
 inc rbx
 jmp .loop
.store:
 mov [rdx+NEBOC_ANALYSIS_CALLGRAPH_FUNCTION_OFFSET],r13
 mov rax,[r13+NEBOC_ANALYSIS_FUNCTION_CALLS_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_CALLGRAPH_CALLS_OFFSET],rax
 mov [rdx+NEBOC_ANALYSIS_CALLGRAPH_CALL_COUNT_OFFSET],r8
 mov [rdx+NEBOC_ANALYSIS_CALLGRAPH_UNKNOWN_COUNT_OFFSET],r9
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [rdx+NEBOC_ANALYSIS_CALLGRAPH_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_analysis_cost
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 mov rax,[r13+NEBOC_ANALYSIS_NODE_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 xor r11d,r11d
 mov rax,[r13+NEBOC_ANALYSIS_NODE_ALLOCATIONS_OFFSET]
 mul qword [r14+NEBOC_ANALYSIS_COST_WEIGHT_ALLOC_OFFSET]
 test rdx,rdx
 jnz .limit
 add r11,rax
 jc .limit
 mov rax,[r13+NEBOC_ANALYSIS_NODE_COPIES_OFFSET]
 mul qword [r14+NEBOC_ANALYSIS_COST_WEIGHT_COPY_OFFSET]
 test rdx,rdx
 jnz .limit
 add r11,rax
 jc .limit
 mov rax,[r13+NEBOC_ANALYSIS_NODE_IO_OFFSET]
 mul qword [r14+NEBOC_ANALYSIS_COST_WEIGHT_IO_OFFSET]
 test rdx,rdx
 jnz .limit
 add r11,rax
 jc .limit
 mov rax,[r13+NEBOC_ANALYSIS_NODE_SYNC_OFFSET]
 mul qword [r14+NEBOC_ANALYSIS_COST_WEIGHT_SYNC_OFFSET]
 test rdx,rdx
 jnz .limit
 add r11,rax
 jc .limit
 mov rax,[r13+NEBOC_ANALYSIS_NODE_MATERIALIZATION_OFFSET]
 mul qword [r14+NEBOC_ANALYSIS_COST_WEIGHT_MATERIALIZE_OFFSET]
 test rdx,rdx
 jnz .limit
 add r11,rax
 jc .limit
 mov [r15+NEBOC_ANALYSIS_COST_NODE_OFFSET],r13
 mov [r15+NEBOC_ANALYSIS_COST_MODEL_OUT_OFFSET],r14
 mov [r15+NEBOC_ANALYSIS_COST_TOTAL_OFFSET],r11
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [r15+NEBOC_ANALYSIS_COST_SNAPSHOT_OFFSET],rax
 xor eax,eax
 jmp .done
.stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_analysis_query
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call analysis_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_SNAPSHOT_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 jne .stale
 cmp qword [r13+NEBOC_ANALYSIS_QUERY_KEY_OFFSET],0
 je .invalid
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_DEPTH_OFFSET]
 cmp rax,[r12+NEBOC_ANALYSIS_SESSION_MAX_QUERY_DEPTH_OFFSET]
 ja .limit
 xor ebx,ebx
.find:
 cmp rbx,[r12+NEBOC_ANALYSIS_SESSION_CACHE_COUNT_OFFSET]
 jae .miss
 mov r8,[r12+NEBOC_ANALYSIS_SESSION_CACHE_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_QUERY_ENTRY_SIZE
 add r8,rax
 cmp qword [r8+NEBOC_ANALYSIS_QUERY_ENTRY_STATE_OFFSET],1
 jne .next
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_KEY_OFFSET]
 cmp [r8+NEBOC_ANALYSIS_QUERY_ENTRY_KEY_OFFSET],rax
 jne .next
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_SNAPSHOT_OFFSET]
 cmp [r8+NEBOC_ANALYSIS_QUERY_ENTRY_SNAPSHOT_OFFSET],rax
 jne .next
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_DEPENDENCY_OFFSET]
 cmp [r8+NEBOC_ANALYSIS_QUERY_ENTRY_DEPENDENCY_OFFSET],rax
 jne .next
 mov rax,[r8+NEBOC_ANALYSIS_QUERY_ENTRY_RESULT_OFFSET]
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_VALUE_OFFSET],rax
 mov rax,[r8+NEBOC_ANALYSIS_QUERY_ENTRY_DEPENDENCY_OFFSET]
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_DEPENDENCY_OFFSET],rax
 mov rax,[r8+NEBOC_ANALYSIS_QUERY_ENTRY_PROVENANCE_OFFSET]
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_PROVENANCE_OFFSET],rax
 mov rax,[r8+NEBOC_ANALYSIS_QUERY_ENTRY_SNAPSHOT_OFFSET]
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_SNAPSHOT_OFFSET],rax
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_CACHE_HIT_OFFSET],1
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.next:
 inc rbx
 jmp .find
.miss:
 cmp rbx,[r12+NEBOC_ANALYSIS_SESSION_CACHE_CAPACITY_OFFSET]
 jae .limit
 mov r8,[r12+NEBOC_ANALYSIS_SESSION_CACHE_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_QUERY_ENTRY_SIZE
 add r8,rax
 mov rax,[r13+NEBOC_ANALYSIS_QUERY_KEY_OFFSET]
 mov [r8+NEBOC_ANALYSIS_QUERY_ENTRY_KEY_OFFSET],rax
 mov rcx,[r13+NEBOC_ANALYSIS_QUERY_SNAPSHOT_OFFSET]
 mov [r8+NEBOC_ANALYSIS_QUERY_ENTRY_SNAPSHOT_OFFSET],rcx
 mov rdx,[r13+NEBOC_ANALYSIS_QUERY_DEPENDENCY_OFFSET]
 mov [r8+NEBOC_ANALYSIS_QUERY_ENTRY_DEPENDENCY_OFFSET],rdx
 mov r9,[r13+NEBOC_ANALYSIS_QUERY_PROVENANCE_OFFSET]
 mov [r8+NEBOC_ANALYSIS_QUERY_ENTRY_PROVENANCE_OFFSET],r9
 xor rax,rcx
 rol rax,17
 xor rax,rdx
 rol rax,13
 xor rax,r9
 mov [r8+NEBOC_ANALYSIS_QUERY_ENTRY_RESULT_OFFSET],rax
 mov qword [r8+NEBOC_ANALYSIS_QUERY_ENTRY_STATE_OFFSET],1
 inc qword [r12+NEBOC_ANALYSIS_SESSION_CACHE_COUNT_OFFSET]
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_VALUE_OFFSET],rax
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_DEPENDENCY_OFFSET],rdx
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_PROVENANCE_OFFSET],r9
 mov [r14+NEBOC_ANALYSIS_QUERY_RESULT_SNAPSHOT_OFFSET],rcx
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_CACHE_HIT_OFFSET],0
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .done
.stale:
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_COMPLETION_OFFSET],0
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.limit:
 mov qword [r14+NEBOC_ANALYSIS_QUERY_RESULT_COMPLETION_OFFSET],NEBOC_ANALYSIS_INCOMPLETE_BUDGET
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
