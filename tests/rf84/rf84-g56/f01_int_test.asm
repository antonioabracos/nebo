bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
extern neboc_text_parse_int
section .rodata
positive_data: db '1','2','3'
negative_data: db '-','4','2'
bad_data: db '1','x'
align 8
positive: dq positive_data,3,NEBO_TEXT_FLAG_ASCII,0
negative: dq negative_data,3,NEBO_TEXT_FLAG_ASCII,0
bad: dq bad_data,2,NEBO_TEXT_FLAG_ASCII,0
section .bss
value: resq 1
section .text
global _start
_start:
 lea rdi,[rel positive]
 mov esi,10
 lea rdx,[rel value]
 call neboc_text_parse_int
 test eax,eax
 jnz fail
 cmp qword [rel value],123
 jne fail
 lea rdi,[rel negative]
 xor esi,esi
 lea rdx,[rel value]
 call neboc_text_parse_int
 test eax,eax
 jnz fail
 cmp qword [rel value],-42
 jne fail
 mov qword [rel value],77
 lea rdi,[rel bad]
 mov esi,10
 lea rdx,[rel value]
 call neboc_text_parse_int
 cmp eax,NEBO_PARSE_INVALID_DIGIT
 jne fail
 cmp qword [rel value],77
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
