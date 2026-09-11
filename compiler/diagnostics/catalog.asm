; Nebo Assembly — initial read-only diagnostic catalog v0
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"

section .rodata
n_cli: db 'NEBO_CLI_USAGE'
n_cli_len equ $-n_cli
m_cli: db 'invalid command-line usage'
m_cli_len equ $-m_cli
n_bom: db 'NEBO_SOURCE_BOM_FORBIDDEN'
n_bom_len equ $-n_bom
m_bom: db 'UTF-8 BOM is forbidden'
m_bom_len equ $-m_bom
n_src_limit: db 'NEBO_SOURCE_TOO_LARGE'
n_src_limit_len equ $-n_src_limit
m_src_limit: db 'source exceeds the configured byte limit'
m_src_limit_len equ $-m_src_limit
n_utf8: db 'NEBO_LEX_INVALID_UTF8'
n_utf8_len equ $-n_utf8
m_utf8: db 'source contains invalid UTF-8'
m_utf8_len equ $-m_utf8
n_char: db 'NEBO_LEX_INVALID_CHARACTER'
n_char_len equ $-n_char
m_char: db 'invalid source character {0}'
m_char_len equ $-m_char
n_expected: db 'NEBO_PARSE_EXPECTED_TOKEN'
n_expected_len equ $-n_expected
m_expected: db 'expected token {0}'
m_expected_len equ $-m_expected
n_undefined: db 'NEBO_NAME_UNDEFINED'
n_undefined_len equ $-n_undefined
m_undefined: db 'undefined name {0}'
m_undefined_len equ $-m_undefined
n_mismatch: db 'NEBO_TYPE_MISMATCH'
n_mismatch_len equ $-n_mismatch
m_mismatch: db 'expected {0}, found {1}'
m_mismatch_len equ $-m_mismatch
n_limit: db 'NEBO_LIMIT_EXCEEDED'
n_limit_len equ $-n_limit
m_limit: db 'resource limit exceeded: {0}'
m_limit_len equ $-m_limit
n_tool: db 'NEBO_TOOLCHAIN_FAILED'
n_tool_len equ $-n_tool
m_tool: db 'external tool failed: {0}'
m_tool_len equ $-m_tool
n_internal: db 'NEBO_INTERNAL_ERROR'
n_internal_len equ $-n_internal
m_internal: db 'internal compiler error'
m_internal_len equ $-m_internal
n_unterminated: db 'NEBO_LEX_UNTERMINATED_TEXT'
n_unterminated_len equ $-n_unterminated
m_unterminated: db 'unterminated Text literal'
m_unterminated_len equ $-m_unterminated
n_escape: db 'NEBO_LEX_INVALID_ESCAPE'
n_escape_len equ $-n_escape
m_escape: db 'invalid Text escape {0}'
m_escape_len equ $-m_escape
n_int_overflow: db 'NEBO_LEX_INT_OVERFLOW'
n_int_overflow_len equ $-n_int_overflow
m_int_overflow: db 'integer literal exceeds signed 64-bit range'
m_int_overflow_len equ $-m_int_overflow
n_block_comment: db 'NEBO_LEX_UNTERMINATED_BLOCK_COMMENT'
n_block_comment_len equ $-n_block_comment
m_block_comment: db 'unterminated nested block comment'
m_block_comment_len equ $-m_block_comment
n_duplicate_start: db 'NEBO_PARSE_DUPLICATE_START'
n_duplicate_start_len equ $-n_duplicate_start
m_duplicate_start: db 'program declares more than one start()'
m_duplicate_start_len equ $-m_duplicate_start
n_top_level: db 'NEBO_PARSE_TOP_LEVEL_STATEMENT'
n_top_level_len equ $-n_top_level
m_top_level: db 'statements are not allowed at top level'
m_top_level_len equ $-m_top_level
n_parse_nesting: db 'NEBO_PARSE_NESTING_LIMIT'
n_parse_nesting_len equ $-n_parse_nesting
m_parse_nesting: db 'parser nesting limit exceeded'
m_parse_nesting_len equ $-m_parse_nesting
n_missing_start: db 'NEBO_PARSE_MISSING_START'
n_missing_start_len equ $-n_missing_start
m_missing_start: db 'program requires exactly one start()'
m_missing_start_len equ $-m_missing_start
n_unsupported_control: db 'NEBO_PARSE_UNSUPPORTED_CONTROL'
n_unsupported_control_len equ $-n_unsupported_control
m_unsupported_control: db 'control feature is reserved but unsupported in Nebo v0.1'
m_unsupported_control_len equ $-m_unsupported_control
n_invalid_control_chain: db 'NEBO_PARSE_INVALID_CONTROL_CHAIN'
n_invalid_control_chain_len equ $-n_invalid_control_chain
m_invalid_control_chain: db 'if/else are statements and cannot be used as fluent chain suffixes'
m_invalid_control_chain_len equ $-m_invalid_control_chain
n_missing_semicolon: db 'NEBO_PARSE_MISSING_SEMICOLON'
n_missing_semicolon_len equ $-n_missing_semicolon
m_missing_semicolon: db "expected ';' after statement"
m_missing_semicolon_len equ $-m_missing_semicolon
n_unexpected_token: db 'NEBO_PARSE_UNEXPECTED_TOKEN'
n_unexpected_token_len equ $-n_unexpected_token
m_unexpected_token: db 'unexpected token while parsing statement'
m_unexpected_token_len equ $-m_unexpected_token
n_nonassoc_chain: db 'NEBO_PARSE_NONASSOCIATIVE_CHAIN'
n_nonassoc_chain_len equ $-n_nonassoc_chain
m_nonassoc_chain: db 'comparison and equality operators cannot be chained without explicit grouping'
m_nonassoc_chain_len equ $-m_nonassoc_chain
n_name_duplicate: db 'NEBO_NAME_DUPLICATE'
n_name_duplicate_len equ $-n_name_duplicate
m_name_duplicate: db 'name is already declared in this scope'
m_name_duplicate_len equ $-m_name_duplicate
n_name_shadow: db 'NEBO_NAME_SHADOW'
n_name_shadow_len equ $-n_name_shadow
m_name_shadow: db 'name would shadow an outer declaration'
m_name_shadow_len equ $-m_name_shadow
n_name_reserved: db 'NEBO_NAME_RESERVED'
n_name_reserved_len equ $-n_name_reserved
m_name_reserved: db 'reserved word cannot be used as a declaration name'
m_name_reserved_len equ $-m_name_reserved
n_type_truthiness: db 'NEBO_TYPE_TRUTHINESS'
n_type_truthiness_len equ $-n_type_truthiness
m_type_truthiness: db 'condition requires Bool; truthiness is forbidden'
m_type_truthiness_len equ $-m_type_truthiness
n_type_operator: db 'NEBO_TYPE_UNSUPPORTED_OPERATOR'
n_type_operator_len equ $-n_type_operator
m_type_operator: db 'operator is not defined for these fundamental types'
m_type_operator_len equ $-m_type_operator
n_type_overflow: db 'NEBO_TYPE_CONSTANT_OVERFLOW'
n_type_overflow_len equ $-n_type_overflow
m_type_overflow: db 'constant Int arithmetic overflows signed 64-bit range'
m_type_overflow_len equ $-m_type_overflow
n_type_div_zero: db 'NEBO_TYPE_DIVISION_BY_ZERO'
n_type_div_zero_len equ $-n_type_div_zero
m_type_div_zero: db 'constant Int division by zero'
m_type_div_zero_len equ $-m_type_div_zero
n_type_return_inconsistent: db 'NEBO_TYPE_INCONSISTENT_RETURN'
n_type_return_inconsistent_len equ $-n_type_return_inconsistent
m_type_return_inconsistent: db 'function returns inconsistent fundamental types'
m_type_return_inconsistent_len equ $-m_type_return_inconsistent
n_type_missing_return: db 'NEBO_TYPE_MISSING_RETURN'
n_type_missing_return_len equ $-n_type_missing_return
m_type_missing_return: db 'value-returning function can fall through without return'
m_type_missing_return_len equ $-m_type_missing_return
n_type_void_binding: db 'NEBO_TYPE_VOID_BINDING'
n_type_void_binding_len equ $-n_type_void_binding
m_type_void_binding: db 'Void call result cannot be bound'
m_type_void_binding_len equ $-m_type_void_binding
n_call_receiver: db 'NEBO_CALL_INVALID_RECEIVER'
n_call_receiver_len equ $-n_call_receiver
m_call_receiver: db 'no overload accepts this receiver type'
m_call_receiver_len equ $-m_call_receiver
n_call_arity: db 'NEBO_CALL_ARITY'
n_call_arity_len equ $-n_call_arity
m_call_arity: db 'call positional argument count does not match signature'
m_call_arity_len equ $-m_call_arity
n_call_argument: db 'NEBO_CALL_ARGUMENT_TYPE'
n_call_argument_len equ $-n_call_argument
m_call_argument: db 'call positional argument type does not match signature'
m_call_argument_len equ $-m_call_argument
n_call_recursion: db 'NEBO_CALL_RECURSION'
n_call_recursion_len equ $-n_call_recursion
m_call_recursion: db 'recursive call cycle is not supported in Nebo v0.1'
m_call_recursion_len equ $-m_call_recursion
n_call_undefined: db 'NEBO_CALL_UNDEFINED'
n_call_undefined_len equ $-n_call_undefined
m_call_undefined: db 'no function signature matches this call name'
m_call_undefined_len equ $-m_call_undefined
n_call_nested: db 'NEBO_CALL_NESTED_FUNCTION'
n_call_nested_len equ $-n_call_nested
m_call_nested: db 'nested functions are not supported in Nebo v0.1'
m_call_nested_len equ $-m_call_nested
n_call_duplicate: db 'NEBO_CALL_DUPLICATE_SIGNATURE'
n_call_duplicate_len equ $-n_call_duplicate
m_call_duplicate: db 'duplicate function signature'
m_call_duplicate_len equ $-m_call_duplicate
n_behavior_unsupported: db 'NEBO_BEHAVIOR_NOT_SUPPORTED'
n_behavior_unsupported_len equ $-n_behavior_unsupported
m_behavior_unsupported: db 'function does not accept this behavior descriptor'
m_behavior_unsupported_len equ $-m_behavior_unsupported
n_behavior_conflict: db 'NEBO_BEHAVIOR_CONFLICT'
n_behavior_conflict_len equ $-n_behavior_conflict
m_behavior_conflict: db 'exclusive behavior conflict in one call'
m_behavior_conflict_len equ $-m_behavior_conflict
n_behavior_effectful: db 'NEBO_BEHAVIOR_EFFECTFUL'
n_behavior_effectful_len equ $-n_behavior_effectful
m_behavior_effectful: db 'behavior descriptors must be PURE in Nebo v0.1'
m_behavior_effectful_len equ $-m_behavior_effectful
n_control_condition: db 'NEBO_CONTROL_CONDITION_TYPE'
n_control_condition_len equ $-n_control_condition
m_control_condition: db 'if and logical conditions require Bool'
m_control_condition_len equ $-m_control_condition
n_control_scope: db 'NEBO_CONTROL_BRANCH_SCOPE'
n_control_scope_len equ $-n_control_scope
m_control_scope: db 'branch scopes must be distinct children of the parent scope'
m_control_scope_len equ $-m_control_scope
n_effect_thread: db 'NEBO_EFFECT_THREAD_CAPABILITY'
n_effect_thread_len equ $-n_effect_thread
m_effect_thread: db 'only console or scan effects may be thread-capable'
m_effect_thread_len equ $-m_effect_thread
effects_capabilities_e_politicas_n_lex: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-LEX-001'
effects_capabilities_e_politicas_n_lex_len equ $-effects_capabilities_e_politicas_n_lex
effects_capabilities_e_politicas_m_lex: db 'unknown or non-canonical Policy atom or literal'
effects_capabilities_e_politicas_m_lex_len equ $-effects_capabilities_e_politicas_m_lex
effects_capabilities_e_politicas_n_parse: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-PARSE-002'
effects_capabilities_e_politicas_n_parse_len equ $-effects_capabilities_e_politicas_n_parse
effects_capabilities_e_politicas_m_parse: db 'malformed or non-canonical Policy clause order'
effects_capabilities_e_politicas_m_parse_len equ $-effects_capabilities_e_politicas_m_parse
effects_capabilities_e_politicas_n_type: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-TYPE-003'
effects_capabilities_e_politicas_n_type_len equ $-effects_capabilities_e_politicas_n_type
effects_capabilities_e_politicas_m_type: db 'Policy value or effect constraint is invalid'
effects_capabilities_e_politicas_m_type_len equ $-effects_capabilities_e_politicas_m_type
effects_capabilities_e_politicas_n_codegen: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-CODEGEN-004'
effects_capabilities_e_politicas_n_codegen_len equ $-effects_capabilities_e_politicas_n_codegen
effects_capabilities_e_politicas_m_codegen: db 'Policy proof cannot be lowered for this target or front'
effects_capabilities_e_politicas_m_codegen_len equ $-effects_capabilities_e_politicas_m_codegen
effects_capabilities_e_politicas_n_runtime: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-RUNTIME-005'
effects_capabilities_e_politicas_n_runtime_len equ $-effects_capabilities_e_politicas_n_runtime
effects_capabilities_e_politicas_m_runtime: db 'Policy evaluation budget is exceeded'
effects_capabilities_e_politicas_m_runtime_len equ $-effects_capabilities_e_politicas_m_runtime
effects_capabilities_e_politicas_n_security: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-SECURITY-006'
effects_capabilities_e_politicas_n_security_len equ $-effects_capabilities_e_politicas_n_security
effects_capabilities_e_politicas_m_security: db 'Policy capability allow deny trust or audit check failed'
effects_capabilities_e_politicas_m_security_len equ $-effects_capabilities_e_politicas_m_security
privacidade_dados_sensiveis_e_zero_trust_n_lex: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-LEX-001'
privacidade_dados_sensiveis_e_zero_trust_n_lex_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_lex
privacidade_dados_sensiveis_e_zero_trust_m_lex: db 'unknown or non-canonical privacy wrapper, type or label'
privacidade_dados_sensiveis_e_zero_trust_m_lex_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_lex
privacidade_dados_sensiveis_e_zero_trust_n_parse: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PARSE-002'
privacidade_dados_sensiveis_e_zero_trust_n_parse_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_parse
privacidade_dados_sensiveis_e_zero_trust_m_parse: db 'malformed or non-canonical privacy proof syntax'
privacidade_dados_sensiveis_e_zero_trust_m_parse_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_parse
privacidade_dados_sensiveis_e_zero_trust_n_type: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-TYPE-003'
privacidade_dados_sensiveis_e_zero_trust_n_type_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_type
privacidade_dados_sensiveis_e_zero_trust_m_type: db 'privacy wrapper or redaction label set is invalid'
privacidade_dados_sensiveis_e_zero_trust_m_type_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_type
privacidade_dados_sensiveis_e_zero_trust_n_codegen: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-CODEGEN-004'
privacidade_dados_sensiveis_e_zero_trust_n_codegen_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_codegen
privacidade_dados_sensiveis_e_zero_trust_m_codegen: db 'privacy proof cannot be lowered for this target or front'
privacidade_dados_sensiveis_e_zero_trust_m_codegen_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_codegen
privacidade_dados_sensiveis_e_zero_trust_n_runtime: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-RUNTIME-005'
privacidade_dados_sensiveis_e_zero_trust_n_runtime_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_runtime
privacidade_dados_sensiveis_e_zero_trust_m_runtime: db 'privacy retention or runtime invariant failed'
privacidade_dados_sensiveis_e_zero_trust_m_runtime_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_runtime
privacidade_dados_sensiveis_e_zero_trust_n_security: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-SECURITY-006'
privacidade_dados_sensiveis_e_zero_trust_n_security_len equ $-privacidade_dados_sensiveis_e_zero_trust_n_security
privacidade_dados_sensiveis_e_zero_trust_m_security: db 'privacy policy trust purpose redaction or sink check failed'
privacidade_dados_sensiveis_e_zero_trust_m_security_len equ $-privacidade_dados_sensiveis_e_zero_trust_m_security
quality_confidence_e_lineage_n_lex: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-LEX-001'
quality_confidence_e_lineage_n_lex_len equ $-quality_confidence_e_lineage_n_lex
quality_confidence_e_lineage_m_lex: db 'unknown or non-canonical quality confidence or lineage name'
quality_confidence_e_lineage_m_lex_len equ $-quality_confidence_e_lineage_m_lex
quality_confidence_e_lineage_n_parse: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-PARSE-002'
quality_confidence_e_lineage_n_parse_len equ $-quality_confidence_e_lineage_n_parse
quality_confidence_e_lineage_m_parse: db 'malformed quality confidence or lineage proof syntax'
quality_confidence_e_lineage_m_parse_len equ $-quality_confidence_e_lineage_m_parse
quality_confidence_e_lineage_n_type: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-TYPE-003'
quality_confidence_e_lineage_n_type_len equ $-quality_confidence_e_lineage_n_type
quality_confidence_e_lineage_m_type: db 'quality confidence score or lineage identity is invalid'
quality_confidence_e_lineage_m_type_len equ $-quality_confidence_e_lineage_m_type
quality_confidence_e_lineage_n_codegen: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-CODEGEN-004'
quality_confidence_e_lineage_n_codegen_len equ $-quality_confidence_e_lineage_n_codegen
quality_confidence_e_lineage_m_codegen: db 'quality confidence lineage proof is unavailable before QUALITY-CONFIDENCE-E-LINEAGE-PF005'
quality_confidence_e_lineage_m_codegen_len equ $-quality_confidence_e_lineage_m_codegen
quality_confidence_e_lineage_n_runtime: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-RUNTIME-005'
quality_confidence_e_lineage_n_runtime_len equ $-quality_confidence_e_lineage_n_runtime
quality_confidence_e_lineage_m_runtime: db 'quality confidence or lineage runtime invariant failed'
quality_confidence_e_lineage_m_runtime_len equ $-quality_confidence_e_lineage_m_runtime
quality_confidence_e_lineage_n_security: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-SECURITY-006'
quality_confidence_e_lineage_n_security_len equ $-quality_confidence_e_lineage_n_security
quality_confidence_e_lineage_m_security: db 'quality confidence privacy or lineage authority check failed'
quality_confidence_e_lineage_m_security_len equ $-quality_confidence_e_lineage_m_security
memoria_ownership_lifetimes_e_recursos_n_lex: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-LEX-001'
memoria_ownership_lifetimes_e_recursos_n_lex_len equ $-memoria_ownership_lifetimes_e_recursos_n_lex
memoria_ownership_lifetimes_e_recursos_m_lex: db 'unknown or non-canonical ownership lifetime or action name'
memoria_ownership_lifetimes_e_recursos_m_lex_len equ $-memoria_ownership_lifetimes_e_recursos_m_lex
memoria_ownership_lifetimes_e_recursos_n_parse: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PARSE-002'
memoria_ownership_lifetimes_e_recursos_n_parse_len equ $-memoria_ownership_lifetimes_e_recursos_n_parse
memoria_ownership_lifetimes_e_recursos_m_parse: db 'malformed ownership lifetime or resource action syntax'
memoria_ownership_lifetimes_e_recursos_m_parse_len equ $-memoria_ownership_lifetimes_e_recursos_m_parse
memoria_ownership_lifetimes_e_recursos_n_type: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-TYPE-003'
memoria_ownership_lifetimes_e_recursos_n_type_len equ $-memoria_ownership_lifetimes_e_recursos_n_type
memoria_ownership_lifetimes_e_recursos_m_type: db 'resource owner lifetime or borrower identity is invalid'
memoria_ownership_lifetimes_e_recursos_m_type_len equ $-memoria_ownership_lifetimes_e_recursos_m_type
memoria_ownership_lifetimes_e_recursos_n_codegen: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-CODEGEN-004'
memoria_ownership_lifetimes_e_recursos_n_codegen_len equ $-memoria_ownership_lifetimes_e_recursos_n_codegen
memoria_ownership_lifetimes_e_recursos_m_codegen: db 'ownership lifetime resource action is unavailable before MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF005'
memoria_ownership_lifetimes_e_recursos_m_codegen_len equ $-memoria_ownership_lifetimes_e_recursos_m_codegen
memoria_ownership_lifetimes_e_recursos_n_runtime: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-RUNTIME-005'
memoria_ownership_lifetimes_e_recursos_n_runtime_len equ $-memoria_ownership_lifetimes_e_recursos_n_runtime
memoria_ownership_lifetimes_e_recursos_m_runtime: db 'ownership lifetime or exact-cleanup runtime invariant failed'
memoria_ownership_lifetimes_e_recursos_m_runtime_len equ $-memoria_ownership_lifetimes_e_recursos_m_runtime
memoria_ownership_lifetimes_e_recursos_n_security: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-SECURITY-006'
memoria_ownership_lifetimes_e_recursos_n_security_len equ $-memoria_ownership_lifetimes_e_recursos_n_security
memoria_ownership_lifetimes_e_recursos_m_security: db 'borrow exclusivity region token or use-after-move check failed'
memoria_ownership_lifetimes_e_recursos_m_security_len equ $-memoria_ownership_lifetimes_e_recursos_m_security
imports_modulos_namespaces_e_api_publica_n_lex: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-LEX-001'
imports_modulos_namespaces_e_api_publica_n_lex_len equ $-imports_modulos_namespaces_e_api_publica_n_lex
imports_modulos_namespaces_e_api_publica_m_lex: db 'unknown or non-canonical module import or visibility name'
imports_modulos_namespaces_e_api_publica_m_lex_len equ $-imports_modulos_namespaces_e_api_publica_m_lex
imports_modulos_namespaces_e_api_publica_n_parse: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PARSE-002'
imports_modulos_namespaces_e_api_publica_n_parse_len equ $-imports_modulos_namespaces_e_api_publica_n_parse
imports_modulos_namespaces_e_api_publica_m_parse: db 'malformed module package import symbol or visibility syntax'
imports_modulos_namespaces_e_api_publica_m_parse_len equ $-imports_modulos_namespaces_e_api_publica_m_parse
imports_modulos_namespaces_e_api_publica_n_type: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-TYPE-003'
imports_modulos_namespaces_e_api_publica_n_type_len equ $-imports_modulos_namespaces_e_api_publica_n_type
imports_modulos_namespaces_e_api_publica_m_type: db 'module package import or symbol identity is invalid'
imports_modulos_namespaces_e_api_publica_m_type_len equ $-imports_modulos_namespaces_e_api_publica_m_type
imports_modulos_namespaces_e_api_publica_n_codegen: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-CODEGEN-004'
imports_modulos_namespaces_e_api_publica_n_codegen_len equ $-imports_modulos_namespaces_e_api_publica_n_codegen
imports_modulos_namespaces_e_api_publica_m_codegen: db 'module import resolution is unavailable before IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF005'
imports_modulos_namespaces_e_api_publica_m_codegen_len equ $-imports_modulos_namespaces_e_api_publica_m_codegen
imports_modulos_namespaces_e_api_publica_n_runtime: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-RUNTIME-005'
imports_modulos_namespaces_e_api_publica_n_runtime_len equ $-imports_modulos_namespaces_e_api_publica_n_runtime
imports_modulos_namespaces_e_api_publica_m_runtime: db 'module initialization or import graph runtime invariant failed'
imports_modulos_namespaces_e_api_publica_m_runtime_len equ $-imports_modulos_namespaces_e_api_publica_m_runtime
imports_modulos_namespaces_e_api_publica_n_security: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-SECURITY-006'
imports_modulos_namespaces_e_api_publica_n_security_len equ $-imports_modulos_namespaces_e_api_publica_n_security
imports_modulos_namespaces_e_api_publica_m_security: db 'module cycle visibility boundary or graph integrity check failed'
imports_modulos_namespaces_e_api_publica_m_security_len equ $-imports_modulos_namespaces_e_api_publica_m_security
packages_registry_lockfile_e_supply_chain_n_lex: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-LEX-001'
packages_registry_lockfile_e_supply_chain_n_lex_len equ $-packages_registry_lockfile_e_supply_chain_n_lex
packages_registry_lockfile_e_supply_chain_m_lex: db 'unknown or non-canonical package manifest or policy name'
packages_registry_lockfile_e_supply_chain_m_lex_len equ $-packages_registry_lockfile_e_supply_chain_m_lex
packages_registry_lockfile_e_supply_chain_n_parse: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PARSE-002'
packages_registry_lockfile_e_supply_chain_n_parse_len equ $-packages_registry_lockfile_e_supply_chain_n_parse
packages_registry_lockfile_e_supply_chain_m_parse: db 'malformed package dependency version digest or policy syntax'
packages_registry_lockfile_e_supply_chain_m_parse_len equ $-packages_registry_lockfile_e_supply_chain_m_parse
packages_registry_lockfile_e_supply_chain_n_type: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-TYPE-003'
packages_registry_lockfile_e_supply_chain_n_type_len equ $-packages_registry_lockfile_e_supply_chain_n_type
packages_registry_lockfile_e_supply_chain_m_type: db 'package dependency version or digest identity is invalid'
packages_registry_lockfile_e_supply_chain_m_type_len equ $-packages_registry_lockfile_e_supply_chain_m_type
packages_registry_lockfile_e_supply_chain_n_codegen: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-CODEGEN-004'
packages_registry_lockfile_e_supply_chain_n_codegen_len equ $-packages_registry_lockfile_e_supply_chain_n_codegen
packages_registry_lockfile_e_supply_chain_m_codegen: db 'package lock resolution is unavailable before PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF005'
packages_registry_lockfile_e_supply_chain_m_codegen_len equ $-packages_registry_lockfile_e_supply_chain_m_codegen
packages_registry_lockfile_e_supply_chain_n_runtime: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-RUNTIME-005'
packages_registry_lockfile_e_supply_chain_n_runtime_len equ $-packages_registry_lockfile_e_supply_chain_n_runtime
packages_registry_lockfile_e_supply_chain_m_runtime: db 'package lock resolution or replay runtime invariant failed'
packages_registry_lockfile_e_supply_chain_m_runtime_len equ $-packages_registry_lockfile_e_supply_chain_m_runtime
packages_registry_lockfile_e_supply_chain_n_security: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-SECURITY-006'
packages_registry_lockfile_e_supply_chain_n_security_len equ $-packages_registry_lockfile_e_supply_chain_n_security
packages_registry_lockfile_e_supply_chain_m_security: db 'package digest policy or lock integrity check failed'
packages_registry_lockfile_e_supply_chain_m_security_len equ $-packages_registry_lockfile_e_supply_chain_m_security
biblioteca_padrao_por_dominios_n_lex: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-LEX-001'
biblioteca_padrao_por_dominios_n_lex_len equ $-biblioteca_padrao_por_dominios_n_lex
biblioteca_padrao_por_dominios_m_lex: db 'unknown or non-canonical std.math namespace or operation name'
biblioteca_padrao_por_dominios_m_lex_len equ $-biblioteca_padrao_por_dominios_m_lex
biblioteca_padrao_por_dominios_n_parse: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-PARSE-002'
biblioteca_padrao_por_dominios_n_parse_len equ $-biblioteca_padrao_por_dominios_n_parse
biblioteca_padrao_por_dominios_m_parse: db 'malformed std.math call arguments punctuation or terminator'
biblioteca_padrao_por_dominios_m_parse_len equ $-biblioteca_padrao_por_dominios_m_parse
biblioteca_padrao_por_dominios_n_type: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-TYPE-003'
biblioteca_padrao_por_dominios_n_type_len equ $-biblioteca_padrao_por_dominios_n_type
biblioteca_padrao_por_dominios_m_type: db 'std.math signed Int operand or clamp domain is invalid'
biblioteca_padrao_por_dominios_m_type_len equ $-biblioteca_padrao_por_dominios_m_type
biblioteca_padrao_por_dominios_n_codegen: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-CODEGEN-004'
biblioteca_padrao_por_dominios_n_codegen_len equ $-biblioteca_padrao_por_dominios_n_codegen
biblioteca_padrao_por_dominios_m_codegen: db 'std.math code generation is unavailable before BIBLIOTECA-PADRAO-POR-DOMINIOS-PF005'
biblioteca_padrao_por_dominios_m_codegen_len equ $-biblioteca_padrao_por_dominios_m_codegen
biblioteca_padrao_por_dominios_n_runtime: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-RUNTIME-005'
biblioteca_padrao_por_dominios_n_runtime_len equ $-biblioteca_padrao_por_dominios_n_runtime
biblioteca_padrao_por_dominios_m_runtime: db 'std.math evaluation or signed domain invariant failed'
biblioteca_padrao_por_dominios_m_runtime_len equ $-biblioteca_padrao_por_dominios_m_runtime
biblioteca_padrao_por_dominios_n_security: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-SECURITY-006'
biblioteca_padrao_por_dominios_n_security_len equ $-biblioteca_padrao_por_dominios_n_security
biblioteca_padrao_por_dominios_m_security: db 'std.math request integrity or bounded purity check failed'
biblioteca_padrao_por_dominios_m_security_len equ $-biblioteca_padrao_por_dominios_m_security
filesystem_paths_e_formatos_n_lex: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-LEX-001'
filesystem_paths_e_formatos_n_lex_len equ $-filesystem_paths_e_formatos_n_lex
filesystem_paths_e_formatos_m_lex: db 'unknown or non-canonical path namespace or query name'
filesystem_paths_e_formatos_m_lex_len equ $-filesystem_paths_e_formatos_m_lex
filesystem_paths_e_formatos_n_parse: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-PARSE-002'
filesystem_paths_e_formatos_n_parse_len equ $-filesystem_paths_e_formatos_n_parse
filesystem_paths_e_formatos_m_parse: db 'malformed lexical path query punctuation quotes or terminator'
filesystem_paths_e_formatos_m_parse_len equ $-filesystem_paths_e_formatos_m_parse
filesystem_paths_e_formatos_n_type: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-TYPE-003'
filesystem_paths_e_formatos_n_type_len equ $-filesystem_paths_e_formatos_n_type
filesystem_paths_e_formatos_m_type: db 'lexical path text is empty non-canonical or outside the bounded profile'
filesystem_paths_e_formatos_m_type_len equ $-filesystem_paths_e_formatos_m_type
filesystem_paths_e_formatos_n_codegen: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-CODEGEN-004'
filesystem_paths_e_formatos_n_codegen_len equ $-filesystem_paths_e_formatos_n_codegen
filesystem_paths_e_formatos_m_codegen: db 'lexical path code generation is unavailable before FILESYSTEM-PATHS-E-FORMATOS-PF005'
filesystem_paths_e_formatos_m_codegen_len equ $-filesystem_paths_e_formatos_m_codegen
filesystem_paths_e_formatos_n_runtime: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-RUNTIME-005'
filesystem_paths_e_formatos_n_runtime_len equ $-filesystem_paths_e_formatos_n_runtime
filesystem_paths_e_formatos_m_runtime: db 'lexical path runtime invariant failed'
filesystem_paths_e_formatos_m_runtime_len equ $-filesystem_paths_e_formatos_m_runtime
filesystem_paths_e_formatos_n_security: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-SECURITY-006'
filesystem_paths_e_formatos_n_security_len equ $-filesystem_paths_e_formatos_n_security
filesystem_paths_e_formatos_m_security: db 'path traversal or authenticated lexical summary integrity check failed'
filesystem_paths_e_formatos_m_security_len equ $-filesystem_paths_e_formatos_m_security
rede_e_protocolos_n_lex: db 'NEBO-REDE-E-PROTOCOLOS-LEX-001'
rede_e_protocolos_n_lex_len equ $-rede_e_protocolos_n_lex
rede_e_protocolos_m_lex: db 'unknown or non-canonical net namespace or port operation name'
rede_e_protocolos_m_lex_len equ $-rede_e_protocolos_m_lex
rede_e_protocolos_n_parse: db 'NEBO-REDE-E-PROTOCOLOS-PARSE-002'
rede_e_protocolos_n_parse_len equ $-rede_e_protocolos_n_parse
rede_e_protocolos_m_parse: db 'malformed decimal network-port punctuation quotes or terminator'
rede_e_protocolos_m_parse_len equ $-rede_e_protocolos_m_parse
rede_e_protocolos_n_type: db 'NEBO-REDE-E-PROTOCOLOS-TYPE-003'
rede_e_protocolos_n_type_len equ $-rede_e_protocolos_n_type
rede_e_protocolos_m_type: db 'decimal network port is empty invalid or outside 1 through 65535'
rede_e_protocolos_m_type_len equ $-rede_e_protocolos_m_type
rede_e_protocolos_n_codegen: db 'NEBO-REDE-E-PROTOCOLOS-CODEGEN-004'
rede_e_protocolos_n_codegen_len equ $-rede_e_protocolos_n_codegen
rede_e_protocolos_m_codegen: db 'network-port code generation is unavailable before REDE-E-PROTOCOLOS-PF005'
rede_e_protocolos_m_codegen_len equ $-rede_e_protocolos_m_codegen
rede_e_protocolos_n_runtime: db 'NEBO-REDE-E-PROTOCOLOS-RUNTIME-005'
rede_e_protocolos_n_runtime_len equ $-rede_e_protocolos_n_runtime
rede_e_protocolos_m_runtime: db 'network-port runtime invariant failed'
rede_e_protocolos_m_runtime_len equ $-rede_e_protocolos_m_runtime
rede_e_protocolos_n_security: db 'NEBO-REDE-E-PROTOCOLOS-SECURITY-006'
rede_e_protocolos_n_security_len equ $-rede_e_protocolos_n_security
rede_e_protocolos_m_security: db 'ambiguous port spelling or authenticated summary integrity check failed'
rede_e_protocolos_m_security_len equ $-rede_e_protocolos_m_security
console_visual_dashboard_e_plots_n_lex: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-LEX-001'
console_visual_dashboard_e_plots_n_lex_len equ $-console_visual_dashboard_e_plots_n_lex
console_visual_dashboard_e_plots_m_lex: db 'unknown or non-canonical visual namespace or summary operation name'
console_visual_dashboard_e_plots_m_lex_len equ $-console_visual_dashboard_e_plots_m_lex
console_visual_dashboard_e_plots_n_parse: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PARSE-002'
console_visual_dashboard_e_plots_n_parse_len equ $-console_visual_dashboard_e_plots_n_parse
console_visual_dashboard_e_plots_m_parse: db 'malformed visual summary punctuation argument or terminator'
console_visual_dashboard_e_plots_m_parse_len equ $-console_visual_dashboard_e_plots_m_parse
console_visual_dashboard_e_plots_n_type: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-TYPE-003'
console_visual_dashboard_e_plots_n_type_len equ $-console_visual_dashboard_e_plots_n_type
console_visual_dashboard_e_plots_m_type: db 'visual summary value is not an integer from 0 through 255'
console_visual_dashboard_e_plots_m_type_len equ $-console_visual_dashboard_e_plots_m_type
console_visual_dashboard_e_plots_n_codegen: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-CODEGEN-004'
console_visual_dashboard_e_plots_n_codegen_len equ $-console_visual_dashboard_e_plots_n_codegen
console_visual_dashboard_e_plots_m_codegen: db 'visual summary code generation is unavailable before CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PF005'
console_visual_dashboard_e_plots_m_codegen_len equ $-console_visual_dashboard_e_plots_m_codegen
console_visual_dashboard_e_plots_n_runtime: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-RUNTIME-005'
console_visual_dashboard_e_plots_n_runtime_len equ $-console_visual_dashboard_e_plots_n_runtime
console_visual_dashboard_e_plots_m_runtime: db 'visual summary runtime invariant failed'
console_visual_dashboard_e_plots_m_runtime_len equ $-console_visual_dashboard_e_plots_m_runtime
console_visual_dashboard_e_plots_n_security: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-SECURITY-006'
console_visual_dashboard_e_plots_n_security_len equ $-console_visual_dashboard_e_plots_n_security
console_visual_dashboard_e_plots_m_security: db 'non-canonical integer spelling or authenticated summary integrity failed'
console_visual_dashboard_e_plots_m_security_len equ $-console_visual_dashboard_e_plots_m_security
media_imagem_audio_e_video_n_lex: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-LEX-001'
media_imagem_audio_e_video_n_lex_len equ $-media_imagem_audio_e_video_n_lex
media_imagem_audio_e_video_m_lex: db 'unsupported synthetic media descriptor spelling'
media_imagem_audio_e_video_m_lex_len equ $-media_imagem_audio_e_video_m_lex
media_imagem_audio_e_video_n_parse: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-PARSE-002'
media_imagem_audio_e_video_n_parse_len equ $-media_imagem_audio_e_video_n_parse
media_imagem_audio_e_video_m_parse: db 'malformed synthetic media descriptor or inconsistent extent'
media_imagem_audio_e_video_m_parse_len equ $-media_imagem_audio_e_video_m_parse
media_imagem_audio_e_video_n_type: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-TYPE-003'
media_imagem_audio_e_video_n_type_len equ $-media_imagem_audio_e_video_n_type
media_imagem_audio_e_video_m_type: db 'media dimensions rate channels or duration are outside the bounded profile'
media_imagem_audio_e_video_m_type_len equ $-media_imagem_audio_e_video_m_type
media_imagem_audio_e_video_n_codegen: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-CODEGEN-004'
media_imagem_audio_e_video_n_codegen_len equ $-media_imagem_audio_e_video_n_codegen
media_imagem_audio_e_video_m_codegen: db 'public synthetic media code generation is not part of the internal profile'
media_imagem_audio_e_video_m_codegen_len equ $-media_imagem_audio_e_video_m_codegen
media_imagem_audio_e_video_n_runtime: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-RUNTIME-005'
media_imagem_audio_e_video_n_runtime_len equ $-media_imagem_audio_e_video_n_runtime
media_imagem_audio_e_video_m_runtime: db 'synthetic media resource bound or declared extent was truncated'
media_imagem_audio_e_video_m_runtime_len equ $-media_imagem_audio_e_video_m_runtime
media_imagem_audio_e_video_n_security: db 'NEBO-MEDIA-IMAGEM-AUDIO-E-VIDEO-SECURITY-006'
media_imagem_audio_e_video_n_security_len equ $-media_imagem_audio_e_video_n_security
media_imagem_audio_e_video_m_security: db 'media privacy capability or authenticated descriptor invariant failed'
media_imagem_audio_e_video_m_security_len equ $-media_imagem_audio_e_video_m_security
machine_learning_neuron_network_e_model_n_lex: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-LEX-001'
machine_learning_neuron_network_e_model_n_lex_len equ $-machine_learning_neuron_network_e_model_n_lex
machine_learning_neuron_network_e_model_m_lex: db 'unsupported bounded ML profile spelling'
machine_learning_neuron_network_e_model_m_lex_len equ $-machine_learning_neuron_network_e_model_m_lex
machine_learning_neuron_network_e_model_n_parse: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-PARSE-002'
machine_learning_neuron_network_e_model_n_parse_len equ $-machine_learning_neuron_network_e_model_n_parse
machine_learning_neuron_network_e_model_m_parse: db 'malformed bounded affine-forward descriptor'
machine_learning_neuron_network_e_model_m_parse_len equ $-machine_learning_neuron_network_e_model_m_parse
machine_learning_neuron_network_e_model_n_type: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-TYPE-003'
machine_learning_neuron_network_e_model_n_type_len equ $-machine_learning_neuron_network_e_model_n_type
machine_learning_neuron_network_e_model_m_type: db 'shape dtype or scalar is outside the local deterministic profile'
machine_learning_neuron_network_e_model_m_type_len equ $-machine_learning_neuron_network_e_model_m_type
machine_learning_neuron_network_e_model_n_codegen: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-CODEGEN-004'
machine_learning_neuron_network_e_model_n_codegen_len equ $-machine_learning_neuron_network_e_model_n_codegen
machine_learning_neuron_network_e_model_m_codegen: db 'public ML code generation is outside the internal profile'
machine_learning_neuron_network_e_model_m_codegen_len equ $-machine_learning_neuron_network_e_model_m_codegen
machine_learning_neuron_network_e_model_n_runtime: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-RUNTIME-005'
machine_learning_neuron_network_e_model_n_runtime_len equ $-machine_learning_neuron_network_e_model_n_runtime
machine_learning_neuron_network_e_model_m_runtime: db 'affine-forward budget or arithmetic bound failed'
machine_learning_neuron_network_e_model_m_runtime_len equ $-machine_learning_neuron_network_e_model_m_runtime
machine_learning_neuron_network_e_model_n_security: db 'NEBO-MACHINE-LEARNING-NEURON-NETWORK-E-MODEL-SECURITY-006'
machine_learning_neuron_network_e_model_n_security_len equ $-machine_learning_neuron_network_e_model_n_security
machine_learning_neuron_network_e_model_m_security: db 'weights lineage privacy ownership device or seal invariant failed'
machine_learning_neuron_network_e_model_m_security_len equ $-machine_learning_neuron_network_e_model_m_security
gpu_e_computacao_acelerada_n_lex: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-LEX-001'
gpu_e_computacao_acelerada_n_lex_len equ $-gpu_e_computacao_acelerada_n_lex
gpu_e_computacao_acelerada_m_lex: db 'GPU syntax is unavailable in the research-only profile'
gpu_e_computacao_acelerada_m_lex_len equ $-gpu_e_computacao_acelerada_m_lex
gpu_e_computacao_acelerada_n_parse: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-PARSE-002'
gpu_e_computacao_acelerada_n_parse_len equ $-gpu_e_computacao_acelerada_n_parse
gpu_e_computacao_acelerada_m_parse: db 'GPU constructs are unavailable in the research-only profile'
gpu_e_computacao_acelerada_m_parse_len equ $-gpu_e_computacao_acelerada_m_parse
gpu_e_computacao_acelerada_n_type: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-TYPE-003'
gpu_e_computacao_acelerada_n_type_len equ $-gpu_e_computacao_acelerada_n_type
gpu_e_computacao_acelerada_m_type: db 'GPU types are unavailable in the research-only profile'
gpu_e_computacao_acelerada_m_type_len equ $-gpu_e_computacao_acelerada_m_type
gpu_e_computacao_acelerada_n_codegen: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-CODEGEN-004'
gpu_e_computacao_acelerada_n_codegen_len equ $-gpu_e_computacao_acelerada_n_codegen
gpu_e_computacao_acelerada_m_codegen: db 'no GPU backend or toolchain is certified'
gpu_e_computacao_acelerada_m_codegen_len equ $-gpu_e_computacao_acelerada_m_codegen
gpu_e_computacao_acelerada_n_runtime: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-RUNTIME-005'
gpu_e_computacao_acelerada_n_runtime_len equ $-gpu_e_computacao_acelerada_n_runtime
gpu_e_computacao_acelerada_m_runtime: db 'no GPU runtime is certified'
gpu_e_computacao_acelerada_m_runtime_len equ $-gpu_e_computacao_acelerada_m_runtime
gpu_e_computacao_acelerada_n_security: db 'NEBO-GPU-E-COMPUTACAO-ACELERADA-SECURITY-006'
gpu_e_computacao_acelerada_n_security_len equ $-gpu_e_computacao_acelerada_n_security
gpu_e_computacao_acelerada_m_security: db 'GPU capability is denied by the research-only profile'
gpu_e_computacao_acelerada_m_security_len equ $-gpu_e_computacao_acelerada_m_security
runtime_distribuido_e_streaming_distribuido_n_lex: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-LEX-001'
runtime_distribuido_e_streaming_distribuido_n_lex_len equ $-runtime_distribuido_e_streaming_distribuido_n_lex
runtime_distribuido_e_streaming_distribuido_m_lex: db 'unsupported local queue simulation spelling'
runtime_distribuido_e_streaming_distribuido_m_lex_len equ $-runtime_distribuido_e_streaming_distribuido_m_lex
runtime_distribuido_e_streaming_distribuido_n_parse: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-PARSE-002'
runtime_distribuido_e_streaming_distribuido_n_parse_len equ $-runtime_distribuido_e_streaming_distribuido_n_parse
runtime_distribuido_e_streaming_distribuido_m_parse: db 'malformed local queue simulation descriptor'
runtime_distribuido_e_streaming_distribuido_m_parse_len equ $-runtime_distribuido_e_streaming_distribuido_m_parse
runtime_distribuido_e_streaming_distribuido_n_type: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-TYPE-003'
runtime_distribuido_e_streaming_distribuido_n_type_len equ $-runtime_distribuido_e_streaming_distribuido_n_type
runtime_distribuido_e_streaming_distribuido_m_type: db 'queue capacity retry or timeout field is outside the local profile'
runtime_distribuido_e_streaming_distribuido_m_type_len equ $-runtime_distribuido_e_streaming_distribuido_m_type
runtime_distribuido_e_streaming_distribuido_n_codegen: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-CODEGEN-004'
runtime_distribuido_e_streaming_distribuido_n_codegen_len equ $-runtime_distribuido_e_streaming_distribuido_n_codegen
runtime_distribuido_e_streaming_distribuido_m_codegen: db 'distributed code generation is outside the local simulation profile'
runtime_distribuido_e_streaming_distribuido_m_codegen_len equ $-runtime_distribuido_e_streaming_distribuido_m_codegen
runtime_distribuido_e_streaming_distribuido_n_runtime: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-RUNTIME-005'
runtime_distribuido_e_streaming_distribuido_n_runtime_len equ $-runtime_distribuido_e_streaming_distribuido_n_runtime
runtime_distribuido_e_streaming_distribuido_m_runtime: db 'ordering backpressure retry timeout loss duplicate or ack invariant failed'
runtime_distribuido_e_streaming_distribuido_m_runtime_len equ $-runtime_distribuido_e_streaming_distribuido_m_runtime
runtime_distribuido_e_streaming_distribuido_n_security: db 'NEBO-RUNTIME-DISTRIBUIDO-E-STREAMING-DISTRIBUIDO-SECURITY-006'
runtime_distribuido_e_streaming_distribuido_n_security_len equ $-runtime_distribuido_e_streaming_distribuido_n_security
runtime_distribuido_e_streaming_distribuido_m_security: db 'cleanup or authenticated local simulation invariant failed'
runtime_distribuido_e_streaming_distribuido_m_security_len equ $-runtime_distribuido_e_streaming_distribuido_m_security

