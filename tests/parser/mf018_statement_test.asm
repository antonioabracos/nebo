; MF018 native statements/if tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/statements/statements.inc"
extern neboc_ast_builder_init
extern neboc_ast_builder_node
extern neboc_statement_parse
extern neboc_statement_parse_block
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,1,%2,%3,%4
%endmacro

section .data
align 8
case7_tokens:
 TOK NEBOC_TOKEN_LBRACE,0,1,0
 TOK NEBOC_TOKEN_KW_IF,2,4,0
 TOK NEBOC_TOKEN_LPAREN,5,6,0
 TOK NEBOC_TOKEN_KW_TRUE,6,10,0
 TOK NEBOC_TOKEN_RPAREN,10,11,0
 TOK NEBOC_TOKEN_LBRACE,12,13,0
 TOK NEBOC_TOKEN_INTEGER,14,15,1
 TOK NEBOC_TOKEN_DOT,15,16,0
 TOK NEBOC_TOKEN_IDENTIFIER,16,17,0
 TOK NEBOC_TOKEN_SEMICOLON,17,18,0
 TOK NEBOC_TOKEN_RBRACE,19,20,0
 TOK NEBOC_TOKEN_KW_ELSE,21,25,0
 TOK NEBOC_TOKEN_LBRACE,26,27,0
 TOK NEBOC_TOKEN_INTEGER,28,29,2
 TOK NEBOC_TOKEN_DOT,29,30,0
 TOK NEBOC_TOKEN_KW_RETURN,30,36,0
 TOK NEBOC_TOKEN_SEMICOLON,36,37,0
 TOK NEBOC_TOKEN_RBRACE,38,39,0
 TOK NEBOC_TOKEN_RBRACE,40,41,0
 TOK NEBOC_TOKEN_EOF,41,41,0
case7_count equ ($-case7_tokens)/NEBOC_TOKEN_SIZE

case8_tokens:
 TOK NEBOC_TOKEN_LBRACE,0,1,0
 TOK NEBOC_TOKEN_KW_IF,2,4,0
 TOK NEBOC_TOKEN_LPAREN,5,6,0
 TOK NEBOC_TOKEN_KW_TRUE,6,10,0
 TOK NEBOC_TOKEN_RPAREN,10,11,0
 TOK NEBOC_TOKEN_LBRACE,12,13,0
 TOK NEBOC_TOKEN_RBRACE,13,14,0
 TOK NEBOC_TOKEN_KW_ELSE,15,19,0
 TOK NEBOC_TOKEN_KW_IF,20,22,0
 TOK NEBOC_TOKEN_LPAREN,23,24,0
 TOK NEBOC_TOKEN_KW_FALSE,24,29,0
 TOK NEBOC_TOKEN_RPAREN,29,30,0
 TOK NEBOC_TOKEN_LBRACE,31,32,0
 TOK NEBOC_TOKEN_RBRACE,32,33,0
 TOK NEBOC_TOKEN_KW_ELSE,34,38,0
 TOK NEBOC_TOKEN_LBRACE,39,40,0
 TOK NEBOC_TOKEN_RBRACE,40,41,0
 TOK NEBOC_TOKEN_RBRACE,42,43,0
 TOK NEBOC_TOKEN_EOF,43,43,0
case8_count equ ($-case8_tokens)/NEBOC_TOKEN_SIZE

case12_tokens:
 TOK NEBOC_TOKEN_KW_WHILE,0,5,0
 TOK NEBOC_TOKEN_LPAREN,6,7,0
 TOK NEBOC_TOKEN_KW_TRUE,7,11,0
 TOK NEBOC_TOKEN_RPAREN,11,12,0
 TOK NEBOC_TOKEN_LBRACE,13,14,0
 TOK NEBOC_TOKEN_RBRACE,14,15,0
 TOK NEBOC_TOKEN_EOF,15,15,0
case12_count equ ($-case12_tokens)/NEBOC_TOKEN_SIZE

case13_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,8,0
 TOK NEBOC_TOKEN_DOT,8,9,0
 TOK NEBOC_TOKEN_KW_IF,9,11,0
 TOK NEBOC_TOKEN_LPAREN,11,12,0
 TOK NEBOC_TOKEN_KW_TRUE,12,16,0
 TOK NEBOC_TOKEN_RPAREN,16,17,0
 TOK NEBOC_TOKEN_LBRACE,18,19,0
 TOK NEBOC_TOKEN_RBRACE,19,20,0
 TOK NEBOC_TOKEN_SEMICOLON,20,21,0
 TOK NEBOC_TOKEN_EOF,21,21,0
case13_count equ ($-case13_tokens)/NEBOC_TOKEN_SIZE

