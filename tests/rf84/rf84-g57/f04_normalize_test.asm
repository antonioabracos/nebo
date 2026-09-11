bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_unicode_profile_version
extern neboc_unicode_normalize_latin
section .rodata
nfd_data: db 'e',0xcc,0x81
align 8
nfd: dq nfd_data,3,NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
out: resb 4
normalized: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 call neboc_unicode_profile_version
 cmp eax,NEBO_UNICODE_PROFILE_VERSION
 jne fail
 mov qword [rel normalized+NEBO_TEXT_AUX_OFFSET],4
 lea rdi,[rel nfd]
 mov esi,NEBO_NORMALIZE_NFC
 lea rdx,[rel out]
 mov ecx,4
 lea r8,[rel normalized]
 call neboc_unicode_normalize_latin
 test eax,eax
 jnz fail
 cmp qword [rel normalized+NEBO_TEXT_LENGTH_OFFSET],2
 jne fail
 cmp word [rel out],0xa9c3
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
