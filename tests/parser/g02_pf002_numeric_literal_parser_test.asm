; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF002 parser/token provenance API test
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/expression/pratt.inc"
extern neboc_numeric_literal_contract_scan
extern neboc_ast_builder_init
extern neboc_ast_builder_node
extern neboc_expression_parse
extern neboc_host_process_exit

section .rodata
s1: db '0b1010'
s2: db '0x2A'
s3: db '0o7_55'
s4: db '1_000'
inputs: dq s1,6,10,NEBOC_TOKEN_FLAG_INT_BASE_BINARY|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
        dq s2,4,42,NEBOC_TOKEN_FLAG_INT_BASE_HEX|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
        dq s3,6,493,NEBOC_TOKEN_FLAG_INT_BASE_OCTAL|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY
        dq s4,5,1000,NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY

section .bss align=16
scan: resb NEBOC_NUMERIC_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*2
builder: resb NEBOC_AST_BUILDER_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*8
expr: resb NEBOC_EXPR_REQUEST_SIZE
node_ptr: resq 1

section .text
global _start
_start:
 lea r14,[rel inputs]
 mov r15d,4
.loop:
 lea rdi,[rel scan]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel scan+NEBOC_NUMERIC_SOURCE_OFFSET],rax
 mov rax,[r14+8]
 mov [rel scan+NEBOC_NUMERIC_LENGTH_OFFSET],rax
 mov qword [rel scan+NEBOC_NUMERIC_SOURCE_ID_OFFSET],77
 mov qword [rel scan+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],500
 lea rdi,[rel scan]
 call neboc_numeric_literal_contract_scan
 test eax,eax
 jnz .fail
 ; Materialize the provisional token API consumed by the existing parser.
 lea rdi,[rel tokens]
 mov ecx,(NEBOC_TOKEN_SIZE*2)/8
 xor eax,eax
 rep stosq
 mov qword [rel tokens+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 mov rax,[rel scan+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 mov [rel tokens+NEBOC_TOKEN_FLAGS_OFFSET],rax
 cmp rax,[r14+24]
 jne .fail
 mov qword [rel tokens+NEBOC_TOKEN_SOURCE_ID_OFFSET],77
 mov qword [rel tokens+NEBOC_TOKEN_START_OFFSET],500
 mov rax,[r14+8]
 add rax,500
 mov [rel tokens+NEBOC_TOKEN_END_OFFSET],rax
 mov rax,[rel scan+NEBOC_NUMERIC_VALUE_OFFSET]
 mov [rel tokens+NEBOC_TOKEN_PAYLOAD_OFFSET],rax
 cmp rax,[r14+16]
 jne .fail
 mov qword [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_EOF
 mov rax,[r14+8]
 add rax,500
 mov [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_START_OFFSET],rax
 mov [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_END_OFFSET],rax
 ; Parse one integer expression.
 lea rdi,[rel nodes]
 mov ecx,(NEBOC_AST_NODE_SIZE*8)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel expr]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel builder]
 lea rsi,[rel nodes]
 mov edx,8
 call neboc_ast_builder_init
 test eax,eax
 jnz .fail
 lea rax,[rel tokens]
 mov [rel expr+NEBOC_EXPR_TOKENS_OFFSET],rax
 mov qword [rel expr+NEBOC_EXPR_TOKEN_COUNT_OFFSET],2
 mov qword [rel expr+NEBOC_EXPR_SOURCE_ID_OFFSET],77
 lea rax,[rel builder]
 mov [rel expr+NEBOC_EXPR_BUILDER_OFFSET],rax
 mov qword [rel expr+NEBOC_EXPR_MAX_NESTING_OFFSET],8
 lea rdi,[rel expr]
 call neboc_expression_parse
 test eax,eax
 jnz .fail
 lea rdx,[rel node_ptr]
 mov rsi,[rel expr+NEBOC_EXPR_RESULT_NODE_OFFSET]
 lea rdi,[rel builder]
 call neboc_ast_builder_node
 test eax,eax
 jnz .fail
 mov rbx,[rel node_ptr]
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .fail
 mov rax,[r14+16]
 cmp [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],rax
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_SOURCE_ID_OFFSET],77
 jne .fail
 cmp qword [rbx+NEBOC_AST_NODE_START_OFFSET],500
 jne .fail
 mov rax,[r14+8]
 add rax,500
 cmp [rbx+NEBOC_AST_NODE_END_OFFSET],rax
 jne .fail
 add r14,32
 dec r15d
 jnz .loop
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
