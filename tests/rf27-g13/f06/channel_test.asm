bits 64
default rel
%include "runtime/concurrency/channel.inc"
section .bss
budget resb NEBO_CHANNEL_BUDGET_SIZE
channel resb NEBO_CHANNEL_SIZE
storage resq 3
section .text
global _start
_start:
 lea rdi,[budget]
 mov esi,3
 mov edx,4
 mov ecx,1000000
 call nebo_channel_budget_init
 test eax,eax
 jnz .fail1
 lea rdi,[channel]
 lea rsi,[budget]
 lea rdx,[storage]
 mov ecx,2
 call nebo_channel_init
 test eax,eax
 jnz .fail2
 lea rdi,[channel]
 mov esi,11
 call nebo_channel_try_send
 test eax,eax
 jnz .fail3
 lea rdi,[channel]
 mov esi,22
 call nebo_channel_try_send
 test eax,eax
 jnz .fail4
 lea rdi,[channel]
 mov esi,33
 call nebo_channel_try_send
 cmp eax,NEBO_CONCURRENCY_ERROR_FULL
 jne .fail5
 lea rdi,[channel]
 call nebo_channel_try_receive
 test eax,eax
 jnz .fail6
 cmp rdx,11
 jne .fail7
 lea rdi,[channel]
 mov esi,33
 call nebo_channel_try_send
 test eax,eax
 jnz .fail8
 lea rdi,[channel]
 call nebo_channel_try_receive
 test eax,eax
 jnz .fail9
 cmp rdx,22
 jne .fail10
 lea rdi,[channel]
 call nebo_channel_try_receive
 test eax,eax
 jnz .fail11
 cmp rdx,33
 jne .fail12
 lea rdi,[channel]
 call nebo_channel_try_receive
 cmp eax,NEBO_CONCURRENCY_ERROR_EMPTY
 jne .fail13
 lea rdi,[channel]
 call nebo_channel_close_sender
 test eax,eax
 jnz .fail14
 lea rdi,[channel]
 mov esi,44
 call nebo_channel_try_send
 cmp eax,NEBO_CONCURRENCY_ERROR_CLOSED
 jne .fail15
 lea rdi,[channel]
 call nebo_channel_try_receive
 cmp eax,NEBO_CONCURRENCY_ERROR_CLOSED
 jne .fail16
 lea rdi,[channel]
 call nebo_channel_close_sender
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail17
 lea rdi,[budget]
 mov esi,NEBO_CONCURRENCY_MAX_CHANNEL_CAPACITY+1
 mov edx,1
 xor ecx,ecx
 call nebo_channel_budget_init
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail18
 xor rdi,rdi
 call nebo_channel_try_receive
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail19
 xor edi,edi
 jmp .exit
%assign i 1
%rep 19
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
