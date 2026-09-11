; Bounded typed calls compose existing concurrency and system runtime owners.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/concurrency/cancel.inc"
%include "runtime/concurrency/channel.inc"
%include "runtime/system/time.inc"
extern nebo_process_current_pid
extern neboc_runtime_store_integer
extern nebo_runtime_trap_arithmetic_domain
extern nebo_codec_public
extern nebo_task_public
extern nebo_environment_public
extern nebo_network_public
extern nebo_sync_public
section .bss
align 8
system_public_clock: resb 64
section .text
; Op, receiver, argument, argument2, caller-owned destination (960 bytes).
NEBOC_ABI_FUNCTION nebo_system_public
 cmp edi,200
 jae nebo_network_public
 cmp edi,100
 jae nebo_codec_public
 cmp edi,60
 jae nebo_sync_public
 cmp edi,40
 jae nebo_task_public
 cmp edi,31
 jae nebo_environment_public
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,20
 jae .system
 cmp ebx,10
 jae .channel
 cmp ebx,1
 je .token_new
 mov rdi,r12
 cmp ebx,2
 je .cancelled
 cmp ebx,3
 je .cancel
 cmp ebx,4
 jne .trap
 call nebo_cancellation_check
 xor edx,edx
 jmp .result
.token_new:
 mov rdi,r15
 xor eax,eax
 mov ecx,960/8
 rep stosq
 lea rdi,[r15+48]
 mov esi,1
 mov edx,1
 mov ecx,100000000
 call nebo_cancellation_budget_init
 test eax,eax
 jnz .trap
 mov rdi,r15
 lea rsi,[r15+48]
 xor edx,edx
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
 call nebo_cancellation_token_init
 jmp .descriptor
.cancelled:
 call nebo_cancellation_is_cancelled
 jmp .scalar
.cancel:
 call nebo_cancellation_cancel
 jmp .void
.channel:
 cmp ebx,11
 jbe .channel_new
 mov rdi,r12
 cmp ebx,12
 je .capacity
 cmp ebx,13
 je .try_send
 cmp ebx,14
 je .try_receive
 cmp ebx,15
 je .send
 cmp ebx,16
 je .receive
 cmp ebx,17
 jne .trap
 call nebo_channel_close_sender
 test eax,eax
 jnz .trap
 mov rdi,r12
 call nebo_channel_close_receiver
 jmp .void
.channel_new:
 cmp ebx,11
 jne .capacity_input
 xor r13d,r13d
.capacity_input:
 cmp r13,64
 ja .trap
 mov rdi,r15
 xor eax,eax
 mov ecx,960/8
 rep stosq
 lea rdi,[r15+96]
 mov esi,64
 mov edx,1
 mov ecx,1000000
 call nebo_channel_budget_init
 test eax,eax
 jnz .trap
 mov rdi,r15
 lea rsi,[r15+96]
 lea rdx,[r15+144]
 mov rcx,r13
 call nebo_channel_init
 jmp .descriptor
.capacity:
 mov rax,[r12+NEBO_CHANNEL_CAPACITY]
 jmp .done
.try_send:
 mov rsi,r13
 call nebo_channel_try_send
 xor edx,edx
 jmp .result
.try_receive:
 call nebo_channel_try_receive
 jmp .result
.send:
 mov rsi,r13
 xor edx,edx
 mov r10d,1
 call nebo_channel_send
 xor edx,edx
 jmp .result
.receive:
 xor esi,esi
 mov edx,1
 call nebo_channel_receive
 jmp .result
.result:
 ; Preserve every native error code, including EMPTY/FULL/CLOSED/TIMEOUT.
 ; No failed receive fabricates a value and no failed send mutates the queue.
 xor esi,esi
 test eax,eax
 jz .tag
 mov esi,1
 mov edx,eax
.tag:
 mov rdi,r15
 call neboc_runtime_store_integer
 mov rax,r15
 jmp .done
.system:
 cmp ebx,30
 je .pid
 cmp qword [rel system_public_clock],0
 jne .clock_ready
 lea rdi,[rel system_public_clock]
 mov esi,NEBO_CLOCK_CAP_MONOTONIC | NEBO_CLOCK_CAP_SLEEP
 mov edx,4096
 mov ecx,100000000
 call nebo_clock_capability_init
 test eax,eax
 jnz .trap
.clock_ready:
 cmp ebx,20
 je .duration
 cmp ebx,21
 je .nanos
 cmp ebx,22
 je .instant
 cmp ebx,23
 je .elapsed
 cmp ebx,24
 jne .trap
 mov rdi,r13
 lea rsi,[rel system_public_clock]
 call nebo_duration_sleep
 jmp .void
.duration:
 mov rdi,r15
 mov rsi,r13
 call nebo_duration_from_millis
 jmp .descriptor
.nanos:
 mov rdi,r12
 call nebo_duration_as_nanos
 jmp .scalar
.instant:
 mov rdi,r15
 lea rsi,[rel system_public_clock]
 call nebo_instant_now
 jmp .descriptor
.elapsed:
 mov rdi,r15
 mov rsi,r12
 lea rdx,[rel system_public_clock]
 call nebo_instant_elapsed
 jmp .descriptor
.pid:
 call nebo_process_current_pid
 jmp .scalar
.descriptor:
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.scalar:
 test eax,eax
 jnz .trap
 mov rax,rdx
 jmp .done
.void:
 test eax,eax
 jnz .trap
 xor eax,eax
 jmp .done
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
