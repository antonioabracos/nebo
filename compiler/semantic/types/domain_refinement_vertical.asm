; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF005 public bounded PositiveInt recognizer
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/domain_refinement_api_contract.inc"
%include "compiler/semantic/types/domain_refinement_semantic.inc"
%include "compiler/lowering/domain/domain_refinement_ir_contract.inc"
%include "compiler/lowering/domain/domain_refinement_native_contract.inc"
%include "compiler/semantic/types/domain_refinement_vertical.inc"
extern neboc_domain_refinement_api_contract
extern neboc_domain_refinement_semantic_analyze
extern neboc_domain_refinement_ir_lower
extern neboc_domain_refinement_native_plan

section .rodata
tipos_semanticos_refinamentos_unidades_e_opaque_types_n_to_positive: db 'toPositiveInt'
tipos_semanticos_refinamentos_unidades_e_opaque_types_n_to_positive_len equ $-tipos_semanticos_refinamentos_unidades_e_opaque_types_n_to_positive
n_positive: db 'PositiveInt'
n_positive_len equ $-n_positive
n_to_natural: db 'toNatural'
n_to_natural_len equ $-n_to_natural
n_as_positive: db 'asPositiveInt'
n_as_positive_len equ $-n_as_positive
n_meters: db 'meters'
n_meters_len equ $-n_meters
n_refine: db 'refine'
n_refine_len equ $-n_refine
domain_refinement_vertical_n_is_ok: db 'isOk'
n_is_ok_len equ $-domain_refinement_vertical_n_is_ok
domain_refinement_vertical_n_is_err: db 'isErr'
n_is_err_len equ $-domain_refinement_vertical_n_is_err
domain_refinement_vertical_n_unwrap: db 'unwrapOr'
n_unwrap_len equ $-domain_refinement_vertical_n_unwrap

section .bss align=16
g08v_api: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_REQUEST_SIZE
g08v_sem: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_REQUEST_SIZE
g08v_ir: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_SIZE
g08v_native: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REQUEST_SIZE

section .text
g08v_token_ptr:
 mov rax,rsi
 cmp rax,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKENS_OFFSET]
 ret
.bad: xor eax,eax
 ret

g08v_token_match:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call g08v_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,r15
 jne .no
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_OFFSET]
 add rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov dl,[rax+rcx]
 cmp dl,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

g08v_kind_is:
 push rdx
 call g08v_token_ptr
 pop rdx
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_KIND_OFFSET],rdx
 sete al
 movzx eax,al
 ret
.no: xor eax,eax
 ret

g08v_error:
 push rbx
 mov rbx,rdi
 mov qword [rbx+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],1
 mov [rbx+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_DIAGNOSTIC_OFFSET],rsi
 mov [rbx+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call g08v_token_ptr
 test rax,rax
 jz .status
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_ERROR_END_OFFSET],rcx
.status:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

