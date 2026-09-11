bits 64
default rel

%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/tokens/operator_registry.inc"
%include "compiler/parser/expression/operator_precedence.inc"
%include "compiler/parser/expression/binder_grammar.inc"
%include "compiler/diagnostics/operator_diagnostic_schema.inc"
%include "compiler/diagnostics/catalog.inc"

extern neboc_operator_precedence_lookup
extern neboc_operator_precedence_table
extern neboc_fixity_spec_lookup
extern neboc_operator_suffix_lookup
extern neboc_operator_power_contract
extern neboc_operator_arithmetic_lookup
extern neboc_operator_composition_contract
extern neboc_operator_nonassoc_chain_allowed
extern neboc_operator_range_contract
extern neboc_operator_membership_contract
extern neboc_operator_logic_family_lookup
extern neboc_operator_logic_token_lookup
extern neboc_binder_grammar_validate
extern neboc_binder_grammar_spec
extern neboc_binder_grammar_limits
extern neboc_parse_domain_grammar
extern neboc_explain_parse_tree
extern neboc_diagnostic_catalog_lookup

section .data
align 8
valid_binder: dq 1,1,3,4,10,30,0,0
limit_binder: dq 1,1,9,4,10,30,0,0x55
missing_domain_binder: dq 1,0,3,4,10,30,0,0x66

section .bss
align 8
diagnostic_entry: resb NEBOC_DIAG_ENTRY_SIZE
parse_explanation: resb NEBOC_OPERATOR_EXPLAIN_SIZE

section .text
global _start
_start:
 call neboc_operator_precedence_table
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_PRECEDENCE_ENTRY_COUNT
 jne fail
 cmp ecx,NEBOC_OPERATOR_PRECEDENCE_ENTRY_SIZE
 jne fail
 cmp r8d,NEBOC_OPERATOR_PRECEDENCE_SCHEMA_VERSION
 jne fail
 mov r11,rax
 mov edi,edx
