bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
extern neboc_text_trim_ascii
extern neboc_text_case_ascii
section .rodata
data: db ' ',9,'N','e','B','o',10
align 8
text: dq data,7,NEBO_TEXT_FLAG_ASCII | NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
trimmed: resb NEBO_TEXT_DESCRIPTOR_SIZE
lower_data: resb 8
lower: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 lea rsi,[rel trimmed]
 call neboc_text_trim_ascii
 test eax,eax
 jnz fail
 cmp qword [rel trimmed+NEBO_TEXT_LENGTH_OFFSET],4
 jne fail
 lea rdi,[rel trimmed]
 lea rsi,[rel lower_data]
 mov edx,8
 mov ecx,NEBO_CASE_LOWER
 lea r8,[rel lower]
 call neboc_text_case_ascii
 test eax,eax
 jnz fail
 cmp dword [rel lower_data],0x6f62656e
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
