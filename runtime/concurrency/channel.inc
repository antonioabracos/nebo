%ifndef NEBO_CHANNEL_INC
%define NEBO_CHANNEL_INC 1
%include "compiler/semantic/concurrency/concurrency_contract.inc"
%define NEBO_CHANNEL_STATE 0
%define NEBO_CHANNEL_STORAGE 8
%define NEBO_CHANNEL_CAPACITY 16
%define NEBO_CHANNEL_HEAD 24
%define NEBO_CHANNEL_TAIL 32
%define NEBO_CHANNEL_COUNT 40
%define NEBO_CHANNEL_SENDERS 48
%define NEBO_CHANNEL_RECEIVERS 56
%define NEBO_CHANNEL_GENERATION 64
%define NEBO_CHANNEL_BUDGET 72
%define NEBO_CHANNEL_WAITERS 80
%define NEBO_CHANNEL_LOCK 88
%ifndef NEBO_CHANNEL_IMPLEMENTATION
extern nebo_channel_budget_init
extern nebo_channel_init
extern nebo_channel_try_send
extern nebo_channel_try_receive
extern nebo_channel_send
extern nebo_channel_receive
extern nebo_channel_close_sender
extern nebo_channel_close_receiver
%endif
%endif
