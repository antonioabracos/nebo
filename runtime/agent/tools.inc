%ifndef NEBO_TOOLS_INC
%define NEBO_TOOLS_INC 1
%define NEBO_TOOL_OK 0
%define NEBO_TOOL_E_ARGUMENT 1
%define NEBO_TOOL_E_LIMIT 2
%define NEBO_TOOL_E_UNKNOWN 3
%define NEBO_TOOL_E_DENIED 4
%define NEBO_TOOL_E_SCHEMA 5
%define NEBO_TOOL_MAX_REGISTRY 16
%define NEBO_TOOL_MAX_CALLS 8
%define NEBO_TOOL_MAX_ARGS 4096
%ifndef NEBO_TOOLS_IMPLEMENTATION
extern nebo_tool_registry_init
extern nebo_tool_register
extern nebo_tool_call
extern nebo_tool_remaining
%endif
%endif
