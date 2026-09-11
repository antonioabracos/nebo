; ALIASES-UNICODE-MATEMATICOS-EXATOS native exact-alias conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/unicode_alias_contract.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/semantic/operators/unicode_alias_registry.inc"

extern neboc_lexer_scan
extern neboc_unicode_arithmetic_alias_match
extern neboc_unicode_alias_provenance
extern neboc_unicode_alias_registry_table
extern neboc_unicode_alias_registry_resolve

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .rodata
source:
 db '- ',0xe2,0x88,0x92,' / ',0xc3,0xb7,' <= ',0xe2,0x89,0xa4
 db ' >= ',0xe2,0x89,0xa5,' != ',0xe2,0x89,0xa0
 db ' && ',0xe2,0x88,0xa7,' || ',0xe2,0x88,0xa8
 db ' ! ',0xc2,0xac,' xor ',0xe2,0x8a,0xbb
source_len equ $-source
minus_alias: db 0xe2,0x88,0x92
percent_source: db '50%'
percent_source_len equ $-percent_source
expected_kinds:
 dq NEBOC_TOKEN_MINUS,NEBOC_TOKEN_SLASH,NEBOC_TOKEN_LESS_EQUAL
 dq NEBOC_TOKEN_GREATER_EQUAL,NEBOC_TOKEN_BANG_EQUAL
 dq NEBOC_TOKEN_AND_AND,NEBOC_TOKEN_OR_OR,NEBOC_TOKEN_BANG,NEBOC_TOKEN_XOR
expected_ids:
 dq NEBOC_UNICODE_ALIAS_MINUS_ID,NEBOC_UNICODE_ALIAS_DIVIDE_ID
 dq NEBOC_UNICODE_ALIAS_LESS_EQUAL_ID,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_ID
 dq NEBOC_UNICODE_ALIAS_NOT_EQUAL_ID,NEBOC_UNICODE_ALIAS_AND_ID
 dq NEBOC_UNICODE_ALIAS_OR_ID,NEBOC_UNICODE_ALIAS_NOT_ID,NEBOC_UNICODE_ALIAS_XOR_ID
expected_codepoints:
 dq NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT,NEBOC_UNICODE_ALIAS_DIVIDE_CODEPOINT
 dq NEBOC_UNICODE_ALIAS_LESS_EQUAL_CODEPOINT,NEBOC_UNICODE_ALIAS_GREATER_EQUAL_CODEPOINT
 dq NEBOC_UNICODE_ALIAS_NOT_EQUAL_CODEPOINT,NEBOC_UNICODE_ALIAS_AND_CODEPOINT
 dq NEBOC_UNICODE_ALIAS_OR_CODEPOINT,NEBOC_UNICODE_ALIAS_NOT_CODEPOINT,NEBOC_UNICODE_ALIAS_XOR_CODEPOINT
expected_prefix_core:
 dq NEBOC_OPERATOR_ID_NSR_CORE_019,0,0,0,0,0,0,NEBOC_OPERATOR_ID_NSR_CORE_020,0
expected_infix_core:
 dq NEBOC_OPERATOR_ID_NSR_CORE_013,NEBOC_OPERATOR_ID_NSR_CORE_015
 dq NEBOC_OPERATOR_ID_NSR_CORE_025,NEBOC_OPERATOR_ID_NSR_CORE_027
 dq NEBOC_OPERATOR_ID_NSR_CORE_029,NEBOC_OPERATOR_ID_NSR_CORE_021
 dq NEBOC_OPERATOR_ID_NSR_CORE_022,0,NEBOC_OPERATOR_ID_NSR_CORE_023

section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*24
result: resb NEBOC_UNICODE_ALIAS_RESULT_SIZE
provenance: resb NEBOC_UNICODE_PROVENANCE_SIZE

section .text
global _start
_start:
 mov ebx,1
 call neboc_unicode_alias_registry_table
 cmp edx,NEBOC_UNICODE_ALIAS_REGISTRY_ENTRY_COUNT
 jne fail
 cmp ecx,NEBOC_UNICODE_ALIAS_REGISTRY_SCHEMA_VERSION
 jne fail
 mov r13,rax
 xor r12d,r12d