.precedence_row:
 cmp qword [r11+NEBOC_OPERATOR_PRECEDENCE_TOKEN_OFFSET],NEBOC_TOKEN_INVALID
 jbe fail
 cmp qword [r11+NEBOC_OPERATOR_PRECEDENCE_FIXITY_OFFSET],NEBOC_OPERATOR_PARSE_FIXITY_PREFIX
 jb fail
 cmp qword [r11+NEBOC_OPERATOR_PRECEDENCE_FIXITY_OFFSET],NEBOC_OPERATOR_PARSE_FIXITY_CONTEXTUAL
 ja fail
 cmp qword [r11+NEBOC_OPERATOR_PRECEDENCE_LEFT_BP_OFFSET],0
 je fail
 test qword [r11+NEBOC_OPERATOR_PRECEDENCE_FLAGS_OFFSET],NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 add r11,NEBOC_OPERATOR_PRECEDENCE_ENTRY_SIZE
 dec edi
 jnz .precedence_row

 mov edi,NEBOC_TOKEN_STAR
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_MULTIPLICATIVE
 jne fail
 cmp ecx,NEBOC_OPERATOR_BP_MULTIPLICATIVE+1
 jne fail
 cmp r9d,NEBOC_OPERATOR_FAMILY_MULTIPLICATIVE
 jne fail

 mov edi,NEBOC_TOKEN_MINUS
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_PREFIX
 call neboc_fixity_spec_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_BP_PREFIX
 jne fail
 cmp ecx,NEBOC_OPERATOR_BP_PREFIX
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 jne fail

 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_SUFFIX
 call neboc_operator_precedence_lookup
 test rax,rax
 jnz fail

 mov edi,NEBOC_TOKEN_EQUAL_EQUAL
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 call neboc_operator_precedence_lookup
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE
 jz fail

 mov edi,NEBOC_TOKEN_DOT
 call neboc_operator_suffix_lookup
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call neboc_operator_suffix_lookup
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail
 mov edi,NEBOC_TOKEN_PERCENT
 call neboc_operator_suffix_lookup
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail
 mov edi,NEBOC_TOKEN_BANG
 call neboc_operator_suffix_lookup
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail

 call neboc_operator_power_contract
 test eax,eax
 jnz fail
 cmp edx,NEBOC_OPERATOR_BP_POWER
 jne fail
 cmp ecx,NEBOC_OPERATOR_BP_POWER
 jne fail
 cmp r8d,NEBOC_OPERATOR_PARSE_ASSOC_RIGHT
 jne fail

 mov edi,NEBOC_TOKEN_PLUS
 call neboc_operator_arithmetic_lookup
 test rax,rax
 jz fail
 cmp edx,12
 jne fail
 cmp ecx,NEBOC_OPERATOR_FAMILY_ADDITIVE
 jne fail

 call neboc_operator_composition_contract
 cmp ecx,NEBOC_OPERATOR_BP_COMPOSITION
 jne fail
 cmp r8d,NEBOC_OPERATOR_BP_COMPOSITION+1
 jne fail
 cmp r9d,NEBOC_OPERATOR_PARSE_ASSOC_NONASSOC
 jne fail
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 test r10d,NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE
 jz fail

 call neboc_operator_range_contract
 test r9d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 test r9d,NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE
 jz fail
 call neboc_operator_membership_contract
 cmp edx,NEBOC_OPERATOR_FAMILY_MEMBERSHIP
 jne fail
 test r9d,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail
 test r9d,NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 jz fail

 mov edi,NEBOC_OPERATOR_FAMILY_RELATIONAL
 mov esi,NEBOC_OPERATOR_FAMILY_RELATIONAL
 call neboc_operator_nonassoc_chain_allowed
 test eax,eax
 jnz fail
 mov edi,NEBOC_OPERATOR_FAMILY_RELATIONAL
 mov esi,NEBOC_OPERATOR_FAMILY_EQUALITY
 call neboc_operator_nonassoc_chain_allowed
 cmp eax,1
 jne fail

 mov edi,NEBOC_OPERATOR_FAMILY_COALESCE
 call neboc_operator_logic_family_lookup
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_SHORT_CIRCUIT
 jz fail
 cmp r9d,NEBOC_TOKEN_COALESCE
 jne fail
 mov edi,NEBOC_OPERATOR_FAMILY_IMPLICATION
 call neboc_operator_logic_family_lookup
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 jz fail
 cmp r9d,NEBOC_TOKEN_LOGIC_IMPLIES
 jne fail
 mov r11,NEBOC_OPERATOR_ID_NSR_DOM_064
 cmp r10,r11
 jne fail
 mov edi,NEBOC_OPERATOR_FAMILY_EQUIVALENCE
 call neboc_operator_logic_family_lookup
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_ACTIVE_CURRENT
 jz fail
 test r8d,NEBOC_OPERATOR_PARSE_FLAG_NONASSOCIATIVE
 jz fail
 cmp r9d,NEBOC_TOKEN_LOGIC_IFF
 jne fail
 mov r11,NEBOC_OPERATOR_ID_NSR_DOM_065
 cmp r10,r11
 jne fail
 mov edi,NEBOC_TOKEN_RESERVED_EQUAL
 call neboc_operator_logic_token_lookup
 test rax,rax
 jz fail
 cmp edx,NEBOC_OPERATOR_FAMILY_ASSIGNMENT
 jne fail
 test ecx,NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail

 lea rdi,[rel valid_binder]
 call neboc_binder_grammar_validate
 cmp eax,NEBOC_STATUS_OK
 jne fail
 cmp qword [rel valid_binder+56],1
 jne fail
 lea rdi,[rel limit_binder]
 call neboc_binder_grammar_validate
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne fail
 cmp qword [rel limit_binder+56],0x55
 jne fail
 lea rdi,[rel missing_domain_binder]
 call neboc_binder_grammar_validate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel missing_domain_binder+56],0x66
 jne fail
 mov edi,1
 call neboc_binder_grammar_spec
 test rax,rax
 jz fail
 test qword [rax+NEBOC_BINDER_SPEC_FLAGS_OFFSET],NEBOC_OPERATOR_PARSE_FLAG_INACTIVE_CURRENT
 jz fail
 test qword [rax+NEBOC_BINDER_SPEC_FLAGS_OFFSET],NEBOC_OPERATOR_PARSE_FLAG_DOMAIN_GATE_REQUIRED
 jz fail
 call neboc_binder_grammar_limits
 cmp eax,NEBOC_BINDER_MAX_CLAUSES
 jne fail
 cmp edx,NEBOC_BINDER_MAX_NESTING
 jne fail
 cmp ecx,NEBOC_BINDER_REQUEST_SIZE
 jne fail
 cmp r8d,NEBOC_BINDER_SPEC_SIZE
 jne fail
 cmp r9d,NEBOC_BINDER_GRAMMAR_SCHEMA_VERSION
 jne fail
 lea rdi,[rel missing_domain_binder]
 call neboc_parse_domain_grammar
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel missing_domain_binder+56],0x66
 jne fail

 mov edi,NEBOC_TOKEN_STAR
 mov esi,NEBOC_OPERATOR_PARSE_FIXITY_INFIX
 mov edx,NEBOC_OPERATOR_BP_ADDITIVE
 lea rcx,[rel parse_explanation]
 call neboc_explain_parse_tree
 cmp eax,NEBOC_STATUS_OK
 jne fail
 cmp qword [rel parse_explanation+NEBOC_OPERATOR_EXPLAIN_LEFT_BP_OFFSET],NEBOC_OPERATOR_BP_MULTIPLICATIVE
 jne fail
 cmp qword [rel parse_explanation+NEBOC_OPERATOR_EXPLAIN_FAMILY_OFFSET],NEBOC_OPERATOR_FAMILY_MULTIPLICATIVE
 jne fail
 cmp qword [rel parse_explanation+NEBOC_OPERATOR_EXPLAIN_PARENTHESIZE_OFFSET],0
 jne fail

 mov edi,NEBOC_DIAG_PARSE_NONASSOCIATIVE_CHAIN
 lea rsi,[rel diagnostic_entry]
 call neboc_diagnostic_catalog_lookup
 cmp eax,NEBOC_STATUS_OK
 jne fail
 cmp qword [rel diagnostic_entry+NEBOC_DIAG_ENTRY_NAME_OFFSET],0
 je fail
 cmp qword [rel diagnostic_entry+NEBOC_DIAG_ENTRY_MESSAGE_OFFSET],0
 je fail

 mov eax,60
 xor edi,edi
 syscall
fail:
 mov eax,60
 mov edi,1
 syscall

section .note.GNU-stack noalloc noexec nowrite progbits
