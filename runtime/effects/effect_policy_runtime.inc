%ifndef NEBOC_EFFECT_POLICY_RUNTIME_INC
%define NEBOC_EFFECT_POLICY_RUNTIME_INC 1

%include "compiler/semantic/effect/effect_policy.inc"

; EFFECTS-CAPABILITIES-E-POLITICAS-PF004 native runtime policy-gate request/result.  q0 and q1 are
; caller-owned inputs; q2..q5 are runtime-owned outputs.  The policy record is
; an aligned, disjoint PF001 17-qword value and is never modified.
%define NEBOC_POLICY_RUNTIME_POLICY_RECORD_OFFSET 0
%define NEBOC_POLICY_RUNTIME_REQUESTED_MASK_OFFSET 8
%define NEBOC_POLICY_RUNTIME_DECISION_OFFSET 16
%define NEBOC_POLICY_RUNTIME_DIAGNOSTIC_OFFSET 24
%define NEBOC_POLICY_RUNTIME_EVENT_HASH_OFFSET 32
%define NEBOC_POLICY_RUNTIME_ALLOCATIONS_OFFSET 40

%define NEBOC_POLICY_RUNTIME_REQUEST_SIZE 48
%define NEBOC_POLICY_RUNTIME_REQUEST_QWORDS 6
%define NEBOC_POLICY_RUNTIME_ALIGNMENT 8
%define NEBOC_POLICY_RUNTIME_OUTPUT_OFFSET 16
%define NEBOC_POLICY_RUNTIME_OUTPUT_QWORDS 4
%define NEBOC_POLICY_RUNTIME_EVENT_HASHED_BYTES 32
%define NEBOC_POLICY_RUNTIME_ALLOCATION_NONE 0

; Short canonical aliases consumed by subsequent effects_capabilities_e_politicas stages.  Keep the ABI
; values literal so static contract validators can audit q0..q5 directly.
%define NEBOC_RUNTIME_POLICY_RECORD_OFFSET 0
%define NEBOC_RUNTIME_POLICY_PTR_OFFSET 0
%define NEBOC_RUNTIME_REQUESTED_MASK_OFFSET 8
%define NEBOC_RUNTIME_REQUESTED_EFFECTS_OFFSET 8
%define neboc_effects_capabilities_e_politicas_RUNTIME_DECISION_OFFSET 16
%define neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET 24
%define neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASH_OFFSET 32
%define neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATIONS_OFFSET 40
%define neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE 48
%define neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS 6
%define neboc_effects_capabilities_e_politicas_RUNTIME_ALIGNMENT 8
%define neboc_effects_capabilities_e_politicas_RUNTIME_OUTPUT_OFFSET 16
%define neboc_effects_capabilities_e_politicas_RUNTIME_OUTPUT_QWORDS 4
%define neboc_effects_capabilities_e_politicas_RUNTIME_EVENT_HASHED_BYTES 32
%define neboc_effects_capabilities_e_politicas_RUNTIME_ALLOCATION_NONE 0

; PF004 authenticates the complete frozen PF001 representation.  Fail the
; assembly if the evaluator owner changes a boundary without an ABI migration.
%if NEBOC_POLICY_REQUEST_QWORDS != 17
    %error "G21 runtime/PF001 policy qword count drift"
%endif
%if NEBOC_POLICY_REQUEST_SIZE != 136
    %error "G21 runtime/PF001 policy size drift"
%endif
%if NEBOC_POLICY_AUDIT_HASH_OFFSET != 120
    %error "G21 runtime/PF001 audit-hash offset drift"
%endif
%if NEBOC_POLICY_DECISION_OFFSET != 128
    %error "G21 runtime/PF001 decision offset drift"
%endif

%endif
