; Nebo Assembly — OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PF005 bounded public Option/Result parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/option_result_api_contract.inc"
%include "compiler/parser/option_result_vertical_parser.inc"

section .rodata
n_option: db "Option"
n_option_len equ $-n_option
n_result: db "Result"
n_result_len equ $-n_result
n_some: db "Some"
n_some_len equ $-n_some
n_none: db "None"
n_none_len equ $-n_none
n_ok: db "Ok"
n_ok_len equ $-n_ok
n_err: db "Err"
n_err_len equ $-n_err
n_is_some: db "isSome"
n_is_some_len equ $-n_is_some
n_is_none: db "isNone"
n_is_none_len equ $-n_is_none
n_is_ok: db "isOk"
n_is_ok_len equ $-n_is_ok
n_is_err: db "isErr"
n_is_err_len equ $-n_is_err
n_unwrap_or: db "unwrapOr"
n_unwrap_or_len equ $-n_unwrap_or
n_unwrap: db "unwrap"
n_unwrap_len equ $-n_unwrap
option_result_vertical_parser_n_get: db "get"
n_get_len equ $-option_result_vertical_parser_n_get
n_null: db "null"
n_null_len equ $-n_null
n_try: db "try"
n_try_len equ $-n_try
n_catch: db "catch"
n_catch_len equ $-n_catch
n_optional: db "Optional"
n_optional_len equ $-n_optional
n_maybe: db "Maybe"
n_maybe_len equ $-n_maybe
n_either: db "Either"
n_either_len equ $-n_either
n_success: db "Success"
n_success_len equ $-n_success
n_failure: db "Failure"
n_failure_len equ $-n_failure
n_box: db "Box"
n_box_len equ $-n_box
n_maybe_value: db "MaybeValue"
n_maybe_value_len equ $-n_maybe_value
n_bool: db "Bool"
n_bool_len equ $-n_bool
n_int: db "Int"
n_int_len equ $-n_int
n_float: db "Float"
n_float_len equ $-n_float
n_char: db "Char"
n_char_len equ $-n_char
n_void: db "Void"
n_void_len equ $-n_void
n_text: db "Text"
n_text_len equ $-n_text
n_bytes: db "Bytes"
n_bytes_len equ $-n_bytes

section .text

; request*, token index -> token* or zero
g06p_token_ptr:
 mov rax,rsi
 cmp rax,[rdi+NEBOC_VPARSE_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_VPARSE_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; request*, token index, bytes*, length -> EAX 1/0
g06p_token_match:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call g06p_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,r15
 jne .no
 mov rax,[r12+NEBOC_VPARSE_SOURCE_OFFSET]
 add rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r15
 jae .yes
 mov dl,[rax+rcx]
 cmp dl,[r14+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, observer token index -> 1 when the current statement is a bounded
; cli_driver Bytes.get chain. Such observers are lowered through the canonical option_result_null_externo_e_erros_tipados
; runtime ABI by text_char_unicode_e_bytes and must not be claimed by the token-level option_result_null_externo_e_erros_tipados grammar.
g06p_statement_has_get:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
.scan:
 test rbx,rbx
 jz .no
 dec rbx
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_SEMICOLON
 je .no
 cmp rcx,NEBOC_TOKEN_LBRACE
 je .no
 cmp rcx,NEBOC_TOKEN_RBRACE
 je .no
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne .scan
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel option_result_vertical_parser_n_get]
 mov ecx,n_get_len
 call g06p_token_match
 test eax,eax
 jz .scan
 mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, diagnostic, token index -> INVALID_SOURCE
g06p_error:
 push rbx
 mov rbx,rdi
 mov [rbx+NEBOC_VPARSE_ERROR_CODE_OFFSET],rsi
 mov [rbx+NEBOC_VPARSE_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call g06p_token_ptr
 test rax,rax
 jz .no_span
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+NEBOC_VPARSE_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+NEBOC_VPARSE_ERROR_END_OFFSET],rcx
.no_span:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

; request*, expected token kind, index -> EAX 0/invalid
; On success RDX receives next index.
g06p_expect_kind:
 push rbx
 mov rbx,rdx
 mov r11,rsi
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp [rax+NEBOC_TOKEN_KIND_OFFSET],r11
 jne .bad
 lea rdx,[rbx+1]
 xor eax,eax
 pop rbx
 ret
.bad:
 mov rdx,rbx
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 call g06p_error
 pop rbx
 ret

; request*, index -> RAX type id, RDX next index
g06p_parse_type:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call g06p_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call g06p_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call g06p_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call g06p_token_match
 test eax,eax
 jnz .char
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_void]
 mov ecx,n_void_len
 call g06p_token_match
 test eax,eax
 jnz .void
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g06p_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call g06p_token_match
 test eax,eax
 jnz .bytes
 xor eax,eax
 jmp .done
