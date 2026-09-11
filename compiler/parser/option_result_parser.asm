; BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-F02 structural bounded Option extension parser and evaluator.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/core_option_range_flow_registry.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/semantic/types/option_layout_semantic.inc"
%include "compiler/lowering/operators/evaluation_plan.inc"

extern neboc_option_layout
extern neboc_option_coalesce
extern neboc_optional_chain
extern neboc_option_coalesce_assignment_plan
extern neboc_option_coalesce_assignment_commit

section .rodata
op_n_console: db 'console'
op_n_console_len equ $-op_n_console
n_option: db 'Option'
n_option_len equ $-n_option
n_array: db 'Array'
n_array_len equ $-n_array
n_int: db 'Int'
n_int_len equ $-n_int
n_bool: db 'Bool'
n_bool_len equ $-n_bool
n_char: db 'Char'
n_char_len equ $-n_char
n_some: db 'Some'
n_some_len equ $-n_some
n_none: db 'None'
n_none_len equ $-n_none
n_is_some: db 'isSome'
n_is_some_len equ $-n_is_some
n_is_none: db 'isNone'
n_is_none_len equ $-n_is_none
n_get: db 'get'
n_get_len equ $-n_get
n_map: db 'map'
n_map_len equ $-n_map
n_and_then: db 'andThen'
n_and_then_len equ $-n_and_then
n_or_else: db 'orElse'
n_or_else_len equ $-n_or_else
n_contains: db 'contains'
n_contains_len equ $-n_contains
n_expect: db 'expect'
n_expect_len equ $-n_expect
n_unwrap_or: db 'unwrapOr'
n_unwrap_or_len equ $-n_unwrap_or
n_filter: db 'filter'
n_filter_len equ $-n_filter
n_zip: db 'zip'
n_zip_len equ $-n_zip
n_at: db 'at'
n_at_len equ $-n_at
n_drop: db 'drop'
n_drop_len equ $-n_drop
n_eager: db 'eager'
n_eager_len equ $-n_eager
n_mutable: db 'mutable'
n_mutable_len equ $-n_mutable
n_wrapping_add: db 'wrappingAdd'
n_wrapping_add_len equ $-n_wrapping_add

section .text

; RAX token index -> token pointer or zero. R12 is request.
op_token_ptr:
 cmp rax,[r12+NEBOC_OPTION_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_OPTION_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX token index, RSI bytes, EDX length -> EAX boolean.
op_token_match:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rsi
 mov r15,rdx
 call op_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r15
 jne .no
 mov r8,[r12+NEBOC_OPTION_SOURCE_OFFSET]
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
op_peek_kind:
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

; EDI token kind.
%undef call
op_expect:
 push rbx
 mov ebx,edi
 call op_peek_kind
 cmp eax,ebx
 jne .syntax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 xor eax,eax
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_OPTION_DIAG_SYNTAX
 call op_error
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
op_expect_empty_call:
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
.done:
 ret

; ESI diagnostic -> invalid source.
%undef call
op_error:
 mov [r12+NEBOC_OPTION_DIAGNOSTIC_OFFSET],rsi
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov [r12+NEBOC_OPTION_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; RSI bytes, EDX len -> EAX boolean at cursor.
op_match_current:
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 jmp op_token_match

; Scan before ownership: a source is ours only when it contains Option and at
; least one F02 operation.  Requiring both keeps legacy Option profiles and
; unrelated get/drop APIs on their established verticals.
op_scan_marker:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 xor ebx,ebx
 xor r13d,r13d
 xor r14d,r14d
 xor r15d,r15d
.loop:
 cmp rbx,[r12+NEBOC_OPTION_TOKEN_COUNT_OFFSET]
 jae .decision
 mov rax,rbx
 call op_token_ptr
 test rax,rax
 jz .no
 mov r10,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r10,NEBOC_TOKEN_COALESCE
 je .mark_operation
 cmp r10,NEBOC_TOKEN_OPTIONAL_CHAIN
 je .mark_operation
 cmp r10,NEBOC_TOKEN_OPTION_ASSIGN
 je .mark_operation
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rax,rbx
 lea rsi,[rel n_option]
 mov edx,n_option_len
 call op_token_match
 test eax,eax
 jz .new_operation
 mov r13d,1
 ; Predicate-only canonical constructors must reach the same tagged owner.
 ; The older Option<T>.some surface retains its separate native grammar.
 lea rax,[rbx+4]
 call op_token_ptr
 test rax,rax
 jz .new_operation
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .new_operation
 mov r15d,1
.new_operation:
 test r15d,r15d
 jz .other_operation
 mov rax,rbx
 lea rsi,[rel n_is_some]
 mov edx,n_is_some_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_is_none]
 mov edx,n_is_none_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
.other_operation:
 mov rax,rbx
 lea rsi,[rel n_get]
 mov edx,n_get_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_map]
 mov edx,n_map_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_and_then]
 mov edx,n_and_then_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_or_else]
 mov edx,n_or_else_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_contains]
 mov edx,n_contains_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_expect]
 mov edx,n_expect_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_unwrap_or]
 mov edx,n_unwrap_or_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_filter]
 mov edx,n_filter_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_zip]
 mov edx,n_zip_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_drop]
 mov edx,n_drop_len
 call op_token_match
 test eax,eax
 jnz .mark_operation
 mov rax,rbx
 lea rsi,[rel n_mutable]
 mov edx,n_mutable_len
 call op_token_match
 test eax,eax
 jz .next
