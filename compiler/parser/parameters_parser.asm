; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F02 bounded parameters/defaults/named arguments and returns.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/parameters_parser.inc"

section .rodata
seguranca_numerica_conversoes_e_overflow_n_int: db 'Int'
seguranca_numerica_conversoes_e_overflow_n_int_len equ $-seguranca_numerica_conversoes_e_overflow_n_int
seguranca_numerica_conversoes_e_overflow_n_bool: db 'Bool'
seguranca_numerica_conversoes_e_overflow_n_bool_len equ $-seguranca_numerica_conversoes_e_overflow_n_bool
seguranca_numerica_conversoes_e_overflow_n_char: db 'Char'
seguranca_numerica_conversoes_e_overflow_n_char_len equ $-seguranca_numerica_conversoes_e_overflow_n_char
parameters_parser_n_tuple: db 'Tuple'
n_tuple_len equ $-parameters_parser_n_tuple
n_overload: db 'overload'
n_overload_len equ $-n_overload
n_self: db 'self'
n_self_len equ $-n_self
seguranca_numerica_conversoes_e_overflow_n_value: db 'value'
seguranca_numerica_conversoes_e_overflow_n_value_len equ $-seguranca_numerica_conversoes_e_overflow_n_value
n_where: db 'where'
n_where_len equ $-n_where
n_symbol: db 'symbol'
n_symbol_len equ $-n_symbol
seguranca_numerica_conversoes_e_overflow_n_scalar: db 'Scalar'
seguranca_numerica_conversoes_e_overflow_n_scalar_len equ $-seguranca_numerica_conversoes_e_overflow_n_scalar
n_integral: db 'Integral'
n_integral_len equ $-n_integral
n_any: db 'Any'
n_any_len equ $-n_any
n_equatable: db 'Equatable'
n_equatable_len equ $-n_equatable
n_callable: db 'callable'
n_callable_len equ $-n_callable
n_capture: db 'capture'
n_capture_len equ $-n_capture
parameters_parser_n_none: db 'none'
n_none_len equ $-parameters_parser_n_none
parameters_parser_n_copy: db 'copy'
n_copy_len equ $-parameters_parser_n_copy
parameters_parser_n_move: db 'move'
n_move_len equ $-parameters_parser_n_move
n_borrow: db 'borrow'
n_borrow_len equ $-n_borrow
parameters_parser_n_sum: db 'sum'
n_sum_len equ $-parameters_parser_n_sum
n_call: db 'call'
n_call_len equ $-n_call
n_callback: db 'callback'
n_callback_len equ $-n_callback
parameters_parser_n_drop: db 'drop'
n_drop_len equ $-parameters_parser_n_drop

section .text

seguranca_numerica_conversoes_e_overflow_token_ptr:
 cmp rax,[r12+NEBOC_PARAM_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_PARAM_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX token index, RSI bytes, EDX length -> EAX boolean.
seguranca_numerica_conversoes_e_overflow_token_match:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rsi
 mov r15d,edx
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r15
 jne .no
 mov r8,[r12+NEBOC_PARAM_SOURCE_OFFSET]
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

; RAX/RDX token indices -> EAX equality of source spelling.
token_equal:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rax
 mov r14,rdx
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,r14
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r15+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[r15+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r8,[r12+NEBOC_PARAM_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r12+NEBOC_PARAM_SOURCE_OFFSET]
 add r9,[r15+NEBOC_TOKEN_START_OFFSET]
 xor edx,edx
.bytes:
 cmp rdx,rcx
 jae .yes
 mov al,[r8+rdx]
 cmp al,[r9+rdx]
 jne .no
 inc rdx
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

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
peek_kind:
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

; RDI token index -> RAX kind.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
seguranca_numerica_conversoes_e_overflow_kind_at:
 mov rax,rdi
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 mov eax,NEBOC_TOKEN_INVALID
 ret

%undef call
seguranca_numerica_conversoes_e_overflow_error:
 mov [r12+NEBOC_PARAM_DIAGNOSTIC_OFFSET],rsi
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [r12+NEBOC_PARAM_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

expect:
 push rbx
 mov ebx,edi
 call peek_kind
 cmp eax,ebx
 jne .bad
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 xor eax,eax
 pop rbx
 ret
.bad:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
 call seguranca_numerica_conversoes_e_overflow_error
 pop rbx
 ret

match_current:
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 jmp seguranca_numerica_conversoes_e_overflow_token_match

scan_marker:
 push rbx
 xor edi,edi
 call seguranca_numerica_conversoes_e_overflow_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .no
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_PARAM_TOKEN_COUNT_OFFSET]
 jae .no
 mov rdi,rbx
 call seguranca_numerica_conversoes_e_overflow_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_EQUAL
 je .yes
 cmp eax,NEBOC_TOKEN_RESERVED_COLON
 je .yes
 mov rax,rbx
 lea rsi,[rel parameters_parser_n_tuple]
 mov edx,n_tuple_len
 call seguranca_numerica_conversoes_e_overflow_token_match
 test eax,eax
 jnz .yes
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

; EAX canonical scalar type or zero.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
seguranca_numerica_conversoes_e_overflow_parse_type:
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_int]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_int_len
 call match_current
 test eax,eax
 jnz .int
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_bool]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_bool_len
 call match_current
 test eax,eax
 jnz .bool
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_char]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_char_len
 call match_current
 test eax,eax
 jnz .char
 xor eax,eax
 ret
