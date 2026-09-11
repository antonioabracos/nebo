bits 64
default rel
%include "runtime/distributed/protocol.inc"
extern nebo_protocol_init,nebo_protocol_process,nebo_protocol_ack
section .bss
state resb NEBO_PROTOCOL_STATE_SIZE
init_req resb NEBO_PROTOCOL_INIT_SIZE
frame resb NEBO_PROTOCOL_FRAME_SIZE
process_req resb NEBO_PROTOCOL_PROCESS_SIZE
ack_req resq 1
section .text
global _start
_start:
 lea rax,[state]
 mov [init_req+NEBO_PROTOCOL_INIT_STATE],rax
 mov qword [init_req+NEBO_PROTOCOL_INIT_IDENTITY],0x2606
 mov qword [init_req+NEBO_PROTOCOL_INIT_CAPABILITY],0xcafe
 mov qword [init_req+NEBO_PROTOCOL_INIT_MAX_INFLIGHT],2
 lea rdi,[init_req]
 call nebo_protocol_init
 test eax,eax
 jnz fail
 mov rax,NEBO_PROTOCOL_FRAME_MAGIC
 mov [frame+NEBO_PROTOCOL_FRAME_MAGIC_OFF],rax
 mov qword [frame+NEBO_PROTOCOL_FRAME_VERSION],1
 mov qword [frame+NEBO_PROTOCOL_FRAME_TYPE],NEBO_PROTOCOL_TYPE_HELLO
 mov qword [frame+NEBO_PROTOCOL_FRAME_SENDER],0x99
 mov qword [frame+NEBO_PROTOCOL_FRAME_SEQUENCE],1
 lea rax,[state]
 mov [process_req+NEBO_PROTOCOL_PROCESS_STATE],rax
 lea rax,[frame]
 mov [process_req+NEBO_PROTOCOL_PROCESS_FRAME],rax
 mov qword [process_req+NEBO_PROTOCOL_PROCESS_CAPABILITY],0xcafe
 lea rdi,[process_req]
 call nebo_protocol_process
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_HELLO
 jne fail
 lea rax,[state]
 mov [ack_req],rax
 lea rdi,[ack_req]
 call nebo_protocol_ack
 test eax,eax
 jnz fail
 mov qword [frame+NEBO_PROTOCOL_FRAME_TYPE],NEBO_PROTOCOL_TYPE_AUTH
 mov qword [frame+NEBO_PROTOCOL_FRAME_SEQUENCE],2
 mov qword [frame+NEBO_PROTOCOL_FRAME_AUTH],0xcafe
 lea rdi,[process_req]
 call nebo_protocol_process
 test eax,eax
 jnz fail
 lea rdi,[ack_req]
 call nebo_protocol_ack
 mov qword [frame+NEBO_PROTOCOL_FRAME_TYPE],NEBO_PROTOCOL_TYPE_READY
 mov qword [frame+NEBO_PROTOCOL_FRAME_SEQUENCE],3
 lea rdi,[process_req]
 call nebo_protocol_process
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_READY
 jne fail
 lea rdi,[process_req]
 call nebo_protocol_process
 cmp eax,NEBO_PROTOCOL_STATUS_REPLAY
 jne fail
 lea rdi,[ack_req]
 call nebo_protocol_ack
 mov qword [frame+NEBO_PROTOCOL_FRAME_TYPE],NEBO_PROTOCOL_TYPE_HEALTH
 mov qword [frame+NEBO_PROTOCOL_FRAME_SEQUENCE],4
 mov qword [frame+NEBO_PROTOCOL_FRAME_PAYLOAD],65537
 lea rdi,[process_req]
 call nebo_protocol_process
 cmp eax,NEBO_PROTOCOL_STATUS_OVERSIZE
 jne fail
 mov qword [frame+NEBO_PROTOCOL_FRAME_PAYLOAD],0
 mov qword [frame+NEBO_PROTOCOL_FRAME_RESERVED],1
 lea rdi,[process_req]
 call nebo_protocol_process
 cmp eax,NEBO_PROTOCOL_STATUS_INTERNET
 jne fail
 mov qword [frame+NEBO_PROTOCOL_FRAME_RESERVED],0
 mov qword [process_req+NEBO_PROTOCOL_PROCESS_CAPABILITY],0xbeef
 lea rdi,[process_req]
 call nebo_protocol_process
 cmp eax,NEBO_PROTOCOL_STATUS_AUTH
 jne fail
 mov qword [process_req+NEBO_PROTOCOL_PROCESS_CAPABILITY],0xcafe
 mov qword [frame+NEBO_PROTOCOL_FRAME_TYPE],NEBO_PROTOCOL_TYPE_DRAIN
 lea rdi,[process_req]
 call nebo_protocol_process
 test eax,eax
 jnz fail
 cmp qword [state+NEBO_PROTOCOL_ST_STATE],NEBO_PROTOCOL_STATE_DRAINED
 jne fail
 xor edi,edi
 mov eax,60
 syscall
fail: mov edi,1
 mov eax,60
 syscall
section .note.GNU-stack noalloc noexec nowrite progbits
