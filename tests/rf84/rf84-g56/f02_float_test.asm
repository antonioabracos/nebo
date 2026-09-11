bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_parse.inc"
extern neboc_text_parse_float
section .rodata
decimal_data: db '1','2','.','5'
bad_data: db '1','.','2','.','3'
align 8
decimal: dq decimal_data,4,NEBO_TEXT_FLAG_ASCII,0
bad: dq bad_data,5,NEBO_TEXT_FLAG_ASCII,0
expected: dq 12.5
section .bss
value: resq 1
section .text
global _start
_start:
 lea rdi,[rel decimal]
 lea rsi,[rel value]
 call neboc_text_parse_float
 test eax,eax
 jnz fail
 movsd xmm0,[rel value]
 ucomisd xmm0,[rel expected]
 jne fail
 mov qword [rel value],0x55
 lea rdi,[rel bad]
 lea rsi,[rel value]
 call neboc_text_parse_float
 cmp eax,NEBO_PARSE_INVALID_DIGIT
 jne fail
 cmp qword [rel value],0x55
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,2
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
