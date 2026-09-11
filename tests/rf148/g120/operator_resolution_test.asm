; G120 native operator-protocol, resolution, coherence and lowering conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/operators/operator_protocol.inc"

extern neboc_operator_known_implementations
extern neboc_operator_known_impl_by_symbol
extern neboc_operator_coherence_validate
extern neboc_operator_resolve_exact
extern neboc_operator_conversion_policy
extern neboc_operator_rank_candidates
extern neboc_operator_lowering_plan
extern neboc_operator_protocol_schema
extern neboc_operator_unary_type
extern neboc_operator_binary_type

%define SENTINEL 0x5a5a5a5a5a5a5a5a
%define TEST_FLAGS NEBOC_OPERATOR_IMPL_FLAG_ACTIVE|NEBOC_OPERATOR_IMPL_FLAG_BUILTIN|NEBOC_OPERATOR_IMPL_FLAG_COHERENT|NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
%define TEST_USER_FLAGS NEBOC_OPERATOR_IMPL_FLAG_ACTIVE|NEBOC_OPERATOR_IMPL_FLAG_USER|NEBOC_OPERATOR_IMPL_FLAG_COHERENT|NEBOC_OPERATOR_IMPL_FLAG_EXACT_TYPES
%define TEST_USER_TYPE 0x1001
%define TEST_OTHER_TYPE 0x1002
%define TEST_RESULT_PARAMETER (NEBOC_OPERATOR_TYPE_PARAMETER_FLAG|1)

%macro IMPL 2
 dq NEBOC_OPERATOR_PROTOCOL_ADD,NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT
 dq NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT,0
 dq NEBOC_OPERATOR_CAPABILITY_CORE,NEBOC_OPERATOR_EFFECT_EAGER,%1
 dq TEST_FLAGS,%2
%endmacro

section .rodata align=8
ranked_impls:
 IMPL 100,42
 IMPL 50,43
ranked_impls_reversed:
 IMPL 50,43
 IMPL 100,42
tied_impls:
 IMPL 100,51
 IMPL 100,52
duplicate_impls:
 IMPL 100,61
 IMPL 100,62
user_impl:
 dq NEBOC_OPERATOR_PROTOCOL_ADD,TEST_USER_TYPE,TEST_USER_TYPE
 dq TEST_USER_TYPE,TEST_USER_TYPE,1
 dq NEBOC_OPERATOR_CAPABILITY_CORE,NEBOC_OPERATOR_EFFECT_EAGER,75
 dq TEST_USER_FLAGS,71
orphan_impl:
 dq NEBOC_OPERATOR_PROTOCOL_ADD,TEST_USER_TYPE,TEST_USER_TYPE
 dq TEST_USER_TYPE,TEST_OTHER_TYPE,1
 dq NEBOC_OPERATOR_CAPABILITY_CORE,NEBOC_OPERATOR_EFFECT_EAGER,75
 dq TEST_USER_FLAGS,72
generic_impl:
 dq NEBOC_OPERATOR_PROTOCOL_ADD,TEST_USER_TYPE,TEST_USER_TYPE
 dq TEST_RESULT_PARAMETER,TEST_USER_TYPE,1
 dq NEBOC_OPERATOR_CAPABILITY_CORE,NEBOC_OPERATOR_EFFECT_EAGER,80
 dq TEST_USER_FLAGS,73
substitutions:
 dq 1,TEST_USER_TYPE
conflicting_substitutions:
 dq 1,TEST_USER_TYPE
 dq 1,TEST_OTHER_TYPE

section .bss align=16
request: resb NEBOC_OPERATOR_RESOLVE_SIZE
resolved: resb NEBOC_OPERATOR_IMPL_SIZE
lower_plan: resb NEBOC_OPERATOR_LOWER_SIZE
scalar_out: resq 1
rank_index: resq 1

section .text
global _start

; prepare_known_request(protocol, left_type, right_type)
prepare_known_request:
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 call neboc_operator_known_implementations
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],rdx
 mov [rel request+NEBOC_OPERATOR_RESOLVE_PROTOCOL_OFFSET],r12
 mov [rel request+NEBOC_OPERATOR_RESOLVE_LEFT_TYPE_OFFSET],r13
 mov [rel request+NEBOC_OPERATOR_RESOLVE_RIGHT_TYPE_OFFSET],r14
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_AVAILABLE_CAPABILITIES_OFFSET],NEBOC_OPERATOR_CAPABILITY_CORE
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_ALLOWED_EFFECTS_OFFSET],NEBOC_OPERATOR_EFFECT_ALL
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTIONS_OFFSET],0
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTION_COUNT_OFFSET],0
 lea rax,[rel resolved]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_OUTPUT_OFFSET],rax
 mov rax,SENTINEL
 mov [rel request+NEBOC_OPERATOR_RESOLVE_OUTPUT_INDEX_OFFSET],rax
 mov [rel request+NEBOC_OPERATOR_RESOLVE_MATCH_COUNT_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],0
 mov [rel resolved+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET],rax
 pop r14
 pop r13
 pop r12
 ret

