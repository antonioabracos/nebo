; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF002 parser/AST goldens for the five frozen receiver APIs
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/expression/pratt.inc"
extern neboc_ast_builder_init
extern neboc_ast_builder_node
extern neboc_expression_parse
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,303,%2,%3,%4
%endmacro

section .data align=8
case1_tokens:
 TOK NEBOC_TOKEN_INTEGER,0,2,42
 TOK NEBOC_TOKEN_DOT,2,3,0
 TOK NEBOC_TOKEN_IDENTIFIER,3,10,0
 TOK NEBOC_TOKEN_LPAREN,10,11,0
 TOK NEBOC_TOKEN_RPAREN,11,12,0
 TOK NEBOC_TOKEN_EOF,12,12,0
case1_count equ ($-case1_tokens)/NEBOC_TOKEN_SIZE

case2_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,3,0
 TOK NEBOC_TOKEN_LPAREN,3,4,0
 TOK NEBOC_TOKEN_INTEGER,4,6,42
 TOK NEBOC_TOKEN_RPAREN,6,7,0
 TOK NEBOC_TOKEN_DOT,7,8,0
 TOK NEBOC_TOKEN_IDENTIFIER,8,15,0
 TOK NEBOC_TOKEN_LPAREN,15,16,0
 TOK NEBOC_TOKEN_RPAREN,16,17,0
 TOK NEBOC_TOKEN_EOF,17,17,0
case2_count equ ($-case2_tokens)/NEBOC_TOKEN_SIZE

case3_tokens:
 TOK NEBOC_TOKEN_FLOAT,0,3,0x3ff0000000000000
 TOK NEBOC_TOKEN_DOT,3,4,0
 TOK NEBOC_TOKEN_IDENTIFIER,4,12,0
 TOK NEBOC_TOKEN_LPAREN,12,13,0
 TOK NEBOC_TOKEN_RPAREN,13,14,0
 TOK NEBOC_TOKEN_EOF,14,14,0
case3_count equ ($-case3_tokens)/NEBOC_TOKEN_SIZE

case4_tokens:
 TOK NEBOC_TOKEN_FLOAT,0,3,0
 TOK NEBOC_TOKEN_DOT,3,4,0
 TOK NEBOC_TOKEN_IDENTIFIER,4,9,0
 TOK NEBOC_TOKEN_LPAREN,9,10,0
 TOK NEBOC_TOKEN_RPAREN,10,11,0
 TOK NEBOC_TOKEN_EOF,11,11,0
case4_count equ ($-case4_tokens)/NEBOC_TOKEN_SIZE

case5_tokens:
 TOK NEBOC_TOKEN_FLOAT,0,3,0x3ff0000000000000
 TOK NEBOC_TOKEN_DOT,3,4,0
 TOK NEBOC_TOKEN_IDENTIFIER,4,14,0
 TOK NEBOC_TOKEN_LPAREN,14,15,0
 TOK NEBOC_TOKEN_RPAREN,15,16,0
 TOK NEBOC_TOKEN_EOF,16,16,0
case5_count equ ($-case5_tokens)/NEBOC_TOKEN_SIZE

case6_tokens:
 TOK NEBOC_TOKEN_LPAREN,0,1,0
 TOK NEBOC_TOKEN_MINUS,1,2,0
 TOK NEBOC_TOKEN_FLOAT,2,5,0
 TOK NEBOC_TOKEN_RPAREN,5,6,0
 TOK NEBOC_TOKEN_DOT,6,7,0
 TOK NEBOC_TOKEN_IDENTIFIER,7,21,0
 TOK NEBOC_TOKEN_LPAREN,21,22,0
 TOK NEBOC_TOKEN_RPAREN,22,23,0
 TOK NEBOC_TOKEN_EOF,23,23,0
case6_count equ ($-case6_tokens)/NEBOC_TOKEN_SIZE

; tokens, count, method-token-index, receiver-kind, receiver-required-flags, start, end
cases:
 dq case1_tokens,case1_count,2,NEBOC_AST_INTEGER_LITERAL,0,0,12
 dq case2_tokens,case2_count,5,NEBOC_AST_CALL_EXPR,NEBOC_AST_FLAG_TYPE_CONSTRUCTOR,0,17
 dq case3_tokens,case3_count,2,NEBOC_AST_FLOAT_LITERAL,0,0,14
 dq case4_tokens,case4_count,2,NEBOC_AST_FLOAT_LITERAL,0,0,11
 dq case5_tokens,case5_count,2,NEBOC_AST_FLOAT_LITERAL,0,0,16
 dq case6_tokens,case6_count,5,NEBOC_AST_UNARY_EXPR,0,1,23
case_count equ ($-cases)/(7*8)

section .bss align=16
builder: resb NEBOC_AST_BUILDER_SIZE
request: resb NEBOC_EXPR_REQUEST_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*64
node_ptr: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel nodes]
 mov ecx,(NEBOC_AST_NODE_SIZE*64)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel request]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel builder]
 lea rsi,[rel nodes]
 mov edx,64
 call neboc_ast_builder_init
 test eax,eax
 jnz .fail
 mov rax,[r14]
 mov [rel request+NEBOC_EXPR_TOKENS_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+NEBOC_EXPR_TOKEN_COUNT_OFFSET],rax
 mov qword [rel request+NEBOC_EXPR_SOURCE_ID_OFFSET],303
 lea rax,[rel builder]
 mov [rel request+NEBOC_EXPR_BUILDER_OFFSET],rax
 mov qword [rel request+NEBOC_EXPR_MAX_NESTING_OFFSET],32
 lea rdi,[rel request]
 call neboc_expression_parse
 test eax,eax
 jnz .fail
 lea rdx,[rel node_ptr]
 mov rsi,[rel request+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdi,[rel builder]
 call neboc_ast_builder_node
 test eax,eax
 jnz .fail
 mov rbx,[rel node_ptr]
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .fail
 mov rax,[r14+16]
 cmp [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_SOURCE_ID_OFFSET],303
 jne .fail
 mov rax,[r14+40]
 cmp [rbx+NEBOC_AST_NODE_START_OFFSET],rax
 jne .fail
 mov rax,[r14+48]
 cmp [rbx+NEBOC_AST_NODE_END_OFFSET],rax
 jne .fail
 lea rdx,[rel node_ptr]
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdi,[rel builder]
 call neboc_ast_builder_node
 test eax,eax
 jnz .fail
 mov rbx,[rel node_ptr]
 mov rax,[r14+24]
 cmp [rbx+NEBOC_AST_NODE_KIND_OFFSET],rax
 jne .fail
 mov rax,[r14+32]
 test rax,rax
 jz .index
 mov rcx,[rbx+NEBOC_AST_NODE_FLAGS_OFFSET]
 and rcx,rax
 cmp rcx,rax
 jne .fail
.index:
 mov rax,[r14+8]
 dec rax
 cmp [rel request+NEBOC_EXPR_INDEX_OFFSET],rax
 jne .fail
 add r14,56
 inc r13d
 dec r15d
 jnz .loop
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
