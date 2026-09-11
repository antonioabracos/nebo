; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F03 structural bounded Result parser and evaluator.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"

extern neboc_result_layout

section .rodata
rp_n_console: db 'console'
rp_n_console_len equ $-rp_n_console
rp_n_result: db 'Result'
rp_n_result_len equ $-rp_n_result
rp_n_array: db 'Array'
rp_n_array_len equ $-rp_n_array
rp_n_int: db 'Int'
rp_n_int_len equ $-rp_n_int
rp_n_bool: db 'Bool'
rp_n_bool_len equ $-rp_n_bool
rp_n_char: db 'Char'
rp_n_char_len equ $-rp_n_char
rp_n_ok: db 'Ok'
rp_n_ok_len equ $-rp_n_ok
rp_n_err: db 'Err'
rp_n_err_len equ $-rp_n_err
rp_n_is_ok: db 'isOk'
rp_n_is_ok_len equ $-rp_n_is_ok
rp_n_is_err: db 'isErr'
rp_n_is_err_len equ $-rp_n_is_err
rp_n_get: db 'get'
rp_n_get_len equ $-rp_n_get
rp_n_get_err: db 'getErr'
rp_n_get_err_len equ $-rp_n_get_err
rp_n_map: db 'map'
rp_n_map_len equ $-rp_n_map
rp_n_map_err: db 'mapErr'
rp_n_map_err_len equ $-rp_n_map_err
rp_n_and_then: db 'andThen'
rp_n_and_then_len equ $-rp_n_and_then
rp_n_expect: db 'expect'
rp_n_expect_len equ $-rp_n_expect
rp_n_expect_err: db 'expectErr'
rp_n_expect_err_len equ $-rp_n_expect_err
rp_n_unwrap_or: db 'unwrapOr'
rp_n_unwrap_or_len equ $-rp_n_unwrap_or
rp_n_or_else: db 'orElse'
rp_n_or_else_len equ $-rp_n_or_else
rp_n_drop: db 'drop'
rp_n_drop_len equ $-rp_n_drop
rp_n_eager: db 'eager'
rp_n_eager_len equ $-rp_n_eager
rpm_n_option: db 'Option'
rpm_n_option_len equ $-rpm_n_option
rpm_n_some: db 'Some'
rpm_n_some_len equ $-rpm_n_some
rpm_n_none: db 'None'
rpm_n_none_len equ $-rpm_n_none
rpm_n_enum: db 'enum'
rpm_n_enum_len equ $-rpm_n_enum
rpm_n_wildcard: db '_'
rpm_n_wildcard_len equ $-rpm_n_wildcard
rpe_n_error: db 'Error'
rpe_n_error_len equ $-rpe_n_error
rpe_n_with_context: db 'withContext'
rpe_n_with_context_len equ $-rpe_n_with_context
rpe_n_with_cause: db 'withCause'
rpe_n_with_cause_len equ $-rpe_n_with_cause
rpe_n_format_hash: db 'formatHash'
rpe_n_format_hash_len equ $-rpe_n_format_hash
rpe_n_code: db 'code'
rpe_n_code_len equ $-rpe_n_code
rpe_n_message: db 'message'
rpe_n_message_len equ $-rpe_n_message
rpe_n_length: db 'length'
rpe_n_length_len equ $-rpe_n_length
rpe_n_cause_option: db 'cause'
rpe_n_cause_option_len equ $-rpe_n_cause_option
rpe_n_is_some: db 'isSome'
rpe_n_is_some_len equ $-rpe_n_is_some
rpe_n_to_diagnostic: db 'toDiagnostic'
rpe_n_to_diagnostic_len equ $-rpe_n_to_diagnostic
rpe_n_span: db 'Span'
rpe_n_span_len equ $-rpe_n_span
rpe_n_category: db 'category'
rpe_n_category_len equ $-rpe_n_category
rpe_n_source: db 'sourceId'
rpe_n_source_len equ $-rpe_n_source
rpe_n_span_start: db 'spanStart'
rpe_n_span_start_len equ $-rpe_n_span_start
rpe_n_span_end: db 'spanEnd'
rpe_n_span_end_len equ $-rpe_n_span_end
rpe_n_cause: db 'causeId'
rpe_n_cause_len equ $-rpe_n_cause
rpe_n_context_hash: db 'contextHash'
rpe_n_context_hash_len equ $-rpe_n_context_hash
rpe_n_propagate: db 'propagate'
rpe_n_propagate_len equ $-rpe_n_propagate
rpe_n_erase: db 'erase'
rpe_n_erase_len equ $-rpe_n_erase

section .text

rp_token_ptr:
 cmp rax,[r12+NEBOC_RESULT_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_RESULT_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX token index, RSI bytes, EDX length -> EAX boolean.
rp_token_match:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rsi
 mov r15,rdx
 call rp_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r15
 jne .no
 mov r8,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rp_peek_kind:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

%undef call
rp_error:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],rsi
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

rp_expect:
 push rbx
 mov ebx,edi
 call rp_peek_kind
 cmp eax,ebx
 jne .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 xor eax,eax
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
 call rp_error
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rp_expect_empty_call:
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
.done:
 ret

%undef call
rp_match_current:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp rp_token_match

; Claim only Result plus an F03 operation.  Constructor-only historical
; programs remain on the frozen option_result_null_externo_e_erros_tipados route.
rp_scan_marker:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 xor ebx,ebx
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp rbx,[r12+NEBOC_RESULT_TOKEN_COUNT_OFFSET]
 jae .decision
 mov rax,rbx
 call rp_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rax,rbx
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_token_match
 test eax,eax
 jz .operation
 mov r13d,1
.operation:
 mov rax,rbx
 lea rsi,[rel rp_n_is_ok]
 mov edx,rp_n_is_ok_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_is_err]
 mov edx,rp_n_is_err_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_get]
 mov edx,rp_n_get_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_get_err]
 mov edx,rp_n_get_err_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_map]
 mov edx,rp_n_map_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_map_err]
 mov edx,rp_n_map_err_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_and_then]
 mov edx,rp_n_and_then_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_expect]
 mov edx,rp_n_expect_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_expect_err]
 mov edx,rp_n_expect_err_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_unwrap_or]
 mov edx,rp_n_unwrap_or_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_or_else]
 mov edx,rp_n_or_else_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_drop]
 mov edx,rp_n_drop_len
 call rp_token_match
 test eax,eax
 jnz .mark
 jmp .next
.mark:
 mov r14d,1
.next:
 inc rbx
 jmp .loop
.decision:
 test r13d,r13d
 jz .no
 test r14d,r14d
 jz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Return RAX type, RDX size, RCX align and R8 Array length.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rp_parse_type:
 xor r8d,r8d
 lea rsi,[rel rp_n_int]
 mov edx,rp_n_int_len
 call rp_match_current
 test eax,eax
 jnz .int
 lea rsi,[rel rp_n_bool]
 mov edx,rp_n_bool_len
 call rp_match_current
 test eax,eax
 jnz .bool
 lea rsi,[rel rp_n_char]
 mov edx,rp_n_char_len
 call rp_match_current
 test eax,eax
 jnz .char
 lea rsi,[rel rp_n_array]
 mov edx,rp_n_array_len
 call rp_match_current
 test eax,eax
 jnz .array
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 ret
.int:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov eax,NEBOC_RESULT_TYPE_INT
 mov edx,8
 mov ecx,8
 ret
.bool:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov eax,NEBOC_RESULT_TYPE_BOOL
 mov edx,1
 mov ecx,1
 ret
.char:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov eax,NEBOC_RESULT_TYPE_CHAR
 mov edx,4
 mov ecx,4
 ret
.array:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call rp_expect
 test eax,eax
 jnz .bad
 lea rsi,[rel rp_n_int]
 mov edx,rp_n_int_len
 call rp_match_current
 test eax,eax
 jz .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov r8,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp r8,NEBOC_RESULT_MAX_ARRAY_LENGTH
 ja .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call rp_expect
 test eax,eax
 jnz .bad
 mov eax,NEBOC_RESULT_TYPE_ARRAY_INT
 mov rdx,r8
 imul rdx,8
 mov ecx,8
 ret
.bad:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 ret

; RDI expected scalar type -> RAX value and EDX status.
%undef call
rp_parse_scalar_value:
 push rbx
 mov ebx,edi
 call rp_peek_kind
 cmp ebx,NEBOC_RESULT_TYPE_INT
 je .int
 cmp ebx,NEBOC_RESULT_TYPE_BOOL
 je .bool
 cmp ebx,NEBOC_RESULT_TYPE_CHAR
 je .char
 jmp .bad
.int:
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .bad
 jmp .payload
.bool:
 cmp rax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp rax,NEBOC_TOKEN_KW_FALSE
 jne .bad
 xor eax,eax
 jmp .consume
.true:
 mov eax,1
 jmp .consume
.char:
 cmp rax,NEBOC_TOKEN_CHAR
 jne .bad
.payload:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
.consume:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 xor edx,edx
 pop rbx
 ret
.bad:
 xor eax,eax
 mov edx,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

; RDI expected length -> RAX deterministic value hash, EDX status.
rp_parse_array_value:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 lea rsi,[rel rp_n_array]
 mov edx,rp_n_array_len
 call rp_match_current
 test eax,eax
 jz .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call rp_expect
 test eax,eax
 jnz .bad
 lea rsi,[rel rp_n_int]
 mov edx,rp_n_int_len
 call rp_match_current
 test eax,eax
 jz .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 cmp [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],r13
 jne .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call rp_expect
 test eax,eax
 jnz .bad
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call rp_expect
 test eax,eax
 jnz .bad
 xor ebx,ebx
 mov r15,14695981039346656037
 mov r14,1099511628211