g08v_contract_chain:
 push r12
 mov r12,rdi
 lea rdi,[rel g08v_api]
 mov ecx,NEBOC_API_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel g08v_api+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_OPERATION_OFFSET],NEBOC_OP_TO_POSITIVE_INT
 mov qword [rel g08v_api+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_RECEIVER_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 mov qword [rel g08v_api+NEBOC_API_RECEIVER_LITERAL_OFFSET],1
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 mov [rel g08v_api+NEBOC_API_RECEIVER_VALUE_OFFSET],rax
 mov qword [rel g08v_api+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_INPUT_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_INPUT_REQUIRED_FLAGS
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_OFFSET]
 mov [rel g08v_api+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g08v_api+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_API_SUBJECT_LENGTH_OFFSET],rax
 lea rdi,[rel g08v_api]
 call neboc_domain_refinement_api_contract
 test eax,eax
 jnz .bad
 mov rax,[rel g08v_api+NEBOC_API_RESULT_TAG_OFFSET]
 mov [r12+NEBOC_VERTICAL_RESULT_TAG_OFFSET],rax
 mov rax,[rel g08v_api+NEBOC_API_RESULT_PAYLOAD_OFFSET]
 mov [r12+NEBOC_VERTICAL_RESULT_PAYLOAD_OFFSET],rax
 or qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],NEBOC_VERTICAL_FLAG_API
 lea rdi,[rel g08v_sem]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel g08v_sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET],NEBOC_SEM_KIND_CONVERT
 mov qword [rel g08v_sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 mov qword [rel g08v_sem+NEBOC_SEM_RECEIVER_LITERAL_OFFSET],1
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 mov [rel g08v_sem+NEBOC_SEM_RECEIVER_VALUE_OFFSET],rax
 mov qword [rel g08v_sem+NEBOC_SEM_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 mov rax,[r12+NEBOC_VERTICAL_RESULT_TAG_OFFSET]
 mov [rel g08v_sem+NEBOC_SEM_API_TAG_OFFSET],rax
 mov rax,[r12+NEBOC_VERTICAL_RESULT_PAYLOAD_OFFSET]
 mov [rel g08v_sem+NEBOC_SEM_API_PAYLOAD_OFFSET],rax
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_LENGTH_OFFSET]
 mov [rel g08v_sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_END_OFFSET],rax
 lea rdi,[rel g08v_sem]
 call neboc_domain_refinement_semantic_analyze
 test eax,eax
 jnz .bad
 or qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAG_SEMANTIC
 lea rdi,[rel g08v_ir]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel g08v_ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_KIND_OFFSET],NEBOC_IR_KIND_RESULT_CONSTRUCT
 lea rax,[rel g08v_sem]
 mov [rel g08v_ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_PTR_OFFSET],rax
 mov rax,[rel g08v_sem+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_HASH_OFFSET]
 mov [rel g08v_ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_HASH_OFFSET],rax
 mov qword [rel g08v_ir+NEBOC_IR_INPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 mov qword [rel g08v_ir+NEBOC_IR_OUTPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 mov rax,[r12+NEBOC_VERTICAL_RESULT_TAG_OFFSET]
 mov [rel g08v_ir+NEBOC_IR_TAG_OFFSET],rax
 mov rax,[r12+NEBOC_VERTICAL_RESULT_PAYLOAD_OFFSET]
 mov [rel g08v_ir+NEBOC_IR_PAYLOAD_OFFSET],rax
 mov qword [rel g08v_ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_X86_64_SYSV
 lea rdi,[rel g08v_ir]
 call neboc_domain_refinement_ir_lower
 test eax,eax
 jnz .bad
 or qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAG_IR
 lea rdi,[rel g08v_native]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel g08v_ir]
 mov [rel g08v_native+NEBOC_NATIVE_IR_PTR_OFFSET],rax
 mov rax,[rel g08v_ir+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_HASH_OFFSET]
 mov [rel g08v_native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_IR_HASH_OFFSET],rax
 mov qword [rel g08v_native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_TARGET_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_X86_64_SYSV
 mov qword [rel g08v_native+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_NATIVE_OPERATION_OFFSET],NEBOC_NATIVE_OP_TRY
 mov qword [rel g08v_native+NEBOC_NATIVE_INPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 mov qword [rel g08v_native+NEBOC_NATIVE_OUTPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 lea rdi,[rel g08v_native]
 call neboc_domain_refinement_native_plan
 test eax,eax
 jnz .bad
 or qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAG_NATIVE
 xor eax,eax
 jmp .done
.bad:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CONTRACT_INVARIANT
 mov rdx,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_ERROR_TOKEN_OFFSET]
 call g08v_error
.done:
 pop r12
 ret

NEBOC_ABI_FUNCTION neboc_domain_refinement_vertical_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET]
 mov ecx,13
 xor eax,eax
 rep stosq
 xor r13d,r13d
 mov qword [rsp],-1
.scan:
 cmp r13,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .scan_done
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_n_to_positive]
 mov ecx,tipos_semanticos_refinamentos_unidades_e_opaque_types_n_to_positive_len
 call g08v_token_match
 test eax,eax
 jnz .canonical
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_to_natural]
 mov ecx,n_to_natural_len
 call g08v_token_match
 test eax,eax
 jnz .alias
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_as_positive]
 mov ecx,n_as_positive_len
 call g08v_token_match
 test eax,eax
 jnz .alias
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_positive]
 mov ecx,n_positive_len
 call g08v_token_match
 test eax,eax
 jnz .constructor
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_meters]
 mov ecx,n_meters_len
 call g08v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_refine]
 mov ecx,n_refine_len
 call g08v_token_match
 test eax,eax
 jnz .dynamic
