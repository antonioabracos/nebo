bits 64
default rel
%define NEBO_GPU_FALLBACK_IMPLEMENTATION 1
%include "runtime/gpu/gpu_fallback.inc"
section .text
global nebo_gpu_device_select
global nebo_gpu_transfer_plan
global nebo_gpu_fallback_to_cpu
global nebo_gpu_pin
global nebo_gpu_supported_on

; rdi=requested device, rsi=selected device*. GPU selection is never implicit.
nebo_gpu_device_select:
 test rsi,rsi
 jz .argument
 cmp edi,NEBO_GPU_DEVICE_CPU
 je .select_cpu
 cmp edi,NEBO_GPU_DEVICE_GPU
 je .unsupported
 jmp .argument
.select_cpu:
 mov qword [rsi],NEBO_GPU_DEVICE_CPU
 xor eax,eax
 ret
.unsupported:
 mov eax,NEBO_GPU_FALLBACK_E_UNSUPPORTED
 ret
.argument:
 mov eax,NEBO_GPU_FALLBACK_E_ARGUMENT
 ret

; rdi=device, rsi=logical tensor bytes, rdx=Plan24 {device, transfers, device_bytes}.
nebo_gpu_transfer_plan:
 test rdx,rdx
 jz .plan_argument
 cmp edi,NEBO_GPU_DEVICE_GPU
 je .plan_unsupported
 cmp edi,NEBO_GPU_DEVICE_CPU
 jne .plan_argument
 cmp rsi,NEBO_GPU_FALLBACK_MAX_BYTES
 ja .plan_limit
 mov qword [rdx],NEBO_GPU_DEVICE_CPU
 mov qword [rdx+8],0
 mov qword [rdx+16],0
 xor eax,eax
 ret
.plan_unsupported:
 mov eax,NEBO_GPU_FALLBACK_E_UNSUPPORTED
 ret
.plan_limit:
 mov eax,NEBO_GPU_FALLBACK_E_LIMIT
 ret
.plan_argument:
 mov eax,NEBO_GPU_FALLBACK_E_ARGUMENT
 ret

; rdi=requested, rsi=Decision16 {selected, fallback_was_required}.
nebo_gpu_fallback_to_cpu:
 test rsi,rsi
 jz .fallback_argument
 cmp edi,NEBO_GPU_DEVICE_CPU
 je .fallback_cpu
 cmp edi,NEBO_GPU_DEVICE_GPU
 jne .fallback_argument
 mov qword [rsi],NEBO_GPU_DEVICE_CPU
 mov qword [rsi+8],1
 xor eax,eax
 ret
.fallback_cpu:
 mov qword [rsi],NEBO_GPU_DEVICE_CPU
 mov qword [rsi+8],0
 xor eax,eax
 ret
.fallback_argument:
 mov eax,NEBO_GPU_FALLBACK_E_ARGUMENT
 ret

; rdi=device, rsi=supported*. CPU pin is a no-op; GPU pin is refused atomically.
nebo_gpu_pin:
 test rsi,rsi
 jz .pin_argument
 cmp edi,NEBO_GPU_DEVICE_GPU
 je .pin_unsupported
 cmp edi,NEBO_GPU_DEVICE_CPU
 jne .pin_argument
 mov qword [rsi],0
 xor eax,eax
 ret
.pin_unsupported:
 mov eax,NEBO_GPU_FALLBACK_E_UNSUPPORTED
 ret
.pin_argument:
 mov eax,NEBO_GPU_FALLBACK_E_ARGUMENT
 ret

; rdi=device, rsi=bool*. This is a factual query and never selects a device.
nebo_gpu_supported_on:
 test rsi,rsi
 jz .supported_argument
 cmp edi,NEBO_GPU_DEVICE_CPU
 je .supported_cpu
 cmp edi,NEBO_GPU_DEVICE_GPU
 je .supported_gpu
 jmp .supported_argument
.supported_cpu:
 mov qword [rsi],1
 xor eax,eax
 ret
.supported_gpu:
 mov qword [rsi],0
 xor eax,eax
 ret
.supported_argument:
 mov eax,NEBO_GPU_FALLBACK_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
