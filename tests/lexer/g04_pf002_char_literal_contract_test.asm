; TEXT-CHAR-UNICODE-E-BYTES-PF002 isolated Char literal syntax and diagnostic contract tests
bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
extern neboc_char_literal_contract_scan
extern neboc_char_literal_parse_contract
extern neboc_host_process_exit

%macro CASE 8
 dq %1,%2,%3,%4,%5,%6,%7,%8
%endmacro

section .rodata
s1: db 39,'A',39
s2: db 39,0xc3,0xa7,39
s3: db 39,0xe2,0x82,0xac,39
s4: db 39,0xf0,0x9f,0x98,0x80,39
s5: db 39,92,'n',39
s6: db 39,92,'r',39
s7: db 39,92,'t',39
s8: db 39,92,92,39
s9: db 39,92,39,39
s10: db 39,39
s11: db 39,'a','b',39
s12: db 39,92,'x',39
s13: db 39
s14: db 39,'A'
s15: db 39,10,39
s16: db 39,0xc0,0xaf,39
s17: db 39,0xed,0xa0,0x80,39
s18: db 39,0xf4,0x90,0x80,0x80,39
s19: db 39,0xe0,0x80,0x80,39
s20: db 0xef,0xbb,0xbf,39,'A',39
s21: db 'A',39
s22: db 39,0xe2,0x28,0xa1,39
align 8
; ptr,len,status,scalar,diag,relative_error_start,relative_error_end,ast_expected
cases:
 CASE s1,3,NEBOC_STATUS_OK,0x41,0,0,0,1
 CASE s2,4,NEBOC_STATUS_OK,0xe7,0,0,0,1
 CASE s3,5,NEBOC_STATUS_OK,0x20ac,0,0,0,1
 CASE s4,6,NEBOC_STATUS_OK,0x1f600,0,0,0,1
 CASE s5,4,NEBOC_STATUS_OK,10,0,0,0,1
 CASE s6,4,NEBOC_STATUS_OK,13,0,0,0,1
 CASE s7,4,NEBOC_STATUS_OK,9,0,0,0,1
 CASE s8,4,NEBOC_STATUS_OK,92,0,0,0,1
 CASE s9,4,NEBOC_STATUS_OK,39,0,0,0,1
 CASE s10,2,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_EMPTY,1,1,0
 CASE s11,4,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_MULTIPLE_SCALARS,2,3,0
 CASE s12,4,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_INVALID_ESCAPE,1,3,0
 CASE s13,1,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_UNTERMINATED,1,1,0
 CASE s14,2,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_UNTERMINATED,2,2,0
 CASE s15,3,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_PHYSICAL_NEWLINE,1,2,0
 CASE s16,4,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_INVALID_UTF8,1,2,0
 CASE s17,5,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_SURROGATE,1,4,0
 CASE s18,6,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_OUT_OF_RANGE,1,5,0
 CASE s19,5,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_INVALID_UTF8,2,3,0
 CASE s20,6,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_BOM_FORBIDDEN,0,3,0
 CASE s21,2,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_EXPECTED_OPEN_QUOTE,0,1,0
 CASE s22,5,NEBOC_STATUS_INVALID_SOURCE,0,NEBOC_CHAR_DIAG_INVALID_UTF8,2,3,0
case_count equ ($-cases)/(8*8)

section .bss align=16
request: resb NEBOC_CHAR_REQUEST_SIZE
ast: resb NEBOC_CHAR_AST_SIZE
first_hash: resq 1

section .text
global _start
_start:
 lea r14,[rel cases]
 mov r15d,case_count
 mov r13d,1
