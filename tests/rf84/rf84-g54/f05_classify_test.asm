bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_query.inc"
extern neboc_text_classify
section .rodata
digits_data: db '1','2','3'
alpha_data: db 'N','e','b','o'
blank_data: db ' ',9,10
align 8
digits: dq digits_data,3,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0
alpha: dq alpha_data,4,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0
blank: dq blank_data,3,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0
section .text
global _start
_start:
 lea rdi,[rel digits]
 call neboc_text_classify
 test eax,NEBO_QUERY_CLASS_DIGITS
 jz fail
 test eax,NEBO_QUERY_CLASS_ALNUM
 jz fail
 lea rdi,[rel alpha]
 call neboc_text_classify
 test eax,NEBO_QUERY_CLASS_ALPHA
 jz fail
 test eax,NEBO_QUERY_CLASS_DIGITS
 jnz fail
 lea rdi,[rel blank]
 call neboc_text_classify
 test eax,NEBO_QUERY_CLASS_BLANK
 jz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
