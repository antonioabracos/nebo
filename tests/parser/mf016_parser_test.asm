; MF016 native parser/AST contract test
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
extern neboc_ast_builder_init
extern neboc_parser_parse
extern neboc_host_process_exit

%macro TOK 3
 dq %1,0,1,%2,%3,0
%endmacro

section .data
align 8
case1_tokens:
 TOK NEBOC_TOKEN_KW_START,0,5
 TOK NEBOC_TOKEN_LPAREN,5,6
 TOK NEBOC_TOKEN_RPAREN,6,7
 TOK NEBOC_TOKEN_LBRACE,8,9
 TOK NEBOC_TOKEN_RBRACE,9,10
 TOK NEBOC_TOKEN_EOF,10,10
case1_count equ ($-case1_tokens)/NEBOC_TOKEN_SIZE

case2_tokens:
 TOK NEBOC_TOKEN_LPAREN,0,1
 TOK NEBOC_TOKEN_IDENTIFIER,1,4
 TOK NEBOC_TOKEN_DOT,4,5
 TOK NEBOC_TOKEN_IDENTIFIER,5,6
 TOK NEBOC_TOKEN_RPAREN,6,7
 TOK NEBOC_TOKEN_IDENTIFIER,7,11
 TOK NEBOC_TOKEN_LPAREN,11,12
 TOK NEBOC_TOKEN_IDENTIFIER,12,15
 TOK NEBOC_TOKEN_DOT,15,16
 TOK NEBOC_TOKEN_IDENTIFIER,16,17
 TOK NEBOC_TOKEN_RPAREN,17,18
 TOK NEBOC_TOKEN_LBRACE,19,20
 TOK NEBOC_TOKEN_RBRACE,20,21
 TOK NEBOC_TOKEN_KW_START,22,27
 TOK NEBOC_TOKEN_LPAREN,27,28
 TOK NEBOC_TOKEN_RPAREN,28,29
 TOK NEBOC_TOKEN_LBRACE,30,31
 TOK NEBOC_TOKEN_RBRACE,31,32
 TOK NEBOC_TOKEN_EOF,32,32
case2_count equ ($-case2_tokens)/NEBOC_TOKEN_SIZE

case3_line_tokens:
 TOK NEBOC_TOKEN_KW_START,0,5
 TOK NEBOC_TOKEN_LPAREN,5,6
 TOK NEBOC_TOKEN_RPAREN,6,7
 TOK NEBOC_TOKEN_LBRACE,8,9
 TOK NEBOC_TOKEN_TEXT,9,15
 TOK NEBOC_TOKEN_DOT,15,16
 TOK NEBOC_TOKEN_IDENTIFIER,16,23
 TOK NEBOC_TOKEN_LPAREN,23,24
 TOK NEBOC_TOKEN_RPAREN,24,25
 TOK NEBOC_TOKEN_DOT,25,26
 TOK NEBOC_TOKEN_IDENTIFIER,26,30
 TOK NEBOC_TOKEN_LPAREN,30,31
 TOK NEBOC_TOKEN_RPAREN,31,32
 TOK NEBOC_TOKEN_DOT,32,33
 TOK NEBOC_TOKEN_IDENTIFIER,33,37
 TOK NEBOC_TOKEN_SEMICOLON,37,38
 TOK NEBOC_TOKEN_RBRACE,38,39
 TOK NEBOC_TOKEN_EOF,39,39
case3_line_count equ ($-case3_line_tokens)/NEBOC_TOKEN_SIZE

case3_multi_tokens:
 TOK NEBOC_TOKEN_KW_START,0,5
 TOK NEBOC_TOKEN_LPAREN,5,6
 TOK NEBOC_TOKEN_RPAREN,6,7
 TOK NEBOC_TOKEN_LBRACE,8,9
 TOK NEBOC_TOKEN_TEXT,14,20
 TOK NEBOC_TOKEN_DOT,29,30
 TOK NEBOC_TOKEN_IDENTIFIER,30,37
 TOK NEBOC_TOKEN_LPAREN,37,38
 TOK NEBOC_TOKEN_RPAREN,38,39
 TOK NEBOC_TOKEN_DOT,48,49
 TOK NEBOC_TOKEN_IDENTIFIER,49,53
 TOK NEBOC_TOKEN_LPAREN,53,54
 TOK NEBOC_TOKEN_RPAREN,54,55
 TOK NEBOC_TOKEN_DOT,64,65
 TOK NEBOC_TOKEN_IDENTIFIER,65,69
 TOK NEBOC_TOKEN_SEMICOLON,69,70
 TOK NEBOC_TOKEN_RBRACE,71,72
 TOK NEBOC_TOKEN_EOF,72,72
case3_multi_count equ ($-case3_multi_tokens)/NEBOC_TOKEN_SIZE

case10_tokens:
 TOK NEBOC_TOKEN_KW_START,0,5
 TOK NEBOC_TOKEN_LPAREN,5,6
 TOK NEBOC_TOKEN_RPAREN,6,7
 TOK NEBOC_TOKEN_LBRACE,7,8
 TOK NEBOC_TOKEN_RBRACE,8,9
 TOK NEBOC_TOKEN_KW_START,10,15
 TOK NEBOC_TOKEN_LPAREN,15,16
 TOK NEBOC_TOKEN_RPAREN,16,17
 TOK NEBOC_TOKEN_LBRACE,17,18
 TOK NEBOC_TOKEN_RBRACE,18,19
 TOK NEBOC_TOKEN_EOF,19,19
