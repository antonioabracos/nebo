bits 64
default rel
%include "compiler/lexer/text_literals.inc"

extern neboc_raw_literal_scan
extern neboc_text_segment_init

section .rodata
raw: db '"','"','"','a',10,'{','{','x','}',0x5c,'n','"','"','"'
multiline: db '"','"','"','l','i','n','e','1',10,'l','i','n','e','2','"','"','"'
bad: db '"','"','x','"','"'

section .bss
align 8
segment_record: resb NEBO_TEXT_SEGMENT_SIZE

section .text
global _start
_start:
 lea rdi,[rel raw]
 mov esi,14
 call neboc_raw_literal_scan
 test eax,eax
 jnz fail
 cmp rcx,3
 jne fail
 cmp rdx,8
 jne fail
 cmp byte [rel raw+5],'{'
 jne fail
 cmp byte [rel raw+9],0x5c
 jne fail

 lea rdi,[rel multiline]
 mov esi,17
 call neboc_raw_literal_scan
 test eax,eax
 jnz fail
 cmp rcx,3
 jne fail
 cmp rdx,11
 jne fail
 cmp byte [rel multiline+8],10
 jne fail

 lea rdi,[rel raw+3]
 mov esi,8
 mov edx,71
 lea rcx,[rel segment_record]
 call neboc_text_segment_init
 test eax,eax
 jnz fail
 cmp qword [rel segment_record+NEBO_TEXT_SEGMENT_KIND_OFFSET],NEBO_TEXT_SEGMENT_LITERAL
 jne fail
 cmp qword [rel segment_record+NEBO_TEXT_SEGMENT_LENGTH_OFFSET],8
 jne fail
 cmp qword [rel segment_record+NEBO_TEXT_SEGMENT_START_OFFSET],71
 jne fail
 cmp qword [rel segment_record+NEBO_TEXT_SEGMENT_END_OFFSET],79
 jne fail

 mov qword [rel segment_record],0x11111111
 lea rdi,[rel raw]
 mov esi,4
 mov rdx,-2
 lea rcx,[rel segment_record]
 call neboc_text_segment_init
 cmp eax,NEBO_LITERAL_UNTERMINATED
 jne fail
 cmp qword [rel segment_record],0x11111111
 jne fail

 lea rdi,[rel bad]
 mov esi,5
 call neboc_raw_literal_scan
 cmp eax,NEBO_LITERAL_UNTERMINATED
 jne fail
 xor edi,edi
 xor esi,esi
 call neboc_raw_literal_scan
 cmp eax,NEBO_LITERAL_NULL
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
