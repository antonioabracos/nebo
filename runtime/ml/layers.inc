%ifndef NEBO_LAYERS_INC
%define NEBO_LAYERS_INC 1
%define NEBO_LAYER_OK 0
%define NEBO_LAYER_E_ARGUMENT 1
%define NEBO_LAYER_E_LIMIT 2
%define NEBO_LAYER_E_NONFINITE 3
%define NEBO_LAYER_E_EPSILON 4
%define NEBO_LAYER_E_TRAINING 5
%define NEBO_LAYER_E_INDEX 6
%define NEBO_LAYER_E_OVERLAP 7
%ifndef NEBO_LAYERS_IMPLEMENTATION
extern nebo_layer_sequential_relu
extern nebo_layer_norm
extern nebo_layer_batch_norm_eval
extern nebo_layer_dropout_eval
extern nebo_layer_residual
extern nebo_layer_flatten
extern nebo_layer_embedding
%endif
%endif
