; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW optional member-chain plan for `?.`.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

section .text
; optional_chain(option_tag, receiver_payload, member_id, out_plan*)
NEBOC_ABI_FUNCTION neboc_optional_chain
 test rcx,rcx
 jz .invalid
 cmp rdi,1
 ja .source
 mov qword [rcx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_OPTIONAL_CHAIN
 mov qword [rcx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY
 mov qword [rcx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rcx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rdx
 mov [rcx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],rsi
 test rdi,rdi
 jz .none
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
.none:
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