.int:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 ret
.bool:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_BOOL
 ret
.char:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ret

; EAX type, RDX value, ECX status.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
parse_literal:
 call peek_kind
 cmp eax,NEBOC_TOKEN_INTEGER
 je .payload_int
 cmp eax,NEBOC_TOKEN_CHAR
 je .payload_char
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp eax,NEBOC_TOKEN_KW_FALSE
 je .false
 xor eax,eax
 xor edx,edx
 mov ecx,NEBOC_STATUS_INVALID_SOURCE
 ret
.payload_int:
 mov r10d,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jmp .payload
.payload_char:
 mov r10d,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
.payload:
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,r10d
 xor ecx,ecx
 ret
.true:
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_BOOL
 mov edx,1
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 xor ecx,ecx
 ret
.false:
 mov eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_BOOL
 xor edx,edx
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 xor ecx,ecx
 ret

; RAX ordinal -> record pointer.
%undef call
param_ptr:
 cmp rax,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_PARAM_RECORD_SIZE
 add rax,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX name token -> RAX record pointer or zero.
find_param:
 push rbx
 push r13
 push r14
 mov r13,rax
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jae .none
 mov rax,rbx
 call param_ptr
 mov r14,rax
 mov rax,r13
 mov rdx,[r14+NEBOC_PARAM_NAME_OFFSET]
 call token_equal
 test eax,eax
 jnz .found
 inc rbx
 jmp .loop
.found:
 mov rax,r14
 jmp .done
.none:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop rbx
 ret

parse_signature:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call seguranca_numerica_conversoes_e_overflow_parse_type
 test eax,eax
 jz .signature
 mov [r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET],rax
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .signature
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [r12+NEBOC_PARAM_RECEIVER_NAME_OFFSET],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .signature
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 xor r15d,r15d                 ; a default was already seen
 call peek_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 je .end_params
.param_loop:
 mov rax,[r12+NEBOC_PARAM_COUNT_OFFSET]
 cmp rax,NEBOC_PARAM_MAX
 jae .abi
 call seguranca_numerica_conversoes_e_overflow_parse_type
 test eax,eax
 jz .signature
 mov r13,rax
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .signature
 mov r14,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rax,r14
 call find_param
 test rax,rax
 jnz .duplicate
 mov rax,[r12+NEBOC_PARAM_COUNT_OFFSET]
 imul rax,NEBOC_PARAM_RECORD_SIZE
 add rax,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov rbx,rax
 mov [rbx+NEBOC_PARAM_NAME_OFFSET],r14
 mov [rbx+NEBOC_PARAM_TYPE_OFFSET],r13
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_RESERVED_EQUAL
 jne .required
 mov r15d,1
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call parse_literal
 test ecx,ecx
 jnz .default
 cmp rax,r13
 jne .default
 mov qword [rbx+NEBOC_PARAM_HAS_DEFAULT_OFFSET],1
 mov [rbx+NEBOC_PARAM_DEFAULT_VALUE_OFFSET],rdx
 jmp .param_done
.required:
 test r15d,r15d
 jnz .default
 inc qword [r12+NEBOC_PARAM_REQUIRED_COUNT_OFFSET]
