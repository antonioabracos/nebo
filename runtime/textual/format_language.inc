%ifndef NEBO_FORMAT_LANGUAGE_INC
%define NEBO_FORMAT_LANGUAGE_INC 1

; Public, caller-owned FormatPlan ABI. Every node is immutable during a call.
FORMAT_NODE_KIND       equ 0
FORMAT_NODE_DATA       equ 8
FORMAT_NODE_LENGTH     equ 16
FORMAT_NODE_PROFILE    equ 24
FORMAT_NODE_SIZE       equ 32

FORMAT_NODE_LITERAL    equ 1
FORMAT_NODE_VALUE      equ 2
FORMAT_NODE_STYLE_OPEN equ 3
FORMAT_NODE_STYLE_CLOSE equ 4
; G059 preserves the historical four-kind ABI and appends the two typed
; addressing forms. For NAMED/POSITION nodes PROFILE packs the stable key or
; zero-based position in the high dword and the formatting profile in the low
; dword. DATA/LENGTH always name the already evaluated immutable value bytes.
FORMAT_NODE_NAMED      equ 5
FORMAT_NODE_POSITION   equ 6

FORMAT_OK              equ 0
FORMAT_E_INVALID       equ 1
FORMAT_E_LIMIT         equ 2
FORMAT_E_SYNTAX        equ 3
FORMAT_E_EFFECT        equ 4
FORMAT_E_CAPACITY      equ 5
FORMAT_E_UNAVAILABLE   equ 6
FORMAT_E_ALLOCATION    equ 7

; Public immutable FormatPlan descriptor. Clone creates another shallow,
; generation-preserving lease over immutable nodes; drop invalidates exactly
; the descriptor supplied by the caller.
FORMAT_PLAN_NODES      equ 0
FORMAT_PLAN_COUNT      equ 8
FORMAT_PLAN_GENERATION equ 16
FORMAT_PLAN_STATE      equ 24
FORMAT_PLAN_SIZE       equ 32
FORMAT_PLAN_DROPPED    equ 0
FORMAT_PLAN_LIVE       equ 1

; ConsoleOptions is deliberately presentation-only. Formatting data never
; crosses this ABI. FLAGS is frozen to zero in G059.
FORMAT_CONSOLE_FD      equ 0
FORMAT_CONSOLE_FLAGS   equ 8
FORMAT_CONSOLE_OPTIONS_SIZE equ 16

FORMAT_MAX_NODES       equ 1024
FORMAT_MAX_INPUT       equ 4096
FORMAT_MAX_OUTPUT      equ 1048576
FORMAT_MAX_SLASH_DEPTH equ 16

; Updated monotonically by the O2 front materializer.
FORMAT_MAX_FEATURE_ID  equ 6509

%endif
