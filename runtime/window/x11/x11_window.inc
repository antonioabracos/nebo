%ifndef NEBO_X11_WINDOW_INC
%define NEBO_X11_WINDOW_INC 1

%include "runtime/window/headless/headless_window.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

; CONTROLO-DE-FLUXO-ESTRUTURADO-F05 bounded direct-X11 Window backend. The runtime is caller-owned,
; uses the repository's direct AF_UNIX/X11 protocol adapter, and does not make
; Window source syntax public. The first 64 bytes embed the F04 headless runtime
; so the same pointer is valid for all canonical Window operations.
%define NEBO_X11_WINDOW_VERSION 1
%define NEBO_X11_RUNTIME_MAGIC 0x4e42575831384635

%define NEBO_X11_RUNTIME_HEADLESS_OFFSET 0
%define NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET 64
%define NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET 72
%define NEBO_X11_RUNTIME_CAPACITY_OFFSET 80
%define NEBO_X11_RUNTIME_FLAGS_OFFSET 88
%define NEBO_X11_RUNTIME_LAST_STATUS_OFFSET 96
%define NEBO_X11_RUNTIME_LAST_ERROR_OFFSET 104
%define NEBO_X11_RUNTIME_RAW_EVENT_OFFSET 112
%define NEBO_X11_RUNTIME_PLATFORM_EVENT_OFFSET 144
%define NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET 208
%define NEBO_X11_RUNTIME_MAGIC_OFFSET 272
%define NEBO_X11_RUNTIME_SIZE 280
%define NEBO_X11_RUNTIME_QWORDS 35

%define NEBO_X11_RUNTIME_FLAG_READY 1
%define NEBO_X11_RUNTIME_FLAG_LIVE 2
%define NEBO_X11_RUNTIME_FLAG_DISCONNECTED 4
%define NEBO_X11_RUNTIME_KNOWN_FLAGS 7

%define NEBO_X11_WAIT_MAX_CYCLES 4096
%define NEBO_X11_WAIT_SLICE_MS 1

; F05 native operation identifiers. They are evidence/registry identifiers and
; do not activate .no syntax.
%define NEBO_X11_OP_RUNTIME_INIT 1
%define NEBO_X11_OP_RUNTIME_SHUTDOWN 2
%define NEBO_X11_OP_CREATE 3
%define NEBO_X11_OP_SHOW 4
%define NEBO_X11_OP_HIDE 5
%define NEBO_X11_OP_RESIZE 6
%define NEBO_X11_OP_SET_TITLE 7
%define NEBO_X11_OP_REQUEST_REDRAW 8
%define NEBO_X11_OP_CLOSE 9
%define NEBO_X11_OP_EVENTS 10
%define NEBO_X11_OP_POLL 11
%define NEBO_X11_OP_WAIT 12
%define NEBO_X11_OP_RELEASE 13
%define NEBO_X11_OP_RECLAIM 14
%define NEBO_X11_OP_KIND 15
%define NEBO_X11_OP_KEY 16
%define NEBO_X11_OP_POINTER 17
%define NEBO_X11_OP_TEXT_INPUT 18
%define NEBO_X11_OP_EVENT_RESIZE 19
%define NEBO_X11_OP_PREVENT_DEFAULT 20
%define NEBO_X11_OP_PUMP_INTERNAL 21
%define NEBO_X11_OP_TRANSLATE_INTERNAL 22
%define NEBO_X11_OP_COUNT 23

; Stable F05 diagnostic IDs map to the F03 WindowError space at the native ABI.
%define NEBO_X11_DIAG_DISPLAY_UNAVAILABLE 1
%define NEBO_X11_DIAG_AUTH_FAILURE 2
%define NEBO_X11_DIAG_PROTOCOL_MALFORMED 3
%define NEBO_X11_DIAG_DISCONNECTED 4
%define NEBO_X11_DIAG_UNKNOWN_XID 5
%define NEBO_X11_DIAG_LIFECYCLE_TIMEOUT 6
%define NEBO_X11_DIAG_STORAGE_OVERLAP 7
%define NEBO_X11_DIAG_QUEUE_OVERFLOW 8
%define NEBO_X11_DIAG_OWNER_MISMATCH 9
%define NEBO_X11_DIAG_STALE_HANDLE 10
%define NEBO_X11_DIAG_TITLE_INVALID 11
%define NEBO_X11_DIAG_BACKEND_FAILURE 12
%define NEBO_X11_DIAG_COUNT 13

%ifndef NEBO_X11_WINDOW_IMPLEMENTATION
extern nebo_x11_runtime_init
extern nebo_x11_runtime_shutdown
extern nebo_x11_window_create
extern nebo_x11_window_show
extern nebo_x11_window_hide
extern nebo_x11_window_resize
extern nebo_x11_window_set_title
extern nebo_x11_window_request_redraw
extern nebo_x11_window_close
extern nebo_x11_window_events
extern nebo_x11_event_stream_poll
extern nebo_x11_event_stream_wait
extern nebo_x11_event_stream_release
extern nebo_x11_window_reclaim
extern nebo_x11_window_pump_once
extern nebo_x11_window_translate_raw
extern nebo_x11_window_event_kind
extern nebo_x11_window_event_key
extern nebo_x11_window_event_pointer
extern nebo_x11_window_event_text_input
extern nebo_x11_window_event_resize
extern nebo_x11_window_event_prevent_default
%endif

%endif
