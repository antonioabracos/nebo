bits 64
default rel
%define NEBO_PROCESS_IMPLEMENTATION 1
%include "runtime/system/process.inc"
%define EINTR 4
%define ENOSYS 38
%define EPERM 1
%define SIGCHLD 17
%define SIGTERM 15
%define O_CLOEXEC 0x80000
%define SYS_READ 0
%define socket_SYS_WRITE 1

section .text
global nebo_process_capability_init
global nebo_process_current_pid
global nebo_process_pipe
global nebo_pipe_read
global nebo_pipe_write
global nebo_pipe_close
global nebo_process_spawn
global nebo_process_wait
global nebo_process_terminate

; rdi=cap, rsi=exact program path, rdx=bytes, rcx=max children,
; r8=max argv bytes, r9=max env bytes. eax=status.
nebo_process_capability_init:
 test rdi,rdi
 jz .cap_denied
 test rsi,rsi
 jz .cap_denied
 test rdx,rdx
 jz .cap_denied
 test rcx,rcx
 jz .cap_limit
 cmp rcx,NEBO_PROCESS_MAX_CHILDREN
 ja .cap_limit
 test r8,r8
 jz .cap_limit
 cmp r8,NEBO_PROCESS_MAX_ARGV_BYTES
 ja .cap_limit
 cmp r9,NEBO_PROCESS_MAX_ENV_BYTES
 ja .cap_limit
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_PROCESS
 mov [rdi+NEBO_PROCESS_CAPABILITY_MAGIC],rax
 mov [rdi+NEBO_PROCESS_CAPABILITY_PROGRAM_SET],rsi
 mov [rdi+NEBO_PROCESS_CAPABILITY_PROGRAM_COUNT],rdx
 mov [rdi+NEBO_PROCESS_CAPABILITY_MAX_CHILDREN],rcx
 mov [rdi+NEBO_PROCESS_CAPABILITY_MAX_ARGV_BYTES],r8
 mov [rdi+NEBO_PROCESS_CAPABILITY_MAX_ENV_BYTES],r9
 mov qword [rdi+NEBO_PROCESS_CAPABILITY_MAX_LIFETIME_NS],1000000000
 mov qword [rdi+NEBO_PROCESS_CAPABILITY_GENERATION],0
 xor eax,eax
 ret
.cap_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.cap_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

nebo_process_current_pid:
 mov eax,NEBO_LINUX_X86_64_SYS_GETPID
 syscall
 mov rdx,rax
 xor eax,eax
 ret

; rdi=64-byte pair of PipeEnd, rsi=capability. eax=status.
nebo_process_pipe:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .pipe_invalid
 mov rdi,r12
 call process_cap_validate
 test eax,eax
 jnz .pipe_return
 sub rsp,16
 mov eax,NEBO_LINUX_X86_64_SYS_PIPE2
 mov rdi,rsp
 mov esi,O_CLOEXEC
 syscall
 cmp rax,-4095
 jae .pipe_syscall
 mov eax,[rsp]
 mov [rbx+NEBO_PIPE_END_FD],rax
 mov qword [rbx+NEBO_PIPE_END_STATE],NEBO_RESOURCE_STATE_OPEN
 mov [rbx+NEBO_PIPE_END_CAPABILITY],r12
 mov qword [rbx+NEBO_PIPE_END_FLAGS],0
 mov eax,[rsp+4]
 mov [rbx+NEBO_PIPE_END_SIZE+NEBO_PIPE_END_FD],rax
 mov qword [rbx+NEBO_PIPE_END_SIZE+NEBO_PIPE_END_STATE],NEBO_RESOURCE_STATE_OPEN
 mov [rbx+NEBO_PIPE_END_SIZE+NEBO_PIPE_END_CAPABILITY],r12
 mov qword [rbx+NEBO_PIPE_END_SIZE+NEBO_PIPE_END_FLAGS],1
 add rsp,16
 xor eax,eax
 jmp .pipe_return
