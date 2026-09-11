bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/semantic/data/data_contract.inc"
extern neboc_flow_init
extern neboc_flow_next
extern neboc_stream_init
extern neboc_stream_configure
extern neboc_stream_next
extern neboc_stream_consume
global _start
section .text
_start:
 mov qword [rel events+nebo_data_contract_EVENT_VALUE],1
 mov qword [rel events+NEBO_EVENT_SEQUENCE],10
 mov qword [rel events+nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],2
 mov qword [rel events+nebo_data_contract_EVENT_SIZE+NEBO_EVENT_SEQUENCE],11
 mov qword [rel events+2*nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],3
 mov qword [rel events+2*nebo_data_contract_EVENT_SIZE+NEBO_EVENT_SEQUENCE],12
 mov qword [rel events+3*nebo_data_contract_EVENT_SIZE+nebo_data_contract_EVENT_VALUE],4
 mov qword [rel events+3*nebo_data_contract_EVENT_SIZE+NEBO_EVENT_SEQUENCE],13
 lea rdi,[rel flow]
 lea rsi,[rel events]
 mov edx,4
 call neboc_flow_init
 test eax,eax
 jnz fail1
 lea rdi,[rel flow]
 lea rsi,[rel out_event]
 lea rdx,[rel has]
 call neboc_flow_next
 test eax,eax
 jnz fail1
 cmp qword [rel has],1
 jne fail1
 cmp qword [rel out_event+nebo_data_contract_EVENT_VALUE],1
 jne fail1
 cmp qword [rel out_event+NEBO_EVENT_SEQUENCE],10
 jne fail1

 lea rdi,[rel stream]
 lea rsi,[rel events]
 mov edx,4
 mov ecx,4
 call neboc_stream_init
 test eax,eax
 jnz fail2
 lea rdi,[rel stream]
 lea rsi,[rel map_double]
 lea rdx,[rel filter_gt_one]
 lea rcx,[rel context]
 call neboc_stream_configure
 test eax,eax
 jnz fail2
 lea rdi,[rel stream]
 lea rsi,[rel out_event]
 lea rdx,[rel has]
 call neboc_stream_next
 test eax,eax
 jnz fail3
 cmp qword [rel out_event+nebo_data_contract_EVENT_VALUE],4
 jne fail3
 cmp qword [rel out_event+NEBO_EVENT_SEQUENCE],11
 jne fail3
 cmp qword [rel context],3       ; filter twice, map once
 jne fail3
 lea rdi,[rel stream]
 lea rsi,[rel out_event]
 lea rdx,[rel has]
 call neboc_stream_next
 test eax,eax
 jnz fail3
 cmp qword [rel out_event+nebo_data_contract_EVENT_VALUE],6
 jne fail3

 ; consumer drains final mapped value and observes completion.
 lea rdi,[rel stream]
 lea rsi,[rel consume_sum]
 lea rdx,[rel sum]
 lea rcx,[rel count]
 call neboc_stream_consume
 test eax,eax
 jnz fail4
 cmp qword [rel count],1
 jne fail4
 cmp qword [rel sum],8
 jne fail4
 test qword [rel stream+nebo_data_contract_STREAM_FLAGS],NEBO_DATA_STREAM_COMPLETE
 jz fail4

 ; capacity refuses construction without mutation.
 mov qword [rel bad_stream],0x55
 lea rdi,[rel bad_stream]
 lea rsi,[rel events]
 mov edx,4
 mov ecx,3
 call neboc_stream_init
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail5
 cmp qword [rel bad_stream],0x55
 jne fail5

 ; callback error leaves the current source event unconsumed.
 lea rdi,[rel error_stream]
 lea rsi,[rel events]
 mov edx,1
 mov ecx,1
 call neboc_stream_init
 test eax,eax
 jnz fail6
 lea rdi,[rel error_stream]
 lea rsi,[rel map_error]
 xor edx,edx
 xor ecx,ecx
 call neboc_stream_configure
 test eax,eax
 jnz fail6
 lea rdi,[rel error_stream]
 lea rsi,[rel out_event]
 lea rdx,[rel has]
 call neboc_stream_next
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail6
 cmp qword [rel error_stream+NEBO_STREAM_INDEX],0
 jne fail6
 cmp qword [rel has],0
 jne fail6

 ; empty flow reaches explicit completion deterministically.
 lea rdi,[rel empty_flow]
 lea rsi,[rel events]
 xor edx,edx
 call neboc_flow_init
 test eax,eax
 jnz fail7
 lea rdi,[rel empty_flow]
 lea rsi,[rel out_event]
 lea rdx,[rel has]
 call neboc_flow_next
 test eax,eax
 jnz fail7
 cmp qword [rel has],0
 jne fail7
 test qword [rel empty_flow+NEBO_FLOW_FLAGS],NEBO_DATA_STREAM_COMPLETE
 jz fail7

 xor edi,edi
 jmp exit
map_double:
 inc qword [rsi]
 add rdi,rdi
 mov [rdx],rdi
 xor eax,eax
 ret
filter_gt_one:
 inc qword [rsi]
 xor eax,eax
 cmp rdi,1
 setg al
 movzx rax,al
 mov [rdx],rax
 xor eax,eax
 ret
consume_sum:
 add [rsi],rdi
 xor eax,eax
 ret
map_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
fail1: mov edi,1
 jmp exit
fail2: mov edi,2
 jmp exit
fail3: mov edi,3
 jmp exit
fail4: mov edi,4
 jmp exit
fail5: mov edi,5
 jmp exit
fail6: mov edi,6
 jmp exit
fail7: mov edi,7
exit:
 mov eax,60
 syscall
section .bss
align 8
events: resb 4*nebo_data_contract_EVENT_SIZE
flow: resb NEBO_FLOW_SIZE
empty_flow: resb NEBO_FLOW_SIZE
stream: resb nebo_data_contract_STREAM_SIZE
error_stream: resb nebo_data_contract_STREAM_SIZE
bad_stream: resb nebo_data_contract_STREAM_SIZE
out_event: resb nebo_data_contract_EVENT_SIZE
has: resq 1
context: resq 1
sum: resq 1
count: resq 1
section .note.GNU-stack noalloc noexec nowrite progbits
