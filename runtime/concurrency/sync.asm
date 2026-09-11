bits 64
default rel
%define NEBO_SYNC_IMPLEMENTATION 1
%include "runtime/concurrency/sync.inc"

section .text
global nebo_sync_budget_init
global nebo_mutex_init
global nebo_mutex_lock
global nebo_mutex_unlock
global nebo_rwlock_init
global nebo_rwlock_read
global nebo_rwlock_write
global nebo_rwlock_unlock
global nebo_atomic_init
global nebo_atomic_load
global nebo_atomic_store
global nebo_atomic_compare_exchange
global nebo_atomic_fetch_add

nebo_sync_budget_init:
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .limit
 cmp rsi,NEBO_CONCURRENCY_MAX_WAITERS
 ja .limit
 mov [rdi+NEBO_SYNCHRONIZATION_BUDGET_MAX_WAITERS],rsi
 mov [rdi+NEBO_SYNCHRONIZATION_BUDGET_MAX_DEADLINE_NS],rdx
 mov qword [rdi+NEBO_SYNCHRONIZATION_BUDGET_GENERATION],1
 xor eax,eax
 ret
.invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 ret

; rdi=lock, rsi=budget.
nebo_mutex_init:
 jmp sync_init
nebo_rwlock_init:
 jmp sync_init
sync_init:
 test rdi,rdi
 jz .sync_invalid
 test rsi,rsi
 jz .sync_invalid
 mov rax,[rsi+NEBO_SYNCHRONIZATION_BUDGET_MAX_WAITERS]
 test rax,rax
 jz .sync_denied
 mov qword [rdi+NEBO_SYNC_STATE],0
 mov qword [rdi+NEBO_SYNC_OWNER],0
 mov qword [rdi+NEBO_SYNC_WAITERS],0
 mov [rdi+NEBO_SYNC_MAX_WAITERS],rax
 mov qword [rdi+NEBO_SYNC_GENERATION],1
 mov qword [rdi+NEBO_SYNC_FLAGS],0
 xor eax,eax
 ret
.sync_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.sync_denied: mov eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 ret

; rdi=Mutex, rsi=Guard, rdx=max waits. Non-recursive.
nebo_mutex_lock:
 push rbx
 push r12
 push r13
 xor r13d,r13d
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .mutex_invalid
 test r12,r12
 jz .mutex_invalid
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 mov r8,rax
 cmp [rbx+NEBO_SYNC_OWNER],r8
 je .mutex_deadlock
.mutex_retry:
 xor eax,eax
 mov ecx,1
 lock cmpxchg [rbx+NEBO_SYNC_STATE],rcx
 jz .mutex_acquired
 test rdx,rdx
 jz .mutex_timeout
 dec rdx
 test r13,r13
 jnz .mutex_yield
 mov eax,1
 lock xadd [rbx+NEBO_SYNC_WAITERS],rax
 cmp rax,[rbx+NEBO_SYNC_MAX_WAITERS]
 jb .mutex_registered
 lock dec qword [rbx+NEBO_SYNC_WAITERS]
 mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jmp .mutex_return
.mutex_registered:
 mov r13d,1
.mutex_yield:
 mov eax,NEBO_LINUX_X86_64_SYS_SCHED_YIELD
 syscall
 jmp .mutex_retry
.mutex_acquired:
.mutex_store:
 mov [rbx+NEBO_SYNC_OWNER],r8
 mov [r12+NEBO_GUARD_LOCK],rbx
 mov qword [r12+NEBO_GUARD_KIND],1
 mov [r12+NEBO_GUARD_OWNER],r8
 mov qword [r12+NEBO_GUARD_STATE],1
 xor eax,eax
 jmp .mutex_return
.mutex_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .mutex_return
.mutex_deadlock: mov eax,NEBO_CONCURRENCY_ERROR_DEADLOCK
 jmp .mutex_return
