; Nebo Assembly — MF023 signatures, return inference, calls and call graph
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/function/function_table.inc"
%include "compiler/semantic/call/call_resolver.inc"

extern neboc_function_table_append
extern neboc_function_table_freeze

section .text

; call_analyze(request*)
NEBOC_ABI_FUNCTION neboc_call_analyze
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .analyze_invalid
 mov r13,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 test r13,r13
 jz .analyze_invalid
 cmp qword [r13+NEBOC_FUNCTION_TABLE_STATE_OFFSET],NEBOC_FUNCTION_TABLE_STATE_MUTABLE
 jne .analyze_invalid
 cmp qword [r13+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],0
 jne .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_TOKENS_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_SOURCE_OFFSET],0
 je .analyze_invalid
 mov rbx,[r12+NEBOC_CALL_REQUEST_FUNCTION_COUNT_OFFSET]
 test rbx,rbx
 jz .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_FUNCTION_INPUTS_OFFSET],0
 je .analyze_invalid
 cmp rbx,[r13+NEBOC_FUNCTION_TABLE_CAPACITY_OFFSET]
 ja .analyze_limit
 cmp rbx,[r12+NEBOC_CALL_REQUEST_SCRATCH_CAPACITY_OFFSET]
 ja .analyze_limit
 cmp qword [r12+NEBOC_CALL_REQUEST_NODE_CAPACITY_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_NODE_FUNCTIONS_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_EDGES_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_INDEGREES_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_TOPO_ORDER_OFFSET],0
 je .analyze_invalid
 cmp qword [r12+NEBOC_CALL_REQUEST_CALL_COUNT_OFFSET],0
 je .calls_pointer_ready
 cmp qword [r12+NEBOC_CALL_REQUEST_CALL_INPUTS_OFFSET],0
 je .analyze_invalid
.calls_pointer_ready:
 cmp qword [r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPE_COUNT_OFFSET],0
 je .positionals_pointer_ready
 cmp qword [r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPES_OFFSET],0
 je .analyze_invalid
.positionals_pointer_ready:
 cmp qword [r12+NEBOC_CALL_REQUEST_RETURN_TYPE_COUNT_OFFSET],0
 je .returns_pointer_ready
 cmp qword [r12+NEBOC_CALL_REQUEST_RETURN_TYPES_OFFSET],0
 je .analyze_invalid
.returns_pointer_ready:
 cmp qword [r12+NEBOC_CALL_REQUEST_ARGUMENT_TYPE_COUNT_OFFSET],0
 je .arguments_pointer_ready
 cmp qword [r12+NEBOC_CALL_REQUEST_ARGUMENT_TYPES_OFFSET],0
 je .analyze_invalid
.arguments_pointer_ready:
 mov qword [r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_CALL_REQUEST_ERROR_RECORD_OFFSET],0
 mov qword [r12+NEBOC_CALL_REQUEST_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_CALL_REQUEST_HASH_OFFSET],0
 ; Clear NodeId -> FunctionId side table.
 mov rdi,[r12+NEBOC_CALL_REQUEST_NODE_FUNCTIONS_OFFSET]
 xor eax,eax
 mov rcx,[r12+NEBOC_CALL_REQUEST_NODE_CAPACITY_OFFSET]
 rep stosq
 ; Clear edge storage.
 mov rdi,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
 mov rcx,[r12+NEBOC_CALL_REQUEST_EDGE_CAPACITY_OFFSET]
 imul rcx,NEBOC_CALL_EDGE_QWORDS
 rep stosq
 ; Clear graph scratch.
 mov rdi,[r12+NEBOC_CALL_REQUEST_INDEGREES_OFFSET]
 mov rcx,[r12+NEBOC_CALL_REQUEST_SCRATCH_CAPACITY_OFFSET]
 rep stosq
 mov rdi,[r12+NEBOC_CALL_REQUEST_TOPO_ORDER_OFFSET]
 mov rcx,[r12+NEBOC_CALL_REQUEST_SCRATCH_CAPACITY_OFFSET]
 rep stosq
 mov rdi,r12
 call ca_collect_functions
 test eax,eax
 jnz .analyze_done
 mov rdi,r13
 call neboc_function_table_freeze
 test eax,eax
 jnz .analyze_done
 mov rdi,r12
 call ca_resolve_calls
 test eax,eax
 jnz .analyze_done
 mov rdi,r12
 call ca_toposort
 test eax,eax
 jnz .analyze_done
 mov rdi,r12
 call ca_compute_hash
 test eax,eax
 jnz .analyze_done
 xor eax,eax
 jmp .analyze_done