.param_done:
 inc qword [r12+NEBOC_PARAM_COUNT_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_COMMA
 je .comma
 cmp eax,NEBOC_TOKEN_RPAREN
 je .end_params
 jmp .signature
.comma:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 je .signature
 jmp .param_loop
.end_params:
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [r12+NEBOC_PARAM_BODY_START_OFFSET],rax
.seek_body_end:
 call peek_kind
 cmp eax,NEBOC_TOKEN_RBRACE
 je .body_end
 cmp eax,NEBOC_TOKEN_EOF
 je .signature
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 jmp .seek_body_end
.body_end:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 xor eax,eax
 jmp .done
.duplicate:
 mov esi,NEBOC_DIAG_DUPLICATE_PARAMETER
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.default:
 mov esi,NEBOC_DIAG_DEFAULT
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.abi:
 mov esi,NEBOC_DIAG_ABI_BOUND
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.signature:
 mov esi,NEBOC_DIAG_SIGNATURE
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse and bind the single direct start call.
parse_call:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov edi,NEBOC_TOKEN_KW_START
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 call parse_literal
 test ecx,ecx
 jnz .type
 cmp rax,[r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET]
 jne .type
 mov [r12+NEBOC_PARAM_RECEIVER_VALUE_OFFSET],rdx
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rdx,[r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET]
 call token_equal
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 xor ebx,ebx                   ; next positional ordinal
 xor r15d,r15d                 ; named phase
 call peek_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 je .args_done
.arg_loop:
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .positional
 mov rdi,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 inc rdi
 call seguranca_numerica_conversoes_e_overflow_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_COLON
 jne .positional
 mov r15d,1
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 call find_param
 test rax,rax
 jz .extra
 mov r14,rax
 cmp qword [r14+NEBOC_PARAM_BOUND_OFFSET],0
 jne .duplicate_named
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 call expect
 test eax,eax
 jnz .done
 inc qword [r12+NEBOC_PARAM_NAMED_COUNT_OFFSET]
 jmp .value
.positional:
 test r15d,r15d
 jnz .extra
 cmp rbx,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jae .extra
 mov rax,rbx
 call param_ptr
 mov r14,rax
 inc rbx
.value:
 call parse_literal
 test ecx,ecx
 jnz .type
 cmp rax,[r14+NEBOC_PARAM_TYPE_OFFSET]
 jne .type
 mov qword [r14+NEBOC_PARAM_BOUND_OFFSET],1
 mov [r14+NEBOC_PARAM_BOUND_VALUE_OFFSET],rdx
 inc qword [r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_COMMA
 je .arg_comma
 cmp eax,NEBOC_TOKEN_RPAREN
 je .args_done
 jmp .syntax
.arg_comma:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_RPAREN
 je .syntax
 jmp .arg_loop
.args_done:
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 xor ebx,ebx
.fill:
 cmp rbx,[r12+NEBOC_PARAM_COUNT_OFFSET]
 jae .filled
 mov rax,rbx
 call param_ptr
 cmp qword [rax+NEBOC_PARAM_BOUND_OFFSET],0
 jne .fill_next
 cmp qword [rax+NEBOC_PARAM_HAS_DEFAULT_OFFSET],0
 je .missing
 mov rdx,[rax+NEBOC_PARAM_DEFAULT_VALUE_OFFSET]
 mov [rax+NEBOC_PARAM_BOUND_VALUE_OFFSET],rdx
 mov qword [rax+NEBOC_PARAM_BOUND_OFFSET],1
 inc qword [r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET]
.fill_next:
 inc rbx
 jmp .fill
.filled:
 mov qword [r12+NEBOC_PARAM_TUPLE_SELECTOR_OFFSET],-1
 call peek_kind
 cmp eax,NEBOC_TOKEN_DOT
 jne .after_selector
 mov rdi,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 inc rdi
 call seguranca_numerica_conversoes_e_overflow_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .after_selector
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 call seguranca_numerica_conversoes_e_overflow_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [r12+NEBOC_PARAM_TUPLE_SELECTOR_OFFSET],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
.after_selector:
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_EOF
 call expect
 jmp .done
.duplicate_named:
 mov esi,NEBOC_DIAG_DUPLICATE_NAMED
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.missing:
 mov esi,NEBOC_DIAG_MISSING_ARGUMENT
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.extra:
 mov esi,NEBOC_DIAG_EXTRA_ARGUMENT
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.type:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_TYPE_MISMATCH
 call seguranca_numerica_conversoes_e_overflow_error
 jmp .done
.syntax:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; EAX type, RDX value, ECX status for literal/receiver/parameter atom.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
eval_atom:
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .identifier
 jmp parse_literal
.identifier:
 mov r13,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rax,r13
 mov rdx,[r12+NEBOC_PARAM_RECEIVER_NAME_OFFSET]
 call token_equal
 test eax,eax
 jz .param
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rax,[r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET]
 mov rdx,[r12+NEBOC_PARAM_RECEIVER_VALUE_OFFSET]
 xor ecx,ecx
 ret
.param:
 mov rax,r13
 call find_param
 test rax,rax
 jz .bad
 mov rdx,[rax+NEBOC_PARAM_BOUND_VALUE_OFFSET]
 mov rax,[rax+NEBOC_PARAM_TYPE_OFFSET]
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 xor ecx,ecx
 ret
.bad:
 xor eax,eax
 xor edx,edx
 mov ecx,NEBOC_STATUS_INVALID_SOURCE
 ret

%undef call
eval_body:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov rax,[r12+NEBOC_PARAM_BODY_START_OFFSET]
 mov [r12+NEBOC_PARAM_CURSOR_OFFSET],rax
 lea rsi,[rel parameters_parser_n_tuple]
 mov edx,n_tuple_len
 call match_current
 test eax,eax
 jnz .tuple
 cmp qword [r12+NEBOC_PARAM_TUPLE_SELECTOR_OFFSET],-1
 jne .return_bad
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call eval_atom
 test ecx,ecx
 jnz .return_bad
 mov r14,rax
 mov r15,rdx
.sum_loop:
 call peek_kind
 cmp eax,NEBOC_TOKEN_PLUS
 jne .sum_done
 cmp r14,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .return_bad
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call eval_atom
 test ecx,ecx
 jnz .return_bad
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .return_bad
 add r15,rdx
 jo .return_bad
 jmp .sum_loop
.sum_done:
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov [r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],r14
 mov [r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],r15
 mov qword [r12+NEBOC_PARAM_RETURN_ARITY_OFFSET],1
 jmp .return_tail
.tuple:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 mov r15,[r12+NEBOC_PARAM_TUPLE_SELECTOR_OFFSET]
 cmp r15,-1
 je .return_bad
 xor ebx,ebx
.tuple_item:
 cmp ebx,NEBOC_PARAM_MAX
 jae .return_bad
 call eval_atom
 test ecx,ecx
 jnz .return_bad
 cmp rbx,r15
 jne .not_selected
 mov [r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],rax
 mov [r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],rdx
.not_selected:
 inc rbx
 call peek_kind
 cmp eax,NEBOC_TOKEN_COMMA
 je .tuple_comma
 cmp eax,NEBOC_TOKEN_RPAREN
 jne .return_bad
 cmp ebx,2
 jb .return_bad
 cmp r15,rbx
 jae .return_bad
 mov [r12+NEBOC_PARAM_RETURN_ARITY_OFFSET],rbx
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 jmp .return_tail
.tuple_comma:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 jmp .tuple_item
.return_tail:
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.return_bad:
 mov esi,NEBOC_DIAG_RETURN
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F03 owns only programs beginning with the explicit overload marker.
; F02 signatures and every historical route therefore keep their old owner.
scan_overload:
 xor eax,eax
 lea rsi,[rel n_overload]
 mov edx,n_overload_len
 jmp seguranca_numerica_conversoes_e_overflow_token_match

; RAX bounded candidate ordinal -> scratch record.
candidate_ptr:
 cmp rax,NEBOC_OVERLOAD_MAX
 jae .bad
 imul rax,NEBOC_PARAM_RECORD_SIZE
 add rax,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; Parse exact scalar, Scalar, or Integral parameter specification.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
parse_param_spec:
 call seguranca_numerica_conversoes_e_overflow_parse_type
 test eax,eax
 jnz .done
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_scalar]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_scalar_len
 call match_current
 test eax,eax
 jnz .scalar
 lea rsi,[rel n_integral]
 mov edx,n_integral_len
 call match_current
 test eax,eax
 jnz .integral
 xor eax,eax
 ret
.scalar:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,NEBOC_SPEC_SCALAR
 ret
.integral:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov eax,NEBOC_SPEC_INTEGRAL
.done:
 ret

; EAX declared constraint, -1 for invalid.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
parse_constraint:
 lea rsi,[rel n_any]
 mov edx,n_any_len
 call match_current
 test eax,eax
 jnz .any
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_scalar]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_scalar_len
 call match_current
 test eax,eax
 jnz .scalar
 lea rsi,[rel n_integral]
 mov edx,n_integral_len
 call match_current
 test eax,eax
 jnz .integral
 lea rsi,[rel n_equatable]
 mov edx,n_equatable_len
 call match_current
 test eax,eax
 jnz .equatable
 mov eax,-1
 ret
