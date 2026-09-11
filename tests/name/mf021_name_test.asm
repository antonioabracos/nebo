; Nebo Assembly — MF021 ScopeTable, SymbolTable and name-resolution tests
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/scope/scope_table.inc"
%include "compiler/semantic/symbol/symbol_table.inc"
%include "compiler/semantic/symbol/name_resolver.inc"

extern neboc_ast_store_freeze
extern neboc_scope_table_init
extern neboc_symbol_table_init
extern neboc_name_resolve
extern neboc_host_process_exit

%macro TOK 3
 dq %1,0,1,%2,%3,0
%endmacro

%macro NODE 9
 dq %1,%2,1,%3,%4,%5,%6,%7,%8,%9
%endmacro

%define CAPACITY 64

section .rodata
align 8
; Case 1 — binding visible after declaration.
case1_source: db 'x x'
case1_source_len equ $-case1_source
align 8
case1_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,1
 TOK NEBOC_TOKEN_IDENTIFIER,2,3
case1_token_count equ ($-case1_tokens)/NEBOC_TOKEN_SIZE
align 8
case1_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,3,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,3,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,3,4,0,2,0,0
 NODE NEBOC_AST_BINDING_STMT,0,0,1,5,6,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,2,3,7,0,1,0,0
 NODE NEBOC_AST_IDENTIFIER_EXPR,0,2,3,0,0,0,1,0
case1_node_count equ ($-case1_nodes)/NEBOC_AST_NODE_SIZE
case1_desc: dq case1_nodes,case1_node_count,case1_tokens,case1_token_count,case1_source,case1_source_len

; Case 2 — use before declaration.
case2_source: db 'x x'
case2_source_len equ $-case2_source
align 8
case2_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,1
 TOK NEBOC_TOKEN_IDENTIFIER,2,3
case2_token_count equ ($-case2_tokens)/NEBOC_TOKEN_SIZE
align 8
case2_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,3,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,3,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,3,4,0,2,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,6,1,0,0
 NODE NEBOC_AST_IDENTIFIER_EXPR,0,0,1,0,0,0,0,0
 NODE NEBOC_AST_BINDING_STMT,0,2,3,7,0,1,1,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,2,3,0,0,0,0,0
case2_node_count equ ($-case2_nodes)/NEBOC_AST_NODE_SIZE
case2_desc: dq case2_nodes,case2_node_count,case2_tokens,case2_token_count,case2_source,case2_source_len

; Case 3 — duplicate in one scope.
case3_source: db 'x x'
case3_source_len equ $-case3_source
align 8
case3_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,1
 TOK NEBOC_TOKEN_IDENTIFIER,2,3
case3_token_count equ ($-case3_tokens)/NEBOC_TOKEN_SIZE
align 8
case3_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,3,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,3,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,3,4,0,2,0,0
 NODE NEBOC_AST_BINDING_STMT,0,0,1,5,6,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,0,0
 NODE NEBOC_AST_BINDING_STMT,0,2,3,7,0,1,1,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,2,3,0,0,0,0,0
case3_node_count equ ($-case3_nodes)/NEBOC_AST_NODE_SIZE
case3_desc: dq case3_nodes,case3_node_count,case3_tokens,case3_token_count,case3_source,case3_source_len

; Case 4 — inner scope shadowing is forbidden.
case4_source: db 'x x'
case4_source_len equ $-case4_source
align 8
case4_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,1
 TOK NEBOC_TOKEN_IDENTIFIER,2,3
case4_token_count equ ($-case4_tokens)/NEBOC_TOKEN_SIZE
align 8
case4_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,3,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,3,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,3,4,0,2,0,0
 NODE NEBOC_AST_BINDING_STMT,0,0,1,5,6,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,0,0
 NODE NEBOC_AST_IF_STMT,0,0,3,7,0,2,0,0
 NODE NEBOC_AST_BOOL_LITERAL,0,0,1,0,8,0,0,0
 NODE NEBOC_AST_BLOCK,0,2,3,9,0,1,0,0
 NODE NEBOC_AST_BINDING_STMT,0,2,3,10,0,1,1,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,2,3,0,0,0,0,0
case4_node_count equ ($-case4_nodes)/NEBOC_AST_NODE_SIZE
case4_desc: dq case4_nodes,case4_node_count,case4_tokens,case4_token_count,case4_source,case4_source_len

