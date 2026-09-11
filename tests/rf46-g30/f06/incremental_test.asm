bits 64
default rel
%include "runtime/solver/incremental.inc"
extern nebo_incremental_init,nebo_incremental_push,nebo_incremental_add,nebo_incremental_pop,nebo_incremental_cancel,nebo_incremental_checkpoint,nebo_incremental_resume_validate,nebo_solver_unsat_core
section .bss
state resb NEBO_INCREMENTAL_STATE_SIZE
marks resq NEBO_INCREMENTAL_MAX_DEPTH
checkpoint resb nebo_incremental_CHECKPOINT_SIZE
core resq 1
section .text
global _start
_start:
 lea rdi,[state]
 lea rsi,[marks]
 mov edx,77
 call nebo_incremental_init
 test eax,eax
 jnz fail
 lea rdi,[state]
 call nebo_incremental_push
 test eax,eax
 jnz fail
 lea rdi,[state]
 mov esi,3
 call nebo_incremental_add
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_INCREMENTAL_STATE_CONSTRAINTS],3
 jne fail
 lea rdi,[state]
 call nebo_incremental_pop
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_INCREMENTAL_STATE_CONSTRAINTS],0
 jne fail
 lea rdi,[state]
 lea rsi,[checkpoint]
 call nebo_incremental_checkpoint
 test eax,eax
 jnz fail
 lea rdi,[checkpoint]
 mov esi,77
 call nebo_incremental_resume_validate
 test eax,eax
 jnz fail
 mov edi,5
 mov esi,1
 lea rdx,[core]
 call nebo_solver_unsat_core
 test eax,eax
 jnz fail
 cmp qword [core],1
 jne fail
 lea rdi,[state]
 call nebo_incremental_cancel
 test eax,eax
 jnz fail
 lea rdi,[state]
 lea rsi,[checkpoint]
 call nebo_incremental_checkpoint
 cmp eax,NEBO_INCREMENTAL_STATUS_CANCELLED
 jne fail
 cmp qword [checkpoint],0
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
