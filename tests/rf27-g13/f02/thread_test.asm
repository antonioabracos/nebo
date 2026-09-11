bits 64
default rel
%include "runtime/concurrency/thread.inc"

section .bss
budget resb NEBO_THREAD_BUDGET_SIZE
thread resb NEBO_THREAD_SIZE
thread2 resb NEBO_THREAD_SIZE
thread_stack resb 16384

section .text
global _start
worker:
 lea rax,[rdi+rdi*2]
 add rax,1
 ret
_start:
 lea rdi,[budget]
 mov esi,1
 mov edx,16384
 mov ecx,1000000000
 call nebo_thread_budget_init
 test eax,eax
 jnz .fail1
 cmp qword [budget+NEBO_THREAD_BUDGET_ACTIVE],0
 jne .fail2
 call nebo_thread_current_id
 test eax,eax
 jnz .fail3
 test rdx,rdx
 jle .fail4
 call nebo_thread_yield
 test eax,eax
 jnz .fail5
 lea rdi,[thread]
 lea rsi,[budget]
 lea rdx,[worker]
 mov ecx,14
 lea r8,[thread_stack]
 mov r9d,16384
 call nebo_thread_spawn
 cmp eax,NEBO_CONCURRENCY_ERROR_UNSUPPORTED_TARGET
 je .unsupported
 test eax,eax
 jnz .fail6
 cmp qword [budget+NEBO_THREAD_BUDGET_ACTIVE],1
 jne .fail7
 lea rdi,[thread]
 call nebo_thread_join
 test eax,eax
 jnz .fail8
 cmp rdx,43
 jne .fail9
 cmp qword [thread+NEBO_THREAD_STATE],NEBO_THREAD_STATE_JOINED
 jne .fail10
 cmp qword [budget+NEBO_THREAD_BUDGET_ACTIVE],0
 jne .fail11
 lea rdi,[thread]
 call nebo_thread_join
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail12
.unsupported:
 lea rdi,[thread2]
 lea rsi,[budget]
 lea rdx,[worker]
 xor ecx,ecx
 lea r8,[thread_stack]
 mov r9d,1024
 call nebo_thread_spawn
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail13
 mov qword [budget+NEBO_THREAD_BUDGET_MAGIC],0
 lea rdi,[thread2]
 lea rsi,[budget]
 lea rdx,[worker]
 xor ecx,ecx
 lea r8,[thread_stack]
 mov r9d,16384
 call nebo_thread_spawn
 cmp eax,NEBO_CONCURRENCY_ERROR_PERMISSION_DENIED
 jne .fail14
 xor rdi,rdi
 call nebo_thread_join
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail15
 xor edi,edi
 jmp .exit
%assign i 1
%rep 15
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