.values:
 cmp rbx,r13
 jae .end_values
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 xor r15,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 imul r15,r14
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 inc rbx
 cmp rbx,r13
 jae .end_values
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .bad
 jmp .values
.end_values:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call rp_expect
 test eax,eax
 jnz .bad
 mov rax,r15
 xor edx,edx
 jmp .done
.bad:
 xor eax,eax
 mov edx,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rp_alloc_binding:
 push rdi
 push rcx
 mov rax,[r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_BINDING_CAPACITY_OFFSET]
 jae .limit
 imul rax,NEBOC_RESULT_BIND_SIZE
 add rax,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 mov rdi,rax
 mov ecx,NEBOC_RESULT_BIND_QWORDS
 xor eax,eax
 rep stosq
 mov rax,rdi
 sub rax,NEBOC_RESULT_BIND_SIZE
 mov qword [rax+NEBOC_RESULT_BIND_NAME_OFFSET],NEBOC_RESULT_UNBOUND_NAME
 mov qword [rax+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 inc qword [r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 pop rcx
 pop rdi
 ret
.limit:
 mov esi,NEBOC_RESULT_DIAG_LAYOUT
 call rp_error
 xor eax,eax
 pop rcx
 pop rdi
 ret

%undef call
rp_find_binding:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 jae .none
 mov r14,rbx
 imul r14,NEBOC_RESULT_BIND_SIZE
 add r14,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 mov r15,[r14+NEBOC_RESULT_BIND_NAME_OFFSET]
 cmp r15,NEBOC_RESULT_UNBOUND_NAME
 je .next
 mov rax,r13
 call rp_token_ptr
 mov r8,rax
 mov rax,r15
 call rp_token_ptr
 test r8,r8
 jz .none
 test rax,rax
 jz .none
 mov rcx,[r8+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r8+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .next
 mov r9,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add r9,[r8+NEBOC_TOKEN_START_OFFSET]
 mov r10,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add r10,[rax+NEBOC_TOKEN_START_OFFSET]
 xor edx,edx
.bytes:
 cmp rdx,rcx
 jae .found
 mov al,[r9+rdx]
 cmp al,[r10+rdx]
 jne .next
 inc rdx
 jmp .bytes
.next:
 inc rbx
 jmp .loop
.found:
 mov rax,r14
 jmp .done
.none:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

rp_clone_binding:
 push rbx
 push r13
 push r14
 sub rsp,16
 mov r13,rsi
 call rp_alloc_binding
 test rax,rax
 jz .done
 mov rbx,rax
 mov rdi,rbx
 mov rsi,r13
 mov ecx,NEBOC_RESULT_BIND_QWORDS
 rep movsq
 mov qword [rbx+NEBOC_RESULT_BIND_NAME_OFFSET],NEBOC_RESULT_UNBOUND_NAME
 mov qword [rbx+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 mov rax,rbx
.done:
 add rsp,16
 pop r14
 pop r13
 pop rbx
 ret

; Parse Result<T,E>(Ok(value)|Err(value)).
rp_parse_constructor:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,168
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call rp_expect
 test eax,eax
 jnz .fail
 call rp_parse_type
 test eax,eax
 jz .payload_error
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+16],rcx
 mov [rsp+24],r8
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 call rp_parse_type
 test eax,eax
 jz .payload_error
 mov [rsp+32],rax
 mov [rsp+40],rdx
 mov [rsp+48],rcx
 mov [rsp+56],r8
 mov edi,NEBOC_TOKEN_GREATER
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel rp_n_ok]
 mov edx,rp_n_ok_len
 call rp_match_current
 test eax,eax
 jnz .ok_variant
 lea rsi,[rel rp_n_err]
 mov edx,rp_n_err_len
 call rp_match_current
 test eax,eax
 jz .variant_error
 mov qword [rsp+64],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 lea r14,[rsp+32]
 jmp .variant
.ok_variant:
 mov qword [rsp+64],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 lea r14,[rsp]
.variant:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 cmp qword [r14],NEBOC_RESULT_TYPE_ARRAY_INT
 je .array_value
 mov rdi,[r14]
 call rp_parse_scalar_value
 test edx,edx
 jnz .payload_error
 mov [rsp+72],rax
 mov [rsp+80],rax
 jmp .value_ready
.array_value:
 mov rdi,[r14+24]
 call rp_parse_array_value
 test edx,edx
 jnz .payload_error
 mov rdx,[r14+24]
 mov [rsp+72],rdx
 mov [rsp+80],rax
.value_ready:
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rdi,[rsp+88]
 mov ecx,NEBOC_RESULT_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp+8]
 mov [rsp+88+NEBOC_RESULT_LAYOUT_OK_SIZE_OFFSET],rax
 mov rax,[rsp+16]
 mov [rsp+88+NEBOC_RESULT_LAYOUT_OK_ALIGN_OFFSET],rax
 mov rax,[rsp+40]
 mov [rsp+88+NEBOC_RESULT_LAYOUT_ERR_SIZE_OFFSET],rax
 mov rax,[rsp+48]
 mov [rsp+88+NEBOC_RESULT_LAYOUT_ERR_ALIGN_OFFSET],rax
 lea rdi,[rsp+88]
 call neboc_result_layout
 test eax,eax
 jnz .layout_error
 call rp_alloc_binding
 test rax,rax
 jz .fail
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET],rax
 mov rax,[rsp+64]
 mov [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rax
 mov rax,[rsp+72]
 mov [r13+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov rax,[rsp+80]
 mov [r13+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_RESULT_BIND_OK_SIZE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_RESULT_BIND_OK_ALIGN_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_RESULT_BIND_OK_LENGTH_OFFSET],rax
 mov rax,[rsp+40]
 mov [r13+NEBOC_RESULT_BIND_ERR_SIZE_OFFSET],rax
 mov rax,[rsp+48]
 mov [r13+NEBOC_RESULT_BIND_ERR_ALIGN_OFFSET],rax
 mov rax,[rsp+56]
 mov [r13+NEBOC_RESULT_BIND_ERR_LENGTH_OFFSET],rax
 mov rax,[rsp+88+NEBOC_RESULT_LAYOUT_RESULT_SIZE_OFFSET]
 mov [r13+NEBOC_RESULT_BIND_LAYOUT_SIZE_OFFSET],rax
 mov rax,[rsp+88+NEBOC_RESULT_LAYOUT_RESULT_ALIGN_OFFSET]
 mov [r13+NEBOC_RESULT_BIND_LAYOUT_ALIGN_OFFSET],rax
 mov rax,r13
 jmp .done
.payload_error:
 mov esi,NEBOC_RESULT_DIAG_PAYLOAD
 jmp .error
.variant_error:
 mov esi,NEBOC_RESULT_DIAG_VARIANT
 jmp .error
.layout_error:
 mov esi,NEBOC_RESULT_DIAG_LAYOUT
.error:
 call rp_error
.fail:
 xor eax,eax
.done:
 add rsp,168
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

rp_parse_statement:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 xor r15d,r15d
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .owned_statement
 xor r13d,r13d
 call rp_scalar_statement
 test eax,eax
 jnz .fail
 mov r15d,1
 jmp .suffix
.owned_statement:
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jnz .constructor
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_find_binding
 test rax,rax
 jz .syntax
 mov r13,rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .suffix
.constructor:
 call rp_parse_constructor
 test rax,rax
 jz .fail
 mov r13,rax
.suffix:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .complete
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 lea rsi,[rel rp_n_console]
 mov edx,rp_n_console_len
 call rp_match_current
 test eax,eax
 jnz .console
 ; A scalar observation is a scalar; never reuse its old container receiver.
 test r15d,r15d
 jnz .syntax
 lea rsi,[rel rp_n_is_ok]
 mov edx,rp_n_is_ok_len
 call rp_match_current
 test eax,eax
 jnz .is_ok
 lea rsi,[rel rp_n_is_err]
 mov edx,rp_n_is_err_len
 call rp_match_current
 test eax,eax
 jnz .is_err
 lea rsi,[rel rp_n_get]
 mov edx,rp_n_get_len
 call rp_match_current
 test eax,eax
 jnz .get
 lea rsi,[rel rp_n_get_err]
 mov edx,rp_n_get_err_len
 call rp_match_current
 test eax,eax
 jnz .get_err
 lea rsi,[rel rp_n_map]
 mov edx,rp_n_map_len
 call rp_match_current
 test eax,eax
 jnz .map
 lea rsi,[rel rp_n_map_err]
 mov edx,rp_n_map_err_len
 call rp_match_current
 test eax,eax
 jnz .map_err
 lea rsi,[rel rp_n_and_then]
 mov edx,rp_n_and_then_len
 call rp_match_current
 test eax,eax
 jnz .and_then
 lea rsi,[rel rp_n_expect]
 mov edx,rp_n_expect_len
 call rp_match_current
 test eax,eax
 jnz .expect
 lea rsi,[rel rp_n_expect_err]
 mov edx,rp_n_expect_err_len
 call rp_match_current
 test eax,eax
 jnz .expect_err
 lea rsi,[rel rp_n_unwrap_or]
 mov edx,rp_n_unwrap_or_len
 call rp_match_current
 test eax,eax
 jnz .unwrap_or
 lea rsi,[rel rp_n_or_else]
 mov edx,rp_n_or_else_len
 call rp_match_current
 test eax,eax
 jnz .or_else
 lea rsi,[rel rp_n_drop]
 mov edx,rp_n_drop_len
 call rp_match_current
 test eax,eax
 jnz .drop
 cmp qword [r13+NEBOC_RESULT_BIND_NAME_OFFSET],NEBOC_RESULT_UNBOUND_NAME
 jne .syntax
 mov [r13+NEBOC_RESULT_BIND_NAME_OFFSET],r14
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .suffix
.check_live:
 cmp qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 ret
.is_ok:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 xor eax,eax
 cmp qword [r13+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 sete al
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.is_err:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov rax,[r13+NEBOC_RESULT_BIND_TAG_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.get:
 mov ebx,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .extract
.get_err:
 mov ebx,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 jmp .extract
.expect:
 mov ebx,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .expect_extract
.expect_err:
 mov ebx,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
.expect_extract:
 mov [rsp+16],rax
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_TEXT
 jne .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 cmp [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rbx
 jne .wrong_side
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 mov rax,[r13+NEBOC_RESULT_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.extract:
 mov [rsp+16],rax
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 cmp [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rbx
 jne .wrong_side
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 mov rax,[r13+NEBOC_RESULT_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.unwrap_or:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rdi,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 cmp rdi,NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 call rp_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rax,[rsp]
 cmp qword [r13+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jne .unwrap_ready
 mov rax,[r13+NEBOC_RESULT_BIND_VALUE_OFFSET]
.unwrap_ready:
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.map:
 mov ebx,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .transform
.map_err:
 mov ebx,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
.transform:
 mov [rsp+16],rax
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel rp_n_eager]
 mov edx,rp_n_eager_len
 call rp_match_current
 test eax,eax
 jnz .lazy
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[rsp+16]
 call rp_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rbx
 jne .suffix
 mov rax,[rsp]
 mov [r13+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.and_then:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel rp_n_eager]
 mov edx,rp_n_eager_len
 call rp_match_current
 test eax,eax
 jnz .lazy
 lea rsi,[rel rp_n_ok]
 mov edx,rp_n_ok_len
 call rp_match_current
 test eax,eax
 jnz .and_ok
 lea rsi,[rel rp_n_err]
 mov edx,rp_n_err_len
 call rp_match_current
 test eax,eax
 jz .callback_type
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 jmp .and_variant
.and_ok:
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
.and_variant:
 mov [rsp+16],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[rsp+16]
 call rp_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp qword [r13+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jne .suffix
 mov rax,[rsp+8]
 mov [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rax
 mov rax,[rsp]
 mov [r13+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.or_else:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel rp_n_eager]
 mov edx,rp_n_eager_len
 call rp_match_current
 test eax,eax
 jnz .lazy
 lea rsi,[rel rp_n_ok]
 mov edx,rp_n_ok_len
 call rp_match_current
 test eax,eax
 jnz .or_ok
 lea rsi,[rel rp_n_err]
 mov edx,rp_n_err_len
 call rp_match_current
 test eax,eax
 jz .callback_type
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 jmp .or_variant
.or_ok:
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
.or_variant:
 mov [rsp+16],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[rsp+16]
 call rp_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp qword [r13+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .suffix
 mov rax,[rsp+8]
 mov [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rax
 mov rax,[rsp]
 mov [r13+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.drop:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],0
 mov r15d,1
 jmp .suffix
.terminal_return:
 test r15d,r15d
 jz .use_after
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov qword [r12+NEBOC_RESULT_RETURNED_OFFSET],1
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .syntax
 jmp .complete
.console:
 test r15d,r15d
 jz .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 call rp_record_console
 test eax,eax
 jnz .fail
 jmp .suffix
.complete:
 test r13,r13
 jz .scalar_complete

 mov rax,[r13+NEBOC_RESULT_BIND_LAYOUT_SIZE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET]
 jbe .align
 mov [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],rax
.align:
 mov rax,[r13+NEBOC_RESULT_BIND_LAYOUT_ALIGN_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET]
 jbe .tag
 mov [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],rax
.tag:
 mov rax,[r13+NEBOC_RESULT_BIND_TAG_OFFSET]
 mov [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],rax
 xor eax,eax
 jmp .done
.scalar_complete:
 xor eax,eax
 jmp .done
.wrong_side:
 mov esi,NEBOC_RESULT_DIAG_WRONG_SIDE
 jmp .error
.use_after:
 mov esi,NEBOC_RESULT_DIAG_USE_AFTER_MOVE
 jmp .error
.callback_type:
 mov esi,NEBOC_RESULT_DIAG_CALLBACK_TYPE
 jmp .error
.lazy:
 mov esi,NEBOC_RESULT_DIAG_LAZY
 jmp .error
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
.error:
 call rp_error
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

rp_cleanup:
 push rbx
 push r13
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 jae .done
 mov r13,rbx
 imul r13,NEBOC_RESULT_BIND_SIZE
 add r13,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 cmp qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .next
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
.next:
 inc rbx
 jmp .loop
.done:
 pop r13
 pop rbx
 ret

rp_hash:
 mov rax,14695981039346656037
 mov rcx,1099511628211
 xor edx,edx
.bindings:
 cmp rdx,[r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 jae .tail
 mov r8,rdx
 imul r8,NEBOC_RESULT_BIND_SIZE
 add r8,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 xor rax,[r8+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_RESULT_BIND_TAG_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_RESULT_BIND_STATE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET]
 imul rax,rcx
 inc rdx
 jmp .bindings
.tail:
 xor rax,[r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_EARLY_RETURN_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_CLEANUP_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_CLEANUP_HASH_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_MATCH_SCRUTINEE_EVAL_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_MATCH_CLEANUP_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_ERROR_FORMAT_HASH_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET]
 imul rax,rcx
 mov rdx,NEBOC_RESULT_RETURNED_OFFSET
.effects:
 xor rax,[r12+rdx]
 imul rax,rcx
 add rdx,8
 cmp rdx,NEBOC_RESULT_AUTH_END
 jb .effects
 ret

; The canonical operator registry promotes `?` to NEBOC_TOKEN_QUESTION and
; greedily tokenizes the public `?.return` spelling as OPTIONAL_CHAIN.  Claim
; only a question-family token followed by the reserved `return` suffix, so
; ordinary optional-chain/coalescing programs remain on their own vertical.
rpp_scan_question:
 push rbx
 push r13
 sub rsp,8
 xor r13d,r13d
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .scan
 mov eax,1
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_token_match
 test eax,eax
 setnz r13b
.scan:
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_RESULT_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,rbx
 call rp_token_ptr
 test rax,rax
 jz .no
 mov r10,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r10,NEBOC_TOKEN_QUESTION
 je .candidate
 cmp r10,NEBOC_TOKEN_OPTIONAL_CHAIN
 je .candidate
 test r13d,r13d
 jz .next
 ; A receiver-first Result with `??.return` is malformed propagation, not an
 ; ordinary coalescing program; retain its frozen typed diagnostic.
 cmp r10,NEBOC_TOKEN_COALESCE
 je .candidate
 cmp r10,NEBOC_TOKEN_OPTION_ASSIGN
 jne .next
.candidate:
 mov rdx,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp byte [rdx],'?'
 jne .next
 cmp r10,NEBOC_TOKEN_OPTIONAL_CHAIN
 je .expect_return
 mov rax,rbx
 inc rax
 call rp_token_ptr
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 mov rax,rbx
 add rax,2
 jmp .check_return
.expect_return:
 mov rax,rbx
 inc rax
.check_return:
 call rp_token_ptr
 test rax,rax
 jz .next
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_RETURN
 je .yes
.next:
 inc rbx
 jmp .loop
.yes:
 mov eax,1
 add rsp,8
 pop r13
 pop rbx
 ret
.no:
 xor eax,eax
 add rsp,8
 pop r13
 pop rbx
 ret

; Compare two identifier token indices. RAX=left, RDX=right -> EAX boolean.
rpp_names_equal:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rdx
 call rp_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rbx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rbx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r15,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add r15,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rax,r14
 call rp_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rbx
 jne .no
 mov r13,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add r13,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.bytes:
 cmp rcx,rbx
 jae .yes
 mov al,[r15+rcx]
 cmp al,[r13+rcx]
 jne .no
 inc rcx
 jmp .bytes
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse Result<T,E> at the current cursor. RAX=T, RDX=E or RAX=0.
rpp_parse_result_type:
 push rbx
 push r13
 sub rsp,8
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jz .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_parse_type
 test eax,eax
 jz .bad
 mov rbx,rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_parse_type
 test eax,eax
 jz .bad
 mov r13,rax
 mov edi,NEBOC_TOKEN_GREATER
 call rp_expect
 test eax,eax
 jnz .bad
 mov rax,rbx
 mov rdx,r13
 jmp .done
.bad:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

rpp_update_layout:
 mov rdx,[rax+NEBOC_RESULT_BIND_LAYOUT_SIZE_OFFSET]
 cmp rdx,[r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET]
 jbe .align
 mov [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],rdx
.align:
 mov rdx,[rax+NEBOC_RESULT_BIND_LAYOUT_ALIGN_OFFSET]
 cmp rdx,[r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET]
 jbe .done
 mov [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],rdx
.done:
 ret

; Parse a bounded receiver-first propagation function and its one direct call.
; The receiver's Result<T,E> is the enclosing return context; the parameter's
; Result<T,E> is consumed by postfix `?`. Local Result guards form the cleanup
; ledger and are discharged in reverse declaration order before either return.
rpp_parse_program:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .context_error
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rpp_parse_result_type
 test eax,eax
 jz .syntax
 mov [r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET],rax
 mov [r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET],rdx
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_CONTEXT_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_FUNCTION_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 call rpp_parse_result_type
 test eax,eax
 jz .syntax
 mov [r12+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET],rax
 mov [r12+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET],rdx
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_VALUE_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET]
 jne .context_error
 mov rax,[r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET]
 jne .context_error
 mov qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .syntax

.body:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jnz .guard
 mov rbx,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rax,rbx
 mov rdx,[r12+NEBOC_RESULT_VALUE_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jnz .value_statement
 mov rax,rbx
 mov rdx,[r12+NEBOC_RESULT_CONTEXT_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jnz .drop_statement
 mov rax,rbx
 call rp_find_binding
 test rax,rax
 jz .context_error
 jmp .drop_statement

.guard:
 call rp_parse_constructor
 test rax,rax
 jz .done
 mov r13,rax
 call rpp_update_layout
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 push rax
 NEBOC_ABI_ALIGNED_CALL rp_find_binding
 test rax,rax
 pop rax
 jnz .syntax
 mov [r13+NEBOC_RESULT_BIND_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .syntax
 jmp .body

.drop_statement:
 mov rax,rbx
 mov rdx,[r12+NEBOC_RESULT_CONTEXT_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jz .guard_drop
 cmp qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .double_cleanup
 mov qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 jmp .parse_drop_suffix
.guard_drop:
 mov rax,rbx
 call rp_find_binding
 test rax,rax
 jz .context_error
 mov r13,rax
 cmp qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .double_cleanup
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
.parse_drop_suffix:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 lea rsi,[rel rp_n_drop]
 mov edx,rp_n_drop_len
 call rp_match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .syntax
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 jmp .body

.value_statement:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_QUESTION
 je .question_token
 cmp eax,NEBOC_TOKEN_OPTIONAL_CHAIN
 jne .syntax
 mov ebx,1
 jmp .question_spelling
.question_token:
 xor ebx,ebx
.question_spelling:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov rdx,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 add rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp byte [rdx],'?'
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_PROPAGATION_TOKEN_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],1
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 test ebx,ebx
 jnz .question_dot_consumed
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
.question_dot_consumed:
 mov edi,NEBOC_TOKEN_KW_RETURN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .syntax
 cmp qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .dropped_context
 mov rax,[r12+NEBOC_RESULT_BINDING_COUNT_OFFSET]
 mov [r12+NEBOC_RESULT_GUARD_COUNT_OFFSET],rax

 ; Reverse-scope cleanup ledger. Explicitly dropped guards are skipped, while
 ; every live guard and the enclosing receiver context are discharged once.
 mov rbx,rax
 mov r15,14695981039346656037
 mov r14,1099511628211
.cleanup_guards:
 test rbx,rbx
 jz .cleanup_context
 dec rbx
 mov r13,rbx
 imul r13,NEBOC_RESULT_BIND_SIZE
 add r13,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 cmp qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .cleanup_guards
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 inc qword [r12+NEBOC_RESULT_CLEANUP_COUNT_OFFSET]
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 xor r15,[r13+NEBOC_RESULT_BIND_NAME_OFFSET]
 imul r15,r14
 xor r15,[r13+NEBOC_RESULT_BIND_TAG_OFFSET]
 imul r15,r14
 jmp .cleanup_guards
.cleanup_context:
 mov qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 inc qword [r12+NEBOC_RESULT_CLEANUP_COUNT_OFFSET]
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 xor r15,[r12+NEBOC_RESULT_CONTEXT_NAME_OFFSET]
 imul r15,r14
 mov [r12+NEBOC_RESULT_CLEANUP_HASH_OFFSET],r15
 mov edi,NEBOC_TOKEN_RBRACE
 call rp_expect
 test eax,eax
 jnz .syntax

 ; Direct start call: Result<T,E>(...).function(Result<T,E>(...)).observer().return
 mov edi,NEBOC_TOKEN_KW_START
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_expect_empty_call
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .syntax
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jz .syntax
 call rp_parse_constructor
 test rax,rax
 jz .done
 mov r13,rax
 call rpp_update_layout
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 jne .context_error
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET]
 jne .context_error
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rdx,[r12+NEBOC_RESULT_FUNCTION_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jz .syntax
 call rp_parse_constructor
 test rax,rax
 jz .done
 mov r14,rax
 call rpp_update_layout
 mov rax,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET]
 jne .context_error
 mov rax,[r14+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET]
 jne .context_error
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
.call_suffix:
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 lea rsi,[rel rp_n_map]
 mov edx,rp_n_map_len
 call rp_match_current
 test eax,eax
 jnz .call_map
 lea rsi,[rel rp_n_map_err]
 mov edx,rp_n_map_err_len
 call rp_match_current
 test eax,eax
 jnz .call_map_err
 lea rsi,[rel rp_n_and_then]
 mov edx,rp_n_and_then_len
 call rp_match_current
 test eax,eax
 jnz .call_and_then
 lea rsi,[rel rp_n_or_else]
 mov edx,rp_n_or_else_len
 call rp_match_current
 test eax,eax
 jnz .call_or_else
 lea rsi,[rel rp_n_unwrap_or]
 mov edx,rp_n_unwrap_or_len
 call rp_match_current
 test eax,eax
 jnz .call_unwrap_or
 lea rsi,[rel rp_n_get]
 mov edx,rp_n_get_len
 call rp_match_current
 test eax,eax
 jnz .observer_get
 lea rsi,[rel rp_n_get_err]
 mov edx,rp_n_get_err_len
 call rp_match_current
 test eax,eax
 jnz .observer_get_err
 lea rsi,[rel rp_n_is_ok]
 mov edx,rp_n_is_ok_len
 call rp_match_current
 test eax,eax
 jnz .observer_is_ok
 lea rsi,[rel rp_n_is_err]
 mov edx,rp_n_is_err_len
 call rp_match_current
 test eax,eax
 jz .syntax
 mov r15d,4
 jmp .observer
.call_map:
 mov ebx,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .call_transform
.call_map_err:
 mov ebx,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r14+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
.call_transform:
 mov [rsp+16],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .context_error
 mov rdi,[rsp+16]
 call rp_parse_scalar_value
 test edx,edx
 jnz .context_error
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 cmp [r14+NEBOC_RESULT_BIND_TAG_OFFSET],rbx
 jne .call_suffix
 mov rax,[rsp]
 mov [r14+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov [r14+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 jmp .call_suffix
.call_and_then:
 mov ebx,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jmp .call_result_transform
.call_or_else:
 mov ebx,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
.call_result_transform:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 lea rsi,[rel rp_n_ok]
 mov edx,rp_n_ok_len
 call rp_match_current
 test eax,eax
 jnz .call_result_ok
 lea rsi,[rel rp_n_err]
 mov edx,rp_n_err_len
 call rp_match_current
 test eax,eax
 jz .context_error
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 mov rax,[r14+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 jmp .call_result_variant
.call_result_ok:
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 mov rax,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
.call_result_variant:
 mov [rsp+16],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 cmp qword [rsp+16],NEBOC_RESULT_TYPE_ARRAY_INT
 je .context_error
 mov rdi,[rsp+16]
 call rp_parse_scalar_value
 test edx,edx
 jnz .context_error
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 cmp [r14+NEBOC_RESULT_BIND_TAG_OFFSET],rbx
 jne .call_suffix
 mov rax,[rsp+8]
 mov [r14+NEBOC_RESULT_BIND_TAG_OFFSET],rax
 mov rax,[rsp]
 mov [r14+NEBOC_RESULT_BIND_VALUE_OFFSET],rax
 mov [r14+NEBOC_RESULT_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET]
 jmp .call_suffix
.call_unwrap_or:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov rdi,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 cmp rdi,NEBOC_RESULT_TYPE_ARRAY_INT
 je .context_error
 call rp_parse_scalar_value
 test edx,edx
 jnz .context_error
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov rax,[rsp]
 cmp qword [r14+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jne .call_unwrap_ready
 mov rax,[r14+NEBOC_RESULT_BIND_VALUE_OFFSET]
.call_unwrap_ready:
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov rax,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rax
 mov r15d,5
 jmp .observer_terminal
.observer_get: mov r15d,1
 jmp .observer
.observer_get_err: mov r15d,2
 jmp .observer
.observer_is_ok: mov r15d,3
.observer:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .syntax
.observer_terminal:
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_KW_RETURN
 call rp_expect
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .syntax
 mov edi,NEBOC_TOKEN_RBRACE
 call rp_expect
 test eax,eax
 jnz .syntax
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_EOF
 jne .syntax

 ; The parameter is moved into the returned Result. The receiver is consumed
 ; by its cleanup ledger; neither transition is a second cleanup event.
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 mov qword [r14+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 mov rax,[r14+NEBOC_RESULT_BIND_TAG_OFFSET]
 mov [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],rax
 cmp rax,NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .continued
 mov qword [r12+NEBOC_RESULT_EARLY_RETURN_OFFSET],1
.continued:
 cmp r15d,5
 je .success
 cmp r15d,1
 je .get
 cmp r15d,2
 je .get_err
 cmp r15d,3
 je .is_ok
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 xor eax,eax
 cmp qword [r14+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 sete al
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 jmp .success
.is_ok:
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 xor eax,eax
 cmp qword [r14+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 sete al
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 jmp .success
.get:
 cmp qword [r14+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jne .wrong_side
 mov rax,[r14+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .extract
.get_err:
 cmp qword [r14+NEBOC_RESULT_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 jne .wrong_side
 mov rax,[r14+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
.extract:
 cmp rax,NEBOC_RESULT_TYPE_ARRAY_INT
 je .context_error
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rax
 mov rax,[r14+NEBOC_RESULT_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
.success:
 call rp_hash
 mov [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.wrong_side:
 mov esi,NEBOC_RESULT_DIAG_WRONG_SIDE
 jmp .error
.context_error:
 mov esi,NEBOC_RESULT_DIAG_PROPAGATION_CONTEXT
 jmp .error
.dropped_context:
 mov esi,NEBOC_RESULT_DIAG_DROPPED_CONTEXT
 jmp .error
.double_cleanup:
 mov esi,NEBOC_RESULT_DIAG_DOUBLE_CLEANUP
 jmp .error
.syntax:
 mov esi,NEBOC_RESULT_DIAG_PROPAGATION_SYNTAX
.error:
 call rp_error
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F05 exhaustive structural match route.
rpm_scan_match:
 push rbx
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_RESULT_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,rbx
 call rp_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_MATCH
 jne .next
 lea rax,[rbx+1]
 call rp_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 je .yes
.next:
 inc rbx
 jmp .loop
.yes:
 mov eax,1
 pop rbx
 ret
.no:
 xor eax,eax
 pop rbx
 ret

; Current scalar literal -> RAX type, RDX value, RCX status.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rpm_parse_any_scalar:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 je .int
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp eax,NEBOC_TOKEN_KW_FALSE
 je .false
 cmp eax,NEBOC_TOKEN_CHAR
 je .char
 xor eax,eax
 xor edx,edx
 mov ecx,NEBOC_STATUS_INVALID_SOURCE
 ret
.int:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov eax,NEBOC_RESULT_TYPE_INT
 jmp .consume
.true:
 mov eax,NEBOC_RESULT_TYPE_BOOL
 mov edx,1
 jmp .consume
.false:
 mov eax,NEBOC_RESULT_TYPE_BOOL
 xor edx,edx
 jmp .consume
.char:
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov eax,NEBOC_RESULT_TYPE_CHAR
.consume:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 xor ecx,ecx
 ret

; RAX current identifier token -> RAX variant record, RDX zero-based tag.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rpm_find_variant:
 push rbx
 push r13
 push r14
 sub rsp,8
 mov r13,rax
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET]
 jae .none
 mov r14,rbx
 imul r14,NEBOC_RESULT_BIND_SIZE
 add r14,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 mov rax,r13
 mov rdx,[r14+NEBOC_RESULT_BIND_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jnz .found
 inc rbx
 jmp .loop
.found:
 mov rax,r14
 mov rdx,rbx
 jmp .done
.none:
 xor eax,eax
 mov rdx,-1
.done:
 add rsp,8
 pop r14
 pop r13
 pop rbx
 ret

; Parse `enum Name { Unit, Payload(Type), ... }` with at most five variants.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rpm_parse_enum:
 push rbx
 push r13
 push r14
 sub rsp,8
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_ENUM_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .bad
.variant:
 cmp qword [r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET],NEBOC_MATCH_MAX_VARIANTS
 jae .bad
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rbx,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rax,rbx
 call rpm_find_variant
 test rax,rax
 jnz .conflict
 call rp_alloc_binding
 test rax,rax
 jz .done
 mov r13,rax
 mov [r13+NEBOC_RESULT_BIND_NAME_OFFSET],rbx
 mov rax,[r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET]
 mov [r13+NEBOC_RESULT_BIND_TAG_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .variant_ready
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_parse_type
 test eax,eax
 jz .bad
 cmp eax,NEBOC_RESULT_TYPE_CHAR
 ja .bad
 mov [r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .bad
.variant_ready:
 inc qword [r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_COMMA
 jne .close
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .variant
.close:
 mov edi,NEBOC_TOKEN_RBRACE
 call rp_expect
 test eax,eax
 jnz .bad
 mov rcx,[r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET]
 test rcx,rcx
 jz .bad
 mov rax,1
 shl rax,cl
 dec rax
 mov [r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET],NEBOC_MATCH_CONTAINER_ENUM
 xor eax,eax
 jmp .done
.conflict:
 mov esi,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
 call rp_error
 jmp .done
.bad:
 mov esi,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
 call rp_error
.done:
 add rsp,8
 pop r14
 pop r13
 pop rbx
 ret

; Parse the scrutinee construction and `.binding;` suffix.
%undef call
rpm_parse_scrutinee:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 lea rsi,[rel rpm_n_option]
 mov edx,rpm_n_option_len
 call rp_match_current
 test eax,eax
 jnz .option
 lea rsi,[rel rp_n_result]
 mov edx,rp_n_result_len
 call rp_match_current
 test eax,eax
 jnz .result
 cmp qword [r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET],NEBOC_MATCH_CONTAINER_ENUM
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rdx,[r12+NEBOC_RESULT_MATCH_ENUM_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jz .bad
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rpm_find_variant
 test rax,rax
 jz .bad
 mov r13,rax
 mov [r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET],rdx
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 test rax,rax
 jz .enum_unit
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .bad
 mov rdi,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 call rp_parse_scalar_value
 test edx,edx
 jnz .bad
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_VALUE_OFFSET],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .bad
 jmp .suffix
.enum_unit:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .suffix
 call rp_expect_empty_call
 test eax,eax
 jnz .bad
 jmp .suffix

.option:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_parse_type
 test eax,eax
 jz .bad
 cmp eax,NEBOC_RESULT_TYPE_CHAR
 ja .bad
 mov [r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET],rax
 mov edi,NEBOC_TOKEN_GREATER
 call rp_expect
 test eax,eax
 jnz .bad
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .bad
 lea rsi,[rel rpm_n_some]
 mov edx,rpm_n_some_len
 call rp_match_current
 test eax,eax
 jnz .some
 lea rsi,[rel rpm_n_none]
 mov edx,rpm_n_none_len
 call rp_match_current
 test eax,eax
 jz .bad
 mov qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET],0
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .bad
 jmp .option_close
.some:
 mov qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET],1
 mov rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .bad
 mov rdi,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 call rp_parse_scalar_value
 test edx,edx
 jnz .bad
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_VALUE_OFFSET],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .bad
.option_close:
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .bad
 mov qword [r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET],NEBOC_MATCH_CONTAINER_OPTION
 mov qword [r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET],3
 mov qword [r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET],2
 jmp .suffix

.result:
 call rp_parse_constructor
 test rax,rax
 jz .done
 mov r13,rax
 mov qword [r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET],NEBOC_MATCH_CONTAINER_RESULT
 mov qword [r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET],3
 mov qword [r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET],2
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_RESULT_BIND_TAG_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET],rax
 cmp rax,NEBOC_OPTION_RESULT_PARSER_RESULT_TAG_OK
 jne .result_err
 mov rax,[r13+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 jmp .result_type
.result_err:
 mov rax,[r13+NEBOC_RESULT_BIND_ERR_TYPE_OFFSET]
.result_type:
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_RESULT_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_PAYLOAD_VALUE_OFFSET],rax
 mov rax,r13
 call rpp_update_layout

.suffix:
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .bad
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_BIND_NAME_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .bad
 mov qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_EVAL_OFFSET],1
 xor eax,eax
 jmp .done
.bad:
 mov esi,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
 call rp_error
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse one arm. Coverage is variant-bit based; guarded arms are deliberately
; non-covering in this profile and therefore require a later unguarded arm.
rpm_parse_arm:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 mov qword [rsp],0                 ; wildcard
 mov qword [rsp+8],0               ; guarded
 mov qword [rsp+16],-1             ; payload binding token
 mov qword [rsp+24],0              ; variant payload type
 mov qword [rsp+32],0              ; tag
 mov rax,[r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET]
 je .unreachable
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .conflict
 lea rsi,[rel rpm_n_wildcard]
 mov edx,rpm_n_wildcard_len
 call rp_match_current
 test eax,eax
 jz .specific
 mov qword [rsp],1
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .guard
.specific:
 mov rbx,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rax,[r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET]
 cmp rax,NEBOC_MATCH_CONTAINER_OPTION
 je .option_pattern
 cmp rax,NEBOC_MATCH_CONTAINER_RESULT
 je .result_pattern
 mov rax,rbx
 call rpm_find_variant
 test rax,rax
 jz .conflict
 mov [rsp+32],rdx
 mov rax,[rax+NEBOC_RESULT_BIND_OK_TYPE_OFFSET]
 mov [rsp+24],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .payload_pattern
.option_pattern:
 lea rsi,[rel rpm_n_none]
 mov edx,rpm_n_none_len
 call rp_match_current
 test eax,eax
 jnz .option_none
 lea rsi,[rel rpm_n_some]
 mov edx,rpm_n_some_len
 call rp_match_current
 test eax,eax
 jz .conflict
 mov qword [rsp+32],1
 mov rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 mov [rsp+24],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .payload_pattern
.option_none:
 mov qword [rsp+32],0
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .unit_pattern
.result_pattern:
 lea rsi,[rel rp_n_ok]
 mov edx,rp_n_ok_len
 call rp_match_current
 test eax,eax
 jnz .result_ok
 lea rsi,[rel rp_n_err]
 mov edx,rp_n_err_len
 call rp_match_current
 test eax,eax
 jz .conflict
 mov qword [rsp+32],1
 mov rax,[r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET]
 mov [rsp+24],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .payload_pattern
.result_ok:
 mov qword [rsp+32],0
 mov rax,[r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET]
 mov [rsp+24],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
.payload_pattern:
 cmp qword [rsp+24],0
 je .unit_pattern
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .conflict
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .conflict
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov [rsp+16],rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .conflict
 jmp .guard
.unit_pattern:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .guard
 call rp_expect_empty_call
 test eax,eax
 jnz .conflict
.guard:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_KW_WHEN
 jne .arrow
 mov qword [rsp+8],1
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .guard_consume
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .conflict
.guard_consume:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
.arrow:
 mov edi,NEBOC_TOKEN_RESERVED_ARROW
 call rp_expect
 test eax,eax
 jnz .conflict

 ; Arm result is one scalar literal or its own payload binding.
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .literal
 cmp qword [rsp+16],-1
 je .conflict
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rdx,[rsp+16]
 call rpp_names_equal
 test eax,eax
 jz .conflict
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov r13,[rsp+24]
 mov r14,[r12+NEBOC_RESULT_MATCH_PAYLOAD_VALUE_OFFSET]
 jmp .expression_ready
.literal:
 call rpm_parse_any_scalar
 test ecx,ecx
 jnz .conflict
 mov r13,rax
 mov r14,rdx
.expression_ready:
 mov edi,NEBOC_TOKEN_DOT
 call rp_expect
 test eax,eax
 jnz .conflict
 mov edi,NEBOC_TOKEN_KW_RETURN
 call rp_expect
 test eax,eax
 jnz .conflict
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .conflict
 mov rax,[r12+NEBOC_RESULT_MATCH_OUTPUT_TYPE_OFFSET]
 test rax,rax
 jz .first_type
 cmp rax,r13
 jne .conflict
 jmp .coverage
.first_type:
 mov [r12+NEBOC_RESULT_MATCH_OUTPUT_TYPE_OFFSET],r13
.coverage:
 cmp qword [rsp+8],0
 jne .arm_done
 cmp qword [rsp],0
 je .specific_coverage
 mov rax,[r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET],rax
 jmp .select
.specific_coverage:
 mov rcx,[rsp+32]
 mov rax,1
 shl rax,cl
 test [r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET],rax
 jnz .unreachable
 or [r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET],rax
.select:
 cmp qword [r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET],-1
 jne .arm_done
 cmp qword [rsp],0
 jne .selected
 mov rax,[rsp+32]
 cmp rax,[r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET]
 jne .arm_done
.selected:
 mov rax,[r12+NEBOC_RESULT_MATCH_ARM_COUNT_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET],rax
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],r13
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],r14
.arm_done:
 inc qword [r12+NEBOC_RESULT_MATCH_ARM_COUNT_OFFSET]
 cmp qword [r12+NEBOC_RESULT_MATCH_ARM_COUNT_OFFSET],NEBOC_MATCH_MAX_ARMS
 ja .conflict
 xor eax,eax
 jmp .done
.unreachable:
 mov esi,NEBOC_RESULT_DIAG_UNREACHABLE_ARM
 jmp .error
.conflict:
 mov esi,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
.error:
 call rp_error
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

rpm_parse_program:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_KW_ENUM
 jne .start
 call rpm_parse_enum
 test eax,eax
 jnz .done
.start:
 mov edi,NEBOC_TOKEN_KW_START
 call rp_expect
 test eax,eax
 jnz .conflict
 call rp_expect_empty_call
 test eax,eax
 jnz .conflict
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .conflict
 call rpm_parse_scrutinee
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_MATCH
 call rp_expect
 test eax,eax
 jnz .conflict
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .conflict
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .conflict
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rdx,[r12+NEBOC_RESULT_MATCH_BIND_NAME_OFFSET]
 call rpp_names_equal
 test eax,eax
 jz .conflict
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .conflict
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .conflict
.arms:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_RBRACE
 je .close_match
 call rpm_parse_arm
 test eax,eax
 jnz .done
 jmp .arms
.close_match:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov rax,[r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET]
 jne .non_exhaustive
 cmp qword [r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET],-1
 je .non_exhaustive
 mov edi,NEBOC_TOKEN_RBRACE
 call rp_expect
 test eax,eax
 jnz .conflict
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_EOF
 jne .conflict
 mov qword [r12+NEBOC_RESULT_MATCH_COUNT_OFFSET],1
 mov qword [r12+NEBOC_RESULT_MATCH_CLEANUP_COUNT_OFFSET],1
 cmp qword [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],8
 jae .layout_ready
 mov qword [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],16
 mov qword [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],8
.layout_ready:
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 mov [r12+NEBOC_RESULT_MATCH_OUTPUT_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 call rp_hash
 mov [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.non_exhaustive:
 mov esi,NEBOC_RESULT_DIAG_NON_EXHAUSTIVE
 jmp .error
.conflict:
 mov esi,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
.error:
 call rp_error
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F06 claims Error only when a bounded structured-error operation is
; also present. This avoids stealing historical identifiers named Error.
rpe_scan_error:
 push rbx
 push r13
 push r14
 xor ebx,ebx
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp rbx,[r12+NEBOC_RESULT_TOKEN_COUNT_OFFSET]
 jae .decision
 mov rax,rbx
 lea rsi,[rel rpe_n_error]
 mov edx,rpe_n_error_len
 call rp_token_match
 test eax,eax
 jz .operations
 mov r13d,1
.operations:
 mov rax,rbx
 lea rsi,[rel rpe_n_with_context]
 mov edx,rpe_n_with_context_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_with_cause]
 mov edx,rpe_n_with_cause_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_format_hash]
 mov edx,rpe_n_format_hash_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_code]
 mov edx,rpe_n_code_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_message]
 mov edx,rpe_n_message_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_cause_option]
 mov edx,rpe_n_cause_option_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_to_diagnostic]
 mov edx,rpe_n_to_diagnostic_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_category]
 mov edx,rpe_n_category_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_source]
 mov edx,rpe_n_source_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_span_start]
 mov edx,rpe_n_span_start_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_span_end]
 mov edx,rpe_n_span_end_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_cause]
 mov edx,rpe_n_cause_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_context_hash]
 mov edx,rpe_n_context_hash_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_propagate]
 mov edx,rpe_n_propagate_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rp_n_drop]
 mov edx,rp_n_drop_len
 call rp_token_match
 test eax,eax
 jnz .mark
 mov rax,rbx
 lea rsi,[rel rpe_n_erase]
 mov edx,rpe_n_erase_len
 call rp_token_match
 test eax,eax
 jnz .mark
 jmp .next
.mark:
 mov r14d,1
.next:
 inc rbx
 jmp .loop
.decision:
 mov eax,r13d
 and eax,r14d
 pop r14
 pop r13
 pop rbx
 ret

; Error(code:u32, category:u16, source:u64, span_start:u64,
;       span_end:u64, cause_id:u64). Message storage is deliberately absent
; from the A0 constructor; its pointer and length are canonical zeroes.
rpe_parse_constructor:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,56
 cmp qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET],NEBOC_ERROR_MAX_BINDINGS
 jae .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+8],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+16],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+24],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+32],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+40],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 cmp qword [rsp],0
 je .invariant
 mov rax,[rsp]
 shr rax,32
 jnz .invariant
 mov rax,[rsp+8]
 shr rax,16
 jnz .invariant
 mov rax,[rsp+24]
 cmp rax,[rsp+32]
 ja .invariant
 call rp_alloc_binding
 test rax,rax
 jz .invariant
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_ERROR_BIND_CODE_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_ERROR_BIND_CATEGORY_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_ERROR_BIND_SOURCE_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_ERROR_BIND_SPAN_START_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_ERROR_BIND_SPAN_END_OFFSET],rax
 mov rax,[rsp+40]
 mov [r13+NEBOC_ERROR_BIND_CAUSE_OFFSET],rax
 mov qword [r13+NEBOC_ERROR_BIND_CONTEXT_HASH_OFFSET],0
 mov qword [r13+NEBOC_ERROR_BIND_CONTEXT_COUNT_OFFSET],0
 mov qword [r13+NEBOC_ERROR_BIND_CAUSE_DEPTH_OFFSET],0
 mov qword [r13+NEBOC_ERROR_BIND_MESSAGE_LENGTH_OFFSET],0
 mov qword [r13+NEBOC_RESULT_BIND_LAYOUT_SIZE_OFFSET],NEBOC_ERROR_LAYOUT_SIZE
 mov qword [r13+NEBOC_RESULT_BIND_LAYOUT_ALIGN_OFFSET],NEBOC_ERROR_LAYOUT_ALIGN
 inc qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 mov rax,r13
 jmp .done
.invariant:
 mov esi,NEBOC_RESULT_DIAG_ERROR_INVARIANT
 call rp_error
.fail:
 xor eax,eax
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

rpe_parse_statement:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 xor r15d,r15d
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .owned_statement
 xor r13d,r13d
 call rp_scalar_statement
 test eax,eax
 jnz .fail
 mov r15d,1
 jmp .suffix
.owned_statement:
 lea rsi,[rel rpe_n_error]
 mov edx,rpe_n_error_len
 call rp_match_current
 test eax,eax
 jnz .constructor
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_find_binding
 test rax,rax
 jz .syntax
 mov r13,rax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .suffix
.constructor:
 call rpe_parse_constructor
 test rax,rax
 jz .fail
 mov r13,rax
.suffix:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .complete
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 lea rsi,[rel rp_n_console]
 mov edx,rp_n_console_len
 call rp_match_current
 test eax,eax
 jnz .console
 ; A scalar observation is a scalar; never reuse its old container receiver.
 cmp r15d,1
 je .syntax
 lea rsi,[rel rpe_n_with_context]
 mov edx,rpe_n_with_context_len
 call rp_match_current
 test eax,eax
 jnz .with_context
 lea rsi,[rel rpe_n_with_cause]
 mov edx,rpe_n_with_cause_len
 call rp_match_current
 test eax,eax
 jnz .with_cause
 lea rsi,[rel rpe_n_format_hash]
 mov edx,rpe_n_format_hash_len
 call rp_match_current
 test eax,eax
 jnz .format_hash
 lea rsi,[rel rpe_n_code]
 mov edx,rpe_n_code_len
 call rp_match_current
 test eax,eax
 jnz .observe_code
 lea rsi,[rel rpe_n_message]
 mov edx,rpe_n_message_len
 call rp_match_current
 test eax,eax
 jnz .message
 lea rsi,[rel rpe_n_cause_option]
 mov edx,rpe_n_cause_option_len
 call rp_match_current
 test eax,eax
 jnz .cause_option
 lea rsi,[rel rpe_n_is_some]
 mov edx,rpe_n_is_some_len
 call rp_match_current
 test eax,eax
 jnz .cause_is_some
 lea rsi,[rel rpe_n_to_diagnostic]
 mov edx,rpe_n_to_diagnostic_len
 call rp_match_current
 test eax,eax
 jnz .to_diagnostic
 lea rsi,[rel rpe_n_length]
 mov edx,rpe_n_length_len
 call rp_match_current
 test eax,eax
 jnz .message_length
 lea rsi,[rel rpe_n_category]
 mov edx,rpe_n_category_len
 call rp_match_current
 test eax,eax
 jnz .observe_category
 lea rsi,[rel rpe_n_source]
 mov edx,rpe_n_source_len
 call rp_match_current
 test eax,eax
 jnz .observe_source
 lea rsi,[rel rpe_n_span_start]
 mov edx,rpe_n_span_start_len
 call rp_match_current
 test eax,eax
 jnz .observe_span_start
 lea rsi,[rel rpe_n_span_end]
 mov edx,rpe_n_span_end_len
 call rp_match_current
 test eax,eax
 jnz .observe_span_end
 lea rsi,[rel rpe_n_cause]
 mov edx,rpe_n_cause_len
 call rp_match_current
 test eax,eax
 jnz .observe_cause
 lea rsi,[rel rpe_n_context_hash]
 mov edx,rpe_n_context_hash_len
 call rp_match_current
 test eax,eax
 jnz .observe_context
 lea rsi,[rel rpe_n_propagate]
 mov edx,rpe_n_propagate_len
 call rp_match_current
 test eax,eax
 jnz .observe_code
 lea rsi,[rel rp_n_drop]
 mov edx,rp_n_drop_len
 call rp_match_current
 test eax,eax
 jnz .drop
 lea rsi,[rel rpe_n_erase]
 mov edx,rpe_n_erase_len
 call rp_match_current
 test eax,eax
 jnz .erasure
 cmp qword [r13+NEBOC_RESULT_BIND_NAME_OFFSET],NEBOC_RESULT_UNBOUND_NAME
 jne .syntax
 mov [r13+NEBOC_RESULT_BIND_NAME_OFFSET],r14
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .suffix
.check_live:
 cmp qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 ret
.with_context:
 call .check_live
 jne .invariant
 cmp qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET],NEBOC_ERROR_MAX_BINDINGS
 jae .invariant
 cmp qword [r13+NEBOC_ERROR_BIND_CONTEXT_COUNT_OFFSET],NEBOC_ERROR_MAX_CONTEXT
 jae .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_TEXT
 jne .context_integer
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp],rdx
 mov eax,edx
 mov [rsp+24],rax
 mov qword [rsp+32],1
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 jmp .context_ready
.context_integer:
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp],rax
 mov qword [rsp+24],0
 mov qword [rsp+32],0
.context_ready:
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .invariant
 mov r13,rax
 inc qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 mov rax,[r13+NEBOC_ERROR_BIND_CONTEXT_HASH_OFFSET]
 test rax,rax
 jnz .context_seeded
 mov rax,14695981039346656037
.context_seeded:
 xor rax,[rsp]
 mov rcx,1099511628211
 imul rax,rcx
 mov [r13+NEBOC_ERROR_BIND_CONTEXT_HASH_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_ERROR_BIND_MESSAGE_LENGTH_OFFSET],rax
 mov rax,[rsp]
 mov [r13+NEBOC_ERROR_BIND_CONTEXT_LITERAL_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_ERROR_BIND_CONTEXT_TEXT_OFFSET],rax
 inc qword [r13+NEBOC_ERROR_BIND_CONTEXT_COUNT_OFFSET]
 mov rax,[r13+NEBOC_ERROR_BIND_CONTEXT_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET]
 jbe .suffix
 mov [r12+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET],rax
 jmp .suffix
.with_cause:
 call .check_live
 jne .invariant
 cmp qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET],NEBOC_ERROR_MAX_BINDINGS
 jae .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .invariant
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_find_binding
 test rax,rax
 jz .invariant
 mov [rsp+8],rax
 cmp rax,r13
 je .invariant
 cmp qword [rax+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_LIVE
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rbx,[rsp+8]
 mov rax,[rbx+NEBOC_ERROR_BIND_CODE_OFFSET]
 cmp rax,[r13+NEBOC_ERROR_BIND_CODE_OFFSET]
 je .invariant
 cmp rax,[r13+NEBOC_ERROR_BIND_CAUSE_OFFSET]
 je .invariant
 mov rdx,[r13+NEBOC_ERROR_BIND_CODE_OFFSET]
 cmp rdx,[rbx+NEBOC_ERROR_BIND_CAUSE_OFFSET]
 je .invariant
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .invariant
 mov r13,rax
 inc qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 mov rax,[rbx+NEBOC_ERROR_BIND_CODE_OFFSET]
 mov [r13+NEBOC_ERROR_BIND_CAUSE_OFFSET],rax
 mov rax,[rbx+NEBOC_ERROR_BIND_CAUSE_DEPTH_OFFSET]
 inc rax
 cmp rax,NEBOC_ERROR_MAX_BINDINGS
 ja .invariant
 mov [r13+NEBOC_ERROR_BIND_CAUSE_DEPTH_OFFSET],rax
 cmp rax,[r12+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET]
 jbe .suffix
 mov [r12+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET],rax
 jmp .suffix
.message:
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov rax,[r13+NEBOC_ERROR_BIND_CATEGORY_OFFSET]
 cmp rax,1
 je .message_filesystem
 cmp rax,2
 je .message_process
 cmp rax,3
 je .message_network
 cmp rax,4
 je .message_http
 mov eax,5                         ; "error"
 jmp .message_context
.message_filesystem:
 mov eax,10                        ; "filesystem"
 jmp .message_context
.message_process:
 mov eax,7                         ; "process"
 jmp .message_context
.message_network:
 mov eax,7                         ; "network"
 jmp .message_context
.message_http:
 mov eax,4                         ; "http"
.message_context:
 mov rdx,[r13+NEBOC_ERROR_BIND_MESSAGE_LENGTH_OFFSET]
 test rdx,rdx
 jz .message_ready
 add rax,2                         ; canonical ": " separator
 add rax,rdx
.message_ready:
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_TEXT
 mov r15d,2                        ; Text value awaiting an observable
 jmp .suffix
.message_length:
 cmp r15d,2
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov r15d,1
 jmp .suffix
.cause_option:
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 xor eax,eax
 cmp qword [r13+NEBOC_ERROR_BIND_CAUSE_OFFSET],0
 setne al
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_OPTION_ERROR
 mov r15d,3                        ; Option<Error> awaiting an observer
 jmp .suffix
.cause_is_some:
 cmp r15d,3
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.to_diagnostic:
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel rpe_n_span]
 mov edx,rpe_n_span_len
 call rp_match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_COMMA
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_RESULT_TYPE_INT
 call rp_parse_scalar_value
 test edx,edx
 jnz .invariant
 mov [rsp+8],rax
 mov rdx,[rsp]
 cmp rdx,rax
 ja .invariant
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call rp_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call rp_clone_binding
 test rax,rax
 jz .invariant
 mov r13,rax
 inc qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET]
 mov rax,[rsp]
 mov [r13+NEBOC_ERROR_BIND_SPAN_START_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_ERROR_BIND_SPAN_END_OFFSET],rax
 jmp .suffix
