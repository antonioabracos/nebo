; ARRAY-VERTICAL-AUD-001 token-structural bounded structs_enums_variants_e_tipos_do_programador programmer-defined type vertical.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/programmer_type_vertical.inc"

%define MAX_DECLS 4
%define MAX_MEMBERS 4
%define MAX_BINDINGS 4
%define NO_TOKEN 0xffffffffffffffff
%define DECL_STRUCT 1
%define DECL_ENUM 2
%define TYPE_INT 1
%define TYPE_BOOL 2
%define TYPE_CHAR 3
%define TYPE_FLOAT 4
%define TYPE_RESULT_POSITIVE_INT_INT 5
%define TYPE_OPTION_INT 6
%define TYPE_RESULT_INT_BOOL 7
%define TYPE_PARAMETER 8
%define TYPE_POSITIVE_INT 9
%define TYPE_NAMED_BASE 256

section .rodata
n_private: db 'private'
n_private_len equ $-n_private
structs_enums_variants_e_tipos_do_programador_n_scalar: db 'Scalar'
structs_enums_variants_e_tipos_do_programador_n_scalar_len equ $-structs_enums_variants_e_tipos_do_programador_n_scalar
structs_enums_variants_e_tipos_do_programador_n_int: db 'Int'
structs_enums_variants_e_tipos_do_programador_n_int_len equ $-structs_enums_variants_e_tipos_do_programador_n_int
structs_enums_variants_e_tipos_do_programador_n_bool: db 'Bool'
structs_enums_variants_e_tipos_do_programador_n_bool_len equ $-structs_enums_variants_e_tipos_do_programador_n_bool
structs_enums_variants_e_tipos_do_programador_n_char: db 'Char'
structs_enums_variants_e_tipos_do_programador_n_char_len equ $-structs_enums_variants_e_tipos_do_programador_n_char
programmer_types_structural_n_float: db 'Float'
n_float_len equ $-programmer_types_structural_n_float
n_positive_int: db 'PositiveInt'
n_positive_int_len equ $-n_positive_int
programmer_types_structural_n_option: db 'Option'
n_option_len equ $-programmer_types_structural_n_option
programmer_types_structural_n_result: db 'Result'
n_result_len equ $-programmer_types_structural_n_result
programmer_types_structural_n_some: db 'Some'
n_some_len equ $-programmer_types_structural_n_some
programmer_types_structural_n_ok: db 'Ok'
n_ok_len equ $-programmer_types_structural_n_ok
structs_enums_variants_e_tipos_do_programador_n_to_positive: db 'toPositiveInt'
structs_enums_variants_e_tipos_do_programador_n_to_positive_len equ $-structs_enums_variants_e_tipos_do_programador_n_to_positive
n_match: db 'match'
n_match_len equ $-n_match

section .bss align=16
request: resq 1
source: resq 1
tokens: resq 1
count: resq 1
cursor: resq 1
decl_count: resq 1
current_decl: resq 1
decl_kind: resq MAX_DECLS
decl_name: resq MAX_DECLS
decl_param: resq MAX_DECLS
decl_member_count: resq MAX_DECLS
member_names: resq MAX_DECLS*MAX_MEMBERS
member_types: resq MAX_DECLS*MAX_MEMBERS
binding_count: resq 1
binding_names: resq MAX_BINDINGS
binding_types: resq MAX_BINDINGS
binding_args: resq MAX_BINDINGS
binding_values: resq MAX_BINDINGS
binding_field_types: resq MAX_BINDINGS*MAX_MEMBERS
binding_field_values: resq MAX_BINDINGS*MAX_MEMBERS
expr_type: resq 1
expr_arg: resq 1
expr_value: resq 1
expr_decl: resq 1
expr_field_types: resq MAX_MEMBERS
expr_field_values: resq MAX_MEMBERS
ctor_seen: resq MAX_MEMBERS
ctor_types: resq MAX_MEMBERS
ctor_values: resq MAX_MEMBERS
scratch_end:

section .text

structs_enums_variants_e_tipos_do_programador_token_ptr:
 cmp rdi,[rel count]
 jae .bad
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel tokens]
 ret
.bad: xor eax,eax
 ret

