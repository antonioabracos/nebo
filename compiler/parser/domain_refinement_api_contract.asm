; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF002 isolated domain refinement API contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/domain_refinement_api_contract.inc"

section .text
tipos_semanticos_refinamentos_unidades_e_opaque_types_api_hash:
 mov r8,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_PTR_OFFSET]
 mov r9,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET]
 mov rax,1469598103934665603
 mov r10,1099511628211
 xor ecx,ecx
.bytes:
 cmp rcx,r9
 jae .fields
 movzx edx,byte [r8+rcx]
 xor rax,rdx
 imul rax,r10
 inc rcx
 jmp .bytes
.fields:
 %assign off 0
 %rep 17
 xor rax,[rdi+off]
 imul rax,r10
 %assign off off+8
 %endrep
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_HASH_OFFSET],rax
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
tipos_semanticos_refinamentos_unidades_e_opaque_types_api_error:
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_DIAGNOSTIC_OFFSET],rsi
 mov rax,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ABSOLUTE_START_OFFSET]
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ERROR_START_OFFSET],rax
 add rax,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET]
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ERROR_END_OFFSET],rax
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
tipos_semanticos_refinamentos_unidades_e_opaque_types_api_success:
 mov qword [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_DIAGNOSTIC_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_NONE
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_hash
 xor eax,eax
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_domain_refinement_api_contract
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_PTR_OFFSET],0
 je .invalid
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET],0
 je .invalid
 lea rdi,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET]
 mov ecx,7
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_OPERATION_OFFSET]
 cmp rax,NEBOC_OP_TO_POSITIVE_INT
 je .convert
 cmp rax,NEBOC_OP_IS_OK
 je .is_ok
 cmp rax,NEBOC_OP_IS_ERR
 je .is_err
 cmp rax,NEBOC_OP_UNWRAP_OR
 je .unwrap
 cmp rax,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_OP_ALIAS
 je .alias
 cmp rax,NEBOC_OP_CONSTRUCTOR
 je .constructor
 cmp rax,NEBOC_OP_DEFERRED_FAMILY
 je .deferred
 cmp rax,NEBOC_OP_DYNAMIC_REFINEMENT
 je .dynamic
 mov esi,NEBOC_DIAG_API_UNKNOWN
 jmp .diag

.convert:
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_INPUT_FLAGS_OFFSET]
 and rax,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_INPUT_REQUIRED_FLAGS
 cmp rax,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_INPUT_REQUIRED_FLAGS
 jne .alias
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RECEIVER_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 jne .need_int
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 cmp qword [r12+NEBOC_API_RECEIVER_LITERAL_OFFSET],1
 jne .literal
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 mov rax,[r12+NEBOC_API_RECEIVER_VALUE_OFFSET]
 test rax,rax
 jle .conversion_err
 mov qword [r12+NEBOC_API_RESULT_TAG_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_RESULT_OK
 mov [r12+NEBOC_API_RESULT_PAYLOAD_OFFSET],rax
 jmp .ok
.conversion_err:
 mov qword [r12+NEBOC_API_RESULT_TAG_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_RESULT_ERR
 mov qword [r12+NEBOC_API_RESULT_PAYLOAD_OFFSET],NEBOC_ERROR_NON_POSITIVE
 jmp .ok

.is_ok:
 call api_observer_precheck
 test eax,eax
 jnz .done
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 mov qword [r12+NEBOC_API_RESULT_PAYLOAD_OFFSET],1
 jmp .ok
.is_err:
 call api_observer_precheck
 test eax,eax
 jnz .done
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 mov qword [r12+NEBOC_API_RESULT_PAYLOAD_OFFSET],1
 jmp .ok
.unwrap:
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .observer_domain
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ARGUMENT_COUNT_OFFSET],1
 jne .fallback_required
 cmp qword [r12+NEBOC_API_FALLBACK_LITERAL_OFFSET],1
 jne .fallback_positive
 cmp qword [r12+NEBOC_API_FALLBACK_VALUE_OFFSET],0
 jle .fallback_positive
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_POSITIVE_INT
 mov rax,[r12+NEBOC_API_FALLBACK_VALUE_OFFSET]
 mov [r12+NEBOC_API_RESULT_PAYLOAD_OFFSET],rax
 jmp .ok

.alias: mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_ALIAS_FORBIDDEN
 jmp .diag
.constructor: mov esi,NEBOC_DIAG_CONSTRUCTOR_FORBIDDEN
 jmp .diag
.deferred: mov esi,NEBOC_DIAG_DOMAIN_FAMILY_DEFERRED
 jmp .diag
.dynamic: mov esi,NEBOC_DIAG_DYNAMIC_REFINEMENT_DEFERRED
 jmp .diag
.need_int: mov esi,NEBOC_DIAG_RECEIVER_MUST_BE_INT
 jmp .diag
.arguments: mov esi,NEBOC_DIAG_ARGUMENTS_NOT_ALLOWED
 jmp .diag
.literal: mov esi,NEBOC_DIAG_LITERAL_RECEIVER_REQUIRED
 jmp .diag
.fallback_required: mov esi,NEBOC_DIAG_FALLBACK_REQUIRED
 jmp .diag
.fallback_positive: mov esi,NEBOC_DIAG_FALLBACK_MUST_BE_POSITIVE_LITERAL
 jmp .diag
.observer_domain: mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_OBSERVER_WRONG_DOMAIN
.diag:
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_error
 jmp .done
.ok:
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_success
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
api_observer_precheck:
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .domain
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_ARGUMENT_COUNT_OFFSET],0
 jne .arguments
 xor eax,eax
 ret
.domain:
 mov rdi,r12
 mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_OBSERVER_WRONG_DOMAIN
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_error
 ret
.arguments:
 mov rdi,r12
 mov esi,NEBOC_DIAG_ARGUMENTS_NOT_ALLOWED
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_api_error
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
