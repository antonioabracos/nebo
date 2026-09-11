%ifndef NEBO_G108_CONSOLE_TESTABILITY_INC
%define NEBO_G108_CONSOLE_TESTABILITY_INC 1

; Caller-owned deterministic test session. No pointer in this record is owned
; by the runtime and close only clears the embedded normalized capture.
%define NEBO_G108_SESSION_MAGIC          0
%define NEBO_G108_SESSION_TARGET         8
%define NEBO_G108_SESSION_SEED           16
%define NEBO_G108_SESSION_TIME           24
%define NEBO_G108_SESSION_CAPABILITIES   32
%define NEBO_G108_SESSION_FLAGS          40
%define NEBO_G108_SESSION_STATE          48
%define NEBO_G108_SESSION_LENGTH         56
%define NEBO_G108_SESSION_DIGEST         64
%define NEBO_G108_SESSION_ASSERTIONS     72
%define NEBO_G108_SESSION_RECEIVER_EVALS 80
%define NEBO_G108_SESSION_BUFFER         96
%define NEBO_G108_CAPTURE_MAX            512
%define NEBO_G108_SESSION_SIZE           608
%define NEBO_G108_SESSION_MAGIC_VALUE    0x4e42473130385345

; Structured capture input. Volatile fields are deliberately not copied into
; snapshots; only stable markers are emitted for path, time and secret fields.
%define NEBO_G108_INPUT_STABLE_PTR        0
%define NEBO_G108_INPUT_STABLE_LEN        8
%define NEBO_G108_INPUT_PATH_PTR          16
%define NEBO_G108_INPUT_PATH_LEN          24
%define NEBO_G108_INPUT_TIME_PTR          32
%define NEBO_G108_INPUT_TIME_LEN          40
%define NEBO_G108_INPUT_SECRET_PTR        48
%define NEBO_G108_INPUT_SECRET_LEN        56
%define NEBO_G108_INPUT_SIZE              64

; Versioned replay record. The payload is normalized inert data, never code.
%define NEBO_G108_RECORD_MAGIC            0
%define NEBO_G108_RECORD_SCHEMA           8
%define NEBO_G108_RECORD_VERSION          16
%define NEBO_G108_RECORD_TARGET           24
%define NEBO_G108_RECORD_SEED             32
%define NEBO_G108_RECORD_TIME             40
%define NEBO_G108_RECORD_PAYLOAD_LEN      48
%define NEBO_G108_RECORD_DIGEST           56
%define NEBO_G108_RECORD_FLAGS            64
%define NEBO_G108_RECORD_HEADER_SIZE      72
%define NEBO_G108_RECORD_MAX              584
%define NEBO_G108_RECORD_MAGIC_VALUE      0x4e42473130385243
%define NEBO_G108_RECORD_SCHEMA_VALUE     0x434f4e534f4c4531
%define NEBO_G108_RECORD_VERSION_VALUE    1

%define NEBO_G108_TARGET_MOCK             1
%define NEBO_G108_TARGET_HEADLESS         2
%define NEBO_G108_TARGET_LIVE             3
%define NEBO_G108_TARGET_MAX              3

%define NEBO_G108_CAP_CAPTURE             0x01
%define NEBO_G108_CAP_SNAPSHOT            0x02
%define NEBO_G108_CAP_REPLAY              0x04
%define NEBO_G108_CAP_ASSERT              0x08
%define NEBO_G108_CAP_DETERMINISTIC       0x10
%define NEBO_G108_CAP_LIVE                0x20
%define NEBO_G108_CAP_ALL                 0x3f
%define NEBO_G108_CAP_REQUIRED            0x1f

%define NEBO_G108_FLAG_NORMALIZE_NEWLINES 0x01
%define NEBO_G108_FLAG_REDACT_PATH        0x02
%define NEBO_G108_FLAG_REDACT_TIME        0x04
%define NEBO_G108_FLAG_REDACT_SECRET      0x08
%define NEBO_G108_FLAG_SILENT             0x10
%define NEBO_G108_FLAG_ALL                0x1f
%define NEBO_G108_FLAG_CANONICAL          0x0f

%define NEBO_G108_STATE_READY             1
%define NEBO_G108_STATE_CAPTURED          2
%define NEBO_G108_STATE_REPLAYED          3
%define NEBO_G108_STATE_CLOSED            4

%define NEBO_G108_ERROR_INVALID           1
%define NEBO_G108_ERROR_LIMIT             2
%define NEBO_G108_ERROR_CAPACITY          3
%define NEBO_G108_ERROR_SCHEMA            4
%define NEBO_G108_ERROR_DIGEST            5
%define NEBO_G108_ERROR_STATE             6
%define NEBO_G108_ERROR_CAPABILITY        7
%define NEBO_G108_ERROR_MISMATCH          8
%define NEBO_G108_ERROR_TARGET            9

%define NEBO_G108_MATURITY_DETERMINISTIC_REPLAY_GREEN 3

%ifndef NEBO_G108_CONSOLE_TESTABILITY_IMPLEMENTATION
extern nebo_g108_session_init
extern nebo_g108_normalize_output
extern nebo_g108_capture
extern nebo_g108_snapshot
extern nebo_g108_record_validate
extern nebo_g108_golden_compare
extern nebo_g108_replay
extern nebo_g108_assert_equals
extern nebo_g108_assert_contains
extern nebo_g108_target_classify
extern nebo_g108_session_close
extern nebo_g108_status_diagnostic
%endif

%endif
