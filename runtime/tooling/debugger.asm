bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/tooling/debugger.inc"
extern nebo_capability_precheck
section .text
debugger_precheck: jmp nebo_capability_precheck

NEBOC_ABI_FUNCTION nebo_debugger_init
 test rdi,rdi
 jz .bad
 mov rsi,[rdi+NEBO_DEBUGGER_INIT_STATE]
 mov rdx,[rdi+NEBO_DEBUGGER_INIT_BREAKPOINTS]
 mov rcx,[rdi+NEBO_DEBUGGER_INIT_BP_CAP]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 test rcx,rcx
 jz .bad
 cmp rcx,NEBO_DEBUGGER_MAX_BREAKPOINTS
 ja .limit
 cmp qword [rdi+NEBO_DEBUGGER_INIT_AUTHORITY],0
 je .bad
 cmp qword [rdi+NEBO_DEBUGGER_INIT_CAPABILITY],0
 je .bad
 cmp qword [rdi+NEBO_DEBUGGER_INIT_METADATA_VERSION],NEBO_DEBUG_VERSION
 jne .metadata
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_DEBUGGER_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_DEBUGGER_MAGIC
 mov [rsi+NEBO_DEBUGGER_STATE_MAGIC],rax
 mov [rsi+NEBO_DEBUGGER_STATE_BREAKPOINTS],rdx
 mov rax,[r8+NEBO_DEBUGGER_INIT_BP_CAP]
 mov [rsi+NEBO_DEBUGGER_STATE_BP_CAP],rax
 mov rax,[r8+NEBO_DEBUGGER_INIT_AUTHORITY]
 mov [rsi+NEBO_DEBUGGER_STATE_AUTHORITY],rax
 mov rax,[r8+NEBO_DEBUGGER_INIT_CAPABILITY]
 mov [rsi+NEBO_DEBUGGER_STATE_CAPABILITY],rax
 mov rax,[r8+NEBO_DEBUGGER_INIT_SCOPE]
 mov [rsi+NEBO_DEBUGGER_STATE_SCOPE],rax
 mov qword [rsi+NEBO_DEBUGGER_STATE_METADATA_VERSION],NEBO_DEBUG_VERSION
 xor eax,eax
 ret
.limit: mov eax,NEBO_DEBUGGER_STATUS_LIMIT
 ret
.metadata: mov eax,NEBO_DEBUGGER_STATUS_METADATA
 ret
.bad: mov eax,NEBO_DEBUGGER_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_debugger_control
 test rdi,rdi
 jz .bad
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov qword [r12+NEBO_DEBUGGER_REQUEST_RESULT],0
 mov qword [r12+NEBO_DEBUGGER_REQUEST_SEQUENCE],0
 mov r13,[r12+NEBO_DEBUGGER_REQUEST_STATE]
 test r13,r13
 jz .bad_saved
 mov rax,NEBO_DEBUGGER_MAGIC
 cmp [r13+NEBO_DEBUGGER_STATE_MAGIC],rax
 jne .bad_saved
 mov rbx,[r12+NEBO_DEBUGGER_REQUEST_OPERATION]
 cmp rbx,NEBO_DEBUGGER_OP_LAUNCH
 je .launch
 mov rax,[r12+NEBO_DEBUGGER_REQUEST_OWNER]
 test rax,rax
 jz .ownership
 cmp rax,[r13+NEBO_DEBUGGER_STATE_OWNER]
 jne .ownership
 cmp rbx,NEBO_DEBUGGER_OP_BREAKPOINT
 je .breakpoint
 cmp rbx,NEBO_DEBUGGER_OP_CONTINUE
 je .continue
 cmp rbx,NEBO_DEBUGGER_OP_STEP
 je .step
 cmp rbx,NEBO_DEBUGGER_OP_STOP
 je .stop
 cmp rbx,NEBO_DEBUGGER_OP_TERMINATE
 je .terminate
 jmp .bad_saved
.launch:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_NEW
 jne .state
 cmp qword [r12+NEBO_DEBUGGER_REQUEST_PID],1
 jbe .bad_saved
 cmp qword [r12+NEBO_DEBUGGER_REQUEST_OWNER],0
 je .ownership
 call .authorize
 test eax,eax
 jnz .capability
 mov rax,[r12+NEBO_DEBUGGER_REQUEST_PID]
 mov [r13+NEBO_DEBUGGER_STATE_PID],rax
 mov rax,[r12+NEBO_DEBUGGER_REQUEST_OWNER]
 mov [r13+NEBO_DEBUGGER_STATE_OWNER],rax
 mov qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_RUNNING
 jmp .success
.breakpoint:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_STOPPED
 jne .state
 mov rdx,[r12+NEBO_DEBUGGER_REQUEST_ADDRESS]
 test rdx,rdx
 jz .bad_saved
 mov rcx,[r13+NEBO_DEBUGGER_STATE_BP_COUNT]
 cmp rcx,[r13+NEBO_DEBUGGER_STATE_BP_CAP]
 jae .limit_saved
 mov r8,[r13+NEBO_DEBUGGER_STATE_BREAKPOINTS]
 xor eax,eax