.bool: mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 jmp .done
.int: mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 jmp .done
.float: mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 jmp .done
.char: mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
 jmp .done
.void: mov eax,NEBOC_TYPE_VOID
 jmp .done
.text: mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_parser
 jmp .done
.bytes: mov eax,NEBOC_TYPE_BYTES
.done:
 lea rdx,[rbx+1]
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, index ->
; RAX type, RDX data, RCX token index, R8 next index, R9 flags.
g06p_parse_literal:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 call g06p_token_ptr
 test rax,rax
 jz .bad
 mov rcx,rbx
 mov r10,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r10,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp r10,NEBOC_TOKEN_KW_FALSE
 je .false
 cmp r10,NEBOC_TOKEN_INTEGER
 je .integer
 cmp r10,NEBOC_TOKEN_FLOAT
 je .float
 cmp r10,NEBOC_TOKEN_CHAR
 je .char
 jmp .bad
.true:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 mov edx,1
 jmp .ok
.false:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_codegen_scalars_x86_64
 xor edx,edx
 jmp .ok
.integer:
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_codegen_scalars_x86_64
 jmp .ok
.float:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_FLOAT
 mov rdx,rbx
 mov r9d,NEBOC_VOP_FLAG_FLOAT_TOKEN
 jmp .finish
.char:
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_codegen_scalars_x86_64
.ok:
 xor r9d,r9d
.finish:
 lea r8,[rbx+1]
 add rsp,8
 pop r12
 pop rbx
 ret
.bad:
 xor eax,eax
 xor edx,edx
 mov rcx,rbx
 mov r8,rbx
 xor r9d,r9d
 add rsp,8
 pop r12
 pop rbx
 ret

