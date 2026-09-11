bits 64
default rel
%include "runtime/textual/text_core.inc"
extern neboc_text_replace_once_byte
extern neboc_text_replace_all_byte
section .rodata
data: db 'a','b','a'
align 8
text: dq data,3,NEBO_TEXT_FLAG_ASCII,0
section .bss
once: resb 4
all: resb 4
desc: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel text]
 mov esi,'a'
 mov edx,'x'
 lea rcx,[rel once]
 mov r8d,3
 lea r9,[rel desc]
 call neboc_text_replace_once_byte
 test eax,eax
 jnz fail
 cmp dword [rel once],0x00616278
 jne fail
 lea rdi,[rel text]
 mov esi,'a'
 mov edx,'x'
 lea rcx,[rel all]
 mov r8d,3
 lea r9,[rel desc]
 call neboc_text_replace_all_byte
 test eax,eax
 jnz fail
 cmp dword [rel all],0x00786278
 jne fail
 mov qword [rel desc],0x55
 lea rdi,[rel text]
 mov esi,'a'
 mov edx,'x'
 lea rcx,[rel all]
 mov r8d,2
 lea r9,[rel desc]
 call neboc_text_replace_all_byte
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 cmp qword [rel desc],0x55
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
