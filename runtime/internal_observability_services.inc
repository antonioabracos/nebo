%ifndef NEBO_G111_INTERNAL_OBSERVABILITY_SERVICES_INC
%define NEBO_G111_INTERNAL_OBSERVABILITY_SERVICES_INC 1

; Stable internal errors. These services are not public Nebo callables.
%define NEBO_G111_ERROR_INVALID       1
%define NEBO_G111_ERROR_RANGE         2
%define NEBO_G111_ERROR_STATE         3
%define NEBO_G111_ERROR_CAPABILITY    4
%define NEBO_G111_ERROR_LIMIT         5
%define NEBO_G111_ERROR_BUSY          6
%define NEBO_G111_ERROR_ORDER         7
%define NEBO_G111_ERROR_TERMINAL      8
%define NEBO_G111_ERROR_FORMAT        9
%define NEBO_G111_ERROR_DEPENDENCY   10

%define NEBO_G111_LOG_MAGIC          0x4e42473131314c47
%define NEBO_G111_PROGRESS_MAGIC     0x4e42473131315052
%define NEBO_G111_TIMELINE_MAGIC     0x4e4247313131544c

%define NEBO_G111_STATE_EMPTY        0
%define NEBO_G111_STATE_ACTIVE       1

%define NEBO_G111_LOG_TRACE          1
%define NEBO_G111_LOG_DEBUG          2
%define NEBO_G111_LOG_INFO           3
%define NEBO_G111_LOG_WARN           4
%define NEBO_G111_LOG_ERROR          5
%define NEBO_G111_LOG_LEVEL_MAX      5

%define NEBO_G111_PROGRESS_ACTIVE    1
%define NEBO_G111_PROGRESS_FINISHED  2
%define NEBO_G111_PROGRESS_FAILED    3
%define NEBO_G111_PROGRESS_CANCELLED 4

%define NEBO_G111_TIMELINE_EVENTS    1
%define NEBO_G111_TIMELINE_STREAM    2
%define NEBO_G111_TIMELINE_PARALLEL  3
%define NEBO_G111_TIMELINE_TRAINING  4

%define NEBO_G111_FORMAT_JSONL       1
%define NEBO_G111_FORMAT_TEXT        2
%define NEBO_G111_FORMAT_BINARY      3
%define NEBO_G111_FORMAT_MAX         3

%define NEBO_G111_MAX_LOG_RECORDS    64
%define NEBO_G111_MAX_LOG_BYTES      4096
%define NEBO_G111_MAX_TIMELINE_ITEMS 64

%define NEBO_G111_MATURITY_CONTRACT_GREEN                        1
%define NEBO_G111_MATURITY_INTERNAL_OBSERVABILITY_SERVICES_GREEN 2

; Caller-owned log state (136 bytes).
%define NEBO_G111_LOG_MAGIC_OFS       0
%define NEBO_G111_LOG_STATE           8
%define NEBO_G111_LOG_GROUP           16
%define NEBO_G111_LOG_TAG             24
%define NEBO_G111_LOG_BRANCH          32
%define NEBO_G111_LOG_MAX_RECORDS_OFS 40
%define NEBO_G111_LOG_MAX_BYTES_OFS   48
%define NEBO_G111_LOG_RECORDS         56
%define NEBO_G111_LOG_BYTES           64
%define NEBO_G111_LOG_TRACE_COUNT     72
%define NEBO_G111_LOG_DEBUG_COUNT     80
%define NEBO_G111_LOG_INFO_COUNT      88
%define NEBO_G111_LOG_WARN_COUNT      96
%define NEBO_G111_LOG_ERROR_COUNT     104
%define NEBO_G111_LOG_DIGEST          112
%define NEBO_G111_LOG_FLUSHES         120
%define NEBO_G111_LOG_GENERATION      128
%define NEBO_G111_LOG_SIZE            136
%define NEBO_G111_LOG_QWORDS          17

; Pointer-free log event receipt (64 bytes).
%define NEBO_G111_LOG_RECEIPT_SEQUENCE 0
%define NEBO_G111_LOG_RECEIPT_LEVEL    8
%define NEBO_G111_LOG_RECEIPT_GROUP    16
%define NEBO_G111_LOG_RECEIPT_TAG      24
%define NEBO_G111_LOG_RECEIPT_BRANCH   32
%define NEBO_G111_LOG_RECEIPT_MESSAGE  40
%define NEBO_G111_LOG_RECEIPT_BYTES    48
%define NEBO_G111_LOG_RECEIPT_DIGEST   56
%define NEBO_G111_LOG_RECEIPT_SIZE     64

; Pointer-free bounded flush receipt (48 bytes).
%define NEBO_G111_FLUSH_RECORDS        0
%define NEBO_G111_FLUSH_BYTES          8
%define NEBO_G111_FLUSH_DIGEST         16
%define NEBO_G111_FLUSH_COUNT          24
%define NEBO_G111_FLUSH_GENERATION     32
%define NEBO_G111_FLUSH_MATURITY       40
%define NEBO_G111_FLUSH_SIZE           48

