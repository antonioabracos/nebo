%ifndef NEBOC_NAME_STYLE_INC
%define NEBOC_NAME_STYLE_INC 1

; Bounded ASCII spelling categories used by the RF116 semantic resolver.
; Non-ASCII identifier bytes remain ordinary: Unicode case folding is not part
; of the first RF116 profile.
%define NEBOC_NAME_INVALID 0
%define NEBOC_NAME_CAMEL_CASE 1
%define NEBOC_NAME_PASCAL_CASE 2
%define NEBOC_NAME_ALL_CAPS 3
%define NEBOC_NAME_ORDINARY 4

%define NEBOC_NAME_MAX_BYTES 255

%endif
