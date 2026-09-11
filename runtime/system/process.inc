%ifndef NEBO_PROCESS_INC
%define NEBO_PROCESS_INC 1
%include "compiler/semantic/system/system_contract.inc"
%define NEBO_PROCESS_PID 0
%define NEBO_PROCESS_STATE 8
%define NEBO_PROCESS_CAPABILITY 16
%define NEBO_PROCESS_EXIT_STATUS 24
%define NEBO_PROCESS_FLAGS 32
%define NEBO_PROCESS_DEADLINE_NS 40
%define NEBO_PROCESS_RESERVED0 48
%define NEBO_PROCESS_RESERVED1 56
%define NEBO_PIPE_END_FD 0
%define NEBO_PIPE_END_STATE 8
%define NEBO_PIPE_END_CAPABILITY 16
%define NEBO_PIPE_END_FLAGS 24
%ifndef NEBO_PROCESS_IMPLEMENTATION
 extern nebo_process_capability_init
 extern nebo_process_current_pid
 extern nebo_process_pipe
 extern nebo_pipe_read
 extern nebo_pipe_write
 extern nebo_pipe_close
 extern nebo_process_spawn
 extern nebo_process_wait
 extern nebo_process_terminate
 extern nebo_environment_get
 extern nebo_environment_arguments
%endif
%endif
