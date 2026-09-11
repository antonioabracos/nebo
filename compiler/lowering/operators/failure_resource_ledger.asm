; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY deterministic failure/resource accounting.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"
%include "compiler/lowering/operators/failure_resource_ledger.inc"

section .text
NEBOC_ABI_FUNCTION neboc_failure_ledger_init
 test rdi,rdi
 jz .invalid
 xor eax,eax
 mov ecx,NEBOC_LEDGER_SIZE/8
 rep stosq
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; failure_ledger_record(ledger*, event) records bounded effects while the
; ledger is open.  Every rejected event leaves all counters unchanged.
NEBOC_ABI_FUNCTION neboc_failure_ledger_record
 test rdi,rdi
 jz .record_invalid
 test qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jnz .record_source
 cmp rsi,NEBOC_LEDGER_EVENT_OPERAND
 jb .record_source
 cmp rsi,NEBOC_LEDGER_EVENT_COUNT
 ja .record_source
 cmp rsi,NEBOC_LEDGER_EVENT_OPERAND
 je .record_operand
 cmp rsi,NEBOC_LEDGER_EVENT_TARGET
 je .record_target
 cmp rsi,NEBOC_LEDGER_EVENT_STORE
 je .record_store
 cmp rsi,NEBOC_LEDGER_EVENT_ACQUIRE
 je .record_acquire
 mov rax,[rdi+NEBOC_LEDGER_RESOURCES_RELEASED]
 cmp rax,[rdi+NEBOC_LEDGER_RESOURCES_ACQUIRED]
 jae .record_source
 inc qword [rdi+NEBOC_LEDGER_RESOURCES_RELEASED]
 xor eax,eax
 ret
.record_operand:
 cmp qword [rdi+NEBOC_LEDGER_OPERAND_EVALS],2
 jae .record_source
 inc qword [rdi+NEBOC_LEDGER_OPERAND_EVALS]
 xor eax,eax
 ret
.record_target:
 cmp qword [rdi+NEBOC_LEDGER_TARGET_EVALS],1
 jae .record_source
 inc qword [rdi+NEBOC_LEDGER_TARGET_EVALS]
 xor eax,eax
 ret
.record_store:
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],1
 jae .record_source
 inc qword [rdi+NEBOC_LEDGER_STORE_COUNT]
 xor eax,eax
 ret
.record_acquire:
 cmp qword [rdi+NEBOC_LEDGER_RESOURCES_ACQUIRED],NEBOC_EVAL_PLAN_MAX_CLEANUPS
 jae .record_limit
 inc qword [rdi+NEBOC_LEDGER_RESOURCES_ACQUIRED]
 xor eax,eax
 ret
.record_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.record_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.record_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; failure_ledger_seal(ledger*, operation_status, diagnostic)
NEBOC_ABI_FUNCTION neboc_failure_ledger_seal
 test rdi,rdi
 jz .seal_invalid
 test qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jnz .seal_source
 cmp rsi,NEBOC_STATUS_COUNT
 jae .seal_source
 test rsi,rsi
 jz .seal_success
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],0
 jne .seal_source
 test rdx,rdx
 jz .seal_source
 jmp .seal_commit
.seal_success:
 test rdx,rdx
 jnz .seal_source
.seal_commit:
 mov [rdi+NEBOC_LEDGER_FAILURE_STATUS],rsi
 mov [rdi+NEBOC_LEDGER_DIAGNOSTIC],rdx
 or qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 xor eax,eax
 ret
.seal_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.seal_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; failure_ledger_validate(ledger*) checks exactly-once and leak freedom.
NEBOC_ABI_FUNCTION neboc_failure_ledger_validate
 test rdi,rdi
 jz .validate_invalid
 test qword [rdi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jz .validate_source
 cmp qword [rdi+NEBOC_LEDGER_OPERAND_EVALS],2
 ja .validate_source
 cmp qword [rdi+NEBOC_LEDGER_TARGET_EVALS],1
 ja .validate_source
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],1
 ja .validate_source
 mov rax,[rdi+NEBOC_LEDGER_RESOURCES_ACQUIRED]
 cmp rax,[rdi+NEBOC_LEDGER_RESOURCES_RELEASED]
 jne .validate_source
 cmp qword [rdi+NEBOC_LEDGER_FAILURE_STATUS],0
 je .validate_ok
 cmp qword [rdi+NEBOC_LEDGER_STORE_COUNT],0
 jne .validate_source
.validate_ok:
 xor eax,eax
 ret
.validate_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.validate_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; verify_failure_atomicity(plan*, ledger*) binds planned evaluation and store
; counts to observed effects.  Failure requires zero stores, a typed diagnostic
; and exact resource balance; success requires the same count parity.
NEBOC_ABI_FUNCTION neboc_verify_failure_atomicity
 test rdi,rdi
 jz .atomic_invalid
 test rsi,rsi
 jz .atomic_invalid
 test qword [rsi+NEBOC_LEDGER_FLAGS],NEBOC_LEDGER_FLAG_SEALED
 jz .atomic_source
 mov rax,[rdi+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET]
 add rax,[rdi+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET]
 cmp rax,[rsi+NEBOC_LEDGER_OPERAND_EVALS]
 jne .atomic_source
 mov rax,[rdi+NEBOC_EVAL_PLAN_TARGET_EVALUATIONS_OFFSET]
 cmp rax,[rsi+NEBOC_LEDGER_TARGET_EVALS]
 jne .atomic_source
 mov rax,[rdi+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET]
 cmp rax,[rsi+NEBOC_LEDGER_STORE_COUNT]
 jne .atomic_source
 mov rax,[rdi+NEBOC_EVAL_PLAN_FAILURE_CODE_OFFSET]
 cmp rax,[rsi+NEBOC_LEDGER_FAILURE_STATUS]
 jne .atomic_source
 mov rax,[rsi+NEBOC_LEDGER_RESOURCES_ACQUIRED]
 cmp rax,[rsi+NEBOC_LEDGER_RESOURCES_RELEASED]
 jne .atomic_source
 cmp qword [rsi+NEBOC_LEDGER_FAILURE_STATUS],0
 je .atomic_ok
 cmp qword [rsi+NEBOC_LEDGER_STORE_COUNT],0
 jne .atomic_source
 cmp qword [rsi+NEBOC_LEDGER_DIAGNOSTIC],0
 je .atomic_source
.atomic_ok:
 xor eax,eax
 ret
.atomic_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.atomic_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
