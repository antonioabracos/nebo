bits 64
default rel
%include "runtime/data/channel_stream_bridge.inc"
extern neboc_stream_init

section .bss
align 8
events resb nebo_data_contract_EVENT_SIZE*4
stream resb nebo_data_contract_STREAM_SIZE
channel_budget resb NEBO_CHANNEL_BUDGET_SIZE
channel resb NEBO_CHANNEL_SIZE
storage resq 2
cancel_budget resb NEBO_CANCELLATION_BUDGET_SIZE
cancelled resb NEBO_CANCELLATION_TOKEN_SIZE
expired resb NEBO_CANCELLATION_TOKEN_SIZE
deadline resb NEBO_DEADLINE_SIZE
plan resb NEBO_CHANNEL_STREAM_PLAN_SIZE
sum resq 1

section .text
global _start
sink:
 add [rsi],rdi
 xor eax,eax
 ret
_start:
 mov qword [events+nebo_data_contract_EVENT_VALUE],1
 mov qword [events+nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],2
 mov qword [events+2*nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],3
 mov qword [events+3*nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],4
 lea rdi,[channel_budget]
 mov esi,2
 mov edx,1
 mov ecx,1000000
 call nebo_channel_budget_init
 test eax,eax
 jnz .fail1
 lea rdi,[channel]
 lea rsi,[channel_budget]
 lea rdx,[storage]
 mov ecx,2
 call nebo_channel_init
 test eax,eax
 jnz .fail2
 lea rdi,[stream]
 lea rsi,[events]
 mov edx,4
 mov ecx,4
 call neboc_stream_init
 test eax,eax
 jnz .fail3
 lea rax,[stream]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_STREAM],rax
 lea rax,[channel]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_CHANNEL],rax
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_MAX_EVENTS],4
 lea rax,[sink]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_SINK],rax
 lea rax,[sum]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_CONTEXT],rax
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_PRODUCED],0x55
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_CONSUMED],0x66
 lea rdi,[plan]
 call nebo_channel_stream_run
 cmp eax,NEBO_CONCURRENCY_ERROR_FULL
 jne .fail4
 cmp qword [stream+NEBO_STREAM_INDEX],0
 jne .fail5
 cmp qword [plan+NEBO_CHANNEL_STREAM_PLAN_PRODUCED],0x55
 jne .fail6
 ; A transfer fitting the bounded channel preserves order and drains to sink.
 lea rdi,[stream]
 lea rsi,[events]
 mov edx,2
 mov ecx,2
 call neboc_stream_init
 test eax,eax
 jnz .fail7
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_MAX_EVENTS],2
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_PRODUCED],0
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_CONSUMED],0
 lea rdi,[plan]
 call nebo_channel_stream_run
 test eax,eax
 jnz .fail8
 cmp qword [plan+NEBO_CHANNEL_STREAM_PLAN_PRODUCED],2
 jne .fail9
 cmp qword [plan+NEBO_CHANNEL_STREAM_PLAN_CONSUMED],2
 jne .fail10
 cmp qword [sum],3
 jne .fail11
 cmp qword [channel+NEBO_CHANNEL_COUNT],0
 jne .fail12
 cmp qword [channel+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_OPEN
 jne .fail13
 ; Cooperative cancellation refuses work without consuming the stream.
 lea rdi,[cancel_budget]
 mov esi,3
 mov edx,1
 mov ecx,1000000000
 call nebo_cancellation_budget_init
 test eax,eax
 jnz .fail14
 lea rdi,[cancelled]
 lea rsi,[cancel_budget]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail15
 lea rdi,[cancelled]
 call nebo_cancellation_cancel
 test eax,eax
 jnz .fail16
 lea rdi,[stream]
 lea rsi,[events]
 mov edx,2
 mov ecx,2
 call neboc_stream_init
 test eax,eax
 jnz .fail17
 lea rax,[cancelled]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_TOKEN],rax
 lea rdi,[plan]
 call nebo_channel_stream_run
 cmp eax,NEBO_CONCURRENCY_ERROR_CANCELLED
 jne .fail18
 cmp qword [stream+NEBO_STREAM_INDEX],0
 jne .fail19
 ; An expired monotonic deadline is a typed timeout with no stream advance.
 mov qword [deadline],0
 mov qword [deadline+8],1
 lea rdi,[expired]
 lea rsi,[cancel_budget]
 xor edx,edx
 lea rcx,[deadline]
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 test eax,eax
 jnz .fail20
 lea rax,[expired]
 mov [plan+NEBO_CHANNEL_STREAM_PLAN_TOKEN],rax
 lea rdi,[plan]
 call nebo_channel_stream_run
 cmp eax,NEBO_CONCURRENCY_ERROR_TIMEOUT
 jne .fail21
 cmp qword [stream+NEBO_STREAM_INDEX],0
 jne .fail22
 ; Invalid/unbounded plans fail without taking ownership.
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_TOKEN],0
 mov qword [plan+NEBO_CHANNEL_STREAM_PLAN_MAX_EVENTS],0
 lea rdi,[plan]
 call nebo_channel_stream_run
 cmp eax,NEBO_CONCURRENCY_ERROR_LIMIT_EXCEEDED
 jne .fail23
 cmp qword [channel+NEBO_CHANNEL_STATE],NEBO_CHANNEL_STATE_OPEN
 jne .fail24
 xor edi,edi
 jmp .exit
%assign i 1
%rep 24
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
