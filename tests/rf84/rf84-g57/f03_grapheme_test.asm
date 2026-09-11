bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_grapheme_count
extern neboc_grapheme_slice
section .rodata
data: db 'A',0xcc,0x81,'B'
align 8
text: dq data,4,NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
slice: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 call neboc_grapheme_count
 cmp eax,2
 jne fail
 lea rdi,[rel text]
 xor esi,esi
 mov edx,1
 lea rcx,[rel slice]
 call neboc_grapheme_slice
 test eax,eax
 jnz fail
 cmp qword [rel slice+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 lea rdi,[rel text]
 mov esi,1
 mov edx,1
 lea rcx,[rel slice]
 call neboc_grapheme_slice
 test eax,eax
 jnz fail
 cmp qword [rel slice+NEBO_TEXT_LENGTH_OFFSET],1
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,3
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