structs_enums_variants_e_tipos_do_programador_kind_at:
 sub rsp,8
 call structs_enums_variants_e_tipos_do_programador_token_ptr
 add rsp,8
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad: xor eax,eax
 ret

structs_enums_variants_e_tipos_do_programador_token_match:
 cmp rdi,[rel count]
 jae .no
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel tokens]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r8,[rel source]
 add r8,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r8+rcx]
 cmp al,[rsi+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 ret
.no: xor eax,eax
 ret

structs_enums_variants_e_tipos_do_programador_name_equal:
 cmp rdi,[rel count]
 jae .no
 cmp rsi,[rel count]
 jae .no
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel tokens]
 imul rcx,rsi,NEBOC_TOKEN_SIZE
 add rcx,[rel tokens]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r8,[rcx+NEBOC_TOKEN_END_OFFSET]
 sub r8,[rcx+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,r8
 jne .no
 mov r9,[rel source]
 mov r10,r9
 add r9,[rax+NEBOC_TOKEN_START_OFFSET]
 add r10,[rcx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r9+rcx]
 cmp al,[r10+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 ret
.no: xor eax,eax
 ret

expect_kind:
 sub rsp,8
 mov r9d,edi
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,r9d
 jne .no
 inc qword [rel cursor]
 mov eax,1
 add rsp,8
 ret
.no:
 xor eax,eax
 add rsp,8
 ret

expect_atom:
 sub rsp,8
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jz .done
 inc qword [rel cursor]
.done:
 add rsp,8
 ret

current_atom:
 sub rsp,8
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_token_match
 add rsp,8
 ret

parse_signed_int:
 sub rsp,8
 mov r8,[rel cursor]
 mov rdi,r8
 call structs_enums_variants_e_tipos_do_programador_kind_at
 xor r9d,r9d
 cmp eax,NEBOC_TOKEN_MINUS
 jne .integer
 mov r9d,1
 inc r8
 mov rdi,r8
 call structs_enums_variants_e_tipos_do_programador_kind_at
.integer:
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .no
 mov rdi,r8
 call structs_enums_variants_e_tipos_do_programador_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r9d,r9d
 jz .store
 neg rdx
.store:
 inc r8
 mov [rel cursor],r8
 mov eax,1
 add rsp,8
 ret
.no:
 xor eax,eax
 add rsp,8
 ret

initialize:
 push rbp
 mov rbp,rsp
 sub rsp,16
 mov [rsp],rdi
 lea rdi,[rel source]
 mov ecx,(scratch_end-source)/8
 xor eax,eax
 rep stosq
 mov rdi,[rsp]
 mov [rel request],rdi
 test rdi,rdi
 jz .bad
 test rdi,7
 jnz .bad
 mov rax,[rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_SOURCE_OFFSET]
 mov [rel source],rax
 mov rax,[rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_TOKENS_OFFSET]
 mov [rel tokens],rax
 mov rax,[rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_TOKEN_COUNT_OFFSET]
 mov [rel count],rax
 cmp qword [rel source],0
 je .bad
 cmp qword [rel tokens],0
 je .bad
 cmp qword [rel count],0
 je .bad
 mov qword [rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],0
 mov qword [rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],0
 mov qword [rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_OUTPUT_VALUE_OFFSET],0
 mov qword [rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FLAGS_OFFSET],0
 mov qword [rdi+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_HASH_OFFSET],0
 mov qword [rel current_decl],NO_TOKEN
 lea rdi,[rel decl_param]
 mov ecx,MAX_DECLS
 mov rax,NO_TOKEN
 rep stosq
 mov eax,1
 jmp .done
.bad: xor eax,eax
.done: leave
 ret

structs_enums_variants_e_tipos_do_programador_error:
 mov rax,[rel request]
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],1
 mov [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],rdi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

structs_enums_variants_e_tipos_do_programador_success:
 mov rax,[rel request]
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],1
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],0
 mov [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_OUTPUT_VALUE_OFFSET],rdi
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FLAGS_OFFSET],neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323747303900
 xor rdx,rdi
 mov [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_HASH_OFFSET],rdx
 xor eax,eax
 ret

