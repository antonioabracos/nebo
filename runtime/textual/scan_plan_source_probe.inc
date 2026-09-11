%ifndef NEBO_G075_SOURCE_PROBE_INC
%define NEBO_G075_SOURCE_PROBE_INC 1

G075_STATE_KIND       equ 0
G075_STATE_FLAGS      equ 8
G075_STATE_SPAN_START equ 16
G075_STATE_SPAN_END   equ 24
G075_STATE_PRESENT    equ 32
G075_STATE_VALUE      equ 40
G075_STATE_LENGTH     equ 48
G075_STATE_BUFFER     equ 64
G075_BUFFER_MAX       equ 256
G075_STATE_SIZE       equ 320
G075_SEED_MIN         equ 1300

G075_EMPTY_REQUIRED   equ 1
G075_EMPTY_OPTIONAL   equ 2
G075_EMPTY_ALLOW      equ 3
G075_EMPTY_DEFAULT    equ 4
G075_EMPTY_FALLBACK   equ 5
G075_EMPTY_AS_NONE    equ 6

G075_NORM_TRIM        equ 1
G075_NORM_TRIM_START  equ 2
G075_NORM_TRIM_END    equ 3
G075_NORM_LOWER       equ 4
G075_NORM_UPPER       equ 5
G075_NORM_CAPITALIZE  equ 6
G075_NORM_SPACES      equ 7
G075_NORM_STRIP       equ 8
G075_NORM_SLUG        equ 9
G075_NORM_CHOMP       equ 10

%ifndef NEBO_G075_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g075_source_probe
 extern nebo_g075_negative_probe
 extern nebo_g075_render_transcript
 extern nebo_g075_plan_init
 extern nebo_g075_validate_kind
 extern nebo_g075_empty_resolve
 extern nebo_g075_normalize
%endif
%endif
