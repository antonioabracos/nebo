; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA native symbol formatter conformance.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/format/symbol_style_profile.inc"

extern neboc_symbol_style_profile
extern neboc_format_operator_ascii
extern neboc_format_operator_math
extern neboc_operator_spacing
extern neboc_operator_line_layout
extern neboc_operator_semantic_equivalence
extern neboc_operator_atomic_mode
extern neboc_lexer_scan

%define SENTINEL 0x5a5a5a5a5a5a5a5a

section .rodata
records_a:
 dq NEBOC_TOKEN_INTEGER,17
 dq NEBOC_TOKEN_MINUS,0
 dq NEBOC_TOKEN_INTEGER,5
records_b:
 dq NEBOC_TOKEN_INTEGER,17
 dq NEBOC_TOKEN_MINUS,0
 dq NEBOC_TOKEN_INTEGER,5
; The token kinds are identical.  Only the operand payload differs, which is
; the false-GREEN case that a kind-only comparison used to accept.
records_bad:
 dq NEBOC_TOKEN_INTEGER,17
 dq NEBOC_TOKEN_MINUS,0
 dq NEBOC_TOKEN_INTEGER,6

section .bss align=16
style: resb NEBOC_SYMBOL_STYLE_RESULT_SIZE
output: resb 16
output_len: resq 1
spacing: resb NEBOC_OPERATOR_SPACING_SIZE
layout: resb NEBOC_OPERATOR_LAYOUT_SIZE
equivalence: resb NEBOC_FORMAT_EQUIVALENCE_SIZE
mode_plan: resb NEBOC_FORMAT_MODE_PLAN_SIZE
request: resb NEBOC_LEXER_REQUEST_SIZE
tokens: resb NEBOC_TOKEN_SIZE*4

