%ifndef NEBOC_PRIVACY_CONTRACT_INC
%define NEBOC_PRIVACY_CONTRACT_INC 1

%include "compiler/semantic/privacy/privacy_policy.inc"
%include "compiler/semantic/types/type_table.inc"

; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF002 allocation-free source-to-syntax parser request.  The aligned
; request, source span and aligned 13-qword result span must be pairwise
; disjoint.  Invalid transport arguments are rejected without writes.
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_OFFSET 0
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET 8
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET 16
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_ERROR_OFFSET_OFFSET 24
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_DIAGNOSTIC_OFFSET 32
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CONSUMED_OFFSET 40
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_CANONICAL_HASH_OFFSET 48
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_FEATURE_MASK_OFFSET 56
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_SIZE 64
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_QWORDS 8
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_ALIGNMENT 8
%define neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_MAX_SOURCE_BYTES 4096

%define NEBOC_PARSE_FEATURE_WRAPPER (1 << 0)
%define NEBOC_PARSE_FEATURE_TYPE (1 << 1)
%define NEBOC_PARSE_FEATURE_REDACT (1 << 2)
%define NEBOC_PARSE_FEATURE_MASK_BASE 0x03
%define NEBOC_PARSE_FEATURE_MASK_COMPLETE 0x07

; Pointerless syntax descriptor.  q0..q4 alone define the canonical shape;
; source-relative spans and statement length are intentionally excluded from the
; hash so ASCII formatting cannot change identity.
%define NEBOC_PRIVACY_RESULT_WRAPPER_KIND_OFFSET 0
%define NEBOC_PRIVACY_RESULT_PAYLOAD_TYPE_ID_OFFSET 8
%define NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET 16
%define NEBOC_PRIVACY_RESULT_REDACTION_MASK_OFFSET 24
%define NEBOC_PRIVACY_RESULT_FLAGS_OFFSET 32
%define NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_OFFSET 40
%define NEBOC_PRIVACY_RESULT_WRAPPER_SPAN_LENGTH_OFFSET 48
%define NEBOC_PRIVACY_RESULT_TYPE_SPAN_OFFSET 56
%define NEBOC_PRIVACY_RESULT_TYPE_SPAN_LENGTH_OFFSET 64
; Redact span is half-open from '.' through the closing ')' and is zero when
; the transition is preserve.
%define NEBOC_PRIVACY_RESULT_REDACT_SPAN_OFFSET 72
%define NEBOC_PRIVACY_RESULT_REDACT_SPAN_LENGTH_OFFSET 80
; Statement span starts at q5 and ends just after the required semicolon.
%define NEBOC_PRIVACY_RESULT_STATEMENT_SPAN_LENGTH_OFFSET 88
; Compatibility spelling retained for the PF002 evidence validator; new code
; uses STATEMENT_SPAN_LENGTH to state the half-open q5..semicolon contract.
%define NEBOC_PRIVACY_RESULT_PROOF_SPAN_LENGTH_OFFSET 88
%define NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET 96
%define NEBOC_PRIVACY_RESULT_SIZE 104
%define NEBOC_PRIVACY_RESULT_QWORDS 13
%define NEBOC_PRIVACY_RESULT_ALIGNMENT 8
%define NEBOC_PRIVACY_HASHED_OUTPUT_BYTES 40

%define NEBOC_PRIVACY_WRAPPER_SECRET 1
%define NEBOC_PRIVACY_WRAPPER_PERSONAL_DATA 2
%define NEBOC_PRIVACY_PAYLOAD_TYPE_INT NEBOC_TYPE_ID_INT
%define NEBOC_PRIVACY_PAYLOAD_TYPE_TEXT NEBOC_TYPE_ID_TEXT
%define NEBOC_PRIVACY_FLAG_CANONICAL (1 << 0)
%define NEBOC_PRIVACY_FLAG_HAS_REDACT (1 << 1)

%endif