.format_hash:
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov rax,14695981039346656037
 mov rcx,1099511628211
 xor rax,[r13+NEBOC_ERROR_BIND_CODE_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_CATEGORY_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_SOURCE_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_SPAN_START_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_SPAN_END_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_CAUSE_OFFSET]
 imul rax,rcx
 xor rax,[r13+NEBOC_ERROR_BIND_CONTEXT_HASH_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_RESULT_ERROR_FORMAT_HASH_OFFSET],rax
 and eax,127
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 jmp .observed
.observe_code:
 mov rax,[r13+NEBOC_ERROR_BIND_CODE_OFFSET]
 jmp .observe
.observe_category:
 mov rax,[r13+NEBOC_ERROR_BIND_CATEGORY_OFFSET]
 jmp .observe
.observe_source:
 mov rax,[r13+NEBOC_ERROR_BIND_SOURCE_OFFSET]
 jmp .observe
.observe_span_start:
 mov rax,[r13+NEBOC_ERROR_BIND_SPAN_START_OFFSET]
 jmp .observe
.observe_span_end:
 mov rax,[r13+NEBOC_ERROR_BIND_SPAN_END_OFFSET]
 jmp .observe
.observe_cause:
 mov rax,[r13+NEBOC_ERROR_BIND_CAUSE_OFFSET]
 jmp .observe
