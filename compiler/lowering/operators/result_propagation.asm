; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW Result postfix `?` propagation plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

%define NEBOC_RESULT_TAG_OK 0
%define NEBOC_RESULT_TAG_ERR 1

section .text
; result_propagation(tag, payload, out_plan*)
; Tag and payload are evaluated once. Err marks a typed early-return edge.
NEBOC_ABI_FUNCTION neboc_result_propagation
 test rdx,rdx
 jz .invalid
 cmp rdi,NEBOC_RESULT_TAG_ERR
 ja .source
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_RESULT_PROPAGATE
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_BOUNDED_CLEANUP
 mov qword [rdx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rdx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rsi
 mov [rdx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],rdi
 test rdi,rdi
 jz .ok
 or qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
.ok:
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
