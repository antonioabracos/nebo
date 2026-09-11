%ifndef NEBO_G107_SOURCE_PROBE_INC
%define NEBO_G107_SOURCE_PROBE_INC 1

%include "runtime/console_routing.inc"

%define NEBO_G107_SOURCE_MIN_SEED 2700
%define NEBO_G107_SOURCE_MAX_MODE 9
%define NEBO_G107_SOURCE_MAX_VARIANT 3

%ifndef NEBO_G107_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g107_source_probe
extern nebo_g107_surface_probe
extern nebo_g107_negative_probe
%endif

%endif