case14_tokens:
 TOK NEBOC_TOKEN_KW_WHILE,0,5,0
 TOK NEBOC_TOKEN_LPAREN,6,7,0
 TOK NEBOC_TOKEN_KW_TRUE,7,11,0
 TOK NEBOC_TOKEN_RPAREN,11,12,0
 TOK NEBOC_TOKEN_LBRACE,13,14,0
 TOK NEBOC_TOKEN_RBRACE,14,15,0
 TOK NEBOC_TOKEN_EOF,15,15,0
case14_count equ ($-case14_tokens)/NEBOC_TOKEN_SIZE

case15_tokens:
 TOK NEBOC_TOKEN_KW_WHILE,0,5,0
 TOK NEBOC_TOKEN_KW_TRUE,6,10,0
 TOK NEBOC_TOKEN_LBRACE,11,12,0
 TOK NEBOC_TOKEN_RBRACE,12,13,0
 TOK NEBOC_TOKEN_EOF,13,13,0
case15_count equ ($-case15_tokens)/NEBOC_TOKEN_SIZE

case16_tokens:
 TOK NEBOC_TOKEN_KW_LOOP,0,4,0
 TOK NEBOC_TOKEN_LBRACE,5,6,0
 TOK NEBOC_TOKEN_RBRACE,6,7,0
 TOK NEBOC_TOKEN_EOF,7,7,0
case16_count equ ($-case16_tokens)/NEBOC_TOKEN_SIZE

case17_source: db 'for item in range {}'
case18_source: db 'for (item in range) {}'
case17_tokens:
 TOK NEBOC_TOKEN_KW_FOR,0,3,0
 TOK NEBOC_TOKEN_IDENTIFIER,4,8,0
 TOK NEBOC_TOKEN_IDENTIFIER,9,11,0
 TOK NEBOC_TOKEN_IDENTIFIER,12,17,0
 TOK NEBOC_TOKEN_LBRACE,18,19,0
 TOK NEBOC_TOKEN_RBRACE,19,20,0
 TOK NEBOC_TOKEN_EOF,20,20,0
case17_count equ ($-case17_tokens)/NEBOC_TOKEN_SIZE
case18_tokens:
 TOK NEBOC_TOKEN_KW_FOR,0,3,0
 TOK NEBOC_TOKEN_LPAREN,4,5,0
 TOK NEBOC_TOKEN_IDENTIFIER,5,9,0
 TOK NEBOC_TOKEN_IDENTIFIER,10,12,0
 TOK NEBOC_TOKEN_IDENTIFIER,13,18,0
 TOK NEBOC_TOKEN_RPAREN,18,19,0
 TOK NEBOC_TOKEN_LBRACE,20,21,0
 TOK NEBOC_TOKEN_RBRACE,21,22,0
 TOK NEBOC_TOKEN_EOF,22,22,0
case18_count equ ($-case18_tokens)/NEBOC_TOKEN_SIZE
case21_source: db 'while (true {}'
case21_tokens:
 TOK NEBOC_TOKEN_KW_WHILE,0,5,0
 TOK NEBOC_TOKEN_LPAREN,6,7,0
 TOK NEBOC_TOKEN_KW_TRUE,7,11,0
 TOK NEBOC_TOKEN_LBRACE,12,13,0
 TOK NEBOC_TOKEN_RBRACE,13,14,0
 TOK NEBOC_TOKEN_EOF,14,14,0
case21_count equ ($-case21_tokens)/NEBOC_TOKEN_SIZE

section .bss align=16
builder: resb NEBOC_AST_BUILDER_SIZE
stmt_request: resb NEBOC_STMT_REQUEST_SIZE
expr_request: resb NEBOC_EXPR_REQUEST_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*256
node_out: resq 1
source_ptr: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp al,'7'
 je test_case7
 cmp al,'8'
 je test_case8
 cmp al,'1'
 je .dispatch_1x
 cmp al,'2'
 je .dispatch_2x
 jmp test_usage
.dispatch_1x:
 movzx eax,byte [rdx+1]
 cmp al,'2'
 je test_case12
 cmp al,'3'
 je test_case13
 cmp al,'4'
 je test_case14
 cmp al,'5'
 je test_case15
 cmp al,'6'
 je test_case16
 cmp al,'7'
 je test_case17
 cmp al,'8'
 je test_case18
 cmp al,'9'
 je test_case19
.dispatch_2x:
 movzx eax,byte [rdx+1]
 cmp al,'0'
 je test_case20
 cmp al,'1'
 je test_case21
 cmp al,'2'
 je test_case22
 jmp test_usage

