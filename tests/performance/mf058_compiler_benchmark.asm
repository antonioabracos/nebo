; Nebo Assembly — MF058 isolated lexer/parser performance fixtures
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"

extern neboc_lexer_scan
extern neboc_ast_builder_init
extern neboc_parser_parse
extern neboc_host_process_exit

global _start

%define MF058_LEXER_SOURCE_REPEATS 4096
%define MF058_LEXER_ITERATIONS 256
%define MF058_LEXER_TOKEN_CAPACITY 49152
%define MF058_LEXER_LITERAL_CAPACITY 4096
%define MF058_PARSER_ITERATIONS 500000
%define MF058_PARSER_NODE_CAPACITY 64

%macro TOK 3
    dq %1,0,1,%2,%3,0
%endmacro

section .rodata align=16
; Stable 64 KiB-class lexical fixture. It deliberately avoids literal storage,
; diagnostics and external I/O so the result measures the lexer core only.
lexer_source:
    times MF058_LEXER_SOURCE_REPEATS db 'start(){1+2*3;}'
lexer_source_end:
%define MF058_LEXER_SOURCE_BYTES (lexer_source_end-lexer_source)

; Stable empty-start parser fixture. It exercises program/start/block creation
; without lexer, semantic, codegen or toolchain work.
parser_tokens:
    TOK NEBOC_TOKEN_KW_START,0,5
    TOK NEBOC_TOKEN_LPAREN,5,6
    TOK NEBOC_TOKEN_RPAREN,6,7
    TOK NEBOC_TOKEN_LBRACE,7,8
    TOK NEBOC_TOKEN_RBRACE,8,9
    TOK NEBOC_TOKEN_EOF,9,9
parser_token_count equ ($-parser_tokens)/NEBOC_TOKEN_SIZE

section .bss align=64
lexer_request: resb NEBOC_LEXER_REQUEST_SIZE
lexer_tokens: resb MF058_LEXER_TOKEN_CAPACITY*NEBOC_TOKEN_SIZE
lexer_literals: resb MF058_LEXER_LITERAL_CAPACITY
parser_builder: resb NEBOC_AST_BUILDER_SIZE
parser_request: resb NEBOC_PARSER_SIZE
parser_nodes: resb MF058_PARSER_NODE_CAPACITY*NEBOC_AST_NODE_SIZE

section .text
_start:
    cmp qword [rsp], 2
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    cmp byte [rbx], '1'
    je benchmark_lexer
    cmp byte [rbx], '2'
    je benchmark_parser
    jmp test_usage

benchmark_lexer:
    mov r15d, MF058_LEXER_ITERATIONS
.lexer_loop:
    lea rax, [rel lexer_source]
    mov [rel lexer_request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET], rax
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET], MF058_LEXER_SOURCE_BYTES
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET], 58
    lea rax, [rel lexer_tokens]
    mov [rel lexer_request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET], rax
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET], MF058_LEXER_TOKEN_CAPACITY
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET], 0
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET], 0
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_FLAGS_OFFSET], 0
    lea rax, [rel lexer_literals]
    mov [rel lexer_request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET], rax
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET], MF058_LEXER_LITERAL_CAPACITY
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET], 0
    mov qword [rel lexer_request+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET], 0
    lea rdi, [rel lexer_request]
    call neboc_lexer_scan
    test eax, eax
    jnz test_fail
    cmp qword [rel lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET], 0
    jne test_fail
    dec r15d
    jnz .lexer_loop
    jmp test_pass

benchmark_parser:
    mov r15d, MF058_PARSER_ITERATIONS
.parser_loop:
    lea rdi, [rel parser_nodes]
    xor eax, eax
    mov ecx, (MF058_PARSER_NODE_CAPACITY*NEBOC_AST_NODE_SIZE)/8
    cld
    rep stosq
    lea rdi, [rel parser_builder]
    xor eax, eax
    mov ecx, NEBOC_AST_BUILDER_SIZE/8
    rep stosq
    lea rdi, [rel parser_request]
    xor eax, eax
    mov ecx, NEBOC_PARSER_SIZE/8
    rep stosq
    lea rdi, [rel parser_builder]
    lea rsi, [rel parser_nodes]
    mov edx, MF058_PARSER_NODE_CAPACITY
    call neboc_ast_builder_init
    test eax, eax
    jnz test_fail
    lea rax, [rel parser_tokens]
    mov [rel parser_request+NEBOC_PARSER_TOKENS_OFFSET], rax
    mov qword [rel parser_request+NEBOC_PARSER_TOKEN_COUNT_OFFSET], parser_token_count
    mov qword [rel parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET], 58
    lea rax, [rel parser_builder]
    mov [rel parser_request+NEBOC_PARSER_BUILDER_OFFSET], rax
    mov qword [rel parser_request+NEBOC_PARSER_MAX_NESTING_OFFSET], NEBOC_PARSER_DEFAULT_MAX_NESTING
    lea rdi, [rel parser_request]
    call neboc_parser_parse
    test eax, eax
    jnz test_fail
    cmp qword [rel parser_builder+NEBOC_AST_BUILDER_COUNT_OFFSET], 3
    jne test_fail
    dec r15d
    jnz .parser_loop
    jmp test_pass

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_fail:
    mov edi, 1
    jmp neboc_host_process_exit

test_usage:
    mov edi, 2
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
