; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW lazy Option `??` lowering.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

%define NEBOC_OPTION_TAG_NONE 0
%define NEBOC_OPTION_TAG_SOME 1

section .text
; option_coalesce(tag, some_payload, fallback_payload, out_plan*)
; The fallback expression is represented, not executed, and selected only for
; None. AUXILIARY records the selected test payload for native conformance.
NEBOC_ABI_FUNCTION neboc_option_coalesce
 test rcx,rcx
 jz .invalid
 cmp rdi,NEBOC_OPTION_TAG_SOME
 ja .source
 mov qword [rcx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_OPTION_COALESCE
 mov qword [rcx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY
 mov qword [rcx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 test rdi,rdi
 jz .fallback
 mov [rcx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rsi
 xor eax,eax
 ret
.fallback:
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov [rcx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rdx
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
