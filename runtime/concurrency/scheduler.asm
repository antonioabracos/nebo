bits 64
default rel
%define NEBO_SCHEDULER_IMPLEMENTATION 1
%include "runtime/concurrency/scheduler.inc"

section .text
global nebo_scheduler_init
global nebo_scheduler_enqueue
global nebo_scheduler_run
global nebo_scheduler_queue_depth
global nebo_scheduler_shutdown
global nebo_scheduler_spawn_blocking

; rdi=scheduler,rsi=budget,rdx=Task queue,rcx=queue slots,
; r8=TraceEvent storage,r9=trace slots.
nebo_scheduler_init:
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 test r8,r8
 jz .init_invalid
 test rcx,rcx
 jz .init_limit
 cmp rcx,[rsi+NEBO_SCHEDULER_BUDGET_MAX_QUEUE]
 ja .init_limit
 test r9,r9
 jz .init_limit
 cmp r9,[rsi+NEBO_SCHEDULER_BUDGET_MAX_TRACE]
 ja .init_limit
 mov qword [rdi+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_CREATED
 mov [rdi+NEBO_SCHEDULER_BUDGET],rsi
 mov [rdi+NEBO_SCHEDULER_QUEUE],rdx
 mov [rdi+NEBO_SCHEDULER_QUEUE_CAPACITY],rcx
 mov qword [rdi+NEBO_SCHEDULER_HEAD],0
 mov qword [rdi+NEBO_SCHEDULER_TAIL],0
 mov qword [rdi+NEBO_SCHEDULER_COUNT],0
 mov [rdi+NEBO_SCHEDULER_TRACE],r8
 mov [rdi+NEBO_SCHEDULER_TRACE_CAPACITY],r9
 mov qword [rdi+NEBO_SCHEDULER_TRACE_COUNT],0
 mov qword [rdi+NEBO_SCHEDULER_WORKERS],0
 mov qword [rdi+NEBO_SCHEDULER_GENERATION],1
 xor eax,eax
 ret
.init_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.init_limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=scheduler,rsi=next Task slot,rdx=callable(arg)->rax/edx,rcx=arg.
nebo_scheduler_enqueue:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .enqueue_invalid
 test rsi,rsi
 jz .enqueue_invalid
 test rdx,rdx
 jz .enqueue_invalid
 cmp qword [rbx+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_STOPPING
 jae .enqueue_transition
 mov r8,[rbx+NEBO_SCHEDULER_COUNT]
 cmp r8,[rbx+NEBO_SCHEDULER_QUEUE_CAPACITY]
 jae .enqueue_full
 mov rax,[rbx+NEBO_SCHEDULER_TAIL]
 shl rax,6
 add rax,[rbx+NEBO_SCHEDULER_QUEUE]
 cmp rsi,rax
 jne .enqueue_invalid
 mov qword [rsi+NEBO_TASK_STATE],NEBO_TASK_STATE_PENDING
 mov [rsi+NEBO_TASK_CALLABLE],rdx
 mov [rsi+NEBO_TASK_ARGUMENT],rcx
 mov [rsi+NEBO_TASK_PARENT],rbx
 mov rax,[rbx+NEBO_SCHEDULER_GENERATION]
 mov [rsi+NEBO_TASK_GENERATION],rax
 mov rax,[rbx+NEBO_SCHEDULER_TAIL]
 inc rax
 xor edx,edx
 div qword [rbx+NEBO_SCHEDULER_QUEUE_CAPACITY]
 mov [rbx+NEBO_SCHEDULER_TAIL],rdx
 inc qword [rbx+NEBO_SCHEDULER_COUNT]
 inc qword [rbx+NEBO_SCHEDULER_GENERATION]
 mov esi,1
 mov rdx,[rbx+NEBO_SCHEDULER_COUNT]
 call scheduler_trace
 xor eax,eax
 jmp .enqueue_return
.enqueue_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .enqueue_return
.enqueue_transition: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 jmp .enqueue_return
.enqueue_full: mov eax,NEBO_CONCURRENCY_ERROR_FULL
.enqueue_return:
 pop rbx
 ret

; Executes up to rsi queued tasks. eax=status,rdx=ran.
nebo_scheduler_run:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 xor r13d,r13d
 test rbx,rbx
 jz .run_invalid
 cmp qword [rbx+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_STOPPED
 je .run_transition
 mov qword [rbx+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_RUNNING
.run_loop:
 test r12,r12
 jz .run_done
 cmp qword [rbx+NEBO_SCHEDULER_COUNT],0
 je .run_done
 mov rax,[rbx+NEBO_SCHEDULER_HEAD]
 shl rax,6
 add rax,[rbx+NEBO_SCHEDULER_QUEUE]
 mov qword [rax+NEBO_TASK_STATE],NEBO_TASK_STATE_RUNNING
 mov rdi,[rax+NEBO_TASK_ARGUMENT]
 call qword [rax+NEBO_TASK_CALLABLE]
 mov rcx,[rbx+NEBO_SCHEDULER_HEAD]
 shl rcx,6
 add rcx,[rbx+NEBO_SCHEDULER_QUEUE]
 mov [rcx+NEBO_TASK_RESULT],rax
 mov [rcx+NEBO_TASK_ERROR],rdx
 test edx,edx
 jnz .run_failed
 mov qword [rcx+NEBO_TASK_STATE],NEBO_TASK_STATE_COMPLETED
 jmp .run_advance
.run_failed:
 mov qword [rcx+NEBO_TASK_STATE],NEBO_TASK_STATE_FAILED
.run_advance:
 mov rax,[rbx+NEBO_SCHEDULER_HEAD]
 inc rax
 xor edx,edx
 div qword [rbx+NEBO_SCHEDULER_QUEUE_CAPACITY]
 mov [rbx+NEBO_SCHEDULER_HEAD],rdx
 dec qword [rbx+NEBO_SCHEDULER_COUNT]
 inc r13
 dec r12
 mov esi,2
 mov rdx,r13
 call scheduler_trace
 jmp .run_loop
.run_done:
 mov rdx,r13
 xor eax,eax
 jmp .run_return
.run_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .run_return
.run_transition: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 xor edx,edx
.run_return:
 pop r13
 pop r12
 pop rbx
 ret

nebo_scheduler_queue_depth:
 test rdi,rdi
 jz .depth_invalid
 mov rdx,[rdi+NEBO_SCHEDULER_COUNT]
 xor eax,eax
 ret
.depth_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret

nebo_scheduler_shutdown:
 test rdi,rdi
 jz .shutdown_invalid
 cmp qword [rdi+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_STOPPED
 je .shutdown_again
 cmp qword [rdi+NEBO_SCHEDULER_COUNT],0
 jne .shutdown_pending
 cmp qword [rdi+NEBO_SCHEDULER_WORKERS],0
 jne .shutdown_pending
 mov qword [rdi+NEBO_SCHEDULER_STATE],NEBO_SCHEDULER_STATE_STOPPED
 xor eax,eax
 ret
.shutdown_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.shutdown_again: mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret
.shutdown_pending: mov eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
 ret

; rdi=scheduler,rsi=Thread,rdx=ThreadBudget,rcx=callable,r8=arg,r9=stack,
; [rsp+8]=stack size. Spawn and join one isolated blocking worker.
nebo_scheduler_spawn_blocking:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .blocking_invalid
 mov rax,[rbx+NEBO_SCHEDULER_WORKERS]
 mov r10,[rbx+NEBO_SCHEDULER_BUDGET]
 cmp rax,[r10+NEBO_SCHEDULER_BUDGET_MAX_WORKERS]
 jae .blocking_limit
 inc qword [rbx+NEBO_SCHEDULER_WORKERS]
 mov rdi,r12
 mov rsi,rdx
 mov rdx,rcx
 mov rcx,r8
 mov r8,r9
 mov r9,[rsp+24]
 call nebo_thread_spawn
 test eax,eax
 jnz .blocking_release
 mov rdi,r12
 call nebo_thread_join
.blocking_release:
 dec qword [rbx+NEBO_SCHEDULER_WORKERS]
 jmp .blocking_return
.blocking_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .blocking_return
.blocking_limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
.blocking_return:
 pop r12
 pop rbx
 ret

; rbx=scheduler, rsi=event, rdx=value. Trace overflow is non-mutating signal.
scheduler_trace:
 mov rax,[rbx+NEBO_SCHEDULER_TRACE_COUNT]
 cmp rax,[rbx+NEBO_SCHEDULER_TRACE_CAPACITY]
 jae .trace_full
 mov rcx,rax
 shl rcx,5
 add rcx,[rbx+NEBO_SCHEDULER_TRACE]
 mov [rcx+NEBO_TRACE_SEQUENCE],rax
 mov [rcx+NEBO_TRACE_EVENT],rsi
 mov r8,[rbx+NEBO_SCHEDULER_STATE]
 mov [rcx+NEBO_TRACE_STATE],r8
 mov [rcx+NEBO_TRACE_VALUE],rdx
 inc qword [rbx+NEBO_SCHEDULER_TRACE_COUNT]
.trace_full: ret