.scan:
 cmp rax,rcx
 jae .store
 mov r9,rax
 shl r9,4
 cmp [r8+r9+NEBO_DEBUGGER_BP_ADDRESS],rdx
 je .state
 inc rax
 jmp .scan
.store:
 call .authorize
 test eax,eax
 jnz .capability
 mov r8,[r13+NEBO_DEBUGGER_STATE_BREAKPOINTS]
 mov rdx,[r12+NEBO_DEBUGGER_REQUEST_ADDRESS]
 mov rcx,[r13+NEBO_DEBUGGER_STATE_BP_COUNT]
 mov rax,rcx
 shl rax,4
 mov [r8+rax+NEBO_DEBUGGER_BP_ADDRESS],rdx
 mov qword [r8+rax+NEBO_DEBUGGER_BP_STATE],1
 inc qword [r13+NEBO_DEBUGGER_STATE_BP_COUNT]
 jmp .success
.continue:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_STOPPED
 jne .state
 call .authorize
 test eax,eax
 jnz .capability
 mov qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_RUNNING
 jmp .success
.step:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_STOPPED
 jne .state
 call .authorize
 test eax,eax
 jnz .capability
 jmp .success
.stop:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_RUNNING
 jne .state
 call .authorize
 test eax,eax
 jnz .capability
 mov qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_STOPPED
 jmp .success
.terminate:
 cmp qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_CLOSED
 je .state
 call .authorize
 test eax,eax
 jnz .capability
 mov qword [r13+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_CLOSED
 mov qword [r13+NEBO_DEBUGGER_STATE_PID],0
.success:
 inc qword [r13+NEBO_DEBUGGER_STATE_SEQUENCE]
 mov rax,[r13+NEBO_DEBUGGER_STATE_SEQUENCE]
 mov [r12+NEBO_DEBUGGER_REQUEST_SEQUENCE],rax
 mov qword [r12+NEBO_DEBUGGER_REQUEST_RESULT],1
 xor eax,eax
 jmp .done
.authorize:
 mov rdi,[r13+NEBO_DEBUGGER_STATE_AUTHORITY]
 mov rsi,[r13+NEBO_DEBUGGER_STATE_CAPABILITY]
 mov edx,NEBO_EFFECT_PROCESS
 mov ecx,1
 mov r8,[r13+NEBO_DEBUGGER_STATE_SCOPE]
 mov r9d,1
 jmp debugger_precheck
.ownership: mov eax,NEBO_DEBUGGER_STATUS_OWNERSHIP
 jmp .done
.state: mov eax,NEBO_DEBUGGER_STATUS_STATE
 jmp .done
.limit_saved: mov eax,NEBO_DEBUGGER_STATUS_LIMIT
 jmp .done
.capability: mov eax,NEBO_DEBUGGER_STATUS_CAPABILITY
 jmp .done
.bad_saved: mov eax,NEBO_DEBUGGER_STATUS_INVALID_ARGUMENT
.done: pop r13
 pop r12
 pop rbx
 ret
.bad: mov eax,NEBO_DEBUGGER_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION nebo_debugger_snapshot
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_DEBUGGER_SNAPSHOT_RESULT],0
 mov rsi,[rdi+NEBO_DEBUGGER_SNAPSHOT_STATE]
 test rsi,rsi
 jz .bad
 mov rax,[rdi+NEBO_DEBUGGER_SNAPSHOT_OWNER]
 cmp rax,[rsi+NEBO_DEBUGGER_STATE_OWNER]
 jne .owner
 cmp qword [rsi+NEBO_DEBUGGER_STATE_STATUS],NEBO_DEBUGGER_STOPPED
 jne .state
 cmp qword [rdi+NEBO_DEBUGGER_SNAPSHOT_METADATA_VERSION],NEBO_DEBUG_VERSION
 jne .metadata
 cmp qword [rdi+NEBO_DEBUGGER_SNAPSHOT_FRAMES],NEBO_DEBUG_MAX_FRAMES
 ja .limit
 cmp qword [rdi+NEBO_DEBUGGER_SNAPSHOT_BINDINGS],NEBO_DEBUG_MAX_BINDINGS
 ja .limit
 mov rax,[rdi+NEBO_DEBUGGER_SNAPSHOT_CLASS]
 test rax,~NEBO_PRIVACY_CLASS_MASK
 jnz .bad
 test rax,rax
 jz .ok
 cmp qword [rdi+NEBO_DEBUGGER_SNAPSHOT_REDACTED],1
 jne .privacy
.ok: mov qword [rdi+NEBO_DEBUGGER_SNAPSHOT_RESULT],1
 xor eax,eax
 ret
.owner: mov eax,NEBO_DEBUGGER_STATUS_OWNERSHIP
 ret
.state: mov eax,NEBO_DEBUGGER_STATUS_STATE
 ret
.metadata: mov eax,NEBO_DEBUGGER_STATUS_METADATA
 ret
.limit: mov eax,NEBO_DEBUGGER_STATUS_LIMIT
 ret
.privacy: mov eax,NEBO_DEBUGGER_STATUS_PRIVACY
 ret
.bad: mov eax,NEBO_DEBUGGER_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
