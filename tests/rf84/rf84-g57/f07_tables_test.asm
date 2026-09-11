bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/unicode.inc"
extern neboc_unicode_table_version
extern neboc_unicode_table_bytes
extern neboc_unicode_budget_check
section .text
global _start
_start:
 call neboc_unicode_table_version
 cmp eax,NEBO_UNICODE_PROFILE_VERSION
 jne fail
 call neboc_unicode_table_bytes
 cmp eax,NEBO_UNICODE_TABLE_BYTES
 jne fail
 mov edi,100
 mov esi,150
 call neboc_unicode_budget_check
 test eax,eax
 jnz fail
 mov edi,100
 mov esi,151
 call neboc_unicode_budget_check
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 mov rdi,NEBO_UNICODE_MAX_INPUT_BYTES+1
 xor esi,esi
 call neboc_unicode_budget_check
 cmp eax,NEBO_TEXT_ERROR_CAPACITY
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,7
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
