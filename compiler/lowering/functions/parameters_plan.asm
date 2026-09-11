; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F02 pointerless authenticated lowering plan.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/parameters_parser.inc"
%include "compiler/lowering/functions/parameters_plan.inc"

section .text

plan_hash:
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

NEBOC_ABI_FUNCTION neboc_parameters_lower
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
 cmp qword [r12+NEBOC_PARAM_FOUND_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jne .source
 cmp qword [r12+NEBOC_PARAM_SEMANTIC_HASH_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_PARAM_ABI_HASH_OFFSET],0
 je .source
 mov rax,[r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET]
 test rax,rax
 jz .source
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .source
 mov rax,[r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 mov rdx,[r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET]
 add rax,rdx
 cmp rax,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jne .source
 mov rax,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 test rax,rax
 jz .overload_ready
 cmp rax,2
 jb .source
 cmp rax,NEBOC_OVERLOAD_MAX
 ja .source
 cmp qword [r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET],0
 je .source
 mov rcx,[r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET]
 cmp rcx,rax
 jae .source
 cmp qword [r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET],1
 jb .source
 cmp qword [r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET],4
 ja .source
 cmp qword [r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET],0
 je .source
 cmp qword [r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET],0
 je .source
.overload_ready:
 mov rax,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 test rax,rax
 jz .callable_ready
 cmp rax,NEBOC_CALLABLE_MAX
 ja .source
 mov rcx,[r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET]
 cmp rcx,rax
 jae .source
 cmp qword [r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_BORROW
 ja .source
 cmp qword [r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET],1
 jne .source
 cmp qword [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],1
 ja .source
 mov rcx,[r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET]
 test rcx,rcx
 jz .callable_no_environment
 cmp qword [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],NEBOC_CALLABLE_ENV_SIZE
 jne .source
 cmp rcx,NEBOC_CAPTURE_BORROW
 jne .callable_environment_ready
 cmp qword [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],1
 jne .source
 jmp .callable_environment_ready
.callable_no_environment:
 cmp qword [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],0
 jne .source
.callable_environment_ready:
 mov rdx,[r12+NEBOC_CALLABLE_SELECTED_BODY_OFFSET]
 cmp rdx,NEBOC_CALLABLE_BODY_VALUE
 jb .source
 cmp rdx,NEBOC_CALLABLE_BODY_SUM
 ja .source
 cmp qword [r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],NEBOC_CAPTURE_NONE
 jne .callable_body_valid
 cmp rdx,NEBOC_CALLABLE_BODY_VALUE
 jne .source
.callable_body_valid:
 mov rdx,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 test rdx,rdx
 jz .source
 cmp qword [rdx+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jb .source
 cmp qword [rdx+NEBOC_PARAM_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .source
 cmp qword [r12+NEBOC_CALLABLE_HASH_OFFSET],0
 je .source
.callable_ready:
 cmp qword [r12+NEBOC_PARAM_VARIADIC_COUNT_OFFSET],NEBOC_PARAM_VARIADIC_MAX
 ja .source
 mov rax,[r12+NEBOC_PARAM_VARIADIC_INDEX_OFFSET]
 cmp rax,-1
 je .variadic_ready
 cmp rax,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jae .source
.variadic_ready:
 mov rdi,r13
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_QWORDS
 xor eax,eax
 rep stosq
 mov rax,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC
 mov [r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_MAGIC_OFFSET],rax
 mov rax,NEBOC_ABI_PROFILE_ID
 mov [r13+NEBOC_PLAN_PROFILE_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_SEMANTIC_HASH_OFFSET]
 mov [r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_SEMANTIC_HASH_OFFSET],rax
 mov qword [r13+NEBOC_PLAN_FOUND_OFFSET],1
 mov rax,[r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET]
 mov [r13+NEBOC_PLAN_OUTPUT_TYPE_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET]
 mov [r13+NEBOC_PLAN_OUTPUT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_EXPLICIT_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_DEFAULT_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_NAMED_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_NAMED_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_RETURN_ARITY_OFFSET]
 mov [r13+NEBOC_PLAN_RETURN_ARITY_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_ABI_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_ABI_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_OVERLOAD_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET]
 mov [r13+NEBOC_PLAN_CANDIDATE_MASK_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET]
 mov [r13+NEBOC_PLAN_SELECTED_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET]
 mov [r13+NEBOC_PLAN_SELECTED_SCORE_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_DISPATCH_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_MANGLE_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET]
 mov [r13+NEBOC_PLAN_CAPTURE_MODE_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_CALL_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET]
 mov [r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_DROP_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET]
 mov [r13+NEBOC_PLAN_ENV_SIZE_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_SELECTED_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_HASH_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_BORROW_MASK_OFFSET]
 mov [r13+NEBOC_PLAN_BORROW_MASK_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_OWNED_MASK_OFFSET]
 mov [r13+NEBOC_PLAN_OWNED_MASK_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_VARIADIC_INDEX_OFFSET]
 mov [r13+NEBOC_PLAN_VARIADIC_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_PARAM_VARIADIC_COUNT_OFFSET]
 mov [r13+NEBOC_PLAN_VARIADIC_COUNT_OFFSET],rax
 xor ecx,ecx
.copy_variadic_values:
 cmp ecx,NEBOC_PARAM_VARIADIC_MAX
 jae .variadic_values_copied
 lea rax,[r12+NEBOC_PARAM_VARIADIC_VALUES_OFFSET]
 mov rdx,[rax+rcx*8]
 lea rax,[r13+NEBOC_PLAN_VARIADIC_VALUES_OFFSET]
 mov [rax+rcx*8],rdx
 inc ecx
 jmp .copy_variadic_values
.variadic_values_copied:
 cmp qword [r12+NEBOC_CALLABLE_COUNT_OFFSET],0
 je .callable_payload_ready
 mov rax,[r12+NEBOC_CALLABLE_SELECTED_BODY_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_BODY_OFFSET],rax
 mov rdx,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov rax,[rdx+NEBOC_PARAM_TYPE_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_ARGUMENT_TYPE_OFFSET],rax
 mov rax,[rdx+NEBOC_PARAM_BOUND_VALUE_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_ARGUMENT_VALUE_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_CAPTURE_VALUE_OFFSET]
 mov [r13+NEBOC_PLAN_CALLABLE_CAPTURE_VALUE_OFFSET],rax
.callable_payload_ready:
 mov rdi,r13
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASHED_BYTES
 call plan_hash
 mov [r13+neboc_seguranca_numerica_conversoes_e_overflow_PLAN_HASH_OFFSET],rax
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

section .note.GNU-stack noalloc noexec nowrite progbits
