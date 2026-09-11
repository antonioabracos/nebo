bits 64
default rel
%include "runtime/concurrency/thread.inc"
%include "runtime/concurrency/sync.inc"
%include "runtime/concurrency/channel.inc"

%define LOOPS 2000
%define CHANNEL_LOOPS 512
section .bss
thread_budget resb NEBO_THREAD_BUDGET_SIZE
thread_a resb NEBO_THREAD_SIZE
thread_b resb NEBO_THREAD_SIZE
stack_a resb 16384
stack_b resb 16384
atomic resb NEBO_ATOMIC_INT_SIZE
worker_arg resq 2
channel_budget resb NEBO_CHANNEL_BUDGET_SIZE
channel resb NEBO_CHANNEL_SIZE
channel_storage resq 8

section .text
global _start
worker:
 push rbx
 push r12
 mov rbx,[rdi]
 mov r12,[rdi+8]
.worker_loop:
 test r12,r12
 jz .worker_done
 mov rdi,rbx
 mov esi,1
 mov edx,NEBO_MEMORY_ORDER_SEQCST
 call nebo_atomic_fetch_add
 test eax,eax
 jnz .worker_error
 dec r12
 jmp .worker_loop
.worker_done:
 mov eax,LOOPS
 pop r12
 pop rbx
 ret
.worker_error:
 mov rax,-1
 pop r12
 pop rbx
 ret

_start:
 lea rdi,[atomic]
 xor esi,esi
 call nebo_atomic_init
 test eax,eax
 jnz .fail1
 lea rdi,[thread_budget]
 mov esi,2
 mov edx,16384
 mov ecx,1000000000
 call nebo_thread_budget_init
 test eax,eax
 jnz .fail2
 lea rax,[atomic]
 mov [worker_arg],rax
 mov qword [worker_arg+8],LOOPS
 lea rdi,[thread_a]
 lea rsi,[thread_budget]
 lea rdx,[worker]
 lea rcx,[worker_arg]
 lea r8,[stack_a]
 mov r9d,16384
 call nebo_thread_spawn
 test eax,eax
 jnz .fail3
 lea rdi,[thread_b]
 lea rsi,[thread_budget]
 lea rdx,[worker]
 lea rcx,[worker_arg]
 lea r8,[stack_b]
 mov r9d,16384
 call nebo_thread_spawn
 test eax,eax
 jnz .fail4
 lea rdi,[thread_a]
 call nebo_thread_join
 test eax,eax
 jnz .fail5
 cmp rdx,LOOPS
 jne .fail6
 lea rdi,[thread_b]
 call nebo_thread_join
 test eax,eax
 jnz .fail7
 cmp rdx,LOOPS
 jne .fail8
 lea rdi,[atomic]
 mov esi,NEBO_MEMORY_ORDER_SEQCST
 call nebo_atomic_load
 test eax,eax
 jnz .fail9
 cmp rdx,LOOPS*2
 jne .fail10
 cmp qword [thread_budget+NEBO_THREAD_BUDGET_ACTIVE],0
 jne .fail11

 lea rdi,[channel_budget]
 mov esi,8
 mov edx,4
 mov ecx,1000000
 call nebo_channel_budget_init
 test eax,eax
 jnz .fail12
 lea rdi,[channel]
 lea rsi,[channel_budget]
 lea rdx,[channel_storage]
 mov ecx,8
 call nebo_channel_init
 test eax,eax
 jnz .fail13
 xor r12d,r12d
.channel_loop:
 cmp r12,CHANNEL_LOOPS
 jae .channel_done
 lea rdi,[channel]
 mov rsi,r12
 call nebo_channel_try_send
 test eax,eax
 jnz .fail14
 lea rdi,[channel]
 call nebo_channel_try_receive
 test eax,eax
 jnz .fail15
 cmp rdx,r12
 jne .fail16
 inc r12
 jmp .channel_loop
.channel_done:
 cmp qword [channel+NEBO_CHANNEL_COUNT],0
 jne .fail17
 xor edi,edi
 jmp .exit
%assign i 1
%rep 17
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
