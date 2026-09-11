; Typed operator implementation to lowering-plan normalization.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

section .text
; lowering_plan(implementation*, token_kind, out_plan*) -> status.
; The output is committed only after protocol/token/activation validation.
NEBOC_ABI_FUNCTION neboc_operator_lowering_plan
 test rdi,rdi
 jz .invalid_argument
 test rdx,rdx
 jz .invalid_argument
 mov rax,[rdi+NEBOC_OPERATOR_IMPL_FLAGS_OFFSET]
 test rax,NEBOC_OPERATOR_IMPL_FLAG_ACTIVE
 jz .invalid_source
 test rax,NEBOC_OPERATOR_IMPL_FLAG_INACTIVE
 jnz .invalid_source
 test rax,NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
 jz .invalid_source
 test rax,NEBOC_OPERATOR_IMPL_FLAG_COHERENT
 jz .invalid_source
 mov r8,[rdi+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET]
 cmp r8,NEBOC_OPERATOR_PROTOCOL_ADD
 je .token_plus
 cmp r8,NEBOC_OPERATOR_PROTOCOL_SUBTRACT
 je .token_minus
 cmp r8,NEBOC_OPERATOR_PROTOCOL_MULTIPLY
 je .token_star
 cmp r8,NEBOC_OPERATOR_PROTOCOL_DIVIDE
 je .token_slash
 cmp r8,NEBOC_OPERATOR_PROTOCOL_REMAINDER
 je .token_percent
 cmp r8,NEBOC_OPERATOR_PROTOCOL_POWER
 je .token_power
 cmp r8,NEBOC_OPERATOR_PROTOCOL_NEGATE
 je .token_minus
 cmp r8,NEBOC_OPERATOR_PROTOCOL_LOGICAL_NOT
 je .token_bang
 cmp r8,NEBOC_OPERATOR_PROTOCOL_LOGICAL_AND
 je .token_and
 cmp r8,NEBOC_OPERATOR_PROTOCOL_LOGICAL_OR
 je .token_or
 cmp r8,NEBOC_OPERATOR_PROTOCOL_XOR
 je .token_xor
 cmp r8,NEBOC_OPERATOR_PROTOCOL_EQUAL
 je .token_equality
 cmp r8,NEBOC_OPERATOR_PROTOCOL_ORDER
 je .token_order
 jmp .invalid_source
.token_plus: cmp rsi,NEBOC_TOKEN_PLUS
 je .token_ok
 jmp .invalid_source
.token_minus: cmp rsi,NEBOC_TOKEN_MINUS
 je .token_ok
 jmp .invalid_source
.token_star: cmp rsi,NEBOC_TOKEN_STAR
 je .token_ok
 jmp .invalid_source
.token_slash: cmp rsi,NEBOC_TOKEN_SLASH
 je .token_ok
 jmp .invalid_source
.token_percent: cmp rsi,NEBOC_TOKEN_PERCENT
 je .token_ok
 jmp .invalid_source
.token_power: cmp rsi,NEBOC_TOKEN_CARET
 je .token_ok
 jmp .invalid_source
.token_bang: cmp rsi,NEBOC_TOKEN_BANG
 je .token_ok
 jmp .invalid_source
.token_and: cmp rsi,NEBOC_TOKEN_AND_AND
 je .token_ok
 jmp .invalid_source
.token_or: cmp rsi,NEBOC_TOKEN_OR_OR
 je .token_ok
 jmp .invalid_source
.token_xor: cmp rsi,NEBOC_TOKEN_XOR
 je .token_ok
 jmp .invalid_source
.token_equality:
 cmp rsi,NEBOC_TOKEN_EQUAL_EQUAL
 je .token_ok
 cmp rsi,NEBOC_TOKEN_BANG_EQUAL
 je .token_ok
 jmp .invalid_source
.token_order:
 cmp rsi,NEBOC_TOKEN_LESS
 je .token_ok
 cmp rsi,NEBOC_TOKEN_LESS_EQUAL
 je .token_ok
 cmp rsi,NEBOC_TOKEN_GREATER
 je .token_ok
 cmp rsi,NEBOC_TOKEN_GREATER_EQUAL
 jne .invalid_source

.token_ok:
 mov r9d,1
 cmp qword [rdi+NEBOC_OPERATOR_IMPL_RIGHT_TYPE_OFFSET],0
 jne .right_count_ready
 xor r9d,r9d
.right_count_ready:
 xor r10d,r10d
 mov rax,[rdi+NEBOC_OPERATOR_IMPL_EFFECTS_OFFSET]
 test rax,NEBOC_OPERATOR_EFFECT_RHS_LAZY
 jz .control_ready
 mov r10d,NEBOC_OPERATOR_CONTROL_RHS_LAZY
.control_ready:
 xor r11d,r11d
 mov rax,[rdi+NEBOC_OPERATOR_IMPL_FLAGS_OFFSET]
 test rax,NEBOC_OPERATOR_IMPL_FLAG_CHECKED
 jz .failure_ready
 mov r11d,NEBOC_OPERATOR_FAILURE_CHECKED
.failure_ready:
 mov [rdx+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET],r8
 mov rax,[rdi+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET]
 mov [rdx+NEBOC_OPERATOR_LOWER_RESULT_TYPE_OFFSET],rax
 mov qword [rdx+NEBOC_OPERATOR_LOWER_EVALUATION_ORDER_OFFSET],NEBOC_OPERATOR_EVALUATION_LEFT_TO_RIGHT
 mov qword [rdx+NEBOC_OPERATOR_LOWER_LEFT_EVALUATIONS_OFFSET],1
 mov [rdx+NEBOC_OPERATOR_LOWER_RIGHT_EVALUATIONS_OFFSET],r9
 mov [rdx+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],r10
 mov [rdx+NEBOC_OPERATOR_LOWER_FAILURE_POLICY_OFFSET],r11
 mov [rdx+NEBOC_OPERATOR_LOWER_TOKEN_KIND_OFFSET],rsi
 mov rax,[rdi+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET]
 mov [rdx+NEBOC_OPERATOR_LOWER_IMPL_SYMBOL_OFFSET],rax
 xor eax,eax
 ret
.invalid_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_operator_lowering_plan_abi
 mov eax,NEBOC_OPERATOR_LOWER_SIZE
 mov edx,NEBOC_OPERATOR_EVALUATION_LEFT_TO_RIGHT
 mov ecx,NEBOC_OPERATOR_FAILURE_CHECKED
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
