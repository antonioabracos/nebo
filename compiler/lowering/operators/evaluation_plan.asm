; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY canonical exactly-once eager evaluation plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; evaluation_plan_eager(out_plan*)
NEBOC_ABI_FUNCTION neboc_evaluation_plan_eager
 test rdi,rdi
 jz .invalid
 mov qword [rdi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_EAGER_BINARY
 mov qword [rdi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED
 mov qword [rdi+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rdi+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],NEBOC_STATUS_OK
 mov qword [rdi+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],0
 mov qword [rdi+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; evaluation_plan_validate(plan*) verifies the global order/count invariant.
NEBOC_ABI_FUNCTION neboc_evaluation_plan_validate
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_EVAL_PLAN_KIND_OFFSET],1
 jb .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_COUNT
 ja .source
 mov rax,[rdi+NEBOC_EVAL_PLAN_FLAGS_OFFSET]
 and eax,NEBOC_EVAL_PLAN_FLAGS_REQUIRED
 cmp eax,NEBOC_EVAL_PLAN_FLAGS_REQUIRED
 jne .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 jne .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 ja .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],1
 ja .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 ja .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],NEBOC_EVAL_PLAN_MAX_CLEANUPS
 ja .limit
 cmp qword [rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],NEBOC_STATUS_COUNT
 jae .source
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 je .failure_consistent
 test qword [rdi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_ATOMIC_STORE
 jz .source
.failure_consistent:
 cmp qword [rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 je .ok
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 jne .source
.ok:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; evaluation_plan_abi() -> eax=schema, edx=plan size, ecx=state size,
; r8d=bounded operand identities.
NEBOC_ABI_FUNCTION neboc_evaluation_plan_abi
 mov eax,NEBOC_EVAL_PLAN_SCHEMA_VERSION
 mov edx,NEBOC_EVAL_PLAN_SIZE
 mov ecx,NEBOC_EVAL_STATE_SIZE
 mov r8d,NEBOC_EVAL_OPERAND_COUNT
 ret

; evaluation_plan_from_operator_lowering(operator_plan*, out_plan*) bridges
; typed G120 resolution to the single G121 evaluation contract.  Validation is
; complete before publication, so an invalid lowering plan leaves output
; unchanged.
NEBOC_ABI_FUNCTION neboc_evaluation_plan_from_operator_lowering
 test rdi,rdi
 jz .bridge_invalid
 test rsi,rsi
 jz .bridge_invalid
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_EVALUATION_ORDER_OFFSET],NEBOC_OPERATOR_EVALUATION_LEFT_TO_RIGHT
 jne .bridge_source
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_LEFT_EVALUATIONS_OFFSET],1
 jne .bridge_source
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_RIGHT_EVALUATIONS_OFFSET],1
 ja .bridge_source
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],NEBOC_OPERATOR_CONTROL_RHS_LAZY
 ja .bridge_source
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_FAILURE_POLICY_OFFSET],NEBOC_OPERATOR_FAILURE_CHECKED
 ja .bridge_source
 mov qword [rsi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_EAGER_BINARY
 mov qword [rsi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED
 cmp qword [rdi+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],NEBOC_OPERATOR_CONTROL_RHS_LAZY
 jne .bridge_counts
 mov qword [rsi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_SHORT_CIRCUIT
 or qword [rsi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_RHS_LAZY
.bridge_counts:
 mov qword [rsi+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov rax,[rdi+NEBOC_OPERATOR_LOWER_RIGHT_EVALUATIONS_OFFSET]
 mov [rsi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],rax
 mov qword [rsi+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],NEBOC_STATUS_OK
 mov rax,[rdi+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET]
 mov [rsi+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rax
 mov qword [rsi+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 xor eax,eax
 ret
.bridge_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bridge_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; evaluation_state_init(state*) clears all materialization evidence.
NEBOC_ABI_FUNCTION neboc_evaluation_state_init
 test rdi,rdi
 jz .state_init_invalid
 xor eax,eax
 mov ecx,NEBOC_EVAL_STATE_SIZE/8
 rep stosq
 ret
.state_init_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; materialize_operand_once(state*, operand_id, value, out_value*) publishes a
; reusable temporary and one ordered event.  Duplicate identities fail before
; changing either the state or output.
NEBOC_ABI_FUNCTION neboc_materialize_operand_once
 test rdi,rdi
 jz .materialize_invalid
 test rcx,rcx
 jz .materialize_invalid
 cmp rsi,NEBOC_EVAL_OPERAND_COUNT
 jae .materialize_source
 cmp qword [rdi+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET],NEBOC_EVAL_OPERAND_COUNT
 jae .materialize_limit
 mov r8,rcx
 mov r9,1
 mov ecx,esi
 shl r9,cl
 test [rdi+NEBOC_EVAL_STATE_SEEN_MASK_OFFSET],r9
 jnz .materialize_source
 mov rax,[rdi+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET]
 or [rdi+NEBOC_EVAL_STATE_SEEN_MASK_OFFSET],r9
 mov [rdi+NEBOC_EVAL_STATE_EVENTS_OFFSET+rax*8],rsi
 mov [rdi+NEBOC_EVAL_STATE_VALUES_OFFSET+rsi*8],rdx
 inc rax
 mov [rdi+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET],rax
 mov [r8],rdx
 xor eax,eax
 ret
.materialize_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.materialize_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.materialize_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; evaluation_order_validate(state*, expected_ids*, count) proves the exact
; event count and lexical order against an independent expected sequence.
NEBOC_ABI_FUNCTION neboc_evaluation_order_validate
 test rdi,rdi
 jz .order_invalid
 cmp rdx,NEBOC_EVAL_OPERAND_COUNT
 ja .order_limit
 cmp [rdi+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET],rdx
 jne .order_source
 test rdx,rdx
 jz .order_ok
 test rsi,rsi
 jz .order_invalid
 xor ecx,ecx
.order_loop:
 mov rax,[rdi+NEBOC_EVAL_STATE_EVENTS_OFFSET+rcx*8]
 cmp rax,[rsi+rcx*8]
 jne .order_source
 inc rcx
 cmp rcx,rdx
 jb .order_loop
.order_ok:
 xor eax,eax
 ret
.order_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.order_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.order_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; emit_lazy_right_operand(plan*, state*, value, out_value*) materializes the
; RHS only when the selected semantic branch requests it.  The skipped branch
; succeeds with state and output byte-unchanged.
NEBOC_ABI_FUNCTION neboc_emit_lazy_right_operand
 test rdi,rdi
 jz .lazy_invalid
 test rsi,rsi
 jz .lazy_invalid
 test rcx,rcx
 jz .lazy_invalid
 test qword [rdi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_RHS_LAZY
 jz .lazy_source
 cmp qword [rdi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 ja .lazy_source
 cmp qword [rdi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 je .lazy_skipped
 mov rdi,rsi
 mov esi,NEBOC_EVAL_OPERAND_RIGHT
 jmp neboc_materialize_operand_once
.lazy_skipped:
 xor eax,eax
 ret
.lazy_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.lazy_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
