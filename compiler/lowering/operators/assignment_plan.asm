; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY atomic compound-assignment lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

section .text
; assignment_plan(operation_status, cleanup_count, out_plan*)
; A non-zero operation status records typed failure and forbids the store.
NEBOC_ABI_FUNCTION neboc_assignment_plan
 test rdx,rdx
 jz .invalid
 cmp rsi,NEBOC_EVAL_PLAN_MAX_CLEANUPS
 ja .limit
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_ASSIGNMENT
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_ATOMIC_STORE|NEBOC_EVAL_PLAN_FLAG_BOUNDED_CLEANUP
 mov qword [rdx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov [rdx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],rsi
 mov [rdx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],rdi
 mov qword [rdx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 test rdi,rdi
 jnz .typed_failure
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 xor eax,eax
 ret
.typed_failure:
 mov eax,edi
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; assignment_commit(plan*, target*) writes the staged value only for a valid
; success plan. staged value lives in AUXILIARY and failures are atomic.
NEBOC_ABI_FUNCTION neboc_assignment_commit
 test rdi,rdi
 jz .commit_invalid
 test rsi,rsi
 jz .commit_invalid
 cmp qword [rdi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_ASSIGNMENT
 jne .commit_source
 cmp qword [rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 jne .commit_failure
 cmp qword [rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 jne .commit_source
 mov rax,[rdi+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET]
 mov [rsi],rax
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
