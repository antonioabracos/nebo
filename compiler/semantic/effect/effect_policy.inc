%ifndef NEBOC_EFFECT_POLICY_INC
%define NEBOC_EFFECT_POLICY_INC 1

%include "compiler/diagnostics/catalog.inc"

; EFFECTS-CAPABILITIES-E-POLITICAS-PF001 pointerless policy request/result.  The first ten qwords are
; caller-owned inputs; the final seven qwords are evaluator-owned outputs.
%define NEBOC_POLICY_DIRECT_EFFECTS_OFFSET 0
%define NEBOC_POLICY_CALLEE_EFFECTS_OFFSET 8
%define NEBOC_POLICY_DECLARED_EFFECTS_OFFSET 16
%define NEBOC_POLICY_CAPABILITIES_OFFSET 24
%define NEBOC_POLICY_ALLOW_OFFSET 32
%define NEBOC_POLICY_DENY_OFFSET 40
%define NEBOC_POLICY_BUDGET_OFFSET 48
%define NEBOC_POLICY_TRUST_OFFSET 56
%define NEBOC_POLICY_AUDIT_ID_OFFSET 64
%define NEBOC_POLICY_PERMIT_OFFSET 72
%define NEBOC_POLICY_INFERRED_EFFECTS_OFFSET 80
%define NEBOC_POLICY_MISSING_EFFECTS_OFFSET 88
%define NEBOC_POLICY_REJECTED_EFFECTS_OFFSET 96
%define NEBOC_POLICY_COST_OFFSET 104
%define NEBOC_POLICY_DIAGNOSTIC_OFFSET 112
%define NEBOC_POLICY_AUDIT_HASH_OFFSET 120
%define NEBOC_POLICY_DECISION_OFFSET 128
%define NEBOC_POLICY_HASHED_BYTES 120
%define NEBOC_POLICY_REQUEST_SIZE 136
%define NEBOC_POLICY_REQUEST_QWORDS 17
%define NEBOC_POLICY_ALIGNMENT 8

%define NEBOC_EFFECT_CONSOLE_WRITE (1 << 0)
%define NEBOC_EFFECT_CONSOLE_READ (1 << 1)
%define NEBOC_EFFECT_FS_READ (1 << 2)
%define NEBOC_EFFECT_FS_WRITE (1 << 3)
%define NEBOC_EFFECT_NET_HTTP (1 << 4)
%define NEBOC_EFFECT_TIME_READ (1 << 5)
%define NEBOC_EFFECT_RANDOM_READ (1 << 6)
%define NEBOC_EFFECT_PROCESS_SPAWN (1 << 7)
%define NEBOC_EFFECT_GPU_COMPUTE (1 << 8)
%define NEBOC_EFFECT_DISTRIBUTED_SEND (1 << 9)
%define NEBOC_EFFECT_UNSAFE (1 << 10)
%define NEBOC_EFFECT_MASK_KNOWN 0x7ff

%define NEBOC_TRUST_PUBLIC 0
%define NEBOC_TRUST_INTERNAL 1
%define NEBOC_TRUST_RESTRICTED 2
%define NEBOC_TRUST_SECRET 3

; Stable catalogue ordinals reserved by EFFECTS-CAPABILITIES-E-POLITICAS-PF001.  PF002 promotes the
; corresponding public names/messages/spans into the shared diagnostics.
%define neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64 neboc_effects_capabilities_e_politicas_DIAG_LEX_diagnostics
%define neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64 neboc_effects_capabilities_e_politicas_DIAG_PARSE_diagnostics
%define neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64 neboc_effects_capabilities_e_politicas_DIAG_TYPE_diagnostics
%define neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64 neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_diagnostics
%define neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64 neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_diagnostics
%define neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64 neboc_effects_capabilities_e_politicas_DIAG_SECURITY_diagnostics

%define NEBOC_POLICY_DECISION_DENY 0
%define NEBOC_POLICY_DECISION_PERMIT 1
%define NEBOC_POLICY_MAX_BUDGET 65535
%define NEBOC_POLICY_MAX_PERMIT 255

%define NEBOC_FNV1A64_OFFSET_BASIS 14695981039346656037
%define NEBOC_FNV1A64_PRIME 1099511628211

%endif
