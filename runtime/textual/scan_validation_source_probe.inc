%ifndef NEBO_G076_SOURCE_PROBE_INC
%define NEBO_G076_SOURCE_PROBE_INC 1

G076_SEED_MIN equ 1500
G076_TEXT_CONTAINS equ 1
G076_TEXT_STARTS   equ 2
G076_TEXT_ENDS     equ 3
G076_LOCALE_C      equ 1
G076_LOCALE_PT_PT  equ 2

G076_RETRY_ATTEMPTS equ 0
G076_RETRY_MAX      equ 8
G076_RETRY_LAST     equ 16
G076_RETRY_FALLBACK equ 24
G076_RETRY_SIZE     equ 32

%ifndef NEBO_G076_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g076_source_probe
 extern nebo_g076_negative_probe
 extern nebo_g076_render_transcript
 extern nebo_g076_text_match
 extern nebo_g076_numeric_validate
 extern nebo_g076_decimal_validate
 extern nebo_g076_prefix_index
 extern nebo_g076_multiselect_mask
 extern nebo_g076_yes_no
 extern nebo_g076_retry_init
 extern nebo_g076_retry_failure
 extern nebo_g076_retry_should_continue
 extern nebo_g076_retry_resolve
%endif
%endif
