; Nebo Assembly — MF022 fundamental types, operators and checked constants
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/symbol/symbol_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/types/type_checker.inc"

extern neboc_ast_store_freeze
extern neboc_symbol_table_init
extern neboc_symbol_table_freeze
extern neboc_type_table_init
extern neboc_type_table_declare_builtins
extern neboc_type_table_freeze
extern neboc_type_check
extern neboc_operator_binary_type
extern neboc_host_process_exit

%macro TOK 4
 dq %1,0,1,%2,%3,%4
%endmacro

%macro NODE 9
 dq %1,%2,1,%3,%4,%5,%6,%7,%8,%9
%endmacro

%define CAPACITY 32

section .rodata
align 8
dummy_source: db 'x'
dummy_source_len equ $-dummy_source
dummy_tokens:
 TOK NEBOC_TOKEN_EOF,0,0,0
dummy_token_count equ ($-dummy_tokens)/NEBOC_TOKEN_SIZE

call_source: db 'console scan'
call_source_len equ $-call_source
align 8
call_tokens:
 TOK NEBOC_TOKEN_IDENTIFIER,0,7,0
 TOK NEBOC_TOKEN_IDENTIFIER,8,12,0
call_token_count equ ($-call_tokens)/NEBOC_TOKEN_SIZE

; descriptor: nodes,count,tokens,count,source,len,status,node,type,error,constflag,const
align 8
case1_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,9223372036854775807,0
case1_count equ ($-case1_nodes)/NEBOC_AST_NODE_SIZE
case1_desc: dq case1_nodes,case1_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,0,5,NEBOC_TYPE_ID_INT,0,1,9223372036854775807

align 8
case2_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_IF_STMT,0,0,1,5,0,2,0,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,6,0,1,0
 NODE NEBOC_AST_BLOCK,0,0,1,0,0,0,0,0
case2_count equ ($-case2_nodes)/NEBOC_AST_NODE_SIZE
case2_desc: dq case2_nodes,case2_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,NEBOC_STATUS_INVALID_SOURCE,4,0,NEBOC_DIAG_TYPE_TRUTHINESS,0,0

align 8
case3_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_TEXT_LITERAL,0,0,1,0,0,0,0,0
case3_count equ ($-case3_nodes)/NEBOC_AST_NODE_SIZE
case3_desc: dq case3_nodes,case3_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,0,5,NEBOC_TYPE_ID_TEXT,0,0,0

align 8
case4_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,12,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,12,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,12,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,12,5,0,1,0,0
 NODE NEBOC_AST_CALL_EXPR,0,0,12,6,0,1,0,0
 NODE NEBOC_AST_TEXT_LITERAL,0,0,1,0,0,0,0,0
case4_count equ ($-case4_nodes)/NEBOC_AST_NODE_SIZE
case4_desc: dq case4_nodes,case4_count,call_tokens,call_token_count,call_source,call_source_len,0,5,NEBOC_TYPE_ID_CONSOLE,0,0,0

align 8
case5_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,12,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,12,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,12,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,12,5,0,1,0,0
 NODE NEBOC_AST_CALL_EXPR,0,0,12,6,0,1,1,0
 NODE NEBOC_AST_TEXT_LITERAL,0,0,1,0,0,0,0,0
case5_count equ ($-case5_nodes)/NEBOC_AST_NODE_SIZE
case5_desc: dq case5_nodes,case5_count,call_tokens,call_token_count,call_source,call_source_len,0,5,NEBOC_TYPE_ID_PENDING_TEXT,0,0,0

align 8
case6_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_BINARY_EXPR,0,0,1,6,0,2,NEBOC_TOKEN_AND_AND,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,7,0,1,0
 NODE NEBOC_AST_BOOL_LITERAL,0,0,1,0,0,0,1,0
case6_count equ ($-case6_nodes)/NEBOC_AST_NODE_SIZE
case6_desc: dq case6_nodes,case6_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,NEBOC_STATUS_INVALID_SOURCE,5,0,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR,0,0

align 8
case7_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_BINARY_EXPR,0,0,1,6,0,2,NEBOC_TOKEN_PLUS,0
 NODE NEBOC_AST_BOOL_LITERAL,0,0,1,0,7,0,1,0
 NODE NEBOC_AST_BOOL_LITERAL,0,0,1,0,0,0,0,0
case7_count equ ($-case7_nodes)/NEBOC_AST_NODE_SIZE
case7_desc: dq case7_nodes,case7_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,NEBOC_STATUS_INVALID_SOURCE,5,0,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR,0,0

align 8
case8_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_BINARY_EXPR,0,0,1,6,0,2,NEBOC_TOKEN_PLUS,0
 NODE NEBOC_AST_TEXT_LITERAL,0,0,1,0,7,0,0,0
 NODE NEBOC_AST_TEXT_LITERAL,0,0,1,0,0,0,0,0
