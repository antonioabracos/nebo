%ifndef NEBO_TENSOR_CORE_INC
%define NEBO_TENSOR_CORE_INC 1
%include "compiler/semantic/tensor/tensor_contract.inc"
%ifndef NEBO_TENSOR_CORE_IMPLEMENTATION
extern nebo_tensor_zeros_f64
extern nebo_tensor_from_values_f64
extern nebo_tensor_rank
extern nebo_tensor_size
extern nebo_tensor_is_contiguous
%endif
%endif
