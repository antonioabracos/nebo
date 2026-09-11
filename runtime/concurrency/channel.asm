bits 64
default rel
%define NEBO_CHANNEL_IMPLEMENTATION 1
%include "runtime/concurrency/channel.inc"
extern nebo_cancellation_check

%define EINTR 4
%define EAGAIN 11
section .text
global nebo_channel_budget_init
global nebo_channel_init
global nebo_channel_try_send
global nebo_channel_try_receive
global nebo_channel_send
global nebo_channel_receive
global nebo_channel_close_sender
global nebo_channel_close_receiver

; rdi=budget, rsi=max capacity, rdx=max waiters, rcx=max deadline ns.
nebo_channel_budget_init:
 test rdi,rdi
 jz .invalid
 cmp rsi,NEBO_CONCURRENCY_MAX_CHANNEL_CAPACITY
 ja .limit
 test rdx,rdx
 jz .limit
 cmp rdx,NEBO_CONCURRENCY_MAX_WAITERS
 ja .limit
 mov [rdi+NEBO_CHANNEL_BUDGET_MAX_CAPACITY],rsi
 mov [rdi+NEBO_CHANNEL_BUDGET_MAX_WAITERS],rdx
 mov [rdi+NEBO_CHANNEL_BUDGET_MAX_DEADLINE_NS],rcx
 mov qword [rdi+NEBO_CHANNEL_BUDGET_GENERATION],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=channel, rsi=budget, rdx=u64 storage (at least one slot for rendezvous), rcx=capacity.
