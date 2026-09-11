; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F06 token-structural aliases, newtypes and bounded enums.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/nominal_types.inc"

section .rodata
n_type: db 'type'
n_type_len equ $-n_type
n_alias: db 'alias'
n_alias_len equ $-n_alias
n_newtype: db 'newtype'
n_newtype_len equ $-n_newtype
n_int: db 'Int'
n_int_len equ $-n_int
n_bool: db 'Bool'
n_bool_len equ $-n_bool
n_char: db 'Char'
n_char_len equ $-n_char
n_float: db 'Float'
n_float_len equ $-n_float
n_text: db 'Text'
n_text_len equ $-n_text
n_unwrap: db 'unwrap'
n_unwrap_len equ $-n_unwrap
n_sizeof: db 'sizeOf'
n_sizeof_len equ $-n_sizeof
n_discriminant: db 'discriminant'
n_discriminant_len equ $-n_discriminant
n_reflection: db 'reflection'
n_reflection_len equ $-n_reflection
n_abia1: db 'abiA1'
n_abia1_len equ $-n_abia1

section .text

; R12=request, RAX=index -> token pointer or zero.
nom_token_ptr:
 cmp rax,[r12+NEBOC_NOM_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_NOM_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RAX=index, EDI=kind -> EAX boolean.
nom_kind_is:
 push rdi
 call nom_token_ptr
 pop rdi
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_KIND_OFFSET],rdi
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; RAX=index, RSI=bytes, EDX=len -> EAX boolean.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_token_match:
 push rbx
 push rbp
 push r13
 push r14
 mov r13,rax
 mov r14,rsi
 mov ebp,edx
 call nom_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rcx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rbp
 jne .no
 mov r8,[r12+NEBOC_NOM_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp ecx,ebp
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r14+rcx]
 jne .no
 inc ecx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r14
 pop r13
 pop rbp
 pop rbx
 ret

