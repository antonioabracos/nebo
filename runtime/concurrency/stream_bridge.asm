bits 64
default rel
%define NEBO_STREAM_BRIDGE_IMPLEMENTATION 1
%include "runtime/concurrency/stream_bridge.inc"
extern neboc_stream_next
extern nebo_cancellation_check

section .text
global nebo_stream_to_channel
global nebo_channel_to_sink
global nebo_channel_to_socket

; rdi=finite Stream,rsi=Channel,rdx=optional token,rcx=max events.
; Preflight capacity preserves the stream index when backpressure cannot fit.
nebo_stream_to_channel:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .stc_invalid
 test r12,r12
 jz .stc_invalid
 mov rax,[rbx+NEBO_STREAM_LENGTH]
 sub rax,[rbx+NEBO_STREAM_INDEX]
 jc .stc_invalid
 cmp rax,r14
 ja .stc_limit
 mov rcx,[r12+NEBO_CHANNEL_CAPACITY]
 sub rcx,[r12+NEBO_CHANNEL_COUNT]
 cmp rax,rcx
 ja .stc_backpressure
 xor r14d,r14d
 sub rsp,32
.stc_loop:
 test r13,r13
 jz .stc_next
 mov rdi,r13
 call nebo_cancellation_check
 test eax,eax
 jnz .stc_done
.stc_next:
 mov rdi,rbx
 mov rsi,rsp
 lea rdx,[rsp+24]
 call neboc_stream_next
 test eax,eax
 jnz .stc_data_error
 cmp qword [rsp+24],0
 je .stc_success
 mov rdi,r12
 mov rsi,[rsp+nebo_data_contract_EVENT_VALUE]
 call nebo_channel_try_send
 test eax,eax
 jnz .stc_done
 inc r14
 jmp .stc_loop
.stc_success:
 mov rdx,r14
 xor eax,eax
 jmp .stc_done
.stc_data_error:
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 jmp .stc_done
.stc_invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .stc_return
.stc_limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 jmp .stc_return
.stc_backpressure: mov eax,NEBO_CONCURRENCY_ERROR_FULL
 xor edx,edx
 jmp .stc_return
.stc_done:
 add rsp,32
.stc_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Channel,rsi=count,rdx=consumer(value,ctx)->status,rcx=ctx,r8=optional token.
nebo_channel_to_sink:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 test rbx,rbx
 jz .cts_invalid
 test r13,r13
 jz .cts_invalid
 xor r10d,r10d
.cts_loop:
 cmp r10,r12
 jae .cts_success
 test r15,r15
 jz .cts_receive
 mov rdi,r15
 call nebo_cancellation_check
 test eax,eax
 jnz .cts_return
.cts_receive:
 mov rdi,rbx
 call nebo_channel_try_receive
 test eax,eax
 jnz .cts_return
 mov rdi,rdx
 mov rsi,r14
 call r13
 test eax,eax
 jnz .cts_callback
 inc r10
 jmp .cts_loop
.cts_success:
 mov rdx,r10
 xor eax,eax
 jmp .cts_return
.cts_callback:
 mov eax,NEBO_CONCURRENCY_ERROR_CHILD_FAILED
 jmp .cts_return
.cts_invalid:
 mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 xor edx,edx
.cts_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Channel,rsi=count,rdx=TcpStream,rcx=optional token.
nebo_channel_to_socket:
 push rbx
 push r12
 push r13
 push r14
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 sub rsp,8
 xor r10d,r10d
.socket_loop:
 cmp r10,r12
 jae .socket_ok
 test r14,r14
 jz .socket_recv
 mov rdi,r14
 call nebo_cancellation_check
 test eax,eax
 jnz .socket_return
.socket_recv:
 mov rdi,rbx
 call nebo_channel_try_receive
 test eax,eax
 jnz .socket_return
 mov [rsp],rdx
 mov rdi,r13
 mov rsi,rsp
 mov edx,8
 call nebo_tcp_stream_write
 test eax,eax
 jnz .socket_map_error
 cmp rdx,8
 jne .socket_io
 inc r10
 jmp .socket_loop
.socket_ok:
 mov rdx,r10
 xor eax,eax
 jmp .socket_return
.socket_map_error:
 mov eax,NEBO_CONCURRENCY_ERROR_IO
 jmp .socket_return
.socket_io:
 mov eax,NEBO_CONCURRENCY_ERROR_IO
.socket_return:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
