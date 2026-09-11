bits 64
default rel
%include "compiler/parser/text_contract.inc"
extern neboc_token_keyword_kind
global neboc_text_parse_contract
global neboc_text_literal_expr
global neboc_text_is_nebo_identifier
section .text
align 16
neboc_text_parse_contract:
 cmp edi,NEBO_TOKEN_TEXT_SIMPLE
 je .text
 cmp edi,NEBO_TOKEN_TEXT_RAW
 je .raw
 cmp edi,NEBO_TOKEN_TEXT_MULTILINE
 je .multiline
 mov eax,NEBO_PARSE_ERROR
 ret
.text:
 mov eax,NEBO_AST_TEXT_LITERAL
 ret
.raw:
 mov eax,NEBO_AST_RAW_TEXT_LITERAL
 ret
.multiline:
 mov eax,NEBO_AST_MULTILINE_TEXT_LITERAL
 ret

; edi=token kind, rsi=start, rdx=end, rcx=out TextLiteralExpr.  Raw and
; G063 activates raw and multiline nodes while preserving the original simple
; TextLiteralExpr kind and half-open source spans.
align 16
neboc_text_literal_expr:
 test rcx,rcx
 jz .expr_error
 mov edi,edi
 cmp rdx,rsi
 jb .expr_error
 cmp edi,NEBO_TOKEN_TEXT_SIMPLE
 je .expr_simple
 cmp edi,NEBO_TOKEN_TEXT_RAW
 je .expr_raw
 cmp edi,NEBO_TOKEN_TEXT_MULTILINE
 jne .expr_error
 mov rax,NEBO_AST_MULTILINE_TEXT_LITERAL
 jmp .expr_commit
.expr_raw:
 mov rax,NEBO_AST_RAW_TEXT_LITERAL
 jmp .expr_commit
.expr_simple:
 mov rax,NEBO_AST_TEXT_LITERAL_EXPR
.expr_commit:
 mov [rcx+NEBO_TEXT_LITERAL_EXPR_KIND_OFFSET],rax
 mov [rcx+NEBO_TEXT_LITERAL_EXPR_TOKEN_OFFSET],rdi
 mov [rcx+NEBO_TEXT_LITERAL_EXPR_START_OFFSET],rsi
 mov [rcx+NEBO_TEXT_LITERAL_EXPR_END_OFFSET],rdx
 ret
.expr_error:
 mov eax,NEBO_PARSE_ERROR
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
 ; A token accepted by the lexical shape rules is an identifier only when the
 ; live token classifier does not reserve it as a language keyword.
 call neboc_token_keyword_kind
 test eax,eax
 setz al
 movzx eax,al
 ret
.id_false:
 xor eax,eax
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
