%ifndef NEBOC_OPERATOR_DIAGNOSTICS_INC
%define NEBOC_OPERATOR_DIAGNOSTICS_INC 1

; core_operator_tokens_tokens P01 reserves a stable, typed namespace without activating P02 syntax.
; The question-family codes are intentionally distinct: propagation, option
; coalescing, optional chaining and conditional assignment cannot collapse to
; one generic parse/type failure.  Equality and ordering also retain separate
; semantic categories so their supported-type matrices cannot drift together.
%define NEBOC_DIAG_QUESTION_PROPAGATION_CONTEXT 14801
%define NEBOC_DIAG_QUESTION_COALESCE_OPERANDS 14802
%define NEBOC_DIAG_QUESTION_OPTIONAL_CHAIN_RECEIVER 14803
%define NEBOC_DIAG_QUESTION_CONDITIONAL_ASSIGN_TARGET 14804
%define NEBOC_DIAG_EQUALITY_UNSUPPORTED_TYPES 14805
%define NEBOC_DIAG_ORDERING_UNSUPPORTED_TYPES 14806
%define NEBOC_DIAG_RELATION_TYPE_MISMATCH 14807
%define NEBOC_DIAG_OPERATOR_AMBIGUOUS 14808
%define NEBOC_DIAG_OPERATOR_LOOKALIKE 14809
%define NEBOC_DIAG_ASCII_RANGE_SPELLING 14810

%define NEBOC_DIAG_QUESTION_FIRST 14801
%define NEBOC_DIAG_QUESTION_LAST 14804
%define NEBOC_DIAG_RELATION_FIRST 14805
%define NEBOC_DIAG_RELATION_LAST 14808
%define NEBOC_DIAG_OPERATOR_COUNT 10

; Diagnostic phase is part of the contract and prevents late codegen errors.
%define NEBOC_DIAG_PHASE_PARSE 1
%define NEBOC_DIAG_PHASE_RESOLVE 2
%define NEBOC_DIAG_PHASE_TYPE 3
%define NEBOC_DIAG_PHASE_COHERENCE 4

; P02 has activated the bounded question family.  This is reporting metadata,
; never a substitute for lexer/parser/semantic feature gates.
%define NEBOC_QUESTION_SYNTAX_ACTIVE 1
%define NEBOC_EQUALITY_DIAGNOSTIC_UNIFORM 1
%define NEBOC_ORDERING_DIAGNOSTIC_UNIFORM 1

%endif