; RDI name token -> RAX declaration index or -1.
find_decl:
 xor ecx,ecx
.loop:
 cmp rcx,[rel decl_count]
 jae .no
 mov rsi,[decl_name+rcx*8]
 push rcx
 call structs_enums_variants_e_tipos_do_programador_name_equal
 pop rcx
 test eax,eax
 jnz .yes
 inc rcx
 jmp .loop
.yes: mov rax,rcx
 ret
.no: mov rax,-1
 ret

; RDI declaration, RSI member-name token -> RAX member or -1.
find_member:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,[decl_member_count+r12*8]
 xor ecx,ecx
.loop:
 cmp rcx,rbx
 jae .no
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rcx
 mov rsi,[member_names+rax*8]
 mov rdi,r13
 mov [rsp],rcx
 call structs_enums_variants_e_tipos_do_programador_name_equal
 mov rcx,[rsp]
 test eax,eax
 jnz .yes
 inc rcx
 jmp .loop
.yes:
 mov rax,rcx
 jmp .done
.no:
 mov rax,-1
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Parse a bounded type at cursor. RAX type code or zero.  Named declarations
; are encoded as TYPE_NAMED_BASE+declaration index.
structs_enums_variants_e_tipos_do_programador_parse_type:
 push rbp
 mov rbp,rsp
 push rbx
 sub rsp,8
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rbx,[rel cursor]
 mov rdi,rbx
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_int]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_int_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .int
 mov rdi,rbx
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_bool]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_bool_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .bool
 mov rdi,rbx
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_char]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_char_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .char
 mov rdi,rbx
 lea rsi,[rel programmer_types_structural_n_float]
 mov edx,n_float_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .float
 mov rdi,rbx
 lea rsi,[rel n_positive_int]
 mov edx,n_positive_int_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .positive
 ; Current generic parameter.
 mov rax,[rel current_decl]
 cmp rax,NO_TOKEN
 je .option
 mov rsi,[decl_param+rax*8]
 cmp rsi,NO_TOKEN
 je .option
 mov rdi,rbx
 call structs_enums_variants_e_tipos_do_programador_name_equal
 test eax,eax
 jnz .param
.option:
 mov rdi,rbx
 lea rsi,[rel programmer_types_structural_n_option]
 mov edx,n_option_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .option_type
 mov rdi,rbx
 lea rsi,[rel programmer_types_structural_n_result]
 mov edx,n_result_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .result_type
 ; Current declaration name is visible for recursive-by-value detection
 ; before it is committed to the declaration table.
 mov rax,[rel current_decl]
 cmp rax,NO_TOKEN
 je .existing_named
 mov rsi,[decl_name+rax*8]
 mov rdi,rbx
 call structs_enums_variants_e_tipos_do_programador_name_equal
 test eax,eax
 jz .existing_named
 mov rax,[rel current_decl]
 inc qword [rel cursor]
 add rax,TYPE_NAMED_BASE
 jmp .done
.existing_named:
 ; Existing named declaration.
 mov rdi,rbx
 call find_decl
 cmp rax,-1
 je .no
 inc qword [rel cursor]
 add rax,TYPE_NAMED_BASE
 jmp .done
.int: mov eax,TYPE_INT
 jmp .simple
.bool: mov eax,TYPE_BOOL
 jmp .simple
.char: mov eax,TYPE_CHAR
 jmp .simple
.float: mov eax,TYPE_FLOAT
 jmp .simple
.positive: mov eax,TYPE_POSITIVE_INT
 jmp .simple
.param: mov eax,TYPE_PARAMETER
.simple:
 inc qword [rel cursor]
 jmp .done
.option_type:
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_LESS
 call expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_int]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_int_len
 call expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_GREATER
 call expect_kind
 test eax,eax
 jz .no
 mov eax,TYPE_OPTION_INT
 jmp .done
.result_type:
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_LESS
 call expect_kind
 test eax,eax
 jz .no
 ; Result<PositiveInt,Int> or Result<Int,Bool>.
 lea rsi,[rel n_positive_int]
 mov edx,n_positive_int_len
 call current_atom
 test eax,eax
 jz .result_int_bool
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_COMMA
 call expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_int]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_int_len
 call expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_GREATER
 call expect_kind
 test eax,eax
 jz .no
 mov eax,TYPE_RESULT_POSITIVE_INT_INT
 jmp .done