_start:
 ; OperatorKind and OperatorProtocol share one explicit versioned schema.
 mov ebx,1
 call neboc_operator_protocol_schema
 cmp eax,NEBOC_OPERATOR_PROTOCOL_SCHEMA_VERSION
 jne fail
 cmp edx,NEBOC_OPERATOR_PROTOCOL_COUNT
 jne fail
 cmp ecx,NEBOC_OPERATOR_KIND_COUNT
 jne fail
 cmp r8d,NEBOC_OPERATOR_IMPL_SIZE
 jne fail
 cmp r9d,NEBOC_OPERATOR_RESOLVE_SIZE
 jne fail
 cmp r10d,NEBOC_OPERATOR_LOWER_SIZE
 jne fail

 ; The factual implementation table is bounded and coherent.
 mov ebx,2
 call neboc_operator_known_implementations
 cmp edx,17
 jne fail
 cmp ecx,NEBOC_OPERATOR_IMPL_SIZE
 jne fail
 mov rdi,rax
 mov esi,17
 call neboc_operator_coherence_validate
 test eax,eax
 jnz fail

 ; Canonical unary and binary typing now resolve through that table.
 mov ebx,3
 mov edi,NEBOC_TOKEN_MINUS
 mov esi,NEBOC_TYPE_ID_INT
 lea rdx,[rel scalar_out]
 call neboc_operator_unary_type
 test eax,eax
 jnz fail
 cmp qword [rel scalar_out],NEBOC_TYPE_ID_INT
 jne fail
 mov edi,NEBOC_TOKEN_BANG
 mov esi,NEBOC_TYPE_ID_BOOL
 lea rdx,[rel scalar_out]
 call neboc_operator_unary_type
 test eax,eax
 jnz fail
 cmp qword [rel scalar_out],NEBOC_TYPE_ID_BOOL
 jne fail
 mov edi,NEBOC_TOKEN_MINUS
 mov esi,NEBOC_TYPE_ID_BOOL
 lea rdx,[rel scalar_out]
 call neboc_operator_unary_type
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel scalar_out],0
 jne fail

 mov ebx,4
 mov edi,NEBOC_TOKEN_PLUS
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 lea rcx,[rel scalar_out]
 call neboc_operator_binary_type
 test eax,eax
 jnz fail
 cmp qword [rel scalar_out],NEBOC_TYPE_ID_INT
 jne fail
 mov edi,NEBOC_TOKEN_EQUAL_EQUAL
 mov esi,NEBOC_TYPE_ID_TEXT
 mov edx,NEBOC_TYPE_ID_TEXT
 lea rcx,[rel scalar_out]
 call neboc_operator_binary_type
 test eax,eax
 jnz fail
 cmp qword [rel scalar_out],NEBOC_TYPE_ID_BOOL
 jne fail
 mov edi,NEBOC_TOKEN_PLUS
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_BOOL
 lea rcx,[rel scalar_out]
 call neboc_operator_binary_type
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel scalar_out],0
 jne fail

 ; Exact success produces the unique implementation and result TypeId.
 mov ebx,5
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 test eax,eax
 jnz fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],1
 jne fail

 ; No candidate, missing capability and forbidden effect are typed failures;
 ; none may mutate the candidate output or success metadata.
 mov ebx,6
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_BOOL
 call prepare_known_request
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_NO_EXACT_CANDIDATE
 jne fail
 call assert_atomic_resolution_failure

 mov ebx,7
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_AVAILABLE_CAPABILITIES_OFFSET],0
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_CAPABILITY_MISSING
 jne fail
 call assert_atomic_resolution_failure

 mov ebx,8
 mov edi,NEBOC_OPERATOR_PROTOCOL_LOGICAL_AND
 mov esi,NEBOC_TYPE_ID_BOOL
 mov edx,NEBOC_TYPE_ID_BOOL
 call prepare_known_request
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_ALLOWED_EFFECTS_OFFSET],NEBOC_OPERATOR_EFFECT_EAGER
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_EFFECT_FORBIDDEN
 jne fail
 call assert_atomic_resolution_failure

 ; Operator lookup admits identity only and preserves output on rejection.
 mov ebx,9
 mov rax,SENTINEL
 mov [rel scalar_out],rax
 mov edi,NEBOC_TYPE_ID_INT
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_OPERATOR_CONVERSION_MODE_IMPLICIT
 lea rcx,[rel scalar_out]
 call neboc_operator_conversion_policy
 test eax,eax
 jnz fail
 cmp qword [rel scalar_out],NEBOC_OPERATOR_CONVERSION_IDENTITY
 jne fail
 mov rax,SENTINEL
 mov [rel scalar_out],rax
 mov edi,NEBOC_TYPE_ID_INT
 mov esi,NEBOC_TYPE_ID_BOOL
 mov edx,NEBOC_OPERATOR_CONVERSION_MODE_IMPLICIT
 lea rcx,[rel scalar_out]
 call neboc_operator_conversion_policy
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp edx,NEBOC_OPERATOR_DIAG_IMPLICIT_CONVERSION_FORBIDDEN
 jne fail
 mov rax,SENTINEL
 cmp [rel scalar_out],rax
 jne fail

 ; Ranking is based on specificity, not declaration order; equal best ranks
 ; are ambiguity and leave the selected-index output untouched.
 mov ebx,10
 lea rdi,[rel ranked_impls]
 mov esi,2
 lea rdx,[rel rank_index]
 call neboc_operator_rank_candidates
 test eax,eax
 jnz fail
 cmp qword [rel rank_index],0
 jne fail
 lea rdi,[rel ranked_impls_reversed]
 mov esi,2
 lea rdx,[rel rank_index]
 call neboc_operator_rank_candidates
 test eax,eax
 jnz fail
 cmp qword [rel rank_index],1
 jne fail
 mov rax,SENTINEL
 mov [rel rank_index],rax
 lea rdi,[rel tied_impls]
 mov esi,2
 lea rdx,[rel rank_index]
 call neboc_operator_rank_candidates
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp edx,NEBOC_OPERATOR_DIAG_AMBIGUOUS_CANDIDATE
 jne fail
 mov rax,SENTINEL
 cmp [rel rank_index],rax
 jne fail

 ; The resolver itself applies the same order-independent ranking and leaves
 ; equal best candidates ambiguous rather than choosing declaration order.
 mov ebx,11
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 lea rax,[rel ranked_impls]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],2
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 test eax,eax
 jnz fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],42
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_OUTPUT_INDEX_OFFSET],0
 jne fail
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 lea rax,[rel ranked_impls_reversed]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],2
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 test eax,eax
 jnz fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],42
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_OUTPUT_INDEX_OFFSET],1
 jne fail
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 lea rax,[rel tied_impls]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],2
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_AMBIGUOUS_CANDIDATE
 jne fail
 call assert_atomic_resolution_failure

 ; Duplicate protocol/type tuples violate coherence and exact resolution is
 ; ambiguity, with the first colliding index and failure atomicity preserved.
 mov ebx,12
 lea rdi,[rel duplicate_impls]
 mov esi,2
 call neboc_operator_coherence_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp edx,NEBOC_OPERATOR_DIAG_COHERENCE_VIOLATION
 jne fail
 cmp r8,1
 jne fail
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,NEBOC_TYPE_ID_INT
 mov edx,NEBOC_TYPE_ID_INT
 call prepare_known_request
 lea rax,[rel duplicate_impls]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],2
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_AMBIGUOUS_CANDIDATE
 jne fail
 call assert_atomic_resolution_failure

 ; A user type may implement a known protocol when an operand owns it. An
 ; orphan owner is rejected before resolution and cannot create semantics.
 mov ebx,13
 lea rdi,[rel user_impl]
 mov esi,1
 call neboc_operator_coherence_validate
 test eax,eax
 jnz fail
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,TEST_USER_TYPE
 mov edx,TEST_USER_TYPE
 call prepare_known_request
 lea rax,[rel user_impl]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 test eax,eax
 jnz fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],TEST_USER_TYPE
 jne fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_SYMBOL_ID_OFFSET],71
 jne fail
 lea rdi,[rel orphan_impl]
 mov esi,1
 call neboc_operator_coherence_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp edx,NEBOC_OPERATOR_DIAG_COHERENCE_VIOLATION
 jne fail
 test r8,r8
 jnz fail

 ; A generic result is substituted exactly once before winner publication.
 ; Missing or conflicting substitutions preserve every output sentinel.
 mov ebx,14
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,TEST_USER_TYPE
 mov edx,TEST_USER_TYPE
 call prepare_known_request
 lea rax,[rel generic_impl]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],1
 lea rax,[rel substitutions]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTIONS_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTION_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 test eax,eax
 jnz fail
 cmp qword [rel resolved+NEBOC_OPERATOR_IMPL_RESULT_TYPE_OFFSET],TEST_USER_TYPE
 jne fail
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,TEST_USER_TYPE
 mov edx,TEST_USER_TYPE
 call prepare_known_request
 lea rax,[rel generic_impl]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],1
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_SUBSTITUTION_MISSING
 jne fail
 call assert_atomic_resolution_failure
 mov edi,NEBOC_OPERATOR_PROTOCOL_ADD
 mov esi,TEST_USER_TYPE
 mov edx,TEST_USER_TYPE
 call prepare_known_request
 lea rax,[rel generic_impl]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATES_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_CANDIDATE_COUNT_OFFSET],1
 lea rax,[rel conflicting_substitutions]
 mov [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTIONS_OFFSET],rax
 mov qword [rel request+NEBOC_OPERATOR_RESOLVE_SUBSTITUTION_COUNT_OFFSET],2
 lea rdi,[rel request]
 call neboc_operator_resolve_exact
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_OPERATOR_RESOLVE_DIAGNOSTIC_OFFSET],NEBOC_OPERATOR_DIAG_SUBSTITUTION_CONFLICT
 jne fail
 call assert_atomic_resolution_failure

 ; Lowering records left-to-right, exactly-once and checked/lazy contracts.
 mov ebx,15
 mov edi,1
 call neboc_operator_known_impl_by_symbol
 mov rdi,rax
 mov esi,NEBOC_TOKEN_PLUS
 lea rdx,[rel lower_plan]
 call neboc_operator_lowering_plan
 test eax,eax
 jnz fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET],NEBOC_OPERATOR_PROTOCOL_ADD
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_RESULT_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_EVALUATION_ORDER_OFFSET],NEBOC_OPERATOR_EVALUATION_LEFT_TO_RIGHT
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_LEFT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_RIGHT_EVALUATIONS_OFFSET],1
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],NEBOC_OPERATOR_CONTROL_NONE
 jne fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_FAILURE_POLICY_OFFSET],NEBOC_OPERATOR_FAILURE_CHECKED
 jne fail
 mov edi,8
 call neboc_operator_known_impl_by_symbol
 mov rdi,rax
 mov esi,NEBOC_TOKEN_AND_AND
 lea rdx,[rel lower_plan]
 call neboc_operator_lowering_plan
 test eax,eax
 jnz fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_CONTROL_FLAGS_OFFSET],NEBOC_OPERATOR_CONTROL_RHS_LAZY
 jne fail
 mov edi,14
 call neboc_operator_known_impl_by_symbol
 mov rdi,rax
 mov esi,NEBOC_TOKEN_CARET
 lea rdx,[rel lower_plan]
 call neboc_operator_lowering_plan
 test eax,eax
 jnz fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET],NEBOC_OPERATOR_KIND_POWER
 jne fail
 mov edi,15
 call neboc_operator_known_impl_by_symbol
 mov rdi,rax
 mov esi,NEBOC_TOKEN_XOR
 lea rdx,[rel lower_plan]
 call neboc_operator_lowering_plan
 test eax,eax
 jnz fail
 cmp qword [rel lower_plan+NEBOC_OPERATOR_LOWER_OPERATION_OFFSET],NEBOC_OPERATOR_KIND_XOR
 jne fail
 mov edi,1
 call neboc_operator_known_impl_by_symbol
 mov rdi,rax
 mov rax,SENTINEL
 mov [rel lower_plan],rax
 mov esi,NEBOC_TOKEN_STAR
 lea rdx,[rel lower_plan]
 call neboc_operator_lowering_plan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel lower_plan],rax
 jne fail

 xor edi,edi
 jmp exit

assert_atomic_resolution_failure:
 mov rax,SENTINEL
 cmp [rel resolved+NEBOC_OPERATOR_IMPL_PROTOCOL_OFFSET],rax
 jne fail
 cmp [rel request+NEBOC_OPERATOR_RESOLVE_OUTPUT_INDEX_OFFSET],rax
 jne fail
 cmp [rel request+NEBOC_OPERATOR_RESOLVE_MATCH_COUNT_OFFSET],rax
 jne fail
 ret

fail:
 mov edi,ebx
exit:
 mov eax,60
 syscall
