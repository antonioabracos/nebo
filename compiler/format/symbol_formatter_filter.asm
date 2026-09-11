; FORMATTER-ASCII-MATEMATICO-E-EQUIVALENCIA-SEMANTICA live bounded source filter.
; The canonical Nebo lexer owns lexical context and exact alias recognition;
; this executable rewrites token spans only and preserves every intervening
; byte (Text, Char, comments, templates and whitespace) verbatim.
bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/format/symbol_style_profile.inc"

extern neboc_lexer_scan
extern neboc_symbol_style_profile
extern neboc_format_operator_ascii
extern neboc_format_operator_math

%define FILTER_TOKEN_CAPACITY NEBOC_FORMAT_EQUIVALENCE_MAX_TOKENS
%define FILTER_REPLACEMENT_CAPACITY 16

section .rodata
ascii_name: db 'ascii',0
math_name: db 'math',0
preserve_name: db 'preserve',0

section .bss align=16
source_bytes: resb NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES+1
output_bytes: resb NEBOC_SYMBOL_FORMAT_MAX_OUTPUT_BYTES
literal_bytes: resb NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES
tokens: resb NEBOC_TOKEN_SIZE*FILTER_TOKEN_CAPACITY
request: resb NEBOC_LEXER_REQUEST_SIZE
profile_result: resb NEBOC_SYMBOL_STYLE_RESULT_SIZE
replacement: resb FILTER_REPLACEMENT_CAPACITY
replacement_length: resq 1
current_start: resq 1
current_end: resq 1

section .text
global _start

; append_range(pointer, length) -> eax status; r13 is committed output length.
append_range:
 mov rax,r13
 add rax,rsi
 jc .limit
 cmp rax,NEBOC_SYMBOL_FORMAT_MAX_OUTPUT_BYTES
 ja .limit
 xor ecx,ecx
.copy:
 cmp rcx,rsi
 jae .done
 mov r8b,[rdi+rcx]
 lea r9,[rel output_bytes]
 mov [r9+r13],r8b
 inc r13
 inc rcx
 jmp .copy
.done:
 xor eax,eax
 ret
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret

same_text:
 ; rdi=argument, rsi=NUL-terminated expected name
 xor eax,eax
.loop:
 mov dl,[rdi+rax]
 cmp dl,[rsi+rax]
 jne .no
 test dl,dl
 jz .yes
 inc rax
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

_start:
 ; Exactly one explicit profile argument keeps the helper surface closed.
 mov rax,[rsp]
 cmp rax,2
 jne filter_invalid
 mov rdi,[rsp+16]
 lea rsi,[rel preserve_name]
 call same_text
 test eax,eax
 jnz .preserve
 mov rdi,[rsp+16]
 lea rsi,[rel ascii_name]
 call same_text
 test eax,eax
 jnz .ascii
 mov rdi,[rsp+16]
 lea rsi,[rel math_name]
 call same_text
 test eax,eax
 jnz .math
 jmp filter_invalid
.preserve:
 mov ebx,NEBOC_SYMBOL_STYLE_PRESERVE
 jmp .read
.ascii:
 mov ebx,NEBOC_SYMBOL_STYLE_ASCII
 jmp .read
.math:
 mov ebx,NEBOC_SYMBOL_STYLE_MATH

.read:
 xor r12d,r12d
.read_loop:
 xor eax,eax
 xor edi,edi
 lea rsi,[rel source_bytes]
 add rsi,r12
 mov edx,NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES+1
 sub rdx,r12
 syscall
 test rax,rax
 js filter_io
 jz .read_done
 add r12,rax
 cmp r12,NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES
 ja filter_limit
 jmp .read_loop
