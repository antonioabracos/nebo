%ifndef NEBO_AGENT_INC
%define NEBO_AGENT_INC 1
%define NEBO_AGENT_OK 0
%define NEBO_AGENT_E_ARGUMENT 1
%define NEBO_AGENT_E_LIMIT 2
%define NEBO_AGENT_E_APPROVAL 3
%define NEBO_AGENT_E_CANCELLED 4
%define NEBO_AGENT_E_UNCOMPENSATED 5
%define NEBO_AGENT_MAX_STEPS 16
%define NEBO_AGENT_MAX_CALLS 8
%define NEBO_AGENT_MAX_APPROVALS 8
%define NEBO_AGENT_MAX_TRACE 65536
%ifndef NEBO_AGENT_IMPLEMENTATION
extern nebo_agent_begin
extern nebo_agent_approve
extern nebo_agent_step
extern nebo_agent_cancel
extern nebo_agent_rollback
%endif
%endif
