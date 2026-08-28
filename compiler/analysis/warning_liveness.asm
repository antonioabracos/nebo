; C05-F01 warning liveness adapter over the RF52-G48 analysis substrate.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/analysis/analysis.inc"
%include "compiler/analysis/warning_liveness.inc"

extern neboc_analysis_control_flow
extern neboc_analysis_data_flow

section .text

warning_liveness_validate_session:
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

; warning_liveness_build(session*, function*, plan*)
; The caller owns CFG and four block-mask arrays.  Events are read only.  For
; combined USE|DEFINE events the use is observed first, matching `x = x + 1`.
NEBOC_ABI_FUNCTION neboc_warning_liveness_build
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,NEBOC_ANALYSIS_DATAFLOW_SIZE+8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call warning_liveness_validate_session
 test eax,eax
 jnz .done
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov rdx,[r14+NEBOC_WARNING_LIVENESS_PLAN_CFG_OFFSET]
 test rdx,rdx
 jz .invalid
 cmp qword [r14+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET],0
 je .invalid
 cmp qword [r14+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET],0
 je .invalid
 cmp qword [r14+NEBOC_WARNING_LIVENESS_PLAN_IN_OFFSET],0
 je .invalid
 cmp qword [r14+NEBOC_WARNING_LIVENESS_PLAN_OUT_OFFSET],0
 je .invalid
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_ANALYSIS_MAX_BLOCKS
 ja .limit
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_ANALYSIS_MAX_ITERATIONS
 ja .limit
 mov rdi,r12
 mov rsi,r13
 call neboc_analysis_control_flow
 test eax,eax
 jnz .done

 mov r15,[r14+NEBOC_WARNING_LIVENESS_PLAN_CFG_OFFSET]
 mov rax,[r15+NEBOC_ANALYSIS_CFG_BLOCK_COUNT_OFFSET]
 cmp rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET]
 ja .limit
 mov [r14+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET],rax
 mov rcx,[r13+NEBOC_ANALYSIS_FUNCTION_EVENT_COUNT_OFFSET]
 test rcx,rcx
 jz .clear
 cmp qword [r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET],0
 je .invalid
.clear:
 xor ebx,ebx
.clear_loop:
 cmp rbx,[r14+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET]
 jae .blocks
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET]
 mov qword [rax+rbx*8],0
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET]
 mov qword [rax+rbx*8],0
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_IN_OFFSET]
 mov qword [rax+rbx*8],0
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_OUT_OFFSET]
 mov qword [rax+rbx*8],0
 inc rbx
 jmp .clear_loop

.blocks:
 xor ebx,ebx
.block_loop:
 cmp rbx,[r14+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET]
 jae .solve
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_BLOCKS_OFFSET]
 mov rax,rbx
 imul rax,NEBOC_ANALYSIS_BLOCK_SIZE
 add rdi,rax
 mov r10,[rdi+NEBOC_ANALYSIS_BLOCK_FIRST_EVENT_OFFSET]
 mov r11,r10
 add r11,[rdi+NEBOC_ANALYSIS_BLOCK_EVENT_COUNT_OFFSET]
 xor r8d,r8d                    ; generated-before-definition mask
 xor r9d,r9d                    ; definition/kill mask
.event_loop:
 cmp r10,r11
 jae .store_masks
 mov rdi,[r13+NEBOC_ANALYSIS_FUNCTION_EVENTS_OFFSET]
 mov rax,r10
 imul rax,NEBOC_ANALYSIS_EVENT_SIZE
 add rdi,rax
 mov rdx,[rdi+NEBOC_ANALYSIS_EVENT_FLAGS_OFFSET]
 test rdx,rdx
 jz .invalid
 mov rax,rdx
 and rax,~(NEBOC_ANALYSIS_EVENT_DEFINE|NEBOC_ANALYSIS_EVENT_USE)
 jnz .invalid
 mov rcx,[rdi+NEBOC_ANALYSIS_EVENT_SYMBOL_OFFSET]
 test rcx,rcx
 jz .invalid
 cmp rcx,NEBOC_WARNING_LIVENESS_MAX_SYMBOLS
 ja .limit
 dec rcx
 mov rax,1
 shl rax,cl
 test rdx,NEBOC_ANALYSIS_EVENT_USE
 jz .event_define
 test r9,rax
 jnz .event_define
 or r8,rax
