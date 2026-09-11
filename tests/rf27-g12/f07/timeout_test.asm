bits 64
default rel
%include "runtime/system/timeout.inc"
section .bss
fds resd 2
budget resb NEBO_CANCELLATION_BUDGET_SIZE
token resb NEBO_CANCELLATION_TOKEN_SIZE
io_byte resb 1
socket_stub resq 1
section .text
global _start
_start:
 mov eax,293
 lea rdi,[fds]
 mov esi,0x80000
 syscall
 test rax,rax
 jnz .fail1
 mov edi,[fds]
 mov esi,NEBO_POLL_READ
 xor edx,edx
 xor ecx,ecx
 call nebo_fd_wait
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .fail2
 mov eax,[fds]
 mov [socket_stub],rax
 lea rdi,[socket_stub]
 xor edx,edx
 xor ecx,ecx
 call nebo_socket_wait_readable
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .fail11
 mov eax,1
 mov edi,[fds+4]
 lea rsi,[io_byte]
 mov byte [io_byte],7
 mov edx,1
 syscall
 cmp rax,1
 jne .fail3
 mov edi,[fds]
 mov esi,NEBO_POLL_READ
 mov edx,10
 xor ecx,ecx
 call nebo_fd_wait
 test eax,eax
 jnz .fail4
 test edx,NEBO_POLL_READ
 jz .fail5
 lea rdi,[socket_stub]
 mov edx,10
 xor ecx,ecx
 call nebo_socket_wait_readable
 test eax,eax
 jnz .fail12
 mov eax,[fds+4]
 mov [socket_stub],rax
 lea rdi,[socket_stub]
 mov edx,10
 xor ecx,ecx
 call nebo_socket_wait_writable
 test eax,eax
 jnz .fail13
 lea rdi,[budget]
 mov esi,1
 mov edx,1
 mov ecx,1000000
 call nebo_cancellation_budget_init
 test eax,eax
 jnz .fail6
 lea rdi,[token]
 lea rsi,[budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail7
 lea rdi,[token]
 call nebo_cancellation_cancel
 test eax,eax
 jnz .fail8
 mov edi,[fds]
 mov esi,NEBO_POLL_READ
 mov edx,10
 lea rcx,[token]
 call nebo_fd_wait
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 jne .fail9
 mov eax,[fds]
 mov [socket_stub],rax
 lea rdi,[socket_stub]
 mov edx,10
 lea rcx,[token]
 call nebo_socket_wait_readable
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 jne .fail14
 mov edi,[fds]
 mov eax,3
 syscall
 mov edi,[fds+4]
 mov eax,3
 syscall
 mov rdi,-1
 mov esi,NEBO_POLL_READ
 xor edx,edx
 xor ecx,ecx
 call nebo_fd_wait
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail10
 xor edi,edi
 jmp .exit
%assign i 1
%rep 14
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
