%ifndef NEBO_GPU_FALLBACK_INC
%define NEBO_GPU_FALLBACK_INC 1
%define NEBO_GPU_FALLBACK_OK 0
%define NEBO_GPU_FALLBACK_E_ARGUMENT 1
%define NEBO_GPU_FALLBACK_E_UNSUPPORTED 2
%define NEBO_GPU_FALLBACK_E_LIMIT 3
%define NEBO_GPU_DEVICE_CPU 0
%define NEBO_GPU_DEVICE_GPU 1
%define NEBO_GPU_FALLBACK_MAX_BYTES 16777216
%ifndef NEBO_GPU_FALLBACK_IMPLEMENTATION
extern nebo_gpu_device_select
extern nebo_gpu_transfer_plan
extern nebo_gpu_fallback_to_cpu
extern nebo_gpu_pin
extern nebo_gpu_supported_on
%endif
%endif