.any: xor eax,eax
 jmp .consume
.scalar: mov eax,NEBOC_CONSTRAINT_SCALAR
 jmp .consume
.integral: mov eax,NEBOC_CONSTRAINT_INTEGRAL
 jmp .consume
.equatable: mov eax,NEBOC_CONSTRAINT_EQUATABLE
.consume:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 ret

%undef call
parse_overload_candidate:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,56
 cmp qword [r12+NEBOC_OVERLOAD_COUNT_OFFSET],NEBOC_OVERLOAD_MAX
 jae .abi
 lea rsi,[rel n_overload]
 mov edx,n_overload_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call seguranca_numerica_conversoes_e_overflow_parse_type
 test eax,eax
 jz .signature
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel n_self]
 mov edx,n_self_len
 call match_current
 test eax,eax
 jz .signature
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .signature
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [rsp+8],rax
 cmp qword [r12+NEBOC_OVERLOAD_COUNT_OFFSET],0
 jne .check_name
 mov [r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET],rax
 jmp .name_ready
.check_name:
 mov rdx,[r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET]
 call token_equal
 test eax,eax
 jz .signature
.name_ready:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call parse_param_spec
 test eax,eax
 jz .signature
 mov [rsp+16],rax
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_value]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_value_len
 call match_current
 test eax,eax
 jz .signature
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel n_where]
 mov edx,n_where_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call parse_constraint
 cmp eax,-1
 je .signature
 mov [rsp+24],rax
 lea rsi,[rel n_symbol]
 mov edx,n_symbol_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [rsp+40],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 call parse_literal
 test ecx,ecx
 jnz .return_bad
 cmp eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .return_bad
 mov [rsp+32],rdx
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done

 ; Exact signatures cannot be duplicated and distinct signatures cannot
 ; publish the same declared canonical symbol.
 xor ebx,ebx
.prior:
 cmp rbx,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 jae .store
 mov rax,rbx
 call candidate_ptr
 mov r13,rax
 mov rax,[r13+NEBOC_CANDIDATE_RECEIVER_TYPE_OFFSET]
 cmp rax,[rsp]
 jne .symbol_check
 mov rax,[r13+NEBOC_CANDIDATE_PARAM_SPEC_OFFSET]
 cmp rax,[rsp+16]
 jne .symbol_check
 mov rax,[r13+NEBOC_CANDIDATE_CONSTRAINT_OFFSET]
 cmp rax,[rsp+24]
 je .duplicate