case8_count equ ($-case8_nodes)/NEBOC_AST_NODE_SIZE
case8_desc: dq case8_nodes,case8_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,NEBOC_STATUS_INVALID_SOURCE,5,0,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR,0,0

align 8
case14_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_BINARY_EXPR,0,0,1,6,0,2,NEBOC_TOKEN_PLUS,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,7,0,9223372036854775807,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,1,0
case14_count equ ($-case14_nodes)/NEBOC_AST_NODE_SIZE
case14_desc: dq case14_nodes,case14_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,NEBOC_STATUS_INVALID_SOURCE,5,0,NEBOC_DIAG_TYPE_CONSTANT_OVERFLOW,0,0

align 8
case15_nodes:
 NODE NEBOC_AST_PROGRAM,0,0,1,2,0,1,0,0
 NODE NEBOC_AST_START_DECL,0,0,1,3,0,1,0,0
 NODE NEBOC_AST_BLOCK,0,0,1,4,0,1,0,0
 NODE NEBOC_AST_EXPRESSION_STMT,0,0,1,5,0,1,0,0
 NODE NEBOC_AST_BINARY_EXPR,0,0,1,6,0,2,NEBOC_TOKEN_SLASH,0
 NODE NEBOC_AST_UNARY_EXPR,0,0,1,7,8,1,NEBOC_TOKEN_MINUS,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,7,0
 NODE NEBOC_AST_INTEGER_LITERAL,0,0,1,0,0,0,2,0
case15_count equ ($-case15_nodes)/NEBOC_AST_NODE_SIZE
case15_desc: dq case15_nodes,case15_count,dummy_tokens,dummy_token_count,dummy_source,dummy_source_len,0,5,NEBOC_TYPE_ID_INT,0,1,-3

section .bss align=16
builder: resb NEBOC_AST_BUILDER_SIZE
store: resb NEBOC_AST_STORE_SIZE
store_nodes: resb NEBOC_AST_NODE_SIZE*CAPACITY
parents: resq CAPACITY
symbol_table: resb NEBOC_SYMBOL_TABLE_SIZE
symbol_entries: resb NEBOC_SYMBOL_ENTRY_SIZE*CAPACITY
type_table: resb NEBOC_TYPE_TABLE_SIZE
type_entries: resb NEBOC_TYPE_ENTRY_SIZE*NEBOC_TYPE_BUILTIN_COUNT
node_symbols: resq CAPACITY
symbol_types: resq CAPACITY
node_types: resq CAPACITY
node_constants: resq CAPACITY
node_constant_flags: resq CAPACITY
request: resb NEBOC_TYPE_REQUEST_SIZE
operator_result: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 cmp byte [rdx+1],0
 je .one_digit
 cmp byte [rdx+2],0
 jne test_usage
 cmp byte [rdx],'1'
 jne test_usage
 cmp byte [rdx+1],'4'
 je test_case14
 cmp byte [rdx+1],'5'
 je test_case15
 jmp test_usage
.one_digit:
 movzx eax,byte [rdx]
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

