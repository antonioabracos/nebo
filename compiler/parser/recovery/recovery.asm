; Nebo Assembly — MF019 bounded parser recovery and ErrorNode
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/statements/statements.inc"
%include "compiler/parser/recovery/recovery.inc"
%include "compiler/diagnostics/catalog.inc"

extern neboc_ast_builder_append
extern neboc_ast_builder_node
extern neboc_statement_parse

%macro REC_TOKEN_PTR 3
 mov %1,%2
 imul %1,NEBOC_TOKEN_SIZE
 add %1,[%3+NEBOC_RECOVERY_TOKENS_OFFSET]
%endmacro

section .text

; recovery_check_limits(request*)
NEBOC_ABI_FUNCTION neboc_parser_recovery_check_limits
 test rdi,rdi
 jz .invalid
 mov r8,[rdi+NEBOC_RECOVERY_TOKENS_OFFSET]
 mov r9,[rdi+NEBOC_RECOVERY_BUILDER_OFFSET]
 mov r10,[rdi+NEBOC_RECOVERY_STATEMENT_REQUEST_OFFSET]
 mov r11,[rdi+NEBOC_RECOVERY_EXPRESSION_REQUEST_OFFSET]
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 test r10,r10
 jz .invalid
 test r11,r11
 jz .invalid
 cmp qword [rdi+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET],0
 je .invalid
 cmp qword [rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],0
 jne .diag_ready
 mov qword [rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],NEBOC_RECOVERY_DEFAULT_MAX_DIAGNOSTICS
.diag_ready:
 cmp qword [rdi+NEBOC_RECOVERY_MAX_TOKENS_OFFSET],0
 jne .tokens_ready
 mov qword [rdi+NEBOC_RECOVERY_MAX_TOKENS_OFFSET],NEBOC_RECOVERY_DEFAULT_MAX_TOKENS
.tokens_ready:
 cmp qword [rdi+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET],0
 jne .ast_ready
 mov qword [rdi+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET],NEBOC_RECOVERY_DEFAULT_MAX_AST_NODES
.ast_ready:
 cmp qword [rdi+NEBOC_RECOVERY_MAX_NESTING_OFFSET],0
 jne .nesting_ready
 mov qword [rdi+NEBOC_RECOVERY_MAX_NESTING_OFFSET],NEBOC_RECOVERY_DEFAULT_MAX_NESTING
.nesting_ready:
 mov rax,[rdi+NEBOC_RECOVERY_INDEX_OFFSET]
 cmp rax,[rdi+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET]
 ja .invalid
 mov rax,[rdi+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RECOVERY_MAX_TOKENS_OFFSET]
 ja .limit
 mov rax,[r9+NEBOC_AST_BUILDER_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET]
 jae .limit
 xor eax,eax
 ret
