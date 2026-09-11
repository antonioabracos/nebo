%ifndef NEBO_G070_SOURCE_PROBE_INC
%define NEBO_G070_SOURCE_PROBE_INC 1

G070_STATE_NOW         equ 0
G070_STATE_LAST        equ 8
G070_STATE_INTERVAL    equ 16
G070_STATE_CAPACITY    equ 24
G070_STATE_HEAD        equ 32
G070_STATE_COUNT       equ 40
G070_STATE_ENQUEUED    equ 48
G070_STATE_EMITTED     equ 56
G070_STATE_PROGRESS    equ 64
G070_STATE_TOTAL       equ 72
G070_STATE_QUEUE       equ 80
G070_STATE_QUEUE_SLOTS equ 8
G070_STATE_SIZE        equ 144

%ifndef NEBO_G070_SOURCE_PROBE_IMPLEMENTATION
 extern nebo_g070_source_probe
 extern nebo_g070_negative_probe
 extern nebo_g070_render_transcript
 extern nebo_g070_state_init
 extern nebo_g070_enqueue
 extern nebo_g070_advance
 extern nebo_g070_drain
 extern nebo_g070_progress
 extern nebo_g070_snapshot
%endif
%endif
