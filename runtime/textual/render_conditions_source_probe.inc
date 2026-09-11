%ifndef NEBO_G073_SOURCE_PROBE_INC
%define NEBO_G073_SOURCE_PROBE_INC 1

G073_STATE_SEED       equ 0
G073_STATE_LENGTH     equ 8
G073_STATE_CALLS      equ 16
G073_STATE_DEPTH      equ 24
G073_STATE_HASH       equ 32
G073_STATE_SCOPES     equ 40
G073_SCOPE_SLOTS      equ 8
G073_STATE_BUFFER     equ 104
G073_CAPTURE_MAX      equ 256
G073_STATE_SIZE       equ 360

G073_CONDITION_WHEN   equ 1
G073_CONDITION_UNLESS equ 2
G073_CONDITION_ONCE   equ 3
G073_CONDITION_EVERY  equ 4
G073_CONDITION_FIRST  equ 5
G073_CONDITION_MAX    equ G073_CONDITION_FIRST

G073_EDUCATION_BEGINNER equ 1
G073_EDUCATION_ADVANCED equ 2
G073_EDUCATION_MAX      equ G073_EDUCATION_ADVANCED

%ifndef NEBO_G073_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g073_source_probe
 extern nebo_g073_negative_probe
 extern nebo_g073_render_transcript
 extern nebo_g073_state_init
 extern nebo_g073_capture
 extern nebo_g073_assert_equals
 extern nebo_g073_assert_contains
 extern nebo_g073_snapshot
 extern nebo_g073_replay
 extern nebo_g073_snapshot_hash
 extern nebo_g073_condition
 extern nebo_g073_scope_push
 extern nebo_g073_scope_pop
 extern nebo_g073_education_render
 extern nebo_g073_normalize_output
%endif
%endif
