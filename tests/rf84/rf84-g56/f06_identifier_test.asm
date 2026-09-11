bits 64
default rel
%include "compiler/parser/text_contract.inc"
extern neboc_text_is_nebo_identifier
section .rodata
valid: db '_','n','e','b','o','4','2'
digit: db '4','2'
dash: db 'a','-','b'
unicode: db 0xc3,0xa9
keyword: db 'w','h','i','l','e'
section .text
global _start
_start:
 lea rdi,[rel valid]
 mov esi,7
 call neboc_text_is_nebo_identifier
 cmp eax,1
 jne fail
 lea rdi,[rel digit]
 mov esi,2
 call neboc_text_is_nebo_identifier
 test eax,eax
 jnz fail
 lea rdi,[rel keyword]
 mov esi,5
 call neboc_text_is_nebo_identifier
 test eax,eax
 jnz fail
 lea rdi,[rel dash]
 mov esi,3
 call neboc_text_is_nebo_identifier
 test eax,eax
 jnz fail
 lea rdi,[rel unicode]
 mov esi,2
 call neboc_text_is_nebo_identifier
 test eax,eax
 jnz fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