; request* -> RAX operation record or zero
g06p_alloc_operation:
 mov rax,[rdi+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_VPARSE_OPERATION_CAPACITY_OFFSET]
 jae .bad
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rax,[rdi+NEBOC_VPARSE_OPERATIONS_OFFSET]
 push rdi
 mov rdi,rax
 mov ecx,NEBOC_VOP_RECORD_QWORDS
 xor eax,eax
 rep stosq
 pop rdi
 mov rax,[rdi+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rax,[rdi+NEBOC_VPARSE_OPERATIONS_OFFSET]
 inc qword [rdi+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; request* -> detects ownership/deferred syntax. Returns 1 when OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OWNED.
g06p_detect_owner:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 xor r13d,r13d
 xor r15d,r15d
.loop:
 cmp r13,[r12+NEBOC_VPARSE_TOKEN_COUNT_OFFSET]
 jae .done_scan
 mov rdi,r12
 mov rsi,r13
 call g06p_token_ptr
 test rax,rax
 jz .done_scan
 mov r14,rax
 mov rax,[r14+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_KW_MATCH
 je .pattern
 cmp rax,NEBOC_TOKEN_INVALID_CHARACTER
 je .invalid_char
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 %macro MATCH_NAME 3
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel %1]
 mov ecx,%2
 call g06p_token_match
 test eax,eax
 jnz %3
 %endmacro
 MATCH_NAME n_null,n_null_len,.null
 MATCH_NAME n_try,n_try_len,.try
 MATCH_NAME n_catch,n_catch_len,.try
 MATCH_NAME n_optional,n_optional_len,.alias
 MATCH_NAME n_maybe,n_maybe_len,.alias
 MATCH_NAME n_either,n_either_len,.alias
 MATCH_NAME n_success,n_success_len,.alias
 MATCH_NAME n_failure,n_failure_len,.alias
 MATCH_NAME n_box,n_box_len,.generic
 MATCH_NAME n_maybe_value,n_maybe_value_len,.owned
 MATCH_NAME n_option,n_option_len,.owned
 MATCH_NAME n_result,n_result_len,.owned
 MATCH_NAME n_some,n_some_len,.owned
 MATCH_NAME n_none,n_none_len,.owned
 MATCH_NAME n_ok,n_ok_len,.owned
 MATCH_NAME n_err,n_err_len,.owned
 MATCH_NAME n_is_some,n_is_some_len,.owned
 MATCH_NAME n_is_none,n_is_none_len,.owned
 MATCH_NAME n_is_ok,n_is_ok_len,.owned
 MATCH_NAME n_is_err,n_is_err_len,.owned
 MATCH_NAME n_unwrap_or,n_unwrap_or_len,.owned
 MATCH_NAME n_unwrap,n_unwrap_len,.owned
 jmp .next
.invalid_char:
 mov rax,[r12+NEBOC_VPARSE_SOURCE_OFFSET]
 add rax,[r14+NEBOC_TOKEN_START_OFFSET]
 cmp byte [rax],'?'
 je .propagation
 jmp .next
.owned:
 mov rdi,r12
 mov rsi,r13
 call g06p_statement_has_get
 test eax,eax
 jnz .next
 mov r15d,1
 jmp .next
.null:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,NEBOC_DIAG_NULL_FORBIDDEN
 mov rdx,r13
 call g06p_error
 jmp .error
.try:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,NEBOC_DIAG_TRY_CATCH_DEFERRED
 mov rdx,r13
 call g06p_error
 jmp .error
.alias:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_ALIAS_FORBIDDEN
 mov rdx,r13
 call g06p_error
 jmp .error
.generic:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,NEBOC_DIAG_GENERAL_GENERICS_DEFERRED
 mov rdx,r13
 call g06p_error
 jmp .error
.pattern:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,NEBOC_DIAG_PATTERN_MATCH_DEFERRED
 mov rdx,r13
 call g06p_error
 jmp .error
.propagation:
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,NEBOC_DIAG_PROPAGATION_DEFERRED
 mov rdx,r13
 call g06p_error
 jmp .error
.next:
 inc r13
 jmp .loop
.done_scan:
 test r15d,r15d
 jz .not_owned
 mov qword [r12+NEBOC_VPARSE_FOUND_OFFSET],1
 mov eax,1
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.error:
 mov eax,-1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, statement index -> parse a container construction.
; On success RDX=next statement index.
g06p_parse_construct:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,rsi
 mov [rsp],r13                 ; container token
 xor r14d,r14d                 ; container
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_option]
 mov ecx,n_option_len
 call g06p_token_match
 test eax,eax
 jnz .option
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_result]
 mov ecx,n_result_len
 call g06p_token_match
 test eax,eax
 jnz .result
 ; A known option_result_null_externo_e_erros_tipados owner followed by '<' but not Option/Result is unknown.
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 mov rdx,r13
 call g06p_error
 jmp .done
.option: mov r14d,NEBOC_CONTAINER_OPTION
 jmp .container_ready
.result: mov r14d,NEBOC_CONTAINER_RESULT
.container_ready:
 lea rbx,[r13+1]
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LESS
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov qword [rsp+8],0           ; type count
 mov qword [rsp+16],0          ; success type
 mov qword [rsp+24],0          ; error type
.type_loop:
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .type_arity
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 je .types_done
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_type
 mov r15,rax
 mov rbx,rdx
 mov rax,[rsp+8]
 cmp rax,0
 jne .second_type
 mov [rsp+16],r15
 jmp .type_counted
.second_type:
 cmp rax,1
 jne .type_counted
 mov [rsp+24],r15
.type_counted:
 inc qword [rsp+8]
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .type_arity
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne .expect_greater
 inc rbx
 jmp .type_loop
.expect_greater:
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_GREATER
 jne .type_arity
.types_done:
 ; Public structural type arity must be validated before the semantic bridge.
 cmp r14d,NEBOC_CONTAINER_OPTION
 jne .validate_result_type_arity
 cmp qword [rsp+8],1
 jne .type_arity
 jmp .type_arity_valid
.validate_result_type_arity:
 cmp r14d,NEBOC_CONTAINER_RESULT
 jne .type_arity
 cmp qword [rsp+8],2
 jne .type_arity
