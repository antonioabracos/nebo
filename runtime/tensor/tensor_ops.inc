%ifndef NEBO_TENSOR_OPS_INC
%define NEBO_TENSOR_OPS_INC 1
%include "compiler/semantic/tensor/tensor_contract.inc"
%define NEBO_TENSOR_OP_ADD 1
%define NEBO_TENSOR_OP_SUB 2
%define NEBO_TENSOR_OP_MUL 3
%define NEBO_TENSOR_OP_DIV 4
%ifndef NEBO_TENSOR_OPS_IMPLEMENTATION
extern nebo_tensor_broadcast_view
extern nebo_tensor_binary_f64
extern nebo_tensor_clamp_f64
%endif
%endif
