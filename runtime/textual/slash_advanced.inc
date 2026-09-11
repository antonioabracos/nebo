%ifndef NEBO_SLASH_ADVANCED_INC
%define NEBO_SLASH_ADVANCED_INC 1

; G065 advanced Slash DSL ABI. The engine is allocation-free, bounded, and
; policy-explicit. Existing G064 entry points remain strict and unchanged.
SLASH_ADV_OK                 equ 0
SLASH_ADV_E_INVALID          equ 1
SLASH_ADV_E_LIMIT            equ 2
SLASH_ADV_E_SYNTAX           equ 3
SLASH_ADV_E_UNKNOWN          equ 4
SLASH_ADV_E_ARGUMENT         equ 5
SLASH_ADV_E_POLICY           equ 6
SLASH_ADV_E_CAPACITY         equ 7
SLASH_ADV_E_TARGET           equ 8

SLASH_ADV_POLICY_STRICT          equ 0
SLASH_ADV_POLICY_UNKNOWN_TEXT    equ 1
SLASH_ADV_POLICY_ALLOW_RAW       equ 2

MAX_SLASH_INPUT             equ 4096
MAX_SLASH_NODES             equ 256
MAX_SLASH_DEPTH             equ 16
MAX_SLASH_ARGUMENT          equ 64
SLASH_CONDITIONALS_NON_TURING_COMPLETE equ 1

SLASH_ADV_TARGET_PLAIN      equ 1
SLASH_ADV_TARGET_ANSI       equ 2
SLASH_ADV_TARGET_MARKDOWN   equ 3
SLASH_ADV_TARGET_HTML       equ 4
SLASH_ADV_TARGET_CONSOLE    equ 5

SLASH_ADV_ERROR_CODE        equ 0
SLASH_ADV_ERROR_START       equ 8
SLASH_ADV_ERROR_END         equ 16
SLASH_ADV_ERROR_SIZE        equ 24

%ifndef NEBO_SLASH_ADVANCED_IMPLEMENTATION
 extern neboc_slash_advanced_validate
 extern neboc_slash_advanced_render
 extern neboc_slash_advanced_registry_count
%endif

%endif
