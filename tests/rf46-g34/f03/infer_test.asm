bits 64
default rel
%include "runtime/reasoning/infer.inc"
extern nebo_infer_fixpoint
section .data
rules dq 1,2, 2,4, 6,8
section .bss
state resq 1
rounds resq 1
section .text
global _start
_start:
 lea rdi,[rules]
 mov esi,3
 mov edx,1
 mov ecx,8
 lea r8,[state]
 lea r9,[rounds]
 call nebo_infer_fixpoint
 test eax,eax
 jnz fail
 cmp qword [state],15
 jne fail
 cmp qword [rounds],4
 ja fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
