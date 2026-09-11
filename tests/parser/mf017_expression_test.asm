; MF017 native Pratt expression parser tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
extern neboc_ast_builder_init
extern neboc_ast_builder_node
extern neboc_parse_operator_expression
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,1,%2,%3,%4
%endmacro

section .data
align 8
case4_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,5,0
 TOK NEBOC_TOKEN_DOT,5,6,0
 TOK NEBOC_TOKEN_IDENTIFIER,6,13,0
 TOK NEBOC_TOKEN_LPAREN,13,14,0
 TOK NEBOC_TOKEN_RPAREN,14,15,0
 TOK NEBOC_TOKEN_DOT,15,16,0
 TOK NEBOC_TOKEN_IDENTIFIER,16,20,0
 TOK NEBOC_TOKEN_EOF,20,20,0
case4_count equ ($-case4_tokens)/NEBOC_TOKEN_SIZE

case5_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1,1
 TOK NEBOC_TOKEN_DOT,1,2,0
 TOK NEBOC_TOKEN_IDENTIFIER,2,6,0
 TOK NEBOC_TOKEN_LPAREN,6,7,0
 TOK NEBOC_TOKEN_INTEGER,7,8,2
 TOK NEBOC_TOKEN_RPAREN,8,9,0
 TOK NEBOC_TOKEN_DOT,9,10,0
 TOK NEBOC_TOKEN_KW_RETURN,10,16,0
 TOK NEBOC_TOKEN_EOF,16,16,0
case5_count equ ($-case5_tokens)/NEBOC_TOKEN_SIZE

case6_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1,1
 TOK NEBOC_TOKEN_PLUS,2,3,0
 TOK NEBOC_TOKEN_INTEGER,4,5,2
 TOK NEBOC_TOKEN_STAR,6,7,0
 TOK NEBOC_TOKEN_INTEGER,8,9,3
 TOK NEBOC_TOKEN_EQUAL_EQUAL,10,12,0
 TOK NEBOC_TOKEN_INTEGER,13,14,7
 TOK NEBOC_TOKEN_OR_OR,15,17,0
 TOK NEBOC_TOKEN_KW_FALSE,18,23,0
 TOK NEBOC_TOKEN_EOF,23,23,0
case6_count equ ($-case6_tokens)/NEBOC_TOKEN_SIZE

case7_tokens:
 TOK NEBOC_TOKEN_LPAREN,0,1,0
 TOK NEBOC_TOKEN_MINUS,1,2,0
 TOK NEBOC_TOKEN_LPAREN,2,3,0
 TOK NEBOC_TOKEN_INTEGER,3,4,1
 TOK NEBOC_TOKEN_PLUS,4,5,0
 TOK NEBOC_TOKEN_INTEGER,5,6,2
 TOK NEBOC_TOKEN_RPAREN,6,7,0
 TOK NEBOC_TOKEN_RPAREN,7,8,0
 TOK NEBOC_TOKEN_DOT,8,9,0
 TOK NEBOC_TOKEN_IDENTIFIER,9,12,0
 TOK NEBOC_TOKEN_LPAREN,12,13,0
 TOK NEBOC_TOKEN_INTEGER,13,14,3
 TOK NEBOC_TOKEN_COMMA,14,15,0
 TOK NEBOC_TOKEN_INTEGER,15,16,4
 TOK NEBOC_TOKEN_RPAREN,16,17,0
 TOK NEBOC_TOKEN_EOF,17,17,0
case7_count equ ($-case7_tokens)/NEBOC_TOKEN_SIZE

case8a_tokens:
 TOK NEBOC_TOKEN_TEXT,0,5,0x0000000500000000
 TOK NEBOC_TOKEN_DOT,5,6,0
 TOK NEBOC_TOKEN_IDENTIFIER,6,13,0
 TOK NEBOC_TOKEN_LPAREN,13,14,0
 TOK NEBOC_TOKEN_RPAREN,14,15,0
 TOK NEBOC_TOKEN_DOT,15,16,0
 TOK NEBOC_TOKEN_IDENTIFIER,16,17,0
 TOK NEBOC_TOKEN_EOF,17,17,0
case8a_count equ ($-case8a_tokens)/NEBOC_TOKEN_SIZE
case8b_tokens:
 TOK NEBOC_TOKEN_TEXT,4,9,0x0000000500000000
 TOK NEBOC_TOKEN_DOT,20,21,0
 TOK NEBOC_TOKEN_IDENTIFIER,30,37,0
 TOK NEBOC_TOKEN_LPAREN,37,38,0
 TOK NEBOC_TOKEN_RPAREN,38,39,0
 TOK NEBOC_TOKEN_DOT,48,49,0
 TOK NEBOC_TOKEN_IDENTIFIER,49,50,0
 TOK NEBOC_TOKEN_EOF,50,50,0
case8b_count equ ($-case8b_tokens)/NEBOC_TOKEN_SIZE

case9_tokens:
 TOK NEBOC_TOKEN_LPAREN,0,1,0
 TOK NEBOC_TOKEN_LPAREN,1,2,0
 TOK NEBOC_TOKEN_LPAREN,2,3,0
 TOK NEBOC_TOKEN_INTEGER,3,4,1
 TOK NEBOC_TOKEN_RPAREN,4,5,0
 TOK NEBOC_TOKEN_RPAREN,5,6,0
 TOK NEBOC_TOKEN_RPAREN,6,7,0
 TOK NEBOC_TOKEN_EOF,7,7,0
case9_count equ ($-case9_tokens)/NEBOC_TOKEN_SIZE

