%ifndef NEBO_DENSE_INC
%define NEBO_DENSE_INC 1
%define NEBO_DENSE_OK 0
%define NEBO_DENSE_E_ARGUMENT 1
%define NEBO_DENSE_E_LIMIT 2
%define NEBO_DENSE_E_NONFINITE 3
%define NEBO_DENSE_E_RANGE 4
%define NEBO_DENSE_E_OVERLAP 5
%ifndef NEBO_DENSE_IMPLEMENTATION
extern nebo_dense_linear
extern nebo_dense_relu
extern nebo_dense_gelu
extern nebo_dense_sigmoid
extern nebo_dense_tanh
extern nebo_dense_softmax
%endif
%endif
