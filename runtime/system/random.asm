bits 64
default rel
%define NEBO_RANDOM_IMPLEMENTATION 1
%include "runtime/system/random.inc"
%define EINTR 4

section .text
global nebo_random_seed
global nebo_random_next_u64
global nebo_random_next_range
global nebo_random_float_unit
global nebo_entropy_capability_init
global nebo_random_fill_secure
global nebo_random_secure_bytes

; rdi=Random, rsi=seed. eax=status.
nebo_random_seed:
 test rdi,rdi
 jz .seed_invalid
 mov rax,NEBO_RANDOM_MAGIC_VALUE
 mov [rdi+NEBO_RANDOM_MAGIC],rax
 mov [rdi+NEBO_RANDOM_STATE],rsi
 mov qword [rdi+NEBO_RANDOM_VERSION],NEBO_RANDOM_VERSION_SPLITMIX64_V1
 mov qword [rdi+NEBO_RANDOM_CALLS],0
 xor eax,eax
 ret
.seed_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=Random. eax=status, rdx=value. SplitMix64 v1.
nebo_random_next_u64:
 test rdi,rdi
 jz .next_invalid
 mov rax,NEBO_RANDOM_MAGIC_VALUE
 cmp [rdi+NEBO_RANDOM_MAGIC],rax
 jne .next_invalid
 cmp qword [rdi+NEBO_RANDOM_VERSION],NEBO_RANDOM_VERSION_SPLITMIX64_V1
 jne .next_invalid
 mov rax,0x9e3779b97f4a7c15
 add [rdi+NEBO_RANDOM_STATE],rax
 mov rdx,[rdi+NEBO_RANDOM_STATE]
 mov rax,rdx
 shr rax,30
 xor rdx,rax
 mov rax,0xbf58476d1ce4e5b9
 imul rdx,rax
 mov rax,rdx
 shr rax,27
 xor rdx,rax
 mov rax,0x94d049bb133111eb
 imul rdx,rax
 mov rax,rdx
 shr rax,31
 xor rdx,rax
 inc qword [rdi+NEBO_RANDOM_CALLS]
 xor eax,eax
 ret
.next_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret

; rdi=Random, rsi=inclusive min, rdx=exclusive max. Nonnegative range.
; eax=status, rdx=value. Rejection sampling removes modulo bias.
nebo_random_next_range:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r13,r13
 js .range_invalid
 cmp r13,rbx
 jae .range_invalid
 sub rbx,r13
 xor eax,eax
 sub rax,rbx
 xor edx,edx
 div rbx
 mov r8,rdx
.range_retry:
 mov rdi,r12
 call nebo_random_next_u64
 test eax,eax
 jnz .range_return
 cmp rdx,r8
 jb .range_retry
 mov rax,rdx
 xor edx,edx
 div rbx
 add rdx,r13
 xor eax,eax
 jmp .range_return
.range_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
.range_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=Random. eax=status, rdx=IEEE-754 binary64 bits in [0,1).
; The upper 52 random bits form the mantissa of [1,2), then one is subtracted.
nebo_random_float_unit:
 call nebo_random_next_u64
 test eax,eax
 jnz .float_return
 shr rdx,12
 mov rax,0x3ff0000000000000
 or rdx,rax
 movq xmm0,rdx
 mov rax,0x3ff0000000000000
 movq xmm1,rax
 subsd xmm0,xmm1
 movq rdx,xmm0
.float_return:
 ret

; rdi=EntropyCapability, rsi=max cumulative bytes, rdx=max calls.
nebo_entropy_capability_init:
 test rdi,rdi
 jz .entropy_denied
 test rsi,rsi
 jz .entropy_limit
 cmp rsi,NEBO_ENTROPY_MAX_BYTES
 ja .entropy_limit
 test rdx,rdx
 jz .entropy_limit
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_ENTROPY
 mov [rdi+NEBO_ENTROPY_CAPABILITY_MAGIC],rax
 mov qword [rdi+NEBO_ENTROPY_CAPABILITY_PERMISSIONS],NEBO_ENTROPY_CAP_SECURE
 mov [rdi+NEBO_ENTROPY_CAPABILITY_MAX_BYTES],rsi
 mov [rdi+NEBO_ENTROPY_CAPABILITY_MAX_CALLS],rdx
 mov qword [rdi+NEBO_ENTROPY_CAPABILITY_BYTES_USED],0
 mov qword [rdi+NEBO_ENTROPY_CAPABILITY_GENERATION],0
 xor eax,eax
 ret
.entropy_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.entropy_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=buffer, rsi=length, rdx=EntropyCapability. eax=status, rdx=count.
; A partial failing fill zeroes its written prefix before returning.
nebo_random_fill_secure:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .fill_invalid
 test r13,r13
 jz .fill_zero
 test r14,r14
 jz .fill_denied
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_ENTROPY
 cmp [r14+NEBO_ENTROPY_CAPABILITY_MAGIC],rax
 jne .fill_denied
 test qword [r14+NEBO_ENTROPY_CAPABILITY_PERMISSIONS],NEBO_ENTROPY_CAP_SECURE
 jz .fill_denied
 mov rax,[r14+NEBO_ENTROPY_CAPABILITY_BYTES_USED]
 add rax,r13
 jc .fill_limit
 cmp rax,[r14+NEBO_ENTROPY_CAPABILITY_MAX_BYTES]
 ja .fill_limit
 mov rax,[r14+NEBO_ENTROPY_CAPABILITY_MAX_CALLS]
 cmp qword [r14+NEBO_ENTROPY_CAPABILITY_GENERATION],rax
 jae .fill_limit
 xor ebx,ebx
.fill_loop:
 cmp rbx,r13
 jae .fill_success
.fill_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_GETRANDOM
 lea rdi,[r12+rbx]
 mov rsi,r13
 sub rsi,rbx
 xor edx,edx
 syscall
 cmp rax,-EINTR
 je .fill_retry
 cmp rax,-4095
 jae .fill_failure
 test rax,rax
 jz .fill_failure
 add rbx,rax
 jmp .fill_loop
.fill_success:
 add [r14+NEBO_ENTROPY_CAPABILITY_BYTES_USED],r13
 inc qword [r14+NEBO_ENTROPY_CAPABILITY_GENERATION]
 mov rdx,r13
 xor eax,eax
 jmp .fill_return
.fill_failure:
 xor ecx,ecx
.zero_prefix:
 cmp rcx,rbx
 jae .zero_done
 mov byte [r12+rcx],0
 inc rcx
 jmp .zero_prefix
.zero_done:
 mov eax,NEBO_SYSTEM_ERROR_IO
 xor edx,edx
 jmp .fill_return
.fill_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .fill_return
.fill_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 xor edx,edx
 jmp .fill_return
.fill_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 jmp .fill_return
.fill_zero:
 xor eax,eax
 xor edx,edx
.fill_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; SecureRandom.bytes uses caller-owned storage in the no-allocator core.
; This exact alias preserves the secure fill's budgets and failure atomicity.
nebo_random_secure_bytes:
 jmp nebo_random_fill_secure
