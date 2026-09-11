bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_starts_with
extern neboc_text_ends_with
extern neboc_text_contains
section .rodata
data: db 'n','e','b','o'
pre_data: db 'n','e'
end_data: db 'b','o'
miss_data: db 'x'
align 8
text: dq data,4,NEBO_TEXT_FLAG_ASCII,0
pre: dq pre_data,2,NEBO_TEXT_FLAG_ASCII,0
ending: dq end_data,2,NEBO_TEXT_FLAG_ASCII,0
miss: dq miss_data,1,NEBO_TEXT_FLAG_ASCII,0
section .text
%macro TRUE_CALL 3
 lea rdi,[rel %2]
 lea rsi,[rel %3]
 call %1
 cmp eax,1
 jne fail
%endmacro
global _start
_start:
 TRUE_CALL neboc_text_starts_with,text,pre
 TRUE_CALL neboc_text_ends_with,text,ending
 TRUE_CALL neboc_text_contains,text,ending
 lea rdi,[rel text]
 lea rsi,[rel miss]
 call neboc_text_contains
 test eax,eax
 jnz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,3
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
