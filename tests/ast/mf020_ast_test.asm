; Nebo Assembly — MF020 AstStore, immutable AST, dump and determinism
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/ast/dump/ast_dump.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/statements/statements.inc"
%include "compiler/parser/recovery/recovery.inc"

extern neboc_ast_builder_init
extern neboc_ast_builder_append
extern neboc_ast_builder_node
extern neboc_parser_parse
extern neboc_parser_recovery_parse_statement
extern neboc_ast_store_freeze
extern neboc_ast_store_verify_immutable
extern neboc_ast_store_node
extern neboc_ast_store_require_clean
extern neboc_ast_dump_canonical
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,1,%2,%3,%4
%endmacro

%define TEST_NODE_CAPACITY 64
%define TEST_DUMP_CAPACITY 4096

section .data
align 8
simple_tokens:
 TOK NEBOC_TOKEN_KW_START,0,5,0
 TOK NEBOC_TOKEN_LPAREN,5,6,0
 TOK NEBOC_TOKEN_RPAREN,6,7,0
 TOK NEBOC_TOKEN_LBRACE,8,9,0
 TOK NEBOC_TOKEN_RBRACE,9,10,0
 TOK NEBOC_TOKEN_EOF,10,10,0
simple_token_count equ ($-simple_tokens)/NEBOC_TOKEN_SIZE

golden_dump:
 incbin "tests/ast/goldens/015-ast-dump.txt"
golden_dump_size equ $-golden_dump

section .bss align=16
builder_a: resb NEBOC_AST_BUILDER_SIZE
parser_a: resb NEBOC_PARSER_SIZE
source_nodes_a: resb NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY
store_a: resb NEBOC_AST_STORE_SIZE
store_nodes_a: resb NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY
parents_a: resq TEST_NODE_CAPACITY

builder_b: resb NEBOC_AST_BUILDER_SIZE
parser_b: resb NEBOC_PARSER_SIZE
source_nodes_b: resb NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY
store_b: resb NEBOC_AST_STORE_SIZE
store_nodes_b: resb NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY
parents_b: resq TEST_NODE_CAPACITY

dump_request_a: resb NEBOC_AST_DUMP_REQUEST_SIZE
dump_request_b: resb NEBOC_AST_DUMP_REQUEST_SIZE
dump_buffer_a: resb TEST_DUMP_CAPACITY
dump_buffer_b: resb TEST_DUMP_CAPACITY

fuzz_builder: resb NEBOC_AST_BUILDER_SIZE
fuzz_recovery: resb NEBOC_RECOVERY_REQUEST_SIZE
fuzz_statement: resb NEBOC_STMT_REQUEST_SIZE
fuzz_expression: resb NEBOC_EXPR_REQUEST_SIZE
fuzz_nodes: resb NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY
fuzz_tokens: resb NEBOC_TOKEN_SIZE*2

node_out: resq 1
append_out: resq 1
saved_hash: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp al,'1'
 je test_case1_or_15
 cmp al,'2'
 je test_case2_or_20
 cmp al,'3'
 je test_case3
 cmp al,'8'
 je test_case8
 jmp test_usage

test_case1_or_15:
 movzx eax,byte [rdx+1]
 test al,al
 jz test_case1
 cmp al,'5'
 je test_case15
 jmp test_usage

test_case2_or_20:
 movzx eax,byte [rdx+1]
 test al,al
 jz test_case2
 cmp al,'0'
 je test_case20
 jmp test_usage

; CONTRACT-001: structural data remains in AstNode; parent metadata is a
; separate side table and clean parser output is consumable.
test_case1:
 call build_store_a
 test eax,eax
 jnz test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_ROOT_ID_OFFSET],1
 jne test_fail
 cmp qword [rel parents_a+0],0
 jne test_fail
 cmp qword [rel parents_a+8],1
 jne test_fail
 cmp qword [rel parents_a+16],2
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_NONE
 jne test_fail
 lea rdi,[rel store_a]
 call neboc_ast_store_require_clean
 test eax,eax
 jnz test_fail
 xor edi,edi
 jmp test_exit

; CONTRACT-002: all public links are bounded 1-based NodeIds; pointer-shaped
; child values are rejected by validation.
test_case2:
 call build_store_a
 test eax,eax
 jnz test_fail
 mov rbx,1