.symbol_check:
 mov rax,[r13+NEBOC_CANDIDATE_SYMBOL_OFFSET]
 mov rdx,[rsp+40]
 call token_equal
 test eax,eax
 jnz .collision
 inc rbx
 jmp .prior
.store:
 mov rax,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 call candidate_ptr
 test rax,rax
 jz .abi
 mov r13,rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_CANDIDATE_NAME_OFFSET],rax
 mov rax,[rsp]
 mov [r13+NEBOC_CANDIDATE_RECEIVER_TYPE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_CANDIDATE_PARAM_SPEC_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_CANDIDATE_CONSTRAINT_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_CANDIDATE_RETURN_VALUE_OFFSET],rax
 mov rax,[rsp+40]
 mov [r13+NEBOC_CANDIDATE_SYMBOL_OFFSET],rax
 inc qword [r12+NEBOC_OVERLOAD_COUNT_OFFSET]

 mov rax,[r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET]
 test rax,rax
 jnz .dispatch_seeded
 mov rax,14695981039346656037
.dispatch_seeded:
 mov rcx,1099511628211
 xor rax,[rsp]
 imul rax,rcx
 xor rax,[rsp+16]
 imul rax,rcx
 xor rax,[rsp+24]
 imul rax,rcx
 xor rax,[rsp+32]
 imul rax,rcx
 mov [r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET],rax
 mov rax,[r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET]
 test rax,rax
 jnz .mangle_seeded
 mov rax,14695981039346656037
