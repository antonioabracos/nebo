%ifndef NEBO_SCALAR_KERNELS_INC
%define NEBO_SCALAR_KERNELS_INC 1
%include "compiler/semantic/numeric/numeric_contract.inc"
%define NEBO_KERNEL_ADD_F64 1
%define NEBO_KERNEL_DOT_F64 2
%define NEBO_KERNEL_REDUCE_SUM_F64 3
%define NEBO_KERNEL_RELU_F64 4
%define NEBO_KERNEL_I64_TO_F64 5
%define NEBO_KERNEL_MATMUL_F64 6
%ifndef NEBO_SCALAR_KERNELS_IMPLEMENTATION
extern nebo_kernel_resolve_scalar
extern nebo_scalar_add_f64
extern nebo_scalar_dot_f64
extern nebo_scalar_reduce_sum_f64
extern nebo_scalar_relu_f64
extern nebo_scalar_i64_to_f64
extern nebo_scalar_matmul_f64
%endif
%endif
