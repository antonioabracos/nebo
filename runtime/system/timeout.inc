%ifndef NEBO_TIMEOUT_INC
%define NEBO_TIMEOUT_INC 1
%include "runtime/concurrency/cancel.inc"
%include "runtime/system/process.inc"
%define NEBO_POLL_READ 1
%define NEBO_POLL_WRITE 4
%ifndef NEBO_TIMEOUT_IMPLEMENTATION
extern nebo_fd_wait
extern nebo_socket_wait_readable
extern nebo_socket_wait_writable
extern nebo_process_wait_timeout
%endif
%endif
