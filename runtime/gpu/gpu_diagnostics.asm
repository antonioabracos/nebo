bits 64
default rel
%define NEBO_GPU_DIAGNOSTICS_IMPLEMENTATION 1
%include "runtime/gpu/gpu_diagnostics.inc"
section .text
global nebo_gpu_error_report
global nebo_gpu_profile_begin
global nebo_gpu_profile_read
global nebo_gpu_memory_budget
global nebo_gpu_failure_inject

; rdi=operation id, rsi=Report48 {domain,code,operation,backend,device_bytes,trace_bytes}.
nebo_gpu_error_report:
 test rsi,rsi
 jz .argument
 mov qword [rsi],NEBO_GPU_DIAG_DOMAIN
 mov qword [rsi+8],NEBO_GPU_DIAG_E_UNSUPPORTED
 mov [rsi+16],rdi
 mov qword [rsi+24],NEBO_GPU_DIAG_BACKEND_NONE
 mov qword [rsi+32],0
 mov qword [rsi+40],0
 xor eax,eax
 ret
.argument:
 mov eax,NEBO_GPU_DIAG_E_ARGUMENT
 ret

; All unavailable backend operations validate the required output pointer and
; then refuse without publishing handles, counters, budgets or injected state.
nebo_gpu_profile_begin:
 test rdi,rdi
 jz gpu_diag_unsupported_argument
 mov eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 ret
nebo_gpu_profile_read:
 test rsi,rsi
 jz gpu_diag_unsupported_argument
 mov eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 ret
nebo_gpu_memory_budget:
 test rdi,rdi
 jz gpu_diag_unsupported_argument
 mov eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 ret
nebo_gpu_failure_inject:
 test rsi,rsi
 jz gpu_diag_unsupported_argument
 mov eax,NEBO_GPU_DIAG_E_UNSUPPORTED
 ret
gpu_diag_unsupported_argument:
 mov eax,NEBO_GPU_DIAG_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
