bits 64
default rel
%include "compiler/parser/text_contract.inc"
global neboc_text_parse_contract
global neboc_text_is_nebo_identifier
section .text
align 16
neboc_text_parse_contract:
 cmp edi,NEBO_TOKEN_TEXT_SIMPLE
 je .text
 cmp edi,NEBO_TOKEN_TEXT_RAW
 je .text
 mov eax,NEBO_PARSE_ERROR
 ret
.text:
 mov eax,NEBO_AST_TEXT_LITERAL
 ret

; rdi=bytes, rsi=length. Mirrors the live lexer ASCII start/continue rules.
align 16
neboc_text_is_nebo_identifier:
 test rdi,rdi
 jz .id_false
 test rsi,rsi
 jz .id_false
 mov al,[rdi]
 cmp al,'A'
 jb .id_first_lower
 cmp al,'Z'
 jbe .id_rest_setup
.id_first_lower:
 cmp al,'a'
 jb .id_first_underscore
 cmp al,'z'
 jbe .id_rest_setup
.id_first_underscore:
 cmp al,'_'
 jne .id_false
.id_rest_setup:
 mov ecx,1
.id_rest:
 cmp rcx,rsi
 jae .id_true
 mov al,[rdi+rcx]
 cmp al,'A'
 jb .id_digit
 cmp al,'Z'
 jbe .id_next
 cmp al,'a'
 jb .id_underscore
 cmp al,'z'
 jbe .id_next
.id_digit:
 cmp al,'0'
 jb .id_false
 cmp al,'9'
 jbe .id_next
.id_underscore:
 cmp al,'_'
 jne .id_false
.id_next:
 inc rcx
 jmp .id_rest
.id_true:
 mov eax,1
 ret
.id_false:
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
