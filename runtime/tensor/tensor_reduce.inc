%ifndef NEBO_TENSOR_REDUCE_INC
%define NEBO_TENSOR_REDUCE_INC 1
%include "compiler/semantic/tensor/tensor_contract.inc"
%define NEBO_REDUCE_SUM 1
%define NEBO_REDUCE_MEAN 2
%define NEBO_REDUCE_MIN 3
%define NEBO_REDUCE_MAX 4
%ifndef NEBO_TENSOR_REDUCE_IMPLEMENTATION
extern nebo_tensor_reduce_all_f64
extern nebo_tensor_argmax_all_f64
extern nebo_tensor_all_bool
extern nebo_tensor_any_bool
%endif
%endif