nebo_channel_init:
 test rdi,rdi
 jz .init_invalid
 test rsi,rsi
 jz .init_invalid
 test rdx,rdx
 jz .init_invalid
 cmp rcx,[rsi+NEBO_CHANNEL_BUDGET_MAX_CAPACITY]
 ja .init_limit
 mov qword [rdi+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_OPEN
 mov [rdi+NEBO_CHANNEL_STORAGE],rdx
 mov [rdi+NEBO_CHANNEL_CAPACITY],rcx
 mov qword [rdi+NEBO_CHANNEL_HEAD],0
 mov qword [rdi+NEBO_CHANNEL_TAIL],0
 mov qword [rdi+NEBO_CHANNEL_COUNT],0
 mov qword [rdi+NEBO_CHANNEL_SENDERS],1
 mov qword [rdi+NEBO_CHANNEL_RECEIVERS],1
 mov qword [rdi+NEBO_CHANNEL_GENERATION],1
 mov [rdi+NEBO_CHANNEL_BUDGET],rsi
 mov qword [rdi+NEBO_CHANNEL_WAITERS],0
 mov qword [rdi+NEBO_CHANNEL_LOCK],0
 xor eax,eax
 ret
.init_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.init_limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=channel, rsi=value. Failure atomic.
nebo_channel_try_send:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .send_invalid
 call channel_lock
 cmp qword [rbx+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_OPEN
 jne .send_closed
 cmp qword [rbx+NEBO_CHANNEL_RECEIVERS],0
 je .send_closed
 mov rcx,[rbx+NEBO_CHANNEL_CAPACITY]
 test rcx,rcx
 jnz .send_capacity
 cmp qword [rbx+NEBO_CHANNEL_WAITERS],0
 je .send_full
 mov ecx,1
.send_capacity:
 cmp [rbx+NEBO_CHANNEL_COUNT],rcx
 jae .send_full
 mov rax,[rbx+NEBO_CHANNEL_TAIL]
 xor edx,edx
 div rcx
 mov rax,[rbx+NEBO_CHANNEL_STORAGE]
 mov [rax+rdx*8],rsi
 mov rax,[rbx+NEBO_CHANNEL_TAIL]
 inc rax
 xor edx,edx
 div rcx
 mov [rbx+NEBO_CHANNEL_TAIL],rdx
 inc qword [rbx+NEBO_CHANNEL_COUNT]
 call channel_publish_unlock
 xor eax,eax
 jmp .send_return
.send_full:
 call channel_unlock
 mov eax,NEBO_CONCURRENCY_ERROR_FULL
 jmp .send_return
.send_closed:
 call channel_unlock
 mov eax,NEBO_CONCURRENCY_ERROR_CLOSED
 jmp .send_return
.send_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
.send_return:
 pop rbx
 ret

; rdi=channel. eax=status, rdx=value.
nebo_channel_try_receive:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .recv_invalid
 call channel_lock
 cmp qword [rbx+NEBO_CHANNEL_COUNT],0
 jne .recv_value
 cmp qword [rbx+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_CLOSED
 je .recv_closed
 call channel_unlock
 mov eax,NEBO_CONCURRENCY_ERROR_EMPTY
 xor edx,edx
 jmp .recv_return
.recv_value:
 mov rcx,[rbx+NEBO_CHANNEL_CAPACITY]
 test rcx,rcx
 jnz .recv_cap_ok
 mov ecx,1
.recv_cap_ok:
 mov rax,[rbx+NEBO_CHANNEL_HEAD]
 xor edx,edx
 div rcx
 mov rax,[rbx+NEBO_CHANNEL_STORAGE]
 mov r8,[rax+rdx*8]
 mov qword [rax+rdx*8],0
 mov rax,[rbx+NEBO_CHANNEL_HEAD]
 inc rax
 xor edx,edx
 div rcx
 mov [rbx+NEBO_CHANNEL_HEAD],rdx
 dec qword [rbx+NEBO_CHANNEL_COUNT]
 call channel_publish_unlock
 mov rdx,r8
 xor eax,eax
 jmp .recv_return
.recv_closed:
 call channel_unlock
 mov eax,NEBO_CONCURRENCY_ERROR_CLOSED
 xor edx,edx
 jmp .recv_return
.recv_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
.recv_return:
 pop rbx
 ret

; Blocking bounded send: rdi=channel,rsi=value,rdx=optional cancellation token,r10=max waits.
nebo_channel_send:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,r10
.blocking_send_retry:
 mov rdi,rbx
 mov rsi,r12
 call nebo_channel_try_send
 test eax,eax
 jz .blocking_send_return
 cmp eax,NEBO_CONCURRENCY_ERROR_FULL
 jne .blocking_send_return
 test r13,r13
 jz .blocking_send_budget
 mov rdi,r13
 call nebo_cancellation_check
 test eax,eax
 jnz .blocking_send_return
.blocking_send_budget:
 test r14,r14
 jz .blocking_send_timeout
 dec r14
 mov rdi,rbx
 call channel_wait
 jmp .blocking_send_retry
.blocking_send_timeout:
 mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.blocking_send_return:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Blocking bounded receive: rdi=channel,rsi=optional token,rdx=max waits.
nebo_channel_receive:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
.blocking_recv_retry:
 mov rdi,rbx
 call nebo_channel_try_receive
 test eax,eax
 jz .blocking_recv_return
 cmp eax,NEBO_CONCURRENCY_ERROR_EMPTY
 jne .blocking_recv_return
 test r12,r12
 jz .blocking_recv_budget
 mov rdi,r12
 call nebo_cancellation_check
 test eax,eax
 jnz .blocking_recv_return
.blocking_recv_budget:
 test r13,r13
 jz .blocking_recv_timeout
 dec r13
 mov rdi,rbx
 call channel_wait
 jmp .blocking_recv_retry
.blocking_recv_timeout:
 mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.blocking_recv_return:
 pop r13
 pop r12
 pop rbx
 ret

nebo_channel_close_sender:
 test rdi,rdi
 jz channel_close_invalid
 cmp qword [rdi+NEBO_CHANNEL_SENDERS],0
 je channel_close_again
 mov qword [rdi+NEBO_CHANNEL_SENDERS],0
 mov qword [rdi+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_CLOSED
 push rbx
 mov rbx,rdi
 call channel_publish
 pop rbx
 xor eax,eax
 ret
nebo_channel_close_receiver:
 test rdi,rdi
 jz channel_close_invalid
 cmp qword [rdi+NEBO_CHANNEL_RECEIVERS],0
 je channel_close_again
 mov qword [rdi+NEBO_CHANNEL_RECEIVERS],0
 mov qword [rdi+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_CLOSED
 push rbx
 mov rbx,rdi
 call channel_publish
 pop rbx
 xor eax,eax
 ret
channel_close_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
channel_close_again: mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret

channel_lock:
.lock_retry:
 mov eax,1
 xchg rax,[rbx+NEBO_CHANNEL_LOCK]
 test rax,rax
 jz .lock_ok
 mov eax,NEBO_LINUX_X86_64_SYS_SCHED_YIELD
 syscall
 mov rax,1
 jmp .lock_retry
.lock_ok: ret
channel_unlock:
 mov qword [rbx+NEBO_CHANNEL_LOCK],0
 ret
channel_publish_unlock:
 inc qword [rbx+NEBO_CHANNEL_GENERATION]
 call channel_unlock
channel_publish:
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 lea rdi,[rbx+NEBO_CHANNEL_GENERATION]
 mov esi,NEBO_FUTEX_WAKE_PRIVATE
 mov edx,0x7fffffff
 syscall
 ret
channel_wait:
 mov rcx,[rbx+NEBO_CHANNEL_BUDGET]
 mov rax,[rbx+NEBO_CHANNEL_WAITERS]
 cmp rax,[rcx+NEBO_CHANNEL_BUDGET_MAX_WAITERS]
 jae .wait_limit
 inc qword [rbx+NEBO_CHANNEL_WAITERS]
 ; A finite waiter budget must also bound the blocking syscall itself.
 ; Linux FUTEX_WAIT takes a relative timespec; zero means an immediate poll.
 sub rsp,16
 mov rax,[rcx+NEBO_CHANNEL_BUDGET_MAX_DEADLINE_NS]
 xor edx,edx
 mov ecx,1000000000
 div rcx
 mov [rsp],rax
 mov [rsp+8],rdx
 mov edx,[rbx+NEBO_CHANNEL_GENERATION]
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 lea rdi,[rbx+NEBO_CHANNEL_GENERATION]
 mov esi,NEBO_FUTEX_WAIT_PRIVATE
 mov r10,rsp
 xor r8d,r8d
 xor r9d,r9d
 syscall
 add rsp,16
 dec qword [rbx+NEBO_CHANNEL_WAITERS]
 xor eax,eax
 ret
.wait_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret
