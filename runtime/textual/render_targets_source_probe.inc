%ifndef NEBO_G072_SOURCE_PROBE_INC
%define NEBO_G072_SOURCE_PROBE_INC 1

G072_TARGET_MASK_PLAIN     equ 1
G072_TARGET_MASK_ANSI      equ 2
G072_TARGET_MASK_MARKDOWN  equ 4
G072_TARGET_MASK_HTML      equ 8
G072_TARGET_MASK_HEADLESS  equ 16
G072_TARGET_MASK_MAX       equ 31

G072_ROUTE_STDOUT          equ 1
G072_ROUTE_STDERR          equ 2
G072_ROUTE_TARGET          equ 3
G072_ROUTE_BUFFER          equ 4
G072_ROUTE_CONSOLE         equ 5
G072_ROUTE_MARKDOWN        equ 6
G072_ROUTE_HTML            equ 7
G072_ROUTE_JSON            equ 8
G072_ROUTE_ANSI            equ 9
G072_ROUTE_PLAIN           equ 10
G072_ROUTE_MAX             equ G072_ROUTE_PLAIN

G072_LIFECYCLE_NEW        equ 0
G072_LIFECYCLE_OPEN       equ 1
G072_LIFECYCLE_CANCELLED  equ 2
G072_LIFECYCLE_CLOSED     equ 3

G072_FILE_TEMP_PATH       equ 0
G072_FILE_FINAL_PATH      equ 8
G072_FILE_DATA            equ 16
G072_FILE_LENGTH          equ 24
G072_FILE_REQUEST_SIZE    equ 32

%ifndef NEBO_G072_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g072_source_probe
 extern nebo_g072_negative_probe
 extern nebo_g072_render_transcript
 extern nebo_g072_select_target
 extern nebo_g072_route_validate
 extern nebo_g072_visual_record
 extern nebo_g072_event_jsonl
 extern nebo_g072_mirror_bytes
 extern nebo_g072_lifecycle_step
 extern nebo_g072_atomic_write
%endif
%endif
