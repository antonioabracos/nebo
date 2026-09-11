bits 64
default rel
%include "runtime/workflow/fsm.inc"
extern nebo_fsm_step
section .data
table dq 1,10,2, 2,20,3
ambiguous dq 1,10,2, 1,10,3
section .bss
next_state resq 1
section .text
global _start
_start:
 lea rdi,[table]
 mov esi,2
 mov edx,1
 mov ecx,10
 lea r8,[next_state]
 call nebo_fsm_step
 test eax,eax
 jnz fail
 cmp qword [next_state],2
 jne fail
 lea rdi,[ambiguous]
 mov esi,2
 mov edx,1
 mov ecx,10
 lea r8,[next_state]
 call nebo_fsm_step
 cmp eax,NEBO_FSM_NONDETERMINISTIC
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
