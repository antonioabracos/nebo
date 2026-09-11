; G084 bounded RF84 integration and closeout ABI.
%ifndef NEBO_G084_CLOSEOUT_INC
%define NEBO_G084_CLOSEOUT_INC 1

%define G084_OK 0
%define G084_INVALID 1
%define G084_LIMIT 2
%define G084_CAPACITY 3
%define G084_CONSOLE_DATA 8
%define G084_UNSUPPORTED 9
%define G084_SUBGROUPS 10

%ifndef NEBO_G084_CLOSEOUT_IMPLEMENTATION
extern nebo_g084_source_probe
extern nebo_g084_negative_probe
extern nebo_g084_render_transcript
%endif

%endif
