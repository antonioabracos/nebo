%ifndef NEBO_THREAD_INC
%define NEBO_THREAD_INC 1
%include "compiler/semantic/concurrency/concurrency_contract.inc"

%define NEBO_THREAD_TID 0
%define NEBO_THREAD_STATE 8
%define NEBO_THREAD_BUDGET 16
%define NEBO_THREAD_RESULT 24
%define NEBO_THREAD_STACK 32
%define NEBO_THREAD_STACK_SIZE 40
%define NEBO_THREAD_CALLABLE 48
%define NEBO_THREAD_ARGUMENT 56

%ifndef NEBO_THREAD_IMPLEMENTATION
extern nebo_thread_budget_init
extern nebo_thread_spawn
extern nebo_thread_join
extern nebo_thread_current_id
extern nebo_thread_yield
%endif
%endif
