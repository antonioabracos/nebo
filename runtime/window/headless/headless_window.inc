%ifndef NEBO_HEADLESS_WINDOW_INC
%define NEBO_HEADLESS_WINDOW_INC 1

%include "runtime/window/window_contract.inc"
%include "runtime/concurrency/task.inc"
%include "runtime/concurrency/cancel.inc"
%include "compiler/semantic/system/system_contract.inc"

; CONTROLO-DE-FLUXO-ESTRUTURADO-F04 deterministic headless Window runtime. The public maturity is
; bounded native. Source-language Window syntax is not activated by this file.
%define NEBO_HEADLESS_WINDOW_VERSION 1
%define NEBO_HEADLESS_RUNTIME_MAGIC 0x4e42574844313834

; Caller-owned runtime descriptor. Record storage contains one 192-byte F03
; Window record per slot and is never allocated by the runtime.
%define NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET 0
%define NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET 8
%define NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET 16
%define NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET 24
%define NEBO_HEADLESS_RUNTIME_WAKE_GENERATION_OFFSET 32
%define NEBO_HEADLESS_RUNTIME_WAITER_COUNT_OFFSET 40
%define NEBO_HEADLESS_RUNTIME_FLAGS_OFFSET 48
%define NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET 56
%define NEBO_HEADLESS_RUNTIME_SIZE 64
%define NEBO_HEADLESS_RUNTIME_QWORDS 8

; Caller-owned single-consumer stream descriptor.
%define NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET 0
%define NEBO_HEADLESS_STREAM_HANDLE_OFFSET 8
%define NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET 16
%define NEBO_HEADLESS_STREAM_GENERATION_OFFSET 24
%define NEBO_HEADLESS_STREAM_ACTIVE_OFFSET 32
%define NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET 40
%define NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET 48
%define NEBO_HEADLESS_STREAM_RESERVED_OFFSET 56
%define NEBO_HEADLESS_STREAM_SIZE 64
%define NEBO_HEADLESS_STREAM_QWORDS 8

; Internal Window record flags. Low four bits retain WindowOptions flags.
%define NEBO_HEADLESS_FLAG_ACCEPTING_EVENTS 0x00000100
%define NEBO_HEADLESS_FLAG_STREAM_BORROWED 0x00000200
%define NEBO_HEADLESS_FLAG_REDRAW_PENDING 0x00000400
%define NEBO_HEADLESS_FLAG_CLEANUP_DONE 0x00000800
%define NEBO_HEADLESS_FLAG_ACTIVE 0x00001000
%define NEBO_HEADLESS_INTERNAL_FLAGS 0x00001f00
%define NEBO_HEADLESS_KNOWN_RECORD_FLAGS (NEBO_WINDOW_OPTION_KNOWN_FLAGS | NEBO_HEADLESS_INTERNAL_FLAGS)

; Deterministic bounded waiting. Every retry blocks in FUTEX_WAIT_PRIVATE with
; a one-millisecond relative timeout. Zero retries is a nonblocking observation.
%define NEBO_HEADLESS_MAX_WAIT_CYCLES 4096
%define NEBO_HEADLESS_WAIT_SLICE_NS 1000000

; Backend-event injection origin used by the headless backend and tests. These
; values are not source-language API and never leak native pointers.
%define NEBO_HEADLESS_EVENT_ORIGIN_PROGRAM 0
%define NEBO_HEADLESS_EVENT_ORIGIN_BACKEND 1

; F04 active bounded-native operation identifiers. F03 reserves 1 through 9.
%define NEBO_HEADLESS_OP_POLL 10
%define NEBO_HEADLESS_OP_WAIT 11
%define NEBO_HEADLESS_OP_RELEASE 12
%define NEBO_HEADLESS_OP_RECLAIM 13
%define NEBO_HEADLESS_OP_PUSH_EVENT_INTERNAL 14
%define NEBO_HEADLESS_OP_COUNT 15

; Close-barrier reasons.
%define NEBO_HEADLESS_CLOSE_DIRECT 0
%define NEBO_HEADLESS_CLOSE_CANCELLED 1
%define NEBO_HEADLESS_CLOSE_BACKEND_FAILED 2
%define NEBO_HEADLESS_CLOSE_QUEUE_OVERFLOW 3

%ifndef NEBO_HEADLESS_WINDOW_IMPLEMENTATION
extern nebo_headless_runtime_init
extern nebo_headless_window_create
extern nebo_headless_window_show
extern nebo_headless_window_hide
extern nebo_headless_window_resize
extern nebo_headless_window_set_title
extern nebo_headless_window_request_redraw
extern nebo_headless_window_close
extern nebo_headless_window_events
extern nebo_headless_event_stream_poll
extern nebo_headless_event_stream_wait
extern nebo_headless_event_stream_release
extern nebo_headless_window_reclaim
extern nebo_headless_window_push_event
extern nebo_headless_window_event_kind
extern nebo_headless_window_event_key
extern nebo_headless_window_event_pointer
extern nebo_headless_window_event_text_input
extern nebo_headless_window_event_resize
extern nebo_headless_window_event_prevent_default
extern nebo_headless_window_backend_close
%endif

%endif
