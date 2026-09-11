bits 64
default rel
%include "compiler/lexer/text_literals.inc"
extern neboc_text_literal_scan
extern neboc_text_literal_token

section .rodata
plain: db '"','n','e','b','o','"'
escaped: db '"','a',0x5c,'n','b','"'
all_escapes: db '"',0x5c,0x5c,0x5c,'"',0x5c,'n',0x5c,'r',0x5c,'t','"'
bad_escape: db '"',0x5c,'q','"'
unterminated: db '"','x'

section .bss
align 8
token: resb NEBO_TEXT_LITERAL_TOKEN_SIZE

section .text
%macro CHECK 3
 lea rdi,[rel %1]
 mov esi,%2
 call neboc_text_literal_scan
 cmp eax,%3
 jne fail
%endmacro
global _start
_start:
 mov r15d,1
 CHECK plain,6,NEBO_LITERAL_OK
 cmp rdx,4
 jne fail
 mov r15d,2
 CHECK escaped,6,NEBO_LITERAL_OK
 cmp rdx,3
 jne fail
 mov r15d,3
 CHECK all_escapes,12,NEBO_LITERAL_OK
 cmp rdx,5
 jne fail
 mov r15d,4
 CHECK bad_escape,4,NEBO_LITERAL_BAD_ESCAPE
 cmp rcx,2
 jne fail
 mov r15d,5
 CHECK unterminated,2,NEBO_LITERAL_UNTERMINATED
 mov r15d,6
 mov qword [rel token],0x11111111
 lea rdi,[rel all_escapes]
 mov esi,12
 mov edx,41
 lea rcx,[rel token]
 call neboc_text_literal_token
 test eax,eax
 jnz fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_KIND_OFFSET],NEBO_TOKEN_TEXT_LITERAL
 jne fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_LENGTH_OFFSET],12
 jne fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_START_OFFSET],41
 jne fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_END_OFFSET],53
 jne fail
 cmp qword [rel token+NEBO_TEXT_LITERAL_TOKEN_DECODED_LENGTH_OFFSET],5
 jne fail
 mov r15d,7
 mov qword [rel token],0x22222222
 lea rdi,[rel bad_escape]
 mov esi,4
 xor edx,edx
 lea rcx,[rel token]
 call neboc_text_literal_token
 cmp eax,NEBO_LITERAL_BAD_ESCAPE
 jne fail
 cmp edx,NEBO_LEX_004
 jne fail
 cmp qword [rel token],0x22222222
 jne fail
 mov r15d,8
 lea rdi,[rel unterminated]
 mov esi,2
 xor edx,edx
 lea rcx,[rel token]
 call neboc_text_literal_token
 cmp eax,NEBO_LITERAL_UNTERMINATED
 jne fail
 cmp edx,NEBO_LEX_003
 jne fail
 mov r15d,9
 xor edi,edi
 xor esi,esi
 call neboc_text_literal_scan
 cmp eax,NEBO_LITERAL_NULL
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,r15d
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
