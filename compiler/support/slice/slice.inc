%ifndef NEBOC_SLICE_INC
%define NEBOC_SLICE_INC 1

; Slice v0 is a checked borrowed view into one live Arena generation.
; It never owns or releases the referenced elements.

%define NEBOC_SLICE_POINTER_OFFSET 0
%define NEBOC_SLICE_LENGTH_OFFSET 8
%define NEBOC_SLICE_ELEMENT_SIZE_OFFSET 16
%define NEBOC_SLICE_ARENA_OFFSET 24
%define NEBOC_SLICE_GENERATION_OFFSET 32
%define NEBOC_SLICE_OWNER_OFFSET 40
%define NEBOC_SLICE_SIZE 48

%define NEBOC_SLICE_MAX_ELEMENT_SIZE 4096

%endif
