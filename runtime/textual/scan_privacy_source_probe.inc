%ifndef NEBO_G077_SOURCE_PROBE_INC
%define NEBO_G077_SOURCE_PROBE_INC 1

G077_SEED_MIN equ 1700
G077_MAX_TIMEOUT_MS equ 3600000
G077_MAX_CANCEL_KEYS equ 16
G077_MAX_FIELDS equ 32

G077_PRIV_SECRET    equ 0x01
G077_PRIV_MASK      equ 0x02
G077_PRIV_REDACT    equ 0x04
G077_PRIV_NO_HISTORY equ 0x08
G077_PRIV_CONFIRM   equ 0x10
G077_PRIV_SENSITIVE equ 0x20
G077_PRIV_FORGET    equ 0x40
G077_PRIV_UNTRUSTED equ 0x80

G077_EVENT_VALUE   equ 1
G077_EVENT_TIMEOUT equ 2
G077_EVENT_CANCEL  equ 3
G077_EVENT_EOF     equ 4

G077_RESOLVE_EOF_NONE        equ 0x01
G077_RESOLVE_EOF_FALLBACK    equ 0x02
G077_RESOLVE_CANCEL_FALLBACK equ 0x04
G077_RESOLVE_INTERRUPTIBLE   equ 0x08
G077_RESOLVE_RESULT          equ 0x10

G077_OUTCOME_OK    equ 0
G077_OUTCOME_NONE  equ 1
G077_OUTCOME_ERROR equ 2
G077_OUTCOME_TAG   equ 0
G077_OUTCOME_VALUE equ 8
G077_OUTCOME_ERROR_CODE equ 16
G077_OUTCOME_SIZE  equ 24
G077_E_TIMEOUT     equ 9

G077_FIELDS_PLAIN equ 0
G077_FIELDS_CSV   equ 1
G077_FIELDS_SHELL equ 2

%ifndef NEBO_G077_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g077_source_probe
 extern nebo_g077_negative_probe
 extern nebo_g077_render_transcript
 extern nebo_g077_privacy_validate
 extern nebo_g077_secret_strength
 extern nebo_g077_secret_confirm
 extern nebo_g077_secret_forget
 extern nebo_g077_cancel_match
 extern nebo_g077_event_resolve
 extern nebo_g077_parse_pair_i64
 extern nebo_g077_field_count
%endif
%endif
