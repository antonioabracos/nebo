%ifndef NEBOC_PRIVACY_SEMANTIC_INC
%define NEBOC_PRIVACY_SEMANTIC_INC 1

%include "compiler/parser/privacy_contract.inc"

; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF003 pointerless syntax + contextual semantic envelope.
; q0..q12 embed the PF002 syntax descriptor; q13..q47 embed the complete
; PF001 privacy evaluator record. q48..q50 are semantic-owned outputs.
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_SYNTAX_OFFSET 0
%define NEBOC_SEMANTIC_PRIVACY_OFFSET 104
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET 384
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASH_OFFSET 392
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATIONS_OFFSET 400
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_HASHED_BYTES 392
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_SIZE 408
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_QWORDS 51
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALIGNMENT 8
%define neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_ALLOCATION_NONE 0

%if NEBOC_SEMANTIC_PRIVACY_OFFSET != NEBOC_PRIVACY_RESULT_SIZE
    %error "privacidade_dados_sensiveis_e_zero_trust semantic/syntax boundary drift"
%endif
%if neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_RESULT_TYPE_OFFSET != NEBOC_SEMANTIC_PRIVACY_OFFSET + NEBOC_PRIVACY_REQUEST_SIZE
    %error "privacidade_dados_sensiveis_e_zero_trust semantic/privacy boundary drift"
%endif

%endif