; Case 5 — function declaration order is independent from call order.
case5_source: db 'soma soma Int self'
case5_source_len equ $-case5_source
align 8
case5_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,4
 TOK NEBOC_TOKEN_IDENTIFIER,5,9
 TOK NEBOC_TOKEN_IDENTIFIER,10,13
 TOK NEBOC_TOKEN_IDENTIFIER,14,18
case5_token_count equ ($-case5_tokens)/NEBOC_TOKEN_SIZE
align 8
case5_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,18,2,0,2,0,0
 NODE NEBOC_AST_START_DECL,0,0,4,3,7,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,4,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,4,5,0,1,0,0
 NODE NEBOC_AST_CALL_EXPR,0,0,4,6,0,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,4,0,0,0,0,0
 NODE NEBOC_AST_FUNCTION_DECL,0,5,18,8,0,2,1,0
 NODE NEBOC_AST_RECEIVER,0,10,18,0,9,0,2,3
 NODE NEBOC_AST_BLOCK,0,18,18,0,0,0,0,0
case5_node_count equ ($-case5_nodes)/NEBOC_AST_NODE_SIZE
case5_desc: dq case5_nodes,case5_node_count,case5_tokens,case5_token_count,case5_source,case5_source_len

; Case 6 — reserved word cannot be a declaration name.
case6_source: db 'if'
case6_source_len equ $-case6_source
align 8
case6_tokens:
 TOK NEBOC_TOKEN_KW_IF,0,2
case6_token_count equ ($-case6_tokens)/NEBOC_TOKEN_SIZE
align 8
case6_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,2,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,2,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,2,4,0,1,0,0
 NODE NEBOC_AST_BINDING_STMT,0,0,2,5,0,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,2,0,0,0,0,0
case6_node_count equ ($-case6_nodes)/NEBOC_AST_NODE_SIZE
case6_desc: dq case6_nodes,case6_node_count,case6_tokens,case6_token_count,case6_source,case6_source_len

; Case 7/8 — receiver and parameter symbols plus deterministic IDs.
case7_source: db 'foo Int self Int other self other'
case7_source_len equ $-case7_source
align 8
case7_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,3
 TOK NEBOC_TOKEN_IDENTIFIER,4,7
 TOK NEBOC_TOKEN_IDENTIFIER,8,12
 TOK NEBOC_TOKEN_IDENTIFIER,13,16
 TOK NEBOC_TOKEN_IDENTIFIER,17,22
 TOK NEBOC_TOKEN_IDENTIFIER,23,27
 TOK NEBOC_TOKEN_IDENTIFIER,28,33
case7_token_count equ ($-case7_tokens)/NEBOC_TOKEN_SIZE
align 8
case7_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,33,2,0,1,0,0
 NODE NEBOC_AST_FUNCTION_DECL,0,0,33,3,0,3,0,1
 NODE NEBOC_AST_RECEIVER,0,4,12,0,4,0,1,2
 NODE NEBOC_AST_PARAMETER,0,13,22,0,5,0,3,4
 NODE NEBOC_AST_BLOCK,0,23,33,6,0,2,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,23,27,7,8,1,0,0
 NODE NEBOC_AST_IDENTIFIER_EXPR,0,23,27,0,0,0,5,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,28,33,9,0,1,0,0
 NODE NEBOC_AST_IDENTIFIER_EXPR,0,28,33,0,0,0,6,0
case7_node_count equ ($-case7_nodes)/NEBOC_AST_NODE_SIZE
case7_desc: dq case7_nodes,case7_node_count,case7_tokens,case7_token_count,case7_source,case7_source_len

align 8
arena_a_desc:
 dq builder_a,store_a,store_nodes_a,parents_a
 dq scope_table_a,scope_entries_a,symbol_table_a,symbol_entries_a
 dq node_symbols_a,node_scopes_a,request_a
arena_b_desc:
 dq builder_b,store_b,store_nodes_b,parents_b
 dq scope_table_b,scope_entries_b,symbol_table_b,symbol_entries_b
 dq node_symbols_b,node_scopes_b,request_b

section .bss align=16
builder_a: resb NEBOC_AST_BUILDER_SIZE
store_a: resb NEBOC_AST_STORE_SIZE
store_nodes_a: resb NEBOC_AST_NODE_SIZE*CAPACITY
parents_a: resq CAPACITY
scope_table_a: resb NEBOC_SCOPE_TABLE_SIZE
scope_entries_a: resb NEBOC_SCOPE_ENTRY_SIZE*CAPACITY
symbol_table_a: resb NEBOC_SYMBOL_TABLE_SIZE
symbol_entries_a: resb NEBOC_SYMBOL_ENTRY_SIZE*CAPACITY
node_symbols_a: resq CAPACITY
node_scopes_a: resq CAPACITY
request_a: resb NEBOC_NAME_REQUEST_SIZE

