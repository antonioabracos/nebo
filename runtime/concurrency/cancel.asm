bits 64
default rel
%define NEBO_CANCEL_IMPLEMENTATION 1
%include "runtime/concurrency/cancel.inc"

%define cancel_CLOCK_MONOTONIC 1
section .text
global nebo_cancellation_budget_init
global nebo_cancellation_token_init
global nebo_cancellation_cancel
global nebo_cancellation_is_cancelled
global nebo_deadline_expired
global nebo_cancellation_check
global nebo_cancellation_release

; rdi=budget, rsi=max descendants, rdx=max callbacks, rcx=max deadline ns.
nebo_cancellation_budget_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_CONCURRENCY_MAX_TASKS
 ja .limit
 test rdx,rdx
 jz .limit
 cmp rdx,NEBO_CONCURRENCY_MAX_WAITERS
 ja .limit
 test rcx,rcx
 jz .limit
 mov [rdi+NEBO_CANCELLATION_BUDGET_MAX_DESCENDANTS],rsi
 mov [rdi+NEBO_CANCELLATION_BUDGET_MAX_CALLBACKS],rdx
 mov [rdi+NEBO_CANCELLATION_BUDGET_MAX_DEADLINE_NS],rcx
 mov qword [rdi+NEBO_CANCELLATION_BUDGET_GENERATION],1
 mov qword [rdi+NEBO_CANCEL_BUDGET_ACTIVE],0
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=token, rsi=budget, rdx=optional parent, rcx=optional Deadline,
; r8=optional cleanup(ctx), r9=ctx.
nebo_cancellation_token_init:
 test rdi,rdi
 jz .token_invalid
 test rsi,rsi
 jz .token_invalid
 mov rax,[rsi+NEBO_CANCEL_BUDGET_ACTIVE]
 cmp rax,[rsi+NEBO_CANCELLATION_BUDGET_MAX_DESCENDANTS]
 jae .token_limit
 test r8,r8
 jz .token_deadline
 cmp qword [rsi+NEBO_CANCELLATION_BUDGET_MAX_CALLBACKS],0
 je .token_limit
.token_deadline:
 xor eax,eax
 xor r10d,r10d
 test rcx,rcx
 jz .token_store
 mov rax,[rcx]
 mov r10,[rcx+8]
 test rax,rax
 js .token_invalid
 cmp r10,1000000000
 jae .token_invalid
.token_store:
 mov qword [rdi+NEBO_CANCEL_TOKEN_STATE],0
 mov [rdi+NEBO_CANCEL_TOKEN_PARENT],rdx
 mov [rdi+NEBO_CANCEL_TOKEN_DEADLINE_SECONDS],rax
 mov [rdi+NEBO_CANCEL_TOKEN_DEADLINE_NANOS],r10
 mov [rdi+NEBO_CANCEL_TOKEN_CLEANUP],r8
 mov [rdi+NEBO_CANCEL_TOKEN_CLEANUP_CONTEXT],r9
 inc qword [rsi+NEBO_CANCEL_BUDGET_ACTIVE]
 inc qword [rsi+NEBO_CANCELLATION_BUDGET_GENERATION]
 xor eax,eax
 ret
.token_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.token_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; eax=0, edx=1 only on first cancellation; cleanup executes once.
nebo_cancellation_cancel:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .cancel_invalid
 mov rax,1
 xchg rax,[rbx+NEBO_CANCEL_TOKEN_STATE]
 test rax,rax
 jnz .cancel_already
 mov rax,[rbx+NEBO_CANCEL_TOKEN_CLEANUP]
 mov qword [rbx+NEBO_CANCEL_TOKEN_CLEANUP],0
 test rax,rax
 jz .cancel_first
 mov rdi,[rbx+NEBO_CANCEL_TOKEN_CLEANUP_CONTEXT]
 call rax
.cancel_first:
 mov edx,1
 xor eax,eax
 jmp .cancel_return
.cancel_already:
 xor edx,edx
 xor eax,eax
 jmp .cancel_return
.cancel_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
.cancel_return:
 pop rbx
 ret

; eax=status, edx=boolean. One-level parent chain is bounded by budget contract.
nebo_cancellation_is_cancelled:
 test rdi,rdi
 jz .is_invalid
 cmp qword [rdi+NEBO_CANCEL_TOKEN_STATE],0
 jne .is_yes
 mov rdi,[rdi+NEBO_CANCEL_TOKEN_PARENT]
 test rdi,rdi
 jz .is_no
 cmp qword [rdi+NEBO_CANCEL_TOKEN_STATE],0
 jne .is_yes
.is_no:
 xor edx,edx
 xor eax,eax
 ret
.is_yes:
 mov edx,1
 xor eax,eax
 ret
.is_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret

; rdi=token. Deadline 0 means none. eax=status, edx=expired.
nebo_deadline_expired:
 push rbx
 mov rbx,rdi
 test rdi,rdi
 jz .deadline_invalid
 mov rax,[rdi+NEBO_CANCEL_TOKEN_DEADLINE_SECONDS]
 or rax,[rdi+NEBO_CANCEL_TOKEN_DEADLINE_NANOS]
 jz .deadline_no
 sub rsp,16
 mov eax,NEBO_LINUX_X86_64_SYS_CLOCK_GETTIME
 mov edi,cancel_CLOCK_MONOTONIC
 mov rsi,rsp
 syscall
 cmp rax,-4095
 jae .deadline_io
 mov rcx,[rsp]
 mov r8,[rsp+8]
 add rsp,16
 cmp rcx,[rbx+NEBO_CANCEL_TOKEN_DEADLINE_SECONDS]
 ja .deadline_yes
 jb .deadline_no
 cmp r8,[rbx+NEBO_CANCEL_TOKEN_DEADLINE_NANOS]
 jae .deadline_yes
.deadline_no:
 xor edx,edx
 xor eax,eax
 pop rbx
 ret
.deadline_yes:
 mov edx,1
 xor eax,eax
 pop rbx
 ret
.deadline_io:
 add rsp,16
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 xor edx,edx
 pop rbx
 ret
.deadline_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 pop rbx
 ret

; Cooperative cancellation checkpoint: CANCELLED outranks TIMEOUT.
nebo_cancellation_check:
 push rbx
 mov rbx,rdi
 call nebo_cancellation_is_cancelled
 test eax,eax
 jnz .check_return
 test edx,edx
 jnz .check_cancelled
 mov rdi,rbx
 call nebo_deadline_expired
 test eax,eax
 jnz .check_return
 test edx,edx
 jnz .check_timeout
 xor eax,eax
 jmp .check_return
.check_cancelled:
 mov eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 jmp .check_return
.check_timeout:
 mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.check_return:
 pop rbx
 ret

; rdi=budget, rsi=token. Release accounting once; token becomes terminal.
nebo_cancellation_release:
 test rdi,rdi
 jz .release_invalid
 test rsi,rsi
 jz .release_invalid
 cmp qword [rsi+NEBO_CANCEL_TOKEN_STATE],2
 je .release_again
 mov qword [rsi+NEBO_CANCEL_TOKEN_STATE],2
 cmp qword [rdi+NEBO_CANCEL_BUDGET_ACTIVE],0
 je .release_again
 dec qword [rdi+NEBO_CANCEL_BUDGET_ACTIVE]
 xor eax,eax
 ret
.release_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.release_again:
 mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret
