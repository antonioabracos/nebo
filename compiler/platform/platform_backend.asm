; PLATFORM-BACKEND-F05 bounded Linux x86_64 syscall platform capability descriptor.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/target/target_registry.inc"
%include "compiler/platform/platform_backend.inc"
section .text
NEBOC_ABI_FUNCTION neboc_platform_backend_for_target
 ; rdi=backend rsi=target descriptor rdx=requested capabilities.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_TARGET_TRIPLE_OFFSET],1
 jne .unsupported
 cmp qword [rsi+NEBOC_TARGET_SYSCALL_OFFSET],1
 jne .unsupported
 mov rax,rdx
 not rax
 and rax,[rsi+NEBOC_TARGET_CAPABILITIES_OFFSET]
 ; Descriptor can expose more than requested; requested must be a subset.
 mov rax,rdx
 mov rcx,[rsi+NEBOC_TARGET_CAPABILITIES_OFFSET]
 not rcx
 and rax,rcx
 jnz .unsupported
 mov [rdi+NEBOC_PLATFORM_TARGET_OFFSET],rsi
 mov [rdi+NEBOC_PLATFORM_REQUESTED_OFFSET],rdx
 mov rax,[rsi+NEBOC_TARGET_CAPABILITIES_OFFSET]
 mov [rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET],rax
 mov rax,[rsi+NEBOC_TARGET_SYSCALL_OFFSET]
 mov [rdi+NEBOC_PLATFORM_SYSCALL_OFFSET],rax
 mov qword [rdi+NEBOC_PLATFORM_MATURITY_OFFSET],2
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%macro PLATFORM_CAPABILITY 3
NEBOC_ABI_FUNCTION %1
 test rdi,rdi
 jz %%invalid
 test rsi,rsi
 jz %%invalid
 test qword [rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET],%2
 jz %%unsupported
 mov qword [rsi],%3
 xor eax,eax
 ret
%%unsupported:
 mov qword [rsi],0
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
%%invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
%endmacro
PLATFORM_CAPABILITY neboc_platform_filesystem,NEBOC_PLATFORM_FS,1
PLATFORM_CAPABILITY neboc_platform_network,NEBOC_PLATFORM_NETWORK,2
PLATFORM_CAPABILITY neboc_platform_process,NEBOC_PLATFORM_PROCESS,3
PLATFORM_CAPABILITY neboc_platform_time,NEBOC_PLATFORM_TIME,4
PLATFORM_CAPABILITY neboc_platform_random,NEBOC_PLATFORM_RANDOM,5
PLATFORM_CAPABILITY neboc_platform_threads,NEBOC_PLATFORM_THREADS,6
PLATFORM_CAPABILITY neboc_platform_window,NEBOC_PLATFORM_WINDOW,7
NEBOC_ABI_FUNCTION neboc_platform_error_map
 ; rsi=native errno, rdx=out{portable,raw}; raw is preserved.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov [rdx+8],rsi
 mov rax,rsi
 cmp rax,1
 jae .bounded
 mov rax,1
.bounded:
 cmp rax,4095
 jbe .write
 mov rax,4095
.write:
 mov [rdx],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_platform_resource_limits
 ; out={handles,paths,sockets,threads,windows,stack_bytes}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov qword [rsi],1024
 mov qword [rsi+8],4096
 mov qword [rsi+16],256
 mov qword [rsi+24],64
 mov qword [rsi+32],0
 mov qword [rsi+40],8388608
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_platform_self_test
 ; Descriptor-only conformance plus live native process execution by the harness.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_PLATFORM_REQUESTED_OFFSET]
 mov rdx,[rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET]
 not rdx
 and rax,rdx
 jnz .unsupported
 mov qword [rsi],2
 mov rax,[rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET]
 mov [rsi+8],rax
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBOC_STATUS_UNSUPPORTED_TARGET
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
NEBOC_ABI_FUNCTION neboc_cli_platform_report
 ; out={target_token,requested,available,syscall,maturity,unavailable}.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rdx,[rdi+NEBOC_PLATFORM_TARGET_OFFSET]
 mov rax,[rdx+NEBOC_TARGET_TRIPLE_OFFSET]
 mov [rsi],rax
 mov rax,[rdi+NEBOC_PLATFORM_REQUESTED_OFFSET]
 mov [rsi+8],rax
 mov rax,[rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET]
 mov [rsi+16],rax
 mov rax,[rdi+NEBOC_PLATFORM_SYSCALL_OFFSET]
 mov [rsi+24],rax
 mov rax,[rdi+NEBOC_PLATFORM_MATURITY_OFFSET]
 mov [rsi+32],rax
 mov rax,[rdi+NEBOC_PLATFORM_REQUESTED_OFFSET]
 not rax
 mov rdx,[rdi+NEBOC_PLATFORM_AVAILABLE_OFFSET]
 not rdx
 and rax,rdx
 mov [rsi+40],rax
 xor eax,eax
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
