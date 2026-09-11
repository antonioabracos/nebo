; Nebo Assembly — MF023 signatures, return inference, calls and call graph
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/function/function_table.inc"
%include "compiler/semantic/call/call_resolver.inc"

extern neboc_function_table_init
extern neboc_call_analyze
extern neboc_host_process_exit

%macro TOK 3
 dq NEBOC_TOKEN_IDENTIFIER,0,1,%1,%2,%3
%endmacro

%macro FUN 9
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9
%endmacro

%macro CALL 7
 dq %1,%2,%3,%4,%5,%6,%7
%endmacro

%define FUNCTION_CAPACITY 8
%define POSITIONAL_CAPACITY 16
%define NODE_CAPACITY 16
%define EDGE_CAPACITY 16

section .rodata
source: db 'g f f f f f f f f f f f'
source_len equ $-source
align 8
tokens:
 TOK 0,1,0
 TOK 2,3,0
 TOK 4,5,0
 TOK 6,7,0
 TOK 8,9,0
 TOK 10,11,0
 TOK 12,13,0
 TOK 14,15,0
 TOK 16,17,0
 TOK 18,19,0
 TOK 20,21,0
 TOK 22,23,0
token_count equ ($-tokens)/NEBOC_TOKEN_SIZE

align 8
empty_pool: dq 0

; Case 1 — one Int return infers Int.
case1_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,1,1,1,NEBOC_CALL_FUNCTION_FLAG_NONE
case1_returns: dq NEBOC_TYPE_ID_INT
case1_desc: dq case1_functions,1,empty_pool,0,case1_returns,1,empty_pool,0,empty_pool,0

; Case 2 — no return infers Void.
case2_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,0,2,1,NEBOC_CALL_FUNCTION_FLAG_MAY_FALLTHROUGH
case2_desc: dq case2_functions,1,empty_pool,0,empty_pool,0,empty_pool,0,empty_pool,0

; Case 3 — inconsistent return types are rejected.
case3_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,2,3,1,NEBOC_CALL_FUNCTION_FLAG_NONE
case3_returns: dq NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_TEXT
case3_desc: dq case3_functions,1,empty_pool,0,case3_returns,2,empty_pool,0,empty_pool,0

; Case 4 — binding a Void result is rejected.
case4_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,0,4,1,NEBOC_CALL_FUNCTION_FLAG_MAY_FALLTHROUGH
case4_calls:
 CALL 0,2,NEBOC_TYPE_ID_INT,0,0,5,NEBOC_CALL_FLAG_BIND_RESULT
case4_desc: dq case4_functions,1,empty_pool,0,empty_pool,0,case4_calls,1,empty_pool,0

; Case 5 — a two-function cycle is recursion and is rejected.
case5_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,1,1,1,NEBOC_CALL_FUNCTION_FLAG_NONE
 FUN 0,NEBOC_TYPE_ID_INT,0,0,1,1,2,2,NEBOC_CALL_FUNCTION_FLAG_NONE
case5_returns: dq NEBOC_TYPE_ID_INT,NEBOC_TYPE_ID_INT
case5_calls:
 CALL 1,0,NEBOC_TYPE_ID_INT,0,0,5,NEBOC_CALL_FLAG_NONE
 CALL 2,2,NEBOC_TYPE_ID_INT,0,0,6,NEBOC_CALL_FLAG_NONE
case5_desc: dq case5_functions,2,empty_pool,0,case5_returns,2,case5_calls,2,empty_pool,0

; Case 6 — overload is selected by name, receiver and positional types.
case6_functions:
 FUN 0,NEBOC_TYPE_ID_CONSOLE,0,0,0,0,1,1,NEBOC_CALL_FUNCTION_FLAG_MAY_FALLTHROUGH
 FUN 1,NEBOC_TYPE_ID_INT,0,1,0,1,2,2,NEBOC_CALL_FUNCTION_FLAG_NONE
 FUN 2,NEBOC_TYPE_ID_TEXT,1,1,1,1,3,3,NEBOC_CALL_FUNCTION_FLAG_NONE
case6_positionals: dq NEBOC_TYPE_ID_TEXT,NEBOC_TYPE_ID_INT
case6_returns: dq NEBOC_TYPE_ID_BOOL,NEBOC_TYPE_ID_TEXT
case6_calls:
 CALL 1,3,NEBOC_TYPE_ID_TEXT,0,1,7,NEBOC_CALL_FLAG_NONE
case6_args: dq NEBOC_TYPE_ID_INT
case6_desc: dq case6_functions,3,case6_positionals,2,case6_returns,2,case6_calls,1,case6_args,1