.read_done:
 ; Empty source is still lexed and receives an EOF token.
 lea rax,[rel source_bytes]
 mov [rel request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rax
 mov [rel request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],r12
 mov qword [rel request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],127
 lea rax,[rel tokens]
 mov [rel request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],FILTER_TOKEN_CAPACITY
 lea rax,[rel literal_bytes]
 mov [rel request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],NEBOC_SYMBOL_FORMAT_MAX_INPUT_BYTES
 lea rdi,[rel request]
 call neboc_lexer_scan
 test eax,eax
 jnz filter_status
 cmp qword [rel request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 je .lexically_admitted
 ; RESERVED spellings are valid formatter input even though compilation must
 ; reject them.  Every such token is copied byte-for-byte and never rewritten.
 xor r15d,r15d
.reserved_error_scan:
 cmp r15,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .lexically_admitted
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea r11,[rel tokens]
 add r11,rax
 test qword [r11+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_ERROR
 jz .reserved_error_next
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_SYMBOL
 je .reserved_error_next
 cmp qword [r11+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_REJECTED_FORM
 jne filter_source
.reserved_error_next:
 inc r15
 jmp .reserved_error_scan
.lexically_admitted:

 xor r13d,r13d                 ; output length
 xor r14d,r14d                 ; committed input cursor
 xor r15d,r15d                 ; token index
.token_loop:
 cmp r15,[rel request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .tail
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea r11,[rel tokens]
 add r11,rax
 mov r8,[r11+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r11+NEBOC_TOKEN_END_OFFSET]
 cmp r8,r14
 jb filter_source
 cmp r9,r8
 jb filter_source
 cmp r9,r12
 ja filter_source
 mov [rel current_start],r8
 mov [rel current_end],r9

 ; Copy comments, whitespace and every other non-token byte before the token.
 lea rdi,[rel source_bytes]
 add rdi,r14
 mov rsi,r8
 sub rsi,r14
 call append_range
 test eax,eax
 jnz filter_status

 ; Resolve the requested profile from the token's actual source provenance.
 xor esi,esi
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea r11,[rel tokens]
 add r11,rax
 mov rax,[r11+NEBOC_TOKEN_FLAGS_OFFSET]
 test rax,NEBOC_TOKEN_FLAG_UNICODE_ALIAS
 jz .profile
 mov esi,NEBOC_SYMBOL_SPELLING_MATH
.profile:
 mov rdi,rbx
 lea rdx,[rel profile_result]
 call neboc_symbol_style_profile
 test eax,eax
 jnz filter_status
 cmp qword [rel profile_result+NEBOC_SYMBOL_STYLE_RESULT_CHANGED_OFFSET],0
 je .copy_token

 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea r11,[rel tokens]
 add r11,rax
 mov rdi,[r11+NEBOC_TOKEN_KIND_OFFSET]
 lea rsi,[rel replacement]
 mov edx,FILTER_REPLACEMENT_CAPACITY
 lea rcx,[rel replacement_length]
 cmp qword [rel profile_result+NEBOC_SYMBOL_STYLE_RESULT_SPELLING_OFFSET],NEBOC_SYMBOL_SPELLING_MATH
 je .format_math
 call neboc_format_operator_ascii
 jmp .formatted
.format_math:
 call neboc_format_operator_math
.formatted:
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .copy_token                  ; Non-registry tokens are never rewritten.
 test eax,eax
 jnz filter_status
 lea rdi,[rel replacement]
 mov rsi,[rel replacement_length]
 call append_range
 test eax,eax
 jnz filter_status
 jmp .advance

.copy_token:
 mov rdi,[rel current_start]
 mov rsi,[rel current_end]
 sub rsi,rdi
 lea rax,[rel source_bytes]
 add rdi,rax
 call append_range
 test eax,eax
 jnz filter_status
.advance:
 mov r14,[rel current_end]
 inc r15
 jmp .token_loop

.tail:
 lea rdi,[rel source_bytes]
 add rdi,r14
 mov rsi,r12
 sub rsi,r14
 call append_range
 test eax,eax
 jnz filter_status

 ; No byte is externally observable until lexing and the complete bounded
 ; transformation have succeeded.
 xor r14d,r14d
.write_loop:
 cmp r14,r13
 jae filter_ok
 mov eax,1
 mov edi,1
 lea rsi,[rel output_bytes]
 add rsi,r14
 mov rdx,r13
 sub rdx,r14
 syscall
 test rax,rax
 jle filter_io
 add r14,rax
 jmp .write_loop

filter_ok:
 xor edi,edi
 jmp filter_exit
filter_invalid:
 mov edi,NEBOC_STATUS_INVALID_ARGUMENT
 jmp filter_exit
filter_io:
 mov edi,NEBOC_STATUS_IO_ERROR
 jmp filter_exit
filter_source:
 mov edi,NEBOC_STATUS_INVALID_SOURCE
 jmp filter_exit
filter_limit:
 mov edi,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp filter_exit
filter_status:
 mov edi,eax
filter_exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
