%ifndef NEBOC_QUALITY_LINEAGE_INC
%define NEBOC_QUALITY_LINEAGE_INC 1

%include "compiler/semantic/privacy/privacy_policy.inc"
%include "compiler/diagnostics/catalog.inc"

; QUALITY-CONFIDENCE-E-LINEAGE-PF001 embeds the complete authenticated privacidade_dados_sensiveis_e_zero_trust request/result at q0..q34.
; q35..q43 are pointerless caller metadata; q44..q49 are derived outputs.
%define NEBOC_DIRECT_QUALITY_OFFSET 280
%define NEBOC_INHERITED_QUALITY_OFFSET 288
%define NEBOC_DIRECT_CONFIDENCE_OFFSET 296
%define NEBOC_INHERITED_CONFIDENCE_OFFSET 304
%define NEBOC_MIN_QUALITY_OFFSET 312
%define NEBOC_MIN_CONFIDENCE_OFFSET 320
%define NEBOC_SOURCE_ID_OFFSET 328
%define NEBOC_TRANSFORM_ID_OFFSET 336
%define NEBOC_PARENT_LINEAGE_HASH_OFFSET 344
%define NEBOC_EFFECTIVE_QUALITY_OFFSET 352
%define NEBOC_EFFECTIVE_CONFIDENCE_OFFSET 360
%define NEBOC_PROVENANCE_FLAGS_OFFSET 368
%define NEBOC_LINEAGE_HASH_OFFSET 376
%define neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET 384
%define neboc_quality_confidence_e_lineage_DECISION_OFFSET 392
%define neboc_quality_confidence_e_lineage_HASHED_BYTES 376
%define neboc_quality_confidence_e_lineage_REQUEST_SIZE 400
%define NEBOC_REQUEST_QWORDS 50
%define neboc_quality_confidence_e_lineage_ALIGNMENT 8

%if NEBOC_DIRECT_QUALITY_OFFSET != NEBOC_PRIVACY_REQUEST_SIZE
    %error "quality_confidence_e_lineage record must embed the complete privacidade_dados_sensiveis_e_zero_trust privacy record"
%endif

%define NEBOC_SCORE_SCALE 1000000
%define NEBOC_PROVENANCE_PRIVACY_AUTHENTICATED (1 << 0)
%define NEBOC_PROVENANCE_QUALITY_PROPAGATED (1 << 1)
%define NEBOC_PROVENANCE_CONFIDENCE_PROPAGATED (1 << 2)
%define NEBOC_PROVENANCE_LINEAGE_BOUND (1 << 3)
%define neboc_quality_confidence_e_lineage_DECISION_DENY 0
%define neboc_quality_confidence_e_lineage_DECISION_PERMIT 1

; PF001 reserves the contiguous quality_confidence_e_lineage namespace. PF002 promotes it to the
; shared catalogue and replaces these numeric reservations with aliases.
%if NEBOC_DIAG_CATALOG_COUNT = 58
    %define neboc_quality_confidence_e_lineage_DIAG_LEX_driver_cli_linux_x86_64 59
    %define neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64 60
    %define neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64 61
    %define neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64 62
    %define neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64 63
    %define neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64 64
%else
    %define neboc_quality_confidence_e_lineage_DIAG_LEX_driver_cli_linux_x86_64 neboc_quality_confidence_e_lineage_DIAG_LEX_diagnostics
    %define neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64 neboc_quality_confidence_e_lineage_DIAG_PARSE_diagnostics
    %define neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64 neboc_quality_confidence_e_lineage_DIAG_TYPE_diagnostics
    %define neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64 neboc_quality_confidence_e_lineage_DIAG_CODEGEN_diagnostics
    %define neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64 neboc_quality_confidence_e_lineage_DIAG_RUNTIME_diagnostics
    %define neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64 neboc_quality_confidence_e_lineage_DIAG_SECURITY_diagnostics
%endif

%endif
