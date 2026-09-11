bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
extern neboc_text_parse_bool
section .rodata
true_data: db 't','r','u','e'
false_data: db 'f','a','l','s','e'
bad_data: db 'T','r','u','e'
align 8
true_text: dq true_data,4,NEBO_TEXT_FLAG_ASCII,0
false_text: dq false_data,5,NEBO_TEXT_FLAG_ASCII,0
bad_text: dq bad_data,4,NEBO_TEXT_FLAG_ASCII,0
section .bss
value: resb 1
section .text
global _start
_start:
 lea rdi,[rel true_text]
 lea rsi,[rel value]
 call neboc_text_parse_bool
 test eax,eax
 jnz fail
 cmp byte [rel value],1
 jne fail
 lea rdi,[rel false_text]
 lea rsi,[rel value]
 call neboc_text_parse_bool
 test eax,eax
 jnz fail
 cmp byte [rel value],0
 jne fail
 mov byte [rel value],7
 lea rdi,[rel bad_text]
 lea rsi,[rel value]
 call neboc_text_parse_bool
 cmp eax,NEBO_PARSE_INVALID_DIGIT
 jne fail
 cmp byte [rel value],7
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,3
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
