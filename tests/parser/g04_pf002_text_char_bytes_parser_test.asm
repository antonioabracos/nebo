; TEXT-CHAR-UNICODE-E-BYTES-PF002 parser/AST shape goldens for frozen Text/Char/Bytes syntax
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
extern neboc_ast_builder_init
extern neboc_ast_builder_node
extern neboc_expression_parse
extern neboc_char_literal_contract_scan
extern neboc_char_literal_parse_contract
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,404,%2,%3,%4
%endmacro
section .data align=8
; "Nébo".byteLength()
case1_tokens:
 TOK NEBOC_TOKEN_TEXT,0,7,1
 TOK NEBOC_TOKEN_DOT,7,8,0
 TOK NEBOC_TOKEN_IDENTIFIER,8,18,0
 TOK NEBOC_TOKEN_LPAREN,18,19,0
 TOK NEBOC_TOKEN_RPAREN,19,20,0
 TOK NEBOC_TOKEN_EOF,20,20,0
case1_count equ ($-case1_tokens)/NEBOC_TOKEN_SIZE
; "Nébo".codepointCount()
case2_tokens:
 TOK NEBOC_TOKEN_TEXT,0,7,2
 TOK NEBOC_TOKEN_DOT,7,8,0
 TOK NEBOC_TOKEN_IDENTIFIER,8,22,0
 TOK NEBOC_TOKEN_LPAREN,22,23,0
 TOK NEBOC_TOKEN_RPAREN,23,24,0
 TOK NEBOC_TOKEN_EOF,24,24,0
case2_count equ ($-case2_tokens)/NEBOC_TOKEN_SIZE
; Bytes.empty()
case3_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,5,0
 TOK NEBOC_TOKEN_DOT,5,6,0
 TOK NEBOC_TOKEN_IDENTIFIER,6,11,0
 TOK NEBOC_TOKEN_LPAREN,11,12,0
 TOK NEBOC_TOKEN_RPAREN,12,13,0
 TOK NEBOC_TOKEN_EOF,13,13,0
case3_count equ ($-case3_tokens)/NEBOC_TOKEN_SIZE
; Bytes.empty().byteLength()
case4_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,5,0
 TOK NEBOC_TOKEN_DOT,5,6,0
 TOK NEBOC_TOKEN_IDENTIFIER,6,11,0
 TOK NEBOC_TOKEN_LPAREN,11,12,0
 TOK NEBOC_TOKEN_RPAREN,12,13,0
 TOK NEBOC_TOKEN_DOT,13,14,0
 TOK NEBOC_TOKEN_IDENTIFIER,14,24,0
 TOK NEBOC_TOKEN_LPAREN,24,25,0
 TOK NEBOC_TOKEN_RPAREN,25,26,0
 TOK NEBOC_TOKEN_EOF,26,26,0
case4_count equ ($-case4_tokens)/NEBOC_TOKEN_SIZE
; tokens,count,method_index,receiver_kind,start,end,receiver_child_count
cases:
 dq case1_tokens,case1_count,2,NEBOC_AST_TEXT_LITERAL,0,20,0
 dq case2_tokens,case2_count,2,NEBOC_AST_TEXT_LITERAL,0,24,0
 dq case3_tokens,case3_count,2,NEBOC_AST_IDENTIFIER_EXPR,0,13,0
 dq case4_tokens,case4_count,6,NEBOC_AST_CALL_EXPR,0,26,1
case_count equ ($-cases)/(7*8)
section .rodata
char1: db 39,'A',39
char2: db 39,0xc3,0xa7,39
char3: db 39,0xf0,0x9f,0x98,0x80,39
char_inputs: dq char1,3,0x41,char2,4,0xe7,char3,6,0x1f600
section .bss align=16
builder: resb NEBOC_AST_BUILDER_SIZE
request: resb NEBOC_EXPR_REQUEST_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*64
node_ptr: resq 1
scan: resb NEBOC_CHAR_REQUEST_SIZE
char_ast: resb NEBOC_CHAR_AST_SIZE
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
 mov qword [rel request+NEBOC_EXPR_SOURCE_ID_OFFSET],404
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
 mov rax,[r14+16]
 cmp [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 jne .fail
 mov rax,[r14+32]
 cmp [rbx+NEBOC_AST_NODE_START_OFFSET],rax
 jne .fail
 mov rax,[r14+40]
 cmp [rbx+NEBOC_AST_NODE_END_OFFSET],rax
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
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
 mov rax,[r14+48]
 cmp [rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 jne .fail
 add r14,56
 inc r13d
 dec r15d
 jnz .loop
 ; Three provisional Char AST goldens.
 lea r14,[rel char_inputs]
 mov r15d,3
.char_loop:
 lea rdi,[rel scan]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel scan+NEBOC_CHAR_SOURCE_OFFSET],rax
 mov rax,[r14+8]
 mov [rel scan+NEBOC_CHAR_LENGTH_OFFSET],rax
 mov qword [rel scan+NEBOC_CHAR_SOURCE_ID_OFFSET],404
 mov qword [rel scan+NEBOC_CHAR_ABSOLUTE_START_OFFSET],700
 lea rdi,[rel scan]
 call neboc_char_literal_contract_scan
 test eax,eax
 jnz .fail
 lea rdi,[rel scan]
 lea rsi,[rel char_ast]
 call neboc_char_literal_parse_contract
 test eax,eax
 jnz .fail
 cmp qword [rel char_ast+NEBOC_CHAR_AST_KIND_OFFSET],NEBOC_AST_CHAR_LITERAL_PROVISIONAL
 jne .fail
 mov rax,[r14+16]
 cmp [rel char_ast+NEBOC_CHAR_AST_SCALAR_OFFSET],rax
 jne .fail
 cmp qword [rel char_ast+NEBOC_CHAR_AST_START_OFFSET],700
 jne .fail
 add r14,24
 inc r13d
 dec r15d
 jnz .char_loop
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