.type_arity_valid:
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 ; variant identifier
 mov [rsp+32],rbx              ; variant token
 xor r15d,r15d
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_some]
 mov ecx,n_some_len
 call g06p_token_match
 test eax,eax
 jnz .some
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_none]
 mov ecx,n_none_len
 call g06p_token_match
 test eax,eax
 jnz .none
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_ok]
 mov ecx,n_ok_len
 call g06p_token_match
 test eax,eax
 jnz .ok
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_err]
 mov ecx,n_err_len
 call g06p_token_match
 test eax,eax
 jnz .err
 mov rdi,r12
 mov esi,NEBOC_DIAG_VARIANT_MISMATCH
 mov rdx,rbx
 call g06p_error
 jmp .done
.some: mov r15d,NEBOC_VARIANT_SOME
 jmp .variant_ready
.none: mov r15d,NEBOC_VARIANT_NONE_VALUE
 jmp .variant_ready
.ok: mov r15d,NEBOC_VARIANT_OK
 jmp .variant_ready
.err: mov r15d,NEBOC_VARIANT_ERR
.variant_ready:
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov qword [rsp+40],0          ; arg count
 mov qword [rsp+48],0          ; value type
 mov qword [rsp+56],0          ; value data
 mov qword [rsp+64],-1         ; value token
 mov qword [rsp+72],0          ; flags
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .variant_arity
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .variant_args_done
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_literal
 test eax,eax
 jz .variant_arity
 mov [rsp+48],rax
 mov [rsp+56],rdx
 mov [rsp+64],rcx
 mov [rsp+72],r9
 mov rbx,r8
 inc qword [rsp+40]
 ; Count any extra literal args so the API contract owns arity diagnostics.
.extra_variant_args:
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .variant_arity
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne .variant_args_done
 inc rbx
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_literal
 test eax,eax
 jz .variant_arity
 mov rbx,r8
 inc qword [rsp+40]
 jmp .extra_variant_args
.variant_args_done:
 mov rdi,r12
 mov esi,NEBOC_TOKEN_RPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_RPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_DOT
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov [rsp+80],rbx              ; binding token
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_SEMICOLON
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 call g06p_alloc_operation
 test rax,rax
 jz .internal
 mov qword [rax+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 mov [rax+NEBOC_VOP_CONTAINER_OFFSET],r14
 mov rcx,[rsp+16]
 mov [rax+NEBOC_VOP_SUCCESS_TYPE_OFFSET],rcx
 mov rcx,[rsp+24]
 mov [rax+NEBOC_VOP_ERROR_TYPE_OFFSET],rcx
 mov [rax+NEBOC_VOP_VARIANT_OBSERVER_OFFSET],r15
 mov rcx,[rsp+40]
 mov [rax+NEBOC_VOP_ARGUMENT_COUNT_OFFSET],rcx
 mov rcx,[rsp+48]
 mov [rax+NEBOC_VOP_VALUE_TYPE_OFFSET],rcx
 mov rcx,[rsp+56]
 mov [rax+NEBOC_VOP_VALUE_DATA_OFFSET],rcx
 mov rcx,[rsp+64]
 mov [rax+NEBOC_VOP_VALUE_TOKEN_OFFSET],rcx
 mov qword [rax+NEBOC_VOP_RECEIVER_TOKEN_OFFSET],-1
 mov rcx,[rsp+80]
 mov [rax+NEBOC_VOP_BINDING_TOKEN_OFFSET],rcx
 mov rcx,[rsp]
 mov [rax+NEBOC_VOP_SUBJECT_TOKEN_OFFSET],rcx
 mov rdi,r12
 mov rsi,[rsp]
 call g06p_token_ptr
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rdi,r12
 mov rsi,[rsp+80]
 call g06p_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rdi,[r12+NEBOC_VPARSE_OPERATIONS_OFFSET]
 mov rax,[r12+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rdi,rax
 mov [rdi+NEBOC_VOP_START_OFFSET],rcx
 mov [rdi+NEBOC_VOP_END_OFFSET],rdx
 mov rcx,[rsp+72]
 mov [rdi+NEBOC_VOP_FLAGS_OFFSET],rcx
 mov rdx,rbx
 xor eax,eax
 jmp .done
.type_arity:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_ARITY
 mov rdx,[rsp]
 call g06p_error
 jmp .done
.variant_arity:
 mov rdi,r12
 mov esi,NEBOC_DIAG_VARIANT_ARITY
 mov rdx,[rsp+32]
 call g06p_error
 jmp .done
.syntax:
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 mov rdx,rbx
 call g06p_error
 jmp .done
.internal:
 mov rdi,r12
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_parser
 mov rdx,[rsp]
 call g06p_error
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, statement index -> parse None()/Some()/Ok()/Err() without context.
g06p_parse_context_missing:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,56
 mov r12,rdi
 mov r13,rsi
 mov [rsp],r13
 xor r14d,r14d
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_some]
 mov ecx,n_some_len
 call g06p_token_match
 test eax,eax
 jnz .some
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_none]
 mov ecx,n_none_len
 call g06p_token_match
 test eax,eax
 jnz .none
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_ok]
 mov ecx,n_ok_len
 call g06p_token_match
 test eax,eax
 jnz .ok
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_err]
 mov ecx,n_err_len
 call g06p_token_match
 test eax,eax
 jnz .err
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 mov rdx,r13
 call g06p_error
 jmp .done
