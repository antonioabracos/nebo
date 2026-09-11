; Bounded stdin-to-token witness for the live lexer, including malformed input.
; This native test binary is always valid; Nebo source is inspected, never run.
bits 64
default rel
%include "compiler/lexer/lexer.inc"
%include "compiler/tokens/token.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/expression/pratt.inc"
extern neboc_lexer_scan
extern neboc_ast_builder_init
extern neboc_expression_parse
section .bss
align 16
request: resb NEBOC_LEXER_REQUEST_SIZE
header: resq 4
source: resb 4096
tokens: resb NEBOC_TOKEN_SIZE*2048
literals: resb 4096
ast_mode: resq 1
builder: resb NEBOC_AST_BUILDER_SIZE
expression: resb NEBOC_EXPR_REQUEST_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*1024
section .text
global _start
_start:
 cmp qword [rsp],2
 sete byte [rel ast_mode]
 xor eax,eax
 xor edi,edi
 lea rsi,[rel source]
 mov edx,4096
 syscall
 test rax,rax
 js .fail
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],rax
 lea rax,[rel source]
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],170
 lea rax,[rel tokens]
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],2048
 lea rax,[rel literals]
 mov [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],4096
 lea rdi,[rel request]
 call neboc_lexer_scan
 cmp byte [rel ast_mode],0
 je .lex_output
 test eax,eax
 jnz .fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .fail
 lea rdi,[rel builder]
 lea rsi,[rel nodes]
 mov edx,1024
 call neboc_ast_builder_init
 test eax,eax
 jnz .fail
 lea rax,[rel tokens]
 mov [rel expression+NEBOC_EXPR_TOKENS_OFFSET],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel expression+NEBOC_EXPR_TOKEN_COUNT_OFFSET],rax
 mov qword [rel expression+NEBOC_EXPR_SOURCE_ID_OFFSET],170
 lea rax,[rel builder]
 mov [rel expression+NEBOC_EXPR_BUILDER_OFFSET],rax
 lea rax,[rel source]
 mov [rel expression+NEBOC_EXPR_SOURCE_DATA_OFFSET],rax
 lea rdi,[rel expression]
 call neboc_expression_parse
 test eax,eax
 jnz .ast_output
 mov rdx,[rel expression+NEBOC_EXPR_INDEX_OFFSET]
 inc rdx
 cmp rdx,[rel expression+NEBOC_EXPR_TOKEN_COUNT_OFFSET]
 je .ast_output
 ; A successful prefix is not proof that the complete expression was owned.
 mov eax,4
 mov qword [rel expression+NEBOC_EXPR_ERROR_CODE_OFFSET],6
.ast_output:
 mov [rel header],rax
 mov rax,[rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov [rel header+8],rax
 mov rax,[rel expression+NEBOC_EXPR_ERROR_CODE_OFFSET]
 mov [rel header+16],rax
 mov rax,[rel expression+NEBOC_EXPR_RESULT_NODE_OFFSET]
 mov [rel header+24],rax
 lea rsi,[rel header]
 mov edx,32
 call .write
 lea rsi,[rel nodes]
 mov rdx,[rel header+8]
 imul rdx,NEBOC_AST_NODE_SIZE
 call .write
 jmp .success
.lex_output:
 mov [rel header],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel header+8],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET]
 mov [rel header+16],rax
 mov rax,[rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel header+24],rax
 lea rsi,[rel header]
 mov edx,32
 call .write
 lea rsi,[rel tokens]
 mov rdx,[rel header+8]
 imul rdx,NEBOC_TOKEN_SIZE
 call .write
 lea rsi,[rel literals]
 mov rdx,[rel header+24]
 call .write
.success:
 mov eax,60
 xor edi,edi
 syscall
.write:
 test rdx,rdx
 jz .written
 mov eax,1
 mov edi,1
 syscall
 test rax,rax
 jle .fail
 add rsi,rax
 sub rdx,rax
 jmp .write
.written: ret
.fail:
 mov eax,60
 mov edi,1
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
