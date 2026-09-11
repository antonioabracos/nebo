; ARITMETICA-CHECKED-E-ASSIGNMENT-COMPOSTO checked arithmetic and atomic-assignment conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/semantic/operators/core_arithmetic_registry.inc"

extern neboc_core_checked_add
extern neboc_core_checked_subtract
extern neboc_core_checked_multiply
extern neboc_core_checked_divide
extern neboc_core_checked_remainder
extern neboc_core_prefix_power_binding
extern neboc_core_prefix_power_validate
extern neboc_compound_multiply
extern neboc_compound_divide
extern neboc_compound_remainder
extern neboc_compound_power
extern neboc_core_fold_binary
extern neboc_core_fold_prefix
extern neboc_core_arithmetic_registry_table
extern neboc_core_arithmetic_registry_lookup
extern neboc_core_arithmetic_registry_resolve

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .bss align=16
out_value: resq 1
target: resq 1

section .rodata align=8
expected_registry_ids:
 dq NEBOC_OPERATOR_ID_NSR_CORE_012
 dq NEBOC_OPERATOR_ID_NSR_CORE_013
 dq NEBOC_OPERATOR_ID_NSR_CORE_014
 dq NEBOC_OPERATOR_ID_NSR_CORE_015
 dq NEBOC_OPERATOR_ID_NSR_CORE_016
 dq NEBOC_OPERATOR_ID_NSR_CORE_018
 dq NEBOC_OPERATOR_ID_NSR_CORE_019
 dq NEBOC_OPERATOR_ID_NSR_CORE_031
 dq NEBOC_OPERATOR_ID_NSR_CORE_032
 dq NEBOC_OPERATOR_ID_NSR_CORE_033
 dq NEBOC_OPERATOR_ID_NSR_CORE_034
 dq NEBOC_OPERATOR_ID_NSR_CORE_035
 dq NEBOC_OPERATOR_ID_NSR_CORE_036
 dq NEBOC_OPERATOR_ID_NSR_CORE_037

section .text
global _start
_start:
 ; The exact fourteen-row semantic Registry slice is active and queryable.
 mov ebx,1
 call neboc_core_arithmetic_registry_table
 cmp edx,NEBOC_CORE_ARITHMETIC_REGISTRY_ENTRY_COUNT
 jne fail
 cmp ecx,NEBOC_CORE_ARITHMETIC_REGISTRY_SCHEMA_VERSION
 jne fail
 mov r10,rax
 lea r11,[rel expected_registry_ids]
 xor r12d,r12d
