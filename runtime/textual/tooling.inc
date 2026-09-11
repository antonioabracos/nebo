; G083 bounded native source-to-effect tooling ABI.
%ifndef NEBO_G083_TOOLING_INC
%define NEBO_G083_TOOLING_INC 1

%define G083_OK 0
%define G083_INVALID 1
%define G083_LIMIT 2
%define G083_SYNTAX 4
%define G083_UNSUPPORTED 6

%define G083_MAX_PATTERN 256
%define G083_MAX_TEXT 4096
%define G083_MAX_STEPS 65536
%define G083_SUBGROUPS 10

%ifndef NEBO_G083_TOOLING_IMPLEMENTATION
extern nebo_g083_source_probe
extern nebo_g083_negative_probe
extern nebo_g083_render_transcript
extern nebo_g083_span_parity
extern nebo_g083_atomic_copy
%endif

%endif
