bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_unicode_locale_supported
extern neboc_unicode_collate_root
section .rodata
a_data: db 'a'
b_data: db 'b'
align 8
a: dq a_data,1,NEBO_TEXT_FLAG_VALID_UTF8,0
b: dq b_data,1,NEBO_TEXT_FLAG_VALID_UTF8,0
section .text
global _start
_start:
 mov edi,NEBO_LOCALE_ROOT
 call neboc_unicode_locale_supported
 cmp eax,1
 jne fail
 mov edi,1
 call neboc_unicode_locale_supported
 test eax,eax
 jnz fail
 lea rdi,[rel a]
 lea rsi,[rel b]
 mov edx,NEBO_LOCALE_ROOT
 call neboc_unicode_collate_root
 cmp eax,-1
 jne fail
 lea rdi,[rel a]
 lea rsi,[rel b]
 mov edx,1
 call neboc_unicode_collate_root
 cmp eax,-NEBO_UNICODE_UNSUPPORTED
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,6
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
