%ifndef NEBO_TASK_INC
%define NEBO_TASK_INC 1
%include "compiler/semantic/concurrency/concurrency_contract.inc"

%define NEBO_TASK_STATE 0
%define NEBO_TASK_RESULT 8
%define NEBO_TASK_ERROR 16
%define NEBO_TASK_CALLABLE 24
%define NEBO_TASK_ARGUMENT 32
%define NEBO_TASK_PARENT 40
%define NEBO_TASK_GENERATION 48
%define NEBO_TASK_RESERVED 56

%define NEBO_TASK_GROUP_BUDGET 0
%define NEBO_TASK_GROUP_STORAGE 8
%define NEBO_TASK_GROUP_CAPACITY 16
%define NEBO_TASK_GROUP_COUNT 24
%define NEBO_TASK_GROUP_STATE 32
%define NEBO_TASK_GROUP_ERROR_COUNT 40
%define NEBO_TASK_GROUP_JOINED 48
%define NEBO_TASK_GROUP_GENERATION 56

%ifndef NEBO_TASK_IMPLEMENTATION
extern nebo_scheduler_budget_init
extern nebo_task_group_init
extern nebo_task_group_spawn
extern nebo_task_group_join_all
extern nebo_task_result
%endif
%endif
