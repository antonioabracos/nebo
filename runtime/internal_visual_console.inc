%ifndef NEBO_G110_INTERNAL_VISUAL_CONSOLE_INC
%define NEBO_G110_INTERNAL_VISUAL_CONSOLE_INC 1

; Stable internal status codes. Public Nebo programs never name these services.
%define NEBO_G110_ERROR_INVALID       1
%define NEBO_G110_ERROR_RANGE         2
%define NEBO_G110_ERROR_STATE         3
%define NEBO_G110_ERROR_CAPABILITY    4
%define NEBO_G110_ERROR_LIMIT         5
%define NEBO_G110_ERROR_NOT_FOUND     6
%define NEBO_G110_ERROR_BUSY          7

%define NEBO_G110_CONSOLE_MAGIC       0x4e4247313130434f
%define NEBO_G110_PANEL_MAGIC         0x4e42473131305041

%define NEBO_G110_STATE_EMPTY         0
%define NEBO_G110_STATE_OPEN          1
%define NEBO_G110_STATE_CLOSED        2
%define NEBO_G110_PANEL_ACTIVE        1
%define NEBO_G110_PANEL_REMOVED       2

%define NEBO_G110_MODE_PLAIN          1
%define NEBO_G110_MODE_ANSI           2
%define NEBO_G110_MODE_VISUAL         3
%define NEBO_G110_MODE_HEADLESS       4
%define NEBO_G110_MODE_PROTOCOL       5
%define NEBO_G110_MODE_MAX            5

%define NEBO_G110_THEME_DEFAULT       1
%define NEBO_G110_THEME_DARK          2
%define NEBO_G110_THEME_LIGHT         3
%define NEBO_G110_THEME_HIGH_CONTRAST 4
%define NEBO_G110_THEME_MAX           4

%define NEBO_G110_PANEL_TEXT          1
%define NEBO_G110_PANEL_TABLE         2
%define NEBO_G110_PANEL_CHART         3
%define NEBO_G110_PANEL_TIMELINE      4
%define NEBO_G110_PANEL_TYPE_MAX      4

%define NEBO_G110_CAP_SHOW            1
%define NEBO_G110_CAP_INSPECT         2
%define NEBO_G110_CAP_PANEL           4
%define NEBO_G110_CAP_SNAPSHOT        8
%define NEBO_G110_CAP_ALL             15

%define NEBO_G110_MATURITY_CONTRACT_GREEN                1
%define NEBO_G110_MATURITY_INTERNAL_VISUAL_CONSOLE_GREEN  2
%define NEBO_G110_MATURITY_INTERNAL_PANEL_SERVICE_GREEN   3

; Caller-owned limits record (24 bytes).
%define NEBO_G110_LIMIT_LINES         0
%define NEBO_G110_LIMIT_BYTES         8
%define NEBO_G110_LIMIT_PANELS        16
%define NEBO_G110_LIMIT_SIZE          24

; Caller-owned console state (112 bytes); no allocation and no ambient state.
%define NEBO_G110_CONSOLE_MAGIC_OFS   0
%define NEBO_G110_CONSOLE_STATE       8
%define NEBO_G110_CONSOLE_MODE        16
%define NEBO_G110_CONSOLE_THEME       24
%define NEBO_G110_CONSOLE_MAX_LINES   32
%define NEBO_G110_CONSOLE_MAX_BYTES   40
%define NEBO_G110_CONSOLE_MAX_PANELS  48
%define NEBO_G110_CONSOLE_LINES       56
%define NEBO_G110_CONSOLE_BYTES       64
%define NEBO_G110_CONSOLE_PANELS      72
%define NEBO_G110_CONSOLE_GENERATION  80
%define NEBO_G110_CONSOLE_DIGEST      88
%define NEBO_G110_CONSOLE_CLEANUPS    96
%define NEBO_G110_CONSOLE_CAPS        104
%define NEBO_G110_CONSOLE_SIZE        112
%define NEBO_G110_CONSOLE_QWORDS      14

; Pointer-free status receipt (104 bytes).
%define NEBO_G110_STATUS_STATE        0
%define NEBO_G110_STATUS_MODE         8
%define NEBO_G110_STATUS_THEME        16
%define NEBO_G110_STATUS_MAX_LINES    24
%define NEBO_G110_STATUS_MAX_BYTES    32
%define NEBO_G110_STATUS_MAX_PANELS   40
%define NEBO_G110_STATUS_LINES        48
%define NEBO_G110_STATUS_BYTES        56
%define NEBO_G110_STATUS_PANELS       64
%define NEBO_G110_STATUS_GENERATION   72
%define NEBO_G110_STATUS_DIGEST       80
%define NEBO_G110_STATUS_CLEANUPS     88
%define NEBO_G110_STATUS_MATURITY     96
%define NEBO_G110_STATUS_SIZE         104

; Caller-owned panel state (96 bytes).
%define NEBO_G110_PANEL_MAGIC_OFS     0
%define NEBO_G110_PANEL_ID            8
%define NEBO_G110_PANEL_STATE         16
%define NEBO_G110_PANEL_TYPE          24
%define NEBO_G110_PANEL_TITLE         32
%define NEBO_G110_PANEL_DIGEST        40
%define NEBO_G110_PANEL_ITEMS         48
%define NEBO_G110_PANEL_BYTES         56
%define NEBO_G110_PANEL_GENERATION    64
%define NEBO_G110_PANEL_SNAPSHOT      72
%define NEBO_G110_PANEL_CLEANUPS      80
%define NEBO_G110_PANEL_OWNER         88
%define NEBO_G110_PANEL_SIZE          96
%define NEBO_G110_PANEL_QWORDS        12

; Pointer-free panel lookup/snapshot receipt (88 bytes).
%define NEBO_G110_SNAPSHOT_ID         0
%define NEBO_G110_SNAPSHOT_STATE      8
%define NEBO_G110_SNAPSHOT_TYPE       16
%define NEBO_G110_SNAPSHOT_TITLE      24
%define NEBO_G110_SNAPSHOT_DIGEST     32
%define NEBO_G110_SNAPSHOT_ITEMS      40
%define NEBO_G110_SNAPSHOT_BYTES      48
%define NEBO_G110_SNAPSHOT_GENERATION 56
%define NEBO_G110_SNAPSHOT_IDENTITY   64
%define NEBO_G110_SNAPSHOT_CLEANUPS   72
%define NEBO_G110_SNAPSHOT_MATURITY   80
%define NEBO_G110_SNAPSHOT_SIZE       88

; Historical generated-front compatibility constants. These validate only the
; legacy test harness and do not expose a Nebo language API.
%define NEBO_INTERNAL_ERR_INVALID -22
%define NEBO_INTERNAL_ERR_BOUNDS  -75

%ifndef NEBO_G110_INTERNAL_VISUAL_CONSOLE_IMPLEMENTATION
extern nebo_g110_console_open
extern nebo_g110_console_close
extern nebo_g110_console_status
extern nebo_g110_console_configure
extern nebo_g110_console_configure_headless
extern nebo_g110_console_set_mode
extern nebo_g110_console_set_theme
extern nebo_g110_console_set_limits
extern nebo_g110_console_show
extern nebo_g110_console_inspect
extern nebo_g110_console_fallback_text
extern nebo_g110_panel_create
extern nebo_g110_panel_get
extern nebo_g110_panel_remove
extern nebo_g110_panel_clear
extern nebo_g110_panel_title
extern nebo_g110_panel_type
extern nebo_g110_panel_send
extern nebo_g110_panel_replace
extern nebo_g110_panel_append
extern nebo_g110_panel_snapshot
%endif

%endif
