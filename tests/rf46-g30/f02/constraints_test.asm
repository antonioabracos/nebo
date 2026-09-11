bits 64
default rel
%include "runtime/solver/constraints.inc"
extern nebo_constraint_check
section .data
one dq 0,1,0,0
distinct dq 2,4,6,8
duplicate dq 2,4,2
sum dq 10,-3,5
section .text
global _start
_start:
 mov edi,NEBO_CONSTRAINT_EXACTLY_ONE
 lea rsi,[one]
 mov edx,4
 xor ecx,ecx
 call nebo_constraint_check
 test eax,eax
 jnz fail
 mov edi,NEBO_CONSTRAINT_ALL_DIFFERENT
 lea rsi,[distinct]
 mov edx,4
 call nebo_constraint_check
 test eax,eax
 jnz fail
 mov edi,NEBO_CONSTRAINT_ALL_DIFFERENT
 lea rsi,[duplicate]
 mov edx,3
 call nebo_constraint_check
 cmp eax,NEBO_CONSTRAINT_STATUS_UNSAT
 jne fail
 mov edi,NEBO_CONSTRAINT_SUM_EQUALS
 lea rsi,[sum]
 mov edx,3
 mov ecx,12
 call nebo_constraint_check
 test eax,eax
 jnz fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
