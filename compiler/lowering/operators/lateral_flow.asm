; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW bounded read-only lateral flow for ASCII `..`.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

%define NEBOC_LATERAL_EFFECT_READ 1
%define NEBOC_LATERAL_EFFECT_DERIVE 2
%define NEBOC_LATERAL_EFFECT_MUTATE 4
%define NEBOC_LATERAL_EFFECT_MOVE 8
%define NEBOC_LATERAL_EFFECT_ESCAPE 16
%define NEBOC_LATERAL_EFFECT_PARALLEL 32
; Parentheses are semantic here: the complement in the validator must mask the
; complete read/derive set, not only the first term after macro expansion.
%define NEBOC_LATERAL_EFFECT_ALLOWED (NEBOC_LATERAL_EFFECT_READ|NEBOC_LATERAL_EFFECT_DERIVE)

section .text
; lateral_flow_plan(receiver, block_effects, out_plan*)
; AUXILIARY is the original receiver: the block result is always discarded.
NEBOC_ABI_FUNCTION neboc_lateral_flow_plan
 test rdx,rdx
 jz .invalid
 mov rax,rsi
 and rax,~NEBOC_LATERAL_EFFECT_ALLOWED
 jnz .source
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_LATERAL_FLOW
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_BOUNDED_CLEANUP
 mov qword [rdx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rdx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rdi
 mov [rdx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],rsi
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
