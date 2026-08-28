%ifndef NEBO_CONSOLE_WINDOW_CHROME_INC
%define NEBO_CONSOLE_WINDOW_CHROME_INC 1

%include "runtime/console/render/software_surface.inc"

; Canonical native custom-chrome profile at scale factor 1.0. Render and
; hit-testing share this geometry; live frontends must not duplicate it.
%define NEBO_CHROME_BORDER_PX 1
%define NEBO_CHROME_HEIGHT_PX 28
%define NEBO_CHROME_CONTROL_WIDTH_PX 28
%define NEBO_CHROME_CONTROL_COUNT 3
%define NEBO_CHROME_CONTROLS_WIDTH_PX 84
%define NEBO_CHROME_TITLE_LEFT_PADDING_PX 14
%define NEBO_CHROME_TITLE_TOP_PX 7
%define NEBO_CHROME_ICON_SIZE_PX 16
%define NEBO_CHROME_ICON_RIGHT_GAP_PX 8
; Title pixels retain the original 2x bitmap metrics. Live content typography
; and padding are separately owned by live/live_typography.inc so visual
; candidates cannot perturb title/control geometry or hit-testing.
%define NEBO_CHROME_FONT_CELL_WIDTH_PX 12
%define NEBO_CHROME_FONT_CELL_HEIGHT_PX 14
%define NEBO_CHROME_LINE_HEIGHT_PX 18
%define NEBO_CHROME_MIN_WINDOW_WIDTH_PX 128
; First height that satisfies the retained live layout's chrome, two-sided
; padding and one complete 16px content line. 64/65 leave only 14/15px.
%define NEBO_CHROME_MIN_WINDOW_HEIGHT_PX 66
%define NEBO_CHROME_RESIZE_BORDER_PX 5

; Canonical MF044 BGRA8 premultiplied tokens.
%define NEBO_CHROME_COLOR_BORDER 0xFF536178
%define NEBO_CHROME_COLOR_BACKGROUND 0xFF202B3D
; Keep the frozen flags=0 render oracle identical; focus remains a lifecycle
; state and caret/input concern, not a chrome color semantic.
%define NEBO_CHROME_COLOR_BACKGROUND_INACTIVE NEBO_CHROME_COLOR_BACKGROUND
%define NEBO_CHROME_COLOR_CONTROL_HOVER 0xFF33445E
%define NEBO_CHROME_COLOR_CLOSE_HOVER 0xFFD65353
%define NEBO_CHROME_COLOR_FOREGROUND 0xFFF2F6FC

%define NEBO_CHROME_REGION_NONE 0
%define NEBO_CHROME_REGION_DRAG 1
%define NEBO_CHROME_REGION_MINIMIZE 2
%define NEBO_CHROME_REGION_MAXIMIZE_RESTORE 3
%define NEBO_CHROME_REGION_CLOSE 4
%define NEBO_CHROME_REGION_RESIZE_BORDER 5
%define NEBO_CHROME_REGION_CONTENT 6

; Canonical resize directions intentionally match the EWMH moveresize wire
; values 0..7 without making the platform-independent chrome owner include an
; X11 protocol header.
%define NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT 0
%define NEBO_CHROME_RESIZE_DIRECTION_TOP 1
%define NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT 2
%define NEBO_CHROME_RESIZE_DIRECTION_RIGHT 3
%define NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT 4
%define NEBO_CHROME_RESIZE_DIRECTION_BOTTOM 5
%define NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT 6
%define NEBO_CHROME_RESIZE_DIRECTION_LEFT 7

%define NEBO_CHROME_ACTION_NONE 0
%define NEBO_CHROME_ACTION_BEGIN_DRAG 1
%define NEBO_CHROME_ACTION_MINIMIZE 2
%define NEBO_CHROME_ACTION_MAXIMIZE 3
%define NEBO_CHROME_ACTION_RESTORE 4
%define NEBO_CHROME_ACTION_CLOSE 5
%define NEBO_CHROME_ACTION_BEGIN_RESIZE 6

%define NEBO_CHROME_WINDOW_FLAG_MAXIMIZED 1
%define NEBO_CHROME_WINDOW_FLAG_ACTIVE 2
%define NEBO_CHROME_WINDOW_FLAG_HOVER_MINIMIZE 4
%define NEBO_CHROME_WINDOW_FLAG_HOVER_MAXIMIZE 8
%define NEBO_CHROME_WINDOW_FLAG_HOVER_CLOSE 16

%define NEBO_CHROME_STATUS_OK 0
%define NEBO_CHROME_STATUS_INVALID_ARGUMENT 1
%define NEBO_CHROME_STATUS_BAD_STATE 2
%define NEBO_CHROME_STATUS_LIMIT 3

%endif