.mutex_timeout: mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.mutex_return:
 test r13,r13
 jz .mutex_pop
 lock dec qword [rbx+NEBO_SYNC_WAITERS]
.mutex_pop:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Guard.
nebo_mutex_unlock:
 test rdi,rdi
 jz .unlock_invalid
 cmp qword [rdi+NEBO_GUARD_STATE],1
 jne .unlock_again
 cmp qword [rdi+NEBO_GUARD_KIND],1
 jne .unlock_invalid
 mov r8,[rdi+NEBO_GUARD_LOCK]
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 cmp rax,[rdi+NEBO_GUARD_OWNER]
 jne .unlock_denied
 mov qword [r8+NEBO_SYNC_OWNER],0
 mov qword [r8+NEBO_SYNC_STATE],0
 lock inc qword [r8+NEBO_SYNC_GENERATION]
 mov qword [rdi+NEBO_GUARD_STATE],0
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 mov rdi,r8
 mov esi,NEBO_FUTEX_WAKE_PRIVATE
 mov edx,1
 syscall
 xor eax,eax
 ret
.unlock_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.unlock_again: mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret
.unlock_denied: mov eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 ret

; rdi=RwLock,rsi=Guard,rdx=max waits.
nebo_rwlock_read:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .read_invalid
 test r12,r12
 jz .read_invalid
.read_retry:
 mov rax,[rbx+NEBO_SYNC_STATE]
 test rax,rax
 js .read_wait
 cmp rax,0x7fffffff
 jae .read_limit
 lea rcx,[rax+1]
 lock cmpxchg [rbx+NEBO_SYNC_STATE],rcx
 jnz .read_retry
 mov [r12+NEBO_GUARD_LOCK],rbx
 mov qword [r12+NEBO_GUARD_KIND],2
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 mov [r12+NEBO_GUARD_OWNER],rax
 mov qword [r12+NEBO_GUARD_STATE],1
 xor eax,eax
 jmp .read_return
.read_wait:
 test rdx,rdx
 jz .read_timeout
 dec rdx
 mov eax,NEBO_LINUX_X86_64_SYS_SCHED_YIELD
 syscall
 jmp .read_retry
.read_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .read_return
.read_limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jmp .read_return
.read_timeout: mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.read_return:
 pop r12
 pop rbx
 ret

nebo_rwlock_write:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .write_invalid
 test r12,r12
 jz .write_invalid
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 mov r8,rax
 cmp [rbx+NEBO_SYNC_OWNER],r8
 je .write_deadlock
.write_retry:
 xor eax,eax
 mov rcx,-1
 lock cmpxchg [rbx+NEBO_SYNC_STATE],rcx
 jz .write_acquired
 test rdx,rdx
 jz .write_timeout
 dec rdx
 mov eax,NEBO_LINUX_X86_64_SYS_SCHED_YIELD
 syscall
 jmp .write_retry
.write_acquired:
 mov [rbx+NEBO_SYNC_OWNER],r8
 mov [r12+NEBO_GUARD_LOCK],rbx
 mov qword [r12+NEBO_GUARD_KIND],3
 mov [r12+NEBO_GUARD_OWNER],r8
 mov qword [r12+NEBO_GUARD_STATE],1
 xor eax,eax
 jmp .write_return
.write_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .write_return
.write_deadlock: mov eax,NEBO_CONCURRENCY_ERROR_DEADLOCK
 jmp .write_return
.write_timeout: mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
.write_return:
 pop r12
 pop rbx
 ret

nebo_rwlock_unlock:
 test rdi,rdi
 jz .rwunlock_invalid
 cmp qword [rdi+NEBO_GUARD_STATE],1
 jne .rwunlock_again
 mov eax,NEBO_LINUX_X86_64_SYS_GETTID
 syscall
 cmp rax,[rdi+NEBO_GUARD_OWNER]
 jne .rwunlock_denied
 mov r8,[rdi+NEBO_GUARD_LOCK]
 cmp qword [rdi+NEBO_GUARD_KIND],2
 je .rwunlock_reader
 cmp qword [rdi+NEBO_GUARD_KIND],3
 jne .rwunlock_invalid
 mov qword [r8+NEBO_SYNC_OWNER],0
 mov qword [r8+NEBO_SYNC_STATE],0
 jmp .rwunlock_done
