bits 64
default rel
%include "runtime/solver/optimize.inc"
extern nebo_optimize_i64
section .data
values dq 9,-3,12,5
section .bss
result resb NEBO_OPTIMIZE_RESULT_SIZE
section .text
global _start
_start:
 lea rdi,[values]
 mov esi,4
 mov edx,NEBO_OPTIMIZE_MINIMIZE
 mov ecx,4
 lea r8,[result]
 call nebo_optimize_i64
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_OPTIMIZE_STATE_OPTIMAL
 jne fail
 cmp qword [result+8],-3
 jne fail
 cmp qword [result+16],1
 jne fail
 lea rdi,[values]
 mov esi,4
 mov edx,NEBO_OPTIMIZE_MAXIMIZE
 mov ecx,2
 lea r8,[result]
 call nebo_optimize_i64
 test eax,eax
 jnz fail
 cmp qword [result],NEBO_OPTIMIZE_STATE_GAP_BOUNDED
 jne fail
 cmp qword [result+32],2
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
