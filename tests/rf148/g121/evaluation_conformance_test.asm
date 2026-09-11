; EXACTLY-ONCE-SHORT-CIRCUIT-CLEANUP-E-FAILURE-ATOMICITY native conformance harness.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"
%include "compiler/lowering/operators/failure_resource_ledger.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

extern neboc_evaluation_plan_eager
extern neboc_evaluation_plan_validate
extern neboc_evaluation_plan_abi
extern neboc_evaluation_plan_from_operator_lowering
extern neboc_evaluation_state_init
extern neboc_materialize_operand_once
extern neboc_evaluation_order_validate
extern neboc_emit_lazy_right_operand
extern neboc_short_circuit_plan
extern neboc_assignment_plan
extern neboc_assignment_commit
extern neboc_cleanup_plan_prepare
extern neboc_cleanup_next
extern neboc_cleanup_take_next
extern neboc_option_result_lazy_plan
extern neboc_failure_ledger_init
extern neboc_failure_ledger_record
extern neboc_failure_ledger_seal
extern neboc_failure_ledger_validate
extern neboc_verify_failure_atomicity

%define SHORT_AND 1
%define SHORT_OR 2
%define LAZY_RESULT 1
%define LAZY_COALESCE 2
%define LAZY_CHAIN 3
%define LAZY_ASSIGN 4
%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .rodata align=8
actions: dq 11,22,33
expected_left_right: dq NEBOC_EVAL_OPERAND_LEFT,NEBOC_EVAL_OPERAND_RIGHT
expected_right: dq NEBOC_EVAL_OPERAND_RIGHT

section .bss align=16
plan: resb NEBOC_EVAL_PLAN_SIZE
operator_plan: resb NEBOC_OPERATOR_LOWER_SIZE
state: resb NEBOC_EVAL_STATE_SIZE
ledger: resb NEBOC_LEDGER_SIZE
out_value: resq 1
target: resq 1

