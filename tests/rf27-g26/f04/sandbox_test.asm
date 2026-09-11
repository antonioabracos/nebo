bits 64
default rel
%include "runtime/sandbox/sandbox.inc"
extern nebo_sandbox_init,nebo_sandbox_admit,nebo_sandbox_terminate
section .bss
state resb NEBO_SANDBOX_STATE_SIZE
init_req resb NEBO_SANDBOX_INIT_SIZE
admit_req resb NEBO_SANDBOX_ADMIT_SIZE
term_req resq 1
section .text
global _start
_start:
 lea rax,[state]
 mov [init_req+NEBO_SANDBOX_INIT_STATE],rax
 mov qword [init_req+NEBO_SANDBOX_INIT_OWNER],0x2604
 mov qword [init_req+NEBO_SANDBOX_INIT_CAP],0xcafe
 mov qword [init_req+NEBO_SANDBOX_INIT_MEMORY],0x100000
 mov qword [init_req+NEBO_SANDBOX_INIT_DEADLINE],100
 mov qword [init_req+NEBO_SANDBOX_INIT_CALLS],2
 mov qword [init_req+NEBO_SANDBOX_INIT_ROOT],0x1234
 mov qword [init_req+NEBO_SANDBOX_INIT_NETWORK],0
 mov qword [init_req+NEBO_SANDBOX_INIT_FDS],4
 lea rdi,[init_req]
 call nebo_sandbox_init
 test eax,eax
 jnz fail
 lea rax,[state]
 mov [admit_req+NEBO_SANDBOX_ADMIT_STATE],rax
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_OWNER],0x2604
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_CAP],0xcafe
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_MEMORY],0x1000
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NOW],1
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_FDS],3
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NETWORK],0
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_ROOT],0x1234
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 test eax,eax
 jnz fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_MEMORY],0x200000
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_MEMORY
 jne fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_MEMORY],0
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_ROOT],0x9999
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_ROOT_ESCAPE
 jne fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_ROOT],0x1234
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NETWORK],1
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_NETWORK
 jne fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NETWORK],0
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_FDS],5
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_FD_LIMIT
 jne fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_FDS],0
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NOW],100
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_DEADLINE
 jne fail
 mov qword [admit_req+NEBO_SANDBOX_ADMIT_NOW],2
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 test eax,eax
 jnz fail
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_CALL_BUDGET
 jne fail
 lea rax,[state]
 mov [term_req],rax
 lea rdi,[term_req]
 call nebo_sandbox_terminate
 test eax,eax
 jnz fail
 lea rdi,[admit_req]
 call nebo_sandbox_admit
 cmp eax,NEBO_SANDBOX_STATUS_TERMINATED
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