case10_count equ ($-case10_tokens)/NEBOC_TOKEN_SIZE

case11_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1
 TOK NEBOC_TOKEN_SEMICOLON,1,2
 TOK NEBOC_TOKEN_KW_START,3,8
 TOK NEBOC_TOKEN_LPAREN,8,9
 TOK NEBOC_TOKEN_RPAREN,9,10
 TOK NEBOC_TOKEN_LBRACE,10,11
 TOK NEBOC_TOKEN_RBRACE,11,12
 TOK NEBOC_TOKEN_EOF,12,12
case11_count equ ($-case11_tokens)/NEBOC_TOKEN_SIZE

section .bss align=16
builder_a: resb NEBOC_AST_BUILDER_SIZE
request_a: resb NEBOC_PARSER_SIZE
nodes_a: resb NEBOC_AST_NODE_SIZE*64
builder_b: resb NEBOC_AST_BUILDER_SIZE
request_b: resb NEBOC_PARSER_SIZE
nodes_b: resb NEBOC_AST_NODE_SIZE*64

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp al,'1'
 je test_scenario_1_or_10_or_11
 cmp al,'2'
 je test_scenario_2
 cmp al,'3'
 je test_scenario_3
 jmp test_usage

test_scenario_1_or_10_or_11:
 movzx eax,byte [rdx+1]
 test al,al
 jz test_scenario_1
 cmp al,'0'
 je test_scenario_10
 cmp al,'1'
 je test_scenario_11
 jmp test_usage

test_scenario_1:
 lea rdi,[rel case1_tokens]
 mov esi,case1_count
 lea rdx,[rel nodes_a]
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 call parse_case
 test eax,eax
 jnz test_fail
 cmp qword [rel builder_a+NEBOC_AST_BUILDER_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],2
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE*2+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne test_fail
 xor edi,edi
 jmp test_exit

test_scenario_2:
 lea rdi,[rel case2_tokens]
 mov esi,case2_count
 lea rdx,[rel nodes_a]
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 call parse_case
 test eax,eax
 jnz test_fail
 cmp qword [rel builder_a+NEBOC_AST_BUILDER_COUNT_OFFSET],7
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE*2+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE*3+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PARAMETER
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE*4+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne test_fail
 cmp qword [rel nodes_a+NEBOC_AST_NODE_SIZE*5+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne test_fail
 xor edi,edi
 jmp test_exit

test_scenario_3:
 lea rdi,[rel case3_line_tokens]
 mov esi,case3_line_count
 lea rdx,[rel nodes_a]
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 call parse_case
 test eax,eax
 jnz test_fail
 lea rdi,[rel case3_multi_tokens]
 mov esi,case3_multi_count
 lea rdx,[rel nodes_b]
 lea rcx,[rel request_b]
 lea r8,[rel builder_b]
 call parse_case
 test eax,eax
 jnz test_fail
 mov rcx,[rel builder_a+NEBOC_AST_BUILDER_COUNT_OFFSET]
 cmp rcx,[rel builder_b+NEBOC_AST_BUILDER_COUNT_OFFSET]
 jne test_fail
 lea rsi,[rel nodes_a]
 lea rdi,[rel nodes_b]
test_compare_nodes:
 test rcx,rcx
 jz test_scenario_3_ok
 ; compare semantic fields, excluding physical source offsets
 mov rax,[rsi+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_KIND_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_FLAGS_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_FLAGS_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 jne test_fail
 mov rax,[rsi+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jne test_fail
 add rsi,NEBOC_AST_NODE_SIZE
 add rdi,NEBOC_AST_NODE_SIZE
 dec rcx
 jmp test_compare_nodes
test_scenario_3_ok:
 xor edi,edi
 jmp test_exit

test_scenario_10:
 lea rdi,[rel case10_tokens]
 mov esi,case10_count
 lea rdx,[rel nodes_a]
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 call parse_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_PARSER_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_DUPLICATE_START
 jne test_fail
 xor edi,edi
 jmp test_exit

test_scenario_11:
 lea rdi,[rel case11_tokens]
 mov esi,case11_count
 lea rdx,[rel nodes_a]
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 call parse_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_PARSER_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_TOP_LEVEL_STATEMENT
 jne test_fail
 xor edi,edi
 jmp test_exit

; parse_case(tokens,count,nodes,request,builder)
parse_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 ; clear builder/request/node storage used by the scenario
 mov rdi,r14
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*64)/8
 rep stosq
 mov rdi,r15
 mov ecx,NEBOC_PARSER_SIZE/8
 rep stosq
 mov rdi,rbx
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 mov rdi,rbx
 mov rsi,r14
 mov edx,64
 call neboc_ast_builder_init
 test eax,eax
 jnz parse_case_done
 mov [r15+NEBOC_PARSER_TOKENS_OFFSET],r12
 mov [r15+NEBOC_PARSER_TOKEN_COUNT_OFFSET],r13
 mov qword [r15+NEBOC_PARSER_SOURCE_ID_OFFSET],1
 mov [r15+NEBOC_PARSER_BUILDER_OFFSET],rbx
 mov qword [r15+NEBOC_PARSER_MAX_NESTING_OFFSET],NEBOC_PARSER_DEFAULT_MAX_NESTING
 mov rdi,r15
 call neboc_parser_parse
parse_case_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,99
test_exit:
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
