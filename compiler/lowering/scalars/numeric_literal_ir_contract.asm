; Nebo Assembly — LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF003 abstract HIR/LIR numeric literal contract
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/semantic/types/numeric_literal_semantic.inc"
%include "compiler/lowering/scalars/numeric_literal_ir_contract.inc"

section .text

; numeric_literal_ir_lower(request*) -> StatusCode
; Abstract semantic-to-IR contract only. No target instructions or runtime ABI
; are selected by this PF003 module.
NEBOC_ABI_FUNCTION neboc_numeric_literal_ir_lower
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_literais_numericos_bases_e_representacao_IR_SEMANTIC_REQUEST_OFFSET]
 test r13,r13
 jz .invalid
 lea rdi,[r12+neboc_literais_numericos_bases_e_representacao_IR_HIR_KIND_OFFSET]
 mov ecx,(neboc_literais_numericos_bases_e_representacao_IR_REQUEST_SIZE-neboc_literais_numericos_bases_e_representacao_IR_HIR_KIND_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_ERROR_NONE
 jne .semantic_invalid
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_CONSTANT_STATE_OFFSET],NEBOC_SEM_CONSTANT_VALID
 jne .semantic_invalid
 cmp qword [r13+NEBOC_SEM_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 jne .semantic_invariant
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_HIR_KIND_OFFSET],NEBOC_SEM_HIR_INT_CONSTANT
 jne .semantic_invariant
 cmp qword [r13+NEBOC_SEM_LIR_REPR_OFFSET],NEBOC_SEM_LIR_SIGNED_I64
 jne .semantic_invariant
 cmp qword [r13+neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_SEM_RUNTIME_METADATA_NONE
 jne .semantic_invariant
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_IR_HIR_KIND_OFFSET],NEBOC_IR_HIR_INT_CONSTANT
 mov qword [r12+NEBOC_IR_HIR_TYPE_ID_OFFSET],NEBOC_TYPE_ID_INT
 mov rax,[r13+NEBOC_SEM_SIGNED_VALUE_OFFSET]
 mov [r12+NEBOC_IR_HIR_VALUE_OFFSET],rax
 mov rax,[r13+neboc_literais_numericos_bases_e_representacao_SEM_SYNTAX_REQUEST_OFFSET]
 mov rdx,[rax+NEBOC_NUMERIC_SOURCE_ID_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_IR_HIR_SOURCE_ID_OFFSET],rdx
 mov rdx,[rax+NEBOC_NUMERIC_TOKEN_START_OFFSET]
 mov [r12+NEBOC_IR_HIR_START_OFFSET],rdx
 mov rdx,[rax+NEBOC_NUMERIC_TOKEN_END_OFFSET]
 mov [r12+NEBOC_IR_HIR_END_OFFSET],rdx
 mov rdx,[r13+neboc_literais_numericos_bases_e_representacao_SEM_PROVENANCE_HASH_OFFSET]
 mov [r12+neboc_literais_numericos_bases_e_representacao_IR_HIR_PROVENANCE_HASH_OFFSET],rdx
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_IR_LIR_KIND_OFFSET],NEBOC_IR_LIR_IMMEDIATE_I64
 mov qword [r12+NEBOC_IR_LIR_WIDTH_OFFSET],NEBOC_IR_WIDTH_64
 mov qword [r12+NEBOC_IR_LIR_SIGNED_OFFSET],NEBOC_IR_SIGNED_YES
 mov rax,[r13+NEBOC_SEM_SIGNED_VALUE_OFFSET]
 mov [r12+NEBOC_IR_LIR_VALUE_OFFSET],rax
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_OFFSET],neboc_literais_numericos_bases_e_representacao_IR_RUNTIME_METADATA_NONE
 ; Deterministic IR hash excludes source spelling but includes normalized value.
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_IR_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_TYPE_ID_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_HIR_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_literais_numericos_bases_e_representacao_IR_LIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_WIDTH_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_IR_LIR_SIGNED_OFFSET]
 imul rax,rcx
 mov [r12+neboc_literais_numericos_bases_e_representacao_IR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.semantic_invalid:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_IR_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_IR_ERROR_SEMANTIC_NOT_VALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.semantic_invariant:
 mov qword [r12+neboc_literais_numericos_bases_e_representacao_IR_ERROR_CODE_OFFSET],neboc_literais_numericos_bases_e_representacao_IR_ERROR_SEMANTIC_INVARIANT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,8
 pop r13
 pop r12
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
