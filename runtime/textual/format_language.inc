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

FORMAT_OK              equ 0
FORMAT_E_INVALID       equ 1
FORMAT_E_LIMIT         equ 2
FORMAT_E_SYNTAX        equ 3
FORMAT_E_EFFECT        equ 4
FORMAT_E_CAPACITY      equ 5
FORMAT_E_UNAVAILABLE   equ 6

FORMAT_MAX_NODES       equ 1024
FORMAT_MAX_INPUT       equ 4096
FORMAT_MAX_OUTPUT      equ 1048576
FORMAT_MAX_SLASH_DEPTH equ 16

; Updated monotonically by the O2 front materializer.
FORMAT_MAX_FEATURE_ID  equ 6509

%endif
