%ifndef NEBO_G108_SOURCE_PROBE_INC
%define NEBO_G108_SOURCE_PROBE_INC 1

%include "runtime/console_testability.inc"

%define NEBO_G108_SOURCE_MIN_SEED 2800
%define NEBO_G108_SOURCE_MAX_MODE 9
%define NEBO_G108_SOURCE_MAX_VARIANT 2

%ifndef NEBO_G108_SOURCE_PROBE_IMPLEMENTATION
extern nebo_g108_source_probe
extern nebo_g108_surface_probe
extern nebo_g108_negative_probe
%endif

%endif