.analyze_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .analyze_done
.analyze_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.analyze_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_token_ptr(request*, token_index) -> RAX or zero
ca_token_ptr:
 test rdi,rdi
 jz .token_bad
 cmp rsi,[rdi+NEBOC_CALL_REQUEST_TOKEN_COUNT_OFFSET]
 jae .token_bad
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_CALL_REQUEST_TOKENS_OFFSET]
 ret
.token_bad:
 xor eax,eax
 ret

; ca_names_equal(request*, token_a, token_b) -> EAX 1/0
ca_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call ca_token_ptr
 test rax,rax
 jz .names_no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call ca_token_ptr
 test rax,rax
 jz .names_no
 mov r15,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 mov r10,[r15+NEBOC_TOKEN_START_OFFSET]
 mov r11,[r15+NEBOC_TOKEN_END_OFFSET]
 cmp r8,r9
 ja .names_no
 cmp r10,r11
 ja .names_no
 cmp r9,[r12+NEBOC_CALL_REQUEST_SOURCE_LENGTH_OFFSET]
 ja .names_no
 cmp r11,[r12+NEBOC_CALL_REQUEST_SOURCE_LENGTH_OFFSET]
 ja .names_no
 sub r9,r8
 sub r11,r10
 cmp r9,r11
 jne .names_no
 mov rcx,r9
 mov rsi,[r12+NEBOC_CALL_REQUEST_SOURCE_OFFSET]
 add rsi,r8
 mov rdi,[r12+NEBOC_CALL_REQUEST_SOURCE_OFFSET]
 add rdi,r10
 repe cmpsb
 sete al
 movzx eax,al
 jmp .names_done
.names_no:
 xor eax,eax
