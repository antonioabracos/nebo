%ifndef NEBOC_POLICY_CONTRACT_INC
%define NEBOC_POLICY_CONTRACT_INC 1

; EFFECTS-CAPABILITIES-E-POLITICAS-PF002 allocation-free source-to-policy parser request.  The aligned
; request, source span and aligned 17-qword output span must be pairwise
; disjoint; overlap is rejected transactionally with INVALID_ARGUMENT.
%define neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET 0
%define neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET 8
%define neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET 16
%define neboc_effects_capabilities_e_politicas_PARSE_ERROR_OFFSET_OFFSET 24
%define neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET 32
%define neboc_effects_capabilities_e_politicas_PARSE_CONSUMED_OFFSET 40
%define neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET 48
%define NEBOC_PARSE_CLAUSE_MASK_OFFSET 56
%define neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE 64
%define neboc_effects_capabilities_e_politicas_PARSE_REQUEST_QWORDS 8
%define neboc_effects_capabilities_e_politicas_PARSE_ALIGNMENT 8
%define neboc_effects_capabilities_e_politicas_PARSE_MAX_SOURCE_BYTES 4096

%define NEBOC_PARSE_CLAUSE_EFFECTS (1 << 0)
%define NEBOC_PARSE_CLAUSE_CAPABILITIES (1 << 1)
%define NEBOC_PARSE_CLAUSE_ALLOW (1 << 2)
%define NEBOC_PARSE_CLAUSE_DENY (1 << 3)
%define NEBOC_PARSE_CLAUSE_BUDGET (1 << 4)
%define NEBOC_PARSE_CLAUSE_TRUST (1 << 5)
%define NEBOC_PARSE_CLAUSE_AUDIT (1 << 6)
%define NEBOC_PARSE_CLAUSE_MASK_COMPLETE 0x7f

%define NEBOC_PARSE_HASHED_OUTPUT_BYTES 80

%endif