.mark_operation:
 mov r14d,1
.next:
 inc rbx
 jmp .loop
.decision:
 test r13d,r13d
 jz .no
 test r14d,r14d
 jz .no
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

; Current token is a scalar type. RAX type, RDX size, RCX align.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
op_parse_scalar_type:
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call op_match_current
 test eax,eax
 jnz .int
 lea rsi,[rel n_bool]
 mov edx,n_bool_len
 call op_match_current
 test eax,eax
 jnz .bool
 lea rsi,[rel n_char]
 mov edx,n_char_len
 call op_match_current
 test eax,eax
 jnz .char
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 ret
.int:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov eax,NEBOC_OPTION_TYPE_INT
 mov edx,8
 mov ecx,8
 ret
.bool:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov eax,NEBOC_OPTION_TYPE_BOOL
 mov edx,1
 mov ecx,1
 ret
.char:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov eax,NEBOC_OPTION_TYPE_CHAR
 mov edx,4
 mov ecx,4
 ret

; RDI expected scalar type -> RAX value, EDX status.
%undef call
op_parse_scalar_value:
 push rbx
 mov ebx,edi
 call op_peek_kind
 cmp ebx,NEBOC_OPTION_TYPE_INT
 je .int
 cmp ebx,NEBOC_OPTION_TYPE_BOOL
 je .bool
 cmp ebx,NEBOC_OPTION_TYPE_CHAR
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
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
.consume:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 xor edx,edx
 pop rbx
 ret
.bad:
 xor eax,eax
 mov edx,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
op_alloc_binding:
 push rdi
 push rcx
 mov rax,[r12+NEBOC_OPTION_BINDING_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_OPTION_BINDING_CAPACITY_OFFSET]
 jae .limit
 imul rax,NEBOC_OPTION_BIND_SIZE
 add rax,[r12+NEBOC_OPTION_BINDINGS_OFFSET]
 mov rdi,rax
 mov ecx,NEBOC_OPTION_BIND_QWORDS
 xor eax,eax
 rep stosq
 mov rax,rdi
 sub rax,NEBOC_OPTION_BIND_SIZE
 mov qword [rax+NEBOC_OPTION_BIND_NAME_OFFSET],NEBOC_OPTION_UNBOUND_NAME
 mov qword [rax+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_LIVE
 inc qword [r12+NEBOC_OPTION_BINDING_COUNT_OFFSET]
 pop rcx
 pop rdi
 ret
.limit:
 mov esi,NEBOC_OPTION_DIAG_LAYOUT
 call op_error
 xor eax,eax
 pop rcx
 pop rdi
 ret

; RAX name token index -> binding pointer or zero.
%undef call
op_find_binding:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_OPTION_BINDING_COUNT_OFFSET]
 jae .none
 mov r14,rbx
 imul r14,NEBOC_OPTION_BIND_SIZE
 add r14,[r12+NEBOC_OPTION_BINDINGS_OFFSET]
 mov r15,[r14+NEBOC_OPTION_BIND_NAME_OFFSET]
 cmp r15,NEBOC_OPTION_UNBOUND_NAME
 je .next
 mov rax,r13
 call op_token_ptr
 mov r8,rax
 mov rax,r15
 call op_token_ptr
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
 mov r9,[r12+NEBOC_OPTION_SOURCE_OFFSET]
 add r9,[r8+NEBOC_TOKEN_START_OFFSET]
 mov r10,[r12+NEBOC_OPTION_SOURCE_OFFSET]
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

