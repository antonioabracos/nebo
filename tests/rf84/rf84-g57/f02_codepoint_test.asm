bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_codepoint_count
extern neboc_codepoint_slice
section .rodata
data: db 'A',0xc3,0xa9,0xf0,0x9f,0x98,0x80
align 8
text: dq data,7,NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
slice: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 call neboc_codepoint_count
 cmp rax,3
 jne fail
 lea rdi,[rel text]
 mov esi,1
 mov edx,1
 lea rcx,[rel slice]
 call neboc_codepoint_slice
 test eax,eax
 jnz fail
 cmp qword [rel slice+NEBO_TEXT_LENGTH_OFFSET],2
 jne fail
 mov rax,[rel slice]
 cmp word [rax],0xa9c3
 jne fail
 lea rdi,[rel text]
 mov esi,4
 mov edx,1
 lea rcx,[rel slice]
 call neboc_codepoint_slice
 cmp eax,NEBO_UNICODE_BOUNDS
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
