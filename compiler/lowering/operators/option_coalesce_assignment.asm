; OPTION-RESULT-RANGES-MATEMATICOS-E-LATERAL-FLOW conditional Option `??=` assignment with zero-store Some path.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

section .text
; option_coalesce_assignment_plan(target*, option_tag, rhs, out_plan*)
NEBOC_ABI_FUNCTION neboc_option_coalesce_assignment_plan
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp rsi,1
 ja .source
 mov qword [rcx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_ASSIGNMENT
 mov qword [rcx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY|NEBOC_EVAL_PLAN_FLAG_ATOMIC_STORE
 mov qword [rcx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rcx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rcx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rdx
 mov [rcx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],rdi
 test rsi,rsi
 jnz .some
 mov qword [rcx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rcx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
.some:
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_option_coalesce_assignment_commit
 test rdi,rdi
 jz .commit_invalid
 cmp qword [rdi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_ASSIGNMENT
 jne .commit_source
 cmp qword [rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 jne .commit_failure
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 je .commit_ok
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 jne .commit_source
 mov rcx,[rdi+NEBOC_EVAL_PLAN_RESERVED_OFFSET]
 test rcx,rcx
 jz .commit_invalid
 mov rax,[rdi+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET]
 mov [rcx],rax
.commit_ok:
 xor eax,eax
 ret
.commit_failure:
 mov eax,[rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET]
 ret
.commit_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.commit_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
