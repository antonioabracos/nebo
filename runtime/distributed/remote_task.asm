; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F07 bounded pre-registered remote-task state.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/distributed/remote_task.inc"
section .text
NEBOC_ABI_FUNCTION nebo_remote_task_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_REMOTE_INIT_RESULT],0
 mov rsi,[rdi+NEBO_REMOTE_INIT_STATE]
 mov rdx,[rdi+NEBO_REMOTE_INIT_ENTRIES]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 cmp qword [rdi+NEBO_REMOTE_INIT_CAPACITY],1
 jb .limit
 cmp qword [rdi+NEBO_REMOTE_INIT_CAPACITY],NEBO_REMOTE_MAX_TASKS
 ja .limit
 cmp qword [rdi+NEBO_REMOTE_INIT_OWNER],0
 je .cap
 cmp qword [rdi+NEBO_REMOTE_INIT_CAPABILITY],0
 je .cap
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_REMOTE_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_REMOTE_MAGIC
 mov [rsi+NEBO_REMOTE_ST_MAGIC],rax
 mov [rsi+NEBO_REMOTE_ST_ENTRIES],rdx
 mov rax,[r8+NEBO_REMOTE_INIT_CAPACITY]
 mov [rsi+NEBO_REMOTE_ST_CAPACITY],rax
 mov rax,[r8+NEBO_REMOTE_INIT_OWNER]
 mov [rsi+NEBO_REMOTE_ST_OWNER],rax
 mov rax,[r8+NEBO_REMOTE_INIT_CAPABILITY]
 mov [rsi+NEBO_REMOTE_ST_CAPABILITY],rax
 mov qword [r8+NEBO_REMOTE_INIT_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_REMOTE_STATUS_CAPABILITY
 ret
.limit: mov eax,NEBO_REMOTE_STATUS_LIMIT
 ret
.bad: mov eax,NEBO_REMOTE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_remote_task_submit
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_REMOTE_SUBMIT_RESULT],0
 mov r10,rdi
 mov rsi,[r10+NEBO_REMOTE_SUBMIT_STATE]
 mov rdx,[r10+NEBO_REMOTE_SUBMIT_TASK]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 mov rax,[r10+NEBO_REMOTE_SUBMIT_CAPABILITY]
 cmp [rsi+NEBO_REMOTE_ST_CAPABILITY],rax
 jne .cap
 cmp qword [rdx+NEBO_REMOTE_TASK_ID],0
 je .bad
 cmp qword [rdx+NEBO_REMOTE_TASK_KEY],0
 je .bad
 cmp qword [rdx+NEBO_REMOTE_TASK_SCHEMA],NEBO_REMOTE_VERSION
 jne .schema
 cmp qword [rdx+NEBO_REMOTE_TASK_FUNCTION],1
 jb .function
 cmp qword [rdx+NEBO_REMOTE_TASK_FUNCTION],NEBO_REMOTE_MAX_FUNCTION
 ja .function
 cmp qword [rdx+NEBO_REMOTE_TASK_PROVENANCE],0
 je .provenance
 cmp qword [rdx+NEBO_REMOTE_TASK_PARTITION],NEBO_REMOTE_MAX_PARTITION
 ja .partition
 cmp qword [rdx+NEBO_REMOTE_TASK_REPLICAS],1
 jb .partition
 cmp qword [rdx+NEBO_REMOTE_TASK_REPLICAS],NEBO_REMOTE_MAX_REPLICAS
 ja .partition
 cmp qword [rdx+NEBO_REMOTE_TASK_FLAGS],0
 jne .shipping
 xor ecx,ecx
.scan:
 cmp rcx,[rsi+NEBO_REMOTE_ST_COUNT]
 jae .store
 imul rax,rcx,NEBO_REMOTE_TASK_SIZE
 add rax,[rsi+NEBO_REMOTE_ST_ENTRIES]
 mov r8,[rdx+NEBO_REMOTE_TASK_KEY]
 cmp [rax+NEBO_REMOTE_TASK_KEY],r8
 jne .next
 mov r8,[rdx+NEBO_REMOTE_TASK_ID]
 cmp [rax+NEBO_REMOTE_TASK_ID],r8
 jne .duplicate
 mov r8,[rdx+NEBO_REMOTE_TASK_FUNCTION]
 cmp [rax+NEBO_REMOTE_TASK_FUNCTION],r8
 jne .duplicate
 mov [r10+NEBO_REMOTE_SUBMIT_RESULT],rcx
 inc qword [r10+NEBO_REMOTE_SUBMIT_RESULT]
 xor eax,eax
 ret
