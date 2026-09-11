bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_byte_length
extern neboc_text_is_empty
section .rodata
data: db 'x'
align 8
text: dq data,1,NEBO_TEXT_FLAG_ASCII,0
empty: dq 0,0,0,0
section .text
global _start
_start:
 lea rdi,[rel text]
 call neboc_text_byte_length
 cmp eax,1
 jne fail
 call neboc_text_is_empty
 test eax,eax
 jnz fail
 lea rdi,[rel empty]
 call neboc_text_is_empty
 cmp eax,1
 jne fail
 xor edi,edi
 call neboc_text_byte_length
 cmp rax,-1
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
