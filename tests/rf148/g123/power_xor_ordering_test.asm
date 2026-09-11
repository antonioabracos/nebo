; POTENCIA-XOR-E-COMPARACAO-TOTAL native syntax/semantic conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/operator_protocol.inc"
%include "compiler/semantic/operators/core_power_xor_ordering_registry.inc"

extern neboc_lexer_scan
extern neboc_core_checked_power
extern neboc_core_power_float_int
extern neboc_core_bool_xor
extern neboc_core_int_xor
extern neboc_core_bytes_xor
extern neboc_core_ordering_type
extern neboc_core_ordering_int
extern neboc_core_ordering_bytes
extern neboc_core_comparison_from_ordering
extern neboc_core_bool_logic
extern neboc_operator_precedence_lookup
extern neboc_core_pxo_registry_table
extern neboc_core_pxo_registry_lookup
extern neboc_core_pxo_registry_resolve

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .rodata
source: db '2 ^ 3 xor true <=> false ',0xe2,0x8a,0xbb,' 1'
source_len equ $-source
left_bytes: db 0x0f,0xf0,0x55
right_bytes: db 0x33,0x0f,0xaa
expected_bytes: db 0x3c,0xff,0xff

section .bss align=16
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*16
out_value: resq 1
out_bytes: resb 3

section .text
global _start
_start:
 mov ebx,1
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],source_len
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],1
 mov qword [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],tokens
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],16
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],10
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*1+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_CARET
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*3+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_XOR
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*5+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SPACESHIP
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*7+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_XOR
 jne fail

 mov ebx,21
 call neboc_core_pxo_registry_table
 cmp edx,NEBOC_CORE_PXO_REGISTRY_ENTRY_COUNT
 jne fail
 cmp ecx,NEBOC_CORE_PXO_REGISTRY_SCHEMA_VERSION
 jne fail
 mov r8,rax
 xor r9d,r9d
.registry_rows:
 cmp r9d,NEBOC_CORE_PXO_REGISTRY_ENTRY_COUNT
 jae .registry_lookup
 cmp qword [r8+NEBOC_CORE_PXO_ENTRY_STATE_OFFSET],NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
 jne fail
 cmp r9d,0
 jne .registry_tail_id
 cmp qword [r8+NEBOC_CORE_PXO_ENTRY_ID_OFFSET],NEBOC_OPERATOR_ID_NSR_CORE_017
 jne fail
 jmp .registry_next
.registry_tail_id:
 mov rax,r9
 add rax,19
 cmp [r8+NEBOC_CORE_PXO_ENTRY_ID_OFFSET],rax
 jne fail
.registry_next:
 add r8,NEBOC_CORE_PXO_ENTRY_SIZE
 inc r9d
 jmp .registry_rows
.registry_lookup:
 mov edi,NEBOC_OPERATOR_ID_NSR_CORE_023
 call neboc_core_pxo_registry_lookup
 test rax,rax
 jz fail
 cmp qword [rax+NEBOC_CORE_PXO_ENTRY_TOKEN_OFFSET],NEBOC_TOKEN_XOR
 jne fail
 test qword [rax+NEBOC_CORE_PXO_ENTRY_FLAGS_OFFSET],NEBOC_CORE_PXO_FLAG_EXACT_TYPES
 jz fail
 mov edi,NEBOC_TOKEN_SPACESHIP
 mov esi,NEBOC_OPERATOR_FIXITY_INFIX
 mov edx,NEBOC_OPERATOR_CONTEXT_EXPRESSION
 call neboc_core_pxo_registry_resolve
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_ID_NSR_CORE_030
 jne fail
 mov edi,NEBOC_TOKEN_SPACESHIP
 mov esi,NEBOC_OPERATOR_FIXITY_PREFIX
 mov edx,NEBOC_OPERATOR_CONTEXT_EXPRESSION
 call neboc_core_pxo_registry_resolve
 test rax,rax
 jnz fail
 test edx,edx
 jnz fail

 mov ebx,2
 mov edi,NEBOC_TOKEN_CARET
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_POWER
 jne fail
 cmp ecx,NEBOC_OPERATOR_BP_POWER
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 jne fail

 mov ebx,31
 mov edi,2
 mov esi,10
 lea rdx,[rel out_value]
 call neboc_core_checked_power
 test eax,eax
 jnz fail
 cmp qword [rel out_value],1024
 jne fail
 mov ebx,32
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov edi,2
 mov rsi,-1
 lea rdx,[rel out_value]
 call neboc_core_checked_power
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail

 mov ebx,4
 mov rdi,0x4000000000000000
 mov rsi,-3
 lea rdx,[rel out_value]
 call neboc_core_power_float_int
 test eax,eax
 jnz fail
 mov rax,0x3fc0000000000000
 cmp [rel out_value],rax
 jne fail

 mov ebx,5
 mov edi,1
 xor esi,esi
 lea rdx,[rel out_value]
 call neboc_core_bool_xor
 test eax,eax
 jnz fail
 cmp qword [rel out_value],1
 jne fail
 mov rdi,0x55aa
 mov rsi,0x0ff0
 lea rdx,[rel out_value]
 call neboc_core_int_xor
 test eax,eax
 jnz fail
 cmp qword [rel out_value],0x5a5a
 jne fail
 lea rdi,[rel left_bytes]
 lea rsi,[rel right_bytes]
 mov edx,3
 lea rcx,[rel out_bytes]
 call neboc_core_bytes_xor
 test eax,eax
 jnz fail
 xor r8d,r8d
 lea r10,[rel out_bytes]
 lea r11,[rel expected_bytes]
.bytes_check:
 cmp r8d,3
 jae .bytes_ok
 mov al,[r10+r8]
 cmp al,[r11+r8]
 jne fail
 inc r8d
 jmp .bytes_check
.bytes_ok:

 mov ebx,6
 mov rdi,-4
 mov esi,9
 lea rdx,[rel out_value]
 call neboc_core_ordering_int
 test eax,eax
 jnz fail
 cmp qword [rel out_value],0
 jne fail
 mov edi,NEBOC_TOKEN_LESS
 mov esi,0
 lea rdx,[rel out_value]
 call neboc_core_comparison_from_ordering
 test eax,eax
 jnz fail
 cmp qword [rel out_value],1
 jne fail
 mov edi,NEBOC_TYPE_ID_INT
 mov esi,NEBOC_TYPE_ID_INT
 lea rdx,[rel out_value]
 call neboc_core_ordering_type
 test eax,eax
 jnz fail
 cmp qword [rel out_value],NEBOC_TYPE_ID_ORDERING
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
