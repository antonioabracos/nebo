; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F02 structural bounded parser/typechecker for named structs/Tuple.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/struct_tuple.inc"

section .rodata
n_int: db "Int"
n_int_len equ $-n_int
n_bool: db "Bool"
n_bool_len equ $-n_bool
n_char: db "Char"
n_char_len equ $-n_char
n_text: db "Text"
n_text_len equ $-n_text
n_tuple: db "Tuple"
n_tuple_len equ $-n_tuple
n_of: db "of"
n_of_len equ $-n_of
n_at: db "at"
n_at_len equ $-n_at
n_length: db "length"
n_length_len equ $-n_length
n_destructure: db "destructure"
n_destructure_len equ $-n_destructure
n_map_each: db "mapEach"
n_map_each_len equ $-n_map_each
n_to_struct: db "toStruct"
n_to_struct_len equ $-n_to_struct
n_update: db "update"
n_update_len equ $-n_update
n_default: db "default"
n_default_len equ $-n_default
n_layout: db "layout"
n_layout_len equ $-n_layout
n_self: db "self"
n_self_len equ $-n_self
n_wildcard: db "_"
n_wildcard_len equ $-n_wildcard

section .text

; recognize(request*) -> Status. The pass owns a source only when the token
; stream contains a real `struct` declaration or a Tuple constructor.
; Declaration-only entry for the common Program AST. It uses exactly the same
; name/type/layout parser and does not claim or evaluate a start body.
NEBOC_ABI_FUNCTION neboc_struct_declarations_recognize
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
 cmp qword [r12+NEBOC_ST_SOURCE_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_ST_TOKENS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_ST_DECLS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_ST_DECL_CAPACITY_OFFSET],NEBOC_ST_MAX_DECLS
 jb .invalid
 lea rdi,[r12+NEBOC_ST_FOUND_OFFSET]
 mov ecx,(NEBOC_ST_REQUEST_SIZE-NEBOC_ST_FOUND_OFFSET)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_ST_DECLS_OFFSET]
 mov ecx,NEBOC_ST_MAX_DECLS*NEBOC_DECL_QWORDS
 rep stosq
.declaration:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_KW_STRUCT
 jne .success
 mov qword [r12+NEBOC_ST_FOUND_OFFSET],1
 call st_parse_decl
 test eax,eax
 jnz .done
 jmp .declaration
.success:
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

NEBOC_ABI_FUNCTION neboc_struct_tuple_recognize
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
 lea rdi,[r12+NEBOC_ST_FOUND_OFFSET]
 mov ecx,60
 xor eax,eax
 rep stosq
 mov r13,[r12+NEBOC_ST_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_ST_TOKEN_COUNT_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_ST_DECLS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_ST_DECL_CAPACITY_OFFSET],NEBOC_ST_MAX_DECLS
 jb .invalid
 mov rax,[r12+NEBOC_ST_VALUES_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_ST_VALUE_CAPACITY_OFFSET],NEBOC_ST_MAX_VALUES
 jb .invalid
 mov rax,[r12+NEBOC_ST_BINDINGS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_ST_BINDING_CAPACITY_OFFSET],NEBOC_ST_MAX_BINDINGS
 jb .invalid
 ; Clear caller-owned bounded stores before inspecting them.
 mov rdi,[r12+NEBOC_ST_DECLS_OFFSET]
 mov ecx,(NEBOC_ST_MAX_DECLS*NEBOC_DECL_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_ST_VALUES_OFFSET]
 mov ecx,(NEBOC_ST_MAX_VALUES*NEBOC_VALUE_SIZE)/8
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_ST_BINDINGS_OFFSET]
 mov ecx,(NEBOC_ST_MAX_BINDINGS*NEBOC_BINDING_SIZE)/8
 xor eax,eax
 rep stosq
 ; Structural ownership scan.
 xor ebx,ebx
.claim_scan:
 cmp rbx,r14
 jae .not_owned
 mov rax,rbx
 call st_token_ptr
 test rax,rax
 jz .not_owned
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_STRUCT
 je .claimed
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .claim_next
 mov rdi,rbx
 lea rsi,[rel n_tuple]
 mov edx,n_tuple_len
 call st_token_match
 test eax,eax
 jz .claim_next
 mov rax,rbx
 inc rax
 call st_kind_at
 cmp rax,NEBOC_TOKEN_LPAREN
 je .claimed
 cmp rax,NEBOC_TOKEN_DOT
 jne .claim_next
 mov rax,rbx
 add rax,2
 mov rdi,rax
 lea rsi,[rel n_of]
 mov edx,n_of_len
 call st_token_match
 test eax,eax
 jz .claim_next
 mov rax,rbx
 add rax,3
 call st_kind_at
 cmp rax,NEBOC_TOKEN_LPAREN
 je .claimed
.claim_next:
 inc rbx
 jmp .claim_scan
.claimed:
 mov qword [r12+NEBOC_ST_FOUND_OFFSET],1
 call st_detect_features
 mov qword [r12+NEBOC_ST_CURSOR_OFFSET],0
.decl_loop:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_KW_STRUCT
 je .parse_decl
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .start
 call st_is_method_prefix
 test eax,eax
 jnz .parse_method
 jmp .start
.parse_decl:
 call st_parse_decl
 test eax,eax
 jnz .done
 jmp .decl_loop
.parse_method:
 call st_parse_method
 test eax,eax
 jnz .done
 jmp .decl_loop
.start:
 mov edi,NEBOC_TOKEN_KW_START
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call st_expect
 test eax,eax
 jnz .done
.statement:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .end_start
 cmp rax,NEBOC_TOKEN_EOF
 je .syntax_here
 call st_parse_expr
 test rax,rax
 jz .done
 mov r13,rax
 mov edi,NEBOC_TOKEN_SEMICOLON
 call st_expect
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 mov [r12+NEBOC_ST_RESULT_TYPE_OFFSET],rax
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 je .scalar_result
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 je .scalar_result
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical
 je .scalar_result
 xor eax,eax
 jmp .store_result
.scalar_result:
 mov rax,[r13+NEBOC_VALUE_MEMBERS_OFFSET]
.store_result:
 mov [r12+NEBOC_ST_RESULT_VALUE_OFFSET],rax
 mov rax,[r13+NEBOC_VALUE_SIZE_OFFSET]
 mov [r12+NEBOC_ST_LAYOUT_SIZE_OFFSET],rax
 mov rax,[r13+NEBOC_VALUE_ALIGN_OFFSET]
 mov [r12+NEBOC_ST_LAYOUT_ALIGN_OFFSET],rax
 jmp .statement