.result_int_bool:
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_int]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_int_len
 call expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_COMMA
 call expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_bool]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_bool_len
 call expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_GREATER
 call expect_kind
 test eax,eax
 jz .no
 mov eax,TYPE_RESULT_INT_BOOL
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop rbx
 pop rbp
 ret

; Parse optional one-parameter `<T: Scalar>` declaration.
parse_generic_param:
 push rbp
 mov rbp,rsp
 sub rsp,16
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_LESS
 jne .none
 inc qword [rel cursor]
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .bad
 mov rax,[rel cursor]
 mov [rsp],rax
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 call expect_kind
 test eax,eax
 jz .bad
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_scalar]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_scalar_len
 call expect_atom
 test eax,eax
 jz .bad
 mov edi,NEBOC_TOKEN_GREATER
 call expect_kind
 test eax,eax
 jz .bad
 mov rax,[rsp]
 jmp .done
.none: mov rax,NO_TOKEN
 jmp .done
.bad: xor eax,eax
.done: leave
 ret

; Parse one struct declaration. EAX 0 success, diagnostic positive, -1 syntax.
parse_struct_decl:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,[rel decl_count]
 cmp r12,MAX_DECLS
 jae .syntax
 mov edi,NEBOC_TOKEN_KW_STRUCT
 call expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r13,[rel cursor]
 mov rdi,r13
 call find_decl
 cmp rax,-1
 jne .duplicate_type
 mov [decl_name+r12*8],r13
 mov qword [decl_kind+r12*8],DECL_STRUCT
 inc qword [rel cursor]
 mov [rel current_decl],r12
 call parse_generic_param
 test rax,rax
 jz .syntax
 mov [decl_param+r12*8],rax
 mov edi,NEBOC_TOKEN_LBRACE
 call expect_kind
 test eax,eax
 jz .syntax
 xor ebx,ebx
.field:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .fields_done
 cmp ebx,MAX_MEMBERS
 jae .syntax
 lea rsi,[rel n_private]
 mov edx,n_private_len
 call current_atom
 test eax,eax
 jnz .deferred
 call structs_enums_variants_e_tipos_do_programador_parse_type
 test eax,eax
 jz .syntax
 mov [rsp],rax
 cmp rax,TYPE_NAMED_BASE
 jb .type_ok
 sub rax,TYPE_NAMED_BASE
 cmp rax,r12
 je .recursive
.type_ok:
 mov edi,NEBOC_TOKEN_DOT
 call expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r13,[rel cursor]
 xor ecx,ecx
.duplicate_field_loop:
 cmp ecx,ebx
 jae .field_unique
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rcx
 mov rsi,[member_names+rax*8]
 mov rdi,r13
 push rcx
 sub rsp,8
 call structs_enums_variants_e_tipos_do_programador_name_equal
 add rsp,8
 pop rcx
 test eax,eax
 jnz .duplicate_field
 inc ecx
 jmp .duplicate_field_loop
.field_unique:
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov [member_names+rax*8],r13
 mov rdx,[rsp]
 mov [member_types+rax*8],rdx
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect_kind
 test eax,eax
 jz .syntax
 inc ebx
 jmp .field
.fields_done:
 test ebx,ebx
 jz .empty
 mov [decl_member_count+r12*8],rbx
 inc qword [rel cursor]
 inc qword [rel decl_count]
 xor eax,eax
 jmp .done
.duplicate_type: mov eax,2
 jmp .done
.duplicate_field: mov eax,4
 jmp .done
.deferred: mov eax,12
 jmp .done
.recursive: mov eax,10
 jmp .done
.empty: mov eax,11
 jmp .done
