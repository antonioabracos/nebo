%ifndef NEBO_SCAN_PLAN_INC
%define NEBO_SCAN_PLAN_INC 1

SCAN_MIN_FEATURE_ID equ 7501
SCAN_MAX_FEATURE_ID equ 7806

SCAN_MAX_INPUT_BYTES equ 4096
SCAN_MAX_LINES       equ 256
SCAN_MAX_CHOICES     equ 32
SCAN_MAX_ATTEMPTS    equ 8
SCAN_MAX_CAPTURES    equ 32

SCAN_KIND_TEXT       equ 1
SCAN_KIND_INT        equ 2
SCAN_KIND_NUMBER     equ 3
SCAN_KIND_BOOL       equ 4
SCAN_KIND_CHAR       equ 5
SCAN_KIND_RAW        equ 6
SCAN_KIND_MULTILINE  equ 7
SCAN_KIND_LINE       equ 8
SCAN_KIND_TOKEN      equ 9
SCAN_KIND_WORDS      equ 10
SCAN_KIND_LIST       equ 11
SCAN_KIND_TUPLE      equ 12
SCAN_KIND_DATE       equ 13
SCAN_KIND_TIME       equ 14
SCAN_KIND_DATETIME   equ 15
SCAN_KIND_EMAIL      equ 16
SCAN_KIND_URL        equ 17
SCAN_KIND_PATH       equ 18
SCAN_KIND_PASSWORD   equ 19
SCAN_KIND_JSON       equ 20
SCAN_KIND_MAX        equ SCAN_KIND_JSON

SCAN_FLAG_REQUIRED        equ 0x0001
SCAN_FLAG_OPTIONAL        equ 0x0002
SCAN_FLAG_ALLOW_EMPTY     equ 0x0004
SCAN_FLAG_TRIM            equ 0x0008
SCAN_FLAG_LOWER           equ 0x0010
SCAN_FLAG_UPPER           equ 0x0020
SCAN_FLAG_COLLAPSE_SPACES equ 0x0040
SCAN_FLAG_CHOMP           equ 0x0080
SCAN_FLAG_SECRET          equ 0x0100
SCAN_FLAG_NO_HISTORY      equ 0x0200
SCAN_FLAG_REDACT          equ 0x0400
SCAN_FLAG_UNTRUSTED       equ 0x0800
SCAN_FLAG_RESULT          equ 0x1000
SCAN_FLAG_EOF_NONE        equ 0x2000

SCAN_TEXT_NO_CONTROL equ 0x01
SCAN_TEXT_DIGITS     equ 0x02
SCAN_TEXT_LETTERS    equ 0x04
SCAN_TEXT_ALNUM      equ 0x08

SCAN_INT_EVEN        equ 0x01
SCAN_INT_ODD         equ 0x02
SCAN_INT_POSITIVE    equ 0x04
SCAN_INT_NONNEGATIVE equ 0x08

SCAN_SOURCE_MOCK   equ 1
SCAN_SOURCE_REPLAY equ 2
SCAN_SOURCE_STDIN  equ 3
SCAN_SOURCE_PIPE   equ 4
SCAN_SOURCE_FILE   equ 5
SCAN_SOURCE_ENV    equ 6
SCAN_SOURCE_ARGS   equ 7
SCAN_SOURCE_DEVICE equ 8

SCAN_CAP_MOCK   equ 0x01
SCAN_CAP_REPLAY equ 0x02
SCAN_CAP_STDIN  equ 0x04
SCAN_CAP_PIPE   equ 0x08
SCAN_CAP_FILE   equ 0x10
SCAN_CAP_ENV    equ 0x20
SCAN_CAP_ARGS   equ 0x40
SCAN_CAP_DEVICE equ 0x80

SCAN_E_INVALID  equ 1
SCAN_E_LIMIT    equ 2
SCAN_E_CAPACITY equ 3
SCAN_E_PARSE    equ 4
SCAN_E_VALIDATE equ 5
SCAN_E_IO       equ 6
SCAN_E_EOF      equ 7
SCAN_E_CANCEL   equ 8

%ifndef NEBO_SCAN_PLAN_IMPLEMENTATION
extern neboc_scan_feature_available
extern neboc_scan_feature_validate
extern neboc_scan_normalize_ascii
extern neboc_scan_parse_int
extern neboc_scan_validate_int
extern neboc_scan_validate_text
extern neboc_scan_choice_index
extern neboc_scan_should_retry
extern neboc_scan_source_validate
extern neboc_scan_multiline_validate
extern neboc_scan_result_resolve
%endif

%endif