n_loop_break_outside: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-030'
n_loop_break_outside_len equ $-n_loop_break_outside
m_loop_break_outside: db 'break is only valid inside a loop'
m_loop_break_outside_len equ $-m_loop_break_outside
n_loop_continue_outside: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-031'
n_loop_continue_outside_len equ $-n_loop_continue_outside
m_loop_continue_outside: db 'continue is only valid inside a loop'
m_loop_continue_outside_len equ $-m_loop_continue_outside
n_array_length_public: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-004'
n_array_length_public_len equ $-n_array_length_public
m_array_length_public: db 'Array length must be a compile-time Int in 0..256'
m_array_length_public_len equ $-m_array_length_public
n_collection_record_capacity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-033'
n_collection_record_capacity_len equ $-n_collection_record_capacity
m_collection_record_capacity: db 'collection record capacity exceeded (maximum 16)'
m_collection_record_capacity_len equ $-m_collection_record_capacity
n_collection_scalar_capacity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-034'
n_collection_scalar_capacity_len equ $-n_collection_scalar_capacity
m_collection_scalar_capacity: db 'collection scalar pool capacity exceeded (maximum 2048)'
m_collection_scalar_capacity_len equ $-m_collection_scalar_capacity
n_function_call_capacity: db 'NEBO_FUNCTION_CALL_CAPACITY'
n_function_call_capacity_len equ $-n_function_call_capacity
m_function_call_capacity: db 'direct invocation count exceeds the bounded maximum of 256'
m_function_call_capacity_len equ $-m_function_call_capacity
n_binding_type_mismatch: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH'
n_binding_type_mismatch_len equ $-n_binding_type_mismatch
m_binding_type_mismatch: db 'binding expression has the wrong public scalar type'
m_binding_type_mismatch_len equ $-m_binding_type_mismatch
n_binding_not_initialized: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-NOT-DEFINITELY-INITIALIZED'
n_binding_not_initialized_len equ $-n_binding_not_initialized
m_binding_not_initialized: db 'binding is not definitely initialized on every control-flow path'
m_binding_not_initialized_len equ $-m_binding_not_initialized
n_call_recursion_surface: db 'NEBO_CALL_RECURSION_SURFACE'
n_call_recursion_surface_len equ $-n_call_recursion_surface
m_call_recursion_surface: db 'recursive function must use the selected Int receiver, zero-parameter, Int-return surface'
m_call_recursion_surface_len equ $-m_call_recursion_surface
n_call_recursion_shape: db 'NEBO_CALL_RECURSION_SHAPE'
n_call_recursion_shape_len equ $-n_call_recursion_shape
m_call_recursion_shape: db 'recursive function must have one exact if/else base case and one self-call site'
m_call_recursion_shape_len equ $-m_call_recursion_shape
n_call_recursion_nontail: db 'NEBO_CALL_RECURSION_NONTAIL'
n_call_recursion_nontail_len equ $-n_call_recursion_nontail
m_call_recursion_nontail: db 'recursive self-call must be the direct expression of a branch return'
m_call_recursion_nontail_len equ $-m_call_recursion_nontail
n_call_recursion_frame: db 'NEBO_CALL_RECURSION_FRAME'
n_call_recursion_frame_len equ $-n_call_recursion_frame
m_call_recursion_frame: db 'selected recursive function requires an exact 16-byte frame'
m_call_recursion_frame_len equ $-m_call_recursion_frame
n_nested_context: db 'NEBO_NESTED_CONTEXT'
n_nested_context_len equ $-n_nested_context
m_nested_context: db 'nested helper declaration is only valid directly in a receiver-first outer function body'
m_nested_context_len equ $-m_nested_context
n_nested_before: db 'NEBO_NESTED_CALL_BEFORE_DECLARATION'
n_nested_before_len equ $-n_nested_before
m_nested_before: db 'nested helper call must appear after its declaration'
m_nested_before_len equ $-m_nested_before
n_nested_scope: db 'NEBO_NESTED_SCOPE'
n_nested_scope_len equ $-n_nested_scope
m_nested_scope: db 'nested helper is private to its exact declaring outer function'
m_nested_scope_len equ $-m_nested_scope
n_nested_duplicate: db 'NEBO_NESTED_DUPLICATE'
n_nested_duplicate_len equ $-n_nested_duplicate
m_nested_duplicate: db 'only one nested helper is permitted per outer function'
m_nested_duplicate_len equ $-m_nested_duplicate
n_nested_capacity: db 'NEBO_NESTED_CAPACITY'
n_nested_capacity_len equ $-n_nested_capacity
m_nested_capacity: db 'nested helper depth or capacity exceeds the selected one-level bound'
m_nested_capacity_len equ $-m_nested_capacity
n_nested_capture: db 'NEBO_NESTED_CAPTURE_UNSUPPORTED'
n_nested_capture_len equ $-n_nested_capture
m_nested_capture: db 'nested helper capture is unsupported; the environment must remain zero bytes'
m_nested_capture_len equ $-m_nested_capture
n_nested_escape: db 'NEBO_NESTED_ESCAPE'
n_nested_escape_len equ $-n_nested_escape
m_nested_escape: db 'nested helper cannot escape or be used as a function value'
m_nested_escape_len equ $-m_nested_escape
n_nested_recursion: db 'NEBO_NESTED_RECURSION'
n_nested_recursion_len equ $-n_nested_recursion
m_nested_recursion: db 'nested helper recursion is outside the selected acyclic call graph'
m_nested_recursion_len equ $-m_nested_recursion
n_nested_recursive_outer: db 'NEBO_NESTED_RECURSIVE_OUTER'
n_nested_recursive_outer_len equ $-n_nested_recursive_outer
m_nested_recursive_outer: db 'a recursive outer function cannot declare the selected nested helper'
m_nested_recursive_outer_len equ $-m_nested_recursive_outer
n_nested_receiver: db 'NEBO_NESTED_RECEIVER_UNSUPPORTED'
n_nested_receiver_len equ $-n_nested_receiver
m_nested_receiver: db 'nested helper requires the exact Int.self receiver'
m_nested_receiver_len equ $-m_nested_receiver
n_nested_parameter: db 'NEBO_NESTED_PARAMETER_UNSUPPORTED'
n_nested_parameter_len equ $-n_nested_parameter
m_nested_parameter: db 'nested helper accepts zero explicit parameters'
m_nested_parameter_len equ $-m_nested_parameter
n_nested_return: db 'NEBO_NESTED_RETURN_UNSUPPORTED'
n_nested_return_len equ $-n_nested_return
m_nested_return: db 'nested helper must return Int on the selected scalar surface'
m_nested_return_len equ $-m_nested_return
n_nested_surface: db 'NEBO_NESTED_SURFACE'
n_nested_surface_len equ $-n_nested_surface
m_nested_surface: db 'nested helper body uses a feature outside the selected noncapturing scalar surface'
m_nested_surface_len equ $-m_nested_surface
n_nested_symbol_collision: db 'NEBO_NESTED_SYMBOL_COLLISION'
n_nested_symbol_collision_len equ $-n_nested_symbol_collision
m_nested_symbol_collision: db 'private nested helper symbol identity collided internally'
m_nested_symbol_collision_len equ $-m_nested_symbol_collision

