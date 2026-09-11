bits 64
default rel
%include "runtime/knowledge/hybrid.inc"
extern nebo_hybrid_score_v1
section .data
a dq 1,2,3
b dq 4,5,6
section .bss
semantic resq 1
total resq 1
section .text
global _start
_start:
 lea rdi,[a]
 lea rsi,[b]
 mov edx,3
 mov ecx,7
 lea r8,[semantic]
 lea r9,[total]
 call nebo_hybrid_score_v1
 test eax,eax
 jnz fail
 cmp qword [semantic],32
 jne fail
 cmp qword [total],85
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