.mangle_seeded:
 xor rax,[rsp+8]
 imul rax,rcx
 xor rax,[rsp+40]
 imul rax,rcx
 mov [r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.duplicate:
 mov esi,NEBOC_DIAG_DUPLICATE_SIGNATURE
 jmp .error
.collision:
 inc qword [r12+NEBOC_OVERLOAD_COLLISION_COUNT_OFFSET]
 mov esi,NEBOC_DIAG_MANGLE_COLLISION
 jmp .error
.abi:
 mov esi,NEBOC_DIAG_ABI_BOUND
 jmp .error
.return_bad:
 mov esi,NEBOC_DIAG_RETURN
 jmp .error
.signature:
 mov esi,NEBOC_DIAG_SIGNATURE
 jmp .error
.syntax:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
.error:
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

parse_overload_call:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,56
 cmp qword [r12+NEBOC_OVERLOAD_COUNT_OFFSET],2
 jb .signature
 mov edi,NEBOC_TOKEN_KW_START
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 call parse_literal
 test ecx,ecx
 jnz .no_match
 mov [rsp],rax
 mov [rsp+8],rdx
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov rdx,[r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET]
 call token_equal
 test eax,eax
 jz .no_match
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call parse_literal
 test ecx,ecx
 jnz .no_match
 mov [rsp+16],rax
 mov [rsp+24],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_EOF
 call expect
 test eax,eax
 jnz .done

 xor ebx,ebx
 xor r14d,r14d                 ; best score
 xor r15d,r15d                 ; ambiguity at best score
 xor r13d,r13d                 ; selected pointer
.candidate:
 cmp rbx,[r12+NEBOC_OVERLOAD_COUNT_OFFSET]
 jae .selected
 mov rax,rbx
 call candidate_ptr
 mov r10,rax
 mov rax,[r10+NEBOC_CANDIDATE_RECEIVER_TYPE_OFFSET]
 cmp rax,[rsp]
 jne .next
 mov rax,[r10+NEBOC_CANDIDATE_PARAM_SPEC_OFFSET]
 cmp rax,NEBOC_SPEC_SCALAR
 je .scalar_spec
 cmp rax,NEBOC_SPEC_INTEGRAL
 je .integral_spec
 cmp rax,[rsp+16]
 jne .next
 mov edx,4
 jmp .constraint
.scalar_spec:
 cmp qword [rsp+16],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .next
 mov edx,1
 jmp .constraint
.integral_spec:
 cmp qword [rsp+16],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .next
 mov edx,2
.constraint:
 mov rax,[r10+NEBOC_CANDIDATE_CONSTRAINT_OFFSET]
 cmp rax,NEBOC_CONSTRAINT_ANY
 je .matches
 cmp rax,NEBOC_CONSTRAINT_SCALAR
 je .scalar_constraint
 cmp rax,NEBOC_CONSTRAINT_INTEGRAL
 je .integral_constraint
 cmp rax,NEBOC_CONSTRAINT_EQUATABLE
 jne .next
 mov rax,[rsp]
 cmp rax,[rsp+16]
 jne .next
 jmp .matches
.scalar_constraint:
 cmp qword [rsp+16],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_CHAR
 ja .next
 jmp .matches
.integral_constraint:
 cmp qword [rsp+16],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .next
.matches:
 mov ecx,ebx
 mov rax,1
 shl rax,cl
 or [r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET],rax
 or [r12+NEBOC_OVERLOAD_CONSTRAINT_MASK_OFFSET],rax
 cmp edx,r14d
 jb .next
 je .tie
 mov r14d,edx
 mov r13,r10
 mov [r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET],rbx
 xor r15d,r15d
 jmp .next
.tie:
 mov r15d,1
.next:
 inc rbx
 jmp .candidate
.selected:
 test r13,r13
 jz .no_match
 test r15d,r15d
 jnz .ambiguous
 mov [r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET],r14
 mov rax,[r13+NEBOC_CANDIDATE_RETURN_VALUE_OFFSET]
 mov [rsp+32],rax
 mov rax,[r13+NEBOC_CANDIDATE_SYMBOL_OFFSET]
 mov [rsp+40],rax

 ; Replace scratch candidates with the selected canonical F02 parameter fact.
 mov rdi,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov ecx,(NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov rax,[rsp+40]
 mov [rdi+NEBOC_PARAM_NAME_OFFSET],rax
 mov rax,[rsp+16]
 mov [rdi+NEBOC_PARAM_TYPE_OFFSET],rax
 mov qword [rdi+NEBOC_PARAM_BOUND_OFFSET],1
 mov rax,[rsp+24]
 mov [rdi+NEBOC_PARAM_BOUND_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_PARAM_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_REQUIRED_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_DEFAULT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_PARAM_NAMED_COUNT_OFFSET],0
 mov rax,[rsp]
 mov [r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+NEBOC_PARAM_RECEIVER_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov rax,[rsp+32]
 mov [r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_PARAM_RETURN_ARITY_OFFSET],1
 mov qword [r12+NEBOC_PARAM_TUPLE_SELECTOR_OFFSET],-1
 xor eax,eax
 jmp .done
.ambiguous:
 mov esi,NEBOC_DIAG_AMBIGUOUS_OVERLOAD
 jmp .error
.no_match:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_TYPE_MISMATCH
 jmp .error
.signature:
 mov esi,NEBOC_DIAG_SIGNATURE
 jmp .error
.syntax:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
.error:
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F04 explicit owner marker for bounded function values.
scan_callable:
 xor eax,eax
 lea rsi,[rel n_callable]
 mov edx,n_callable_len
 jmp seguranca_numerica_conversoes_e_overflow_token_match

callable_ptr:
 cmp rax,NEBOC_CALLABLE_MAX
 jae .bad
 imul rax,NEBOC_PARAM_RECORD_SIZE
 add rax,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

parse_callable_declaration:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,56
 cmp qword [r12+NEBOC_CALLABLE_COUNT_OFFSET],NEBOC_CALLABLE_MAX
 jae .capacity
 lea rsi,[rel n_callable]
 mov edx,n_callable_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [rsp],rax
 xor ebx,ebx
.unique:
 cmp rbx,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 jae .unique_ready
 mov rax,rbx
 call callable_ptr
 mov rdx,[rax+NEBOC_CALLABLE_NAME_OFFSET]
 mov rax,[rsp]
 call token_equal
 test eax,eax
 jnz .duplicate
 inc rbx
 jmp .unique
.unique_ready:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call seguranca_numerica_conversoes_e_overflow_parse_type
 test eax,eax
 jz .signature
 mov [rsp+8],rax
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_value]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_value_len
 call match_current
 test eax,eax
 jz .signature
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel n_capture]
 mov edx,n_capture_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 lea rsi,[rel parameters_parser_n_none]
 mov edx,n_none_len
 call match_current
 test eax,eax
 jnz .capture_none
 lea rsi,[rel parameters_parser_n_copy]
 mov edx,n_copy_len
 call match_current
 test eax,eax
 jnz .capture_copy
 lea rsi,[rel parameters_parser_n_move]
 mov edx,n_move_len
 call match_current
 test eax,eax
 jnz .capture_move
 lea rsi,[rel n_borrow]
 mov edx,n_borrow_len
 call match_current
 test eax,eax
 jz .syntax
 mov qword [rsp+16],NEBOC_CAPTURE_BORROW
 jmp .capture_value
.capture_none:
 mov qword [rsp+16],NEBOC_CAPTURE_NONE
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov qword [rsp+24],0
 jmp .body
.capture_copy:
 mov qword [rsp+16],NEBOC_CAPTURE_COPY
 jmp .capture_value
.capture_move:
 mov qword [rsp+16],NEBOC_CAPTURE_MOVE
.capture_value:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 call parse_literal
 test ecx,ecx
 jnz .signature
 cmp eax,neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 jne .signature
 mov [rsp+24],rdx
.body:
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel seguranca_numerica_conversoes_e_overflow_n_value]
 mov edx,seguranca_numerica_conversoes_e_overflow_n_value_len
 call match_current
 test eax,eax
 jnz .body_value
 lea rsi,[rel n_capture]
 mov edx,n_capture_len
 call match_current
 test eax,eax
 jnz .body_capture
 lea rsi,[rel parameters_parser_n_sum]
 mov edx,n_sum_len
 call match_current
 test eax,eax
 jz .syntax
 mov qword [rsp+32],NEBOC_CALLABLE_BODY_SUM
 jmp .body_ready
.body_value:
 mov qword [rsp+32],NEBOC_CALLABLE_BODY_VALUE
 jmp .body_ready
.body_capture:
 mov qword [rsp+32],NEBOC_CALLABLE_BODY_CAPTURE