; Case 7 — name exists, but receiver type does not.
case7_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,0,0,1,1,1,NEBOC_CALL_FUNCTION_FLAG_NONE
case7_returns: dq NEBOC_TYPE_ID_INT
case7_calls:
 CALL 0,2,NEBOC_TYPE_ID_TEXT,0,0,4,NEBOC_CALL_FLAG_NONE
case7_desc: dq case7_functions,1,empty_pool,0,case7_returns,1,case7_calls,1,empty_pool,0

; Case 8 — receiver/name match but arity is wrong.
case8_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,1,0,1,1,1,NEBOC_CALL_FUNCTION_FLAG_NONE
case8_positionals: dq NEBOC_TYPE_ID_TEXT
case8_returns: dq NEBOC_TYPE_ID_INT
case8_calls:
 CALL 0,2,NEBOC_TYPE_ID_INT,0,0,4,NEBOC_CALL_FLAG_NONE
case8_desc: dq case8_functions,1,case8_positionals,1,case8_returns,1,case8_calls,1,empty_pool,0

; Case 9 — receiver/name/arity match but positional type is wrong.
case9_functions:
 FUN 1,NEBOC_TYPE_ID_INT,0,1,0,1,1,1,NEBOC_CALL_FUNCTION_FLAG_NONE
case9_positionals: dq NEBOC_TYPE_ID_TEXT
case9_returns: dq NEBOC_TYPE_ID_INT
case9_calls:
 CALL 0,2,NEBOC_TYPE_ID_INT,0,1,4,NEBOC_CALL_FLAG_NONE
case9_args: dq NEBOC_TYPE_ID_INT
case9_desc: dq case9_functions,1,case9_positionals,1,case9_returns,1,case9_calls,1,case9_args,1

section .bss align=16
function_table: resb NEBOC_FUNCTION_TABLE_SIZE
function_entries: resb NEBOC_FUNCTION_ENTRY_SIZE*FUNCTION_CAPACITY
function_positionals: resq POSITIONAL_CAPACITY
node_functions: resq NODE_CAPACITY
edges: resb NEBOC_CALL_EDGE_SIZE*EDGE_CAPACITY
indegrees: resq FUNCTION_CAPACITY
topo_order: resq FUNCTION_CAPACITY
request: resb NEBOC_CALL_REQUEST_SIZE

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne test_usage
 mov rdx,[rsp+16]
 cmp byte [rdx+1],0
 jne test_usage
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
 cmp al,'9'
 je test_case9
 jmp test_usage

test_case1:
 lea rdi,[rel case1_desc]
 call run_case
 test eax,eax
 jnz test_fail
 cmp qword [rel function_table+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel function_entries+NEBOC_FUNCTION_ENTRY_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_INT
 jne test_fail
 cmp qword [rel function_entries+NEBOC_FUNCTION_ENTRY_ID_OFFSET],1
 jne test_fail
 cmp qword [rel topo_order],1
 jne test_fail
 jmp test_pass

test_case2:
 lea rdi,[rel case2_desc]
 call run_case
 test eax,eax
 jnz test_fail
 cmp qword [rel function_entries+NEBOC_FUNCTION_ENTRY_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_VOID
 jne test_fail
 jmp test_pass

test_case3:
 lea rdi,[rel case3_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_INCONSISTENT_RETURN
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_RECORD_OFFSET],1
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_NODE_ID_OFFSET],3
 jne test_fail
 jmp test_pass

test_case4:
 lea rdi,[rel case4_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_TYPE_VOID_BINDING
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_RECORD_OFFSET],1
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_NODE_ID_OFFSET],5
 jne test_fail
 jmp test_pass

test_case5:
 lea rdi,[rel case5_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_CALL_RECURSION
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_NODE_ID_OFFSET],5
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET],2
 jne test_fail
 jmp test_pass

test_case6:
 lea rdi,[rel case6_desc]
 call run_case
 test eax,eax
 jnz test_fail
 cmp qword [rel function_table+NEBOC_FUNCTION_TABLE_COUNT_OFFSET],3
 jne test_fail
 cmp qword [rel function_entries+NEBOC_FUNCTION_ENTRY_SIZE*2+NEBOC_FUNCTION_ENTRY_RETURN_TYPE_OFFSET],NEBOC_TYPE_ID_TEXT
 jne test_fail
 cmp qword [rel node_functions+48],3
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_EDGE_COUNT_OFFSET],1
 jne test_fail
 cmp qword [rel edges+NEBOC_CALL_EDGE_CALLER_ID_OFFSET],1
 jne test_fail
 cmp qword [rel edges+NEBOC_CALL_EDGE_CALLEE_ID_OFFSET],3
 jne test_fail
 cmp qword [rel topo_order],1
 jne test_fail
 cmp qword [rel topo_order+8],2
 jne test_fail
 cmp qword [rel topo_order+16],3
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_HASH_OFFSET],0
 je test_fail
 jmp test_pass

