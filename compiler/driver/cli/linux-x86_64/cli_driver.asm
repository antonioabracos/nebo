; Nebo Assembly — MF035 public CLI driver for Linux x86-64
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/recovery.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/explain.inc"
%include "compiler/diagnostics/ice.inc"
%include "compiler/diagnostics/observability.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/lexer/numeric_literal_contract.inc"
%include "compiler/lexer/text_char_literal_contract.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/parser/parser.inc"
%include "compiler/parser/expression/pratt.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/parser/mutable_assignment_parser.inc"
%include "compiler/parser/parameters_parser.inc"
%include "compiler/parser/module_parser.inc"
%include "compiler/parser/generic_parser.inc"
%include "compiler/parser/nominal_types.inc"
%include "compiler/parser/buffer_parser.inc"
%include "compiler/semantic/types/buffer_freeze.inc"
%include "compiler/semantic/collections/public_slice.inc"
%include "compiler/parser/option_result_parser.inc"
%include "compiler/parser/option_result_vertical_parser.inc"
%include "compiler/parser/statements/statements.inc"
%include "compiler/semantic/types/foundation_float_semantic.inc"
%include "compiler/semantic/types/numeric_safety_vertical.inc"
%include "compiler/semantic/types/text_char_bytes_vertical.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"
%include "compiler/lowering/bindings/loop_plan.inc"
%include "compiler/semantic/types/option_result_vertical.inc"
%include "compiler/semantic/generics/generic_vertical.inc"
%include "compiler/semantic/types/domain_refinement_vertical.inc"
%include "compiler/semantic/types/programmer_type_vertical.inc"
%include "compiler/semantic/types/struct_tuple.inc"
%include "compiler/semantic/collections/array_vertical.inc"
%include "compiler/semantic/collections/array_range.inc"
%include "compiler/semantic/collections/slice_view.inc"
%include "compiler/semantic/collections/vector_vertical.inc"
%include "compiler/semantic/collections/column_vertical.inc"
%include "compiler/parser/policy_contract.inc"
%include "compiler/parser/privacy_contract.inc"
%include "compiler/parser/quality_contract.inc"
%include "compiler/semantic/quality/quality_semantic.inc"
%include "compiler/lowering/quality/quality_ir.inc"
%include "compiler/lowering/quality/quality_native.inc"
%include "runtime/quality/quality_runtime.inc"
%include "compiler/codegen/quality/x86_64/quality_codegen.inc"
%include "runtime/memory/ownership_runtime.inc"
%include "compiler/codegen/memory/x86_64/ownership_codegen.inc"
%include "compiler/semantic/memory/move_copy_clone.inc"
%include "compiler/lowering/memory/move_copy_clone_plan.inc"
%include "compiler/codegen/memory/x86_64/move_copy_clone_codegen.inc"
%include "compiler/lowering/scalars/option_result_plan.inc"
%include "compiler/lowering/functions/parameters_plan.inc"
%include "compiler/lowering/modules/module_plan.inc"
%include "compiler/lowering/generics/generic_plan.inc"
%include "compiler/lowering/aggregates/nominal_plan.inc"
%include "compiler/lowering/textual/buffer_plan.inc"
%include "compiler/codegen/scalars/x86_64/option_layout_codegen.inc"
%include "compiler/codegen/functions/x86_64/parameters_codegen.inc"
%include "compiler/codegen/modules/x86_64/module_graph_codegen.inc"
%include "compiler/codegen/generics/x86_64/generic_instance_codegen.inc"
%include "compiler/codegen/aggregates/x86_64/nominal_codegen.inc"
%include "compiler/codegen/textual/x86_64/buffer_codegen.inc"
%include "compiler/lowering/aggregates/struct_tuple_plan.inc"
%include "compiler/lowering/collections/array_range_plan.inc"
%include "compiler/lowering/collections/slice_view_plan.inc"
%include "runtime/modules/module_runtime.inc"
%include "compiler/codegen/modules/x86_64/module_codegen.inc"
%include "runtime/package/package_runtime.inc"
%include "compiler/codegen/package/x86_64/package_codegen.inc"
%include "runtime/stdlib/std_math_runtime.inc"
%include "compiler/codegen/stdlib/x86_64/std_math_codegen.inc"
%include "runtime/stdlib/path_query_runtime.inc"
%include "compiler/codegen/stdlib/x86_64/path_query_codegen.inc"
%include "runtime/stdlib/net_port_runtime.inc"
%include "compiler/codegen/stdlib/x86_64/net_port_codegen.inc"
%include "runtime/stdlib/visual_summary_runtime.inc"
%include "compiler/codegen/stdlib/x86_64/visual_summary_codegen.inc"
%include "compiler/semantic/privacy/privacy_semantic.inc"
%include "compiler/lowering/privacy/privacy_ir.inc"
%include "compiler/lowering/privacy/privacy_native.inc"
%include "runtime/privacy/privacy_runtime.inc"
%include "compiler/codegen/privacy/x86_64/privacy_codegen.inc"
%include "compiler/semantic/effect/effect_policy.inc"
%include "compiler/semantic/effect/effect_policy_semantic.inc"
%include "compiler/lowering/effects/effect_policy_ir.inc"
%include "compiler/lowering/effects/effect_policy_native.inc"
%include "runtime/effects/effect_policy_runtime.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "runtime/scalars/float/foundation_float_runtime.inc"
%include "compiler/data-layout/data_layout.inc"
%include "compiler/target/target_context.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/core/x86_64/value_codegen.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/functions/x86_64/function_codegen.inc"
%include "compiler/codegen/scalars/x86_64/foundation_float_codegen.inc"
%include "compiler/codegen/scalars/x86_64/numeric_safety_codegen.inc"
%include "compiler/codegen/textual/x86_64/text_char_bytes_codegen.inc"
%include "compiler/codegen/bindings/x86_64/binding_codegen.inc"
%include "compiler/codegen/scalars/x86_64/option_result_codegen.inc"
%include "compiler/codegen/generics/x86_64/generic_codegen.inc"
%include "compiler/codegen/domain/x86_64/domain_refinement_codegen.inc"
%include "compiler/codegen/aggregates/x86_64/programmer_type_codegen.inc"
%include "compiler/codegen/aggregates/x86_64/struct_tuple_codegen.inc"
%include "compiler/codegen/collections/x86_64/array_codegen.inc"
%include "compiler/codegen/collections/x86_64/array_range_codegen.inc"
%include "compiler/codegen/collections/x86_64/slice_view_codegen.inc"
%include "compiler/codegen/collections/x86_64/vector_codegen.inc"
%include "compiler/codegen/collections/x86_64/column_codegen.inc"
%include "compiler/codegen/effects/x86_64/effect_policy_codegen.inc"
%include "compiler/format/elf64/format_adapter.inc"
%include "compiler/toolchain/toolchain_descriptor.inc"
%include "compiler/driver/cli/linux-x86_64/cli_driver.inc"

extern neboc_lexer_scan
extern neboc_ast_builder_init
extern neboc_parser_parse
extern neboc_ast_builder_node
extern neboc_statement_parse_block
extern neboc_foundation_float_recognize
extern neboc_numeric_safety_vertical_recognize
extern neboc_text_char_bytes_vertical_recognize
extern neboc_binding_vertical_recognize
extern neboc_loop_plan_lower
extern neboc_mutable_assignment_recognize
extern neboc_parameters_recognize
extern neboc_parameters_analyze
extern neboc_parameters_lower
extern neboc_seguranca_numerica_conversoes_e_overflow_module_parse
extern neboc_module_analyze
extern neboc_module_lower
extern neboc_generic_parse
extern neboc_generic_analyze
extern neboc_generic_lower
extern neboc_nominal_parse
extern neboc_nominal_analyze
extern neboc_nominal_lower
extern neboc_buffer_parse
extern neboc_buffer_analyze
extern neboc_buffer_lower
extern neboc_option_recognize
extern neboc_option_lower
extern neboc_result_recognize
extern neboc_result_lower
extern neboc_option_result_vertical_parse
extern neboc_option_result_vertical_analyze
extern neboc_generic_vertical_recognize
extern neboc_domain_refinement_vertical_recognize
extern neboc_programmer_type_vertical_recognize
extern neboc_struct_tuple_recognize
extern neboc_struct_tuple_lower
extern neboc_array_vertical_recognize
extern neboc_array_range_recognize
extern neboc_array_range_lower
extern neboc_slice_lower
extern neboc_vector_vertical_recognize
extern neboc_column_vertical_recognize
extern neboc_option_result_null_externo_e_erros_tipados_generic_codegen_emit_start
extern neboc_nominal_codegen_emit_start
extern neboc_buffer_codegen_emit_start
extern neboc_policy_parse
extern neboc_privacy_parse
extern neboc_quality_parse
extern neboc_quality_semantic_analyze
extern neboc_quality_ir_lower
extern neboc_quality_native_lower
extern neboc_quality_runtime_gate
extern neboc_quality_codegen_emit_start
extern neboc_ownership_parse
extern neboc_ownership_transition
extern neboc_ownership_semantic_analyze
extern neboc_ownership_ir_lower
extern neboc_ownership_native_lower
extern neboc_ownership_runtime_execute
extern neboc_ownership_codegen_emit_start
extern neboc_move_copy_clone_recognize
extern neboc_move_copy_clone_lower
extern neboc_move_copy_clone_codegen_emit_start
extern neboc_imports_modulos_namespaces_e_api_publica_module_parse
extern neboc_module_visibility_init
extern neboc_module_semantic_build
extern neboc_module_ir_lower
extern neboc_module_native_lower
extern neboc_module_runtime_execute
extern neboc_imports_modulos_namespaces_e_api_publica_module_codegen_emit_start
extern neboc_package_manifest_parse
extern neboc_package_lock_init
extern neboc_package_semantic_build
extern neboc_package_ir_lower
extern neboc_package_native_lower
extern neboc_package_runtime_execute
extern neboc_package_codegen_emit_start
extern neboc_std_math_parse
extern neboc_std_math_init
extern neboc_std_math_semantic_build
extern neboc_std_math_ir_lower
extern neboc_std_math_native_lower
extern neboc_std_math_runtime_execute
extern neboc_std_math_codegen_emit_start
extern neboc_path_query_parse
extern neboc_path_query_init
extern neboc_path_query_semantic_build
extern neboc_path_query_ir_lower
extern neboc_path_query_native_lower
extern neboc_path_query_runtime_execute
extern neboc_path_query_codegen_emit_start
extern neboc_net_port_parse
extern neboc_net_port_init
extern neboc_net_port_semantic_build
extern neboc_net_port_ir_lower
extern neboc_net_port_native_lower
extern neboc_net_port_runtime_execute
extern neboc_net_port_codegen_emit_start
extern neboc_visual_summary_parse
extern neboc_visual_summary_init
extern neboc_visual_summary_semantic_build
extern neboc_visual_summary_ir_lower
extern neboc_visual_summary_native_lower
extern neboc_visual_summary_runtime_execute
extern neboc_visual_summary_codegen_emit_start
extern neboc_privacy_semantic_analyze
extern neboc_privacy_ir_lower
extern neboc_privacy_native_lower
extern neboc_privacy_runtime_check
extern neboc_privacy_codegen_emit_start
extern neboc_policy_semantic_analyze
extern neboc_policy_ir_lower
extern neboc_policy_native_lower
extern neboc_policy_runtime_check
extern neboc_foundation_float_materialize_literal
extern neboc_foundation_float_runtime_classify
extern neboc_data_layout_init_first_target
extern neboc_target_context_init
extern neboc_assembly_writer_init
extern neboc_assembly_writer_append_bytes
extern neboc_arch_backend_init
extern neboc_arch_backend_begin_module
extern neboc_arch_backend_begin_function
extern neboc_arch_backend_end_module
extern neboc_core_value_codegen_init
extern neboc_core_value_codegen_emit_start
extern neboc_abi_adapter_init
extern neboc_function_codegen_init
extern neboc_function_codegen_emit
extern neboc_foundation_float_codegen_emit_start
extern neboc_numeric_safety_codegen_emit_start
extern neboc_text_char_bytes_codegen_emit_data
extern neboc_text_char_bytes_codegen_emit_start
extern neboc_binding_codegen_emit_start
extern neboc_option_codegen_emit_start
extern neboc_result_codegen_emit_start
extern neboc_parameters_codegen_emit_start
extern neboc_seguranca_numerica_conversoes_e_overflow_module_codegen_emit_start
extern neboc_option_result_codegen_emit_start
extern neboc_generics_constraints_overload_e_dispatch_generic_codegen_emit_start
extern neboc_domain_refinement_codegen_emit_start
extern neboc_programmer_type_codegen_emit_start
extern neboc_struct_tuple_codegen_emit_start
extern neboc_array_codegen_emit_start
extern neboc_array_range_codegen_emit_start
extern neboc_slice_codegen_emit_start
extern neboc_vector_codegen_emit_start
extern neboc_column_codegen_emit_start
extern neboc_policy_codegen_emit_start
extern neboc_format_adapter_init
extern neboc_format_adapter_emit_entry_prelude
extern neboc_toolchain_init
extern neboc_toolchain_build_assembler_invocation
extern neboc_toolchain_build_linker_invocation
extern neboc_toolchain_execute
extern nebo_bench_cli_run
extern neboc_diagnostic_explanation_load
extern neboc_diagnostic_explanation_render
extern neboc_diagnostic_explanation_search
extern neboc_ice_report_new
extern neboc_ice_report_node_identity
extern neboc_ice_report_phase_trace
extern neboc_ice_report_compiler_manifest
extern neboc_ice_report_redact
extern neboc_ice_report_reproducer
extern neboc_ice_report_write
extern neboc_ice_bundle_inspect
extern neboc_ice_bundle_minimize
extern neboc_terminal_capabilities

section .rodata
cli_help_text:
 db 'Nebo compiler (neboc)',10,10
 db 'Usage:',10
 db '  neboc --help',10
 db '  neboc --version',10
 db '  neboc bench numeric',10
 db '  neboc probabilistic-report <artifact>',10
 db '  neboc firmware build --board NEBO_REFERENCE_BOARD_SIM_V1',10
 db '  neboc firmware test --simulator NEBO_REFERENCE_BOARD_SIM_V1',10
 db '  neboc simulation-replay <log>',10
 db '  neboc crypto-audit <artifact>',10
 db '  neboc optimize-explain <file>',10
 db '  neboc bootstrap --verify',10
 db '  neboc protocol generate <schema>',10
 db '  neboc protocol fuzz <schema>',10
 db '  neboc warnings --list',10
 db '  neboc diagnostic-schema --version 1',10
 db '  neboc explain <diagnostic-code>',10
 db '  neboc diagnostics --search <term>',10
 db '  neboc bug-report --local <source>',10
 db '  neboc bug-report --inspect <bundle>',10
 db '  neboc minimize-ice <bundle>',10
 db '  neboc exit-codes',10
 db '  neboc check <file.no> [--message-format human|short|json|json-lines|sarif]',10
 db '              [--color auto|always|never] [--emit-build-events <path>]',10
 db '              [--path-style relative|workspace|absolute] [--diagnostic-width 40..240]',10
 db '              [--max-errors 1..64] [--fail-fast|--keep-going] [--show-fixes]',10
 db '              [--unit <file.no>]...',10
 db '  neboc emit-asm <file.no> -o <file.asm> [--unit <file.no>]...',10
 db '  neboc build <file.no> -o <artifact> [--keep-temp] [--unit <file.no>]...',10
 db '              [--progress auto|always|never] [--quiet|--verbose] [--trace driver|diagnostics|codegen]',10,10
 db 'Commands:',10
 db '  bench       Run the bounded local numeric benchmark.',10
 db '  probabilistic-report  Inspect a redacted versioned probabilistic artifact.',10
 db '  firmware    Build or test the bounded simulator-only reference image.',10
 db '  simulation-replay  Validate and replay a bounded versioned simulation log.',10
 db '  crypto-audit  Inspect crypto metadata without reading secret bytes.',10
 db '  optimize-explain  Report bounded optimization facts.',10
 db '  bootstrap   Verify factual stage0 and source-compiler availability.',10
 db '  protocol    Generate bounded typed protocol artifacts.',10
 db '  warnings    List the stable warning groups and defaults.',10
 db '  explain     Show a versioned diagnostic explanation from the offline catalog.',10
 db '  diagnostics Search the bounded offline diagnostic catalog.',10
 db '  bug-report  Create or inspect a redacted local ICE bundle.',10
 db '  minimize-ice  Emit a bounded local ICE reproducer summary.',10
 db '  exit-codes  List the stable public process exit contract.',10
 db '  check       Validate source without invoking the toolchain.',10
 db '  emit-asm    Emit deterministic NASM Intel assembly.',10
 db '  build       Produce a native ELF64 executable.',10,10
 db 'Target: x86_64-systemv-elf-linux',10
cli_help_text_end:

cli_version_text: db 'neboc ',NEBO_VERSION_STRING,10
cli_version_text_end:

cli_error_usage: db 'neboc: usage error',10
cli_error_usage_end:
cli_error_unknown: db 'neboc: unknown command',10
cli_error_unknown_end:
cli_error_extension: db 'neboc: source file must use the .no extension',10
cli_error_extension_end:
cli_error_output_path: db 'neboc: invalid output path',10
cli_error_output_path_end:
cli_error_source: db 'neboc: source validation failed',10
cli_error_source_end:
cli_error_float_constructor: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-TYPE-003: Float(expr) requires one Float expression, implicit Int-to-Float coercion is forbidden',10
cli_error_float_constructor_end:
cli_error_float_mixed: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-TYPE-003: Float arithmetic requires homogeneous Float operands, implicit coercion is forbidden',10
cli_error_float_mixed_end:
cli_error_float_operator: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-CODEGEN-004: this Float operator is outside the TIPOS-PRIMITIVOS-ESCALARES-PF005 vertical slice',10
cli_error_float_operator_end:
cli_error_float_context: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-CODEGEN-004: this Float context is not executable in TIPOS-PRIMITIVOS-ESCALARES-PF005',10
cli_error_float_context_end:
cli_error_float_literal: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-SECURITY-006: Float literal cannot be materialized safely',10
cli_error_float_literal_end:
cli_error_missing_digits: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-MISSING-DIGITS: numeric base prefix requires at least one valid digit',10
cli_error_missing_digits_end:
cli_error_invalid_digit: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-INVALID-DIGIT: digit is invalid for the selected numeric base',10
cli_error_invalid_digit_end:
cli_error_invalid_separator: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-INVALID-SEPARATOR: underscore must appear once between valid digits',10
cli_error_invalid_separator_end:
cli_error_uppercase_prefix: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-UPPERCASE-PREFIX: use lowercase 0b, 0x or 0o',10
cli_error_uppercase_prefix_end:
cli_error_unknown_prefix: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-UNKNOWN-PREFIX: unknown numeric base prefix',10
cli_error_unknown_prefix_end:
cli_error_suffix: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-SUFFIX-UNAVAILABLE: numeric suffixes are not available in this profile',10
cli_error_suffix_end:
literais_numericos_bases_e_representacao_cli_error_overflow: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-LITERAL-OVERFLOW: literal exceeds the signed 64-bit Int domain',10
literais_numericos_bases_e_representacao_cli_error_overflow_end:
cli_error_float_separator: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-FLOAT-SEPARATOR-UNAVAILABLE: Float separators are not available in this profile',10
cli_error_float_separator_end:
seguranca_numerica_conversoes_e_overflow_cli_error_unknown: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-API-UNKNOWN: unknown numeric foundation API',10
seguranca_numerica_conversoes_e_overflow_cli_error_unknown_end:
seguranca_numerica_conversoes_e_overflow_cli_error_alias: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-ALIAS-FORBIDDEN: use the canonical numeric foundation API name',10
seguranca_numerica_conversoes_e_overflow_cli_error_alias_end:
seguranca_numerica_conversoes_e_overflow_cli_error_arguments: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-ARGUMENTS-NOT-ALLOWED: this numeric foundation API takes zero arguments',10
seguranca_numerica_conversoes_e_overflow_cli_error_arguments_end:
cli_error_need_int: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-RECEIVER-MUST-BE-INT: toFloat() requires an Int receiver',10
cli_error_need_int_end:
cli_error_need_float: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-RECEIVER-MUST-BE-FLOAT: Float classifier requires a Float receiver',10
cli_error_need_float_end:
cli_error_implicit: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-IMPLICIT-COERCION-FORBIDDEN: use explicit Int.toFloat()',10
cli_error_implicit_end:
cli_error_cast: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-CAST-SYNTAX-UNAVAILABLE: cast syntax is not available in this profile',10
cli_error_cast_end:
seguranca_numerica_conversoes_e_overflow_cli_error_deferred: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-DEFERRED-API: this numeric API is deferred beyond the foundation profile',10
seguranca_numerica_conversoes_e_overflow_cli_error_deferred_end:
seguranca_numerica_conversoes_e_overflow_cli_error_constructor: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-NUMERIC-CROSS-TYPE-CONSTRUCTOR-FORBIDDEN: constructors do not perform numeric conversion',10
seguranca_numerica_conversoes_e_overflow_cli_error_constructor_end:
cli_error_char_bom: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-BOM-FORBIDDEN: source BOM is not allowed',10
cli_error_char_bom_end:
cli_error_char_open: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-EXPECTED-OPEN-QUOTE: Char literal must begin with a single quote',10
cli_error_char_open_end:
cli_error_char_unterminated: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-UNTERMINATED: Char literal is not terminated',10
cli_error_char_unterminated_end:
cli_error_char_empty: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-EMPTY: Char literal requires exactly one Unicode scalar',10
cli_error_char_empty_end:
cli_error_char_multiple: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-MULTIPLE-SCALARS: Char literal contains more than one Unicode scalar',10
cli_error_char_multiple_end:
cli_error_char_escape: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-INVALID-ESCAPE: Char escape is not in the foundation profile',10
cli_error_char_escape_end:
cli_error_char_newline: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-PHYSICAL-NEWLINE: physical newline is not allowed in a Char literal',10
cli_error_char_newline_end:
cli_error_char_utf8: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-INVALID-UTF8: Char literal must contain valid canonical UTF-8',10
cli_error_char_utf8_end:
cli_error_char_surrogate: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-SURROGATE: surrogate code points are not Unicode scalars',10
cli_error_char_surrogate_end:
cli_error_char_range: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-CHAR-OUT-OF-RANGE: Char scalar exceeds U+10FFFF',10
cli_error_char_range_end:
text_char_unicode_e_bytes_cli_error_unknown: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN: unknown Text/Char/Bytes foundation API',10
text_char_unicode_e_bytes_cli_error_unknown_end:
text_char_unicode_e_bytes_cli_error_alias: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-ALIAS-FORBIDDEN: use canonical Text, Char, Bytes and method names',10
text_char_unicode_e_bytes_cli_error_alias_end:
text_char_unicode_e_bytes_cli_error_arguments: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-ARGUMENTS-NOT-ALLOWED: this foundation API takes zero arguments',10
text_char_unicode_e_bytes_cli_error_arguments_end:
cli_error_need_text: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-RECEIVER-MUST-BE-TEXT: this API requires a Text receiver',10
cli_error_need_text_end:
cli_error_need_char: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-RECEIVER-MUST-BE-CHAR: codepoint() requires a Char receiver',10
cli_error_need_char_end:
cli_error_need_bytes: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-RECEIVER-MUST-BE-BYTES: this API requires a Bytes receiver',10
cli_error_need_bytes_end:
cli_error_type_receiver: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-TYPE-RECEIVER-REQUIRED: Bytes.empty() requires the Bytes type receiver',10
cli_error_type_receiver_end:
cli_error_instance_receiver: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-INSTANCE-RECEIVER-REQUIRED: this API requires a value receiver',10
cli_error_instance_receiver_end:
text_char_unicode_e_bytes_cli_error_deferred: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-DEFERRED-API: this textual API is deferred beyond the foundation profile',10
text_char_unicode_e_bytes_cli_error_deferred_end:
cli_error_bytes_literal: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-BYTES-LITERAL-UNAVAILABLE: Bytes literals are not available in this profile',10
cli_error_bytes_literal_end:
cli_error_byte_below: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-001: byte value must be in 0..255; negative literal is forbidden',10
cli_error_byte_below_end:
cli_error_byte_above: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-002: byte value must be in 0..255',10
cli_error_byte_above_end:
cli_error_from_byte_arity: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-003: Bytes.fromByte requires exactly one argument',10
cli_error_from_byte_arity_end:
cli_error_from_values_arity: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-004: Bytes.fromValues requires exactly four arguments',10
cli_error_from_values_arity_end:
cli_error_constructor_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-005: Bytes constructor arguments must be Int literals',10
cli_error_constructor_type_end:
cli_error_constructor_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-006: dynamic Bytes constructor arguments are deferred',10
cli_error_constructor_dynamic_end:
cli_error_index_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-007: Bytes index must be an Int literal',10
cli_error_index_type_end:
cli_error_index_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-008: dynamic Bytes index or slice bound is deferred',10
cli_error_index_dynamic_end:
cli_error_at_bounds: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-009: Bytes.at index is out of bounds',10
cli_error_at_bounds_end:
cli_error_slice_range: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-010: Bytes.slice requires 0 <= start <= end <= byteLength and exactly two bounds',10
cli_error_slice_range_end:
cli_error_bit_receiver: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-011: bounded bit methods require an Int receiver',10
cli_error_bit_receiver_end:
cli_error_bit_argument: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-012: bounded bit method argument has an incompatible type',10
cli_error_bit_argument_end:
cli_error_bit_arity: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-013: bounded bit methods received the wrong number of arguments',10
cli_error_bit_arity_end:
cli_error_shift_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-014: shift count must be an Int literal',10
cli_error_shift_type_end:
cli_error_shift_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-015: dynamic shift count is deferred',10
cli_error_shift_dynamic_end:
cli_error_shift_range: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-016: shift count must be in 0..63',10
cli_error_shift_range_end:
cli_error_position_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-017: bit position must be an Int literal',10
cli_error_position_type_end:
cli_error_position_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-018: dynamic bit position is deferred',10
cli_error_position_dynamic_end:
cli_error_position_range: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-019: bit position must be in 0..63',10
cli_error_position_range_end:
cli_error_undefined: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-UNDEFINED-NAME: binding name is not declared in the visible scope',10
cli_error_undefined_end:
cli_error_use_before: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-USE-BEFORE-INITIALIZATION: binding must be initialized before it is read',10
cli_error_use_before_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_duplicate: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-DUPLICATE-DECLARATION: binding name is already declared in this scope',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_duplicate_end:
cli_error_already: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-ALREADY-INITIALIZED: immutable binding may be initialized exactly once',10
cli_error_already_end:
cli_error_shadow: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-SHADOWING-FORBIDDEN: shadowing is not available in this profile',10
cli_error_shadow_end:
cli_error_reserved: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-RESERVED-NAME: this name is reserved by the language',10
cli_error_reserved_end:
cli_error_void: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-VOID-FORBIDDEN: Void cannot be used as a binding value type',10
cli_error_void_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_type: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-TYPE-MISMATCH: initializer type does not match the declared binding type',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_type_end:
cli_error_not_definite: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-NOT-DEFINITELY-INITIALIZED: binding is not initialized on every predecessor path',10
cli_error_not_definite_end:
cli_error_assignment: db 'NEBO-bindings_constantes_mutabilidade_e_definite_assignment-BINDING-ASSIGNMENT-SYNTAX-UNAVAILABLE: assignment syntax is not available; use one-shot expression.name',10
cli_error_assignment_end:
cli_error_const: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-CONST-DECLARATION-DEFERRED: declarative constants are deferred',10
cli_error_const_end:
cli_error_mutable: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-MUTABLE-DECLARATION-DEFERRED: mutable bindings are deferred',10
cli_error_mutable_end:
cli_error_named: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-NAMED-ARGUMENTS-DEFERRED: named arguments are deferred',10
cli_error_named_end:
cli_error_invalid: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-BINDING-INVALID-NAME: binding name is not a valid identifier',10
cli_error_invalid_end:
literais_numericos_bases_e_representacao_cli_error_001: db 'NEBO-cli_driver-literais_numericos_bases_e_representacao-001: invalid mutable binding syntax; expected value.name.mutable;',10
literais_numericos_bases_e_representacao_cli_error_001_end:
literais_numericos_bases_e_representacao_cli_error_002: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-002: mutable marker is duplicated',10
literais_numericos_bases_e_representacao_cli_error_002_end:
literais_numericos_bases_e_representacao_cli_error_003: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-003: mutable binding requires an initializer',10
literais_numericos_bases_e_representacao_cli_error_003_end:
literais_numericos_bases_e_representacao_cli_error_004: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-004: mutable binding type is outside the bounded scalar profile',10
literais_numericos_bases_e_representacao_cli_error_004_end:
literais_numericos_bases_e_representacao_cli_error_005: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-005: assignment target is not declared',10
literais_numericos_bases_e_representacao_cli_error_005_end:
literais_numericos_bases_e_representacao_cli_error_006: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-006: assignment target is immutable',10
literais_numericos_bases_e_representacao_cli_error_006_end:
literais_numericos_bases_e_representacao_cli_error_007: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-007: assignment target is not an assignable local place',10
literais_numericos_bases_e_representacao_cli_error_007_end:
literais_numericos_bases_e_representacao_cli_error_008: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-008: local binding is outside its lexical scope',10
literais_numericos_bases_e_representacao_cli_error_008_end:
cli_error_010: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-010: assignment value type does not match the target place type',10
cli_error_010_end:
literais_numericos_bases_e_representacao_cli_error_012: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-012: assignment is a statement and cannot be used as an expression',10
literais_numericos_bases_e_representacao_cli_error_012_end:
literais_numericos_bases_e_representacao_cli_error_013: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-013: chained assignment is forbidden in the F02 profile',10
literais_numericos_bases_e_representacao_cli_error_013_end:
literais_numericos_bases_e_representacao_cli_error_014: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-014: compound assignment is limited to mutable Int += and -= in the F04 profile',10
literais_numericos_bases_e_representacao_cli_error_014_end:
cli_error_030: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-030: break is only valid inside a lexical loop',10
cli_error_030_end:
cli_error_031: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-031: continue is only valid inside a lexical loop',10
cli_error_031_end:
cli_error_032: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-032: while condition must have type Bool',10
cli_error_032_end:
cli_error_034: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-034: loop CFG contains unreachable code or violates cleanup invariants',10
cli_error_034_end:
cli_error_036: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-036: bounded loop nesting capacity exceeded',10
cli_error_036_end:
cli_error_037: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-037: for iterator source must be a live bounded Range, Array or Slice',10
cli_error_037_end:
cli_error_038: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-038: collection mutation during bounded iteration is forbidden',10
cli_error_038_end:
cli_error_039: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-039: iterator cardinality exceeds the checked bounded profile',10
cli_error_039_end:
cli_error_040: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-040: invalid canonical for iterator syntax or body action',10
cli_error_040_end:
cli_error_041: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-041: bounded for nesting capacity exceeded',10
cli_error_041_end:
text_char_unicode_e_bytes_cli_error_001: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-001: value cannot be used after it has been moved',10
text_char_unicode_e_bytes_cli_error_001_end:
text_char_unicode_e_bytes_cli_error_002: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-002: resource cannot be dropped more than once',10
text_char_unicode_e_bytes_cli_error_002_end:
text_char_unicode_e_bytes_cli_error_003: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-003: shared and unique borrows conflict',10
text_char_unicode_e_bytes_cli_error_003_end:
text_char_unicode_e_bytes_cli_error_004: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-004: value cannot be moved or mutated while borrowed',10
text_char_unicode_e_bytes_cli_error_004_end:
text_char_unicode_e_bytes_cli_error_005: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-005: borrow cannot escape its owner region',10
text_char_unicode_e_bytes_cli_error_005_end:
text_char_unicode_e_bytes_cli_error_006: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-006: unique owner cannot be copied or implicitly cloned',10
text_char_unicode_e_bytes_cli_error_006_end:
text_char_unicode_e_bytes_cli_error_007: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-007: clone or ownership operation is unavailable for this bounded value',10
text_char_unicode_e_bytes_cli_error_007_end:
text_char_unicode_e_bytes_cli_error_013: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-013: resource path would leak without cleanup',10
text_char_unicode_e_bytes_cli_error_013_end:
text_char_unicode_e_bytes_cli_error_internal: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-INTERNAL: bounded ownership plan authentication failed',10
text_char_unicode_e_bytes_cli_error_internal_end:
seguranca_numerica_conversoes_e_overflow_cli_error_001: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-001: invalid bounded receiver-first function signature',10
seguranca_numerica_conversoes_e_overflow_cli_error_001_end:
seguranca_numerica_conversoes_e_overflow_cli_error_002: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-002: duplicate parameter name in bounded signature',10
seguranca_numerica_conversoes_e_overflow_cli_error_002_end:
seguranca_numerica_conversoes_e_overflow_cli_error_003: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-003: defaults must be trailing immutable literals of the declared type',10
seguranca_numerica_conversoes_e_overflow_cli_error_003_end:
seguranca_numerica_conversoes_e_overflow_cli_error_004: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-004: duplicate exact or return-only overload signature',10
seguranca_numerica_conversoes_e_overflow_cli_error_004_end:
seguranca_numerica_conversoes_e_overflow_cli_error_005: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-005: overload remains ambiguous after declared constraints',10
seguranca_numerica_conversoes_e_overflow_cli_error_005_end:
seguranca_numerica_conversoes_e_overflow_cli_error_006: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-006: receiver plus parameters exceeds the six-register ABI profile',10
seguranca_numerica_conversoes_e_overflow_cli_error_006_end:
seguranca_numerica_conversoes_e_overflow_cli_error_007: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-007: canonical mangled symbol collision',10
seguranca_numerica_conversoes_e_overflow_cli_error_007_end:
cli_error_011: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-011: named argument is supplied more than once',10
cli_error_011_end:
seguranca_numerica_conversoes_e_overflow_cli_error_012: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-012: required bounded argument is missing',10
seguranca_numerica_conversoes_e_overflow_cli_error_012_end:
seguranca_numerica_conversoes_e_overflow_cli_error_013: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-013: extra or unknown bounded argument',10
seguranca_numerica_conversoes_e_overflow_cli_error_013_end:
seguranca_numerica_conversoes_e_overflow_cli_error_014: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-014: receiver or argument type does not match the signature',10
seguranca_numerica_conversoes_e_overflow_cli_error_014_end:
seguranca_numerica_conversoes_e_overflow_cli_error_015: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-015: return expression or Tuple projection is invalid',10
seguranca_numerica_conversoes_e_overflow_cli_error_015_end:
seguranca_numerica_conversoes_e_overflow_cli_error_016: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-016: invalid bounded call, named argument or return syntax',10
seguranca_numerica_conversoes_e_overflow_cli_error_016_end:
seguranca_numerica_conversoes_e_overflow_cli_error_017: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-017: closure borrow capture escapes its lexical owner',10
seguranca_numerica_conversoes_e_overflow_cli_error_017_end:
seguranca_numerica_conversoes_e_overflow_cli_error_018: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-018: callable argument or callback signature mismatch',10
seguranca_numerica_conversoes_e_overflow_cli_error_018_end:
seguranca_numerica_conversoes_e_overflow_cli_error_019: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-019: callable environment is dropped more than once',10
seguranca_numerica_conversoes_e_overflow_cli_error_019_end:
seguranca_numerica_conversoes_e_overflow_cli_error_020: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-020: bounded callable environment capacity exceeded',10
seguranca_numerica_conversoes_e_overflow_cli_error_020_end:
seguranca_numerica_conversoes_e_overflow_cli_error_021: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-021: imported static module is missing from the bounded unit set',10
seguranca_numerica_conversoes_e_overflow_cli_error_021_end:
seguranca_numerica_conversoes_e_overflow_cli_error_022: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-022: private module export is inaccessible from the importing unit',10
seguranca_numerica_conversoes_e_overflow_cli_error_022_end:
seguranca_numerica_conversoes_e_overflow_cli_error_023: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-023: static module import graph contains a cycle',10
seguranca_numerica_conversoes_e_overflow_cli_error_023_end:
seguranca_numerica_conversoes_e_overflow_cli_error_008: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-008: canonical module identity collision',10
seguranca_numerica_conversoes_e_overflow_cli_error_008_end:
seguranca_numerica_conversoes_e_overflow_cli_error_024: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-024: qualified symbol is not exported by the referenced module',10
seguranca_numerica_conversoes_e_overflow_cli_error_024_end:
cli_error_025: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-025: bounded three-unit module capacity exceeded',10
cli_error_025_end:
seguranca_numerica_conversoes_e_overflow_cli_error_internal: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-INTERNAL: parameter semantic, ABI or lowering proof failed',10
seguranca_numerica_conversoes_e_overflow_cli_error_internal_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_001: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-001: Option payload type or value is invalid for the bounded profile',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_001_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_002: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-002: Option variant does not match its declared container',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_002_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_003: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-003: Option A0 layout exceeds the checked bounded profile',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_003_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_004: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-004: Option value is not in canonical explicit-tag form',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_004_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_005: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-005: Option combinator callback result has the wrong type',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_005_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_006: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-006: Option combinator callback must remain lazy',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_006_end:
cli_error_result_001: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-001: Result payload or type argument is invalid for the bounded profile',10
cli_error_result_001_end:
cli_error_result_002: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-002: Result variant does not match its declared container',10
cli_error_result_002_end:
cli_error_result_003: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-003: Result A0 layout exceeds the checked bounded profile',10
cli_error_result_003_end:
cli_error_result_004: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-004: Result value is not in canonical explicit-tag form',10
cli_error_result_004_end:
cli_error_result_005: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-005: Result combinator callback result has the wrong type',10
cli_error_result_005_end:
cli_error_result_006: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-006: Result combinator callback must remain lazy',10
cli_error_result_006_end:
cli_error_result_007: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-007: propagation requires an enclosing Result with the exact error type',10
cli_error_result_007_end:
cli_error_result_008: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-008: match does not cover every bounded variant',10
cli_error_result_008_end:
cli_error_result_009: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-009: match arm is duplicate or unreachable after complete coverage',10
cli_error_result_009_end:
cli_error_result_010: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-010: match payload binding type or ownership conflicts with its pattern',10
cli_error_result_010_end:
cli_error_result_011: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-011: structured Error code span context cause or allocation invariant is invalid',10
cli_error_result_011_end:
cli_error_result_012: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-012: exception panic or Error type erasure is forbidden',10
cli_error_result_012_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_013: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-013: get cannot inspect a None value safely',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_013_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_014: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-014: Option value is used after drop/move or escapes the bounded scope',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_014_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_015: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-015: invalid bounded Option construction or combinator syntax',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_015_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_016: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-016: Result inspection selected the inactive side',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_016_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_017: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-017: Result value is used after drop/move or escapes the bounded scope',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_017_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_018: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-018: invalid bounded Result construction or combinator syntax',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_018_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_019: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-019: propagation context was dropped before the early-return edge',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_019_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_020: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-020: Result cleanup is scheduled more than once',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_020_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_021: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-021: invalid bounded postfix Result propagation syntax',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_021_end:
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_internal: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-INTERNAL: Option semantic or lowering proof failed',10
bindings_constantes_mutabilidade_e_definite_assignment_cli_error_internal_end:
cli_error_result_internal: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-INTERNAL: Result semantic or lowering proof failed',10
cli_error_result_internal_end:
option_result_null_externo_e_erros_tipados_cli_error_001: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-001: by-value recursive struct layout is forbidden',10
option_result_null_externo_e_erros_tipados_cli_error_001_end:
option_result_null_externo_e_erros_tipados_cli_error_003: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-003: composite layout exceeds the checked bounded profile',10
option_result_null_externo_e_erros_tipados_cli_error_003_end:
option_result_null_externo_e_erros_tipados_cli_error_005: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-005: Tuple position is outside the constructed value',10
option_result_null_externo_e_erros_tipados_cli_error_005_end:
cli_error_005_array: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-005: Array index is outside the compile-time bounded value',10
cli_error_005_array_end:
option_result_null_externo_e_erros_tipados_cli_error_013: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-013: struct field is initialized more than once',10
option_result_null_externo_e_erros_tipados_cli_error_013_end:
option_result_null_externo_e_erros_tipados_cli_error_014: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-014: struct or Tuple arity does not match its bounded declaration',10
option_result_null_externo_e_erros_tipados_cli_error_014_end:
option_result_null_externo_e_erros_tipados_cli_error_015: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-015: composite field value has the wrong type',10
option_result_null_externo_e_erros_tipados_cli_error_015_end:
option_result_null_externo_e_erros_tipados_cli_error_016: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-016: struct literal names an unknown field',10
option_result_null_externo_e_erros_tipados_cli_error_016_end:
option_result_null_externo_e_erros_tipados_cli_error_017: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-017: invalid bounded struct or Tuple syntax',10
option_result_null_externo_e_erros_tipados_cli_error_017_end:
option_result_null_externo_e_erros_tipados_cli_error_004: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-004: Array length must be a compile-time Int in 0..256',10
option_result_null_externo_e_erros_tipados_cli_error_004_end:
option_result_null_externo_e_erros_tipados_cli_error_006: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-006: Range step, direction or checked length is invalid',10
option_result_null_externo_e_erros_tipados_cli_error_006_end:
option_result_null_externo_e_erros_tipados_cli_error_007: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-007: Slice view is released, stale or has an invalid bounded layout',10
option_result_null_externo_e_erros_tipados_cli_error_007_end:
option_result_null_externo_e_erros_tipados_cli_error_018: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-018: Array literal arity does not match its declared length',10
option_result_null_externo_e_erros_tipados_cli_error_018_end:
option_result_null_externo_e_erros_tipados_cli_error_019: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-019: Array or Range value has the wrong bounded scalar type',10
option_result_null_externo_e_erros_tipados_cli_error_019_end:
option_result_null_externo_e_erros_tipados_cli_error_020: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-020: Array index must be a compile-time Int in this bounded profile',10
option_result_null_externo_e_erros_tipados_cli_error_020_end:
option_result_null_externo_e_erros_tipados_cli_error_021: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-021: invalid bounded Array or Range syntax',10
option_result_null_externo_e_erros_tipados_cli_error_021_end:
option_result_null_externo_e_erros_tipados_cli_error_022: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-022: live Slice view blocks owner mutation',10
option_result_null_externo_e_erros_tipados_cli_error_022_end:
option_result_null_externo_e_erros_tipados_cli_error_023: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-023: borrowed Slice view cannot escape its lexical owner scope',10
option_result_null_externo_e_erros_tipados_cli_error_023_end:
option_result_null_externo_e_erros_tipados_cli_error_024: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-024: Slice operation is outside the bounded F04 surface',10
option_result_null_externo_e_erros_tipados_cli_error_024_end:
option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64_native_vertical: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-INTERNAL: composite semantic or lowering proof failed',10
option_result_null_externo_e_erros_tipados_cli_error_internal_end_driver_cli_linux_x86_64_native_vertical:
cli_error_unknown_container: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-UNKNOWN-CONTAINER: expected Option<T> or Result<T,E>',10
cli_error_unknown_container_end:
cli_error_type_arity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-TYPE-ARITY: Option requires one type and Result requires two types',10
cli_error_type_arity_end:
cli_error_payload_unavailable: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-PAYLOAD-TYPE-UNAVAILABLE: payload type is outside Bool, Int, Float or Char',10
cli_error_payload_unavailable_end:
cli_error_variant_mismatch: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-VARIANT-MISMATCH: variant does not belong to the declared container',10
cli_error_variant_mismatch_end:
cli_error_variant_arity: db 'NEBO-option_result_null_externo_e_erros_tipados-OPTION-RESULT-VARIANT-ARITY: Some, Ok and Err take one value; None takes none',10
cli_error_variant_arity_end:
cli_error_observer_unknown: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-OBSERVER-UNKNOWN: unknown Option/Result observer',10
cli_error_observer_unknown_end:
cli_error_observer_domain: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-OBSERVER-WRONG-DOMAIN: observer is not valid for the receiver container',10
cli_error_observer_domain_end:
cli_error_observer_arity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-OBSERVER-ARITY: predicate observer takes no arguments',10
cli_error_observer_arity_end:
cli_error_unwrap_arity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-UNWRAP-OR-ARITY: unwrapOr requires one fallback value',10
cli_error_unwrap_arity_end:
cli_error_null: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-NULL-SOURCE-FORBIDDEN: null is not a Nebo source value',10
cli_error_null_end:
cli_error_propagation: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PROPAGATION-DEFERRED: propagation syntax is deferred',10
cli_error_propagation_end:
cli_error_try: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-TRY-CATCH-DEFERRED: try/catch is deferred',10
cli_error_try_end:
cli_error_fatal: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-FATAL-UNWRAP-DEFERRED: fatal unwrap is not available',10
cli_error_fatal_end:
cli_error_match: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-PATTERN-MATCH-DEFERRED: pattern matching is deferred',10
cli_error_match_end:
option_result_null_externo_e_erros_tipados_cli_error_alias: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-ALIAS-FORBIDDEN: use canonical Option, Result, Some, None, Ok and Err',10
option_result_null_externo_e_erros_tipados_cli_error_alias_end:
cli_error_void_payload: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-VOID-PAYLOAD-FORBIDDEN: Void cannot be a payload type',10
cli_error_void_payload_end:
cli_error_generics: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-GENERAL-GENERICS-DEFERRED: general generics and ADTs are deferred',10
cli_error_generics_end:
cli_error_payload_mismatch: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-PAYLOAD-TYPE-MISMATCH: variant payload type must exactly match its structural type',10
cli_error_payload_mismatch_end:
cli_error_context: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-CONTEXT-REQUIRED: variant requires complete Option or Result type context',10
cli_error_context_end:
option_result_null_externo_e_erros_tipados_cli_error_fallback: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-FALLBACK-TYPE-MISMATCH: unwrapOr fallback must exactly match the success type',10
option_result_null_externo_e_erros_tipados_cli_error_fallback_end:
option_result_null_externo_e_erros_tipados_cli_error_receiver: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-RECEIVER-TYPE-MISMATCH: observer receiver must be an Option or Result binding',10
option_result_null_externo_e_erros_tipados_cli_error_receiver_end:
cli_error_span: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-SEMANTIC-SPAN-INVARIANT: invalid semantic source span',10
cli_error_span_end:
cli_error_unknown_binding: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-UNKNOWN-BINDING: receiver binding is not defined',10
cli_error_unknown_binding_end:
cli_error_duplicate_binding: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-DUPLICATE-BINDING: binding name is already defined',10
cli_error_duplicate_binding_end:
option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-OPTION-RESULT-INTERNAL: internal Option/Result vertical contract failure',10
option_result_null_externo_e_erros_tipados_cli_error_internal_end_driver_cli_linux_x86_64:

cli_error_gen_constraint: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-008: generic type argument does not satisfy the declared constraint',10
cli_error_gen_constraint_end:
cli_error_gen_budget: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-009: generic declaration exceeds 32 deterministic AOT instances',10
cli_error_gen_budget_end:
cli_error_gen_collision: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-010: generic instance key or canonical mangled symbol collision',10
cli_error_gen_collision_end:
cli_error_gen_recursive: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-025: recursive generic expansion is outside the bounded AOT profile',10
cli_error_gen_recursive_end:
cli_error_gen_syntax: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-026: invalid bounded generic function or type syntax',10
cli_error_gen_syntax_end:
cli_error_gen_type: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-027: generic use has an unsupported or mismatched concrete type',10
cli_error_gen_type_end:
cli_error_gen_internal: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-028: generic semantic lowering or native plan invariant failed',10
cli_error_gen_internal_end:

cli_error_nom_identity: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-011: alias newtype or nominal identity conflict',10
cli_error_nom_identity_end:
cli_error_nom_abi: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-012: explicit discriminant unversioned ABI reflection or type erasure is unavailable',10
cli_error_nom_abi_end:
cli_error_nom_syntax: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-029: invalid bounded alias newtype or enum syntax',10
cli_error_nom_syntax_end:
cli_error_nom_variant: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-030: enum variant is duplicate unknown or outside the two-to-eight bound',10
cli_error_nom_variant_end:
cli_error_nom_payload: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-031: nominal or enum payload type does not match its declaration',10
cli_error_nom_payload_end:
cli_error_nom_internal: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-032: nominal type layout lowering or native plan invariant failed',10
cli_error_nom_internal_end:

cli_error_buffer_capacity_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-020: Buffer capacity must be an Int literal',10
cli_error_buffer_capacity_type_end:
cli_error_buffer_capacity_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-021: dynamic Buffer capacity is deferred',10
cli_error_buffer_capacity_dynamic_end:
cli_error_buffer_capacity_unsupported: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-022: bounded Buffer capacity must be exactly 4',10
cli_error_buffer_capacity_unsupported_end:
cli_error_buffer_length_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-023: Buffer length must be an Int literal',10
cli_error_buffer_length_type_end:
cli_error_buffer_length_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-024: dynamic Buffer length is deferred',10
cli_error_buffer_length_dynamic_end:
cli_error_buffer_length_range: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-025: bounded Buffer length must be in 0 through 4',10
cli_error_buffer_length_range_end:
cli_error_buffer_byte_below: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-026: Buffer byte must be at least 0',10
cli_error_buffer_byte_below_end:
cli_error_buffer_byte_above: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-027: Buffer byte must be at most 255',10
cli_error_buffer_byte_above_end:
cli_error_buffer_index_type: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-028: Buffer index must be an Int literal',10
cli_error_buffer_index_type_end:
cli_error_buffer_index_dynamic: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-029: dynamic Buffer index is deferred',10
cli_error_buffer_index_dynamic_end:
cli_error_buffer_read_bounds: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-030: Buffer read index is outside logical length',10
cli_error_buffer_read_bounds_end:
cli_error_buffer_write_bounds: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-031: Buffer write index is outside logical length',10
cli_error_buffer_write_bounds_end:
cli_error_buffer_full: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-032: Buffer is full',10
cli_error_buffer_full_end:
cli_error_buffer_receiver: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-033: Buffer method requires a unique Buffer receiver',10
cli_error_buffer_receiver_end:
cli_error_buffer_arity: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-034: Buffer method received the wrong number of arguments',10
cli_error_buffer_arity_end:
cli_error_buffer_alias: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-035: Buffer mutation requires a unique local owner',10
cli_error_buffer_alias_end:
cli_error_buffer_reserve: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-036: Buffer reserve requires a future allocator profile',10
cli_error_buffer_reserve_end:
cli_error_buffer_growth: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-037: bounded Buffer growth is forbidden',10
cli_error_buffer_growth_end:
cli_error_buffer_extend: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-038: Buffer extend is deferred to a later bounded phase',10
cli_error_buffer_extend_end:
cli_error_buffer_escape: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-040: bounded Buffer cannot escape its local owner',10
cli_error_buffer_escape_end:
cli_error_buffer_copy_move: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-041: bounded Buffer cannot be copied or moved',10
cli_error_buffer_copy_move_end:
cli_error_buffer_transport: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-042: Buffer parameter and return transport is deferred',10
cli_error_buffer_transport_end:
cli_error_buffer_freeze_length: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-043: bounded Buffer freeze supports lengths 0 1 and 4',10
cli_error_buffer_freeze_length_end:
cli_error_buffer_slice_bounds: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-045: bounded Slice range or index is outside owner bounds',10
cli_error_buffer_slice_bounds_end:
cli_error_buffer_slice_escape: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-046: bounded Slice cannot escape its lexical owner',10
cli_error_buffer_slice_escape_end:
cli_error_buffer_slice_mutation: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-047: Buffer mutation conflicts with a live Slice view',10
cli_error_buffer_slice_mutation_end:
cli_error_buffer_slice_stale: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-048: bounded Slice view is stale or released',10
cli_error_buffer_slice_stale_end:
cli_error_buffer_slice_owner: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-049: bounded Slice requires a Buffer Bytes or Array owner',10
cli_error_buffer_slice_owner_end:
cli_error_buffer_slice_arity: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-050: bounded Slice method received the wrong number of arguments',10
cli_error_buffer_slice_arity_end:
cli_error_buffer_internal: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-099: bounded Buffer semantic lowering or native plan invariant failed',10
cli_error_buffer_internal_end:

cli_error_expected: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-EXPECTED-TYPE-PARAMETER: generic declaration requires T',10
cli_error_expected_end:
generics_constraints_overload_e_dispatch_cli_error_arity: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-TYPE-PARAMETER-ARITY: first profile requires exactly one type parameter',10
generics_constraints_overload_e_dispatch_cli_error_arity_end:
generics_constraints_overload_e_dispatch_cli_error_duplicate: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-DUPLICATE-TYPE-PARAMETER: type parameter T is duplicated',10
generics_constraints_overload_e_dispatch_cli_error_duplicate_end:
cli_error_bound_expected: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-BOUND-EXPECTED: type parameter T requires Scalar',10
cli_error_bound_expected_end:
cli_error_bound_unknown: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-BOUND-UNKNOWN: only Scalar is available in this profile',10
cli_error_bound_unknown_end:
cli_error_bound: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-BOUND-NOT-SATISFIED: receiver must be Bool, Int, Float or Char',10
cli_error_bound_end:
generics_constraints_overload_e_dispatch_cli_error_receiver: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-RECEIVER-TYPE-PARAMETER-REQUIRED: generic receiver must have type T',10
generics_constraints_overload_e_dispatch_cli_error_receiver_end:
cli_error_return: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-RETURN-TYPE-PARAMETER-REQUIRED: generic identity must return T',10
cli_error_return_end:
cli_error_positionals: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-POSITIONAL-PARAMETERS-DEFERRED: generic positional parameters are deferred',10
cli_error_positionals_end:
cli_error_explicit: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-EXPLICIT-TYPE-ARGUMENTS-DEFERRED: explicit type arguments are deferred',10
cli_error_explicit_end:
generics_constraints_overload_e_dispatch_cli_error_type: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-TYPE-DEFERRED: generic aggregate types are deferred to structs_enums_variants_e_tipos_do_programador',10
generics_constraints_overload_e_dispatch_cli_error_type_end:
generics_constraints_overload_e_dispatch_cli_error_alias: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-ALIAS-FORBIDDEN: use generic, T, Scalar and identity',10
generics_constraints_overload_e_dispatch_cli_error_alias_end:
cli_error_no_match: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-OVERLOAD-NO-MATCH: no exact concrete or generic candidate matches',10
cli_error_no_match_end:
cli_error_ambiguous: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-OVERLOAD-AMBIGUOUS: multiple viable same-tier candidates',10
cli_error_ambiguous_end:
cli_error_sharing: db 'NEBO-GENERICS-CONSTRAINTS-OVERLOAD-E-DISPATCH-GENERIC-CODE-SHARING-DEFERRED: runtime dictionaries and code sharing are deferred',10
cli_error_sharing_end:

tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_unknown: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-API-UNKNOWN: unknown domain-refinement API',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_unknown_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_alias: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-ALIAS-FORBIDDEN: use PositiveInt and toPositiveInt',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_alias_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_receiver: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-RECEIVER-MUST-BE-INT: toPositiveInt requires an Int receiver',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_receiver_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_arguments: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-ARGUMENTS-NOT-ALLOWED: this domain operation takes no arguments',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_arguments_end:
cli_error_literal: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-LITERAL-RECEIVER-REQUIRED: toPositiveInt requires an Int literal in this profile',10
cli_error_literal_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_fallback: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-FALLBACK-REQUIRED: unwrapOr requires one positive Int literal',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_fallback_end:
cli_error_fallback_positive: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-FALLBACK-MUST-BE-POSITIVE-LITERAL: unwrapOr fallback must be a positive Int literal',10
cli_error_fallback_positive_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_constructor: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-CONSTRUCTOR-FORBIDDEN: PositiveInt values require validated conversion',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_constructor_end:
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_deferred: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-FAMILY-DEFERRED: this semantic-domain family is deferred',10
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_deferred_end:
cli_error_dynamic: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-DYNAMIC-REFINEMENT-DEFERRED: dynamic refinement is deferred',10
cli_error_dynamic_end:
cli_error_observer: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-OBSERVER-WRONG-DOMAIN: observer requires Result<PositiveInt,Int>',10
cli_error_observer_end:
cli_error_contract: db 'NEBO-TIPOS-SEMANTICOS-REFINAMENTOS-UNIDADES-E-OPAQUE-TYPES-DOMAIN-CONTRACT-INVARIANT: domain-refinement contract invariant failed',10
cli_error_contract_end:

cli_error_expected_type: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-EXPECTED-TYPE-NAME: programmer-defined type requires one nominal type name',10
cli_error_expected_type_end:
cli_error_duplicate_type: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DUPLICATE-TYPE: nominal type name is already declared',10
cli_error_duplicate_type_end:
cli_error_expected_field: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-EXPECTED-FIELD-NAME: struct field requires one receiver-first name',10
cli_error_expected_field_end:
cli_error_duplicate_field: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DUPLICATE-FIELD: field is declared or initialized more than once',10
cli_error_duplicate_field_end:
cli_error_missing_field: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-MISSING-FIELD: struct literal must initialize every declared field',10
cli_error_missing_field_end:
cli_error_unknown_field: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-UNKNOWN-FIELD: field is not declared by this nominal type',10
cli_error_unknown_field_end:
cli_error_field_type: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-FIELD-TYPE-MISMATCH: field value must have its exact declared type',10
cli_error_field_type_end:
cli_error_duplicate_variant: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DUPLICATE-VARIANT: enum variant name is duplicated',10
cli_error_duplicate_variant_end:
cli_error_payload_type: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-PAYLOAD-TYPE-MISMATCH: variant payload must have its exact declared type',10
cli_error_payload_type_end:
cli_error_recursive: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-RECURSIVE-BY-VALUE: recursive by-value programmer type is unavailable',10
cli_error_recursive_end:
cli_error_empty: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-EMPTY-DECLARATION: programmer type declaration must not be empty',10
cli_error_empty_end:
structs_enums_variants_e_tipos_do_programador_cli_error_deferred: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DEFERRED-FEATURE: construct is outside the bounded structs_enums_variants_e_tipos_do_programador programmer-type profile',10
structs_enums_variants_e_tipos_do_programador_cli_error_deferred_end:
colecoes_primitivas_cli_error_arity: db 'NEBO-COLECOES-PRIMITIVAS-ARRAY-ARITY: Array<Int,4> requires exactly four elements',10
colecoes_primitivas_cli_error_arity_end:
colecoes_primitivas_cli_error_type: db 'NEBO-COLECOES-PRIMITIVAS-ELEMENT-TYPE-MISMATCH: Array<Int,4> elements must be Int',10
colecoes_primitivas_cli_error_type_end:
colecoes_primitivas_cli_error_bounds: db 'NEBO-COLECOES-PRIMITIVAS-INDEX-OUT-OF-BOUNDS: Array<Int,4> index is out of bounds',10
colecoes_primitivas_cli_error_bounds_end:
colecoes_primitivas_cli_error_constant: db 'NEBO-COLECOES-PRIMITIVAS-CONSTANT-INDEX-REQUIRED: bounded Array index must be constant',10
colecoes_primitivas_cli_error_constant_end:
cli_error_mutation: db 'NEBO-COLECOES-PRIMITIVAS-MUTATION-DEFERRED: Array mutation is deferred',10
cli_error_mutation_end:
cli_error_list: db 'NEBO-COLECOES-PRIMITIVAS-LIST-DEFERRED: List and general collections are deferred',10
cli_error_list_end:
cli_error_dict: db 'NEBO-COLECOES-PRIMITIVAS-DICT-DEFERRED: Dict is deferred',10
cli_error_dict_end:
cli_error_capacity: db 'NEBO-COLECOES-PRIMITIVAS-CAPACITY-DEFERRED: capacity and allocation policies are deferred',10
cli_error_capacity_end:

vetores_matrizes_tensores_e_computacao_cientifica_cli_error_arity: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-ARITY: Vector<Int> requires exactly four elements',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_arity_end:
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_type: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-ELEMENT-TYPE: Vector<Int> elements must be Int',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_type_end:
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_bounds: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-INDEX-OUT-OF-BOUNDS: Vector<Int> index is out of bounds',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_bounds_end:
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_constant: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-CONSTANT-INDEX-REQUIRED: bounded Vector index must be constant',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_constant_end:
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_dtype: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-DTYPE-DEFERRED: only dense CPU Vector<Int> is available',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_dtype_end:
cli_error_matrix: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-MATRIX-DEFERRED: Matrix is deferred',10
cli_error_matrix_end:
cli_error_tensor: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-TENSOR-DEFERRED: Tensor is deferred',10
cli_error_tensor_end:
cli_error_device: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-DEVICE-DEFERRED: device transfer is deferred',10
cli_error_device_end:
cli_error_sparse: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-SPARSE-DEFERRED: sparse Vector storage is deferred',10
cli_error_sparse_end:
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_overflow: db 'NEBO-VETORES-MATRIZES-TENSORES-E-COMPUTACAO-CIENTIFICA-VECTOR-OVERFLOW: Vector arithmetic overflows Int',10
vetores_matrizes_tensores_e_computacao_cientifica_cli_error_overflow_end:

column_row_table_e_dataset_cli_error_arity: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-ARITY: Column<Int> requires exactly four elements',10
column_row_table_e_dataset_cli_error_arity_end:
column_row_table_e_dataset_cli_error_type: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-ELEMENT-TYPE: Column<Int> elements must be Int',10
column_row_table_e_dataset_cli_error_type_end:
column_row_table_e_dataset_cli_error_bounds: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-INDEX-OUT-OF-BOUNDS: Column<Int> index is out of bounds',10
column_row_table_e_dataset_cli_error_bounds_end:
column_row_table_e_dataset_cli_error_constant: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-CONSTANT-INDEX-REQUIRED: bounded Column index must be constant',10
column_row_table_e_dataset_cli_error_constant_end:
column_row_table_e_dataset_cli_error_dtype: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-DTYPE-DEFERRED: only Column<Int> is available',10
column_row_table_e_dataset_cli_error_dtype_end:
cli_error_table: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-TABLE-DEFERRED: Table is deferred',10
cli_error_table_end:
cli_error_dataset: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-DATASET-DEFERRED: Dataset is deferred',10
cli_error_dataset_end:
cli_error_missing: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-MISSING-DEFERRED: missing values are deferred',10
cli_error_missing_end:
cli_error_join: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-JOIN-DEFERRED: joins are deferred',10
cli_error_join_end:
column_row_table_e_dataset_cli_error_overflow: db 'NEBO-COLUMN-ROW-TABLE-E-DATASET-COLUMN-OVERFLOW: Column arithmetic overflows Int',10
column_row_table_e_dataset_cli_error_overflow_end:
stream_event_e_processamento_continuo_cli_error_bounded: db 'NEBO-STREAM-EVENT-E-PROCESSAMENTO-CONTINUO-BOUNDED-PROFILE: source is outside the bounded stream_event_e_processamento_continuo profile',10
stream_event_e_processamento_continuo_cli_error_bounded_end:
tree_graph_node_e_edge_cli_error_bounded: db 'NEBO-TREE-GRAPH-NODE-E-EDGE-BOUNDED-PROFILE: source is outside the bounded tree_graph_node_e_edge profile',10
tree_graph_node_e_edge_cli_error_bounded_end:
funcoes_lambdas_callbacks_e_referencias_cli_error_bounded: db 'NEBO-FUNCOES-LAMBDAS-CALLBACKS-E-REFERENCIAS-BOUNDED-PROFILE: source is outside the bounded funcoes_lambdas_callbacks_e_referencias profile',10
funcoes_lambdas_callbacks_e_referencias_cli_error_bounded_end:
call_e_comportamentos_de_chamada_cli_error_bounded: db 'NEBO-CALL-E-COMPORTAMENTOS-DE-CHAMADA-BOUNDED-PROFILE: source is outside the bounded call_e_comportamentos_de_chamada profile',10
call_e_comportamentos_de_chamada_cli_error_bounded_end:
operadores_de_fluxo_e_branching_pipelines_cli_error_bounded: db 'NEBO-OPERADORES-DE-FLUXO-E-BRANCHING-PIPELINES-BOUNDED-PROFILE: source is outside the bounded operadores_de_fluxo_e_branching_pipelines profile',10
operadores_de_fluxo_e_branching_pipelines_cli_error_bounded_end:
controlo_de_fluxo_estruturado_cli_error_bounded: db 'NEBO-CONTROLO-DE-FLUXO-ESTRUTURADO-BOUNDED-PROFILE: source is outside the bounded controlo_de_fluxo_estruturado profile',10
controlo_de_fluxo_estruturado_cli_error_bounded_end:
pattern_matching_e_destructuring_cli_error_bounded: db 'NEBO-PATTERN-MATCHING-E-DESTRUCTURING-BOUNDED-PROFILE: source is outside the bounded pattern_matching_e_destructuring profile',10
pattern_matching_e_destructuring_cli_error_bounded_end:
async_await_e_concorrencia_estruturada_cli_error_bounded: db 'NEBO-ASYNC-AWAIT-E-CONCORRENCIA-ESTRUTURADA-BOUNDED-PROFILE: source is outside the bounded async_await_e_concorrencia_estruturada profile',10
async_await_e_concorrencia_estruturada_cli_error_bounded_end:
effects_capabilities_e_politicas_cli_error_lex: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-LEX-001: unknown or non-canonical Policy atom or literal',10
effects_capabilities_e_politicas_cli_error_lex_end:
effects_capabilities_e_politicas_cli_error_parse: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-PARSE-002: malformed or non-canonical Policy clause order',10
effects_capabilities_e_politicas_cli_error_parse_end:
effects_capabilities_e_politicas_cli_error_type: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-TYPE-003: Policy value or effect constraint is invalid',10
effects_capabilities_e_politicas_cli_error_type_end:
effects_capabilities_e_politicas_cli_error_codegen: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-CODEGEN-004: Policy proof cannot be lowered for this target or front',10
effects_capabilities_e_politicas_cli_error_codegen_end:
effects_capabilities_e_politicas_cli_error_runtime: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-RUNTIME-005: Policy evaluation budget is exceeded',10
effects_capabilities_e_politicas_cli_error_runtime_end:
effects_capabilities_e_politicas_cli_error_security: db 'NEBO-EFFECTS-CAPABILITIES-E-POLITICAS-SECURITY-006: Policy capability allow deny trust or audit check failed',10
effects_capabilities_e_politicas_cli_error_security_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_lex: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-LEX-001: unknown or non-canonical privacy wrapper, type or label',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_lex_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_parse: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PARSE-002: malformed or non-canonical privacy proof syntax',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_parse_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_type: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-TYPE-003: privacy wrapper or redaction label set is invalid',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_type_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_codegen: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-CODEGEN-004: privacy proof cannot be lowered for this target or front',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_codegen_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_runtime: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-RUNTIME-005: privacy retention or runtime invariant failed',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_runtime_end:
privacidade_dados_sensiveis_e_zero_trust_cli_error_security: db 'NEBO-PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-SECURITY-006: privacy policy trust purpose redaction or sink check failed',10
privacidade_dados_sensiveis_e_zero_trust_cli_error_security_end:
quality_confidence_e_lineage_cli_error_lex: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-LEX-001: unknown or non-canonical quality confidence or lineage name',10
quality_confidence_e_lineage_cli_error_lex_end:
quality_confidence_e_lineage_cli_error_parse: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-PARSE-002: malformed quality confidence or lineage proof syntax',10
quality_confidence_e_lineage_cli_error_parse_end:
quality_confidence_e_lineage_cli_error_type: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-TYPE-003: quality confidence score or lineage identity is invalid',10
quality_confidence_e_lineage_cli_error_type_end:
quality_confidence_e_lineage_cli_error_codegen: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-CODEGEN-004: quality confidence lineage proof is unavailable before QUALITY-CONFIDENCE-E-LINEAGE-PF005',10
quality_confidence_e_lineage_cli_error_codegen_end:
quality_confidence_e_lineage_cli_error_runtime: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-RUNTIME-005: quality confidence or lineage runtime invariant failed',10
quality_confidence_e_lineage_cli_error_runtime_end:
quality_confidence_e_lineage_cli_error_security: db 'NEBO-QUALITY-CONFIDENCE-E-LINEAGE-SECURITY-006: quality confidence privacy or lineage authority check failed',10
quality_confidence_e_lineage_cli_error_security_end:
memoria_ownership_lifetimes_e_recursos_cli_error_lex: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-LEX-001: unknown or non-canonical ownership lifetime or action name',10
memoria_ownership_lifetimes_e_recursos_cli_error_lex_end:
memoria_ownership_lifetimes_e_recursos_cli_error_parse: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PARSE-002: malformed ownership lifetime or resource action syntax',10
memoria_ownership_lifetimes_e_recursos_cli_error_parse_end:
memoria_ownership_lifetimes_e_recursos_cli_error_type: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-TYPE-003: resource owner lifetime or borrower identity is invalid',10
memoria_ownership_lifetimes_e_recursos_cli_error_type_end:
memoria_ownership_lifetimes_e_recursos_cli_error_codegen: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-CODEGEN-004: ownership lifetime resource action is unavailable before MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-PF005',10
memoria_ownership_lifetimes_e_recursos_cli_error_codegen_end:
memoria_ownership_lifetimes_e_recursos_cli_error_runtime: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-RUNTIME-005: ownership lifetime or exact-cleanup runtime invariant failed',10
memoria_ownership_lifetimes_e_recursos_cli_error_runtime_end:
memoria_ownership_lifetimes_e_recursos_cli_error_security: db 'NEBO-MEMORIA-OWNERSHIP-LIFETIMES-E-RECURSOS-SECURITY-006: borrow exclusivity region token or use-after-move check failed',10
memoria_ownership_lifetimes_e_recursos_cli_error_security_end:
imports_modulos_namespaces_e_api_publica_cli_error_lex: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-LEX-001: unknown or non-canonical module import or visibility name',10
imports_modulos_namespaces_e_api_publica_cli_error_lex_end:
imports_modulos_namespaces_e_api_publica_cli_error_parse: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PARSE-002: malformed module package import symbol or visibility syntax',10
imports_modulos_namespaces_e_api_publica_cli_error_parse_end:
imports_modulos_namespaces_e_api_publica_cli_error_type: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-TYPE-003: module package import or symbol identity is invalid',10
imports_modulos_namespaces_e_api_publica_cli_error_type_end:
imports_modulos_namespaces_e_api_publica_cli_error_codegen: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-CODEGEN-004: module import resolution is unavailable before IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-PF005',10
imports_modulos_namespaces_e_api_publica_cli_error_codegen_end:
imports_modulos_namespaces_e_api_publica_cli_error_runtime: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-RUNTIME-005: module initialization or import graph runtime invariant failed',10
imports_modulos_namespaces_e_api_publica_cli_error_runtime_end:
imports_modulos_namespaces_e_api_publica_cli_error_security: db 'NEBO-IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-SECURITY-006: module cycle visibility boundary or graph integrity check failed',10
imports_modulos_namespaces_e_api_publica_cli_error_security_end:
packages_registry_lockfile_e_supply_chain_cli_error_lex: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-LEX-001: unknown or non-canonical package manifest or policy name',10
packages_registry_lockfile_e_supply_chain_cli_error_lex_end:
packages_registry_lockfile_e_supply_chain_cli_error_parse: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PARSE-002: malformed package dependency version digest or policy syntax',10
packages_registry_lockfile_e_supply_chain_cli_error_parse_end:
packages_registry_lockfile_e_supply_chain_cli_error_type: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-TYPE-003: package dependency version or digest identity is invalid',10
packages_registry_lockfile_e_supply_chain_cli_error_type_end:
packages_registry_lockfile_e_supply_chain_cli_error_codegen: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-CODEGEN-004: package lock resolution is unavailable before PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-PF005',10
packages_registry_lockfile_e_supply_chain_cli_error_codegen_end:
packages_registry_lockfile_e_supply_chain_cli_error_runtime: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-RUNTIME-005: package lock resolution or replay runtime invariant failed',10
packages_registry_lockfile_e_supply_chain_cli_error_runtime_end:
packages_registry_lockfile_e_supply_chain_cli_error_security: db 'NEBO-PACKAGES-REGISTRY-LOCKFILE-E-SUPPLY-CHAIN-SECURITY-006: package digest policy or lock integrity check failed',10
packages_registry_lockfile_e_supply_chain_cli_error_security_end:
biblioteca_padrao_por_dominios_cli_error_lex: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-LEX-001: unknown or non-canonical std.math namespace or operation name',10
biblioteca_padrao_por_dominios_cli_error_lex_end:
biblioteca_padrao_por_dominios_cli_error_parse: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-PARSE-002: malformed std.math call arguments punctuation or terminator',10
biblioteca_padrao_por_dominios_cli_error_parse_end:
biblioteca_padrao_por_dominios_cli_error_type: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-TYPE-003: std.math signed Int operand or clamp domain is invalid',10
biblioteca_padrao_por_dominios_cli_error_type_end:
biblioteca_padrao_por_dominios_cli_error_codegen: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-CODEGEN-004: std.math code generation failed',10
biblioteca_padrao_por_dominios_cli_error_codegen_end:
biblioteca_padrao_por_dominios_cli_error_runtime: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-RUNTIME-005: std.math evaluation or signed domain invariant failed',10
biblioteca_padrao_por_dominios_cli_error_runtime_end:
biblioteca_padrao_por_dominios_cli_error_security: db 'NEBO-BIBLIOTECA-PADRAO-POR-DOMINIOS-SECURITY-006: std.math request integrity or bounded purity check failed',10
biblioteca_padrao_por_dominios_cli_error_security_end:
filesystem_paths_e_formatos_cli_error_lex: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-LEX-001: unknown or non-canonical path namespace or query name',10
filesystem_paths_e_formatos_cli_error_lex_end:
filesystem_paths_e_formatos_cli_error_parse: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-PARSE-002: malformed lexical path query punctuation quotes or terminator',10
filesystem_paths_e_formatos_cli_error_parse_end:
filesystem_paths_e_formatos_cli_error_type: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-TYPE-003: lexical path text is empty non-canonical or outside the bounded profile',10
filesystem_paths_e_formatos_cli_error_type_end:
filesystem_paths_e_formatos_cli_error_codegen: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-CODEGEN-004: lexical path code generation failed',10
filesystem_paths_e_formatos_cli_error_codegen_end:
filesystem_paths_e_formatos_cli_error_runtime: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-RUNTIME-005: lexical path runtime invariant failed',10
filesystem_paths_e_formatos_cli_error_runtime_end:
filesystem_paths_e_formatos_cli_error_security: db 'NEBO-FILESYSTEM-PATHS-E-FORMATOS-SECURITY-006: path traversal or authenticated lexical summary integrity check failed',10
filesystem_paths_e_formatos_cli_error_security_end:
rede_e_protocolos_cli_error_lex: db 'NEBO-REDE-E-PROTOCOLOS-LEX-001: unknown or non-canonical net namespace or port operation name',10
rede_e_protocolos_cli_error_lex_end:
rede_e_protocolos_cli_error_parse: db 'NEBO-REDE-E-PROTOCOLOS-PARSE-002: malformed decimal network-port punctuation quotes or terminator',10
rede_e_protocolos_cli_error_parse_end:
rede_e_protocolos_cli_error_type: db 'NEBO-REDE-E-PROTOCOLOS-TYPE-003: decimal network port is empty invalid or outside 1 through 65535',10
rede_e_protocolos_cli_error_type_end:
rede_e_protocolos_cli_error_codegen: db 'NEBO-REDE-E-PROTOCOLOS-CODEGEN-004: network-port code generation failed',10
rede_e_protocolos_cli_error_codegen_end:
rede_e_protocolos_cli_error_runtime: db 'NEBO-REDE-E-PROTOCOLOS-RUNTIME-005: network-port runtime invariant failed',10
rede_e_protocolos_cli_error_runtime_end:
rede_e_protocolos_cli_error_security: db 'NEBO-REDE-E-PROTOCOLOS-SECURITY-006: ambiguous port spelling or authenticated summary integrity check failed',10
rede_e_protocolos_cli_error_security_end:
console_visual_dashboard_e_plots_cli_error_lex: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-LEX-001: unknown or non-canonical visual namespace or summary operation name',10
console_visual_dashboard_e_plots_cli_error_lex_end:
console_visual_dashboard_e_plots_cli_error_parse: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-PARSE-002: malformed visual summary punctuation argument or terminator',10
console_visual_dashboard_e_plots_cli_error_parse_end:
console_visual_dashboard_e_plots_cli_error_type: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-TYPE-003: visual summary value is not an integer from 0 through 255',10
console_visual_dashboard_e_plots_cli_error_type_end:
console_visual_dashboard_e_plots_cli_error_codegen: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-CODEGEN-004: visual summary code generation failed',10
console_visual_dashboard_e_plots_cli_error_codegen_end:
console_visual_dashboard_e_plots_cli_error_runtime: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-RUNTIME-005: visual summary runtime invariant failed',10
console_visual_dashboard_e_plots_cli_error_runtime_end:
console_visual_dashboard_e_plots_cli_error_security: db 'NEBO-CONSOLE-VISUAL-DASHBOARD-E-PLOTS-SECURITY-006: non-canonical integer spelling or authenticated summary integrity failed',10
console_visual_dashboard_e_plots_cli_error_security_end:

cli_name_const: db 'const'
cli_name_const_len equ $-cli_name_const
cli_name_mut: db 'mut'
cli_name_mut_len equ $-cli_name_mut
cli_name_policy: db 'Policy'
cli_name_policy_len equ $-cli_name_policy
cli_name_secret: db 'Secret'
cli_name_secret_len equ $-cli_name_secret
cli_name_personal_data: db 'PersonalData'
cli_name_personal_data_len equ $-cli_name_personal_data
cli_name_secret_value: db 'SecretValue'
cli_name_secret_value_len equ $-cli_name_secret_value
cli_name_private: db 'Private'
cli_name_private_len equ $-cli_name_private
cli_name_quality: db 'Quality'
cli_name_quality_len equ $-cli_name_quality
cli_name_quality_alias: db 'quality'
cli_name_quality_alias_len equ $-cli_name_quality_alias

cli_error_io: db 'neboc: I/O error',10
cli_error_io_end:
cli_error_toolchain: db 'neboc: toolchain error',10
cli_error_toolchain_end:
cli_error_internal: db 'neboc: internal compiler error',10
cli_error_internal_end:

arg_help: db '--help',0
arg_version: db '--version',0
arg_bench: db 'bench',0
arg_bench_numeric: db 'numeric',0
arg_probabilistic_report: db 'probabilistic-report',0
arg_firmware: db 'firmware',0
arg_firmware_build: db 'build',0
arg_firmware_test: db 'test',0
arg_firmware_board: db '--board',0
arg_firmware_simulator: db '--simulator',0
arg_reference_board: db 'NEBO_REFERENCE_BOARD_SIM_V1',0
arg_simulation_replay: db 'simulation-replay',0
arg_crypto_audit: db 'crypto-audit',0
arg_optimize_explain: db 'optimize-explain',0
arg_bootstrap: db 'bootstrap',0
arg_verify: db '--verify',0
arg_protocol: db 'protocol',0
arg_protocol_generate: db 'generate',0
arg_protocol_fuzz: db 'fuzz',0
arg_check: db 'check',0
arg_warnings: db 'warnings',0
arg_diagnostic_schema: db 'diagnostic-schema',0
arg_explain: db 'explain',0
arg_diagnostics: db 'diagnostics',0
arg_search: db '--search',0
arg_bug_report: db 'bug-report',0
arg_local: db '--local',0
arg_inspect: db '--inspect',0
arg_minimize_ice: db 'minimize-ice',0
arg_exit_codes: db 'exit-codes',0
arg_list: db '--list',0
arg_emit_asm: db 'emit-asm',0
arg_build: db 'build',0
arg_output: db '-o',0
arg_keep_temp: db '--keep-temp',0
arg_unit: db '--unit',0
arg_message_format: db '--message-format',0
arg_color: db '--color',0
arg_path_style: db '--path-style',0
arg_diagnostic_width: db '--diagnostic-width',0
arg_warnings_as_errors: db '--warnings-as-errors',0
arg_allow: db '--allow',0
arg_warn: db '--warn',0
arg_deny: db '--deny',0
arg_forbid: db '--forbid',0
arg_emit_build_events: db '--emit-build-events',0
arg_max_errors: db '--max-errors',0
arg_fail_fast: db '--fail-fast',0
arg_keep_going: db '--keep-going',0
arg_show_fixes: db '--show-fixes',0
arg_progress: db '--progress',0
arg_quiet: db '--quiet',0
arg_verbose: db '--verbose',0
arg_trace: db '--trace',0
arg_human: db 'human',0
arg_short: db 'short',0
arg_json: db 'json',0
arg_json_lines: db 'json-lines',0
arg_sarif: db 'sarif',0
arg_auto: db 'auto',0
arg_always: db 'always',0
arg_never: db 'never',0
arg_relative: db 'relative',0
arg_workspace: db 'workspace',0
arg_absolute: db 'absolute',0
arg_driver_component: db 'driver',0
arg_diagnostics_component: db 'diagnostics',0
arg_codegen_component: db 'codegen',0
warning_list:
 db 'warning-groups-v1:',10
 db '  unused default=warn maturity=stable',10
 db '  portability default=warn maturity=stable',10
 db '  performance default=allow maturity=stable',10
 db '  deprecated default=warn maturity=stable',10
 db '  experimental default=allow maturity=experimental',10
warning_list_end:

diagnostic_schema:
 db '{"schemaVersion":1,"format":"nebo-diagnostic","required":["schema","code","severity","category","phase","messageKey","primary"]}',10
diagnostic_schema_end:
cli_json_error:
 db '{"schema":1,"code":"NEBO-E0001","severity":1,"category":1,"phase":4,"messageKey":"source.validation.failed","primary":{"sourceId":1,"start":0,"end":0}}',10
cli_json_error_end:
cli_json_lex_error:
 db '{"schema":1,"code":"NEBO-E0001","severity":1,"category":1,"phase":3,"messageKey":"source.validation.failed","primary":{"sourceId":1,"start":0,"end":0}}',10
cli_json_lex_error_end:
cli_sarif_error:
 db '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"neboc"}},"results":[{"ruleId":"NEBO-E0001","level":"error","message":{"id":"source.validation.failed"}}]}]}',10
cli_sarif_error_end:
build_events_success:
 db '{"event":"phaseStarted","phase":1,"unit":"cli"}',10
 db '{"event":"phaseFinished","phase":1,"outcome":1,"diagnosticCount":0}',10
build_events_success_end:
build_events_failure:
 db '{"event":"phaseStarted","phase":1,"unit":"cli"}',10
 db '{"event":"diagnostic","diagnostic":{"schema":1,"code":"NEBO-E0001","severity":1,"messageKey":"source.validation.failed"}}',10
 db '{"event":"phaseFinished","phase":1,"outcome":2,"diagnosticCount":1}',10
build_events_failure_end:
cli_fix_preview:
 db 'fix-it[manualOnly]: preview only; inspect the primary diagnostic span',10
cli_fix_preview_end:
ice_invariant: db 'compiler.internal.invariant'
ice_invariant_len equ $-ice_invariant
ice_context: db 'private source context is intentionally redacted'
ice_context_len equ $-ice_context
ice_version: db 'neboc-',NEBO_VERSION_STRING
ice_version_len equ $-ice_version
ice_target: db 'x86_64-systemv-elf-linux'
ice_target_len equ $-ice_target
ice_suffix: db '.icebundle',0
ice_suffix_len equ $-ice_suffix-1
ice_newline: db 10
exit_code_registry:
 db '0 success',10
 db '1 source-error-or-warning-denied',10
 db '2 usage',10
 db '3 environment-or-io',10
 db '4 unsupported-target',10
 db '5 toolchain',10
 db '6 internal-compiler-error',10
exit_code_registry_end:
progress_summary: db 'progress phase=build total=1 completed=1 success=1 failed=0',10
progress_summary_end:
verbose_summary: db 'verbose: phase=build outcome=success',10
verbose_summary_end:
trace_prefix: db 'trace['
trace_prefix_end:
trace_suffix: db ']: build artifact committed',10
trace_suffix_end:

nasm_path: db '/usr/bin/nasm',0
nasm_path_len equ $-nasm_path-1
ld_path: db '/usr/bin/ld',0
ld_path_len equ $-ld_path-1

suffix_asm: db '.neboc.asm',0
suffix_asm_len equ $-suffix_asm-1
suffix_obj: db '.neboc.o',0
suffix_obj_len equ $-suffix_obj-1
runtime_relative: db '../obj/runtime_core.o',0
runtime_relative_len equ $-runtime_relative-1
runtime_default: db 'build/obj/runtime_core.o',0
runtime_default_len equ $-runtime_default-1

cli_runtime_trap_externs: db 'extern nebo_runtime_trap_overflow',10,'extern nebo_runtime_trap_division_by_zero',10,'extern nebo_runtime_numeric_safety_int_to_float',10,'extern nebo_runtime_numeric_safety_is_finite',10,'extern nebo_runtime_numeric_safety_is_nan',10,'extern nebo_runtime_numeric_safety_is_infinite',10,'extern nebo_runtime_numeric_safety_is_negative_zero',10,'extern nebo_runtime_textual_text_byte_length',10,'extern nebo_runtime_textual_text_codepoint_count',10,'extern nebo_runtime_textual_char_codepoint',10,'extern nebo_runtime_textual_bytes_empty',10,'extern nebo_runtime_textual_bytes_byte_length',10,'extern neboc_runtime_store_zero_payload',10,'extern neboc_runtime_store_integer',10,'extern neboc_runtime_store_float',10,'extern neboc_runtime_tag_test',10,'extern neboc_runtime_unwrap_integer',10,'extern neboc_runtime_unwrap_float',10,'extern nebo_runtime_contract_1',10,'extern nebo_runtime_contract_3',10,'extern nebo_runtime_console_publish_text',10,'extern nebo_runtime_console_publish_int',10,'extern nebo_runtime_console_publish_bool',10
cli_runtime_trap_externs_end:

section .bss align=16
console_visual_dashboard_e_plots_cli_frontend_diagnostic: resq 1
console_visual_dashboard_e_plots_cli_found: resq 1
console_visual_dashboard_e_plots_cli_parse_request: resb neboc_console_visual_dashboard_e_plots_PARSE_REQUEST_SIZE
console_visual_dashboard_e_plots_cli_syntax: resb neboc_console_visual_dashboard_e_plots_SYNTAX_SIZE
console_visual_dashboard_e_plots_cli_authority: resb neboc_console_visual_dashboard_e_plots_RECORD_SIZE
console_visual_dashboard_e_plots_cli_semantic: resb neboc_console_visual_dashboard_e_plots_SEM_SIZE
console_visual_dashboard_e_plots_cli_ir: resb neboc_console_visual_dashboard_e_plots_IR_SIZE
console_visual_dashboard_e_plots_cli_plan: resb neboc_console_visual_dashboard_e_plots_NATIVE_SIZE
console_visual_dashboard_e_plots_cli_runtime_state: resb neboc_console_visual_dashboard_e_plots_RUNTIME_SIZE
console_visual_dashboard_e_plots_cli_codegen_request: resb neboc_console_visual_dashboard_e_plots_CODEGEN_REQUEST_SIZE
rede_e_protocolos_cli_frontend_diagnostic: resq 1
rede_e_protocolos_cli_found: resq 1
rede_e_protocolos_cli_parse_request: resb neboc_rede_e_protocolos_PARSE_REQUEST_SIZE
rede_e_protocolos_cli_syntax: resb neboc_rede_e_protocolos_SYNTAX_SIZE
rede_e_protocolos_cli_authority: resb neboc_rede_e_protocolos_RECORD_SIZE
rede_e_protocolos_cli_semantic: resb neboc_rede_e_protocolos_SEM_SIZE
rede_e_protocolos_cli_ir: resb neboc_rede_e_protocolos_IR_SIZE
rede_e_protocolos_cli_plan: resb neboc_rede_e_protocolos_NATIVE_SIZE
rede_e_protocolos_cli_runtime_state: resb neboc_rede_e_protocolos_RUNTIME_SIZE
rede_e_protocolos_cli_codegen_request: resb neboc_rede_e_protocolos_CODEGEN_REQUEST_SIZE
filesystem_paths_e_formatos_cli_frontend_diagnostic: resq 1
filesystem_paths_e_formatos_cli_found: resq 1
filesystem_paths_e_formatos_cli_parse_request: resb neboc_filesystem_paths_e_formatos_PARSE_REQUEST_SIZE
filesystem_paths_e_formatos_cli_syntax: resb neboc_filesystem_paths_e_formatos_SYNTAX_SIZE
filesystem_paths_e_formatos_cli_authority: resb neboc_filesystem_paths_e_formatos_RECORD_SIZE
filesystem_paths_e_formatos_cli_semantic: resb neboc_filesystem_paths_e_formatos_SEM_SIZE
filesystem_paths_e_formatos_cli_ir: resb neboc_filesystem_paths_e_formatos_IR_SIZE
filesystem_paths_e_formatos_cli_plan: resb neboc_filesystem_paths_e_formatos_NATIVE_SIZE
filesystem_paths_e_formatos_cli_runtime_state: resb neboc_filesystem_paths_e_formatos_RUNTIME_SIZE
filesystem_paths_e_formatos_cli_codegen_request: resb neboc_filesystem_paths_e_formatos_CODEGEN_REQUEST_SIZE
biblioteca_padrao_por_dominios_cli_frontend_diagnostic: resq 1
biblioteca_padrao_por_dominios_cli_found: resq 1
biblioteca_padrao_por_dominios_cli_parse_request: resb neboc_biblioteca_padrao_por_dominios_PARSE_REQUEST_SIZE
biblioteca_padrao_por_dominios_cli_syntax: resb neboc_biblioteca_padrao_por_dominios_SYNTAX_SIZE
biblioteca_padrao_por_dominios_cli_authority: resb neboc_biblioteca_padrao_por_dominios_RECORD_SIZE
biblioteca_padrao_por_dominios_cli_semantic: resb neboc_biblioteca_padrao_por_dominios_SEM_SIZE
biblioteca_padrao_por_dominios_cli_ir: resb neboc_biblioteca_padrao_por_dominios_IR_SIZE
biblioteca_padrao_por_dominios_cli_plan: resb neboc_biblioteca_padrao_por_dominios_NATIVE_SIZE
biblioteca_padrao_por_dominios_cli_runtime_state: resb neboc_biblioteca_padrao_por_dominios_RUNTIME_SIZE
biblioteca_padrao_por_dominios_cli_codegen_request: resb neboc_biblioteca_padrao_por_dominios_CODEGEN_REQUEST_SIZE
packages_registry_lockfile_e_supply_chain_cli_frontend_diagnostic: resq 1
packages_registry_lockfile_e_supply_chain_cli_found: resq 1
packages_registry_lockfile_e_supply_chain_cli_parse_request: resb neboc_packages_registry_lockfile_e_supply_chain_PARSE_REQUEST_SIZE
packages_registry_lockfile_e_supply_chain_cli_syntax: resb neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SIZE
cli_lock: resb neboc_packages_registry_lockfile_e_supply_chain_RECORD_SIZE
packages_registry_lockfile_e_supply_chain_cli_semantic: resb neboc_packages_registry_lockfile_e_supply_chain_SEM_SIZE
packages_registry_lockfile_e_supply_chain_cli_ir: resb neboc_packages_registry_lockfile_e_supply_chain_IR_SIZE
packages_registry_lockfile_e_supply_chain_cli_plan: resb neboc_packages_registry_lockfile_e_supply_chain_NATIVE_SIZE
packages_registry_lockfile_e_supply_chain_cli_runtime_state: resb neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_SIZE
packages_registry_lockfile_e_supply_chain_cli_codegen_request: resb neboc_packages_registry_lockfile_e_supply_chain_CODEGEN_REQUEST_SIZE
imports_modulos_namespaces_e_api_publica_cli_frontend_diagnostic: resq 1
imports_modulos_namespaces_e_api_publica_cli_found: resq 1
imports_modulos_namespaces_e_api_publica_cli_parse_request: resb neboc_imports_modulos_namespaces_e_api_publica_PARSE_REQUEST_SIZE
imports_modulos_namespaces_e_api_publica_cli_syntax: resb neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SIZE
cli_table: resb neboc_imports_modulos_namespaces_e_api_publica_RECORD_SIZE
imports_modulos_namespaces_e_api_publica_cli_semantic: resb neboc_imports_modulos_namespaces_e_api_publica_SEM_SIZE
imports_modulos_namespaces_e_api_publica_cli_ir: resb neboc_imports_modulos_namespaces_e_api_publica_IR_SIZE
imports_modulos_namespaces_e_api_publica_cli_plan: resb neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SIZE
imports_modulos_namespaces_e_api_publica_cli_runtime_state: resb neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_SIZE
imports_modulos_namespaces_e_api_publica_cli_codegen_request: resb neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_REQUEST_SIZE
cli_module_request: resb NEBOC_MODULE_REQUEST_SIZE
cli_module_records: resb NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE
cli_module_plan: resb NEBOC_MODULE_PLAN_SIZE
cli_module_codegen: resb NEBOC_MODULE_CODEGEN_SIZE
cli_module_unit_count: resq 1
cli_module_unit_paths: resq 2
cli_module_unit_lengths: resq 2
cli_module_source1: resb NEBOC_MODULE_MAX_SOURCE_BYTES+1
cli_module_source2: resb NEBOC_MODULE_MAX_SOURCE_BYTES+1
resb ((8-(($-$$)&7))&7)
text_char_unicode_e_bytes_cli_semantic: resb neboc_text_char_unicode_e_bytes_SEM_REQUEST_SIZE_driver_cli_linux_x86_64_native_vertical
text_char_unicode_e_bytes_cli_symbols: resb NEBOC_SEM_MAX_SYMBOLS*NEBOC_SYMBOL_SIZE
text_char_unicode_e_bytes_cli_plan: resb neboc_text_char_unicode_e_bytes_PLAN_SIZE
text_char_unicode_e_bytes_cli_codegen: resb neboc_text_char_unicode_e_bytes_CODEGEN_SIZE
memoria_ownership_lifetimes_e_recursos_cli_frontend_diagnostic: resq 1
memoria_ownership_lifetimes_e_recursos_cli_found: resq 1
memoria_ownership_lifetimes_e_recursos_cli_parse_request: resb neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_SIZE
memoria_ownership_lifetimes_e_recursos_cli_runtime_request: resb neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_REQUEST_SIZE
memoria_ownership_lifetimes_e_recursos_cli_codegen_request: resb neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_REQUEST_SIZE
quality_confidence_e_lineage_cli_frontend_diagnostic: resq 1
quality_confidence_e_lineage_cli_found: resq 1
quality_confidence_e_lineage_cli_parse_request: resb neboc_quality_confidence_e_lineage_PARSE_REQUEST_SIZE
cli_parse_result: resb neboc_quality_confidence_e_lineage_RESULT_SIZE
quality_confidence_e_lineage_cli_native_request: resb neboc_quality_confidence_e_lineage_NATIVE_REQUEST_SIZE
quality_confidence_e_lineage_cli_runtime_request: resb neboc_quality_confidence_e_lineage_RUNTIME_REQUEST_SIZE
quality_confidence_e_lineage_cli_codegen_request: resb neboc_quality_confidence_e_lineage_CODEGEN_REQUEST_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic: resq 1
privacidade_dados_sensiveis_e_zero_trust_cli_found: resq 1
privacidade_dados_sensiveis_e_zero_trust_cli_parse_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_SIZE
cli_privacy_result: resb NEBOC_PRIVACY_RESULT_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_ir_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_IR_REQUEST_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_native_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REQUEST_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_SIZE
privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request: resb neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_REQUEST_SIZE
effects_capabilities_e_politicas_cli_frontend_diagnostic: resq 1
effects_capabilities_e_politicas_cli_found: resq 1
effects_capabilities_e_politicas_cli_parse_request: resb neboc_effects_capabilities_e_politicas_PARSE_REQUEST_SIZE
cli_policy_record: resb NEBOC_POLICY_REQUEST_SIZE
effects_capabilities_e_politicas_cli_semantic_request: resb neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_SIZE
effects_capabilities_e_politicas_cli_ir_request: resb neboc_effects_capabilities_e_politicas_IR_REQUEST_SIZE
effects_capabilities_e_politicas_cli_native_request: resb neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_SIZE
effects_capabilities_e_politicas_cli_runtime_request: resb neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_SIZE
effects_capabilities_e_politicas_cli_codegen_request: resb neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_SIZE
cli_writer: resb NEBOC_ASSEMBLY_WRITER_SIZE
cli_state: resb NEBOC_CLI_STATE_SIZE
cli_source: resb NEBOC_CLI_SOURCE_CAPACITY+1
cli_tokens: resb NEBOC_CLI_TOKEN_CAPACITY*NEBOC_TOKEN_SIZE
cli_literal_bytes: resb NEBOC_CLI_LITERAL_CAPACITY
cli_lexer_request: resb NEBOC_LEXER_REQUEST_SIZE
cli_ast_builder: resb NEBOC_AST_BUILDER_SIZE
cli_ast_nodes: resb NEBOC_CLI_AST_CAPACITY*NEBOC_AST_NODE_SIZE
cli_parser_request: resb NEBOC_PARSER_SIZE
cli_stmt_request: resb NEBOC_STMT_REQUEST_SIZE
cli_expr_request: resb NEBOC_EXPR_REQUEST_SIZE
cli_float_sem_request: resb NEBOC_FLOAT_SEM_REQUEST_SIZE
seguranca_numerica_conversoes_e_overflow_cli_vertical_request: resb neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_REQUEST_SIZE
seguranca_numerica_conversoes_e_overflow_cli_frontend_diagnostic: resq 1
text_char_unicode_e_bytes_cli_vertical_request: resb neboc_text_char_unicode_e_bytes_VERTICAL_REQUEST_SIZE
text_char_unicode_e_bytes_cli_frontend_diagnostic: resq 1
bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic: resq 1
literais_numericos_bases_e_representacao_cli_parse_request: resb neboc_literais_numericos_bases_e_representacao_PARSE_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_symbols: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_branch_a: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_branch_b: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_loop_snapshots: resb NEBOC_VERTICAL_MAX_LOOP_DEPTH*neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_loop_plan: resb NEBOC_LOOP_PLAN_SIZE
option_result_null_externo_e_erros_tipados_cli_parse_request: resb NEBOC_VPARSE_REQUEST_SIZE
cli_frontend_status: resq 1
cli_operations: resb NEBOC_VERTICAL_MAX_OPERATIONS*NEBOC_VOP_RECORD_SIZE
cli_sem_request: resb NEBOC_VSEM_REQUEST_SIZE
option_result_null_externo_e_erros_tipados_cli_symbols: resb neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS*NEBOC_VSYM_RECORD_SIZE
resb ((8-(($-$$)&7))&7)
cli_option: resb NEBOC_OPTION_REQUEST_SIZE
cli_option_bindings: resb NEBOC_OPTION_MAX_BINDINGS*NEBOC_OPTION_BIND_SIZE
cli_option_plan: resb NEBOC_OPTION_PLAN_SIZE
cli_option_codegen: resb NEBOC_OPTION_CODEGEN_SIZE
resb ((8-(($-$$)&7))&7)
cli_result: resb NEBOC_RESULT_REQUEST_SIZE
cli_result_bindings: resb NEBOC_RESULT_MAX_BINDINGS*NEBOC_RESULT_BIND_SIZE
cli_result_plan: resb NEBOC_RESULT_PLAN_SIZE
cli_result_codegen: resb NEBOC_RESULT_CODEGEN_SIZE
resb ((8-(($-$$)&7))&7)
cli_parameters: resb NEBOC_PARAM_REQUEST_SIZE
cli_param_records: resb NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE
cli_param_plan: resb neboc_seguranca_numerica_conversoes_e_overflow_PLAN_SIZE
cli_param_codegen: resb neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_SIZE
resb ((8-(($-$$)&7))&7)
cli_generic: resb NEBOC_GEN_REQUEST_SIZE
cli_generic_records: resb NEBOC_GEN_MAX_INSTANCES*NEBOC_GEN_RECORD_SIZE
cli_generic_plan: resb NEBOC_GEN_PLAN_SIZE
cli_generic_codegen: resb NEBOC_GEN_CODEGEN_SIZE
resb ((8-(($-$$)&7))&7)
cli_nominal: resb NEBOC_NOM_REQUEST_SIZE
cli_nominal_variants: resb NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_SIZE
cli_nominal_plan: resb NEBOC_NOM_PLAN_SIZE
cli_nominal_codegen: resb NEBOC_NOM_CODEGEN_SIZE
resb ((8-(($-$$)&7))&7)
cli_buffer: resb NEBOC_BUFFER_F11_REQUEST_SIZE
cli_buffer_plan: resb NEBOC_BUFFER_PLAN_F11_SIZE
cli_buffer_codegen: resb NEBOC_BUFFER_CODEGEN_SIZE
generics_constraints_overload_e_dispatch_cli_vertical_request: resb neboc_generics_constraints_overload_e_dispatch_VERTICAL_REQUEST_SIZE
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_REQUEST_SIZE
structs_enums_variants_e_tipos_do_programador_cli_vertical_request: resb neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_REQUEST_SIZE
resb ((8-(($-$$)&7))&7)
cli_struct_tuple: resb NEBOC_ST_REQUEST_SIZE
cli_decls: resb NEBOC_ST_MAX_DECLS*NEBOC_DECL_SIZE
cli_values: resb NEBOC_ST_MAX_VALUES*NEBOC_VALUE_SIZE
cli_bindings: resb NEBOC_ST_MAX_BINDINGS*NEBOC_BINDING_SIZE
option_result_null_externo_e_erros_tipados_cli_plan: resb neboc_option_result_null_externo_e_erros_tipados_PLAN_SIZE
option_result_null_externo_e_erros_tipados_cli_codegen: resb neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SIZE
colecoes_primitivas_cli_vertical_request: resb NEBOC_ARRAY_VERTICAL_REQUEST_SIZE
resb ((8-(($-$$)&7))&7)
cli_array_range: resb NEBOC_AR_REQUEST_SIZE
cli_ar_bindings: resb NEBOC_AR_MAX_BINDINGS*NEBOC_AR_BIND_SIZE
cli_ar_values: resq NEBOC_AR_MAX_VALUES
cli_for_loops: resb NEBOC_FOR_MAX_LOOPS*NEBOC_FOR_RECORD_SIZE
cli_ar_plan: resb NEBOC_AR_PLAN_SIZE
cli_ar_codegen: resb NEBOC_AR_CODEGEN_SIZE
cli_slice_plan: resb NEBOC_SLICE_PLAN_SIZE
cli_slice_codegen: resb NEBOC_SLICE_CODEGEN_SIZE
vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request: resb NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
column_row_table_e_dataset_cli_vertical_request: resb NEBOC_COLUMN_VERTICAL_REQUEST_SIZE
cli_float_lowering_request: resb NEBOC_FLOAT_LOWERING_REQUEST_SIZE
cli_float_lowering_bits: resq 1
cli_float_runtime_class: resq 1
cli_float_runtime_flags: resq 1
cli_layout: resb NEBOC_DATA_LAYOUT_SIZE
cli_target_context: resb NEBOC_TARGET_CONTEXT_SIZE
cli_target_request: resb NEBOC_TARGET_REQUEST_SIZE
cli_backend: resb NEBOC_ARCH_BACKEND_SIZE
cli_value_codegen: resb NEBOC_CORE_VALUE_CODEGEN_SIZE
cli_abi_adapter: resb NEBOC_ABI_ADAPTER_SIZE
cli_abi_request: resb NEBOC_ABI_REQUEST_SIZE
cli_function_codegen: resb NEBOC_FUNCTION_CODEGEN_SIZE
cli_function_codegen_request: resb NEBOC_FUNCTION_CODEGEN_REQUEST_SIZE
cli_function_signatures: resb (NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1)*NEBOC_ABI_SIGNATURE_SIZE
cli_function_plans: resb (NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1)*NEBOC_FUNCTION_PLAN_SIZE
cli_float_codegen_request: resb NEBOC_FLOAT_CODEGEN_SIZE
seguranca_numerica_conversoes_e_overflow_cli_codegen_request: resb neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_REQUEST_SIZE
text_char_unicode_e_bytes_cli_codegen_request: resb neboc_text_char_unicode_e_bytes_CODEGEN_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_REQUEST_SIZE
cli_loop_stack: resq NEBOC_CODEGEN_MAX_LOOP_DEPTH
option_result_null_externo_e_erros_tipados_cli_codegen_request: resb neboc_option_result_null_externo_e_erros_tipados_CODEGEN_REQUEST_SIZE
generics_constraints_overload_e_dispatch_cli_codegen_request: resb neboc_generics_constraints_overload_e_dispatch_CODEGEN_REQUEST_SIZE
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_codegen_request: resb neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_REQUEST_SIZE
structs_enums_variants_e_tipos_do_programador_cli_codegen_request: resb neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_REQUEST_SIZE
colecoes_primitivas_cli_codegen_request: resb NEBOC_ARRAY_CODEGEN_REQUEST_SIZE
vetores_matrizes_tensores_e_computacao_cientifica_cli_codegen_request: resb NEBOC_VECTOR_CODEGEN_REQUEST_SIZE
column_row_table_e_dataset_cli_codegen_request: resb NEBOC_COLUMN_CODEGEN_REQUEST_SIZE
cli_format: resb NEBOC_FORMAT_ADAPTER_SIZE
cli_toolchain: resb NEBOC_TOOLCHAIN_SIZE
cli_toolchain_request: resb NEBOC_TOOLCHAIN_REQUEST_SIZE
cli_toolchain_invocation: resb NEBOC_TOOLCHAIN_INVOCATION_SIZE
cli_toolchain_result: resb NEBOC_TOOLCHAIN_RESULT_SIZE
cli_asm_output: resb NEBOC_CLI_ASM_CAPACITY
cli_temp_asm_path: resb NEBOC_CLI_PATH_CAPACITY
cli_temp_obj_path: resb NEBOC_CLI_PATH_CAPACITY
cli_runtime_obj_path: resb NEBOC_CLI_PATH_CAPACITY
cli_wait_status: resd 1
cli_null_env: resq 1
cli_message_format: resq 1
cli_color_policy: resq 1
cli_path_style: resq 1
cli_diagnostic_width: resq 1
cli_warnings_as_errors: resq 1
cli_warning_rule_count: resq 1
cli_warning_rules: resq 32
cli_max_errors: resq 1
cli_recovery_policy: resq 1
cli_build_events_path: resq 1
cli_machine_reporting: resq 1
cli_show_fixes: resq 1
cli_explanation: resb NEBOC_EXPLANATION_SIZE
cli_explanation_writer: resb NEBOC_WRITER_SIZE
cli_explanation_output: resb 4096
cli_ice_report: resb NEBOC_ICE_REPORT_SIZE
cli_ice_request: resb NEBOC_ICE_REQUEST_SIZE
cli_ice_manifest: resb NEBOC_ICE_MANIFEST_SIZE
cli_ice_reproducer: resb NEBOC_ICE_REPRO_SIZE
cli_ice_capability: resb NEBOC_ICE_CAP_SIZE
cli_ice_writer: resb NEBOC_WRITER_SIZE
cli_ice_output: resb NEBOC_ICE_MAX_BUNDLE_BYTES
cli_ice_path: resb NEBOC_CLI_PATH_CAPACITY
cli_ice_output_length: resq 1
cli_ice_trace: resq 3
cli_progress_policy: resq 1
cli_quiet: resq 1
cli_verbose: resq 1
cli_trace_component: resq 1
cli_trace_component_length: resq 1
cli_terminal_policy: resb NEBOC_TERMINAL_POLICY_SIZE
cli_terminal_caps: resb NEBOC_TERMINAL_CAP_SIZE

section .text

; neboc_cli_main(argc, argv) -> public CLI exit code in EAX.
NEBOC_ABI_FUNCTION neboc_cli_main
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 lea rdi,[rel cli_state]
 mov ecx,NEBOC_CLI_STATE_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rel cli_module_unit_count],0
 mov qword [rel cli_module_unit_paths],0
 mov qword [rel cli_module_unit_paths+8],0
 mov qword [rel cli_module_unit_lengths],0
 mov qword [rel cli_module_unit_lengths+8],0
 mov qword [rel cli_show_fixes],0
 mov qword [rel cli_progress_policy],0
 mov qword [rel cli_quiet],0
 mov qword [rel cli_verbose],0
 mov qword [rel cli_trace_component],0
 mov qword [rel cli_trace_component_length],0
 test r13,r13
 jz .internal
 test r12,r12
 jz .help
 mov rax,[r13]
 mov [rel cli_state+NEBOC_CLI_STATE_ARGV0_PTR_OFFSET],rax
 cmp r12,1
 je .help
 mov rbx,[r13+8]
 mov rdi,rbx
 lea rsi,[rel arg_help]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .help_exact
 mov rdi,rbx
 lea rsi,[rel arg_version]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jnz .version_exact
 mov rdi,rbx
 lea rsi,[rel arg_bench]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .bench_exact
 mov rdi,rbx
 lea rsi,[rel arg_probabilistic_report]
 mov edx,20
 call cli_arg_equals
 test eax,eax
 jnz .probabilistic_report_exact
 mov rdi,rbx
 lea rsi,[rel arg_firmware]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .firmware_exact
 mov rdi,rbx
 lea rsi,[rel arg_simulation_replay]
 mov edx,17
 call cli_arg_equals
 test eax,eax
 jnz .simulation_replay_exact
 mov rdi,rbx
 lea rsi,[rel arg_crypto_audit]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .crypto_audit_exact
 mov rdi,rbx
 lea rsi,[rel arg_optimize_explain]
 mov edx,16
 call cli_arg_equals
 test eax,eax
 jnz .optimize_explain_exact
 mov rdi,rbx
 lea rsi,[rel arg_bootstrap]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jnz .bootstrap_exact
 mov rdi,rbx
 lea rsi,[rel arg_protocol]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .protocol_exact
 mov rdi,rbx
 lea rsi,[rel arg_warnings]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .warnings_exact
 mov rdi,rbx
 lea rsi,[rel arg_diagnostic_schema]
 mov edx,17
 call cli_arg_equals
 test eax,eax
 jnz .diagnostic_schema_exact
 mov rdi,rbx
 lea rsi,[rel arg_explain]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .explain_exact
 mov rdi,rbx
 lea rsi,[rel arg_diagnostics]
 mov edx,11
 call cli_arg_equals
 test eax,eax
 jnz .diagnostics_exact
 mov rdi,rbx
 lea rsi,[rel arg_bug_report]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .bug_report_exact
 mov rdi,rbx
 lea rsi,[rel arg_minimize_ice]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .minimize_ice_exact
 mov rdi,rbx
 lea rsi,[rel arg_exit_codes]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .exit_codes_exact
 mov rdi,rbx
 lea rsi,[rel arg_check]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .mode_check
 mov rdi,rbx
 lea rsi,[rel arg_emit_asm]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .mode_emit
 mov rdi,rbx
 lea rsi,[rel arg_build]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .mode_build
 lea rdi,[rel cli_error_unknown]
 mov esi,cli_error_unknown_end-cli_error_unknown
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_USAGE_ERROR
 jmp .done
.help_exact:
 cmp r12,2
 jne .usage
.help:
 lea rdi,[rel cli_help_text]
 mov esi,cli_help_text_end-cli_help_text
 call cli_write_stdout
 xor eax,eax
 jmp .done
.version_exact:
 cmp r12,2
 jne .usage
 lea rdi,[rel cli_version_text]
 mov esi,cli_version_text_end-cli_version_text
 call cli_write_stdout
 xor eax,eax
 jmp .done
.warnings_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_list]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jz .usage
 lea rdi,[rel warning_list]
 mov esi,warning_list_end-warning_list
 call cli_write_stdout
 xor eax,eax
 jmp .done
.diagnostic_schema_exact:
 cmp r12,4
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_version]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+24]
 cmp byte [rdi],'1'
 jne .usage
 cmp byte [rdi+1],0
 jne .usage
 lea rdi,[rel diagnostic_schema]
 mov esi,diagnostic_schema_end-diagnostic_schema
 call cli_write_stdout
 xor eax,eax
 jmp .done
.explain_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 call cli_strlen_path
 cmp rax,-1
 je .usage
 test rax,rax
 jz .usage
 cmp rax,NEBOC_EXPLANATION_MAX_QUERY_BYTES
 ja .usage
 mov rdi,[r13+16]
 mov rsi,rax
 lea rdx,[rel cli_explanation]
 call neboc_diagnostic_explanation_load
 test eax,eax
 jnz .usage
 lea rax,[rel cli_explanation_output]
 mov [rel cli_explanation_writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel cli_explanation_writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel cli_explanation_writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel cli_explanation]
 lea rsi,[rel cli_explanation_writer]
 call neboc_diagnostic_explanation_render
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_explanation_output]
 mov rsi,[rel cli_explanation_writer+NEBOC_WRITER_LENGTH_OFFSET]
 call cli_write_stdout
 xor eax,eax
 jmp .done
.diagnostics_exact:
 cmp r12,4
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_search]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+24]
 call cli_strlen_path
 cmp rax,-1
 je .usage
 test rax,rax
 jz .usage
 cmp rax,NEBOC_EXPLANATION_MAX_QUERY_BYTES
 ja .usage
 lea rcx,[rel cli_explanation_output]
 mov [rel cli_explanation_writer+NEBOC_WRITER_BYTES_OFFSET],rcx
 mov qword [rel cli_explanation_writer+NEBOC_WRITER_CAPACITY_OFFSET],4096
 mov qword [rel cli_explanation_writer+NEBOC_WRITER_LENGTH_OFFSET],0
 mov rdi,[r13+24]
 mov rsi,rax
 lea rdx,[rel cli_explanation_writer]
 call neboc_diagnostic_explanation_search
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_explanation_output]
 mov rsi,[rel cli_explanation_writer+NEBOC_WRITER_LENGTH_OFFSET]
 call cli_write_stdout
 xor eax,eax
 jmp .done
.bug_report_exact:
 cmp r12,4
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_local]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .bug_report_local
 mov rdi,[r13+16]
 lea rsi,[rel arg_inspect]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+24]
 call cli_validate_output_path
 test eax,eax
 jnz .usage
 mov rax,[r13+24]
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rax
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_ice_reset_writer
 lea rdi,[rel cli_source]
 mov rsi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 lea rdx,[rel cli_ice_writer]
 call neboc_ice_bundle_inspect
 test eax,eax
 jnz .usage
 lea rdi,[rel cli_ice_output]
 mov rsi,[rel cli_ice_writer+NEBOC_WRITER_LENGTH_OFFSET]
 call cli_write_stdout
 xor eax,eax
 jmp .done
.bug_report_local:
 mov rdi,[r13+24]
 call cli_validate_output_path
 test eax,eax
 jnz .usage
 mov rax,[r13+24]
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rax
 call cli_read_source
 test eax,eax
 jnz .done
 mov rdi,[r13+24]
 call cli_strlen_path
 cmp rax,-1
 je .usage
 test rax,rax
 jz .usage
 cmp rax,NEBOC_CLI_PATH_CAPACITY-ice_suffix_len-1
 ja .usage
 mov [rel cli_ice_output_length],rax
 lea rdi,[rel cli_ice_path]
 mov rsi,[r13+24]
 xor ecx,ecx
.bug_path_copy:
 cmp rcx,rax
 jae .bug_suffix_copy
 mov dl,[rsi+rcx]
 mov [rdi+rcx],dl
 inc rcx
 jmp .bug_path_copy
.bug_suffix_copy:
 lea rsi,[rel ice_suffix]
 xor edx,edx
.bug_suffix_loop:
 mov bl,[rsi+rdx]
 mov [rdi+rcx],bl
 inc rcx
 inc rdx
 test bl,bl
 jnz .bug_suffix_loop
 mov rax,[rel cli_ice_output_length]
 add rax,ice_suffix_len
 mov [rel cli_ice_output_length],rax
 mov qword [rel cli_ice_request+NEBOC_ICE_REQUEST_PHASE_OFFSET],13
 lea rax,[rel ice_invariant]
 mov [rel cli_ice_request+NEBOC_ICE_REQUEST_INVARIANT_OFFSET],rax
 mov qword [rel cli_ice_request+NEBOC_ICE_REQUEST_INVARIANT_LENGTH_OFFSET],ice_invariant_len
 lea rax,[rel ice_context]
 mov [rel cli_ice_request+NEBOC_ICE_REQUEST_CONTEXT_OFFSET],rax
 mov qword [rel cli_ice_request+NEBOC_ICE_REQUEST_CONTEXT_LENGTH_OFFSET],ice_context_len
 lea rdi,[rel cli_ice_report]
 lea rsi,[rel cli_ice_request]
 call neboc_ice_report_new
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_ice_report]
 mov rsi,0x52f8000000000001
 mov edx,1
 call neboc_ice_report_node_identity
 test eax,eax
 jnz .internal
 mov qword [rel cli_ice_trace],1
 mov qword [rel cli_ice_trace+8],4
 mov qword [rel cli_ice_trace+16],13
 lea rdi,[rel cli_ice_report]
 lea rsi,[rel cli_ice_trace]
 mov edx,3
 call neboc_ice_report_phase_trace
 test eax,eax
 jnz .internal
 lea rax,[rel ice_version]
 mov [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_VERSION_OFFSET],rax
 mov qword [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_VERSION_LENGTH_OFFSET],ice_version_len
 lea rax,[rel ice_target]
 mov [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_TARGET_OFFSET],rax
 mov qword [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_TARGET_LENGTH_OFFSET],ice_target_len
 mov rax,0x52f8000000000010
 mov [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_OPTIONS_DIGEST_OFFSET],rax
 mov rax,0x52f8000000000020
 mov [rel cli_ice_manifest+NEBOC_ICE_MANIFEST_FEATURE_DIGEST_OFFSET],rax
 lea rdi,[rel cli_ice_report]
 lea rsi,[rel cli_ice_manifest]
 call neboc_ice_report_compiler_manifest
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_ice_report]
 mov esi,NEBOC_ICE_REDACT_STRICT
 call neboc_ice_report_redact
 test eax,eax
 jnz .internal
 lea rax,[rel cli_source]
 mov [rel cli_ice_reproducer+NEBOC_ICE_REPRO_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,NEBOC_ICE_MAX_SOURCE_BYTES
 jbe .bug_source_bounded
 mov eax,NEBOC_ICE_MAX_SOURCE_BYTES
.bug_source_bounded:
 mov [rel cli_ice_reproducer+NEBOC_ICE_REPRO_SOURCE_LENGTH_OFFSET],rax
 mov qword [rel cli_ice_reproducer+NEBOC_ICE_REPRO_INCLUDE_SOURCE_OFFSET],0
 mov qword [rel cli_ice_reproducer+NEBOC_ICE_REPRO_MAX_SOURCE_OFFSET],NEBOC_ICE_MAX_SOURCE_BYTES
 call cli_ice_reset_writer
 lea rdi,[rel cli_ice_report]
 lea rsi,[rel cli_ice_reproducer]
 lea rdx,[rel cli_ice_writer]
 call neboc_ice_report_reproducer
 test eax,eax
 jnz .internal
 mov qword [rel cli_ice_capability+NEBOC_ICE_CAP_PREFIX_OFFSET],0
 mov qword [rel cli_ice_capability+NEBOC_ICE_CAP_PREFIX_LENGTH_OFFSET],0
 mov qword [rel cli_ice_capability+NEBOC_ICE_CAP_MAX_BYTES_OFFSET],NEBOC_ICE_MAX_BUNDLE_BYTES
 mov qword [rel cli_ice_capability+NEBOC_ICE_CAP_ALLOW_WRITE_OFFSET],1
 lea rdi,[rel cli_ice_report]
 lea rsi,[rel cli_ice_path]
 mov rdx,[rel cli_ice_output_length]
 lea rcx,[rel cli_ice_capability]
 call neboc_ice_report_write
 test eax,eax
 jnz .io
 lea rdi,[rel cli_ice_path]
 mov rsi,[rel cli_ice_output_length]
 call cli_write_stdout
 lea rdi,[rel ice_newline]
 mov esi,1
 call cli_write_stdout
 xor eax,eax
 jmp .done
.minimize_ice_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 call cli_validate_output_path
 test eax,eax
 jnz .usage
 mov rax,[r13+16]
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rax
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_ice_reset_writer
 lea rdi,[rel cli_source]
 mov rsi,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 lea rdx,[rel cli_ice_writer]
 call neboc_ice_bundle_minimize
 test eax,eax
 jnz .usage
 lea rdi,[rel cli_ice_output]
 mov rsi,[rel cli_ice_writer+NEBOC_WRITER_LENGTH_OFFSET]
 call cli_write_stdout
 xor eax,eax
 jmp .done
.exit_codes_exact:
 cmp r12,2
 jne .usage
 lea rdi,[rel exit_code_registry]
 mov esi,exit_code_registry_end-exit_code_registry
 call cli_write_stdout
 xor eax,eax
 jmp .done
.bench_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_bench_numeric]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jz .usage
 call nebo_bench_cli_run
 jmp .done
.probabilistic_report_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .report_status
 call cli_probabilistic_report
 jmp .done
.firmware_exact:
 cmp r12,5
 jne .usage
 mov rdi,[r13+32]
 lea rsi,[rel arg_reference_board]
 mov edx,27
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_firmware_build]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .firmware_build
 mov rdi,[r13+16]
 lea rsi,[rel arg_firmware_test]
 mov edx,4
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+24]
 lea rsi,[rel arg_firmware_simulator]
 mov edx,11
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov edi,1
 call cli_firmware_report
 xor eax,eax
 jmp .done
.firmware_build:
 mov rdi,[r13+24]
 lea rsi,[rel arg_firmware_board]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jz .usage
 xor edi,edi
 call cli_firmware_report
 xor eax,eax
 jmp .done
.crypto_audit_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_crypto_audit
 jmp .done
.optimize_explain_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_optimize_explain
 jmp .done
.bootstrap_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_verify]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jz .usage
 call cli_bootstrap_verify
 jmp .done
.protocol_exact:
 cmp r12,4
 jne .usage
 mov rdi,[r13+16]
 lea rsi,[rel arg_protocol_generate]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .protocol_generate_exact
 mov rdi,[r13+16]
 lea rsi,[rel arg_protocol_fuzz]
 mov edx,4
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov rdi,[r13+24]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_protocol_fuzz
 jmp .done
.protocol_generate_exact:
 mov rdi,[r13+24]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_protocol_generate
 jmp .done
.simulation_replay_exact:
 cmp r12,3
 jne .usage
 mov rdi,[r13+16]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi
 call cli_read_source
 test eax,eax
 jnz .done
 call cli_simulation_replay_validate
 jmp .done
.mode_check:
 mov qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jmp .parse
.mode_emit:
 mov qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_EMIT_ASM
 jmp .parse
.mode_build:
 mov qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
.parse:
 mov r14,2
.parse_loop:
 cmp r14,r12
 jae .parse_done
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_emit_build_events]
 mov edx,19
 call cli_arg_equals
 test eax,eax
 jnz .parse_emit_build_events
 mov rdi,rbx
 lea rsi,[rel arg_max_errors]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .parse_max_errors
 mov rdi,rbx
 lea rsi,[rel arg_fail_fast]
 mov edx,11
 call cli_arg_equals
 test eax,eax
 jnz .parse_fail_fast
 mov rdi,rbx
 lea rsi,[rel arg_keep_going]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .parse_keep_going
 mov rdi,rbx
 lea rsi,[rel arg_show_fixes]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .parse_show_fixes
 mov rdi,rbx
 lea rsi,[rel arg_progress]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .parse_progress
 mov rdi,rbx
 lea rsi,[rel arg_quiet]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .parse_quiet
 mov rdi,rbx
 lea rsi,[rel arg_verbose]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jnz .parse_verbose
 mov rdi,rbx
 lea rsi,[rel arg_trace]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .parse_trace
 mov rdi,rbx
 lea rsi,[rel arg_warnings_as_errors]
 mov edx,20
 call cli_arg_equals
 test eax,eax
 jnz .parse_warnings_as_errors
 mov rdi,rbx
 lea rsi,[rel arg_allow]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .parse_allow
 mov rdi,rbx
 lea rsi,[rel arg_warn]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .parse_warn
 mov rdi,rbx
 lea rsi,[rel arg_deny]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .parse_deny
 mov rdi,rbx
 lea rsi,[rel arg_forbid]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .parse_forbid
 mov rdi,rbx
 lea rsi,[rel arg_message_format]
 mov edx,16
 call cli_arg_equals
 test eax,eax
 jnz .parse_message_format
 mov rdi,rbx
 lea rsi,[rel arg_color]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .parse_color
 mov rdi,rbx
 lea rsi,[rel arg_path_style]
 mov edx,12
 call cli_arg_equals
 test eax,eax
 jnz .parse_path_style
 mov rdi,rbx
 lea rsi,[rel arg_diagnostic_width]
 mov edx,18
 call cli_arg_equals
 test eax,eax
 jnz .parse_diagnostic_width
 mov rdi,rbx
 lea rsi,[rel arg_output]
 mov edx,2
 call cli_arg_equals
 test eax,eax
 jnz .parse_output
 mov rdi,rbx
 lea rsi,[rel arg_keep_temp]
 mov edx,11
 call cli_arg_equals
 test eax,eax
 jnz .parse_keep
 mov rdi,rbx
 lea rsi,[rel arg_unit]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .parse_unit
 cmp byte [rbx],'-'
 je .usage
 cmp qword [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],0
 jne .usage
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rbx
 inc r14
 jmp .parse_loop
.parse_emit_build_events:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_build_events_path],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rdi,[r13+r14*8]
 call cli_validate_output_path
 test eax,eax
 jnz .usage
 mov rax,[r13+r14*8]
 mov [rel cli_build_events_path],rax
 inc r14
 jmp .parse_loop
.parse_max_errors:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_max_errors],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 xor eax,eax
 xor ecx,ecx
.max_errors_digit:
 movzx edx,byte [rbx+rcx]
 test dl,dl
 jz .max_errors_ready
 cmp dl,'0'
 jb .usage
 cmp dl,'9'
 ja .usage
 imul rax,rax,10
 sub dl,'0'
 movzx edx,dl
 add rax,rdx
 cmp rax,NEBOC_DIAG_BAG_HARD_MAX
 ja .usage
 inc rcx
 jmp .max_errors_digit
.max_errors_ready:
 test rcx,rcx
 jz .usage
 test rax,rax
 jz .usage
 mov [rel cli_max_errors],rax
 inc r14
 jmp .parse_loop
.parse_fail_fast:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_recovery_policy],0
 jne .usage
 mov qword [rel cli_recovery_policy],1
 inc r14
 jmp .parse_loop
.parse_keep_going:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_recovery_policy],0
 jne .usage
 mov qword [rel cli_recovery_policy],2
 inc r14
 jmp .parse_loop
.parse_show_fixes:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_show_fixes],0
 jne .usage
 mov qword [rel cli_show_fixes],1
 inc r14
 jmp .parse_loop
.parse_progress:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
 jne .usage
 cmp qword [rel cli_progress_policy],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_auto]
 mov edx,4
 call cli_arg_equals
 test eax,eax
 jnz .progress_auto
 mov rdi,rbx
 lea rsi,[rel arg_always]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .progress_always
 mov rdi,rbx
 lea rsi,[rel arg_never]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_progress_policy],3
 jmp .option_done
.progress_auto:
 mov qword [rel cli_progress_policy],1
 jmp .option_done
.progress_always:
 mov qword [rel cli_progress_policy],2
 jmp .option_done
.parse_quiet:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
 jne .usage
 cmp qword [rel cli_quiet],0
 jne .usage
 cmp qword [rel cli_verbose],0
 jne .usage
 cmp qword [rel cli_trace_component],0
 jne .usage
 mov qword [rel cli_quiet],1
 inc r14
 jmp .parse_loop
.parse_verbose:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
 jne .usage
 cmp qword [rel cli_verbose],0
 jne .usage
 cmp qword [rel cli_quiet],0
 jne .usage
 mov qword [rel cli_verbose],1
 inc r14
 jmp .parse_loop
.parse_trace:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
 jne .usage
 cmp qword [rel cli_trace_component],0
 jne .usage
 cmp qword [rel cli_quiet],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_driver_component]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .trace_driver
 mov rdi,rbx
 lea rsi,[rel arg_diagnostics_component]
 mov edx,11
 call cli_arg_equals
 test eax,eax
 jnz .trace_diagnostics
 mov rdi,rbx
 lea rsi,[rel arg_codegen_component]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_trace_component_length],7
 jmp .trace_store
.trace_driver:
 mov qword [rel cli_trace_component_length],6
 jmp .trace_store
.trace_diagnostics:
 mov qword [rel cli_trace_component_length],11
.trace_store:
 mov [rel cli_trace_component],rbx
 inc r14
 jmp .parse_loop
.parse_warnings_as_errors:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_warnings_as_errors],0
 jne .usage
 mov qword [rel cli_warnings_as_errors],1
 inc r14
 jmp .parse_loop
.parse_allow:
 mov edx,NEBOC_WARNING_LEVEL_ALLOW
 jmp .parse_warning_rule
.parse_warn:
 mov edx,NEBOC_WARNING_LEVEL_WARN
 jmp .parse_warning_rule
.parse_deny:
 mov edx,NEBOC_WARNING_LEVEL_DENY
 jmp .parse_warning_rule
.parse_forbid:
 mov edx,NEBOC_WARNING_LEVEL_FORBID
.parse_warning_rule:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 mov rcx,[rel cli_warning_rule_count]
 cmp rcx,16
 jae .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rax,[r13+r14*8]
 test rax,rax
 jz .usage
 cmp byte [rax],0
 je .usage
 cmp byte [rax],'-'
 je .usage
 lea rsi,[rel cli_warning_rules]
 mov r8,rcx
 shl r8,4
 mov [rsi+r8],rax
 mov [rsi+r8+8],rdx
 inc rcx
 mov [rel cli_warning_rule_count],rcx
 inc r14
 jmp .parse_loop
.parse_message_format:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_message_format],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_human]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .message_human
 mov rdi,rbx
 lea rsi,[rel arg_short]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jnz .message_short
 mov rdi,rbx
 lea rsi,[rel arg_json]
 mov edx,4
 call cli_arg_equals
 test eax,eax
 jnz .message_json
 mov rdi,rbx
 lea rsi,[rel arg_json_lines]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .message_json_lines
 mov rdi,rbx
 lea rsi,[rel arg_sarif]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_message_format],5
 jmp .option_done
.message_json_lines:
 mov qword [rel cli_message_format],4
 jmp .option_done
.message_json:
 mov qword [rel cli_message_format],3
 jmp .option_done
.message_short:
 mov qword [rel cli_message_format],2
 jmp .option_done
.message_human:
 mov qword [rel cli_message_format],1
 jmp .option_done
.parse_color:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_color_policy],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_auto]
 mov edx,4
 call cli_arg_equals
 test eax,eax
 jnz .color_auto
 mov rdi,rbx
 lea rsi,[rel arg_always]
 mov edx,6
 call cli_arg_equals
 test eax,eax
 jnz .color_always
 mov rdi,rbx
 lea rsi,[rel arg_never]
 mov edx,5
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_color_policy],3
 jmp .option_done
.color_auto:
 mov qword [rel cli_color_policy],1
 jmp .option_done
.color_always:
 mov qword [rel cli_color_policy],2
 jmp .option_done
.parse_path_style:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_path_style],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_relative]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .path_relative
 mov rdi,rbx
 lea rsi,[rel arg_workspace]
 mov edx,9
 call cli_arg_equals
 test eax,eax
 jnz .path_workspace
 mov rdi,rbx
 lea rsi,[rel arg_absolute]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_path_style],3
 jmp .option_done
.path_relative:
 mov qword [rel cli_path_style],1
 jmp .option_done
.path_workspace:
 mov qword [rel cli_path_style],2
 jmp .option_done
.parse_diagnostic_width:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .usage
 cmp qword [rel cli_diagnostic_width],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 xor eax,eax
 xor ecx,ecx
.width_digit:
 movzx edx,byte [rbx+rcx]
 test dl,dl
 jz .width_ready
 cmp dl,'0'
 jb .usage
 cmp dl,'9'
 ja .usage
 imul rax,rax,10
 sub dl,'0'
 movzx edx,dl
 add rax,rdx
 cmp rax,240
 ja .usage
 inc rcx
 jmp .width_digit
.width_ready:
 test rcx,rcx
 jz .usage
 cmp rax,40
 jb .usage
 mov [rel cli_diagnostic_width],rax
.option_done:
 inc r14
 jmp .parse_loop
.parse_output:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rax,[r13+r14*8]
 test rax,rax
 jz .usage
 cmp byte [rax],0
 je .usage
 mov [rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET],rax
 inc r14
 jmp .parse_loop
.parse_keep:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .usage
 mov qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],1
 inc r14
 jmp .parse_loop
.parse_unit:
 mov rcx,[rel cli_module_unit_count]
 cmp rcx,2
 jae .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rax,[r13+r14*8]
 test rax,rax
 jz .usage
 cmp byte [rax],0
 je .usage
 cmp byte [rax],'-'
 je .usage
 lea rdx,[rel cli_module_unit_paths]
 mov [rdx+rcx*8],rax
 inc rcx
 mov [rel cli_module_unit_count],rcx
 inc r14
 jmp .parse_loop
.parse_done:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],0
 je .usage
 mov rax,[rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET]
 cmp rax,NEBOC_CLI_MODE_CHECK
 jne .need_output
 cmp qword [rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET],0
 jne .usage
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .usage
 cmp qword [rel cli_show_fixes],0
 je .check_options_ready
 cmp qword [rel cli_message_format],3
 jae .usage
.check_options_ready:
 jmp .validate_extension
.need_output:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET],0
 je .usage
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 call cli_validate_output_path
 test eax,eax
 jnz .output_path
 mov rax,[rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET]
 cmp rax,NEBOC_CLI_MODE_BUILD
 je .validate_extension
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .usage
.validate_extension:
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_validate_no_extension
 test eax,eax
 jnz .extension
 call cli_validate_module_unit_paths
 test eax,eax
 jnz .extension
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_read_source
 test eax,eax
 jnz .report_status
 call cli_read_module_units
 test eax,eax
 jnz .report_status
 cmp qword [rel cli_message_format],3
 jb .frontend_call
 mov qword [rel cli_machine_reporting],1
.frontend_call:
 call cli_frontend_validate
 test eax,eax
 jz .frontend_ready
 cmp qword [rel cli_message_format],3
 jae .source
 call cli_report_buffer_diagnostic
 test eax,eax
 jnz .source
 call console_visual_dashboard_e_plots_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call rede_e_protocolos_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call filesystem_paths_e_formatos_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call biblioteca_padrao_por_dominios_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call packages_registry_lockfile_e_supply_chain_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call cli_report_module_diagnostic
 test eax,eax
 jnz .source
 call imports_modulos_namespaces_e_api_publica_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call cli_report_ownership_diagnostic
 test eax,eax
 jnz .source
 call memoria_ownership_lifetimes_e_recursos_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call quality_confidence_e_lineage_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call privacidade_dados_sensiveis_e_zero_trust_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call effects_capabilities_e_politicas_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call column_row_table_e_dataset_cli_report_diagnostic
 test eax,eax
 jnz .source
 call vetores_matrizes_tensores_e_computacao_cientifica_cli_report_diagnostic
 test eax,eax
 jnz .source
 call colecoes_primitivas_cli_report_diagnostic
 test eax,eax
 jnz .source
 call cli_report_array_range_diagnostic
 test eax,eax
 jnz .source
 call cli_report_composite_diagnostic
 test eax,eax
 jnz .source
 call cli_report_nominal_diagnostic
 test eax,eax
 jnz .source
 call structs_enums_variants_e_tipos_do_programador_cli_report_diagnostic
 test eax,eax
 jnz .source
 call tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_report_diagnostic
 test eax,eax
 jnz .source
 call cli_report_generic_diagnostic
 test eax,eax
 jnz .source
 call generics_constraints_overload_e_dispatch_cli_report_diagnostic
 test eax,eax
 jnz .source
 call cli_report_parameters_diagnostic
 test eax,eax
 jnz .source
 call cli_report_option_diagnostic
 test eax,eax
 jnz .source
 call cli_report_result_diagnostic
 test eax,eax
 jnz .source
 call option_result_null_externo_e_erros_tipados_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call literais_numericos_bases_e_representacao_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call bindings_constantes_mutabilidade_e_definite_assignment_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call text_char_unicode_e_bytes_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call seguranca_numerica_conversoes_e_overflow_cli_report_frontend_diagnostic
 test eax,eax
 jnz .source
 call cli_report_numeric_diagnostic
 jmp .source
.frontend_ready:
 mov qword [rel cli_machine_reporting],0
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel console_visual_dashboard_e_plots_cli_found],0
 jne .generate
 cmp qword [rel rede_e_protocolos_cli_found],0
 jne .generate
 cmp qword [rel filesystem_paths_e_formatos_cli_found],0
 jne .generate
 cmp qword [rel biblioteca_padrao_por_dominios_cli_found],0
 jne .generate
 cmp qword [rel packages_registry_lockfile_e_supply_chain_cli_found],0
 jne .generate
 cmp qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel imports_modulos_namespaces_e_api_publica_cli_found],0
 jne .generate
 cmp qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],0
 jne .generate
 cmp qword [rel quality_confidence_e_lineage_cli_found],0
 jne .generate
 cmp qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],0
 jne .generate
 cmp qword [rel effects_capabilities_e_politicas_cli_found],0
 jne .generate
 cmp qword [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_struct_tuple+NEBOC_ST_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_nominal+NEBOC_NOM_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_generic+NEBOC_GEN_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_option+NEBOC_OPTION_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel cli_result+NEBOC_RESULT_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_FOUND_OFFSET],0
 je .not_semantic
 call cli_recognize_option_result
 test eax,eax
 jz .generate
 call option_result_null_externo_e_erros_tipados_cli_report_semantic_diagnostic
 jmp .source
.not_semantic:
 call cli_recognize_bindings
 test eax,eax
 jz .bindings_constantes_mutabilidade_e_definite_assignment_semantic_ready
 call bindings_constantes_mutabilidade_e_definite_assignment_cli_report_semantic_diagnostic
 jmp .source
.bindings_constantes_mutabilidade_e_definite_assignment_semantic_ready:
 call cli_recognize_text_char_bytes
 test eax,eax
 jz .text_char_unicode_e_bytes_semantic_ready
 call text_char_unicode_e_bytes_cli_report_semantic_diagnostic
 jmp .source
.text_char_unicode_e_bytes_semantic_ready:
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 jne .generate
 call cli_recognize_numeric_safety
 test eax,eax
 jz .seguranca_numerica_conversoes_e_overflow_semantic_ready
 call seguranca_numerica_conversoes_e_overflow_cli_report_semantic_diagnostic
 jmp .source
.seguranca_numerica_conversoes_e_overflow_semantic_ready:
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 jne ._materialize
 call cli_recognize_foundation_float
 test eax,eax
 jz .float_semantic_ready
 call cli_report_float_semantic_diagnostic
 jmp .source
.float_semantic_ready:
 cmp qword [rel cli_float_sem_request+NEBOC_FLOAT_SEM_FOUND_OFFSET],0
 je .generate
 ; TIPOS-PRIMITIVOS-ESCALARES-PF005 materializes and classifies every strict Float token before the
 ; public vertical codegen path. No unsupported token silently reaches NASM.
 call cli_materialize_foundation_float_vertical
 test eax,eax
 jz .generate
 call cli_report_float_literal_diagnostic
 jmp .source
._materialize:
 call cli_materialize_foundation_float_vertical
 test eax,eax
 jz .generate
 call cli_report_float_literal_diagnostic
 jmp .source
.generate:
 call cli_generate_assembly
 test eax,eax
 jz .assembly_ready
 cmp eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jne .internal
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 je .report_buffer_codegen
 call cli_report_ownership_diagnostic
 jmp .source
.report_buffer_codegen:
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 je .console_visual_dashboard_e_plots_report_codegen
 call cli_report_buffer_diagnostic
 jmp .source
.console_visual_dashboard_e_plots_report_codegen:
 cmp qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 je .report_parameter_codegen
 call cli_report_module_diagnostic
 jmp .source
.report_parameter_codegen:
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 je .numeric_safety_report_codegen_next
 call cli_report_parameters_diagnostic
 jmp .source
.numeric_safety_report_codegen_next:
 cmp qword [rel cli_result+NEBOC_RESULT_FOUND_OFFSET],0
 je .report_option_codegen
 call cli_report_result_diagnostic
 jmp .source
.report_option_codegen:
 cmp qword [rel cli_option+NEBOC_OPTION_FOUND_OFFSET],0
 je .console_visual_dashboard_e_plots_report_codegen_next
 call cli_report_option_diagnostic
 jmp .source
.console_visual_dashboard_e_plots_report_codegen_next:
 cmp qword [rel console_visual_dashboard_e_plots_cli_found],0
 je .rede_e_protocolos_report_codegen
 call console_visual_dashboard_e_plots_cli_report_frontend_diagnostic
 jmp .source
.rede_e_protocolos_report_codegen:
 cmp qword [rel rede_e_protocolos_cli_found],0
 je .filesystem_paths_e_formatos_report_codegen
 call rede_e_protocolos_cli_report_frontend_diagnostic
 jmp .source
.filesystem_paths_e_formatos_report_codegen:
 cmp qword [rel filesystem_paths_e_formatos_cli_found],0
 je .biblioteca_padrao_por_dominios_report_codegen
 call filesystem_paths_e_formatos_cli_report_frontend_diagnostic
 jmp .source
.biblioteca_padrao_por_dominios_report_codegen:
 cmp qword [rel biblioteca_padrao_por_dominios_cli_found],0
 je .packages_registry_lockfile_e_supply_chain_report_codegen
 call biblioteca_padrao_por_dominios_cli_report_frontend_diagnostic
 jmp .source
.packages_registry_lockfile_e_supply_chain_report_codegen:
 cmp qword [rel packages_registry_lockfile_e_supply_chain_cli_found],0
 je .imports_modulos_namespaces_e_api_publica_report_codegen
 call packages_registry_lockfile_e_supply_chain_cli_report_frontend_diagnostic
 jmp .source
.imports_modulos_namespaces_e_api_publica_report_codegen:
 cmp qword [rel imports_modulos_namespaces_e_api_publica_cli_found],0
 je .memoria_ownership_lifetimes_e_recursos_report_codegen
 call imports_modulos_namespaces_e_api_publica_cli_report_frontend_diagnostic
 jmp .source
.memoria_ownership_lifetimes_e_recursos_report_codegen:
 cmp qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],0
 je .quality_confidence_e_lineage_report_codegen
 call memoria_ownership_lifetimes_e_recursos_cli_report_frontend_diagnostic
 jmp .source
.quality_confidence_e_lineage_report_codegen:
 cmp qword [rel quality_confidence_e_lineage_cli_found],0
 je .privacidade_dados_sensiveis_e_zero_trust_report_codegen
 call quality_confidence_e_lineage_cli_report_frontend_diagnostic
 jmp .source
.privacidade_dados_sensiveis_e_zero_trust_report_codegen:
 cmp qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],0
 je .effects_capabilities_e_politicas_report_codegen
 call privacidade_dados_sensiveis_e_zero_trust_cli_report_frontend_diagnostic
 jmp .source
.effects_capabilities_e_politicas_report_codegen:
 cmp qword [rel effects_capabilities_e_politicas_cli_found],0
 je .source
 call effects_capabilities_e_politicas_cli_report_frontend_diagnostic
 jmp .source
.assembly_ready:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 je .success
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_EMIT_ASM
 jne .build
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 lea rsi,[rel cli_asm_output]
 mov rdx,[rel cli_state+NEBOC_CLI_STATE_ASM_LENGTH_OFFSET]
 call cli_write_file
 test eax,eax
 jnz .io
 jmp .success
.build:
 call cli_build_artifact
 test eax,eax
 jnz .report_status
.success:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_BUILD
 jne .success_check
 call cli_emit_observability
 test eax,eax
 jnz .internal
.success_check:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET],NEBOC_CLI_MODE_CHECK
 jne .success_exit
 mov rdi,[rel cli_build_events_path]
 test rdi,rdi
 jz .success_exit
 lea rsi,[rel build_events_success]
 mov edx,build_events_success_end-build_events_success
 call cli_write_file
 test eax,eax
 jnz .io
.success_exit:
 xor eax,eax
 jmp .done
.report_status:
 cmp eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 je .source
 cmp eax,NEBOC_CLI_EXIT_IO_ERROR
 je .io
 cmp eax,NEBOC_CLI_EXIT_TOOLCHAIN_ERROR
 je .toolchain
 jmp .internal
.usage:
 lea rdi,[rel cli_error_usage]
 mov esi,cli_error_usage_end-cli_error_usage
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_USAGE_ERROR
 jmp .done
.extension:
 lea rdi,[rel cli_error_extension]
 mov esi,cli_error_extension_end-cli_error_extension
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_USAGE_ERROR
 jmp .done
.output_path:
 lea rdi,[rel cli_error_output_path]
 mov esi,cli_error_output_path_end-cli_error_output_path
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_USAGE_ERROR
 jmp .done
.source:
 mov qword [rel cli_machine_reporting],0
 mov rdi,[rel cli_build_events_path]
 test rdi,rdi
 jz .source_format
 lea rsi,[rel build_events_failure]
 mov edx,build_events_failure_end-build_events_failure
 call cli_write_file
 test eax,eax
 jnz .io
.source_format:
 cmp qword [rel cli_message_format],3
 je .source_json
 cmp qword [rel cli_message_format],4
 je .source_json
 cmp qword [rel cli_message_format],5
 je .source_sarif
 lea rdi,[rel cli_error_source]
 mov esi,cli_error_source_end-cli_error_source
 call cli_write_stderr
 cmp qword [rel cli_show_fixes],1
 jne .source_human_done
 lea rdi,[rel cli_fix_preview]
 mov esi,cli_fix_preview_end-cli_fix_preview
 call cli_write_stderr_raw
.source_human_done:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.source_json:
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .source_json_lex
 cmp qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],0
 jne .source_json_lex
 lea rdi,[rel cli_json_error]
 mov esi,cli_json_error_end-cli_json_error
 call cli_write_stderr_raw
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.source_json_lex:
 lea rdi,[rel cli_json_lex_error]
 mov esi,cli_json_lex_error_end-cli_json_lex_error
 call cli_write_stderr_raw
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.source_sarif:
 lea rdi,[rel cli_sarif_error]
 mov esi,cli_sarif_error_end-cli_sarif_error
 call cli_write_stderr_raw
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.io:
 lea rdi,[rel cli_error_io]
 mov esi,cli_error_io_end-cli_error_io
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.toolchain:
 lea rdi,[rel cli_error_toolchain]
 mov esi,cli_error_toolchain_end-cli_error_toolchain
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_TOOLCHAIN_ERROR
 jmp .done
.internal:
 lea rdi,[rel cli_error_internal]
 mov esi,cli_error_internal_end-cli_error_internal
 call cli_write_stderr
 mov eax,NEBOC_CLI_EXIT_INTERNAL_ERROR
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Exact NUL-terminated argv atom comparison.
cli_arg_equals:
 xor eax,eax
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .end
 mov r8b,[rdi+rcx]
 cmp r8b,[rsi+rcx]
 jne .done
 inc rcx
 jmp .loop
.end:
 cmp byte [rdi+rdx],0
 jne .done
 mov eax,1
.done:
 ret

; Return length in RAX, or -1 when the path exceeds the bounded limit.
cli_strlen_path:
 xor eax,eax
.loop:
 cmp rax,NEBOC_CLI_PATH_CAPACITY-1
 jae .bad
 cmp byte [rdi+rax],0
 je .done
 inc rax
 jmp .loop
.bad:
 mov rax,-1
.done:
 ret


; Validate an output argv atom. Absolute and relative paths are accepted, but
; a path component equal to ".." is rejected before any file or tool action.
cli_validate_output_path:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 test rbx,rbx
 jz .bad
 call cli_strlen_path
 cmp rax,-1
 je .bad
 test rax,rax
 jz .bad
 mov r12,rax
 cmp byte [rbx],'-'
 je .bad
 xor ecx,ecx
 xor edx,edx
.scan:
 cmp rcx,r12
 jae .final_component
 mov al,[rbx+rcx]
 cmp al,10
 je .bad
 cmp al,13
 je .bad
 cmp al,'/'
 je .component
 inc rcx
 jmp .scan
.component:
 mov r8,rcx
 sub r8,rdx
 cmp r8,2
 jne .next_component
 cmp byte [rbx+rdx],'.'
 jne .next_component
 cmp byte [rbx+rdx+1],'.'
 je .bad
.next_component:
 inc rcx
 mov rdx,rcx
 jmp .scan
.final_component:
 mov r8,r12
 sub r8,rdx
 cmp r8,2
 jne .ok
 cmp byte [rbx+rdx],'.'
 jne .ok
 cmp byte [rbx+rdx+1],'.'
 je .bad
.ok:
 xor eax,eax
 add rsp,8
 pop r12
 pop rbx
 ret
.bad:
 mov eax,1
 add rsp,8
 pop r12
 pop rbx
 ret

cli_validate_no_extension:
 push rbx
 mov rbx,rdi
 call cli_strlen_path
 cmp rax,3
 jb .bad
 cmp rax,-1
 je .bad
 cmp byte [rbx+rax-3],'.'
 jne .bad
 cmp byte [rbx+rax-2],'n'
 jne .bad
 cmp byte [rbx+rax-1],'o'
 jne .bad
 xor eax,eax
 pop rbx
 ret
.bad:
 mov eax,1
 pop rbx
 ret

; Read the source into the fixed bounded buffer. Returns a public CLI exit code.
cli_read_source:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov edi,-100
 mov rsi,r12
 xor edx,edx
 xor r10d,r10d
 mov eax,257
 syscall
 cmp rax,-4095
 jae .io
 mov rbx,rax
 xor r13d,r13d
.read_loop:
 cmp r13,NEBOC_CLI_SOURCE_CAPACITY+1
 jae .too_large
 xor eax,eax
 mov rdi,rbx
 lea rsi,[rel cli_source]
 add rsi,r13
 mov rdx,NEBOC_CLI_SOURCE_CAPACITY+1
 sub rdx,r13
 syscall
 test rax,rax
 jz .eof
 js .read_error
 add r13,rax
 jmp .read_loop
.read_error:
 cmp rax,-4
 je .read_loop
 jmp .close_io
.too_large:
 mov eax,3
 mov rdi,rbx
 syscall
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.eof:
 mov eax,3
 mov rdi,rbx
 syscall
 cmp r13,NEBOC_CLI_SOURCE_CAPACITY
 ja .source
 lea rax,[rel cli_source]
 mov byte [rax+r13],0
 mov [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],r13
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.close_io:
 mov eax,3
 mov rdi,rbx
 syscall
.io:
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Validate the optional bounded --unit source paths before opening any of them.
cli_validate_module_unit_paths:
 push rbx
 xor ebx,ebx
.loop:
 cmp rbx,[rel cli_module_unit_count]
 jae .ok
 lea rdi,[rel cli_module_unit_paths]
 mov rdi,[rdi+rbx*8]
 call cli_validate_no_extension
 test eax,eax
 jnz .done
 inc rbx
 jmp .loop
.ok:
 xor eax,eax
.done:
 pop rbx
 ret

; Read zero, one or two auxiliary module units into isolated 4096-byte buffers.
cli_read_module_units:
 push rbx
 xor ebx,ebx
.loop:
 cmp rbx,[rel cli_module_unit_count]
 jae .ok
 lea rdi,[rel cli_module_unit_paths]
 mov rdi,[rdi+rbx*8]
 test ebx,ebx
 jnz .second
 lea rsi,[rel cli_module_source1]
 jmp .read
.second:
 lea rsi,[rel cli_module_source2]
.read:
 mov edx,NEBOC_MODULE_MAX_SOURCE_BYTES
 call cli_read_aux_source
 test eax,eax
 jnz .done
 lea rax,[rel cli_module_unit_lengths]
 mov [rax+rbx*8],rdx
 inc rbx
 jmp .loop
.ok:
 xor eax,eax
.done:
 pop rbx
 ret

; cli_read_aux_source(path, buffer, capacity) -> status in EAX, length in RDX.
cli_read_aux_source:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov edi,-100
 mov rsi,r12
 xor edx,edx
 xor r10d,r10d
 mov eax,257
 syscall
 cmp rax,-4095
 jae .io
 mov rbx,rax
 xor r12d,r12d
.read_loop:
 cmp r12,r14
 ja .too_large
 xor eax,eax
 mov rdi,rbx
 lea rsi,[r13+r12]
 mov rdx,r14
 inc rdx
 sub rdx,r12
 syscall
 test rax,rax
 jz .eof
 js .read_error
 add r12,rax
 jmp .read_loop
.read_error:
 cmp rax,-4
 je .read_loop
 jmp .close_io
.too_large:
 mov eax,3
 mov rdi,rbx
 syscall
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.eof:
 mov eax,3
 mov rdi,rbx
 syscall
 cmp r12,r14
 ja .source
 mov byte [r13+r12],0
 mov rdx,r12
 xor eax,eax
 jmp .done
.source:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.close_io:
 mov eax,3
 mov rdi,rbx
 syscall
.io:
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
.done:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Existing lexer/parser gate. An empty start body has no semantic/dependency work.
cli_frontend_validate:
 push rbx
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_frontend_diagnostic],0
 mov qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],0
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],0
 mov qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 mov qword [rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],0
 mov qword [rel imports_modulos_namespaces_e_api_publica_cli_frontend_diagnostic],0
 mov qword [rel imports_modulos_namespaces_e_api_publica_cli_found],0
 mov qword [rel memoria_ownership_lifetimes_e_recursos_cli_frontend_diagnostic],0
 mov qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],0
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],0
 mov qword [rel quality_confidence_e_lineage_cli_frontend_diagnostic],0
 mov qword [rel quality_confidence_e_lineage_cli_found],0
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic],0
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],0
 mov qword [rel effects_capabilities_e_politicas_cli_frontend_diagnostic],0
 mov qword [rel effects_capabilities_e_politicas_cli_found],0
 lea rdi,[rel cli_lexer_request]
 mov ecx,NEBOC_LEXER_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_ast_builder]
 mov ecx,NEBOC_AST_BUILDER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_parser_request]
 mov ecx,NEBOC_PARSER_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_lexer_request+NEBOC_LEXER_REQUEST_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_lexer_request+NEBOC_LEXER_REQUEST_LENGTH_OFFSET],rax
 mov qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_SOURCE_ID_OFFSET],1
 lea rax,[rel cli_tokens]
 mov [rel cli_lexer_request+NEBOC_LEXER_REQUEST_TOKENS_OFFSET],rax
 mov qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_CAPACITY_OFFSET],NEBOC_CLI_TOKEN_CAPACITY
 lea rax,[rel cli_literal_bytes]
 mov [rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_CAPACITY_OFFSET],NEBOC_CLI_LITERAL_CAPACITY
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 imul rax,NEBOC_LEXER_DEFAULT_STEP_FACTOR
 add rax,64
 mov [rel cli_lexer_request+NEBOC_LEXER_REQUEST_STEP_BUDGET_OFFSET],rax
 lea rdi,[rel cli_lexer_request]
 call neboc_lexer_scan
 mov ebx,eax
 ; Receiver-first F02 sources are identified by a leading signature plus an
 ; '=', ':' or Tuple marker.  Claim them before legacy token heuristics can
 ; reinterpret defaults as assignment or a returned Tuple as a top-level
 ; composite construction.
 call cli_recognize_parameters
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 je ._early_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._early_not_owned:
 call cli_recognize_modules
 cmp qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 je ._modules_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._modules_not_owned:
 call cli_recognize_buffer
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 je ._buffer_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
._buffer_not_owned:
 call cli_recognize_visual_summary
 test eax,eax
 jnz .bad
 call cli_recognize_net_port
 test eax,eax
 jnz .bad
 call cli_recognize_path_query
 test eax,eax
 jnz .bad
 call cli_recognize_std_math
 test eax,eax
 jnz .bad
 call cli_recognize_package
 test eax,eax
 jnz .bad
 call cli_recognize_module
 test eax,eax
 jnz .bad
 call memoria_ownership_lifetimes_e_recursos_cli_recognize_ownership
 test eax,eax
 jnz .bad
 call cli_recognize_quality
 test eax,eax
 jnz .bad
 call cli_recognize_privacy
 test eax,eax
 jnz .bad
 call cli_recognize_policy
 test eax,eax
 jnz .bad
 cmp qword [rel console_visual_dashboard_e_plots_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel rede_e_protocolos_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel filesystem_paths_e_formatos_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel biblioteca_padrao_por_dominios_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel packages_registry_lockfile_e_supply_chain_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel imports_modulos_namespaces_e_api_publica_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel quality_confidence_e_lineage_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 cmp qword [rel effects_capabilities_e_politicas_cli_found],0
 jne .effects_capabilities_e_politicas_frontend_owned
 call cli_recognize_mutability
 call text_char_unicode_e_bytes_cli_detect_frontend_diagnostic
 call bindings_constantes_mutabilidade_e_definite_assignment_cli_detect_frontend_diagnostic
 call cli_recognize_column
 cmp qword [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_FOUND_OFFSET],0
 je .column_row_table_e_dataset_frontend_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.effects_capabilities_e_politicas_frontend_owned:
 xor eax,eax
 pop rbx
 ret
.column_row_table_e_dataset_frontend_not_owned:
 call cli_recognize_vector
 cmp qword [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],0
 je .vetores_matrizes_tensores_e_computacao_cientifica_frontend_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.vetores_matrizes_tensores_e_computacao_cientifica_frontend_not_owned:
 call cli_recognize_result
 cmp qword [rel cli_result+NEBOC_RESULT_FOUND_OFFSET],0
 je ._result_not_owned
 test eax,eax
 jnz .bad
 cmp qword [rel cli_result+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],0
 jne ._propagation_owned
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 jmp ._result_ready
._propagation_owned:
 cmp qword [rel cli_result+NEBOC_RESULT_PROPAGATION_COUNT_OFFSET],1
 jne .bad
 ; `?` is an active canonical token, not the historical invalid-character
 ; transport used by the original bounded Result parser.
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
._result_ready:
 xor eax,eax
 pop rbx
 ret
._result_not_owned:
 call cli_recognize_option
 cmp qword [rel cli_option+NEBOC_OPTION_FOUND_OFFSET],0
 je ._option_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
._option_not_owned:
 call cli_recognize_array
 cmp qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_FOUND_OFFSET],0
 je .colecoes_primitivas_frontend_not_owned
 cmp qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_DIAGNOSTIC_OFFSET],8
 jne .colecoes_primitivas_frontend_owned
 ; Diagnostic 8 is also colecoes_primitivas's frozen open-world Array boundary. Give the cli_driver
 ; structural extension one chance to own its literal/filled Array<T,N>
 ; grammar; it deliberately declines colecoes_primitivas's exact `withCapacity` rejection.
 call cli_recognize_array_range
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 je ._fallback_not_owned
 mov qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_FOUND_OFFSET],0
 mov qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_DIAGNOSTIC_OFFSET],0
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._fallback_not_owned:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .bad
.colecoes_primitivas_frontend_owned:
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.colecoes_primitivas_frontend_not_owned:
 call cli_recognize_array_range
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 je ._array_range_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._array_range_not_owned:
 call option_result_null_externo_e_erros_tipados_cli_recognize_generic
 cmp qword [rel cli_generic+NEBOC_GEN_FOUND_OFFSET],0
 je ._generic_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
._generic_not_owned:
 ; Preserve the public generics_constraints_overload_e_dispatch ownership boundary for sources that start with the
 ; canonical `generic` declaration.  structs_enums_variants_e_tipos_do_programador owns `struct`/`enum` declarations,
 ; but must not relabel generics_constraints_overload_e_dispatch's frozen generic-aggregate rejection.
 call generics_constraints_overload_e_dispatch_cli_recognize_generic
 cmp qword [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],0
 je ._legacy_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
._legacy_not_owned:
 call cli_recognize_programmer_type
 cmp qword [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],0
 je .structs_enums_variants_e_tipos_do_programador_frontend_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.structs_enums_variants_e_tipos_do_programador_frontend_not_owned:
 call cli_recognize_nominal
 cmp qword [rel cli_nominal+NEBOC_NOM_FOUND_OFFSET],0
 je ._nominal_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
._nominal_not_owned:
 call cli_recognize_composite
 cmp qword [rel cli_struct_tuple+NEBOC_ST_FOUND_OFFSET],0
 je ._composite_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._composite_not_owned:
 call cli_recognize_domain_refinement
 cmp qword [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],0
 je .tipos_semanticos_refinamentos_unidades_e_opaque_types_frontend_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
.tipos_semanticos_refinamentos_unidades_e_opaque_types_frontend_not_owned:
 call generics_constraints_overload_e_dispatch_cli_recognize_generic
 cmp qword [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],0
 je .generics_constraints_overload_e_dispatch_frontend_not_owned
 test eax,eax
 jnz .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
.generics_constraints_overload_e_dispatch_frontend_not_owned:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_parse_request]
 mov ecx,NEBOC_VPARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_operations]
 mov ecx,(NEBOC_VERTICAL_MAX_OPERATIONS*NEBOC_VOP_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_operations]
 mov [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_OPERATIONS_OFFSET],rax
 mov qword [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_OPERATION_CAPACITY_OFFSET],NEBOC_VERTICAL_MAX_OPERATIONS
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_parse_request]
 call neboc_option_result_vertical_parse
 mov [rel cli_frontend_status],rax
 cmp qword [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_FOUND_OFFSET],0
 je .option_result_null_externo_e_erros_tipados_frontend_not_owned
 cmp qword [rel cli_frontend_status],0
 jne .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 xor eax,eax
 pop rbx
 ret
.option_result_null_externo_e_erros_tipados_frontend_not_owned:
 cmp qword [rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET],0
 jne .bad
 test ebx,ebx
 jnz .bad
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .bad
 call cli_detect_cast_syntax
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_ast_builder]
 lea rsi,[rel cli_ast_nodes]
 mov edx,NEBOC_CLI_AST_CAPACITY
 call neboc_ast_builder_init
 test eax,eax
 jnz .bad
 lea rax,[rel cli_tokens]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKEN_COUNT_OFFSET],rax
 mov qword [rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET],1
 lea rax,[rel cli_ast_builder]
 mov [rel cli_parser_request+NEBOC_PARSER_BUILDER_OFFSET],rax
 mov qword [rel cli_parser_request+NEBOC_PARSER_MAX_NESTING_OFFSET],NEBOC_PARSER_DEFAULT_MAX_NESTING
 lea rdi,[rel cli_parser_request]
 call neboc_parser_parse
 test eax,eax
 jnz .bad
 call cli_materialize_start_body
 test eax,eax
 jnz .bad
 call cli_materialize_function_bodies
 test eax,eax
 jnz .bad
 call text_char_unicode_e_bytes_cli_recognize_ownership
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
.bad:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 pop rbx
 ret

; TEXT-CHAR-UNICODE-E-BYTES-F02 composes the general AST with a dedicated ownership resolver
; and authenticated lowering plan.  Sources without ownership calls remain on
; their historical verticals byte-for-byte.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
text_char_unicode_e_bytes_cli_recognize_ownership:
 lea rdi,[rel text_char_unicode_e_bytes_cli_semantic]
 mov ecx,neboc_text_char_unicode_e_bytes_SEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 cmp qword [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_FOUND_OFFSET],0
 jne .scalar
 lea rax,[rel cli_source]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_ROOT_ID_OFFSET],rax
 lea rax,[rel text_char_unicode_e_bytes_cli_symbols]
 mov [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SYMBOLS_OFFSET],rax
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SYMBOL_CAPACITY_OFFSET],NEBOC_SEM_MAX_SYMBOLS
 lea rdi,[rel text_char_unicode_e_bytes_cli_semantic]
 call neboc_move_copy_clone_recognize
 test eax,eax
 jz .recognized
 ; text_char_unicode_e_bytes historically claimed every structural loop. F06 lets the literais_numericos_bases_e_representacao scalar
 ; vertical own loop/control trees that carry no text_char_unicode_e_bytes ownership symbol while
 ; retaining the established text_char_unicode_e_bytes route for ownership-bearing cleanup sources.
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 je .done
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SYMBOL_COUNT_OFFSET],0
 jne .done
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_CLONE_UNAVAILABLE
 jne .done
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],0
 xor eax,eax
 jmp .done
.recognized:
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 je .done
 ; A structural scalar loop may be a successful text_char_unicode_e_bytes recognition even though
 ; it has no ownership symbols.  Delegate that case to literais_numericos_bases_e_representacao before lowering;
 ; ownership-bearing loops retain the established text_char_unicode_e_bytes cleanup route.
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_SYMBOL_COUNT_OFFSET],0
 jne .ownership_found
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],0
 xor eax,eax
 jmp .done
.ownership_found:
 lea rdi,[rel text_char_unicode_e_bytes_cli_semantic]
 lea rsi,[rel text_char_unicode_e_bytes_cli_plan]
 call neboc_move_copy_clone_lower
 test eax,eax
 jz .done
 mov qword [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret
.scalar:
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_ownership_diagnostic:
 mov rax,[rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_DIAG_USE_AFTER_MOVE
 je .use_after_move
 cmp rax,NEBOC_DIAG_DOUBLE_DROP
 je .double_drop
 cmp rax,NEBOC_DIAG_BORROW_CONFLICT
 je .borrow_conflict
 cmp rax,NEBOC_DIAG_MOVE_WHILE_BORROWED
 je .move_while_borrowed
 cmp rax,NEBOC_DIAG_BORROW_ESCAPE
 je .borrow_escape
 cmp rax,NEBOC_DIAG_COPY_UNIQUE
 je .copy_unique
 cmp rax,NEBOC_DIAG_CLONE_UNAVAILABLE
 je .clone
 cmp rax,NEBOC_DIAG_RESOURCE_LEAK_PATH
 je .leak
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_internal]
 mov esi,text_char_unicode_e_bytes_cli_error_internal_end-text_char_unicode_e_bytes_cli_error_internal
 jmp .write
.use_after_move:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_001]
 mov esi,text_char_unicode_e_bytes_cli_error_001_end-text_char_unicode_e_bytes_cli_error_001
 jmp .write
.double_drop:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_002]
 mov esi,text_char_unicode_e_bytes_cli_error_002_end-text_char_unicode_e_bytes_cli_error_002
 jmp .write
.borrow_conflict:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_003]
 mov esi,text_char_unicode_e_bytes_cli_error_003_end-text_char_unicode_e_bytes_cli_error_003
 jmp .write
.move_while_borrowed:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_004]
 mov esi,text_char_unicode_e_bytes_cli_error_004_end-text_char_unicode_e_bytes_cli_error_004
 jmp .write
.borrow_escape:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_005]
 mov esi,text_char_unicode_e_bytes_cli_error_005_end-text_char_unicode_e_bytes_cli_error_005
 jmp .write
.copy_unique:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_006]
 mov esi,text_char_unicode_e_bytes_cli_error_006_end-text_char_unicode_e_bytes_cli_error_006
 jmp .write
.clone:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_007]
 mov esi,text_char_unicode_e_bytes_cli_error_007_end-text_char_unicode_e_bytes_cli_error_007
 jmp .write
.leak:
 lea rdi,[rel text_char_unicode_e_bytes_cli_error_013]
 mov esi,text_char_unicode_e_bytes_cli_error_013_end-text_char_unicode_e_bytes_cli_error_013
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret



; Detect bindings_constantes_mutabilidade_e_definite_assignment deferred spellings that would otherwise fail before the public
; binding semantic pass can issue its stable diagnostic.
%undef call
bindings_constantes_mutabilidade_e_definite_assignment_cli_detect_frontend_diagnostic:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .none
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 mov r14,rax
 mov rcx,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_RESERVED_EQUAL
 je .assignment
 cmp rcx,NEBOC_TOKEN_RESERVED_COLON
 je .named
 cmp rcx,NEBOC_TOKEN_INVALID_IDENTIFIER
 je .invalid
 cmp rcx,NEBOC_TOKEN_IDENTIFIER
 jne .reserved_start
 mov rdi,r14
 lea rsi,[rel cli_name_const]
 mov edx,cli_name_const_len
 call cli_token_equals
 test eax,eax
 jnz .const
 mov rdi,r14
 lea rsi,[rel cli_name_mut]
 mov edx,cli_name_mut_len
 call cli_token_equals
 test eax,eax
 jnz .mutable
.reserved_start:
 mov rcx,[r14+NEBOC_TOKEN_KIND_OFFSET]
 cmp r13,0
 je .next
 cmp rcx,NEBOC_TOKEN_KW_START
 jne .next
 mov rax,r13
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 je .reserved
.next:
 inc r13
 jmp .loop
.assignment:
 cmp qword [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_FOUND_OFFSET],0
 jne .next
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_ASSIGNMENT_SYNTAX_UNAVAILABLE
 jmp .yes
.named: mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_NAMED_ARGUMENTS_DEFERRED
 jmp .yes
.invalid: mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_INVALID_NAME
 jmp .yes
.const: mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_CONST_DECLARATION_DEFERRED
 jmp .yes
.mutable:
 cmp qword [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_FOUND_OFFSET],0
 jne .next
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_MUTABLE_DECLARATION_DEFERRED
 jmp .yes
.reserved: mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],NEBOC_BIND_DIAG_RESERVED_NAME
.yes: mov eax,1
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; token pointer, bytes, length -> 1/0
cli_token_equals:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r12+NEBOC_TOKEN_START_OFFSET]
 cmp rax,r14
 jne .no
 lea rbx,[rel cli_source]
 add rbx,[r12+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r14
 jae .yes
 mov al,[rbx+rcx]
 cmp al,[r13+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

bindings_constantes_mutabilidade_e_definite_assignment_cli_report_frontend_diagnostic:
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 jmp bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code
.none: xor eax,eax
 ret

cli_recognize_mutability:
 lea rdi,[rel literais_numericos_bases_e_representacao_cli_parse_request]
 mov ecx,neboc_literais_numericos_bases_e_representacao_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel literais_numericos_bases_e_representacao_cli_parse_request]
 jmp neboc_mutable_assignment_recognize

literais_numericos_bases_e_representacao_cli_report_frontend_diagnostic:
 mov rax,[rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET]
 jmp literais_numericos_bases_e_representacao_cli_report_diagnostic_code

; biblioteca_padrao_por_dominios owns the bounded std.math family and its explicitly rejected aliases.
cli_recognize_std_math:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,4
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'s'
 je .std_tail
 cmp al,'S'
 je .std_tail
 cmp al,'m'
 jne .none
 cmp qword [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],5
 jb .none
 cmp byte [rbx+1],'a'
 jne .none
 cmp byte [rbx+2],'t'
 jne .none
 cmp byte [rbx+3],'h'
 jne .none
 cmp byte [rbx+4],'.'
 jne .none
 jmp .owned
.std_tail:
 cmp byte [rbx+1],'t'
 jne .none
 cmp byte [rbx+2],'d'
 jne .none
 cmp byte [rbx+3],'.'
 jne .none
.owned:
 mov qword [rel biblioteca_padrao_por_dominios_cli_found],1
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_parse_request]
 mov ecx,neboc_biblioteca_padrao_por_dominios_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_syntax]
 mov ecx,(neboc_biblioteca_padrao_por_dominios_SYNTAX_SIZE+neboc_biblioteca_padrao_por_dominios_RECORD_SIZE+neboc_biblioteca_padrao_por_dominios_SEM_SIZE+neboc_biblioteca_padrao_por_dominios_IR_SIZE+neboc_biblioteca_padrao_por_dominios_NATIVE_SIZE+neboc_biblioteca_padrao_por_dominios_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel biblioteca_padrao_por_dominios_cli_parse_request+neboc_biblioteca_padrao_por_dominios_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel biblioteca_padrao_por_dominios_cli_parse_request+neboc_biblioteca_padrao_por_dominios_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel biblioteca_padrao_por_dominios_cli_syntax]
 mov [rel biblioteca_padrao_por_dominios_cli_parse_request+neboc_biblioteca_padrao_por_dominios_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_parse_request]
 call neboc_std_math_parse
 test eax,eax
 jnz .parser
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_authority]
 mov rsi,[rel biblioteca_padrao_por_dominios_cli_syntax+neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET]
 mov rdx,[rel biblioteca_padrao_por_dominios_cli_syntax+neboc_biblioteca_padrao_por_dominios_SYNTAX_VALUE_OFFSET]
 mov rcx,[rel biblioteca_padrao_por_dominios_cli_syntax+NEBOC_SYNTAX_LOWER_OFFSET]
 mov r8,[rel biblioteca_padrao_por_dominios_cli_syntax+NEBOC_SYNTAX_UPPER_OFFSET]
 mov r9d,neboc_biblioteca_padrao_por_dominios_REQUIRED_FLAGS
 call neboc_std_math_init
 test eax,eax
 jnz .type
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_syntax]
 lea rsi,[rel biblioteca_padrao_por_dominios_cli_authority]
 lea rdx,[rel biblioteca_padrao_por_dominios_cli_semantic]
 call neboc_std_math_semantic_build
 test eax,eax
 jnz .semantic
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_semantic]
 lea rsi,[rel biblioteca_padrao_por_dominios_cli_ir]
 call neboc_std_math_ir_lower
 test eax,eax
 jnz .ir
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_ir]
 lea rsi,[rel biblioteca_padrao_por_dominios_cli_plan]
 call neboc_std_math_native_lower
 test eax,eax
 jnz .native
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_plan]
 lea rsi,[rel biblioteca_padrao_por_dominios_cli_runtime_state]
 call neboc_std_math_runtime_execute
 test eax,eax
 jnz .runtime
 xor eax,eax
 jmp .done
.parser:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_parse_request+neboc_biblioteca_padrao_por_dominios_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.type:
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_semantic+neboc_biblioteca_padrao_por_dominios_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_ir+neboc_biblioteca_padrao_por_dominios_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
 jmp .publish
.native:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_plan+neboc_biblioteca_padrao_por_dominios_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_CODEGEN_codegen_stdlib_x86_64
 jmp .publish
.runtime:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_runtime_state+neboc_biblioteca_padrao_por_dominios_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_biblioteca_padrao_por_dominios_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel biblioteca_padrao_por_dominios_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
biblioteca_padrao_por_dominios_cli_report_frontend_diagnostic:
 mov rax,[rel biblioteca_padrao_por_dominios_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,neboc_biblioteca_padrao_por_dominios_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_biblioteca_padrao_por_dominios_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_biblioteca_padrao_por_dominios_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_biblioteca_padrao_por_dominios_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_biblioteca_padrao_por_dominios_DIAG_SECURITY_codegen_stdlib_x86_64
 je .security
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_codegen]
 mov esi,biblioteca_padrao_por_dominios_cli_error_codegen_end-biblioteca_padrao_por_dominios_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_lex]
 mov esi,biblioteca_padrao_por_dominios_cli_error_lex_end-biblioteca_padrao_por_dominios_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_parse]
 mov esi,biblioteca_padrao_por_dominios_cli_error_parse_end-biblioteca_padrao_por_dominios_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_type]
 mov esi,biblioteca_padrao_por_dominios_cli_error_type_end-biblioteca_padrao_por_dominios_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_runtime]
 mov esi,biblioteca_padrao_por_dominios_cli_error_runtime_end-biblioteca_padrao_por_dominios_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_error_security]
 mov esi,biblioteca_padrao_por_dominios_cli_error_security_end-biblioteca_padrao_por_dominios_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; packages_registry_lockfile_e_supply_chain owns the exact bounded offline package manifest family.
%undef call
cli_recognize_package:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,7
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'p'
 je .tail
 cmp al,'P'
 jne .none
.tail:
 cmp byte [rbx+1],'a'
 jne .none
 cmp byte [rbx+2],'c'
 jne .none
 cmp byte [rbx+3],'k'
 jne .none
 cmp byte [rbx+4],'a'
 jne .none
 cmp byte [rbx+5],'g'
 jne .none
 cmp byte [rbx+6],'e'
 jne .none
 mov qword [rel packages_registry_lockfile_e_supply_chain_cli_found],1
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_parse_request]
 mov ecx,neboc_packages_registry_lockfile_e_supply_chain_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_syntax]
 mov ecx,(neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_SIZE+neboc_packages_registry_lockfile_e_supply_chain_RECORD_SIZE+neboc_packages_registry_lockfile_e_supply_chain_SEM_SIZE+neboc_packages_registry_lockfile_e_supply_chain_IR_SIZE+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_SIZE+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel packages_registry_lockfile_e_supply_chain_cli_parse_request+neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel packages_registry_lockfile_e_supply_chain_cli_parse_request+neboc_packages_registry_lockfile_e_supply_chain_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel packages_registry_lockfile_e_supply_chain_cli_syntax]
 mov [rel packages_registry_lockfile_e_supply_chain_cli_parse_request+neboc_packages_registry_lockfile_e_supply_chain_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_parse_request]
 call neboc_package_manifest_parse
 test eax,eax
 jnz .parser
 lea rdi,[rel cli_lock]
 mov rsi,[rel packages_registry_lockfile_e_supply_chain_cli_syntax+neboc_packages_registry_lockfile_e_supply_chain_SYNTAX_PACKAGE_ID_OFFSET]
 mov rdx,[rel packages_registry_lockfile_e_supply_chain_cli_syntax+NEBOC_SYNTAX_DEPENDENCY_ID_OFFSET]
 mov rcx,[rel packages_registry_lockfile_e_supply_chain_cli_syntax+NEBOC_SYNTAX_VERSION_OFFSET]
 mov r8,[rel packages_registry_lockfile_e_supply_chain_cli_syntax+NEBOC_SYNTAX_DIGEST_OFFSET]
 mov r9d,neboc_packages_registry_lockfile_e_supply_chain_REQUIRED_FLAGS
 call neboc_package_lock_init
 test eax,eax
 jnz .type
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_syntax]
 lea rsi,[rel cli_lock]
 lea rdx,[rel packages_registry_lockfile_e_supply_chain_cli_semantic]
 call neboc_package_semantic_build
 test eax,eax
 jnz .semantic
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_semantic]
 lea rsi,[rel packages_registry_lockfile_e_supply_chain_cli_ir]
 call neboc_package_ir_lower
 test eax,eax
 jnz .ir
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_ir]
 lea rsi,[rel packages_registry_lockfile_e_supply_chain_cli_plan]
 call neboc_package_native_lower
 test eax,eax
 jnz .native
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_plan]
 lea rsi,[rel packages_registry_lockfile_e_supply_chain_cli_runtime_state]
 call neboc_package_runtime_execute
 test eax,eax
 jnz .runtime
 xor eax,eax
 jmp .done
.parser:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_parse_request+neboc_packages_registry_lockfile_e_supply_chain_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.type:
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_semantic+neboc_packages_registry_lockfile_e_supply_chain_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_ir+neboc_packages_registry_lockfile_e_supply_chain_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
 jmp .publish
.native:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_plan+neboc_packages_registry_lockfile_e_supply_chain_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_CODEGEN_codegen_package_x86_64
 jmp .publish
.runtime:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_runtime_state+neboc_packages_registry_lockfile_e_supply_chain_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel packages_registry_lockfile_e_supply_chain_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
packages_registry_lockfile_e_supply_chain_cli_report_frontend_diagnostic:
 mov rax,[rel packages_registry_lockfile_e_supply_chain_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_packages_registry_lockfile_e_supply_chain_DIAG_SECURITY_codegen_package_x86_64
 je .security
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_codegen]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_codegen_end-packages_registry_lockfile_e_supply_chain_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_lex]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_lex_end-packages_registry_lockfile_e_supply_chain_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_parse]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_parse_end-packages_registry_lockfile_e_supply_chain_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_type]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_type_end-packages_registry_lockfile_e_supply_chain_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_runtime]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_runtime_end-packages_registry_lockfile_e_supply_chain_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_error_security]
 mov esi,packages_registry_lockfile_e_supply_chain_cli_error_security_end-packages_registry_lockfile_e_supply_chain_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-F05 owns explicit three-unit compilations selected with two --unit
; arguments.  imports_modulos_namespaces_e_api_publica remains the historical single-statement module vertical.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_modules:
 cmp qword [rel cli_module_unit_count],0
 je .none
 lea rdi,[rel cli_module_request]
 mov ecx,NEBOC_MODULE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_module_records]
 mov ecx,(NEBOC_MODULE_MAX_UNITS*NEBOC_MODULE_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_module_plan]
 mov ecx,NEBOC_MODULE_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_module_request+NEBOC_MODULE_SOURCE0_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_module_request+NEBOC_MODULE_LENGTH0_OFFSET],rax
 lea rax,[rel cli_module_source1]
 mov [rel cli_module_request+NEBOC_MODULE_SOURCE1_OFFSET],rax
 mov rax,[rel cli_module_unit_lengths]
 mov [rel cli_module_request+NEBOC_MODULE_LENGTH1_OFFSET],rax
 lea rax,[rel cli_module_source2]
 mov [rel cli_module_request+NEBOC_MODULE_SOURCE2_OFFSET],rax
 mov rax,[rel cli_module_unit_lengths+8]
 mov [rel cli_module_request+NEBOC_MODULE_LENGTH2_OFFSET],rax
 lea rax,[rel cli_module_records]
 mov [rel cli_module_request+NEBOC_MODULE_RECORDS_OFFSET],rax
 mov qword [rel cli_module_request+NEBOC_MODULE_CAPACITY_OFFSET],NEBOC_MODULE_MAX_UNITS
 lea rdi,[rel cli_module_request]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_parse
 test eax,eax
 jnz .failed
 lea rdi,[rel cli_module_request]
 call neboc_module_analyze
 test eax,eax
 jnz .failed
 lea rdi,[rel cli_module_request]
 lea rsi,[rel cli_module_plan]
 call neboc_module_lower
 test eax,eax
 jnz .lower_failed
 xor eax,eax
 ret
.lower_failed:
 cmp qword [rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],0
 jne .failed
 mov qword [rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],NEBOC_MODULE_DIAG_INTERNAL
.failed:
 cmp qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 jne .return_failure
 mov qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],1
.return_failure:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.none:
 mov qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_module_diagnostic:
 mov rax,[rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_MISSING_UNIT
 je .missing_unit
 cmp rax,NEBOC_MODULE_DIAG_PRIVATE_ACCESS
 je .private_access
 cmp rax,NEBOC_MODULE_DIAG_IMPORT_CYCLE
 je .cycle
 cmp rax,NEBOC_MODULE_DIAG_IDENTITY_COLLISION
 je .identity
 cmp rax,NEBOC_MODULE_DIAG_MISSING_EXPORT
 je .missing_export
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_MODULE_DIAG_CAPACITY
 je .capacity
 cmp rax,NEBOC_MODULE_DIAG_SYNTAX
 je .syntax
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_internal]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_internal_end-seguranca_numerica_conversoes_e_overflow_cli_error_internal
 jmp .write
.missing_unit:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_021]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_021_end-seguranca_numerica_conversoes_e_overflow_cli_error_021
 jmp .write
.private_access:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_022]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_022_end-seguranca_numerica_conversoes_e_overflow_cli_error_022
 jmp .write
.cycle:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_023]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_023_end-seguranca_numerica_conversoes_e_overflow_cli_error_023
 jmp .write
.identity:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_008]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_008_end-seguranca_numerica_conversoes_e_overflow_cli_error_008
 jmp .write
.missing_export:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_024]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_024_end-seguranca_numerica_conversoes_e_overflow_cli_error_024
 jmp .write
.capacity:
 lea rdi,[rel cli_error_025]
 mov esi,cli_error_025_end-cli_error_025
 jmp .write
.syntax:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_016]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_016_end-seguranca_numerica_conversoes_e_overflow_cli_error_016
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; imports_modulos_namespaces_e_api_publica owns the exact raw bounded module/import family beginning with module.
; The public profile resolves against one immutable built-in export table:
; module 2501, package 25, symbols 251/252/253.
%undef call
cli_recognize_module:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,6
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'m'
 je .prefix_tail
 cmp al,'M'
 jne .none
.prefix_tail:
 cmp byte [rbx+1],'o'
 jne .none
 cmp byte [rbx+2],'d'
 jne .none
 cmp byte [rbx+3],'u'
 jne .none
 cmp byte [rbx+4],'l'
 jne .none
 cmp byte [rbx+5],'e'
 jne .none
 mov qword [rel imports_modulos_namespaces_e_api_publica_cli_found],1
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_parse_request]
 mov ecx,neboc_imports_modulos_namespaces_e_api_publica_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_syntax]
 mov ecx,(neboc_imports_modulos_namespaces_e_api_publica_SYNTAX_SIZE+neboc_imports_modulos_namespaces_e_api_publica_RECORD_SIZE+neboc_imports_modulos_namespaces_e_api_publica_SEM_SIZE+neboc_imports_modulos_namespaces_e_api_publica_IR_SIZE+neboc_imports_modulos_namespaces_e_api_publica_NATIVE_SIZE+neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel imports_modulos_namespaces_e_api_publica_cli_parse_request+neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel imports_modulos_namespaces_e_api_publica_cli_parse_request+neboc_imports_modulos_namespaces_e_api_publica_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel imports_modulos_namespaces_e_api_publica_cli_syntax]
 mov [rel imports_modulos_namespaces_e_api_publica_cli_parse_request+neboc_imports_modulos_namespaces_e_api_publica_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_parse_request]
 call neboc_imports_modulos_namespaces_e_api_publica_module_parse
 test eax,eax
 jnz .parser_rejected
 lea rdi,[rel cli_table]
 mov esi,2501
 mov edx,25
 mov ecx,251
 mov r8d,252
 mov r9d,253
 call neboc_module_visibility_init
 test eax,eax
 jnz .state_rejected
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_syntax]
 lea rsi,[rel cli_table]
 lea rdx,[rel imports_modulos_namespaces_e_api_publica_cli_semantic]
 call neboc_module_semantic_build
 test eax,eax
 jnz .semantic_rejected
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_semantic]
 lea rsi,[rel imports_modulos_namespaces_e_api_publica_cli_ir]
 call neboc_module_ir_lower
 test eax,eax
 jnz .ir_rejected
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_ir]
 lea rsi,[rel imports_modulos_namespaces_e_api_publica_cli_plan]
 call neboc_module_native_lower
 test eax,eax
 jnz .native_rejected
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_plan]
 lea rsi,[rel imports_modulos_namespaces_e_api_publica_cli_runtime_state]
 call neboc_module_runtime_execute
 test eax,eax
 jnz .runtime_rejected
 xor eax,eax
 jmp .done
.parser_rejected:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_parse_request+neboc_imports_modulos_namespaces_e_api_publica_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.state_rejected:
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic_rejected:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_semantic+neboc_imports_modulos_namespaces_e_api_publica_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir_rejected:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_ir+neboc_imports_modulos_namespaces_e_api_publica_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.native_rejected:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_plan+neboc_imports_modulos_namespaces_e_api_publica_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_CODEGEN_codegen_modules_x86_64
 jmp .publish
.runtime_rejected:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_runtime_state+neboc_imports_modulos_namespaces_e_api_publica_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel imports_modulos_namespaces_e_api_publica_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
imports_modulos_namespaces_e_api_publica_cli_report_frontend_diagnostic:
 mov rax,[rel imports_modulos_namespaces_e_api_publica_cli_frontend_diagnostic]
 test rax,rax
 je .none
 cmp rax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_imports_modulos_namespaces_e_api_publica_DIAG_SECURITY_codegen_modules_x86_64
 je .security
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_codegen]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_codegen_end-imports_modulos_namespaces_e_api_publica_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_lex]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_lex_end-imports_modulos_namespaces_e_api_publica_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_parse]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_parse_end-imports_modulos_namespaces_e_api_publica_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_type]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_type_end-imports_modulos_namespaces_e_api_publica_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_runtime]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_runtime_end-imports_modulos_namespaces_e_api_publica_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_error_security]
 mov esi,imports_modulos_namespaces_e_api_publica_cli_error_security_end-imports_modulos_namespaces_e_api_publica_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; memoria_ownership_lifetimes_e_recursos owns the exact raw bounded declaration family beginning with resource.
; It composes PF001..PF004 before publishing the front as recognized.
%undef call
memoria_ownership_lifetimes_e_recursos_cli_recognize_ownership:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,8
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'r'
 je .prefix_tail
 cmp al,'R'
 jne .none
.prefix_tail:
 cmp byte [rbx+1],'e'
 jne .none
 cmp byte [rbx+2],'s'
 jne .none
 cmp byte [rbx+3],'o'
 jne .none
 cmp byte [rbx+4],'u'
 jne .none
 cmp byte [rbx+5],'r'
 jne .none
 cmp byte [rbx+6],'c'
 jne .none
 cmp byte [rbx+7],'e'
 jne .none
 mov qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],1
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_parse_request]
 mov ecx,neboc_memoria_ownership_lifetimes_e_recursos_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 mov ecx,neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_parse_request+neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_parse_request+neboc_memoria_ownership_lifetimes_e_recursos_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_parse_request+neboc_memoria_ownership_lifetimes_e_recursos_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_parse_request]
 call neboc_ownership_parse
 test eax,eax
 jnz .parser_rejected
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+NEBOC_SEMANTIC_STATE_OFFSET]
 mov esi,NEBOC_OP_INIT
 mov rdx,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+NEBOC_SYNTAX_OWNER_TOKEN_OFFSET]
 mov rcx,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+NEBOC_SYNTAX_OWNER_REGION_OFFSET]
 mov r8,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+NEBOC_SYNTAX_RESOURCE_ID_OFFSET]
 call neboc_ownership_transition
 test eax,eax
 jnz .state_rejected
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 call neboc_ownership_semantic_analyze
 test eax,eax
 jnz .semantic_rejected
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 call neboc_ownership_ir_lower
 test eax,eax
 jnz .ir_rejected
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 call neboc_ownership_native_lower
 test eax,eax
 jnz .native_rejected
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 call neboc_ownership_runtime_execute
 test eax,eax
 jnz .runtime_rejected
 xor eax,eax
 jmp .done
.parser_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_parse_request+neboc_memoria_ownership_lifetimes_e_recursos_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.state_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+NEBOC_SEMANTIC_STATE_OFFSET+neboc_memoria_ownership_lifetimes_e_recursos_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
 jmp .publish
.semantic_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+neboc_memoria_ownership_lifetimes_e_recursos_SEMANTIC_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
 jmp .publish
.ir_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+neboc_memoria_ownership_lifetimes_e_recursos_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
 jmp .publish
.native_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+neboc_memoria_ownership_lifetimes_e_recursos_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_CODEGEN_codegen_memory_x86_64
 jmp .publish
.runtime_rejected:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request+neboc_memoria_ownership_lifetimes_e_recursos_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
memoria_ownership_lifetimes_e_recursos_cli_report_frontend_diagnostic:
 mov rax,[rel memoria_ownership_lifetimes_e_recursos_cli_frontend_diagnostic]
 test rax,rax
 je .none
 cmp rax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_TYPE_codegen_memory_x86_64
 je .type
 cmp rax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_SECURITY_codegen_memory_x86_64
 je .security
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_codegen]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_codegen_end-memoria_ownership_lifetimes_e_recursos_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_lex]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_lex_end-memoria_ownership_lifetimes_e_recursos_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_parse]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_parse_end-memoria_ownership_lifetimes_e_recursos_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_type]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_type_end-memoria_ownership_lifetimes_e_recursos_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_runtime]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_runtime_end-memoria_ownership_lifetimes_e_recursos_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_error_security]
 mov esi,memoria_ownership_lifetimes_e_recursos_cli_error_security_end-memoria_ownership_lifetimes_e_recursos_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; quality_confidence_e_lineage owns only the first expression in start() when its leading name is the
; canonical Quality atom or the frozen lower-case negative alias. PF005 now
; composes the exact parser, semantic, IR, native and runtime owners.
%undef call
cli_recognize_quality:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 cmp r12,5
 jb .none
 cmp qword [rbx+0*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .none
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .none
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .none
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne .none
 lea r14,[rbx+4*NEBOC_TOKEN_SIZE]
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .none
 mov rdi,r14
 lea rsi,[rel cli_name_quality]
 mov edx,cli_name_quality_len
 call cli_token_equals
 test eax,eax
 jnz .found
 mov rdi,r14
 lea rsi,[rel cli_name_quality_alias]
 mov edx,cli_name_quality_alias_len
 call cli_token_equals
 test eax,eax
 jz .none
.found:
 mov qword [rel quality_confidence_e_lineage_cli_found],1
 lea rdi,[rel quality_confidence_e_lineage_cli_parse_request]
 mov ecx,neboc_quality_confidence_e_lineage_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_parse_result]
 mov ecx,neboc_quality_confidence_e_lineage_RESULT_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel quality_confidence_e_lineage_cli_parse_request+neboc_quality_confidence_e_lineage_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel quality_confidence_e_lineage_cli_parse_request+neboc_quality_confidence_e_lineage_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_parse_result]
 mov [rel quality_confidence_e_lineage_cli_parse_request+neboc_quality_confidence_e_lineage_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel quality_confidence_e_lineage_cli_parse_request]
 call neboc_quality_parse
 test eax,eax
 jnz .parser_rejected

 lea rdi,[rel quality_confidence_e_lineage_cli_native_request]
 mov ecx,neboc_quality_confidence_e_lineage_NATIVE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rsi,[rel cli_parse_result]
 lea rdi,[rel quality_confidence_e_lineage_cli_native_request]
 mov ecx,neboc_quality_confidence_e_lineage_RESULT_QWORDS
 rep movsq
 mov qword [rel quality_confidence_e_lineage_cli_native_request+NEBOC_SEMANTIC_QUALITY_OFFSET+NEBOC_POLICY_PERMIT_OFFSET],23
 mov qword [rel quality_confidence_e_lineage_cli_native_request+NEBOC_SEMANTIC_QUALITY_OFFSET+NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET],1
 lea rdi,[rel quality_confidence_e_lineage_cli_native_request]
 call neboc_quality_semantic_analyze
 test eax,eax
 jnz .semantic_rejected
 lea rdi,[rel quality_confidence_e_lineage_cli_native_request]
 call neboc_quality_ir_lower
 test eax,eax
 jnz .ir_rejected
 lea rdi,[rel quality_confidence_e_lineage_cli_native_request]
 call neboc_quality_native_lower
 test eax,eax
 jnz .native_rejected

 lea rdi,[rel quality_confidence_e_lineage_cli_runtime_request]
 mov ecx,neboc_quality_confidence_e_lineage_RUNTIME_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+neboc_quality_confidence_e_lineage_NATIVE_HASH_OFFSET]
 mov [rel quality_confidence_e_lineage_cli_runtime_request+neboc_quality_confidence_e_lineage_RUNTIME_PLAN_HASH_OFFSET],rax
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+NEBOC_NATIVE_EFFECTIVE_QUALITY_OFFSET]
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_REQUIRED_QUALITY_OFFSET],rax
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_OBSERVED_QUALITY_OFFSET],rax
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+NEBOC_NATIVE_EFFECTIVE_CONFIDENCE_OFFSET]
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_REQUIRED_CONFIDENCE_OFFSET],rax
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_OBSERVED_CONFIDENCE_OFFSET],rax
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+NEBOC_NATIVE_LINEAGE_HASH_OFFSET]
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_EXPECTED_LINEAGE_OFFSET],rax
 mov [rel quality_confidence_e_lineage_cli_runtime_request+NEBOC_RUNTIME_OBSERVED_LINEAGE_OFFSET],rax
 lea rdi,[rel quality_confidence_e_lineage_cli_runtime_request]
 call neboc_quality_runtime_gate
 test eax,eax
 jnz .runtime_rejected
 xor eax,eax
 jmp .done
.semantic_rejected:
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+NEBOC_SEMANTIC_QUALITY_OFFSET+neboc_quality_confidence_e_lineage_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
 jmp .pipeline_publish
.ir_rejected:
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+neboc_quality_confidence_e_lineage_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
 jmp .pipeline_publish
.native_rejected:
 mov rax,[rel quality_confidence_e_lineage_cli_native_request+neboc_quality_confidence_e_lineage_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
 jmp .pipeline_publish
.runtime_rejected:
 mov rax,[rel quality_confidence_e_lineage_cli_runtime_request+neboc_quality_confidence_e_lineage_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64
.pipeline_publish:
 mov [rel quality_confidence_e_lineage_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.parser_rejected:
 mov rax,[rel quality_confidence_e_lineage_cli_parse_request+neboc_quality_confidence_e_lineage_PARSE_DIAGNOSTIC_OFFSET]
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_LEX_driver_cli_linux_x86_64
 je .publish
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64
 je .publish
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
 je .publish
 mov eax,neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64
.publish:
 mov [rel quality_confidence_e_lineage_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
quality_confidence_e_lineage_cli_report_frontend_diagnostic:
 mov rax,[rel quality_confidence_e_lineage_cli_frontend_diagnostic]
 test rax,rax
 je .none
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_TYPE_codegen_quality_x86_64
 je .type
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_quality_confidence_e_lineage_DIAG_SECURITY_codegen_quality_x86_64
 je .security
 lea rdi,[rel quality_confidence_e_lineage_cli_error_codegen]
 mov esi,quality_confidence_e_lineage_cli_error_codegen_end-quality_confidence_e_lineage_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel quality_confidence_e_lineage_cli_error_lex]
 mov esi,quality_confidence_e_lineage_cli_error_lex_end-quality_confidence_e_lineage_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel quality_confidence_e_lineage_cli_error_parse]
 mov esi,quality_confidence_e_lineage_cli_error_parse_end-quality_confidence_e_lineage_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel quality_confidence_e_lineage_cli_error_type]
 mov esi,quality_confidence_e_lineage_cli_error_type_end-quality_confidence_e_lineage_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel quality_confidence_e_lineage_cli_error_runtime]
 mov esi,quality_confidence_e_lineage_cli_error_runtime_end-quality_confidence_e_lineage_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel quality_confidence_e_lineage_cli_error_security]
 mov esi,quality_confidence_e_lineage_cli_error_security_end-quality_confidence_e_lineage_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; PRIVACIDADE-DADOS-SENSIVEIS-E-ZERO-TRUST-PF002 public maturity guard.  Ownership is deliberately narrow: a
; privacy wrapper must occur either in the frozen first-expression slot or
; immediately after the reserved assignment marker used by the PF001 intent
; corpus.  The four recognized wrapper spellings cover the canonical surface
; and its frozen negative aliases without stealing earlier generic families.
; Every owned source is passed to the isolated PF002 parser.  A valid syntax
; proof is still non-executable before PF005 and therefore reports CODEGEN.
%undef call
cli_recognize_privacy:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 cmp r12,6
 jb .none
 cmp qword [rbx+0*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .none
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .none
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .none
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne .none
 mov r13,4
.scan:
 cmp r13,r12
 jae .none
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea r14,[rbx+rax]
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,r14
 lea rsi,[rel cli_name_secret]
 mov edx,cli_name_secret_len
 call cli_token_equals
 test eax,eax
 jnz .candidate
 mov rdi,r14
 lea rsi,[rel cli_name_personal_data]
 mov edx,cli_name_personal_data_len
 call cli_token_equals
 test eax,eax
 jnz .candidate
 mov rdi,r14
 lea rsi,[rel cli_name_secret_value]
 mov edx,cli_name_secret_value_len
 call cli_token_equals
 test eax,eax
 jnz .candidate
 mov rdi,r14
 lea rsi,[rel cli_name_private]
 mov edx,cli_name_private_len
 call cli_token_equals
 test eax,eax
 jz .next
.candidate:
 mov rax,r13
 inc rax
 cmp rax,r12
 jae .next
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LESS
 jne .next
 cmp r13,4
 je .found
 mov rax,r13
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_EQUAL
 je .found
.next:
 inc r13
 jmp .scan

.found:
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],1
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_privacy_result]
 mov ecx,NEBOC_PRIVACY_RESULT_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request+neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request+neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_privacy_result]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request+neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request]
 call neboc_privacy_parse
 test eax,eax
 jnz .parser_rejected

 ; PF005 public profile is the six checksum-frozen GOLDEN shapes. Other
 ; syntactically valid combinations remain bounded future seams (CODEGEN).
 mov rax,[rel cli_privacy_result+NEBOC_PRIVACY_RESULT_SHAPE_HASH_OFFSET]
 mov rdx,0xa714ba6065bf2f03
 cmp rax,rdx
 je .public_shape
 mov rdx,0x5c686804d54b0ce0
 cmp rax,rdx
 je .public_shape
 mov rdx,0xda4eb06e737beee7
 cmp rax,rdx
 je .public_shape
 mov rdx,0x7a4812f0633052a7
 cmp rax,rdx
 je .public_shape
 mov rdx,0xc88730cb47668c0e
 cmp rax,rdx
 je .public_shape
 mov rdx,0xfc61ca86c4ff70a0
 cmp rax,rdx
 je .public_shape
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic],neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
 mov eax,1
 jmp .done
.public_shape:

 ; PF003: embed the authenticated descriptor and compose the bounded public
 ; context. Syntax owns labels/redaction; PF001 remains the decision owner.
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rsi,[rel cli_privacy_result]
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request]
 mov ecx,NEBOC_PRIVACY_RESULT_QWORDS
 rep movsq
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_PERMIT_OFFSET],22
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_RETENTION_LIMIT_OFFSET],10
 mov rax,[rel cli_privacy_result+NEBOC_PRIVACY_RESULT_DIRECT_LABEL_OFFSET]
 cmp rax,NEBOC_LABEL_SECRET
 je .secret_trust
 mov edx,NEBOC_TRUST_RESTRICTED
 jmp .trust_ready
.secret_trust:
 mov edx,NEBOC_TRUST_SECRET
.trust_ready:
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_SOURCE_TRUST_OFFSET],rdx
 test qword [rel cli_privacy_result+NEBOC_PRIVACY_RESULT_FLAGS_OFFSET],NEBOC_PRIVACY_FLAG_HAS_REDACT
 jnz .redact_context
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_SINK_CLEARANCE_OFFSET],rax
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_TARGET_TRUST_OFFSET],rdx
 jmp .semantic_call
.redact_context:
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_DIRECT_EFFECTS_OFFSET],NEBOC_EFFECT_CONSOLE_WRITE
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_DECLARED_EFFECTS_OFFSET],NEBOC_EFFECT_CONSOLE_WRITE
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_CAPABILITIES_OFFSET],NEBOC_EFFECT_CONSOLE_WRITE
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_ALLOW_OFFSET],NEBOC_EFFECT_CONSOLE_WRITE
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_BUDGET_OFFSET],1
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_TRUST_OFFSET],NEBOC_TRUST_PUBLIC
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_POLICY_AUDIT_ID_OFFSET],2201
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_TARGET_TRUST_OFFSET],NEBOC_TRUST_PUBLIC
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_RETENTION_ELAPSED_OFFSET],1
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_PURPOSE_ID_OFFSET],2202
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_SINK_EFFECT_MASK_OFFSET],NEBOC_EFFECT_CONSOLE_WRITE
.semantic_call:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request]
 call neboc_privacy_semantic_analyze
 test eax,eax
 jnz .semantic_rejected

 lea rsi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request]
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_ir_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_SEMANTIC_REQUEST_QWORDS
 rep movsq
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_ir_request]
 call neboc_privacy_ir_lower
 test eax,eax
 jnz .ir_rejected

 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_ir_request]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_IR_POINTER_OFFSET],rax
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_ID_OFFSET],neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
 mov qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION_OFFSET],neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_ABI_VERSION
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request]
 call neboc_privacy_native_lower
 test eax,eax
 jnz .native_rejected

 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+NEBOC_NATIVE_PRIVACY_RECORD_OFFSET]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request+NEBOC_RUNTIME_PRIVACY_RECORD_OFFSET],rax
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+NEBOC_NATIVE_PRIVACY_RECORD_OFFSET+NEBOC_PRIVACY_EFFECTIVE_LABELS_OFFSET]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request+NEBOC_RUNTIME_REQUESTED_LABELS_OFFSET],rax
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request]
 call neboc_privacy_runtime_check
 test eax,eax
 jnz .runtime_rejected
 xor eax,eax
 jmp .done
.semantic_rejected:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_semantic_request+NEBOC_SEMANTIC_PRIVACY_OFFSET+NEBOC_PRIVACY_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
 jmp .pipeline_publish
.ir_rejected:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_ir_request+neboc_privacidade_dados_sensiveis_e_zero_trust_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
 jmp .pipeline_publish
.native_rejected:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request+neboc_privacidade_dados_sensiveis_e_zero_trust_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
 jmp .pipeline_publish
.runtime_rejected:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request+neboc_privacidade_dados_sensiveis_e_zero_trust_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .pipeline_publish
 mov eax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
.pipeline_publish:
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.parser_rejected:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_parse_request+neboc_privacidade_dados_sensiveis_e_zero_trust_PARSE_DIAGNOSTIC_OFFSET]
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
 je .publish
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
 je .publish
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
 je .publish
 mov eax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
.publish:
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
privacidade_dados_sensiveis_e_zero_trust_cli_report_frontend_diagnostic:
 mov rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic]
 test rax,rax
 je .none
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_TYPE_codegen_privacy_x86_64
 je .type
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_SECURITY_driver_cli_linux_x86_64
 je .security
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_codegen]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_codegen_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_lex]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_lex_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_parse]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_parse_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_type]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_type_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_runtime]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_runtime_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_error_security]
 mov esi,privacidade_dados_sensiveis_e_zero_trust_cli_error_security_end-privacidade_dados_sensiveis_e_zero_trust_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

; EFFECTS-CAPABILITIES-E-POLITICAS-PF005 public owner.  Only Policy in the frozen first-expression slot of
; start() owns effects_capabilities_e_politicas; an unrelated identifier/member named Policy remains with
; the generic frontend.  Once that structural prefix matches, PF002 owns every
; malformed suffix and routes the complete source through PF003 -> PF004.
%undef call
cli_recognize_policy:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 cmp r12,5
 jb .none
 cmp qword [rbx+0*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .none
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .none
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .none
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 jne .none
 lea r14,[rbx+4*NEBOC_TOKEN_SIZE]
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .none
 mov rdi,r14
 lea rsi,[rel cli_name_policy]
 mov edx,cli_name_policy_len
 call cli_token_equals
 test eax,eax
 jnz .found
 jmp .none
.found:
 mov qword [rel effects_capabilities_e_politicas_cli_found],1

 ; PF002: canonical source -> exact caller-owned 17-qword policy record.
 lea rdi,[rel effects_capabilities_e_politicas_cli_parse_request]
 mov ecx,neboc_effects_capabilities_e_politicas_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_policy_record]
 mov ecx,NEBOC_POLICY_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel effects_capabilities_e_politicas_cli_parse_request+neboc_effects_capabilities_e_politicas_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_parse_request+neboc_effects_capabilities_e_politicas_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_policy_record]
 mov [rel effects_capabilities_e_politicas_cli_parse_request+neboc_effects_capabilities_e_politicas_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel effects_capabilities_e_politicas_cli_parse_request]
 call neboc_policy_parse
 test eax,eax
 jnz .parse_failure

 ; PF003 semantic envelope: the bounded public profile has no unresolved
 ; callees, so its resolver-owned direct mask is the parsed direct mask.
 lea rdi,[rel effects_capabilities_e_politicas_cli_semantic_request]
 mov ecx,neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rel cli_policy_record+NEBOC_POLICY_DECLARED_EFFECTS_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_DECLARED_EFFECTS_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_CAPABILITIES_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_CAPABILITIES_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_ALLOW_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_ALLOW_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_DENY_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_DENY_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_BUDGET_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_BUDGET_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_TRUST_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_TRUST_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_AUDIT_ID_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_AUDIT_ID_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_PERMIT_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_PERMIT_OFFSET],rax
 mov rax,[rel effects_capabilities_e_politicas_cli_parse_request+neboc_effects_capabilities_e_politicas_PARSE_CANONICAL_HASH_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_PARSER_HASH_OFFSET],rax
 mov rax,[rel effects_capabilities_e_politicas_cli_parse_request+NEBOC_PARSE_CLAUSE_MASK_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_CLAUSE_MASK_OFFSET],rax
 mov rax,[rel cli_policy_record+NEBOC_POLICY_DIRECT_EFFECTS_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_RESOLVED_DIRECT_EFFECTS_OFFSET],rax
 mov qword [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_RESOLVED_CALLEE_EFFECTS_OFFSET],0
 mov qword [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_SOURCE_START_OFFSET],0
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_SOURCE_END_OFFSET],rax
 mov qword [rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_FLAGS_OFFSET],NEBOC_SEMANTIC_FLAG_REQUIRED
 lea rdi,[rel effects_capabilities_e_politicas_cli_semantic_request]
 call neboc_policy_semantic_analyze
 test eax,eax
 jnz .semantic_failure

 ; PF003 target-neutral IR authenticates the full semantic envelope.
 lea rdi,[rel effects_capabilities_e_politicas_cli_ir_request]
 mov ecx,neboc_effects_capabilities_e_politicas_IR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rsi,[rel effects_capabilities_e_politicas_cli_semantic_request]
 lea rdi,[rel effects_capabilities_e_politicas_cli_ir_request]
 mov ecx,neboc_effects_capabilities_e_politicas_SEMANTIC_REQUEST_QWORDS
 rep movsq
 lea rdi,[rel effects_capabilities_e_politicas_cli_ir_request]
 call neboc_policy_ir_lower
 test eax,eax
 jnz .ir_failure

 ; PF004 native lowering and runtime subset guard independently authenticate
 ; the IR and policy record before any public code is emitted.
 lea rdi,[rel effects_capabilities_e_politicas_cli_native_request]
 mov ecx,neboc_effects_capabilities_e_politicas_NATIVE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel effects_capabilities_e_politicas_cli_ir_request]
 mov [rel effects_capabilities_e_politicas_cli_native_request+neboc_effects_capabilities_e_politicas_NATIVE_IR_POINTER_OFFSET],rax
 mov qword [rel effects_capabilities_e_politicas_cli_native_request+neboc_effects_capabilities_e_politicas_NATIVE_TARGET_ID_OFFSET],neboc_effects_capabilities_e_politicas_NATIVE_TARGET_X86_64_SYSV_ELF_LINUX
 mov qword [rel effects_capabilities_e_politicas_cli_native_request+neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION_OFFSET],neboc_effects_capabilities_e_politicas_NATIVE_ABI_VERSION
 lea rdi,[rel effects_capabilities_e_politicas_cli_native_request]
 call neboc_policy_native_lower
 test eax,eax
 jnz .native_failure

 lea rdi,[rel effects_capabilities_e_politicas_cli_runtime_request]
 mov ecx,neboc_effects_capabilities_e_politicas_RUNTIME_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel effects_capabilities_e_politicas_cli_native_request+NEBOC_NATIVE_POLICY_RECORD_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_runtime_request+NEBOC_RUNTIME_POLICY_RECORD_OFFSET],rax
 mov rax,[rel effects_capabilities_e_politicas_cli_native_request+NEBOC_NATIVE_POLICY_INFERRED_EFFECTS_OFFSET]
 mov [rel effects_capabilities_e_politicas_cli_runtime_request+NEBOC_RUNTIME_REQUESTED_MASK_OFFSET],rax
 lea rdi,[rel effects_capabilities_e_politicas_cli_runtime_request]
 call neboc_policy_runtime_check
 test eax,eax
 jnz .runtime_failure
 xor eax,eax
 jmp .done

.parse_failure:
 mov rax,[rel effects_capabilities_e_politicas_cli_parse_request+neboc_effects_capabilities_e_politicas_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .set_failure
 mov eax,neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .set_failure
.semantic_failure:
 mov rax,[rel effects_capabilities_e_politicas_cli_semantic_request+neboc_effects_capabilities_e_politicas_SEMANTIC_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .set_failure
 mov eax,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
 jmp .set_failure
.ir_failure:
 mov rax,[rel effects_capabilities_e_politicas_cli_ir_request+neboc_effects_capabilities_e_politicas_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .set_failure
 mov eax,neboc_effects_capabilities_e_politicas_DIAG_TYPE_codegen_effects_x86_64
 jmp .set_failure
.native_failure:
 mov rax,[rel effects_capabilities_e_politicas_cli_native_request+neboc_effects_capabilities_e_politicas_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .set_failure
 mov eax,neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
 jmp .set_failure
.runtime_failure:
 mov rax,[rel effects_capabilities_e_politicas_cli_runtime_request+neboc_effects_capabilities_e_politicas_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .set_failure
 mov eax,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
.set_failure:
 mov [rel effects_capabilities_e_politicas_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
effects_capabilities_e_politicas_cli_report_frontend_diagnostic:
 mov rax,[rel effects_capabilities_e_politicas_cli_frontend_diagnostic]
 test rax,rax
 je .none
 cmp rax,neboc_effects_capabilities_e_politicas_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_effects_capabilities_e_politicas_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_effects_capabilities_e_politicas_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
 je .security
 cmp rax,neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
 je .codegen
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_type]
 mov esi,effects_capabilities_e_politicas_cli_error_type_end-effects_capabilities_e_politicas_cli_error_type
 jmp .emit
.lex:
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_lex]
 mov esi,effects_capabilities_e_politicas_cli_error_lex_end-effects_capabilities_e_politicas_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_parse]
 mov esi,effects_capabilities_e_politicas_cli_error_parse_end-effects_capabilities_e_politicas_cli_error_parse
 jmp .emit
.runtime:
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_runtime]
 mov esi,effects_capabilities_e_politicas_cli_error_runtime_end-effects_capabilities_e_politicas_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_security]
 mov esi,effects_capabilities_e_politicas_cli_error_security_end-effects_capabilities_e_politicas_cli_error_security
 jmp .emit
.codegen:
 lea rdi,[rel effects_capabilities_e_politicas_cli_error_codegen]
 mov esi,effects_capabilities_e_politicas_cli_error_codegen_end-effects_capabilities_e_politicas_cli_error_codegen
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
text_char_unicode_e_bytes_cli_detect_frontend_diagnostic:
 push rbx
 push r12
 push r13
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .none
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID_CHAR_LITERAL
 je .char
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_LBRACKET
 je .bytes
 jmp .next
.char:
 mov rax,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.bytes:
 mov qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],NEBOC_API_DIAG_BYTES_LITERAL_UNAVAILABLE
 mov eax,1
 jmp .done
.next: inc r13
 jmp .loop
.none: xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
text_char_unicode_e_bytes_cli_report_frontend_diagnostic:
 mov rax,[rel text_char_unicode_e_bytes_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,NEBOC_CHAR_DIAG_BOM_FORBIDDEN
 je .bom
 cmp rax,NEBOC_CHAR_DIAG_EXPECTED_OPEN_QUOTE
 je .open
 cmp rax,NEBOC_CHAR_DIAG_UNTERMINATED
 je .unterminated
 cmp rax,NEBOC_CHAR_DIAG_EMPTY
 je .empty
 cmp rax,NEBOC_CHAR_DIAG_MULTIPLE_SCALARS
 je .multiple
 cmp rax,NEBOC_CHAR_DIAG_INVALID_ESCAPE
 je .escape
 cmp rax,NEBOC_CHAR_DIAG_PHYSICAL_NEWLINE
 je .newline
 cmp rax,NEBOC_CHAR_DIAG_INVALID_UTF8
 je .utf8
 cmp rax,NEBOC_CHAR_DIAG_SURROGATE
 je .surrogate
 cmp rax,NEBOC_CHAR_DIAG_OUT_OF_RANGE
 je .range
 cmp rax,NEBOC_API_DIAG_BYTES_LITERAL_UNAVAILABLE
 je .bytes
 jmp .none
.bom: lea rdi,[rel cli_error_char_bom]
 mov esi,cli_error_char_bom_end-cli_error_char_bom
 jmp .write
.open: lea rdi,[rel cli_error_char_open]
 mov esi,cli_error_char_open_end-cli_error_char_open
 jmp .write
.unterminated: lea rdi,[rel cli_error_char_unterminated]
 mov esi,cli_error_char_unterminated_end-cli_error_char_unterminated
 jmp .write
.empty: lea rdi,[rel cli_error_char_empty]
 mov esi,cli_error_char_empty_end-cli_error_char_empty
 jmp .write
.multiple: lea rdi,[rel cli_error_char_multiple]
 mov esi,cli_error_char_multiple_end-cli_error_char_multiple
 jmp .write
.escape: lea rdi,[rel cli_error_char_escape]
 mov esi,cli_error_char_escape_end-cli_error_char_escape
 jmp .write
.newline: lea rdi,[rel cli_error_char_newline]
 mov esi,cli_error_char_newline_end-cli_error_char_newline
 jmp .write
.utf8: lea rdi,[rel cli_error_char_utf8]
 mov esi,cli_error_char_utf8_end-cli_error_char_utf8
 jmp .write
.surrogate: lea rdi,[rel cli_error_char_surrogate]
 mov esi,cli_error_char_surrogate_end-cli_error_char_surrogate
 jmp .write
.range: lea rdi,[rel cli_error_char_range]
 mov esi,cli_error_char_range_end-cli_error_char_range
 jmp .write
.bytes: lea rdi,[rel cli_error_bytes_literal]
 mov esi,cli_error_bytes_literal_end-cli_error_bytes_literal
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret


%undef call
cli_recognize_column:
 lea rdi,[rel column_row_table_e_dataset_cli_vertical_request]
 mov ecx,NEBOC_COLUMN_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel column_row_table_e_dataset_cli_vertical_request]
 jmp neboc_column_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
column_row_table_e_dataset_cli_report_diagnostic:
 mov rax,[rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .arity
 cmp rax,2
 je .type
 cmp rax,3
 je .bounds
 cmp rax,4
 je .constant
 cmp rax,5
 je .dtype
 cmp rax,6
 je .table
 cmp rax,7
 je .dataset
 cmp rax,8
 je .missing
 cmp rax,9
 je .join
 cmp rax,10
 je .overflow
 cmp rax,11
 je .stream_event_e_processamento_continuo
 cmp rax,12
 je .tree_graph_node_e_edge
 cmp rax,13
 je .funcoes_lambdas_callbacks_e_referencias
 cmp rax,14
 je .call_e_comportamentos_de_chamada
 cmp rax,15
 je .operadores_de_fluxo_e_branching_pipelines
 cmp rax,16
 je .controlo_de_fluxo_estruturado
 cmp rax,17
 je .pattern_matching_e_destructuring
 cmp rax,18
 je .async_await_e_concorrencia_estruturada
 xor eax,eax
 ret
.arity: lea rdi,[rel column_row_table_e_dataset_cli_error_arity]
 mov esi,column_row_table_e_dataset_cli_error_arity_end-column_row_table_e_dataset_cli_error_arity
 jmp .write
.type: lea rdi,[rel column_row_table_e_dataset_cli_error_type]
 mov esi,column_row_table_e_dataset_cli_error_type_end-column_row_table_e_dataset_cli_error_type
 jmp .write
.bounds: lea rdi,[rel column_row_table_e_dataset_cli_error_bounds]
 mov esi,column_row_table_e_dataset_cli_error_bounds_end-column_row_table_e_dataset_cli_error_bounds
 jmp .write
.constant: lea rdi,[rel column_row_table_e_dataset_cli_error_constant]
 mov esi,column_row_table_e_dataset_cli_error_constant_end-column_row_table_e_dataset_cli_error_constant
 jmp .write
.dtype: lea rdi,[rel column_row_table_e_dataset_cli_error_dtype]
 mov esi,column_row_table_e_dataset_cli_error_dtype_end-column_row_table_e_dataset_cli_error_dtype
 jmp .write
.table: lea rdi,[rel cli_error_table]
 mov esi,cli_error_table_end-cli_error_table
 jmp .write
.dataset: lea rdi,[rel cli_error_dataset]
 mov esi,cli_error_dataset_end-cli_error_dataset
 jmp .write
.missing: lea rdi,[rel cli_error_missing]
 mov esi,cli_error_missing_end-cli_error_missing
 jmp .write
.join: lea rdi,[rel cli_error_join]
 mov esi,cli_error_join_end-cli_error_join
 jmp .write
.overflow: lea rdi,[rel column_row_table_e_dataset_cli_error_overflow]
 mov esi,column_row_table_e_dataset_cli_error_overflow_end-column_row_table_e_dataset_cli_error_overflow
 jmp .write
.stream_event_e_processamento_continuo: lea rdi,[rel stream_event_e_processamento_continuo_cli_error_bounded]
 mov esi,stream_event_e_processamento_continuo_cli_error_bounded_end-stream_event_e_processamento_continuo_cli_error_bounded
 jmp .write
.tree_graph_node_e_edge: lea rdi,[rel tree_graph_node_e_edge_cli_error_bounded]
 mov esi,tree_graph_node_e_edge_cli_error_bounded_end-tree_graph_node_e_edge_cli_error_bounded
 jmp .write
.funcoes_lambdas_callbacks_e_referencias: lea rdi,[rel funcoes_lambdas_callbacks_e_referencias_cli_error_bounded]
 mov esi,funcoes_lambdas_callbacks_e_referencias_cli_error_bounded_end-funcoes_lambdas_callbacks_e_referencias_cli_error_bounded
 jmp .write
.call_e_comportamentos_de_chamada: lea rdi,[rel call_e_comportamentos_de_chamada_cli_error_bounded]
 mov esi,call_e_comportamentos_de_chamada_cli_error_bounded_end-call_e_comportamentos_de_chamada_cli_error_bounded
 jmp .write
.operadores_de_fluxo_e_branching_pipelines: lea rdi,[rel operadores_de_fluxo_e_branching_pipelines_cli_error_bounded]
 mov esi,operadores_de_fluxo_e_branching_pipelines_cli_error_bounded_end-operadores_de_fluxo_e_branching_pipelines_cli_error_bounded
 jmp .write
.controlo_de_fluxo_estruturado: lea rdi,[rel controlo_de_fluxo_estruturado_cli_error_bounded]
 mov esi,controlo_de_fluxo_estruturado_cli_error_bounded_end-controlo_de_fluxo_estruturado_cli_error_bounded
 jmp .write
.pattern_matching_e_destructuring: lea rdi,[rel pattern_matching_e_destructuring_cli_error_bounded]
 mov esi,pattern_matching_e_destructuring_cli_error_bounded_end-pattern_matching_e_destructuring_cli_error_bounded
 jmp .write
.async_await_e_concorrencia_estruturada: lea rdi,[rel async_await_e_concorrencia_estruturada_cli_error_bounded]
 mov esi,async_await_e_concorrencia_estruturada_cli_error_bounded_end-async_await_e_concorrencia_estruturada_cli_error_bounded
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
cli_recognize_vector:
 lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request]
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request]
 jmp neboc_vector_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
vetores_matrizes_tensores_e_computacao_cientifica_cli_report_diagnostic:
 mov rax,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .arity
 cmp rax,2
 je .type
 cmp rax,3
 je .bounds
 cmp rax,4
 je .constant
 cmp rax,5
 je .dtype
 cmp rax,6
 je .matrix
 cmp rax,7
 je .tensor
 cmp rax,8
 je .device
 cmp rax,9
 je .sparse
 cmp rax,10
 je .overflow
 xor eax,eax
 ret
.arity: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_arity]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_arity_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_arity
 jmp .write
.type: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_type]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_type_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_type
 jmp .write
.bounds: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_bounds]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_bounds_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_bounds
 jmp .write
.constant: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_constant]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_constant_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_constant
 jmp .write
.dtype: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_dtype]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_dtype_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_dtype
 jmp .write
.matrix: lea rdi,[rel cli_error_matrix]
 mov esi,cli_error_matrix_end-cli_error_matrix
 jmp .write
.tensor: lea rdi,[rel cli_error_tensor]
 mov esi,cli_error_tensor_end-cli_error_tensor
 jmp .write
.device: lea rdi,[rel cli_error_device]
 mov esi,cli_error_device_end-cli_error_device
 jmp .write
.sparse: lea rdi,[rel cli_error_sparse]
 mov esi,cli_error_sparse_end-cli_error_sparse
 jmp .write
.overflow: lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_error_overflow]
 mov esi,vetores_matrizes_tensores_e_computacao_cientifica_cli_error_overflow_end-vetores_matrizes_tensores_e_computacao_cientifica_cli_error_overflow
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
cli_recognize_array:
 lea rdi,[rel colecoes_primitivas_cli_vertical_request]
 mov ecx,NEBOC_ARRAY_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel colecoes_primitivas_cli_vertical_request]
 jmp neboc_array_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
colecoes_primitivas_cli_report_diagnostic:
 mov rax,[rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .arity
 cmp rax,2
 je .type
 cmp rax,3
 je .bounds
 cmp rax,4
 je .constant
 cmp rax,5
 je .mutation
 cmp rax,6
 je .list
 cmp rax,7
 je .dict
 cmp rax,8
 je .capacity
 xor eax,eax
 ret
.arity: lea rdi,[rel colecoes_primitivas_cli_error_arity]
 mov esi,colecoes_primitivas_cli_error_arity_end-colecoes_primitivas_cli_error_arity
 jmp .write
.type: lea rdi,[rel colecoes_primitivas_cli_error_type]
 mov esi,colecoes_primitivas_cli_error_type_end-colecoes_primitivas_cli_error_type
 jmp .write
.bounds: lea rdi,[rel colecoes_primitivas_cli_error_bounds]
 mov esi,colecoes_primitivas_cli_error_bounds_end-colecoes_primitivas_cli_error_bounds
 jmp .write
.constant: lea rdi,[rel colecoes_primitivas_cli_error_constant]
 mov esi,colecoes_primitivas_cli_error_constant_end-colecoes_primitivas_cli_error_constant
 jmp .write
.mutation: lea rdi,[rel cli_error_mutation]
 mov esi,cli_error_mutation_end-cli_error_mutation
 jmp .write
.list: lea rdi,[rel cli_error_list]
 mov esi,cli_error_list_end-cli_error_list
 jmp .write
.dict: lea rdi,[rel cli_error_dict]
 mov esi,cli_error_dict_end-cli_error_dict
 jmp .write
.capacity: lea rdi,[rel cli_error_capacity]
 mov esi,cli_error_capacity_end-cli_error_capacity
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_parameters:
 lea rdi,[rel cli_parameters]
 mov ecx,NEBOC_PARAM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_param_records]
 mov ecx,(NEBOC_PARAM_MAX*NEBOC_PARAM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_param_plan]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_parameters+NEBOC_PARAM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_parameters+NEBOC_PARAM_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_parameters+NEBOC_PARAM_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_parameters+NEBOC_PARAM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_param_records]
 mov [rel cli_parameters+NEBOC_PARAM_RECORDS_OFFSET],rax
 mov qword [rel cli_parameters+NEBOC_PARAM_CAPACITY_OFFSET],NEBOC_PARAM_MAX
 lea rdi,[rel cli_parameters]
 call neboc_parameters_recognize
 test eax,eax
 jnz .parse_fail
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_parameters]
 call neboc_parameters_analyze
 test eax,eax
 jnz .semantic_fail
 lea rdi,[rel cli_parameters]
 lea rsi,[rel cli_param_plan]
 call neboc_parameters_lower
 test eax,eax
 jz .done
 jmp .stage_fail
.parse_fail:
 cmp qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
 jmp .done
.semantic_fail:
 cmp qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
 jmp .done
.stage_fail:
 cmp qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_parameters_diagnostic:
 mov rax,[rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_DIAG_SIGNATURE
 je .signature
 cmp rax,NEBOC_DIAG_DUPLICATE_PARAMETER
 je .duplicate_parameter
 cmp rax,NEBOC_DIAG_DEFAULT
 je .default
 cmp rax,NEBOC_DIAG_DUPLICATE_SIGNATURE
 je .duplicate_signature
 cmp rax,NEBOC_DIAG_AMBIGUOUS_OVERLOAD
 je .ambiguous_overload
 cmp rax,NEBOC_DIAG_ABI_BOUND
 je .abi
 cmp rax,NEBOC_DIAG_MANGLE_COLLISION
 je .mangle_collision
 cmp rax,NEBOC_DIAG_DUPLICATE_NAMED
 je .duplicate_named
 cmp rax,NEBOC_DIAG_MISSING_ARGUMENT
 je .missing
 cmp rax,NEBOC_DIAG_EXTRA_ARGUMENT
 je .extra
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_TYPE_MISMATCH
 je .type
 cmp rax,NEBOC_DIAG_RETURN
 je .return
 cmp rax,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_SYNTAX
 je .syntax
 cmp rax,NEBOC_DIAG_CLOSURE_BORROW_ESCAPE
 je .closure_borrow_escape
 cmp rax,NEBOC_DIAG_CALLABLE_SIGNATURE
 je .callable_signature
 cmp rax,NEBOC_DIAG_CALLABLE_DOUBLE_DROP
 je .callable_double_drop
 cmp rax,NEBOC_DIAG_CALLABLE_CAPACITY
 je .callable_capacity
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_internal]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_internal_end-seguranca_numerica_conversoes_e_overflow_cli_error_internal
 jmp .write
.signature: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_001]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_001_end-seguranca_numerica_conversoes_e_overflow_cli_error_001
 jmp .write
.duplicate_parameter: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_002]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_002_end-seguranca_numerica_conversoes_e_overflow_cli_error_002
 jmp .write
.default: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_003]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_003_end-seguranca_numerica_conversoes_e_overflow_cli_error_003
 jmp .write
.duplicate_signature: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_004]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_004_end-seguranca_numerica_conversoes_e_overflow_cli_error_004
 jmp .write
.ambiguous_overload: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_005]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_005_end-seguranca_numerica_conversoes_e_overflow_cli_error_005
 jmp .write
.abi: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_006]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_006_end-seguranca_numerica_conversoes_e_overflow_cli_error_006
 jmp .write
.mangle_collision: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_007]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_007_end-seguranca_numerica_conversoes_e_overflow_cli_error_007
 jmp .write
.duplicate_named: lea rdi,[rel cli_error_011]
 mov esi,cli_error_011_end-cli_error_011
 jmp .write
.missing: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_012]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_012_end-seguranca_numerica_conversoes_e_overflow_cli_error_012
 jmp .write
.extra: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_013]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_013_end-seguranca_numerica_conversoes_e_overflow_cli_error_013
 jmp .write
.type: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_014]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_014_end-seguranca_numerica_conversoes_e_overflow_cli_error_014
 jmp .write
.return: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_015]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_015_end-seguranca_numerica_conversoes_e_overflow_cli_error_015
 jmp .write
.syntax: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_016]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_016_end-seguranca_numerica_conversoes_e_overflow_cli_error_016
 jmp .write
.closure_borrow_escape: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_017]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_017_end-seguranca_numerica_conversoes_e_overflow_cli_error_017
 jmp .write
.callable_signature: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_018]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_018_end-seguranca_numerica_conversoes_e_overflow_cli_error_018
 jmp .write
.callable_double_drop: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_019]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_019_end-seguranca_numerica_conversoes_e_overflow_cli_error_019
 jmp .write
.callable_capacity: lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_020]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_020_end-seguranca_numerica_conversoes_e_overflow_cli_error_020
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_option:
 lea rdi,[rel cli_option]
 mov ecx,NEBOC_OPTION_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_option_bindings]
 mov ecx,(NEBOC_OPTION_MAX_BINDINGS*NEBOC_OPTION_BIND_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_option_plan]
 mov ecx,NEBOC_OPTION_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_option+NEBOC_OPTION_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_option+NEBOC_OPTION_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_option+NEBOC_OPTION_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_option+NEBOC_OPTION_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_option_bindings]
 mov [rel cli_option+NEBOC_OPTION_BINDINGS_OFFSET],rax
 mov qword [rel cli_option+NEBOC_OPTION_BINDING_CAPACITY_OFFSET],NEBOC_OPTION_MAX_BINDINGS
 lea rdi,[rel cli_option]
 call neboc_option_recognize
 test eax,eax
 jnz .done
 cmp qword [rel cli_option+NEBOC_OPTION_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_option]
 lea rsi,[rel cli_option_plan]
 call neboc_option_lower
 test eax,eax
 jz .done
 cmp qword [rel cli_option+NEBOC_OPTION_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_option+NEBOC_OPTION_DIAGNOSTIC_OFFSET],NEBOC_OPTION_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_option_diagnostic:
 mov rax,[rel cli_option+NEBOC_OPTION_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_OPTION_DIAG_PAYLOAD
 je .payload
 cmp rax,NEBOC_OPTION_DIAG_VARIANT
 je .variant
 cmp rax,NEBOC_OPTION_DIAG_LAYOUT
 je .layout
 cmp rax,NEBOC_OPTION_DIAG_CANONICAL
 je .canonical
 cmp rax,NEBOC_OPTION_DIAG_CALLBACK_TYPE
 je .callback
 cmp rax,NEBOC_OPTION_DIAG_LAZY
 je .lazy
 cmp rax,NEBOC_OPTION_DIAG_UNSAFE_GET
 je .unsafe_get
 cmp rax,NEBOC_OPTION_DIAG_USE_AFTER_MOVE
 je .use_after
 cmp rax,NEBOC_OPTION_DIAG_SYNTAX
 je .syntax
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_internal]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_internal_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_internal
 jmp .write
.payload:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_001]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_001_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_001
 jmp .write
.variant:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_002]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_002_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_002
 jmp .write
.layout:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_003]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_003_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_003
 jmp .write
.canonical:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_004]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_004_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_004
 jmp .write
.callback:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_005]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_005_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_005
 jmp .write
.lazy:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_006]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_006_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_006
 jmp .write
.unsafe_get:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_013]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_013_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_013
 jmp .write
.use_after:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_014]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_014_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_014
 jmp .write
.syntax:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_015]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_015_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_015
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_result:
 lea rdi,[rel cli_result]
 mov ecx,NEBOC_RESULT_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_result_bindings]
 mov ecx,(NEBOC_RESULT_MAX_BINDINGS*NEBOC_RESULT_BIND_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_result_plan]
 mov ecx,NEBOC_RESULT_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_result+NEBOC_RESULT_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_result+NEBOC_RESULT_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_result+NEBOC_RESULT_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_result+NEBOC_RESULT_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_result_bindings]
 mov [rel cli_result+NEBOC_RESULT_BINDINGS_OFFSET],rax
 mov qword [rel cli_result+NEBOC_RESULT_BINDING_CAPACITY_OFFSET],NEBOC_RESULT_MAX_BINDINGS
 lea rdi,[rel cli_result]
 call neboc_result_recognize
 test eax,eax
 jnz .done
 cmp qword [rel cli_result+NEBOC_RESULT_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_result]
 lea rsi,[rel cli_result_plan]
 call neboc_result_lower
 test eax,eax
 jz .done
 cmp qword [rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_result_diagnostic:
 mov rax,[rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_RESULT_DIAG_PAYLOAD
 je .payload
 cmp rax,NEBOC_RESULT_DIAG_VARIANT
 je .variant
 cmp rax,NEBOC_RESULT_DIAG_LAYOUT
 je .layout
 cmp rax,NEBOC_RESULT_DIAG_CANONICAL
 je .canonical
 cmp rax,NEBOC_RESULT_DIAG_CALLBACK_TYPE
 je .callback
 cmp rax,NEBOC_RESULT_DIAG_LAZY
 je .lazy
 cmp rax,NEBOC_RESULT_DIAG_PROPAGATION_CONTEXT
 je .propagation_context
 cmp rax,NEBOC_RESULT_DIAG_NON_EXHAUSTIVE
 je .non_exhaustive
 cmp rax,NEBOC_RESULT_DIAG_UNREACHABLE_ARM
 je .unreachable_arm
 cmp rax,NEBOC_RESULT_DIAG_PATTERN_CONFLICT
 je .pattern_conflict
 cmp rax,NEBOC_RESULT_DIAG_ERROR_INVARIANT
 je .error_invariant
 cmp rax,NEBOC_RESULT_DIAG_ERROR_ERASURE
 je .error_erasure
 cmp rax,NEBOC_RESULT_DIAG_WRONG_SIDE
 je .wrong_side
 cmp rax,NEBOC_RESULT_DIAG_USE_AFTER_MOVE
 je .use_after
 cmp rax,NEBOC_RESULT_DIAG_SYNTAX
 je .syntax
 cmp rax,NEBOC_RESULT_DIAG_DROPPED_CONTEXT
 je .dropped_context
 cmp rax,NEBOC_RESULT_DIAG_DOUBLE_CLEANUP
 je .double_cleanup
 cmp rax,NEBOC_RESULT_DIAG_PROPAGATION_SYNTAX
 je .propagation_syntax
 lea rdi,[rel cli_error_result_internal]
 mov esi,cli_error_result_internal_end-cli_error_result_internal
 jmp .write
.payload:
 lea rdi,[rel cli_error_result_001]
 mov esi,cli_error_result_001_end-cli_error_result_001
 jmp .write
.variant:
 lea rdi,[rel cli_error_result_002]
 mov esi,cli_error_result_002_end-cli_error_result_002
 jmp .write
.layout:
 lea rdi,[rel cli_error_result_003]
 mov esi,cli_error_result_003_end-cli_error_result_003
 jmp .write
.canonical:
 lea rdi,[rel cli_error_result_004]
 mov esi,cli_error_result_004_end-cli_error_result_004
 jmp .write
.callback:
 lea rdi,[rel cli_error_result_005]
 mov esi,cli_error_result_005_end-cli_error_result_005
 jmp .write
.lazy:
 lea rdi,[rel cli_error_result_006]
 mov esi,cli_error_result_006_end-cli_error_result_006
 jmp .write
.propagation_context:
 lea rdi,[rel cli_error_result_007]
 mov esi,cli_error_result_007_end-cli_error_result_007
 jmp .write
.non_exhaustive:
 lea rdi,[rel cli_error_result_008]
 mov esi,cli_error_result_008_end-cli_error_result_008
 jmp .write
.unreachable_arm:
 lea rdi,[rel cli_error_result_009]
 mov esi,cli_error_result_009_end-cli_error_result_009
 jmp .write
.pattern_conflict:
 lea rdi,[rel cli_error_result_010]
 mov esi,cli_error_result_010_end-cli_error_result_010
 jmp .write
.error_invariant:
 lea rdi,[rel cli_error_result_011]
 mov esi,cli_error_result_011_end-cli_error_result_011
 jmp .write
.error_erasure:
 lea rdi,[rel cli_error_result_012]
 mov esi,cli_error_result_012_end-cli_error_result_012
 jmp .write
.wrong_side:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_016]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_016_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_016
 jmp .write
.use_after:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_017]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_017_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_017
 jmp .write
.syntax:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_018]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_018_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_018
 jmp .write
.dropped_context:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_019]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_019_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_019
 jmp .write
.double_cleanup:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_020]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_020_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_020
 jmp .write
.propagation_syntax:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_021]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_021_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_021
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_array_range:
 lea rdi,[rel cli_array_range]
 mov ecx,NEBOC_AR_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_array_range+NEBOC_AR_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_array_range+NEBOC_AR_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_array_range+NEBOC_AR_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_array_range+NEBOC_AR_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ar_bindings]
 mov [rel cli_array_range+NEBOC_AR_BINDINGS_OFFSET],rax
 mov qword [rel cli_array_range+NEBOC_AR_BINDING_CAPACITY_OFFSET],NEBOC_AR_MAX_BINDINGS
 lea rax,[rel cli_ar_values]
 mov [rel cli_array_range+NEBOC_AR_VALUES_OFFSET],rax
 mov qword [rel cli_array_range+NEBOC_AR_VALUE_CAPACITY_OFFSET],NEBOC_AR_MAX_VALUES
 lea rax,[rel cli_for_loops]
 mov [rel cli_array_range+NEBOC_AR_LOOPS_OFFSET],rax
 mov qword [rel cli_array_range+NEBOC_AR_LOOP_CAPACITY_OFFSET],NEBOC_FOR_MAX_LOOPS
 lea rdi,[rel cli_array_range]
 call neboc_array_range_recognize
 test eax,eax
 jnz .done
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_array_range]
 lea rsi,[rel cli_ar_plan]
 call neboc_array_range_lower
 test eax,eax
 jnz .lower_failed
 lea rdi,[rel cli_array_range]
 lea rsi,[rel cli_slice_plan]
 call neboc_slice_lower
 test eax,eax
 jz .done
.lower_failed:
 cmp qword [rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_array_range_diagnostic:
 mov rax,[rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_AR_DIAG_CONST_LENGTH
 je .length
 cmp rax,NEBOC_AR_DIAG_BOUNDS
 je .bounds
 cmp rax,NEBOC_AR_DIAG_RANGE
 je .range
 cmp rax,NEBOC_AR_DIAG_SLICE_STALE
 je .slice_stale
 cmp rax,NEBOC_AR_DIAG_ARITY
 je .arity
 cmp rax,NEBOC_AR_DIAG_TYPE
 je .type
 cmp rax,NEBOC_AR_DIAG_DYNAMIC_INDEX
 je .dynamic
 cmp rax,NEBOC_AR_DIAG_SYNTAX
 je .syntax
 cmp rax,NEBOC_AR_DIAG_SLICE_MUTATION_CONFLICT
 je .slice_mutation
 cmp rax,NEBOC_AR_DIAG_SLICE_ESCAPE
 je .slice_escape
 cmp rax,NEBOC_AR_DIAG_SLICE_UNAVAILABLE
 je .slice_unavailable
 cmp rax,NEBOC_AR_DIAG_FOR_TYPE
 je .for_type
 cmp rax,NEBOC_AR_DIAG_FOR_MUTATION
 je .for_mutation
 cmp rax,NEBOC_AR_DIAG_FOR_OVERFLOW
 je .for_overflow
 cmp rax,NEBOC_AR_DIAG_FOR_SYNTAX
 je .for_syntax
 cmp rax,NEBOC_AR_DIAG_FOR_NESTING
 je .for_nesting
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64_native_vertical]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_internal_end_driver_cli_linux_x86_64_native_vertical-option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64_native_vertical
 jmp .write
.length:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_004]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_004_end-option_result_null_externo_e_erros_tipados_cli_error_004
 jmp .write
.bounds:
 lea rdi,[rel cli_error_005_array]
 mov esi,cli_error_005_array_end-cli_error_005_array
 jmp .write
.range:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_006]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_006_end-option_result_null_externo_e_erros_tipados_cli_error_006
 jmp .write
.slice_stale:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_007]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_007_end-option_result_null_externo_e_erros_tipados_cli_error_007
 jmp .write
.arity:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_018]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_018_end-option_result_null_externo_e_erros_tipados_cli_error_018
 jmp .write
.type:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_019]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_019_end-option_result_null_externo_e_erros_tipados_cli_error_019
 jmp .write
.dynamic:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_020]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_020_end-option_result_null_externo_e_erros_tipados_cli_error_020
 jmp .write
.syntax:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_021]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_021_end-option_result_null_externo_e_erros_tipados_cli_error_021
 jmp .write
.slice_mutation:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_022]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_022_end-option_result_null_externo_e_erros_tipados_cli_error_022
 jmp .write
.slice_escape:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_023]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_023_end-option_result_null_externo_e_erros_tipados_cli_error_023
 jmp .write
.slice_unavailable:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_024]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_024_end-option_result_null_externo_e_erros_tipados_cli_error_024
 jmp .write
.for_type:
 lea rdi,[rel cli_error_037]
 mov esi,cli_error_037_end-cli_error_037
 jmp .write
.for_mutation:
 lea rdi,[rel cli_error_038]
 mov esi,cli_error_038_end-cli_error_038
 jmp .write
.for_overflow:
 lea rdi,[rel cli_error_039]
 mov esi,cli_error_039_end-cli_error_039
 jmp .write
.for_syntax:
 lea rdi,[rel cli_error_040]
 mov esi,cli_error_040_end-cli_error_040
 jmp .write
.for_nesting:
 lea rdi,[rel cli_error_041]
 mov esi,cli_error_041_end-cli_error_041
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_buffer:
 lea rdi,[rel cli_buffer]
 mov ecx,NEBOC_BUFFER_F11_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_buffer_plan]
 mov ecx,NEBOC_BUFFER_PLAN_F11_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_buffer+NEBOC_BUFFER_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_buffer+NEBOC_BUFFER_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_buffer+NEBOC_BUFFER_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_buffer+NEBOC_BUFFER_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel cli_buffer]
 call neboc_buffer_parse
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 je .done
 test eax,eax
 jnz .done
 lea rdi,[rel cli_buffer]
 call neboc_buffer_analyze
 test eax,eax
 jnz .done
 lea rdi,[rel cli_buffer]
 lea rsi,[rel cli_buffer_plan]
 call neboc_buffer_lower
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_buffer_diagnostic:
 mov rax,[rel cli_buffer+NEBOC_BUFFER_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp eax,NEBOC_BUFFER_DIAG_CAPACITY_TYPE
 je .capacity_type
 cmp eax,NEBOC_BUFFER_DIAG_CAPACITY_DYNAMIC
 je .capacity_dynamic
 cmp eax,NEBOC_BUFFER_DIAG_CAPACITY_UNSUPPORTED
 je .capacity_unsupported
 cmp eax,NEBOC_BUFFER_DIAG_LENGTH_TYPE
 je .length_type
 cmp eax,NEBOC_BUFFER_DIAG_LENGTH_DYNAMIC
 je .length_dynamic
 cmp eax,NEBOC_BUFFER_DIAG_LENGTH_RANGE
 je .length_range
 cmp eax,NEBOC_BUFFER_DIAG_BYTE_BELOW
 je .byte_below
 cmp eax,NEBOC_BUFFER_DIAG_BYTE_ABOVE
 je .byte_above
 cmp eax,NEBOC_BUFFER_DIAG_INDEX_TYPE
 je .index_type
 cmp eax,NEBOC_BUFFER_DIAG_INDEX_DYNAMIC
 je .index_dynamic
 cmp eax,NEBOC_BUFFER_DIAG_READ_BOUNDS
 je .read_bounds
 cmp eax,NEBOC_BUFFER_DIAG_WRITE_BOUNDS
 je .write_bounds
 cmp eax,NEBOC_BUFFER_DIAG_FULL
 je .full
 cmp eax,NEBOC_BUFFER_DIAG_RECEIVER
 je .receiver
 cmp eax,NEBOC_BUFFER_DIAG_ARITY
 je .arity
 cmp eax,NEBOC_BUFFER_DIAG_ALIAS
 je .alias
 cmp eax,NEBOC_BUFFER_DIAG_RESERVE
 je .reserve
 cmp eax,NEBOC_BUFFER_DIAG_GROWTH
 je .growth
 cmp eax,NEBOC_BUFFER_DIAG_EXTEND
 je .extend
 cmp eax,NEBOC_BUFFER_DIAG_ESCAPE
 je .escape
 cmp eax,NEBOC_BUFFER_DIAG_COPY_MOVE
 je .copy_move
 cmp eax,NEBOC_BUFFER_DIAG_FUNCTION_TRANSPORT
 je .transport
 cmp eax,NEBOC_BUFFER_DIAG_FREEZE_LENGTH
 je .freeze_length
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_BOUNDS
 je .slice_bounds
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_ESCAPE
 je .slice_escape
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_MUTATION_CONFLICT
 je .slice_mutation
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_STALE
 je .slice_stale
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_OWNER
 je .slice_owner
 cmp eax,NEBOC_BUFFER_DIAG_SLICE_ARITY
 je .slice_arity
 cmp eax,NEBOC_BUFFER_DIAG_INTERNAL
 je .internal
.none:
 xor eax,eax
 ret
.capacity_type:
 lea rdi,[rel cli_error_buffer_capacity_type]
 mov esi,cli_error_buffer_capacity_type_end-cli_error_buffer_capacity_type
 jmp .write
.capacity_dynamic:
 lea rdi,[rel cli_error_buffer_capacity_dynamic]
 mov esi,cli_error_buffer_capacity_dynamic_end-cli_error_buffer_capacity_dynamic
 jmp .write
.capacity_unsupported:
 lea rdi,[rel cli_error_buffer_capacity_unsupported]
 mov esi,cli_error_buffer_capacity_unsupported_end-cli_error_buffer_capacity_unsupported
 jmp .write
.length_type:
 lea rdi,[rel cli_error_buffer_length_type]
 mov esi,cli_error_buffer_length_type_end-cli_error_buffer_length_type
 jmp .write
.length_dynamic:
 lea rdi,[rel cli_error_buffer_length_dynamic]
 mov esi,cli_error_buffer_length_dynamic_end-cli_error_buffer_length_dynamic
 jmp .write
.length_range:
 lea rdi,[rel cli_error_buffer_length_range]
 mov esi,cli_error_buffer_length_range_end-cli_error_buffer_length_range
 jmp .write
.byte_below:
 lea rdi,[rel cli_error_buffer_byte_below]
 mov esi,cli_error_buffer_byte_below_end-cli_error_buffer_byte_below
 jmp .write
.byte_above:
 lea rdi,[rel cli_error_buffer_byte_above]
 mov esi,cli_error_buffer_byte_above_end-cli_error_buffer_byte_above
 jmp .write
.index_type:
 lea rdi,[rel cli_error_buffer_index_type]
 mov esi,cli_error_buffer_index_type_end-cli_error_buffer_index_type
 jmp .write
.index_dynamic:
 lea rdi,[rel cli_error_buffer_index_dynamic]
 mov esi,cli_error_buffer_index_dynamic_end-cli_error_buffer_index_dynamic
 jmp .write
.read_bounds:
 lea rdi,[rel cli_error_buffer_read_bounds]
 mov esi,cli_error_buffer_read_bounds_end-cli_error_buffer_read_bounds
 jmp .write
.write_bounds:
 lea rdi,[rel cli_error_buffer_write_bounds]
 mov esi,cli_error_buffer_write_bounds_end-cli_error_buffer_write_bounds
 jmp .write
.full:
 lea rdi,[rel cli_error_buffer_full]
 mov esi,cli_error_buffer_full_end-cli_error_buffer_full
 jmp .write
.receiver:
 lea rdi,[rel cli_error_buffer_receiver]
 mov esi,cli_error_buffer_receiver_end-cli_error_buffer_receiver
 jmp .write
.arity:
 lea rdi,[rel cli_error_buffer_arity]
 mov esi,cli_error_buffer_arity_end-cli_error_buffer_arity
 jmp .write
.alias:
 lea rdi,[rel cli_error_buffer_alias]
 mov esi,cli_error_buffer_alias_end-cli_error_buffer_alias
 jmp .write
.reserve:
 lea rdi,[rel cli_error_buffer_reserve]
 mov esi,cli_error_buffer_reserve_end-cli_error_buffer_reserve
 jmp .write
.growth:
 lea rdi,[rel cli_error_buffer_growth]
 mov esi,cli_error_buffer_growth_end-cli_error_buffer_growth
 jmp .write
.extend:
 lea rdi,[rel cli_error_buffer_extend]
 mov esi,cli_error_buffer_extend_end-cli_error_buffer_extend
 jmp .write
.escape:
 lea rdi,[rel cli_error_buffer_escape]
 mov esi,cli_error_buffer_escape_end-cli_error_buffer_escape
 jmp .write
.copy_move:
 lea rdi,[rel cli_error_buffer_copy_move]
 mov esi,cli_error_buffer_copy_move_end-cli_error_buffer_copy_move
 jmp .write
.transport:
 lea rdi,[rel cli_error_buffer_transport]
 mov esi,cli_error_buffer_transport_end-cli_error_buffer_transport
 jmp .write
.freeze_length:
 lea rdi,[rel cli_error_buffer_freeze_length]
 mov esi,cli_error_buffer_freeze_length_end-cli_error_buffer_freeze_length
 jmp .write
.slice_bounds:
 lea rdi,[rel cli_error_buffer_slice_bounds]
 mov esi,cli_error_buffer_slice_bounds_end-cli_error_buffer_slice_bounds
 jmp .write
.slice_escape:
 lea rdi,[rel cli_error_buffer_slice_escape]
 mov esi,cli_error_buffer_slice_escape_end-cli_error_buffer_slice_escape
 jmp .write
.slice_mutation:
 lea rdi,[rel cli_error_buffer_slice_mutation]
 mov esi,cli_error_buffer_slice_mutation_end-cli_error_buffer_slice_mutation
 jmp .write
.slice_stale:
 lea rdi,[rel cli_error_buffer_slice_stale]
 mov esi,cli_error_buffer_slice_stale_end-cli_error_buffer_slice_stale
 jmp .write
.slice_owner:
 lea rdi,[rel cli_error_buffer_slice_owner]
 mov esi,cli_error_buffer_slice_owner_end-cli_error_buffer_slice_owner
 jmp .write
.slice_arity:
 lea rdi,[rel cli_error_buffer_slice_arity]
 mov esi,cli_error_buffer_slice_arity_end-cli_error_buffer_slice_arity
 jmp .write
.internal:
 lea rdi,[rel cli_error_buffer_internal]
 mov esi,cli_error_buffer_internal_end-cli_error_buffer_internal
.write:
 call cli_write_stderr
 mov eax,1
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_nominal:
 lea rdi,[rel cli_nominal]
 mov ecx,NEBOC_NOM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_nominal_variants]
 mov ecx,NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_nominal_plan]
 mov ecx,NEBOC_NOM_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_nominal+NEBOC_NOM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_nominal+NEBOC_NOM_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_nominal+NEBOC_NOM_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_nominal+NEBOC_NOM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_nominal_variants]
 mov [rel cli_nominal+NEBOC_NOM_VARIANTS_OFFSET],rax
 mov qword [rel cli_nominal+NEBOC_NOM_VARIANT_CAPACITY_OFFSET],NEBOC_NOM_MAX_VARIANTS
 lea rdi,[rel cli_nominal]
 call neboc_nominal_parse
 cmp qword [rel cli_nominal+NEBOC_NOM_FOUND_OFFSET],0
 je .done
 test eax,eax
 jnz .done
 lea rdi,[rel cli_nominal]
 call neboc_nominal_analyze
 test eax,eax
 jnz .done
 lea rdi,[rel cli_nominal]
 lea rsi,[rel cli_nominal_plan]
 call neboc_nominal_lower
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_nominal_diagnostic:
 mov rax,[rel cli_nominal+NEBOC_NOM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_NOM_DIAG_IDENTITY
 je .identity
 cmp rax,NEBOC_NOM_DIAG_ABI
 je .abi
 cmp rax,NEBOC_NOM_DIAG_SYNTAX
 je .syntax
 cmp rax,NEBOC_NOM_DIAG_VARIANT
 je .variant
 cmp rax,NEBOC_NOM_DIAG_PAYLOAD
 je .payload
 cmp rax,NEBOC_NOM_DIAG_INTERNAL
 je .internal
.none:
 xor eax,eax
 ret
.identity: lea rdi,[rel cli_error_nom_identity]
 mov esi,cli_error_nom_identity_end-cli_error_nom_identity
 jmp .write
.abi: lea rdi,[rel cli_error_nom_abi]
 mov esi,cli_error_nom_abi_end-cli_error_nom_abi
 jmp .write
.syntax: lea rdi,[rel cli_error_nom_syntax]
 mov esi,cli_error_nom_syntax_end-cli_error_nom_syntax
 jmp .write
.variant: lea rdi,[rel cli_error_nom_variant]
 mov esi,cli_error_nom_variant_end-cli_error_nom_variant
 jmp .write
.payload: lea rdi,[rel cli_error_nom_payload]
 mov esi,cli_error_nom_payload_end-cli_error_nom_payload
 jmp .write
.internal: lea rdi,[rel cli_error_nom_internal]
 mov esi,cli_error_nom_internal_end-cli_error_nom_internal
.write:
 call cli_write_stderr
 mov eax,1
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_composite:
 lea rdi,[rel cli_struct_tuple]
 mov ecx,NEBOC_ST_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_struct_tuple+NEBOC_ST_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_struct_tuple+NEBOC_ST_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_struct_tuple+NEBOC_ST_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_struct_tuple+NEBOC_ST_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_decls]
 mov [rel cli_struct_tuple+NEBOC_ST_DECLS_OFFSET],rax
 mov qword [rel cli_struct_tuple+NEBOC_ST_DECL_CAPACITY_OFFSET],NEBOC_ST_MAX_DECLS
 lea rax,[rel cli_values]
 mov [rel cli_struct_tuple+NEBOC_ST_VALUES_OFFSET],rax
 mov qword [rel cli_struct_tuple+NEBOC_ST_VALUE_CAPACITY_OFFSET],NEBOC_ST_MAX_VALUES
 lea rax,[rel cli_bindings]
 mov [rel cli_struct_tuple+NEBOC_ST_BINDINGS_OFFSET],rax
 mov qword [rel cli_struct_tuple+NEBOC_ST_BINDING_CAPACITY_OFFSET],NEBOC_ST_MAX_BINDINGS
 lea rdi,[rel cli_struct_tuple]
 call neboc_struct_tuple_recognize
 test eax,eax
 jnz .done
 cmp qword [rel cli_struct_tuple+NEBOC_ST_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_struct_tuple]
 lea rsi,[rel option_result_null_externo_e_erros_tipados_cli_plan]
 call neboc_struct_tuple_lower
 test eax,eax
 jz .done
 cmp qword [rel cli_struct_tuple+NEBOC_ST_DIAGNOSTIC_OFFSET],0
 jne .done
 mov qword [rel cli_struct_tuple+NEBOC_ST_DIAGNOSTIC_OFFSET],neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_composite_diagnostic:
 mov rax,[rel cli_struct_tuple+NEBOC_ST_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_DIAG_RECURSIVE_LAYOUT
 je .recursive
 cmp rax,NEBOC_DIAG_LAYOUT_OVERFLOW
 je .overflow
 cmp rax,NEBOC_DIAG_TUPLE_BOUNDS
 je .tuple_bounds
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_DIAG_DUPLICATE_FIELD
 je .duplicate
 cmp rax,NEBOC_DIAG_WRONG_ARITY
 je .arity
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_DIAG_TYPE_MISMATCH
 je .type
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_DIAG_UNKNOWN_FIELD
 je .unknown
 cmp rax,neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX
 je .syntax
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64_native_vertical]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_internal_end_driver_cli_linux_x86_64_native_vertical-option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64_native_vertical
 jmp .write
.recursive:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_001]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_001_end-option_result_null_externo_e_erros_tipados_cli_error_001
 jmp .write
.overflow:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_003]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_003_end-option_result_null_externo_e_erros_tipados_cli_error_003
 jmp .write
.tuple_bounds:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_005]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_005_end-option_result_null_externo_e_erros_tipados_cli_error_005
 jmp .write
.duplicate:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_013]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_013_end-option_result_null_externo_e_erros_tipados_cli_error_013
 jmp .write
.arity:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_014]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_014_end-option_result_null_externo_e_erros_tipados_cli_error_014
 jmp .write
.type:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_015]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_015_end-option_result_null_externo_e_erros_tipados_cli_error_015
 jmp .write
.unknown:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_016]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_016_end-option_result_null_externo_e_erros_tipados_cli_error_016
 jmp .write
.syntax:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_017]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_017_end-option_result_null_externo_e_erros_tipados_cli_error_017
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
cli_recognize_programmer_type:
 lea rdi,[rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request]
 mov ecx,neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request]
 jmp neboc_programmer_type_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
structs_enums_variants_e_tipos_do_programador_cli_report_diagnostic:
 mov rax,[rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .expected_type
 cmp rax,2
 je .duplicate_type
 cmp rax,3
 je .expected_field
 cmp rax,4
 je .duplicate_field
 cmp rax,5
 je .missing_field
 cmp rax,6
 je .unknown_field
 cmp rax,7
 je .field_type
 cmp rax,8
 je .duplicate_variant
 cmp rax,9
 je .payload_type
 cmp rax,10
 je .recursive
 cmp rax,11
 je .empty
 cmp rax,12
 je .deferred
 jmp .none
.expected_type: lea rdi,[rel cli_error_expected_type]
 mov esi,cli_error_expected_type_end-cli_error_expected_type
 jmp .write
.duplicate_type: lea rdi,[rel cli_error_duplicate_type]
 mov esi,cli_error_duplicate_type_end-cli_error_duplicate_type
 jmp .write
.expected_field: lea rdi,[rel cli_error_expected_field]
 mov esi,cli_error_expected_field_end-cli_error_expected_field
 jmp .write
.duplicate_field: lea rdi,[rel cli_error_duplicate_field]
 mov esi,cli_error_duplicate_field_end-cli_error_duplicate_field
 jmp .write
.missing_field: lea rdi,[rel cli_error_missing_field]
 mov esi,cli_error_missing_field_end-cli_error_missing_field
 jmp .write
.unknown_field: lea rdi,[rel cli_error_unknown_field]
 mov esi,cli_error_unknown_field_end-cli_error_unknown_field
 jmp .write
.field_type: lea rdi,[rel cli_error_field_type]
 mov esi,cli_error_field_type_end-cli_error_field_type
 jmp .write
.duplicate_variant: lea rdi,[rel cli_error_duplicate_variant]
 mov esi,cli_error_duplicate_variant_end-cli_error_duplicate_variant
 jmp .write
.payload_type: lea rdi,[rel cli_error_payload_type]
 mov esi,cli_error_payload_type_end-cli_error_payload_type
 jmp .write
.recursive: lea rdi,[rel cli_error_recursive]
 mov esi,cli_error_recursive_end-cli_error_recursive
 jmp .write
.empty: lea rdi,[rel cli_error_empty]
 mov esi,cli_error_empty_end-cli_error_empty
 jmp .write
.deferred: lea rdi,[rel structs_enums_variants_e_tipos_do_programador_cli_error_deferred]
 mov esi,structs_enums_variants_e_tipos_do_programador_cli_error_deferred_end-structs_enums_variants_e_tipos_do_programador_cli_error_deferred
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
cli_recognize_domain_refinement:
 lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request]
 jmp neboc_domain_refinement_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_report_diagnostic:
 mov rax,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .unknown
 cmp rax,2
 je .alias
 cmp rax,3
 je .receiver
 cmp rax,4
 je .arguments
 cmp rax,5
 je .literal
 cmp rax,6
 je .fallback
 cmp rax,7
 je .fallback_positive
 cmp rax,8
 je .constructor
 cmp rax,9
 je .deferred
 cmp rax,10
 je .dynamic
 cmp rax,11
 je .observer
 cmp rax,12
 je .contract
 jmp .none
.unknown: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_unknown]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_unknown_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_unknown
 jmp .write
.alias: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_alias]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_alias_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_alias
 jmp .write
.receiver: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_receiver]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_receiver_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_receiver
 jmp .write
.arguments: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_arguments]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_arguments_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_arguments
 jmp .write
.literal: lea rdi,[rel cli_error_literal]
 mov esi,cli_error_literal_end-cli_error_literal
 jmp .write
.fallback: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_fallback]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_fallback_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_fallback
 jmp .write
.fallback_positive: lea rdi,[rel cli_error_fallback_positive]
 mov esi,cli_error_fallback_positive_end-cli_error_fallback_positive
 jmp .write
.constructor: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_constructor]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_constructor_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_constructor
 jmp .write
.deferred: lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_deferred]
 mov esi,tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_deferred_end-tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_error_deferred
 jmp .write
.dynamic: lea rdi,[rel cli_error_dynamic]
 mov esi,cli_error_dynamic_end-cli_error_dynamic
 jmp .write
.observer: lea rdi,[rel cli_error_observer]
 mov esi,cli_error_observer_end-cli_error_observer
 jmp .write
.contract: lea rdi,[rel cli_error_contract]
 mov esi,cli_error_contract_end-cli_error_contract
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
option_result_null_externo_e_erros_tipados_cli_recognize_generic:
 lea rdi,[rel cli_generic]
 mov ecx,NEBOC_GEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_generic_records]
 mov ecx,NEBOC_GEN_MAX_INSTANCES*NEBOC_GEN_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_generic_plan]
 mov ecx,NEBOC_GEN_PLAN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_generic+NEBOC_GEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_generic+NEBOC_GEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_generic+NEBOC_GEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_generic+NEBOC_GEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_generic_records]
 mov [rel cli_generic+NEBOC_GEN_RECORDS_OFFSET],rax
 mov qword [rel cli_generic+NEBOC_GEN_CAPACITY_OFFSET],NEBOC_GEN_MAX_INSTANCES
 lea rdi,[rel cli_generic]
 call neboc_generic_parse
 cmp qword [rel cli_generic+NEBOC_GEN_FOUND_OFFSET],0
 je .done
 test eax,eax
 jnz .done
 lea rdi,[rel cli_generic]
 call neboc_generic_analyze
 test eax,eax
 jnz .done
 lea rdi,[rel cli_generic]
 lea rsi,[rel cli_generic_plan]
 call neboc_generic_lower
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_generic_diagnostic:
 mov rax,[rel cli_generic+NEBOC_GEN_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,NEBOC_GEN_DIAG_CONSTRAINT
 je .constraint
 cmp rax,NEBOC_GEN_DIAG_BUDGET
 je .budget
 cmp rax,NEBOC_GEN_DIAG_COLLISION
 je .collision
 cmp rax,NEBOC_GEN_DIAG_RECURSIVE
 je .recursive
 cmp rax,NEBOC_GEN_DIAG_SYNTAX
 je .syntax
 cmp rax,NEBOC_GEN_DIAG_TYPE
 je .type
 cmp rax,NEBOC_GEN_DIAG_INTERNAL
 je .internal
.none:
 xor eax,eax
 ret
.constraint: lea rdi,[rel cli_error_gen_constraint]
 mov esi,cli_error_gen_constraint_end-cli_error_gen_constraint
 jmp .write
.budget: lea rdi,[rel cli_error_gen_budget]
 mov esi,cli_error_gen_budget_end-cli_error_gen_budget
 jmp .write
.collision: lea rdi,[rel cli_error_gen_collision]
 mov esi,cli_error_gen_collision_end-cli_error_gen_collision
 jmp .write
.recursive: lea rdi,[rel cli_error_gen_recursive]
 mov esi,cli_error_gen_recursive_end-cli_error_gen_recursive
 jmp .write
.syntax: lea rdi,[rel cli_error_gen_syntax]
 mov esi,cli_error_gen_syntax_end-cli_error_gen_syntax
 jmp .write
.type: lea rdi,[rel cli_error_gen_type]
 mov esi,cli_error_gen_type_end-cli_error_gen_type
 jmp .write
.internal: lea rdi,[rel cli_error_gen_internal]
 mov esi,cli_error_gen_internal_end-cli_error_gen_internal
.write:
 call cli_write_stderr
 mov eax,1
 ret

%undef call
generics_constraints_overload_e_dispatch_cli_recognize_generic:
 lea rdi,[rel generics_constraints_overload_e_dispatch_cli_vertical_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rdi,[rel generics_constraints_overload_e_dispatch_cli_vertical_request]
 jmp neboc_generic_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
generics_constraints_overload_e_dispatch_cli_report_diagnostic:
 mov rax,[rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_DIAGNOSTIC_OFFSET]
 test rax,rax
 jz .none
 cmp rax,1
 je .expected
 cmp rax,2
 je .arity
 cmp rax,3
 je .duplicate
 cmp rax,4
 je .bound_expected
 cmp rax,5
 je .bound_unknown
 cmp rax,6
 je .bound
 cmp rax,7
 je .receiver
 cmp rax,8
 je .return
 cmp rax,9
 je .positionals
 cmp rax,10
 je .explicit
 cmp rax,11
 je .type
 cmp rax,12
 je .alias
 cmp rax,13
 je .no_match
 cmp rax,14
 je .ambiguous
 cmp rax,15
 je .sharing
 xor eax,eax
 ret
.expected: lea rdi,[rel cli_error_expected]
 mov esi,cli_error_expected_end-cli_error_expected
 jmp .write
.arity: lea rdi,[rel generics_constraints_overload_e_dispatch_cli_error_arity]
 mov esi,generics_constraints_overload_e_dispatch_cli_error_arity_end-generics_constraints_overload_e_dispatch_cli_error_arity
 jmp .write
.duplicate: lea rdi,[rel generics_constraints_overload_e_dispatch_cli_error_duplicate]
 mov esi,generics_constraints_overload_e_dispatch_cli_error_duplicate_end-generics_constraints_overload_e_dispatch_cli_error_duplicate
 jmp .write
.bound_expected: lea rdi,[rel cli_error_bound_expected]
 mov esi,cli_error_bound_expected_end-cli_error_bound_expected
 jmp .write
.bound_unknown: lea rdi,[rel cli_error_bound_unknown]
 mov esi,cli_error_bound_unknown_end-cli_error_bound_unknown
 jmp .write
.bound: lea rdi,[rel cli_error_bound]
 mov esi,cli_error_bound_end-cli_error_bound
 jmp .write
.receiver: lea rdi,[rel generics_constraints_overload_e_dispatch_cli_error_receiver]
 mov esi,generics_constraints_overload_e_dispatch_cli_error_receiver_end-generics_constraints_overload_e_dispatch_cli_error_receiver
 jmp .write
.return: lea rdi,[rel cli_error_return]
 mov esi,cli_error_return_end-cli_error_return
 jmp .write
.positionals: lea rdi,[rel cli_error_positionals]
 mov esi,cli_error_positionals_end-cli_error_positionals
 jmp .write
.explicit: lea rdi,[rel cli_error_explicit]
 mov esi,cli_error_explicit_end-cli_error_explicit
 jmp .write
.type: lea rdi,[rel generics_constraints_overload_e_dispatch_cli_error_type]
 mov esi,generics_constraints_overload_e_dispatch_cli_error_type_end-generics_constraints_overload_e_dispatch_cli_error_type
 jmp .write
.alias: lea rdi,[rel generics_constraints_overload_e_dispatch_cli_error_alias]
 mov esi,generics_constraints_overload_e_dispatch_cli_error_alias_end-generics_constraints_overload_e_dispatch_cli_error_alias
 jmp .write
.no_match: lea rdi,[rel cli_error_no_match]
 mov esi,cli_error_no_match_end-cli_error_no_match
 jmp .write
.ambiguous: lea rdi,[rel cli_error_ambiguous]
 mov esi,cli_error_ambiguous_end-cli_error_ambiguous
 jmp .write
.sharing: lea rdi,[rel cli_error_sharing]
 mov esi,cli_error_sharing_end-cli_error_sharing
.write:
 call cli_write_stderr
 mov eax,1
 ret
.none: xor eax,eax
 ret

%undef call
option_result_null_externo_e_erros_tipados_cli_report_frontend_diagnostic:
 mov rax,[rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_ERROR_CODE_OFFSET]
 test rax,rax
 jz .none
 jmp option_result_null_externo_e_erros_tipados_cli_report_diagnostic_code
.none: xor eax,eax
 ret

cli_recognize_option_result:
 lea rdi,[rel cli_sem_request]
 mov ecx,NEBOC_VSEM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_symbols]
 mov ecx,(neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS*NEBOC_VSYM_RECORD_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_sem_request+NEBOC_VSEM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_sem_request+NEBOC_VSEM_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_sem_request+NEBOC_VSEM_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_sem_request+NEBOC_VSEM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_operations]
 mov [rel cli_sem_request+NEBOC_VSEM_OPERATIONS_OFFSET],rax
 mov rax,[rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 mov [rel cli_sem_request+NEBOC_VSEM_OPERATION_COUNT_OFFSET],rax
 lea rax,[rel option_result_null_externo_e_erros_tipados_cli_symbols]
 mov [rel cli_sem_request+NEBOC_VSEM_SYMBOLS_OFFSET],rax
 mov qword [rel cli_sem_request+NEBOC_VSEM_SYMBOL_CAPACITY_OFFSET],neboc_option_result_null_externo_e_erros_tipados_VERTICAL_MAX_SYMBOLS
 lea rdi,[rel cli_sem_request]
 jmp neboc_option_result_vertical_analyze

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
option_result_null_externo_e_erros_tipados_cli_report_semantic_diagnostic:
 mov rax,[rel cli_sem_request+NEBOC_VSEM_ERROR_CODE_OFFSET]
 jmp option_result_null_externo_e_erros_tipados_cli_report_diagnostic_code

option_result_null_externo_e_erros_tipados_cli_report_diagnostic_code:
 cmp rax,1
 je .unknown_container
 cmp rax,2
 je .type_arity
 cmp rax,3
 je .payload_unavailable
 cmp rax,4
 je .variant_mismatch
 cmp rax,5
 je .variant_arity
 cmp rax,6
 je .observer_unknown
 cmp rax,7
 je .observer_domain
 cmp rax,8
 je .observer_arity
 cmp rax,9
 je .unwrap_arity
 cmp rax,10
 je .null
 cmp rax,11
 je .propagation
 cmp rax,12
 je .try
 cmp rax,13
 je .fatal
 cmp rax,14
 je .match
 cmp rax,15
 je .alias
 cmp rax,16
 je .void_payload
 cmp rax,17
 je .generics
 cmp rax,18
 je .payload_mismatch
 cmp rax,19
 je .context
 cmp rax,20
 je .fallback
 cmp rax,21
 je .receiver
 cmp rax,22
 je .span
 cmp rax,23
 je .unknown_binding
 cmp rax,24
 je .duplicate_binding
 cmp rax,25
 je .internal
 xor eax,eax
 ret
.unknown_container: lea rdi,[rel cli_error_unknown_container]
 mov esi,cli_error_unknown_container_end-cli_error_unknown_container
 jmp .write
.type_arity: lea rdi,[rel cli_error_type_arity]
 mov esi,cli_error_type_arity_end-cli_error_type_arity
 jmp .write
.payload_unavailable: lea rdi,[rel cli_error_payload_unavailable]
 mov esi,cli_error_payload_unavailable_end-cli_error_payload_unavailable
 jmp .write
.variant_mismatch: lea rdi,[rel cli_error_variant_mismatch]
 mov esi,cli_error_variant_mismatch_end-cli_error_variant_mismatch
 jmp .write
.variant_arity: lea rdi,[rel cli_error_variant_arity]
 mov esi,cli_error_variant_arity_end-cli_error_variant_arity
 jmp .write
.observer_unknown: lea rdi,[rel cli_error_observer_unknown]
 mov esi,cli_error_observer_unknown_end-cli_error_observer_unknown
 jmp .write
.observer_domain: lea rdi,[rel cli_error_observer_domain]
 mov esi,cli_error_observer_domain_end-cli_error_observer_domain
 jmp .write
.observer_arity: lea rdi,[rel cli_error_observer_arity]
 mov esi,cli_error_observer_arity_end-cli_error_observer_arity
 jmp .write
.unwrap_arity: lea rdi,[rel cli_error_unwrap_arity]
 mov esi,cli_error_unwrap_arity_end-cli_error_unwrap_arity
 jmp .write
.null: lea rdi,[rel cli_error_null]
 mov esi,cli_error_null_end-cli_error_null
 jmp .write
.propagation: lea rdi,[rel cli_error_propagation]
 mov esi,cli_error_propagation_end-cli_error_propagation
 jmp .write
.try: lea rdi,[rel cli_error_try]
 mov esi,cli_error_try_end-cli_error_try
 jmp .write
.fatal: lea rdi,[rel cli_error_fatal]
 mov esi,cli_error_fatal_end-cli_error_fatal
 jmp .write
.match: lea rdi,[rel cli_error_match]
 mov esi,cli_error_match_end-cli_error_match
 jmp .write
.alias: lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_alias]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_alias_end-option_result_null_externo_e_erros_tipados_cli_error_alias
 jmp .write
.void_payload: lea rdi,[rel cli_error_void_payload]
 mov esi,cli_error_void_payload_end-cli_error_void_payload
 jmp .write
.generics: lea rdi,[rel cli_error_generics]
 mov esi,cli_error_generics_end-cli_error_generics
 jmp .write
.payload_mismatch: lea rdi,[rel cli_error_payload_mismatch]
 mov esi,cli_error_payload_mismatch_end-cli_error_payload_mismatch
 jmp .write
.context: lea rdi,[rel cli_error_context]
 mov esi,cli_error_context_end-cli_error_context
 jmp .write
.fallback: lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_fallback]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_fallback_end-option_result_null_externo_e_erros_tipados_cli_error_fallback
 jmp .write
.receiver: lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_receiver]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_receiver_end-option_result_null_externo_e_erros_tipados_cli_error_receiver
 jmp .write
.span: lea rdi,[rel cli_error_span]
 mov esi,cli_error_span_end-cli_error_span
 jmp .write
.unknown_binding: lea rdi,[rel cli_error_unknown_binding]
 mov esi,cli_error_unknown_binding_end-cli_error_unknown_binding
 jmp .write
.duplicate_binding: lea rdi,[rel cli_error_duplicate_binding]
 mov esi,cli_error_duplicate_binding_end-cli_error_duplicate_binding
 jmp .write
.internal: lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_internal_end_driver_cli_linux_x86_64-option_result_null_externo_e_erros_tipados_cli_error_internal_driver_cli_linux_x86_64
.write:
 call cli_write_stderr
 mov eax,1
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_bindings:
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request]
 mov ecx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ROOT_ID_OFFSET],rax
 lea rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_symbols]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_SYMBOL_CAPACITY_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS
 lea rax,[rel cli_branch_a]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_A_OFFSET],rax
 lea rax,[rel cli_branch_b]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_B_OFFSET],rax
 lea rax,[rel cli_loop_snapshots]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_LOOP_SNAPSHOTS_OFFSET],rax
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_MAX_DEPTH_OFFSET],NEBOC_VERTICAL_DEFAULT_MAX_DEPTH
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request]
 call neboc_binding_vertical_recognize
 test eax,eax
 jnz .done
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 je .done
 lea rdi,[rel cli_ast_builder]
 lea rsi,[rel cli_loop_plan]
 call neboc_loop_plan_lower
 test eax,eax
 jz .done
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_LOOP_CFG_INVARIANT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 ret

%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
bindings_constantes_mutabilidade_e_definite_assignment_cli_report_semantic_diagnostic:
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET]
 jmp bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code

bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code:
 cmp rax,NEBOC_DIAG_MUTABLE_SYNTAX
 je ._001
 cmp rax,NEBOC_DIAG_MUTABLE_DUPLICATED
 je ._002
 cmp rax,NEBOC_DIAG_MUTABLE_MISSING_INITIALIZER
 je ._003
 cmp rax,NEBOC_DIAG_MUTABLE_UNSUPPORTED_TYPE
 je ._004
 cmp rax,NEBOC_DIAG_ASSIGNMENT_UNDECLARED
 je ._005
 cmp rax,NEBOC_DIAG_ASSIGNMENT_IMMUTABLE
 je ._006
 cmp rax,NEBOC_DIAG_ASSIGNMENT_NOT_LVALUE
 je ._007
 cmp rax,NEBOC_DIAG_ASSIGNMENT_OUT_OF_SCOPE
 je ._008
 cmp rax,NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
 je ._010
 cmp rax,NEBOC_DIAG_ASSIGNMENT_EXPRESSION
 je ._012
 cmp rax,NEBOC_DIAG_ASSIGNMENT_CHAINED
 je ._013
 cmp rax,NEBOC_DIAG_COMPOUND_UNSUPPORTED
 je ._014
 cmp rax,NEBOC_DIAG_BREAK_OUTSIDE_LOOP
 je ._030
 cmp rax,NEBOC_DIAG_CONTINUE_OUTSIDE_LOOP
 je ._031
 cmp rax,NEBOC_DIAG_WHILE_CONDITION_TYPE
 je ._032
 cmp rax,NEBOC_DIAG_LOOP_CFG_INVARIANT
 je ._034
 cmp rax,NEBOC_DIAG_LOOP_NESTING
 je ._036
 cmp rax,NEBOC_BIND_DIAG_UNDEFINED_NAME
 je .undefined
 cmp rax,NEBOC_BIND_DIAG_USE_BEFORE_INITIALIZATION
 je .use_before
 cmp rax,NEBOC_BIND_DIAG_DUPLICATE_DECLARATION
 je .duplicate
 cmp rax,NEBOC_BIND_DIAG_ALREADY_INITIALIZED
 je .already
 cmp rax,NEBOC_BIND_DIAG_SHADOWING_FORBIDDEN
 je .shadow
 cmp rax,NEBOC_BIND_DIAG_RESERVED_NAME
 je .reserved
 cmp rax,NEBOC_BIND_DIAG_VOID_FORBIDDEN
 je .void
 cmp rax,NEBOC_BIND_DIAG_TYPE_MISMATCH
 je .type
 cmp rax,NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 je .not_definite
 cmp rax,NEBOC_BIND_DIAG_ASSIGNMENT_SYNTAX_UNAVAILABLE
 je .assignment
 cmp rax,NEBOC_BIND_DIAG_CONST_DECLARATION_DEFERRED
 je .const
 cmp rax,NEBOC_BIND_DIAG_MUTABLE_DECLARATION_DEFERRED
 je .mutable
 cmp rax,NEBOC_BIND_DIAG_NAMED_ARGUMENTS_DEFERRED
 je .named
 cmp rax,NEBOC_BIND_DIAG_INVALID_NAME
 je .invalid
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 je ._receiver
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_ARGUMENT
 je ._argument
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_ARITY
 je ._arity
 cmp rax,NEBOC_DIAG_SHIFT_WRONG_TYPE
 je ._shift_type
 cmp rax,NEBOC_DIAG_SHIFT_DYNAMIC
 je ._shift_dynamic
 cmp rax,NEBOC_DIAG_SHIFT_OUT_OF_RANGE
 je ._shift_range
 cmp rax,NEBOC_DIAG_POSITION_WRONG_TYPE
 je ._position_type
 cmp rax,NEBOC_DIAG_POSITION_DYNAMIC
 je ._position_dynamic
 cmp rax,NEBOC_DIAG_POSITION_OUT_OF_RANGE
 je ._position_range
 xor eax,eax
 ret
.undefined: lea rdi,[rel cli_error_undefined]
 mov esi,cli_error_undefined_end-cli_error_undefined
 jmp .write
.use_before: lea rdi,[rel cli_error_use_before]
 mov esi,cli_error_use_before_end-cli_error_use_before
 jmp .write
.duplicate: lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_duplicate]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_duplicate_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_duplicate
 jmp .write
.already: lea rdi,[rel cli_error_already]
 mov esi,cli_error_already_end-cli_error_already
 jmp .write
.shadow: lea rdi,[rel cli_error_shadow]
 mov esi,cli_error_shadow_end-cli_error_shadow
 jmp .write
.reserved: lea rdi,[rel cli_error_reserved]
 mov esi,cli_error_reserved_end-cli_error_reserved
 jmp .write
.void: lea rdi,[rel cli_error_void]
 mov esi,cli_error_void_end-cli_error_void
 jmp .write
.type: lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_error_type]
 mov esi,bindings_constantes_mutabilidade_e_definite_assignment_cli_error_type_end-bindings_constantes_mutabilidade_e_definite_assignment_cli_error_type
 jmp .write
.not_definite: lea rdi,[rel cli_error_not_definite]
 mov esi,cli_error_not_definite_end-cli_error_not_definite
 jmp .write
.assignment: lea rdi,[rel cli_error_assignment]
 mov esi,cli_error_assignment_end-cli_error_assignment
 jmp .write
.const: lea rdi,[rel cli_error_const]
 mov esi,cli_error_const_end-cli_error_const
 jmp .write
.mutable: lea rdi,[rel cli_error_mutable]
 mov esi,cli_error_mutable_end-cli_error_mutable
 jmp .write
.named: lea rdi,[rel cli_error_named]
 mov esi,cli_error_named_end-cli_error_named
 jmp .write
.invalid: lea rdi,[rel cli_error_invalid]
 mov esi,cli_error_invalid_end-cli_error_invalid
 jmp .write
._001: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_001]
 mov esi,literais_numericos_bases_e_representacao_cli_error_001_end-literais_numericos_bases_e_representacao_cli_error_001
 jmp .write
._002: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_002]
 mov esi,literais_numericos_bases_e_representacao_cli_error_002_end-literais_numericos_bases_e_representacao_cli_error_002
 jmp .write
._003: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_003]
 mov esi,literais_numericos_bases_e_representacao_cli_error_003_end-literais_numericos_bases_e_representacao_cli_error_003
 jmp .write
._004: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_004]
 mov esi,literais_numericos_bases_e_representacao_cli_error_004_end-literais_numericos_bases_e_representacao_cli_error_004
 jmp .write
._005: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_005]
 mov esi,literais_numericos_bases_e_representacao_cli_error_005_end-literais_numericos_bases_e_representacao_cli_error_005
 jmp .write
._006: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_006]
 mov esi,literais_numericos_bases_e_representacao_cli_error_006_end-literais_numericos_bases_e_representacao_cli_error_006
 jmp .write
._007: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_007]
 mov esi,literais_numericos_bases_e_representacao_cli_error_007_end-literais_numericos_bases_e_representacao_cli_error_007
 jmp .write
._008: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_008]
 mov esi,literais_numericos_bases_e_representacao_cli_error_008_end-literais_numericos_bases_e_representacao_cli_error_008
 jmp .write
._010: lea rdi,[rel cli_error_010]
 mov esi,cli_error_010_end-cli_error_010
 jmp .write
._012: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_012]
 mov esi,literais_numericos_bases_e_representacao_cli_error_012_end-literais_numericos_bases_e_representacao_cli_error_012
 jmp .write
._013: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_013]
 mov esi,literais_numericos_bases_e_representacao_cli_error_013_end-literais_numericos_bases_e_representacao_cli_error_013
 jmp .write
._014: lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_014]
 mov esi,literais_numericos_bases_e_representacao_cli_error_014_end-literais_numericos_bases_e_representacao_cli_error_014
 jmp .write
._030: lea rdi,[rel cli_error_030]
 mov esi,cli_error_030_end-cli_error_030
 jmp .write
._031: lea rdi,[rel cli_error_031]
 mov esi,cli_error_031_end-cli_error_031
 jmp .write
._032: lea rdi,[rel cli_error_032]
 mov esi,cli_error_032_end-cli_error_032
 jmp .write
._034: lea rdi,[rel cli_error_034]
 mov esi,cli_error_034_end-cli_error_034
 jmp .write
._036: lea rdi,[rel cli_error_036]
 mov esi,cli_error_036_end-cli_error_036
 jmp .write
._receiver: lea rdi,[rel cli_error_bit_receiver]
 mov esi,cli_error_bit_receiver_end-cli_error_bit_receiver
 jmp .write
._argument: lea rdi,[rel cli_error_bit_argument]
 mov esi,cli_error_bit_argument_end-cli_error_bit_argument
 jmp .write
._arity: lea rdi,[rel cli_error_bit_arity]
 mov esi,cli_error_bit_arity_end-cli_error_bit_arity
 jmp .write
._shift_type: lea rdi,[rel cli_error_shift_type]
 mov esi,cli_error_shift_type_end-cli_error_shift_type
 jmp .write
._shift_dynamic: lea rdi,[rel cli_error_shift_dynamic]
 mov esi,cli_error_shift_dynamic_end-cli_error_shift_dynamic
 jmp .write
._shift_range: lea rdi,[rel cli_error_shift_range]
 mov esi,cli_error_shift_range_end-cli_error_shift_range
 jmp .write
._position_type: lea rdi,[rel cli_error_position_type]
 mov esi,cli_error_position_type_end-cli_error_position_type
 jmp .write
._position_dynamic: lea rdi,[rel cli_error_position_dynamic]
 mov esi,cli_error_position_dynamic_end-cli_error_position_dynamic
 jmp .write
._position_range: lea rdi,[rel cli_error_position_range]
 mov esi,cli_error_position_range_end-cli_error_position_range
.write:
 call cli_write_stderr
 mov eax,1
 ret

; RAX=cli_driver literais_numericos_bases_e_representacao diagnostic. Reuse the exact message routing above without
; aliasing legacy bindings_constantes_mutabilidade_e_definite_assignment diagnostic identifiers.
literais_numericos_bases_e_representacao_cli_report_diagnostic_code:
 cmp rax,NEBOC_DIAG_MUTABLE_SYNTAX
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._001
 cmp rax,NEBOC_DIAG_MUTABLE_DUPLICATED
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._002
 cmp rax,NEBOC_DIAG_MUTABLE_MISSING_INITIALIZER
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._003
 cmp rax,NEBOC_DIAG_ASSIGNMENT_NOT_LVALUE
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._007
 cmp rax,NEBOC_DIAG_ASSIGNMENT_EXPRESSION
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._012
 cmp rax,NEBOC_DIAG_ASSIGNMENT_CHAINED
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._013
 cmp rax,NEBOC_DIAG_COMPOUND_UNSUPPORTED
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._014
 cmp rax,NEBOC_DIAG_BREAK_OUTSIDE_LOOP
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._030
 cmp rax,NEBOC_DIAG_CONTINUE_OUTSIDE_LOOP
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._031
 cmp rax,NEBOC_DIAG_WHILE_CONDITION_TYPE
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._032
 cmp rax,NEBOC_DIAG_LOOP_CFG_INVARIANT
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._034
 cmp rax,NEBOC_DIAG_LOOP_NESTING
 je bindings_constantes_mutabilidade_e_definite_assignment_cli_report_diagnostic_code._036
 xor eax,eax
 ret

%undef call
cli_recognize_text_char_bytes:
 lea rdi,[rel text_char_unicode_e_bytes_cli_vertical_request]
 mov ecx,neboc_text_char_unicode_e_bytes_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ROOT_ID_OFFSET],rax
 lea rdi,[rel text_char_unicode_e_bytes_cli_vertical_request]
 jmp neboc_text_char_bytes_vertical_recognize

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
text_char_unicode_e_bytes_cli_report_semantic_diagnostic:
 mov rax,[rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET]
 cmp rax,NEBOC_API_DIAG_UNKNOWN
 je .unknown
 cmp rax,neboc_text_char_unicode_e_bytes_API_DIAG_ALIAS_FORBIDDEN
 je .alias
 cmp rax,neboc_text_char_unicode_e_bytes_API_DIAG_ARGUMENTS_NOT_ALLOWED
 je .arguments
 cmp rax,NEBOC_API_DIAG_RECEIVER_MUST_BE_TEXT
 je .text
 cmp rax,NEBOC_API_DIAG_RECEIVER_MUST_BE_CHAR
 je .char
 cmp rax,NEBOC_API_DIAG_RECEIVER_MUST_BE_BYTES
 je .bytes
 cmp rax,NEBOC_API_DIAG_TYPE_RECEIVER_REQUIRED
 je .type
 cmp rax,NEBOC_API_DIAG_INSTANCE_RECEIVER_REQUIRED
 je .instance
 cmp rax,neboc_text_char_unicode_e_bytes_API_DIAG_DEFERRED_API
 je .deferred
 cmp rax,NEBOC_API_DIAG_BYTES_LITERAL_UNAVAILABLE
 je .bytes_literal
 cmp rax,NEBOC_DIAG_FROM_BYTE_ARITY
 je ._from_byte_arity
 cmp rax,NEBOC_DIAG_FROM_VALUES_ARITY
 je ._from_values_arity
 cmp rax,NEBOC_DIAG_CONSTRUCTOR_NON_INT
 je ._constructor_type
 cmp rax,NEBOC_DIAG_CONSTRUCTOR_DYNAMIC
 je ._constructor_dynamic
 cmp rax,NEBOC_DIAG_BYTE_BELOW_ZERO
 je ._byte_below
 cmp rax,NEBOC_DIAG_BYTE_ABOVE_255
 je ._byte_above
 cmp rax,NEBOC_DIAG_INDEX_WRONG_TYPE
 je ._index_type
 cmp rax,NEBOC_DIAG_INDEX_DYNAMIC
 je ._index_dynamic
 cmp rax,NEBOC_DIAG_AT_OUT_OF_BOUNDS
 je ._at_bounds
 cmp rax,NEBOC_DIAG_SLICE_INVALID_RANGE
 je ._slice_range
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 je ._bit_receiver
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_ARGUMENT
 je ._bit_argument
 cmp rax,NEBOC_DIAG_BITWISE_WRONG_ARITY
 je ._bit_arity
 cmp rax,NEBOC_DIAG_SHIFT_WRONG_TYPE
 je ._shift_type
 cmp rax,NEBOC_DIAG_SHIFT_DYNAMIC
 je ._shift_dynamic
 cmp rax,NEBOC_DIAG_SHIFT_OUT_OF_RANGE
 je ._shift_range
 cmp rax,NEBOC_DIAG_POSITION_WRONG_TYPE
 je ._position_type
 cmp rax,NEBOC_DIAG_POSITION_DYNAMIC
 je ._position_dynamic
 cmp rax,NEBOC_DIAG_POSITION_OUT_OF_RANGE
 je ._position_range
 xor eax,eax
 ret
.unknown: lea rdi,[rel text_char_unicode_e_bytes_cli_error_unknown]
 mov esi,text_char_unicode_e_bytes_cli_error_unknown_end-text_char_unicode_e_bytes_cli_error_unknown
 jmp .write
.alias: lea rdi,[rel text_char_unicode_e_bytes_cli_error_alias]
 mov esi,text_char_unicode_e_bytes_cli_error_alias_end-text_char_unicode_e_bytes_cli_error_alias
 jmp .write
.arguments: lea rdi,[rel text_char_unicode_e_bytes_cli_error_arguments]
 mov esi,text_char_unicode_e_bytes_cli_error_arguments_end-text_char_unicode_e_bytes_cli_error_arguments
 jmp .write
.text: lea rdi,[rel cli_error_need_text]
 mov esi,cli_error_need_text_end-cli_error_need_text
 jmp .write
.char: lea rdi,[rel cli_error_need_char]
 mov esi,cli_error_need_char_end-cli_error_need_char
 jmp .write
.bytes: lea rdi,[rel cli_error_need_bytes]
 mov esi,cli_error_need_bytes_end-cli_error_need_bytes
 jmp .write
.type: lea rdi,[rel cli_error_type_receiver]
 mov esi,cli_error_type_receiver_end-cli_error_type_receiver
 jmp .write
.instance: lea rdi,[rel cli_error_instance_receiver]
 mov esi,cli_error_instance_receiver_end-cli_error_instance_receiver
 jmp .write
.deferred: lea rdi,[rel text_char_unicode_e_bytes_cli_error_deferred]
 mov esi,text_char_unicode_e_bytes_cli_error_deferred_end-text_char_unicode_e_bytes_cli_error_deferred
 jmp .write
.bytes_literal: lea rdi,[rel cli_error_bytes_literal]
 mov esi,cli_error_bytes_literal_end-cli_error_bytes_literal
 jmp .write
._from_byte_arity: lea rdi,[rel cli_error_from_byte_arity]
 mov esi,cli_error_from_byte_arity_end-cli_error_from_byte_arity
 jmp .write
._from_values_arity: lea rdi,[rel cli_error_from_values_arity]
 mov esi,cli_error_from_values_arity_end-cli_error_from_values_arity
 jmp .write
._constructor_type: lea rdi,[rel cli_error_constructor_type]
 mov esi,cli_error_constructor_type_end-cli_error_constructor_type
 jmp .write
._constructor_dynamic: lea rdi,[rel cli_error_constructor_dynamic]
 mov esi,cli_error_constructor_dynamic_end-cli_error_constructor_dynamic
 jmp .write
._byte_below: lea rdi,[rel cli_error_byte_below]
 mov esi,cli_error_byte_below_end-cli_error_byte_below
 jmp .write
._byte_above: lea rdi,[rel cli_error_byte_above]
 mov esi,cli_error_byte_above_end-cli_error_byte_above
 jmp .write
._index_type: lea rdi,[rel cli_error_index_type]
 mov esi,cli_error_index_type_end-cli_error_index_type
 jmp .write
._index_dynamic: lea rdi,[rel cli_error_index_dynamic]
 mov esi,cli_error_index_dynamic_end-cli_error_index_dynamic
 jmp .write
._at_bounds: lea rdi,[rel cli_error_at_bounds]
 mov esi,cli_error_at_bounds_end-cli_error_at_bounds
 jmp .write
._slice_range: lea rdi,[rel cli_error_slice_range]
 mov esi,cli_error_slice_range_end-cli_error_slice_range
 jmp .write
._bit_receiver: lea rdi,[rel cli_error_bit_receiver]
 mov esi,cli_error_bit_receiver_end-cli_error_bit_receiver
 jmp .write
._bit_argument: lea rdi,[rel cli_error_bit_argument]
 mov esi,cli_error_bit_argument_end-cli_error_bit_argument
 jmp .write
._bit_arity: lea rdi,[rel cli_error_bit_arity]
 mov esi,cli_error_bit_arity_end-cli_error_bit_arity
 jmp .write
._shift_type: lea rdi,[rel cli_error_shift_type]
 mov esi,cli_error_shift_type_end-cli_error_shift_type
 jmp .write
._shift_dynamic: lea rdi,[rel cli_error_shift_dynamic]
 mov esi,cli_error_shift_dynamic_end-cli_error_shift_dynamic
 jmp .write
._shift_range: lea rdi,[rel cli_error_shift_range]
 mov esi,cli_error_shift_range_end-cli_error_shift_range
 jmp .write
._position_type: lea rdi,[rel cli_error_position_type]
 mov esi,cli_error_position_type_end-cli_error_position_type
 jmp .write
._position_dynamic: lea rdi,[rel cli_error_position_dynamic]
 mov esi,cli_error_position_dynamic_end-cli_error_position_dynamic
 jmp .write
._position_range: lea rdi,[rel cli_error_position_range]
 mov esi,cli_error_position_range_end-cli_error_position_range
.write:
 call cli_write_stderr
 mov eax,1
 ret

; Detect the token-level `as` cast spelling before the Pratt parser reports a
; generic syntax failure. Returns 1 when the seguranca_numerica_conversoes_e_overflow diagnostic was recorded.
%undef call
cli_detect_cast_syntax:
 push rbx
 push r12
 push r13
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,2
 jne .next
 lea rsi,[rel cli_source]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp byte [rsi],'a'
 jne .next
 cmp byte [rsi+1],'s'
 jne .next
 ; Require an expression-like token before `as` and Int/Float after it so a
 ; user identifier named `as` is not intercepted outside cast syntax.
 test r13,r13
 jz .next
 mov rdx,r13
 dec rdx
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,rbx
 mov r8,[rdx+NEBOC_TOKEN_KIND_OFFSET]
 cmp r8,NEBOC_TOKEN_INTEGER
 je .cast_prev_ok
 cmp r8,NEBOC_TOKEN_FLOAT
 je .cast_prev_ok
 cmp r8,NEBOC_TOKEN_IDENTIFIER
 je .cast_prev_ok
 cmp r8,NEBOC_TOKEN_RPAREN
 jne .next
.cast_prev_ok:
 mov rdx,r13
 inc rdx
 cmp rdx,r12
 jae .next
 imul rdx,NEBOC_TOKEN_SIZE
 add rdx,rbx
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rsi,[rel cli_source]
 add rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,3
 jne .cast_check_float
 cmp byte [rsi],'I'
 jne .next
 cmp byte [rsi+1],'n'
 jne .next
 cmp byte [rsi+2],'t'
 jne .next
 jmp .cast_found
.cast_check_float:
 cmp rcx,5
 jne .next
 cmp byte [rsi],'F'
 jne .next
 cmp byte [rsi+1],'l'
 jne .next
 cmp byte [rsi+2],'o'
 jne .next
 cmp byte [rsi+3],'a'
 jne .next
 cmp byte [rsi+4],'t'
 jne .next
.cast_found:
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_frontend_diagnostic],NEBOC_VERTICAL_ERROR_CAST_SYNTAX_UNAVAILABLE
 mov eax,1
 jmp .done
.next:
 inc r13
 jmp .loop
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
seguranca_numerica_conversoes_e_overflow_cli_report_frontend_diagnostic:
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_frontend_diagnostic],NEBOC_VERTICAL_ERROR_CAST_SYNTAX_UNAVAILABLE
 jne .none
 lea rdi,[rel cli_error_cast]
 mov esi,cli_error_cast_end-cli_error_cast
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret

%undef call
cli_recognize_numeric_safety:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ROOT_ID_OFFSET],rax
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request]
 jmp neboc_numeric_safety_vertical_recognize

seguranca_numerica_conversoes_e_overflow_cli_report_semantic_diagnostic:
 mov rax,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET]
 cmp rax,NEBOC_VERTICAL_ERROR_UNKNOWN_API
 je .unknown
 cmp rax,NEBOC_VERTICAL_ERROR_ALIAS_FORBIDDEN
 je .alias
 cmp rax,NEBOC_VERTICAL_ERROR_ARGUMENTS_NOT_ALLOWED
 je .args
 cmp rax,NEBOC_VERTICAL_ERROR_RECEIVER_MUST_BE_INT
 je .need_int
 cmp rax,NEBOC_VERTICAL_ERROR_RECEIVER_MUST_BE_FLOAT
 je .need_float
 cmp rax,NEBOC_VERTICAL_ERROR_IMPLICIT_COERCION_FORBIDDEN
 je .implicit
 cmp rax,NEBOC_VERTICAL_ERROR_CAST_SYNTAX_UNAVAILABLE
 je .cast
 cmp rax,NEBOC_VERTICAL_ERROR_DEFERRED_API
 je .deferred
 cmp rax,NEBOC_VERTICAL_ERROR_CROSS_TYPE_CONSTRUCTOR_FORBIDDEN
 je .constructor
 jmp .unknown
.unknown:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_unknown]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_unknown_end-seguranca_numerica_conversoes_e_overflow_cli_error_unknown
 jmp cli_write_stderr
.alias:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_alias]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_alias_end-seguranca_numerica_conversoes_e_overflow_cli_error_alias
 jmp cli_write_stderr
.args:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_arguments]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_arguments_end-seguranca_numerica_conversoes_e_overflow_cli_error_arguments
 jmp cli_write_stderr
.need_int:
 lea rdi,[rel cli_error_need_int]
 mov esi,cli_error_need_int_end-cli_error_need_int
 jmp cli_write_stderr
.need_float:
 lea rdi,[rel cli_error_need_float]
 mov esi,cli_error_need_float_end-cli_error_need_float
 jmp cli_write_stderr
.implicit:
 lea rdi,[rel cli_error_implicit]
 mov esi,cli_error_implicit_end-cli_error_implicit
 jmp cli_write_stderr
.cast:
 lea rdi,[rel cli_error_cast]
 mov esi,cli_error_cast_end-cli_error_cast
 jmp cli_write_stderr
.deferred:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_deferred]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_deferred_end-seguranca_numerica_conversoes_e_overflow_cli_error_deferred
 jmp cli_write_stderr
.constructor:
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_error_constructor]
 mov esi,seguranca_numerica_conversoes_e_overflow_cli_error_constructor_end-seguranca_numerica_conversoes_e_overflow_cli_error_constructor
 jmp cli_write_stderr

; Print the first stable literais_numericos_bases_e_representacao public numeric diagnostic, if present.
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_report_numeric_diagnostic:
 push rbx
 push r12
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor ecx,ecx
._diag_loop:
 cmp rcx,r12
 jae ._diag_done
 mov rax,rcx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INVALID_NUMERIC_LITERAL
 jne ._diag_next
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rdx,NEBOC_NUMERIC_DIAG_MISSING_DIGITS
 je ._missing
 cmp rdx,NEBOC_NUMERIC_DIAG_INVALID_DIGIT
 je ._digit
 cmp rdx,NEBOC_NUMERIC_DIAG_INVALID_SEPARATOR
 je ._separator
 cmp rdx,NEBOC_NUMERIC_DIAG_UPPERCASE_PREFIX
 je ._upper
 cmp rdx,NEBOC_NUMERIC_DIAG_UNKNOWN_PREFIX
 je ._unknown
 cmp rdx,NEBOC_NUMERIC_DIAG_SUFFIX_UNAVAILABLE
 je ._suffix
 cmp rdx,NEBOC_NUMERIC_DIAG_OVERFLOW
 je ._overflow
 cmp rdx,NEBOC_NUMERIC_DIAG_FLOAT_SEPARATOR_UNAVAILABLE
 je ._float_separator
 jmp ._diag_done
._missing:
 lea rdi,[rel cli_error_missing_digits]
 mov esi,cli_error_missing_digits_end-cli_error_missing_digits
 jmp ._write
._digit:
 lea rdi,[rel cli_error_invalid_digit]
 mov esi,cli_error_invalid_digit_end-cli_error_invalid_digit
 jmp ._write
._separator:
 lea rdi,[rel cli_error_invalid_separator]
 mov esi,cli_error_invalid_separator_end-cli_error_invalid_separator
 jmp ._write
._upper:
 lea rdi,[rel cli_error_uppercase_prefix]
 mov esi,cli_error_uppercase_prefix_end-cli_error_uppercase_prefix
 jmp ._write
._unknown:
 lea rdi,[rel cli_error_unknown_prefix]
 mov esi,cli_error_unknown_prefix_end-cli_error_unknown_prefix
 jmp ._write
._suffix:
 lea rdi,[rel cli_error_suffix]
 mov esi,cli_error_suffix_end-cli_error_suffix
 jmp ._write
._overflow:
 lea rdi,[rel literais_numericos_bases_e_representacao_cli_error_overflow]
 mov esi,literais_numericos_bases_e_representacao_cli_error_overflow_end-literais_numericos_bases_e_representacao_cli_error_overflow
 jmp ._write
._float_separator:
 lea rdi,[rel cli_error_float_separator]
 mov esi,cli_error_float_separator_end-cli_error_float_separator
._write:
 call cli_write_stderr
 jmp ._diag_done
._diag_next:
 inc rcx
 jmp ._diag_loop
._diag_done:
 pop r12
 pop rbx
 ret

; Run the bounded PF003 Float recognizer after all opaque bodies are materialized.
%undef call
cli_recognize_foundation_float:
 push rbx
 lea rdi,[rel cli_float_sem_request]
 mov ecx,NEBOC_FLOAT_SEM_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel cli_float_sem_request+NEBOC_FLOAT_SEM_ROOT_ID_OFFSET],rax
 lea rdi,[rel cli_float_sem_request]
 call neboc_foundation_float_recognize
 pop rbx
 ret


; Emit a stable tipos_primitivos_escalares diagnostic before the generic CLI source-error line.
cli_report_float_semantic_diagnostic:
 mov rax,[rel cli_float_sem_request+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET]
 cmp rax,NEBOC_FLOAT_SEM_ERROR_INVALID_CONSTRUCTOR
 je .constructor
 cmp rax,NEBOC_FLOAT_SEM_ERROR_MIXED_NUMERIC_TYPES
 je .mixed
 cmp rax,NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_OPERATOR
 je .operator
 lea rdi,[rel cli_error_float_context]
 mov esi,cli_error_float_context_end-cli_error_float_context
 jmp cli_write_stderr
.constructor:
 lea rdi,[rel cli_error_float_constructor]
 mov esi,cli_error_float_constructor_end-cli_error_float_constructor
 jmp cli_write_stderr
.mixed:
 lea rdi,[rel cli_error_float_mixed]
 mov esi,cli_error_float_mixed_end-cli_error_float_mixed
 jmp cli_write_stderr
.operator:
 lea rdi,[rel cli_error_float_operator]
 mov esi,cli_error_float_operator_end-cli_error_float_operator
 jmp cli_write_stderr

cli_report_float_codegen_diagnostic:
 mov rax,[rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET]
 cmp rax,NEBOC_FLOAT_CODEGEN_ERROR_LITERAL
 je cli_report_float_literal_diagnostic
 lea rdi,[rel cli_error_float_context]
 mov esi,cli_error_float_context_end-cli_error_float_context
 jmp cli_write_stderr

cli_report_float_literal_diagnostic:
 lea rdi,[rel cli_error_float_literal]
 mov esi,cli_error_float_literal_end-cli_error_float_literal
 jmp cli_write_stderr

; TIPOS-PRIMITIVOS-ESCALARES-PF005: materialize and classify every strict Float token before codegen.
cli_materialize_foundation_float_vertical:
 push rbx
 push r12
 push r13
 push r14
 push r15
 lea r12,[rel cli_tokens]
 mov r13,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 lea r15,[rel cli_source]
 xor r14d,r14d
.vertical_loop:
 cmp r14,r13
 jae .vertical_ok
 mov rbx,r14
 imul rbx,NEBOC_TOKEN_SIZE
 add rbx,r12
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne .vertical_next
 lea rdi,[rel cli_float_lowering_request]
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp rdx,rax
 jb .vertical_bad
 sub rdx,rax
 add rax,r15
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rax
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 lea rax,[rel cli_float_lowering_bits]
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 lea rdi,[rel cli_float_lowering_request]
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jz .vertical_classify
 jmp .vertical_bad
.vertical_classify:
 mov rdi,[rel cli_float_lowering_bits]
 lea rsi,[rel cli_float_runtime_class]
 lea rdx,[rel cli_float_runtime_flags]
 call neboc_foundation_float_runtime_classify
 test eax,eax
 jnz .vertical_bad
.vertical_next:
 inc r14
 jmp .vertical_loop
.vertical_ok:
 xor eax,eax
 jmp .vertical_done
.vertical_bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.vertical_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Materialize the opaque parser Start block through the MF018 statement/Pratt parser.
; The top-level parser contract remains unchanged; only the CLI compilation session
; replaces StartDecl.first_child with the fully parsed block used by MF037 codegen.
cli_materialize_start_body:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 lea rbx,[rel cli_ast_builder]
 mov rsi,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r12,[rsp]
 cmp qword [r12+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .bad
 mov rsi,[r12+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r13,[rsp+8]
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start_found
 mov rsi,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start_found:
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r14,[rsp+16]
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_BODY_OPAQUE
 jz .bad
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 test r15,r15
 jz .bad
 dec r15
 lea rdi,[rel cli_stmt_request]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_expr_request]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_tokens]
 mov [rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_ID_OFFSET],rax
 lea rax,[rel cli_source]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_DATA_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_BUILDER_OFFSET],rbx
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r15
 mov qword [rel cli_stmt_request+NEBOC_STMT_MAX_NESTING_OFFSET],NEBOC_STMT_DEFAULT_MAX_NESTING
 lea rax,[rel cli_expr_request]
 mov [rel cli_stmt_request+NEBOC_STMT_EXPR_REQUEST_OFFSET],rax
 lea rdi,[rel cli_stmt_request]
 call neboc_statement_parse_block
 test eax,eax
 jnz .bad
 mov rax,[rel cli_stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 test rax,rax
 jz .bad
 mov [r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret


; Materialize every opaque receiver-first function body through the existing
; Statement/Pratt parser. Receiver/parameter children remain attached to the
; FunctionDecl; only the original Block node is populated in place.
cli_materialize_function_bodies:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 lea rbx,[rel cli_ast_builder]
 mov rsi,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .bad
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.decl_loop:
 test r12,r12
 jz .ok
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r13,[rsp+8]
 mov r14,[r13+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .decl_next
 mov r15,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_block:
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rsp+16]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp+16]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .block_found
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_block
.block_found:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_BODY_OPAQUE
 jz .decl_next
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 test r15,r15
 jz .bad
 dec r15
 lea rdi,[rel cli_stmt_request]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_expr_request]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_tokens]
 mov [rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_ID_OFFSET],rax
 lea rax,[rel cli_source]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_DATA_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_BUILDER_OFFSET],rbx
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r15
 mov qword [rel cli_stmt_request+NEBOC_STMT_MAX_NESTING_OFFSET],NEBOC_STMT_DEFAULT_MAX_NESTING
 lea rax,[rel cli_expr_request]
 mov [rel cli_stmt_request+NEBOC_STMT_EXPR_REQUEST_OFFSET],rax
 lea rdi,[rel cli_stmt_request]
 call neboc_statement_parse_block
 test eax,eax
 jnz .bad
 mov rsi,[rel cli_stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rdx,[rsp+16]
 mov rcx,[rsp+24]
 mov rax,[rcx+NEBOC_AST_NODE_START_OFFSET]
 mov [rdx+NEBOC_AST_NODE_START_OFFSET],rax
 mov rax,[rcx+NEBOC_AST_NODE_END_OFFSET]
 mov [rdx+NEBOC_AST_NODE_END_OFFSET],rax
 mov rax,[rcx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rcx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov [rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 and qword [rdx+NEBOC_AST_NODE_FLAGS_OFFSET],~NEBOC_AST_FLAG_BODY_OPAQUE
 mov qword [rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 mov qword [rdx+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
.decl_next:
 mov r12,r14
 jmp .decl_loop
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret


; Return 1 when the parsed Program contains at least one receiver-first
; FunctionDecl, 0 when it contains only start(), and -1 on AST corruption.
cli_program_requires_function_codegen:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .none
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r14,[rsp]
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_FUNCTION_DECL
 je .yes
 cmp rax,NEBOC_AST_IF_STMT
 je .yes
 cmp rax,NEBOC_AST_BINDING_STMT
 je .yes
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .yes
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .next
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .yes
.next:
 inc r13
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.none:
 xor eax,eax
 jmp .done
.bad:
 mov eax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

cli_generate_assembly:
 push rbx
 lea rdi,[rel cli_layout]
 mov ecx,NEBOC_DATA_LAYOUT_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_target_context]
 mov ecx,NEBOC_TARGET_CONTEXT_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_target_request]
 mov ecx,NEBOC_TARGET_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_writer]
 mov ecx,NEBOC_ASSEMBLY_WRITER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_backend]
 mov ecx,NEBOC_ARCH_BACKEND_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_format]
 mov ecx,NEBOC_FORMAT_ADAPTER_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_layout]
 call neboc_data_layout_init_first_target
 test eax,eax
 jnz .bad
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_TARGET_ID_OFFSET],NEBOC_TARGET_ID_FIRST
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_INSTRUCTION_SET_OFFSET],NEBOC_TARGET_ISA_X86_64
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_OBJECT_FORMAT_OFFSET],NEBOC_TARGET_FORMAT_ELF64
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_OPERATING_ENVIRONMENT_OFFSET],NEBOC_TARGET_ENV_LINUX
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_RUNTIME_NATIVE_LINUX_V0
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_CONSOLE_RUNTIME_PROFILE_OFFSET],NEBOC_TARGET_CONSOLE_RUNTIME_CORE_V0
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_TOOLCHAIN_PROFILE_OFFSET],NEBOC_TARGET_TOOLCHAIN_NASM_GNU_LD_NINJA_V0
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_FEATURE_FLAGS_OFFSET],NEBOC_TARGET_FEATURES_V0
 mov qword [rel cli_target_request+NEBOC_TARGET_REQUEST_COMPONENT_MASK_OFFSET],NEBOC_TARGET_COMPONENT_REQUIRED_MASK
 lea rdi,[rel cli_target_context]
 lea rsi,[rel cli_layout]
 lea rdx,[rel cli_target_request]
 call neboc_target_context_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_asm_output]
 mov edx,NEBOC_CLI_ASM_CAPACITY
 call neboc_assembly_writer_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_backend]
 lea rsi,[rel cli_target_context]
 xor edx,edx
 lea rcx,[rel cli_writer]
 call neboc_arch_backend_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_backend]
 mov esi,1
 xor edx,edx
 call neboc_arch_backend_begin_module
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_runtime_trap_externs]
 mov edx,cli_runtime_trap_externs_end-cli_runtime_trap_externs
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_format]
 lea rsi,[rel cli_target_context]
 lea rdx,[rel cli_backend]
 lea rcx,[rel cli_writer]
 call neboc_format_adapter_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_format]
 mov esi,1
 call neboc_format_adapter_emit_entry_prelude
 test eax,eax
 jnz .bad
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 jne .text_char_bytes_program
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 jne ._buffer_program
 cmp qword [rel console_visual_dashboard_e_plots_cli_found],0
 jne .console_visual_dashboard_e_plots_program
 cmp qword [rel rede_e_protocolos_cli_found],0
 jne .rede_e_protocolos_program
 cmp qword [rel filesystem_paths_e_formatos_cli_found],0
 jne .filesystem_paths_e_formatos_program
 cmp qword [rel biblioteca_padrao_por_dominios_cli_found],0
 jne .biblioteca_padrao_por_dominios_program
 cmp qword [rel packages_registry_lockfile_e_supply_chain_cli_found],0
 jne .packages_registry_lockfile_e_supply_chain_program
 cmp qword [rel cli_module_request+NEBOC_MODULE_FOUND_OFFSET],0
 jne ._module_program
 cmp qword [rel imports_modulos_namespaces_e_api_publica_cli_found],0
 jne .imports_modulos_namespaces_e_api_publica_program
 cmp qword [rel memoria_ownership_lifetimes_e_recursos_cli_found],0
 jne .memoria_ownership_lifetimes_e_recursos_program
 cmp qword [rel quality_confidence_e_lineage_cli_found],0
 jne .quality_confidence_e_lineage_program
 cmp qword [rel privacidade_dados_sensiveis_e_zero_trust_cli_found],0
 jne .privacidade_dados_sensiveis_e_zero_trust_program
 cmp qword [rel effects_capabilities_e_politicas_cli_found],0
 jne .effects_capabilities_e_politicas_program
 cmp qword [rel column_row_table_e_dataset_cli_vertical_request+NEBOC_COLUMN_VERTICAL_FOUND_OFFSET],0
 jne .column_row_table_e_dataset_program
 cmp qword [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],0
 jne .vetores_matrizes_tensores_e_computacao_cientifica_program
 cmp qword [rel colecoes_primitivas_cli_vertical_request+NEBOC_ARRAY_VERTICAL_FOUND_OFFSET],0
 jne .colecoes_primitivas_program
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 jne ._array_range_program
 cmp qword [rel cli_struct_tuple+NEBOC_ST_FOUND_OFFSET],0
 jne ._composite_program
 cmp qword [rel cli_nominal+NEBOC_NOM_FOUND_OFFSET],0
 jne ._nominal_program
 cmp qword [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_FOUND_OFFSET],0
 jne .structs_enums_variants_e_tipos_do_programador_program
 cmp qword [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_VERTICAL_FOUND_OFFSET],0
 jne .tipos_semanticos_refinamentos_unidades_e_opaque_types_program
 cmp qword [rel cli_generic+NEBOC_GEN_FOUND_OFFSET],0
 jne ._generic_program
 cmp qword [rel generics_constraints_overload_e_dispatch_cli_vertical_request+neboc_generics_constraints_overload_e_dispatch_VERTICAL_FOUND_OFFSET],0
 jne .generics_constraints_overload_e_dispatch_program
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 jne ._parameters_program
 cmp qword [rel cli_option+NEBOC_OPTION_FOUND_OFFSET],0
 jne ._option_program
 cmp qword [rel cli_result+NEBOC_RESULT_FOUND_OFFSET],0
 jne ._result_program
 cmp qword [rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_FOUND_OFFSET],0
 jne .option_result_null_externo_e_erros_tipados_program
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 jne .bindings_constantes_mutabilidade_e_definite_assignment_program
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 jne .text_char_unicode_e_bytes_program_driver_cli_linux_x86_64
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 jne .seguranca_numerica_conversoes_e_overflow_program
 cmp qword [rel cli_float_sem_request+NEBOC_FLOAT_SEM_FOUND_OFFSET],0
 jne .float_program
 call cli_program_requires_function_codegen
 cmp eax,-1
 je .bad
 test eax,eax
 jnz .function_program
 jmp .legacy_no_function

._buffer_program:
 lea rdi,[rel cli_buffer_codegen]
 mov ecx,NEBOC_BUFFER_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_buffer_plan]
 mov [rel cli_buffer_codegen+NEBOC_BUFFER_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_buffer_codegen+NEBOC_BUFFER_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_buffer_codegen]
 call neboc_buffer_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_buffer_codegen+NEBOC_BUFFER_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz ._buffer_publish_codegen
 mov edx,NEBOC_BUFFER_DIAG_INTERNAL
._buffer_publish_codegen:
 mov [rel cli_buffer+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.text_char_bytes_program:
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen]
 mov ecx,neboc_text_char_unicode_e_bytes_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel text_char_unicode_e_bytes_cli_plan]
 mov [rel text_char_unicode_e_bytes_cli_codegen+neboc_text_char_unicode_e_bytes_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel text_char_unicode_e_bytes_cli_codegen+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_memory_x86_64_native_vertical],rax
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen]
 call neboc_move_copy_clone_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel text_char_unicode_e_bytes_cli_codegen+neboc_text_char_unicode_e_bytes_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .text_char_bytes_publish_codegen
 mov edx,neboc_text_char_unicode_e_bytes_DIAG_INTERNAL
.text_char_bytes_publish_codegen:
 mov [rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.console_visual_dashboard_e_plots_program:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_codegen_request]
 mov ecx,neboc_console_visual_dashboard_e_plots_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel console_visual_dashboard_e_plots_cli_runtime_state]
 mov [rel console_visual_dashboard_e_plots_cli_codegen_request+neboc_console_visual_dashboard_e_plots_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel console_visual_dashboard_e_plots_cli_codegen_request+neboc_console_visual_dashboard_e_plots_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel console_visual_dashboard_e_plots_cli_codegen_request]
 call neboc_visual_summary_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel console_visual_dashboard_e_plots_cli_codegen_request+neboc_console_visual_dashboard_e_plots_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .console_visual_dashboard_e_plots_publish_codegen_diagnostic
 mov edx,neboc_console_visual_dashboard_e_plots_DIAG_CODEGEN_codegen_stdlib_x86_64
.console_visual_dashboard_e_plots_publish_codegen_diagnostic:
 mov [rel console_visual_dashboard_e_plots_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.rede_e_protocolos_program:
 lea rdi,[rel rede_e_protocolos_cli_codegen_request]
 mov ecx,neboc_rede_e_protocolos_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel rede_e_protocolos_cli_runtime_state]
 mov [rel rede_e_protocolos_cli_codegen_request+neboc_rede_e_protocolos_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel rede_e_protocolos_cli_codegen_request+neboc_rede_e_protocolos_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel rede_e_protocolos_cli_codegen_request]
 call neboc_net_port_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel rede_e_protocolos_cli_codegen_request+neboc_rede_e_protocolos_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .rede_e_protocolos_publish_codegen_diagnostic
 mov edx,neboc_rede_e_protocolos_DIAG_CODEGEN_codegen_stdlib_x86_64
.rede_e_protocolos_publish_codegen_diagnostic:
 mov [rel rede_e_protocolos_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.filesystem_paths_e_formatos_program:
 lea rdi,[rel filesystem_paths_e_formatos_cli_codegen_request]
 mov ecx,neboc_filesystem_paths_e_formatos_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel filesystem_paths_e_formatos_cli_runtime_state]
 mov [rel filesystem_paths_e_formatos_cli_codegen_request+neboc_filesystem_paths_e_formatos_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel filesystem_paths_e_formatos_cli_codegen_request+neboc_filesystem_paths_e_formatos_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel filesystem_paths_e_formatos_cli_codegen_request]
 call neboc_path_query_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel filesystem_paths_e_formatos_cli_codegen_request+neboc_filesystem_paths_e_formatos_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .filesystem_paths_e_formatos_publish_codegen_diagnostic
 mov edx,neboc_filesystem_paths_e_formatos_DIAG_CODEGEN_codegen_stdlib_x86_64
.filesystem_paths_e_formatos_publish_codegen_diagnostic:
 mov [rel filesystem_paths_e_formatos_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.biblioteca_padrao_por_dominios_program:
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_codegen_request]
 mov ecx,neboc_biblioteca_padrao_por_dominios_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel biblioteca_padrao_por_dominios_cli_runtime_state]
 mov [rel biblioteca_padrao_por_dominios_cli_codegen_request+neboc_biblioteca_padrao_por_dominios_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel biblioteca_padrao_por_dominios_cli_codegen_request+neboc_biblioteca_padrao_por_dominios_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_codegen_request]
 call neboc_std_math_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel biblioteca_padrao_por_dominios_cli_codegen_request+neboc_biblioteca_padrao_por_dominios_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .biblioteca_padrao_por_dominios_publish_codegen_diagnostic
 mov edx,neboc_biblioteca_padrao_por_dominios_DIAG_CODEGEN_codegen_stdlib_x86_64
.biblioteca_padrao_por_dominios_publish_codegen_diagnostic:
 mov [rel biblioteca_padrao_por_dominios_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.packages_registry_lockfile_e_supply_chain_program:
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_codegen_request]
 mov ecx,neboc_packages_registry_lockfile_e_supply_chain_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel packages_registry_lockfile_e_supply_chain_cli_runtime_state]
 mov [rel packages_registry_lockfile_e_supply_chain_cli_codegen_request+neboc_packages_registry_lockfile_e_supply_chain_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel packages_registry_lockfile_e_supply_chain_cli_codegen_request+neboc_packages_registry_lockfile_e_supply_chain_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel packages_registry_lockfile_e_supply_chain_cli_codegen_request]
 call neboc_package_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel packages_registry_lockfile_e_supply_chain_cli_codegen_request+neboc_packages_registry_lockfile_e_supply_chain_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .packages_registry_lockfile_e_supply_chain_publish_codegen_diagnostic
 mov edx,neboc_packages_registry_lockfile_e_supply_chain_DIAG_CODEGEN_codegen_package_x86_64
.packages_registry_lockfile_e_supply_chain_publish_codegen_diagnostic:
 mov [rel packages_registry_lockfile_e_supply_chain_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._module_program:
 lea rdi,[rel cli_module_codegen]
 mov ecx,NEBOC_MODULE_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_module_plan]
 mov [rel cli_module_codegen+NEBOC_MODULE_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_module_codegen+NEBOC_MODULE_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_module_codegen]
 call neboc_seguranca_numerica_conversoes_e_overflow_module_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_module_codegen+NEBOC_MODULE_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz ._module_publish_codegen
 mov edx,NEBOC_MODULE_DIAG_INTERNAL
._module_publish_codegen:
 mov [rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.imports_modulos_namespaces_e_api_publica_program:
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_codegen_request]
 mov ecx,neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel imports_modulos_namespaces_e_api_publica_cli_runtime_state]
 mov [rel imports_modulos_namespaces_e_api_publica_cli_codegen_request+neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel imports_modulos_namespaces_e_api_publica_cli_codegen_request+neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel imports_modulos_namespaces_e_api_publica_cli_codegen_request]
 call neboc_imports_modulos_namespaces_e_api_publica_module_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel imports_modulos_namespaces_e_api_publica_cli_codegen_request+neboc_imports_modulos_namespaces_e_api_publica_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .imports_modulos_namespaces_e_api_publica_publish_codegen_diagnostic
 mov edx,neboc_imports_modulos_namespaces_e_api_publica_DIAG_CODEGEN_codegen_modules_x86_64
.imports_modulos_namespaces_e_api_publica_publish_codegen_diagnostic:
 mov [rel imports_modulos_namespaces_e_api_publica_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.memoria_ownership_lifetimes_e_recursos_program:
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_codegen_request]
 mov ecx,neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel memoria_ownership_lifetimes_e_recursos_cli_runtime_request]
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_codegen_request+neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_codegen_request+neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel memoria_ownership_lifetimes_e_recursos_cli_codegen_request]
 call neboc_ownership_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel memoria_ownership_lifetimes_e_recursos_cli_codegen_request+neboc_memoria_ownership_lifetimes_e_recursos_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .memoria_ownership_lifetimes_e_recursos_publish_codegen_diagnostic
 mov edx,neboc_memoria_ownership_lifetimes_e_recursos_DIAG_CODEGEN_codegen_memory_x86_64
.memoria_ownership_lifetimes_e_recursos_publish_codegen_diagnostic:
 mov [rel memoria_ownership_lifetimes_e_recursos_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.quality_confidence_e_lineage_program:
 lea rdi,[rel quality_confidence_e_lineage_cli_codegen_request]
 mov ecx,neboc_quality_confidence_e_lineage_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel quality_confidence_e_lineage_cli_native_request]
 mov [rel quality_confidence_e_lineage_cli_codegen_request+neboc_quality_confidence_e_lineage_CODEGEN_NATIVE_OFFSET],rax
 lea rax,[rel quality_confidence_e_lineage_cli_runtime_request]
 mov [rel quality_confidence_e_lineage_cli_codegen_request+neboc_quality_confidence_e_lineage_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel quality_confidence_e_lineage_cli_codegen_request+neboc_quality_confidence_e_lineage_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel quality_confidence_e_lineage_cli_codegen_request]
 call neboc_quality_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel quality_confidence_e_lineage_cli_codegen_request+neboc_quality_confidence_e_lineage_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .quality_confidence_e_lineage_publish_codegen_diagnostic
 mov edx,neboc_quality_confidence_e_lineage_DIAG_CODEGEN_codegen_quality_x86_64
.quality_confidence_e_lineage_publish_codegen_diagnostic:
 mov [rel quality_confidence_e_lineage_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.privacidade_dados_sensiveis_e_zero_trust_program:
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request]
 mov ecx,neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_native_request]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request+neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_NATIVE_OFFSET],rax
 lea rax,[rel privacidade_dados_sensiveis_e_zero_trust_cli_runtime_request]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request+neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request+neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request]
 call neboc_privacy_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel privacidade_dados_sensiveis_e_zero_trust_cli_codegen_request+neboc_privacidade_dados_sensiveis_e_zero_trust_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .privacidade_dados_sensiveis_e_zero_trust_publish_codegen_diagnostic
 mov edx,neboc_privacidade_dados_sensiveis_e_zero_trust_DIAG_CODEGEN_codegen_privacy_x86_64
.privacidade_dados_sensiveis_e_zero_trust_publish_codegen_diagnostic:
 mov [rel privacidade_dados_sensiveis_e_zero_trust_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.effects_capabilities_e_politicas_program:
 lea rdi,[rel effects_capabilities_e_politicas_cli_codegen_request]
 mov ecx,neboc_effects_capabilities_e_politicas_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel effects_capabilities_e_politicas_cli_native_request]
 mov [rel effects_capabilities_e_politicas_cli_codegen_request+neboc_effects_capabilities_e_politicas_CODEGEN_NATIVE_OFFSET],rax
 lea rax,[rel effects_capabilities_e_politicas_cli_runtime_request]
 mov [rel effects_capabilities_e_politicas_cli_codegen_request+neboc_effects_capabilities_e_politicas_CODEGEN_RUNTIME_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel effects_capabilities_e_politicas_cli_codegen_request+neboc_effects_capabilities_e_politicas_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel effects_capabilities_e_politicas_cli_codegen_request]
 call neboc_policy_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel effects_capabilities_e_politicas_cli_codegen_request+neboc_effects_capabilities_e_politicas_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .effects_capabilities_e_politicas_publish_codegen_diagnostic
 mov edx,neboc_effects_capabilities_e_politicas_DIAG_CODEGEN_codegen_effects_x86_64
.effects_capabilities_e_politicas_publish_codegen_diagnostic:
 mov [rel effects_capabilities_e_politicas_cli_frontend_diagnostic],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.column_row_table_e_dataset_program:
 lea rdi,[rel column_row_table_e_dataset_cli_codegen_request]
 mov ecx,NEBOC_COLUMN_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel column_row_table_e_dataset_cli_vertical_request]
 mov [rel column_row_table_e_dataset_cli_codegen_request+NEBOC_COLUMN_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel column_row_table_e_dataset_cli_codegen_request+NEBOC_COLUMN_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel column_row_table_e_dataset_cli_codegen_request]
 call neboc_column_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.vetores_matrizes_tensores_e_computacao_cientifica_program:
 lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_codegen_request]
 mov ecx,NEBOC_VECTOR_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_codegen_request+NEBOC_VECTOR_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_codegen_request+NEBOC_VECTOR_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_codegen_request]
 call neboc_vector_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.colecoes_primitivas_program:
 lea rdi,[rel colecoes_primitivas_cli_codegen_request]
 mov ecx,NEBOC_ARRAY_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel colecoes_primitivas_cli_vertical_request]
 mov [rel colecoes_primitivas_cli_codegen_request+NEBOC_ARRAY_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel colecoes_primitivas_cli_codegen_request+NEBOC_ARRAY_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel colecoes_primitivas_cli_codegen_request]
 call neboc_array_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._composite_program:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_codegen]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel option_result_null_externo_e_erros_tipados_cli_plan]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_aggregates_x86_64_native_vertical],rax
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_codegen]
 call neboc_struct_tuple_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov qword [rel cli_struct_tuple+NEBOC_ST_DIAGNOSTIC_OFFSET],neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._array_range_program:
 cmp qword [rel cli_ar_plan+NEBOC_AR_PLAN_LOOP_COUNT_OFFSET],0
 jne ._for_program
 cmp qword [rel cli_slice_plan+NEBOC_SLICE_PLAN_FOUND_OFFSET],0
 jne ._slice_program
._for_program:
 lea rdi,[rel cli_ar_codegen]
 mov ecx,NEBOC_AR_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_ar_plan]
 mov [rel cli_ar_codegen+NEBOC_AR_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_ar_codegen+NEBOC_AR_CODEGEN_WRITER_OFFSET],rax
 lea rax,[rel cli_array_range]
 mov [rel cli_ar_codegen+NEBOC_AR_CODEGEN_SEMANTIC_OFFSET],rax
 lea rdi,[rel cli_ar_codegen]
 call neboc_array_range_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov qword [rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._slice_program:
 lea rdi,[rel cli_slice_codegen]
 mov ecx,NEBOC_SLICE_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_slice_plan]
 mov [rel cli_slice_codegen+NEBOC_SLICE_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_slice_codegen+NEBOC_SLICE_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_slice_codegen]
 call neboc_slice_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov qword [rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET],NEBOC_AR_DIAG_INTERNAL
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._nominal_program:
 lea rdi,[rel cli_nominal_codegen]
 mov ecx,NEBOC_NOM_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_nominal_plan]
 mov [rel cli_nominal_codegen+NEBOC_NOM_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_nominal_codegen+NEBOC_NOM_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_nominal_codegen]
 call neboc_nominal_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_nominal_codegen+NEBOC_NOM_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz ._nominal_publish_codegen
 mov edx,NEBOC_NOM_DIAG_INTERNAL
._nominal_publish_codegen:
 mov [rel cli_nominal+NEBOC_NOM_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.structs_enums_variants_e_tipos_do_programador_program:
 lea rdi,[rel structs_enums_variants_e_tipos_do_programador_cli_codegen_request]
 mov ecx,neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_codegen_request+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel structs_enums_variants_e_tipos_do_programador_cli_codegen_request+neboc_structs_enums_variants_e_tipos_do_programador_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel structs_enums_variants_e_tipos_do_programador_cli_codegen_request]
 call neboc_programmer_type_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.tipos_semanticos_refinamentos_unidades_e_opaque_types_program:
 lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_codegen_request]
 mov ecx,neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_vertical_request]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_codegen_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_codegen_request+neboc_tipos_semanticos_refinamentos_unidades_e_opaque_types_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel tipos_semanticos_refinamentos_unidades_e_opaque_types_cli_codegen_request]
 call neboc_domain_refinement_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._generic_program:
 lea rdi,[rel cli_generic_codegen]
 mov ecx,NEBOC_GEN_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_generic_plan]
 mov [rel cli_generic_codegen+NEBOC_GEN_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_generic_codegen+NEBOC_GEN_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_generic_codegen]
 call neboc_option_result_null_externo_e_erros_tipados_generic_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_generic_codegen+NEBOC_GEN_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz ._generic_publish_codegen
 mov edx,NEBOC_GEN_DIAG_INTERNAL
._generic_publish_codegen:
 mov [rel cli_generic+NEBOC_GEN_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.generics_constraints_overload_e_dispatch_program:
 lea rdi,[rel generics_constraints_overload_e_dispatch_cli_codegen_request]
 mov ecx,neboc_generics_constraints_overload_e_dispatch_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel generics_constraints_overload_e_dispatch_cli_vertical_request]
 mov [rel generics_constraints_overload_e_dispatch_cli_codegen_request+neboc_generics_constraints_overload_e_dispatch_CODEGEN_VERTICAL_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel generics_constraints_overload_e_dispatch_cli_codegen_request+neboc_generics_constraints_overload_e_dispatch_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel generics_constraints_overload_e_dispatch_cli_codegen_request]
 call neboc_generics_constraints_overload_e_dispatch_generic_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._parameters_program:
 lea rdi,[rel cli_param_codegen]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_param_plan]
 mov [rel cli_param_codegen+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_param_codegen+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_functions_x86_64_native_vertical],rax
 lea rdi,[rel cli_param_codegen]
 call neboc_parameters_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_param_codegen+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .numeric_safety_publish_codegen
 mov edx,neboc_seguranca_numerica_conversoes_e_overflow_DIAG_INTERNAL
.numeric_safety_publish_codegen:
 mov [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._option_program:
 lea rdi,[rel cli_option_codegen]
 mov ecx,NEBOC_OPTION_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_option_plan]
 mov [rel cli_option_codegen+NEBOC_OPTION_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_option_codegen+NEBOC_OPTION_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_option_codegen]
 call neboc_option_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_option_codegen+NEBOC_OPTION_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz .bindings_publish_codegen
 mov edx,NEBOC_OPTION_DIAG_INTERNAL
.bindings_publish_codegen:
 mov [rel cli_option+NEBOC_OPTION_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

._result_program:
 lea rdi,[rel cli_result_codegen]
 mov ecx,NEBOC_RESULT_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_result_plan]
 mov [rel cli_result_codegen+NEBOC_RESULT_CODEGEN_PLAN_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_result_codegen+NEBOC_RESULT_CODEGEN_WRITER_OFFSET],rax
 lea rdi,[rel cli_result_codegen]
 call neboc_result_codegen_emit_start
 test eax,eax
 jz .program_emitted
 mov rdx,[rel cli_result_codegen+NEBOC_RESULT_CODEGEN_DIAGNOSTIC_OFFSET]
 test rdx,rdx
 jnz ._result_publish_codegen
 mov edx,NEBOC_RESULT_DIAG_INTERNAL
._result_publish_codegen:
 mov [rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],rdx
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.option_result_null_externo_e_erros_tipados_program:
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_codegen_request]
 mov ecx,neboc_option_result_null_externo_e_erros_tipados_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_operations]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+NEBOC_CODEGEN_OPERATIONS_OFFSET],rax
 mov rax,[rel option_result_null_externo_e_erros_tipados_cli_parse_request+NEBOC_VPARSE_OPERATION_COUNT_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_OPERATION_COUNT_OFFSET],rax
 lea rax,[rel option_result_null_externo_e_erros_tipados_cli_symbols]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rel cli_sem_request+NEBOC_VSEM_SYMBOL_COUNT_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rel cli_sem_request+NEBOC_VSEM_FRAME_SIZE_OFFSET]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FRAME_SIZE_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64],rax
 lea rax,[rel cli_float_lowering_request]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_REQUEST_OFFSET],rax
 lea rax,[rel cli_float_lowering_bits]
 mov [rel option_result_null_externo_e_erros_tipados_cli_codegen_request+neboc_option_result_null_externo_e_erros_tipados_CODEGEN_FLOAT_BITS_OFFSET],rax
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_codegen_request]
 call neboc_option_result_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.bindings_constantes_mutabilidade_e_definite_assignment_program:
 ; Reuse text_char_unicode_e_bytes data emission so Text literals referenced by binding slots have
 ; the same deterministic descriptors as the public textual pipeline.
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen_request]
 mov ecx,neboc_text_char_unicode_e_bytes_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_literal_bytes]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+NEBOC_CODEGEN_LITERAL_BYTES_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+NEBOC_CODEGEN_LITERAL_LENGTH_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64],rax
 mov qword [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_DEFAULT
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen_request]
 call neboc_text_char_bytes_codegen_emit_data
 test eax,eax
 jnz .source_bad
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request]
 mov ecx,neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET],rax
 lea rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_symbols]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 lea rax,[rel cli_branch_a]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_A_OFFSET],rax
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_A_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_A_COUNT_OFFSET],rax
 lea rax,[rel cli_branch_b]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_B_OFFSET],rax
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_B_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_B_COUNT_OFFSET],rax
 lea rax,[rel cli_float_lowering_request]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_REQUEST_OFFSET],rax
 lea rax,[rel cli_float_lowering_bits]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_BITS_OFFSET],rax
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_DEFAULT
 lea rax,[rel cli_loop_stack]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_LOOP_STACK_OFFSET],rax
 lea rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request]
 call neboc_binding_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.text_char_unicode_e_bytes_program_driver_cli_linux_x86_64:
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen_request]
 mov ecx,neboc_text_char_unicode_e_bytes_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_literal_bytes]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+NEBOC_CODEGEN_LITERAL_BYTES_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+NEBOC_CODEGEN_LITERAL_LENGTH_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_WRITER_OFFSET_codegen_textual_x86_64],rax
 mov qword [rel text_char_unicode_e_bytes_cli_codegen_request+neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_OFFSET],neboc_text_char_unicode_e_bytes_CODEGEN_MAX_DEPTH_DEFAULT
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen_request]
 call neboc_text_char_bytes_codegen_emit_data
 test eax,eax
 jnz ._source_bad
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel text_char_unicode_e_bytes_cli_codegen_request]
 call neboc_text_char_bytes_codegen_emit_start
 test eax,eax
 jz .program_emitted
._source_bad:
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.seguranca_numerica_conversoes_e_overflow_program:
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request]
 mov ecx,neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64],rax
 lea rax,[rel cli_float_lowering_request]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_REQUEST_OFFSET],rax
 lea rax,[rel cli_float_lowering_bits]
 mov [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_BITS_OFFSET],rax
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_DEFAULT
 lea rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_codegen_request]
 call neboc_numeric_safety_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.float_program:
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_float_codegen_request]
 mov ecx,NEBOC_FLOAT_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_ast_builder]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_WRITER_OFFSET],rax
 lea rax,[rel cli_float_lowering_request]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_LOWERING_REQUEST_OFFSET],rax
 lea rax,[rel cli_float_lowering_bits]
 mov [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_LOWERING_BITS_OFFSET],rax
 mov qword [rel cli_float_codegen_request+NEBOC_FLOAT_CODEGEN_MAX_DEPTH_OFFSET],NEBOC_FLOAT_CODEGEN_MAX_DEPTH_DEFAULT
 lea rdi,[rel cli_float_codegen_request]
 call neboc_foundation_float_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .float_source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .float_source_bad
 jmp .bad
.float_source_bad:
 call cli_report_float_codegen_diagnostic
 jmp .source_bad

.legacy_no_function:
 ; Preserve the MF037 no-function path byte-for-byte.
 lea rdi,[rel cli_backend]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_value_codegen]
 mov ecx,NEBOC_CORE_VALUE_CODEGEN_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_value_codegen]
 lea rsi,[rel cli_ast_builder]
 mov rdx,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 lea rcx,[rel cli_writer]
 call neboc_core_value_codegen_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_value_codegen]
 call neboc_core_value_codegen_emit_start
 test eax,eax
 jz .program_emitted
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .source_bad
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .source_bad
 jmp .bad

.function_program:
 lea rdi,[rel cli_abi_adapter]
 mov ecx,NEBOC_ABI_ADAPTER_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_abi_request]
 mov ecx,NEBOC_ABI_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_function_codegen]
 mov ecx,NEBOC_FUNCTION_CODEGEN_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_function_codegen_request]
 mov ecx,NEBOC_FUNCTION_CODEGEN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_function_signatures]
 mov ecx,((NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1)*NEBOC_ABI_SIGNATURE_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_function_plans]
 mov ecx,((NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1)*NEBOC_FUNCTION_PLAN_SIZE)/8
 xor eax,eax
 rep stosq

 mov qword [rel cli_abi_request+NEBOC_ABI_REQUEST_INTERNAL_VERSION_OFFSET],NEBOC_INTERNAL_ABI_VERSION
 mov qword [rel cli_abi_request+NEBOC_ABI_REQUEST_RUNTIME_VERSION_OFFSET],NEBOC_RUNTIME_ABI_VERSION_V0
 mov qword [rel cli_abi_request+NEBOC_ABI_REQUEST_TARGET_ABI_ID_OFFSET],NEBOC_TARGET_ABI_SYSTEMV_AMD64
 mov qword [rel cli_abi_request+NEBOC_ABI_REQUEST_STACK_ALIGNMENT_OFFSET],NEBOC_ABI_STACK_ALIGNMENT
 mov qword [rel cli_abi_request+NEBOC_ABI_REQUEST_FLAGS_OFFSET],NEBOC_ABI_REQUEST_REQUIRED_FLAGS
 lea rdi,[rel cli_abi_adapter]
 lea rsi,[rel cli_target_context]
 lea rdx,[rel cli_backend]
 lea rcx,[rel cli_abi_request]
 call neboc_abi_adapter_init
 test eax,eax
 jnz .bad

 lea rax,[rel cli_ast_builder]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_BUILDER_OFFSET],rax
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_ROOT_ID_OFFSET],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET],rax
 lea rax,[rel cli_source]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_literal_bytes]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_LENGTH_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET],rax
 lea rax,[rel cli_backend]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET],rax
 lea rax,[rel cli_abi_adapter]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET],rax
 lea rax,[rel cli_function_signatures]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET],rax
 mov qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET],NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1
 lea rax,[rel cli_function_plans]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET],rax
 mov qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET],NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS+1
 lea rdi,[rel cli_function_codegen]
 lea rsi,[rel cli_function_codegen_request]
 call neboc_function_codegen_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_function_codegen]
 call neboc_function_codegen_emit
 test eax,eax
 jz .program_emitted
 mov rax,[rel cli_function_codegen+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 je .source_bad
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 je .bad
 jmp .source_bad

.program_emitted:
 lea rdi,[rel cli_backend]
 call neboc_arch_backend_end_module
 test eax,eax
 jnz .bad
 mov rax,[rel cli_writer+NEBOC_ASSEMBLY_WRITER_LENGTH_OFFSET]
 test rax,rax
 jz .bad
 mov [rel cli_state+NEBOC_CLI_STATE_ASM_LENGTH_OFFSET],rax
 xor eax,eax
 pop rbx
 ret
.source_bad:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 pop rbx
 ret
.bad:
 mov eax,NEBOC_CLI_EXIT_INTERNAL_ERROR
 pop rbx
 ret

; write_file(path, bytes, length) -> 0 or 1.
cli_write_file:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov edi,-100
 mov rsi,r12
 mov edx,577
 mov r10d,420
 mov eax,257
 syscall
 cmp rax,-4095
 jae .bad
 mov rbx,rax
 xor r15d,r15d
.loop:
 cmp r15,r14
 jae .close_ok
 mov eax,1
 mov rdi,rbx
 lea rsi,[r13+r15]
 mov rdx,r14
 sub rdx,r15
 syscall
 test rax,rax
 jz .write_bad
 js .write_error
 add r15,rax
 jmp .loop
.write_error:
 cmp rax,-4
 je .loop
.write_bad:
 mov eax,3
 mov rdi,rbx
 syscall
 mov eax,87
 mov rdi,r12
 syscall
 mov eax,1
 jmp .done
.close_ok:
 mov eax,3
 mov rdi,rbx
 syscall
 test rax,rax
 js .bad
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; make_suffixed_path(dest, base, suffix, suffix_len) -> 0 or 1.
cli_make_suffixed_path:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov rdi,r12
 call cli_strlen_path
 cmp rax,-1
 je .bad
 mov r15,rax
 mov rdx,r15
 add rdx,r14
 inc rdx
 cmp rdx,NEBOC_CLI_PATH_CAPACITY
 ja .bad
 mov rdi,rbx
 mov rsi,r12
 mov rcx,r15
 rep movsb
 mov rsi,r13
 mov rcx,r14
 rep movsb
 mov byte [rdi],0
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Derive the runtime object from argv[0], falling back to project-root relative.
cli_make_runtime_path:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,r12
 call cli_strlen_path
 cmp rax,-1
 je .bad
 mov r13,rax
 xor r14d,r14d
 xor ecx,ecx
.find:
 cmp rcx,r13
 jae .found
 cmp byte [r12+rcx],'/'
 jne .next
 lea r14,[rcx+1]
.next:
 inc rcx
 jmp .find
.found:
 test r14,r14
 jz .default
 mov rax,r14
 add rax,runtime_relative_len
 inc rax
 cmp rax,NEBOC_CLI_PATH_CAPACITY
 ja .bad
 mov rdi,rbx
 mov rsi,r12
 mov rcx,r14
 rep movsb
 lea rsi,[rel runtime_relative]
 mov rcx,runtime_relative_len
 rep movsb
 mov byte [rdi],0
 xor eax,eax
 jmp .done
.default:
 mov rdi,rbx
 lea rsi,[rel runtime_default]
 mov ecx,runtime_default_len
 rep movsb
 mov byte [rdi],0
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

cli_unlink_path:
 mov eax,87
 syscall
 xor eax,eax
 ret

; ToolchainDescriptor runner callback:
; runner(context, argv_ptrs, argv_lens, argc, result*) -> Status.
; argv_ptrs already contains a trailing NULL because the invocation is zeroed.
cli_toolchain_runner:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rsi
 mov r13,r8
 mov r14,rcx
 test r12,r12
 jz .host_error
 test r13,r13
 jz .host_error
 test r14,r14
 jz .host_error
 cmp r14,NEBOC_TOOLCHAIN_MAX_ARGS
 ja .host_error
 mov dword [rel cli_wait_status],0
 mov eax,57
 syscall
 test rax,rax
 js .host_error
 jz .child
 mov rbx,rax
.wait:
 mov rdi,rbx
 lea rsi,[rel cli_wait_status]
 xor edx,edx
 xor r10d,r10d
 mov eax,61
 syscall
 cmp rax,-4
 je .wait
 test rax,rax
 js .host_error
 mov eax,[rel cli_wait_status]
 mov edx,eax
 and edx,0x7f
 test edx,edx
 jnz .signaled
 shr eax,8
 and eax,0xff
 mov [r13+NEBOC_TOOLCHAIN_RESULT_EXIT_CODE_OFFSET],rax
 mov qword [r13+NEBOC_TOOLCHAIN_RESULT_TERM_SIGNAL_OFFSET],0
 xor eax,eax
 jmp .done
.signaled:
 mov [r13+NEBOC_TOOLCHAIN_RESULT_TERM_SIGNAL_OFFSET],rdx
 lea eax,[rdx+128]
 mov [r13+NEBOC_TOOLCHAIN_RESULT_EXIT_CODE_OFFSET],rax
 xor eax,eax
 jmp .done
.child:
 mov rdi,[r12]
 mov rsi,r12
 lea rdx,[rel cli_null_env]
 mov eax,59
 syscall
 mov edi,127
 mov eax,60
 syscall
 ud2
.host_error:
 mov eax,NEBOC_STATUS_IO_ERROR
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; ToolchainDescriptor removal callback: remover(context, path, length).
cli_toolchain_remover:
 mov rdi,rsi
 mov eax,87
 syscall
 xor eax,eax
 ret

cli_build_artifact:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 lea rdi,[rel cli_temp_asm_path]
 mov rsi,r12
 lea rdx,[rel suffix_asm]
 mov ecx,suffix_asm_len
 call cli_make_suffixed_path
 test eax,eax
 jnz .io
 lea rdi,[rel cli_temp_obj_path]
 mov rsi,r12
 lea rdx,[rel suffix_obj]
 mov ecx,suffix_obj_len
 call cli_make_suffixed_path
 test eax,eax
 jnz .io
 lea rdi,[rel cli_runtime_obj_path]
 mov rsi,[rel cli_state+NEBOC_CLI_STATE_ARGV0_PTR_OFFSET]
 call cli_make_runtime_path
 test eax,eax
 jnz .internal
 mov rdi,r12
 call cli_strlen_path
 cmp rax,-1
 je .io
 mov r13,rax
 lea rdi,[rel cli_temp_asm_path]
 call cli_strlen_path
 cmp rax,-1
 je .io
 mov r14,rax
 lea rdi,[rel cli_temp_obj_path]
 call cli_strlen_path
 cmp rax,-1
 je .io
 mov r15,rax
 lea rdi,[rel cli_runtime_obj_path]
 call cli_strlen_path
 cmp rax,-1
 je .internal
 mov [rsp],rax

 lea rdi,[rel cli_toolchain]
 mov ecx,NEBOC_TOOLCHAIN_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_toolchain_request]
 mov ecx,NEBOC_TOOLCHAIN_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_toolchain_invocation]
 mov ecx,NEBOC_TOOLCHAIN_INVOCATION_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_toolchain_result]
 mov ecx,NEBOC_TOOLCHAIN_RESULT_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel nasm_path]
 mov [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_PTR_OFFSET],rax
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_ASSEMBLER_LEN_OFFSET],nasm_path_len
 lea rax,[rel ld_path]
 mov [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_LINKER_PTR_OFFSET],rax
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_LINKER_LEN_OFFSET],ld_path_len
 lea rax,[rel cli_toolchain_runner]
 mov [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_RUNNER_OFFSET],rax
 lea rax,[rel cli_toolchain_remover]
 mov [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_REMOVER_OFFSET],rax
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_CONTEXT_OFFSET],0
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_NASM_MAJOR_OFFSET],2
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_NASM_MINOR_OFFSET],16
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_LD_MAJOR_OFFSET],2
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_LD_MINOR_OFFSET],42
 mov qword [rel cli_toolchain_request+NEBOC_TOOLCHAIN_REQUEST_FLAGS_OFFSET],NEBOC_TOOLCHAIN_REQUIRED_FLAGS
 lea rdi,[rel cli_toolchain]
 lea rsi,[rel cli_target_context]
 lea rdx,[rel cli_toolchain_request]
 call neboc_toolchain_init
 test eax,eax
 jnz .tool_fail

 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
 lea rdi,[rel cli_temp_obj_path]
 call cli_unlink_path
 mov rdi,r12
 call cli_unlink_path
 lea rdi,[rel cli_temp_asm_path]
 lea rsi,[rel cli_asm_output]
 mov rdx,[rel cli_state+NEBOC_CLI_STATE_ASM_LENGTH_OFFSET]
 call cli_write_file
 test eax,eax
 jnz .io

 lea rdi,[rel cli_toolchain]
 lea rsi,[rel cli_temp_asm_path]
 mov rdx,r14
 lea rcx,[rel cli_temp_obj_path]
 mov r8,r15
 lea r9,[rel cli_toolchain_invocation]
 call neboc_toolchain_build_assembler_invocation
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_toolchain]
 lea rsi,[rel cli_toolchain_invocation]
 lea rdx,[rel cli_toolchain_result]
 call neboc_toolchain_execute
 test eax,eax
 jnz .tool_fail

 lea rdi,[rel cli_toolchain]
 lea rsi,[rel cli_temp_obj_path]
 mov rdx,r15
 lea rcx,[rel cli_runtime_obj_path]
 mov r8,[rsp]
 mov r9,r12
 sub rsp,16
 mov [rsp],r13
 lea rax,[rel cli_toolchain_invocation]
 mov [rsp+8],rax
 call neboc_toolchain_build_linker_invocation
 add rsp,16
 test eax,eax
 jnz .internal
 lea rdi,[rel cli_toolchain]
 lea rsi,[rel cli_toolchain_invocation]
 lea rdx,[rel cli_toolchain_result]
 call neboc_toolchain_execute
 test eax,eax
 jnz .tool_fail
 mov rax,[rel cli_toolchain+NEBOC_TOOLCHAIN_INVOCATION_COUNT_OFFSET]
 mov [rel cli_state+NEBOC_CLI_STATE_TOOLCHAIN_COUNT_OFFSET],rax
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .ok
 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
 lea rdi,[rel cli_temp_obj_path]
 call cli_unlink_path
.ok:
 xor eax,eax
 jmp .done
.tool_fail:
 mov rdi,r12
 call cli_unlink_path
 lea rdi,[rel cli_temp_obj_path]
 call cli_unlink_path
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .tool_error
 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
.tool_error:
 mov eax,NEBOC_CLI_EXIT_TOOLCHAIN_ERROR
 jmp .done
.io:
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.internal:
 mov eax,NEBOC_CLI_EXIT_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

cli_ice_reset_writer:
 lea rax,[rel cli_ice_output]
 mov [rel cli_ice_writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel cli_ice_writer+NEBOC_WRITER_CAPACITY_OFFSET],NEBOC_ICE_MAX_BUNDLE_BYTES
 mov qword [rel cli_ice_writer+NEBOC_WRITER_LENGTH_OFFSET],0
 ret

; Build observability is presentation-only: stderr changes, artifact bytes do not.
cli_emit_observability:
 push rbx
 cmp qword [rel cli_quiet],1
 je .ok
 mov rbx,[rel cli_progress_policy]
 cmp rbx,NEBOC_TERMINAL_ALWAYS
 je .progress
 cmp rbx,NEBOC_TERMINAL_AUTO
 jne .verbose
 mov qword [rel cli_terminal_policy+NEBOC_TERMINAL_POLICY_COLOR_OFFSET],NEBOC_TERMINAL_AUTO
 mov qword [rel cli_terminal_policy+NEBOC_TERMINAL_POLICY_UNICODE_OFFSET],NEBOC_TERMINAL_UNICODE_AUTO
 mov qword [rel cli_terminal_policy+NEBOC_TERMINAL_POLICY_FALLBACK_WIDTH_OFFSET],80
 mov edi,2
 lea rsi,[rel cli_terminal_policy]
 lea rdx,[rel cli_terminal_caps]
 call neboc_terminal_capabilities
 test eax,eax
 jnz .ok
 cmp qword [rel cli_terminal_caps+NEBOC_TERMINAL_CAP_TTY_OFFSET],1
 jne .verbose
.progress:
 lea rdi,[rel progress_summary]
 mov esi,progress_summary_end-progress_summary
 call cli_write_stderr_raw
.verbose:
 cmp qword [rel cli_verbose],1
 jne .trace
 lea rdi,[rel verbose_summary]
 mov esi,verbose_summary_end-verbose_summary
 call cli_write_stderr_raw
.trace:
 mov rdi,[rel cli_trace_component]
 test rdi,rdi
 jz .ok
 lea rdi,[rel trace_prefix]
 mov esi,trace_prefix_end-trace_prefix
 call cli_write_stderr_raw
 mov rdi,[rel cli_trace_component]
 mov rsi,[rel cli_trace_component_length]
 call cli_write_stderr_raw
 lea rdi,[rel trace_suffix]
 mov esi,trace_suffix_end-trace_suffix
 call cli_write_stderr_raw
.ok:
 xor eax,eax
 pop rbx
 ret

cli_write_stdout:
 mov rdx,rsi
 mov rsi,rdi
 mov edi,1
 mov eax,1
 syscall
 ret

cli_write_stderr:
 cmp qword [rel cli_message_format],3
 jae cli_write_stderr_suppressed
 cmp qword [rel cli_machine_reporting],1
 je cli_write_stderr_suppressed
cli_write_stderr_raw:
 mov rdx,rsi
 mov rsi,rdi
 mov edi,2
 mov eax,1
 syscall
 ret
cli_write_stderr_suppressed:
 xor eax,eax
 ret

%include "compiler/driver/cli/linux-x86_64/path_cli.inc"
%include "compiler/driver/cli/linux-x86_64/net_port_cli.inc"
%include "compiler/driver/cli/linux-x86_64/visual_summary_cli.inc"
%include "compiler/driver/cli/linux-x86_64/probabilistic_report_cli.inc"
%include "compiler/driver/cli/linux-x86_64/firmware_cli.inc"
%include "compiler/driver/cli/linux-x86_64/simulation_cli.inc"
%include "compiler/driver/cli/linux-x86_64/security_optimization_cli.inc"
%include "compiler/driver/cli/linux-x86_64/protocol_cli.inc"

section .note.GNU-stack noalloc noexec nowrite progbits