.syntax: mov rax,-1
.done:
 mov qword [rel current_decl],NO_TOKEN
 add rsp,8
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Parse one enum declaration. EAX 0 success, diagnostic positive, -1 syntax.
parse_enum_decl:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,[rel decl_count]
 cmp r12,MAX_DECLS
 jae .syntax
 mov edi,NEBOC_TOKEN_KW_ENUM
 call expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r13,[rel cursor]
 mov rdi,r13
 call find_decl
 cmp rax,-1
 jne .duplicate_type
 mov [decl_name+r12*8],r13
 mov qword [decl_kind+r12*8],DECL_ENUM
 inc qword [rel cursor]
 mov [rel current_decl],r12
 call parse_generic_param
 test rax,rax
 jz .syntax
 mov [decl_param+r12*8],rax
 mov edi,NEBOC_TOKEN_LBRACE
 call expect_kind
 test eax,eax
 jz .syntax
 xor ebx,ebx
.variant:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .variants_done
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 cmp ebx,MAX_MEMBERS
 jae .syntax
 mov r13,[rel cursor]
 xor ecx,ecx
.duplicate_loop:
 cmp ecx,ebx
 jae .unique
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rcx
 mov rsi,[member_names+rax*8]
 mov rdi,r13
 push rcx
 sub rsp,8
 call structs_enums_variants_e_tipos_do_programador_name_equal
 add rsp,8
 pop rcx
 test eax,eax
 jnz .duplicate_variant
 inc ecx
 jmp .duplicate_loop
.unique:
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov [member_names+rax*8],r13
 mov qword [member_types+rax*8],0
 inc qword [rel cursor]
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .discriminant
 inc qword [rel cursor]
 call structs_enums_variants_e_tipos_do_programador_parse_type
 test eax,eax
 jz .syntax
 mov [rsp],rax
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov rdx,[rsp]
 mov [member_types+rax*8],rdx
.discriminant:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_EQUAL
 je .deferred
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect_kind
 test eax,eax
 jz .syntax
 inc ebx
 jmp .variant
.variants_done:
 test ebx,ebx
 jz .empty
 mov [decl_member_count+r12*8],rbx
 inc qword [rel cursor]
 inc qword [rel decl_count]
 xor eax,eax
 jmp .done
.duplicate_type: mov eax,2
 jmp .done
.duplicate_variant: mov eax,8
 jmp .done
.deferred: mov eax,12
 jmp .done
.empty: mov eax,11
 jmp .done
.syntax: mov rax,-1
.done:
 mov qword [rel current_decl],NO_TOKEN
 add rsp,8
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Clear current expression value.
clear_expr:
 lea rdi,[rel expr_type]
 mov ecx,(ctor_seen-expr_type)/8
 xor eax,eax
 rep stosq
 ret

; Find binding by name token RDI -> RAX binding index or -1.
find_binding:
 xor ecx,ecx
.loop:
 cmp rcx,[rel binding_count]
 jae .no
 mov rsi,[binding_names+rcx*8]
 push rcx
 call structs_enums_variants_e_tipos_do_programador_name_equal
 pop rcx
 test eax,eax
 jnz .yes
 inc rcx
 jmp .loop
.yes: mov rax,rcx
 ret
.no: mov rax,-1
 ret

; Substitute a declaration field type for one Int generic argument.
substitute_type:
 cmp rax,TYPE_PARAMETER
 jne .done
 mov rax,rsi
.done: ret

; Parse one expression. EAX 0 success, positive diagnostic, -1 syntax.
parse_expr:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 call clear_expr
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 je .integer
 cmp eax,NEBOC_TOKEN_MINUS
 je .integer
 cmp eax,NEBOC_TOKEN_CHAR
 je .char
 cmp eax,NEBOC_TOKEN_KW_TRUE
 je .true
 cmp eax,NEBOC_TOKEN_KW_FALSE
 je .false
 cmp eax,NEBOC_TOKEN_KW_MATCH
 je .deferred
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rbx,[rel cursor]
 ; match may be lexed as identifier in historical lexer configurations.
 mov rdi,rbx
 lea rsi,[rel n_match]
 mov edx,n_match_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .deferred
 ; Option/Result wrapper constructors.
 mov rdi,rbx
 lea rsi,[rel programmer_types_structural_n_option]
 mov edx,n_option_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .option_expr
 mov rdi,rbx
 lea rsi,[rel programmer_types_structural_n_result]
 mov edx,n_result_len
 call structs_enums_variants_e_tipos_do_programador_token_match
 test eax,eax
 jnz .result_expr
 ; Named declaration constructor or binding.
 mov rdi,rbx
 call find_decl
 cmp rax,-1
 jne .named
 mov rdi,rbx
 call find_binding
 cmp rax,-1
 jne .binding
 jmp .syntax
