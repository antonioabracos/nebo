bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/foundation_float_semantic.inc"
extern neboc_foundation_float_recognize
extern neboc_host_process_exit

section .rodata
source: db 'FloatNumberfloat'
source_len equ $-source

section .bss align=16
request: resb NEBOC_FLOAT_SEM_REQUEST_SIZE
builder: resb NEBOC_AST_BUILDER_SIZE
nodes: resb NEBOC_AST_NODE_SIZE*8
tokens: resb NEBOC_TOKEN_SIZE*4
hash_a: resq 1

section .text
global _start
_start:
 mov rax,[rsp]
 cmp rax,2
 jne usage
 mov rsi,[rsp+16]
 movzx ecx,byte [rsi]
 sub ecx,'0'
 cmp ecx,1
 jb usage
 cmp ecx,8
 ja usage
 call reset_all
 cmp ecx,1
 je scenario1
 cmp ecx,2
 je scenario2
 cmp ecx,3
 je scenario3
 cmp ecx,4
 je scenario4
 cmp ecx,5
 je scenario5
 cmp ecx,6
 je scenario6
 cmp ecx,7
 je scenario7
 jmp scenario8
scenario1:
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 call run_ok_found
 jmp exit
scenario2:
 call token_float
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_CALL_EXPR
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE]
 mov qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],2
 call run_ok_found
 jmp exit
scenario3:
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_BINDING_TERMINAL
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE]
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],2
 call run_ok_found
 jmp exit
scenario4:
 call token_float
 mov edi,1
 mov esi,NEBOC_AST_INTEGER_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_CALL_EXPR
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE]
 mov qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],2
 call run_invalid_constructor
 jmp exit
scenario5:
 call token_number
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_CALL_EXPR
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE]
 mov qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],1
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],2
 call run_mixed
 jmp exit
scenario6:
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 lea rax,[rel nodes]
 mov qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],2
 mov edi,3
 mov esi,NEBOC_AST_BINARY_EXPR
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE*2]
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_PLUS
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],3
 call run_ok_found
 jmp exit
scenario7:
 call token_lower_float
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov edi,2
 mov esi,NEBOC_AST_CALL_EXPR
 call set_node
 lea rax,[rel nodes+NEBOC_AST_NODE_SIZE]
 mov qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 mov qword [rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],2
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],2
 call run_mixed
 jmp exit
scenario8:
 mov edi,1
 mov esi,NEBOC_AST_FLOAT_LITERAL
 call set_node
 mov qword [rel builder+NEBOC_AST_BUILDER_COUNT_OFFSET],1
 call run_request
 test eax,eax
 jnz exit
 mov rax,[rel request+NEBOC_FLOAT_SEM_HASH_OFFSET]
 mov [rel hash_a],rax
 call run_request
 test eax,eax
 jnz exit
 mov rax,[rel hash_a]
 cmp rax,[rel request+NEBOC_FLOAT_SEM_HASH_OFFSET]
 jne fail
 xor eax,eax
 jmp exit

reset_all:
 push rcx
 lea rdi,[rel request]
 mov ecx,NEBOC_FLOAT_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel nodes]
 mov ecx,(NEBOC_AST_NODE_SIZE*8)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel tokens]
 mov ecx,(NEBOC_TOKEN_SIZE*4)/8
 xor eax,eax
 rep stosq
 lea rax,[rel nodes]
 mov [rel builder+NEBOC_AST_BUILDER_DATA_OFFSET],rax
 mov qword [rel builder+NEBOC_AST_BUILDER_CAPACITY_OFFSET],8
 pop rcx
 ret
set_node:
 mov eax,edi
 dec eax
 imul rax,NEBOC_AST_NODE_SIZE
 lea rdx,[rel nodes]
 add rax,rdx
 mov [rax+NEBOC_AST_NODE_KIND_OFFSET],rsi
 mov qword [rax+NEBOC_AST_NODE_SOURCE_ID_OFFSET],1
 mov qword [rax+NEBOC_AST_NODE_END_OFFSET],1
 ret
token_float:
 lea rax,[rel tokens]
 mov qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 mov qword [rax+NEBOC_TOKEN_START_OFFSET],0
 mov qword [rax+NEBOC_TOKEN_END_OFFSET],5
 ret
token_number:
 lea rax,[rel tokens+NEBOC_TOKEN_SIZE]
 mov qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 mov qword [rax+NEBOC_TOKEN_START_OFFSET],5
 mov qword [rax+NEBOC_TOKEN_END_OFFSET],11
 ret
token_lower_float:
 lea rax,[rel tokens+NEBOC_TOKEN_SIZE*2]
 mov qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 mov qword [rax+NEBOC_TOKEN_START_OFFSET],11
 mov qword [rax+NEBOC_TOKEN_END_OFFSET],16
 ret
run_request:
 sub rsp,8
 lea rax,[rel source]
 mov [rel request+NEBOC_FLOAT_SEM_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_FLOAT_SEM_SOURCE_LENGTH_OFFSET],source_len
 lea rax,[rel tokens]
 mov [rel request+NEBOC_FLOAT_SEM_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_FLOAT_SEM_TOKEN_COUNT_OFFSET],3
 lea rax,[rel builder]
 mov [rel request+NEBOC_FLOAT_SEM_BUILDER_OFFSET],rax
 mov qword [rel request+NEBOC_FLOAT_SEM_ROOT_ID_OFFSET],1
 lea rdi,[rel request]
 call neboc_foundation_float_recognize
 add rsp,8
 ret
run_ok_found:
 sub rsp,8
 call run_request
 add rsp,8
 test eax,eax
 jnz exit
 cmp qword [rel request+NEBOC_FLOAT_SEM_FOUND_OFFSET],1
 jne fail
 xor eax,eax
 ret
run_invalid_constructor:
 sub rsp,8
 call run_request
 add rsp,8
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_INVALID_CONSTRUCTOR
 jne fail
 xor eax,eax
 ret
run_unsupported:
 sub rsp,8
 call run_request
 add rsp,8
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_CONTEXT
 jne fail
 xor eax,eax
 ret
run_mixed:
 sub rsp,8
 call run_request
 add rsp,8
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel request+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_MIXED_NUMERIC_TYPES
 jne fail
 xor eax,eax
 ret
usage:
 mov eax,2
 jmp exit
fail:
 mov eax,1
exit:
 mov edi,eax
 call neboc_host_process_exit
 ud2
section .note.GNU-stack noalloc noexec nowrite progbits