; RSI parent binding -> RAX cloned unbound live binding.
op_clone_binding:
 push rbx
 push r13
 push r14
 sub rsp,16
 mov r13,rsi
 call op_alloc_binding
 test rax,rax
 jz .done
 mov rbx,rax
 mov rdi,rbx
 mov rsi,r13
 mov ecx,NEBOC_OPTION_BIND_QWORDS
 rep movsq
 mov qword [rbx+NEBOC_OPTION_BIND_NAME_OFFSET],NEBOC_OPTION_UNBOUND_NAME
 mov qword [rbx+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_LIVE
 mov rax,rbx
.done:
 add rsp,16
 pop r14
 pop r13
 pop rbx
 ret

; Parse Option<T>(Some(value)|None()) and return binding pointer.
op_parse_constructor:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,120
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call op_expect
 test eax,eax
 jnz .fail
 ; Scalar type or bounded Array<Int,N>.
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call op_match_current
 test eax,eax
 jnz .array_type
 call op_parse_scalar_type
 test eax,eax
 jz .payload_error
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+16],rcx
 mov qword [rsp+24],0
 jmp .type_ready
.array_type:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call op_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call op_match_current
 test eax,eax
 jz .payload_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call op_expect
 test eax,eax
 jnz .fail
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .payload_error
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rbx,NEBOC_OPTION_MAX_ARRAY_LENGTH
 ja .layout_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call op_expect
 test eax,eax
 jnz .fail
 mov qword [rsp],NEBOC_OPTION_TYPE_ARRAY_INT
 mov rax,rbx
 imul rax,8
 mov [rsp+8],rax
 mov qword [rsp+16],8
 mov [rsp+24],rbx
.type_ready:
 mov edi,NEBOC_TOKEN_GREATER
 call op_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel n_some]
 mov edx,n_some_len
 call op_match_current
 test eax,eax
 jnz .some
 lea rsi,[rel n_none]
 mov edx,n_none_len
 call op_match_current
 test eax,eax
 jz .variant_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [rsp+32],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 mov qword [rsp+40],0
 mov qword [rsp+48],0
 jmp .variant_ready
.some:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 cmp qword [rsp],NEBOC_OPTION_TYPE_ARRAY_INT
 je .array_value
 mov rdi,[rsp]
 call op_parse_scalar_value
 test edx,edx
 jnz .payload_error
 mov [rsp+40],rax
 mov [rsp+48],rax
 jmp .some_close
.array_value:
 lea rsi,[rel n_array]
 mov edx,n_array_len
 call op_match_current
 test eax,eax
 jz .payload_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call op_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call op_match_current
 test eax,eax
 jz .payload_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call op_expect
 test eax,eax
 jnz .fail
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .payload_error
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 mov r14,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp r14,[rsp+24]
 jne .payload_error
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call op_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call op_expect
 test eax,eax
 jnz .fail
 xor ebx,ebx
 mov r15,14695981039346656037
 mov r10,1099511628211
.array_loop:
 cmp rbx,r14
 jae .array_end
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .payload_error
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 xor r15,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 imul r15,r10
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 inc rbx
 cmp rbx,r14
 jae .array_end
 mov edi,NEBOC_TOKEN_COMMA
 call op_expect
 test eax,eax
 jnz .fail
 jmp .array_loop
.array_end:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call op_expect
 test eax,eax
 jnz .fail
 mov [rsp+40],r14
 mov [rsp+48],r15