.end_start:
 mov edi,NEBOC_TOKEN_RBRACE
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_EOF
 jne .syntax_here
 call st_semantic_hash
 mov [r12+NEBOC_ST_SEMANTIC_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.syntax_here:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
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
 cld
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; Publish aggregate-extension routing facts directly from real identifier
; tokens before semantic parsing. This keeps malformed calls on the same
; authoritative owner and prevents older whole-source routes from relabeling
; their diagnostics.
st_detect_features:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,r14
 jae .done
 mov rax,rbx
 call st_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 lea rsi,[rel n_update]
 mov edx,n_update_len
 call st_token_match
 test eax,eax
 jnz .update
 mov rdi,rbx
 lea rsi,[rel n_default]
 mov edx,n_default_len
 call st_token_match
 test eax,eax
 jnz .default
 mov rdi,rbx
 lea rsi,[rel n_layout]
 mov edx,n_layout_len
 call st_token_match
 test eax,eax
 jnz .layout
 mov rdi,rbx
 lea rsi,[rel n_map_each]
 mov edx,n_map_each_len
 call st_token_match
 test eax,eax
 jnz .map
 mov rdi,rbx
 lea rsi,[rel n_to_struct]
 mov edx,n_to_struct_len
 call st_token_match
 test eax,eax
 jnz .to_struct
 jmp .next
.update: or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_UPDATE
 jmp .next
.default: or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_DEFAULT
 jmp .next
.layout: or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_LAYOUT
 jmp .next
.map: or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_MAP_EACH
 jmp .next
.to_struct: or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_TO_STRUCT
.next:
 inc rbx
 jmp .scan
.done:
 pop rbx
 ret

; EAX=1 only for the exact aggregate-method prefix
; `(Type.self)name()`. Parameterized/defaulted receiver-first functions stay
; with the shared function owner even when their bodies construct Tuples.
st_is_method_prefix:
 sub rsp,8
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 inc rax
 call st_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rax,2
 call st_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .no
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rdi,3
 lea rsi,[rel n_self]
 mov edx,n_self_len
 call st_token_match
 test eax,eax
 jz .no
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rax,4
 call st_kind_at
 cmp rax,NEBOC_TOKEN_RPAREN
 jne .no
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rax,5
 call st_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rax,6
 call st_kind_at
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .no
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 add rax,7
 call st_kind_at
 cmp rax,NEBOC_TOKEN_RPAREN
 jne .no
 mov eax,1
 add rsp,8
 ret
.no:
 xor eax,eax
 add rsp,8
 ret

; Parse one declaration using source-order A0 layout.
st_parse_decl:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 mov edi,NEBOC_TOKEN_KW_STRUCT
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 call st_find_decl
 test rax,rax
 jnz .duplicate_type
 cmp qword [r12+NEBOC_ST_DECL_COUNT_OFFSET],NEBOC_ST_MAX_DECLS
 jae .overflow
 mov rax,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov r13,rax
 mov [r13+NEBOC_DECL_NAME_OFFSET],r14
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LBRACE
 call st_expect
 test eax,eax
 jnz .done
 xor ebx,ebx                    ; field count
 mov qword [rsp],0             ; cursor bytes
 mov qword [rsp+8],1           ; max alignment
 mov qword [rsp+16],0          ; drop leaves
.field:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .fields_done
 cmp rbx,NEBOC_ST_MAX_FIELDS
 jae .arity
 mov rdi,r13
 call st_parse_type
 test rax,rax
 jz .done
 mov [r13+NEBOC_DECL_FIELD_TYPES_OFFSET+rbx*8],rax
 mov [rsp+24],rdx              ; size
 mov [rsp+32],rcx              ; align
 add [rsp+16],r8
 jc .overflow
 mov edi,NEBOC_TOKEN_DOT
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[r12+NEBOC_ST_CURSOR_OFFSET]
 xor ecx,ecx
.field_duplicate:
 cmp rcx,rbx
 jae .field_unique
 mov rdi,r15
 mov rsi,[r13+NEBOC_DECL_FIELD_NAMES_OFFSET+rcx*8]
 call st_name_equal
 test eax,eax
 jnz .duplicate_field
 inc rcx
 jmp .field_duplicate
.field_unique:
 mov [r13+NEBOC_DECL_FIELD_NAMES_OFFSET+rbx*8],r15
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call st_expect
 test eax,eax
 jnz .done
 mov rcx,[rsp+32]
 cmp rcx,[rsp+8]
 jbe .field_align_ready
 mov [rsp+8],rcx
.field_align_ready:
 lea rdx,[rcx-1]
 mov rax,[rsp]
 add rax,rdx
 jc .overflow
 not rdx
 and rax,rdx
 mov [r13+NEBOC_DECL_FIELD_OFFSETS_OFFSET+rbx*8],rax
 add rax,[rsp+24]
 jc .overflow
 cmp rax,NEBOC_ST_MAX_LAYOUT
 ja .overflow
 mov [rsp],rax
 inc rbx
 jmp .field
.fields_done:
 test rbx,rbx
 jz .arity
 mov edi,NEBOC_TOKEN_RBRACE
 call st_expect
 test eax,eax
 jnz .done
 mov rcx,[rsp+8]
 lea rdx,[rcx-1]
 mov rax,[rsp]
 add rax,rdx
 jc .overflow
 not rdx
 and rax,rdx
 cmp rax,NEBOC_ST_MAX_LAYOUT
 ja .overflow
 mov [r13+NEBOC_DECL_FIELD_COUNT_OFFSET],rbx
 mov [r13+NEBOC_DECL_SIZE_OFFSET],rax
 mov [r13+NEBOC_DECL_ALIGN_OFFSET],rcx
 mov rdx,[rsp+16]
 mov [r13+NEBOC_DECL_DROP_COUNT_OFFSET],rdx
 mov rdi,r13
 mov ecx,NEBOC_DECL_HASH_OFFSET
 call st_hash_bytes
 mov [r13+NEBOC_DECL_HASH_OFFSET],rax
 inc qword [r12+NEBOC_ST_DECL_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.duplicate_type:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 jmp .error_current
.duplicate_field:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_DUPLICATE_FIELD
 mov rdx,r15
 call st_error
 jmp .done
.arity:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 jmp .error_current
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 jmp .error_current
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error_current:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.done:
 cmp qword [r12+NEBOC_ST_DIAGNOSTIC_OFFSET],0
 je .status_ready
 test eax,eax
 jnz .status_ready
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.status_ready:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse one bounded receiver-first method declaration.  Methods are stored in
; the semantic request by receiver TypeKey and source name, so calls on two
; distinct struct declarations cannot alias.  The public bounded bodies are
; identity, checked Int addition, and a typed struct-field projection.
st_parse_method:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_METHOD
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call st_token_match
 test eax,eax
 jnz .receiver_int
 mov rdi,r14
 lea rsi,[rel n_bool]
 mov edx,n_bool_len
 call st_token_match
 test eax,eax
 jnz .receiver_bool
 mov rdi,r14
 lea rsi,[rel n_char]
 mov edx,n_char_len
 call st_token_match
 test eax,eax
 jnz .receiver_char
 mov rdi,r14
 call st_find_decl
 test rax,rax
 jz .type
 mov rax,rdx
 add rax,NEBOC_TYPE_STRUCT_BASE
 mov [rsp],rax
 jmp .receiver_ready
.receiver_int:
 mov qword [rsp],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 jmp .receiver_ready
.receiver_bool:
 mov qword [rsp],neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 jmp .receiver_ready
.receiver_char:
 mov qword [rsp],neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical
.receiver_ready:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call st_expect
 test eax,eax
 jnz .done
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 lea rsi,[rel n_self]
 mov edx,n_self_len
 call st_token_match
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov [rsp+8],r14
 ; Duplicate receiver/name pairs are ambiguous and fail closed.
 xor ebx,ebx
.duplicate_scan:
 cmp rbx,[r12+NEBOC_ST_METHOD_COUNT_OFFSET]
 jae .name_unique
 mov rax,rbx
 imul rax,NEBOC_ST_METHOD_SIZE
 lea r13,[r12+NEBOC_ST_METHODS_OFFSET+rax]
 mov rax,[r13+NEBOC_ST_METHOD_RECEIVER_TYPE_OFFSET]
 cmp rax,[rsp]
 jne .duplicate_next
 mov rdi,r14
 mov rsi,[r13+NEBOC_ST_METHOD_NAME_OFFSET]
 call st_name_equal
 test eax,eax
 jnz .syntax
.duplicate_next:
 inc rbx
 jmp .duplicate_scan
.name_unique:
 cmp qword [r12+NEBOC_ST_METHOD_COUNT_OFFSET],NEBOC_ST_MAX_METHODS
 jae .overflow
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LBRACE
 call st_expect
 test eax,eax
 jnz .done
 ; identity: self.return;
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 lea rsi,[rel n_self]
 mov edx,n_self_len
 call st_token_match
 test eax,eax
 jnz .identity
 ; checked Int add: (self + integer).return;
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .syntax
 cmp qword [rsp],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 jne .type
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 lea rsi,[rel n_self]
 mov edx,n_self_len
 call st_token_match
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_PLUS
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .type
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp+24],rax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov qword [rsp+16],NEBOC_ST_METHOD_ADD
 mov rax,[rsp]
 mov [rsp+32],rax
 jmp .return_tail
.identity:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_DOT
 jne .syntax
 ; A struct receiver followed by `.field.return` is a method projection.
 mov rax,[rsp]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jb .identity_tail
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rax,[rsp]
 sub rax,NEBOC_TYPE_STRUCT_BASE
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov r13,rax
 xor ebx,ebx
.field_scan:
 cmp rbx,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .type
 mov rdi,r15
 mov rsi,[r13+NEBOC_DECL_FIELD_NAMES_OFFSET+rbx*8]
 call st_name_equal
 test eax,eax
 jnz .field_found
 inc rbx
 jmp .field_scan
.field_found:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov qword [rsp+16],NEBOC_ST_METHOD_FIELD
 mov [rsp+24],rbx
 mov rax,[r13+NEBOC_DECL_FIELD_TYPES_OFFSET+rbx*8]
 mov [rsp+32],rax
 jmp .return_tail
.identity_tail:
 mov qword [rsp+16],NEBOC_ST_METHOD_IDENTITY
 mov qword [rsp+24],0
 mov rax,[rsp]
 mov [rsp+32],rax
.return_tail:
 mov edi,NEBOC_TOKEN_DOT
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_KW_RETURN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_SEMICOLON
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RBRACE
 call st_expect
 test eax,eax
 jnz .done
 mov rax,[r12+NEBOC_ST_METHOD_COUNT_OFFSET]
 imul rax,NEBOC_ST_METHOD_SIZE
 lea r13,[r12+NEBOC_ST_METHODS_OFFSET+rax]
 mov rax,[rsp]
 mov [r13+NEBOC_ST_METHOD_RECEIVER_TYPE_OFFSET],rax
 mov rax,[rsp+8]
 mov [r13+NEBOC_ST_METHOD_NAME_OFFSET],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_ST_METHOD_OPERATION_OFFSET],rax
 mov rax,[rsp+24]
 mov [r13+NEBOC_ST_METHOD_OPERAND_OFFSET],rax
 mov rax,[rsp+32]
 mov [r13+NEBOC_ST_METHOD_RESULT_TYPE_OFFSET],rax
 inc qword [r12+NEBOC_ST_METHOD_COUNT_OFFSET]
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_METHOD
 xor eax,eax
 jmp .done