section .text
global _start
_start:
 mov ebx,1
 lea rdi,[rel plan]
 call neboc_evaluation_plan_eager
 test eax,eax
 jnz fail
 lea rdi,[rel plan]
 call neboc_evaluation_plan_validate
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_LEFT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 call neboc_evaluation_plan_abi
 cmp eax,NEBOC_EVAL_PLAN_SCHEMA_VERSION
 jne fail
 cmp edx,NEBOC_EVAL_PLAN_SIZE
 jne fail
 cmp ecx,NEBOC_EVAL_STATE_SIZE
 jne fail
 cmp r8d,NEBOC_EVAL_OPERAND_COUNT
 jne fail

 ; A typed G120 lowering record becomes the canonical G121 plan only after
 ; complete validation and without evaluating either operand.
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET],NEBOC_OPERATOR_PROTOCOL_ADD
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_EVALUATION_ORDER_OFFSET],0
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_LEFT_EVALUATIONS_OFFSET],1
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_RIGHT_EVALUATIONS_OFFSET],1
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],NEBOC_OPERATOR_CONTROL_NONE
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_FAILURE_POLICY_OFFSET],NEBOC_OPERATOR_FAILURE_CHECKED
 mov rax,SENTINEL
 mov [rel plan+NEBOC_EVAL_PLAN_KIND_OFFSET],rax
 lea rdi,[rel operator_plan]
 lea rsi,[rel plan]
 call neboc_evaluation_plan_from_operator_lowering
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel plan+NEBOC_EVAL_PLAN_KIND_OFFSET],rax
 jne fail
 mov qword [rel operator_plan+NEBOC_OPERATOR_LOWER_EVALUATION_ORDER_OFFSET],NEBOC_OPERATOR_EVALUATION_LEFT_TO_RIGHT
 lea rdi,[rel operator_plan]
 lea rsi,[rel plan]
 call neboc_evaluation_plan_from_operator_lowering
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],NEBOC_OPERATOR_PROTOCOL_ADD
 jne fail

 mov ebx,7
 lea rdi,[rel state]
 call neboc_evaluation_state_init
 test eax,eax
 jnz fail
 lea rdi,[rel state]
 mov esi,NEBOC_EVAL_OPERAND_LEFT
 mov edx,71
 lea rcx,[rel out_value]
 call neboc_materialize_operand_once
 test eax,eax
 jnz fail
 cmp qword [rel out_value],71
 jne fail
 lea rdi,[rel state]
 mov esi,NEBOC_EVAL_OPERAND_RIGHT
 mov edx,29
 lea rcx,[rel out_value]
 call neboc_materialize_operand_once
 test eax,eax
 jnz fail
 cmp qword [rel out_value],29
 jne fail
 lea rdi,[rel state]
 lea rsi,[rel expected_left_right]
 mov edx,2
 call neboc_evaluation_order_validate
 test eax,eax
 jnz fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 lea rdi,[rel state]
 mov esi,NEBOC_EVAL_OPERAND_LEFT
 mov edx,99
 lea rcx,[rel out_value]
 call neboc_materialize_operand_once
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 cmp qword [rel state+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET],2
 jne fail

 mov ebx,2
 mov edi,SHORT_AND
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_short_circuit_plan
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 jne fail
 mov edi,SHORT_OR
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_short_circuit_plan
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 ; Invalid Bool/tag input fails before publishing a plan.
 mov rax,SENTINEL
 mov [rel plan],rax
 mov edi,SHORT_AND
 mov esi,2
 lea rdx,[rel plan]
 call neboc_short_circuit_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel plan],rax
 jne fail

 ; The shared lazy emitter preserves output/state for a skipped RHS and
 ; materializes one selected RHS exactly once.
 lea rdi,[rel state]
 call neboc_evaluation_state_init
 mov edi,SHORT_AND
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_short_circuit_plan
 mov rax,SENTINEL
 mov [rel out_value],rax
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov edx,41
 lea rcx,[rel out_value]
 call neboc_emit_lazy_right_operand
 test eax,eax
 jnz fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 cmp qword [rel state+NEBOC_EVAL_STATE_EVENT_COUNT_OFFSET],0
 jne fail
 mov edi,SHORT_OR
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_short_circuit_plan
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov edx,43
 lea rcx,[rel out_value]
 call neboc_emit_lazy_right_operand
 test eax,eax
 jnz fail
 cmp qword [rel out_value],43
 jne fail
 lea rdi,[rel state]
 lea rsi,[rel expected_right]
 mov edx,1
 call neboc_evaluation_order_validate
 test eax,eax
 jnz fail
 lea rdi,[rel plan]
 lea rsi,[rel state]
 mov edx,47
 lea rcx,[rel out_value]
 call neboc_emit_lazy_right_operand
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov ebx,3
 mov edi,NEBOC_STATUS_LIMIT_EXCEEDED
 mov esi,2
 lea rdx,[rel plan]
 call neboc_assignment_plan
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 mov [rel target],rax
 mov qword [rel plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],99
 lea rdi,[rel plan]
 lea rsi,[rel target]
 call neboc_assignment_commit
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel target],rax
 jne fail
 xor edi,edi
 mov esi,2
 lea rdx,[rel plan]
 call neboc_assignment_plan
 test eax,eax
 jnz fail
 mov qword [rel plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],99
 lea rdi,[rel plan]
 lea rsi,[rel target]
 call neboc_assignment_commit
 test eax,eax
 jnz fail
 cmp qword [rel target],99
 jne fail
 mov qword [rel plan+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET],101
 lea rdi,[rel plan]
 lea rsi,[rel target]
 call neboc_assignment_commit
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel target],99
 jne fail

 mov ebx,4
 mov edi,3
 lea rsi,[rel plan]
 call neboc_cleanup_plan_prepare
 test eax,eax
 jnz fail
 lea rdi,[rel actions]
 mov esi,3
 xor edx,edx
 lea rcx,[rel out_value]
 call neboc_cleanup_next
 test eax,eax
 jnz fail
 cmp qword [rel out_value],33
 jne fail
 lea rdi,[rel actions]
 mov esi,3
 mov edx,2
 lea rcx,[rel out_value]
 call neboc_cleanup_next
 test eax,eax
 jnz fail
 cmp qword [rel out_value],11
 jne fail
 ; Stateful cleanup consumption forbids duplicate drop/defer actions.
 mov edi,3
 lea rsi,[rel plan]
 call neboc_cleanup_plan_prepare
 test eax,eax
 jnz fail
 lea rdi,[rel actions]
 lea rsi,[rel plan]
 lea rdx,[rel out_value]
 call neboc_cleanup_take_next
 test eax,eax
 jnz fail
 cmp qword [rel out_value],33
 jne fail
 lea rdi,[rel actions]
 lea rsi,[rel plan]
 lea rdx,[rel out_value]
 call neboc_cleanup_take_next
 test eax,eax
 jnz fail
 cmp qword [rel out_value],22
 jne fail
 lea rdi,[rel actions]
 lea rsi,[rel plan]
 lea rdx,[rel out_value]
 call neboc_cleanup_take_next
 test eax,eax
 jnz fail
 cmp qword [rel out_value],11
 jne fail
 lea rdi,[rel actions]
 lea rsi,[rel plan]
 lea rdx,[rel out_value]
 call neboc_cleanup_take_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel out_value],11
 jne fail

 mov ebx,5
 mov edi,LAZY_RESULT
 mov esi,1
 lea rdx,[rel plan]
 call neboc_option_result_lazy_plan
 test eax,eax
 jnz fail
 test qword [rel plan+NEBOC_EVAL_PLAN_FLAGS_OFFSET],NEBOC_EVAL_PLAN_FLAG_EARLY_RETURN
 jz fail
 mov edi,LAZY_COALESCE
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_option_result_lazy_plan
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 mov edi,LAZY_CHAIN
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_option_result_lazy_plan
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET],0
 jne fail
 mov edi,LAZY_ASSIGN
 xor esi,esi
 lea rdx,[rel plan]
 call neboc_option_result_lazy_plan
 test eax,eax
 jnz fail
 cmp qword [rel plan+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],1
 jne fail

 mov ebx,6
 ; Failed assignment: two operands and target are observed, no store commits,
 ; resources balance, typed failure/diagnostic match the plan.
 mov edi,NEBOC_STATUS_LIMIT_EXCEEDED
 mov esi,2
 lea rdx,[rel plan]
 call neboc_assignment_plan
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 lea rdi,[rel ledger]
 call neboc_failure_ledger_init
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_OPERAND
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_OPERAND
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_TARGET
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_ACQUIRE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_ACQUIRE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_ACQUIRE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_RELEASE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_RELEASE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_RELEASE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_STATUS_LIMIT_EXCEEDED
 mov edx,77
 call neboc_failure_ledger_seal
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 call neboc_failure_ledger_validate
 test eax,eax
 jnz fail
 lea rdi,[rel plan]
 lea rsi,[rel ledger]
 call neboc_verify_failure_atomicity
 test eax,eax
 jnz fail

 ; A failed seal after a recorded store is transactional: it does not seal or
 ; publish status/diagnostic fields and therefore cannot validate.
 lea rdi,[rel ledger]
 call neboc_failure_ledger_init
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_LEDGER_EVENT_STORE
 call neboc_failure_ledger_record
 test eax,eax
 jnz fail
 lea rdi,[rel ledger]
 mov esi,NEBOC_STATUS_LIMIT_EXCEEDED
 mov edx,79
 call neboc_failure_ledger_seal
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel ledger+NEBOC_LEDGER_FLAGS],0
 jne fail
 cmp qword [rel ledger+NEBOC_LEDGER_FAILURE_STATUS],0
 jne fail
 cmp qword [rel ledger+NEBOC_LEDGER_DIAGNOSTIC],0
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
