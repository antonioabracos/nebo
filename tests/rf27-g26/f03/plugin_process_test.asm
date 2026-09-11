bits 64
default rel
%include "runtime/plugins/plugin_process.inc"
extern nebo_plugin_process_init,nebo_plugin_process_call,nebo_plugin_process_shutdown
section .bss
state resb NEBO_PROCESS_STATE_SIZE
init_req resb NEBO_PROCESS_INIT_SIZE
call_req resb NEBO_PROCESS_CALL_SIZE
shut_req resb NEBO_PROCESS_SHUT_SIZE
wait_status resd 1
section .text
global _start
_start:
 mov eax,57
 syscall
 test rax,rax
 js fail
 jz child
 mov r12,rax
 mov rdi,rax
 lea rsi,[wait_status]
 xor edx,edx
 xor r10d,r10d
 mov eax,61
 syscall
 cmp rax,r12
 jne fail
 lea rax,[state]
 mov [init_req+NEBO_PROCESS_INIT_STATE],rax
 mov [init_req+NEBO_PROCESS_INIT_PID],r12
 mov qword [init_req+NEBO_PROCESS_INIT_OWNER],0x2603
 mov qword [init_req+NEBO_PROCESS_INIT_CAPABILITY],0xcafe
 mov qword [init_req+NEBO_PROCESS_INIT_BUDGET],2
 mov qword [init_req+NEBO_PROCESS_INIT_VERSION],1
 lea rdi,[init_req]
 call nebo_plugin_process_init
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROCESS_ST_PID],r12
 jne fail
 lea rax,[state]
 mov [call_req+NEBO_PROCESS_CALL_STATE],rax
 mov qword [call_req+NEBO_PROCESS_CALL_OWNER],0x2603
 mov qword [call_req+NEBO_PROCESS_CALL_CAPABILITY],0xcafe
 mov qword [call_req+NEBO_PROCESS_CALL_METHOD],1
 mov qword [call_req+NEBO_PROCESS_CALL_SCHEMA],1
 mov qword [call_req+NEBO_PROCESS_CALL_PAYLOAD],32
 mov qword [call_req+NEBO_PROCESS_CALL_DEADLINE],1
 lea rdi,[call_req]
 call nebo_plugin_process_call
 test eax,eax
 jnz fail
 cmp qword [call_req+NEBO_PROCESS_CALL_RESULT],32
 jne fail
 mov qword [call_req+NEBO_PROCESS_CALL_CAPABILITY],0xbeef
 lea rdi,[call_req]
 call nebo_plugin_process_call
 cmp eax,NEBO_PROCESS_STATUS_CAPABILITY
 jne fail
 mov qword [call_req+NEBO_PROCESS_CALL_CAPABILITY],0xcafe
 mov qword [call_req+NEBO_PROCESS_CALL_CANCEL],1
 lea rdi,[call_req]
 call nebo_plugin_process_call
 cmp eax,NEBO_PROCESS_STATUS_CANCELLED
 jne fail
 mov qword [call_req+NEBO_PROCESS_CALL_CANCEL],0
 mov qword [call_req+NEBO_PROCESS_CALL_PAYLOAD],65537
 lea rdi,[call_req]
 call nebo_plugin_process_call
 cmp eax,NEBO_PROCESS_STATUS_LIMIT
 jne fail
 mov qword [call_req+NEBO_PROCESS_CALL_PAYLOAD],8
 lea rdi,[call_req]
 call nebo_plugin_process_call
 test eax,eax
 jnz fail
 lea rdi,[call_req]
 call nebo_plugin_process_call
 cmp eax,NEBO_PROCESS_STATUS_LIMIT
 jne fail
 lea rax,[state]
 mov [shut_req+NEBO_PROCESS_SHUT_STATE],rax
 mov qword [shut_req+NEBO_PROCESS_SHUT_OWNER],0x2603
 mov qword [shut_req+NEBO_PROCESS_SHUT_CAPABILITY],0xcafe
 lea rdi,[shut_req]
 call nebo_plugin_process_shutdown
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_SHUTDOWN
 jne fail
 lea rdi,[call_req]
 call nebo_plugin_process_call
 cmp eax,NEBO_PROCESS_STATUS_STATE
 jne fail
 xor edi,edi
 mov eax,60
 syscall
child:
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