test_case2_id_loop:
 mov qword [rel node_out],0
 lea rdi,[rel store_a]
 mov rsi,rbx
 lea rdx,[rel node_out]
 call neboc_ast_store_node
 test eax,eax
 jnz test_fail
 mov rax,rbx
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 lea rcx,[rel store_nodes_a]
 add rcx,rax
 cmp [rel node_out],rcx
 jne test_fail
 inc rbx
 cmp rbx,4
 jb test_case2_id_loop
 mov qword [rel node_out],1
 lea rdi,[rel store_a]
 xor esi,esi
 lea rdx,[rel node_out]
 call neboc_ast_store_node
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 cmp qword [rel node_out],0
 jne test_fail
 lea rdi,[rel store_a]
 mov esi,4
 lea rdx,[rel node_out]
 call neboc_ast_store_node
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail

 call init_builder_a
 test eax,eax
 jnz test_fail
 ; Program root.
 lea rdi,[rel builder_a]
 mov esi,NEBOC_AST_PROGRAM
 mov edx,1
 xor ecx,ecx
 mov r8d,2
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 test eax,eax
 jnz test_fail
 ; Block child.
 lea rdi,[rel builder_a]
 mov esi,NEBOC_AST_BLOCK
 mov edx,1
 xor ecx,ecx
 mov r8d,2
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 test eax,eax
 jnz test_fail
 lea rdi,[rel builder_a]
 mov esi,1
 lea rdx,[rel node_out]
 call neboc_ast_builder_node
 test eax,eax
 jnz test_fail
 mov rax,[rel node_out]
 lea rcx,[rel source_nodes_a]
 mov [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rcx
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 lea rdi,[rel store_a]
 lea rsi,[rel builder_a]
 lea rdx,[rel store_nodes_a]
 lea rcx,[rel parents_a]
 mov r8d,TEST_NODE_CAPACITY
 mov r9d,1
 call neboc_ast_store_freeze
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],NEBOC_AST_VALIDATION_BAD_ID
 jne test_fail
 xor edi,edi
 jmp test_exit

; CONTRACT-003: finalizing freezes the builder; source mutations do not alter
; the copied store, while store mutation is detected by the stable hash.
test_case3:
 call build_store_a
 test eax,eax
 jnz test_fail
 mov rax,[rel store_a+NEBOC_AST_STORE_HASH_OFFSET]
 mov [rel saved_hash],rax
 mov qword [rel append_out],0
 lea rdi,[rel builder_a]
 mov esi,NEBOC_AST_INTEGER_LITERAL
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne test_fail
 or qword [rel source_nodes_a+NEBOC_AST_NODE_FLAGS_OFFSET],0x100
 lea rdi,[rel store_a]
 call neboc_ast_store_verify_immutable
 test eax,eax
 jnz test_fail
 mov rax,[rel store_a+NEBOC_AST_STORE_HASH_OFFSET]
 cmp rax,[rel saved_hash]
 jne test_fail
 or qword [rel store_nodes_a+NEBOC_AST_NODE_FLAGS_OFFSET],0x100
 lea rdi,[rel store_a]
 call neboc_ast_store_verify_immutable
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_VALIDATION_ERROR_OFFSET],NEBOC_AST_VALIDATION_HASH_MISMATCH
 jne test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_INVALID
 jne test_fail
 xor edi,edi
 jmp test_exit

; NEG-008: a structurally valid recovered ErrorNode is retained for diagnostics
; but the clean-AST gate blocks future semantic/codegen consumption.
test_case8:
 call init_builder_a
 test eax,eax
 jnz test_fail
 lea rdi,[rel builder_a]
 mov esi,NEBOC_AST_PROGRAM
 mov edx,1
 xor ecx,ecx
 mov r8d,2
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 test eax,eax
 jnz test_fail
 lea rdi,[rel builder_a]
 mov esi,NEBOC_AST_ERROR_NODE
 mov edx,1
 xor ecx,ecx
 mov r8d,1
 lea r9,[rel append_out]
 call neboc_ast_builder_append
 test eax,eax
 jnz test_fail
 lea rdi,[rel builder_a]
 mov esi,1
 lea rdx,[rel node_out]
 call neboc_ast_builder_node
 test eax,eax
 jnz test_fail
 mov rax,[rel node_out]
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],2
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 lea rdi,[rel builder_a]
 mov esi,2
 lea rdx,[rel node_out]
 call neboc_ast_builder_node
 test eax,eax
 jnz test_fail
 mov rax,[rel node_out]
 or qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_RECOVERED
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],1
 lea rdi,[rel store_a]
 lea rsi,[rel builder_a]
 lea rdx,[rel store_nodes_a]
 lea rcx,[rel parents_a]
 mov r8d,TEST_NODE_CAPACITY
 mov r9d,1
 call neboc_ast_store_freeze
 test eax,eax
 jnz test_fail
 test qword [rel store_a+NEBOC_AST_STORE_FLAGS_OFFSET],NEBOC_AST_STORE_FLAG_HAS_ERROR
 jz test_fail
 cmp qword [rel store_a+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET],2
 jne test_fail
 lea rdi,[rel store_a]
 call neboc_ast_store_require_clean
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 xor edi,edi
 jmp test_exit

