; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 public Option/Result resolver/typechecker bridge
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/parser/option_result_vertical_parser.inc"
%include "compiler/semantic/types/option_result_semantic.inc"
%include "compiler/lowering/scalars/option_result_ir_contract.inc"
%include "compiler/lowering/scalars/option_result_native_lowering.inc"
%include "compiler/semantic/types/option_result_vertical.inc"
extern neboc_option_result_api_contract
extern neboc_option_result_semantic_analyze
extern neboc_option_result_ir_lower
extern neboc_option_result_native_lower

section .text

; request*, token index -> token* or zero
g06v_token_ptr:
 mov rax,rsi
 cmp rax,[rdi+NEBOC_VSEM_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_VSEM_TOKENS_OFFSET]
 ret
.bad: xor eax,eax
 ret

; request*, token a, token b -> EAX 1 when exact same bytes
g06v_token_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g06v_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call g06v_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r15+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[r15+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r8,[r12+NEBOC_VSEM_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r12+NEBOC_VSEM_SOURCE_OFFSET]
 add r9,[r15+NEBOC_TOKEN_START_OFFSET]
 xor edx,edx
.loop:
 cmp rdx,rcx
 jae .yes
 mov al,[r8+rdx]
 cmp al,[r9+rdx]
 jne .no
 inc rdx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, public diagnostic, token index -> INVALID_SOURCE
g06v_set_error:
 push rbx
 mov rbx,rdi
 mov [rbx+NEBOC_VSEM_ERROR_CODE_OFFSET],rsi
 mov [rbx+NEBOC_VSEM_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call g06v_token_ptr
 test rax,rax
 jz .done_span
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+NEBOC_VSEM_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+NEBOC_VSEM_ERROR_END_OFFSET],rcx
.done_span:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

; request*, token index -> RAX symbol index or -1
g06v_lookup_symbol:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 xor r14d,r14d
.loop:
 cmp r14,[r12+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 jae .not_found
 mov rax,r14
 imul rax,NEBOC_VSYM_RECORD_SIZE
 add rax,[r12+NEBOC_VSEM_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rbx+NEBOC_VSYM_NAME_TOKEN_OFFSET]
 call g06v_token_equal
 test eax,eax
 jnz .found
 inc r14
 jmp .loop
.found: mov rax,r14
 jmp .done
.not_found: mov rax,-1
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RAX scalar type -> RDX size, RCX alignment; EAX zero on unsupported
g06v_scalar_layout:
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 je .bool
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 je .eight
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 je .eight
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
 je .char
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 ret
.bool: mov edx,1
 mov ecx,1
 mov eax,1
 ret
.char: mov edx,4
 mov ecx,4
 mov eax,1
 ret
.eight: mov edx,8
 mov ecx,8
 mov eax,1
 ret

; request*, name token, kind, container, success, error, scalar ->
; RAX symbol index or -1. Uses stack arg scalar at [entry rsp+8].
g06v_add_symbol:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov [rsp],r8
 mov [rsp+8],r9
 mov rax,[rbp+16]
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,r13
 call g06v_lookup_symbol
 cmp rax,-1
 jne .duplicate
 mov rax,[r12+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_VSEM_SYMBOL_CAPACITY_OFFSET]
 jae .internal
 mov rbx,rax
 imul rax,NEBOC_VSYM_RECORD_SIZE
 add rax,[r12+NEBOC_VSEM_SYMBOLS_OFFSET]
 mov [rax+NEBOC_VSYM_NAME_TOKEN_OFFSET],r13
 mov [rax+NEBOC_VSYM_KIND_OFFSET],r14
 mov [rax+NEBOC_VSYM_CONTAINER_OFFSET],r15
 mov rcx,[rsp]
 mov [rax+NEBOC_VSYM_SUCCESS_TYPE_OFFSET],rcx
 mov rcx,[rsp+8]
 mov [rax+NEBOC_VSYM_ERROR_TYPE_OFFSET],rcx
 mov rcx,[rsp+16]
 mov [rax+NEBOC_VSYM_SCALAR_TYPE_OFFSET],rcx
 cmp r14,NEBOC_VSYM_KIND_CONTAINER
 je .container_layout
 mov rax,rcx
 call g06v_scalar_layout
 test eax,eax
 jz .internal
 jmp .layout_ready
.container_layout:
 mov edx,16
 mov ecx,8
.layout_ready:
 mov rax,[r12+NEBOC_VSEM_FRAME_SIZE_OFFSET]
 dec rcx
 add rax,rcx
 not rcx
 and rax,rcx
 add rax,rdx
 mov [r12+NEBOC_VSEM_FRAME_SIZE_OFFSET],rax
 mov rcx,rbx
 imul rcx,NEBOC_VSYM_RECORD_SIZE
 add rcx,[r12+NEBOC_VSEM_SYMBOLS_OFFSET]
 mov [rcx+NEBOC_VSYM_SLOT_OFFSET],rax
 mov [rcx+NEBOC_VSYM_SIZE_OFFSET],rdx
 inc qword [r12+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 mov rax,rbx
 jmp .done
.duplicate:
 mov rdi,r12
 mov esi,NEBOC_DIAG_DUPLICATE_BINDING
 mov rdx,r13
 call g06v_set_error
 mov rax,-1
 jmp .done
.internal:
 mov rdi,r12
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_parser
 mov rdx,r13
 call g06v_set_error
 mov rax,-1
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; request*, semantic error code, subject token -> public diagnostic
g06v_semantic_error:
 cmp rsi,NEBOC_SEM_ERROR_PAYLOAD_TYPE_MISMATCH
 je .payload
 cmp rsi,NEBOC_SEM_ERROR_FALLBACK_TYPE_MISMATCH
 je .fallback
 cmp rsi,NEBOC_SEM_ERROR_CONTEXT_REQUIRED
 je .context
 cmp rsi,neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_SPAN_INVARIANT
 je .span
 mov esi,NEBOC_DIAG_RECEIVER_TYPE_MISMATCH
 jmp g06v_set_error
.payload: mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_PAYLOAD_TYPE_MISMATCH
 jmp g06v_set_error
.fallback: mov esi,NEBOC_DIAG_FALLBACK_TYPE_MISMATCH
 jmp g06v_set_error
.context: mov esi,NEBOC_DIAG_CONTEXT_REQUIRED
 jmp g06v_set_error
.span: mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SEMANTIC_SPAN_INVARIANT
 jmp g06v_set_error

; request*, operation record -> validate API, semantic, IR and native contracts.
g06v_validate_operation:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,944
 mov r12,rdi
 mov r13,rsi
 ; Resolve observer receiver before constructing contract requests.
 cmp qword [r13+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_OBSERVER
 jne .context_ready
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_RECEIVER_TOKEN_OFFSET]
 call g06v_lookup_symbol
 cmp rax,-1
 jne .receiver_found
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_BINDING
 mov rdx,[r13+NEBOC_VOP_RECEIVER_TOKEN_OFFSET]
 call g06v_set_error
 jmp .done
.receiver_found:
 mov [r13+NEBOC_VOP_RESOLVED_RECEIVER_OFFSET],rax
 mov rbx,rax
 imul rbx,NEBOC_VSYM_RECORD_SIZE
 add rbx,[r12+NEBOC_VSEM_SYMBOLS_OFFSET]
 cmp qword [rbx+NEBOC_VSYM_KIND_OFFSET],NEBOC_VSYM_KIND_CONTAINER
 je .receiver_container
 mov rdi,r12
 mov esi,NEBOC_DIAG_RECEIVER_TYPE_MISMATCH
 mov rdx,[r13+NEBOC_VOP_RECEIVER_TOKEN_OFFSET]
 call g06v_set_error
 jmp .done
.receiver_container:
 mov rax,[rbx+NEBOC_VSYM_CONTAINER_OFFSET]
 mov [r13+NEBOC_VOP_CONTAINER_OFFSET],rax
 mov rax,[rbx+NEBOC_VSYM_SUCCESS_TYPE_OFFSET]
 mov [r13+NEBOC_VOP_SUCCESS_TYPE_OFFSET],rax
 mov rax,[rbx+NEBOC_VSYM_ERROR_TYPE_OFFSET]
 mov [r13+NEBOC_VOP_ERROR_TYPE_OFFSET],rax
.context_ready:
 test qword [r13+NEBOC_VOP_FLAGS_OFFSET],NEBOC_VOP_FLAG_CONTEXT_MISSING
 jz .api_request
 mov rdi,r12
 mov esi,NEBOC_DIAG_CONTEXT_REQUIRED
 mov rdx,[r13+NEBOC_VOP_SUBJECT_TOKEN_OFFSET]
 call g06v_set_error
 jmp .done
.api_request:
 lea rdi,[rsp]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r13+NEBOC_VOP_KIND_OFFSET]
 cmp rax,NEBOC_VOP_CONSTRUCT
 je .api_construct
 mov qword [rsp+neboc_option_result_null_externo_e_erros_tipados_OPERATION_OFFSET],NEBOC_OP_OBSERVER
 jmp .api_common
.api_construct:
 mov qword [rsp+neboc_option_result_null_externo_e_erros_tipados_OPERATION_OFFSET],NEBOC_OP_CONSTRUCT
 mov rax,[r13+NEBOC_VOP_CONTAINER_OFFSET]
 cmp rax,NEBOC_CONTAINER_OPTION
 jne .api_result_types
 mov qword [rsp+NEBOC_TYPE_ARG_COUNT_OFFSET],1
 jmp .api_common
.api_result_types:
 mov qword [rsp+NEBOC_TYPE_ARG_COUNT_OFFSET],2
.api_common:
 mov rax,[r13+NEBOC_VOP_CONTAINER_OFFSET]
 mov [rsp+NEBOC_CONTAINER_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_SUCCESS_TYPE_OFFSET]
 mov [rsp+NEBOC_SUCCESS_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_ERROR_TYPE_OFFSET]
 mov [rsp+NEBOC_ERROR_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_VARIANT_OBSERVER_OFFSET]
 cmp qword [r13+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 jne .api_observer
 mov [rsp+NEBOC_VARIANT_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_ARGUMENT_COUNT_OFFSET]
 mov [rsp+NEBOC_VARIANT_ARG_COUNT_OFFSET],rax
 jmp .api_subject
.api_observer:
 mov [rsp+NEBOC_OBSERVER_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_ARGUMENT_COUNT_OFFSET]
 mov [rsp+NEBOC_OBSERVER_ARG_COUNT_OFFSET],rax
.api_subject:
 mov qword [rsp+NEBOC_INPUT_FLAGS_OFFSET],neboc_option_result_null_externo_e_erros_tipados_INPUT_EXACT_SPELLING
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_SUBJECT_TOKEN_OFFSET]
 call g06v_token_ptr
 test rax,rax
 jz .internal
 mov rbx,rax
 mov rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,rcx
 mov rax,[r12+NEBOC_VSEM_SOURCE_OFFSET]
 add rax,rcx
 mov [rsp+NEBOC_SUBJECT_PTR_OFFSET],rax
 mov [rsp+NEBOC_SUBJECT_LENGTH_OFFSET],rdx
 mov [rsp+NEBOC_ABSOLUTE_START_OFFSET],rcx
 lea rdi,[rsp]
 call neboc_option_result_api_contract
 test eax,eax
 jz .semantic_request
 mov rsi,[rsp+neboc_option_result_null_externo_e_erros_tipados_DIAGNOSTIC_OFFSET]
 mov rdx,[r13+NEBOC_VOP_SUBJECT_TOKEN_OFFSET]
 mov rdi,r12
 call g06v_set_error
 jmp .done
.semantic_request:
 lea rdi,[rsp+160]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rsp]
 mov [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_API_REQUEST_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_CONTAINER_OFFSET]
 mov [rsp+160+NEBOC_SEM_CONTAINER_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_SUCCESS_TYPE_OFFSET]
 mov [rsp+160+NEBOC_SEM_SUCCESS_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_ERROR_TYPE_OFFSET]
 mov [rsp+160+NEBOC_SEM_ERROR_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_VALUE_TYPE_OFFSET]
 mov [rsp+160+NEBOC_SEM_VALUE_TYPE_OFFSET],rax
 mov [rsp+160+NEBOC_SEM_FALLBACK_TYPE_OFFSET],rax
 mov qword [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_SOURCE_ID_OFFSET],1
 mov rax,[r13+NEBOC_VOP_START_OFFSET]
 mov [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_START_OFFSET],rax
 mov rax,[r13+NEBOC_VOP_END_OFFSET]
 mov [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_NODE_END_OFFSET],rax
 mov rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_START_OFFSET],rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 mov [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_SUBJECT_END_OFFSET],rax
 mov qword [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_CONTEXT_VALID
 cmp qword [r13+NEBOC_VOP_ARGUMENT_COUNT_OFFSET],0
 je .semantic_invoke
 cmp qword [r13+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 jne .fallback_present
 or qword [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_VALUE_PRESENT
 jmp .semantic_invoke
.fallback_present:
 or qword [rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_INPUT_FLAGS_OFFSET],NEBOC_SEM_INPUT_FALLBACK_PRESENT
.semantic_invoke:
 lea rdi,[rsp+160]
 call neboc_option_result_semantic_analyze
 test eax,eax
 jz .ir_request
 mov rdi,r12
 mov rsi,[rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_ERROR_CODE_OFFSET]
 mov rdx,[r13+NEBOC_VOP_SUBJECT_TOKEN_OFFSET]
 call g06v_semantic_error
 jmp .done
.ir_request:
 lea rdi,[rsp+424]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_IR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rsp+160]
 mov [rsp+424+neboc_option_result_null_externo_e_erros_tipados_IR_SEMANTIC_REQUEST_OFFSET],rax
 lea rdi,[rsp+424]
 call neboc_option_result_ir_lower
 test eax,eax
 jnz .internal
.native_request:
 lea rdi,[rsp+560]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_NATIVE_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rsp+160]
 mov [rsp+560+neboc_option_result_null_externo_e_erros_tipados_NATIVE_SEMANTIC_REQUEST_OFFSET],rax
 lea rax,[rsp+424]
 mov [rsp+560+neboc_option_result_null_externo_e_erros_tipados_NATIVE_IR_REQUEST_OFFSET],rax
 mov qword [rsp+560+neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_ID_OFFSET],neboc_option_result_null_externo_e_erros_tipados_NATIVE_TARGET_X86_64_SYSTEMV_ELF_LINUX
 lea rdi,[rsp+560]
 call neboc_option_result_native_lower
 test eax,eax
 jnz .internal
 mov rax,[rsp+560+neboc_option_result_null_externo_e_erros_tipados_NATIVE_RUNTIME_HELPER_OFFSET]
 mov [r13+NEBOC_VOP_RUNTIME_HELPER_OFFSET],rax
 mov rax,[rsp+560+NEBOC_NATIVE_TAG_VALUE_OFFSET]
 mov [r13+NEBOC_VOP_TAG_VALUE_OFFSET],rax
 mov rax,[rsp+560+NEBOC_NATIVE_SUCCESS_TAG_OFFSET]
 mov [r13+NEBOC_VOP_SUCCESS_TAG_OFFSET],rax
 mov rax,[rsp+560+NEBOC_NATIVE_ACTIVE_REPR_OFFSET]
 mov [r13+NEBOC_VOP_ACTIVE_REPR_OFFSET],rax
 mov rax,[rsp+160+neboc_option_result_null_externo_e_erros_tipados_SEM_SEMANTIC_HASH_OFFSET]
 mov [r13+NEBOC_VOP_SEMANTIC_HASH_OFFSET],rax
 mov rax,[rsp+560+neboc_option_result_null_externo_e_erros_tipados_NATIVE_HASH_OFFSET]
 mov [r13+NEBOC_VOP_NATIVE_HASH_OFFSET],rax
 ; Add result binding to the public symbol table.
 cmp qword [r13+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 jne .add_scalar
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_BINDING_TOKEN_OFFSET]
 mov edx,NEBOC_VSYM_KIND_CONTAINER
 mov rcx,[r13+NEBOC_VOP_CONTAINER_OFFSET]
 mov r8,[r13+NEBOC_VOP_SUCCESS_TYPE_OFFSET]
 mov r9,[r13+NEBOC_VOP_ERROR_TYPE_OFFSET]
 sub rsp,16
 mov qword [rsp],NEBOC_TYPE_NONE
 call g06v_add_symbol
 add rsp,16
 jmp .symbol_added
.add_scalar:
 mov rax,[rsp+160+NEBOC_SEM_RESULT_TYPE_KIND_OFFSET]
 cmp rax,NEBOC_SEM_RESULT_BOOL
 jne .payload_result
 mov r15,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 jmp .scalar_type_ready
.payload_result:
 mov r15,[r13+NEBOC_VOP_SUCCESS_TYPE_OFFSET]
.scalar_type_ready:
 mov [r13+NEBOC_VOP_RESULT_TYPE_OFFSET],r15
 mov rdi,r12
 mov rsi,[r13+NEBOC_VOP_BINDING_TOKEN_OFFSET]
 mov edx,NEBOC_VSYM_KIND_SCALAR
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 sub rsp,16
 mov [rsp],r15
 call g06v_add_symbol
 add rsp,16
.symbol_added:
 cmp rax,-1
 je .done
 mov [r13+NEBOC_VOP_RESOLVED_OUTPUT_OFFSET],rax
 inc qword [r12+NEBOC_VSEM_OPERATION_VALIDATED_OFFSET]
 xor eax,eax
 jmp .done
.internal:
 mov rdi,r12
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_parser
 mov rdx,[r13+NEBOC_VOP_SUBJECT_TOKEN_OFFSET]
 call g06v_set_error
.done:
 add rsp,944
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_option_result_vertical_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov rax,[r12+NEBOC_VSEM_OPERATIONS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VSEM_SYMBOLS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_VSEM_SYMBOL_CAPACITY_OFFSET],1
 jb .invalid
 lea rdi,[r12+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 mov ecx,(NEBOC_VSEM_REQUEST_SIZE-NEBOC_VSEM_SYMBOL_COUNT_OFFSET)/8
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_VSEM_FOUND_OFFSET],1
 xor r13d,r13d
.loop:
 cmp r13,[r12+NEBOC_VSEM_OPERATION_COUNT_OFFSET]
 jae .finish
 mov rax,r13
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rax,[r12+NEBOC_VSEM_OPERATIONS_OFFSET]
 mov r14,rax
 mov rdi,r12
 mov rsi,r14
 call g06v_validate_operation
 test eax,eax
 jnz .done
 inc r13
 jmp .loop
.finish:
 mov rax,[r12+NEBOC_VSEM_FRAME_SIZE_OFFSET]
 add rax,15
 and rax,-16
 test rax,rax
 jnz .frame_ready
 mov eax,16
.frame_ready:
 mov [r12+NEBOC_VSEM_FRAME_SIZE_OFFSET],rax
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_VSEM_OPERATION_VALIDATED_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_VSEM_FRAME_SIZE_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_VSEM_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
