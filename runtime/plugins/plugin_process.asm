; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F03 owned local plugin process lifecycle and typed IPC admission.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/plugins/plugin_process.inc"
section .text
NEBOC_ABI_FUNCTION nebo_plugin_process_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROCESS_INIT_RESULT],0
 mov rsi,[rdi+NEBO_PROCESS_INIT_STATE]
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBO_PROCESS_INIT_VERSION],NEBO_PROCESS_VERSION
 jne .version
 cmp qword [rdi+NEBO_PROCESS_INIT_PID],1
 jbe .bad
 cmp qword [rdi+NEBO_PROCESS_INIT_OWNER],0
 je .cap
 cmp qword [rdi+NEBO_PROCESS_INIT_CAPABILITY],0
 je .cap
 cmp qword [rdi+NEBO_PROCESS_INIT_BUDGET],0
 je .limit
 cmp qword [rdi+NEBO_PROCESS_INIT_BUDGET],NEBO_PROCESS_MAX_CALLS
 ja .limit
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_PROCESS_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PROCESS_MAGIC
 mov [rsi+NEBO_PROCESS_ST_MAGIC],rax
 mov rax,[r8+NEBO_PROCESS_INIT_PID]
 mov [rsi+NEBO_PROCESS_ST_PID],rax
 mov rax,[r8+NEBO_PROCESS_INIT_OWNER]
 mov [rsi+NEBO_PROCESS_ST_OWNER],rax
 mov rax,[r8+NEBO_PROCESS_INIT_CAPABILITY]
 mov [rsi+NEBO_PROCESS_ST_CAPABILITY],rax
 mov qword [rsi+NEBO_PROCESS_ST_PROTOCOL],NEBO_PROCESS_VERSION
 mov qword [rsi+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_READY
 mov rax,[r8+NEBO_PROCESS_INIT_BUDGET]
 mov [rsi+NEBO_PROCESS_ST_BUDGET],rax
 mov qword [r8+NEBO_PROCESS_INIT_RESULT],1
 xor eax,eax
 ret
.version: mov eax,NEBO_PROCESS_STATUS_VERSION
 ret
.cap: mov eax,NEBO_PROCESS_STATUS_CAPABILITY
 ret
.limit: mov eax,NEBO_PROCESS_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_PROCESS_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_plugin_process_call
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROCESS_CALL_RESULT],0
 mov rsi,[rdi+NEBO_PROCESS_CALL_STATE]
 test rsi,rsi
 jz .bad
 mov rax,NEBO_PROCESS_MAGIC
 cmp [rsi+NEBO_PROCESS_ST_MAGIC],rax
 jne .bad
 mov rax,[rdi+NEBO_PROCESS_CALL_OWNER]
 cmp [rsi+NEBO_PROCESS_ST_OWNER],rax
 jne .cap
 mov rax,[rdi+NEBO_PROCESS_CALL_CAPABILITY]
 cmp [rsi+NEBO_PROCESS_ST_CAPABILITY],rax
 jne .cap
 cmp qword [rsi+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_READY
 jne .state
 cmp qword [rdi+NEBO_PROCESS_CALL_CANCEL],0
 jne .cancel
 cmp qword [rdi+NEBO_PROCESS_CALL_DEADLINE],0
 je .deadline
 cmp qword [rdi+NEBO_PROCESS_CALL_SCHEMA],NEBO_PROCESS_VERSION
 jne .schema
 cmp qword [rdi+NEBO_PROCESS_CALL_METHOD],1
 jb .method
 cmp qword [rdi+NEBO_PROCESS_CALL_METHOD],NEBO_PROCESS_MAX_METHOD
 ja .method
 cmp qword [rdi+NEBO_PROCESS_CALL_PAYLOAD],NEBO_PROCESS_MAX_PAYLOAD
 ja .limit
 mov rax,[rsi+NEBO_PROCESS_ST_CALLS]
 cmp rax,[rsi+NEBO_PROCESS_ST_BUDGET]
 jae .limit
 inc qword [rsi+NEBO_PROCESS_ST_CALLS]
 mov rax,[rdi+NEBO_PROCESS_CALL_PAYLOAD]
 mov [rdi+NEBO_PROCESS_CALL_RESULT],rax
 xor eax,eax
 ret
.cap: mov eax,NEBO_PROCESS_STATUS_CAPABILITY
 ret
.state: mov eax,NEBO_PROCESS_STATUS_STATE
 ret
.method: mov eax,NEBO_PROCESS_STATUS_METHOD
 ret
.schema: mov eax,NEBO_PROCESS_STATUS_SCHEMA
 ret
.limit: mov eax,NEBO_PROCESS_STATUS_LIMIT
 ret
.deadline: mov eax,NEBO_PROCESS_STATUS_DEADLINE
 ret
.cancel: mov eax,NEBO_PROCESS_STATUS_CANCELLED
 ret
.bad: mov eax,NEBO_PROCESS_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_plugin_process_shutdown
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROCESS_SHUT_RESULT],0
 mov rsi,[rdi+NEBO_PROCESS_SHUT_STATE]
 test rsi,rsi
 jz .bad
 mov rax,[rdi+NEBO_PROCESS_SHUT_OWNER]
 cmp [rsi+NEBO_PROCESS_ST_OWNER],rax
 jne .cap
 mov rax,[rdi+NEBO_PROCESS_SHUT_CAPABILITY]
 cmp [rsi+NEBO_PROCESS_ST_CAPABILITY],rax
 jne .cap
 cmp qword [rsi+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_READY
 jne .state
 cmp qword [rdi+NEBO_PROCESS_SHUT_CHILD_STATUS],0
 jne .crash
 mov qword [rsi+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_SHUTDOWN
 mov qword [rdi+NEBO_PROCESS_SHUT_RESULT],1
 xor eax,eax
 ret
.crash:
 mov qword [rsi+NEBO_PROCESS_ST_STATE],NEBO_PROCESS_STATE_CRASHED
 mov eax,NEBO_PROCESS_STATUS_CRASH
 ret
.cap: mov eax,NEBO_PROCESS_STATUS_CAPABILITY
 ret
.state: mov eax,NEBO_PROCESS_STATUS_STATE
 ret
.bad: mov eax,NEBO_PROCESS_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
