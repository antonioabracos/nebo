%ifndef NEBO_RANDOM_INC
%define NEBO_RANDOM_INC 1
%include "compiler/semantic/system/system_contract.inc"
%define NEBO_RANDOM_SIZE 32
%define NEBO_RANDOM_MAGIC 0
%define NEBO_RANDOM_STATE 8
%define NEBO_RANDOM_VERSION 16
%define NEBO_RANDOM_CALLS 24
%define NEBO_RANDOM_VERSION_SPLITMIX64_V1 1
%define NEBO_RANDOM_MAGIC_VALUE 0x4e42524e44313231
%ifndef NEBO_RANDOM_IMPLEMENTATION
 extern nebo_random_seed
 extern nebo_random_next_u64
 extern nebo_random_next_range
 extern nebo_random_float_unit
 extern nebo_entropy_capability_init
 extern nebo_random_fill_secure
 extern nebo_random_secure_bytes
%endif
%endif