builder_b: resb NEBOC_AST_BUILDER_SIZE
store_b: resb NEBOC_AST_STORE_SIZE
store_nodes_b: resb NEBOC_AST_NODE_SIZE*CAPACITY
parents_b: resq CAPACITY
scope_table_b: resb NEBOC_SCOPE_TABLE_SIZE
scope_entries_b: resb NEBOC_SCOPE_ENTRY_SIZE*CAPACITY
symbol_table_b: resb NEBOC_SYMBOL_TABLE_SIZE
symbol_entries_b: resb NEBOC_SYMBOL_ENTRY_SIZE*CAPACITY
node_symbols_b: resq CAPACITY
node_scopes_b: resq CAPACITY
request_b: resb NEBOC_NAME_REQUEST_SIZE

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 movzx eax,byte [rdx]
 cmp byte [rdx+1],0
 jne test_usage
 cmp al,'1'
 je test_case1
 cmp al,'2'
 je test_case2
 cmp al,'3'
 je test_case3
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
 jmp test_usage

test_case1:
 lea rdi,[rel case1_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 test eax,eax
 jnz test_fail
 cmp qword [rel scope_table_a+NEBOC_SCOPE_TABLE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel symbol_table_a+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel node_symbols_a+24],1
 jne test_fail
 cmp qword [rel node_symbols_a+48],1
 jne test_fail
 jmp test_pass

test_case2:
 lea rdi,[rel case2_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_NAME_UNDEFINED
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],5
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_TOKEN_OFFSET],0
 jne test_fail
 jmp test_pass

test_case3:
 lea rdi,[rel case3_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_NAME_DUPLICATE
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],6
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_TOKEN_OFFSET],1
 jne test_fail
 jmp test_pass

