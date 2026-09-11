%ifndef NEBOC_CORE_ARITHMETIC_REGISTRY_INC
%define NEBOC_CORE_ARITHMETIC_REGISTRY_INC 1

; G122 semantic Registry slice.  Compound spellings remain two lexer atoms
; (the arithmetic token followed by '=') and are classified here before type
; or lowering semantics are selected.
%define NEBOC_CORE_ARITHMETIC_REGISTRY_SCHEMA_VERSION 1
%define NEBOC_CORE_ARITHMETIC_REGISTRY_ENTRY_COUNT 14

%define NEBOC_CORE_ARITHMETIC_ENTRY_ID_OFFSET 0
%define NEBOC_CORE_ARITHMETIC_ENTRY_TOKEN_OFFSET 8
%define NEBOC_CORE_ARITHMETIC_ENTRY_FOLLOW_TOKEN_OFFSET 16
%define NEBOC_CORE_ARITHMETIC_ENTRY_FIXITY_OFFSET 24
%define NEBOC_CORE_ARITHMETIC_ENTRY_CONTEXTS_OFFSET 32
%define NEBOC_CORE_ARITHMETIC_ENTRY_PRECEDENCE_OFFSET 40
%define NEBOC_CORE_ARITHMETIC_ENTRY_ASSOCIATIVITY_OFFSET 48
%define NEBOC_CORE_ARITHMETIC_ENTRY_PROTOCOL_OFFSET 56
%define NEBOC_CORE_ARITHMETIC_ENTRY_STATE_OFFSET 64
%define NEBOC_CORE_ARITHMETIC_ENTRY_FLAGS_OFFSET 72
%define NEBOC_CORE_ARITHMETIC_ENTRY_SIZE 80

%define NEBOC_CORE_ARITHMETIC_FLAG_CHECKED 1
%define NEBOC_CORE_ARITHMETIC_FLAG_MUTATION 2
%define NEBOC_CORE_ARITHMETIC_FLAG_ZERO_STORE_ON_FAILURE 4
%define NEBOC_CORE_ARITHMETIC_FLAG_POWER_ONLY 8

; Classify a compound base token through the G122 Registry IDs before any
; type or lowering rule is selected.  The caller supplies token/id registers
; and one rejection label; local labels remain expansion-private.
%macro NEBOC_CORE_ARITHMETIC_CLASSIFY_COMPOUND 3
 cmp %1,NEBOC_TOKEN_PLUS
 je %%add
 cmp %1,NEBOC_TOKEN_MINUS
 je %%subtract
 cmp %1,NEBOC_TOKEN_STAR
 je %%multiply
 cmp %1,NEBOC_TOKEN_SLASH
 je %%divide
 cmp %1,NEBOC_TOKEN_PERCENT
 je %%remainder
 cmp %1,NEBOC_TOKEN_CARET
 je %%power
 jmp %3
%%add:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_032
 jmp %%done
%%subtract:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_033
 jmp %%done
%%multiply:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_034
 jmp %%done
%%divide:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_035
 jmp %%done
%%remainder:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_036
 jmp %%done
%%power:
 mov %2,NEBOC_OPERATOR_ID_NSR_CORE_037
%%done:
%endmacro

%if NEBOC_CORE_ARITHMETIC_ENTRY_SIZE & 7
 %error "G122 arithmetic Registry ABI must be eight-byte aligned"
%endif

%endif