; PARSE-DETERMINISM-015: identical parser input yields identical IDs, hash and
; canonical golden dump without addresses, time or locale data.
test_case15:
 call build_store_a
 test eax,eax
 jnz test_fail
 call build_store_b
 test eax,eax
 jnz test_fail
 mov rax,[rel store_a+NEBOC_AST_STORE_HASH_OFFSET]
 cmp rax,[rel store_b+NEBOC_AST_STORE_HASH_OFFSET]
 jne test_fail
 lea rdi,[rel dump_request_a]
 xor eax,eax
 mov ecx,NEBOC_AST_DUMP_REQUEST_SIZE/8
 rep stosq
 lea rax,[rel store_a]
 mov [rel dump_request_a+NEBOC_AST_DUMP_STORE_OFFSET],rax
 lea rax,[rel dump_buffer_a]
 mov [rel dump_request_a+NEBOC_AST_DUMP_BUFFER_OFFSET],rax
 mov qword [rel dump_request_a+NEBOC_AST_DUMP_CAPACITY_OFFSET],TEST_DUMP_CAPACITY
 lea rdi,[rel dump_request_a]
 call neboc_ast_dump_canonical
 test eax,eax
 jnz test_fail
 lea rdi,[rel dump_request_b]
 xor eax,eax
 mov ecx,NEBOC_AST_DUMP_REQUEST_SIZE/8
 rep stosq
 lea rax,[rel store_b]
 mov [rel dump_request_b+NEBOC_AST_DUMP_STORE_OFFSET],rax
 lea rax,[rel dump_buffer_b]
 mov [rel dump_request_b+NEBOC_AST_DUMP_BUFFER_OFFSET],rax
 mov qword [rel dump_request_b+NEBOC_AST_DUMP_CAPACITY_OFFSET],TEST_DUMP_CAPACITY
 lea rdi,[rel dump_request_b]
 call neboc_ast_dump_canonical
 test eax,eax
 jnz test_fail
 mov rcx,[rel dump_request_a+NEBOC_AST_DUMP_LENGTH_OFFSET]
 cmp rcx,[rel dump_request_b+NEBOC_AST_DUMP_LENGTH_OFFSET]
 jne test_fail
 cmp rcx,golden_dump_size
 jne test_fail
 lea rsi,[rel dump_buffer_a]
 lea rdi,[rel dump_buffer_b]
 repe cmpsb
 jne test_fail
 mov rcx,[rel dump_request_a+NEBOC_AST_DUMP_LENGTH_OFFSET]
 lea rsi,[rel dump_buffer_a]
 lea rdi,[rel golden_dump]
 repe cmpsb
 jne test_fail
 lea rdi,[rel store_a]
 call neboc_ast_store_verify_immutable
 test eax,eax
 jnz test_fail
 lea rdi,[rel store_b]
 call neboc_ast_store_verify_immutable
 test eax,eax
 jnz test_fail
 xor edi,edi
 jmp test_exit

; Bounded deterministic parser fuzz. Every Core token kind is tested as the
; first token before EOF. The contract is termination, bounded cursor/nodes and
; a controlled status, not semantic acceptance.
test_case20:
 xor ebx,ebx
test_case20_loop:
 cmp ebx,96
 jae test_case20_done
 call init_fuzz_case
 test eax,eax
 jnz test_fail
 mov [rel fuzz_tokens+NEBOC_TOKEN_KIND_OFFSET],rbx
 lea rdi,[rel fuzz_recovery]
 call neboc_parser_recovery_parse_statement
 cmp eax,NEBOC_STATUS_OK
 je test_case20_check
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je test_case20_check
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne test_fail
test_case20_check:
 cmp qword [rel fuzz_recovery+NEBOC_RECOVERY_INDEX_OFFSET],2
 ja test_fail
 cmp qword [rel fuzz_builder+NEBOC_AST_BUILDER_COUNT_OFFSET],TEST_NODE_CAPACITY
 ja test_fail
 inc ebx
 jmp test_case20_loop
test_case20_done:
 xor edi,edi
 jmp test_exit