.next: inc rcx
 jmp .scan
.store:
 cmp rcx,[rsi+NEBO_REMOTE_ST_CAPACITY]
 jae .limit
 imul rax,rcx,NEBO_REMOTE_TASK_SIZE
 add rax,[rsi+NEBO_REMOTE_ST_ENTRIES]
 push rdi
 push rsi
 mov rdi,rax
 mov rsi,rdx
 mov ecx,NEBO_REMOTE_TASK_SIZE/8
 rep movsq
 pop rsi
 pop rdi
 mov qword [rax+NEBO_REMOTE_TASK_STATE],NEBO_REMOTE_STATE_PENDING
 inc qword [rsi+NEBO_REMOTE_ST_COUNT]
 mov rax,[rsi+NEBO_REMOTE_ST_COUNT]
 mov [r10+NEBO_REMOTE_SUBMIT_RESULT],rax
 xor eax,eax
 ret
.cap: mov eax,NEBO_REMOTE_STATUS_CAPABILITY
 ret
.schema: mov eax,NEBO_REMOTE_STATUS_SCHEMA
 ret
.function: mov eax,NEBO_REMOTE_STATUS_UNKNOWN_FUNCTION
 ret
.shipping: mov eax,NEBO_REMOTE_STATUS_CODE_SHIPPING
 ret
.duplicate: mov eax,NEBO_REMOTE_STATUS_DUPLICATE
 ret
.limit: mov eax,NEBO_REMOTE_STATUS_LIMIT
 ret
.provenance: mov eax,NEBO_REMOTE_STATUS_PROVENANCE
 ret
.partition: mov eax,NEBO_REMOTE_STATUS_PARTITION
 ret
.bad: mov eax,NEBO_REMOTE_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_remote_task_update
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_REMOTE_UPDATE_RESULT],0
 mov rsi,[rdi+NEBO_REMOTE_UPDATE_STATE]
 test rsi,rsi
 jz .bad
 mov rax,[rdi+NEBO_REMOTE_UPDATE_CAPABILITY]
 cmp [rsi+NEBO_REMOTE_ST_CAPABILITY],rax
 jne .cap
 mov r8,[rdi+NEBO_REMOTE_UPDATE_NEW_STATE]
 cmp r8,NEBO_REMOTE_STATE_COMPLETED
 je .scan_start
 cmp r8,NEBO_REMOTE_STATE_CANCELLED
 jne .state
.scan_start:
 xor ecx,ecx
.scan:
 cmp rcx,[rsi+NEBO_REMOTE_ST_COUNT]
 jae .not_found
 imul rax,rcx,NEBO_REMOTE_TASK_SIZE
 add rax,[rsi+NEBO_REMOTE_ST_ENTRIES]
 mov r9,[rdi+NEBO_REMOTE_UPDATE_KEY]
 cmp [rax+NEBO_REMOTE_TASK_KEY],r9
 je .found
 inc rcx
 jmp .scan
.found:
 cmp qword [rax+NEBO_REMOTE_TASK_STATE],NEBO_REMOTE_STATE_PENDING
 jne .state
 mov [rax+NEBO_REMOTE_TASK_STATE],r8
 mov qword [rdi+NEBO_REMOTE_UPDATE_RESULT],1
 xor eax,eax
 ret
.cap: mov eax,NEBO_REMOTE_STATUS_CAPABILITY
 ret
.state: mov eax,NEBO_REMOTE_STATUS_STATE
 ret
.not_found: mov eax,NEBO_REMOTE_STATUS_NOT_FOUND
 ret
.bad: mov eax,NEBO_REMOTE_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
