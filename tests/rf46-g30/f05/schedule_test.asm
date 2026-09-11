bits 64
default rel
%include "runtime/solver/schedule.inc"
extern nebo_schedule_task_validate,nebo_schedule_before,nebo_schedule_no_overlap,nebo_schedule_capacity_at,nebo_schedule_makespan
section .data
tasks:
 dq 0,3,1,2
 dq 3,4,1,3
 overlap dq 2,3,1,4
section .bss
makespan resq 1
section .text
global _start
_start:
 lea rdi,[tasks]
 mov esi,10
 call nebo_schedule_task_validate
 test eax,eax
 jnz fail
 lea rdi,[tasks]
 lea rsi,[tasks+nebo_schedule_TASK_SIZE]
 call nebo_schedule_before
 test eax,eax
 jnz fail
 lea rdi,[tasks]
 lea rsi,[overlap]
 call nebo_schedule_no_overlap
 cmp eax,NEBO_SCHEDULE_STATUS_CONFLICT
 jne fail
 lea rdi,[tasks]
 mov esi,2
 mov edx,3
 mov ecx,3
 call nebo_schedule_capacity_at
 test eax,eax
 jnz fail
 lea rdi,[tasks]
 mov esi,2
 lea rdx,[makespan]
 call nebo_schedule_makespan
 test eax,eax
 jnz fail
 cmp qword [makespan],7
 jne fail
 xor edi,edi
 jmp exit
fail: mov edi,1
exit: mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
