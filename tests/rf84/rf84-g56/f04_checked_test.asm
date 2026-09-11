bits 64
default rel
%include "runtime/textual/text_parse.inc"
extern neboc_text_parse_error_diagnostic
extern neboc_text_checked_add
section .bss
value: resq 1
section .text
global _start
_start:
 mov edi,NEBO_PARSE_OVERFLOW
 call neboc_text_parse_error_diagnostic
 cmp eax,NEBO_PARSE_DIAG_BASE+NEBO_PARSE_OVERFLOW
 jne fail
 mov edi,40
 mov esi,2
 lea rdx,[rel value]
 call neboc_text_checked_add
 test eax,eax
 jnz fail
 cmp qword [rel value],42
 jne fail
 mov qword [rel value],77
 mov rdi,0x7fffffffffffffff
 mov esi,1
 lea rdx,[rel value]
 call neboc_text_checked_add
 cmp eax,NEBO_PARSE_OVERFLOW
 jne fail
 cmp qword [rel value],77
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,4
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