test_case1: lea rdi,[rel case1_desc]
 call run_case
 test eax,eax
 jnz test_fail
 ; Built-in ordering and Pending<Text> base descriptor are contractual.
 cmp qword [rel type_table+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUILTIN_COUNT
 jne test_fail
 cmp qword [rel type_entries+NEBOC_TYPE_ENTRY_ID_OFFSET],NEBOC_TYPE_ID_VOID
 jne test_fail
 cmp qword [rel type_entries+NEBOC_TYPE_ENTRY_SIZE*5+NEBOC_TYPE_ENTRY_BASE_TYPE_ID_OFFSET],NEBOC_TYPE_ID_TEXT
 jne test_fail
 jmp test_pass

test_case2: lea rdi,[rel case2_desc]
 jmp test_run
test_case3:
 lea rdi,[rel case3_desc]
 call run_case
 test eax,eax
 jnz test_fail
 mov rdi,NEBOC_TOKEN_EQUAL_EQUAL
 mov rsi,NEBOC_TYPE_ID_TEXT
 mov rdx,NEBOC_TYPE_ID_TEXT
 lea rcx,[rel operator_result]
 call neboc_operator_binary_type
 test eax,eax
 jnz test_fail
 cmp qword [rel operator_result],NEBOC_TYPE_ID_BOOL
 jne test_fail
 jmp test_pass
test_case4: lea rdi,[rel case4_desc]
 jmp test_run
test_case5: lea rdi,[rel case5_desc]
 jmp test_run
test_case6: lea rdi,[rel case6_desc]
 jmp test_run
test_case7: lea rdi,[rel case7_desc]
 jmp test_run
test_case8: lea rdi,[rel case8_desc]
 jmp test_run
test_case14: lea rdi,[rel case14_desc]
 jmp test_run
test_case15: lea rdi,[rel case15_desc]
test_run:
 call run_case
 test eax,eax
 jnz test_fail
 jmp test_pass

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

; run_case(descriptor*) -> 0 when actual state matches descriptor.
run_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 ; Freeze caller-provided AST into stable storage.
 lea r14,[rel builder]
 mov rax,[r12]
 mov [r14+NEBOC_AST_BUILDER_DATA_OFFSET],rax
 mov rax,[r12+8]
 mov [r14+NEBOC_AST_BUILDER_COUNT_OFFSET],rax
 mov [r14+NEBOC_AST_BUILDER_CAPACITY_OFFSET],rax
 mov qword [r14+NEBOC_AST_BUILDER_FINALIZED_OFFSET],0
 lea rdi,[rel store]
 mov rsi,r14
 lea rdx,[rel store_nodes]
 lea rcx,[rel parents]
 mov r8d,CAPACITY
 mov r9d,1
 call neboc_ast_store_freeze
 test eax,eax
 jnz .run_fail
 ; Empty frozen SymbolTable is sufficient for literal/operator cases.
 lea rdi,[rel symbol_table]
 lea rsi,[rel symbol_entries]
 mov edx,CAPACITY
 call neboc_symbol_table_init
 test eax,eax
 jnz .run_fail
 lea rdi,[rel symbol_table]
 call neboc_symbol_table_freeze
 test eax,eax
 jnz .run_fail
 ; Declare immutable built-in types.
 lea rdi,[rel type_table]
 lea rsi,[rel type_entries]
 mov edx,NEBOC_TYPE_BUILTIN_COUNT
 call neboc_type_table_init
 test eax,eax
 jnz .run_fail
 lea rdi,[rel type_table]
 call neboc_type_table_declare_builtins
 test eax,eax
 jnz .run_fail
 lea rdi,[rel type_table]
 call neboc_type_table_freeze
 test eax,eax
 jnz .run_fail
 ; Build request.
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,NEBOC_TYPE_REQUEST_SIZE/8
 rep stosq
 lea r13,[rel request]
 lea rax,[rel store]
 mov [r13+NEBOC_TYPE_REQUEST_AST_STORE_OFFSET],rax
 mov rax,[r12+16]
 mov [r13+NEBOC_TYPE_REQUEST_TOKENS_OFFSET],rax
 mov rax,[r12+24]
 mov [r13+NEBOC_TYPE_REQUEST_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+32]
 mov [r13+NEBOC_TYPE_REQUEST_SOURCE_OFFSET],rax
 mov rax,[r12+40]
 mov [r13+NEBOC_TYPE_REQUEST_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel type_table]
 mov [r13+NEBOC_TYPE_REQUEST_TYPE_TABLE_OFFSET],rax
 lea rax,[rel symbol_table]
 mov [r13+NEBOC_TYPE_REQUEST_SYMBOL_TABLE_OFFSET],rax
 lea rax,[rel node_symbols]
 mov [r13+NEBOC_TYPE_REQUEST_NODE_SYMBOLS_OFFSET],rax
 lea rax,[rel symbol_types]
 mov [r13+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET],rax
 mov qword [r13+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET],CAPACITY
 lea rax,[rel node_types]
 mov [r13+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET],rax
 lea rax,[rel node_constants]
 mov [r13+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET],rax
 lea rax,[rel node_constant_flags]
 mov [r13+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET],rax
 mov qword [r13+NEBOC_TYPE_REQUEST_NODE_CAPACITY_OFFSET],CAPACITY
 mov rdi,r13
 call neboc_type_check
 cmp rax,[r12+48]
 jne .run_fail
 cmp qword [r12+48],0
 jne .check_error
 mov rbx,[r12+56]
 test rbx,rbx
 jz .run_fail
 lea rax,[rel node_types]
 dec rbx
 mov rdx,[rax+rbx*8]
 cmp rdx,[r12+64]
 jne .run_fail
 mov rdx,[r12+80]
 test rdx,rdx
 jz .run_ok
 lea rax,[rel node_constant_flags]
 cmp qword [rax+rbx*8],NEBOC_TYPE_CONSTANT_VALID
 jne .run_fail
 lea rax,[rel node_constants]
 mov rdx,[rax+rbx*8]
 cmp rdx,[r12+88]
 jne .run_fail
 jmp .run_ok
.check_error:
 mov rax,[r13+NEBOC_TYPE_REQUEST_ERROR_CODE_OFFSET]
 cmp rax,[r12+72]
 jne .run_fail
 mov rax,[r13+NEBOC_TYPE_REQUEST_ERROR_NODE_ID_OFFSET]
 cmp rax,[r12+56]
 jne .run_fail
.run_ok:
 xor eax,eax
 jmp .run_done
.run_fail:
 mov eax,1
.run_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