.rwunlock_reader:
 lock dec qword [r8+NEBO_SYNC_STATE]
.rwunlock_done:
 lock inc qword [r8+NEBO_SYNC_GENERATION]
 mov qword [rdi+NEBO_GUARD_STATE],0
 mov eax,NEBO_LINUX_X86_64_SYS_FUTEX
 mov rdi,r8
 mov esi,NEBO_FUTEX_WAKE_PRIVATE
 mov edx,0x7fffffff
 syscall
 xor eax,eax
 ret
.rwunlock_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
.rwunlock_again: mov eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 ret
.rwunlock_denied: mov eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 ret

nebo_atomic_init:
 test rdi,rdi
 jz .atomic_invalid
 mov [rdi+NEBO_ATOMIC_VALUE],rsi
 mov qword [rdi+NEBO_ATOMIC_GENERATION],1
 xor eax,eax
 ret
.atomic_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret

; rdi=AtomicInt,rsi=order. eax=status,rdx=value.
nebo_atomic_load:
 test rdi,rdi
 jz atomic_invalid_result
 cmp rsi,NEBO_MEMORY_ORDER_SEQCST
 ja atomic_order_result
 cmp rsi,NEBO_MEMORY_ORDER_RELEASE
 je atomic_order_result
 cmp rsi,NEBO_MEMORY_ORDER_ACQREL
 je atomic_order_result
 mov rdx,[rdi+NEBO_ATOMIC_VALUE]
 xor eax,eax
 ret

; rdi=AtomicInt,rsi=value,rdx=order.
nebo_atomic_store:
 test rdi,rdi
 jz atomic_invalid
 cmp rdx,NEBO_MEMORY_ORDER_SEQCST
 ja atomic_order
 cmp rdx,NEBO_MEMORY_ORDER_ACQUIRE
 je atomic_order
 cmp rdx,NEBO_MEMORY_ORDER_ACQREL
 je atomic_order
 xchg rsi,[rdi+NEBO_ATOMIC_VALUE]
 lock inc qword [rdi+NEBO_ATOMIC_GENERATION]
 xor eax,eax
 ret

; rdi=AtomicInt,rsi=expected,rdx=desired,rcx=order. eax=status,r8=observed, r9=swapped.
nebo_atomic_compare_exchange:
 test rdi,rdi
 jz atomic_invalid
 cmp rcx,NEBO_MEMORY_ORDER_SEQCST
 ja atomic_order
 mov rax,rsi
 lock cmpxchg [rdi+NEBO_ATOMIC_VALUE],rdx
 mov r8,rax
 sete r9b
 movzx r9,r9b
 test r9,r9
 jz .cas_ok
 lock inc qword [rdi+NEBO_ATOMIC_GENERATION]
.cas_ok: xor eax,eax
 ret

; rdi=AtomicInt,rsi=delta,rdx=order. eax=status,r8=old.
nebo_atomic_fetch_add:
 test rdi,rdi
 jz atomic_invalid
 cmp rdx,NEBO_MEMORY_ORDER_SEQCST
 ja atomic_order
 mov r8,rsi
 lock xadd [rdi+NEBO_ATOMIC_VALUE],r8
 lock inc qword [rdi+NEBO_ATOMIC_GENERATION]
 xor eax,eax
 ret
atomic_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 ret
atomic_order: mov eax,NEBO_CONCURRENCY_ERROR_WRONG_ORDER
 ret
atomic_invalid_result: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
atomic_order_result: mov eax,NEBO_CONCURRENCY_ERROR_WRONG_ORDER
 xor edx,edx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
