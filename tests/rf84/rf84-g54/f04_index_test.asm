bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_query.inc"
extern neboc_text_find
extern neboc_text_rfind
section .rodata
data: db 'a','b','a','b'
needle_data: db 'a','b'
miss_data: db 'z'
align 8
text: dq data,4,NEBO_TEXT_FLAG_ASCII,0
needle: dq needle_data,2,NEBO_TEXT_FLAG_ASCII,0
miss: dq miss_data,1,NEBO_TEXT_FLAG_ASCII,0
section .text
global _start
_start:
 lea rdi,[rel text]
 lea rsi,[rel needle]
 call neboc_text_find
 test rax,rax
 jnz fail
 lea rdi,[rel text]
 lea rsi,[rel needle]
 call neboc_text_rfind
 cmp rax,2
 jne fail
 lea rdi,[rel text]
 lea rsi,[rel miss]
 call neboc_text_find
 cmp rax,NEBO_QUERY_NOT_FOUND
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
