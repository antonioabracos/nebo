; COLECOES-PRIMITIVAS-F09 finite Stream -> bounded Channel -> sink integration facade.
bits 64
default rel
%define NEBO_CHANNEL_STREAM_BRIDGE_IMPLEMENTATION 1
%include "runtime/data/channel_stream_bridge.inc"

section .text
global nebo_channel_stream_run

; rdi=ChannelStreamPlan. The plan borrows every resource and never closes it.
; Produced/consumed observations commit only when the bounded transfer succeeds.
nebo_channel_stream_run:
 push rbx
 push r12
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov rdi,[r12+NEBO_CHANNEL_STREAM_PLAN_STREAM]
 test rdi,rdi
 jz .invalid
 mov rsi,[r12+NEBO_CHANNEL_STREAM_PLAN_CHANNEL]
 test rsi,rsi
 jz .invalid
 mov rcx,[r12+NEBO_CHANNEL_STREAM_PLAN_MAX_EVENTS]
 test rcx,rcx
 jz .limit
 cmp rcx,NEBO_DATA_MAX_EVENTS
 ja .limit
 mov rax,[r12+NEBO_CHANNEL_STREAM_PLAN_SINK]
 test rax,rax
 jz .invalid
 mov rdx,[r12+NEBO_CHANNEL_STREAM_PLAN_TOKEN]
 test rdx,rdx
 jz .transfer
 push rdi
 push rsi
 push rdx
 push rcx
 mov rdi,rdx
 call nebo_cancellation_check
 pop rcx
 pop rdx
 pop rsi
 pop rdi
 test eax,eax
 jnz .return
.transfer:
 call nebo_stream_to_channel
 test eax,eax
 jnz .return
 mov rbx,rdx
 mov rdi,[r12+NEBO_CHANNEL_STREAM_PLAN_CHANNEL]
 mov rsi,rbx
 mov rdx,[r12+NEBO_CHANNEL_STREAM_PLAN_SINK]
 mov rcx,[r12+NEBO_CHANNEL_STREAM_PLAN_CONTEXT]
 mov r8,[r12+NEBO_CHANNEL_STREAM_PLAN_TOKEN]
 call nebo_channel_to_sink
 test eax,eax
 jnz .return
 cmp rdx,rbx
 jne .io
 mov [r12+NEBO_CHANNEL_STREAM_PLAN_PRODUCED],rbx
 mov [r12+NEBO_CHANNEL_STREAM_PLAN_CONSUMED],rdx
 xor eax,eax
 jmp .return
.invalid: mov eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jmp .return
.limit: mov eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jmp .return
.io: mov eax,NEBO_CONCURRENCY_ERROR_IO
.return:
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
