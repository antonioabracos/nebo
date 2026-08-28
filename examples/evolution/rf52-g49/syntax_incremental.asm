bits 64
default rel
%include "compiler/incremental/syntax_incremental.inc"
global _start
extern neboc_source_snapshot_new,neboc_incremental_parser_set_budget
extern neboc_cli_check_cold,neboc_host_process_exit

section .data
source: db "let answer 42"
source_end:

section .bss align=16
snapshot: resb NEBOC_SNAPSHOT_SIZE
tokens: resb NEBOC_SYNTAX_INCREMENTAL_TOKEN_SIZE*8
lex_result: resb NEBOC_LEX_RESULT_SIZE
lex_request: resb NEBOC_LEX_REQUEST_SIZE
budget: resb NEBOC_INCREMENTAL_BUDGET_SIZE
tree: resb NEBOC_TREE_SIZE
parse_request: resb neboc_syntax_incremental_PARSE_REQUEST_SIZE

section .text
_start:
 sub rsp,8
 lea rdi,[rel snapshot]
 mov esi,1
 lea rdx,[rel source]
 mov ecx,source_end-source
 mov r8d,1
 call neboc_source_snapshot_new
 test eax,eax
 jne .done
 lea rdi,[rel budget]
 mov esi,64
 mov edx,4096
 mov ecx,100
 call neboc_incremental_parser_set_budget
 test eax,eax
 jne .done
 lea rax,[rel snapshot]
 mov [rel lex_request+NEBOC_LEX_REQUEST_SNAPSHOT_OFFSET],rax
 lea rax,[rel tokens]
 mov [rel lex_request+NEBOC_LEX_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel lex_request+NEBOC_LEX_REQUEST_TOKEN_CAPACITY_OFFSET],8
 lea rax,[rel lex_result]
 mov [rel lex_request+NEBOC_LEX_REQUEST_RESULT_OFFSET],rax
 lea rax,[rel lex_result]
 mov [rel parse_request+NEBOC_PARSE_REQUEST_LEX_OFFSET],rax
 lea rax,[rel budget]
 mov [rel parse_request+NEBOC_PARSE_REQUEST_BUDGET_OFFSET],rax
 lea rax,[rel tree]
 mov [rel parse_request+NEBOC_PARSE_REQUEST_TREE_OFFSET],rax
 lea rdi,[rel lex_request]
 lea rsi,[rel parse_request]
 call neboc_cli_check_cold
.done:
 mov edi,eax
 call neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
