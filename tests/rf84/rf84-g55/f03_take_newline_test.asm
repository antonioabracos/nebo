bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
extern neboc_text_take_drop
extern neboc_text_normalize_newlines
section .rodata
data: db 'a',13,10,'b',13,'c'
align 8
text: dq data,6,NEBO_TEXT_FLAG_ASCII,0
section .bss
view: resb NEBO_TEXT_DESCRIPTOR_SIZE
out: resb 8
normalized: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 mov esi,2
 mov edx,NEBO_TAKE
 lea rcx,[rel view]
 call neboc_text_take_drop
 test eax,eax
 jnz fail
 cmp qword [rel view+NEBO_TEXT_LENGTH_OFFSET],2
 jne fail
 lea rdi,[rel text]
 lea rsi,[rel out]
 mov edx,8
 lea rcx,[rel normalized]
 call neboc_text_normalize_newlines
 test eax,eax
 jnz fail
 cmp qword [rel normalized+NEBO_TEXT_LENGTH_OFFSET],5
 jne fail
 cmp byte [rel out+1],10
 jne fail
 cmp byte [rel out+3],10
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,3
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
