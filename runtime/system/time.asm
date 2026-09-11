bits 64
default rel

%include "compiler/semantic/system/system_contract.inc"

%define NANOS_PER_SECOND 1000000000
%define NANOS_PER_MILLI 1000000
%define EINTR 4

section .text
global nebo_clock_capability_init
global nebo_duration_from_millis
global nebo_duration_to_millis
global nebo_duration_as_nanos
global nebo_duration_add
global nebo_instant_now
global nebo_system_time_now
global nebo_system_time_to_unix_seconds
global nebo_instant_elapsed
global nebo_duration_sleep

; rdi=capability, rsi=permission bits, rdx=max calls, rcx=max sleep nanoseconds.
nebo_clock_capability_init:
 test rdi,rdi
 jz .invalid
 test rsi,~NEBO_CLOCK_CAP_ALL
 jnz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .limit
 test rcx,rcx
 js .limit
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_CLOCK
 mov [rdi+NEBO_CLOCK_CAPABILITY_MAGIC],rax
 mov [rdi+NEBO_CLOCK_CAPABILITY_PERMISSIONS],rsi
 mov [rdi+NEBO_CLOCK_CAPABILITY_MAX_CALLS],rdx
 mov [rdi+NEBO_CLOCK_CAPABILITY_MAX_SLEEP_NS],rcx
 mov qword [rdi+NEBO_CLOCK_CAPABILITY_CALLS_USED],0
 mov qword [rdi+NEBO_CLOCK_CAPABILITY_GENERATION],1
 xor eax,eax
 ret
.invalid:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=Duration out, rsi=nonnegative milliseconds. eax=status.
nebo_duration_from_millis:
 test rdi,rdi
 jz .duration_invalid
 test rsi,rsi
 js .duration_invalid
 mov rax,rsi
 xor edx,edx
 mov rcx,1000
 div rcx
 imul rdx,NANOS_PER_MILLI
 mov [rdi+NEBO_DURATION_SECONDS],rax
 mov [rdi+NEBO_DURATION_NANOS],rdx
 xor eax,eax
 ret
.duration_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=Duration. eax=status, rdx=milliseconds.
nebo_duration_to_millis:
 call duration_validate
 test eax,eax
 jnz .to_return
 mov rax,[rdi+NEBO_DURATION_SECONDS]
 mov rcx,1000
 mul rcx
 test rdx,rdx
 jnz .to_overflow
 mov r8,rax
 mov rax,[rdi+NEBO_DURATION_NANOS]
 xor edx,edx
 mov rcx,NANOS_PER_MILLI
 div rcx
 add r8,rax
 jc .to_overflow
 mov rdx,r8
 xor eax,eax
.to_return:
 ret
.to_overflow:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 ret

; rdi=Duration. eax=status, rdx=nanoseconds. Checked and non-lossy.
nebo_duration_as_nanos:
 call duration_validate
 test eax,eax
 jnz .nanos_return
 mov rax,[rdi+NEBO_DURATION_SECONDS]
 mov rcx,NANOS_PER_SECOND
 mul rcx
 test rdx,rdx
 jnz .nanos_overflow
 add rax,[rdi+NEBO_DURATION_NANOS]
 jc .nanos_overflow
 mov rdx,rax
 xor eax,eax
.nanos_return:
 ret
.nanos_overflow:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 ret

; rdi=SystemTime. eax=status, rdx=whole Unix seconds.
nebo_system_time_to_unix_seconds:
 call duration_validate
 test eax,eax
 jnz .unix_return
 mov rdx,[rdi+NEBO_SYSTEM_TIME_SECONDS]
 xor eax,eax
.unix_return:
 ret
; rdi=out, rsi=a, rdx=b. eax=status. Output is failure-atomic.
nebo_duration_add:
 test rdi,rdi
 jz .add_invalid
 test rsi,rsi
 jz .add_invalid
 test rdx,rdx
 jz .add_invalid
 mov r8,rdi
 mov rdi,rsi
 call duration_validate
 test eax,eax
 jnz .add_return
 mov rdi,rdx
 call duration_validate
 test eax,eax
 jnz .add_return
 mov rax,[rsi+NEBO_DURATION_SECONDS]
 add rax,[rdx+NEBO_DURATION_SECONDS]
 jo .add_overflow
 mov rcx,[rsi+NEBO_DURATION_NANOS]
 add rcx,[rdx+NEBO_DURATION_NANOS]
 cmp rcx,NANOS_PER_SECOND
 jb .add_store
 sub rcx,NANOS_PER_SECOND
 inc rax
 jo .add_overflow
.add_store:
 mov [r8+NEBO_DURATION_SECONDS],rax
 mov [r8+NEBO_DURATION_NANOS],rcx
 xor eax,eax
.add_return:
 ret
.add_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.add_overflow:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=Instant out, rsi=ClockCapability.
nebo_instant_now:
 mov edx,NEBO_CLOCK_CAP_MONOTONIC
 mov ecx,NEBO_CLOCK_MONOTONIC
 jmp clock_now

