%ifndef NEBO_G115_SOURCE_PROBE_INC
%define NEBO_G115_SOURCE_PROBE_INC 1

%include "runtime/internal_console_abi.inc"

%define NEBO_G115_SOURCE_MIN_SEED 3501
%define NEBO_G115_SOURCE_MAX_SEED 3510
%define NEBO_G115_SOURCE_MAX_MODE 10
%define NEBO_G115_SOURCE_SURFACE_COUNT 78
%define NEBO_G115_SOURCE_NEGATIVE_COUNT 24

%ifndef NEBO_G115_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g115_source_probe
extern nebo_g115_surface_probe
extern nebo_g115_negative_probe
%endif

%endif