.integer:
 call parse_signed_int
 test eax,eax
 jz .syntax
 mov qword [rel expr_type],TYPE_INT
 mov [rel expr_value],rdx
 ; Structural positive-int refinement composition.
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .ok
 inc qword [rel cursor]
 lea rsi,[rel structs_enums_variants_e_tipos_do_programador_n_to_positive]
 mov edx,structs_enums_variants_e_tipos_do_programador_n_to_positive_len
 call expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 mov qword [rel expr_type],TYPE_RESULT_POSITIVE_INT_INT
 jmp .ok
.char:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_token_ptr
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [rel cursor]
 mov qword [rel expr_type],TYPE_CHAR
 mov [rel expr_value],rdx
 jmp .ok
.true:
 inc qword [rel cursor]
 mov qword [rel expr_type],TYPE_BOOL
 mov qword [rel expr_value],1
 jmp .ok
.false:
 inc qword [rel cursor]
 mov qword [rel expr_type],TYPE_BOOL
 mov qword [rel expr_value],0
 jmp .ok
.option_expr:
 mov qword [rsp],TYPE_OPTION_INT
 jmp .wrapper_expr
.result_expr:
 ; Determine the exact Result type structurally with structs_enums_variants_e_tipos_do_programador_parse_type.
 mov rax,[rel cursor]
 mov [rsp],rax
 call structs_enums_variants_e_tipos_do_programador_parse_type
 test eax,eax
 jz .syntax
 mov [rsp],rax
 jmp .wrapper_after_type
.wrapper_expr:
 call structs_enums_variants_e_tipos_do_programador_parse_type
 test eax,eax
 jz .syntax
.wrapper_after_type:
 mov edi,NEBOC_TOKEN_LPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 ; Some(...) or Ok(...).
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 call parse_expr
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .done
 mov r14,[rel expr_value]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp]
 mov [rel expr_type],rax
 mov [rel expr_value],r14
 jmp .ok
.named:
 mov r12,rax
 inc qword [rel cursor]
 xor r13d,r13d
 ; Optional single concrete generic type argument.
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_LESS
 jne .named_dispatch
 inc qword [rel cursor]
 call structs_enums_variants_e_tipos_do_programador_parse_type
 test eax,eax
 jz .syntax
 mov r13,rax
 mov edi,NEBOC_TOKEN_GREATER
 call expect_kind
 test eax,eax
 jz .syntax
.named_dispatch:
 mov rax,[decl_param+r12*8]
 cmp rax,NO_TOKEN
 je .no_param
 test r13,r13
 jz .syntax
 jmp .kind
.no_param:
 test r13,r13
 jnz .syntax
.kind:
 cmp qword [decl_kind+r12*8],DECL_STRUCT
 je .struct_ctor
 cmp qword [decl_kind+r12*8],DECL_ENUM
 je .enum_ctor
 jmp .syntax
.struct_ctor:
 mov edi,NEBOC_TOKEN_LBRACE
 call expect_kind
 test eax,eax
 jz .syntax
 lea rdi,[rel ctor_seen]
 mov ecx,MAX_MEMBERS*3
 xor eax,eax
 rep stosq
.field_loop:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .struct_fields_done
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[rel cursor]
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_RESERVED_COLON
 call expect_kind
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r15
 call find_member
 cmp rax,-1
 je .unknown
 mov rbx,rax
 cmp qword [ctor_seen+rbx*8],0
 jne .duplicate_field
 call parse_expr
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .done
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov r8,[member_types+rax*8]
 mov rax,r8
 mov rsi,r13
 call substitute_type
 cmp rax,[rel expr_type]
 jne .field_type
 mov qword [ctor_seen+rbx*8],1
 mov rax,[rel expr_type]
 mov [ctor_types+rbx*8],rax
 mov rax,[rel expr_value]
 mov [ctor_values+rbx*8],rax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .field_loop
 inc qword [rel cursor]
 jmp .field_loop
