%ifndef NEBO_G112_SOURCE_PROBE_INC
%define NEBO_G112_SOURCE_PROBE_INC 1

%include "runtime/internal_chart_table_services.inc"

%define NEBO_G112_SOURCE_MIN_SEED 3201
%define NEBO_G112_SOURCE_MAX_SEED 3209
%define NEBO_G112_SOURCE_MAX_MODE 9
%define NEBO_G112_SOURCE_SURFACE_COUNT 24
%define NEBO_G112_SOURCE_NEGATIVE_COUNT 20

%ifndef NEBO_G112_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g112_source_probe
extern nebo_g112_surface_probe
extern nebo_g112_negative_probe
%endif

%endif
