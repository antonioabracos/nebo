; LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-PF002 numeric literal syntax/API/diagnostic contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
extern neboc_numeric_literal_contract_scan
extern neboc_host_process_exit

%macro CASE 10
 dq %1,%2,%3,%4,%5,%6,%7,%8,%9,%10
%endmacro

section .rodata
s1: db '42'
s2: db '1_000'
s3: db '0b1010'
s4: db '0b1010_0110'
s5: db '0x2Af'
s6: db '0o755'
s7: db '0x8000_0000_0000_0000'
s8: db '0X2A'
s9: db '0x'
s10: db '0x_1'
s11: db '123_'
s12: db '1__0'
s13: db '0b2'
s14: db '0o8'
s15: db '0xG'
s16: db '42i64'
s17: db '0q10'
s18: db '9_223_372_036_854_775_809'
s19: db '1_0.5'

align 8
cases:
 CASE s1,2,NEBOC_STATUS_OK,10,0x2a,0,0,0,0,0
 CASE s2,5,NEBOC_STATUS_OK,10,1000,NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY,0,0,0,0
 CASE s3,6,NEBOC_STATUS_OK,2,10,NEBOC_TOKEN_FLAG_INT_BASE_BINARY|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY,0,0,0,0
 CASE s4,11,NEBOC_STATUS_OK,2,0xa6,NEBOC_TOKEN_FLAG_INT_BASE_BINARY|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY,0,0,0,0
 CASE s5,5,NEBOC_STATUS_OK,16,0x2af,NEBOC_TOKEN_FLAG_INT_BASE_HEX|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY,0,0,0,0
 CASE s6,5,NEBOC_STATUS_OK,8,0x1ed,NEBOC_TOKEN_FLAG_INT_BASE_OCTAL|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY,0,0,0,0
 CASE s7,21,NEBOC_STATUS_OK,16,0x8000000000000000,NEBOC_TOKEN_FLAG_INT_BASE_HEX|NEBOC_TOKEN_FLAG_INT_HAS_SEPARATOR|neboc_literais_numericos_bases_e_representacao_TOKEN_FLAG_SYNTAX_ONLY|NEBOC_TOKEN_FLAG_INT_MIN_MAGNITUDE,0,0,0,0
 CASE s8,4,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_UPPERCASE_PREFIX,1,2,0
 CASE s9,2,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_MISSING_DIGITS,2,2,0
 CASE s10,4,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR,2,3,0
 CASE s11,4,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR,3,4,0
 CASE s12,4,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR,1,2,0
 CASE s13,3,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_DIGIT,2,3,0
 CASE s14,3,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_DIGIT,2,3,0
 CASE s15,3,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_INVALID_DIGIT,2,3,0
 CASE s16,5,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_SUFFIX_UNAVAILABLE,2,3,0
 CASE s17,4,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_UNKNOWN_PREFIX,1,2,0
 CASE s18,25,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_OVERFLOW,24,25,0
 CASE s19,5,NEBOC_STATUS_INVALID_SOURCE,0,0,NEBOC_TOKEN_FLAG_ERROR,NEBOC_NUMERIC_DIAG_FLOAT_SEPARATOR_UNAVAILABLE,1,2,0
case_count equ ($-cases)/(10*8)

section .bss align=16
request: resb NEBOC_NUMERIC_REQUEST_SIZE
hash_first: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
.case_loop:
 test r15d,r15d
 jz .determinism
 lea rdi,[rel request]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+NEBOC_NUMERIC_SOURCE_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+NEBOC_NUMERIC_LENGTH_OFFSET],rax
 mov qword [rel request+NEBOC_NUMERIC_SOURCE_ID_OFFSET],7
 mov qword [rel request+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],100
 lea rdi,[rel request]
 call neboc_numeric_literal_contract_scan
 cmp rax,[r14+16]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_BASE_OFFSET]
 cmp rax,[r14+24]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_VALUE_OFFSET]
 cmp rax,[r14+32]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_TOKEN_FLAGS_OFFSET]
 cmp rax,[r14+40]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_ERROR_CODE_OFFSET]
 cmp rax,[r14+48]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_ERROR_START_OFFSET]
 cmp qword [r14+48],0
 je .valid_spans
 sub rax,100
 cmp rax,[r14+56]
 jne .fail
 mov rax,[rel request+NEBOC_NUMERIC_ERROR_END_OFFSET]
 sub rax,100
 cmp rax,[r14+64]
 jne .fail
 jmp .next
.valid_spans:
 cmp qword [rel request+NEBOC_NUMERIC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .fail
 cmp qword [rel request+NEBOC_NUMERIC_TOKEN_START_OFFSET],100
 jne .fail
 mov rax,100
 add rax,[r14+8]
 cmp [rel request+NEBOC_NUMERIC_TOKEN_END_OFFSET],rax
 jne .fail
.next:
 add r14,80
 dec r15d
 jmp .case_loop
.determinism:
 ; Same exact lexeme/request must produce the same result hash.
 lea rdi,[rel request]
 mov ecx,NEBOC_NUMERIC_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel s4]
 mov [rel request+NEBOC_NUMERIC_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_NUMERIC_LENGTH_OFFSET],11
 mov qword [rel request+NEBOC_NUMERIC_SOURCE_ID_OFFSET],1
 mov qword [rel request+NEBOC_NUMERIC_ABSOLUTE_START_OFFSET],9
 lea rdi,[rel request]
 call neboc_numeric_literal_contract_scan
 test eax,eax
 jnz .fail
 mov rax,[rel request+NEBOC_NUMERIC_HASH_OFFSET]
 mov [rel hash_first],rax
 lea rdi,[rel request]
 call neboc_numeric_literal_contract_scan
 test eax,eax
 jnz .fail
 mov rax,[rel hash_first]
 cmp rax,[rel request+NEBOC_NUMERIC_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_numeric_literal_contract_scan
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 lea rdi,[rel request]
 mov qword [rel request+NEBOC_NUMERIC_LENGTH_OFFSET],0
 call neboc_numeric_literal_contract_scan
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,1
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
