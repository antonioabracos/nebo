bits 64
default rel
%define NEBO_FUTURE_IMPLEMENTATION 1
%include "runtime/concurrency/future.inc"

section .text
global nebo_future_init
global nebo_future_set_waker
global nebo_future_complete
global nebo_future_poll
global nebo_future_take
global nebo_future_map
global nebo_future_select
global nebo_task_await

; rdi=future, rsi=max polls.
nebo_future_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_CONCURRENCY_MAX_POLLS
 ja .limit
 mov qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_PENDING
 mov qword [rdi+NEBO_FUTURE_VALUE],0
 mov qword [rdi+NEBO_FUTURE_ERROR],0
 mov qword [rdi+NEBO_FUTURE_POLLS],0
 mov [rdi+NEBO_FUTURE_MAX_POLLS],rsi
 mov qword [rdi+NEBO_FUTURE_WAKER],0
 mov qword [rdi+NEBO_FUTURE_WAKER_CONTEXT],0
 mov qword [rdi+NEBO_FUTURE_GENERATION],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=future, rsi=waker(context), rdx=context.
nebo_future_set_waker:
 test rdi,rdi
 jz .waker_invalid
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_PENDING
 jne .waker_transition
 mov [rdi+NEBO_FUTURE_WAKER],rsi
 mov [rdi+NEBO_FUTURE_WAKER_CONTEXT],rdx
 xor eax,eax
 ret
.waker_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.waker_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 ret

; rdi=future, rsi=value, rdx=structured error (0 success).
nebo_future_complete:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .complete_invalid
 cmp qword [rbx+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_PENDING
 jne .complete_again
 mov [rbx+NEBO_FUTURE_VALUE],rsi
 mov [rbx+NEBO_FUTURE_ERROR],rdx
 mov qword [rbx+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 inc qword [rbx+NEBO_FUTURE_GENERATION]
 mov rax,[rbx+NEBO_FUTURE_WAKER]
 test rax,rax
 jz .complete_ok
 mov rdi,[rbx+NEBO_FUTURE_WAKER_CONTEXT]
 call rax
.complete_ok:
 xor eax,eax
 jmp .complete_return
.complete_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .complete_return
.complete_again:
 mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
.complete_return:
 pop rbx
 ret

; eax=status, edx=0 pending/1 ready, r8=value, r9=error.
nebo_future_poll:
 test rdi,rdi
 jz .poll_invalid
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_TAKEN
 je .poll_transition
 mov rax,[rdi+NEBO_FUTURE_POLLS]
 cmp rax,[rdi+NEBO_FUTURE_MAX_POLLS]
 jae .poll_limit
 inc qword [rdi+NEBO_FUTURE_POLLS]
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 je .poll_ready
 xor edx,edx
 xor r8d,r8d
 xor r9d,r9d
 xor eax,eax
 ret
.poll_ready:
 mov edx,1
 mov r8,[rdi+NEBO_FUTURE_VALUE]
 mov r9,[rdi+NEBO_FUTURE_ERROR]
 xor eax,eax
 ret
.poll_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.poll_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 ret
.poll_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; eax=status, rdx=value, r8=error. Consumes a ready future once.
nebo_future_take:
 test rdi,rdi
 jz .take_invalid
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 jne .take_transition
 mov rdx,[rdi+NEBO_FUTURE_VALUE]
 mov r8,[rdi+NEBO_FUTURE_ERROR]
 mov qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_TAKEN
 xor eax,eax
 ret
.take_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.take_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 ret

; rdi=out, rsi=ready input, rdx=map(value)->value, rcx=max polls.
nebo_future_map:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .map_invalid
 test rsi,rsi
 jz .map_invalid
 test rdx,rdx
 jz .map_invalid
 cmp qword [rsi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 jne .map_transition
 mov rdi,rbx
 mov rsi,rcx
 call nebo_future_init
 test eax,eax
 jnz .map_return
 mov rdi,[r12+NEBO_FUTURE_VALUE]
 call r13
 mov rsi,rax
 mov rdx,[r12+NEBO_FUTURE_ERROR]
 mov rdi,rbx
 call nebo_future_complete
 jmp .map_return
.map_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .map_return
.map_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
.map_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=a, rsi=b. eax=status, edx=index 0/1, r8=value.
nebo_future_select:
 test rdi,rdi
 jz .select_invalid
 test rsi,rsi
 jz .select_invalid
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 je .select_a
 cmp qword [rsi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 je .select_b
 mov eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
 ret
.select_a:
 xor edx,edx
 mov r8,[rdi+NEBO_FUTURE_VALUE]
 xor eax,eax
 ret
.select_b:
 mov edx,1
 mov r8,[rsi+NEBO_FUTURE_VALUE]
 xor eax,eax
 ret
.select_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret

; Method-based await: ready now or explicit WOULD_BLOCK; no hidden spin.
nebo_task_await:
 test rdi,rdi
 jz .await_invalid
 cmp qword [rdi+NEBO_FUTURE_STATE],NEBO_FUTURE_STATE_READY
 jne .await_pending
 jmp nebo_future_take
.await_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.await_pending:
 mov eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
 ret
