; Nebo Assembly — TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-PF003 explicit PositiveInt/result IR invariants
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/lowering/domain/domain_refinement_ir_contract.inc"

section .text
tipos_semanticos_refinamentos_unidades_e_opaque_types_ir_hash:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 %assign off 0
 %rep 15
 xor rax,[rdi+off]
 imul rax,rcx
 %assign off off+8
 %endrep
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_HASH_OFFSET],rax
 ret
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
tipos_semanticos_refinamentos_unidades_e_opaque_types_ir_error:
 mov [rdi+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_DIAGNOSTIC_OFFSET],rsi
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_ir_hash
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_domain_refinement_ir_lower
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 lea rdi,[r12+NEBOC_IR_SLOT_SIZE_OFFSET]
 mov ecx,8
 xor eax,eax
 rep stosq
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_PTR_OFFSET]
 test rax,rax
 jz .semantic
 cmp qword [rax+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAGNOSTIC_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_DIAG_NONE
 jne .semantic
 mov rcx,[rax+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_SEM_HASH_OFFSET]
 cmp rcx,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_SEMANTIC_HASH_OFFSET]
 jne .hash
 cmp qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_TARGET_X86_64_SYSV
 jne .target
 mov rax,[r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_KIND_OFFSET]
 cmp rax,NEBOC_IR_KIND_RESULT_CONSTRUCT
 je .construct
 cmp rax,NEBOC_IR_KIND_PREDICATE
 je .predicate
 cmp rax,NEBOC_IR_KIND_EXTRACT_OR
 je .extract
 jmp .types
.construct:
 cmp qword [r12+NEBOC_IR_INPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_INT
 jne .types
 cmp qword [r12+NEBOC_IR_OUTPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 cmp qword [r12+NEBOC_IR_TAG_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_RESULT_ERR
 ja .tag
 mov qword [r12+NEBOC_IR_SLOT_SIZE_OFFSET],16
 mov qword [r12+NEBOC_IR_SLOT_ALIGNMENT_OFFSET],8
 mov qword [r12+NEBOC_IR_TAG_OFFSET_OFFSET],0
 mov qword [r12+NEBOC_IR_PAYLOAD_OFFSET_OFFSET],8
 jmp .common
.predicate:
 cmp qword [r12+NEBOC_IR_INPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 cmp qword [r12+NEBOC_IR_OUTPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_BOOL
 jne .types
 mov qword [r12+NEBOC_IR_SLOT_SIZE_OFFSET],1
 mov qword [r12+NEBOC_IR_SLOT_ALIGNMENT_OFFSET],1
 jmp .common
.extract:
 cmp qword [r12+NEBOC_IR_INPUT_TYPE_OFFSET],NEBOC_TYPE_RESULT_POSITIVE_INT_INT
 jne .types
 cmp qword [r12+NEBOC_IR_OUTPUT_TYPE_OFFSET],neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_TYPE_POSITIVE_INT
 jne .types
 cmp qword [r12+NEBOC_IR_PAYLOAD_OFFSET],0
 jle .payload
 mov qword [r12+NEBOC_IR_SLOT_SIZE_OFFSET],8
 mov qword [r12+NEBOC_IR_SLOT_ALIGNMENT_OFFSET],8
.common:
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_ABI_CLASS_OFFSET],NEBOC_IR_ABI_INTEGER
 mov qword [r12+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_IR_FLAGS_OFFSET],NEBOC_IR_FLAGS_REQUIRED
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_ir_hash
 xor eax,eax
 jmp .done
.semantic: mov esi,NEBOC_IR_DIAG_SEMANTIC_INVALID
 jmp .diag
.hash: mov esi,NEBOC_IR_DIAG_SEMANTIC_HASH_MISMATCH
 jmp .diag
.types: mov esi,NEBOC_IR_DIAG_TYPE_INVARIANT
 jmp .diag
.tag: mov esi,NEBOC_IR_DIAG_TAG_INVARIANT
 jmp .diag
.target: mov esi,NEBOC_IR_DIAG_TARGET_UNSUPPORTED
 jmp .diag
.payload: mov esi,NEBOC_IR_DIAG_PAYLOAD_INVARIANT
.diag:
 mov rdi,r12
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_ir_error
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
