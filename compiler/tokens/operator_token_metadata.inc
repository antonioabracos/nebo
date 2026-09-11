%ifndef NEBOC_OPERATOR_TOKEN_METADATA_INC
%define NEBOC_OPERATOR_TOKEN_METADATA_INC 1

%include "compiler/tokens/operator_registry.inc"

; OperatorAtomMetadata: contextual classification for one generated lexeme atom.
%define OPERATOR_ATOM_META_REGISTRY_ID_OFFSET 0
%define OPERATOR_ATOM_META_TOKEN_KIND_OFFSET 8
%define OPERATOR_ATOM_META_CONTEXTS_OFFSET 16
%define OPERATOR_ATOM_META_FIXITY_OFFSET 24
%define OPERATOR_ATOM_META_DOMAIN_OFFSET 32
%define OPERATOR_ATOM_META_FLAGS_OFFSET 40
%define OPERATOR_ATOM_META_SIZE 48

%if OPERATOR_ATOM_META_SIZE & 7
 %error "operator atom metadata ABI must remain eight-byte aligned"
%endif

%endif