; Build the same minimal parser AST in caller-selected buffers and freeze it.
; RDI=builder, RSI=parser, RDX=source nodes, RCX=store, R8=store nodes,
; R9=parent side table.
build_store_common:
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
 mov rdi,r14
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY)/8
 rep stosq
 mov rdi,r12
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 mov rdi,r13
 mov ecx,NEBOC_PARSER_SIZE/8
 rep stosq
 mov rdi,r15
 mov ecx,NEBOC_AST_STORE_SIZE/8
 rep stosq
 mov rdi,rbx
 mov ecx,(NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY)/8
 rep stosq
 mov rdi,[rsp]
 mov ecx,TEST_NODE_CAPACITY
 rep stosq
 mov rdi,r12
 mov rsi,r14
 mov edx,TEST_NODE_CAPACITY
 call neboc_ast_builder_init
 test eax,eax
 jnz build_store_done
 lea rax,[rel simple_tokens]
 mov [r13+NEBOC_PARSER_TOKENS_OFFSET],rax
 mov qword [r13+NEBOC_PARSER_TOKEN_COUNT_OFFSET],simple_token_count
 mov qword [r13+NEBOC_PARSER_SOURCE_ID_OFFSET],1
 mov [r13+NEBOC_PARSER_BUILDER_OFFSET],r12
 mov qword [r13+NEBOC_PARSER_MAX_NESTING_OFFSET],NEBOC_PARSER_DEFAULT_MAX_NESTING
 mov rdi,r13
 call neboc_parser_parse
 test eax,eax
 jnz build_store_done
 mov rdi,r15
 mov rsi,r12
 mov rdx,rbx
 mov rcx,[rsp]
 mov r8d,TEST_NODE_CAPACITY
 mov r9,[r13+NEBOC_PARSER_ROOT_ID_OFFSET]
 call neboc_ast_store_freeze
build_store_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

build_store_a:
 lea rdi,[rel builder_a]
 lea rsi,[rel parser_a]
 lea rdx,[rel source_nodes_a]
 lea rcx,[rel store_a]
 lea r8,[rel store_nodes_a]
 lea r9,[rel parents_a]
 jmp build_store_common

build_store_b:
 lea rdi,[rel builder_b]
 lea rsi,[rel parser_b]
 lea rdx,[rel source_nodes_b]
 lea rcx,[rel store_b]
 lea r8,[rel store_nodes_b]
 lea r9,[rel parents_b]
 jmp build_store_common

init_builder_a:
 lea rdi,[rel source_nodes_a]
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY)/8
 rep stosq
 lea rdi,[rel builder_a]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 lea rdi,[rel store_a]
 mov ecx,NEBOC_AST_STORE_SIZE/8
 rep stosq
 lea rdi,[rel store_nodes_a]
 mov ecx,(NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY)/8
 rep stosq
 lea rdi,[rel parents_a]
 mov ecx,TEST_NODE_CAPACITY
 rep stosq
 lea rdi,[rel builder_a]
 lea rsi,[rel source_nodes_a]
 mov edx,TEST_NODE_CAPACITY
 jmp neboc_ast_builder_init

init_fuzz_case:
 lea rdi,[rel fuzz_nodes]
 xor eax,eax
 mov ecx,(NEBOC_AST_NODE_SIZE*TEST_NODE_CAPACITY)/8
 rep stosq
 lea rdi,[rel fuzz_builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 rep stosq
 lea rdi,[rel fuzz_recovery]
 mov ecx,NEBOC_RECOVERY_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel fuzz_statement]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel fuzz_expression]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 rep stosq
 lea rdi,[rel fuzz_tokens]
 mov ecx,(NEBOC_TOKEN_SIZE*2)/8
 rep stosq
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_SOURCE_ID_OFFSET],1
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_END_OFFSET],1
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_EOF
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_SOURCE_ID_OFFSET],1
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_START_OFFSET],1
 mov qword [rel fuzz_tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_END_OFFSET],1
 lea rdi,[rel fuzz_builder]
 lea rsi,[rel fuzz_nodes]
 mov edx,TEST_NODE_CAPACITY
 call neboc_ast_builder_init
 test eax,eax
 jnz init_fuzz_done
 lea rax,[rel fuzz_tokens]
 mov [rel fuzz_recovery+NEBOC_RECOVERY_TOKENS_OFFSET],rax
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_TOKEN_COUNT_OFFSET],2
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_SOURCE_ID_OFFSET],1
 lea rax,[rel fuzz_builder]
 mov [rel fuzz_recovery+NEBOC_RECOVERY_BUILDER_OFFSET],rax
 lea rax,[rel fuzz_statement]
 mov [rel fuzz_recovery+NEBOC_RECOVERY_STATEMENT_REQUEST_OFFSET],rax
 lea rax,[rel fuzz_expression]
 mov [rel fuzz_recovery+NEBOC_RECOVERY_EXPRESSION_REQUEST_OFFSET],rax
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_MAX_NESTING_OFFSET],64
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_MAX_DIAGNOSTICS_OFFSET],8
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_MAX_TOKENS_OFFSET],2
 mov qword [rel fuzz_recovery+NEBOC_RECOVERY_MAX_AST_NODES_OFFSET],TEST_NODE_CAPACITY
 xor eax,eax
init_fuzz_done:
 ret

test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,99
test_exit:
 jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
