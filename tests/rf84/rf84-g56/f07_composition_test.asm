bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
extern neboc_text_parse_int
extern neboc_text_checked_add
extern neboc_int_to_text
extern neboc_text_equal
section .rodata
input_data: db '4','2'
expected_data: db '5','0'
align 8
input: dq input_data,2,NEBO_TEXT_FLAG_ASCII,0
expected: dq expected_data,2,NEBO_TEXT_FLAG_ASCII,0
section .bss
value: resq 1
sum: resq 1
out_data: resb 8
out: resb NEBO_TEXT_DESCRIPTOR_SIZE
section .text
global _start
_start:
 lea rdi,[rel input]
 mov esi,10
 lea rdx,[rel value]
 call neboc_text_parse_int
 test eax,eax
 jnz fail
 mov rdi,[rel value]
 mov esi,8
 lea rdx,[rel sum]
 call neboc_text_checked_add
 test eax,eax
 jnz fail
 mov rdi,[rel sum]
 lea rsi,[rel out_data]
 mov edx,8
 lea rcx,[rel out]
 call neboc_int_to_text
 test eax,eax
 jnz fail
 lea rdi,[rel out]
 lea rsi,[rel expected]
 call neboc_text_equal
 cmp eax,1
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,7
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
