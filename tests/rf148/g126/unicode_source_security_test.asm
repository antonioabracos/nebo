; SEGURANCA-UNICODE-DA-FONTE native UTF-8/source-security conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/unicode_alias_contract.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/source/utf8/unicode_source_security.inc"

extern neboc_lexer_scan
extern neboc_unicode_operator_scan
extern neboc_unicode_normalization_identity
extern neboc_unicode_confusable_policy
extern neboc_unicode_bidi_policy
extern neboc_unicode_invisible_policy
extern neboc_unicode_security_diagnostic

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .rodata
alias_minus: db 0xe2,0x88,0x92
overlong: db 0xc0,0xaf
surrogate: db 0xed,0xa0,0x80
too_high: db 0xf4,0x90,0x80,0x80
malformed_text: db '"',0xc0,0xaf,'"'
malformed_text_len equ $-malformed_text
context_text: db '"',0xe2,0x80,0xae,0xe2,0x80,0x8b,0xcc,0x80,'"'
context_text_len equ $-context_text
security_source:
 db 0xef,0xbc,0x8d,' ',0xe2,0x80,0xae,' ',0xe2,0x80,0x8b,' ',0xcc,0x80
security_source_len equ $-security_source

section .bss align=16
scan: resb NEBOC_UNICODE_SCAN_SIZE
policy: resb NEBOC_UNICODE_POLICY_SIZE
diagnostic: resb NEBOC_UNICODE_SECURITY_DIAG_SIZE
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*8
literals: resb 64

section .text
global _start
_start:
 mov ebx,1
 lea rdi,[rel alias_minus]
 mov esi,3
 lea rdx,[rel scan]
 call neboc_unicode_operator_scan
 test eax,eax
 jnz fail
 cmp qword [rel scan+NEBOC_UNICODE_SCAN_CODEPOINT_OFFSET],NEBOC_UNICODE_ALIAS_MINUS_CODEPOINT
 jne fail
 cmp qword [rel scan+NEBOC_UNICODE_SCAN_CLASS_OFFSET],NEBOC_UNICODE_CLASS_EXACT_ALIAS
 jne fail

 mov ebx,2
 mov rax,SENTINEL
 mov [rel scan],rax
 lea rdi,[rel overlong]
 mov esi,2
 lea rdx,[rel scan]
 call neboc_unicode_operator_scan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel scan],rax
 jne fail
 lea rdi,[rel surrogate]
 mov esi,3
 lea rdx,[rel scan]
 call neboc_unicode_operator_scan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 lea rdi,[rel too_high]
 mov esi,4
 lea rdx,[rel scan]
 call neboc_unicode_operator_scan
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail

 mov ebx,3
 mov edi,0xff0d
 lea rsi,[rel policy]
 call neboc_unicode_normalization_identity
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_NORMALIZATION_ACTION_OFFSET],NEBOC_UNICODE_NORMALIZATION_REJECT_NFKC_CONFUSABLE
 jne fail
 cmp qword [rel policy+NEBOC_UNICODE_NORMALIZATION_CODEPOINT_OFFSET],0xff0d
 jne fail

 mov ebx,4
 mov edi,0xff0d
 lea rsi,[rel policy]
 call neboc_unicode_confusable_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 jne fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_REPLACEMENT_OFFSET],'-'
 jne fail
 mov edi,0x202e
 lea rsi,[rel policy]
 call neboc_unicode_bidi_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_BIDI
 jne fail
 mov edi,0x200b
 lea rsi,[rel policy]
 call neboc_unicode_invisible_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_INVISIBLE
 jne fail
 mov edi,0x0300
 lea rsi,[rel policy]
 call neboc_unicode_invisible_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_ACTION_OFFSET],NEBOC_UNICODE_SECURITY_REJECT_COMBINING
 jne fail

 mov ebx,5
 mov edi,NEBOC_UNICODE_SECURITY_REJECT_CONFUSABLE
 mov esi,0xff0d
 mov edx,4
 mov ecx,7
 mov r8d,'-'
 lea r9,[rel diagnostic]
 call neboc_unicode_security_diagnostic
 test eax,eax
 jnz fail
 cmp qword [rel diagnostic+NEBOC_UNICODE_SECURITY_DIAG_CODE_OFFSET],NEBOC_UNICODE_DIAG_CONFUSABLE
 jne fail
 cmp qword [rel diagnostic+NEBOC_UNICODE_SECURITY_DIAG_CODEPOINT_OFFSET],0xff0d
 jne fail
 cmp qword [rel diagnostic+NEBOC_UNICODE_SECURITY_DIAG_REPLACEMENT_OFFSET],'-'
 jne fail

 mov ebx,6
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],security_source
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],security_source_len
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],126
 mov qword [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],tokens
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],8
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],5
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],4
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_UNICODE_DIAG_CONFUSABLE
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_UNICODE_DIAG_BIDI_CONTROL
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*2+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_UNICODE_DIAG_INVISIBLE
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_SIZE*3+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_UNICODE_DIAG_COMBINING
 jne fail

 mov ebx,7
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],malformed_text
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],malformed_text_len
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],literals
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],64
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],1
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_PAYLOAD_OFFSET],NEBOC_UNICODE_DIAG_MALFORMED_UTF8
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_START_OFFSET],1
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_END_OFFSET],2
 jne fail

 mov ebx,8
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],context_text
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],context_text_len
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET],2
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET],8
 jne fail

 mov ebx,9
 mov edi,0x2010
 lea rsi,[rel policy]
 call neboc_unicode_confusable_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_REPLACEMENT_OFFSET],'-'
 jne fail
 mov edi,0x2044
 lea rsi,[rel policy]
 call neboc_unicode_confusable_policy
 test eax,eax
 jnz fail
 cmp qword [rel policy+NEBOC_UNICODE_POLICY_REPLACEMENT_OFFSET],'/'
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
