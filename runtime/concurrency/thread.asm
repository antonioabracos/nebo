bits 64
default rel
%define NEBO_THREAD_IMPLEMENTATION 1
%include "runtime/concurrency/thread.inc"

%define EINTR 4
%define EPERM 1
%define ENOSYS 38
%define EAGAIN 11
%define CLONE_VM 0x00000100
%define CLONE_FS 0x00000200
%define CLONE_FILES 0x00000400
%define CLONE_SIGHAND 0x00000800
%define CLONE_THREAD 0x00010000
%define CLONE_SYSVSEM 0x00040000
%define CLONE_PARENT_SETTID 0x00100000
%define CLONE_CHILD_CLEARTID 0x00200000
%define THREAD_FLAGS (CLONE_VM | CLONE_FS | CLONE_FILES | CLONE_SIGHAND | CLONE_THREAD | CLONE_SYSVSEM | CLONE_PARENT_SETTID | CLONE_CHILD_CLEARTID)

section .text
global nebo_thread_budget_init
global nebo_thread_spawn
global nebo_thread_join
global nebo_thread_current_id
global nebo_thread_yield

; rdi=ThreadBudget, rsi=max threads, rdx=max stack bytes, rcx=deadline ns.
nebo_thread_budget_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_CONCURRENCY_MAX_THREADS
 ja .limit
 cmp rdx,4096
 jb .limit
 cmp rdx,NEBO_CONCURRENCY_MAX_STACK_BYTES
 ja .limit
 mov rax,NEBO_CONCURRENCY_MAGIC_THREAD
 mov [rdi+NEBO_THREAD_BUDGET_MAGIC],rax
 mov [rdi+NEBO_THREAD_BUDGET_MAX_THREADS],rsi
 mov [rdi+NEBO_THREAD_BUDGET_MAX_STACK_BYTES],rdx
 mov [rdi+NEBO_THREAD_BUDGET_MAX_DEADLINE_NS],rcx
 mov qword [rdi+NEBO_THREAD_BUDGET_ACTIVE],0
 mov qword [rdi+NEBO_THREAD_BUDGET_GENERATION],1
 mov qword [rdi+NEBO_THREAD_BUDGET_FLAGS],0
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=Thread, rsi=budget, rdx=callable(arg)->i64, rcx=arg,
; r8=caller-owned stack base, r9=stack size. Thread remains joinable.
nebo_thread_spawn:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 test r12,r12
 jz .spawn_invalid
 test rbx,rbx
 jz .spawn_invalid
 test rdx,rdx
 jz .spawn_invalid
 test r8,r8
 jz .spawn_invalid
 mov rax,NEBO_CONCURRENCY_MAGIC_THREAD
 cmp [rbx+NEBO_THREAD_BUDGET_MAGIC],rax
 jne .spawn_denied
 cmp qword [r12+NEBO_THREAD_STATE],NEBO_THREAD_STATE_UNINITIALIZED
 jne .spawn_transition
 cmp r9,4096
 jb .spawn_limit
 cmp r9,[rbx+NEBO_THREAD_BUDGET_MAX_STACK_BYTES]
 ja .spawn_limit
 mov rax,[rbx+NEBO_THREAD_BUDGET_ACTIVE]
 cmp rax,[rbx+NEBO_THREAD_BUDGET_MAX_THREADS]
 jae .spawn_limit
 mov [r12+NEBO_THREAD_BUDGET],rbx
 mov [r12+NEBO_THREAD_STACK],r8
 mov [r12+NEBO_THREAD_STACK_SIZE],r9
 mov [r12+NEBO_THREAD_CALLABLE],rdx
 mov [r12+NEBO_THREAD_ARGUMENT],rcx
 mov qword [r12+NEBO_THREAD_RESULT],0
 sub rsp,96
 xor eax,eax
 mov ecx,12
 mov rdi,rsp
 rep stosq
 mov qword [rsp],THREAD_FLAGS
 lea rax,[r12+NEBO_THREAD_TID]
 mov [rsp+16],rax
 mov [rsp+24],rax
 mov [rsp+40],r8
 mov [rsp+48],r9
 mov eax,NEBO_LINUX_X86_64_SYS_CLONE3
 mov rdi,rsp
 mov esi,88
 syscall
 test rax,rax
 jz .spawn_child
 cmp rax,-4095
 jae .spawn_syscall
 mov qword [r12+NEBO_THREAD_STATE],NEBO_THREAD_STATE_RUNNING
 inc qword [rbx+NEBO_THREAD_BUDGET_ACTIVE]
 inc qword [rbx+NEBO_THREAD_BUDGET_GENERATION]
 add rsp,96
 xor eax,eax
 jmp .spawn_return