.registry_loop:
 mov rax,[r11+r12*8]
 cmp [r10+NEBOC_CORE_ARITHMETIC_ENTRY_ID_OFFSET],rax
 jne fail
 cmp qword [r10+NEBOC_CORE_ARITHMETIC_ENTRY_STATE_OFFSET],NEBOC_OPERATOR_STATE_ACTIVE_CURRENT
 jne fail
 add r10,NEBOC_CORE_ARITHMETIC_ENTRY_SIZE
 inc r12
 cmp r12,NEBOC_CORE_ARITHMETIC_REGISTRY_ENTRY_COUNT
 jb .registry_loop
 mov edi,NEBOC_OPERATOR_ID_NSR_CORE_037
 call neboc_core_arithmetic_registry_lookup
 test rax,rax
 jz fail
 cmp qword [rax+NEBOC_CORE_ARITHMETIC_ENTRY_TOKEN_OFFSET],NEBOC_TOKEN_CARET
 jne fail
 mov edi,NEBOC_TOKEN_CARET
 mov esi,NEBOC_TOKEN_RESERVED_EQUAL
 mov edx,NEBOC_OPERATOR_FIXITY_CONTEXTUAL
 mov ecx,NEBOC_OPERATOR_CONTEXT_STATEMENT
 call neboc_core_arithmetic_registry_resolve
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_ID_NSR_CORE_037
 jne fail
 test qword [rax+NEBOC_CORE_ARITHMETIC_ENTRY_FLAGS_OFFSET],NEBOC_CORE_ARITHMETIC_FLAG_POWER_ONLY
 jz fail

 mov ebx,1
 mov edi,40
 mov esi,2
 lea rdx,[rel out_value]
 call neboc_core_checked_add
 test eax,eax
 jnz fail
 cmp qword [rel out_value],42
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov rdi,0x7fffffffffffffff
 mov esi,1
 lea rdx,[rel out_value]
 call neboc_core_checked_add
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail

 mov edi,10
 mov esi,52
 lea rdx,[rel out_value]
 call neboc_core_checked_subtract
 test eax,eax
 jnz fail
 cmp qword [rel out_value],-42
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov rdi,0x8000000000000000
 mov esi,1
 lea rdx,[rel out_value]
 call neboc_core_checked_subtract
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail

 mov rdi,-7
 mov esi,6
 lea rdx,[rel out_value]
 call neboc_core_checked_multiply
 test eax,eax
 jnz fail
 cmp qword [rel out_value],-42
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov rdi,0x7fffffffffffffff
 mov esi,2
 lea rdx,[rel out_value]
 call neboc_core_checked_multiply
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail

 mov rax,SENTINEL
 mov [rel out_value],rax
 mov rdi,0x8000000000000000
 mov rsi,-1
 lea rdx,[rel out_value]
 call neboc_core_checked_remainder
 test eax,eax
 jnz fail
 cmp qword [rel out_value],0
 jne fail

 mov ebx,2
 mov rdi,-7
 mov rsi,3
 lea rdx,[rel out_value]
 call neboc_core_checked_divide
 test eax,eax
 jnz fail
 cmp qword [rel out_value],-2
 jne fail
 mov rdi,-7
 mov rsi,3
 lea rdx,[rel out_value]
 call neboc_core_checked_remainder
 test eax,eax
 jnz fail
 cmp qword [rel out_value],-1
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov edi,9
 xor esi,esi
 lea rdx,[rel out_value]
 call neboc_core_checked_divide
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov rdi,0x8000000000000000
 mov rsi,-1
 lea rdx,[rel out_value]
 call neboc_core_checked_divide
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov edi,9
 xor esi,esi
 lea rdx,[rel out_value]
 call neboc_core_checked_remainder
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 mov edi,7
 mov rsi,-3
 lea rdx,[rel out_value]
 call neboc_core_checked_divide
 test eax,eax
 jnz fail
 cmp qword [rel out_value],-2
 jne fail
 mov edi,7
 mov rsi,-3
 lea rdx,[rel out_value]
 call neboc_core_checked_remainder
 test eax,eax
 jnz fail
 cmp qword [rel out_value],1
 jne fail

 mov ebx,31
 mov qword [rel target],6
 lea rdi,[rel target]
 mov esi,7
 call neboc_compound_multiply
 test eax,eax
 jnz fail
 cmp qword [rel target],42
 jne fail
 mov ebx,32
 mov qword [rel target],84
 lea rdi,[rel target]
 mov esi,2
 call neboc_compound_divide
 test eax,eax
 jnz fail
 cmp qword [rel target],42
 jne fail
 mov ebx,33
 mov qword [rel target],43
 lea rdi,[rel target]
 mov esi,5
 call neboc_compound_remainder
 test eax,eax
 jnz fail
 cmp qword [rel target],3
 jne fail
 mov ebx,34
 mov qword [rel target],9
 lea rdi,[rel target]
 mov esi,2
 call neboc_compound_power
 test eax,eax
 jne fail
 cmp qword [rel target],81
 jne fail
 mov rax,0x7fffffffffffffff
 mov [rel target],rax
 lea rdi,[rel target]
 mov esi,2
 call neboc_compound_multiply
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,0x7fffffffffffffff
 cmp [rel target],rax
 jne fail
 mov qword [rel target],42
 lea rdi,[rel target]
 xor esi,esi
 call neboc_compound_divide
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel target],42
 jne fail
 mov qword [rel target],43
 lea rdi,[rel target]
 xor esi,esi
 call neboc_compound_remainder
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel target],43
 jne fail
 mov qword [rel target],9
 lea rdi,[rel target]
 mov rsi,-1
 call neboc_compound_power
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel target],9
 jne fail
 mov rax,3037000500
 mov [rel target],rax
 lea rdi,[rel target]
 mov esi,2
 call neboc_compound_power
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,3037000500
 cmp [rel target],rax
 jne fail

 mov ebx,4
 mov edi,NEBOC_TOKEN_STAR
 mov esi,6
 mov edx,7
 lea rcx,[rel out_value]
 call neboc_core_fold_binary
 test eax,eax
 jnz fail
 cmp qword [rel out_value],42
 jne fail
 mov rax,SENTINEL
 mov [rel out_value],rax
 mov edi,NEBOC_TOKEN_MINUS
 mov rsi,0x8000000000000000
 lea rdx,[rel out_value]
 call neboc_core_fold_prefix
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel out_value],rax
 jne fail
 mov edi,NEBOC_TOKEN_PLUS
 mov esi,42
 lea rdx,[rel out_value]
 call neboc_core_fold_prefix
 test eax,eax
 jnz fail
 cmp qword [rel out_value],42
 jne fail

 mov ebx,5
 call neboc_core_prefix_power_validate
 test eax,eax
 jnz fail
 mov edi,3
 call neboc_core_prefix_power_binding
 test eax,eax
 jnz fail
 cmp edx,160
 jne fail
 cmp ecx,160
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