n_control_header_parens: db 'NEBO_PARSE_CONTROL_HEADER_PARENS_REQUIRED'
n_control_header_parens_len equ $-n_control_header_parens
m_control_header_parens: db 'control header requires parentheses'
m_control_header_parens_len equ $-m_control_header_parens
n_control_header_delimiter: db 'NEBO_PARSE_CONTROL_HEADER_DELIMITER'
n_control_header_delimiter_len equ $-n_control_header_delimiter
m_control_header_delimiter: db 'control header requires a closing parenthesis'
m_control_header_delimiter_len equ $-m_control_header_delimiter
n_while_condition_type: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-032'
n_while_condition_type_len equ $-n_while_condition_type
m_while_condition_type: db 'while condition must have type Bool'
m_while_condition_type_len equ $-m_while_condition_type
n_entrypoint_missing: db 'NEBO_ENTRYPOINT_MISSING'
n_entrypoint_missing_len equ $-n_entrypoint_missing
m_entrypoint_missing: db 'selected target requires exactly one start()'
m_entrypoint_missing_len equ $-m_entrypoint_missing
n_entrypoint_duplicate: db 'NEBO_ENTRYPOINT_DUPLICATE'
n_entrypoint_duplicate_len equ $-n_entrypoint_duplicate
m_entrypoint_duplicate: db 'selected target declares more than one start()'
m_entrypoint_duplicate_len equ $-m_entrypoint_duplicate
n_entrypoint_invalid: db 'NEBO_ENTRYPOINT_INVALID_SIGNATURE'
n_entrypoint_invalid_len equ $-n_entrypoint_invalid
m_entrypoint_invalid: db 'start() violates the frozen entrypoint signature or status contract'
m_entrypoint_invalid_len equ $-m_entrypoint_invalid
n_entrypoint_ambiguous: db 'NEBO_ENTRYPOINT_AMBIGUOUS'
n_entrypoint_ambiguous_len equ $-n_entrypoint_ambiguous
m_entrypoint_ambiguous: db 'start() identity is ambiguous in the selected target'
m_entrypoint_ambiguous_len equ $-m_entrypoint_ambiguous
n_entrypoint_forbidden: db 'NEBO_ENTRYPOINT_FORBIDDEN_FOR_TARGET'
n_entrypoint_forbidden_len equ $-n_entrypoint_forbidden
m_entrypoint_forbidden: db 'library and test targets must not declare start()'
m_entrypoint_forbidden_len equ $-m_entrypoint_forbidden
n_tuple_arity: db 'NEBO_TUPLE_ARITY'
n_tuple_arity_len equ $-n_tuple_arity
m_tuple_arity: db 'Tuple arity exceeds the bounded maximum of 8'
m_tuple_arity_len equ $-m_tuple_arity
n_tuple_bounds: db 'NEBO_TUPLE_INDEX_OUT_OF_RANGE'
n_tuple_bounds_len equ $-n_tuple_bounds
m_tuple_bounds: db 'constant Tuple component index is outside its arity'
m_tuple_bounds_len equ $-m_tuple_bounds
n_tuple_depth: db 'NEBO_TUPLE_NESTING_LIMIT'
n_tuple_depth_len equ $-n_tuple_depth
m_tuple_depth: db 'Tuple nesting exceeds the bounded maximum depth of 4'
m_tuple_depth_len equ $-m_tuple_depth
n_tuple_receiver: db 'NEBO_TUPLE_INVALID_RECEIVER'
n_tuple_receiver_len equ $-n_tuple_receiver
m_tuple_receiver: db 'Tuple operation requires a Tuple receiver'
m_tuple_receiver_len equ $-m_tuple_receiver
n_tuple_duplicate: db 'NEBO_TUPLE_DUPLICATE_BINDING'
n_tuple_duplicate_len equ $-n_tuple_duplicate
m_tuple_duplicate: db 'Tuple destructuring binding is already initialized in this scope'
m_tuple_duplicate_len equ $-m_tuple_duplicate
n_unicode_confusable: db 'NEBO_SOURCE_UNICODE_CONFUSABLE'
n_unicode_confusable_len equ $-n_unicode_confusable
m_unicode_confusable: db 'confusable Unicode source spelling is forbidden; use the canonical ASCII replacement from the note'
m_unicode_confusable_len equ $-m_unicode_confusable
n_unicode_bidi: db 'NEBO_SOURCE_BIDI_CONTROL'
n_unicode_bidi_len equ $-n_unicode_bidi
m_unicode_bidi: db 'bidirectional control is forbidden in source syntax; remove the code point shown in the note'
m_unicode_bidi_len equ $-m_unicode_bidi
n_unicode_invisible: db 'NEBO_SOURCE_INVISIBLE_SEPARATOR'
n_unicode_invisible_len equ $-n_unicode_invisible
m_unicode_invisible: db 'invisible source separator is forbidden; use visible ASCII separation'
m_unicode_invisible_len equ $-m_unicode_invisible
n_unicode_combining: db 'NEBO_SOURCE_COMBINING_MARK'
n_unicode_combining_len equ $-n_unicode_combining
m_unicode_combining: db 'combining mark is forbidden in source syntax; use an exact visible token spelling'
m_unicode_combining_len equ $-m_unicode_combining
n_unicode_malformed: db 'NEBO_SOURCE_MALFORMED_UTF8'
n_unicode_malformed_len equ $-n_unicode_malformed
m_unicode_malformed: db 'source is not strict UTF-8; replace or remove the invalid byte sequence'
m_unicode_malformed_len equ $-m_unicode_malformed
n_reserved_symbol: db 'NEBO_LEX_RESERVED_SYMBOL'
n_reserved_symbol_len equ $-n_reserved_symbol
m_reserved_symbol: db 'symbol spelling is RESERVED and has no executable semantics'
m_reserved_symbol_len equ $-m_reserved_symbol
n_rejected_form: db 'NEBO_LEX_REJECTED_FORM'
n_rejected_form_len equ $-n_rejected_form
m_rejected_form: db 'source form is REJECTED; use the explicit canonical migration'
m_rejected_form_len equ $-m_rejected_form
n_block_comment_depth: db 'NEBO_LEX_BLOCK_COMMENT_DEPTH'
n_block_comment_depth_len equ $-n_block_comment_depth
m_block_comment_depth: db 'nested block comment exceeds the maximum depth of 64'
m_block_comment_depth_len equ $-m_block_comment_depth

