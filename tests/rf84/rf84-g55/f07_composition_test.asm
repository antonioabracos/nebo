bits 64
default rel
%include "runtime/textual/text_core.inc"
%include "runtime/textual/text_transform.inc"
extern neboc_text_trim_ascii
extern neboc_text_case_ascii
extern neboc_text_split_byte
section .rodata
data: db ' ','a',',','b',' '
align 8
text: dq data,5,NEBO_TEXT_FLAG_ASCII,0
section .bss
trimmed: resb NEBO_TEXT_DESCRIPTOR_SIZE
upper_data: resb 4
upper: resb NEBO_TEXT_DESCRIPTOR_SIZE
items: resb NEBO_SPLIT_ITEM_SIZE*2
section .text
global _start
_start:
 lea rdi,[rel text]
 lea rsi,[rel trimmed]
 call neboc_text_trim_ascii
 test eax,eax
 jnz fail
 lea rdi,[rel trimmed]
 lea rsi,[rel upper_data]
 mov edx,4
 mov ecx,NEBO_CASE_UPPER
 lea r8,[rel upper]
 call neboc_text_case_ascii
 test eax,eax
 jnz fail
 lea rdi,[rel upper]
 mov esi,','
 lea rdx,[rel items]
 mov ecx,2
 call neboc_text_split_byte
 cmp eax,2
 jne fail
 mov rax,[rel items]
 cmp byte [rax],'A'
 jne fail
 mov rax,[rel items+NEBO_SPLIT_ITEM_SIZE]
 cmp byte [rax],'B'
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail:
 mov edi,7
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
