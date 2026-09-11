; Nebo Assembly — MF019 recovery, ErrorNode and parser limits
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/statements/statements.inc"
%include "compiler/parser/recovery/recovery.inc"
%include "compiler/diagnostics/catalog.inc"
extern neboc_ast_builder_init
extern neboc_ast_builder_append
extern neboc_ast_builder_node
extern neboc_parser_recovery_parse_statement
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,1,%2,%3,%4
%endmacro

section .data
align 8
case9_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1,1
 TOK NEBOC_TOKEN_EOF,1,1,0
case9_count equ ($-case9_tokens)/NEBOC_TOKEN_SIZE

case14_tokens:
 TOK NEBOC_TOKEN_KW_IF,0,2,0
 TOK NEBOC_TOKEN_LPAREN,2,3,0
 TOK NEBOC_TOKEN_KW_TRUE,3,7,0
 TOK NEBOC_TOKEN_RPAREN,7,8,0
 TOK NEBOC_TOKEN_LBRACE,8,9,0
 TOK NEBOC_TOKEN_KW_IF,9,11,0
 TOK NEBOC_TOKEN_LPAREN,11,12,0
 TOK NEBOC_TOKEN_KW_TRUE,12,16,0
 TOK NEBOC_TOKEN_RPAREN,16,17,0
 TOK NEBOC_TOKEN_LBRACE,17,18,0
 TOK NEBOC_TOKEN_KW_IF,18,20,0
 TOK NEBOC_TOKEN_LPAREN,20,21,0
 TOK NEBOC_TOKEN_KW_TRUE,21,25,0
 TOK NEBOC_TOKEN_RPAREN,25,26,0
 TOK NEBOC_TOKEN_LBRACE,26,27,0
 TOK NEBOC_TOKEN_RBRACE,27,28,0
 TOK NEBOC_TOKEN_RBRACE,28,29,0
 TOK NEBOC_TOKEN_RBRACE,29,30,0
 TOK NEBOC_TOKEN_EOF,30,30,0
case14_count equ ($-case14_tokens)/NEBOC_TOKEN_SIZE

case16_tokens:
 TOK NEBOC_TOKEN_RPAREN,0,1,0
 TOK NEBOC_TOKEN_SEMICOLON,1,2,0
 TOK NEBOC_TOKEN_EOF,2,2,0
case16_count equ ($-case16_tokens)/NEBOC_TOKEN_SIZE

case18_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1,1
 TOK NEBOC_TOKEN_SEMICOLON,1,2,0
 TOK NEBOC_TOKEN_EOF,2,2,0
case18_count equ ($-case18_tokens)/NEBOC_TOKEN_SIZE

section .bss align=16
builder: resb NEBOC_AST_BUILDER_SIZE
recovery: resb NEBOC_RECOVERY_REQUEST_SIZE
statement: resb NEBOC_STMT_REQUEST_SIZE
expression: resb NEBOC_EXPR_REQUEST_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*256
node_out: resq 1
append_out: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp al,'9'
 je test_case9
 cmp al,'1'
 jne test_usage
 movzx eax,byte [rdx+1]
 cmp al,'4'
 je test_case14
 cmp al,'6'
 je test_case16
 cmp al,'7'
 je test_case17
 cmp al,'8'
 je test_case18
 cmp al,'9'
 je test_case19
 jmp test_usage

test_case9:
 lea rdi,[rel case9_tokens]
 mov esi,case9_count
 mov edx,64
 mov ecx,8
 mov r8d,1024
 mov r9d,256
 call init_case
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_PARSE_DIAG_MISSING_SEMICOLON
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_INDEX_OFFSET],case9_count
 jne test_fail
 cmp qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 jne test_fail
 call check_error_node
 test eax,eax
 jnz test_fail
 xor edi,edi
 jmp test_exit

test_case14:
 lea rdi,[rel case14_tokens]
 mov esi,case14_count
 mov edx,2
 mov ecx,8
 mov r8d,1024
 mov r9d,256
 call init_case
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_INDEX_OFFSET],0
 je test_fail
 cmp qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 jne test_fail
 call check_error_node
 test eax,eax
 jnz test_fail
 xor edi,edi
 jmp test_exit