.event_define:
 test rdx,NEBOC_ANALYSIS_EVENT_DEFINE
 jz .event_next
 or r9,rax
.event_next:
 inc r10
 jmp .event_loop
.store_masks:
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET]
 mov [rax+rbx*8],r8
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET]
 mov [rax+rbx*8],r9
 inc rbx
 jmp .block_loop

.solve:
 lea rdi,[rsp]
 mov rcx,NEBOC_ANALYSIS_DATAFLOW_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_CFG_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_CFG_OFFSET],rax
 mov qword [rsp+NEBOC_ANALYSIS_DATAFLOW_DIRECTION_OFFSET],NEBOC_ANALYSIS_DIRECTION_BACKWARD
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_GEN_OFFSET],rax
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_KILL_OFFSET],rax
 mov qword [rsp+NEBOC_ANALYSIS_DATAFLOW_INITIAL_OFFSET],0
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_IN_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_IN_OFFSET],rax
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_OUT_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_OUT_OFFSET],rax
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_CAPACITY_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_CAPACITY_OFFSET],rax
 mov rax,[r14+NEBOC_WARNING_LIVENESS_PLAN_MAX_ITERATIONS_OFFSET]
 mov [rsp+NEBOC_ANALYSIS_DATAFLOW_MAX_ITERATIONS_OFFSET],rax
 mov rdi,r12
 lea rsi,[rsp]
 call neboc_analysis_data_flow
 mov rdx,[rsp+NEBOC_ANALYSIS_DATAFLOW_ITERATIONS_OFFSET]
 mov [r14+NEBOC_WARNING_LIVENESS_PLAN_ITERATIONS_OFFSET],rdx
 mov rdx,[rsp+NEBOC_ANALYSIS_DATAFLOW_COMPLETION_OFFSET]
 mov [r14+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],rdx
 mov rdx,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 mov [r14+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET],rdx
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,NEBOC_ANALYSIS_DATAFLOW_SIZE+8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; warning_liveness_query(session*, plan*, block_id, symbol_id, out*)
NEBOC_ABI_FUNCTION neboc_warning_liveness_query
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 call warning_liveness_validate_session
 test eax,eax
 jnz .query_done
 test r13,r13
 jz .query_invalid
 test rbx,rbx
 jz .query_invalid
 mov rax,[r12+NEBOC_ANALYSIS_SESSION_SNAPSHOT_OFFSET]
 cmp [r13+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET],rax
 jne .query_stale
 cmp qword [r13+NEBOC_WARNING_LIVENESS_PLAN_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 jne .query_incomplete
 cmp r14,[r13+NEBOC_WARNING_LIVENESS_PLAN_BLOCK_COUNT_OFFSET]
 jae .query_invalid
 test r15,r15
 jz .query_invalid
 cmp r15,NEBOC_WARNING_LIVENESS_MAX_SYMBOLS
 ja .query_limit
 mov rcx,r15
 dec rcx
 mov rdx,1
 shl rdx,cl
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_BLOCK_OFFSET],r14
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_SYMBOL_OFFSET],r15
 mov rax,[r13+NEBOC_WARNING_LIVENESS_PLAN_IN_OFFSET]
 mov rax,[rax+r14*8]
 test rax,rdx
 setnz al
 movzx eax,al
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_LIVE_IN_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_LIVENESS_PLAN_OUT_OFFSET]
 mov rax,[rax+r14*8]
 test rax,rdx
 setnz al
 movzx eax,al
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_LIVE_OUT_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_LIVENESS_PLAN_GEN_OFFSET]
 mov rax,[rax+r14*8]
 test rax,rdx
 setnz al
 movzx eax,al
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_GENERATED_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_LIVENESS_PLAN_KILL_OFFSET]
 mov rax,[rax+r14*8]
 test rax,rdx
 setnz al
 movzx eax,al
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_KILLED_OFFSET],rax
 mov rax,[r13+NEBOC_WARNING_LIVENESS_PLAN_SNAPSHOT_OFFSET]
 mov [rbx+NEBOC_WARNING_LIVENESS_QUERY_SNAPSHOT_OFFSET],rax
 mov qword [rbx+NEBOC_WARNING_LIVENESS_QUERY_COMPLETION_OFFSET],NEBOC_ANALYSIS_COMPLETE
 xor eax,eax
 jmp .query_done
.query_stale:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .query_done
.query_incomplete:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .query_done
.query_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .query_done
.query_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.query_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
