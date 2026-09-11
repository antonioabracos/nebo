%ifndef NEBO_G113_SOURCE_PROBE_INC
%define NEBO_G113_SOURCE_PROBE_INC 1

%include "runtime/internal_domain_visual_services.inc"

%define NEBO_G113_SOURCE_MIN_SEED 3301
%define NEBO_G113_SOURCE_MAX_SEED 3310
%define NEBO_G113_SOURCE_MAX_MODE 10
%define NEBO_G113_SOURCE_SURFACE_COUNT 46
%define NEBO_G113_SOURCE_NEGATIVE_COUNT 18

%ifndef NEBO_G113_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g113_source_probe
extern nebo_g113_surface_probe
extern nebo_g113_negative_probe
%endif

%endif
