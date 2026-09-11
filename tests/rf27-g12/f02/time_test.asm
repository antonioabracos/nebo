bits 64
default rel
%include "compiler/semantic/system/system_contract.inc"
%include "runtime/system/time.inc"

section .bss
cap_all resb NEBO_CLOCK_CAPABILITY_SIZE
cap_mono resb NEBO_CLOCK_CAPABILITY_SIZE
duration_a resb 16
duration_b resb 16
duration_out resb 16
instant_a resb 16
instant_future resb 16
system_time resb 16

section .text
global _start
_start:
 lea rdi,[cap_all]
 mov esi,NEBO_CLOCK_CAP_ALL
 mov edx,16
 mov ecx,2000000
 call nebo_clock_capability_init
 test eax,eax
 jnz .fail1
 lea rdi,[duration_a]
 mov rsi,1501
 call nebo_duration_from_millis
 test eax,eax
 jnz .fail2
 cmp qword [duration_a],1
 jne .fail3
 cmp qword [duration_a+8],501000000
 jne .fail4
 lea rdi,[duration_a]
 call nebo_duration_to_millis
 test eax,eax
 jnz .fail5
 cmp rdx,1501
 jne .fail6
 lea rdi,[duration_b]
 mov rsi,999
 call nebo_duration_from_millis
 test eax,eax
 jnz .fail7
 lea rdi,[duration_out]
 lea rsi,[duration_a]
 lea rdx,[duration_b]
 call nebo_duration_add
 test eax,eax
 jnz .fail8
 cmp qword [duration_out],2
 jne .fail9
 cmp qword [duration_out+8],500000000
 jne .fail10
 lea rdi,[duration_out]
 mov qword [duration_out],77
 mov qword [duration_out+8],88
 lea rsi,[duration_a]
 lea rdx,[duration_b]
 mov qword [duration_b+8],1000000000
 call nebo_duration_add
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail11
 cmp qword [duration_out],77
 jne .fail12
 lea rdi,[duration_b]
 mov rsi,-1
 call nebo_duration_from_millis
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail13
 lea rdi,[instant_a]
 lea rsi,[cap_all]
 call nebo_instant_now
 test eax,eax
 jnz .fail14
 cmp qword [instant_a+8],1000000000
 jae .fail15
 lea rdi,[system_time]
 lea rsi,[cap_all]
 call nebo_system_time_now
 test eax,eax
 jnz .fail16
 cmp qword [system_time],0
 jle .fail17
 lea rdi,[duration_out]
 lea rsi,[instant_a]
 lea rdx,[cap_all]
 call nebo_instant_elapsed
 test eax,eax
 jnz .fail18
 cmp qword [duration_out],0
 jl .fail19
 lea rdi,[instant_future]
 mov rax,[instant_a]
 add rax,10
 mov [instant_future],rax
 mov rax,[instant_a+8]
 mov [instant_future+8],rax
 lea rdi,[duration_out]
 lea rsi,[instant_future]
 lea rdx,[cap_all]
 call nebo_instant_elapsed
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail20
 lea rdi,[cap_mono]
 mov esi,NEBO_CLOCK_CAP_MONOTONIC
 mov edx,1
 xor ecx,ecx
 call nebo_clock_capability_init
 test eax,eax
 jnz .fail21
 lea rdi,[system_time]
 lea rsi,[cap_mono]
 call nebo_system_time_now
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail22
 lea rdi,[instant_a]
 lea rsi,[cap_mono]
 call nebo_instant_now
 test eax,eax
 jnz .fail23
 lea rdi,[instant_a]
 lea rsi,[cap_mono]
 call nebo_instant_now
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail24
 lea rdi,[duration_a]
 xor esi,esi
 call nebo_duration_from_millis
 test eax,eax
 jnz .fail25
 lea rdi,[duration_a]
 lea rsi,[cap_all]
 call nebo_duration_sleep
 test eax,eax
 jnz .fail26
 lea rdi,[duration_a]
 mov esi,3
 call nebo_duration_from_millis
 test eax,eax
 jnz .fail27
 lea rdi,[duration_a]
 lea rsi,[cap_all]
 call nebo_duration_sleep
 cmp eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 jne .fail28
 xor edi,edi
 lea rsi,[instant_a]
 lea rdx,[cap_all]
 call nebo_instant_elapsed
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail31
 lea rdi,[duration_out]
 xor esi,esi
 lea rdx,[cap_all]
 call nebo_instant_elapsed
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail32
 xor edi,edi
 lea rsi,[cap_all]
 call nebo_instant_now
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail33
 mov qword [cap_all+NEBO_CLOCK_CAPABILITY_MAGIC],0
 lea rdi,[instant_a]
 lea rsi,[cap_all]
 call nebo_instant_now
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail29
 lea rdi,[cap_all]
 mov esi,8
 mov edx,1
 mov ecx,1
 call nebo_clock_capability_init
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail30
 xor edi,edi
 jmp .exit
%assign i 1
%rep 33
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
