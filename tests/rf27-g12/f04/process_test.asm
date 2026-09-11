bits 64
default rel
%include "runtime/system/process.inc"

section .rodata
helper_path db 'build/tests/rf27-g12/f04/process_helper',0
helper_len equ $-helper_path-1
bad_path db 'build/bin/neboc',0
pipe_payload db 'pipe-ok'
empty_env dq 0
argv dq helper_path,0

section .bss
capability resb NEBO_PROCESS_CAPABILITY_SIZE
pipe_pair resb 64
process resb NEBO_PROCESS_SIZE
read_buffer resb 16

section .text
global _start
_start:
 call nebo_process_current_pid
 test eax,eax
 jnz .fail1
 test rdx,rdx
 jle .fail2
 lea rdi,[capability]
 lea rsi,[helper_path]
 mov edx,helper_len
 mov ecx,2
 mov r8d,256
 mov r9d,256
 call nebo_process_capability_init
 test eax,eax
 jnz .fail3
 lea rdi,[pipe_pair]
 lea rsi,[capability]
 call nebo_process_pipe
 test eax,eax
 jnz .fail4
 lea rdi,[pipe_pair+NEBO_PIPE_END_SIZE]
 lea rsi,[pipe_payload]
 mov edx,7
 call nebo_pipe_write
 test eax,eax
 jnz .fail5
 cmp rdx,7
 jne .fail6
 lea rdi,[pipe_pair]
 lea rsi,[read_buffer]
 mov edx,7
 call nebo_pipe_read
 test eax,eax
 jnz .fail7
 cmp rdx,7
 jne .fail8
 mov rax,[read_buffer]
 cmp rax,[pipe_payload]
 jne .fail9
 lea rdi,[pipe_pair]
 call nebo_pipe_close
 test eax,eax
 jnz .fail10
 lea rdi,[pipe_pair]
 call nebo_pipe_close
 cmp eax,NEBO_SYSTEM_ERROR_CLOSED
 jne .fail11
 lea rdi,[pipe_pair+NEBO_PIPE_END_SIZE]
 call nebo_pipe_close
 test eax,eax
 jnz .fail12
 lea rdi,[process]
 lea rsi,[capability]
 lea rdx,[bad_path]
 mov ecx,15
 lea r8,[argv]
 lea r9,[empty_env]
 push qword 0
 push qword 16
 call nebo_process_spawn
 add rsp,16
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail13
 lea rdi,[process]
 lea rsi,[capability]
 lea rdx,[helper_path]
 mov ecx,helper_len
 lea r8,[argv]
 lea r9,[empty_env]
 push qword 0
 push qword helper_len+1
 call nebo_process_spawn
 add rsp,16
 cmp eax,NEBO_SYSTEM_ERROR_UNSUPPORTED_TARGET
 je .unsupported
 test eax,eax
 jnz .fail14
 cmp qword [process+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_RUNNING
 jne .fail15
 lea rdi,[process]
 call nebo_process_wait
 test eax,eax
 jnz .fail16
 cmp rdx,7
 jne .fail17
 cmp qword [process+NEBO_PROCESS_STATE],NEBO_PROCESS_STATE_REAPED
 jne .fail18
 lea rdi,[process]
 call nebo_process_wait
 cmp eax,NEBO_SYSTEM_ERROR_ALREADY_COMPLETED
 jne .fail19
 cmp qword [capability+NEBO_PROCESS_CAPABILITY_GENERATION],0
 jne .fail20
 jmp .post_spawn
.unsupported:
 cmp qword [process+NEBO_PROCESS_STATE],0
 jne .fail21
.post_spawn:
 mov qword [capability+NEBO_PROCESS_CAPABILITY_MAGIC],0
 lea rdi,[pipe_pair]
 lea rsi,[capability]
 call nebo_process_pipe
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail22
 lea rdi,[capability]
 lea rsi,[helper_path]
 mov edx,helper_len
 mov ecx,NEBO_PROCESS_MAX_CHILDREN+1
 mov r8d,1
 xor r9d,r9d
 call nebo_process_capability_init
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail23
 xor edi,edi
 jmp .exit
%assign i 1
%rep 23
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
