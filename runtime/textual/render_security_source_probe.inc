%ifndef NEBO_G071_SOURCE_PROBE_INC
%define NEBO_G071_SOURCE_PROBE_INC 1

G071_PROFILE_TEXT          equ 1
G071_PROFILE_CONTRAST      equ 2
G071_PROFILE_ASCII         equ 4
G071_PROFILE_MAX           equ 7

%ifndef NEBO_G071_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g071_source_probe
 extern nebo_g071_negative_probe
 extern nebo_g071_render_transcript
 extern nebo_g071_escape_sink
 extern nebo_g071_locale_profile
 extern nebo_g071_select_profile
 extern nebo_g071_privacy_authorize
%endif
%endif
