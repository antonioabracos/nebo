%ifndef NEBOC_OPERATOR_PROVENANCE_INC
%define NEBOC_OPERATOR_PROVENANCE_INC 1

%include "compiler/tokens/operator_registry.inc"

; Lossless provenance carried from lexing into contextual interpretation.
; All offsets are half-open byte offsets in the original immutable source.
; neboc_operator_lexeme_provenance(source, remaining, source_id, start, output)
; fills one record atomically after exact generated-Registry lookup.
%define NEBOC_OPERATOR_PROVENANCE_REGISTRY_ID_OFFSET 0
%define NEBOC_OPERATOR_PROVENANCE_ATOM_INDEX_OFFSET 8
%define NEBOC_OPERATOR_PROVENANCE_SOURCE_ID_OFFSET 16
%define NEBOC_OPERATOR_PROVENANCE_START_OFFSET 24
%define NEBOC_OPERATOR_PROVENANCE_END_OFFSET 32
%define NEBOC_OPERATOR_PROVENANCE_BYTE_LENGTH_OFFSET 40
%define NEBOC_OPERATOR_PROVENANCE_CODEPOINT_COUNT_OFFSET 48
%define NEBOC_OPERATOR_PROVENANCE_FLAGS_OFFSET 56
%define NEBOC_OPERATOR_PROVENANCE_SIZE 64

%define NEBOC_OPERATOR_PROVENANCE_FLAG_NONE 0
%define NEBOC_OPERATOR_PROVENANCE_FLAG_ASCII_CANONICAL 1
%define NEBOC_OPERATOR_PROVENANCE_FLAG_UNICODE_ALIAS 2
%define NEBOC_OPERATOR_PROVENANCE_FLAG_CONTEXTUAL 4
%define NEBOC_OPERATOR_PROVENANCE_FLAG_SKIPPED 8

; Bounded batch request.  Written stays zero unless the entire batch fits;
; consumers must therefore preserve failure atomicity.
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_TOKENS_OFFSET 0
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_TOKEN_COUNT_OFFSET 8
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_OUTPUT_OFFSET 16
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_CAPACITY_OFFSET 24
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_WRITTEN_OFFSET 32
%define NEBOC_OPERATOR_PROVENANCE_REQUEST_SIZE 40

%define NEBOC_OPERATOR_PROVENANCE_MAX_BATCH 65536
%define NEBOC_OPERATOR_PROVENANCE_MAX_SOURCE_BYTES 1073741824

%if NEBOC_OPERATOR_PROVENANCE_END_OFFSET <= NEBOC_OPERATOR_PROVENANCE_START_OFFSET
 %error "operator provenance must retain an ordered half-open span"
%endif
%if NEBOC_OPERATOR_PROVENANCE_SIZE & 7
 %error "operator provenance ABI must remain eight-byte aligned"
%endif
%if NEBOC_OPERATOR_REGISTRY_MAX_LEXEME_BYTES > NEBOC_OPERATOR_PROVENANCE_MAX_SOURCE_BYTES
 %error "operator provenance source bound is smaller than one lexeme"
%endif

%endif
