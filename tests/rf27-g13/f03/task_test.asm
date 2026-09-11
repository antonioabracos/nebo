bits 64
default rel
%include "runtime/concurrency/task.inc"

section .bss
budget resb NEBO_SCHEDULER_BUDGET_SIZE
group resb NEBO_TASK_GROUP_SIZE
tasks resb nebo_concurrency_contract_TASK_SIZE*3

section .text
global _start
ok_task:
 lea rax,[rdi+7]
 xor edx,edx
 ret
bad_task:
 mov rax,rdi
 mov edx,NEBO_CONCURRENCY_ERROR_IO
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
 lea rdi,[group]
 lea rsi,[budget]
 lea rdx,[tasks]
 mov ecx,3
 call nebo_task_group_init
 test eax,eax
 jnz .fail2
 lea rdi,[group]
 lea rsi,[tasks]
 lea rdx,[ok_task]
 mov ecx,10
 call nebo_task_group_spawn
 test eax,eax
 jnz .fail3
 lea rdi,[tasks]
 call nebo_task_result
 test eax,eax
 jnz .fail4
 cmp rdx,17
 jne .fail5
 lea rdi,[group]
 lea rsi,[tasks+nebo_concurrency_contract_TASK_SIZE]
 lea rdx,[bad_task]
 mov ecx,22
 call nebo_task_group_spawn
 test eax,eax
 jnz .fail6
 cmp qword [tasks+nebo_concurrency_contract_TASK_SIZE+NEBO_TASK_STATE],NEBO_TASK_STATE_FAILED
 jne .fail7
 lea rdi,[tasks+nebo_concurrency_contract_TASK_SIZE]
 call nebo_task_result
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jne .fail8
 lea rdi,[group]
 call nebo_task_group_join_all
 cmp eax,NEBO_CONCURRENCY_ERROR_CHILD_FAILED
 jne .fail9
 cmp rdx,2
 jne .fail10
 lea rdi,[group]
 call nebo_task_group_join_all
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail11
 lea rdi,[group]
 lea rsi,[tasks+nebo_concurrency_contract_TASK_SIZE*2]
 lea rdx,[ok_task]
 xor ecx,ecx
 call nebo_task_group_spawn
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jne .fail12
 lea rdi,[budget]
 mov esi,NEBO_CONCURRENCY_MAX_WORKERS+1
 mov edx,1
 mov ecx,1
 mov r8d,1
 mov r9d,1
 call nebo_scheduler_budget_init
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail13
 xor rdi,rdi
 call nebo_task_group_join_all
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail14
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