.some: mov r14d,NEBOC_VARIANT_SOME
 jmp .variant
.none: mov r14d,NEBOC_VARIANT_NONE_VALUE
 jmp .variant
.ok: mov r14d,NEBOC_VARIANT_OK
 jmp .variant
.err: mov r14d,NEBOC_VARIANT_ERR
.variant:
 lea rbx,[r13+1]
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 mov qword [rsp+32],-1
 mov qword [rsp+40],NEBOC_VOP_FLAG_CONTEXT_MISSING
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .args_done
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_literal
 test eax,eax
 jz .bad
 mov [rsp+16],rax
 mov [rsp+24],rdx
 mov [rsp+32],rcx
 or [rsp+40],r9
 mov rbx,r8
 inc qword [rsp+8]
.args_done:
 mov rdi,r12
 mov esi,NEBOC_TOKEN_RPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_DOT
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov r10,rbx
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_SEMICOLON
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 call g06p_alloc_operation
 test rax,rax
 jz .bad
 mov qword [rax+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_CONSTRUCT
 mov qword [rax+NEBOC_VOP_CONTAINER_OFFSET],NEBOC_CONTAINER_NONE
 mov qword [rax+NEBOC_VOP_SUCCESS_TYPE_OFFSET],NEBOC_TYPE_NONE
 mov qword [rax+NEBOC_VOP_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 mov [rax+NEBOC_VOP_VARIANT_OBSERVER_OFFSET],r14
 ; Context-missing forms are rejected semantically before payload detail matters.
 mov qword [rax+NEBOC_VOP_ARGUMENT_COUNT_OFFSET],0
 mov qword [rax+NEBOC_VOP_VALUE_TYPE_OFFSET],NEBOC_TYPE_NONE
 mov qword [rax+NEBOC_VOP_VALUE_DATA_OFFSET],0
 mov qword [rax+NEBOC_VOP_VALUE_TOKEN_OFFSET],-1
 mov qword [rax+NEBOC_VOP_RECEIVER_TOKEN_OFFSET],-1
 mov [rax+NEBOC_VOP_BINDING_TOKEN_OFFSET],r10
 mov [rax+NEBOC_VOP_SUBJECT_TOKEN_OFFSET],r13
 mov qword [rax+NEBOC_VOP_FLAGS_OFFSET],NEBOC_VOP_FLAG_CONTEXT_MISSING
 mov rdi,r12
 mov rsi,r13
 call g06p_token_ptr
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r12
 mov rsi,r10
 call g06p_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rdi,[r12+NEBOC_VPARSE_OPERATIONS_OFFSET]
 mov rax,[r12+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rdi,rax
 mov [rdi+NEBOC_VOP_START_OFFSET],rcx
 mov [rdi+NEBOC_VOP_END_OFFSET],rdx
 mov rdx,rbx
 xor eax,eax
 jmp .done
.bad:
 mov rdi,r12
 mov esi,NEBOC_DIAG_CONTEXT_REQUIRED
 mov rdx,r13
 call g06p_error
.done:
 add rsp,56
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, statement index -> parse receiver.observer(args).binding;
g06p_parse_observer:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov [rsp],r13                 ; receiver token
 lea rbx,[r13+1]
 mov rdi,r12
 mov esi,NEBOC_TOKEN_DOT
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov [rsp+8],rbx              ; observer token
 xor r14d,r14d
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_some]
 mov ecx,n_is_some_len
 call g06p_token_match
 test eax,eax
 jnz .is_some
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_none]
 mov ecx,n_is_none_len
 call g06p_token_match
 test eax,eax
 jnz .is_none
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_ok]
 mov ecx,n_is_ok_len
 call g06p_token_match
 test eax,eax
 jnz .is_ok
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_err]
 mov ecx,n_is_err_len
 call g06p_token_match
 test eax,eax
 jnz .is_err
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_unwrap_or]
 mov ecx,n_unwrap_or_len
 call g06p_token_match
 test eax,eax
 jnz .unwrap_or
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_unwrap]
 mov ecx,n_unwrap_len
 call g06p_token_match
 test eax,eax
 jnz .fatal
 mov rdi,r12
 mov esi,NEBOC_DIAG_OBSERVER_UNKNOWN
 mov rdx,rbx
 call g06p_error
 jmp .done
