; Nebo Assembly — TEXT-CHAR-UNICODE-E-BYTES-PF003 isolated portable HIR/LIR contract
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/text_char_bytes_semantic.inc"
%include "compiler/lowering/textual/text_char_bytes_ir_contract.inc"
section .text
NEBOC_ABI_FUNCTION neboc_text_char_bytes_ir_lower
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid_argument
 mov rbx,[r12+neboc_text_char_unicode_e_bytes_IR_SEMANTIC_REQUEST_OFFSET]
 test rbx,rbx
 jz .invalid_argument
 lea rdi,[r12+neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET]
 mov ecx,(neboc_text_char_unicode_e_bytes_IR_REQUEST_SIZE-neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET)/8
 xor eax,eax
 rep stosq
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_ERROR_CODE_OFFSET],0
 jne .semantic_invalid
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_CHAR_LITERAL
 jb .semantic_invariant
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET],NEBOC_SEM_OPERATION_BYTES_BYTE_LENGTH
 ja .semantic_invariant
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET],0
 je .semantic_invariant
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET],0
 je .semantic_invariant
 cmp qword [rbx+neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_OFFSET],neboc_text_char_unicode_e_bytes_SEM_RUNTIME_METADATA_NONE
 jne .semantic_invariant
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_OPERATION_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_HIR_KIND_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_HIR_KIND_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_OPERAND_TYPE_OFFSET]
 mov [r12+NEBOC_IR_OPERAND_TYPE_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_RESULT_TYPE_OFFSET_lowering_textual]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_RESULT_TYPE_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_LIR_KIND_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_OPERAND_REPR_OFFSET]
 mov [r12+NEBOC_IR_OPERAND_REPR_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_RESULT_REPR_OFFSET]
 mov [r12+NEBOC_IR_RESULT_REPR_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_POLICY_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_POLICY_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_EFFECT_FLAGS_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_EFFECT_FLAGS_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_SCALAR_VALUE_OFFSET]
 mov [r12+NEBOC_IR_SCALAR_VALUE_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_BYTE_LENGTH_OFFSET]
 mov [r12+NEBOC_IR_BYTE_LENGTH_OFFSET],rax
 mov rax,[rbx+NEBOC_SEM_CODEPOINT_COUNT_OFFSET]
 mov [r12+NEBOC_IR_CODEPOINT_COUNT_OFFSET],rax
 mov qword [r12+neboc_text_char_unicode_e_bytes_IR_RUNTIME_METADATA_OFFSET],0
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_SOURCE_ID_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_SOURCE_ID_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_NODE_START_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_NODE_START_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_NODE_END_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_NODE_END_OFFSET],rax
 mov rax,[rbx+neboc_text_char_unicode_e_bytes_SEM_SEMANTIC_HASH_OFFSET]
 mov [r12+neboc_text_char_unicode_e_bytes_IR_SEMANTIC_HASH_OFFSET],rax
 mov rcx,1099511628211
 xor rax,[r12+neboc_text_char_unicode_e_bytes_IR_OPERATION_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_IR_HIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_IR_LIR_KIND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_IR_POLICY_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_text_char_unicode_e_bytes_IR_RESULT_TYPE_OFFSET]
 imul rax,rcx
 mov [r12+neboc_text_char_unicode_e_bytes_IR_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.semantic_invalid:
 mov qword [r12+neboc_text_char_unicode_e_bytes_IR_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_IR_ERROR_SEMANTIC_INVALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.semantic_invariant:
 mov qword [r12+neboc_text_char_unicode_e_bytes_IR_ERROR_CODE_OFFSET],neboc_text_char_unicode_e_bytes_IR_ERROR_SEMANTIC_INVARIANT
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid_argument:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
