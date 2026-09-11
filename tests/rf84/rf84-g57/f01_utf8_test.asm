bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_utf8_next
extern neboc_utf8_validate
section .rodata
valid_data: db 'O','l',0xc3,0xa1,0xf0,0x9f,0x98,0x80
invalid_data: db 0xc0,0x80
align 8
valid: dq valid_data,8,NEBO_TEXT_FLAG_VALID_UTF8,0
invalid: dq invalid_data,2,0,0
section .bss
cp: resd 1
next: resq 1
error: resq 1
section .text
global _start
_start:
 lea rdi,[rel valid]
 lea rsi,[rel error]
 call neboc_utf8_validate
 test eax,eax
 jnz fail
 lea rdi,[rel valid_data]
 mov esi,8
 mov edx,4
 lea rcx,[rel cp]
 lea r8,[rel next]
 call neboc_utf8_next
 test eax,eax
 jnz fail
 cmp dword [rel cp],0x1f600
 jne fail
 cmp qword [rel next],8
 jne fail
 lea rdi,[rel invalid]
 lea rsi,[rel error]
 call neboc_utf8_validate
 cmp eax,NEBO_UNICODE_INVALID_UTF8
 jne fail
 cmp qword [rel error],0
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
