; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY shared Option/Result lazy-control plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

%define NEBOC_LAZY_RESULT_PROPAGATE 1
%define NEBOC_LAZY_OPTION_COALESCE 2
%define NEBOC_LAZY_OPTIONAL_CHAIN 3
%define NEBOC_LAZY_OPTION_ASSIGN 4
%define NEBOC_TAG_NONE_OR_OK 0
%define NEBOC_TAG_SOME_OR_ERR 1

section .text
; option_result_lazy_plan(mode, tag, out_plan*)
NEBOC_ABI_FUNCTION neboc_option_result_lazy_plan
 test rdx,rdx
 jz .invalid
 cmp rdi,NEBOC_LAZY_RESULT_PROPAGATE
 jb .source
 cmp rdi,NEBOC_LAZY_OPTION_ASSIGN
 ja .source
 cmp rsi,NEBOC_TAG_SOME_OR_ERR
 ja .source
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY|NEBOC_EVAL_PLAN_FLAG_BOUNDED_CLEANUP
 mov qword [rdx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rdx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rsi
 mov qword [rdx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 cmp rdi,NEBOC_LAZY_RESULT_PROPAGATE
 je .result
 cmp rdi,NEBOC_LAZY_OPTION_COALESCE
 je .coalesce
 cmp rdi,NEBOC_LAZY_OPTIONAL_CHAIN
 je .chain
 ; Conditional assignment evaluates its target once regardless of Option tag.
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_ASSIGNMENT
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],1
 test rsi,rsi
 jnz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 or qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_ATOMIC_STORE
 jmp .done
.result:
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_RESULT_PROPAGATE
 test rsi,rsi
 jz .done
 or qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
 jmp .done
.coalesce:
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_OPTION_COALESCE
 test rsi,rsi
 jnz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jmp .done
.chain:
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_OPTIONAL_CHAIN
 test rsi,rsi
 jz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
.done:
 xor eax,eax
 ret
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
