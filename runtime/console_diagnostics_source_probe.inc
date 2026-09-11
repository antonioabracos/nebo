%ifndef NEBO_G109_SOURCE_PROBE_INC
%define NEBO_G109_SOURCE_PROBE_INC 1

%include "runtime/console/diagnostics.inc"

%define NEBO_G109_SOURCE_MIN_SEED 2900
%define NEBO_G109_SOURCE_MAX_MODE 9
%define NEBO_G109_SOURCE_MAX_DEPTH 8
%define NEBO_G109_SOURCE_MAX_BUDGET 64

%ifndef NEBO_G109_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g109_source_probe
extern nebo_g109_surface_probe
extern nebo_g109_negative_probe
%endif

%endif
