bits 64
default rel
%include "runtime/concurrency/scheduler.inc"
section .bss
budget resb NEBO_SCHEDULER_BUDGET_SIZE
scheduler resb NEBO_SCHEDULER_SIZE
queue resb nebo_concurrency_contract_TASK_SIZE*3
trace resb NEBO_TRACE_EVENT_SIZE*8
section .text
global _start
task: lea rax,[rdi+100]
 xor edx,edx
 ret
_start:
 lea rdi,[budget]
 mov esi,2
 mov edx,3
 mov ecx,3
 mov r8d,8
 mov r9d,32
 call nebo_scheduler_budget_init
 test eax,eax
 jnz .fail1
 lea rdi,[scheduler]
 lea rsi,[budget]
 lea rdx,[queue]
 mov ecx,3
 lea r8,[trace]
 mov r9d,8
 call nebo_scheduler_init
 test eax,eax
 jnz .fail2
 lea rdi,[scheduler]
 lea rsi,[queue]
 lea rdx,[task]
 mov ecx,1
 call nebo_scheduler_enqueue
 test eax,eax
 jnz .fail3
 lea rdi,[scheduler]
 lea rsi,[queue+nebo_concurrency_contract_TASK_SIZE]
 lea rdx,[task]
 mov ecx,2
 call nebo_scheduler_enqueue
 test eax,eax
 jnz .fail4
 lea rdi,[scheduler]
 call nebo_scheduler_queue_depth
 test eax,eax
 jnz .fail5
 cmp rdx,2
 jne .fail6
 lea rdi,[scheduler]
 mov esi,1
 call nebo_scheduler_run
 test eax,eax
 jnz .fail7
 cmp rdx,1
 jne .fail8
 cmp qword [queue+NEBO_TASK_RESULT],101
 jne .fail9
 lea rdi,[scheduler]
 call nebo_scheduler_shutdown
 cmp eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
 jne .fail10
 lea rdi,[scheduler]
 mov esi,3
 call nebo_scheduler_run
 test eax,eax
 jnz .fail11
 cmp rdx,1
 jne .fail12
 cmp qword [queue+nebo_concurrency_contract_TASK_SIZE+NEBO_TASK_RESULT],102
 jne .fail13
 lea rdi,[scheduler]
 call nebo_scheduler_shutdown
 test eax,eax
 jnz .fail14
 lea rdi,[scheduler]
 call nebo_scheduler_shutdown
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail15
 lea rdi,[scheduler]
 lea rsi,[queue+nebo_concurrency_contract_TASK_SIZE*2]
 lea rdx,[task]
 xor ecx,ecx
 call nebo_scheduler_enqueue
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jne .fail16
 cmp qword [scheduler+NEBO_SCHEDULER_TRACE_COUNT],4
 jne .fail17
 cmp qword [trace+NEBO_TRACE_EVENT],1
 jne .fail18
 xor rdi,rdi
 call nebo_scheduler_queue_depth
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail19
 xor edi,edi
 jmp .exit
%assign i 1
%rep 19
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
