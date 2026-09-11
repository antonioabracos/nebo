%ifndef NEBO_SCAN_CONSOLE_INC
%define NEBO_SCAN_CONSOLE_INC 1

; G105 owns a caller-allocated, target-neutral adapter between ScanPlan and
; Console. Requests intentionally contain metadata only: input bytes are
; supplied to the response boundary and can never enter request/event records.

NEBO_G105_STATUS_OK          equ 0
NEBO_G105_STATUS_INVALID     equ 1
NEBO_G105_STATUS_LIMIT       equ 2
NEBO_G105_STATUS_CAPABILITY  equ 3
NEBO_G105_STATUS_VALIDATION  equ 4
NEBO_G105_STATUS_EXHAUSTED   equ 5
NEBO_G105_STATUS_BAD_STATE   equ 6
NEBO_G105_STATUS_REPLAY      equ 7

NEBO_G105_MAX_FIELDS         equ 32
NEBO_G105_MAX_CHOICES        equ 32
NEBO_G105_MAX_LINES          equ 256
NEBO_G105_MAX_INPUT_BYTES    equ 4096
NEBO_G105_MAX_ATTEMPTS       equ 8
NEBO_G105_MAX_STRENGTH       equ 5

NEBO_G105_FRONTEND_CONSOLE   equ 1

NEBO_G105_SOURCE_MOCK        equ 1
NEBO_G105_SOURCE_REPLAY      equ 2
NEBO_G105_SOURCE_LIVE        equ 3
NEBO_G105_SOURCE_HEADLESS    equ 4

NEBO_G105_CAP_MOCK           equ 0x01
NEBO_G105_CAP_REPLAY         equ 0x02
NEBO_G105_CAP_LIVE           equ 0x04
NEBO_G105_CAP_HEADLESS       equ 0x08
NEBO_G105_CAP_ALL            equ 0x0f

NEBO_G105_INPUT_LINE         equ 1
NEBO_G105_INPUT_MULTILINE    equ 2
NEBO_G105_INPUT_PARAGRAPH    equ 3
NEBO_G105_INPUT_BLOCK        equ 4
NEBO_G105_INPUT_MARKDOWN     equ 5
NEBO_G105_INPUT_CODE         equ 6
NEBO_G105_INPUT_JSON_BLOCK   equ 7
NEBO_G105_INPUT_RAW_BLOCK    equ 8

NEBO_G105_CHOICE_ONE          equ 0x001
NEBO_G105_CHOICE_ONE_OF       equ 0x002
NEBO_G105_CHOICE_MENU         equ 0x004
NEBO_G105_CHOICE_SELECT       equ 0x008
NEBO_G105_CHOICE_MULTI        equ 0x010
NEBO_G105_CHOICE_INDEX        equ 0x020
NEBO_G105_CHOICE_BOOLEAN      equ 0x040
NEBO_G105_CHOICE_CONFIRM      equ 0x080
NEBO_G105_CHOICE_ENUM         equ 0x100
NEBO_G105_CHOICE_AUTOCOMPLETE equ 0x200
NEBO_G105_CHOICE_ALL          equ 0x3ff

NEBO_G105_SECURITY_SECRET       equ 0x001
NEBO_G105_SECURITY_PASSWORD     equ 0x002
NEBO_G105_SECURITY_REDACT       equ 0x004
NEBO_G105_SECURITY_NO_HISTORY   equ 0x008
NEBO_G105_SECURITY_NO_ECHO      equ 0x010
NEBO_G105_SECURITY_CONFIRM      equ 0x020
NEBO_G105_SECURITY_SENSITIVE    equ 0x040
NEBO_G105_SECURITY_FORGET       equ 0x080
NEBO_G105_SECURITY_UNTRUSTED    equ 0x100
NEBO_G105_SECURITY_MASK         equ 0x200
NEBO_G105_SECURITY_ALL          equ 0x3ff

NEBO_G105_EVENT_RESPONSE          equ 1
NEBO_G105_EVENT_VALIDATION_FAILED equ 2
NEBO_G105_EVENT_FLAG_REDACTED     equ 1
NEBO_G105_REDACTED_DIGEST         equ 0x7265646163746564

NEBO_G105_MATURITY_HEADLESS_SCAN_CONSOLE_GREEN equ 1
NEBO_G105_MATURITY_LIVE_SCAN_CONSOLE_GREEN     equ 2