.type:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_TYPE_MISMATCH
 jmp .error
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.done:
 cmp qword [r12+NEBOC_ST_DIAGNOSTIC_OFFSET],0
 je .status
 test eax,eax
 jnz .status
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.status:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Parse a field type. RDI=current declaration. Returns type RAX, size RDX,
; alignment RCX, leaf drop count R8. Zero means a published diagnostic.
st_parse_type:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 mov rsi,[r13+NEBOC_DECL_NAME_OFFSET]
 call st_name_equal
 test eax,eax
 jnz .recursive
 mov rdi,r14
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call st_token_match
 test eax,eax
 jnz .int
 mov rdi,r14
 lea rsi,[rel n_bool]
 mov edx,n_bool_len
 call st_token_match
 test eax,eax
 jnz .bool
 mov rdi,r14
 lea rsi,[rel n_char]
 mov edx,n_char_len
 call st_token_match
 test eax,eax
 jnz .char
 mov rdi,r14
 lea rsi,[rel n_text]
 mov edx,n_text_len
 call st_token_match
 test eax,eax
 jnz .text
 mov rdi,r14
 call st_find_decl
 test rax,rax
 jz .syntax
 mov r15,rax
 mov rbx,rdx
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 lea rax,[rbx+NEBOC_TYPE_STRUCT_BASE]
 mov rdx,[r15+NEBOC_DECL_SIZE_OFFSET]
 mov rcx,[r15+NEBOC_DECL_ALIGN_OFFSET]
 mov r8,[r15+NEBOC_DECL_DROP_COUNT_OFFSET]
 jmp .done
.int:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 mov edx,8
 mov ecx,8
 xor r8d,r8d
 jmp .scalar
.bool:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 mov edx,1
 mov ecx,1
 xor r8d,r8d
 jmp .scalar
.char:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical
 mov edx,4
 mov ecx,4
 xor r8d,r8d
 jmp .scalar
.text:
 mov eax,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_semantic_types_native_vertical
 mov edx,16
 mov ecx,8
 mov r8d,1
.scalar:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .done
.recursive:
 mov esi,NEBOC_DIAG_RECURSIVE_LAYOUT
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Expression parser with bounded product construction, binding terminals and
; chained named/positional projections. Returns a value-record pointer.
st_parse_expr:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 call st_parse_primary
 test rax,rax
 jz .done
 mov r13,rax
.suffix:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_DOT
 jne .return
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_KW_RETURN
 je .terminal_return
 cmp rax,NEBOC_TOKEN_INTEGER
 je .tuple_access
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_at]
 mov edx,n_at_len
 call st_token_match
 test eax,eax
 jnz .tuple_at
 mov rdi,r14
 lea rsi,[rel n_length]
 mov edx,n_length_len
 call st_token_match
 test eax,eax
 jnz .tuple_length
 mov rdi,r14
 lea rsi,[rel n_destructure]
 mov edx,n_destructure_len
 call st_token_match
 test eax,eax
 jnz .tuple_destructure
 mov rdi,r14
 lea rsi,[rel n_map_each]
 mov edx,n_map_each_len
 call st_token_match
 test eax,eax
 jnz .tuple_map_each
 mov rdi,r14
 lea rsi,[rel n_to_struct]
 mov edx,n_to_struct_len
 call st_token_match
 test eax,eax
 jnz .tuple_to_struct
 mov rdi,r14
 lea rsi,[rel n_update]
 mov edx,n_update_len
 call st_token_match
 test eax,eax
 jnz .struct_update
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jb .bind
 bt rax,62
 jc .bind
 sub rax,NEBOC_TYPE_STRUCT_BASE
 cmp rax,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .internal
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov r15,rax
 xor ebx,ebx