; Caller-owned progress state (96 bytes).
%define NEBO_G111_PROGRESS_MAGIC_OFS   0
%define NEBO_G111_PROGRESS_STATE       8
%define NEBO_G111_PROGRESS_ID          16
%define NEBO_G111_PROGRESS_TOTAL       24
%define NEBO_G111_PROGRESS_CURRENT     32
%define NEBO_G111_PROGRESS_LABEL       40
%define NEBO_G111_PROGRESS_MESSAGE     48
%define NEBO_G111_PROGRESS_DIGEST      56
%define NEBO_G111_PROGRESS_GENERATION  64
%define NEBO_G111_PROGRESS_UPDATES     72
%define NEBO_G111_PROGRESS_TERMINALS   80
%define NEBO_G111_PROGRESS_PANEL_ID    88
%define NEBO_G111_PROGRESS_SIZE        96
%define NEBO_G111_PROGRESS_QWORDS      12

; Pointer-free progress snapshot (88 bytes).
%define NEBO_G111_PROGRESS_SNAPSHOT_ID          0
%define NEBO_G111_PROGRESS_SNAPSHOT_STATE       8
%define NEBO_G111_PROGRESS_SNAPSHOT_TOTAL       16
%define NEBO_G111_PROGRESS_SNAPSHOT_CURRENT     24
%define NEBO_G111_PROGRESS_SNAPSHOT_LABEL       32
%define NEBO_G111_PROGRESS_SNAPSHOT_MESSAGE     40
%define NEBO_G111_PROGRESS_SNAPSHOT_DIGEST      48
%define NEBO_G111_PROGRESS_SNAPSHOT_GENERATION  56
%define NEBO_G111_PROGRESS_SNAPSHOT_UPDATES     64
%define NEBO_G111_PROGRESS_SNAPSHOT_TERMINALS   72
%define NEBO_G111_PROGRESS_SNAPSHOT_MATURITY    80
%define NEBO_G111_PROGRESS_SNAPSHOT_SIZE        88

; Caller-owned timeline state (96 bytes).
%define NEBO_G111_TIMELINE_MAGIC_OFS          0
%define NEBO_G111_TIMELINE_STATE              8
%define NEBO_G111_TIMELINE_SOURCE             16
%define NEBO_G111_TIMELINE_EVENT_COUNT        24
%define NEBO_G111_TIMELINE_LIMIT              32
%define NEBO_G111_TIMELINE_WINDOW_START       40
%define NEBO_G111_TIMELINE_WINDOW_COUNT       48
%define NEBO_G111_TIMELINE_SOURCE_GENERATION  56
%define NEBO_G111_TIMELINE_DIGEST             64
%define NEBO_G111_TIMELINE_GENERATION         72
%define NEBO_G111_TIMELINE_EXPORT_FORMAT      80
%define NEBO_G111_TIMELINE_DEPENDENCY_STATUS  88
%define NEBO_G111_TIMELINE_SIZE               96
%define NEBO_G111_TIMELINE_QWORDS             12

; Pointer-free timeline export receipt (72 bytes).
%define NEBO_G111_TIMELINE_RECEIPT_SOURCE       0
%define NEBO_G111_TIMELINE_RECEIPT_TOTAL        8
%define NEBO_G111_TIMELINE_RECEIPT_LIMIT        16
%define NEBO_G111_TIMELINE_RECEIPT_WINDOW_START 24
%define NEBO_G111_TIMELINE_RECEIPT_WINDOW_COUNT 32
%define NEBO_G111_TIMELINE_RECEIPT_FORMAT       40
%define NEBO_G111_TIMELINE_RECEIPT_DIGEST       48
%define NEBO_G111_TIMELINE_RECEIPT_GENERATION   56
%define NEBO_G111_TIMELINE_RECEIPT_MATURITY     64
%define NEBO_G111_TIMELINE_RECEIPT_SIZE         72

; Historical generated-front compatibility only.
%define NEBO_INTERNAL_ERR_INVALID -22
%define NEBO_INTERNAL_ERR_BOUNDS  -75

%ifndef NEBO_G111_INTERNAL_OBSERVABILITY_IMPLEMENTATION
extern nebo_g111_log_group
extern nebo_g111_log_tag
extern nebo_g111_log_branch
extern nebo_g111_log_trace
extern nebo_g111_log_debug
extern nebo_g111_log_info
extern nebo_g111_log_warn
extern nebo_g111_log_error
extern nebo_g111_log_flush
extern nebo_g111_progress_create
extern nebo_g111_progress_update
extern nebo_g111_progress_increment
extern nebo_g111_progress_message
extern nebo_g111_progress_finish
extern nebo_g111_progress_fail
extern nebo_g111_progress_cancel
extern nebo_g111_progress_snapshot
extern nebo_g111_timeline_from_events
extern nebo_g111_timeline_from_stream
extern nebo_g111_timeline_from_parallel
extern nebo_g111_timeline_from_training
extern nebo_g111_timeline_limit
extern nebo_g111_timeline_window
extern nebo_g111_timeline_export
%endif

%endif
