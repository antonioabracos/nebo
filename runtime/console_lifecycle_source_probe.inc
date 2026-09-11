%ifndef NEBO_G111_SOURCE_PROBE_INC
%define NEBO_G111_SOURCE_PROBE_INC 1

%include "runtime/internal_observability_services.inc"

%define NEBO_G111_SOURCE_MIN_SEED 3101
%define NEBO_G111_SOURCE_MAX_SEED 3109
%define NEBO_G111_SOURCE_MAX_MODE 9
%define NEBO_G111_SOURCE_SURFACE_COUNT 20
%define NEBO_G111_SOURCE_NEGATIVE_COUNT 16

%ifndef NEBO_G111_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g111_source_probe
extern nebo_g111_surface_probe
extern nebo_g111_negative_probe
%endif

%endif