.registry_loop:
 cmp r12d,NEBOC_UNICODE_ALIAS_REGISTRY_ENTRY_COUNT
 jae .registry_done
 mov rax,r12
 imul rax,NEBOC_UNICODE_ALIAS_ENTRY_SIZE
 lea r8,[r13+rax]
 lea r9,[rel expected_ids]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_UNICODE_ALIAS_ENTRY_ID_OFFSET],r10
 jne fail
 cmp qword [r8+NEBOC_UNICODE_ALIAS_ENTRY_CLASS_OFFSET],NEBOC_OPERATOR_CLASS_UNICODE_ALIAS
 jne fail
 cmp qword [r8+NEBOC_UNICODE_ALIAS_ENTRY_STATE_OFFSET],NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
 jne fail
 lea r9,[rel expected_codepoints]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_UNICODE_ALIAS_ENTRY_CODEPOINT_OFFSET],r10
 jne fail
 lea r9,[rel expected_kinds]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_UNICODE_ALIAS_ENTRY_TOKEN_OFFSET],r10
 jne fail
 lea r9,[rel expected_prefix_core]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_UNICODE_ALIAS_ENTRY_PREFIX_CORE_ID_OFFSET],r10
 jne fail
 lea r9,[rel expected_infix_core]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_UNICODE_ALIAS_ENTRY_INFIX_CORE_ID_OFFSET],r10
 jne fail
 mov r10,[r8+NEBOC_UNICODE_ALIAS_ENTRY_FLAGS_OFFSET]
 and r10,NEBOC_UNICODE_ALIAS_REQUIRED_FLAGS
 cmp r10,NEBOC_UNICODE_ALIAS_REQUIRED_FLAGS
 jne fail
 inc r12d
 jmp .registry_loop
.registry_done:

 mov ebx,2
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],source_len
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],125
 mov qword [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],tokens
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],24
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],19
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail

 mov ebx,3
 xor r12d,r12d
.pair_loop:
 cmp r12d,9
 jae .pairs_done
 mov rax,r12
 shl rax,1
 imul rax,NEBOC_TOKEN_SIZE
 lea r8,[rel tokens]
 add r8,rax
 lea r9,[rel expected_kinds]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_TOKEN_KIND_OFFSET],r10
 jne fail
 test qword [r8+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jnz fail
 cmp qword [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],0
 jne fail
 add r8,NEBOC_TOKEN_SIZE
 cmp [r8+NEBOC_TOKEN_KIND_OFFSET],r10
 jne fail
 test qword [r8+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jz fail
 lea r9,[rel expected_ids]
 mov r10,[r9+r12*8]
 cmp [r8+NEBOC_TOKEN_PAYLOAD_OFFSET],r10
 jne fail
 inc r12d
 jmp .pair_loop
.pairs_done:

 mov ebx,4
 lea rdi,[rel minus_alias]
 mov esi,3
 lea rdx,[rel result]
 call neboc_unicode_arithmetic_alias_match
 test eax,eax
 jnz fail
 cmp qword [rel result+NEBOC_UNICODE_ALIAS_RESULT_TOKEN_OFFSET],NEBOC_TOKEN_MINUS
 jne fail
 cmp qword [rel result+NEBOC_UNICODE_ALIAS_RESULT_REGISTRY_ID_OFFSET],NEBOC_UNICODE_ALIAS_MINUS_ID
 jne fail

 mov ebx,5
 mov rax,SENTINEL
 mov [rel result],rax
 lea rdi,[rel minus_alias]
 mov esi,2
 lea rdx,[rel result]
 call neboc_unicode_arithmetic_alias_match
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel result],rax
 jne fail

 mov ebx,6
 mov edi,NEBOC_TOKEN_MINUS
 mov esi,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 mov edx,10
 mov ecx,13
 lea r8,[rel provenance]
 call neboc_unicode_alias_provenance
 test eax,eax
 jnz fail
 cmp qword [rel provenance+NEBOC_UNICODE_PROVENANCE_TOKEN_OFFSET],NEBOC_TOKEN_MINUS
 jne fail
 cmp qword [rel provenance+NEBOC_UNICODE_PROVENANCE_SOURCE_START_OFFSET],10
 jne fail
 cmp qword [rel provenance+NEBOC_UNICODE_PROVENANCE_SOURCE_END_OFFSET],13
 jne fail

 mov ebx,7
 mov edi,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 mov esi,NEBOC_TOKEN_MINUS
 mov edx,NEBOC_OPERATOR_FIXITY_PREFIX
 call neboc_unicode_alias_registry_resolve
 test rax,rax
 jz fail
 cmp edx,NEBOC_UNICODE_ALIAS_MINUS_ID
 jne fail
 cmp ecx,NEBOC_OPERATOR_ID_NSR_CORE_019
 jne fail
 mov edi,NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 mov esi,NEBOC_TOKEN_MINUS
 mov edx,NEBOC_OPERATOR_FIXITY_INFIX
 call neboc_unicode_alias_registry_resolve
 test rax,rax
 jz fail
 cmp edx,NEBOC_UNICODE_ALIAS_MINUS_ID
 jne fail
 cmp ecx,NEBOC_OPERATOR_ID_NSR_CORE_013
 jne fail

 mov ebx,8
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],percent_source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],percent_source_len
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],3
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_PERCENT
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