NEBO_G105_PLAN_FRONTEND_OFFSET       equ 0
NEBO_G105_PLAN_FORM_OFFSET           equ 8
NEBO_G105_PLAN_FIELD_COUNT_OFFSET    equ 16
NEBO_G105_PLAN_VIEW_OFFSET           equ 24
NEBO_G105_PLAN_PANEL_OFFSET          equ 32
NEBO_G105_PLAN_FEEDBACK_OFFSET       equ 40
NEBO_G105_PLAN_STYLE_OFFSET          equ 48
NEBO_G105_PLAN_INPUT_MODE_OFFSET     equ 56
NEBO_G105_PLAN_MAX_LINES_OFFSET      equ 64
NEBO_G105_PLAN_DELIMITER_LEN_OFFSET  equ 72
NEBO_G105_PLAN_CHOICE_COUNT_OFFSET   equ 80
NEBO_G105_PLAN_CHOICE_FLAGS_OFFSET   equ 88
NEBO_G105_PLAN_SECURITY_FLAGS_OFFSET equ 96
NEBO_G105_PLAN_MIN_STRENGTH_OFFSET   equ 104
NEBO_G105_PLAN_MAX_ATTEMPTS_OFFSET   equ 112
NEBO_G105_PLAN_CAPABILITIES_OFFSET   equ 120
NEBO_G105_PLAN_DIGEST_OFFSET         equ 128
NEBO_G105_PLAN_SIZE                  equ 136
NEBO_G105_PLAN_QWORDS                equ NEBO_G105_PLAN_SIZE/8

; A request has no pointer, length, digest, or copy of user input.
NEBO_G105_REQUEST_ID_OFFSET          equ 0
NEBO_G105_REQUEST_ATTEMPT_OFFSET     equ 8
NEBO_G105_REQUEST_SOURCE_OFFSET      equ 16
NEBO_G105_REQUEST_FORM_OFFSET        equ 24
NEBO_G105_REQUEST_FIELD_COUNT_OFFSET equ 32
NEBO_G105_REQUEST_FLAGS_OFFSET       equ 40
NEBO_G105_REQUEST_SIZE               equ 48
NEBO_G105_REQUEST_QWORDS             equ NEBO_G105_REQUEST_SIZE/8

NEBO_G105_RESPONSE_REQUEST_ID_OFFSET   equ 0
NEBO_G105_RESPONSE_STATUS_OFFSET       equ 8
NEBO_G105_RESPONSE_VALUE_LENGTH_OFFSET equ 16
NEBO_G105_RESPONSE_VALUE_DIGEST_OFFSET equ 24
NEBO_G105_RESPONSE_SELECTIONS_OFFSET   equ 32
NEBO_G105_RESPONSE_ZEROIZED_OFFSET     equ 40
NEBO_G105_RESPONSE_SIZE                 equ 48

NEBO_G105_EVENT_REQUEST_ID_OFFSET    equ 0
NEBO_G105_EVENT_KIND_OFFSET          equ 8
NEBO_G105_EVENT_STATUS_OFFSET        equ 16
NEBO_G105_EVENT_PUBLIC_LENGTH_OFFSET equ 24
NEBO_G105_EVENT_PUBLIC_DIGEST_OFFSET equ 32
NEBO_G105_EVENT_FLAGS_OFFSET         equ 40
NEBO_G105_EVENT_SIZE                 equ 48

NEBO_G105_EVIDENCE_REQUESTS_OFFSET        equ 0
NEBO_G105_EVIDENCE_RESPONSES_OFFSET       equ 8
NEBO_G105_EVIDENCE_FAILURES_OFFSET        equ 16
NEBO_G105_EVIDENCE_RETRIES_OFFSET         equ 24
NEBO_G105_EVIDENCE_REDACTIONS_OFFSET      equ 32
NEBO_G105_EVIDENCE_ZEROIZATIONS_OFFSET    equ 40
NEBO_G105_EVIDENCE_FALLBACKS_OFFSET       equ 48
NEBO_G105_EVIDENCE_REPLAYS_OFFSET         equ 56
NEBO_G105_EVIDENCE_LAST_REQUEST_ID_OFFSET equ 64
NEBO_G105_EVIDENCE_LAST_DIGEST_OFFSET     equ 72
NEBO_G105_EVIDENCE_MATURITY_OFFSET        equ 80
NEBO_G105_EVIDENCE_SIZE                   equ 88
NEBO_G105_EVIDENCE_QWORDS                 equ NEBO_G105_EVIDENCE_SIZE/8

%ifndef NEBO_SCAN_CONSOLE_IMPLEMENTATION
extern nebo_scan_console_plan_init
extern nebo_scan_console_plan_metadata_sparse
extern nebo_scan_console_plan_metadata
extern nebo_scan_console_plan_multiline
extern nebo_scan_console_plan_choices
extern nebo_scan_console_plan_security
extern nebo_scan_console_request_build
extern nebo_scan_console_response_commit
extern nebo_scan_console_response_apply
extern nebo_scan_console_should_retry
extern nebo_scan_console_replay_validate
extern nebo_scan_console_select_backend
extern nebo_scan_console_evidence_observe
extern nebo_scan_console_zeroize
extern nebo_scan_console_evidence_validate
extern nebo_scan_console_adapter_validate
extern nebo_form_metadata_validate
extern nebo_feedback_style_validate
extern nebo_multiline_input_validate
extern nebo_choice_model_validate
extern nebo_security_policy_validate
extern nebo_request_response_validate
extern nebo_validation_retry_validate
extern nebo_live_fallback_replay_validate
extern nebo_scan_console_forms_choices_e_input_visual_closeout_contract_validate
%endif

%endif
