bits 64
default rel
%include "runtime/concurrency/cancel.inc"
section .bss
budget resb NEBO_CANCELLATION_BUDGET_SIZE
parent resb NEBO_CANCELLATION_TOKEN_SIZE
child resb NEBO_CANCELLATION_TOKEN_SIZE
expired resb NEBO_CANCELLATION_TOKEN_SIZE
deadline resb NEBO_DEADLINE_SIZE
cleanups resq 1
section .text
global _start
cleanup: inc qword [cleanups]
 ret
_start:
 lea rdi,[budget]
 mov esi,3
 mov edx,2
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 test eax,eax
 jnz .fail1
 lea rdi,[parent]
 lea rsi,[budget]
 xor edx,edx
 xor ecx,ecx
 lea r8,[cleanup]
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail2
 lea rdi,[child]
 lea rsi,[budget]
 lea rdx,[parent]
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail3
 lea rdi,[child]
 call nebo_cancellation_check
 test eax,eax
 jnz .fail4
 lea rdi,[parent]
 call nebo_cancellation_cancel
 test eax,eax
 jnz .fail5
 cmp edx,1
 jne .fail6
 cmp qword [cleanups],1
 jne .fail7
 lea rdi,[parent]
 call nebo_cancellation_cancel
 test eax,eax
 jnz .fail8
 test edx,edx
 jnz .fail9
 cmp qword [cleanups],1
 jne .fail10
 lea rdi,[child]
 call nebo_cancellation_check
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 jne .fail11
 mov qword [deadline],0
 mov qword [deadline+8],1
 lea rdi,[expired]
 lea rsi,[budget]
 xor edx,edx
 lea rcx,[deadline]
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail12
 lea rdi,[expired]
 call nebo_deadline_expired
 test eax,eax
 jnz .fail13
 cmp edx,1
 jne .fail14
 lea rdi,[expired]
 call nebo_cancellation_check
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .fail15
 lea rdi,[budget]
 lea rsi,[expired]
 call nebo_cancellation_release
 test eax,eax
 jnz .fail16
 lea rdi,[budget]
 lea rsi,[expired]
 call nebo_cancellation_release
 cmp eax,NEBO_CONCURRENCY_ERROR_ALREADY_COMPLETED
 jne .fail17
 lea rdi,[budget]
 xor esi,esi
 mov edx,1
 mov ecx,1
 call nebo_cancellation_budget_init
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail18
 xor rdi,rdi
 call nebo_cancellation_check
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