.is_some: mov r14d,NEBOC_OBSERVER_IS_SOME
 jmp .observer_ready
.is_none: mov r14d,NEBOC_OBSERVER_IS_NONE
 jmp .observer_ready
.is_ok: mov r14d,NEBOC_OBSERVER_IS_OK
 jmp .observer_ready
.is_err: mov r14d,NEBOC_OBSERVER_IS_ERR
 jmp .observer_ready
.unwrap_or: mov r14d,NEBOC_OBSERVER_UNWRAP_OR
 jmp .observer_ready
.fatal:
 mov rdi,r12
 mov esi,NEBOC_DIAG_FATAL_UNWRAP_DEFERRED
 mov rdx,rbx
 call g06p_error
 jmp .done
.observer_ready:
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov qword [rsp+16],0          ; arg count
 mov qword [rsp+24],0          ; value type
 mov qword [rsp+32],0          ; value data
 mov qword [rsp+40],-1         ; value token
 mov qword [rsp+48],0          ; flags
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .args_done
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_literal
 test eax,eax
 jz .bad
 mov [rsp+24],rax
 mov [rsp+32],rdx
 mov [rsp+40],rcx
 mov [rsp+48],r9
 mov rbx,r8
 inc qword [rsp+16]
.extra_args:
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_COMMA
 jne .args_done
 inc rbx
 mov rdi,r12
 mov rsi,rbx
 call g06p_parse_literal
 test eax,eax
 jz .bad
 mov rbx,r8
 inc qword [rsp+16]
 jmp .extra_args