.limit:
 mov qword [rdi+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 mov rax,[rdi+NEBOC_RECOVERY_INDEX_OFFSET]
 mov [rdi+NEBOC_RECOVERY_LAST_DIAG_TOKEN_OFFSET],rax
 mov qword [rdi+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_LIMIT_EXCEEDED
 mov rax,[rdi+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET]
 jae .limit_return
 inc qword [rdi+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET]
.limit_return:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; recovery_record_diagnostic(request*, code, token_index)
NEBOC_ABI_FUNCTION neboc_parser_recovery_record_diagnostic
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],0
 jne .have_limit
 mov qword [rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],NEBOC_RECOVERY_DEFAULT_MAX_DIAGNOSTICS
.have_limit:
 mov rax,[rdi+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET]
 jae .limit
 inc rax
 mov [rdi+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET],rax
 mov [rdi+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],rsi
 mov [rdi+NEBOC_RECOVERY_LAST_DIAG_TOKEN_OFFSET],rdx
 mov qword [rdi+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_INVALID_SOURCE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.limit:
 mov qword [rdi+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 mov [rdi+NEBOC_RECOVERY_LAST_DIAG_TOKEN_OFFSET],rdx
 mov qword [rdi+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; recovery_synchronize(request*) — synchronizes at ';', '}' or EOF.
; It always advances when called on a token and never moves backwards.
NEBOC_ABI_FUNCTION neboc_parser_recovery_synchronize
 test rdi,rdi
 jz .invalid
 mov r8,[rdi+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET]
 mov r9,[rdi+NEBOC_RECOVERY_TOKENS_OFFSET]
 test r9,r9
 jz .invalid
 mov rax,[rdi+NEBOC_RECOVERY_INDEX_OFFSET]
 mov r10,rax
.loop:
 cmp rax,r8
 jae .store
 mov r11,rax
 imul r11,NEBOC_TOKEN_SIZE
 add r11,r9
 mov rcx,[r11+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_SEMICOLON
 je .consume
 cmp rcx,NEBOC_TOKEN_RBRACE
 je .boundary
 cmp rcx,NEBOC_TOKEN_EOF
 je .boundary
 inc rax
 jmp .loop
.consume:
 inc rax
 jmp .store
.boundary:
 cmp rax,r10
 jne .store
 inc rax
.store:
 cmp rax,r8
 jbe .write
 mov rax,r8
.write:
 mov [rdi+NEBOC_RECOVERY_INDEX_OFFSET],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; recovery_append_error(request*, start_index, diagnostic_code, diagnostic_token)
NEBOC_ABI_FUNCTION neboc_parser_recovery_append_error
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov [rsp],rsi
 mov [rsp+8],rdx
 mov [rsp+16],rcx
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET]
 mov r14,[r12+NEBOC_RECOVERY_TOKENS_OFFSET]
 mov r15,[r12+NEBOC_RECOVERY_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 mov rbx,[rsp]
 cmp rbx,r13
 jb .start_ready
 mov rbx,r13
 dec rbx
.start_ready:
 mov r10,rbx
 imul r10,NEBOC_TOKEN_SIZE
 add r10,r14
 mov rax,[r10+NEBOC_TOKEN_START_OFFSET]
 mov [rsp+24],rax
 mov rax,[r12+NEBOC_RECOVERY_INDEX_OFFSET]
 cmp rax,rbx
 jbe .end_start
 dec rax
 jmp .end_clamp
.end_start:
 mov rax,rbx
.end_clamp:
 cmp rax,r13
 jb .end_ready
 mov rax,r13
 dec rax
.end_ready:
 mov r10,rax
 imul r10,NEBOC_TOKEN_SIZE
 add r10,r14
 mov rax,[r10+NEBOC_TOKEN_END_OFFSET]
 mov [rsp+32],rax
 mov rdi,r15
 mov esi,NEBOC_AST_ERROR_NODE
 mov rdx,[r12+NEBOC_RECOVERY_SOURCE_ID_OFFSET]
 mov rcx,[rsp+24]
 mov r8,[rsp+32]
 lea r9,[rsp+40]
 call neboc_ast_builder_append
 test eax,eax
 jnz .done
 mov rdi,r15
 mov rsi,[rsp+40]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov r10,[rsp+48]
 or qword [r10+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_RECOVERED
 mov rax,[rsp+8]
 mov [r10+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 mov rax,[rsp+16]
 mov [r10+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rax
 mov rax,[rsp+40]
 mov [r12+NEBOC_RECOVERY_RESULT_NODE_OFFSET],rax
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; recovery_parse_statement(request*)
NEBOC_ABI_FUNCTION neboc_parser_recovery_parse_statement
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,160
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_RECOVERY_RESULT_NODE_OFFSET],0
 mov qword [r12+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],0
 mov qword [r12+NEBOC_RECOVERY_LAST_DIAG_TOKEN_OFFSET],0
 mov rdi,r12
 call neboc_parser_recovery_check_limits
 test eax,eax
 jnz .done
 mov r13,[r12+NEBOC_RECOVERY_BUILDER_OFFSET]
 mov r14,[r12+NEBOC_RECOVERY_STATEMENT_REQUEST_OFFSET]
 mov r15,[r12+NEBOC_RECOVERY_EXPRESSION_REQUEST_OFFSET]
 mov rax,[r12+NEBOC_RECOVERY_INDEX_OFFSET]
 mov [rsp],rax
 mov rax,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rax,[r13+NEBOC_AST_BUILDER_CAPACITY_OFFSET]
 mov [rsp+16],rax
 mov rcx,[r12+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET]
 cmp rcx,rax
 cmova rcx,rax
 mov [r13+NEBOC_AST_BUILDER_CAPACITY_OFFSET],rcx
 mov rdi,r14
 xor eax,eax
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 rep stosq
 mov rax,[r12+NEBOC_RECOVERY_TOKENS_OFFSET]
 mov [r14+NEBOC_STMT_TOKENS_OFFSET],rax
 mov rax,[r12+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET]
 mov [r14+NEBOC_STMT_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_RECOVERY_SOURCE_ID_OFFSET]
 mov [r14+NEBOC_STMT_SOURCE_ID_OFFSET],rax
 mov [r14+NEBOC_STMT_BUILDER_OFFSET],r13
 mov rax,[r12+NEBOC_RECOVERY_INDEX_OFFSET]
 mov [r14+NEBOC_STMT_INDEX_OFFSET],rax
 mov rax,[r12+NEBOC_RECOVERY_MAX_NESTING_OFFSET]
 mov [r14+NEBOC_STMT_MAX_NESTING_OFFSET],rax
 mov [r14+NEBOC_STMT_EXPR_REQUEST_OFFSET],r15
 mov rdi,r14
 call neboc_statement_parse
 mov [rsp+24],rax
 mov rax,[r14+NEBOC_STMT_INDEX_OFFSET]
 mov [rsp+32],rax
 mov rax,[r14+NEBOC_STMT_RESULT_NODE_OFFSET]
 mov [rsp+40],rax
 mov rax,[r14+NEBOC_STMT_ERROR_CODE_OFFSET]
 mov [rsp+48],rax
 mov rax,[r14+NEBOC_STMT_ERROR_TOKEN_OFFSET]
 mov [rsp+56],rax
 mov rax,[rsp+16]
 mov [r13+NEBOC_AST_BUILDER_CAPACITY_OFFSET],rax
 cmp qword [rsp+24],NEBOC_STATUS_OK
 jne .recover
 mov rax,[rsp+32]
 mov [r12+NEBOC_RECOVERY_INDEX_OFFSET],rax
 mov rax,[rsp+40]
 mov [r12+NEBOC_RECOVERY_RESULT_NODE_OFFSET],rax
 mov qword [r12+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_OK
 xor eax,eax
 jmp .done
.recover:
 mov rax,[rsp+8]
 mov [r13+NEBOC_AST_BUILDER_COUNT_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_RECOVERY_INDEX_OFFSET],rax
 mov rbx,[rsp+48]
 cmp qword [rsp+24],NEBOC_STATUS_LIMIT_EXCEEDED
 je .limit_code
 cmp rbx,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 jne .check_supported_diagnostics
 ; EXPECTED_TOKEN after a completed expression means a missing semicolon.
 ; Without a result node or cursor progress, it means an unexpected token.
 cmp qword [rsp+40],0
 je .unexpected_token
 mov rax,[rsp+32]
 cmp rax,[rsp]
 jbe .unexpected_token
 mov ebx,NEBOC_PARSE_DIAG_MISSING_SEMICOLON
 jmp .diag_ready
.check_supported_diagnostics:
 cmp rbx,NEBOC_PARSE_DIAG_UNSUPPORTED_CONTROL
 je .diag_ready
 cmp rbx,NEBOC_PARSE_DIAG_INVALID_CONTROL_CHAIN
 je .diag_ready
 cmp rbx,NEBOC_PARSE_DIAG_NESTING_LIMIT
 je .diag_ready
 cmp rbx,NEBOC_PARSE_DIAG_NONASSOCIATIVE_CHAIN
 je .diag_ready
.unexpected_token:
 mov ebx,NEBOC_PARSE_DIAG_UNEXPECTED_TOKEN
 jmp .diag_ready
.limit_code:
 test rbx,rbx
 jnz .diag_ready
 mov ebx,NEBOC_DIAG_LIMIT_EXCEEDED
.diag_ready:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,[rsp+56]
 call neboc_parser_recovery_record_diagnostic
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .done
 mov rdi,r12
 call neboc_parser_recovery_synchronize
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp]
 mov rdx,rbx
 mov rcx,[rsp+56]
 call neboc_parser_recovery_append_error
 test eax,eax
 jnz .append_failed
 cmp qword [rsp+24],NEBOC_STATUS_LIMIT_EXCEEDED
 je .return_limit
 mov qword [r12+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_INVALID_SOURCE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.return_limit:
 mov qword [r12+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.append_failed:
 mov qword [r12+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 mov qword [r12+NEBOC_RECOVERY_LAST_STATUS_OFFSET],NEBOC_STATUS_LIMIT_EXCEEDED
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,160
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