n_owner_moved: db 'NEBO_USE_AFTER_MOVE'
n_owner_moved_len equ $-n_owner_moved
m_owner_moved: db 'value was moved, dropped or released before this read'
m_owner_moved_len equ $-m_owner_moved
n_owner_copy: db 'NEBO_COPY_UNIQUE'
n_owner_copy_len equ $-n_owner_copy
m_owner_copy: db 'owned value cannot be copied implicitly; move or clone it explicitly'
m_owner_copy_len equ $-m_owner_copy

n_owner_borrow: db 'NEBO_BORROW_CONFLICT'
n_owner_borrow_len equ $-n_owner_borrow
m_owner_borrow: db 'mutation or transfer conflicts with an active lexical borrow'
m_owner_borrow_len equ $-m_owner_borrow

align 8
catalog:
 dq n_cli,n_cli_len,m_cli,m_cli_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_DRIVER
 dq n_bom,n_bom_len,m_bom,m_bom_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SOURCE
 dq n_src_limit,n_src_limit_len,m_src_limit,m_src_limit_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SOURCE
 dq n_utf8,n_utf8_len,m_utf8,m_utf8_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_char,n_char_len,m_char,m_char_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_expected,n_expected_len,m_expected,m_expected_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_undefined,n_undefined_len,m_undefined,m_undefined_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_mismatch,n_mismatch_len,m_mismatch,m_mismatch_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_limit,n_limit_len,m_limit,m_limit_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 dq n_tool,n_tool_len,m_tool,m_tool_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TOOLCHAIN
 dq n_internal,n_internal_len,m_internal,m_internal_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 dq n_unterminated,n_unterminated_len,m_unterminated,m_unterminated_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_escape,n_escape_len,m_escape,m_escape_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_int_overflow,n_int_overflow_len,m_int_overflow,m_int_overflow_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_block_comment,n_block_comment_len,m_block_comment,m_block_comment_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_duplicate_start,n_duplicate_start_len,m_duplicate_start,m_duplicate_start_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_top_level,n_top_level_len,m_top_level,m_top_level_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_parse_nesting,n_parse_nesting_len,m_parse_nesting,m_parse_nesting_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_missing_start,n_missing_start_len,m_missing_start,m_missing_start_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_unsupported_control,n_unsupported_control_len,m_unsupported_control,m_unsupported_control_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_invalid_control_chain,n_invalid_control_chain_len,m_invalid_control_chain,m_invalid_control_chain_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_missing_semicolon,n_missing_semicolon_len,m_missing_semicolon,m_missing_semicolon_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_unexpected_token,n_unexpected_token_len,m_unexpected_token,m_unexpected_token_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_name_duplicate,n_name_duplicate_len,m_name_duplicate,m_name_duplicate_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_name_shadow,n_name_shadow_len,m_name_shadow,m_name_shadow_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_name_reserved,n_name_reserved_len,m_name_reserved,m_name_reserved_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_type_truthiness,n_type_truthiness_len,m_type_truthiness,m_type_truthiness_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_operator,n_type_operator_len,m_type_operator,m_type_operator_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_overflow,n_type_overflow_len,m_type_overflow,m_type_overflow_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_div_zero,n_type_div_zero_len,m_type_div_zero,m_type_div_zero_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_return_inconsistent,n_type_return_inconsistent_len,m_type_return_inconsistent,m_type_return_inconsistent_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_missing_return,n_type_missing_return_len,m_type_missing_return,m_type_missing_return_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_type_void_binding,n_type_void_binding_len,m_type_void_binding,m_type_void_binding_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_receiver,n_call_receiver_len,m_call_receiver,m_call_receiver_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_arity,n_call_arity_len,m_call_arity,m_call_arity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_argument,n_call_argument_len,m_call_argument,m_call_argument_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_recursion,n_call_recursion_len,m_call_recursion,m_call_recursion_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_undefined,n_call_undefined_len,m_call_undefined,m_call_undefined_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_nested,n_call_nested_len,m_call_nested,m_call_nested_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_duplicate,n_call_duplicate_len,m_call_duplicate,m_call_duplicate_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_behavior_unsupported,n_behavior_unsupported_len,m_behavior_unsupported,m_behavior_unsupported_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_behavior_conflict,n_behavior_conflict_len,m_behavior_conflict,m_behavior_conflict_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_behavior_effectful,n_behavior_effectful_len,m_behavior_effectful,m_behavior_effectful_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_control_condition,n_control_condition_len,m_control_condition,m_control_condition_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_control_scope,n_control_scope_len,m_control_scope,m_control_scope_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_effect_thread,n_effect_thread_len,m_effect_thread,m_effect_thread_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq effects_capabilities_e_politicas_n_lex,effects_capabilities_e_politicas_n_lex_len,effects_capabilities_e_politicas_m_lex,effects_capabilities_e_politicas_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq effects_capabilities_e_politicas_n_parse,effects_capabilities_e_politicas_n_parse_len,effects_capabilities_e_politicas_m_parse,effects_capabilities_e_politicas_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq effects_capabilities_e_politicas_n_type,effects_capabilities_e_politicas_n_type_len,effects_capabilities_e_politicas_m_type,effects_capabilities_e_politicas_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq effects_capabilities_e_politicas_n_codegen,effects_capabilities_e_politicas_n_codegen_len,effects_capabilities_e_politicas_m_codegen,effects_capabilities_e_politicas_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq effects_capabilities_e_politicas_n_runtime,effects_capabilities_e_politicas_n_runtime_len,effects_capabilities_e_politicas_m_runtime,effects_capabilities_e_politicas_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq effects_capabilities_e_politicas_n_security,effects_capabilities_e_politicas_n_security_len,effects_capabilities_e_politicas_m_security,effects_capabilities_e_politicas_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq privacidade_dados_sensiveis_e_zero_trust_n_lex,privacidade_dados_sensiveis_e_zero_trust_n_lex_len,privacidade_dados_sensiveis_e_zero_trust_m_lex,privacidade_dados_sensiveis_e_zero_trust_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq privacidade_dados_sensiveis_e_zero_trust_n_parse,privacidade_dados_sensiveis_e_zero_trust_n_parse_len,privacidade_dados_sensiveis_e_zero_trust_m_parse,privacidade_dados_sensiveis_e_zero_trust_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq privacidade_dados_sensiveis_e_zero_trust_n_type,privacidade_dados_sensiveis_e_zero_trust_n_type_len,privacidade_dados_sensiveis_e_zero_trust_m_type,privacidade_dados_sensiveis_e_zero_trust_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq privacidade_dados_sensiveis_e_zero_trust_n_codegen,privacidade_dados_sensiveis_e_zero_trust_n_codegen_len,privacidade_dados_sensiveis_e_zero_trust_m_codegen,privacidade_dados_sensiveis_e_zero_trust_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq privacidade_dados_sensiveis_e_zero_trust_n_runtime,privacidade_dados_sensiveis_e_zero_trust_n_runtime_len,privacidade_dados_sensiveis_e_zero_trust_m_runtime,privacidade_dados_sensiveis_e_zero_trust_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq privacidade_dados_sensiveis_e_zero_trust_n_security,privacidade_dados_sensiveis_e_zero_trust_n_security_len,privacidade_dados_sensiveis_e_zero_trust_m_security,privacidade_dados_sensiveis_e_zero_trust_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq quality_confidence_e_lineage_n_lex,quality_confidence_e_lineage_n_lex_len,quality_confidence_e_lineage_m_lex,quality_confidence_e_lineage_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq quality_confidence_e_lineage_n_parse,quality_confidence_e_lineage_n_parse_len,quality_confidence_e_lineage_m_parse,quality_confidence_e_lineage_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq quality_confidence_e_lineage_n_type,quality_confidence_e_lineage_n_type_len,quality_confidence_e_lineage_m_type,quality_confidence_e_lineage_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq quality_confidence_e_lineage_n_codegen,quality_confidence_e_lineage_n_codegen_len,quality_confidence_e_lineage_m_codegen,quality_confidence_e_lineage_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq quality_confidence_e_lineage_n_runtime,quality_confidence_e_lineage_n_runtime_len,quality_confidence_e_lineage_m_runtime,quality_confidence_e_lineage_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq quality_confidence_e_lineage_n_security,quality_confidence_e_lineage_n_security_len,quality_confidence_e_lineage_m_security,quality_confidence_e_lineage_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq memoria_ownership_lifetimes_e_recursos_n_lex,memoria_ownership_lifetimes_e_recursos_n_lex_len,memoria_ownership_lifetimes_e_recursos_m_lex,memoria_ownership_lifetimes_e_recursos_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq memoria_ownership_lifetimes_e_recursos_n_parse,memoria_ownership_lifetimes_e_recursos_n_parse_len,memoria_ownership_lifetimes_e_recursos_m_parse,memoria_ownership_lifetimes_e_recursos_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq memoria_ownership_lifetimes_e_recursos_n_type,memoria_ownership_lifetimes_e_recursos_n_type_len,memoria_ownership_lifetimes_e_recursos_m_type,memoria_ownership_lifetimes_e_recursos_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq memoria_ownership_lifetimes_e_recursos_n_codegen,memoria_ownership_lifetimes_e_recursos_n_codegen_len,memoria_ownership_lifetimes_e_recursos_m_codegen,memoria_ownership_lifetimes_e_recursos_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq memoria_ownership_lifetimes_e_recursos_n_runtime,memoria_ownership_lifetimes_e_recursos_n_runtime_len,memoria_ownership_lifetimes_e_recursos_m_runtime,memoria_ownership_lifetimes_e_recursos_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq memoria_ownership_lifetimes_e_recursos_n_security,memoria_ownership_lifetimes_e_recursos_n_security_len,memoria_ownership_lifetimes_e_recursos_m_security,memoria_ownership_lifetimes_e_recursos_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq imports_modulos_namespaces_e_api_publica_n_lex,imports_modulos_namespaces_e_api_publica_n_lex_len,imports_modulos_namespaces_e_api_publica_m_lex,imports_modulos_namespaces_e_api_publica_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq imports_modulos_namespaces_e_api_publica_n_parse,imports_modulos_namespaces_e_api_publica_n_parse_len,imports_modulos_namespaces_e_api_publica_m_parse,imports_modulos_namespaces_e_api_publica_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq imports_modulos_namespaces_e_api_publica_n_type,imports_modulos_namespaces_e_api_publica_n_type_len,imports_modulos_namespaces_e_api_publica_m_type,imports_modulos_namespaces_e_api_publica_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq imports_modulos_namespaces_e_api_publica_n_codegen,imports_modulos_namespaces_e_api_publica_n_codegen_len,imports_modulos_namespaces_e_api_publica_m_codegen,imports_modulos_namespaces_e_api_publica_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq imports_modulos_namespaces_e_api_publica_n_runtime,imports_modulos_namespaces_e_api_publica_n_runtime_len,imports_modulos_namespaces_e_api_publica_m_runtime,imports_modulos_namespaces_e_api_publica_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq imports_modulos_namespaces_e_api_publica_n_security,imports_modulos_namespaces_e_api_publica_n_security_len,imports_modulos_namespaces_e_api_publica_m_security,imports_modulos_namespaces_e_api_publica_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq packages_registry_lockfile_e_supply_chain_n_lex,packages_registry_lockfile_e_supply_chain_n_lex_len,packages_registry_lockfile_e_supply_chain_m_lex,packages_registry_lockfile_e_supply_chain_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq packages_registry_lockfile_e_supply_chain_n_parse,packages_registry_lockfile_e_supply_chain_n_parse_len,packages_registry_lockfile_e_supply_chain_m_parse,packages_registry_lockfile_e_supply_chain_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq packages_registry_lockfile_e_supply_chain_n_type,packages_registry_lockfile_e_supply_chain_n_type_len,packages_registry_lockfile_e_supply_chain_m_type,packages_registry_lockfile_e_supply_chain_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq packages_registry_lockfile_e_supply_chain_n_codegen,packages_registry_lockfile_e_supply_chain_n_codegen_len,packages_registry_lockfile_e_supply_chain_m_codegen,packages_registry_lockfile_e_supply_chain_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq packages_registry_lockfile_e_supply_chain_n_runtime,packages_registry_lockfile_e_supply_chain_n_runtime_len,packages_registry_lockfile_e_supply_chain_m_runtime,packages_registry_lockfile_e_supply_chain_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq packages_registry_lockfile_e_supply_chain_n_security,packages_registry_lockfile_e_supply_chain_n_security_len,packages_registry_lockfile_e_supply_chain_m_security,packages_registry_lockfile_e_supply_chain_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq biblioteca_padrao_por_dominios_n_lex,biblioteca_padrao_por_dominios_n_lex_len,biblioteca_padrao_por_dominios_m_lex,biblioteca_padrao_por_dominios_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq biblioteca_padrao_por_dominios_n_parse,biblioteca_padrao_por_dominios_n_parse_len,biblioteca_padrao_por_dominios_m_parse,biblioteca_padrao_por_dominios_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq biblioteca_padrao_por_dominios_n_type,biblioteca_padrao_por_dominios_n_type_len,biblioteca_padrao_por_dominios_m_type,biblioteca_padrao_por_dominios_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq biblioteca_padrao_por_dominios_n_codegen,biblioteca_padrao_por_dominios_n_codegen_len,biblioteca_padrao_por_dominios_m_codegen,biblioteca_padrao_por_dominios_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq biblioteca_padrao_por_dominios_n_runtime,biblioteca_padrao_por_dominios_n_runtime_len,biblioteca_padrao_por_dominios_m_runtime,biblioteca_padrao_por_dominios_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq biblioteca_padrao_por_dominios_n_security,biblioteca_padrao_por_dominios_n_security_len,biblioteca_padrao_por_dominios_m_security,biblioteca_padrao_por_dominios_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq filesystem_paths_e_formatos_n_lex,filesystem_paths_e_formatos_n_lex_len,filesystem_paths_e_formatos_m_lex,filesystem_paths_e_formatos_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq filesystem_paths_e_formatos_n_parse,filesystem_paths_e_formatos_n_parse_len,filesystem_paths_e_formatos_m_parse,filesystem_paths_e_formatos_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq filesystem_paths_e_formatos_n_type,filesystem_paths_e_formatos_n_type_len,filesystem_paths_e_formatos_m_type,filesystem_paths_e_formatos_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq filesystem_paths_e_formatos_n_codegen,filesystem_paths_e_formatos_n_codegen_len,filesystem_paths_e_formatos_m_codegen,filesystem_paths_e_formatos_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq filesystem_paths_e_formatos_n_runtime,filesystem_paths_e_formatos_n_runtime_len,filesystem_paths_e_formatos_m_runtime,filesystem_paths_e_formatos_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq filesystem_paths_e_formatos_n_security,filesystem_paths_e_formatos_n_security_len,filesystem_paths_e_formatos_m_security,filesystem_paths_e_formatos_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq rede_e_protocolos_n_lex,rede_e_protocolos_n_lex_len,rede_e_protocolos_m_lex,rede_e_protocolos_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq rede_e_protocolos_n_parse,rede_e_protocolos_n_parse_len,rede_e_protocolos_m_parse,rede_e_protocolos_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq rede_e_protocolos_n_type,rede_e_protocolos_n_type_len,rede_e_protocolos_m_type,rede_e_protocolos_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq rede_e_protocolos_n_codegen,rede_e_protocolos_n_codegen_len,rede_e_protocolos_m_codegen,rede_e_protocolos_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq rede_e_protocolos_n_runtime,rede_e_protocolos_n_runtime_len,rede_e_protocolos_m_runtime,rede_e_protocolos_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq rede_e_protocolos_n_security,rede_e_protocolos_n_security_len,rede_e_protocolos_m_security,rede_e_protocolos_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq console_visual_dashboard_e_plots_n_lex,console_visual_dashboard_e_plots_n_lex_len,console_visual_dashboard_e_plots_m_lex,console_visual_dashboard_e_plots_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq console_visual_dashboard_e_plots_n_parse,console_visual_dashboard_e_plots_n_parse_len,console_visual_dashboard_e_plots_m_parse,console_visual_dashboard_e_plots_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq console_visual_dashboard_e_plots_n_type,console_visual_dashboard_e_plots_n_type_len,console_visual_dashboard_e_plots_m_type,console_visual_dashboard_e_plots_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq console_visual_dashboard_e_plots_n_codegen,console_visual_dashboard_e_plots_n_codegen_len,console_visual_dashboard_e_plots_m_codegen,console_visual_dashboard_e_plots_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq console_visual_dashboard_e_plots_n_runtime,console_visual_dashboard_e_plots_n_runtime_len,console_visual_dashboard_e_plots_m_runtime,console_visual_dashboard_e_plots_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq console_visual_dashboard_e_plots_n_security,console_visual_dashboard_e_plots_n_security_len,console_visual_dashboard_e_plots_m_security,console_visual_dashboard_e_plots_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq media_imagem_audio_e_video_n_lex,media_imagem_audio_e_video_n_lex_len,media_imagem_audio_e_video_m_lex,media_imagem_audio_e_video_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq media_imagem_audio_e_video_n_parse,media_imagem_audio_e_video_n_parse_len,media_imagem_audio_e_video_m_parse,media_imagem_audio_e_video_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq media_imagem_audio_e_video_n_type,media_imagem_audio_e_video_n_type_len,media_imagem_audio_e_video_m_type,media_imagem_audio_e_video_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq media_imagem_audio_e_video_n_codegen,media_imagem_audio_e_video_n_codegen_len,media_imagem_audio_e_video_m_codegen,media_imagem_audio_e_video_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq media_imagem_audio_e_video_n_runtime,media_imagem_audio_e_video_n_runtime_len,media_imagem_audio_e_video_m_runtime,media_imagem_audio_e_video_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq media_imagem_audio_e_video_n_security,media_imagem_audio_e_video_n_security_len,media_imagem_audio_e_video_m_security,media_imagem_audio_e_video_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq machine_learning_neuron_network_e_model_n_lex,machine_learning_neuron_network_e_model_n_lex_len,machine_learning_neuron_network_e_model_m_lex,machine_learning_neuron_network_e_model_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq machine_learning_neuron_network_e_model_n_parse,machine_learning_neuron_network_e_model_n_parse_len,machine_learning_neuron_network_e_model_m_parse,machine_learning_neuron_network_e_model_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq machine_learning_neuron_network_e_model_n_type,machine_learning_neuron_network_e_model_n_type_len,machine_learning_neuron_network_e_model_m_type,machine_learning_neuron_network_e_model_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq machine_learning_neuron_network_e_model_n_codegen,machine_learning_neuron_network_e_model_n_codegen_len,machine_learning_neuron_network_e_model_m_codegen,machine_learning_neuron_network_e_model_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq machine_learning_neuron_network_e_model_n_runtime,machine_learning_neuron_network_e_model_n_runtime_len,machine_learning_neuron_network_e_model_m_runtime,machine_learning_neuron_network_e_model_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq machine_learning_neuron_network_e_model_n_security,machine_learning_neuron_network_e_model_n_security_len,machine_learning_neuron_network_e_model_m_security,machine_learning_neuron_network_e_model_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq gpu_e_computacao_acelerada_n_lex,gpu_e_computacao_acelerada_n_lex_len,gpu_e_computacao_acelerada_m_lex,gpu_e_computacao_acelerada_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq gpu_e_computacao_acelerada_n_parse,gpu_e_computacao_acelerada_n_parse_len,gpu_e_computacao_acelerada_m_parse,gpu_e_computacao_acelerada_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq gpu_e_computacao_acelerada_n_type,gpu_e_computacao_acelerada_n_type_len,gpu_e_computacao_acelerada_m_type,gpu_e_computacao_acelerada_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq gpu_e_computacao_acelerada_n_codegen,gpu_e_computacao_acelerada_n_codegen_len,gpu_e_computacao_acelerada_m_codegen,gpu_e_computacao_acelerada_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq gpu_e_computacao_acelerada_n_runtime,gpu_e_computacao_acelerada_n_runtime_len,gpu_e_computacao_acelerada_m_runtime,gpu_e_computacao_acelerada_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq gpu_e_computacao_acelerada_n_security,gpu_e_computacao_acelerada_n_security_len,gpu_e_computacao_acelerada_m_security,gpu_e_computacao_acelerada_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq runtime_distribuido_e_streaming_distribuido_n_lex,runtime_distribuido_e_streaming_distribuido_n_lex_len,runtime_distribuido_e_streaming_distribuido_m_lex,runtime_distribuido_e_streaming_distribuido_m_lex_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq runtime_distribuido_e_streaming_distribuido_n_parse,runtime_distribuido_e_streaming_distribuido_n_parse_len,runtime_distribuido_e_streaming_distribuido_m_parse,runtime_distribuido_e_streaming_distribuido_m_parse_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq runtime_distribuido_e_streaming_distribuido_n_type,runtime_distribuido_e_streaming_distribuido_n_type_len,runtime_distribuido_e_streaming_distribuido_m_type,runtime_distribuido_e_streaming_distribuido_m_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq runtime_distribuido_e_streaming_distribuido_n_codegen,runtime_distribuido_e_streaming_distribuido_n_codegen_len,runtime_distribuido_e_streaming_distribuido_m_codegen,runtime_distribuido_e_streaming_distribuido_m_codegen_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq runtime_distribuido_e_streaming_distribuido_n_runtime,runtime_distribuido_e_streaming_distribuido_n_runtime_len,runtime_distribuido_e_streaming_distribuido_m_runtime,runtime_distribuido_e_streaming_distribuido_m_runtime_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_RUNTIME
 dq runtime_distribuido_e_streaming_distribuido_n_security,runtime_distribuido_e_streaming_distribuido_n_security_len,runtime_distribuido_e_streaming_distribuido_m_security,runtime_distribuido_e_streaming_distribuido_m_security_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_nonassoc_chain,n_nonassoc_chain_len,m_nonassoc_chain,m_nonassoc_chain_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_loop_break_outside,n_loop_break_outside_len,m_loop_break_outside,m_loop_break_outside_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_loop_continue_outside,n_loop_continue_outside_len,m_loop_continue_outside,m_loop_continue_outside_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_array_length_public,n_array_length_public_len,m_array_length_public,m_array_length_public_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_collection_record_capacity,n_collection_record_capacity_len,m_collection_record_capacity,m_collection_record_capacity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_collection_scalar_capacity,n_collection_scalar_capacity_len,m_collection_scalar_capacity,m_collection_scalar_capacity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_function_call_capacity,n_function_call_capacity_len,m_function_call_capacity,m_function_call_capacity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_binding_type_mismatch,n_binding_type_mismatch_len,m_binding_type_mismatch,m_binding_type_mismatch_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_binding_not_initialized,n_binding_not_initialized_len,m_binding_not_initialized,m_binding_not_initialized_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_call_recursion_surface,n_call_recursion_surface_len,m_call_recursion_surface,m_call_recursion_surface_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_call_recursion_shape,n_call_recursion_shape_len,m_call_recursion_shape,m_call_recursion_shape_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_call_recursion_nontail,n_call_recursion_nontail_len,m_call_recursion_nontail,m_call_recursion_nontail_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_call_recursion_frame,n_call_recursion_frame_len,m_call_recursion_frame,m_call_recursion_frame_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_nested_context,n_nested_context_len,m_nested_context,m_nested_context_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_nested_before,n_nested_before_len,m_nested_before,m_nested_before_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_nested_scope,n_nested_scope_len,m_nested_scope,m_nested_scope_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_nested_duplicate,n_nested_duplicate_len,m_nested_duplicate,m_nested_duplicate_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_nested_capacity,n_nested_capacity_len,m_nested_capacity,m_nested_capacity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_nested_capture,n_nested_capture_len,m_nested_capture,m_nested_capture_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_nested_escape,n_nested_escape_len,m_nested_escape,m_nested_escape_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_nested_recursion,n_nested_recursion_len,m_nested_recursion,m_nested_recursion_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_nested_recursive_outer,n_nested_recursive_outer_len,m_nested_recursive_outer,m_nested_recursive_outer_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_nested_receiver,n_nested_receiver_len,m_nested_receiver,m_nested_receiver_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_nested_parameter,n_nested_parameter_len,m_nested_parameter,m_nested_parameter_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_nested_return,n_nested_return_len,m_nested_return,m_nested_return_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_nested_surface,n_nested_surface_len,m_nested_surface,m_nested_surface_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_CODEGEN
 dq n_nested_symbol_collision,n_nested_symbol_collision_len,m_nested_symbol_collision,m_nested_symbol_collision_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_INTERNAL
 dq n_control_header_parens,n_control_header_parens_len,m_control_header_parens,m_control_header_parens_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_control_header_delimiter,n_control_header_delimiter_len,m_control_header_delimiter,m_control_header_delimiter_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_PARSE
 dq n_while_condition_type,n_while_condition_type_len,m_while_condition_type,m_while_condition_type_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_entrypoint_missing,n_entrypoint_missing_len,m_entrypoint_missing,m_entrypoint_missing_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_entrypoint_duplicate,n_entrypoint_duplicate_len,m_entrypoint_duplicate,m_entrypoint_duplicate_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_entrypoint_invalid,n_entrypoint_invalid_len,m_entrypoint_invalid,m_entrypoint_invalid_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_entrypoint_ambiguous,n_entrypoint_ambiguous_len,m_entrypoint_ambiguous,m_entrypoint_ambiguous_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_entrypoint_forbidden,n_entrypoint_forbidden_len,m_entrypoint_forbidden,m_entrypoint_forbidden_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_tuple_arity,n_tuple_arity_len,m_tuple_arity,m_tuple_arity_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_tuple_bounds,n_tuple_bounds_len,m_tuple_bounds,m_tuple_bounds_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_tuple_depth,n_tuple_depth_len,m_tuple_depth,m_tuple_depth_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_tuple_receiver,n_tuple_receiver_len,m_tuple_receiver,m_tuple_receiver_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_tuple_duplicate,n_tuple_duplicate_len,m_tuple_duplicate,m_tuple_duplicate_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_NAME
 dq n_unicode_confusable,n_unicode_confusable_len,m_unicode_confusable,m_unicode_confusable_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_unicode_bidi,n_unicode_bidi_len,m_unicode_bidi,m_unicode_bidi_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_unicode_invisible,n_unicode_invisible_len,m_unicode_invisible,m_unicode_invisible_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_unicode_combining,n_unicode_combining_len,m_unicode_combining,m_unicode_combining_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_unicode_malformed,n_unicode_malformed_len,m_unicode_malformed,m_unicode_malformed_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_SECURITY
 dq n_reserved_symbol,n_reserved_symbol_len,m_reserved_symbol,m_reserved_symbol_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_rejected_form,n_rejected_form_len,m_rejected_form,m_rejected_form_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_block_comment_depth,n_block_comment_depth_len,m_block_comment_depth,m_block_comment_depth_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_LEX
 dq n_owner_moved,n_owner_moved_len,m_owner_moved,m_owner_moved_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_owner_copy,n_owner_copy_len,m_owner_copy,m_owner_copy_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_owner_borrow,n_owner_borrow_len,m_owner_borrow,m_owner_borrow_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE
 dq n_public_const_write,n_public_const_write_len,m_public_const_write,m_public_const_write_len,NEBOC_DIAGNOSTIC_SEVERITY_ERROR,NEBOC_DIAGNOSTIC_PHASE_TYPE

