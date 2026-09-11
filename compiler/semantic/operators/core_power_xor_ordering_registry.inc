%ifndef NEBOC_CORE_POWER_XOR_ORDERING_REGISTRY_INC
%define NEBOC_CORE_POWER_XOR_ORDERING_REGISTRY_INC 1

; G123's closed semantic Registry slice. Every public dispatch first maps its
; token to one of these stable IDs; token recognition alone never activates an
; implementation or a domain bridge.
%define NEBOC_CORE_PXO_REGISTRY_SCHEMA_VERSION 1
%define NEBOC_CORE_PXO_REGISTRY_ENTRY_COUNT 12

%define NEBOC_CORE_PXO_ENTRY_ID_OFFSET 0
%define NEBOC_CORE_PXO_ENTRY_TOKEN_OFFSET 8
%define NEBOC_CORE_PXO_ENTRY_FIXITY_OFFSET 16
%define NEBOC_CORE_PXO_ENTRY_CONTEXTS_OFFSET 24
%define NEBOC_CORE_PXO_ENTRY_PRECEDENCE_OFFSET 32
%define NEBOC_CORE_PXO_ENTRY_ASSOCIATIVITY_OFFSET 40
%define NEBOC_CORE_PXO_ENTRY_PROTOCOL_OFFSET 48
%define NEBOC_CORE_PXO_ENTRY_STATE_OFFSET 56
%define NEBOC_CORE_PXO_ENTRY_FLAGS_OFFSET 64
%define NEBOC_CORE_PXO_ENTRY_SIZE 72

%define NEBOC_CORE_PXO_FLAG_CHECKED 1
%define NEBOC_CORE_PXO_FLAG_EXACT_TYPES 2
%define NEBOC_CORE_PXO_FLAG_RIGHT_LAZY 4
%define NEBOC_CORE_PXO_FLAG_DOMAIN_BRIDGES 8
%define NEBOC_CORE_PXO_FLAG_THREE_WAY 16
%define NEBOC_CORE_PXO_FLAG_COHERENT 32

; token register, Registry-ID register, rejection label
%macro NEBOC_CORE_PXO_CLASSIFY 3
 cmp %1,NEBOC_TOKEN_CARET
 je %%power
 cmp %1,NEBOC_TOKEN_BANG
 je %%not
 cmp %1,NEBOC_TOKEN_AND_AND
 je %%and
 cmp %1,NEBOC_TOKEN_OR_OR
 je %%or
 cmp %1,NEBOC_TOKEN_XOR
 je %%xor
 cmp %1,NEBOC_TOKEN_LESS
 je %%less
 cmp %1,NEBOC_TOKEN_LESS_EQUAL
 je %%less_equal
 cmp %1,NEBOC_TOKEN_GREATER
 je %%greater
 cmp %1,NEBOC_TOKEN_GREATER_EQUAL
 je %%greater_equal
 cmp %1,NEBOC_TOKEN_EQUAL_EQUAL
 je %%equal
 cmp %1,NEBOC_TOKEN_BANG_EQUAL
 je %%not_equal
 cmp %1,NEBOC_TOKEN_SPACESHIP
 je %%spaceship
 jmp %3
%%power: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_017
 jmp %%done
%%not: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_020
 jmp %%done
%%and: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_021
 jmp %%done
%%or: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_022
 jmp %%done
%%xor: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_023
 jmp %%done
%%less: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_024
 jmp %%done
%%less_equal: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_025
 jmp %%done
%%greater: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_026
 jmp %%done
%%greater_equal: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_027
 jmp %%done
%%equal: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_028
 jmp %%done
%%not_equal: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_029
 jmp %%done
%%spaceship: mov %2,NEBOC_OPERATOR_ID_NSR_CORE_030
%%done:
%endmacro

%if NEBOC_CORE_PXO_ENTRY_SIZE & 7
 %error "G123 Registry ABI must be eight-byte aligned"
%endif

%endif