.scan_next:
 inc r13
 jmp .scan
.canonical:
 cmp qword [rsp],-1
 jne .api_unknown
 mov [rsp],r13
 jmp .scan_next
.scan_done:
 cmp qword [rsp],-1
 je .not_owned
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],1
 mov r14,[rsp]
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_ERROR_TOKEN_OFFSET],r14
 cmp r14,6
 jne .literal_required
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET],16
 jb .api_unknown
 mov rdi,r12
 xor esi,esi
 mov edx,NEBOC_TOKEN_KW_START
 call g08v_kind_is
 test eax,eax
 jz .api_unknown
 mov rdi,r12
 mov esi,4
 mov edx,NEBOC_TOKEN_INTEGER
 call g08v_kind_is
 test eax,eax
 jz .receiver_kind
 mov rdi,r12
 mov esi,4
 call g08v_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET],rax
 mov rdi,r12
 mov esi,7
 mov edx,NEBOC_TOKEN_LPAREN
 call g08v_kind_is
 test eax,eax
 jz .api_unknown
 mov rdi,r12
 mov esi,8
 mov edx,NEBOC_TOKEN_RPAREN
 call g08v_kind_is
 test eax,eax
 jz .arguments
 mov rdi,r12
 mov esi,9
 mov edx,NEBOC_TOKEN_DOT
 call g08v_kind_is
 test eax,eax
 jz .api_unknown
 mov rdi,r12
 mov esi,10
 lea rdx,[rel domain_refinement_vertical_n_unwrap]
 mov ecx,n_unwrap_len
 call g08v_token_match
 test eax,eax
 jnz .unwrap
 mov rdi,r12
 mov esi,10
 lea rdx,[rel domain_refinement_vertical_n_is_ok]
 mov ecx,n_is_ok_len
 call g08v_token_match
 test eax,eax
 jnz .is_ok
 mov rdi,r12
 mov esi,10
 lea rdx,[rel domain_refinement_vertical_n_is_err]
 mov ecx,n_is_err_len
 call g08v_token_match
 test eax,eax
 jnz .is_err
 jmp .api_unknown
.unwrap:
 mov qword [r12+NEBOC_VERTICAL_OPERATION_OFFSET],NEBOC_NATIVE_OP_UNWRAP_OR
 mov rdi,r12
 mov esi,12
 mov edx,NEBOC_TOKEN_RPAREN
 call g08v_kind_is
 test eax,eax
 jnz .fallback_required
 mov rdi,r12
 mov esi,12
 mov edx,NEBOC_TOKEN_INTEGER
 call g08v_kind_is
 test eax,eax
 jz .fallback_positive
 mov rdi,r12
 mov esi,12
 call g08v_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test rax,rax
 jle .fallback_positive
 mov [r12+NEBOC_VERTICAL_FALLBACK_VALUE_OFFSET],rax
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET],17
 jne .observer_domain
 mov rdi,r12
 mov esi,13
 mov edx,NEBOC_TOKEN_RPAREN
 call g08v_kind_is
 test eax,eax
 jz .fallback_positive
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 test rax,rax
 jg .unwrap_value
 mov rax,[r12+NEBOC_VERTICAL_FALLBACK_VALUE_OFFSET]
.unwrap_value:
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_OUTPUT_VALUE_OFFSET],rax
 mov r14d,14
 jmp .validate_tail