.find_field:
 cmp rbx,[r15+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .method_call
 mov rdi,r14
 mov rsi,[r15+NEBOC_DECL_FIELD_NAMES_OFFSET+rbx*8]
 call st_name_equal
 test eax,eax
 jnz .field_access
 inc rbx
 jmp .find_field
.field_access:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov rax,[r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jb .scalar_field
 mov r13,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 test r13,r13
 jz .internal
 jmp .accessed
.scalar_field:
 mov [rsp],rax
 mov r15,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 call st_alloc_value
 test rax,rax
 jz .done
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_VALUE_TYPE_OFFSET],rax
 mov [r13+NEBOC_VALUE_MEMBERS_OFFSET],r15
 mov rax,r13
 call st_set_scalar_layout
.accessed:
 inc qword [r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 jmp .suffix
.method_call:
 mov rdi,r13
 mov rsi,r14
 call st_apply_method
 test rax,rax
 jz .bind
 mov r13,rax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 inc qword [r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 jmp .suffix
.struct_update:
 mov rdi,r13
 call st_update_struct
 test rax,rax
 jz .done
 mov r13,rax
 jmp .suffix
.tuple_map_each:
 mov rdi,r13
 call st_tuple_map_each
 test rax,rax
 jz .done
 mov r13,rax
 jmp .suffix
.tuple_to_struct:
 mov rdi,r13
 call st_tuple_to_struct
 test rax,rax
 jz .done
 mov r13,rax
 jmp .suffix
.bind:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call st_bind_value
 test eax,eax
 jz .bind_ready
 xor eax,eax
 jmp .done
.bind_ready:
 jmp .suffix
.tuple_access:
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rax,r14
 call st_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 mov rdx,r14
 call st_tuple_project
 test rax,rax
 jz .done
 mov r13,rax
 jmp .suffix
.tuple_at:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call st_expect
 test eax,eax
 jnz .done
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rax,r14
 call st_token_ptr
 mov rbx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,rbx
 mov rdx,r14
 call st_tuple_project
 test rax,rax
 jz .done
 mov r13,rax
 jmp .suffix
.tuple_length:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 bt rax,62
 jnc .tuple_type
 mov rbx,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 call st_alloc_value
 test rax,rax
 jz .done
 mov r13,rax
 mov qword [r13+NEBOC_VALUE_TYPE_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 mov [r13+NEBOC_VALUE_MEMBERS_OFFSET],rbx
 call st_set_scalar_layout
 inc qword [r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 jmp .suffix
.tuple_destructure:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 bt rax,62
 jnc .tuple_type
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov r15,r13
 xor ebx,ebx
.destructure_item:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RPAREN
 je .destructure_finish
 cmp rbx,[r15+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jae .destructure_arity
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_wildcard]
 mov edx,n_wildcard_len
 call st_token_match
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 test eax,eax
 jnz .destructure_next
 mov rdi,r15
 mov rsi,rbx
 mov rdx,r14
 call st_tuple_project
 test rax,rax
 jz .done
 mov r13,rax
 mov rdi,r14
 mov rsi,r13
 call st_bind_value
 test eax,eax
 jz .destructure_bound
 xor eax,eax
 jmp .done
.destructure_bound:
 mov r13,r15
.destructure_next:
 inc rbx
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RPAREN
 je .destructure_finish
 cmp rax,NEBOC_TOKEN_COMMA
 jne .syntax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .destructure_item
.destructure_finish:
 cmp rbx,[r15+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jne .destructure_arity
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .done
 mov r13,r15
 jmp .suffix
.destructure_arity:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
 jmp .done
.tuple_type:
 mov esi,NEBOC_DIAG_TUPLE_TYPE
 mov rdx,r14
 call st_error
 xor eax,eax
 jmp .done
.terminal_return:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .suffix
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 jmp .error_current
.internal:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
.error_current:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
 jmp .done
.return:
 mov rax,r13
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Project constant RSI from Tuple value RDI. RDX is the causal index token.
; The returned record is either the existing composite member or one bounded
; scalar value record. No constructor or source expression is re-evaluated.
st_tuple_project:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 mov rbx,rsi
 mov r14,rdx
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 bt rax,62
 jnc .bounds
 cmp rbx,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jae .bounds
 mov rax,[r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jae .composite
 mov [rsp],rax
 mov r15,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 call st_alloc_value
 test rax,rax
 jz .done
 mov r13,rax
 mov rax,[rsp]
 mov [r13+NEBOC_VALUE_TYPE_OFFSET],rax
 mov [r13+NEBOC_VALUE_MEMBERS_OFFSET],r15
 mov rax,r13
 call st_set_scalar_layout
 mov rax,r13
 jmp .accessed
.composite:
 mov rax,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 test rax,rax
 jz .internal
.accessed:
 inc qword [r12+NEBOC_ST_ACCESS_COUNT_OFFSET]
 jmp .done
.bounds:
 mov esi,NEBOC_DIAG_TUPLE_BOUNDS
 mov rdx,r14
 call st_error
 xor eax,eax
 jmp .done
.internal:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
 mov rdx,r14
 call st_error
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

st_parse_primary:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_INTEGER
 je .integer
 cmp rax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp rax,NEBOC_TOKEN_KW_FALSE
 je .false
 cmp rax,NEBOC_TOKEN_CHAR
 je .char
 cmp rax,NEBOC_TOKEN_TEXT
 je .text
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r14,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r14
 lea rsi,[rel n_tuple]
 mov edx,n_tuple_len
 call st_token_match
 test eax,eax
 jnz .tuple
 mov rdi,r14
 call st_find_binding
 test rax,rax
 jnz .binding
 mov rdi,r14
 call st_find_decl
 test rax,rax
 jz .syntax
 mov r13,rax
 mov r15,rdx
 jmp .struct
.integer:
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 jmp .scalar_token
.true:
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 mov qword [rsp],1
 jmp .scalar_known
.false:
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 mov qword [rsp],0
 jmp .scalar_known
.char:
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical
.scalar_token:
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_token_ptr
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rsp],rax
.scalar_known:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 call st_alloc_value
 test rax,rax
 jz .done
 mov [rax+NEBOC_VALUE_TYPE_OFFSET],rbx
 mov rcx,[rsp]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET],rcx
 call st_set_scalar_layout
 jmp .done
.text:
 mov ebx,neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_semantic_types_native_vertical
 mov qword [rsp],0
 jmp .scalar_known
.binding:
 mov rax,[rax+NEBOC_BINDING_VALUE_INDEX_OFFSET]
 imul rax,NEBOC_VALUE_SIZE
 add rax,[r12+NEBOC_ST_VALUES_OFFSET]
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .done
.tuple:
 call st_parse_tuple
 jmp .done
.struct:
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 inc rax
 call st_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .struct_literal
 mov rdi,r13
 mov rsi,r15
 call st_parse_struct_static
 jmp .done
.struct_literal:
 mov rdi,r13
 mov rsi,r15
 call st_parse_struct_literal
 jmp .done
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RDI declaration pointer, RSI declaration index.
st_parse_struct_literal:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 mov r13,rdi
 mov [rsp],rsi
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LBRACE
 call st_expect
 test eax,eax
 jnz .fail
 call st_alloc_value
 test rax,rax
 jz .fail
 mov r14,rax
 mov rax,[rsp]
 add rax,NEBOC_TYPE_STRUCT_BASE
 mov [r14+NEBOC_VALUE_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBER_COUNT_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_SIZE_OFFSET]
 mov [r14+NEBOC_VALUE_SIZE_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_ALIGN_OFFSET]
 mov [r14+NEBOC_VALUE_ALIGN_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_DROP_COUNT_OFFSET]
 mov [r14+NEBOC_VALUE_DROP_COUNT_OFFSET],rax
 xor ebx,ebx                    ; seen mask
.item:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RBRACE
 je .finish
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[r12+NEBOC_ST_CURSOR_OFFSET]
 xor ecx,ecx
.find:
 cmp rcx,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .unknown
 mov rdi,r15
 mov rsi,[r13+NEBOC_DECL_FIELD_NAMES_OFFSET+rcx*8]
 call st_name_equal
 test eax,eax
 jnz .found
 inc rcx
 jmp .find
.found:
 mov rax,1
 shl rax,cl
 test rbx,rax
 jnz .duplicate
 or rbx,rax
 mov [rsp+8],rcx
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 call st_expect
 test eax,eax
 jnz .fail
 call st_parse_expr
 test rax,rax
 jz .fail
 mov r15,rax
 mov rcx,[rsp+8]
 mov rdx,[r15+NEBOC_VALUE_TYPE_OFFSET]
 cmp rdx,[r13+NEBOC_DECL_FIELD_TYPES_OFFSET+rcx*8]
 jne .type
 mov [r14+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rcx*8],rdx
 cmp rdx,NEBOC_TYPE_STRUCT_BASE
 jb .store_scalar
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rcx*8],r15
 jmp .separator
.store_scalar:
 mov rdx,[r15+NEBOC_VALUE_MEMBERS_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rcx*8],rdx
.separator:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 jne .item
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .item
.finish:
 mov rcx,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 mov rax,1
 shl rax,cl
 dec rax
 cmp rbx,rax
 jne .arity
 mov edi,NEBOC_TOKEN_RBRACE
 call st_expect
 test eax,eax
 jnz .fail
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov rax,[r14+NEBOC_VALUE_DROP_COUNT_OFFSET]
 add [r12+NEBOC_ST_DROP_COUNT_OFFSET],rax
 jc .overflow
 mov r8,1099511628211
 mov rax,[r12+NEBOC_ST_CLEANUP_HASH_OFFSET]
 test rax,rax
 jnz .hash_ready
 mov rax,14695981039346656037
.hash_ready:
 xor rax,[r14+NEBOC_VALUE_TYPE_OFFSET]
 imul rax,r8
 xor rax,[r14+NEBOC_VALUE_DROP_COUNT_OFFSET]
 imul rax,r8
 mov [r12+NEBOC_ST_CLEANUP_HASH_OFFSET],rax
 mov rax,r14
 jmp .done
.unknown:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_UNKNOWN_FIELD
 jmp .error_name
.duplicate:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_DUPLICATE_FIELD
.error_name:
 mov rdx,r15
 call st_error
 jmp .fail
.type:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_TYPE_MISMATCH
 jmp .error_current
.arity:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 jmp .error_current
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 jmp .error_current
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error_current:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.fail:
 xor eax,eax
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RDI=value, RSI=member index -> projected value or zero.
st_project_member:
 push rbx
 push r13
 sub rsp,8
 mov r13,rdi
 mov rbx,rsi
 cmp rbx,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jae .bounds
 mov rax,[r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jb .scalar
 mov rax,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 test rax,rax
 jz .internal
 jmp .done
.scalar:
 mov [rsp],rax
 call st_alloc_value
 test rax,rax
 jz .done
 mov rcx,[rsp]
 mov [rax+NEBOC_VALUE_TYPE_OFFSET],rcx
 mov rcx,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET],rcx
 call st_set_scalar_layout
 jmp .done
.bounds:
 mov esi,NEBOC_DIAG_TUPLE_BOUNDS
 jmp .error
.internal:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

; RDI=value, RSI=method-name token -> transformed value or zero.  A missing
; method is not itself a diagnostic because the caller may still interpret
; the suffix as the language's one-shot binding terminal.
st_apply_method:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 mov r14,rsi
 xor ebx,ebx
.find:
 cmp rbx,[r12+NEBOC_ST_METHOD_COUNT_OFFSET]
 jae .missing
 mov rax,rbx
 imul rax,NEBOC_ST_METHOD_SIZE
 lea r15,[r12+NEBOC_ST_METHODS_OFFSET+rax]
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 cmp rax,[r15+NEBOC_ST_METHOD_RECEIVER_TYPE_OFFSET]
 jne .next
 mov rdi,r14
 mov rsi,[r15+NEBOC_ST_METHOD_NAME_OFFSET]
 call st_name_equal
 test eax,eax
 jnz .found
.next:
 inc rbx
 jmp .find
.found:
 mov rax,[r15+NEBOC_ST_METHOD_OPERATION_OFFSET]
 cmp rax,NEBOC_ST_METHOD_IDENTITY
 je .identity
 cmp rax,NEBOC_ST_METHOD_FIELD
 je .field
 cmp rax,NEBOC_ST_METHOD_ADD
 jne .internal
 mov rax,[r13+NEBOC_VALUE_MEMBERS_OFFSET]
 add rax,[r15+NEBOC_ST_METHOD_OPERAND_OFFSET]
 jo .overflow
 mov [rsp],rax
 call st_alloc_value
 test rax,rax
 jz .done
 mov rcx,[r15+NEBOC_ST_METHOD_RESULT_TYPE_OFFSET]
 mov [rax+NEBOC_VALUE_TYPE_OFFSET],rcx
 mov rcx,[rsp]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET],rcx
 call st_set_scalar_layout
 jmp .done
.field:
 mov rdi,r13
 mov rsi,[r15+NEBOC_ST_METHOD_OPERAND_OFFSET]
 call st_project_member
 jmp .done
.identity:
 mov rax,r13
 jmp .done
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 jmp .error
.internal:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
.error:
 mov rdx,r14
 call st_error
.missing:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Construct a recursively defaulted struct.  All currently public field types
; have a deterministic zero/default representation; recursive layouts were
; already rejected when declarations were built.
st_default_struct:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 mov r13,rdi
 mov [rsp],rsi
 call st_alloc_value
 test rax,rax
 jz .done
 mov r14,rax
 mov rax,[rsp]
 add rax,NEBOC_TYPE_STRUCT_BASE
 mov [r14+NEBOC_VALUE_TYPE_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBER_COUNT_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_SIZE_OFFSET]
 mov [r14+NEBOC_VALUE_SIZE_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_ALIGN_OFFSET]
 mov [r14+NEBOC_VALUE_ALIGN_OFFSET],rax
 mov rax,[r13+NEBOC_DECL_DROP_COUNT_OFFSET]
 mov [r14+NEBOC_VALUE_DROP_COUNT_OFFSET],rax
 xor ebx,ebx
.field:
 cmp rbx,[r13+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .ready
 mov r15,[r13+NEBOC_DECL_FIELD_TYPES_OFFSET+rbx*8]
 mov [r14+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8],r15
 cmp r15,NEBOC_TYPE_STRUCT_BASE
 jb .zero
 mov rax,r15
 sub rax,NEBOC_TYPE_STRUCT_BASE
 mov [rsp+8],rax
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov rdi,rax
 mov rsi,[rsp+8]
 call st_default_struct
 test rax,rax
 jz .done
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rax
 jmp .next
.zero:
 mov qword [r14+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],0
.next:
 inc rbx
 jmp .field
.ready:
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov rax,[r14+NEBOC_VALUE_DROP_COUNT_OFFSET]
 add [r12+NEBOC_ST_DROP_COUNT_OFFSET],rax
 jc .overflow
 mov rax,r14
 jmp .done
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Static struct operations: Type.default() and Type.layout(). layout returns
; the canonical (size, alignment) Tuple so both facts remain independently
; observable through the normal constant-index Tuple projection.
st_parse_struct_static:
 push rbx
 push r13
 push r14
 mov r13,rdi
 mov r14,rsi
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_DOT
 call st_expect
 test eax,eax
 jnz .fail
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rbx,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,rbx
 lea rsi,[rel n_default]
 mov edx,n_default_len
 call st_token_match
 test eax,eax
 jnz .default
 mov rdi,rbx
 lea rsi,[rel n_layout]
 mov edx,n_layout_len
 call st_token_match
 test eax,eax
 jnz .layout
 jmp .syntax
.default:
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_DEFAULT
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov rdi,r13
 mov rsi,r14
 call st_default_struct
 jmp .done
.layout:
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_LAYOUT
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 call st_alloc_value
 test rax,rax
 jz .fail
 mov rcx,NEBOC_TYPE_TUPLE_MASK
 or rcx,[r13+NEBOC_DECL_HASH_OFFSET]
 mov [rax+NEBOC_VALUE_TYPE_OFFSET],rcx
 mov qword [rax+NEBOC_VALUE_MEMBER_COUNT_OFFSET],2
 mov qword [rax+NEBOC_VALUE_SIZE_OFFSET],16
 mov qword [rax+NEBOC_VALUE_ALIGN_OFFSET],8
 mov qword [rax+NEBOC_VALUE_MEMBER_TYPES_OFFSET],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 mov qword [rax+NEBOC_VALUE_MEMBER_TYPES_OFFSET+8],neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 mov rcx,[r13+NEBOC_DECL_SIZE_OFFSET]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET],rcx
 mov rcx,[r13+NEBOC_DECL_ALIGN_OFFSET]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET+8],rcx
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 jmp .done
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.fail:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop rbx
 ret

; RDI=struct value. Cursor names `update`; returns a copied value with one or
; more named replacements. The original remains untouched (failure atomicity).
st_update_struct:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,24
 mov r13,rdi
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_UPDATE
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 cmp rax,NEBOC_TYPE_STRUCT_BASE
 jb .type
 bt rax,62
 jc .type
 sub rax,NEBOC_TYPE_STRUCT_BASE
 cmp rax,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .type
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov r15,rax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 call st_alloc_value
 test rax,rax
 jz .fail
 mov r14,rax
 mov rdi,r14
 mov rsi,r13
 mov ecx,NEBOC_VALUE_QWORDS
 rep movsq
 mov qword [rsp],0
 mov qword [rsp+16],0
.item:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RPAREN
 je .finish
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rbx,[r12+NEBOC_ST_CURSOR_OFFSET]
 xor ecx,ecx
.find_field:
 cmp rcx,[r15+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .unknown
 mov rdi,rbx
 mov rsi,[r15+NEBOC_DECL_FIELD_NAMES_OFFSET+rcx*8]
 call st_name_equal
 test eax,eax
 jnz .field
 inc rcx
 jmp .find_field
.field:
 mov rax,1
 shl rax,cl
 test [rsp],rax
 jnz .duplicate
 or [rsp],rax
 mov [rsp+8],rcx
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 call st_expect
 test eax,eax
 jnz .fail
 call st_parse_expr
 test rax,rax
 jz .fail
 mov rcx,[rsp+8]
 mov rdx,[rax+NEBOC_VALUE_TYPE_OFFSET]
 cmp rdx,[r15+NEBOC_DECL_FIELD_TYPES_OFFSET+rcx*8]
 jne .type
 mov [r14+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rcx*8],rdx
 cmp rdx,NEBOC_TYPE_STRUCT_BASE
 jb .store_scalar
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rcx*8],rax
 jmp .stored
.store_scalar:
 mov rax,[rax+NEBOC_VALUE_MEMBERS_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rcx*8],rax
.stored:
 inc qword [rsp+16]
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 jne .item
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .item
.finish:
 cmp qword [rsp+16],0
 je .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov rax,[r14+NEBOC_VALUE_DROP_COUNT_OFFSET]
 add [r12+NEBOC_ST_DROP_COUNT_OFFSET],rax
 jc .overflow
 mov rax,r14
 jmp .done
.unknown:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_UNKNOWN_FIELD
 mov rdx,rbx
 jmp .error_at
.duplicate:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_DUPLICATE_FIELD
 mov rdx,rbx
 jmp .error_at
.type:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_TYPE_MISMATCH
 jmp .error
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
.error_at:
 call st_error
.fail:
 xor eax,eax
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RDI=Tuple value. Parse one callable name per position and materialize the
; transformed Tuple. Each callable is selected by exact receiver TypeKey.
st_tuple_map_each:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_MAP_EACH
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 bt rax,62
 jnc .type
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 call st_alloc_value
 test rax,rax
 jz .fail
 mov r14,rax
 mov rdi,r14
 mov rsi,r13
 mov ecx,NEBOC_VALUE_QWORDS
 rep movsq
 xor ebx,ebx
.item:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RPAREN
 je .finish
 cmp rbx,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jae .arity
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[r12+NEBOC_ST_CURSOR_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 call st_project_member
 test rax,rax
 jz .fail
 mov rdi,rax
 mov rsi,r15
 call st_apply_method
 test rax,rax
 jz .type
 mov rdx,[rax+NEBOC_VALUE_TYPE_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8],rdx
 cmp rdx,NEBOC_TYPE_STRUCT_BASE
 jb .scalar
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rax
 jmp .mapped
.scalar:
 mov rax,[rax+NEBOC_VALUE_MEMBERS_OFFSET]
 mov [r14+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rax
.mapped:
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 inc rbx
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 jne .item
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .item
.finish:
 cmp rbx,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 jne .arity
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov rax,r14
 jmp .done
.arity:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 jmp .error
.type:
 mov esi,NEBOC_DIAG_TUPLE_TYPE
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.fail:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; RDI=Tuple value. Parse toStruct<Type>() and require exact source-order type
; correspondence with the nominal struct declaration.
st_tuple_to_struct:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,8
 mov r13,rdi
 or qword [r12+NEBOC_ST_FEATURE_FLAGS_OFFSET],NEBOC_ST_FEATURE_TO_STRUCT
 mov rax,[r13+NEBOC_VALUE_TYPE_OFFSET]
 bt rax,62
 jnc .type
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_LESS
 call st_expect
 test eax,eax
 jnz .fail
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_find_decl
 test rax,rax
 jz .type
 mov r14,rax
 mov r15,rdx
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 mov edi,NEBOC_TOKEN_GREATER
 call st_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov rax,[r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET]
 cmp rax,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jne .arity
 xor ebx,ebx
.match:
 cmp rbx,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .materialize
 mov rax,[r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8]
 cmp rax,[r14+NEBOC_DECL_FIELD_TYPES_OFFSET+rbx*8]
 jne .type
 inc rbx
 jmp .match
.materialize:
 call st_alloc_value
 test rax,rax
 jz .fail
 mov rdx,r15
 add rdx,NEBOC_TYPE_STRUCT_BASE
 mov [rax+NEBOC_VALUE_TYPE_OFFSET],rdx
 mov rdx,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 mov [rax+NEBOC_VALUE_MEMBER_COUNT_OFFSET],rdx
 mov rdx,[r14+NEBOC_DECL_SIZE_OFFSET]
 mov [rax+NEBOC_VALUE_SIZE_OFFSET],rdx
 mov rdx,[r14+NEBOC_DECL_ALIGN_OFFSET]
 mov [rax+NEBOC_VALUE_ALIGN_OFFSET],rdx
 mov rdx,[r14+NEBOC_DECL_DROP_COUNT_OFFSET]
 mov [rax+NEBOC_VALUE_DROP_COUNT_OFFSET],rdx
 xor ebx,ebx
.copy:
 cmp rbx,[r14+NEBOC_DECL_FIELD_COUNT_OFFSET]
 jae .ready
 mov rdx,[r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8]
 mov [rax+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8],rdx
 mov rdx,[r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8]
 mov [rax+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rdx
 inc rbx
 jmp .copy
.ready:
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 jmp .done
.arity:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 jmp .error
.type:
 mov esi,NEBOC_DIAG_TUPLE_TYPE
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.fail:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

st_parse_tuple:
 push rbx
 push r13
 push r14
 push r15
 sub rsp,40
 mov qword [rsp+24],0          ; depth ownership flag
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 ; C07 canonical spelling is Tuple.of(...). The original Tuple(...) spelling
 ; remains an exact compatibility route and reaches the same parser state.
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_DOT
 jne .constructor_ready
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[r12+NEBOC_ST_CURSOR_OFFSET]
 lea rsi,[rel n_of]
 mov edx,n_of_len
 call st_token_match
 test eax,eax
 jz .syntax
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
.constructor_ready:
 mov edi,NEBOC_TOKEN_LPAREN
 call st_expect
 test eax,eax
 jnz .fail
 inc qword [r12+NEBOC_ST_TUPLE_DEPTH_OFFSET]
 mov qword [rsp+24],1
 mov rax,[r12+NEBOC_ST_TUPLE_DEPTH_OFFSET]
 cmp rax,NEBOC_ST_MAX_TUPLE_DEPTH
 ja .depth
 cmp rax,[r12+NEBOC_ST_MAX_OBSERVED_DEPTH_OFFSET]
 jbe .depth_recorded
 mov [r12+NEBOC_ST_MAX_OBSERVED_DEPTH_OFFSET],rax
.depth_recorded:
 call st_alloc_value
 test rax,rax
 jz .fail
 mov r13,rax
 xor ebx,ebx
 mov qword [rsp],0             ; cursor
 mov qword [rsp+8],1           ; max align
 mov qword [rsp+16],0          ; drops
 mov r14,14695981039346656037  ; structural TypeKey hash
 mov r15,1099511628211
.member:
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_RPAREN
 je .finish
 cmp rbx,NEBOC_ST_MAX_FIELDS
 jae .bounds
 call st_parse_expr
 test rax,rax
 jz .fail
 mov rcx,[rax+NEBOC_VALUE_TYPE_OFFSET]
 mov [r13+NEBOC_VALUE_MEMBER_TYPES_OFFSET+rbx*8],rcx
 xor r14,rcx
 imul r14,r15
 cmp rcx,NEBOC_TYPE_STRUCT_BASE
 jb .scalar
 mov [r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rax
 jmp .facts
.scalar:
 mov rdx,[rax+NEBOC_VALUE_MEMBERS_OFFSET]
 mov [r13+NEBOC_VALUE_MEMBERS_OFFSET+rbx*8],rdx
.facts:
 mov rcx,[rax+NEBOC_VALUE_ALIGN_OFFSET]
 cmp rcx,[rsp+8]
 jbe .tuple_align_ready
 mov [rsp+8],rcx
.tuple_align_ready:
 lea rdx,[rcx-1]
 mov r9,[rsp]
 add r9,rdx
 jc .overflow
 not rdx
 and r9,rdx
 add r9,[rax+NEBOC_VALUE_SIZE_OFFSET]
 jc .overflow
 cmp r9,NEBOC_ST_MAX_LAYOUT
 ja .overflow
 mov [rsp],r9
 mov rdx,[rax+NEBOC_VALUE_DROP_COUNT_OFFSET]
 add [rsp+16],rdx
 jc .overflow
 inc rbx
 call st_peek_kind
 cmp rax,NEBOC_TOKEN_COMMA
 jne .member
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 jmp .member
.finish:
 mov edi,NEBOC_TOKEN_RPAREN
 call st_expect
 test eax,eax
 jnz .fail
 mov [r13+NEBOC_VALUE_MEMBER_COUNT_OFFSET],rbx
 mov rax,NEBOC_TYPE_TUPLE_MASK
 or r14,rax
 mov [r13+NEBOC_VALUE_TYPE_OFFSET],r14
 test rbx,rbx
 jnz .nonempty
 mov qword [rsp],1
 mov qword [rsp+8],1
.nonempty:
 mov rcx,[rsp+8]
 lea rdx,[rcx-1]
 mov rax,[rsp]
 add rax,rdx
 jc .overflow
 not rdx
 and rax,rdx
 cmp rax,NEBOC_ST_MAX_LAYOUT
 ja .overflow
 mov [r13+NEBOC_VALUE_SIZE_OFFSET],rax
 mov [r13+NEBOC_VALUE_ALIGN_OFFSET],rcx
 mov rax,[rsp+16]
 mov [r13+NEBOC_VALUE_DROP_COUNT_OFFSET],rax
 add [r12+NEBOC_ST_DROP_COUNT_OFFSET],rax
 jc .overflow
 inc qword [r12+NEBOC_ST_CONSTRUCT_COUNT_OFFSET]
 mov rax,r13
 jmp .done
.bounds:
 mov esi,NEBOC_DIAG_WRONG_ARITY
 jmp .error
.depth:
 mov esi,NEBOC_DIAG_TUPLE_DEPTH
 jmp .error
.syntax:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 jmp .error
.overflow:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
.error:
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
.fail:
 xor eax,eax
.done:
 cmp qword [rsp+24],0
 je .depth_done
 dec qword [r12+NEBOC_ST_TUPLE_DEPTH_OFFSET]
.depth_done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop rbx
 ret

; Allocate and clear one value record. Returns pointer or zero.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
st_alloc_value:
 mov rax,[r12+NEBOC_ST_VALUE_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_ST_VALUE_CAPACITY_OFFSET]
 jae .limit
 mov rdx,rax
 imul rax,NEBOC_VALUE_SIZE
 add rax,[r12+NEBOC_ST_VALUES_OFFSET]
 inc qword [r12+NEBOC_ST_VALUE_COUNT_OFFSET]
 ret
.limit:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 xor eax,eax
 ret

; RDI=name token, RSI=value pointer.
%undef call
st_bind_value:
 push r13
 push r14
 sub rsp,8
 mov r13,rdi
 mov r14,rsi
 mov rdi,r13
 call st_find_binding
 test rax,rax
 jnz .duplicate
 mov rax,[r12+NEBOC_ST_BINDING_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_ST_BINDING_CAPACITY_OFFSET]
 jae .limit
 imul rax,NEBOC_BINDING_SIZE
 add rax,[r12+NEBOC_ST_BINDINGS_OFFSET]
 mov [rax+NEBOC_BINDING_NAME_OFFSET],r13
 mov rdx,r14
 sub rdx,[r12+NEBOC_ST_VALUES_OFFSET]
 mov rax,rdx
 xor edx,edx
 mov ecx,NEBOC_VALUE_SIZE
 div rcx
 mov rdx,[r12+NEBOC_ST_BINDING_COUNT_OFFSET]
 imul rdx,NEBOC_BINDING_SIZE
 add rdx,[r12+NEBOC_ST_BINDINGS_OFFSET]
 mov [rdx+NEBOC_BINDING_VALUE_INDEX_OFFSET],rax
 inc qword [r12+NEBOC_ST_BINDING_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.duplicate:
 mov esi,NEBOC_DIAG_TUPLE_DUPLICATE_BINDING
 jmp .error
.limit:
 mov esi,NEBOC_DIAG_LAYOUT_OVERFLOW
.error:
 mov rdx,r13
 call st_error
.done:
 add rsp,8
 pop r14
 pop r13
 ret

st_set_scalar_layout:
 mov rcx,[rax+NEBOC_VALUE_TYPE_OFFSET]
 cmp rcx,neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical
 je .int
 cmp rcx,neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical
 je .bool
 cmp rcx,neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical
 je .char
 mov qword [rax+NEBOC_VALUE_SIZE_OFFSET],16
 mov qword [rax+NEBOC_VALUE_ALIGN_OFFSET],8
 mov qword [rax+NEBOC_VALUE_DROP_COUNT_OFFSET],1
 ret
.int:
 mov qword [rax+NEBOC_VALUE_SIZE_OFFSET],8
 mov qword [rax+NEBOC_VALUE_ALIGN_OFFSET],8
 ret
.bool:
 mov qword [rax+NEBOC_VALUE_SIZE_OFFSET],1
 mov qword [rax+NEBOC_VALUE_ALIGN_OFFSET],1
 ret
.char:
 mov qword [rax+NEBOC_VALUE_SIZE_OFFSET],4
 mov qword [rax+NEBOC_VALUE_ALIGN_OFFSET],4
 ret

; Return binding pointer or zero for token index RDI.
st_find_binding:
 push rbx
 push r13
 sub rsp,8
 mov r13,rdi
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_ST_BINDING_COUNT_OFFSET]
 jae .no
 mov rax,rbx
 imul rax,NEBOC_BINDING_SIZE
 add rax,[r12+NEBOC_ST_BINDINGS_OFFSET]
 mov rdi,r13
 mov rsi,[rax+NEBOC_BINDING_NAME_OFFSET]
 mov [rsp],rax
 call st_name_equal
 mov rdx,[rsp]
 test eax,eax
 jnz .yes
 inc rbx
 jmp .loop
.yes:
 mov rax,rdx
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

; Return declaration pointer in RAX and zero-based index in RDX.
st_find_decl:
 push rbx
 push r13
 sub rsp,8
 mov r13,rdi
 xor ebx,ebx
.loop:
 cmp rbx,[r12+NEBOC_ST_DECL_COUNT_OFFSET]
 jae .no
 mov rax,rbx
 imul rax,NEBOC_DECL_SIZE
 add rax,[r12+NEBOC_ST_DECLS_OFFSET]
 mov rdi,r13
 mov rsi,[rax+NEBOC_DECL_NAME_OFFSET]
 mov [rsp],rax
 call st_name_equal
 mov rdx,[rsp]
 test eax,eax
 jnz .yes
 inc rbx
 jmp .loop
.yes:
 mov rax,rdx
 mov rdx,rbx
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,8
 pop r13
 pop rbx
 ret

; Compare two token spellings from the same source.
st_name_equal:
 push rbx
 push r13
 push r14
 push rcx
 sub rsp,8
 mov r13,rdi
 mov r14,rsi
 mov rax,r13
 call st_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,r14
 call st_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+NEBOC_ST_SOURCE_OFFSET]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdi,[r12+NEBOC_ST_SOURCE_OFFSET]
 add rdi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,rdx
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rcx
 pop r14
 pop r13
 pop rbx
 ret

; Compare token RDI to atom RSI/EDX.
st_token_match:
 push rbx
 mov rbx,rsi
 mov r9,rdx
 mov rax,rdi
 call st_token_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,r9
 jne .no
 mov rsi,[r12+NEBOC_ST_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,rbx
 mov rcx,r9
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

st_peek_kind:
 mov rax,[r12+NEBOC_ST_CURSOR_OFFSET]
 jmp st_kind_at

; EDI expected kind.
st_expect:
 push rbx
 mov ebx,edi
 call st_peek_kind
 cmp rax,rbx
 jne .bad
 inc qword [r12+NEBOC_ST_CURSOR_OFFSET]
 xor eax,eax
 pop rbx
 ret
.bad:
 mov esi,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 mov rdx,[r12+NEBOC_ST_CURSOR_OFFSET]
 call st_error
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
st_kind_at:
 call st_token_ptr
 test rax,rax
 jz .invalid
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.invalid:
 xor eax,eax
 ret

%undef call
st_token_ptr:
 cmp rax,[r12+NEBOC_ST_TOKEN_COUNT_OFFSET]
 jae .invalid
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_ST_TOKENS_OFFSET]
 ret
.invalid:
 xor eax,eax
 ret

; ESI diagnostic, RDX token index.
st_error:
 mov [r12+NEBOC_ST_DIAGNOSTIC_OFFSET],rsi
 mov [r12+NEBOC_ST_ERROR_TOKEN_OFFSET],rdx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

st_semantic_hash:
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

st_hash_bytes:
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
