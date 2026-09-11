%ifndef NEBO_G114_SOURCE_PROBE_INC
%define NEBO_G114_SOURCE_PROBE_INC 1

%include "runtime/internal_export_privacy_services.inc"

%define NEBO_G114_SOURCE_MIN_SEED 3401
%define NEBO_G114_SOURCE_MAX_SEED 3409
%define NEBO_G114_SOURCE_MAX_MODE 9
%define NEBO_G114_SOURCE_SURFACE_COUNT 44
%define NEBO_G114_SOURCE_NEGATIVE_COUNT 22

%ifndef NEBO_G114_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g114_source_probe
extern nebo_g114_surface_probe
extern nebo_g114_negative_probe
%endif

%endif
