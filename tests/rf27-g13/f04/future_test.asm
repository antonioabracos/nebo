bits 64
default rel
%include "runtime/concurrency/future.inc"
section .bss
future_a resb NEBO_FUTURE_SIZE
future_b resb NEBO_FUTURE_SIZE
future_c resb NEBO_FUTURE_SIZE
wakes resq 1
section .text
global _start
waker: inc qword [wakes]
 ret
mapper: lea rax,[rdi+rdi]
 ret
_start:
 lea rdi,[future_a]
 mov esi,4
 call nebo_future_init
 test eax,eax
 jnz .fail1
 lea rdi,[future_a]
 call nebo_future_poll
 test eax,eax
 jnz .fail2
 test edx,edx
 jnz .fail3
 lea rdi,[future_a]
 lea rsi,[waker]
 xor edx,edx
 call nebo_future_set_waker
 test eax,eax
 jnz .fail4
 lea rdi,[future_a]
 mov esi,21
 xor edx,edx
 call nebo_future_complete
 test eax,eax
 jnz .fail5
 cmp qword [wakes],1
 jne .fail6
 lea rdi,[future_a]
 call nebo_future_poll
 test eax,eax
 jnz .fail7
 cmp edx,1
 jne .fail8
 cmp r8,21
 jne .fail9
 lea rdi,[future_b]
 lea rsi,[future_a]
 lea rdx,[mapper]
 mov ecx,3
 call nebo_future_map
 test eax,eax
 jnz .fail10
 lea rdi,[future_a]
 lea rsi,[future_b]
 call nebo_future_select
 test eax,eax
 jnz .fail11
 test edx,edx
 jnz .fail12
 cmp r8,21
 jne .fail13
 lea rdi,[future_b]
 call nebo_task_await
 test eax,eax
 jnz .fail14
 cmp rdx,42
 jne .fail15
 lea rdi,[future_b]
 call nebo_task_await
 cmp eax,NEBO_CONCURRENCY_ERROR_WOULD_BLOCK
 jne .fail16
 lea rdi,[future_a]
 mov esi,9
 xor edx,edx
 call nebo_future_complete
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail17
 lea rdi,[future_c]
 xor esi,esi
 call nebo_future_init
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail18
 xor edi,edi
 jmp .exit
%assign i 1
%rep 18
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
