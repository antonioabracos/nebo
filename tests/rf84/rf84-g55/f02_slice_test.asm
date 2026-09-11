bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_slice_bytes
section .rodata
data: db 'a','b','c','d'
align 8
text: dq data,4,NEBO_TEXT_FLAG_ASCII,0
section .bss
slice: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 mov esi,1
 mov edx,3
 lea rcx,[rel slice]
 call neboc_text_slice_bytes
 test eax,eax
 jnz fail
 cmp qword [rel slice+NEBO_TEXT_LENGTH_OFFSET],2
 jne fail
 mov rax,[rel slice]
 cmp word [rax],0x6362
 jne fail
 mov r10,[rel slice]
 lea rdi,[rel text]
 mov esi,3
 mov edx,2
 lea rcx,[rel slice]
 call neboc_text_slice_bytes
 cmp eax,NEBO_TEXT_ERROR_BOUNDS
 jne fail
 cmp [rel slice],r10
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
