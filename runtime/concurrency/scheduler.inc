%ifndef NEBO_SCHEDULER_INC
%define NEBO_SCHEDULER_INC 1
%include "runtime/concurrency/task.inc"
%include "runtime/concurrency/thread.inc"
%define NEBO_SCHEDULER_STATE 0
%define NEBO_SCHEDULER_BUDGET 8
%define NEBO_SCHEDULER_QUEUE 16
%define NEBO_SCHEDULER_QUEUE_CAPACITY 24
%define NEBO_SCHEDULER_HEAD 32
%define NEBO_SCHEDULER_TAIL 40
%define NEBO_SCHEDULER_COUNT 48
%define NEBO_SCHEDULER_TRACE 56
%define NEBO_SCHEDULER_TRACE_CAPACITY 64
%define NEBO_SCHEDULER_TRACE_COUNT 72
%define NEBO_SCHEDULER_WORKERS 80
%define NEBO_SCHEDULER_GENERATION 88
%define NEBO_TRACE_SEQUENCE 0
%define NEBO_TRACE_EVENT 8
%define NEBO_TRACE_STATE 16
%define NEBO_TRACE_VALUE 24
%ifndef NEBO_SCHEDULER_IMPLEMENTATION
extern nebo_scheduler_init
extern nebo_scheduler_enqueue
extern nebo_scheduler_run
extern nebo_scheduler_queue_depth
extern nebo_scheduler_shutdown
extern nebo_scheduler_spawn_blocking
%endif
%endif