.observe_context:
 mov rax,[r13+NEBOC_ERROR_BIND_CONTEXT_HASH_OFFSET]
.observe:
 mov [rsp+16],rax
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov rax,[rsp+16]
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
.observed:
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov r15d,1
 jmp .suffix
.drop:
 call .check_live
 jne .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [r13+NEBOC_RESULT_BIND_STATE_OFFSET],NEBOC_RESULT_STATE_DROPPED
 inc qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET]
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],0
 mov r15d,1
 jmp .suffix
.terminal_return:
 test r15d,r15d
 jz .invariant
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 mov qword [r12+NEBOC_RESULT_RETURNED_OFFSET],1
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .syntax
 jmp .complete
.console:
 test r15d,r15d
 jz .syntax
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_expect_empty_call
 test eax,eax
 jnz .fail
 call rp_record_console
 test eax,eax
 jnz .fail
 ; Publishing consumes the temporary Text observation; implicit start has
 ; the same zero result as the general Console effect path.
 cmp r15d,2
 jne .suffix
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],NEBOC_RESULT_TYPE_INT
 mov qword [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],0
 mov r15d,1
 jmp .suffix
.complete:
 test r13,r13
 jz .scalar_complete

 mov qword [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],NEBOC_ERROR_LAYOUT_SIZE
 mov qword [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],NEBOC_ERROR_LAYOUT_ALIGN
 mov qword [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],NEBOC_OPTION_RESULT_PLAN_RESULT_TAG_ERR
 xor eax,eax
 jmp .done
