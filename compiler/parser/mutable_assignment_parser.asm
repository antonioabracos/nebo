; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-F04 bounded mutable declaration and assignment syntax recognizer
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/parser/mutable_assignment_parser.inc"

section .rodata
n_mutable: db "mutable"
n_mutable_len equ $-n_mutable

section .text

; Request owns no storage. This pass claims only sources containing `.mutable`
; or reserved `=` and rejects shapes that must not reach the generic parser.
NEBOC_ABI_FUNCTION neboc_mutable_assignment_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_PARSE_TOKENS_OFFSET]
 mov r14,[r12+NEBOC_PARSE_TOKEN_COUNT_OFFSET]
 test r13,r13
 jz .invalid
 lea rdi,[r12+NEBOC_PARSE_FOUND_OFFSET]
 mov ecx,6
 xor eax,eax
 rep stosq
 xor ebx,ebx
.scan:
 cmp rbx,r14
 jae .finish
 mov rax,rbx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,r13
 mov r15,rax
 mov rcx,[r15+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_RESERVED_EQUAL
 je .equal
 cmp rcx,NEBOC_TOKEN_OPTION_ASSIGN
 je .option_equal
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,r12
 mov rsi,rbx
 call rf27g02_is_mutable
 test eax,eax
 jz .next
 mov qword [r12+NEBOC_PARSE_FOUND_OFFSET],1
 inc qword [r12+NEBOC_PARSE_MUTABLE_COUNT_OFFSET]
 ; Canonical marker must be `. <binding-identifier> . mutable`.
 cmp rbx,3
 jb .mutable_missing
 mov rax,rbx
 dec rax
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .mutable_syntax
 mov rax,rbx
 sub rax,2
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .mutable_syntax
 mov rax,rbx
 sub rax,3
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .mutable_syntax
 ; The modifier is terminal and may occur exactly once.
 lea rax,[rbx+1]
 cmp rax,r14
 jae .mutable_syntax
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_DOT
 jne .mutable_expect_semicolon
 lea rax,[rbx+2]
 cmp rax,r14
 jae .mutable_syntax
 mov rsi,rax
 mov rdi,r12
 call rf27g02_is_mutable
 test eax,eax
 jnz .mutable_duplicate
 jmp .mutable_syntax
.mutable_expect_semicolon:
 lea rax,[rbx+1]
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_SEMICOLON
 jne .mutable_syntax
 ; A statement delimiter before the initializer's dot means no initializer.
 mov rax,rbx
 sub rax,3
 test rax,rax
 jz .mutable_missing
 dec rax
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_LBRACE
 je .mutable_missing
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .mutable_missing
 jmp .next
.equal:
 mov qword [r12+NEBOC_PARSE_FOUND_OFFSET],1
 inc qword [r12+NEBOC_PARSE_ASSIGNMENT_COUNT_OFFSET]
 ; Assignment is a whole statement starting with one local identifier. F04
 ; recognizes adjacent compound-operator/equal token pairs.
 test rbx,rbx
 jz .not_lvalue
 mov rax,rbx
 dec rax
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 je .simple_boundary
 cmp rax,NEBOC_TOKEN_PLUS
 je .compound
 cmp rax,NEBOC_TOKEN_MINUS
 je .compound
 cmp rax,NEBOC_TOKEN_STAR
 je .compound
 cmp rax,NEBOC_TOKEN_SLASH
 je .compound
 cmp rax,NEBOC_TOKEN_PERCENT
 je .compound
 cmp rax,NEBOC_TOKEN_CARET
 je .compound
 jmp .not_lvalue
.option_equal:
 mov qword [r12+NEBOC_PARSE_FOUND_OFFSET],1
 inc qword [r12+NEBOC_PARSE_ASSIGNMENT_COUNT_OFFSET]
 test rbx,rbx
 jz .not_lvalue
 mov rax,rbx
 dec rax
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .not_lvalue
 jmp .equal_rhs
.compound:
 cmp rbx,2
 jb .not_lvalue
 ; The operator and reserved equal token must form one lexical operator.
 mov rax,rbx
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,r13
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 cmp rdx,[r15+NEBOC_TOKEN_START_OFFSET]
 jne .compound_unsupported_diagnostic
 mov rax,rbx
 sub rax,2
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .not_lvalue
 cmp rbx,2
 je .assignment_expression
 mov rax,rbx
 sub rax,3
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_LBRACE
 je .equal_rhs
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .equal_rhs
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .assignment_expression
 jmp .equal_rhs
.compound_unsupported:
 cmp rbx,2
 jb .not_lvalue
 mov rax,rbx
 sub rax,2
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .not_lvalue
 jmp .compound_unsupported_diagnostic
.simple_boundary:
 cmp rbx,1
 je .assignment_expression
 mov rax,rbx
 sub rax,2
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_LBRACE
 je .equal_rhs
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .equal_rhs
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .assignment_expression
.equal_rhs:
 lea rax,[rbx+1]
 cmp rax,r14
 jae .assignment_expression
 ; Search only this statement for a second `=`; it is a forbidden chain.
 mov rcx,rax
.equal_tail:
 cmp rcx,r14
 jae .assignment_expression
 mov rax,rcx
 call rf27g02_kind_at
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .next
 cmp rax,NEBOC_TOKEN_RESERVED_EQUAL
 je .chained
 inc rcx
 jmp .equal_tail
.next:
 inc rbx
 jmp .scan
.mutable_missing:
 mov esi,NEBOC_DIAG_MUTABLE_MISSING_INITIALIZER
 jmp .diagnostic
.mutable_syntax:
 mov esi,NEBOC_DIAG_MUTABLE_SYNTAX
 jmp .diagnostic
.mutable_duplicate:
 mov esi,NEBOC_DIAG_MUTABLE_DUPLICATED
 jmp .diagnostic
.not_lvalue:
 mov esi,NEBOC_DIAG_ASSIGNMENT_NOT_LVALUE
 jmp .diagnostic
.assignment_expression:
 mov esi,NEBOC_DIAG_ASSIGNMENT_EXPRESSION
 jmp .diagnostic
.chained:
 mov esi,NEBOC_DIAG_ASSIGNMENT_CHAINED
 jmp .diagnostic
.compound_unsupported_diagnostic:
 mov esi,NEBOC_DIAG_COMPOUND_UNSUPPORTED
.diagnostic:
 mov [r12+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET],rsi
 mov [r12+NEBOC_PARSE_ERROR_TOKEN_OFFSET],rbx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.finish:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+NEBOC_PARSE_FOUND_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_PARSE_MUTABLE_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_PARSE_ASSIGNMENT_COUNT_OFFSET]
 imul rax,rcx
 mov [r12+NEBOC_PARSE_HASH_OFFSET],rax
 xor eax,eax
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

; R12=request, RAX=index -> token kind or INVALID.
rf27g02_kind_at:
 cmp rax,[r12+NEBOC_PARSE_TOKEN_COUNT_OFFSET]
 jae .invalid
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_PARSE_TOKENS_OFFSET]
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.invalid:
 xor eax,eax
 ret

; request*, token index -> 1 iff identifier bytes equal `mutable`.
rf27g02_is_mutable:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 cmp rbx,[r12+NEBOC_PARSE_TOKEN_COUNT_OFFSET]
 jae .no
 imul rbx,NEBOC_TOKEN_SIZE
 add rbx,[r12+NEBOC_PARSE_TOKENS_OFFSET]
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp rax,n_mutable_len
 jne .no
 mov rsi,[r12+neboc_literais_numericos_bases_e_representacao_PARSE_SOURCE_OFFSET]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel n_mutable]
 mov ecx,n_mutable_len
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