.names_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_fail(request*, diagnostic_code, record_index, node_id)
ca_fail:
 mov [rdi+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_CALL_REQUEST_ERROR_RECORD_OFFSET],rdx
 mov [rdi+NEBOC_CALL_REQUEST_ERROR_NODE_ID_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; ca_signature_duplicate(request*, function_input*) -> EAX 1/0
ca_signature_duplicate:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov rbx,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 xor r14d,r14d
.duplicate_loop:
 cmp r14,[rbx+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 jae .duplicate_no
 mov rax,r14
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[rbx+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 mov [rsp],rax
 mov rdi,r12
 mov rsi,[r13+NEBOC_CALL_FUNCTION_NAME_TOKEN_OFFSET]
 mov rdx,[rax+NEBOC_FUNCTION_ENTRY_NAME_TOKEN_OFFSET]
 call ca_names_equal
 test eax,eax
 jz .duplicate_next
 mov rax,[rsp]
 mov rdx,[r13+NEBOC_CALL_FUNCTION_RECEIVER_TYPE_OFFSET]
 cmp rdx,[rax+NEBOC_FUNCTION_ENTRY_RECEIVER_TYPE_OFFSET]
 jne .duplicate_next
 mov rdx,[r13+NEBOC_CALL_FUNCTION_POSITIONAL_COUNT_OFFSET]
 cmp rdx,[rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_COUNT_OFFSET]
 jne .duplicate_next
 mov [rsp+8],rdx
 xor r15d,r15d
.duplicate_type_loop:
 cmp r15,[rsp+8]
 jae .duplicate_yes
 mov rax,[r13+NEBOC_CALL_FUNCTION_POSITIONAL_OFFSET_OFFSET]
 add rax,r15
 cmp rax,[r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPE_COUNT_OFFSET]
 jae .duplicate_no
 mov rcx,[r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPES_OFFSET]
 mov rdx,[rcx+rax*8]
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_OFFSET_OFFSET]
 add rcx,r15
 mov rax,[rbx+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET]
 cmp rdx,[rax+rcx*8]
 jne .duplicate_next
 inc r15
 jmp .duplicate_type_loop
.duplicate_yes:
 mov eax,1
 jmp .duplicate_done
.duplicate_next:
 inc r14
 jmp .duplicate_loop
.duplicate_no:
 xor eax,eax
.duplicate_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_collect_functions(request*)
ca_collect_functions:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 xor r13d,r13d
.collect_loop:
 cmp r13,[r12+NEBOC_CALL_REQUEST_FUNCTION_COUNT_OFFSET]
 jae .collect_ok
 mov rax,r13
 imul rax,NEBOC_CALL_FUNCTION_INPUT_SIZE
 add rax,[r12+NEBOC_CALL_REQUEST_FUNCTION_INPUTS_OFFSET]
 mov r14,rax
 mov rax,[r14+NEBOC_CALL_FUNCTION_FLAGS_OFFSET]
 test rax,NEBOC_CALL_FUNCTION_FLAG_NESTED
 jnz .collect_nested
 mov rdi,r12
 mov rsi,[r14+NEBOC_CALL_FUNCTION_NAME_TOKEN_OFFSET]
 call ca_token_ptr
 test rax,rax
 jz .collect_invalid
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .collect_invalid
 cmp qword [r14+NEBOC_CALL_FUNCTION_RECEIVER_TYPE_OFFSET],0
 je .collect_invalid
 cmp qword [r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET],0
 je .collect_invalid
 cmp qword [r14+NEBOC_CALL_FUNCTION_SYMBOL_ID_OFFSET],0
 je .collect_invalid
 ; Validate positional pool range.
 mov rax,[r14+NEBOC_CALL_FUNCTION_POSITIONAL_OFFSET_OFFSET]
 mov rdx,[r14+NEBOC_CALL_FUNCTION_POSITIONAL_COUNT_OFFSET]
 mov rcx,rax
 add rcx,rdx
 jc .collect_limit
 cmp rcx,[r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPE_COUNT_OFFSET]
 ja .collect_limit
 ; Infer return type from all explicit returns.
 mov rax,[r14+NEBOC_CALL_FUNCTION_RETURN_OFFSET_OFFSET]
 mov rdx,[r14+NEBOC_CALL_FUNCTION_RETURN_COUNT_OFFSET]
 mov rcx,rax
 add rcx,rdx
 jc .collect_limit
 cmp rcx,[r12+NEBOC_CALL_REQUEST_RETURN_TYPE_COUNT_OFFSET]
 ja .collect_limit
 test rdx,rdx
 jz .collect_void
 mov rcx,[r12+NEBOC_CALL_REQUEST_RETURN_TYPES_OFFSET]
 mov r15,[rcx+rax*8]
 test r15,r15
 jz .collect_invalid
 mov [rsp+72],rax
 mov rbx,1
.collect_return_loop:
 cmp rbx,rdx
 jae .collect_return_ready
 mov rax,[rsp+72]
 add rax,rbx
 mov rcx,[r12+NEBOC_CALL_REQUEST_RETURN_TYPES_OFFSET]
 cmp r15,[rcx+rax*8]
 jne .collect_inconsistent
 inc rbx
 jmp .collect_return_loop
.collect_void:
 mov r15,NEBOC_TYPE_ID_VOID
.collect_return_ready:
 cmp r15,NEBOC_TYPE_ID_VOID
 je .collect_signature
 mov rax,[r14+NEBOC_CALL_FUNCTION_FLAGS_OFFSET]
 test rax,NEBOC_CALL_FUNCTION_FLAG_MAY_FALLTHROUGH
 jnz .collect_missing_return
.collect_signature:
 mov rdi,r12
 mov rsi,r14
 call ca_signature_duplicate
 test eax,eax
 jnz .collect_duplicate
 ; Build function declaration descriptor on stack.
 mov rax,[r14+NEBOC_CALL_FUNCTION_NAME_TOKEN_OFFSET]
 mov [rsp+NEBOC_FUNCTION_DECL_NAME_TOKEN_OFFSET],rax
 mov rax,[r14+NEBOC_CALL_FUNCTION_RECEIVER_TYPE_OFFSET]
 mov [rsp+NEBOC_FUNCTION_DECL_RECEIVER_TYPE_OFFSET],rax
 mov rax,[r14+NEBOC_CALL_FUNCTION_POSITIONAL_COUNT_OFFSET]
 mov [rsp+NEBOC_FUNCTION_DECL_POSITIONAL_COUNT_OFFSET],rax
 test rax,rax
 jz .collect_no_positionals
 mov rdx,[r14+NEBOC_CALL_FUNCTION_POSITIONAL_OFFSET_OFFSET]
 mov rcx,[r12+NEBOC_CALL_REQUEST_POSITIONAL_TYPES_OFFSET]
 lea rcx,[rcx+rdx*8]
 mov [rsp+NEBOC_FUNCTION_DECL_POSITIONALS_PTR_OFFSET],rcx
 jmp .collect_positionals_ready
.collect_no_positionals:
 mov qword [rsp+NEBOC_FUNCTION_DECL_POSITIONALS_PTR_OFFSET],0
.collect_positionals_ready:
 mov [rsp+NEBOC_FUNCTION_DECL_RETURN_TYPE_OFFSET],r15
 mov rax,[r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET]
 mov [rsp+NEBOC_FUNCTION_DECL_NODE_ID_OFFSET],rax
 mov rax,[r14+NEBOC_CALL_FUNCTION_SYMBOL_ID_OFFSET]
 mov [rsp+NEBOC_FUNCTION_DECL_SYMBOL_ID_OFFSET],rax
 mov qword [rsp+NEBOC_FUNCTION_DECL_FLAGS_OFFSET],NEBOC_FUNCTION_FLAG_RETURN_INFERRED
 mov rdi,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 lea rsi,[rsp]
 lea rdx,[rsp+64]
 call neboc_function_table_append
 test eax,eax
 jnz .collect_done
 inc r13
 jmp .collect_loop
.collect_inconsistent:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_INCONSISTENT_RETURN
 lea rdx,[r13+1]
 mov rcx,[r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET]
 call ca_fail
 jmp .collect_done
.collect_missing_return:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_MISSING_RETURN
 lea rdx,[r13+1]
 mov rcx,[r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET]
 call ca_fail
 jmp .collect_done
.collect_nested:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CALL_NESTED_FUNCTION
 lea rdx,[r13+1]
 mov rcx,[r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET]
 call ca_fail
 jmp .collect_done
.collect_duplicate:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CALL_DUPLICATE_SIGNATURE
 lea rdx,[r13+1]
 mov rcx,[r14+NEBOC_CALL_FUNCTION_DECL_NODE_ID_OFFSET]
 call ca_fail
 jmp .collect_done
.collect_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .collect_done
.collect_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .collect_done
.collect_ok:
 xor eax,eax
.collect_done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_resolve_calls(request*)
ca_resolve_calls:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 xor r13d,r13d
.resolve_call_loop:
 cmp r13,[r12+NEBOC_CALL_REQUEST_CALL_COUNT_OFFSET]
 jae .resolve_ok
 mov rax,r13
 imul rax,NEBOC_CALL_INPUT_SIZE
 add rax,[r12+NEBOC_CALL_REQUEST_CALL_INPUTS_OFFSET]
 mov r14,rax
 mov rbx,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 mov rax,[r14+NEBOC_CALL_INPUT_CALLER_FUNCTION_ID_OFFSET]
 cmp rax,[rbx+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 ja .resolve_invalid
 cmp qword [r14+NEBOC_CALL_INPUT_RECEIVER_TYPE_OFFSET],0
 je .resolve_invalid
 mov rax,[r14+NEBOC_CALL_INPUT_NODE_ID_OFFSET]
 test rax,rax
 jz .resolve_invalid
 cmp rax,[r12+NEBOC_CALL_REQUEST_NODE_CAPACITY_OFFSET]
 ja .resolve_limit
 mov rdi,r12
 mov rsi,[r14+NEBOC_CALL_INPUT_NAME_TOKEN_OFFSET]
 call ca_token_ptr
 test rax,rax
 jz .resolve_invalid
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .resolve_invalid
 mov rax,[r14+NEBOC_CALL_INPUT_ARGUMENT_OFFSET_OFFSET]
 mov rdx,[r14+NEBOC_CALL_INPUT_ARGUMENT_COUNT_OFFSET]
 mov rcx,rax
 add rcx,rdx
 jc .resolve_limit
 cmp rcx,[r12+NEBOC_CALL_REQUEST_ARGUMENT_TYPE_COUNT_OFFSET]
 ja .resolve_limit
 mov qword [rsp],0       ; name seen
 mov qword [rsp+8],0     ; receiver seen
 mov qword [rsp+16],0    ; arity seen
 mov qword [rsp+24],0    ; matched FunctionId
 mov qword [rsp+32],0    ; matched entry pointer
 xor r15d,r15d
.resolve_candidate_loop:
 cmp r15,[rbx+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 jae .resolve_candidates_done
 mov rax,r15
 imul rax,NEBOC_FUNCTION_ENTRY_SIZE
 add rax,[rbx+NEBOC_FUNCTION_TABLE_DATA_OFFSET]
 mov [rsp+40],rax
 mov rdi,r12
 mov rsi,[r14+NEBOC_CALL_INPUT_NAME_TOKEN_OFFSET]
 mov rdx,[rax+NEBOC_FUNCTION_ENTRY_NAME_TOKEN_OFFSET]
 call ca_names_equal
 test eax,eax
 jz .resolve_candidate_next
 mov qword [rsp],1
 mov rax,[rsp+40]
 mov rdx,[r14+NEBOC_CALL_INPUT_RECEIVER_TYPE_OFFSET]
 cmp rdx,[rax+NEBOC_FUNCTION_ENTRY_RECEIVER_TYPE_OFFSET]
 jne .resolve_candidate_next
 mov qword [rsp+8],1
 mov rdx,[r14+NEBOC_CALL_INPUT_ARGUMENT_COUNT_OFFSET]
 cmp rdx,[rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_COUNT_OFFSET]
 jne .resolve_candidate_next
 mov qword [rsp+16],1
 xor ecx,ecx
.resolve_argument_loop:
 cmp rcx,rdx
 jae .resolve_exact
 mov r8,[r14+NEBOC_CALL_INPUT_ARGUMENT_OFFSET_OFFSET]
 add r8,rcx
 mov r9,[r12+NEBOC_CALL_REQUEST_ARGUMENT_TYPES_OFFSET]
 mov r10,[r9+r8*8]
 mov r8,[rax+NEBOC_FUNCTION_ENTRY_POSITIONAL_OFFSET_OFFSET]
 add r8,rcx
 mov r9,[rbx+NEBOC_FUNCTION_TABLE_POSITIONALS_OFFSET]
 cmp r10,[r9+r8*8]
 jne .resolve_candidate_next
 inc rcx
 jmp .resolve_argument_loop
.resolve_exact:
 cmp qword [rsp+24],0
 jne .resolve_duplicate_runtime
 mov rax,[rsp+40]
 mov rdx,[rax+NEBOC_FUNCTION_ENTRY_ID_OFFSET]
 mov [rsp+24],rdx
 mov [rsp+32],rax
.resolve_candidate_next:
 inc r15
 jmp .resolve_candidate_loop
.resolve_candidates_done:
 cmp qword [rsp+24],0
 jne .resolve_publish
 cmp qword [rsp],0
 je .resolve_undefined
 cmp qword [rsp+8],0
 je .resolve_receiver
 cmp qword [rsp+16],0
 je .resolve_arity
 jmp .resolve_argument_type
.resolve_publish:
 mov rax,[r14+NEBOC_CALL_INPUT_NODE_ID_OFFSET]
 dec rax
 mov rdx,[r12+NEBOC_CALL_REQUEST_NODE_FUNCTIONS_OFFSET]
 mov rcx,[rsp+24]
 mov [rdx+rax*8],rcx
 mov rax,[r14+NEBOC_CALL_INPUT_FLAGS_OFFSET]
 test rax,NEBOC_CALL_FLAG_BIND_RESULT
 jz .resolve_edge
 mov rax,[rsp+32]
 cmp qword [rax+NEBOC_FUNCTION_ENTRY_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_VOID
 je .resolve_void_binding
.resolve_edge:
 mov rax,[r14+NEBOC_CALL_INPUT_CALLER_FUNCTION_ID_OFFSET]
 test rax,rax
 jz .resolve_call_next
 mov rdx,[r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET]
 cmp rdx,[r12+NEBOC_CALL_REQUEST_EDGE_CAPACITY_OFFSET]
 jae .resolve_limit
 mov rcx,rdx
 imul rcx,NEBOC_CALL_EDGE_SIZE
 add rcx,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
 mov [rcx+NEBOC_CALL_EDGE_CALLER_ID_OFFSET],rax
 mov rax,[rsp+24]
 mov [rcx+NEBOC_CALL_EDGE_CALLEE_ID_OFFSET],rax
 mov rax,[r14+NEBOC_CALL_INPUT_NODE_ID_OFFSET]
 mov [rcx+NEBOC_CALL_EDGE_NODE_ID_OFFSET],rax
 inc rdx
 mov [r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET],rdx
.resolve_call_next:
 inc r13
 jmp .resolve_call_loop
.resolve_undefined:
 mov esi,NEBOC_DIAG_CALL_UNDEFINED
 jmp .resolve_fail
.resolve_receiver:
 mov esi,NEBOC_DIAG_CALL_INVALID_RECEIVER
 jmp .resolve_fail
.resolve_arity:
 mov esi,NEBOC_DIAG_CALL_ARITY
 jmp .resolve_fail
.resolve_argument_type:
 mov esi,NEBOC_DIAG_CALL_ARGUMENT_TYPE
 jmp .resolve_fail
.resolve_void_binding:
 mov esi,NEBOC_DIAG_TYPE_VOID_BINDING
 jmp .resolve_fail
.resolve_duplicate_runtime:
 mov esi,NEBOC_DIAG_CALL_DUPLICATE_SIGNATURE
.resolve_fail:
 mov rdi,r12
 lea rdx,[r13+1]
 mov rcx,[r14+NEBOC_CALL_INPUT_NODE_ID_OFFSET]
 call ca_fail
 jmp .resolve_done
.resolve_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .resolve_done
.resolve_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .resolve_done
.resolve_ok:
 xor eax,eax
.resolve_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_toposort(request*) — stable Kahn order; any cycle is recursion.
ca_toposort:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov rbx,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 mov r13,[rbx+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
 xor r14d,r14d
 ; Build indegrees.
 xor r15d,r15d
.topo_edge_degree_loop:
 cmp r15,[r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET]
 jae .topo_select_start
 mov rax,r15
 imul rax,NEBOC_CALL_EDGE_SIZE
 add rax,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
 mov rdx,[rax+NEBOC_CALL_EDGE_CALLEE_ID_OFFSET]
 test rdx,rdx
 jz .topo_invalid
 cmp rdx,r13
 ja .topo_invalid
 dec rdx
 mov rcx,[r12+NEBOC_CALL_REQUEST_INDEGREES_OFFSET]
 inc qword [rcx+rdx*8]
 inc r15
 jmp .topo_edge_degree_loop
.topo_select_start:
 cmp r14,r13
 jae .topo_ok
 xor r15d,r15d
 mov qword [rsp],0
.topo_scan:
 cmp r15,r13
 jae .topo_scan_done
 mov rax,[r12+NEBOC_CALL_REQUEST_INDEGREES_OFFSET]
 cmp qword [rax+r15*8],0
 jne .topo_scan_next
 lea rdx,[r15+1]
 mov [rsp],rdx
 mov qword [rax+r15*8],-1
 mov rcx,[r12+NEBOC_CALL_REQUEST_TOPO_ORDER_OFFSET]
 mov [rcx+r14*8],rdx
 inc r14
 jmp .topo_decrement_start
.topo_scan_next:
 inc r15
 jmp .topo_scan
.topo_scan_done:
 cmp qword [rsp],0
 je .topo_cycle
.topo_decrement_start:
 xor r15d,r15d
.topo_decrement_loop:
 cmp r15,[r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET]
 jae .topo_select_start
 mov rax,r15
 imul rax,NEBOC_CALL_EDGE_SIZE
 add rax,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
 mov rdx,[rax+NEBOC_CALL_EDGE_CALLER_ID_OFFSET]
 cmp rdx,[rsp]
 jne .topo_decrement_next
 mov rdx,[rax+NEBOC_CALL_EDGE_CALLEE_ID_OFFSET]
 dec rdx
 mov rcx,[r12+NEBOC_CALL_REQUEST_INDEGREES_OFFSET]
 cmp qword [rcx+rdx*8],-1
 je .topo_decrement_next
 dec qword [rcx+rdx*8]
.topo_decrement_next:
 inc r15
 jmp .topo_decrement_loop
.topo_cycle:
 mov rcx,0
 cmp qword [r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET],0
 je .topo_cycle_fail
 mov rax,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
 mov rcx,[rax+NEBOC_CALL_EDGE_NODE_ID_OFFSET]
.topo_cycle_fail:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CALL_RECURSION
 xor edx,edx
 call ca_fail
 jmp .topo_done
.topo_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .topo_done
.topo_ok:
 xor eax,eax
.topo_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; ca_compute_hash(request*)
ca_compute_hash:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov ebx,NEBOC_CALL_HASH_FNV1A32_OFFSET_BASIS
 mov rax,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 mov rdx,[rax+NEBOC_FUNCTION_TABLE_HASH_OFFSET]
 xor ebx,edx
 imul ebx,ebx,NEBOC_CALL_HASH_FNV1A32_PRIME
 xor r13d,r13d
 mov r14,[r12+NEBOC_CALL_REQUEST_NODE_FUNCTIONS_OFFSET]
.hash_node_loop:
 cmp r13,[r12+NEBOC_CALL_REQUEST_NODE_CAPACITY_OFFSET]
 jae .hash_edge_start
 mov rdx,[r14+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_CALL_HASH_FNV1A32_PRIME
 inc r13
 jmp .hash_node_loop
.hash_edge_start:
 xor r13d,r13d
 mov r14,[r12+NEBOC_CALL_REQUEST_EDGES_OFFSET]
.hash_edge_loop:
 cmp r13,[r12+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET]
 jae .hash_topo_start
 mov rax,r13
 imul rax,NEBOC_CALL_EDGE_SIZE
 add rax,r14
 xor ecx,ecx
.hash_edge_qword:
 cmp rcx,NEBOC_CALL_EDGE_QWORDS
 jae .hash_edge_next
 mov rdx,[rax+rcx*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_CALL_HASH_FNV1A32_PRIME
 inc rcx
 jmp .hash_edge_qword
.hash_edge_next:
 inc r13
 jmp .hash_edge_loop
.hash_topo_start:
 xor r13d,r13d
 mov r14,[r12+NEBOC_CALL_REQUEST_TOPO_ORDER_OFFSET]
 mov rax,[r12+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET]
 mov rax,[rax+NEBOC_FUNCTION_TABLE_COUNT_OFFSET]
.hash_topo_loop:
 cmp r13,rax
 jae .hash_done
 mov rdx,[r14+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_CALL_HASH_FNV1A32_PRIME
 inc r13
 jmp .hash_topo_loop
.hash_done:
 mov [r12+NEBOC_CALL_REQUEST_HASH_OFFSET],rbx
 xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
