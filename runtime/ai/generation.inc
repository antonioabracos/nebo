%ifndef NEBO_GENERATION_INC
%define NEBO_GENERATION_INC 1
%define NEBO_GEN_OK 0
%define NEBO_GEN_E_ARGUMENT 1
%define NEBO_GEN_E_LIMIT 2
%define NEBO_GEN_E_CANCELLED 3
%define NEBO_GEN_MODE_GREEDY 0
%define NEBO_GEN_MODE_TEMPERATURE 1
%define NEBO_GEN_MODE_TOPK 2
%define NEBO_GEN_MODE_TOPP 3
%define NEBO_GEN_MODE_REPETITION 4
%define NEBO_GEN_MAX_TOKENS 64
%ifndef NEBO_GENERATION_IMPLEMENTATION
extern nebo_sample
extern nebo_generator_begin
extern nebo_generator_next
extern nebo_generator_cancel
%endif
%endif
