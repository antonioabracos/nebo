bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "runtime/concurrency/stream_bridge.inc"
extern neboc_stream_init
section .bss
events resb nebo_data_contract_EVENT_SIZE*4
align 8
stream resb nebo_data_contract_STREAM_SIZE
align 8
channel_budget resb NEBO_CHANNEL_BUDGET_SIZE
channel resb NEBO_CHANNEL_SIZE
storage resq 4
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
 lea rdi,[stream]
 lea rsi,[events]
 mov edx,4
 mov ecx,4
 call neboc_stream_init
 test eax,eax
 jnz .fail1
 lea rdi,[channel_budget]
 mov esi,4
 mov edx,2
 mov ecx,1000000
 call nebo_channel_budget_init
 test eax,eax
 jnz .fail2
 lea rdi,[channel]
 lea rsi,[channel_budget]
 lea rdx,[storage]
 mov ecx,4
 call nebo_channel_init
 test eax,eax
 jnz .fail3
 lea rdi,[stream]
 lea rsi,[channel]
 xor edx,edx
 mov ecx,4
 call nebo_stream_to_channel
 test eax,eax
 jnz .fail4
 cmp rdx,4
 jne .fail5
 cmp qword [channel+NEBO_CHANNEL_COUNT],4
 jne .fail6
 lea rdi,[channel]
 mov esi,4
 lea rdx,[sink]
 lea rcx,[sum]
 xor r8d,r8d
 call nebo_channel_to_sink
 test eax,eax
 jnz .fail7
 cmp rdx,4
 jne .fail8
 cmp qword [sum],10
 jne .fail9
 cmp qword [channel+NEBO_CHANNEL_COUNT],0
 jne .fail10
 ; completed stream produces zero deterministically.
 lea rdi,[stream]
 lea rsi,[channel]
 xor edx,edx
 mov ecx,4
 call nebo_stream_to_channel
 test eax,eax
 jnz .fail11
 test rdx,rdx
 jnz .fail12
 xor rdi,rdi
 lea rsi,[channel]
 xor edx,edx
 xor ecx,ecx
 call nebo_stream_to_channel
 cmp eax,NEBO_CONCURRENCY_ERROR_INVALID_ARGUMENT
 jne .fail13
 xor edi,edi
 jmp .exit
%assign i 1
%rep 13
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit: mov eax,60
 syscall
