bits 64
default rel
%define NEBO_TIMEOUT_IMPLEMENTATION 1
%include "runtime/system/timeout.inc"
%define EINTR 4
%define WNOHANG 1
section .text
global nebo_fd_wait
global nebo_socket_wait_readable
global nebo_socket_wait_writable
global nebo_process_wait_timeout

; rdi=fd, rsi=events, rdx=timeout milliseconds, rcx=optional token.
; One-millisecond poll slices guarantee bounded cancellation observation.
nebo_fd_wait:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 js .wait_invalid
.wait_loop:
 test r14,r14
 jz .wait_poll
 mov rdi,r14
 call nebo_cancellation_check
 test eax,eax
 jnz .wait_return
.wait_poll:
 sub rsp,8
 mov [rsp],ebx
 mov [rsp+4],r12w
 mov word [rsp+6],0
 mov eax,NEBO_LINUX_X86_64_SYS_POLL
 mov rdi,rsp
 mov esi,1
 xor edx,edx
 test r13,r13
 jz .poll_call
 mov edx,1
.poll_call:
 syscall
 cmp rax,-EINTR
 je .poll_interrupted
 cmp rax,-4095
 jae .poll_io
 test rax,rax
 jnz .poll_ready
 add rsp,8
 test r13,r13
 jz .wait_timeout
 dec r13
 jnz .wait_loop
.wait_timeout:
 mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 xor edx,edx
 jmp .wait_return
.poll_interrupted:
 add rsp,8
 jmp .wait_loop
.poll_io:
 add rsp,8
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 xor edx,edx
 jmp .wait_return
.poll_ready:
 movzx edx,word [rsp+6]
 add rsp,8
 xor eax,eax
 jmp .wait_return
.wait_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
.wait_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

nebo_socket_wait_readable:
 mov rdi,[rdi]
 mov esi,NEBO_POLL_READ
 jmp nebo_fd_wait
nebo_socket_wait_writable:
 mov rdi,[rdi]
 mov esi,NEBO_POLL_WRITE
 jmp nebo_fd_wait

; rdi=Process, rsi=timeout ms, rdx=optional token. eax=status,rdx=exit.
nebo_process_wait_timeout:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test rbx,rbx
 jz .process_invalid
 cmp qword [rbx+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 jne .process_transition
.process_loop:
 test r13,r13
 jz .process_probe
 mov rdi,r13
 call nebo_cancellation_check
 test eax,eax
 jnz .process_return
.process_probe:
 sub rsp,16
 mov eax,NEBO_LINUX_X86_64_SYS_WAIT4
 mov rdi,[rbx+NEBO_PROCESS_PID]
 mov rsi,rsp
 mov edx,WNOHANG
 xor r10d,r10d
 syscall
 cmp rax,-EINTR
 je .process_eintr
 cmp rax,-4095
 jae .process_io
 test rax,rax
 jnz .process_done
 add rsp,16
 test r12,r12
 jz .process_timeout
 dec r12
 mov eax,NEBO_LINUX_X86_64_SYS_POLL
 xor edi,edi
 xor esi,esi
 mov edx,1
 syscall
 cmp rax,-EINTR
 je .process_loop
 cmp rax,-4095
 jae .process_io_nostack
 jmp .process_loop
.process_done:
 mov eax,[rsp]
 add rsp,16
 shr eax,8
 and eax,0xff
 mov edx,eax
 mov [rbx+NEBO_PROCESS_EXIT_STATUS],rdx
 mov qword [rbx+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_REAPED
 mov rcx,[rbx+NEBO_PROCESS_CAPABILITY]
 test rcx,rcx
 jz .process_ok
 cmp qword [rcx+NEBO_PROCESS_CAPABILITY_GENERATION],0
 je .process_ok
 dec qword [rcx+NEBO_PROCESS_CAPABILITY_GENERATION]
.process_ok:
 xor eax,eax
 jmp .process_return
.process_eintr:
 add rsp,16
 jmp .process_loop
.process_io:
 add rsp,16
.process_io_nostack:
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 xor edx,edx
 jmp .process_return
.process_timeout:
 mov eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 xor edx,edx
 jmp .process_return
.process_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .process_return
.process_transition:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_TRANSITION
 xor edx,edx
.process_return:
 pop r13
 pop r12
 pop rbx
 ret