.some_close:
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov qword [rsp+32],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
.variant_ready:
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 ; Compute generic A0 layout through the separate semantic unit.
 lea rdi,[rsp+56]
 mov ecx,NEBOC_OPTION_LAYOUT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp+8]
 mov [rsp+56+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_SIZE_OFFSET],rax
 mov rax,[rsp+16]
 mov [rsp+56+NEBOC_OPTION_LAYOUT_REQUEST_PAYLOAD_ALIGN_OFFSET],rax
 lea rdi,[rsp+56]
 call neboc_option_layout
 test eax,eax
 jnz .layout_error
 call op_alloc_binding
 test rax,rax
 jz .fail
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_OPTION_BIND_TAG_OFFSET],rax
 mov rax,[rsp+40]
 mov [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_OPTION_BIND_ARRAY_LENGTH_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_OPTION_BIND_PAYLOAD_SIZE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_OPTION_BIND_PAYLOAD_ALIGN_OFFSET],rax
 mov rax,[rsp+56+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_SIZE_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_LAYOUT_SIZE_OFFSET],rax
 mov rax,[rsp+56+NEBOC_OPTION_LAYOUT_REQUEST_RESULT_ALIGN_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_LAYOUT_ALIGN_OFFSET],rax
 mov rax,[rsp+48]
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 mov rax,r13
 jmp .done
.payload_error:
 mov esi,NEBOC_OPTION_DIAG_PAYLOAD
 jmp .error
.variant_error:
 mov esi,NEBOC_OPTION_DIAG_VARIANT
 jmp .error
.layout_error:
 mov esi,NEBOC_OPTION_DIAG_LAYOUT
.error:
 call op_error
.fail:
 xor eax,eax
.done:
 add rsp,120
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse one F02 statement.
op_parse_statement:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,120
 xor r15d,r15d
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .owned_statement
 xor r13d,r13d
 call op_scalar_statement
 test eax,eax
 jnz .fail
 mov r15d,1
 jmp .suffix
.owned_statement:
 lea rsi,[rel n_option]
 mov edx,n_option_len
 call op_match_current
 test eax,eax
 jnz .constructor
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_find_binding
 test rax,rax
 jz .syntax
 mov r13,rax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 jmp .suffix
.constructor:
 call op_parse_constructor
 test rax,rax
 jz .fail
 mov r13,rax
.suffix:
 call op_peek_kind
 mov r10,rax
 NEBOC_CORE_ORF_CLASSIFY r10,r11,.suffix_non_registry
 cmp r11,NEBOC_OPERATOR_ID_NSR_CORE_039
 je .coalesce
 cmp r11,NEBOC_OPERATOR_ID_NSR_CORE_040
 je .optional_chain
 cmp r11,NEBOC_OPERATOR_ID_NSR_CORE_041
 je .option_assign
