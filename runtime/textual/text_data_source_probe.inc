%ifndef NEBO_G082_SOURCE_PROBE_INC
%define NEBO_G082_SOURCE_PROBE_INC 1

G082_MAX_BYTES equ 4096
G082_MAX_ITEMS equ 32
G082_DESC_INPUT equ 0
G082_DESC_LENGTH equ 8
G082_DESC_OUTPUT equ 16
G082_DESC_CAPACITY equ 24
G082_DESC_FLAGS equ 32
G082_DESC_SIZE equ 40

G082_SUMMARY_FIELDS equ 0
G082_SUMMARY_RECORDS equ 8
G082_SUMMARY_BYTES equ 16
G082_SUMMARY_SIZE equ 24

G082_PROFILE_SCALAR equ 1
G082_PROFILE_SIMD_OR_SCALAR equ 2

%ifndef NEBO_G082_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g082_source_probe
 extern nebo_g082_negative_probe
 extern nebo_g082_render_transcript
 extern nebo_g082_ascii_lower_vector
 extern nebo_g082_trim_text
 extern nebo_g082_join_texts
 extern nebo_g082_text_lengths
 extern nebo_g082_text_relation
 extern nebo_g082_table_summary
 extern nebo_g082_kernel_apply
 extern nebo_g082_chunk_boundary
%endif
%endif
