%ifndef NEBO_NUMERIC_PARALLEL_INC
%define NEBO_NUMERIC_PARALLEL_INC 1
%include "runtime/kernel/kernel_planner.inc"
%define NEBO_NUMERIC_CHUNK_ELEMENTS 256
%define NEBO_NUMERIC_ERROR_CANCELLED 10
%define NEBO_PARALLEL_PLAN_WORKERS 0
%define NEBO_PARALLEL_PLAN_CHUNKS 8
%define NEBO_PARALLEL_PLAN_CHUNK_SIZE 16
%define NEBO_PARALLEL_PLAN_LAST_CHUNK 24
%define NEBO_PARALLEL_PLAN_TRACE 32
%define NEBO_PARALLEL_PLAN_SIZE 40
%ifndef NEBO_NUMERIC_PARALLEL_IMPLEMENTATION
extern nebo_parallel_plan
extern nebo_parallel_add_f64
extern nebo_parallel_reduce_sum_f64
%endif
%endif