test_case7:
 lea rdi,[rel case7_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_CALL_INVALID_RECEIVER
 jne test_fail
 jmp test_pass

test_case8:
 lea rdi,[rel case8_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_CALL_ARITY
 jne test_fail
 jmp test_pass

test_case9:
 lea rdi,[rel case9_desc]
 call run_case
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne test_fail
 cmp qword [rel request+NEBOC_CALL_REQUEST_ERROR_CODE_OFFSET],NEBOC_DIAG_CALL_ARGUMENT_TYPE
 jne test_fail
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

; run_case(descriptor*) -> status
; descriptor: functions,count,positionals,count,returns,count,calls,count,args,count
run_case:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 lea rdi,[rel function_table]
 lea rsi,[rel function_entries]
 mov edx,FUNCTION_CAPACITY
 lea rcx,[rel function_positionals]
 mov r8d,POSITIONAL_CAPACITY
 call neboc_function_table_init
 test eax,eax
 jnz .run_done
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,NEBOC_CALL_REQUEST_QWORDS
 rep stosq
 lea r13,[rel request]
 lea rax,[rel tokens]
 mov [r13+NEBOC_CALL_REQUEST_TOKENS_OFFSET],rax
 mov qword [r13+NEBOC_CALL_REQUEST_TOKEN_COUNT_OFFSET],token_count
 lea rax,[rel source]
 mov [r13+NEBOC_CALL_REQUEST_SOURCE_OFFSET],rax
 mov qword [r13+NEBOC_CALL_REQUEST_SOURCE_LENGTH_OFFSET],source_len
 lea rax,[rel function_table]
 mov [r13+NEBOC_CALL_REQUEST_FUNCTION_TABLE_OFFSET],rax
 mov rax,[r12]
 mov [r13+NEBOC_CALL_REQUEST_FUNCTION_INPUTS_OFFSET],rax
 mov rax,[r12+8]
 mov [r13+NEBOC_CALL_REQUEST_FUNCTION_COUNT_OFFSET],rax
 mov rax,[r12+16]
 mov [r13+NEBOC_CALL_REQUEST_POSITIONAL_TYPES_OFFSET],rax
 mov rax,[r12+24]
 mov [r13+NEBOC_CALL_REQUEST_POSITIONAL_TYPE_COUNT_OFFSET],rax
 mov rax,[r12+32]
 mov [r13+NEBOC_CALL_REQUEST_RETURN_TYPES_OFFSET],rax
 mov rax,[r12+40]
 mov [r13+NEBOC_CALL_REQUEST_RETURN_TYPE_COUNT_OFFSET],rax
 mov rax,[r12+48]
 mov [r13+NEBOC_CALL_REQUEST_CALL_INPUTS_OFFSET],rax
 mov rax,[r12+56]
 mov [r13+NEBOC_CALL_REQUEST_CALL_COUNT_OFFSET],rax
 mov rax,[r12+64]
 mov [r13+NEBOC_CALL_REQUEST_ARGUMENT_TYPES_OFFSET],rax
 mov rax,[r12+72]
 mov [r13+NEBOC_CALL_REQUEST_ARGUMENT_TYPE_COUNT_OFFSET],rax
 lea rax,[rel node_functions]
 mov [r13+NEBOC_CALL_REQUEST_NODE_FUNCTIONS_OFFSET],rax
 mov qword [r13+NEBOC_CALL_REQUEST_NODE_CAPACITY_OFFSET],NODE_CAPACITY
 lea rax,[rel edges]
 mov [r13+NEBOC_CALL_REQUEST_EDGES_OFFSET],rax
 mov qword [r13+NEBOC_CALL_REQUEST_EDGE_CAPACITY_OFFSET],EDGE_CAPACITY
 lea rax,[rel indegrees]
 mov [r13+NEBOC_CALL_REQUEST_INDEGREES_OFFSET],rax
 lea rax,[rel topo_order]
 mov [r13+NEBOC_CALL_REQUEST_TOPO_ORDER_OFFSET],rax
 mov qword [r13+NEBOC_CALL_REQUEST_SCRATCH_CAPACITY_OFFSET],FUNCTION_CAPACITY
 mov rdi,r13
 call neboc_call_analyze
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
