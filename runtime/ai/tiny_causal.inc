%ifndef NEBO_TINY_CAUSAL_INC
%define NEBO_TINY_CAUSAL_INC 1
%define NEBO_CAUSAL_OK 0
%define NEBO_CAUSAL_E_ARGUMENT 1
%define NEBO_CAUSAL_E_LIMIT 2
%define NEBO_CAUSAL_E_TOKEN 3
%define NEBO_CAUSAL_VOCAB 16
%define NEBO_CAUSAL_DIM 8
%define NEBO_CAUSAL_CONTEXT 32
%ifndef NEBO_TINY_CAUSAL_IMPLEMENTATION
extern nebo_causal_forward
extern nebo_kv_init
extern nebo_kv_append
extern nebo_kv_length
extern nebo_kv_truncate
extern nebo_causal_context_length
%endif
%endif
