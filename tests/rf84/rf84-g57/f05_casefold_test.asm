bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_unicode_casefold_root
section .rodata
data: db 0xc3,0x89,'A'
align 8
text: dq data,3,NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
out: resb 4
folded: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 lea rsi,[rel out]
 mov edx,4
 lea rcx,[rel folded]
 call neboc_unicode_casefold_root
 test eax,eax
 jnz fail
 cmp word [rel out],0xa9c3
 jne fail
 cmp byte [rel out+2],'a'
 jne fail
 mov qword [rel folded],0x77
 lea rdi,[rel text]
 lea rsi,[rel out]
 mov edx,2
 lea rcx,[rel folded]
 call neboc_unicode_casefold_root
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel folded],0x77
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
