; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F02 pointerless authenticated composite lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/types/struct_tuple.inc"
%include "compiler/lowering/aggregates/struct_tuple_plan.inc"

section .text

NEBOC_ABI_FUNCTION neboc_struct_tuple_lower
 test rdi,rdi
 jz .invalid_direct
 test rsi,rsi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 test rsi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 cmp qword [r12+NEBOC_ST_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_ST_DIAGNOSTIC_OFFSET],0
 jne .source
 call semantic_hash
 cmp rax,[r12+NEBOC_ST_SEMANTIC_HASH_OFFSET]
 jne .source
 mov rdi,r13
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,neboc_option_result_null_externo_e_erros_tipados_PLAN_MAGIC
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_MAGIC_OFFSET],rax
 mov rax,neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ID
 mov [r13+NEBOC_PLAN_LAYOUT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_ST_SEMANTIC_HASH_OFFSET]
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_DECL_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CONSTRUCT_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_ACCESS_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_ST_RESULT_TYPE_OFFSET]
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_RESULT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_ST_RESULT_VALUE_OFFSET]
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_RESULT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_ST_LAYOUT_SIZE_OFFSET]
 mov [r13+NEBOC_PLAN_LAYOUT_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_ST_LAYOUT_ALIGN_OFFSET]
 mov [r13+NEBOC_PLAN_LAYOUT_ALIGN_OFFSET],rax
 mov rax,[r12+NEBOC_ST_DROP_COUNT_OFFSET]
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_ST_CLEANUP_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_CLEANUP_HASH_OFFSET],rax
 mov rdi,r13
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_PLAN_HASHED_BYTES
 call hash_bytes
 mov [r13+neboc_option_result_null_externo_e_erros_tipados_PLAN_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

semantic_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 mov rcx,[r12+NEBOC_ST_FOUND_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_RESULT_TYPE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_RESULT_VALUE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_LAYOUT_SIZE_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_LAYOUT_ALIGN_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_DROP_COUNT_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,[r12+NEBOC_ST_CLEANUP_HASH_OFFSET]
 xor rax,rcx
 imul rax,r8
 mov rcx,neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ID
 xor rax,rcx
 imul rax,r8
 ret

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
