bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_utf8_validate
extern neboc_codepoint_count
extern neboc_grapheme_count
extern neboc_unicode_normalize_latin
extern neboc_unicode_casefold_root
section .rodata
; The frozen local profile covers ASCII, Latin-1 e-acute and combining U+0301.
source_data: db 'A','e',0xcc,0x81
align 8
source: dq source_data,4,NEBO_TEXT_FLAG_VALID_UTF8,0
section .bss
error_offset: resq 1
normalized_bytes: resb 8
normalized: resb NEBO_TEXT_DESCRIPTOR_SIZE
folded_bytes: resb 8
folded: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel source]
 lea rsi,[rel error_offset]
 call neboc_utf8_validate
 test eax,eax
 jnz fail
 cmp qword [rel error_offset],-1
 jne fail
 lea rdi,[rel source]
 call neboc_codepoint_count
 cmp rax,3
 jne fail
 lea rdi,[rel source]
 call neboc_grapheme_count
 cmp rax,2
 jne fail
 lea rdi,[rel source]
 mov esi,NEBO_NORMALIZE_NFC
 lea rdx,[rel normalized_bytes]
 mov ecx,8
 lea r8,[rel normalized]
 call neboc_unicode_normalize_latin
 test eax,eax
 jnz fail
 cmp qword [rel normalized+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 cmp byte [rel normalized_bytes],'A'
 jne fail
 cmp word [rel normalized_bytes+1],0xa9c3
 jne fail
 lea rdi,[rel normalized]
 lea rsi,[rel folded_bytes]
 mov edx,8
 lea rcx,[rel folded]
 call neboc_unicode_casefold_root
 test eax,eax
 jnz fail
 cmp qword [rel folded+NEBO_TEXT_LENGTH_OFFSET],3
 jne fail
 cmp byte [rel folded_bytes],'a'
 jne fail
 cmp word [rel folded_bytes+1],0xa9c3
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,8
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
