%ifndef NEBOC_PRIVACY_POLICY_INC
%define NEBOC_PRIVACY_POLICY_INC 1

%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/diagnostics/catalog.inc"

; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF001 embeds the complete effects_capabilities_e_politicas request/result at q0..q16.  The privacidade_dados_sensiveis_e_zero_trust
; extension remains pointerless: q17..q27 are caller-owned metadata inputs and
; q28..q34 are evaluator-owned derived metadata outputs.
%define NEBOC_PRIVACY_POLICY_OFFSET 0
%define NEBOC_PRIVACY_DIRECT_LABELS_OFFSET 136
%define NEBOC_PRIVACY_CALLEE_LABELS_OFFSET 144
%define NEBOC_PRIVACY_REDACTION_MASK_OFFSET 152
%define NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET 160
%define NEBOC_PRIVACY_TRANSITION_OFFSET 168
%define NEBOC_PRIVACY_SOURCE_TRUST_OFFSET 176
%define NEBOC_PRIVACY_TARGET_TRUST_OFFSET 184
%define NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET 192
%define NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET 200
%define NEBOC_PRIVACY_PURPOSE_ID_OFFSET 208
%define NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET 216
%define NEBOC_PRIVACY_INFERRED_LABELS_OFFSET 224
%define NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET 232
%define NEBOC_PRIVACY_REJECTED_LABELS_OFFSET 240
%define NEBOC_PRIVACY_PROVENANCE_FLAGS_OFFSET 248
%define NEBOC_PRIVACY_DIAGNOSTIC_OFFSET 256
%define NEBOC_PRIVACY_METADATA_HASH_OFFSET 264
%define NEBOC_PRIVACY_DECISION_OFFSET 272
%define NEBOC_PRIVACY_HASHED_BYTES 264
%define NEBOC_PRIVACY_REQUEST_SIZE 280
%define NEBOC_PRIVACY_REQUEST_QWORDS 35
%define NEBOC_PRIVACY_ALIGNMENT 8

%if NEBOC_PRIVACY_DIRECT_LABELS_OFFSET != NEBOC_POLICY_REQUEST_SIZE
    %error "privacidade_dados_sensiveis_e_zero_trust privacy record must embed the complete effects_capabilities_e_politicas policy record"
%endif

; Public is the empty set.  The remaining classifications are independent,
; composable taint bits rather than an accidental total order.
%define NEBOC_LABEL_PUBLIC 0
%define NEBOC_LABEL_INTERNAL (1 << 0)
%define NEBOC_LABEL_PERSONAL (1 << 1)
%define NEBOC_LABEL_SENSITIVE (1 << 2)
%define NEBOC_LABEL_SECRET (1 << 3)
%define NEBOC_LABEL_MASK_KNOWN 0x0f

%define NEBOC_TRANSITION_PRESERVE 0
%define NEBOC_TRANSITION_REDACT 1
%define NEBOC_TRANSITION_MAX NEBOC_TRANSITION_REDACT

%define NEBOC_PROVENANCE_PROPAGATED (1 << 0)
%define NEBOC_PROVENANCE_REDACTED (1 << 1)
%define NEBOC_PROVENANCE_POLICY_AUTHENTICATED (1 << 2)
%define NEBOC_PROVENANCE_TRUST_TRANSITION (1 << 3)
%define NEBOC_PROVENANCE_RETENTION_VALID (1 << 4)
%define NEBOC_PROVENANCE_SINK_AUTHORIZED (1 << 5)

%define NEBOC_PRIVACY_DECISION_DENY 0
%define NEBOC_PRIVACY_DECISION_PERMIT 1
%define NEBOC_RETENTION_MAX 65535

; PF002 promotes the six PF001-reserved ordinals into the shared catalogue;
; semantic code consumes the catalogue symbols as the single numeric source.
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_diagnostics
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_diagnostics
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_diagnostics
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_diagnostics
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_RUNTIME_driver_cli_linux_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_RUNTIME_diagnostics
%define neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64 neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_diagnostics

%endif
