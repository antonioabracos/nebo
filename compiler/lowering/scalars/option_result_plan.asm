; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F02 pointerless authenticated Option lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"

section .text

NEBOC_ABI_FUNCTION neboc_option_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_OPTION_EFFECT_COUNT_OFFSET],32
 ja .source
 cmp qword [r12+NEBOC_OPTION_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_OPTION_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r12+NEBOC_OPTION_SEMANTIC_HASH_OFFSET],0
 je .source
 mov rax,[r12+NEBOC_OPTION_RESULT_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_OPTION_TYPE_CHAR
 ja .source
 mov rax,[r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 cmp rax,NEBOC_OPTION_MAX_BINDINGS
 ja .source
 mov rax,[r12+NEBOC_OPTION_DROP_COUNT_OFFSET]
 cmp rax,NEBOC_OPTION_MAX_BINDINGS
 ja .source
 mov rax,[r12+NEBOC_OPTION_LAYOUT_SIZE_OFFSET]
 cmp rax,8
 jb .source
 cmp rax,NEBOC_OPTION_MAX_PAYLOAD_SIZE
 ja .source
 mov rcx,[r12+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET]
 cmp rcx,8
 jb .source
 cmp rcx,64
 ja .source
 mov rdx,rcx
 dec rdx
 test rcx,rdx
 jnz .source
 test rax,rdx
 jnz .source
 mov rdi,r13
 mov ecx,NEBOC_OPTION_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_OPTION_PLAN_MAGIC
 mov [r13+NEBOC_OPTION_PLAN_MAGIC_OFFSET],rax
 mov rax,NEBOC_OPTION_LAYOUT_ID
 mov [r13+NEBOC_OPTION_PLAN_LAYOUT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov qword [r13+NEBOC_OPTION_PLAN_FOUND_OFFSET],1
 mov rax,[r12+NEBOC_OPTION_RESULT_TYPE_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_RESULT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_RESULT_VALUE_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_RESULT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_CALLBACK_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_DROP_COUNT_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_LAYOUT_SIZE_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_MAX_LAYOUT_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET]
 mov [r13+NEBOC_OPTION_PLAN_MAX_LAYOUT_ALIGN_OFFSET],rax
 lea rsi,[r12+NEBOC_OPTION_EFFECT_COUNT_OFFSET]
 lea rdi,[r13+NEBOC_OPTION_PLAN_EFFECT_COUNT_OFFSET]
 mov ecx,1+32*4
 rep movsq
 mov rdi,r13
 mov ecx,NEBOC_OPTION_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+NEBOC_OPTION_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r13
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Build the pointerless authenticated Result<T,E> plan.  The public value is
; deliberately restricted to the scalar result of an inspection/combinator;
; aggregate payloads may still participate in construction and destruction.
NEBOC_ABI_FUNCTION neboc_result_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_RESULT_EFFECT_COUNT_OFFSET],32
 ja .source
 cmp qword [r12+NEBOC_RESULT_TEXT_USED_OFFSET],NEBOC_RESULT_TEXT_CAPACITY
 ja .source
 cmp qword [r12+NEBOC_RESULT_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],0
 je .source
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_RESULT_TYPE_CHAR
 ja .source
 mov rax,[r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 cmp rax,NEBOC_RESULT_MAX_BINDINGS
 ja .source
 mov rax,[r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 cmp rax,NEBOC_RESULT_MAX_BINDINGS
 ja .source
 mov rax,[r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET]
 cmp rax,8
 jb .source
 cmp rax,NEBOC_RESULT_MAX_PAYLOAD_SIZE
 ja .source
 mov rcx,[r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET]
 cmp rcx,8
 jb .source
 cmp rcx,64
 ja .source
 mov rdx,rcx
 dec rdx
 test rcx,rdx
 jnz .source
 test rax,rdx
 jnz .source
 cmp qword [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 ja .source
 mov rax,[r12+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET]
 cmp rax,1
 ja .source
 test rax,rax
 jz .propagation_ready
 cmp qword [r12+NEBOC_RESULT_EARLY_RETURN_OFFSET],1
 ja .source
 mov rax,[r12+NEBOC_RESULT_CLEANUP_COUNT_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_RESULT_MAX_BINDINGS
 ja .source
 cmp rax,[r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 ja .source
 cmp qword [r12+NEBOC_RESULT_CLEANUP_HASH_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_RESULT_GUARD_COUNT_OFFSET],NEBOC_RESULT_MAX_BINDINGS
 ja .source
 cmp qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 jne .source
 mov rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,[r12+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET]
 jne .source
 mov rax,[r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,[r12+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET]
 jne .source
.propagation_ready:
 mov rax,[r12+NEBOC_RESULT_MATCH_COUNT_OFFSET]
 cmp rax,1
 ja .source
 test rax,rax
 jz .match_ready
 mov rax,[r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,[r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET]
 jne .source
 cmp qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_EVAL_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_RESULT_MATCH_CLEANUP_COUNT_OFFSET],1
 jne .source
 mov rax,[r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET]
 cmp rax,NEBOC_MATCH_CONTAINER_OPTION
 jb .source
 cmp rax,NEBOC_MATCH_CONTAINER_ENUM
 ja .source
 mov rax,[r12+NEBOC_RESULT_MATCH_ARM_COUNT_OFFSET]
 test rax,rax
 jz .source
 cmp rax,NEBOC_MATCH_MAX_ARMS
 ja .source
 mov rcx,[r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET]
 cmp rcx,rax
 jae .source
.match_ready:
 mov rax,[r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 test rax,rax
 jz .error_ready
 cmp rax,NEBOC_ERROR_MAX_BINDINGS
 ja .source
 cmp qword [r12+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET],NEBOC_ERROR_MAX_CONTEXT
 ja .source
 cmp qword [r12+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET],NEBOC_ERROR_MAX_BINDINGS
 ja .source
 cmp qword [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],NEBOC_ERROR_LAYOUT_SIZE
 jne .source
 cmp qword [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],NEBOC_ERROR_LAYOUT_ALIGN
 jne .source
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 cmp rax,NEBOC_RESULT_TYPE_INT
 je .error_output_ready
 cmp rax,NEBOC_RESULT_TYPE_BOOL
 jne .source
.error_output_ready:
 cmp qword [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .source
.error_ready:
 mov rdi,r13
 mov ecx,NEBOC_RESULT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,NEBOC_RESULT_PLAN_MAGIC
 mov [r13+NEBOC_RESULT_PLAN_MAGIC_OFFSET],rax
 mov rax,NEBOC_RESULT_LAYOUT_ID
 mov [r13+NEBOC_RESULT_PLAN_LAYOUT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov qword [r13+NEBOC_RESULT_PLAN_FOUND_OFFSET],1
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_OUTPUT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_OUTPUT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_CALLBACK_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_MAX_LAYOUT_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_MAX_LAYOUT_ALIGN_OFFSET],rax
 mov rax,[r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET]
 mov [r13+NEBOC_RESULT_PLAN_ACTIVE_TAG_OFFSET],rax
 lea rsi,[r12+NEBOC_RESULT_EFFECT_COUNT_OFFSET]
 lea rdi,[r13+NEBOC_RESULT_PLAN_EFFECT_COUNT_OFFSET]
 mov ecx,2+32*4+4096/8
 rep movsq
 mov rdi,r13
 mov ecx,NEBOC_RESULT_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+NEBOC_RESULT_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r13
 pop r12
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

hash_bytes:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rdi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