case10_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,1,1
 TOK NEBOC_TOKEN_LESS,2,3,0
 TOK NEBOC_TOKEN_INTEGER,4,5,2
 TOK NEBOC_TOKEN_LESS,6,7,0
 TOK NEBOC_TOKEN_INTEGER,8,9,3
 TOK NEBOC_TOKEN_EOF,9,9,0
case10_count equ ($-case10_tokens)/NEBOC_TOKEN_SIZE

section .bss align=16
builder_a: resb NEBOC_AST_BUILDER_SIZE
request_a: resb NEBOC_EXPR_REQUEST_SIZE
nodes_a: resb NEBOC_AST_NODE_SIZE*128
builder_b: resb NEBOC_AST_BUILDER_SIZE
request_b: resb NEBOC_EXPR_REQUEST_SIZE
nodes_b: resb NEBOC_AST_NODE_SIZE*128

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp al,'4'
 je test_case4
 cmp al,'5'
 je test_case5
 cmp al,'6'
 je test_case6
 cmp al,'7'
 je test_case7
 cmp al,'8'
 je test_case8
 cmp al,'9'
 je test_case9
 cmp al,'1'
 jne test_usage
 cmp byte [rdx+1],'0'
 je test_case10
 jmp test_usage

test_case4:
 lea rdi,[rel case4_tokens]
 mov esi,case4_count
 xor edx,edx
 call parse_expression_a
 test eax,eax
 jnz test_fail
 mov rbx,[rel request_a+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov rdi,rbx
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],6
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],2
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne test_fail
 cmp qword [rel request_a+NEBOC_EXPR_INDEX_OFFSET],7
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case5:
 lea rdi,[rel case5_tokens]
 mov esi,case5_count
 xor edx,edx
 call parse_expression_a
 test eax,eax
 jnz test_fail
 mov rdi,[rel request_a+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],2
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case6:
 lea rdi,[rel case6_tokens]
 mov esi,case6_count
 xor edx,edx
 call parse_expression_a
 test eax,eax
 jnz test_fail
 mov rdi,[rel request_a+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_OR_OR
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_EQUAL_EQUAL
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_PLUS
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 mov rdi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_STAR
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case7:
 lea rdi,[rel case7_tokens]
 mov esi,case7_count
 xor edx,edx
 call parse_expression_a
 test eax,eax
 jnz test_fail
 mov rdi,[rel request_a+NEBOC_EXPR_RESULT_NODE_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne test_fail
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne test_fail
 mov rdi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call node_a
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case8:
 lea rdi,[rel case8a_tokens]
 mov esi,case8a_count
 xor edx,edx
 call parse_expression_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel case8b_tokens]
 mov esi,case8b_count
 xor edx,edx
 call parse_expression_b
 test eax,eax
 jnz test_fail
 mov rcx,[rel builder_a+NEBOC_AST_BUILDER_COUNT_OFFSET]
 cmp rcx,[rel builder_b+NEBOC_AST_BUILDER_COUNT_OFFSET]
 jne test_fail
 lea rsi,[rel nodes_a]
 lea rdi,[rel nodes_b]
test_compare_semantics:
 test rcx,rcx
 jz test_case8_ok
 mov rax,[rsi+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,[rdi+NEBOC_AST_NODE_KIND_OFFSET]
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
 jmp test_compare_semantics
test_case8_ok:
 xor edi,edi
 jmp test_exit

test_case9:
 lea rdi,[rel case9_tokens]
 mov esi,case9_count
 mov edx,2
 call parse_expression_a
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_EXPR_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NESTING_LIMIT
 jne test_fail
 xor edi,edi
 jmp test_exit

test_case10:
 lea rdi,[rel case10_tokens]
 mov esi,case10_count
 xor edx,edx
 call parse_expression_a
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_EXPR_ERROR_CODE_OFFSET],NEBOC_PARSE_DIAG_NONASSOCIATIVE_CHAIN
 jne test_fail
 cmp qword [rel request_a+NEBOC_EXPR_ERROR_TOKEN_OFFSET],3
 jne test_fail
 xor edi,edi
 jmp test_exit

; parse_expression_a(tokens,count,max_nesting)
parse_expression_a:
 lea rcx,[rel request_a]
 lea r8,[rel builder_a]
 lea r9,[rel nodes_a]
 jmp parse_expression_common
parse_expression_b:
 lea rcx,[rel request_b]
 lea r8,[rel builder_b]
 lea r9,[rel nodes_b]
parse_expression_common:
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
 mov r10,r9
 mov rdi,r10
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*128)/8
 rep stosq
 mov rdi,r15
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 rep stosq
 mov rdi,rbx
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 mov rdi,rbx
 mov rsi,r10
 mov edx,128
 call neboc_ast_builder_init
 test eax,eax
 jnz parse_expression_done
 mov [r15+NEBOC_EXPR_TOKENS_OFFSET],r12
 mov [r15+NEBOC_EXPR_TOKEN_COUNT_OFFSET],r13
 mov qword [r15+NEBOC_EXPR_SOURCE_ID_OFFSET],1
 mov [r15+NEBOC_EXPR_BUILDER_OFFSET],rbx
 mov [r15+NEBOC_EXPR_MAX_NESTING_OFFSET],r14
 mov rdi,r15
 call neboc_parse_operator_expression
parse_expression_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

node_a:
 lea rsi,[rel request_a+NEBOC_EXPR_SCRATCH0_OFFSET]
 mov qword [rsi],0
 mov rdx,rsi
 mov rsi,rdi
 lea rdi,[rel builder_a]
 call neboc_ast_builder_node
 test eax,eax
 jnz test_fail
 mov rax,[rel request_a+NEBOC_EXPR_SCRATCH0_OFFSET]
 ret

test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,99
test_exit:
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
