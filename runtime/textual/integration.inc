; RF84 O6 bounded cross-system integration ABI
%ifndef INTEGRATION_INC
%define INTEGRATION_INC 1

%define INTEGRATION_OK              0
%define INTEGRATION_INVALID         1
%define INTEGRATION_LIMIT           2
%define INTEGRATION_CAPACITY        3
%define INTEGRATION_CONSOLE_DATA    8

%define INTEGRATION_TEXT            0x01
%define INTEGRATION_FORMAT          0x02
%define INTEGRATION_RENDER_CONSOLE  0x04
%define INTEGRATION_SCAN            0x08
%define INTEGRATION_FORMAT_DATA     0x10
%define INTEGRATION_PRIVACY_UNICODE 0x20
%define INTEGRATION_ALL             0x3f

%define INTEGRATION_MAX_COMPILE_TICKS  1000000
%define INTEGRATION_MAX_RUNTIME_TICKS  1000000
%define INTEGRATION_MAX_TEXT_BYTES     1048576
%define INTEGRATION_MAX_BSS_BYTES      1048576
%define INTEGRATION_MAX_STARTUP_TICKS  1000000

extern integration_front_state
extern registry_counts_write
extern ab_semantic_equal
extern console_options_validate
extern pipeline_require
extern performance_budget_check
extern integration_diagnostic

%endif