.args_done:
 mov rdi,r12
 mov esi,NEBOC_TOKEN_RPAREN
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_DOT
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov r15,rbx
 inc rbx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_SEMICOLON
 mov rdx,rbx
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov rbx,rdx
 mov rdi,r12
 call g06p_alloc_operation
 test rax,rax
 jz .bad
 mov qword [rax+NEBOC_VOP_KIND_OFFSET],NEBOC_VOP_OBSERVER
 mov qword [rax+NEBOC_VOP_CONTAINER_OFFSET],NEBOC_CONTAINER_NONE
 mov qword [rax+NEBOC_VOP_SUCCESS_TYPE_OFFSET],NEBOC_TYPE_NONE
 mov qword [rax+NEBOC_VOP_ERROR_TYPE_OFFSET],NEBOC_TYPE_NONE
 mov [rax+NEBOC_VOP_VARIANT_OBSERVER_OFFSET],r14
 mov rcx,[rsp+16]
 mov [rax+NEBOC_VOP_ARGUMENT_COUNT_OFFSET],rcx
 mov rcx,[rsp+24]
 mov [rax+NEBOC_VOP_VALUE_TYPE_OFFSET],rcx
 mov rcx,[rsp+32]
 mov [rax+NEBOC_VOP_VALUE_DATA_OFFSET],rcx
 mov rcx,[rsp+40]
 mov [rax+NEBOC_VOP_VALUE_TOKEN_OFFSET],rcx
 mov rcx,[rsp]
 mov [rax+NEBOC_VOP_RECEIVER_TOKEN_OFFSET],rcx
 mov [rax+NEBOC_VOP_BINDING_TOKEN_OFFSET],r15
 mov rcx,[rsp+8]
 mov [rax+NEBOC_VOP_SUBJECT_TOKEN_OFFSET],rcx
 mov rcx,[rsp+48]
 mov [rax+NEBOC_VOP_FLAGS_OFFSET],rcx
 mov rdi,r12
 mov rsi,[rsp]
 call g06p_token_ptr
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,r12
 mov rsi,r15
 call g06p_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rdi,[r12+NEBOC_VPARSE_OPERATIONS_OFFSET]
 mov rax,[r12+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_VOP_RECORD_SIZE
 add rdi,rax
 mov [rdi+NEBOC_VOP_START_OFFSET],rcx
 mov [rdi+NEBOC_VOP_END_OFFSET],rdx
 mov rdx,rbx
 xor eax,eax
 jmp .done
.bad:
 mov rdi,r12
 mov esi,NEBOC_DIAG_OBSERVER_ARITY
 mov rdx,[rsp+8]
 call g06p_error
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_option_result_vertical_parse
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov rax,[r12+NEBOC_VPARSE_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VPARSE_TOKENS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VPARSE_OPERATIONS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_VPARSE_OPERATION_CAPACITY_OFFSET],1
 jb .invalid
 lea rdi,[r12+NEBOC_VPARSE_FOUND_OFFSET]
 mov ecx,(NEBOC_VPARSE_REQUEST_SIZE-NEBOC_VPARSE_FOUND_OFFSET)/8
 xor eax,eax
 rep stosq
 mov rdi,r12
 call g06p_detect_owner
 cmp eax,-1
 je .source_error
 test eax,eax
 jz .not_owned
 ; Exact bounded public grammar: start() { statements }
 xor r13d,r13d
 mov rdi,r12
 mov esi,NEBOC_TOKEN_KW_START
 mov rdx,r13
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov r13,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LPAREN
 mov rdx,r13
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov r13,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_RPAREN
 mov rdx,r13
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov r13,rdx
 mov rdi,r12
 mov esi,NEBOC_TOKEN_LBRACE
 mov rdx,r13
 call g06p_expect_kind
 test eax,eax
 jnz .done
 mov r13,rdx
.statement_loop:
 mov rdi,r12
 mov rsi,r13
 call g06p_token_ptr
 test rax,rax
 jz .syntax
 mov r14,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r14,NEBOC_TOKEN_RBRACE
 je .body_done
 cmp r14,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 ; Container constructors.
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_option]
 mov ecx,n_option_len
 call g06p_token_match
 test eax,eax
 jnz .construct
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_result]
 mov ecx,n_result_len
 call g06p_token_match
 test eax,eax
 jnz .construct
 ; Context-missing variants.
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_some]
 mov ecx,n_some_len
 call g06p_token_match
 test eax,eax
 jnz .context_missing
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_none]
 mov ecx,n_none_len
 call g06p_token_match
 test eax,eax
 jnz .context_missing
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_ok]
 mov ecx,n_ok_len
 call g06p_token_match
 test eax,eax
 jnz .context_missing
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel n_err]
 mov ecx,n_err_len
 call g06p_token_match
 test eax,eax
 jnz .context_missing
 ; Unknown generic container is owned and diagnosed.
 lea rbx,[r13+1]
 mov rdi,r12
 mov rsi,rbx
 call g06p_token_ptr
 test rax,rax
 jz .observer
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 je .unknown_container
.observer:
 mov rdi,r12
 mov rsi,r13
 call g06p_parse_observer
 test eax,eax
 jnz .done
 mov r13,rdx
 jmp .statement_loop
.construct:
 mov rdi,r12
 mov rsi,r13
 call g06p_parse_construct
 test eax,eax
 jnz .done
 mov r13,rdx
 jmp .statement_loop
.context_missing:
 mov rdi,r12
 mov rsi,r13
 call g06p_parse_context_missing
 test eax,eax
 jnz .done
 mov r13,rdx
 jmp .statement_loop
.unknown_container:
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 mov rdx,r13
 call g06p_error
 jmp .done
.body_done:
 inc r13
 mov rdi,r12
 mov rsi,r13
 call g06p_token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_EOF
 jne .syntax
 ; Hash parsed operation stream metadata.
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_VPARSE_ERROR_CODE_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_VPARSE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax:
 mov rdi,r12
 mov esi,NEBOC_DIAG_UNKNOWN_CONTAINER
 mov rdx,r13
 call g06p_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.source_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
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
