; PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-F06 versioned bounded local-loopback protocol state machine.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/distributed/protocol.inc"
section .text
NEBOC_ABI_FUNCTION nebo_protocol_init
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROTOCOL_INIT_RESULT],0
 mov rsi,[rdi+NEBO_PROTOCOL_INIT_STATE]
 test rsi,rsi
 jz .bad
 cmp qword [rdi+NEBO_PROTOCOL_INIT_IDENTITY],0
 je .bad
 cmp qword [rdi+NEBO_PROTOCOL_INIT_CAPABILITY],0
 je .auth
 cmp qword [rdi+NEBO_PROTOCOL_INIT_MAX_INFLIGHT],1
 jb .backpressure
 cmp qword [rdi+NEBO_PROTOCOL_INIT_MAX_INFLIGHT],NEBO_PROTOCOL_MAX_INFLIGHT
 ja .backpressure
 mov r8,rdi
 mov rdi,rsi
 mov ecx,NEBO_PROTOCOL_STATE_SIZE/8
 xor eax,eax
 rep stosq
 mov rax,NEBO_PROTOCOL_MAGIC
 mov [rsi+NEBO_PROTOCOL_ST_MAGIC],rax
 mov rax,[r8+NEBO_PROTOCOL_INIT_IDENTITY]
 mov [rsi+NEBO_PROTOCOL_ST_IDENTITY],rax
 mov rax,[r8+NEBO_PROTOCOL_INIT_CAPABILITY]
 mov [rsi+NEBO_PROTOCOL_ST_CAPABILITY],rax
 mov qword [rsi+NEBO_PROTOCOL_ST_VERSION],1
 mov qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_NEW
 mov rax,[r8+NEBO_PROTOCOL_INIT_MAX_INFLIGHT]
 mov [rsi+NEBO_PROTOCOL_ST_MAX_INFLIGHT],rax
 mov qword [r8+NEBO_PROTOCOL_INIT_RESULT],1
 xor eax,eax
 ret
.auth: mov eax,NEBO_PROTOCOL_STATUS_AUTH
 ret
.backpressure: mov eax,NEBO_PROTOCOL_STATUS_BACKPRESSURE
 ret
.bad: mov eax,NEBO_PROTOCOL_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_protocol_process
 test rdi,rdi
 jz .bad
 mov qword [rdi+NEBO_PROTOCOL_PROCESS_RESULT],0
 mov rsi,[rdi+NEBO_PROTOCOL_PROCESS_STATE]
 mov rdx,[rdi+NEBO_PROTOCOL_PROCESS_FRAME]
 test rsi,rsi
 jz .bad
 test rdx,rdx
 jz .bad
 mov rax,[rdi+NEBO_PROTOCOL_PROCESS_CAPABILITY]
 cmp [rsi+NEBO_PROTOCOL_ST_CAPABILITY],rax
 jne .auth
 mov rax,NEBO_PROTOCOL_FRAME_MAGIC
 cmp [rdx+NEBO_PROTOCOL_FRAME_MAGIC_OFF],rax
 jne .corrupt
 cmp qword [rdx+NEBO_PROTOCOL_FRAME_VERSION],nebo_protocol_PROTOCOL_VERSION
 jne .version
 cmp qword [rdx+NEBO_PROTOCOL_FRAME_RESERVED],0
 jne .internet
 cmp qword [rdx+NEBO_PROTOCOL_FRAME_PAYLOAD],NEBO_PROTOCOL_MAX_PAYLOAD
 ja .oversize
 mov rax,[rdx+NEBO_PROTOCOL_FRAME_SEQUENCE]
 cmp rax,[rsi+NEBO_PROTOCOL_ST_LAST_RX]
 jbe .replay
 mov rax,[rsi+NEBO_PROTOCOL_ST_INFLIGHT]
 cmp rax,[rsi+NEBO_PROTOCOL_ST_MAX_INFLIGHT]
 jae .backpressure
 mov r8,[rdx+NEBO_PROTOCOL_FRAME_TYPE]
 cmp r8,NEBO_PROTOCOL_TYPE_HELLO
 je .hello
 cmp r8,NEBO_PROTOCOL_TYPE_AUTH
 je .auth_frame
 cmp r8,NEBO_PROTOCOL_TYPE_READY
 je .ready_frame
 cmp r8,NEBO_PROTOCOL_TYPE_HEALTH
 je .health
 cmp r8,NEBO_PROTOCOL_TYPE_DRAIN
 je .drain
 jmp .state
.hello:
 cmp qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_NEW
 jne .state
 cmp qword [rdx+NEBO_PROTOCOL_FRAME_SENDER],0
 je .auth
 mov qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_HELLO
 jmp .accept
.auth_frame:
 cmp qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_HELLO
 jne .state
 mov rax,[rdx+NEBO_PROTOCOL_FRAME_AUTH]
 cmp rax,[rsi+NEBO_PROTOCOL_ST_CAPABILITY]
 jne .auth
 mov qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_AUTH
 mov qword [rsi+NEBO_PROTOCOL_ST_AUTH],1
 jmp .accept
.ready_frame:
 cmp qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_AUTH
 jne .state
 mov qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_READY
 jmp .accept
.health:
 cmp qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_READY
 jne .state
 jmp .accept
.drain:
 cmp qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_READY
 jne .state
 mov qword [rsi+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_DRAINED
.accept:
 mov rax,[rdx+NEBO_PROTOCOL_FRAME_SEQUENCE]
 mov [rsi+NEBO_PROTOCOL_ST_LAST_RX],rax
 inc qword [rsi+NEBO_PROTOCOL_ST_INFLIGHT]
 mov [rdi+NEBO_PROTOCOL_PROCESS_RESULT],r8
 xor eax,eax
 ret
.version: mov eax,NEBO_PROTOCOL_STATUS_VERSION
 ret
.auth: mov eax,NEBO_PROTOCOL_STATUS_AUTH
 ret
.replay: mov eax,NEBO_PROTOCOL_STATUS_REPLAY
 ret
.oversize: mov eax,NEBO_PROTOCOL_STATUS_OVERSIZE
 ret
.state: mov eax,NEBO_PROTOCOL_STATUS_STATE
 ret
.backpressure: mov eax,NEBO_PROTOCOL_STATUS_BACKPRESSURE
 ret
.internet: mov eax,NEBO_PROTOCOL_STATUS_INTERNET
 ret
.corrupt: mov eax,NEBO_PROTOCOL_STATUS_CORRUPT
 ret
.bad: mov eax,NEBO_PROTOCOL_STATUS_INVALID
 ret

NEBOC_ABI_FUNCTION nebo_protocol_ack
 test rdi,rdi
 jz .bad
 mov rsi,[rdi]
 test rsi,rsi
 jz .bad
 cmp qword [rsi+NEBO_PROTOCOL_ST_INFLIGHT],0
 je .state
 dec qword [rsi+NEBO_PROTOCOL_ST_INFLIGHT]
 xor eax,eax
 ret
.state: mov eax,NEBO_PROTOCOL_STATUS_STATE
 ret
.bad: mov eax,NEBO_PROTOCOL_STATUS_INVALID
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