.body_ready:
 cmp qword [rsp+16],NEBOC_CAPTURE_NONE
 jne .body_valid
 cmp qword [rsp+32],NEBOC_CALLABLE_BODY_VALUE
 jne .signature
.body_valid:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 call callable_ptr
 test rax,rax
 jz .capacity
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_CALLABLE_NAME_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_CALLABLE_PARAM_TYPE_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_CALLABLE_CAPTURE_MODE_RECORD_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_CALLABLE_CAPTURE_VALUE_RECORD_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_CALLABLE_BODY_MODE_OFFSET],rax
 mov qword [r13+NEBOC_CALLABLE_STATE_OFFSET],1
 inc qword [r12+NEBOC_CALLABLE_COUNT_OFFSET]
 mov rax,[r12+NEBOC_CALLABLE_HASH_OFFSET]
 test rax,rax
 jnz .hash_seeded
 mov rax,14695981039346656037
.hash_seeded:
 mov rcx,1099511628211
 xor rax,[rsp]
 imul rax,rcx
 xor rax,[rsp+8]
 imul rax,rcx
 xor rax,[rsp+16]
 imul rax,rcx
 xor rax,[rsp+24]
 imul rax,rcx
 xor rax,[rsp+32]
 imul rax,rcx
 mov [r12+NEBOC_CALLABLE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.duplicate:
 mov esi,NEBOC_DIAG_DUPLICATE_SIGNATURE
 jmp .error
.capacity:
 mov esi,NEBOC_DIAG_CALLABLE_CAPACITY
 jmp .error
.signature:
 mov esi,NEBOC_DIAG_CALLABLE_SIGNATURE
 jmp .error
.syntax:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
.error:
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
find_callable:
 push rbx
 push r13
 mov r13,rax
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_CALLABLE_COUNT_OFFSET]
 jae .none
 mov rax,rbx
 call callable_ptr
 mov rdx,[rax+NEBOC_CALLABLE_NAME_OFFSET]
 mov rax,r13
 call token_equal
 test eax,eax
 jnz .found
 inc rbx
 jmp .loop
.found:
 mov rax,rbx
 call callable_ptr
 mov rdx,rbx
 jmp .done
.none:
 xor eax,eax
 xor edx,edx
.done:
 pop r13
 pop rbx
 ret

%undef call
parse_callable_call:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,56
 mov edi,NEBOC_TOKEN_KW_START
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel n_callback]
 mov edx,n_callback_len
 call match_current
 test eax,eax
 jnz .callback
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [rsp],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 lea rsi,[rel n_call]
 mov edx,n_call_len
 call match_current
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 jmp .argument
.callback:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov [rsp],rax
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_COMMA
 call expect
 test eax,eax
 jnz .done
.argument:
 call parse_literal
 test ecx,ecx
 jnz .signature
 mov [rsp+8],rax
 mov [rsp+16],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 mov rax,[rsp]
 call find_callable
 test rax,rax
 jz .signature
 mov r13,rax
 mov [rsp+24],rdx
 mov rax,[r13+NEBOC_CALLABLE_PARAM_TYPE_OFFSET]
 cmp rax,[rsp+8]
 jne .signature
 mov rax,[r13+NEBOC_CALLABLE_BODY_MODE_OFFSET]
 cmp rax,NEBOC_CALLABLE_BODY_VALUE
 je .body_value
 cmp rax,NEBOC_CALLABLE_BODY_CAPTURE
 je .body_capture
 mov rax,[r13+NEBOC_CALLABLE_CAPTURE_VALUE_RECORD_OFFSET]
 add rax,[rsp+16]
 jo .signature
 jmp .output
.body_value:
 mov rax,[rsp+16]
 jmp .output
.body_capture:
 mov rax,[r13+NEBOC_CALLABLE_CAPTURE_VALUE_RECORD_OFFSET]
.output:
 mov [rsp+32],rax
 mov qword [r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET],1
 xor r15d,r15d
.suffix:
 mov edi,NEBOC_TOKEN_DOT
 call expect
 test eax,eax
 jnz .done
 call peek_kind
 cmp eax,NEBOC_TOKEN_KW_RETURN
 je .return
 lea rsi,[rel parameters_parser_n_drop]
 mov edx,n_drop_len
 call match_current
 test eax,eax
 jz .syntax
 test r15d,r15d
 jnz .double_drop
 mov r15d,1
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call expect
 test eax,eax
 jnz .done
 jmp .suffix
.return:
 inc qword [r12+NEBOC_PARAM_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_EOF
 call expect
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_CALLABLE_CAPTURE_MODE_RECORD_OFFSET]
 cmp rax,NEBOC_CAPTURE_BORROW
 jne .cleanup
 test r15d,r15d
 jz .borrow_escape
.cleanup:
 cmp rax,NEBOC_CAPTURE_NONE
 je .cleanup_ready
 test r15d,r15d
 jnz .cleanup_ready
 mov r15d,1                    ; lexical cleanup for owned environments