test_case16:
 lea rdi,[rel case16_tokens]
 mov esi,case16_count
 mov edx,64
 mov ecx,8
 mov r8d,1024
 mov r9d,256
 call init_case
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_PARSE_DIAG_UNEXPECTED_TOKEN
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_INDEX_OFFSET],2
 jne test_fail
 call check_error_node
 test eax,eax
 jnz test_fail
 xor edi,edi
 jmp test_exit

test_case17:
 lea rdi,[rel case9_tokens]
 mov esi,case9_count
 mov edx,64
 mov ecx,1
 mov r8d,1024
 mov r9d,256
 call init_case
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 mov qword [rel recovery+NEBOC_RECOVERY_INDEX_OFFSET],0
 mov qword [rel recovery+NEBOC_RECOVERY_RESULT_NODE_OFFSET],0
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case18:
 lea rdi,[rel case18_tokens]
 mov esi,case18_count
 mov edx,64
 mov ecx,8
 mov r8d,2
 mov r9d,256
 call init_case
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_DIAGNOSTICS_COUNT_OFFSET],1
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case19:
 lea rdi,[rel case18_tokens]
 mov esi,case18_count
 mov edx,64
 mov ecx,8
 mov r8d,1024
 mov r9d,1
 call init_case
 mov qword [rel append_out],0
 lea rdi,[rel builder]
 mov esi,NEBOC_AST_INTEGER_LITERAL
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 test eax,eax
 jnz test_fail
 lea rdi,[rel recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET],NEBOC_DIAG_LIMIT_EXCEEDED
 jne test_fail
 cmp qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 jne test_fail
 xor edi,edi
 jmp test_exit

; init_case(tokens,count,max_nesting,max_diagnostics,max_tokens,max_ast_nodes)
init_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 mov [rsp],r9
 lea rdi,[rel nodes]
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*256)/8
 rep stosq
 lea rdi,[rel builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 lea rdi,[rel recovery]
 mov ecx,NEBOC_RECOVERY_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel statement]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel expression]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel builder]
 lea rsi,[rel nodes]
 mov edx,256
 call neboc_ast_builder_init
 test eax,eax
 jnz init_done
 lea rax,[rel recovery]
 mov [rax+NEBOC_RECOVERY_TOKENS_OFFSET],r12
 mov [rax+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET],r13
 mov qword [rax+NEBOC_RECOVERY_SOURCE_ID_OFFSET],1
 lea rcx,[rel builder]
 mov [rax+NEBOC_RECOVERY_BUILDER_OFFSET],rcx
 lea rcx,[rel statement]
 mov [rax+NEBOC_RECOVERY_STATEMENT_REQUEST_OFFSET],rcx
 lea rcx,[rel expression]
 mov [rax+NEBOC_RECOVERY_EXPRESSION_REQUEST_OFFSET],rcx
 mov [rax+NEBOC_RECOVERY_MAX_NESTING_OFFSET],r14
 mov [rax+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],r15
 mov [rax+NEBOC_RECOVERY_MAX_TOKENS_OFFSET],rbx
 mov rcx,[rsp]
 mov [rax+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET],rcx
 xor eax,eax
init_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

check_error_node:
 mov qword [rel node_out],0
 lea rdi,[rel builder]
 mov rsi,[rel recovery+NEBOC_RECOVERY_RESULT_NODE_OFFSET]
 lea rdx,[rel node_out]
 call neboc_ast_builder_node
 test eax,eax
 jnz .done
 mov rax,[rel node_out]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ERROR_NODE
 jne .bad
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_RECOVERED
 jz .bad
 mov rcx,[rel recovery+NEBOC_RECOVERY_LAST_DIAG_CODE_OFFSET]
 cmp [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rcx
 jne .bad
 xor eax,eax
 ret
.bad:
 mov eax,1
.done:
 ret

test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,99
test_exit:
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