; Public projection of the native ConstBinding write/mutability policy.
n_public_const_write: db 'NEBO_CONST_WRITE_FORBIDDEN'
n_public_const_write_len equ $-n_public_const_write
m_public_const_write: db 'ConstBinding is immutable and cannot be marked mutable or reassigned'
m_public_const_write_len equ $-m_public_const_write

section .text
; catalog_lookup(code_id, out_entry*)
NEBOC_ABI_FUNCTION neboc_diagnostic_catalog_lookup
 test rsi,rsi
 jz .invalid
 mov qword [rsi],0
 mov qword [rsi+8],0
 mov qword [rsi+16],0
 mov qword [rsi+24],0
 mov qword [rsi+32],0
 mov qword [rsi+40],0
 test rdi,rdi
 jz .invalid
 cmp rdi,NEBOC_DIAG_CATALOG_COUNT
 ja .invalid
 dec rdi
 imul rdi,NEBOC_DIAG_ENTRY_SIZE
 lea r8,[rel catalog]
 add r8,rdi
 mov rax,[r8]
 mov [rsi],rax
 mov rax,[r8+8]
 mov [rsi+8],rax
 mov rax,[r8+16]
 mov [rsi+16],rax
 mov rax,[r8+24]
 mov [rsi+24],rax
 mov rax,[r8+32]
 mov [rsi+32],rax
 mov rax,[r8+40]
 mov [rsi+40],rax
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
section .note.GNU-stack noalloc noexec nowrite progbits