section .text
global _start
_start:
 mov ebx,1
 mov edi,NEBOC_SYMBOL_STYLE_PRESERVE
 mov esi,NEBOC_SYMBOL_SPELLING_MATH
 lea rdx,[rel style]
 call neboc_symbol_style_profile
 test eax,eax
 jnz fail
 cmp qword [rel style+NEBOC_SYMBOL_STYLE_RESULT_SPELLING_OFFSET],NEBOC_SYMBOL_SPELLING_MATH
 jne fail
 cmp qword [rel style+NEBOC_SYMBOL_STYLE_RESULT_CHANGED_OFFSET],0
 jne fail
 mov edi,NEBOC_SYMBOL_STYLE_ASCII
 mov esi,NEBOC_SYMBOL_SPELLING_MATH
 lea rdx,[rel style]
 call neboc_symbol_style_profile
 test eax,eax
 jnz fail
 cmp qword [rel style+NEBOC_SYMBOL_STYLE_RESULT_CHANGED_OFFSET],1
 jne fail
 mov rax,SENTINEL
 mov [rel style],rax
 mov edi,3
 xor esi,esi
 lea rdx,[rel style]
 call neboc_symbol_style_profile
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel style],rax
 jne fail

 mov ebx,2
 mov edi,NEBOC_TOKEN_XOR
 lea rsi,[rel output]
 mov edx,16
 lea rcx,[rel output_len]
 call neboc_format_operator_ascii
 test eax,eax
 jnz fail
 cmp qword [rel output_len],3
 jne fail
 cmp byte [rel output],'x'
 jne fail
 cmp byte [rel output+1],'o'
 jne fail
 cmp byte [rel output+2],'r'
 jne fail
 mov rax,SENTINEL
 mov [rel output],rax
 mov [rel output_len],rax
 mov edi,NEBOC_TOKEN_XOR
 lea rsi,[rel output]
 mov edx,2
 lea rcx,[rel output_len]
 call neboc_format_operator_ascii
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel output],rax
 jne fail
 cmp [rel output_len],rax
 jne fail

 mov ebx,3
 mov edi,NEBOC_TOKEN_XOR
 lea rsi,[rel output]
 mov edx,16
 lea rcx,[rel output_len]
 call neboc_format_operator_math
 test eax,eax
 jnz fail
 cmp qword [rel output_len],3
 jne fail
 cmp byte [rel output],0xe2
 jne fail
 cmp byte [rel output+1],0x8a
 jne fail
 cmp byte [rel output+2],0xbb
 jne fail
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],output
 mov qword [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],3
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],127
 mov qword [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],tokens
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],4
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz fail
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne fail
 cmp qword [rel tokens+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_XOR
 jne fail

 mov ebx,4
 mov edi,NEBOC_TOKEN_AND_AND
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel spacing]
 call neboc_operator_spacing
 test eax,eax
 jnz fail
 cmp qword [rel spacing+NEBOC_OPERATOR_SPACING_BEFORE_OFFSET],1
 jne fail
 cmp qword [rel spacing+NEBOC_OPERATOR_SPACING_AFTER_OFFSET],1
 jne fail
 mov edi,NEBOC_TOKEN_BANG
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_PREFIX
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel spacing]
 call neboc_operator_spacing
 test eax,eax
 jnz fail
 cmp qword [rel spacing+NEBOC_OPERATOR_SPACING_AFTER_OFFSET],0
 jne fail
 mov rax,SENTINEL
 mov [rel spacing],rax
 mov edi,NEBOC_TOKEN_MINUS
 mov esi,99
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel spacing]
 call neboc_operator_spacing
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel spacing],rax
 jne fail

 mov ebx,5
 mov edi,79
 mov esi,4
 mov edx,80
 mov ecx,3
 lea r8,[rel layout]
 call neboc_operator_line_layout
 test eax,eax
 jnz fail
 cmp qword [rel layout+NEBOC_OPERATOR_LAYOUT_BREAK_OFFSET],1
 jne fail
 cmp qword [rel layout+NEBOC_OPERATOR_LAYOUT_INDENT_OFFSET],4
 jne fail
 mov rax,SENTINEL
 mov [rel layout],rax
 xor edi,edi
 xor esi,esi
 xor edx,edx
 mov ecx,1
 lea r8,[rel layout]
 call neboc_operator_line_layout
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel layout],rax
 jne fail
 xor edi,edi
 xor esi,esi
 mov edx,4097
 mov ecx,1
 lea r8,[rel layout]
 call neboc_operator_line_layout
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 mov rax,SENTINEL
 cmp [rel layout],rax
 jne fail

 mov ebx,6
 lea rdi,[rel records_a]
 lea rsi,[rel records_b]
 mov edx,3
 lea rcx,[rel equivalence]
 call neboc_operator_semantic_equivalence
 test eax,eax
 jnz fail
 cmp qword [rel equivalence+NEBOC_FORMAT_EQUIVALENCE_AST_IDENTITY_OFFSET],1
 jne fail
 mov rax,SENTINEL
 mov [rel equivalence],rax
 mov [rel equivalence+8],rax
 mov [rel equivalence+16],rax
 lea rdi,[rel records_a]
 lea rsi,[rel records_bad]
 mov edx,3
 lea rcx,[rel equivalence]
 call neboc_operator_semantic_equivalence
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel equivalence],rax
 jne fail
 cmp [rel equivalence+8],rax
 jne fail
 cmp [rel equivalence+16],rax
 jne fail

 mov ebx,7
 mov edi,NEBOC_SYMBOL_FORMAT_MODE_CHECK
 mov esi,3
 mov edx,3
 mov ecx,1
 mov r8d,1
 lea r9,[rel mode_plan]
 call neboc_operator_atomic_mode
 test eax,eax
 jnz fail
 cmp qword [rel mode_plan+NEBOC_FORMAT_MODE_PLAN_EXIT_OFFSET],1
 jne fail
 cmp qword [rel mode_plan+NEBOC_FORMAT_MODE_PLAN_WRITE_OFFSET],0
 jne fail
 mov edi,NEBOC_SYMBOL_FORMAT_MODE_WRITE
 mov esi,3
 mov edx,3
 mov ecx,1
 mov r8d,1
 lea r9,[rel mode_plan]
 call neboc_operator_atomic_mode
 test eax,eax
 jnz fail
 cmp qword [rel mode_plan+NEBOC_FORMAT_MODE_PLAN_WRITE_OFFSET],1
 jne fail
 cmp qword [rel mode_plan+NEBOC_FORMAT_MODE_PLAN_TEMP_OFFSET],1
 jne fail
 cmp qword [rel mode_plan+NEBOC_FORMAT_MODE_PLAN_ROLLBACK_OFFSET],1
 jne fail
 mov rax,SENTINEL
 mov [rel mode_plan],rax
 mov edi,NEBOC_SYMBOL_FORMAT_MODE_WRITE
 mov esi,3
 mov edx,3
 mov ecx,1
 xor r8d,r8d
 lea r9,[rel mode_plan]
 call neboc_operator_atomic_mode
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov rax,SENTINEL
 cmp [rel mode_plan],rax
 jne fail

 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,ebx
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