.scalar_complete:
 xor eax,eax
 jmp .done
.erasure:
 mov esi,NEBOC_RESULT_DIAG_ERROR_ERASURE
 jmp .error
.invariant:
 mov esi,NEBOC_RESULT_DIAG_ERROR_INVARIANT
 jmp .error
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
.error:
 call rp_error
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rpe_parse_program:
 mov edi,NEBOC_TOKEN_KW_START
 call rp_expect
 test eax,eax
 jnz .done
 call rp_expect_empty_call
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .done
.statements:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_RBRACE
 je .close
 cmp qword [r12+NEBOC_RESULT_RETURNED_OFFSET],0
 jne .syntax
 call rpe_parse_statement
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .done
 jmp .statements
.close:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_EOF
 jne .syntax
 cmp qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET],0
 je .invariant
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 cmp rax,NEBOC_RESULT_TYPE_INT
 je .output_ready
 cmp rax,NEBOC_RESULT_TYPE_BOOL
 jne .invariant
.output_ready:
 call rp_cleanup
 call rp_hash
 mov [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 ret
.invariant:
 mov esi,NEBOC_RESULT_DIAG_ERROR_INVARIANT
 jmp .error
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
.error:
 call rp_error
.done:
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_result_recognize
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 lea rdi,[r12+NEBOC_RESULT_RETURNED_OFFSET]
 mov ecx,(NEBOC_RESULT_AUTH_END-NEBOC_RESULT_RETURNED_OFFSET)/8
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_RESULT_FOUND_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CURSOR_OFFSET],0
 mov qword [r12+NEBOC_RESULT_BINDING_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_LAYOUT_SIZE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_LAYOUT_ALIGN_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CALLBACK_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_DROP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ACTIVE_TAG_OFFSET],0
 mov qword [r12+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_EARLY_RETURN_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CLEANUP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CLEANUP_HASH_OFFSET],0
 mov qword [r12+NEBOC_RESULT_FUNCTION_NAME_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CONTEXT_NAME_OFFSET],0
 mov qword [r12+NEBOC_RESULT_VALUE_NAME_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CONTEXT_OK_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CONTEXT_ERR_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_VALUE_OK_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_VALUE_ERR_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_CONTEXT_STATE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_PROPAGATION_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_RESULT_GUARD_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_COVERAGE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_FULL_MASK_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_SELECTED_ARM_OFFSET],-1
 mov qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_EVAL_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_CLEANUP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_CONTAINER_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_ARM_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_VARIANT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_ENUM_NAME_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_SCRUTINEE_TAG_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_PAYLOAD_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_PAYLOAD_VALUE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_BIND_NAME_OFFSET],0
 mov qword [r12+NEBOC_RESULT_MATCH_OUTPUT_TYPE_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ERROR_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ERROR_CONTEXT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ERROR_FORMAT_HASH_OFFSET],0
 mov qword [r12+NEBOC_RESULT_ERROR_CAUSE_DEPTH_OFFSET],0
 mov rax,[r12+NEBOC_RESULT_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_RESULT_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_RESULT_BINDINGS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_RESULT_BINDING_CAPACITY_OFFSET],1
 jb .invalid
 call rpp_scan_question
 test eax,eax
 jz .legacy
 mov qword [r12+NEBOC_RESULT_FOUND_OFFSET],1
 call rpp_parse_program
 jmp .done