.struct_fields_done:
 inc qword [rel cursor]
 mov rcx,[decl_member_count+r12*8]
 xor ebx,ebx
.missing_loop:
 cmp rbx,rcx
 jae .struct_ok
 cmp qword [ctor_seen+rbx*8],0
 je .missing
 inc rbx
 jmp .missing_loop
.struct_ok:
 mov rax,r12
 add rax,TYPE_NAMED_BASE
 mov [rel expr_type],rax
 mov [rel expr_arg],r13
 mov [rel expr_decl],r12
 xor ebx,ebx
.copy_fields:
 cmp ebx,MAX_MEMBERS
 jae .ok
 mov rax,[ctor_types+rbx*8]
 mov [expr_field_types+rbx*8],rax
 mov rax,[ctor_values+rbx*8]
 mov [expr_field_values+rbx*8],rax
 inc ebx
 jmp .copy_fields
.enum_ctor:
 mov edi,NEBOC_TOKEN_DOT
 call expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[rel cursor]
 inc qword [rel cursor]
 mov rdi,r12
 mov rsi,r15
 call find_member
 cmp rax,-1
 je .unknown
 mov rbx,rax
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov r14,[member_types+rax*8]
 xor r15d,r15d
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .enum_payload_done
 inc qword [rel cursor]
 call parse_expr
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .done
 mov r15,1
 mov r8,[rel expr_type]
 mov r9,[rel expr_value]
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .syntax
.enum_payload_done:
 mov rax,r14
 mov rsi,r13
 call substitute_type
 test rax,rax
 jz .unit_expected
 test r15,r15
 jz .payload_type
 cmp rax,r8
 jne .payload_type
 mov [rel expr_value],r9
 jmp .enum_ok
.unit_expected:
 test r15,r15
 jnz .payload_type
 mov qword [rel expr_value],0
.enum_ok:
 mov rax,r12
 add rax,TYPE_NAMED_BASE
 mov [rel expr_type],rax
 mov [rel expr_arg],r13
 mov [rel expr_decl],r12
 jmp .ok
.binding:
 mov r12,rax
 inc qword [rel cursor]
 mov rax,[binding_types+r12*8]
 mov [rel expr_type],rax
 mov rax,[binding_args+r12*8]
 mov [rel expr_arg],rax
 mov rax,[binding_values+r12*8]
 mov [rel expr_value],rax
 mov rax,[binding_types+r12*8]
 cmp rax,TYPE_NAMED_BASE
 jb .ok
 sub rax,TYPE_NAMED_BASE
 mov [rel expr_decl],rax
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .copy_binding_fields
 inc qword [rel cursor]
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r15,[rel cursor]
 inc qword [rel cursor]
 mov rdi,[rel expr_decl]
 mov rsi,r15
 call find_member
 cmp rax,-1
 je .unknown
 mov rbx,rax
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov rdx,[binding_field_types+rax*8]
 mov [rel expr_type],rdx
 mov rdx,[binding_field_values+rax*8]
 mov [rel expr_value],rdx
 mov qword [rel expr_decl],0
 jmp .ok
.copy_binding_fields:
 xor ebx,ebx
.copy_binding_loop:
 cmp ebx,MAX_MEMBERS
 jae .ok
 mov rax,r12
 imul rax,MAX_MEMBERS
 add rax,rbx
 mov rdx,[binding_field_types+rax*8]
 mov [expr_field_types+rbx*8],rdx
 mov rdx,[binding_field_values+rax*8]
 mov [expr_field_values+rbx*8],rdx
 inc ebx
 jmp .copy_binding_loop
.missing: mov eax,5
 jmp .done
.duplicate_field: mov eax,4
 jmp .done
.unknown: mov eax,6
 jmp .done
.field_type: mov eax,7
 jmp .done
.payload_type: mov eax,9
 jmp .done
.deferred: mov eax,12
 jmp .done
.syntax: mov rax,-1
 jmp .done
