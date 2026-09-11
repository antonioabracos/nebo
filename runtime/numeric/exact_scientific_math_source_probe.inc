%ifndef NEBO_G035_SOURCE_PROBE_INC
%define NEBO_G035_SOURCE_PROBE_INC 1

G035_STATUS_OK equ 0
G035_STATUS_INVALID equ 1
G035_STATUS_LIMIT equ 2
G035_STATUS_OVERFLOW equ 3
G035_STATUS_DIGIT equ 4

%ifndef NEBO_G035_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g035_source_probe
 extern nebo_g035_bigint_parse_i64
 extern nebo_g035_exact_sub_i64
%endif
%endif