test_case7:
 lea rdi,[rel case7_tokens]
 mov esi,case7_count
 call parse_block_case
 test eax,eax
 jnz test_fail
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BOOL_LITERAL
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rdi,rdi
 jnz test_fail
 ; Recover else block through IF child chain:
 ; outer block -> if -> condition -> then block -> else block.
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case8:
 lea rdi,[rel case8_tokens]
 mov esi,case8_count
 call parse_block_case
 test eax,eax
 jnz test_fail
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne test_fail
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_ELSE_IF
 jz test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case12:
 lea rdi,[rel case12_tokens]
 mov esi,case12_count
 call parse_statement_case
 test eax,eax
 jne test_fail
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case13:
 lea rdi,[rel case13_tokens]
 mov esi,case13_count
 call parse_statement_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_INVALID_CONTROL_CHAIN
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case14:
 lea rdi,[rel case14_tokens]
 mov esi,case14_count
 call parse_statement_preview_case
 test eax,eax
 jnz test_fail
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case15:
 lea rdi,[rel case15_tokens]
 mov esi,case15_count
 call parse_statement_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case16:
 lea rdi,[rel case16_tokens]
 mov esi,case16_count
 call parse_statement_preview_case
 test eax,eax
 jnz test_fail
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case17:
 lea rax,[rel case17_source]
 mov [rel source_ptr],rax
 lea rdi,[rel case17_tokens]
 mov esi,case17_count
 call parse_statement_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case18:
 lea rax,[rel case18_source]
 mov [rel source_ptr],rax
 lea rdi,[rel case18_tokens]
 mov esi,case18_count
 call parse_statement_preview_case
 test eax,eax
 jnz test_fail
 call assert_range_for
 xor edi,edi
 jmp test_exit

test_case19:
 lea rax,[rel case18_source]
 mov [rel source_ptr],rax
 lea rdi,[rel case18_tokens]
 mov esi,case18_count
 call parse_statement_case
 test eax,eax
 jnz test_fail
 call assert_range_for
 xor edi,edi
 jmp test_exit

test_case20:
 lea rdi,[rel case15_tokens]
 mov esi,case15_count
 call parse_statement_preview_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT0_START_OFFSET],6
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT0_END_OFFSET],6
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT1_START_OFFSET],11
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT1_KIND_OFFSET],NEBOC_STMT_FIXIT_INSERT_RPAREN
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case21:
 lea rax,[rel case21_source]
 mov [rel source_ptr],rax
 lea rdi,[rel case21_tokens]
 mov esi,case21_count
 call parse_statement_preview_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_RPAREN_REQUIRED
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT0_START_OFFSET],12
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT0_KIND_OFFSET],NEBOC_STMT_FIXIT_INSERT_RPAREN
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case22:
 lea rax,[rel case17_source]
 mov [rel source_ptr],rax
 lea rdi,[rel case17_tokens]
 mov esi,case17_count
 call parse_statement_preview_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT0_START_OFFSET],4
 jne test_fail
 cmp qword [rel stmt_request+NEBOC_STMT_FIXIT1_START_OFFSET],18
 jne test_fail
 xor edi,edi
 jmp test_exit

assert_range_for:
 mov rdi,[rel stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 call node
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RANGE_FOR_STMT
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne test_fail
 ret

parse_block_case:
 mov edx,1
 jmp parse_common
parse_statement_case:
 xor edx,edx
 jmp parse_common
parse_statement_preview_case:
 xor edx,edx
parse_common:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 lea r15,[rel nodes]
 mov rdi,r15
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*256)/8
 rep stosq
 lea rdi,[rel builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 lea rdi,[rel stmt_request]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel expr_request]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel builder]
 mov rsi,r15
 mov edx,256
 call neboc_ast_builder_init
 test eax,eax
 jnz parse_done
 lea rax,[rel stmt_request]
 mov [rax+NEBOC_STMT_TOKENS_OFFSET],r12
 mov [rax+NEBOC_STMT_TOKEN_COUNT_OFFSET],r13
 mov qword [rax+NEBOC_STMT_SOURCE_ID_OFFSET],1
 lea rcx,[rel builder]
 mov [rax+NEBOC_STMT_BUILDER_OFFSET],rcx
 mov qword [rax+NEBOC_STMT_MAX_NESTING_OFFSET],64
 mov rcx,[rel source_ptr]
 mov [rax+NEBOC_STMT_SOURCE_DATA_OFFSET],rcx
 lea rcx,[rel expr_request]
 mov [rax+NEBOC_STMT_EXPR_REQUEST_OFFSET],rcx
 mov rdi,rax
 cmp r14,1
 jne .one
 call neboc_statement_parse_block
 jmp parse_done
.one:
 call neboc_statement_parse
parse_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

node:
 mov qword [rel node_out],0
 mov rsi,rdi
 lea rdi,[rel builder]
 lea rdx,[rel node_out]
 call neboc_ast_builder_node
 test eax,eax
 jnz test_fail
 mov rax,[rel node_out]
 ret

test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,99
test_exit:
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