.ok: xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Store current expression under binding-name token RDI.
store_binding:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 sub rsp,16
 mov r12,rdi
 mov rbx,[rel binding_count]
 cmp rbx,MAX_BINDINGS
 jae .no
 mov [binding_names+rbx*8],r12
 mov rax,[rel expr_type]
 mov [binding_types+rbx*8],rax
 mov rax,[rel expr_arg]
 mov [binding_args+rbx*8],rax
 mov rax,[rel expr_value]
 mov [binding_values+rbx*8],rax
 xor ecx,ecx
.copy:
 cmp ecx,MAX_MEMBERS
 jae .yes
 mov rax,rbx
 imul rax,MAX_MEMBERS
 add rax,rcx
 mov rdx,[expr_field_types+rcx*8]
 mov [binding_field_types+rax*8],rdx
 mov rdx,[expr_field_values+rcx*8]
 mov [binding_field_values+rax*8],rdx
 inc ecx
 jmp .copy
.yes:
 inc qword [rel binding_count]
 mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,16
 pop r12
 pop rbx
 pop rbp
 ret

NEBOC_ABI_FUNCTION neboc_programmer_type_vertical_recognize
 push rbp
 mov rbp,rsp
 sub rsp,16
 call initialize
 test eax,eax
 jz .invalid
 ; Claim only when the canonical token stream contains a real declaration.
 xor ecx,ecx
.claim:
 cmp rcx,[rel count]
 jae .not_owned
 mov rdi,rcx
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_KW_STRUCT
 je .claimed
 cmp eax,NEBOC_TOKEN_KW_ENUM
 je .claimed
 inc rcx
 jmp .claim
.claimed:
 mov qword [rel cursor],0
.declarations:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_KW_STRUCT
 je .struct
 cmp eax,NEBOC_TOKEN_KW_ENUM
 je .enum
 jmp .start
.struct:
 call parse_struct_decl
 cmp eax,-1
 je .not_owned
 test eax,eax
 jnz .semantic
 jmp .declarations
.enum:
 call parse_enum_decl
 cmp eax,-1
 je .not_owned
 test eax,eax
 jnz .semantic
 jmp .declarations
.start:
 mov edi,NEBOC_TOKEN_KW_START
 call expect_kind
 test eax,eax
 jz .not_owned
 mov edi,NEBOC_TOKEN_LPAREN
 call expect_kind
 test eax,eax
 jz .not_owned
 mov edi,NEBOC_TOKEN_RPAREN
 call expect_kind
 test eax,eax
 jz .not_owned
 mov edi,NEBOC_TOKEN_LBRACE
 call expect_kind
 test eax,eax
 jz .not_owned
 mov qword [rsp],0
.statement:
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_RBRACE
 je .finish
 cmp eax,NEBOC_TOKEN_EOF
 je .not_owned
 call parse_expr
 cmp eax,-1
 je .not_owned
 test eax,eax
 jnz .semantic
 mov rax,[rel expr_value]
 mov [rsp],rax
 ; A constructor expression may be followed by value-first `.binding`.
 mov rdi,[rel cursor]
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .semicolon
 mov rax,[rel cursor]
 inc rax
 mov rdi,rax
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .not_owned
 mov rax,[rel cursor]
 add rax,2
 mov rdi,rax
 call structs_enums_variants_e_tipos_do_programador_kind_at
 cmp eax,NEBOC_TOKEN_SEMICOLON
 jne .not_owned
 inc qword [rel cursor]
 mov rdi,[rel cursor]
 inc qword [rel cursor]
 call store_binding
 test eax,eax
 jz .not_owned
.semicolon:
 mov edi,NEBOC_TOKEN_SEMICOLON
 call expect_kind
 test eax,eax
 jz .not_owned
 jmp .statement
.finish:
 inc qword [rel cursor]
 mov edi,NEBOC_TOKEN_EOF
 call expect_kind
 test eax,eax
 jz .not_owned
 mov rdi,[rsp]
 call structs_enums_variants_e_tipos_do_programador_success
 jmp .done
.semantic:
 mov edi,eax
 call structs_enums_variants_e_tipos_do_programador_error
 jmp .done
.not_owned:
 mov rax,[rel request]
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],0
 mov qword [rax+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],0
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 leave
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
