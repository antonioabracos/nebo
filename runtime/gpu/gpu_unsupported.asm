bits 64
default rel
%define NEBO_GPU_UNSUPPORTED_IMPLEMENTATION 1
%include "runtime/gpu/gpu_unsupported.inc"
section .text
global nebo_gpu_enumerate
global nebo_gpu_backend_status
global nebo_gpu_context_create
global nebo_gpu_context_properties
global nebo_gpu_context_synchronize
global nebo_gpu_context_close
global nebo_gpu_buffer_create
global nebo_gpu_buffer_close
global nebo_gpu_copy_to_device
global nebo_gpu_copy_to_host
global nebo_gpu_tensor_transfer
global nebo_gpu_pin_host

; rdi=count*. Zero-device enumeration is a successful factual observation.
nebo_gpu_enumerate:
 test rdi,rdi
 jz .argument
 mov qword [rdi],0
 xor eax,eax
 ret
.argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

; rdi=Report32: backend,devices,state,error.
nebo_gpu_backend_status:
 test rdi,rdi
 jz .status_argument
 mov qword [rdi],NEBO_GPU_BACKEND_NONE
 mov qword [rdi+8],0
 mov qword [rdi+16],NEBO_GPU_STATE_UNAVAILABLE
 mov qword [rdi+24],NEBO_GPU_E_BACKEND_UNSUPPORTED
 xor eax,eax
 ret
.status_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

; All context operations reject before reading or publishing caller state.
nebo_gpu_context_create:
 test rsi,rsi
 jz .create_argument
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret
.create_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

nebo_gpu_context_properties:
 test rsi,rsi
 jz .properties_argument
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret
.properties_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

nebo_gpu_context_synchronize:
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret

nebo_gpu_context_close:
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret

; Memory/transfer operations reject before allocation, copy or output publish.
nebo_gpu_buffer_create:
 test rdx,rdx
 jz .buffer_create_argument
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret
.buffer_create_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

nebo_gpu_buffer_close:
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret

nebo_gpu_copy_to_device:
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret

nebo_gpu_copy_to_host:
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret

nebo_gpu_tensor_transfer:
 test rcx,rcx
 jz .tensor_argument
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret
.tensor_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret

nebo_gpu_pin_host:
 test rdx,rdx
 jz .pin_argument
 mov eax,NEBO_GPU_E_BACKEND_UNSUPPORTED
 ret
.pin_argument:
 mov eax,NEBO_GPU_E_ARGUMENT
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
