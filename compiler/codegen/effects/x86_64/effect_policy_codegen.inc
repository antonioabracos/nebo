%ifndef NEBOC_EFFECT_POLICY_CODEGEN_INC
%define NEBOC_EFFECT_POLICY_CODEGEN_INC 1

; EFFECTS-CAPABILITIES-E-POLITICAS-PF005 bounded policy-program emitter request.  q0..q2 are immutable
; inputs; q3..q5 are published only after authenticated, transactional emit.
%define neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET 0
%define neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET 8
%define neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET 16
%define neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_OFFSET 24
%define neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET 32
%define neboc_effects_capabilities_e_politicas_CODEGEN_HASH_OFFSET 40
%define neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE 48
%define neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS 6

%define neboc_effects_capabilities_e_politicas_CODEGEN_ALIGNMENT 8
%define NEBOC_CODEGEN_OUTPUT_OFFSET 24
%define NEBOC_CODEGEN_OUTPUT_QWORDS 3
%define NEBOC_CODEGEN_EMITTED_NONE 0
%define neboc_effects_capabilities_e_politicas_CODEGEN_EMITTED_START 1

%if neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS * 8 != neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    %error "effects_capabilities_e_politicas codegen request size drift"
%endif
%if NEBOC_CODEGEN_OUTPUT_OFFSET + NEBOC_CODEGEN_OUTPUT_QWORDS * 8 != neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
    %error "effects_capabilities_e_politicas codegen output region drift"
%endif

%endif
