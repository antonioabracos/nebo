%ifndef NEBO_AVX2_KERNELS_INC
%define NEBO_AVX2_KERNELS_INC 1
%include "runtime/kernel/sse2_kernels.inc"
%include "compiler/semantic/cpu/cpu_contract.inc"
%define NEBO_KERNEL_SCALAR 0
%define NEBO_KERNEL_SSE2 1
%define NEBO_KERNEL_AVX2 2
%ifndef NEBO_AVX2_KERNELS_IMPLEMENTATION
extern nebo_avx2_select_safe
extern nebo_avx2_add_f64
extern nebo_avx2_dot_f64
extern nebo_avx2_reduce_sum_f64
extern nebo_avx2_relu_f64
%endif
%endif
