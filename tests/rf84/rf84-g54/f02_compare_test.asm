bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_equal
extern neboc_text_compare_ascii
section .rodata
a_data: db 'a','b'
b_data: db 'a','c'
align 8
a: dq a_data,2,NEBO_TEXT_FLAG_ASCII,0
a2: dq a_data,2,NEBO_TEXT_FLAG_ASCII,0
b: dq b_data,2,NEBO_TEXT_FLAG_ASCII,0
section .text
global _start
_start:
 lea rdi,[rel a]
 lea rsi,[rel a2]
 call neboc_text_equal
 cmp eax,1
 jne fail
 lea rdi,[rel a]
 lea rsi,[rel b]
 call neboc_text_equal
 test eax,eax
 jnz fail
 lea rdi,[rel a]
 lea rsi,[rel b]
 call neboc_text_compare_ascii
 cmp eax,-1
 jne fail
 lea rdi,[rel b]
 lea rsi,[rel a]
 call neboc_text_compare_ascii
 cmp eax,1
 jne fail
 lea rdi,[rel a]
 lea rsi,[rel a2]
 call neboc_text_compare_ascii
 test eax,eax
 jnz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
