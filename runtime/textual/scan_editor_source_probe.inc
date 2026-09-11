%ifndef NEBO_G078_SOURCE_PROBE_INC
%define NEBO_G078_SOURCE_PROBE_INC 1
G078_SEED_MIN equ 1900
G078_MAX_BYTES equ 4096
G078_MAX_LINES equ 256
G078_MAX_CHOICES equ 32
G078_CAP_READ equ 1
G078_CAP_RECORD equ 2
G078_SOURCE_STDIN equ 1
G078_SOURCE_FILE equ 2
G078_SOURCE_ENV equ 3
G078_SOURCE_ARGS equ 4
G078_SOURCE_PIPE equ 5
G078_SOURCE_MOCK equ 6
G078_SOURCE_NAMED equ 7
G078_SOURCE_REPLAY equ 8
G078_SOURCE_RECORD equ 9
G078_SOURCE_DEVICE equ 10
G078_STATS_BYTES equ 0
G078_STATS_LINES equ 8
G078_STATS_SIZE equ 16
G078_META_SCHEMA equ 0
G078_META_DOC_LEN equ 8
G078_META_QUALITY equ 16
G078_META_PROVENANCE equ 24
G078_META_EVENT equ 32
G078_META_FLAGS equ 40
G078_META_SIZE equ 48
%ifndef NEBO_G078_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g078_source_probe
 extern nebo_g078_negative_probe
 extern nebo_g078_render_transcript
 extern nebo_g078_multiline_stats
 extern nebo_g078_editor_replay
 extern nebo_g078_source_copy
 extern nebo_g078_path_validate
 extern nebo_g078_form_validate
 extern nebo_g078_metadata_validate
%endif
%endif