.spawn_child:
 mov rdi,[r12+NEBO_THREAD_ARGUMENT]
 call qword [r12+NEBO_THREAD_CALLABLE]
 mov [r12+NEBO_THREAD_RESULT],rax
 mov qword [r12+NEBO_THREAD_STATE],NEBO_THREAD_STATE_EXITED
 xor edi,edi
 mov eax,60
 syscall
.spawn_syscall:
 add rsp,96
 mov qword [r12+NEBO_THREAD_TID],0
 mov qword [r12+NEBO_THREAD_STATE],NEBO_THREAD_STATE_UNINITIALIZED
 cmp rax,-ENOSYS
 je .spawn_unsupported
 cmp rax,-EPERM
 je .spawn_unsupported
 cmp rax,-EAGAIN
 je .spawn_limit
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 jmp .spawn_return
.spawn_unsupported:
 mov eax,NEBO_CONCURRENCY_ERROR_UNSUPPORTED_TARGET
 jmp .spawn_return
.spawn_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .spawn_return
.spawn_denied:
 mov eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 jmp .spawn_return
.spawn_limit:
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jmp .spawn_return
.spawn_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
.spawn_return:
 pop r12
 pop rbx
 ret

; rdi=Thread. eax=status, rdx=result. Joins exactly once.
nebo_thread_join:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .join_invalid
 mov rax,[rbx+NEBO_THREAD_STATE]
 cmp rax,NEBO_THREAD_STATE_JOINED
 je .join_completed
 cmp rax,NEBO_THREAD_STATE_RUNNING
 je .join_wait
 cmp rax,NEBO_THREAD_STATE_EXITED
 jne .join_transition
.join_wait:
 mov eax,[rbx+NEBO_THREAD_TID]
 test eax,eax
 jz .join_done
 mov edx,eax
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 lea rdi,[rbx+NEBO_THREAD_TID]
 ; CLONE_CHILD_CLEARTID uses the kernel's shared futex wake operation.
 mov esi,NEBO_FUTEX_WAIT
 xor r10d,r10d
 xor r8d,r8d
 xor r9d,r9d
 syscall
 cmp rax,-EINTR
 je .join_wait
 jmp .join_wait
.join_done:
 mov qword [rbx+NEBO_THREAD_STATE],NEBO_THREAD_STATE_JOINED
 mov rcx,[rbx+NEBO_THREAD_BUDGET]
 test rcx,rcx
 jz .join_result
 cmp qword [rcx+NEBO_THREAD_BUDGET_ACTIVE],0
 je .join_result
 dec qword [rcx+NEBO_THREAD_BUDGET_ACTIVE]
.join_result:
 mov rdx,[rbx+NEBO_THREAD_RESULT]
 xor eax,eax
 jmp .join_return
.join_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .join_return
.join_completed:
 mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 xor edx,edx
 jmp .join_return
.join_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 xor edx,edx
.join_return:
 pop rbx
 ret

nebo_thread_current_id:
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 mov rdx,rax
 xor eax,eax
 ret

nebo_thread_yield:
 mov eax,NEBO_LINUX_X86_64_SYS_SCHED_YIELD
 syscall
 cmp rax,-4095
 jae .yield_io
 xor eax,eax
 ret
.yield_io:
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 ret