.cleanup_ready:
 mov [r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],rax
 mov rdx,[r13+NEBOC_CALLABLE_CAPTURE_VALUE_RECORD_OFFSET]
 mov [r12+NEBOC_CALLABLE_CAPTURE_VALUE_OFFSET],rdx
 mov [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],r15
 xor edx,edx
 cmp rax,NEBOC_CAPTURE_NONE
 je .environment_ready
 mov edx,NEBOC_CALLABLE_ENV_SIZE
.environment_ready:
 mov [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],rdx
 mov rax,[rsp+24]
 mov [r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_CALLABLE_HASH_OFFSET]
 mov rcx,1099511628211
 xor rax,[rsp+24]
 imul rax,rcx
 xor rax,[rsp+8]
 imul rax,rcx
 xor rax,[rsp+16]
 imul rax,rcx
 mov [r12+NEBOC_CALLABLE_HASH_OFFSET],rax

 mov rax,[rsp]
 mov [r12+NEBOC_PARAM_FUNCTION_NAME_OFFSET],rax
 mov rdi,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov ecx,(NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 mov rax,[rsp]
 mov [rdi+NEBOC_PARAM_NAME_OFFSET],rax
 mov rax,[rsp+8]
 mov [rdi+NEBOC_PARAM_TYPE_OFFSET],rax
 mov qword [rdi+NEBOC_PARAM_BOUND_OFFSET],1
 mov rax,[rsp+16]
 mov [rdi+NEBOC_PARAM_BOUND_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_PARAM_RECEIVER_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov qword [r12+NEBOC_PARAM_RECEIVER_VALUE_OFFSET],0
 mov qword [r12+NEBOC_PARAM_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_REQUIRED_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_EXPLICIT_COUNT_OFFSET],1
 mov qword [r12+NEBOC_PARAM_OUTPUT_TYPE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_TYPE_INT
 mov rax,[rsp+32]
 mov [r12+NEBOC_PARAM_OUTPUT_VALUE_OFFSET],rax
 mov qword [r12+NEBOC_PARAM_RETURN_ARITY_OFFSET],1
 xor eax,eax
 jmp .done
.borrow_escape:
 mov esi,NEBOC_DIAG_CLOSURE_BORROW_ESCAPE
 jmp .error
.double_drop:
 mov esi,NEBOC_DIAG_CALLABLE_DOUBLE_DROP
 jmp .error
.signature:
 mov esi,NEBOC_DIAG_CALLABLE_SIGNATURE
 jmp .error
.syntax:
 mov esi,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
.error:
 call seguranca_numerica_conversoes_e_overflow_error
.done:
 add rsp,56
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
parse_callable_program:
.declarations:
 call parse_callable_declaration
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 lea rsi,[rel n_callable]
 mov edx,n_callable_len
 call seguranca_numerica_conversoes_e_overflow_token_match
 test eax,eax
 jnz .declarations
 call parse_callable_call
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
parse_overload_program:
.declarations:
 call parse_overload_candidate
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_PARAM_CURSOR_OFFSET]
 lea rsi,[rel n_overload]
 mov edx,n_overload_len
 call seguranca_numerica_conversoes_e_overflow_token_match
 test eax,eax
 jnz .declarations
 call parse_overload_call
.done:
 ret

%undef call
NEBOC_ABI_FUNCTION neboc_parameters_recognize
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
 mov rax,[r12+NEBOC_PARAM_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_PARAM_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_PARAM_RECORDS_OFFSET]
 test rax,rax
 jz .invalid
 test rax,7
 jnz .invalid
 cmp qword [r12+NEBOC_PARAM_CAPACITY_OFFSET],NEBOC_PARAM_MAX
 jb .invalid
 mov rdi,rax
 mov ecx,(NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 mov qword [r12+NEBOC_PARAM_FOUND_OFFSET],0
 mov qword [r12+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 mov qword [r12+NEBOC_PARAM_CURSOR_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_COUNT_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_CANDIDATE_MASK_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_SELECTED_INDEX_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_SELECTED_SCORE_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_CONSTRAINT_MASK_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_DISPATCH_HASH_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_MANGLE_HASH_OFFSET],0
 mov qword [r12+NEBOC_OVERLOAD_COLLISION_COUNT_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_COUNT_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_CAPTURE_MODE_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_CAPTURE_VALUE_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_CALL_COUNT_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_DROP_COUNT_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_ENV_SIZE_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_SELECTED_INDEX_OFFSET],0
 mov qword [r12+NEBOC_CALLABLE_HASH_OFFSET],0
 call scan_callable
 test eax,eax
 jz .overload_scan
 mov qword [r12+NEBOC_PARAM_FOUND_OFFSET],1
 call parse_callable_program
 jmp .done
.overload_scan:
 call scan_overload
 test eax,eax
 jz .legacy_scan
 mov qword [r12+NEBOC_PARAM_FOUND_OFFSET],1
 call parse_overload_program
 jmp .done
.legacy_scan:
 call scan_marker
 test eax,eax
 jz .not_found
 mov qword [r12+NEBOC_PARAM_FOUND_OFFSET],1
 call parse_signature
 test eax,eax
 jnz .done
 call parse_call
 test eax,eax
 jnz .done
 call eval_body
 jmp .done
.not_found:
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

section .note.GNU-stack noalloc noexec nowrite progbits
