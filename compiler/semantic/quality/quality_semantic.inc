%ifndef NEBOC_QUALITY_SEMANTIC_INC
%define NEBOC_QUALITY_SEMANTIC_INC 1

%include "compiler/parser/quality_contract.inc"

; q0..q12 embed the PF002 descriptor and q13..q62 embed the complete PF001
; authenticated record. q63..q68 are semantic-owned, pointerless outputs.
%define neboc_quality_confidence_e_lineage_SEMANTIC_SYNTAX_OFFSET 0
%define NEBOC_SEMANTIC_QUALITY_OFFSET 104
%define neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET 504
%define NEBOC_SEMANTIC_EFFECTIVE_QUALITY_OFFSET 512
%define NEBOC_SEMANTIC_EFFECTIVE_CONFIDENCE_OFFSET 520
%define NEBOC_SEMANTIC_LINEAGE_HASH_OFFSET 528
%define neboc_quality_confidence_e_lineage_SEMANTIC_HASH_OFFSET 536
%define neboc_quality_confidence_e_lineage_SEMANTIC_ALLOCATIONS_OFFSET 544
%define neboc_quality_confidence_e_lineage_SEMANTIC_HASHED_BYTES 536
%define neboc_quality_confidence_e_lineage_SEMANTIC_REQUEST_SIZE 552
%define neboc_quality_confidence_e_lineage_SEMANTIC_REQUEST_QWORDS 69
%define neboc_quality_confidence_e_lineage_SEMANTIC_ALIGNMENT 8
%define NEBOC_SEMANTIC_TYPE_INT 1
%define neboc_quality_confidence_e_lineage_SEMANTIC_ALLOCATION_NONE 0

%if NEBOC_SEMANTIC_QUALITY_OFFSET != neboc_quality_confidence_e_lineage_RESULT_SIZE
    %error "quality_confidence_e_lineage semantic/syntax boundary drift"
%endif
%if neboc_quality_confidence_e_lineage_SEMANTIC_RESULT_TYPE_OFFSET != NEBOC_SEMANTIC_QUALITY_OFFSET + neboc_quality_confidence_e_lineage_REQUEST_SIZE
    %error "quality_confidence_e_lineage semantic/quality boundary drift"
%endif

%endif