.is_ok:
 mov qword [r12+NEBOC_VERTICAL_OPERATION_OFFSET],NEBOC_NATIVE_OP_IS_OK
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET],16
 jne .observer_domain
 mov rdi,r12
 mov esi,12
 mov edx,NEBOC_TOKEN_RPAREN
 call g08v_kind_is
 test eax,eax
 jz .arguments
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 test rax,rax
 setg al
 movzx eax,al
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_OUTPUT_VALUE_OFFSET],rax
 mov r14d,13
 jmp .validate_tail
.is_err:
 mov qword [r12+NEBOC_VERTICAL_OPERATION_OFFSET],NEBOC_NATIVE_OP_IS_ERR
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET],16
 jne .observer_domain
 mov rdi,r12
 mov esi,12
 mov edx,NEBOC_TOKEN_RPAREN
 call g08v_kind_is
 test eax,eax
 jz .arguments
 mov rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 test rax,rax
 setle al
 movzx eax,al
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_OUTPUT_VALUE_OFFSET],rax
 mov r14d,13
.validate_tail:
 mov rdi,r12
 mov rsi,r14
 mov edx,NEBOC_TOKEN_SEMICOLON
 call g08v_kind_is
 test eax,eax
 jz .observer_domain
 mov rdi,r12
 lea rsi,[r14+1]
 mov edx,NEBOC_TOKEN_RBRACE
 call g08v_kind_is
 test eax,eax
 jz .observer_domain
 mov rdi,r12
 lea rsi,[r14+2]
 mov edx,NEBOC_TOKEN_EOF
 call g08v_kind_is
 test eax,eax
 jz .observer_domain
 mov rdi,r12
 call g08v_contract_chain
 test eax,eax
 jnz .done
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FLAGS_REQUIRED
 jne .contract
 mov rax,1469598103934665603
 mov rbx,1099511628211
 xor rax,[r12+NEBOC_VERTICAL_RECEIVER_VALUE_OFFSET]
 imul rax,rbx
 xor rax,[r12+NEBOC_VERTICAL_OPERATION_OFFSET]
 imul rax,rbx
 xor rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_OUTPUT_VALUE_OFFSET]
 mov [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.receiver_kind:
 mov rdi,r12
 mov esi,4
 mov edx,NEBOC_TOKEN_IDENTIFIER
 call g08v_kind_is
 test eax,eax
 jnz .literal_required
 mov esi,NEBOC_DIAG_RECEIVER_MUST_BE_INT
 mov edx,4
 jmp .emit_error
.literal_required: mov esi,NEBOC_DIAG_LITERAL_RECEIVER_REQUIRED
 mov rdx,r14
 jmp .emit_error
.api_unknown: mov esi,NEBOC_DIAG_API_UNKNOWN
 mov rdx,r13
 jmp .emit_error
.alias: mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_ALIAS_FORBIDDEN
 mov rdx,r13
 jmp .emit_error
.constructor: mov esi,NEBOC_DIAG_CONSTRUCTOR_FORBIDDEN
 mov rdx,r13
 jmp .emit_error
.deferred: mov esi,NEBOC_DIAG_DOMAIN_FAMILY_DEFERRED
 mov rdx,r13
 jmp .emit_error
.dynamic: mov esi,NEBOC_DIAG_DYNAMIC_REFINEMENT_DEFERRED
 mov rdx,r13
 jmp .emit_error
.arguments: mov esi,NEBOC_DIAG_ARGUMENTS_NOT_ALLOWED
 mov edx,6
 jmp .emit_error
.fallback_required: mov esi,NEBOC_DIAG_FALLBACK_REQUIRED
 mov edx,10
 jmp .emit_error
.fallback_positive: mov esi,NEBOC_DIAG_FALLBACK_MUST_BE_POSITIVE_LITERAL
 mov edx,12
 jmp .emit_error
.observer_domain: mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_DIAG_OBSERVER_WRONG_DOMAIN
 mov edx,10
 jmp .emit_error
.contract: mov esi,NEBOC_DIAG_CONTRACT_INVARIANT
 mov edx,6
.emit_error:
 mov rdi,r12
 call g08v_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