; RAX=index -> stable nonzero FNV hash.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_token_hash:
 push rbx
 push r13
 call nom_token_ptr
 test rax,rax
 jz .bad
 mov r13,rax
 mov rcx,[r13+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[r13+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[r12+NEBOC_NOM_SOURCE_OFFSET]
 add rsi,[r13+NEBOC_TOKEN_START_OFFSET]
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ebx,ebx
.loop:
 cmp rbx,rcx
 jae .done
 movzx r9d,byte [rsi+rbx]
 xor rax,r9
 imul rax,r8
 inc rbx
 jmp .loop
.done:
 test rax,rax
 jnz .out
 mov eax,1
.out:
 pop r13
 pop rbx
 ret
.bad:
 xor eax,eax
 pop r13
 pop rbx
 ret

; RAX=index -> EAX bounded type id or zero.
%undef call
nom_type_at:
 push rbx
 mov rbx,rax
 lea rsi,[rel n_int]
 mov edx,n_int_len
 call nom_token_match
 test eax,eax
 jnz .int
 mov rax,rbx
 lea rsi,[rel n_bool]
 mov edx,n_bool_len
 call nom_token_match
 test eax,eax
 jnz .bool
 mov rax,rbx
 lea rsi,[rel n_char]
 mov edx,n_char_len
 call nom_token_match
 test eax,eax
 jnz .char
 mov rax,rbx
 lea rsi,[rel n_float]
 mov edx,n_float_len
 call nom_token_match
 test eax,eax
 jnz .float
 mov rax,rbx
 lea rsi,[rel n_text]
 mov edx,n_text_len
 call nom_token_match
 test eax,eax
 jnz .text
 xor eax,eax
 jmp .done
.int: mov eax,NEBOC_NOM_TYPE_INT
 jmp .done
.bool: mov eax,NEBOC_NOM_TYPE_BOOL
 jmp .done
.char: mov eax,NEBOC_NOM_TYPE_CHAR
 jmp .done
.float: mov eax,NEBOC_NOM_TYPE_FLOAT
 jmp .done
.text: mov eax,NEBOC_NOM_TYPE_TEXT
.done:
 pop rbx
 ret

; RAX=index -> EAX type id, RDX value. Zero type means not a literal.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_literal_at:
 mov r10,rax
 call nom_token_ptr
 test rax,rax
 jz .none
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rcx,NEBOC_TOKEN_MINUS
 je .negative
 cmp rcx,NEBOC_TOKEN_INTEGER
 je .positive_int
 cmp rcx,NEBOC_TOKEN_CHAR
 je .char
 cmp rcx,NEBOC_TOKEN_FLOAT
 je .float
 cmp rcx,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp rcx,NEBOC_TOKEN_KW_FALSE
 je .false
 cmp rcx,NEBOC_TOKEN_TEXT
 je .text
.none:
 xor eax,eax
 xor edx,edx
 ret
.negative:
 lea rax,[r10+1]
 call nom_token_ptr
 test rax,rax
 jz .none
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .none
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov rcx,0x8000000000000000
 cmp rdx,rcx
 ja .none
 neg rdx
 jmp .int
.positive_int:
 test rdx,rdx
 js .none
.int: mov eax,NEBOC_NOM_TYPE_INT
 ret
.char: mov eax,NEBOC_NOM_TYPE_CHAR
 ret
.float:
 mov eax,NEBOC_NOM_TYPE_FLOAT
 xor edx,edx
 ret
.true:
 mov eax,NEBOC_NOM_TYPE_BOOL
 mov edx,1
 ret
.false:
 mov eax,NEBOC_NOM_TYPE_BOOL
 xor edx,edx
 ret
.text:
 mov eax,NEBOC_NOM_TYPE_TEXT
 xor edx,edx
 ret

; RSI diagnostic -> invalid source.
nom_error:
 mov qword [r12+NEBOC_NOM_FOUND_OFFSET],1
 mov [r12+NEBOC_NOM_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; RAX=index, EDI=kind -> status; preserves no cursor.
nom_expect_kind:
 call nom_kind_is
 test eax,eax
 jnz .yes
 mov esi,NEBOC_NOM_DIAG_SYNTAX
 jmp nom_error
.yes:
 xor eax,eax
 ret

; Parse alias declaration at fixed canonical prefix.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_parse_alias:
 mov qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ALIAS
 mov eax,1
 lea rsi,[rel n_alias]
 mov edx,n_alias_len
 call nom_token_match
 test eax,eax
 jz .syntax
 mov eax,2
 mov edi,NEBOC_TOKEN_IDENTIFIER
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,2
 call nom_token_hash
 mov rbp,rax
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
 mov eax,3
 mov edi,NEBOC_TOKEN_RESERVED_EQUAL
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,4
 call nom_type_at
 test eax,eax
 jnz .type_ok
 mov eax,4
 call nom_token_hash
 cmp rax,rbp
 je .identity
 jmp .payload
.type_ok:
 mov [r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],rax
 mov eax,5
 mov edi,NEBOC_TOKEN_SEMICOLON
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov r15d,6
 jmp nom_scan_operations
.identity:
 mov esi,NEBOC_NOM_DIAG_IDENTITY
 jmp nom_error
.payload:
 mov esi,NEBOC_NOM_DIAG_PAYLOAD
 jmp nom_error
.syntax:
 mov esi,NEBOC_NOM_DIAG_SYNTAX
 jmp nom_error

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_parse_newtype:
 mov qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_NEWTYPE
 mov eax,1
 mov edi,NEBOC_TOKEN_IDENTIFIER
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,1
 call nom_token_hash
 mov rbp,rax
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
 mov eax,2
 mov edi,NEBOC_TOKEN_LPAREN
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,3
 call nom_type_at
 test eax,eax
 jnz .type_ok
 mov eax,3
 call nom_token_hash
 cmp rax,rbp
 je .identity
 jmp .payload
.type_ok:
 mov [r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],rax
 mov eax,4
 mov edi,NEBOC_TOKEN_RPAREN
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,5
 mov edi,NEBOC_TOKEN_SEMICOLON
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov r15d,6
 jmp nom_scan_operations
.identity:
 mov esi,NEBOC_NOM_DIAG_IDENTITY
 jmp nom_error
.payload:
 mov esi,NEBOC_NOM_DIAG_PAYLOAD
 jmp nom_error
.syntax:
 mov esi,NEBOC_NOM_DIAG_SYNTAX
 jmp nom_error

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
nom_parse_enum:
 mov qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 mov eax,1
 mov edi,NEBOC_TOKEN_IDENTIFIER
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov eax,1
 call nom_token_hash
 mov rbp,rax
 mov [r12+NEBOC_NOM_TYPE_KEY_OFFSET],rax
 mov eax,2
 mov edi,NEBOC_TOKEN_LBRACE
 call nom_kind_is
 test eax,eax
 jz .abi_or_syntax
 mov r15d,3
 xor ebx,ebx
.variant:
 cmp rbx,NEBOC_NOM_MAX_VARIANTS
 jae .variant_error
 mov rax,r15
 mov edi,NEBOC_TOKEN_IDENTIFIER
 call nom_kind_is
 test eax,eax
 jz .syntax
 mov rax,r15
 call nom_token_hash
 mov r13,rax
 xor ecx,ecx
.duplicate_loop:
 cmp rcx,rbx
 jae .unique
 mov rdx,rcx
 shl rdx,5
 add rdx,[r12+NEBOC_NOM_VARIANTS_OFFSET]
 cmp r13,[rdx+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET]
 je .variant_error
 inc rcx
 jmp .duplicate_loop
.unique:
 mov rdx,rbx
 shl rdx,5
 add rdx,[r12+NEBOC_NOM_VARIANTS_OFFSET]
 mov [rdx+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET],r13
 mov r13,rdx
 inc r15
 mov rax,r15
 mov edi,NEBOC_TOKEN_LPAREN
 call nom_kind_is
 test eax,eax
 jz .unit
 inc r15
 mov rax,r15
 call nom_type_at
 test eax,eax
 jnz .payload_ok
 mov rax,r15
 call nom_token_hash
 cmp rax,rbp
 je .identity
 jmp .payload_error
.payload_ok:
 mov [r13+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET],rax
 inc r15
 mov rax,r15
 mov edi,NEBOC_TOKEN_RPAREN
 call nom_kind_is
 test eax,eax
 jz .syntax
 inc r15
.unit:
 inc rbx
 mov rax,r15
 mov edi,NEBOC_TOKEN_COMMA
 call nom_kind_is
 test eax,eax
 jnz .comma
 mov rax,r15
 mov edi,NEBOC_TOKEN_RBRACE
 call nom_kind_is
 test eax,eax
 jnz .close
 mov rax,r15
 mov edi,NEBOC_TOKEN_RESERVED_EQUAL
 call nom_kind_is
 test eax,eax
 jnz .abi
 jmp .syntax
.comma:
 inc r15
 jmp .variant
.close:
 cmp rbx,2
 jb .variant_error
 mov [r12+NEBOC_NOM_VARIANT_COUNT_OFFSET],rbx
 inc r15
 mov rax,r15
 mov edi,NEBOC_TOKEN_SEMICOLON
 call nom_kind_is
 test eax,eax
 jz nom_scan_operations
 inc r15
 jmp nom_scan_operations
.abi_or_syntax:
 mov eax,2
 lea rsi,[rel n_abia1]
 mov edx,n_abia1_len
 call nom_token_match
 test eax,eax
 jnz .abi
.syntax:
 mov esi,NEBOC_NOM_DIAG_SYNTAX
 jmp nom_error
.identity:
 mov esi,NEBOC_NOM_DIAG_IDENTITY
 jmp nom_error
.variant_error:
 mov esi,NEBOC_NOM_DIAG_VARIANT
 jmp nom_error
.payload_error:
 mov esi,NEBOC_NOM_DIAG_PAYLOAD
 jmp nom_error
.abi:
 mov esi,NEBOC_NOM_DIAG_ABI
 jmp nom_error

; R15 is first token after declaration. Scan bounded construction/observer.
nom_scan_operations:
 mov r14,r15
 xor r13d,r13d                         ; exact owner-chain active in statement
 mov qword [r12+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],0
 mov qword [r12+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],0
.scan:
 cmp r14,[r12+NEBOC_NOM_TOKEN_COUNT_OFFSET]
 jae .finish
 mov rax,r14
 mov edi,NEBOC_TOKEN_SEMICOLON
 call nom_kind_is
 test eax,eax
 jz .statement_active_ready
 xor r13d,r13d
.statement_active_ready:
 mov rax,r14
 lea rsi,[rel n_reflection]
 mov edx,n_reflection_len
 call nom_token_match
 test eax,eax
 jnz .abi
 mov rax,r14
 lea rsi,[rel n_abia1]
 mov edx,n_abia1_len
 call nom_token_match
 test eax,eax
 jnz .abi
 mov rax,r14
 lea rsi,[rel n_sizeof]
 mov edx,n_sizeof_len
 call nom_token_match
 test eax,eax
 jz .unwrap
 test r13,r13
 jz .unwrap
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_SIZEOF
.unwrap:
 mov rax,r14
 lea rsi,[rel n_unwrap]
 mov edx,n_unwrap_len
 call nom_token_match
 test eax,eax
 jz .discriminant
 test r13,r13
 jz .discriminant
 cmp qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 je .discriminant
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_UNWRAP
.discriminant:
 mov rax,r14
 lea rsi,[rel n_discriminant]
 mov edx,n_discriminant_len
 call nom_token_match
 test eax,eax
 jz .match
 test r13,r13
 jz .match
 cmp qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 jne .match
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_DISCRIMINANT
.match:
 mov rax,r14
 mov edi,NEBOC_TOKEN_KW_MATCH
 call nom_kind_is
 test eax,eax
 jz .literal
 cmp qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 jne .literal
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_MATCH
.literal:
 ; Payload evidence is accepted only from the exact nominal construction
 ; below.  An unrelated literal elsewhere in a multi-owner Program cannot
 ; define this owner's value identity.
.construction:
 mov rax,r14
 call nom_token_hash
 cmp rax,[r12+NEBOC_NOM_TYPE_KEY_OFFSET]
 jne .next
 mov rax,r14
 inc rax
 mov edi,NEBOC_TOKEN_DOT
 call nom_kind_is
 test eax,eax
 jnz .enum_construct
 mov rax,r14
 inc rax
 mov edi,NEBOC_TOKEN_LPAREN
 call nom_kind_is
 test eax,eax
 jz .next
 mov r13d,1
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_CONSTRUCTED
 lea rax,[r14+2]
 call nom_literal_at
 test eax,eax
 jz .next
 cmp rax,[r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET]
 jne .constructor_payload_error
 mov [r12+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],rax
 mov [r12+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],rdx
 jmp .next
.constructor_payload_error:
 lea rax,[r14+2]
 mov [r12+NEBOC_NOM_ERROR_TOKEN_OFFSET],rax
 jmp .payload_error
.enum_construct:
 cmp qword [r12+NEBOC_NOM_KIND_OFFSET],NEBOC_NOM_KIND_ENUM
 je .enum_owner_construct
 mov r13d,1
 jmp .next
.enum_owner_construct:
 mov r13d,1
 lea rax,[r14+2]
 lea rsi,[rel n_sizeof]
 mov edx,n_sizeof_len
 call nom_token_match
 test eax,eax
 jnz .next
 lea rax,[r14+2]
 call nom_token_hash
 xor ecx,ecx
.find_variant:
 cmp rcx,[r12+NEBOC_NOM_VARIANT_COUNT_OFFSET]
 jae .variant_error
 mov rdx,rcx
 shl rdx,5
 add rdx,[r12+NEBOC_NOM_VARIANTS_OFFSET]
 cmp rax,[rdx+NEBOC_NOM_VARIANT_NAME_HASH_OFFSET]
 je .active
 inc rcx
 jmp .find_variant
.active:
 mov r13,rdx
 mov [r12+NEBOC_NOM_ACTIVE_TAG_OFFSET],rcx
 mov rax,[r13+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET]
 mov [r12+NEBOC_NOM_UNDERLYING_TYPE_OFFSET],rax
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_CONSTRUCTED
 test rax,rax
 jz .next
 lea rax,[r14+3]
 mov edi,NEBOC_TOKEN_LPAREN
 call nom_kind_is
 test eax,eax
 jz .payload_error
 lea rax,[r14+4]
 call nom_literal_at
 test eax,eax
 jz .payload_error
 cmp rax,[r13+NEBOC_NOM_VARIANT_PAYLOAD_TYPE_OFFSET]
 jne .payload_error
 mov [r12+NEBOC_NOM_PAYLOAD_TYPE_OFFSET],rax
 mov [r12+NEBOC_NOM_PAYLOAD_VALUE_OFFSET],rdx
.next:
 inc r14
 jmp .scan
.finish:
 mov rax,[r12+NEBOC_NOM_KIND_OFFSET]
 cmp rax,NEBOC_NOM_KIND_ALIAS
 je .alias_finish
 cmp rax,NEBOC_NOM_KIND_NEWTYPE
 je .newtype_finish
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_SIZEOF
 jnz .success
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_CONSTRUCTED
 jz .variant_error
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_UNWRAP
 jnz .identity
 jmp .success
.alias_finish:
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_UNWRAP
 jnz .identity
 jmp .success
.newtype_finish:
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_SIZEOF
 jnz .success
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_CONSTRUCTED
 jz .identity
 test qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_OP_UNWRAP
 jz .identity
.success:
 or qword [r12+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_PARSED | NEBOC_NOM_FLAG_ABI_A0
 mov qword [r12+NEBOC_NOM_FOUND_OFFSET],1
 xor eax,eax
 ret
.abi:
 mov esi,NEBOC_NOM_DIAG_ABI
 jmp nom_error
.identity:
 mov esi,NEBOC_NOM_DIAG_IDENTITY
 jmp nom_error
.variant_error:
 mov esi,NEBOC_NOM_DIAG_VARIANT
 jmp nom_error
.payload_error:
 mov esi,NEBOC_NOM_DIAG_PAYLOAD
 jmp nom_error

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_nominal_parse
 test rdi,rdi
 jz .invalid_direct
 test rdi,7
 jnz .invalid_direct
 push rbx
 push rbp
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 lea rdi,[r12+NEBOC_NOM_FOUND_OFFSET]
 mov ecx,17
 xor eax,eax
 rep stosq
 mov rdi,[r12+NEBOC_NOM_VARIANTS_OFFSET]
 test rdi,rdi
 jz .invalid
 cmp qword [r12+NEBOC_NOM_VARIANT_CAPACITY_OFFSET],NEBOC_NOM_MAX_VARIANTS
 jb .invalid
 mov ecx,NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_NOM_TOKEN_COUNT_OFFSET],6
 jb .not_owned
 xor eax,eax
 lea rsi,[rel n_type]
 mov edx,n_type_len
 call nom_token_match
 test eax,eax
 jnz .alias
 xor eax,eax
 lea rsi,[rel n_newtype]
 mov edx,n_newtype_len
 call nom_token_match
 test eax,eax
 jnz .newtype
 xor eax,eax
 mov edi,NEBOC_TOKEN_KW_ENUM
 call nom_kind_is
 test eax,eax
 jnz .enum
.not_owned:
 xor eax,eax
 jmp .done
.alias:
 call nom_parse_alias
 jmp .done
.newtype:
 call nom_parse_newtype
 jmp .done
.enum:
 call nom_parse_enum
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbp
 pop rbx
 ret
.invalid_direct:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

section .note.GNU-stack noalloc noexec nowrite progbits
%undef call
