; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY bounded LIFO cleanup planning for every exit edge.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

section .text
; cleanup_plan_prepare(action_count, out_plan*)
NEBOC_ABI_FUNCTION neboc_cleanup_plan_prepare
 test rsi,rsi
 jz .invalid
 cmp rdi,NEBOC_EVAL_PLAN_MAX_CLEANUPS
 ja .limit
 mov qword [rsi+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_EAGER_BINARY
 mov qword [rsi+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_BOUNDED_CLEANUP
 mov qword [rsi+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rsi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov [rsi+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],rdi
 mov qword [rsi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],0
 mov qword [rsi+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; cleanup_next(actions*, action_count, completed_count, out_action*)
; Returns the next action in reverse registration order without mutation.
NEBOC_ABI_FUNCTION neboc_cleanup_next
 test rdi,rdi
 jz .next_invalid
 test rcx,rcx
 jz .next_invalid
 cmp rsi,NEBOC_EVAL_PLAN_MAX_CLEANUPS
 ja .next_limit
 cmp rdx,rsi
 jae .next_source
 mov rax,rsi
 dec rax
 sub rax,rdx
 mov rax,[rdi+rax*8]
 mov [rcx],rax
 xor eax,eax
 ret
.next_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.next_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.next_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
