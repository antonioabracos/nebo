; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF003 PositiveInt semantic proof contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/domain_refinement_semantic.inc"

section .text
tipos_semanticos_refinamentos_unidades_e_opaque_types_sem_hash:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 %assign off 0
 %rep 15
 xor rax,[rdi+off]
 imul rax,rcx
 %assign off off+8
 %endrep
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_HASH_OFFSET],rax
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
tipos_semanticos_refinamentos_unidades_e_opaque_types_sem_error:
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAGNOSTIC_OFFSET],rsi
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_sem_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_domain_refinement_semantic_analyze
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RESULT_TYPE_OFFSET]
 mov ecx,6
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_END_OFFSET]
 cmp rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_SOURCE_START_OFFSET]
 jb .span
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_KIND_OFFSET]
 cmp rax,NEBOC_SEM_KIND_CONVERT
 je .convert
 cmp rax,NEBOC_SEM_KIND_IS_OK
 je .predicate
 cmp rax,NEBOC_SEM_KIND_IS_ERR
 je .predicate
 cmp rax,NEBOC_SEM_KIND_UNWRAP_OR
 je .unwrap
 mov esi,NEBOC_SEM_DIAG_API_CONTRACT_MISMATCH
 jmp .diag

.convert:
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 jne .receiver
 cmp qword [r12+NEBOC_SEM_RECEIVER_LITERAL_OFFSET],1
 jne .literal
 cmp qword [r12+NEBOC_SEM_API_RESULT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .api
 mov rax,[r12+NEBOC_SEM_RECEIVER_VALUE_OFFSET]
 test rax,rax
 jle .convert_err
 cmp qword [r12+NEBOC_SEM_API_TAG_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_RESULT_OK
 jne .api
 cmp rax,[r12+NEBOC_SEM_API_PAYLOAD_OFFSET]
 jne .api
 mov [r12+NEBOC_SEM_REFINED_VALUE_OFFSET],rax
 jmp .convert_common
.convert_err:
 cmp qword [r12+NEBOC_SEM_API_TAG_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_RESULT_ERR
 jne .api
 cmp qword [r12+NEBOC_SEM_API_PAYLOAD_OFFSET],NEBOC_ERROR_NON_POSITIVE
 jne .api
 mov qword [r12+NEBOC_SEM_ERROR_PAYLOAD_OFFSET],NEBOC_ERROR_NON_POSITIVE
.convert_common:
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RESULT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_REQUIRED
 jmp .ok

.predicate:
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .observer
 cmp qword [r12+NEBOC_SEM_API_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 jne .api
 cmp qword [r12+NEBOC_SEM_API_PAYLOAD_OFFSET],1
 ja .api
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 mov rax,[r12+NEBOC_SEM_API_PAYLOAD_OFFSET]
 mov [r12+NEBOC_SEM_REFINED_VALUE_OFFSET],rax
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_REQUIRED
 jmp .ok

.unwrap:
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RECEIVER_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .observer
 cmp qword [r12+NEBOC_SEM_API_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_POSITIVE_INT
 jne .api
 mov rax,[r12+NEBOC_SEM_API_PAYLOAD_OFFSET]
 test rax,rax
 jle .refined
 mov [r12+NEBOC_SEM_REFINED_VALUE_OFFSET],rax
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_RESULT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_POSITIVE_INT
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_FLAGS_REQUIRED
 jmp .ok

.receiver: mov esi,NEBOC_SEM_DIAG_RECEIVER_TYPE
 jmp .diag
.literal: mov esi,NEBOC_SEM_DIAG_LITERAL_REQUIRED
 jmp .diag
.api: mov esi,NEBOC_SEM_DIAG_API_CONTRACT_MISMATCH
 jmp .diag
.span: mov esi,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAG_SPAN_INVARIANT
 jmp .diag
.observer: mov esi,NEBOC_SEM_DIAG_OBSERVER_INVARIANT
 jmp .diag
.refined: mov esi,NEBOC_SEM_DIAG_REFINED_VALUE_INVALID
.diag:
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_sem_error
 jmp .done
.ok:
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_sem_hash
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