.legacy:
 call rpm_scan_match
 test eax,eax
 jz .error_core
 mov qword [r12+NEBOC_RESULT_FOUND_OFFSET],1
 call rpm_parse_program
 jmp .done
.error_core:
 call rpe_scan_error
 test eax,eax
 jz .legacy_result
 mov qword [r12+NEBOC_RESULT_FOUND_OFFSET],1
 call rpe_parse_program
 jmp .done
.legacy_result:
 call rp_scan_marker
 test eax,eax
 jz .not_owned
 mov qword [r12+NEBOC_RESULT_FOUND_OFFSET],1
 mov edi,NEBOC_TOKEN_KW_START
 call rp_expect
 test eax,eax
 jnz .done
 call rp_expect_empty_call
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call rp_expect
 test eax,eax
 jnz .done
.statements:
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_RBRACE
 je .close
 cmp qword [r12+NEBOC_RESULT_RETURNED_OFFSET],0
 jne .syntax
 call rp_parse_statement
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call rp_expect
 test eax,eax
 jnz .done
 jmp .statements
.close:
 inc qword [r12+NEBOC_RESULT_CURSOR_OFFSET]
 call rp_peek_kind
 cmp eax,NEBOC_TOKEN_EOF
 jne .syntax
 call rp_cleanup
 call rp_hash
 mov [r12+NEBOC_RESULT_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
 call rp_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT


; The same native scalar parser used for container payloads also owns an
; independent scalar statement. Container values/layouts remain untouched.
%undef call
rp_scalar_statement:
 push rbx
 call rp_peek_kind
 mov ebx,NEBOC_RESULT_TYPE_INT
 cmp eax,NEBOC_TOKEN_INTEGER
 je .literal
 mov ebx,NEBOC_RESULT_TYPE_CHAR
 cmp eax,NEBOC_TOKEN_CHAR
 je .literal
 mov ebx,NEBOC_RESULT_TYPE_BOOL
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .literal
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .syntax
.literal:
 mov edi,ebx
 call rp_parse_scalar_value
 test edx,edx
 jnz .syntax
 mov [r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET],rax
 mov [r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET],rbx
 xor eax,eax
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
 call rp_error
 pop rbx
 ret

; A typed scalar effect is recorded at its exact source call interval.
rp_record_console:
 push rbx
 mov rax,[r12+NEBOC_RESULT_OUTPUT_TYPE_OFFSET]
 cmp rax,NEBOC_RESULT_TYPE_INT
 je .typed
 cmp rax,NEBOC_RESULT_TYPE_BOOL
 je .typed
 cmp rax,NEBOC_RESULT_TYPE_TEXT
 jne .syntax
.typed:
 mov rbx,[r12+NEBOC_RESULT_EFFECT_COUNT_OFFSET]
 cmp rbx,32
 jae .limit
 shl rbx,5
 lea rbx,[r12+rbx+NEBOC_RESULT_EFFECTS_OFFSET]
 mov [rbx],rax
 mov rax,[r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET]
 cmp qword [rbx],NEBOC_RESULT_TYPE_TEXT
 jne .value_ready
 call rpe_materialize_message
 test edx,edx
 jnz .limit
.value_ready:
 mov [rbx+8],rax
 mov rax,r14
 call rp_token_ptr
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+16],rax
 mov rax,[r12+NEBOC_RESULT_CURSOR_OFFSET]
 dec rax
 call rp_token_ptr
 mov rax,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+24],rax
 inc qword [r12+NEBOC_RESULT_EFFECT_COUNT_OFFSET]
 xor eax,eax
 pop rbx
 ret
