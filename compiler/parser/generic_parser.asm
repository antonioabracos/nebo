; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F05 bounded generic function/type recognizer.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/generic_parser.inc"

section .rodata
n_t: db 'T'
n_t_len equ $-n_t
n_copy: db 'Copy'
n_copy_len equ $-n_copy
n_eq: db 'Eq'
n_eq_len equ $-n_eq
n_comparable: db 'Comparable'
n_comparable_len equ $-n_comparable
n_hash: db 'Hash'
n_hash_len equ $-n_hash
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

section .text

; request*, token index -> token* or zero
token_ptr:
 mov rax,rsi
 cmp rax,[rdi+NEBOC_GEN_TOKEN_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_GEN_TOKENS_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; request*, index, kind -> 1/0
kind_is:
 push rdx
 call token_ptr
 pop rdx
 test rax,rax
 jz .no
 cmp [rax+NEBOC_TOKEN_KIND_OFFSET],rdx
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; request*, index, bytes*, length -> 1/0
token_match:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,r15
 jne .no
 mov rax,[r12+NEBOC_GEN_SOURCE_OFFSET]
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

; request*, token index -> stable nonzero FNV token hash
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
token_hash:
 push rbx
 push r12
 mov r12,rdi
 call token_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rsi,[r12+NEBOC_GEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
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
 pop r12
 pop rbx
 ret
.bad:
 xor eax,eax
 pop r12
 pop rbx
 ret

; request*, diagnostic -> INVALID_SOURCE
%undef call
parse_error:
 mov qword [rdi+NEBOC_GEN_FOUND_OFFSET],1
 mov [rdi+NEBOC_GEN_DIAGNOSTIC_OFFSET],rsi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; request*, token index -> EAX type, RDX scalar value. EAX zero is unsupported.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
literal_type:
 call token_ptr
 test rax,rax
 jz .bad
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rcx,NEBOC_TOKEN_INTEGER
 je .int
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
.bad:
 xor eax,eax
 xor edx,edx
 ret
.int: mov eax,NEBOC_GEN_TYPE_INT
 ret
.char: mov eax,NEBOC_GEN_TYPE_CHAR
 ret
.float:
 mov eax,NEBOC_GEN_TYPE_FLOAT
 xor edx,edx
 ret
.true:
 mov eax,NEBOC_GEN_TYPE_BOOL
 mov edx,1
 ret
.false:
 mov eax,NEBOC_GEN_TYPE_BOOL
 xor edx,edx
 ret
.text:
 mov eax,NEBOC_GEN_TYPE_TEXT
 xor edx,edx
 ret

; request*, token index -> EAX type id or zero
%undef call
named_type:
 push rbx
 mov rbx,rsi
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call token_match
 test eax,eax
 jnz .int
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call token_match
 test eax,eax
 jnz .bool
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call token_match
 test eax,eax
 jnz .char
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call token_match
 test eax,eax
 jnz .float
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call token_match
 test eax,eax
 jnz .text
 xor eax,eax
 jmp .done
.int: mov eax,NEBOC_GEN_TYPE_INT
 jmp .done
.bool: mov eax,NEBOC_GEN_TYPE_BOOL
 jmp .done
.char: mov eax,NEBOC_GEN_TYPE_CHAR
 jmp .done
.float: mov eax,NEBOC_GEN_TYPE_FLOAT
 jmp .done
.text: mov eax,NEBOC_GEN_TYPE_TEXT
.done:
 pop rbx
 ret

; request*, type id, value, declaration hash, constraint, kind -> status
; RDI, RSI, RDX, RCX, R8, R9
add_record:
 mov rax,[rdi+NEBOC_GEN_USE_COUNT_OFFSET]
 cmp rax,NEBOC_GEN_MAX_INSTANCES
 jae .budget
 cmp rax,[rdi+NEBOC_GEN_CAPACITY_OFFSET]
 jae .budget
 shl rax,6
 add rax,[rdi+NEBOC_GEN_RECORDS_OFFSET]
 mov [rax+NEBOC_GEN_RECORD_DECLARATION_HASH_OFFSET],rcx
 mov [rax+NEBOC_GEN_RECORD_TYPE_ID_OFFSET],rsi
 mov qword [rax+NEBOC_GEN_RECORD_CONST_KEY_OFFSET],0
 mov [rax+NEBOC_GEN_RECORD_CONSTRAINT_OFFSET],r8
 mov [rax+NEBOC_GEN_RECORD_KIND_OFFSET],r9
 inc qword [rdi+NEBOC_GEN_USE_COUNT_OFFSET]
 mov [rdi+NEBOC_GEN_RESULT_OFFSET],rdx
 xor eax,eax
 ret
.budget:
 mov esi,NEBOC_GEN_DIAG_BUDGET
 jmp parse_error

; Recognizes only the cli_driver constraints; historical generic<T: Scalar> declines.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
NEBOC_ABI_FUNCTION neboc_generic_parse
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
 sub rsp,32
 mov r12,rdi
 lea rdi,[r12+NEBOC_GEN_FOUND_OFFSET]
 mov ecx,8
 xor eax,eax
 rep stosq
 mov r13,[r12+NEBOC_GEN_RECORDS_OFFSET]
 test r13,r13
 jz .invalid
 cmp qword [r12+NEBOC_GEN_CAPACITY_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_GEN_CAPACITY_OFFSET],NEBOC_GEN_MAX_INSTANCES
 ja .invalid
 mov rdi,r13
 mov rcx,[r12+NEBOC_GEN_CAPACITY_OFFSET]
 shl rcx,3
 xor eax,eax
 rep stosq
 cmp qword [r12+NEBOC_GEN_TOKEN_COUNT_OFFSET],7
 jb .not_owned
 mov rdi,r12
 xor esi,esi
 mov edx,NEBOC_TOKEN_KW_GENERIC
 call kind_is
 test eax,eax
 jz .not_owned

 ; Own only Copy/Eq/Comparable/Hash; Scalar remains the historical generics_constraints_overload_e_dispatch route.
 mov rdi,r12
 mov esi,4
 lea rdx,[rel n_copy]
 mov ecx,n_copy_len
 call token_match
 test eax,eax
 jnz .constraint_copy
 mov rdi,r12
 mov esi,4
 lea rdx,[rel n_eq]
 mov ecx,n_eq_len
 call token_match
 test eax,eax
 jnz .constraint_eq
 mov rdi,r12
 mov esi,4
 lea rdx,[rel n_comparable]
 mov ecx,n_comparable_len
 call token_match
 test eax,eax
 jnz .constraint_comparable
 mov rdi,r12
 mov esi,4
 lea rdx,[rel n_hash]
 mov ecx,n_hash_len
 call token_match
 test eax,eax
 jnz .constraint_hash
 jmp .not_owned
.constraint_copy: mov qword [rsp],NEBOC_GEN_CONSTRAINT_COPY
 jmp .header
.constraint_eq: mov qword [rsp],NEBOC_GEN_CONSTRAINT_EQ
 jmp .header
.constraint_comparable: mov qword [rsp],NEBOC_GEN_CONSTRAINT_COMPARABLE
 jmp .header
.constraint_hash: mov qword [rsp],NEBOC_GEN_CONSTRAINT_HASH

.header:
 mov qword [r12+NEBOC_GEN_FOUND_OFFSET],1
 mov rdi,r12
 mov esi,1
 mov edx,NEBOC_TOKEN_LESS
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov esi,2
 lea rdx,[rel n_t]
 mov ecx,n_t_len
 call token_match
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov esi,3
 mov edx,NEBOC_TOKEN_RESERVED_COLON
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov esi,5
 mov edx,NEBOC_TOKEN_GREATER
 call kind_is
 test eax,eax
 jz .syntax

 ; Find start and reject multiple generic declarations as a mangle collision.
 xor ebx,ebx
 xor ebp,ebp
 mov qword [rsp+16],-1
.find_start:
 cmp rbx,[r12+NEBOC_GEN_TOKEN_COUNT_OFFSET]
 jae .found_start
 mov rdi,r12
 mov rsi,rbx
 call token_ptr
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_GENERIC
 jne .check_start
 inc rbp
.check_start:
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .next_start
 mov [rsp+16],rbx
.next_start:
 inc rbx
 jmp .find_start
.found_start:
 cmp rbp,1
 jne .collision
 cmp qword [rsp+16],-1
 je .syntax
 mov qword [r12+NEBOC_GEN_DECLARATION_COUNT_OFFSET],1

 mov rdi,r12
 mov esi,6
 mov edx,NEBOC_TOKEN_KW_STRUCT
 call kind_is
 test eax,eax
 jnz .type_header
 mov rdi,r12
 mov esi,6
 mov edx,NEBOC_TOKEN_LPAREN
 call kind_is
 test eax,eax
 jz .syntax
 mov qword [rsp+24],14
 mov qword [rsp+8],11
 mov r14d,NEBOC_GEN_KIND_FUNCTION
 mov rdi,r12
 mov esi,7
 lea rdx,[rel n_t]
 mov ecx,n_t_len
 call token_match
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov esi,8
 mov edx,NEBOC_TOKEN_DOT
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov esi,10
 mov edx,NEBOC_TOKEN_RPAREN
 call kind_is
 test eax,eax
 jz .syntax
 jmp .decl_ready
.type_header:
 mov qword [rsp+24],8
 mov qword [rsp+8],7
 mov r14d,NEBOC_GEN_KIND_TYPE

.decl_ready:
 mov rdi,r12
 mov rsi,[rsp+8]
 call token_ptr
 test rax,rax
 jz .syntax
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,r12
 mov rsi,[rsp+8]
 call token_hash
 test rax,rax
 jz .syntax
 mov r15,rax

 ; A declaration-name reference in its body is recursive expansion.
 mov rbx,[rsp+24]
.recursive_scan:
 cmp rbx,[rsp+16]
 jae .use_scan_begin
 mov rdi,r12
 mov rsi,rbx
 call token_hash
 cmp rax,r15
 je .recursive
 inc rbx
 jmp .recursive_scan

.use_scan_begin:
 mov rbx,[rsp+16]
.use_scan:
 cmp rbx,[r12+NEBOC_GEN_TOKEN_COUNT_OFFSET]
 jae .uses_done
 cmp r14,NEBOC_GEN_KIND_FUNCTION
 je .function_use
 ; Type use: Name < Type > ( literal ) . field
 mov rdi,r12
 mov rsi,rbx
 call token_hash
 cmp rax,r15
 jne .use_next
 mov rdi,r12
 lea rsi,[rbx+1]
 mov edx,NEBOC_TOKEN_LESS
 call kind_is
 test eax,eax
 jz .use_next
 mov rdi,r12
 lea rsi,[rbx+2]
 call named_type
 test eax,eax
 jz .type_error
 mov r13,rax
 mov rdi,r12
 lea rsi,[rbx+5]
 call literal_type
 test eax,eax
 jz .type_error
 cmp rax,r13
 jne .type_error
 mov rbp,rdx
 mov rdi,r12
 lea rsi,[rbx+3]
 mov edx,NEBOC_TOKEN_GREATER
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 lea rsi,[rbx+4]
 mov edx,NEBOC_TOKEN_LPAREN
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbp
 mov rcx,r15
 mov r8,[rsp]
 mov r9,r14
 call add_record
 test eax,eax
 jnz .done
 add rbx,6
 jmp .use_next

.function_use:
 mov rdi,r12
 mov rsi,rbx
 call literal_type
 test eax,eax
 jz .use_next
 mov r13,rax
 mov rbp,rdx
 mov rdi,r12
 lea rsi,[rbx+1]
 mov edx,NEBOC_TOKEN_DOT
 call kind_is
 test eax,eax
 jz .use_next
 mov rdi,r12
 lea rsi,[rbx+2]
 call token_hash
 cmp rax,r15
 jne .use_next
 mov rdi,r12
 lea rsi,[rbx+3]
 mov edx,NEBOC_TOKEN_LPAREN
 call kind_is
 test eax,eax
 jz .syntax
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbp
 mov rcx,r15
 mov r8,[rsp]
 mov r9,r14
 call add_record
 test eax,eax
 jnz .done
 add rbx,3
.use_next:
 inc rbx
 jmp .use_scan

.uses_done:
 cmp qword [r12+NEBOC_GEN_USE_COUNT_OFFSET],0
 je .syntax
 mov qword [r12+NEBOC_GEN_FLAGS_OFFSET],NEBOC_GEN_FLAG_PARSED
 xor eax,eax
 jmp .done
.constraint_error:
 mov esi,NEBOC_GEN_DIAG_CONSTRAINT
 jmp .error
.collision:
 mov esi,NEBOC_GEN_DIAG_COLLISION
 jmp .error
.recursive:
 mov esi,NEBOC_GEN_DIAG_RECURSIVE
 jmp .error
.syntax:
 mov esi,NEBOC_GEN_DIAG_SYNTAX
 jmp .error
.type_error:
 mov esi,NEBOC_GEN_DIAG_TYPE
.error:
 mov rdi,r12
 call parse_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
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
