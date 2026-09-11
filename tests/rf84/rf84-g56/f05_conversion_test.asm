bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_int_to_text
extern neboc_bool_to_text
section .bss
out: resb 8
text: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 mov qword [rel text+NEBO_TEXT_AUX_OFFSET],8
 mov rdi,-42
 lea rsi,[rel out]
 mov edx,8
 lea rcx,[rel text]
 call neboc_int_to_text
 test eax,eax
 jnz fail
 cmp dword [rel out],0x0032342d
 jne fail
 cmp qword [rel text+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 mov edi,1
 lea rsi,[rel text]
 call neboc_bool_to_text
 test eax,eax
 jnz fail
 mov rax,[rel text]
 cmp dword [rax],0x65757274
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,5
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
