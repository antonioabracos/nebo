%ifndef NEBOC_ENTRYPOINT_DIAGNOSTIC_INC
%define NEBOC_ENTRYPOINT_DIAGNOSTIC_INC 1

; C03-F05 does not widen the canonical diagnostic schema.  It maps the
; C03-F04 resolver result into the existing fixed-capacity v1 record.
%define NEBOC_ENTRYPOINT_DIAGNOSTIC_MAX_RELATED 1

%endif