.limit:
 mov esi,NEBOC_RESULT_DIAG_LAYOUT
 call rp_error
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_RESULT_DIAG_SYNTAX
 call rp_error
 pop rbx
 ret


; Fold the native Error message into an owned typed Text constant. Lexer bytes
; are copied, never inferred from a token hash. The plan remains pointerless.
; r12=request, r13=live Error; rax=packed length:pool-offset, edx=status.
rpe_materialize_message:
 push rbx
 push r14
 push r15
 test r13,r13
 jz .bad
 mov r14,[r12+NEBOC_RESULT_TEXT_USED_OFFSET]
 mov r15,[r12+NEBOC_RESULT_OUTPUT_VALUE_OFFSET]
 mov rax,r14
 add rax,r15
 jc .bad
 cmp rax,NEBOC_RESULT_TEXT_CAPACITY
 ja .bad
 lea rdi,[r12+r14+NEBOC_RESULT_TEXT_BYTES_OFFSET]
 mov rax,[r13+NEBOC_ERROR_BIND_CATEGORY_OFFSET]
 lea rsi,[rel rpe_message_error]
 mov ecx,5
 cmp rax,1
 jne .process
 lea rsi,[rel rpe_message_filesystem]
 mov ecx,10
 jmp .base
.process:
 cmp rax,2
 jne .network
 lea rsi,[rel rpe_message_process]
 mov ecx,7
 jmp .base
