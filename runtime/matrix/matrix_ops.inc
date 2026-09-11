%ifndef NEBO_MATRIX_OPS_INC
%define NEBO_MATRIX_OPS_INC 1
%include "compiler/semantic/matrix/matrix_contract.inc"
%define NEBO_MATRIX_OP_ADD 1
%define NEBO_MATRIX_OP_SUB 2
%define NEBO_MATRIX_OP_MUL 3
%define NEBO_MATRIX_OP_DIV 4
%define NEBO_MATRIX_REDUCE_SUM 1
%define NEBO_MATRIX_REDUCE_MEAN 2
%define NEBO_MATRIX_REDUCE_MIN 3
%define NEBO_MATRIX_REDUCE_MAX 4
%ifndef NEBO_MATRIX_OPS_IMPLEMENTATION
extern nebo_matrix_elementwise_f64
extern nebo_matrix_scale_f64
extern nebo_matrix_clamp_f64
extern nebo_matrix_map_i64
extern nebo_matrix_map_f64
extern nebo_matrix_reduce_f64
extern nebo_matrix_reduce_axis_i64
extern nebo_matrix_reduce_axis_f64
%endif
%endif
