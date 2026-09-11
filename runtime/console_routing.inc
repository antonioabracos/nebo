%ifndef NEBO_G107_CONSOLE_ROUTING_INC
%define NEBO_G107_CONSOLE_ROUTING_INC 1

%include "runtime/textual/render_console.inc"
%include "runtime/filesystem/text.inc"

extern neboc_render_target_token_validate
extern neboc_render_policy_token_validate

; Caller-owned immutable route plan.
%define NEBO_G107_PLAN_MAGIC             0
%define NEBO_G107_PLAN_REQUESTED         8
%define NEBO_G107_PLAN_AVAILABLE         16
%define NEBO_G107_PLAN_EFFECTIVE         24
%define NEBO_G107_PLAN_REQUIRED_CAPS     32
%define NEBO_G107_PLAN_PROVIDED_CAPS     40
%define NEBO_G107_PLAN_FALLBACK          48
%define NEBO_G107_PLAN_FILE_MODE         56
%define NEBO_G107_PLAN_GENERATION        64
%define NEBO_G107_PLAN_FALLBACK_USED     72
%define NEBO_G107_PLAN_DIGEST            80
%define NEBO_G107_PLAN_QWORDS            11
%define NEBO_G107_PLAN_SIZE              88
%define NEBO_G107_PLAN_MAGIC_VALUE       0x4e4247313037504c

; Caller-owned publication record. Payload bytes remain owned by the caller.
%define NEBO_G107_RESULT_MAGIC           0
%define NEBO_G107_RESULT_COMMITTED       8
%define NEBO_G107_RESULT_TOTAL_BYTES     16
%define NEBO_G107_RESULT_PAYLOAD_DIGEST  24
%define NEBO_G107_RESULT_STDOUT_BYTES    32
%define NEBO_G107_RESULT_STDERR_BYTES    40
%define NEBO_G107_RESULT_FILE_BYTES      48
%define NEBO_G107_RESULT_ANSI_BYTES      56
%define NEBO_G107_RESULT_VISUAL_BYTES    64
%define NEBO_G107_RESULT_PANEL_BYTES     72
%define NEBO_G107_RESULT_FALLBACK_USED   80
%define NEBO_G107_RESULT_RECEIVER_EVALS  88
%define NEBO_G107_RESULT_GENERATION      96
%define NEBO_G107_RESULT_CLOSED          104
%define NEBO_G107_RESULT_STATUS          112
%define NEBO_G107_RESULT_PLAN_DIGEST     120
%define NEBO_G107_RESULT_QWORDS          16
%define NEBO_G107_RESULT_SIZE            128
%define NEBO_G107_RESULT_MAGIC_VALUE     0x4e42473130375253

%define NEBO_G107_SINK_STDOUT            0x01
%define NEBO_G107_SINK_STDERR            0x02
%define NEBO_G107_SINK_FILE              0x04
%define NEBO_G107_SINK_ANSI              0x08
%define NEBO_G107_SINK_VISUAL            0x10
%define NEBO_G107_SINK_PANEL             0x20
%define NEBO_G107_SINK_ALL               0x3f

%define NEBO_G107_CAP_PLAIN              0x01
%define NEBO_G107_CAP_ANSI               0x02
%define NEBO_G107_CAP_FILE               0x04
%define NEBO_G107_CAP_VISUAL             0x08
%define NEBO_G107_CAP_PANEL              0x10
%define NEBO_G107_CAP_ATOMIC             0x20
%define NEBO_G107_CAP_ALL                0x3f

%define NEBO_G107_FALLBACK_NONE          0
%define NEBO_G107_FALLBACK_TEXT          1
%define NEBO_G107_FALLBACK_TABLE         2
%define NEBO_G107_FALLBACK_SUMMARY       3
%define NEBO_G107_FALLBACK_DETECT_TARGET 4
%define NEBO_G107_FALLBACK_MAX           4

%define NEBO_G107_FILE_OVERWRITE         NEBO_TEXT_WRITE_TRUNCATE
%define NEBO_G107_FILE_APPEND            NEBO_TEXT_WRITE_APPEND
%define NEBO_G107_FILE_ATOMIC            NEBO_TEXT_WRITE_ATOMIC
%define NEBO_G107_FILE_MODE_MAX          NEBO_G107_FILE_ATOMIC

%define NEBO_G107_ERROR_INVALID          1
%define NEBO_G107_ERROR_CAPABILITY       2
%define NEBO_G107_ERROR_TARGET           3
%define NEBO_G107_ERROR_LIMIT            4
%define NEBO_G107_ERROR_STATE            5
%define NEBO_G107_ERROR_FILESYSTEM       6

%define NEBO_G107_MAX_PAYLOAD            4096
%define NEBO_G107_MATURITY_PUBLIC_CONSOLE_ROUTING_GREEN 2

%ifndef NEBO_G107_CONSOLE_ROUTING_IMPLEMENTATION
extern nebo_g107_route_plan_init
extern nebo_g107_route_plan_validate
extern nebo_g107_route_execute
extern nebo_g107_route_close
extern nebo_g107_file_publish
extern nebo_g107_status_diagnostic
%endif

%endif