; rdi=SystemTime out, rsi=ClockCapability.
nebo_system_time_now:
 mov edx,NEBO_CLOCK_CAP_CIVIL
 mov ecx,NEBO_CLOCK_REALTIME
 jmp clock_now

; rdi=Duration out, rsi=earlier Instant, rdx=ClockCapability.
nebo_instant_elapsed:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 sub rsp,16
 test r12,r12
 jz .elapsed_invalid
 test rbx,rbx
 jz .elapsed_invalid
 mov rdi,rsp
 mov rsi,rdx
 call nebo_instant_now
 test eax,eax
 jnz .elapsed_return
 mov rax,[rsp]
 mov rcx,[rsp+8]
 cmp rax,[rbx]
 jb .elapsed_invalid
 jne .elapsed_subtract
 cmp rcx,[rbx+8]
 jb .elapsed_invalid
.elapsed_subtract:
 sub rcx,[rbx+8]
 jns .elapsed_no_borrow
 add rcx,NANOS_PER_SECOND
 dec rax
.elapsed_no_borrow:
 sub rax,[rbx]
 mov [r12],rax
 mov [r12+8],rcx
 xor eax,eax
 jmp .elapsed_return
.elapsed_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.elapsed_return:
 add rsp,16
 pop r12
 pop rbx
 ret

; rdi=Duration, rsi=ClockCapability. EINTR resumes from kernel remainder.
nebo_duration_sleep:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 call duration_validate
 test eax,eax
 jnz .sleep_return
 mov rdi,rbx
 mov esi,NEBO_CLOCK_CAP_SLEEP
 call clock_capability_validate
 test eax,eax
 jnz .sleep_return
 mov rax,[r12]
 mov rcx,NANOS_PER_SECOND
 mul rcx
 test rdx,rdx
 jnz .sleep_limit
 add rax,[r12+8]
 jc .sleep_limit
 cmp rax,[rbx+NEBO_CLOCK_CAPABILITY_MAX_SLEEP_NS]
 ja .sleep_limit
 sub rsp,32
 mov rax,[r12]
 mov [rsp],rax
 mov rax,[r12+8]
 mov [rsp+8],rax
.sleep_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_CLOCK_NANOSLEEP
 mov edi,NEBO_CLOCK_MONOTONIC
 xor esi,esi
 mov rdx,rsp
 lea r10,[rsp+16]
 syscall
 cmp rax,-EINTR
 jne .sleep_done
 mov rax,[rsp+16]
 mov [rsp],rax
 mov rax,[rsp+24]
 mov [rsp+8],rax
 jmp .sleep_retry
.sleep_done:
 cmp rax,-4095
 jae .sleep_syscall
 inc qword [rbx+NEBO_CLOCK_CAPABILITY_CALLS_USED]
 add rsp,32
 xor eax,eax
 jmp .sleep_return
.sleep_syscall:
 add rsp,32
 mov eax,NEBO_SYSTEM_ERROR_IO
 jmp .sleep_return
.sleep_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.sleep_return:
 pop r12
 pop rbx
 ret

; rdi=output, rsi=capability, edx=permission, ecx=clock id.
clock_now:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov rbx,rsi
 mov r13d,ecx
 test r12,r12
 jz .now_invalid
 mov rdi,rbx
 mov esi,edx
 call clock_capability_validate
 test eax,eax
 jnz .now_return
 sub rsp,16
 mov eax,NEBO_LINUX_X86_64_SYS_CLOCK_GETTIME
 mov edi,r13d
 mov rsi,rsp
 syscall
 cmp rax,-4095
 jae .now_syscall
 mov rax,[rsp]
 mov rdx,[rsp+8]
 add rsp,16
 test rax,rax
 js .now_invalid
 cmp rdx,NANOS_PER_SECOND
 jae .now_invalid
 mov [r12],rax
 mov [r12+8],rdx
 inc qword [rbx+NEBO_CLOCK_CAPABILITY_CALLS_USED]
 xor eax,eax
 jmp .now_return
.now_syscall:
 add rsp,16
 mov eax,NEBO_SYSTEM_ERROR_IO
 jmp .now_return
.now_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.now_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=capability, rsi=required permission. eax=status.
clock_capability_validate:
 test rdi,rdi
 jz .cap_denied
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_CLOCK
 cmp [rdi+NEBO_CLOCK_CAPABILITY_MAGIC],rax
 jne .cap_denied
 mov rax,[rdi+NEBO_CLOCK_CAPABILITY_PERMISSIONS]
 test rax,rsi
 jz .cap_denied
 mov rax,[rdi+NEBO_CLOCK_CAPABILITY_CALLS_USED]
 cmp rax,[rdi+NEBO_CLOCK_CAPABILITY_MAX_CALLS]
 jae .cap_limit
 xor eax,eax
 ret
.cap_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.cap_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=Duration. eax=status.
duration_validate:
 test rdi,rdi
 jz .duration_bad
 cmp qword [rdi],0
 jl .duration_bad
 cmp qword [rdi+8],0
 jl .duration_bad
 cmp qword [rdi+8],NANOS_PER_SECOND
 jae .duration_bad
 xor eax,eax
 ret
.duration_bad:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
