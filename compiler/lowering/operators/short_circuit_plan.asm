; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY lazy branch selection without source-expression execution.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

%define NEBOC_SHORT_CIRCUIT_AND 1
%define NEBOC_SHORT_CIRCUIT_OR 2
%define NEBOC_SHORT_CIRCUIT_RESULT_PROPAGATE 3
%define NEBOC_SHORT_CIRCUIT_OPTION_COALESCE 4
%define NEBOC_SHORT_CIRCUIT_OPTIONAL_CHAIN 5
%define NEBOC_SHORT_CIRCUIT_OPTION_ASSIGN 6

section .text
; short_circuit_plan(operation, lhs_tag_or_bool, out_plan*)
NEBOC_ABI_FUNCTION neboc_short_circuit_plan
 test rdx,rdx
 jz .invalid
 cmp rdi,NEBOC_SHORT_CIRCUIT_AND
 jb .source
 cmp rdi,NEBOC_SHORT_CIRCUIT_OPTION_ASSIGN
 ja .source
 mov qword [rdx+NEBOC_EVAL_PLAN_KIND_OFFSET],NEBOC_EVAL_PLAN_KIND_SHORT_CIRCUIT
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY
 mov qword [rdx+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_CLEANUP_COUNT_OFFSET],0
 mov qword [rdx+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET],0
 mov [rdx+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],rdi
 mov qword [rdx+NEBOC_EVAL_PLAN_RESERVED_OFFSET],0
 cmp rdi,NEBOC_SHORT_CIRCUIT_AND
 je .and
 cmp rdi,NEBOC_SHORT_CIRCUIT_OR
 je .or
 cmp rdi,NEBOC_SHORT_CIRCUIT_RESULT_PROPAGATE
 je .result
 ; Option-family RHS/member/assignment is selected only for the relevant tag.
 cmp rdi,NEBOC_SHORT_CIRCUIT_OPTION_COALESCE
 je .option_none
 cmp rdi,NEBOC_SHORT_CIRCUIT_OPTIONAL_CHAIN
 je .option_some
 ; ??= selects RHS and store only for None (tag zero).
 test rsi,rsi
 jnz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 mov qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAGS_REQUIRED|NEBOC_EVAL_PLAN_FLAG_RHS_LAZY|NEBOC_EVAL_PLAN_FLAG_ATOMIC_STORE
 jmp .done
.and:
 test rsi,rsi
 jz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jmp .done
.or:
 test rsi,rsi
 jnz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jmp .done
.result:
 test rsi,rsi
 jz .done
 or qword [rdx+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
 jmp .done
.option_none:
 test rsi,rsi
 jnz .done
 mov qword [rdx+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jmp .done
.option_some:
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
