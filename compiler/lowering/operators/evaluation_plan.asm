; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY canonical exactly-once eager evaluation plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

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

section .note.GNU-stack noalloc noexec nowrite progbits
