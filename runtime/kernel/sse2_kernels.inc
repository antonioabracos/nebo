%ifndef NEBO_SSE2_KERNELS_INC
%define NEBO_SSE2_KERNELS_INC 1
%include "runtime/kernel/scalar_kernels.inc"
%ifndef NEBO_SSE2_KERNELS_IMPLEMENTATION
extern nebo_sse2_add_f64
extern nebo_sse2_dot_f64
extern nebo_sse2_reduce_sum_f64
extern nebo_sse2_i64_to_f64
%endif
%endif
