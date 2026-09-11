%ifndef NEBO_G081_SOURCE_PROBE_INC
%define NEBO_G081_SOURCE_PROBE_INC 1

G081_SEED_MIN equ 2900
G081_MAX_BYTES equ 4096
G081_MAX_ITEMS equ 64
G081_MAX_DEPTH equ 32
G081_MAX_LINE equ 1024

G081_POLICY_STRICT equ 1
G081_POLICY_ESCAPE equ 2

G081_KIND_MARKDOWN equ 5
G081_KIND_TOML equ 6
G081_KIND_LOG equ 7
G081_KIND_FEED equ 8
G081_KIND_XML equ 9
G081_KIND_HTML equ 10
G081_KIND_YAML equ 11
G081_KIND_INI equ 12

G081_SUMMARY_PRIMARY equ 0
G081_SUMMARY_SECONDARY equ 8
G081_SUMMARY_BYTES equ 16
G081_SUMMARY_KIND equ 24
G081_SUMMARY_FLAGS equ 32
G081_SUMMARY_SIZE equ 40

G081_EXTERNAL_FIRST equ 13
G081_EXTERNAL_LAST equ 20

%ifndef NEBO_G081_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g081_source_probe
 extern nebo_g081_negative_probe
 extern nebo_g081_render_transcript
 extern nebo_g081_md_parse
 extern nebo_g081_md_extract_headings
 extern nebo_g081_md_extract_links
 extern nebo_g081_md_frontmatter
 extern nebo_g081_md_to_html
 extern nebo_g081_toml_parse
 extern nebo_g081_toml_write
 extern nebo_g081_log_parse_line
 extern nebo_g081_log_stream
 extern nebo_g081_log_write
 extern nebo_g081_feed_parse
 extern nebo_g081_xml_parse
 extern nebo_g081_html_sanitize
 extern nebo_g081_html_to_text
 extern nebo_g081_yaml_parse
 extern nebo_g081_ini_parse
 extern nebo_g081_ini_write
 extern nebo_g081_profile_classify
 extern nebo_g081_read_bounded
 extern nebo_g081_write_atomic
%endif
%endif
