%ifndef NEBO_CONV_INC
%define NEBO_CONV_INC 1
%define NEBO_CONV_OK 0
%define NEBO_CONV_E_ARGUMENT 1
%define NEBO_CONV_E_LIMIT 2
%define NEBO_CONV_E_SHAPE 3
%define NEBO_CONV_E_NONFINITE 4
%define NEBO_CONV_E_OVERLAP 5
%ifndef NEBO_CONV_IMPLEMENTATION
extern nebo_conv1d
extern nebo_conv2d
extern nebo_max_pool2d
extern nebo_avg_pool2d
extern nebo_global_avg_pool2d
extern nebo_padding2d
%endif
%endif