.network:
 cmp rax,3
 jne .http
 lea rsi,[rel rpe_message_network]
 mov ecx,7
 jmp .base
.http:
 cmp rax,4
 jne .base
 lea rsi,[rel rpe_message_http]
 mov ecx,4
.base:
 rep movsb
 mov rcx,[r13+NEBOC_ERROR_BIND_MESSAGE_LENGTH_OFFSET]
 test rcx,rcx
 jz .ready
 cmp qword [r13+NEBOC_ERROR_BIND_CONTEXT_TEXT_OFFSET],1
 jne .bad
 mov rdx,[r13+NEBOC_ERROR_BIND_CONTEXT_LITERAL_OFFSET]
 mov eax,edx
 cmp rax,rcx
 jne .bad
 shr rdx,32
 add rax,rdx
 jc .bad
 cmp rax,[r12+NEBOC_RESULT_LITERAL_LENGTH_OFFSET]
 ja .bad
 mov rsi,[r12+NEBOC_RESULT_LITERAL_BYTES_OFFSET]
 test rsi,rsi
 jz .bad
 add rsi,rdx
 mov word [rdi],0x203a
 add rdi,2
 rep movsb
.ready:
 mov rax,r14
 add rax,r15
 mov [r12+NEBOC_RESULT_TEXT_USED_OFFSET],rax
 mov rax,r15
 shl rax,32
 or rax,r14
 xor edx,edx
 jmp .done
.bad:
 mov edx,1
.done:
 pop r15
 pop r14
 pop rbx
 ret

section .rodata
rpe_message_error: db 'error'
rpe_message_filesystem: db 'filesystem'
rpe_message_process: db 'process'
rpe_message_network: db 'network'
rpe_message_http: db 'http'

section .note.GNU-stack noalloc noexec nowrite progbits
