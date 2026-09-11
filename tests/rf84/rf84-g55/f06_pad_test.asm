bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
extern neboc_text_pad_ascii
section .rodata
data: db 'x','y'
align 8
text: dq data,2,NEBO_TEXT_FLAG_ASCII,0
section .bss
out: resb 4
builder: resb NEBO_BUILDER_SIZE
section .text
global _start
_start:
 lea rax,[rel out]
 mov [rel builder+NEBO_BUILDER_DATA_OFFSET],rax
 mov qword [rel builder+NEBO_BUILDER_CAPACITY_OFFSET],4
 lea rdi,[rel text]
 mov esi,4
 mov edx,'.'
 mov ecx,NEBO_PAD_LEFT
 lea r8,[rel builder]
 call neboc_text_pad_ascii
 test eax,eax
 jnz fail
 cmp dword [rel out],0x79782e2e
 jne fail
 cmp qword [rel builder+NEBO_BUILDER_LENGTH_OFFSET],4
 jne fail
 lea rdi,[rel text]
 mov esi,5
 mov edx,'.'
 mov ecx,NEBO_PAD_RIGHT
 lea r8,[rel builder]
 call neboc_text_pad_ascii
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
