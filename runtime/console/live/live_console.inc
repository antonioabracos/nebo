%ifndef NEBO_RUNTIME_LIVE_CONSOLE_INC
%define NEBO_RUNTIME_LIVE_CONSOLE_INC 1

%include "runtime/core/runtime_core.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"
%include "runtime/console/platform/input/native_input_bridge.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/render/software_surface.inc"

%include "runtime/console/chrome/window_chrome.inc"

%define NEBO_LIVE_DEFAULT_WIDTH 640
%define NEBO_LIVE_DEFAULT_HEIGHT 400
%define NEBO_LIVE_X11_SCRATCH_BYTES 65536
%define NEBO_LIVE_XAUTH_BYTES 65536
%define NEBO_LIVE_XAUTH_PATH_BYTES 512
%define NEBO_LIVE_PLAIN_TEXT_BYTES NEBO_CONSOLE_DEFAULT_TEXT_CAPACITY
%define NEBO_LIVE_LAYOUT_BOX_CAPACITY NEBO_CONSOLE_DEFAULT_NODE_CAPACITY
%define NEBO_LIVE_INPUT_TEXT_STRIDE 4096
%define NEBO_LIVE_INPUT_CAPACITY NEBO_INPUT_DEFAULT_CAPACITY
%define NEBO_LIVE_EVENT_WAIT_MS 500
%define NEBO_LIVE_REQUIRED_CAPABILITIES NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
%define NEBO_LIVE_TITLE_MAX_BYTES 256
%define NEBO_LIVE_ICON_MAX_WIDTH 16
%define NEBO_LIVE_ICON_MAX_HEIGHT 16
%define NEBO_LIVE_ICON_BYTES (NEBO_LIVE_ICON_MAX_WIDTH*NEBO_LIVE_ICON_MAX_HEIGHT*4)

; Internal live metadata snapshot, intentionally not a public language API.
%define NEBO_LIVE_CONFIG_WIDTH_OFFSET 0
%define NEBO_LIVE_CONFIG_HEIGHT_OFFSET 8
%define NEBO_LIVE_CONFIG_WINDOW_FLAGS_OFFSET 16
%define NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET 24
%define NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET 32
%define NEBO_LIVE_CONFIG_ICON_PTR_OFFSET 40
%define NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET 48
%define NEBO_LIVE_CONFIG_ICON_HEIGHT_OFFSET 56
%define NEBO_LIVE_CONFIG_ICON_STRIDE_OFFSET 64
%define NEBO_LIVE_CONFIG_REVISION_OFFSET 72
%define NEBO_LIVE_CONFIG_SIZE 80
%define NEBO_LIVE_CONFIG_QWORDS 10

%define NEBO_LIVE_METADATA_STATUS_OK 0
%define NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT 1
%define NEBO_LIVE_METADATA_STATUS_LIMIT 2
%define NEBO_LIVE_METADATA_STATUS_BAD_STATE 3

%define NEBO_LIVE_EVENT_PASS 0
%define NEBO_LIVE_EVENT_CONSUMED 1
%define NEBO_LIVE_EVENT_CLOSE 2
%define NEBO_LIVE_EVENT_ERROR 3

%define NEBO_LIVE_STATE_EMPTY 0
%define NEBO_LIVE_STATE_READY 1
%define NEBO_LIVE_STATE_WINDOW 2
%define NEBO_LIVE_STATE_CLOSED 3
%define NEBO_LIVE_STATE_FAILED 4

%define NEBO_LIVE_STATUS_OK 0
%define NEBO_LIVE_STATUS_HEADLESS 1
%define NEBO_LIVE_STATUS_ENV 2
%define NEBO_LIVE_STATUS_AUTH 3
%define NEBO_LIVE_STATUS_ADAPTER 4
%define NEBO_LIVE_STATUS_WINDOW 5
%define NEBO_LIVE_STATUS_RENDER 6
%define NEBO_LIVE_STATUS_INPUT 7
%define NEBO_LIVE_STATUS_CANCELLED 8

%endif
