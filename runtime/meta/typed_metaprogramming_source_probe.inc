%ifndef NEBO_G028_SOURCE_PROBE_INC
%define NEBO_G028_SOURCE_PROBE_INC 1

G028_STATUS_OK equ 0
G028_STATUS_INVALID equ 1
G028_STATUS_KIND equ 2
G028_STATUS_CAPTURE equ 3
G028_STATUS_CAPABILITY equ 4
G028_STATUS_LIMIT equ 5
G028_STATUS_BUDGET equ 6
G028_STATUS_ASSERT equ 7

G028_MAX_DEPTH equ 32
G028_MAX_NODES equ 65536
G028_MAX_BYTES equ 1048576
G028_MAX_FIELDS equ 64
G028_MAX_ITEMS equ 64
G028_DERIVE_ALL equ 127
G028_MIN_SEED equ 2801
G028_MAX_SEED equ 999999

G028_FRAGMENT_KIND equ 0
G028_FRAGMENT_ORIGIN equ 8
G028_FRAGMENT_OWNER equ 16
G028_FRAGMENT_NODES equ 24
G028_FRAGMENT_BYTES equ 32
G028_FRAGMENT_EFFECTS equ 40
G028_FRAGMENT_SPAN equ 48
G028_FRAGMENT_SIZE equ 56

G028_REFLECT_FIELDS equ 0
G028_REFLECT_METHODS equ 8
G028_REFLECT_VARIANTS equ 16
G028_REFLECT_SIZE equ 24
G028_REFLECT_ALIGN equ 32
G028_REFLECT_CAPABILITIES equ 40
G028_REFLECT_DESC_SIZE equ 48

%ifndef NEBO_G028_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g028_source_probe
 extern nebo_g028_fragment_validate
 extern nebo_g028_fresh_name
 extern nebo_g028_capture_validate
 extern nebo_g028_reflect_summary
 extern nebo_g028_require_capability
 extern nebo_g028_derive_plan
 extern nebo_g028_compile_evaluate
 extern nebo_g028_compile_for_each
 extern nebo_g028_compile_assert
 extern nebo_g028_compile_resource
 extern nebo_g028_compile_environment
 extern nebo_g028_compile_cache_key
 extern nebo_g028_macro_expand
 extern nebo_g028_generated_origin
%endif
%endif
