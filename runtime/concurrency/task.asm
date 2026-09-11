bits 64
default rel
%define NEBO_TASK_IMPLEMENTATION 1
%include "runtime/concurrency/task.inc"

section .text
global nebo_scheduler_budget_init
global nebo_task_group_init
global nebo_task_group_spawn
global nebo_task_group_join_all
global nebo_task_result
global nebo_task_group_cancel

; rdi=budget, rsi=max workers, rdx=max tasks, rcx=max queue,
; r8=max trace, r9=max polls.
nebo_scheduler_budget_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_CONCURRENCY_MAX_WORKERS
 ja .limit
 test rdx,rdx
 jz .limit
 cmp rdx,NEBO_CONCURRENCY_MAX_TASKS
 ja .limit
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_CONCURRENCY_MAX_QUEUE
 ja .limit
 cmp r8,NEBO_CONCURRENCY_MAX_TRACE_EVENTS
 ja .limit
 test r9,r9
 jz .limit
 cmp r9,NEBO_CONCURRENCY_MAX_POLLS
 ja .limit
 mov [rdi+NEBO_SCHEDULER_BUDGET_MAX_WORKERS],rsi
 mov [rdi+NEBO_SCHEDULER_BUDGET_MAX_TASKS],rdx
 mov [rdi+NEBO_SCHEDULER_BUDGET_MAX_QUEUE],rcx
 mov [rdi+NEBO_SCHEDULER_BUDGET_MAX_TRACE],r8
 mov [rdi+NEBO_SCHEDULER_BUDGET_MAX_POLLS],r9
 mov qword [rdi+NEBO_SCHEDULER_BUDGET_GENERATION],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=TaskGroup, rsi=budget, rdx=Task storage, rcx=storage slots.
nebo_task_group_init:
 test rdi,rdi
 jz .group_invalid
 test rsi,rsi
 jz .group_invalid
 test rdx,rdx
 jz .group_invalid
 test rcx,rcx
 jz .group_limit
 cmp rcx,[rsi+NEBO_SCHEDULER_BUDGET_MAX_TASKS]
 ja .group_limit
 mov rax,[rsi+NEBO_SCHEDULER_BUDGET_MAX_WORKERS]
 test rax,rax
 jz .group_denied
 mov [rdi+NEBO_TASK_GROUP_BUDGET],rsi
 mov [rdi+NEBO_TASK_GROUP_STORAGE],rdx
 mov [rdi+NEBO_TASK_GROUP_CAPACITY],rcx
 mov qword [rdi+NEBO_TASK_GROUP_COUNT],0
 mov qword [rdi+NEBO_TASK_GROUP_STATE],NEBO_TASK_STATE_PENDING
 mov qword [rdi+NEBO_TASK_GROUP_ERROR_COUNT],0
 mov qword [rdi+NEBO_TASK_GROUP_JOINED],0
 mov qword [rdi+NEBO_TASK_GROUP_GENERATION],1
 xor eax,eax
 ret
.group_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.group_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret
.group_denied:
 mov eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 ret

; rdi=group, rsi=Task out (must be next storage slot), rdx=callable,
; rcx=argument. Callable returns result in rax and status in edx (0 success).
nebo_task_group_spawn:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .spawn_invalid
 test r12,r12
 jz .spawn_invalid
 test rdx,rdx
 jz .spawn_invalid
 cmp qword [rbx+NEBO_TASK_GROUP_JOINED],0
 jne .spawn_transition
 cmp qword [rbx+NEBO_TASK_GROUP_STATE],NEBO_TASK_STATE_CANCELLED
 je .spawn_cancelled
 mov r8,[rbx+NEBO_TASK_GROUP_COUNT]
 cmp r8,[rbx+NEBO_TASK_GROUP_CAPACITY]
 jae .spawn_limit
 mov rax,r8
 shl rax,6
 add rax,[rbx+NEBO_TASK_GROUP_STORAGE]
 cmp r12,rax
 jne .spawn_invalid
 cmp qword [r12+NEBO_TASK_STATE],NEBO_TASK_STATE_PENDING
 jne .spawn_transition
 mov qword [r12+NEBO_TASK_STATE],NEBO_TASK_STATE_RUNNING
 mov [r12+NEBO_TASK_CALLABLE],rdx
 mov [r12+NEBO_TASK_ARGUMENT],rcx
 mov [r12+NEBO_TASK_PARENT],rbx
 mov rax,[rbx+NEBO_TASK_GROUP_GENERATION]
 mov [r12+NEBO_TASK_GENERATION],rax
 mov rdi,rcx
 call rdx
 mov [r12+NEBO_TASK_RESULT],rax
 mov [r12+NEBO_TASK_ERROR],rdx
 test edx,edx
 jnz .spawn_child_error
 mov qword [r12+NEBO_TASK_STATE],NEBO_TASK_STATE_COMPLETED
 jmp .spawn_publish
.spawn_child_error:
 mov qword [r12+NEBO_TASK_STATE],NEBO_TASK_STATE_FAILED
 inc qword [rbx+NEBO_TASK_GROUP_ERROR_COUNT]
.spawn_publish:
 inc qword [rbx+NEBO_TASK_GROUP_COUNT]
 inc qword [rbx+NEBO_TASK_GROUP_GENERATION]
 xor eax,eax
 jmp .spawn_return
.spawn_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .spawn_return
.spawn_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jmp .spawn_return
.spawn_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jmp .spawn_return
.spawn_cancelled:
 mov eax,NEBO_CONCURRENCY_ERROR_CANCELLED
.spawn_return:
 add rsp,8
 pop r12
 pop rbx
 ret

; The current scheduler executes one child at a time. Cancellation closes
; admission without rewriting already completed child results; join still
; consumes the scope once and reports those children.
nebo_task_group_cancel:
 test rdi,rdi
 jz .invalid
 cmp qword [rdi+NEBO_TASK_GROUP_JOINED],0
 jne .closed
 mov qword [rdi+NEBO_TASK_GROUP_STATE],NEBO_TASK_STATE_CANCELLED
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.closed:
 mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret

; rdi=group. eax=status, rdx=completed count. Consumes structured group.
nebo_task_group_join_all:
 test rdi,rdi
 jz .join_invalid
 cmp qword [rdi+NEBO_TASK_GROUP_JOINED],0
 jne .join_completed
 mov qword [rdi+NEBO_TASK_GROUP_JOINED],1
 mov qword [rdi+NEBO_TASK_GROUP_STATE],NEBO_TASK_STATE_COMPLETED
 mov rdx,[rdi+NEBO_TASK_GROUP_COUNT]
 cmp qword [rdi+NEBO_TASK_GROUP_ERROR_COUNT],0
 jne .join_child
 xor eax,eax
 ret
.join_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.join_completed:
 mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 xor edx,edx
 ret
.join_child:
 mov eax,NEBO_CONCURRENCY_ERROR_CHILD_FAILED
 ret

; rdi=task. eax=status, rdx=result.
nebo_task_result:
 test rdi,rdi
 jz .result_invalid
 cmp qword [rdi+NEBO_TASK_STATE],NEBO_TASK_STATE_COMPLETED
 jne .result_transition
 mov rdx,[rdi+NEBO_TASK_RESULT]
 xor eax,eax
 ret
.result_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.result_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 xor edx,edx
 ret
