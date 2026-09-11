bits 64
default rel
%include "runtime/concurrency/sync.inc"
section .bss
budget resb NEBO_SYNCHRONIZATION_BUDGET_SIZE
mutex resb NEBO_MUTEX_SIZE
rwlock resb NEBO_RWLOCK_SIZE
guard1 resb NEBO_MUTEX_GUARD_SIZE
guard2 resb NEBO_MUTEX_GUARD_SIZE
atomic resb NEBO_ATOMIC_INT_SIZE
section .text
global _start
_start:
 lea rdi,[budget]
 mov esi,4
 mov edx,1000000
 call nebo_sync_budget_init
 test eax,eax
 jnz .fail1
 lea rdi,[mutex]
 lea rsi,[budget]
 call nebo_mutex_init
 test eax,eax
 jnz .fail2
 lea rdi,[mutex]
 lea rsi,[guard1]
 mov edx,2
 call nebo_mutex_lock
 test eax,eax
 jnz .fail3
 lea rdi,[mutex]
 lea rsi,[guard2]
 mov edx,1
 call nebo_mutex_lock
 cmp eax,NEBO_CONCURRENCY_ERROR_DEADLOCK
 jne .fail4
 lea rdi,[guard1]
 call nebo_mutex_unlock
 test eax,eax
 jnz .fail5
 lea rdi,[guard1]
 call nebo_mutex_unlock
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail6
 lea rdi,[rwlock]
 lea rsi,[budget]
 call nebo_rwlock_init
 test eax,eax
 jnz .fail7
 lea rdi,[rwlock]
 lea rsi,[guard1]
 mov edx,1
 call nebo_rwlock_read
 test eax,eax
 jnz .fail8
 lea rdi,[rwlock]
 lea rsi,[guard2]
 mov edx,1
 call nebo_rwlock_read
 test eax,eax
 jnz .fail9
 lea rdi,[guard2]
 call nebo_rwlock_unlock
 test eax,eax
 jnz .fail10
 lea rdi,[guard1]
 call nebo_rwlock_unlock
 test eax,eax
 jnz .fail11
 lea rdi,[rwlock]
 lea rsi,[guard1]
 mov edx,1
 call nebo_rwlock_write
 test eax,eax
 jnz .fail12
 lea rdi,[guard1]
 call nebo_rwlock_unlock
 test eax,eax
 jnz .fail13
 lea rdi,[atomic]
 mov esi,10
 call nebo_atomic_init
 test eax,eax
 jnz .fail14
 lea rdi,[atomic]
 mov esi,NEBO_MEMORY_ORDER_ACQUIRE
 call nebo_atomic_load
 test eax,eax
 jnz .fail15
 cmp rdx,10
 jne .fail16
 lea rdi,[atomic]
 mov esi,10
 mov edx,20
 mov ecx,NEBO_MEMORY_ORDER_ACQREL
 call nebo_atomic_compare_exchange
 test eax,eax
 jnz .fail17
 cmp r9,1
 jne .fail18
 lea rdi,[atomic]
 mov esi,5
 mov edx,NEBO_MEMORY_ORDER_SEQCST
 call nebo_atomic_fetch_add
 test eax,eax
 jnz .fail19
 cmp r8,20
 jne .fail20
 lea rdi,[atomic]
 mov esi,NEBO_MEMORY_ORDER_RELEASE
 call nebo_atomic_load
 cmp eax,NEBO_CONCURRENCY_ERROR_WRONG_ORDER
 jne .fail21
 lea rdi,[atomic]
 mov esi,1
 mov edx,NEBO_MEMORY_ORDER_ACQUIRE
 call nebo_atomic_store
 cmp eax,NEBO_CONCURRENCY_ERROR_WRONG_ORDER
 jne .fail22
 lea rdi,[budget]
 xor esi,esi
 xor edx,edx
 call nebo_sync_budget_init
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail23
 xor edi,edi
 jmp .exit
%assign i 1
%rep 23
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
