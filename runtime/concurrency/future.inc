%ifndef NEBO_FUTURE_INC
%define NEBO_FUTURE_INC 1
%include "compiler/semantic/concurrency/concurrency_contract.inc"
%define NEBO_FUTURE_STATE 0
%define NEBO_FUTURE_VALUE 8
%define NEBO_FUTURE_ERROR 16
%define NEBO_FUTURE_POLLS 24
%define NEBO_FUTURE_MAX_POLLS 32
%define NEBO_FUTURE_WAKER 40
%define NEBO_FUTURE_WAKER_CONTEXT 48
%define NEBO_FUTURE_GENERATION 56
%ifndef NEBO_FUTURE_IMPLEMENTATION
extern nebo_future_init
extern nebo_future_set_waker
extern nebo_future_complete
extern nebo_future_poll
extern nebo_future_take
extern nebo_future_map
extern nebo_future_select
extern nebo_task_await
%endif
%endif