.pipe_syscall:
 add rsp,16
 mov eax,NEBO_SYSTEM_ERROR_IO
 jmp .pipe_return
.pipe_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.pipe_return:
 pop r12
 pop rbx
 ret

; rdi=PipeEnd, rsi=buffer, rdx=bytes. eax=status, rdx=count.
nebo_pipe_read:
 mov r8,SYS_READ
 xor r9d,r9d
 jmp pipe_io

nebo_pipe_write:
 mov r8,socket_SYS_WRITE
 mov r9d,1
 jmp pipe_io

nebo_pipe_close:
 test rdi,rdi
 jz .close_invalid
 cmp qword [rdi+NEBO_PIPE_END_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .close_closed
.close_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rsi,rdi
 mov rdi,[rsi+NEBO_PIPE_END_FD]
 syscall
 cmp rax,-EINTR
 je .close_retry
 mov qword [rsi+NEBO_PIPE_END_STATE],NEBO_RESOURCE_STATE_CLOSED
 cmp rax,-4095
 jae .close_io
 xor eax,eax
 ret
.close_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.close_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 ret
.close_io:
 mov eax,NEBO_SYSTEM_ERROR_IO
 ret

; rdi=Process out, rsi=capability, rdx=path, rcx=path bytes,
; r8=argv, r9=envp, stack args [rsp+8]=argv bytes [rsp+16]=env bytes.
nebo_process_spawn:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .spawn_invalid
 mov rdi,r13
 call process_cap_validate
 test eax,eax
 jnz .spawn_return
 cmp r15,[r13+NEBO_PROCESS_CAPABILITY_PROGRAM_COUNT]
 jne .spawn_denied
 mov rdi,[r13+NEBO_PROCESS_CAPABILITY_PROGRAM_SET]
 xor ecx,ecx
.path_compare:
 cmp rcx,r15
 jae .path_ok
 mov al,[rdi+rcx]
 cmp al,[r14+rcx]
 jne .spawn_denied
 test al,al
 jz .spawn_denied
 inc rcx
 jmp .path_compare
.path_ok:
 cmp byte [r14+r15],0
 jne .spawn_invalid
 mov rax,[rsp+48]
 cmp rax,[r13+NEBO_PROCESS_CAPABILITY_MAX_ARGV_BYTES]
 ja .spawn_limit
 mov rax,[rsp+56]
 cmp rax,[r13+NEBO_PROCESS_CAPABILITY_MAX_ENV_BYTES]
 ja .spawn_limit
 mov rax,[r13+NEBO_PROCESS_CAPABILITY_GENERATION]
 cmp rax,[r13+NEBO_PROCESS_CAPABILITY_MAX_CHILDREN]
 jae .spawn_limit
 sub rsp,96
 xor eax,eax
 mov ecx,12
 mov rdi,rsp
 rep stosq
 mov qword [rsp+32],SIGCHLD
 mov eax,NEBO_LINUX_X86_64_SYS_CLONE3
 mov rdi,rsp
 mov esi,88
 syscall
 test rax,rax
 jz .spawn_child
 cmp rax,-4095
 jae .spawn_syscall
 mov [r12+NEBO_PROCESS_PID],rax
 mov qword [r12+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 mov [r12+NEBO_PROCESS_CAPABILITY],r13
 mov qword [r12+NEBO_PROCESS_EXIT_STATUS],0
 mov qword [r12+NEBO_PROCESS_FLAGS],0
 mov qword [r12+NEBO_PROCESS_DEADLINE_NS],0
 mov qword [r12+NEBO_PROCESS_RESERVED0],0
 mov qword [r12+NEBO_PROCESS_RESERVED1],0
 inc qword [r13+NEBO_PROCESS_CAPABILITY_GENERATION]
 add rsp,96
 xor eax,eax
 jmp .spawn_return
.spawn_child:
 mov eax,NEBO_LINUX_X86_64_SYS_EXECVE
 mov rdi,r14
 mov rsi,rbx
 mov rdx,r9
 syscall
 mov edi,127
 mov eax,60
 syscall
.spawn_syscall:
 add rsp,96
 cmp rax,-ENOSYS
 je .spawn_unsupported
 cmp rax,-EPERM
 je .spawn_unsupported
 mov eax,NEBO_SYSTEM_ERROR_IO
 jmp .spawn_return
.spawn_unsupported:
 mov eax,NEBO_SYSTEM_ERROR_UNSUPPORTED_TARGET
 jmp .spawn_return
.spawn_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .spawn_return
.spawn_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jmp .spawn_return
.spawn_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.spawn_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Process. eax=status, rdx=exit code.
nebo_process_wait:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .wait_invalid
 cmp qword [rbx+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 jne .wait_completed
 sub rsp,16
.wait_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_WAIT4
 mov rdi,[rbx+NEBO_PROCESS_PID]
 mov rsi,rsp
 xor edx,edx
 xor r10d,r10d
 syscall
 cmp rax,-EINTR
 je .wait_retry
 cmp rax,-4095
 jae .wait_io
 mov eax,[rsp]
 mov edx,eax
 and edx,0x7f
 jnz .wait_signaled
 shr eax,8
 and eax,0xff
 mov edx,eax
 jmp .wait_store
.wait_signaled:
 or edx,0x100
.wait_store:
 add rsp,16
 mov [rbx+NEBO_PROCESS_EXIT_STATUS],rdx
 mov qword [rbx+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_REAPED
 mov rcx,[rbx+NEBO_PROCESS_CAPABILITY]
 dec qword [rcx+NEBO_PROCESS_CAPABILITY_GENERATION]
 xor eax,eax
 jmp .wait_return
.wait_io:
 add rsp,16
 mov eax,NEBO_SYSTEM_ERROR_IO
 xor edx,edx
 jmp .wait_return
.wait_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .wait_return
.wait_completed:
 mov eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 xor edx,edx
.wait_return:
 pop rbx
 ret

; rdi=Process. SIGTERM only.
nebo_process_terminate:
 test rdi,rdi
 jz .term_invalid
 cmp qword [rdi+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 jne .term_completed
 mov r8,rdi
 mov eax,NEBO_LINUX_X86_64_SYS_KILL
 mov rdi,[r8+NEBO_PROCESS_PID]
 mov esi,SIGTERM
 syscall
 cmp rax,-4095
 jae .term_io
 mov qword [r8+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_TERMINATED
 ; wait() remains authorized after terminate, so restore RUNNING marker.
 mov qword [r8+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 xor eax,eax
 ret
.term_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.term_completed:
 mov eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 ret
.term_io:
 mov eax,NEBO_SYSTEM_ERROR_IO
 ret

process_cap_validate:
 test rdi,rdi
 jz .validate_denied
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_PROCESS
 cmp [rdi+NEBO_PROCESS_CAPABILITY_MAGIC],rax
 jne .validate_denied
 xor eax,eax
 ret
.validate_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret

; rdi=end, rsi=buffer, rdx=bytes, r8=syscall, r9=required direction.
pipe_io:
 test rdi,rdi
 jz .io_invalid
 test rsi,rsi
 jz .io_invalid
 cmp qword [rdi+NEBO_PIPE_END_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .io_closed
 cmp [rdi+NEBO_PIPE_END_FLAGS],r9
 jne .io_denied
 mov r10,rdi
.io_retry:
 mov rax,r8
 mov rdi,[r10+NEBO_PIPE_END_FD]
 syscall
 cmp rax,-EINTR
 je .io_retry
 cmp rax,-4095
 jae .io_failure
 mov rdx,rax
 xor eax,eax
 ret
.io_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.io_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 xor edx,edx
 ret
.io_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 xor edx,edx
 ret
.io_failure:
 mov eax,NEBO_SYSTEM_ERROR_IO
 xor edx,edx
 ret