.loop:
 lea rdi,[rel request]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,[r14]
 mov [rel request+NEBOC_CHAR_SOURCE_OFFSET],rax
 mov rax,[r14+8]
 mov [rel request+NEBOC_CHAR_LENGTH_OFFSET],rax
 mov qword [rel request+NEBOC_CHAR_SOURCE_ID_OFFSET],404
 mov qword [rel request+NEBOC_CHAR_ABSOLUTE_START_OFFSET],1000
 lea rdi,[rel request]
 call neboc_char_literal_contract_scan
 cmp rax,[r14+16]
 jne .fail
 mov rax,[rel request+NEBOC_CHAR_SCALAR_OFFSET]
 cmp rax,[r14+24]
 jne .fail
 mov rax,[rel request+NEBOC_CHAR_DIAGNOSTIC_OFFSET]
 cmp rax,[r14+32]
 jne .fail
 cmp qword [r14+16],NEBOC_STATUS_OK
 je .valid
 mov rax,[rel request+NEBOC_CHAR_ERROR_START_OFFSET]
 sub rax,1000
 cmp rax,[r14+40]
 jne .fail
 mov rax,[rel request+NEBOC_CHAR_ERROR_END_OFFSET]
 sub rax,1000
 cmp rax,[r14+48]
 jne .fail
 lea rdi,[rel request]
 lea rsi,[rel ast]
 call neboc_char_literal_parse_contract
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail
 jmp .next
.valid:
 cmp qword [rel request+NEBOC_CHAR_TOKEN_KIND_OFFSET],NEBOC_TOKEN_CHAR_PROVISIONAL
 jne .fail
 cmp qword [rel request+NEBOC_CHAR_SCALAR_COUNT_OFFSET],1
 jne .fail
 cmp qword [rel request+NEBOC_CHAR_TOKEN_START_OFFSET],1000
 jne .fail
 mov rax,1000
 add rax,[r14+8]
 cmp [rel request+NEBOC_CHAR_TOKEN_END_OFFSET],rax
 jne .fail
 lea rdi,[rel ast]
 mov ecx,NEBOC_CHAR_AST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel request]
 lea rsi,[rel ast]
 call neboc_char_literal_parse_contract
 test eax,eax
 jnz .fail
 cmp qword [rel ast+NEBOC_CHAR_AST_KIND_OFFSET],NEBOC_AST_CHAR_LITERAL_PROVISIONAL
 jne .fail
 mov rax,[r14+24]
 cmp [rel ast+NEBOC_CHAR_AST_SCALAR_OFFSET],rax
 jne .fail
 cmp qword [rel ast+NEBOC_CHAR_AST_SOURCE_ID_OFFSET],404
 jne .fail
 cmp qword [rel ast+NEBOC_CHAR_AST_START_OFFSET],1000
 jne .fail
 cmp qword [rel ast+NEBOC_CHAR_AST_HASH_OFFSET],0
 je .fail
.next:
 add r14,64
 inc r13d
 dec r15d
 jnz .loop
 ; Deterministic scan hash.
 lea rdi,[rel request]
 mov ecx,NEBOC_CHAR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel s4]
 mov [rel request+NEBOC_CHAR_SOURCE_OFFSET],rax
 mov qword [rel request+NEBOC_CHAR_LENGTH_OFFSET],6
 mov qword [rel request+NEBOC_CHAR_SOURCE_ID_OFFSET],404
 mov qword [rel request+NEBOC_CHAR_ABSOLUTE_START_OFFSET],77
 lea rdi,[rel request]
 call neboc_char_literal_contract_scan
 test eax,eax
 jnz .fail
 mov rax,[rel request+NEBOC_CHAR_HASH_OFFSET]
 mov [rel first_hash],rax
 lea rdi,[rel request]
 call neboc_char_literal_contract_scan
 test eax,eax
 jnz .fail
 mov rax,[rel first_hash]
 cmp rax,[rel request+NEBOC_CHAR_HASH_OFFSET]
 jne .fail
 xor edi,edi
 call neboc_char_literal_contract_scan
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne .fail
 xor edi,edi
 jmp neboc_host_process_exit
.fail:
 mov edi,r13d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
