bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_find
extern neboc_text_view
extern neboc_text_equal
section .rodata
data: db 'x','n','e','b','o','y'
needle_data: db 'n','e','b','o'
align 8
text: dq data,6,NEBO_TEXT_FLAG_ASCII,0
needle: dq needle_data,4,NEBO_TEXT_FLAG_ASCII,0
section .bss
view: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 lea rsi,[rel needle]
 call neboc_text_find
 cmp rax,1
 jne fail
 lea rdi,[rel text]
 mov rsi,rax
 mov edx,4
 lea rcx,[rel view]
 call neboc_text_view
 test eax,eax
 jnz fail
 lea rdi,[rel view]
 lea rsi,[rel needle]
 call neboc_text_equal
 cmp eax,1
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,7
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
