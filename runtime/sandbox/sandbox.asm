; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F04 factual bounded process-isolation policy.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/sandbox/sandbox.inc"
section .text
NEBOC_ABI_FUNCTION nebo_sandbox_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_SANDBOX_INIT_RESULT],0
 mov rsi,[rdi+NEBO_SANDBOX_INIT_STATE]
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBO_SANDBOX_INIT_OWNER],0
 je .cap
 cmp qword [rdi+NEBO_SANDBOX_INIT_CAP],0
 je .cap
 cmp qword [rdi+NEBO_SANDBOX_INIT_MEMORY],0
 je .limit
 cmp qword [rdi+NEBO_SANDBOX_INIT_MEMORY],NEBO_SANDBOX_MAX_MEMORY
 ja .limit
 cmp qword [rdi+NEBO_SANDBOX_INIT_DEADLINE],0
 je .limit
 cmp qword [rdi+NEBO_SANDBOX_INIT_CALLS],0
 je .limit
 cmp qword [rdi+NEBO_SANDBOX_INIT_CALLS],NEBO_SANDBOX_MAX_CALLS
 ja .limit
 cmp qword [rdi+NEBO_SANDBOX_INIT_ROOT],0
 je .root
 cmp qword [rdi+NEBO_SANDBOX_INIT_NETWORK],NEBO_SANDBOX_NETWORK_LOOPBACK
 ja .network
 cmp qword [rdi+NEBO_SANDBOX_INIT_FDS],NEBO_SANDBOX_MAX_FDS
 ja .fd
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_SANDBOX_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_SANDBOX_MAGIC
 mov [rsi+NEBO_SANDBOX_ST_MAGIC],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_OWNER]
 mov [rsi+NEBO_SANDBOX_ST_OWNER],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_CAP]
 mov [rsi+NEBO_SANDBOX_ST_CAPABILITY],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_MEMORY]
 mov [rsi+NEBO_SANDBOX_ST_MEMORY],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_DEADLINE]
 mov [rsi+NEBO_SANDBOX_ST_DEADLINE],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_CALLS]
 mov [rsi+NEBO_SANDBOX_ST_CALL_LIMIT],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_ROOT]
 mov [rsi+NEBO_SANDBOX_ST_ROOT],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_NETWORK]
 mov [rsi+NEBO_SANDBOX_ST_NETWORK],rax
 mov rax,[r8+NEBO_SANDBOX_INIT_FDS]
 mov [rsi+NEBO_SANDBOX_ST_FD_LIMIT],rax
 mov qword [rsi+NEBO_SANDBOX_ST_ACTIVE],1
 mov qword [r8+NEBO_SANDBOX_INIT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_SANDBOX_STATUS_CAPABILITY
 ret
.root: mov eax,NEBO_SANDBOX_STATUS_ROOT_ESCAPE
 ret
.network: mov eax,NEBO_SANDBOX_STATUS_NETWORK
 ret
.fd: mov eax,NEBO_SANDBOX_STATUS_FD_LIMIT
 ret
.limit: mov eax,NEBO_SANDBOX_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_SANDBOX_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_sandbox_admit
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_SANDBOX_ADMIT_RESULT],0
 mov rsi,[rdi+NEBO_SANDBOX_ADMIT_STATE]
 test rsi,rsi
 jz .bad
 mov rax,NEBO_SANDBOX_MAGIC
 cmp [rsi+NEBO_SANDBOX_ST_MAGIC],rax
 jne .bad
 cmp qword [rsi+NEBO_SANDBOX_ST_ACTIVE],1
 jne .terminated
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_OWNER]
 cmp [rsi+NEBO_SANDBOX_ST_OWNER],rax
 jne .cap
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_CAP]
 cmp [rsi+NEBO_SANDBOX_ST_CAPABILITY],rax
 jne .cap
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_MEMORY]
 cmp rax,[rsi+NEBO_SANDBOX_ST_MEMORY]
 ja .memory
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_NOW]
 cmp rax,[rsi+NEBO_SANDBOX_ST_DEADLINE]
 jae .deadline
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_FDS]
 cmp rax,[rsi+NEBO_SANDBOX_ST_FD_LIMIT]
 ja .fd
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_ROOT]
 cmp rax,[rsi+NEBO_SANDBOX_ST_ROOT]
 jne .root
 mov rax,[rdi+NEBO_SANDBOX_ADMIT_NETWORK]
 cmp rax,[rsi+NEBO_SANDBOX_ST_NETWORK]
 ja .network
 mov rax,[rsi+NEBO_SANDBOX_ST_CALLS]
 cmp rax,[rsi+NEBO_SANDBOX_ST_CALL_LIMIT]
 jae .calls
 inc qword [rsi+NEBO_SANDBOX_ST_CALLS]
 mov qword [rdi+NEBO_SANDBOX_ADMIT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_SANDBOX_STATUS_CAPABILITY
 ret
.memory: mov eax,NEBO_SANDBOX_STATUS_MEMORY
 ret
.deadline: mov eax,NEBO_SANDBOX_STATUS_DEADLINE
 ret
.calls: mov eax,NEBO_SANDBOX_STATUS_CALL_BUDGET
 ret
.root: mov eax,NEBO_SANDBOX_STATUS_ROOT_ESCAPE
 ret
.network: mov eax,NEBO_SANDBOX_STATUS_NETWORK
 ret
.fd: mov eax,NEBO_SANDBOX_STATUS_FD_LIMIT
 ret
.terminated: mov eax,NEBO_SANDBOX_STATUS_TERMINATED
 ret
.bad: mov eax,NEBO_SANDBOX_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_sandbox_terminate
 test rdi,rdi
 jz .bad
 mov rsi,[rdi]
 test rsi,rsi
 jz .bad
 cmp qword [rsi+NEBO_SANDBOX_ST_ACTIVE],1
 jne .terminated
 mov qword [rsi+NEBO_SANDBOX_ST_ACTIVE],0
 xor eax,eax
 ret
.terminated: mov eax,NEBO_SANDBOX_STATUS_TERMINATED
 ret
.bad: mov eax,NEBO_SANDBOX_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