test_case4:
 lea rdi,[rel case4_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_NAME_SHADOW
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],9
 jne test_fail
 cmp qword [rel scope_table_a+NEBOC_SCOPE_TABLE_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

test_case5:
 lea rdi,[rel case5_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 test eax,eax
 jnz test_fail
 cmp qword [rel symbol_table_a+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],2
 jne test_fail
 cmp qword [rel node_symbols_a+32],1
 jne test_fail
 cmp qword [rel node_symbols_a+48],1
 jne test_fail
 cmp qword [rel node_symbols_a+56],2
 jne test_fail
 jmp test_pass

test_case6:
 lea rdi,[rel case6_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_NAME_RESERVED
 jne test_fail
 cmp qword [rel request_a+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],4
 jne test_fail
 jmp test_pass

test_case7:
 lea rdi,[rel case7_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 test eax,eax
 jnz test_fail
 cmp qword [rel scope_table_a+NEBOC_SCOPE_TABLE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel symbol_table_a+NEBOC_SYMBOL_TABLE_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel node_symbols_a+8],1
 jne test_fail
 cmp qword [rel node_symbols_a+16],2
 jne test_fail
 cmp qword [rel node_symbols_a+24],3
 jne test_fail
 cmp qword [rel node_symbols_a+48],2
 jne test_fail
 cmp qword [rel node_symbols_a+64],3
 jne test_fail
 cmp qword [rel symbol_entries_a+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_FUNCTION
 jne test_fail
 cmp qword [rel symbol_entries_a+NEBOC_SYMBOL_ENTRY_SIZE+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_RECEIVER
 jne test_fail
 cmp qword [rel symbol_entries_a+NEBOC_SYMBOL_ENTRY_SIZE*2+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_PARAMETER
 jne test_fail
 jmp test_pass

test_case8:
 lea rdi,[rel case7_desc]
 lea rsi,[rel arena_a_desc]
 call resolve_case
 test eax,eax
 jnz test_fail
 lea rdi,[rel case7_desc]
 lea rsi,[rel arena_b_desc]
 call resolve_case
 test eax,eax
 jnz test_fail
 mov rax,[rel request_a+NEBOC_NAME_REQUEST_HASH_OFFSET]
 cmp rax,[rel request_b+NEBOC_NAME_REQUEST_HASH_OFFSET]
 jne test_fail
 mov rax,[rel scope_table_a+NEBOC_SCOPE_TABLE_COUNT_OFFSET]
 cmp rax,[rel scope_table_b+NEBOC_SCOPE_TABLE_COUNT_OFFSET]
 jne test_fail
 imul rcx,rax,NEBOC_SCOPE_ENTRY_QWORDS
 lea rsi,[rel scope_entries_a]
 lea rdi,[rel scope_entries_b]
 repe cmpsq
 jne test_fail
 mov rax,[rel symbol_table_a+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 cmp rax,[rel symbol_table_b+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 jne test_fail
 imul rcx,rax,NEBOC_SYMBOL_ENTRY_QWORDS
 lea rsi,[rel symbol_entries_a]
 lea rdi,[rel symbol_entries_b]
 repe cmpsq
 jne test_fail
 mov rcx,case7_node_count
 lea rsi,[rel node_symbols_a]
 lea rdi,[rel node_symbols_b]
 repe cmpsq
 jne test_fail
 mov rcx,case7_node_count
 lea rsi,[rel node_scopes_a]
 lea rdi,[rel node_scopes_b]
 repe cmpsq
 jne test_fail
 xor ebx,ebx
.id_loop:
 cmp rbx,3
 jae .map_loop_start
 mov rax,rbx
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 lea rdx,[rel symbol_entries_a]
 add rdx,rax
 mov rax,[rdx+NEBOC_SYMBOL_ENTRY_ID_OFFSET]
 lea rcx,[rbx+1]
 cmp rax,rcx
 jne test_fail
 cmp rax,3
 ja test_fail
 inc rbx
 jmp .id_loop
.map_loop_start:
 xor ebx,ebx
.map_loop:
 cmp rbx,case7_node_count
 jae test_pass
 lea rdx,[rel node_symbols_a]
 mov rax,[rdx+rbx*8]
 cmp rax,3
 ja test_fail
 inc rbx
 jmp .map_loop

test_pass:
 xor edi,edi
 jmp test_exit
test_fail:
 mov edi,1
 jmp test_exit
test_usage:
 mov edi,64
test_exit:
 call neboc_host_process_exit
 ud2

; resolve_case(case_descriptor*, arena_descriptor*) -> status
; Descriptor fields are pointers/counts only; all output storage is caller-backed.
resolve_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,[r13]
 mov rax,[r12]
 mov [r14+NEBOC_AST_BUILDER_DATA_OFFSET],rax
 mov rax,[r12+8]
 mov [r14+NEBOC_AST_BUILDER_COUNT_OFFSET],rax
 mov [r14+NEBOC_AST_BUILDER_CAPACITY_OFFSET],rax
 mov qword [r14+NEBOC_AST_BUILDER_FINALIZED_OFFSET],0
 mov rdi,[r13+8]
 mov rsi,r14
 mov rdx,[r13+16]
 mov rcx,[r13+24]
 mov r8d,CAPACITY
 mov r9d,1
 call neboc_ast_store_freeze
 test eax,eax
 jnz .resolve_case_done
 mov rdi,[r13+32]
 mov rsi,[r13+40]
 mov edx,CAPACITY
 call neboc_scope_table_init
 test eax,eax
 jnz .resolve_case_done
 mov rdi,[r13+48]
 mov rsi,[r13+56]
 mov edx,CAPACITY
 call neboc_symbol_table_init
 test eax,eax
 jnz .resolve_case_done
 mov r15,[r13+80]
 mov rdi,r15
 xor eax,eax
 mov ecx,NEBOC_NAME_REQUEST_SIZE/8
 rep stosq
 mov rax,[r13+8]
 mov [r15+NEBOC_NAME_REQUEST_AST_STORE_OFFSET],rax
 mov rax,[r12+16]
 mov [r15+NEBOC_NAME_REQUEST_TOKENS_OFFSET],rax
 mov rax,[r12+24]
 mov [r15+NEBOC_NAME_REQUEST_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+32]
 mov [r15+NEBOC_NAME_REQUEST_SOURCE_OFFSET],rax
 mov rax,[r12+40]
 mov [r15+NEBOC_NAME_REQUEST_SOURCE_LENGTH_OFFSET],rax
 mov rax,[r13+32]
 mov [r15+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET],rax
 mov rax,[r13+48]
 mov [r15+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET],rax
 mov rax,[r13+64]
 mov [r15+NEBOC_NAME_REQUEST_NODE_SYMBOLS_OFFSET],rax
 mov rax,[r13+72]
 mov [r15+NEBOC_NAME_REQUEST_NODE_SCOPES_OFFSET],rax
 mov qword [r15+NEBOC_NAME_REQUEST_NODE_CAPACITY_OFFSET],CAPACITY
 mov rdi,r15
 call neboc_name_resolve
.resolve_case_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
