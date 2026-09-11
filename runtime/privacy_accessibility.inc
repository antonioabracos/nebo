%ifndef NEBO_PRIVACY_ACCESSIBILITY_INC
%define NEBO_PRIVACY_ACCESSIBILITY_INC 1

%include "runtime/textual/text_privacy.inc"
%include "runtime/textual/render_console.inc"

; Caller-owned, allocation-free policy, RenderPlan, and audit records.
NEBO_G106_POLICY_CLASS              equ 0
NEBO_G106_POLICY_ACTION             equ 8
NEBO_G106_POLICY_SINK_MAX           equ 16
NEBO_G106_POLICY_TRUST              equ 24
NEBO_G106_POLICY_TOKEN              equ 32
NEBO_G106_POLICY_QUALITY            equ 40
NEBO_G106_POLICY_CONFIDENCE         equ 48
NEBO_G106_POLICY_LINEAGE            equ 56
NEBO_G106_POLICY_ACCESS             equ 64
NEBO_G106_POLICY_STYLE              equ 72
NEBO_G106_POLICY_MASK_WIDTH         equ 80
NEBO_G106_POLICY_CAPABILITY         equ 88
NEBO_G106_POLICY_DIGEST             equ 96
NEBO_G106_POLICY_CONFIGURED         equ 104
NEBO_G106_POLICY_SIZE               equ 112
NEBO_G106_POLICY_QWORDS             equ 14

NEBO_G106_PLAN_CLASS                equ 0
NEBO_G106_PLAN_ACTION               equ 8
NEBO_G106_PLAN_SINK_MAX             equ 16
NEBO_G106_PLAN_POLICY_TOKEN         equ 24
NEBO_G106_PLAN_RENDER_FLAGS         equ 32
NEBO_G106_PLAN_ACCESS               equ 40
NEBO_G106_PLAN_QUALITY              equ 48
NEBO_G106_PLAN_CONFIDENCE           equ 56
NEBO_G106_PLAN_LINEAGE              equ 64
NEBO_G106_PLAN_TRUST                equ 72
NEBO_G106_PLAN_MASK_WIDTH           equ 80
NEBO_G106_PLAN_VISIBILITY           equ 88
NEBO_G106_PLAN_COLOR                equ 96
NEBO_G106_PLAN_STYLE                equ 104
NEBO_G106_PLAN_FALLBACK             equ 112
NEBO_G106_PLAN_DIGEST               equ 120
NEBO_G106_PLAN_SIZE                 equ 128
NEBO_G106_PLAN_QWORDS               equ 16

NEBO_G106_AUDIT_EVALUATED           equ 0
NEBO_G106_AUDIT_ALLOWED             equ 8
NEBO_G106_AUDIT_DENIED              equ 16
NEBO_G106_AUDIT_REDACTED            equ 24
NEBO_G106_AUDIT_MASKED              equ 32
NEBO_G106_AUDIT_ACCESSIBLE          equ 40
NEBO_G106_AUDIT_NO_COLOR            equ 48
NEBO_G106_AUDIT_HIGH_CONTRAST       equ 56
NEBO_G106_AUDIT_SCREEN_READER       equ 64
NEBO_G106_AUDIT_LINEAGE_BOUND       equ 72
NEBO_G106_AUDIT_LAST_DECISION       equ 80
NEBO_G106_AUDIT_LAST_DIAGNOSTIC     equ 88
NEBO_G106_AUDIT_LAST_DIGEST         equ 96
NEBO_G106_AUDIT_MATURITY            equ 104
NEBO_G106_AUDIT_SIZE                equ 112
NEBO_G106_AUDIT_QWORDS              equ 14

NEBO_G106_ACTION_ALLOW              equ 1
NEBO_G106_ACTION_REDACT             equ 2
NEBO_G106_ACTION_MASK               equ 3
NEBO_G106_ACTION_DENY               equ 4
NEBO_G106_ACTION_MAX                equ NEBO_G106_ACTION_DENY

NEBO_G106_ACCESS_NO_COLOR           equ 1
NEBO_G106_ACCESS_HIGH_CONTRAST      equ 2
NEBO_G106_ACCESS_SCREEN_READER      equ 4
NEBO_G106_ACCESS_TEXT_FALLBACK      equ 8
NEBO_G106_ACCESS_ALL                equ 15

NEBO_G106_STYLE_COLOR               equ 1
NEBO_G106_STYLE_SEMANTIC            equ 2
NEBO_G106_STYLE_ALL                 equ 3

NEBO_G106_VISIBILITY_PUBLIC         equ 1
NEBO_G106_VISIBILITY_REDACTED       equ 2
NEBO_G106_VISIBILITY_MASKED         equ 3
NEBO_G106_VISIBILITY_DENIED         equ 4

NEBO_G106_CAPABILITY_V1             equ 0x4731303650524956
NEBO_G106_MATURITY_CONTRACT         equ 0
NEBO_G106_MATURITY_PUBLIC_PRIVACY_AWARE_CONSOLE_GREEN equ 1
NEBO_G106_MATURITY_ACCESSIBILITY_CONFORMANCE_GREEN equ 2

NEBO_G106_OK                        equ 0
NEBO_G106_ERROR_INVALID             equ 1
NEBO_G106_ERROR_LIMIT               equ 2
NEBO_G106_ERROR_TRUST               equ 3
NEBO_G106_ERROR_QUALITY             equ 4
NEBO_G106_ERROR_LINEAGE             equ 5
NEBO_G106_ERROR_PRIVACY             equ 6
NEBO_G106_ERROR_ACCESSIBILITY       equ 7
NEBO_G106_ERROR_STATE               equ 8

NEBO_G106_DIAG_INVALID              equ 0x8410601
NEBO_G106_DIAG_LIMIT                equ 0x8410602
NEBO_G106_DIAG_TRUST                equ 0x8410603
NEBO_G106_DIAG_QUALITY              equ 0x8410604
NEBO_G106_DIAG_LINEAGE              equ 0x8410605
NEBO_G106_DIAG_PRIVACY              equ 0x8410606
NEBO_G106_DIAG_ACCESSIBILITY        equ 0x8410607
NEBO_G106_DIAG_STATE                equ 0x8410608

NEBO_G106_SOURCE_MIN_SEED           equ 2600
NEBO_G106_SOURCE_MAX_MODE           equ 10
NEBO_G106_SOURCE_MAX_VARIANT        equ 3

%ifndef NEBO_G106_PRIVACY_ACCESSIBILITY_IMPLEMENTATION
extern nebo_g106_policy_init
extern nebo_g106_policy_quality_lineage
extern nebo_g106_policy_trust
extern nebo_g106_policy_accessibility
extern nebo_g106_policy_evaluate
extern nebo_g106_plan_validate
extern nebo_g106_audit_validate
extern nebo_g106_status_diagnostic
%endif
%endif