.suffix_non_registry:
 cmp eax,NEBOC_TOKEN_DOT
 jne .complete
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 lea rsi,[rel op_n_console]
 mov edx,op_n_console_len
 call op_match_current
 test eax,eax
 jnz .console
 ; A scalar observation is a scalar; never reuse its old container receiver.
 test r15d,r15d
 jnz .syntax
 lea rsi,[rel n_is_some]
 mov edx,n_is_some_len
 call op_match_current
 test eax,eax
 jnz .is_some
 lea rsi,[rel n_is_none]
 mov edx,n_is_none_len
 call op_match_current
 test eax,eax
 jnz .is_none
 lea rsi,[rel n_get]
 mov edx,n_get_len
 call op_match_current
 test eax,eax
 jnz .get
 lea rsi,[rel n_map]
 mov edx,n_map_len
 call op_match_current
 test eax,eax
 jnz .map
 lea rsi,[rel n_and_then]
 mov edx,n_and_then_len
 call op_match_current
 test eax,eax
 jnz .and_then
 lea rsi,[rel n_or_else]
 mov edx,n_or_else_len
 call op_match_current
 test eax,eax
 jnz .or_else
 lea rsi,[rel n_contains]
 mov edx,n_contains_len
 call op_match_current
 test eax,eax
 jnz .contains
 lea rsi,[rel n_expect]
 mov edx,n_expect_len
 call op_match_current
 test eax,eax
 jnz .expect
 lea rsi,[rel n_unwrap_or]
 mov edx,n_unwrap_or_len
 call op_match_current
 test eax,eax
 jnz .unwrap_or
 lea rsi,[rel n_filter]
 mov edx,n_filter_len
 call op_match_current
 test eax,eax
 jnz .filter
 lea rsi,[rel n_zip]
 mov edx,n_zip_len
 call op_match_current
 test eax,eax
 jnz .zip
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call op_match_current
 test eax,eax
 jnz .at
 lea rsi,[rel n_drop]
 mov edx,n_drop_len
 call op_match_current
 test eax,eax
 jnz .drop
 lea rsi,[rel n_mutable]
 mov edx,n_mutable_len
 call op_match_current
 test eax,eax
 jnz .mutable
 ; One-shot binding terminal.
 cmp qword [r13+NEBOC_OPTION_BIND_NAME_OFFSET],NEBOC_OPTION_UNBOUND_NAME
 jne .syntax
 mov [r13+NEBOC_OPTION_BIND_NAME_OFFSET],r14
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 jmp .suffix
.mutable:
 call .check_live
 jne .use_after
 cmp qword [r13+NEBOC_OPTION_BIND_NAME_OFFSET],NEBOC_OPTION_UNBOUND_NAME
 je .syntax
 test qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_MUTABLE
 jnz .syntax
 or qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_MUTABLE
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 jmp .suffix
.coalesce:
 call .check_live
 jne .use_after
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov rdi,[r13+NEBOC_OPTION_BIND_TAG_OFFSET]
 mov rsi,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov rdx,[rsp]
 lea rcx,[rsp+40]
 call neboc_option_coalesce
 test eax,eax
 jnz .syntax
 mov rax,[rsp+40+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET]
 add [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],rax
 mov rax,[rsp+40+NEBOC_EVAL_PLAN_AUXILIARY_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.optional_chain:
 call .check_live
 jne .use_after
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_INT
 jne .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 lea rsi,[rel n_wrapping_add]
 mov edx,n_wrapping_add_len
 call op_match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_OPTION_TYPE_INT
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rdi,[r13+NEBOC_OPTION_BIND_TAG_OFFSET]
 mov rsi,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov edx,NEBOC_OPERATOR_ID_NSR_CORE_040
 lea rcx,[rsp+40]
 call neboc_optional_chain
 test eax,eax
 jnz .syntax
 mov rax,[rsp+40+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET]
 add [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],rax
 mov rsi,r13
 call op_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .suffix
 mov rax,[rsp]
 add [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 jmp .suffix
.option_assign:
 call .check_live
 jne .use_after
 cmp qword [r13+NEBOC_OPTION_BIND_NAME_OFFSET],NEBOC_OPTION_UNBOUND_NAME
 je .syntax
 test qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_MUTABLE
 jz .syntax
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 lea rdi,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov rsi,[r13+NEBOC_OPTION_BIND_TAG_OFFSET]
 mov rdx,[rsp]
 lea rcx,[rsp+40]
 call neboc_option_coalesce_assignment_plan
 test eax,eax
 jnz .syntax
 lea rdi,[rsp+40]
 call neboc_option_coalesce_assignment_commit
 test eax,eax
 jnz .syntax
 mov rax,[rsp+40+NEBOC_EVAL_PLAN_RIGHT_EVALUATIONS_OFFSET]
 add [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],rax
 cmp qword [rsp+40+NEBOC_EVAL_PLAN_STORE_COUNT_OFFSET],0
 je .suffix
 mov qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 jmp .suffix
.check_live:
 cmp qword [r13+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_LIVE
 ret
.is_some:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 mov rax,[r13+NEBOC_OPTION_BIND_TAG_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],NEBOC_OPTION_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.is_none:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 xor eax,eax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 sete al
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],NEBOC_OPTION_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.get:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .unsafe_get
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.contains:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 xor eax,eax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .contains_ready
 mov rdx,[rsp]
 cmp rdx,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 sete al
.contains_ready:
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],NEBOC_OPTION_TYPE_BOOL
 mov r15d,1
 jmp .suffix
.expect:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_TEXT
 jne .syntax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .unsafe_get
 test qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_ZIPPED
 jnz .syntax
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.unwrap_or:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rax,[rsp]
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 je .unwrap_ready
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
.unwrap_ready:
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rax
 mov r15d,1
 jmp .suffix
.filter:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_OPTION_TYPE_BOOL
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call op_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .suffix
 inc qword [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 cmp qword [rsp],0
 jne .suffix
 mov qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 mov qword [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],0
 mov qword [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],0
 jmp .suffix
.zip:
 call .check_live
 jne .use_after
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_find_binding
 test rax,rax
 jz .syntax
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_LIVE
 jne .use_after
 cmp qword [rax+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call op_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 mov rdx,[rsp+16]
 or qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_ZIPPED
 mov rax,[rdx+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_SECOND_VALUE_OFFSET],rax
 mov rax,[rdx+NEBOC_OPTION_BIND_TYPE_OFFSET]
 mov [r13+NEBOC_OPTION_BIND_SECOND_TYPE_OFFSET],rax
 cmp qword [rdx+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 je .suffix
 mov qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 jmp .suffix
.at:
 call .check_live
 jne .use_after
 test qword [r13+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_ZIPPED
 jz .syntax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .unsafe_get
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call op_expect
 test eax,eax
 jnz .fail
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .syntax
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rbx,1
 ja .syntax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call op_expect
 test eax,eax
 jnz .fail
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 test rbx,rbx
 jnz .at_second
 mov rax,[r13+NEBOC_OPTION_BIND_VALUE_OFFSET]
 mov rdx,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 jmp .at_ready
.at_second:
 mov rax,[r13+NEBOC_OPTION_BIND_SECOND_VALUE_OFFSET]
 mov rdx,[r13+NEBOC_OPTION_BIND_SECOND_TYPE_OFFSET]
.at_ready:
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rdx
 mov r15d,1
 jmp .suffix
.map:
 mov ebx,1
 jmp .transform_scalar
.or_else:
 mov ebx,2
.transform_scalar:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel n_eager]
 mov edx,n_eager_len
 call op_match_current
 test eax,eax
 jnz .lazy
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call op_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp ebx,1
 je .map_apply
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 jne .suffix
 mov qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 mov rax,[rsp]
 mov [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.map_apply:
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .suffix
 mov rax,[rsp]
 mov [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.and_then:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 lea rsi,[rel n_eager]
 mov edx,n_eager_len
 call op_match_current
 test eax,eax
 jnz .lazy
 lea rsi,[rel n_some]
 mov edx,n_some_len
 call op_match_current
 test eax,eax
 jnz .and_some
 lea rsi,[rel n_none]
 mov edx,n_none_len
 call op_match_current
 test eax,eax
 jz .callback_type
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_NONE
 mov qword [rsp],0
 jmp .and_arg_ready
.and_some:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call op_expect
 test eax,eax
 jnz .fail
 cmp qword [r13+NEBOC_OPTION_BIND_TYPE_OFFSET],NEBOC_OPTION_TYPE_ARRAY_INT
 je .callback_type
 mov rdi,[r13+NEBOC_OPTION_BIND_TYPE_OFFSET]
 call op_parse_scalar_value
 test edx,edx
 jnz .callback_type
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov qword [rsp+8],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
.and_arg_ready:
 mov edi,NEBOC_TOKEN_RPAREN
 call op_expect
 test eax,eax
 jnz .fail
 mov rsi,r13
 call op_clone_binding
 test rax,rax
 jz .fail
 mov r13,rax
 cmp qword [r13+NEBOC_OPTION_BIND_TAG_OFFSET],NEBOC_OPTION_RESULT_PARSER_OPTION_TAG_SOME
 jne .suffix
 mov rax,[rsp+8]
 mov [r13+NEBOC_OPTION_BIND_TAG_OFFSET],rax
 mov rax,[rsp]
 mov [r13+NEBOC_OPTION_BIND_VALUE_OFFSET],rax
 mov [r13+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET],rax
 inc qword [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 jmp .suffix
.drop:
 call .check_live
 jne .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 mov qword [r13+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_DROPPED
 inc qword [r12+NEBOC_OPTION_DROP_COUNT_OFFSET]
 mov qword [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],NEBOC_OPTION_TYPE_INT
 mov qword [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],0
 mov r15d,1
 jmp .suffix
.terminal_return:
 test r15d,r15d
 jz .use_after
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 mov qword [r12+NEBOC_OPTION_RETURNED_OFFSET],1
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .syntax
 jmp .complete
.console:
 test r15d,r15d
 jz .syntax
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_expect_empty_call
 test eax,eax
 jnz .fail
 call op_record_console
 test eax,eax
 jnz .fail
 jmp .suffix
.complete:
 test r13,r13
 jz .scalar_complete

 mov rax,[r13+NEBOC_OPTION_BIND_LAYOUT_SIZE_OFFSET]
 cmp rax,[r12+NEBOC_OPTION_LAYOUT_SIZE_OFFSET]
 jbe .align
 mov [r12+NEBOC_OPTION_LAYOUT_SIZE_OFFSET],rax
.align:
 mov rax,[r13+NEBOC_OPTION_BIND_LAYOUT_ALIGN_OFFSET]
 cmp rax,[r12+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET]
 jbe .ok
 mov [r12+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET],rax
.ok:
 xor eax,eax
 jmp .done
.scalar_complete:
 xor eax,eax
 jmp .done
.unsafe_get:
 mov esi,NEBOC_OPTION_DIAG_UNSAFE_GET
 jmp .error
.use_after:
 mov esi,NEBOC_OPTION_DIAG_USE_AFTER_MOVE
 jmp .error
.callback_type:
 mov esi,NEBOC_OPTION_DIAG_CALLBACK_TYPE
 jmp .error
.lazy:
 mov esi,NEBOC_OPTION_DIAG_LAZY
 jmp .error
.syntax:
 mov esi,NEBOC_OPTION_DIAG_SYNTAX
.error:
 call op_error
.fail:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,120
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

op_cleanup:
 push rbx
 push r13
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_OPTION_BINDING_COUNT_OFFSET]
 jae .done
 mov r13,rbx
 imul r13,NEBOC_OPTION_BIND_SIZE
 add r13,[r12+NEBOC_OPTION_BINDINGS_OFFSET]
 cmp qword [r13+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_LIVE
 jne .next
 mov qword [r13+NEBOC_OPTION_BIND_STATE_OFFSET],NEBOC_OPTION_STATE_DROPPED
 inc qword [r12+NEBOC_OPTION_DROP_COUNT_OFFSET]
.next:
 inc rbx
 jmp .loop
.done:
 pop r13
 pop rbx
 ret

op_hash:
 mov rax,14695981039346656037
 mov rcx,1099511628211
 xor rdx,rdx
.bindings:
 cmp rdx,[r12+NEBOC_OPTION_BINDING_COUNT_OFFSET]
 jae .tail
 mov r8,rdx
 imul r8,NEBOC_OPTION_BIND_SIZE
 add r8,[r12+NEBOC_OPTION_BINDINGS_OFFSET]
 xor rax,[r8+NEBOC_OPTION_BIND_TYPE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_OPTION_BIND_TAG_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_OPTION_BIND_STATE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_OPTION_BIND_VALUE_HASH_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_OPTION_BIND_FLAGS_OFFSET]
 imul rax,rcx
 test qword [r8+NEBOC_OPTION_BIND_FLAGS_OFFSET],NEBOC_OPTION_BIND_FLAG_ZIPPED
 jz .binding_ready
 xor rax,[r8+NEBOC_OPTION_BIND_SECOND_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r8+NEBOC_OPTION_BIND_SECOND_TYPE_OFFSET]
 imul rax,rcx
.binding_ready:
 inc rdx
 jmp .bindings
.tail:
 xor rax,[r12+NEBOC_OPTION_RESULT_VALUE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_OPTION_DROP_COUNT_OFFSET]
 imul rax,rcx
 mov rdx,NEBOC_OPTION_RETURNED_OFFSET
.effects:
 xor rax,[r12+rdx]
 imul rax,rcx
 add rdx,8
 cmp rdx,NEBOC_OPTION_REQUEST_SIZE
 jb .effects
 ret

NEBOC_ABI_FUNCTION neboc_option_recognize
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
 lea rdi,[r12+NEBOC_OPTION_RETURNED_OFFSET]
 mov ecx,2+32*4
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_OPTION_FOUND_OFFSET],0
 mov qword [r12+NEBOC_OPTION_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_OPTION_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_OPTION_CURSOR_OFFSET],0
 mov qword [r12+NEBOC_OPTION_BINDING_COUNT_OFFSET],0
 mov qword [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],0
 mov qword [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],0
 mov qword [r12+NEBOC_OPTION_LAYOUT_SIZE_OFFSET],0
 mov qword [r12+NEBOC_OPTION_LAYOUT_ALIGN_OFFSET],0
 mov qword [r12+NEBOC_OPTION_CALLBACK_COUNT_OFFSET],0
 mov qword [r12+NEBOC_OPTION_DROP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_OPTION_SEMANTIC_HASH_OFFSET],0
 mov rax,[r12+NEBOC_OPTION_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_OPTION_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_OPTION_BINDINGS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_OPTION_BINDING_CAPACITY_OFFSET],1
 jb .invalid
 call op_scan_marker
 test eax,eax
 jz .not_owned
 mov qword [r12+NEBOC_OPTION_FOUND_OFFSET],1
 mov edi,NEBOC_TOKEN_KW_START
 call op_expect
 test eax,eax
 jnz .done
 call op_expect_empty_call
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call op_expect
 test eax,eax
 jnz .done
.statements:
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_RBRACE
 je .close
 cmp qword [r12+NEBOC_OPTION_RETURNED_OFFSET],0
 jne .syntax
 call op_parse_statement
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call op_expect
 test eax,eax
 jnz .done
 jmp .statements
.close:
 inc qword [r12+NEBOC_OPTION_CURSOR_OFFSET]
 call op_peek_kind
 cmp eax,NEBOC_TOKEN_EOF
 jne .syntax
 call op_cleanup
 call op_hash
 mov [r12+NEBOC_OPTION_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax:
 mov esi,NEBOC_OPTION_DIAG_SYNTAX
 call op_error
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
op_scalar_statement:
 push rbx
 call op_peek_kind
 mov ebx,NEBOC_OPTION_TYPE_INT
 cmp eax,NEBOC_TOKEN_INTEGER
 je .literal
 mov ebx,NEBOC_OPTION_TYPE_CHAR
 cmp eax,NEBOC_TOKEN_CHAR
 je .literal
 mov ebx,NEBOC_OPTION_TYPE_BOOL
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .literal
 cmp eax,NEBOC_TOKEN_KW_FALSE
 jne .syntax
.literal:
 mov edi,ebx
 call op_parse_scalar_value
 test edx,edx
 jnz .syntax
 mov [r12+NEBOC_OPTION_RESULT_VALUE_OFFSET],rax
 mov [r12+NEBOC_OPTION_RESULT_TYPE_OFFSET],rbx
 xor eax,eax
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_OPTION_DIAG_SYNTAX
 call op_error
 pop rbx
 ret

; A typed scalar effect is recorded at its exact source call interval.
op_record_console:
 push rbx
 mov rax,[r12+NEBOC_OPTION_RESULT_TYPE_OFFSET]
 cmp rax,NEBOC_OPTION_TYPE_INT
 je .typed
 cmp rax,NEBOC_OPTION_TYPE_BOOL
 jne .syntax
.typed:
 mov rbx,[r12+NEBOC_OPTION_EFFECT_COUNT_OFFSET]
 cmp rbx,32
 jae .limit
 shl rbx,5
 lea rbx,[r12+rbx+NEBOC_OPTION_EFFECTS_OFFSET]
 mov [rbx],rax
 mov rax,[r12+NEBOC_OPTION_RESULT_VALUE_OFFSET]
 mov [rbx+8],rax
 mov rax,r14
 call op_token_ptr
 mov rax,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+16],rax
 mov rax,[r12+NEBOC_OPTION_CURSOR_OFFSET]
 dec rax
 call op_token_ptr
 mov rax,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+24],rax
 inc qword [r12+NEBOC_OPTION_EFFECT_COUNT_OFFSET]
 xor eax,eax
 pop rbx
 ret
.limit:
 mov esi,NEBOC_OPTION_DIAG_LAYOUT
 call op_error
 pop rbx
 ret
.syntax:
 mov esi,NEBOC_OPTION_DIAG_SYNTAX
 call op_error
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
