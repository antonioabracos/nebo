; Nebo Assembly — MF035 public CLI driver for Linux x86-64
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/diagnostics/warning_policy.inc"
%include "compiler/diagnostics/warning_registry.inc"
%include "compiler/diagnostics/recovery.inc"
%include "compiler/diagnostics/renderer.inc"
%include "compiler/diagnostics/diagnostic.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/diagnostics/machine.inc"
%include "compiler/source/span/source_span.inc"
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
%include "compiler/semantic/modules/entrypoint_resolver.inc"
%include "compiler/parser/target_manifest.inc"
%include "compiler/semantic/modules/target_registry.inc"
%include "compiler/semantic/modules/target_path.inc"
%include "compiler/semantic/modules/test_runner_plan.inc"
%include "compiler/interface/interface_v1.inc"
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

; C13-PRC-A3 keeps owner storage private and bounded.  This is an internal
; compiler capacity, not a public Nebo language or ABI limit.
%define NEBOC_MULTI_OWNER_MAX 256

extern neboc_lexer_scan
extern neboc_ast_builder_init
extern neboc_parser_parse
extern neboc_parser_parse_function
extern neboc_ast_builder_node
extern neboc_statement_parse
extern neboc_statement_parse_block
extern neboc_statement_set_error
extern neboc_foundation_float_recognize
extern neboc_numeric_safety_vertical_recognize
extern neboc_text_char_bytes_vertical_recognize
extern neboc_text_char_bytes_api_contract
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
extern neboc_assembly_writer_append_u64_decimal
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
extern neboc_format_adapter_emit_named_entry_prelude
extern neboc_target_manifest_parse
extern neboc_target_registry_select
extern neboc_target_path_open_read
extern neboc_test_runner_plan
extern neboc_interface_read
extern neboc_toolchain_init
extern neboc_toolchain_build_assembler_invocation
extern neboc_toolchain_build_linker_invocation
extern neboc_toolchain_execute
extern nebo_bench_cli_run
extern neboc_diagnostic_explanation_load
extern neboc_diagnostic_explanation_render
extern neboc_diagnostic_explanation_search
extern neboc_diagnostic_catalog_lookup
extern neboc_diagnostic_encoder_json
extern neboc_diagnostic_encoder_json_lines
extern neboc_diagnostic_encoder_sarif
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
 db '              [--target-kind executable|example|library]',10
 db '  neboc check --manifest <nebo.targets> [--target <TargetId>]',10
 db '  neboc emit-asm <file.no> -o <file.asm> [--unit <file.no>] [--target-kind executable|example|library]',10
 db '  neboc emit-asm --manifest <nebo.targets> [--target <TargetId>] -o <file.asm>',10
 db '  neboc build <file.no> -o <artifact> [--keep-temp] [--unit <file.no>] [--target-kind executable|example|library]',10
 db '  neboc build --manifest <nebo.targets> [--target <TargetId>] -o <artifact>',10
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
cli_function_console_name: db 'console'
cli_function_console_name_len equ $-cli_function_console_name
cli_function_scan_name: db 'scan'
cli_function_scan_name_len equ $-cli_function_scan_name
cli_function_mutable_name: db 'mutable'
cli_function_mutable_name_len equ $-cli_function_mutable_name
cli_function_return_name: db 'return'
cli_function_return_name_len equ $-cli_function_return_name
cli_buffer_type_name: db 'Buffer'
cli_buffer_type_name_len equ $-cli_buffer_type_name
cli_buffer_zeroed_name: db 'zeroed'
cli_buffer_zeroed_name_len equ $-cli_buffer_zeroed_name
cli_buffer_with_capacity_name: db 'withCapacity'
cli_buffer_with_capacity_name_len equ $-cli_buffer_with_capacity_name

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
cli_error_target_manifest: db 'NEBO-C03-TARGET-002: target manifest validation failed',10
cli_error_target_manifest_end:
cli_error_target_selection: db 'NEBO-C03-TARGET-009: exact TargetId selection failed',10
cli_error_target_selection_end:
cli_error_target_path: db 'NEBO-C03-TARGET-013: selected target member path is not secure',10
cli_error_target_path_end:
cli_error_target_interface: db 'NEBO-C03-TARGET-016: selected NI-v1 interface is invalid',10
cli_error_target_interface_end:
cli_error_target_test: db 'NEBO-C03-TARGET-017: selected test reference is invalid',10
cli_error_target_test_end:
cli_error_target_collision: db 'NEBO-C03-TARGET-014: output aliases a manifest input',10
cli_error_target_collision_end:
cli_error_target_runner: db 'NEBO-C03-TARGET-020: private test runner invariant failed',10
cli_error_target_runner_end:
cli_target_code_002: db 'NEBO-C03-TARGET-002'
cli_target_code_002_len equ $-cli_target_code_002
cli_target_code_009: db 'NEBO-C03-TARGET-009'
cli_target_code_009_len equ $-cli_target_code_009
cli_target_code_013: db 'NEBO-C03-TARGET-013'
cli_target_code_013_len equ $-cli_target_code_013
cli_target_code_014: db 'NEBO-C03-TARGET-014'
cli_target_code_014_len equ $-cli_target_code_014
cli_target_code_016: db 'NEBO-C03-TARGET-016'
cli_target_code_016_len equ $-cli_target_code_016
cli_target_code_017: db 'NEBO-C03-TARGET-017'
cli_target_code_017_len equ $-cli_target_code_017
cli_target_code_020: db 'NEBO-C03-TARGET-020'
cli_target_code_020_len equ $-cli_target_code_020
cli_target_json_prefix: db '{"schema":1,"code":"'
cli_target_json_prefix_len equ $-cli_target_json_prefix
cli_target_json_suffix: db '","severity":1,"category":3,"phase":4,"messageKey":"target.validation.failed","primary":{"sourceId":1,"start":0,"end":1}}',10
cli_target_json_suffix_len equ $-cli_target_json_suffix
cli_target_sarif_prefix: db '{"version":"2.1.0","runs":[{"tool":{"driver":{"name":"neboc"}},"results":[{"ruleId":"'
cli_target_sarif_prefix_len equ $-cli_target_sarif_prefix
cli_target_sarif_suffix: db '","level":"error","message":{"text":"target validation failed"}}]}]}',10
cli_target_sarif_suffix_len equ $-cli_target_sarif_suffix
cli_target_code_prefix: db 'NEBO-C03-TARGET-'
cli_target_code_prefix_len equ $-cli_target_code_prefix
cli_target_human_suffix: db ': target validation failed',10
cli_target_human_suffix_len equ $-cli_target_human_suffix
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
cli_semantic_code_bit_receiver: db 'NEBO-TIPOS-PRIMITIVOS-ESCALARES-011'
cli_semantic_code_bit_receiver_end:
cli_semantic_message_bit_receiver: db 'bounded bit methods require an Int receiver'
cli_semantic_message_bit_receiver_end:
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
cli_semantic_code_assignment_type: db 'NEBO-LITERAIS-NUMERICOS-BASES-E-REPRESENTACAO-010'
cli_semantic_code_assignment_type_end:
cli_semantic_message_assignment_type: db 'assignment value type does not match the target place type'
cli_semantic_message_assignment_type_end:
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
cli_semantic_code_use_after_move: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-001'
cli_semantic_code_use_after_move_end:
cli_semantic_message_use_after_move: db 'value cannot be used after it has been moved'
cli_semantic_message_use_after_move_end:
cli_semantic_code_textual_unknown: db 'NEBO-TEXT-CHAR-UNICODE-E-BYTES-TEXTUAL-API-UNKNOWN'
cli_semantic_code_textual_unknown_end:
cli_semantic_message_textual_unknown: db 'unknown Text/Char/Bytes foundation API'
cli_semantic_message_textual_unknown_end:
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
cli_semantic_code_missing_argument: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-012'
cli_semantic_code_missing_argument_end:
cli_semantic_message_missing_argument: db 'required bounded argument is missing'
cli_semantic_message_missing_argument_end:
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
cli_semantic_code_module_private: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-022'
cli_semantic_code_module_private_end:
cli_semantic_message_module_private: db 'private module export is inaccessible from the importing unit'
cli_semantic_message_module_private_end:
seguranca_numerica_conversoes_e_overflow_cli_error_023: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-023: static module import graph contains a cycle',10
seguranca_numerica_conversoes_e_overflow_cli_error_023_end:
seguranca_numerica_conversoes_e_overflow_cli_error_008: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-008: canonical module identity collision',10
seguranca_numerica_conversoes_e_overflow_cli_error_008_end:
seguranca_numerica_conversoes_e_overflow_cli_error_024: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-024: qualified symbol is not exported by the referenced module',10
seguranca_numerica_conversoes_e_overflow_cli_error_024_end:
cli_semantic_code_module_export: db 'NEBO-SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-024'
cli_semantic_code_module_export_end:
cli_semantic_message_module_export: db 'qualified symbol is not exported by the referenced module'
cli_semantic_message_module_export_end:
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
cli_semantic_code_result_non_exhaustive: db 'NEBO-BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-008'
cli_semantic_code_result_non_exhaustive_end:
cli_semantic_message_result_non_exhaustive: db 'match does not cover every bounded variant'
cli_semantic_message_result_non_exhaustive_end:
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
option_result_null_externo_e_erros_tipados_cli_error_033: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-033: collection record capacity exceeds the bounded maximum of 256',10
option_result_null_externo_e_erros_tipados_cli_error_033_end:
option_result_null_externo_e_erros_tipados_cli_error_034: db 'NEBO-OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-034: collection scalar pool capacity exceeds the bounded maximum of 2048',10
option_result_null_externo_e_erros_tipados_cli_error_034_end:
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
cli_semantic_code_duplicate_field: db 'NEBO-STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR-DUPLICATE-FIELD'
cli_semantic_code_duplicate_field_end:
cli_semantic_message_duplicate_field: db 'field is declared or initialized more than once'
cli_semantic_message_duplicate_field_end:
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
scientific_cli_error_matrix_dtype:
scientific_cli_code_matrix_dtype: db 'NEBO-SCIENTIFIC-001'
scientific_cli_code_matrix_dtype_end:
 db ': '
scientific_cli_message_matrix_dtype: db 'Matrix public dtype must be Int'
scientific_cli_message_matrix_dtype_end:
 db 10
scientific_cli_error_matrix_dtype_end:
scientific_cli_error_matrix_limit:
scientific_cli_code_matrix_limit: db 'NEBO-SCIENTIFIC-007'
scientific_cli_code_matrix_limit_end:
 db ': '
scientific_cli_message_matrix_limit: db 'Matrix rows, columns and checked element product exceed CPU_I64_SMALL_V1 limits'
scientific_cli_message_matrix_limit_end:
 db 10
scientific_cli_error_matrix_limit_end:
scientific_cli_error_matrix_syntax:
scientific_cli_code_matrix_syntax: db 'NEBO-SCIENTIFIC-002'
scientific_cli_code_matrix_syntax_end:
 db ': '
scientific_cli_message_matrix_syntax: db 'expected Matrix<Int>.zeros(rows, columns).binding followed by a scalar result'
scientific_cli_message_matrix_syntax_end:
 db 10
scientific_cli_error_matrix_syntax_end:
scientific_cli_error_matrix_deferred:
scientific_cli_code_matrix_deferred: db 'NEBO-SCIENTIFIC-016'
scientific_cli_code_matrix_deferred_end:
 db ': '
scientific_cli_message_matrix_deferred: db 'Matrix constructor or operation is deferred by the current C11 tier'
scientific_cli_message_matrix_deferred_end:
 db 10
scientific_cli_error_matrix_deferred_end:
scientific_cli_tensor_atom: db 'Tensor'
scientific_cli_tensor_atom_len equ $-scientific_cli_tensor_atom
scientific_cli_error_tensor_dtype:
scientific_cli_code_tensor_dtype: db 'NEBO-SCIENTIFIC-001'
scientific_cli_code_tensor_dtype_end:
 db ': '
scientific_cli_message_tensor_dtype: db 'Tensor public dtype must be Int'
scientific_cli_message_tensor_dtype_end:
 db 10
scientific_cli_error_tensor_dtype_end:
scientific_cli_error_tensor_syntax:
scientific_cli_code_tensor_syntax: db 'NEBO-SCIENTIFIC-002'
scientific_cli_code_tensor_syntax_end:
 db ': '
scientific_cli_message_tensor_syntax: db 'expected Tensor<Int> with bounded Tuple.of shape'
scientific_cli_message_tensor_syntax_end:
 db 10
scientific_cli_error_tensor_syntax_end:
scientific_cli_error_tensor_extent:
scientific_cli_code_tensor_extent: db 'NEBO-SCIENTIFIC-003'
scientific_cli_code_tensor_extent_end:
 db ': '
scientific_cli_message_tensor_extent: db 'Tensor shape does not match the selected source extent'
scientific_cli_message_tensor_extent_end:
 db 10
scientific_cli_error_tensor_extent_end:
scientific_cli_error_tensor_overflow:
scientific_cli_code_tensor_overflow: db 'NEBO-SCIENTIFIC-005'
scientific_cli_code_tensor_overflow_end:
 db ': '
scientific_cli_message_tensor_overflow: db 'Tensor shape product overflowed before publication'
scientific_cli_message_tensor_overflow_end:
 db 10
scientific_cli_error_tensor_overflow_end:
scientific_cli_error_tensor_limit:
scientific_cli_code_tensor_limit: db 'NEBO-SCIENTIFIC-007'
scientific_cli_code_tensor_limit_end:
 db ': '
scientific_cli_message_tensor_limit: db 'Tensor rank dimensions or checked element product exceed CPU_I64_SMALL_V1 limits'
scientific_cli_message_tensor_limit_end:
 db 10
scientific_cli_error_tensor_limit_end:
scientific_cli_error_tensor_copy:
scientific_cli_code_tensor_copy: db 'NEBO-SCIENTIFIC-010'
scientific_cli_code_tensor_copy_end:
 db ': '
scientific_cli_message_tensor_copy: db 'Tensor fromBuffer requires a nonoverlapping explicit copy source'
scientific_cli_message_tensor_copy_end:
 db 10
scientific_cli_error_tensor_copy_end:
scientific_cli_error_tensor_deferred:
scientific_cli_code_tensor_deferred: db 'NEBO-SCIENTIFIC-016'
scientific_cli_code_tensor_deferred_end:
 db ': '
scientific_cli_message_tensor_deferred: db 'Tensor constructor or operation is deferred by the current C12 tier'
scientific_cli_message_tensor_deferred_end:
 db 10
scientific_cli_error_tensor_deferred_end:
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
cli_name_match: db 'match'
cli_name_match_len equ $-cli_name_match
cli_name_float_type: db 'Float'
cli_name_float_type_len equ $-cli_name_float_type
cli_name_to_float: db 'toFloat'
cli_name_to_float_len equ $-cli_name_to_float
cli_name_is_finite: db 'isFinite'
cli_name_is_finite_len equ $-cli_name_is_finite
cli_name_is_nan: db 'isNaN'
cli_name_is_nan_len equ $-cli_name_is_nan
cli_name_is_infinite: db 'isInfinite'
cli_name_is_infinite_len equ $-cli_name_is_infinite
cli_name_is_negative_zero: db 'isNegativeZero'
cli_name_is_negative_zero_len equ $-cli_name_is_negative_zero
; C13-PRC-A3 compiler-private routing atoms.  These names do not define a
; source surface: the existing scientific vertical still authenticates the
; complete Matrix/Tensor grammar and every public operation.
cli_scientific_name_matrix: db 'Matrix'
cli_scientific_name_matrix_len equ $-cli_scientific_name_matrix
cli_scientific_name_tensor: db 'Tensor'
cli_scientific_name_tensor_len equ $-cli_scientific_name_tensor
cli_scientific_name_array: db 'Array'
cli_scientific_name_array_len equ $-cli_scientific_name_array
cli_scientific_name_sum: db 'sum'
cli_scientific_name_sum_len equ $-cli_scientific_name_sum
cli_scientific_name_at: db 'at'
cli_scientific_name_at_len equ $-cli_scientific_name_at
cli_scientific_name_is_square: db 'isSquare'
cli_scientific_name_is_square_len equ $-cli_scientific_name_is_square
cli_scientific_name_set: db 'set'
cli_scientific_name_set_len equ $-cli_scientific_name_set
cli_nominal_name_type: db 'type'
cli_nominal_name_type_len equ $-cli_nominal_name_type
cli_nominal_name_newtype: db 'newtype'
cli_nominal_name_newtype_len equ $-cli_nominal_name_newtype

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
arg_target_kind: db '--target-kind',0
arg_manifest: db '--manifest',0
arg_target: db '--target',0
arg_executable: db 'executable',0
arg_example: db 'example',0
arg_library: db 'library',0
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
cli_test_runner_head: db 10,'static '
cli_test_runner_head_len equ $-cli_test_runner_head
cli_test_runner_static_tail: db ':function',10
cli_test_runner_static_tail_len equ $-cli_test_runner_static_tail
cli_test_runner_after_label:
 db ':',10,'    push rbp',10,'    mov rbp, rsp',10,'    xor edi, edi',10,'    call nebo_fn_'
cli_test_runner_after_label_len equ $-cli_test_runner_after_label
cli_test_runner_tail:
 db 10,'    test rax, rax',10,'    setne al',10,'    movzx eax, al',10
 db '    mov rsp, rbp',10,'    pop rbp',10,'    ret',10
cli_test_runner_tail_len equ $-cli_test_runner_tail
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
cli_diag_human_separator: db ':'
cli_diag_human_error: db ': error '
cli_diag_human_error_len equ $-cli_diag_human_error
cli_diag_human_message: db ': '
cli_diag_human_newline: db 10
cli_diag_human_related: db '  related '
cli_diag_human_related_len equ $-cli_diag_human_related
cli_diag_human_note: db '  note: '
cli_diag_human_note_len equ $-cli_diag_human_note
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
cli_control_fix_suggestion:
 db 'insert the required control-header parentheses'
cli_control_fix_suggestion_end:
cli_entrypoint_note_missing:
 db 'selected executable or example target requires exactly one start()'
cli_entrypoint_note_missing_end:
cli_entrypoint_note_duplicate:
 db 'the first start() declaration is the related location'
cli_entrypoint_note_duplicate_end:
cli_entrypoint_note_invalid:
 db 'start() permits no parameters or modifiers; status terminals require Int, Bool or Char'
cli_entrypoint_note_invalid_end:
cli_entrypoint_note_ambiguous:
 db 'entrypoint identity is resolved by target membership, never file or linker order'
cli_entrypoint_note_ambiguous_end:
cli_entrypoint_note_forbidden:
 db 'only executable and example targets own an entrypoint'
cli_entrypoint_note_forbidden_end:
cli_entrypoint_label_duplicate:
 db 'first start() declaration'
cli_entrypoint_label_duplicate_end:
cli_fix_lparen: db '('
cli_fix_rparen: db ')'
cli_exact_fix_prefix: db 'fix-it[machineApplicable]: insert "'
cli_exact_fix_prefix_len equ $-cli_exact_fix_prefix
cli_exact_fix_offset: db '" at byte '
cli_exact_fix_offset_len equ $-cli_exact_fix_offset
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
runtime_relative: db '../obj/runtime_practical_io.o',0
runtime_relative_len equ $-runtime_relative-1
runtime_default: db 'build/obj/runtime_practical_io.o',0
runtime_default_len equ $-runtime_default-1

cli_runtime_trap_externs: db 'extern nebo_runtime_trap_overflow',10,'extern nebo_runtime_trap_division_by_zero',10,'extern nebo_runtime_numeric_safety_int_to_float',10,'extern nebo_runtime_numeric_safety_is_finite',10,'extern nebo_runtime_numeric_safety_is_nan',10,'extern nebo_runtime_numeric_safety_is_infinite',10,'extern nebo_runtime_numeric_safety_is_negative_zero',10,'extern nebo_runtime_textual_text_byte_length',10,'extern nebo_runtime_textual_text_codepoint_count',10,'extern nebo_runtime_textual_char_codepoint',10,'extern nebo_runtime_textual_bytes_empty',10,'extern nebo_runtime_textual_bytes_byte_length',10,'extern neboc_runtime_store_zero_payload',10,'extern neboc_runtime_store_integer',10,'extern neboc_runtime_store_float',10,'extern neboc_runtime_tag_test',10,'extern neboc_runtime_unwrap_integer',10,'extern neboc_runtime_unwrap_float',10,'extern nebo_runtime_contract_1',10,'extern nebo_runtime_contract_3',10,'extern nebo_runtime_console_publish_text',10,'extern nebo_runtime_console_publish_int',10,'extern nebo_runtime_console_publish_bool',10,'extern nebo_runtime_scan_stdin_text',10,'extern nebo_runtime_scan_console_handle',10
cli_runtime_trap_externs_end:
cli_text_equal_extern: db 'extern nebo_runtime_text_equal',10
cli_text_equal_extern_len equ $-cli_text_equal_extern

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
cli_entrypoint_target_kind: resq 1
cli_entrypoint_target_kind_seen: resq 1
cli_manifest_path: resq 1
cli_manifest_selector: resq 1
cli_manifest_selector_length: resq 1
cli_manifest_root_fd: resq 1
cli_manifest_selected_record: resq 1
cli_manifest_device: resq 1
cli_manifest_inode: resq 1
cli_manifest_source_device: resq 1
cli_manifest_source_inode: resq 1
cli_manifest_interface_device: resq 1
cli_manifest_interface_inode: resq 1
cli_manifest_diagnostic: resq 1
cli_manifest_bytes: resb NEBOC_TARGET_MANIFEST_MAX_BYTES+1
resb ((8-(($-$$)&7))&7)
cli_manifest_request: resb NEBOC_TARGET_MANIFEST_SIZE
cli_manifest_records: resb NEBOC_TARGET_MANIFEST_MAX_TARGETS*NEBOC_TARGET_RECORD_SIZE
cli_manifest_path_request: resb NEBOC_TARGET_PATH_SIZE
cli_manifest_root_path: resb NEBOC_CLI_PATH_CAPACITY
cli_manifest_selected_source_path: resb NEBOC_TARGET_PATH_MAX_BYTES+1
cli_manifest_interface: resb 0x01000000+1
resb ((8-(($-$$)&7))&7)
cli_manifest_interface_summary: resb 64
cli_manifest_stat: resb 144
cli_manifest_output_stat: resb 144
cli_test_runner_request: resb NEBOC_TEST_RUNNER_REQUEST_SIZE
cli_test_runner_label: resb 34
cli_target_dynamic_code: resb 32
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
cli_general_tokens: resb NEBOC_CLI_TOKEN_CAPACITY*NEBOC_TOKEN_SIZE
cli_general_token_count: resq 1
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
cli_function_textual_validated: resq 1
bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic: resq 1
literais_numericos_bases_e_representacao_cli_parse_request: resb neboc_literais_numericos_bases_e_representacao_PARSE_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_symbols: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_branch_a: resb NEBOC_VERTICAL_MAX_BRANCH_SNAPSHOTS*NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
cli_branch_b: resb NEBOC_VERTICAL_MAX_BRANCH_SNAPSHOTS*NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
cli_branch_a_counts: resq NEBOC_VERTICAL_MAX_BRANCH_SNAPSHOTS
cli_branch_b_counts: resq NEBOC_VERTICAL_MAX_BRANCH_SNAPSHOTS
cli_loop_snapshots: resb NEBOC_VERTICAL_MAX_LOOP_DEPTH*neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
cli_loop_bodies: resb NEBOC_VERTICAL_MAX_LOOP_DEPTH*NEBOC_VERTICAL_LOOP_SNAPSHOT_BYTES
cli_loop_body_counts: resq NEBOC_VERTICAL_MAX_LOOP_DEPTH
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
cli_nominal_owner_count: resq 1
cli_nominal_owners: resb NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_REQUEST_SIZE
cli_nominal_owner_variants: resb NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_SIZE
cli_nominal_owner_plans: resb NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_PLAN_SIZE
resb ((8-(($-$$)&7))&7)
; Owner ordinal is the stable arena index.  The first records retain their
; historical symbols so existing diagnostic and codegen consumers remain
; byte-layout compatible while every same-kind owner receives isolated state.
cli_buffer_owner_count: resq 1
cli_buffer: resb NEBOC_MULTI_OWNER_MAX*NEBOC_BUFFER_F11_REQUEST_SIZE
cli_buffer_plan: resb NEBOC_MULTI_OWNER_MAX*NEBOC_BUFFER_PLAN_F11_SIZE
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
; Program-wide scientific owner registry.  Every entry is produced by the
; unchanged source-to-runtime vertical from a bounded synthetic `start` view
; whose tokens retain the exact original source spans.  The parallel
; half-open token ranges are compiler-private composition metadata.
%define NEBOC_CLI_SCIENTIFIC_OWNER_MAX 64
%define NEBOC_CLI_SCIENTIFIC_SCRATCH_TOKEN_MAX 512
cli_scientific_owner_count: resq 1
cli_scientific_owners: resb NEBOC_CLI_SCIENTIFIC_OWNER_MAX*NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
cli_scientific_owner_starts: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_ends: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_preamble_starts: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_preamble_ends: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_source_starts: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_source_ends: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
; Zero means the authenticated helper has no scalar result binding in the
; shared AST.  Nonzero entries are original token ordinals and let the
; filtered FunctionTable retain exactly one typed scalar anchor per helper.
cli_scientific_owner_result_tokens: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_owner_result_source_starts: resq NEBOC_CLI_SCIENTIFIC_OWNER_MAX
cli_scientific_program_start_index: resq 1
cli_scientific_program_start_close: resq 1
cli_scientific_probe_preamble_start: resq 1
cli_scientific_probe_preamble_end: resq 1
cli_scientific_scratch_tokens: resb NEBOC_CLI_SCIENTIFIC_SCRATCH_TOKEN_MAX*NEBOC_TOKEN_SIZE
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
cli_function_signatures: resb NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS*NEBOC_ABI_SIGNATURE_SIZE
cli_function_plans: resb NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS*NEBOC_FUNCTION_PLAN_SIZE
cli_float_codegen_request: resb NEBOC_FLOAT_CODEGEN_SIZE
seguranca_numerica_conversoes_e_overflow_cli_codegen_request: resb neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_REQUEST_SIZE
text_char_unicode_e_bytes_cli_codegen_request: resb neboc_text_char_unicode_e_bytes_CODEGEN_REQUEST_SIZE
bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request: resb neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_REQUEST_SIZE
cli_loop_stack: resq NEBOC_CODEGEN_MAX_LOOP_DEPTH
cli_binding_slot_catalog: resb NEBOC_CODEGEN_SLOT_CATALOG_CAPACITY*NEBOC_CODEGEN_SLOT_CATALOG_RECORD_SIZE
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
cli_warning_selector_group: resq 1
cli_warning_selector_entry: resb NEBOC_WARNING_ENTRY_SIZE
cli_max_errors: resq 1
cli_recovery_policy: resq 1
cli_build_events_path: resq 1
cli_machine_reporting: resq 1
cli_textual_frontend_error_token: resq 1
cli_textual_api_probe: resb neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE
cli_canonical_diagnostic: resb NEBOC_DIAGNOSTIC_SIZE
cli_diag_catalog_entry: resb NEBOC_DIAG_ENTRY_SIZE
cli_diag_writer: resb NEBOC_WRITER_SIZE
cli_diag_output: resb NEBOC_MACHINE_MAX_OUTPUT
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

extern neboc_warning_policy_group
extern neboc_warning_registry_lookup

; Validate one frozen warning selector exactly. Unknown codes/groups and
; overlong or empty selectors fail closed before source processing.
cli_warning_selector_valid:
 test rdi,rdi
 jz .selector_invalid
 push rbx
 push r12
 mov rbx,rdi
 xor r12d,r12d
.selector_length:
 cmp r12,64
 jae .selector_invalid_pop
 cmp byte [rbx+r12],0
 je .selector_validate
 inc r12
 jmp .selector_length
.selector_validate:
 test r12,r12
 jz .selector_invalid_pop
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel cli_warning_selector_group]
 call neboc_warning_policy_group
 test eax,eax
 jz .selector_valid
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel cli_warning_selector_entry]
 call neboc_warning_registry_lookup
 test eax,eax
 jnz .selector_invalid_pop
.selector_valid:
 mov eax,1
 pop r12
 pop rbx
 ret
.selector_invalid_pop:
 xor eax,eax
 pop r12
 pop rbx
 ret
.selector_invalid:
 xor eax,eax
 ret

; Exact NUL-terminated selector equality, bounded by the validated 64-byte cap.
cli_warning_selector_equal:
 xor eax,eax
 xor ecx,ecx
.selector_equal_loop:
 cmp rcx,64
 jae .selector_equal_no
 mov dl,[rdi+rcx]
 cmp dl,[rsi+rcx]
 jne .selector_equal_no
 test dl,dl
 jz .selector_equal_yes
 inc rcx
 jmp .selector_equal_loop
.selector_equal_yes:
 mov eax,1
.selector_equal_no:
 ret

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
 mov qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_EXECUTABLE
 mov qword [rel cli_entrypoint_target_kind_seen],0
 mov qword [rel cli_manifest_path],0
 mov qword [rel cli_manifest_selector],0
 mov qword [rel cli_manifest_selector_length],0
 mov qword [rel cli_manifest_root_fd],-1
 mov qword [rel cli_manifest_selected_record],0
 mov qword [rel cli_manifest_diagnostic],0
 mov qword [rel cli_manifest_device],0
 mov qword [rel cli_manifest_inode],0
 mov qword [rel cli_manifest_source_device],0
 mov qword [rel cli_manifest_source_inode],0
 mov qword [rel cli_manifest_interface_device],0
 mov qword [rel cli_manifest_interface_inode],0
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
 lea rsi,[rel arg_manifest]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .parse_manifest
 mov rdi,rbx
 lea rsi,[rel arg_target]
 mov edx,8
 call cli_arg_equals
 test eax,eax
 jnz .parse_target
 mov rdi,rbx
 lea rsi,[rel arg_target_kind]
 mov edx,13
 call cli_arg_equals
 test eax,eax
 jnz .parse_target_kind
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
 mov rbx,rax
 push rdx
 mov rdi,rbx
 call cli_warning_selector_valid
 test eax,eax
 jz .warning_rule_invalid
 xor r15d,r15d
.warning_rule_duplicate_scan:
 cmp r15,[rel cli_warning_rule_count]
 jae .warning_rule_unique
 lea rax,[rel cli_warning_rules]
 mov r8,r15
 shl r8,4
 mov rdi,rbx
 mov rsi,[rax+r8]
 call cli_warning_selector_equal
 test eax,eax
 jnz .warning_rule_invalid
 inc r15
 jmp .warning_rule_duplicate_scan
.warning_rule_unique:
 pop rdx
 mov rax,rbx
 mov rcx,[rel cli_warning_rule_count]
 lea rsi,[rel cli_warning_rules]
 mov r8,rcx
 shl r8,4
 mov [rsi+r8],rax
 mov [rsi+r8+8],rdx
 inc rcx
 mov [rel cli_warning_rule_count],rcx
 inc r14
 jmp .parse_loop
.warning_rule_invalid:
 pop rdx
 jmp .usage
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
.parse_manifest:
 cmp qword [rel cli_manifest_path],0
 jne .usage
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
 mov [rel cli_manifest_path],rax
 inc r14
 jmp .parse_loop
.parse_target:
 cmp qword [rel cli_manifest_selector],0
 jne .usage
 inc r14
 cmp r14,r12
 jae .usage
 mov rdi,[r13+r14*8]
 test rdi,rdi
 jz .usage
 cmp byte [rdi],0
 je .usage
 cmp byte [rdi],'-'
 je .usage
 mov [rel cli_manifest_selector],rdi
 call cli_strlen_path
 cmp rax,-1
 je .usage
 mov [rel cli_manifest_selector_length],rax
 inc r14
 jmp .parse_loop
.parse_target_kind:
 cmp qword [rel cli_entrypoint_target_kind_seen],0
 jne .usage
 mov qword [rel cli_entrypoint_target_kind_seen],1
 inc r14
 cmp r14,r12
 jae .usage
 mov rbx,[r13+r14*8]
 mov rdi,rbx
 lea rsi,[rel arg_executable]
 mov edx,10
 call cli_arg_equals
 test eax,eax
 jnz .target_kind_done
 mov rdi,rbx
 lea rsi,[rel arg_example]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jnz .target_kind_example
 mov rdi,rbx
 lea rsi,[rel arg_library]
 mov edx,7
 call cli_arg_equals
 test eax,eax
 jz .usage
 mov qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 jmp .target_kind_done
.target_kind_example:
 mov qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_EXAMPLE
.target_kind_done:
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
 cmp qword [rel cli_manifest_path],0
 jne .manifest_shape
 cmp qword [rel cli_manifest_selector],0
 jne .usage
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 jne .target_units_ready
 cmp qword [rel cli_module_unit_count],0
 jne .usage
.target_units_ready:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],0
 je .usage
 jmp .input_shape_ready
.manifest_shape:
 cmp qword [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],0
 jne .usage
 cmp qword [rel cli_module_unit_count],0
 jne .usage
 cmp qword [rel cli_entrypoint_target_kind_seen],0
 jne .usage
.input_shape_ready:
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
 cmp qword [rel cli_manifest_path],0
 jne .load_manifest_target
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
 jmp .source_loaded
.load_manifest_target:
 call cli_load_manifest_target
 test eax,eax
 jnz .report_status
.source_loaded:
 ; Owner-specific reporters remain presentation-silent.  Every rejected
 ; source is rendered once from the canonical typed record below.
 mov qword [rel cli_machine_reporting],1
.frontend_call:
 call cli_frontend_validate
 test eax,eax
 jnz .frontend_failed
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 jne .frontend_ready
 call cli_prepare_test_runner
 test eax,eax
 jz .frontend_ready
 cmp eax,NEBOC_STATUS_INTERNAL_ERROR
 jne .test_plan_source
 mov qword [rel cli_manifest_diagnostic],20
 call cli_invalidate_rejected_source_outputs
 call cli_emit_target_diagnostic
 mov eax,70
 jmp .done
.test_plan_source:
 mov qword [rel cli_manifest_diagnostic],17
 jmp .source
.frontend_failed:
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
 ; A binding lexically contained by an if/else inside a receiver-first
 ; function belongs to the shared function scope owner. The legacy binding
 ; vertical has no branch-scope model and must not reject that bounded form.
 call cli_program_is_function_branch_binding
 cmp eax,-1
 je .source
 cmp eax,1
 je .binding_function_composition_yield
 ; A Console-bearing function is owned as one unit by the shared function
 ; backend.  Yield legacy binding diagnostics before they can split the body
 ; away from the already-public Console receiver expression.
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 cmp eax,1
 je .binding_function_composition_yield
 ; The binding vertical cannot infer a call whose scalar result is produced by
 ; branch terminals.  Its legacy scalar-type-mismatch is yielded for any
 ; parsed function+if program.  The older binding expression walker reports
 ; its internal sentinel for the narrower Char-returning form, so yield that
 ; sentinel only after the shared AST proves function+if+Char structure.  All
 ; other binding failures retain their established owner and diagnostic.
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_BIND_DIAG_TYPE_MISMATCH
 je .binding_function_exit_flow
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 jne .binding_semantic_error
 call cli_program_is_char_exit_flow
 jmp .binding_exit_flow_classified
.binding_function_exit_flow:
 call cli_program_is_function_exit_flow
.binding_exit_flow_classified:
 cmp eax,1
 jne .binding_semantic_error
.binding_function_composition_yield:
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],0
 jmp .bindings_constantes_mutabilidade_e_definite_assignment_semantic_ready
.binding_semantic_error:
 call bindings_constantes_mutabilidade_e_definite_assignment_cli_report_semantic_diagnostic
 jmp .source
.bindings_constantes_mutabilidade_e_definite_assignment_semantic_ready:
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 je .bindings_exit_flow_ready
 ; The legacy binding vertical can successfully recognize the caller binding
 ; while still lacking ownership of a comparison plus Char-valued branch
 ; result.  Keep the binding in the shared AST and yield only this already
 ; classified Char exit-flow program to the function backend.
 call cli_program_is_function_branch_binding
 cmp eax,-1
 je .source
 test eax,eax
 jnz .binding_found_function_yield
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 test eax,eax
 jnz .binding_found_function_yield
 call cli_program_is_char_exit_flow
 cmp eax,-1
 je .source
 test eax,eax
 jz .bindings_exit_flow_ready
.binding_found_function_yield:
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],0
.bindings_exit_flow_ready:
 call cli_recognize_text_char_bytes
 test eax,eax
 jz .text_char_unicode_e_bytes_semantic_ready
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 test eax,eax
 jnz .text_function_composition_yield
 call cli_program_is_char_exit_flow
 cmp eax,-1
 je .source
 test eax,eax
 jz .text_char_semantic_error
.text_function_composition_yield:
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 je .text_function_composition_no_validated_owner
 mov qword [rel cli_function_textual_validated],1
.text_function_composition_no_validated_owner:
 mov qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 mov qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],0
 jmp .text_char_unicode_e_bytes_semantic_ready
.text_char_semantic_error:
 call text_char_unicode_e_bytes_cli_report_semantic_diagnostic
 jmp .source
.text_char_unicode_e_bytes_semantic_ready:
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 jne .generate
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 je .text_char_route_ready
 ; Char literals normally belong to the dedicated textual vertical.  A
 ; receiver-first Char function containing bounded if/else is the one causal
 ; exception: its exits must be analyzed together with Int/Bool by the shared
 ; function CFG owner.  Straight-line Char functions retain their certified
 ; F02 route.
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 test eax,eax
 jnz .text_found_function_yield
 call cli_program_is_char_exit_flow
 cmp eax,-1
 je .source
 test eax,eax
 jz .generate
.text_found_function_yield:
 mov qword [rel cli_function_textual_validated],1
 mov qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_FOUND_OFFSET],0
 mov qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],0
.text_char_route_ready:
 call cli_recognize_numeric_safety
 test eax,eax
 jz .seguranca_numerica_conversoes_e_overflow_semantic_ready
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 test eax,eax
 jnz .numeric_function_composition_yield
 call cli_program_is_char_exit_flow
 cmp eax,-1
 je .source
 test eax,eax
 jz .numeric_semantic_error
.numeric_function_composition_yield:
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],0
 jmp .seguranca_numerica_conversoes_e_overflow_semantic_ready
.numeric_semantic_error:
 call seguranca_numerica_conversoes_e_overflow_cli_report_semantic_diagnostic
 jmp .source
.seguranca_numerica_conversoes_e_overflow_semantic_ready:
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 je .numeric_route_ready
 ; A numeric comparison may be the Bool condition of the same bounded Char
 ; exit-flow function routed above.  In that exact structural case the shared
 ; function backend owns both the comparison and the Char return merge; do not
 ; let the legacy whole-program numeric vertical split the function CFG.
 call cli_program_is_function_composition
 cmp eax,-1
 je .source
 test eax,eax
 jnz .numeric_found_function_yield
 call cli_program_is_char_exit_flow
 cmp eax,-1
 je .source
 test eax,eax
 jz ._materialize
.numeric_found_function_yield:
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],0
.numeric_route_ready:
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
 mov qword [rel cli_machine_reporting],0
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
 jne .report_toolchain
 cmp qword [rel cli_manifest_diagnostic],0
 je .io
 call cli_invalidate_rejected_source_outputs
 call cli_emit_target_diagnostic
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.report_toolchain:
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
 call cli_invalidate_rejected_source_outputs
 mov rdi,[rel cli_build_events_path]
 test rdi,rdi
 jz .source_format
 lea rsi,[rel build_events_failure]
 mov edx,build_events_failure_end-build_events_failure
 call cli_write_file
 test eax,eax
 jnz .io
.source_format:
 cmp qword [rel cli_manifest_diagnostic],0
 je .source_canonical
 call cli_emit_target_diagnostic
 mov qword [rel cli_machine_reporting],0
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.source_canonical:
 call cli_prepare_canonical_diagnostic
 test eax,eax
 jnz .internal
 call cli_emit_canonical_diagnostic
 test eax,eax
 jnz .internal
 cmp qword [rel cli_show_fixes],1
 jne .source_human_done
 cmp qword [rel cli_message_format],3
 jae .source_human_done
 test qword [rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_FIXITS
 jz .source_generic_fix
 call cli_emit_exact_control_fixits
 jmp .source_human_done
.source_generic_fix:
 lea rdi,[rel cli_fix_preview]
 mov esi,cli_fix_preview_end-cli_fix_preview
 call cli_write_stderr_raw
.source_human_done:
 mov qword [rel cli_machine_reporting],0
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

; Open the explicit manifest without following any path-component symlink,
; read at most 4096 bytes, authenticate its regular-file identity, and retain
; one O_PATH fd for the containing workspace directory.
cli_read_target_manifest:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,176
 mov r12,[rel cli_manifest_path]
 test r12,r12
 jz .invalid
 mov rdi,r12
 call cli_strlen_path
 cmp rax,-1
 je .invalid
 test rax,rax
 jz .invalid
 mov r13,rax
 mov qword [rsp],0x80000             ; O_RDONLY|O_CLOEXEC
 mov qword [rsp+8],0
 mov qword [rsp+16],6                ; NO_MAGICLINKS|NO_SYMLINKS
 mov eax,437
 mov rdi,-100
 mov rsi,r12
 lea rdx,[rsp]
 mov r10d,24
 syscall
 cmp rax,-4095
 jae .open_error
 mov rbx,rax
 mov eax,5
 mov rdi,rbx
 lea rsi,[rsp+24]
 syscall
 test rax,rax
 js .close_io
 mov eax,[rsp+48]                    ; struct stat st_mode
 and eax,0xf000
 cmp eax,0x8000                      ; S_IFREG
 jne .close_source
 mov rax,[rsp+24]
 mov [rel cli_manifest_device],rax
 mov rax,[rsp+32]
 mov [rel cli_manifest_inode],rax
 xor r14d,r14d
.read:
 cmp r14,NEBOC_TARGET_MANIFEST_MAX_BYTES
 jae .probe
 xor eax,eax
 mov rdi,rbx
 lea rsi,[rel cli_manifest_bytes]
 add rsi,r14
 mov rdx,NEBOC_TARGET_MANIFEST_MAX_BYTES
 sub rdx,r14
 syscall
 test rax,rax
 jz .eof
 js .read_error
 add r14,rax
 jmp .read
.probe:
 xor eax,eax
 mov rdi,rbx
 lea rsi,[rsp+168]
 mov edx,1
 syscall
 test rax,rax
 jz .eof
 js .read_error
 mov qword [rel cli_manifest_diagnostic],21
 mov eax,3
 mov rdi,rbx
 syscall
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.read_error:
 cmp rax,-4
 je .read
 jmp .close_io
.eof:
 mov eax,3
 mov rdi,rbx
 syscall
 lea rax,[rel cli_manifest_bytes]
 mov byte [rax+r14],0
 mov [rel cli_manifest_request+NEBOC_TARGET_MANIFEST_LENGTH],r14

 ; Derive the containing directory bytes without normalization.
 mov r15,-1
 xor ecx,ecx
.slash_scan:
 cmp rcx,r13
 jae .slash_done
 cmp byte [r12+rcx],'/'
 jne .slash_next
 mov r15,rcx
.slash_next:
 inc rcx
 jmp .slash_scan
.slash_done:
 lea rdi,[rel cli_manifest_root_path]
 cmp r15,-1
 jne .has_slash
 mov byte [rdi],'.'
 mov byte [rdi+1],0
 jmp .open_root
.has_slash:
 test r15,r15
 jnz .copy_root
 mov byte [rdi],'/'
 mov byte [rdi+1],0
 jmp .open_root
.copy_root:
 xor ecx,ecx
.copy_root_loop:
 cmp rcx,r15
 jae .copy_root_done
 mov al,[r12+rcx]
 mov [rdi+rcx],al
 inc rcx
 jmp .copy_root_loop
.copy_root_done:
 mov byte [rdi+rcx],0
.open_root:
 mov qword [rsp],0x290000            ; O_PATH|O_DIRECTORY|O_CLOEXEC
 mov qword [rsp+8],0
 mov qword [rsp+16],6
 mov eax,437
 mov rdi,-100
 lea rsi,[rel cli_manifest_root_path]
 lea rdx,[rsp]
 mov r10d,24
 syscall
 cmp rax,-4095
 jae .root_error
 mov [rel cli_manifest_root_fd],rax
 xor eax,eax
 jmp .done
.open_error:
 cmp rax,-40
 je .symlink
 mov qword [rel cli_manifest_diagnostic],1
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.root_error:
 cmp rax,-40
 je .symlink
 mov qword [rel cli_manifest_diagnostic],1
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.symlink:
 mov qword [rel cli_manifest_diagnostic],13
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.close_io:
 mov eax,3
 mov rdi,rbx
 syscall
 mov qword [rel cli_manifest_diagnostic],1
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.close_source:
 mov eax,3
 mov rdi,rbx
 syscall
 mov qword [rel cli_manifest_diagnostic],2
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_CLI_EXIT_USAGE_ERROR
.done:
 add rsp,176
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Load, parse and select exactly one target, then open only its direct source
; and optional NI-v1 interface through the retained workspace fd.
cli_load_manifest_target:
 push rbx
 push r12
 push r13
 push r14
 push r15
 call cli_read_target_manifest
 test eax,eax
 jnz .done
 lea rdi,[rel cli_manifest_request]
 mov ecx,NEBOC_TARGET_MANIFEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_manifest_bytes]
 mov [rel cli_manifest_request+NEBOC_TARGET_MANIFEST_BYTES],rax
 ; cli_read_target_manifest retained the length before the clear; recover it
 ; from the canonical terminating LF scan instead of trusting stale state.
 xor ecx,ecx
.manifest_length:
 cmp rcx,NEBOC_TARGET_MANIFEST_MAX_BYTES+1
 jae .manifest_bad
 cmp byte [rax+rcx],0
 je .manifest_length_ready
 inc rcx
 jmp .manifest_length
.manifest_length_ready:
 mov [rel cli_manifest_request+NEBOC_TARGET_MANIFEST_LENGTH],rcx
 lea rax,[rel cli_manifest_records]
 mov [rel cli_manifest_request+NEBOC_TARGET_MANIFEST_RECORDS],rax
 mov qword [rel cli_manifest_request+NEBOC_TARGET_MANIFEST_CAPACITY],NEBOC_TARGET_MANIFEST_MAX_TARGETS
 lea rdi,[rel cli_manifest_request]
 call neboc_target_manifest_parse
 test eax,eax
 jnz .manifest_bad
 lea rdi,[rel cli_manifest_request]
 mov rsi,[rel cli_manifest_selector]
 mov rdx,[rel cli_manifest_selector_length]
 call neboc_target_registry_select
 test eax,eax
 jnz .selection_bad
 mov rax,[rel cli_manifest_request+NEBOC_TARGET_MANIFEST_SELECTED_INDEX]
 cmp rax,NEBOC_TARGET_MANIFEST_MAX_TARGETS
 jae .manifest_bad
 imul rax,NEBOC_TARGET_RECORD_SIZE
 lea r12,[rel cli_manifest_records]
 add r12,rax
 mov [rel cli_manifest_selected_record],r12
 mov rax,[r12+NEBOC_TARGET_RECORD_KIND]
 mov [rel cli_entrypoint_target_kind],rax

 ; NUL-terminated presentation copy of the selected relative source path.
 mov rsi,[r12+NEBOC_TARGET_RECORD_SOURCE_PTR]
 mov rcx,[r12+NEBOC_TARGET_RECORD_SOURCE_LEN]
 lea rdi,[rel cli_manifest_selected_source_path]
 xor edx,edx
.source_path_copy:
 cmp rdx,rcx
 jae .source_path_done
 mov al,[rsi+rdx]
 mov [rdi+rdx],al
 inc rdx
 jmp .source_path_copy
.source_path_done:
 mov byte [rdi+rdx],0
 mov [rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET],rdi

 lea rdi,[rel cli_manifest_path_request]
 mov ecx,NEBOC_TARGET_PATH_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rel cli_manifest_root_fd]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_ROOT_FD],rax
 mov rax,[r12+NEBOC_TARGET_RECORD_SOURCE_PTR]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_BYTES],rax
 mov rax,[r12+NEBOC_TARGET_RECORD_SOURCE_LEN]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_LENGTH],rax
 mov qword [rel cli_manifest_path_request+NEBOC_TARGET_PATH_SUFFIX],NEBOC_TARGET_PATH_SUFFIX_SOURCE
 lea rax,[rel cli_source]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_BUFFER],rax
 mov qword [rel cli_manifest_path_request+NEBOC_TARGET_PATH_CAPACITY],NEBOC_CLI_SOURCE_CAPACITY
 lea rdi,[rel cli_manifest_path_request]
 call neboc_target_path_open_read
 test eax,eax
 jnz .path_bad
 mov rax,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_RESULT_LENGTH]
 mov [rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET],rax
 mov rax,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_DEVICE]
 mov [rel cli_manifest_source_device],rax
 mov rax,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_INODE]
 mov [rel cli_manifest_source_inode],rax
 mov rax,[rel cli_manifest_source_device]
 cmp rax,[rel cli_manifest_device]
 jne .source_identity_ready
 mov rax,[rel cli_manifest_source_inode]
 cmp rax,[rel cli_manifest_inode]
 jne .source_identity_ready
 mov qword [rel cli_manifest_path_request+NEBOC_TARGET_PATH_ERROR],NEBOC_TARGET_PATH_ERROR_MALFORMED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .path_bad
.source_identity_ready:

 cmp qword [r12+NEBOC_TARGET_RECORD_INTERFACE_LEN],0
 je .interface_ready
 lea rdi,[rel cli_manifest_path_request]
 mov ecx,NEBOC_TARGET_PATH_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rel cli_manifest_root_fd]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_ROOT_FD],rax
 mov rax,[r12+NEBOC_TARGET_RECORD_INTERFACE_PTR]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_BYTES],rax
 mov rax,[r12+NEBOC_TARGET_RECORD_INTERFACE_LEN]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_LENGTH],rax
 mov qword [rel cli_manifest_path_request+NEBOC_TARGET_PATH_SUFFIX],NEBOC_TARGET_PATH_SUFFIX_INTERFACE
 lea rax,[rel cli_manifest_interface]
 mov [rel cli_manifest_path_request+NEBOC_TARGET_PATH_BUFFER],rax
 mov qword [rel cli_manifest_path_request+NEBOC_TARGET_PATH_CAPACITY],0x01000000
 lea rdi,[rel cli_manifest_path_request]
 call neboc_target_path_open_read
 test eax,eax
 jnz .path_bad
 mov rax,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_DEVICE]
 mov [rel cli_manifest_interface_device],rax
 mov rax,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_INODE]
 mov [rel cli_manifest_interface_inode],rax
 mov rax,[rel cli_manifest_interface_device]
 cmp rax,[rel cli_manifest_device]
 jne .interface_source_identity
 mov rax,[rel cli_manifest_interface_inode]
 cmp rax,[rel cli_manifest_inode]
 je .interface_bad
.interface_source_identity:
 mov rax,[rel cli_manifest_interface_device]
 cmp rax,[rel cli_manifest_source_device]
 jne .interface_identity_ready
 mov rax,[rel cli_manifest_interface_inode]
 cmp rax,[rel cli_manifest_source_inode]
 je .interface_bad
.interface_identity_ready:
 lea rdi,[rel cli_manifest_interface]
 mov rsi,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_RESULT_LENGTH]
 lea rdx,[rel cli_manifest_interface_summary]
 call neboc_interface_read
 test eax,eax
 jnz .interface_bad
.interface_ready:
 mov rdi,[rel cli_manifest_root_fd]
 mov eax,3
 syscall
 mov qword [rel cli_manifest_root_fd],-1
 call cli_validate_manifest_output
 test eax,eax
 jnz .done
 xor eax,eax
 jmp .done
.manifest_bad:
 mov rax,[rel cli_manifest_request+NEBOC_TARGET_MANIFEST_ERROR]
 mov qword [rel cli_manifest_diagnostic],2
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_SCHEMA
 jne .manifest_diag_field
 mov qword [rel cli_manifest_diagnostic],3
 jmp .manifest_diag_ready
.manifest_diag_field:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_FIELD
 jne .manifest_diag_id
 mov qword [rel cli_manifest_diagnostic],4
 jmp .manifest_diag_ready
.manifest_diag_id:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_ID
 jne .manifest_diag_id_missing
 mov qword [rel cli_manifest_diagnostic],7
 jmp .manifest_diag_ready
.manifest_diag_id_missing:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_ID_MISSING
 jne .manifest_diag_duplicate
 mov qword [rel cli_manifest_diagnostic],6
 jmp .manifest_diag_ready
.manifest_diag_duplicate:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_DUPLICATE_OR_ORDER
 jne .manifest_diag_kind
 mov qword [rel cli_manifest_diagnostic],8
 jmp .manifest_diag_ready
.manifest_diag_kind:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_KIND
 jne .manifest_diag_path
 mov qword [rel cli_manifest_diagnostic],15
 jmp .manifest_diag_ready
.manifest_diag_path:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_PATH
 jne .manifest_diag_path_escape
 mov qword [rel cli_manifest_diagnostic],11
 jmp .manifest_diag_ready
.manifest_diag_path_escape:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_PATH_ESCAPE
 jne .manifest_diag_test
 mov qword [rel cli_manifest_diagnostic],12
 jmp .manifest_diag_ready
.manifest_diag_test:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_TEST
 jne .manifest_diag_empty
 mov qword [rel cli_manifest_diagnostic],17
 jmp .manifest_diag_ready
.manifest_diag_empty:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_TEST_EMPTY
 jne .manifest_diag_limit
 mov qword [rel cli_manifest_diagnostic],19
 jmp .manifest_diag_ready
.manifest_diag_limit:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_LIMIT
 jne .manifest_diag_ready
 mov qword [rel cli_manifest_diagnostic],21
.manifest_diag_ready:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .close_done
.selection_bad:
 mov rax,[rel cli_manifest_request+NEBOC_TARGET_MANIFEST_ERROR]
 mov qword [rel cli_manifest_diagnostic],9
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_ID
 jne .selection_diag_required
 mov qword [rel cli_manifest_diagnostic],7
 jmp .selection_diag_ready
.selection_diag_required:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_SELECTION_REQUIRED
 jne .selection_diag_default
 mov qword [rel cli_manifest_diagnostic],10
 jmp .selection_diag_ready
.selection_diag_default:
 cmp rax,NEBOC_TARGET_MANIFEST_ERROR_DEFAULT_UNKNOWN
 jne .selection_diag_ready
 mov qword [rel cli_manifest_diagnostic],12
.selection_diag_ready:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .close_done
.path_bad:
 mov rdx,[rel cli_manifest_path_request+NEBOC_TARGET_PATH_ERROR]
 mov qword [rel cli_manifest_diagnostic],11
 cmp rdx,NEBOC_TARGET_PATH_ERROR_ESCAPE
 jne .path_diag_symlink
 mov qword [rel cli_manifest_diagnostic],12
 jmp .path_diag_ready
.path_diag_symlink:
 cmp rdx,NEBOC_TARGET_PATH_ERROR_SYMLINK
 jne .path_diag_limit
 mov qword [rel cli_manifest_diagnostic],13
 jmp .path_diag_ready
.path_diag_limit:
 cmp rdx,NEBOC_TARGET_PATH_ERROR_LIMIT
 jne .path_diag_io
 mov qword [rel cli_manifest_diagnostic],21
 jmp .path_diag_ready
.path_diag_io:
 cmp rdx,NEBOC_TARGET_PATH_ERROR_IO
 jne .path_diag_ready
 mov qword [rel cli_manifest_diagnostic],1
.path_diag_ready:
 cmp eax,NEBOC_STATUS_IO_ERROR
 jne .path_source
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .close_done
.path_source:
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
 jmp .close_done
.interface_bad:
 mov qword [rel cli_manifest_diagnostic],16
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
.close_done:
 mov rbx,rax
 mov rdi,[rel cli_manifest_root_fd]
 cmp rdi,-1
 je .restore_status
 mov eax,3
 syscall
 mov qword [rel cli_manifest_root_fd],-1
.restore_status:
 mov rax,rbx
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Existing output spelling is preserved. In manifest mode an existing output
; may not be a symlink or the same filesystem object as the manifest, selected
; source, or selected interface (hard links included).
cli_validate_manifest_output:
 push rbx
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 test rdi,rdi
 jz .ok
 mov eax,262                         ; newfstatat
 mov rsi,rdi
 mov rdi,-100
 lea rdx,[rel cli_manifest_output_stat]
 mov r10d,0x100                     ; AT_SYMLINK_NOFOLLOW
 syscall
 test rax,rax
 jz .exists
 cmp rax,-2                         ; ENOENT is a new output
 je .ok
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
 jmp .done
.exists:
 mov eax,[rel cli_manifest_output_stat+24]
 and eax,0xf000
 cmp eax,0xa000                     ; S_IFLNK
 je .collision
 mov rax,[rel cli_manifest_output_stat]
 mov rbx,[rel cli_manifest_output_stat+8]
 cmp rax,[rel cli_manifest_device]
 jne .source_object
 cmp rbx,[rel cli_manifest_inode]
 je .collision
.source_object:
 cmp rax,[rel cli_manifest_source_device]
 jne .interface_object
 cmp rbx,[rel cli_manifest_source_inode]
 je .collision
.interface_object:
 cmp qword [rel cli_manifest_interface_device],0
 je .ok
 cmp rax,[rel cli_manifest_interface_device]
 jne .ok
 cmp rbx,[rel cli_manifest_interface_inode]
 je .collision
.ok:
 xor eax,eax
 jmp .done
.collision:
 mov qword [rel cli_manifest_diagnostic],14
 mov eax,NEBOC_CLI_EXIT_SOURCE_ERROR
.done:
 pop rbx
 ret

cli_prepare_test_runner:
 lea rdi,[rel cli_test_runner_request]
 mov ecx,NEBOC_TEST_RUNNER_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_ast_builder]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_BUILDER],rax
 lea rax,[rel cli_tokens]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TOKENS],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TOKEN_COUNT],rax
 lea rax,[rel cli_source]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_SOURCE],rax
 mov rdx,[rel cli_manifest_selected_record]
 test rdx,rdx
 jz .invalid
 mov rax,[rdx+NEBOC_TARGET_RECORD_TEST_PTR]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TEST_PTR],rax
 mov rax,[rdx+NEBOC_TARGET_RECORD_TEST_LEN]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TEST_LEN],rax
 mov rax,[rdx+NEBOC_TARGET_RECORD_ID_PTR]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TARGET_PTR],rax
 mov rax,[rdx+NEBOC_TARGET_RECORD_ID_LEN]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_TARGET_LEN],rax
 lea rax,[rel cli_test_runner_label]
 mov [rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_LABEL],rax
 lea rdi,[rel cli_test_runner_request]
 call neboc_test_runner_plan
 ret
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

cli_emit_test_runner:
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_head]
 mov edx,cli_test_runner_head_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_label]
 mov rdx,[rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_LABEL_LEN]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_static_tail]
 mov edx,cli_test_runner_static_tail_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_label]
 mov rdx,[rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_LABEL_LEN]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_after_label]
 mov edx,cli_test_runner_after_label_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 mov rsi,[rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_FUNCTION_SYMBOL]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_test_runner_tail]
 mov edx,cli_test_runner_tail_len
 call neboc_assembly_writer_append_bytes
.done:
 ret

cli_emit_target_diagnostic:
 push rbx
 push r12
 push r13
 ; Materialize every bounded selected-contract code (001..021). Human,
 ; JSON/JSONL and SARIF therefore report one canonical code without a
 ; fallback that silently collapses uncommon failures to TARGET-002.
 lea r13,[rel cli_target_dynamic_code]
 lea rsi,[rel cli_target_code_prefix]
 mov rdi,r13
 mov ecx,cli_target_code_prefix_len
 rep movsb
 mov rax,[rel cli_manifest_diagnostic]
 test rax,rax
 jnz .diag_nonzero
 mov eax,1
.diag_nonzero:
 cmp rax,21
 jbe .diag_bounded
 mov eax,2
.diag_bounded:
 xor edx,edx
 mov ebx,10
 div rbx
 mov byte [rdi],'0'
 add al,'0'
 mov [rdi+1],al
 add dl,'0'
 mov [rdi+2],dl
 mov r12d,cli_target_code_prefix_len+3
 cmp qword [rel cli_message_format],3
 jb .human
 cmp qword [rel cli_message_format],5
 je .sarif
 lea rdi,[rel cli_target_json_prefix]
 mov esi,cli_target_json_prefix_len
 call cli_write_stderr_raw
 mov rdi,r13
 mov rsi,r12
 call cli_write_stderr_raw
 lea rdi,[rel cli_target_json_suffix]
 mov esi,cli_target_json_suffix_len
 call cli_write_stderr_raw
 jmp .done
.sarif:
 lea rdi,[rel cli_target_sarif_prefix]
 mov esi,cli_target_sarif_prefix_len
 call cli_write_stderr_raw
 mov rdi,r13
 mov rsi,r12
 call cli_write_stderr_raw
 lea rdi,[rel cli_target_sarif_suffix]
 mov esi,cli_target_sarif_suffix_len
 call cli_write_stderr_raw
 jmp .done
.human:
 mov rdi,r13
 mov rsi,r12
 call cli_write_stderr_raw
 lea rdi,[rel cli_target_human_suffix]
 mov esi,cli_target_human_suffix_len
 call cli_write_stderr_raw
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

; Build the shared-parser token view for NPT-LANG-16 without changing the
; lexer-owned token array used by collection semantics.  Only authenticated
; top-level collection declaration statements are omitted; their immutable
; values remain in cli_array_range.  All source spans and literal payloads are
; retained verbatim.
cli_prepare_array_range_general_tokens:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 xor r12d,r12d                 ; input token index
 xor r13d,r13d                 ; output token count
 xor r14d,r14d                 ; brace depth
 xor r15d,r15d                 ; skip current top-level declaration
 mov qword [rsp],0             ; current top-level statement output start
.loop:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .finish
 ; Scientific owners have already been independently authenticated from exact
 ; token slices.  Remove their complete half-open intervals only from this
 ; compiler-private FunctionTable view; original tokens and owner records stay
 ; byte-identical for source-to-runtime codegen.
 cmp qword [rel cli_scientific_owner_count],0
 je .scientific_owner_ready
 mov rax,r12
 call cli_scientific_range_end_at
 test rax,rax
 jz .scientific_owner_ready
 mov [rsp+24],rax
 ; A result-bearing scientific operation is lowered by its authenticated
 ; helper, but its public binding must remain visible to later scalar code.
 ; Retain a compiler-private `0.name;` anchor with the exact name span; codegen
 ; replaces the literal with the helper's RAX result before storing the slot.
 xor ecx,ecx
.scientific_result_scan:
 cmp rcx,[rel cli_scientific_owner_count]
 jae .scientific_skip_ready
 lea rdx,[rel cli_scientific_owner_starts]
 cmp r12,[rdx+rcx*8]
 jne .scientific_result_next
 lea rdx,[rel cli_scientific_owner_result_tokens]
 mov rax,[rdx+rcx*8]
 test rax,rax
 jz .scientific_skip_ready
 mov r12,rax
 call cli_copy_general_token
 mov rax,r13
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_general_tokens]
 add rdx,rax
 mov qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 mov qword [rdx+NEBOC_TOKEN_PAYLOAD_OFFSET],0
 dec r12
 call cli_copy_general_token
 inc r12
 call cli_copy_general_token
 mov r12,[rsp+24]
 dec r12
 call cli_copy_general_token
 mov [rsp],r13
 jmp .scientific_skip_ready
.scientific_result_next:
 inc rcx
 jmp .scientific_result_scan
.scientific_skip_ready:
 mov r12,[rsp+24]
 mov [rsp],r13
 xor r15d,r15d
 jmp .loop
.scientific_owner_ready:
 ; Nominal declarations were already authenticated independently into the
 ; exact owner registry.  Omit only a complete top-level enum declaration
 ; from the private shared-parser view; original tokens remain untouched for
 ; nominal semantics and every source span remains byte-identical.
 test r14,r14
 jnz .owned_preamble_ready
 cmp qword [rel cli_nominal_owner_count],0
 je .owned_preamble_ready
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_ENUM
 je .skip_enum_begin
 mov rax,r12
 call cli_token_is_identifier_nominal_declaration
 test eax,eax
 jz .owned_preamble_ready
.skip_linear_nominal:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 inc r12
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .skip_linear_nominal
 mov [rsp],r13
 jmp .loop
.skip_enum_begin:
 xor ecx,ecx
 xor r10d,r10d
.skip_enum:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov r11,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp r11,NEBOC_TOKEN_LBRACE
 jne .skip_enum_close
 inc rcx
 mov r10d,1
 jmp .skip_enum_next
.skip_enum_close:
 cmp r11,NEBOC_TOKEN_RBRACE
 jne .skip_enum_next
 test rcx,rcx
 jz .bad
 dec rcx
 test r10d,r10d
 jz .bad
 test rcx,rcx
 jz .skip_enum_done
.skip_enum_next:
 inc r12
 jmp .skip_enum
.skip_enum_done:
 inc r12
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .skip_enum_ready
 inc r12
.skip_enum_ready:
 mov [rsp],r13
 jmp .loop
.owned_preamble_ready:
 ; At any function/start body depth, an exact authenticated collection
 ; binding-name token proves this declaration is already represented by the
 ; semantic record.  The current statement start is updated after every brace
 ; and semicolon, so branch-local declarations can be omitted without erasing
 ; their surrounding control structure.
 cmp r14,1
 jb .kind
 mov rax,r12
 call cli_float_statement_is_dead_binding
 test eax,eax
 jnz .mark_nominal_skip
 mov rax,r12
 call cli_token_is_float_type
 test eax,eax
 jz .nominal_owned_statement
 mov rax,r12
 call cli_nominal_statement_is_binding
 test eax,eax
 jnz .mark_nominal_skip
.nominal_owned_statement:
 cmp qword [rel cli_nominal_owner_count],0
 je .binding_scan_begin
 mov rax,r12
 call cli_token_is_matched_nominal_owner_name
 test eax,eax
 jz .nominal_match_keyword
 mov rax,r12
 call cli_nominal_statement_is_binding
 test eax,eax
 jnz .mark_nominal_skip
.nominal_match_keyword:
 mov rax,r12
 call cli_token_is_match_keyword
 test eax,eax
 jz .binding_scan_begin
 call cli_has_matched_nominal_owner
 test eax,eax
 jnz .skip_nominal_match
.binding_scan_begin:
 xor ecx,ecx
.binding_scan:
 cmp rcx,[rel cli_array_range+NEBOC_AR_BINDING_COUNT_OFFSET]
 jae .buffer_binding_scan_begin
 mov rax,rcx
 imul rax,NEBOC_AR_BIND_SIZE
 lea rdx,[rel cli_ar_bindings]
 add rdx,rax
 cmp r12,[rdx+NEBOC_AR_BIND_NAME_OFFSET]
 je .mark_skip
 inc rcx
 jmp .binding_scan
.mark_nominal_skip:
 mov r15d,1
 jmp .kind
.skip_nominal_match:
 ; The nominal vertical has already authenticated this exact bounded match.
 ; Omit its balanced statement only from the private FunctionTable token view;
 ; the source, original tokens and nominal result record remain authoritative.
 xor ecx,ecx
 xor r10d,r10d
.skip_nominal_match_loop:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov r11,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp r11,NEBOC_TOKEN_LBRACE
 jne .skip_nominal_match_close
 inc rcx
 mov r10d,1
 jmp .skip_nominal_match_next
.skip_nominal_match_close:
 cmp r11,NEBOC_TOKEN_RBRACE
 jne .skip_nominal_match_next
 test rcx,rcx
 jz .bad
 dec rcx
 test r10d,r10d
 jz .bad
 test rcx,rcx
 jz .skip_nominal_match_done
.skip_nominal_match_next:
 inc r12
 jmp .skip_nominal_match_loop
.skip_nominal_match_done:
 inc r12
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .skip_nominal_match_ready
 inc r12
.skip_nominal_match_ready:
 mov [rsp],r13
 jmp .loop
.buffer_binding_scan_begin:
 xor ecx,ecx
.buffer_binding_scan:
 cmp rcx,[rel cli_buffer_owner_count]
 jae .kind
 mov rax,rcx
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 lea rdx,[rel cli_buffer]
 add rdx,rax
 mov rax,[rdx+NEBOC_BUFFER_TOKENS_OFFSET]
 lea rbx,[rel cli_tokens]
 sub rax,rbx
 jc .bad
 xor edx,edx
 mov ebx,NEBOC_TOKEN_SIZE
 div rbx
 test rdx,rdx
 jnz .bad
 mov rdx,rcx
 imul rdx,NEBOC_BUFFER_F11_REQUEST_SIZE
 lea rbx,[rel cli_buffer]
 add rbx,rdx
 add rax,[rbx+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 cmp r12,rax
 je .preserve_buffer_anchor
 inc rcx
 jmp .buffer_binding_scan
.preserve_buffer_anchor:
 mov [rsp+16],r12
 mov rax,r12
 jmp .find_shadow_integer
.mark_skip:
 mov r15d,1
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_ARRAY_RETURN
 jz .check_slice_return_anchor
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_ARRAY
 jne .check_slice_return_anchor
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_ARRAY_RETURN_SOURCE
 jnz .preserve_return_anchor
.check_slice_return_anchor:
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_SLICE_RETURN
 jz .kind
 cmp qword [rdx+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .kind
 test qword [rdx+NEBOC_AR_BIND_FLAGS_OFFSET],NEBOC_AR_SLICE_RETURN_SOURCE
 jz .kind
.preserve_return_anchor:
 ; The collection declaration remains semantically owned and omitted.  For an
 ; authenticated owned-Array return only, retain a scalar-shaped name anchor
 ; (`<existing-int>.<name>;`) in the private filtered view so the general AST
 ; can represent the bare return receiver.  Codegen recognizes the semantic
 ; collection record and emits no scalar binding.
 mov [rsp+16],r12             ; original binding-name token
 mov rax,r12
.find_shadow_integer:
 test rax,rax
 jz .bad
 dec rax
 mov rcx,rax
 imul rcx,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rcx
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .find_shadow_integer
 mov [rsp+8],rax
 mov r15d,2
.kind:
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov r11,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp r11,NEBOC_TOKEN_SEMICOLON
 jne .copy_or_skip
 cmp r14,1
 jb .copy_or_skip
 test r15d,r15d
 jz .copy_semicolon
 mov r13,[rsp]
 cmp r15d,2
 jne .drop_declaration
 mov [rsp+24],r12             ; declaration semicolon
 mov r12,[rsp+8]
 call cli_copy_general_token
 mov r12,[rsp+16]
 dec r12                     ; authenticated declaration dot
 call cli_copy_general_token
 inc r12                     ; authenticated declaration name
 call cli_copy_general_token
 mov r12,[rsp+24]
 call cli_copy_general_token
 mov [rsp],r13
.drop_declaration:
 xor r15d,r15d
 inc r12
 jmp .loop
.copy_semicolon:
 call cli_copy_general_token
 mov [rsp],r13
 inc r12
 jmp .loop
.copy_or_skip:
 test r15d,r15d
 jnz .advance_state
 call cli_copy_general_token
.advance_state:
 cmp r11,NEBOC_TOKEN_LBRACE
 jne .close
 inc r14
 mov [rsp],r13
 jmp .next
.close:
 cmp r11,NEBOC_TOKEN_RBRACE
 jne .next
 test r14,r14
 jz .bad
 dec r14
 mov [rsp],r13
.next:
 inc r12
 jmp .loop
.finish:
 test r14,r14
 jnz .bad
 test r15d,r15d
 jnz .bad
 test r13,r13
 jz .bad
 mov [rel cli_general_token_count],r13
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

; Copy original token r12 to transformed slot r13 and increment r13.
cli_copy_general_token:
 push rcx
 push rsi
 push rdi
 mov rsi,r12
 imul rsi,NEBOC_TOKEN_SIZE
 lea rax,[rel cli_tokens]
 add rsi,rax
 mov rdi,r13
 imul rdi,NEBOC_TOKEN_SIZE
 lea rax,[rel cli_general_tokens]
 add rdi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 inc r13
 pop rdi
 pop rsi
 pop rcx
 ret

; RAX=original token index -> EAX 1 only when it names a nominal owner whose
; independently authenticated operation set includes match.
cli_token_is_matched_nominal_owner_name:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 lea r12,[rel cli_tokens]
 add r12,rax
 mov r14,[rel cli_nominal_owner_count]
 lea r15,[rel cli_nominal_owners]
.loop:
 test r14,r14
 jz .no
 test qword [r15+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_MATCHED
 jz .next
 mov rax,[r15+NEBOC_NOM_KIND_OFFSET]
 mov r13,1
 cmp rax,NEBOC_NOM_KIND_ALIAS
 jne .index_ready
 mov r13,2
.index_ready:
 cmp r13,[r15+NEBOC_NOM_TOKEN_COUNT_OFFSET]
 jae .next
 imul rax,r13,NEBOC_TOKEN_SIZE
 add rax,[r15+NEBOC_NOM_TOKENS_OFFSET]
 mov rdi,r12
 mov rsi,rax
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .yes
.next:
 add r15,NEBOC_NOM_REQUEST_SIZE
 dec r14
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RAX=original token index -> EAX exact `match` identifier predicate.
cli_token_is_match_keyword:
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rax
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_MATCH
 je .yes
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,cli_name_match_len
 jne .no
 lea rsi,[rel cli_source]
 add rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel cli_name_match]
 mov ecx,cli_name_match_len
 cld
 repe cmpsb
 sete al
 movzx eax,al
 ret
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RAX=original token index -> exact public Float type token predicate.  The
; Float/numeric vertical still consumes the original tokens and owns every
; diagnostic; this predicate is used only to keep unused validated bindings
; out of FunctionTable's private scalar AST.
cli_token_is_float_type:
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rax
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,cli_name_float_type_len
 jne .no
 lea rsi,[rel cli_source]
 add rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel cli_name_float_type]
 mov ecx,cli_name_float_type_len
 cld
 repe cmpsb
 sete al
 movzx eax,al
 ret
.no:
 xor eax,eax
 ret

; RAX=statement-start token -> EAX 1 only for a dot-terminal binding statement,
; never for the `.return` operation used by nominal helpers.
cli_nominal_statement_is_binding:
 push rbx
 push r12
 mov r12,rax
.scan:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 je .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 je .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 je .terminal
 inc r12
 jmp .scan
.terminal:
 cmp r12,2
 jb .no
 mov rax,r12
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,r12
 sub rax,2
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; RAX=statement-start token -> EAX 1 only for a pure Float-classification
; statement whose terminal binding has no later token use.  The existing
; Float/numeric vertical authenticates the original statement; FunctionTable
; may therefore omit this dead result without suppressing a dependency.
cli_float_statement_is_dead_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rax
 xor r14d,r14d
.statement_scan:
 cmp r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne .not_float
 mov r14d,1
.not_float:
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .not_numeric_method
 mov rdi,rbx
 call cli_token_is_pure_numeric_method
 test eax,eax
 jz .not_numeric_method
 mov r14d,1
.not_numeric_method:
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 je .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 je .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 je .terminal
 inc r12
 jmp .statement_scan
.terminal:
 test r14d,r14d
 jz .no
 cmp r12,2
 jb .no
 mov rax,r12
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea r13,[rel cli_tokens]
 add r13,rax
 cmp qword [r13+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,r12
 sub rax,2
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 lea r15,[r12+1]
.use_scan:
 cmp r15,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .yes
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next_use
 mov rdi,r13
 mov rsi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .no
.next_use:
 inc r15
 jmp .use_scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=token pointer -> EAX 1 for the established pure numeric classifier or
; explicit conversion names whose unused results can be removed from the
; private FunctionTable AST after the numeric vertical validates them.
cli_token_is_pure_numeric_method:
 push rbx
 push r12
 mov rbx,rdi
 mov r12,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub r12,[rbx+NEBOC_TOKEN_START_OFFSET]
 lea rsi,[rel cli_source]
 add rsi,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp r12,cli_name_to_float_len
 jne .finite
 lea rdi,[rel cli_name_to_float]
 mov ecx,cli_name_to_float_len
 jmp .compare
.finite:
 cmp r12,cli_name_is_finite_len
 jne .nan
 lea rdi,[rel cli_name_is_finite]
 mov ecx,cli_name_is_finite_len
 jmp .compare
.nan:
 cmp r12,cli_name_is_nan_len
 jne .infinite
 lea rdi,[rel cli_name_is_nan]
 mov ecx,cli_name_is_nan_len
 jmp .compare
.infinite:
 cmp r12,cli_name_is_infinite_len
 jne .negative_zero
 lea rdi,[rel cli_name_is_infinite]
 mov ecx,cli_name_is_infinite_len
 jmp .compare
.negative_zero:
 cmp r12,cli_name_is_negative_zero_len
 jne .no
 lea rdi,[rel cli_name_is_negative_zero]
 mov ecx,cli_name_is_negative_zero_len
.compare:
 cld
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

cli_has_matched_nominal_owner:
 mov rcx,[rel cli_nominal_owner_count]
 lea rdx,[rel cli_nominal_owners]
.loop:
 test rcx,rcx
 jz .no
 test qword [rdx+NEBOC_NOM_FLAGS_OFFSET],NEBOC_NOM_FLAG_MATCHED
 jnz .yes
 add rdx,NEBOC_NOM_REQUEST_SIZE
 dec rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; Existing lexer/parser gate. An empty start body has no semantic/dependency work.
cli_frontend_validate:
 push rbx
 mov qword [rel cli_function_textual_validated],1
 mov qword [rel seguranca_numerica_conversoes_e_overflow_cli_frontend_diagnostic],0
 mov qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],0
 mov qword [rel cli_textual_frontend_error_token],0
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
 ; C12-F01: an exact Tensor identifier routes to the bounded scientific
 ; type/parser owner before the older parameter/Tuple heuristic.  Final
 ; ownership still requires the complete token-driven Tensor grammar.
 call cli_tokens_contain_tensor_atom
 test eax,eax
 jz ._early_tensor_not_owned
 call cli_recognize_vector
 cmp qword [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],0
 je ._early_tensor_not_owned
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._early_tensor_not_owned:
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .function_mutation_frontend_ready
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 je .function_mutation_frontend_ready
 ; An exact existing receiver-first declaration below brace depth zero is the
 ; NPT-LANG-37 routing witness.  Keep this bounded source on the shared AST
 ; path so legacy whole-source vertical recognizers cannot claim tokens from
 ; the private helper body (notably an immutable local followed by if/else).
 call cli_npt37_source_has_nested_prefix
 test eax,eax
 jnz .function_mutation_frontend_ready
 call cli_source_has_top_level_function_prefix
 test eax,eax
 jnz .multi_owner_function_frontend_ready
 ; Receiver-first F02 sources are identified by a leading signature plus an
 ; '=', ':' or Tuple marker, or by the complete markerless scalar-signature
 ; shape containing a public Char receiver/parameter. Claim them before legacy
 ; token heuristics can reinterpret defaults, Tuple returns or Char routing.
 call cli_recognize_parameters
 cmp qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 je ._early_not_owned
 ; The legacy parameter recognizer deliberately uses any `=` token as an
 ; ownership marker.  A material assignment inside an otherwise ordinary
 ; receiver-first body is not a parameter default; let the shared AST and
 ; function backend own that exact token-contained composition.
 mov [rel cli_frontend_status],rax
 call cli_tokens_contain_function_body_mutation
 test eax,eax
 jnz ._early_function_mutation
 mov rax,[rel cli_frontend_status]
 test eax,eax
 jz ._early_parameter_status
 ; B01's owned Array<Char,N> result is otherwise claimed and rejected by the
 ; markerless scalar-Char parameter front before the collection owner runs.
 ; Delegate only after the existing Array semantic recognizer proves the
 ; complete owned-return shape; ordinary Char functions retain their frozen
 ; early route and diagnostics.
 call cli_recognize_array_range
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 je ._early_parameter_status
 test eax,eax
 jnz ._early_parameter_status
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],(NEBOC_AR_FOR_FLAG_ARRAY_RETURN | NEBOC_AR_FOR_FLAG_SLICE_RETURN)
 jz ._early_parameter_status
 mov qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 mov qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jmp ._early_not_owned
._early_parameter_status:
 mov rax,[rel cli_frontend_status]
 test eax,eax
 jnz .bad
 xor eax,eax
 pop rbx
 ret
._early_function_mutation:
 mov qword [rel cli_parameters+NEBOC_PARAM_FOUND_OFFSET],0
 mov qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],0
 jmp ._early_not_owned
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
 ; The historical Buffer backend remains authoritative only when every start
 ; statement is rooted in one of the exact Buffer/Bytes/Slice names that the
 ; owner authenticated (plus the explicit scalar return terminal).  Any other
 ; statement is unconsumed by that whole-source backend and therefore selects
 ; the shared Program composition path; it may never be silently discarded.
 call cli_buffer_source_requires_composition
 cmp eax,-1
 je .bad
 test eax,eax
 jnz .multi_owner_function_frontend_ready
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jnz .array_range_general_frontend_ready
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jnz .array_range_general_frontend_ready
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
 je .function_mutation_frontend_ready
 call cli_tokens_contain_function_body_mutation
 test eax,eax
 jz .bad
 mov qword [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_FOUND_OFFSET],0
 mov qword [rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET],0
 mov qword [rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_ERROR_TOKEN_OFFSET],0
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_frontend_diagnostic],0
.array_range_general_frontend_ready:
 call cli_prepare_array_range_general_tokens
 test eax,eax
 jnz .bad
 jmp .function_mutation_frontend_ready
.multi_owner_function_frontend_ready:
 ; Publish every material collection owner record before building the
 ; declaration-filtered shared token view.  Each semantic vertical remains
 ; authoritative for its own values; Program/FunctionTable owns composition.
 call cli_recognize_scientific_owners
 test eax,eax
 jnz .bad
 call cli_recognize_nominal_owners
 test eax,eax
 jnz .bad
 call cli_recognize_buffer
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 je .multi_owner_buffer_ready
 test eax,eax
 jnz .bad
.multi_owner_buffer_ready:
 call cli_recognize_array_range
 cmp qword [rel cli_array_range+NEBOC_AR_FOUND_OFFSET],0
 jne .multi_owner_array_found
 cmp qword [rel cli_nominal_owner_count],0
 jne .multi_owner_force_general_tokens
 cmp qword [rel cli_buffer_owner_count],0
 jne .multi_owner_force_general_tokens
 cmp qword [rel cli_scientific_owner_count],0
 je .function_mutation_frontend_ready
.multi_owner_force_general_tokens:
 or qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jmp .array_range_general_frontend_ready
.multi_owner_array_found:
 test eax,eax
 jnz .bad
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jnz .array_range_general_frontend_ready
 cmp qword [rel cli_nominal_owner_count],0
 jne .multi_owner_force_general_tokens
 cmp qword [rel cli_buffer_owner_count],0
 jne .multi_owner_force_general_tokens
 cmp qword [rel cli_scientific_owner_count],0
 je .function_mutation_frontend_ready
 or qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jmp .array_range_general_frontend_ready
.function_mutation_frontend_ready:
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .parser_original_tokens
 lea rax,[rel cli_general_tokens]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKENS_OFFSET],rax
 mov rax,[rel cli_general_token_count]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKEN_COUNT_OFFSET],rax
 jmp .parser_tokens_ready
.parser_original_tokens:
 lea rax,[rel cli_tokens]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKENS_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 mov [rel cli_parser_request+NEBOC_PARSER_TOKEN_COUNT_OFFSET],rax
.parser_tokens_ready:
 mov qword [rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET],1
 lea rax,[rel cli_ast_builder]
 mov [rel cli_parser_request+NEBOC_PARSER_BUILDER_OFFSET],rax
 mov qword [rel cli_parser_request+NEBOC_PARSER_MAX_NESTING_OFFSET],NEBOC_PARSER_DEFAULT_MAX_NESTING
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .zero_start_policy
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 jne .parser_policy_ready
.zero_start_policy:
 mov qword [rel cli_parser_request+NEBOC_PARSER_FLAGS_OFFSET],NEBOC_PARSER_FLAG_ALLOW_ZERO_START|NEBOC_PARSER_FLAG_FORBID_START
.parser_policy_ready:
 lea rdi,[rel cli_parser_request]
 call neboc_parser_parse
 test eax,eax
 jnz .bad
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .start_body_ready
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 je .start_body_ready
 call cli_materialize_start_body
 test eax,eax
 jnz .bad
.start_body_ready:
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

; Exact token-level C12 routing witness.  It prevents the earlier generic
; parameter/Tuple heuristic from claiming a complete Tensor source while
; leaving Matrix, Vector and every unrelated source in their frozen order.
cli_tokens_contain_tensor_atom:
 push rbx
 push r12
 push r13
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
.scan:
 cmp r13,r12
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea rdi,[rbx+rax]
 cmp qword [rdi+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rsi,[rel scientific_cli_tensor_atom]
 mov edx,scientific_cli_tensor_atom_len
 call cli_token_equals
 test eax,eax
 jnz .yes
.next:
 inc r13
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
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
 push r14
 push r15
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
 mov r15,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp r15,NEBOC_TOKEN_TEXT
 je .literal_method
 cmp r15,NEBOC_TOKEN_CHAR
 jne .next
.literal_method:
 lea rax,[r13+4]
 cmp rax,r12
 jae .next
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 lea r14,[rax+2*NEBOC_TOKEN_SIZE]
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 cmp qword [rax+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .next
 ; Console is a separate public extension.  Only Text.console() with no
 ; arguments bypasses the foundation API probe; Char or argument-bearing
 ; forms retain the stable textual-API rejection.
 mov rdi,r14
 lea rsi,[rel cli_function_console_name]
 mov edx,cli_function_console_name_len
 call cli_token_equals
 test eax,eax
 jz .probe_foundation
 cmp r15,NEBOC_TOKEN_TEXT
 jne .unknown_method
 mov rax,r13
 add rax,4
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 je .next
 jmp .unknown_method
.probe_foundation:
 lea rdi,[rel cli_textual_api_probe]
 mov ecx,neboc_text_char_unicode_e_bytes_API_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 add rax,[r14+NEBOC_TOKEN_START_OFFSET]
 mov [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_SUBJECT_PTR_OFFSET],rax
 mov rax,[r14+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r14+NEBOC_TOKEN_START_OFFSET]
 mov [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_SUBJECT_LENGTH_OFFSET],rax
 mov qword [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_OPERATION_OFFSET],neboc_text_char_unicode_e_bytes_API_OPERATION_METHOD
 mov qword [rel cli_textual_api_probe+NEBOC_API_RECEIVER_FORM_OFFSET],NEBOC_RECEIVER_INSTANCE
 mov rax,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_TEXT
 cmp r15,NEBOC_TOKEN_TEXT
 je .probe_type_ready
 mov rax,NEBOC_TEXT_CHAR_BYTES_SEMANTIC_TYPE_ID_CHAR
.probe_type_ready:
 mov [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_RECEIVER_TYPE_OFFSET],rax
 mov rax,[r14+NEBOC_TOKEN_START_OFFSET]
 mov [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_ABSOLUTE_START_OFFSET],rax
 lea rdi,[rel cli_textual_api_probe]
 call neboc_text_char_bytes_api_contract
 cmp qword [rel cli_textual_api_probe+neboc_text_char_unicode_e_bytes_API_DIAGNOSTIC_OFFSET],NEBOC_API_DIAG_UNKNOWN
 jne .next
.unknown_method:
 mov qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],NEBOC_API_DIAG_UNKNOWN
 mov [rel cli_textual_frontend_error_token],r13
 mov eax,1
 jmp .done
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
 pop r15
 pop r14
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
; RAX=token index -> EAX=1 for the two identifier-led nominal declaration
; prefixes (`type alias` and `newtype`).  Enum remains a lexer keyword and is
; handled directly by the caller.  This is routing only; the existing nominal
; parser authenticates the complete declaration and operation contract.
cli_token_is_identifier_nominal_declaration:
 push rbx
 push r12
 push r13
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .nominal_declaration_no
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .nominal_declaration_no
 mov r12,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub r12,[rbx+NEBOC_TOKEN_START_OFFSET]
 lea r13,[rel cli_source]
 add r13,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp r12,cli_nominal_name_type_len
 jne .nominal_declaration_newtype
 mov rsi,r13
 lea rdi,[rel cli_nominal_name_type]
 mov ecx,cli_nominal_name_type_len
 cld
 repe cmpsb
 je .nominal_declaration_yes
.nominal_declaration_newtype:
 cmp r12,cli_nominal_name_newtype_len
 jne .nominal_declaration_no
 mov rsi,r13
 lea rdi,[rel cli_nominal_name_newtype]
 mov ecx,cli_nominal_name_newtype_len
 cld
 repe cmpsb
 jne .nominal_declaration_no
.nominal_declaration_yes:
 mov eax,1
 jmp .nominal_declaration_done
.nominal_declaration_no:
 xor eax,eax
.nominal_declaration_done:
 cld
 pop r13
 pop r12
 pop rbx
 ret

; RAX=original token index -> EAX=1 only for the bounded atoms that may begin
; one existing Matrix/Tensor vertical.  Array is admitted solely because the
; authenticated fromBuffer Tensor/Matrix forms begin with caller-owned Array
; storage.  Complete ownership is still decided by the existing recognizer.
cli_token_is_scientific_candidate:
 push rbx
 push r12
 push r13
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 mov r12,rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .identifier_candidate
 ; The selected typed-result function-return vertical begins with a scalar
 ; receiver call (`0.f()`).  Admit only that structural call prefix; ordinary
 ; integer expressions never enter the scientific probe path.
 lea rax,[r12+3]
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .no
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 je .yes
 jmp .no
.identifier_candidate:
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov r12,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub r12,[rbx+NEBOC_TOKEN_START_OFFSET]
 lea r13,[rel cli_source]
 add r13,[rbx+NEBOC_TOKEN_START_OFFSET]
 cmp r12,cli_scientific_name_matrix_len
 jne .tensor
 mov rsi,r13
 lea rdi,[rel cli_scientific_name_matrix]
 mov ecx,cli_scientific_name_matrix_len
 cld
 repe cmpsb
 je .yes
.tensor:
 cmp r12,cli_scientific_name_tensor_len
 jne .array
 mov rsi,r13
 lea rdi,[rel cli_scientific_name_tensor]
 mov ecx,cli_scientific_name_tensor_len
 cld
 repe cmpsb
 je .yes
.array:
 cmp r12,cli_scientific_name_array_len
 jne .no
 mov rsi,r13
 lea rdi,[rel cli_scientific_name_array]
 mov ecx,cli_scientific_name_array_len
 cld
 repe cmpsb
 jne .no
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 cld
 pop r13
 pop r12
 pop rbx
 ret

; Recover all top-level scientific owners inside an already-composed start().
; For every candidate the driver constructs:
;
;   exact-original start ( ) { + exact candidate tokens + } EOF
;
; and invokes the unchanged Matrix/Tensor vertical.  The first semicolon
; boundary producing FOUND=1, diagnostic=0 is the exact bounded owner.  Failed
; probes publish no state and cannot weaken the shared parser's diagnostics.
cli_recognize_scientific_owners:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov qword [rel cli_scientific_owner_count],0
 lea rdi,[rel cli_scientific_owners]
 mov ecx,NEBOC_CLI_SCIENTIFIC_OWNER_MAX*NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_scientific_owner_starts]
 mov ecx,NEBOC_CLI_SCIENTIFIC_OWNER_MAX*8
 xor eax,eax
 rep stosq
 mov r14,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 cmp r14,6
 jb .ok
 xor r12d,r12d
.find_start:
 lea rax,[r12+4]
 cmp rax,r14
 jae .ok
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+0*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_START
 jne .find_start_next
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .find_start_next
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .find_start_next
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LBRACE
 je .start_found
.find_start_next:
 inc r12
 jmp .find_start
.start_found:
 mov [rsp],r12
 mov [rel cli_scientific_program_start_index],r12
 lea r15,[r12+4]
 mov r13d,1
.find_start_close:
 cmp r15,r14
 jae .invalid
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .start_close_token
 inc r13
 jmp .start_close_next
.start_close_token:
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .start_close_next
 dec r13
 jz .start_close_found
.start_close_next:
 inc r15
 jmp .find_start_close
.start_close_found:
 mov [rsp+8],r15
 mov [rel cli_scientific_program_start_close],r15
 mov r12,[rsp]
 add r12,4
.body_scan:
 cmp r12,[rsp+8]
 jae .ok
 mov rax,r12
 call cli_token_is_scientific_candidate
 test eax,eax
 jz .body_next
 mov [rsp+16],r12
 mov r15,r12
.candidate_end_scan:
 cmp r15,[rsp+8]
 jae .body_next
 mov rax,r15
 sub rax,[rsp+16]
 cmp rax,NEBOC_CLI_SCIENTIFIC_SCRATCH_TOKEN_MAX-6
 jae .body_next
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .candidate_next
 mov [rsp+24],r15
 mov rax,[rel cli_scientific_owner_count]
 cmp rax,NEBOC_CLI_SCIENTIFIC_OWNER_MAX
 jae .limit
 imul rax,NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
 lea rbx,[rel cli_scientific_owners]
 add rbx,rax
 mov [rsp+32],rbx
 mov rdi,rbx
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ; Copy the four exact header tokens.
 mov rax,[rsp]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 lea rdi,[rel cli_scientific_scratch_tokens]
 mov ecx,4*NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 ; Copy the candidate's exact inclusive token interval.
 mov rax,[rsp+16]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+24]
 sub rcx,[rsp+16]
 inc rcx
 mov [rsp+40],rcx
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 ; Close the synthetic start with the original closing brace and EOF.
 mov rax,[rsp+8]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,r14
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 cmp qword [rsi+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_EOF
 jne .invalid
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rbx,[rsp+32]
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_scientific_scratch_tokens]
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rsp+40]
 add rax,6
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],rax
 mov qword [rel cli_scientific_probe_preamble_start],0
 mov qword [rel cli_scientific_probe_preamble_end],0
 mov rdi,rbx
 call neboc_vector_vertical_recognize
 mov rbx,[rsp+32]
 test eax,eax
 jnz .candidate_function_probe
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .candidate_function_probe
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .candidate_function_probe
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 je .candidate_publish
.candidate_function_probe:
 mov rdi,[rsp+32]
 mov rsi,[rsp+16]
 mov rdx,[rsp+24]
 call cli_try_scientific_function_candidate
 test eax,eax
 jz .candidate_next
 mov rbx,[rsp+32]
.candidate_publish:
 mov rax,[rel cli_scientific_owner_count]
 mov rcx,[rsp+16]
 lea rdx,[rel cli_scientific_owner_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+24]
 inc rcx
 lea rdx,[rel cli_scientific_owner_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rel cli_scientific_probe_preamble_start]
 lea rdx,[rel cli_scientific_owner_preamble_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rel cli_scientific_probe_preamble_end]
 lea rdx,[rel cli_scientific_owner_preamble_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+16]
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+24]
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_ends]
 mov [rdx+rax*8],rcx
 inc qword [rel cli_scientific_owner_count]
 mov r12,[rsp+24]
 inc r12
 jmp .body_scan
.candidate_next:
 inc r15
 jmp .candidate_end_scan
.body_next:
 inc r12
 jmp .body_scan
.ok:
 cmp qword [rel cli_scientific_owner_count],0
 jne .ok_ready
 call cli_recognize_scientific_bound_results
 test eax,eax
 jnz .done
.ok_ready:
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Compose one bounded Matrix scalar-result statement with its authenticated
; constructor (and optional owned-result mutation) and ask the unchanged C11
; vertical to validate the exact operation.  The public source interval stays
; separate: only the original operation/mutation is removed from the private
; FunctionTable view, while its result name is retained as a scalar anchor.
; RDI=constructor start, RSI=constructor end, RDX=mutation start or 0,
; RCX=mutation end, R8=operation start, R9=operation end (all half-open).
; EAX=1 published, 0 not owned.
cli_scientific_publish_matrix_bound_result:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov [rsp+32],r8
 mov [rsp+40],r9
 mov rax,[rel cli_scientific_owner_count]
 cmp rax,NEBOC_CLI_SCIENTIFIC_OWNER_MAX
 jae .no
 mov [rsp+56],rax
 imul rax,NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
 lea rbx,[rel cli_scientific_owners]
 add rbx,rax
 mov [rsp+48],rbx
 mov rdi,rbx
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_scientific_scratch_tokens]
 mov rax,[rel cli_scientific_program_start_index]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,4*NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 ; Exact constructor statement.
 mov rax,[rsp]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+8]
 sub rcx,[rsp]
 mov r12,rcx
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 ; Optional exact owned-result mutation statement (for set(...).name).
 cmp qword [rsp+16],0
 je .operation
 mov rax,[rsp+16]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+24]
 sub rcx,[rsp+16]
 add r12,rcx
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
.operation:
 ; Scalar scientific calls are terminal in the C11 contract.  Preserve every
 ; original token except the public postfix `.binding`, then retain the exact
 ; semicolon so the vertical authenticates the same call and arguments.
 mov rcx,[rsp+40]
 sub rcx,[rsp+32]
 cmp rcx,4
 jb .no
 mov rax,[rsp+40]
 sub rax,2
 mov [rsp+72],rax
 sub rcx,3
 add r12,rcx
 mov rax,[rsp+32]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rsp+40]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 inc r12
 ; Original start close and EOF.
 mov rax,[rel cli_scientific_program_start_close]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rbx,[rsp+48]
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_scientific_scratch_tokens]
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 add r12,6
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],r12
 mov rdi,rbx
 call neboc_vector_vertical_recognize
 mov rbx,[rsp+48]
 test eax,eax
 jnz .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 jne .no
 mov rax,[rbx+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET]
 cmp rax,NEBOC_VECTOR_MATRIX_KIND_GENERIC_VALUE_PLAN
 je .matrix_kind_ready
 ; The unchanged C11 vertical deliberately folds a direct filled+sum source
 ; into its specialized plan.  That plan is just as structurally certified as
 ; the generic scalar plan and the composition helper already lowers it.
 cmp rax,NEBOC_VECTOR_MATRIX_KIND_FILLED_SUM
 jne .no
.matrix_kind_ready:
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_FILLED_SUM
 je .matrix_result_ready
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],NEBOC_MATRIX_RESULT_SCALAR
 je .matrix_result_ready
 ; In the exact constructor + set(...).owned + owned.sum() composition, C11
 ; authenticates the mutation as an owned result and its existing helper
 ; deliberately reduces the updated descriptor before returning.  Publish
 ; that returned sum only when the caller supplied the adjacent mutation
 ; interval and the certified operation is SET.
 cmp qword [rsp+16],0
 je .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],NEBOC_MATRIX_RESULT_OWNED
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION0_OFFSET],NEBOC_MATRIX_OPERATION_SET
 jne .no
.matrix_result_ready:
 mov rax,[rsp+56]
 mov rcx,[rsp+32]
 cmp qword [rsp+16],0
 je .range_ready
 mov rcx,[rsp+16]
.range_ready:
 lea rdx,[rel cli_scientific_owner_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+40]
 lea rdx,[rel cli_scientific_owner_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp]
 lea rdx,[rel cli_scientific_owner_preamble_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+8]
 lea rdx,[rel cli_scientific_owner_preamble_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+72]
 lea rdx,[rel cli_scientific_owner_result_tokens]
 mov [rdx+rax*8],rcx
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdx,[rel cli_scientific_owner_result_source_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+32]
 cmp qword [rsp+16],0
 je .source_start_ready
 mov rcx,[rsp+16]
.source_start_ready:
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+40]
 dec rcx
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_ends]
 mov [rdx+rax*8],rcx
 inc qword [rel cli_scientific_owner_count]
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Tensor<Int>.filled with a bounded literal shape has compile-time element
; count and fill.  C12's direct-source contract already represents this tier
; as a checked scalar proof; authenticate that constructor unchanged and
; publish the exact sum as the helper result instead of discarding its binding.
; RDI=constructor start, RSI=constructor end, RDX=sum start, RCX=sum end.
cli_scientific_publish_tensor_bound_sum:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov rax,[rel cli_scientific_owner_count]
 cmp rax,NEBOC_CLI_SCIENTIFIC_OWNER_MAX
 jae .no
 mov [rsp+40],rax
 imul rax,NEBOC_VECTOR_VERTICAL_REQUEST_SIZE
 lea rbx,[rel cli_scientific_owners]
 add rbx,rax
 mov [rsp+32],rbx
 mov rdi,rbx
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_scientific_scratch_tokens]
 mov rax,[rel cli_scientific_program_start_index]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,4*NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 mov rax,[rsp]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+8]
 sub rcx,[rsp]
 mov r12,rcx
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 ; Clone one original token as the C12 scalar proof, but make its identity a
 ; literal zero until the authenticated constructor publishes its dimensions.
 mov rax,[rsp+16]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov qword [rdi-NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 mov qword [rdi-NEBOC_TOKEN_SIZE+NEBOC_TOKEN_PAYLOAD_OFFSET],0
 mov rax,[rsp+24]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 add r12,2
 mov rax,[rel cli_scientific_program_start_close]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rbx,[rsp+32]
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_scientific_scratch_tokens]
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 add r12,6
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],r12
 mov rdi,rbx
 call neboc_vector_vertical_recognize
 mov rbx,[rsp+32]
 test eax,eax
 jnz .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 jne .no
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_TENSOR_TYPE_OFFSET],NEBOC_TENSOR_TYPE_INT
 jne .no
 ; The nearest integer before the constructor's closing parenthesis is the
 ; bounded fill literal.  Preserve an immediately preceding unary minus.
 mov r14,[rsp+8]
 cmp r14,[rsp]
 jbe .no
.fill_scan:
 dec r14
 cmp r14,[rsp]
 jb .no
 mov rax,r14
 imul rax,NEBOC_TOKEN_SIZE
 lea r13,[rel cli_tokens]
 add r13,rax
 cmp qword [r13+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .fill_scan
 mov r15,[r13+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp r14,[rsp]
 jbe .fill_ready
 mov rax,r14
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea r13,[rel cli_tokens]
 add r13,rax
 cmp qword [r13+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .fill_ready
 neg r15
.fill_ready:
 imul r15,[rbx+NEBOC_VECTOR_VERTICAL_TENSOR_ELEMENT_COUNT_OFFSET]
 jo .no
 mov [rbx+NEBOC_VECTOR_VERTICAL_OUTPUT_VALUE_OFFSET],r15
 mov rax,[rsp+40]
 mov rcx,[rsp+16]
 lea rdx,[rel cli_scientific_owner_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+24]
 lea rdx,[rel cli_scientific_owner_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp]
 lea rdx,[rel cli_scientific_owner_preamble_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+8]
 lea rdx,[rel cli_scientific_owner_preamble_ends]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+24]
 sub rcx,2
 lea rdx,[rel cli_scientific_owner_result_tokens]
 mov [rdx+rax*8],rcx
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdx,[rel cli_scientific_owner_result_source_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+16]
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_starts]
 mov [rdx+rax*8],rcx
 mov rcx,[rsp+24]
 dec rcx
 imul rcx,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rcx
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 lea rdx,[rel cli_scientific_owner_source_ends]
 mov [rdx+rax*8],rcx
 inc qword [rel cli_scientific_owner_count]
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Recover bounded scientific result bindings that the historical verticals
; accept only as terminal scalar expressions.  Owner names are compared by
; exact source bytes; constructor, operation and arguments are revalidated by
; the existing C11/C12 recognizer before any interval is published.
cli_recognize_scientific_bound_results:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 xor eax,eax
 mov ecx,10
 lea rdi,[rsp]
 rep stosq
 mov r12,[rel cli_scientific_program_start_index]
 add r12,4
 mov r15,[rel cli_scientific_program_start_close]
.statement:
 cmp r12,r15
 jae .ok
 mov r13,r12
.find_end:
 cmp r13,r15
 jae .ok
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 je .classify
 inc r13
 jmp .find_end
.classify:
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 lea rsi,[rel cli_scientific_name_matrix]
 mov edx,cli_scientific_name_matrix_len
 call cli_token_equals
 test eax,eax
 jnz .matrix_constructor
 mov rdi,rbx
 lea rsi,[rel cli_scientific_name_tensor]
 mov edx,cli_scientific_name_tensor_len
 call cli_token_equals
 test eax,eax
 jnz .tensor_constructor
 ; A result-producing call must have receiver.method(...).binding;.
 lea rax,[r12+3]
 cmp rax,r13
 jae .next
 cmp qword [rbx+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 cmp r13,3
 jb .next
 mov rax,r13
 sub rax,3
 imul rax,NEBOC_TOKEN_SIZE
 lea r14,[rel cli_tokens]
 add r14,rax
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .next
 cmp qword [r14+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 cmp qword [r14+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 ; Primary Matrix owner.
 cmp qword [rsp+16],0
 je .derived_matrix
 mov rax,[rsp+16]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jz .derived_matrix
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_set]
 mov edx,cli_scientific_name_set_len
 call cli_token_equals
 test eax,eax
 jnz .matrix_mutation
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_sum]
 mov edx,cli_scientific_name_sum_len
 call cli_token_equals
 test eax,eax
 jnz .matrix_scalar
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_at]
 mov edx,cli_scientific_name_at_len
 call cli_token_equals
 test eax,eax
 jnz .matrix_scalar
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_is_square]
 mov edx,cli_scientific_name_is_square_len
 call cli_token_equals
 test eax,eax
 jnz .matrix_scalar
.derived_matrix:
 cmp qword [rsp+40],0
 je .tensor_owner
 mov rax,[rsp+40]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jz .tensor_owner
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_sum]
 mov edx,cli_scientific_name_sum_len
 call cli_token_equals
 test eax,eax
 jz .next
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 mov rdx,[rsp+24]
 mov rcx,[rsp+32]
 mov r8,r12
 lea r9,[r13+1]
 call cli_scientific_publish_matrix_bound_result
 jmp .next
.tensor_owner:
 cmp qword [rsp+64],0
 je .next
 mov rax,[rsp+64]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jz .next
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel cli_scientific_name_sum]
 mov edx,cli_scientific_name_sum_len
 call cli_token_equals
 test eax,eax
 jz .next
 mov rdi,[rsp+48]
 mov rsi,[rsp+56]
 mov rdx,r12
 lea rcx,[r13+1]
 call cli_scientific_publish_tensor_bound_sum
 jmp .next
.matrix_constructor:
 cmp r13,r12
 jbe .next
 mov [rsp],r12
 lea rax,[r13+1]
 mov [rsp+8],rax
 lea rax,[r13-1]
 mov [rsp+16],rax
 mov qword [rsp+24],0
 mov qword [rsp+32],0
 mov qword [rsp+40],0
 jmp .next
.tensor_constructor:
 cmp r13,r12
 jbe .next
 mov [rsp+48],r12
 lea rax,[r13+1]
 mov [rsp+56],rax
 lea rax,[r13-1]
 mov [rsp+64],rax
 jmp .next
.matrix_mutation:
 mov [rsp+24],r12
 lea rax,[r13+1]
 mov [rsp+32],rax
 lea rax,[r13-1]
 mov [rsp+40],rax
 jmp .next
.matrix_scalar:
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 xor edx,edx
 xor ecx,ecx
 mov r8,r12
 lea r9,[r13+1]
 call cli_scientific_publish_matrix_bound_result
.next:
 lea r12,[r13+1]
 jmp .statement
.ok:
 xor eax,eax
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Try the selected public Matrix/Tensor function-boundary vertical without
; teaching the general parser a second representation of those values.  The
; original top-level function definition and the exact start-body candidate
; are composed into one bounded token stream.  A preamble range is published
; only when the unchanged vertical accepts the whole function+start program.
; RDI=owner request, RSI=candidate start, RDX=candidate inclusive end.
; EAX=1 when a complete function-boundary owner was authenticated, else 0.
cli_try_scientific_function_candidate:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 mov qword [rel cli_scientific_probe_preamble_start],0
 mov qword [rel cli_scientific_probe_preamble_end],0
 xor r12d,r12d
.preamble_scan:
 cmp r12,[rel cli_scientific_program_start_index]
 jae .not_found
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .preamble_next
 mov [rsp+24],r12
 mov r13,r12
 xor r14d,r14d
 xor r15d,r15d
.preamble_end_scan:
 cmp r13,[rel cli_scientific_program_start_index]
 jae .preamble_next
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .preamble_close
 inc r14
 mov r15d,1
 jmp .preamble_end_next
.preamble_close:
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .preamble_end_next
 test r15d,r15d
 jz .preamble_end_next
 test r14,r14
 jz .preamble_next
 dec r14
 jnz .preamble_end_next
 mov [rsp+32],r13
 mov rax,r13
 sub rax,[rsp+24]
 inc rax
 mov [rsp+40],rax
 mov rcx,[rsp+16]
 sub rcx,[rsp+8]
 inc rcx
 mov [rsp+48],rcx
 add rax,rcx
 add rax,8
 cmp rax,NEBOC_CLI_SCIENTIFIC_SCRATCH_TOKEN_MAX
 ja .preamble_next
 ; Every speculative trial starts from a zeroed owner request.
 mov rdi,[rsp]
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ; Exact top-level function preamble.
 mov rax,[rsp+24]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 lea rdi,[rel cli_scientific_scratch_tokens]
 mov rcx,[rsp+40]
 imul rcx,NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 ; Original start() header.
 mov rax,[rel cli_scientific_program_start_index]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,4*NEBOC_TOKEN_QWORDS
 rep movsq
 ; Exact candidate interval.
 mov rax,[rsp+8]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+48]
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 ; Original start closing brace and EOF.
 mov rax,[rel cli_scientific_program_start_close]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 cmp qword [rsi+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_EOF
 jne .preamble_next
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rbx,[rsp]
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_scientific_scratch_tokens]
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rsp+40]
 add rax,[rsp+48]
 add rax,6
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],rax
 mov rdi,rbx
 call neboc_vector_vertical_recognize
 mov rbx,[rsp]
 test eax,eax
 jnz .try_return_adapted
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .try_return_adapted
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .try_return_adapted
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 je .function_owner_success
.try_return_adapted:
 ; The monolithic atlas must continue after a scalar-returning Matrix helper,
 ; whereas the historical isolated vertical requires the selected call to be
 ; the terminal `.return` expression.  Reuse the exact program return tokens
 ; to authenticate that same value flow without changing source bytes: omit
 ; only the candidate's terminating semicolon and append the original
 ; `.return;` tail before the synthetic closing brace.
 cmp qword [rsp+48],1
 jbe .preamble_next
 mov rax,[rel cli_scientific_program_start_close]
 cmp rax,3
 jb .preamble_next
 mov rdi,[rsp]
 mov ecx,NEBOC_VECTOR_VERTICAL_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp+24]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 lea rdi,[rel cli_scientific_scratch_tokens]
 mov rcx,[rsp+40]
 imul rcx,NEBOC_TOKEN_QWORDS
 cld
 rep movsq
 mov rax,[rel cli_scientific_program_start_index]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,4*NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rsp+8]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov rcx,[rsp+48]
 dec rcx
 imul rcx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_scientific_program_start_close]
 sub rax,3
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,3*NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_scientific_program_start_close]
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 lea rsi,[rel cli_tokens]
 add rsi,rax
 mov ecx,NEBOC_TOKEN_QWORDS
 rep movsq
 mov rbx,[rsp]
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_VECTOR_VERTICAL_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_scientific_scratch_tokens]
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKENS_OFFSET],rax
 mov rax,[rsp+40]
 add rax,[rsp+48]
 add rax,8
 mov [rbx+NEBOC_VECTOR_VERTICAL_TOKEN_COUNT_OFFSET],rax
 mov rdi,rbx
 call neboc_vector_vertical_recognize
 mov rbx,[rsp]
 test eax,eax
 jnz .preamble_next
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],1
 jne .preamble_next
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET],0
 jne .preamble_next
 cmp qword [rbx+NEBOC_VECTOR_VERTICAL_FLAGS_OFFSET],NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 jne .preamble_next
.function_owner_success:
 mov rax,[rsp+24]
 mov [rel cli_scientific_probe_preamble_start],rax
 mov rax,[rsp+32]
 inc rax
 mov [rel cli_scientific_probe_preamble_end],rax
 mov eax,1
 jmp .function_probe_done
.preamble_end_next:
 inc r13
 jmp .preamble_end_scan
.preamble_next:
 inc r12
 jmp .preamble_scan
.not_found:
 xor eax,eax
.function_probe_done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RAX=original token index -> matching scientific half-open range end or zero.
cli_scientific_range_end_at:
 mov rcx,[rel cli_scientific_owner_count]
 lea r8,[rel cli_scientific_owner_starts]
 lea r9,[rel cli_scientific_owner_ends]
 xor edx,edx
.range_loop:
 cmp rdx,rcx
 jae .preamble_range_start
 cmp rax,[r8+rdx*8]
 je .range_found
 inc rdx
 jmp .range_loop
.range_found:
 mov rax,[r9+rdx*8]
 ret
.preamble_range_start:
 lea r8,[rel cli_scientific_owner_preamble_starts]
 lea r9,[rel cli_scientific_owner_preamble_ends]
 xor edx,edx
.preamble_range_loop:
 cmp rdx,rcx
 jae .range_none
 cmp qword [r9+rdx*8],0
 je .preamble_range_next
 cmp rax,[r8+rdx*8]
 je .range_found
.preamble_range_next:
 inc rdx
 jmp .preamble_range_loop
.range_none:
 xor eax,eax
 ret

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
 cmp rax,11
 je .matrix_dtype
 cmp rax,12
 je .matrix_limit
 cmp rax,13
 je .matrix_syntax
 cmp rax,16
 je .matrix_deferred
 cmp rax,17
 je .tensor_dtype
 cmp rax,18
 je .tensor_syntax
 cmp rax,19
 je .tensor_extent
 cmp rax,20
 je .tensor_overflow
 cmp rax,21
 je .tensor_limit
 cmp rax,22
 je .tensor_copy
 cmp rax,23
 je .tensor_deferred
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
 jmp .write
.matrix_dtype: lea rdi,[rel scientific_cli_error_matrix_dtype]
 mov esi,scientific_cli_error_matrix_dtype_end-scientific_cli_error_matrix_dtype
 jmp .write
.matrix_limit: lea rdi,[rel scientific_cli_error_matrix_limit]
 mov esi,scientific_cli_error_matrix_limit_end-scientific_cli_error_matrix_limit
 jmp .write
.matrix_syntax: lea rdi,[rel scientific_cli_error_matrix_syntax]
 mov esi,scientific_cli_error_matrix_syntax_end-scientific_cli_error_matrix_syntax
 jmp .write
.matrix_deferred: lea rdi,[rel scientific_cli_error_matrix_deferred]
 mov esi,scientific_cli_error_matrix_deferred_end-scientific_cli_error_matrix_deferred
 jmp .write
.tensor_dtype: lea rdi,[rel scientific_cli_error_tensor_dtype]
 mov esi,scientific_cli_error_tensor_dtype_end-scientific_cli_error_tensor_dtype
 jmp .write
.tensor_syntax: lea rdi,[rel scientific_cli_error_tensor_syntax]
 mov esi,scientific_cli_error_tensor_syntax_end-scientific_cli_error_tensor_syntax
 jmp .write
.tensor_extent: lea rdi,[rel scientific_cli_error_tensor_extent]
 mov esi,scientific_cli_error_tensor_extent_end-scientific_cli_error_tensor_extent
 jmp .write
.tensor_overflow: lea rdi,[rel scientific_cli_error_tensor_overflow]
 mov esi,scientific_cli_error_tensor_overflow_end-scientific_cli_error_tensor_overflow
 jmp .write
.tensor_limit: lea rdi,[rel scientific_cli_error_tensor_limit]
 mov esi,scientific_cli_error_tensor_limit_end-scientific_cli_error_tensor_limit
 jmp .write
.tensor_copy: lea rdi,[rel scientific_cli_error_tensor_copy]
 mov esi,scientific_cli_error_tensor_copy_end-scientific_cli_error_tensor_copy
 jmp .write
.tensor_deferred: lea rdi,[rel scientific_cli_error_tensor_deferred]
 mov esi,scientific_cli_error_tensor_deferred_end-scientific_cli_error_tensor_deferred
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
 cmp rax,NEBOC_AR_DIAG_RECORD_CAPACITY
 je .record_capacity
 cmp rax,NEBOC_AR_DIAG_VALUE_CAPACITY
 je .value_capacity
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
.record_capacity:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_033]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_033_end-option_result_null_externo_e_erros_tipados_cli_error_033
 jmp .write
.value_capacity:
 lea rdi,[rel option_result_null_externo_e_erros_tipados_cli_error_034]
 mov esi,option_result_null_externo_e_erros_tipados_cli_error_034_end-option_result_null_externo_e_erros_tipados_cli_error_034
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
; RAX token ordinal -> EAX boolean.  Only a material public constructor
; (`Buffer.zeroed(` or `Buffer.withCapacity(`) creates an owner.  Type names,
; comments, strings and function-boundary spellings cannot allocate slots.
cli_buffer_token_is_constructor:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rax
 mov r13,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 lea rax,[r12+3]
 cmp rax,r13
 jae .no
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea r14,[rel cli_tokens]
 add r14,rax
 cmp qword [r14+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdi,r14
 lea rsi,[rel cli_buffer_type_name]
 mov edx,cli_buffer_type_name_len
 call cli_token_equals
 test eax,eax
 jz .no
 cmp qword [r14+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 lea rbx,[r14+2*NEBOC_TOKEN_SIZE]
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdi,rbx
 lea rsi,[rel cli_buffer_zeroed_name]
 mov edx,cli_buffer_zeroed_name_len
 call cli_token_equals
 test eax,eax
 jnz .method
 mov rdi,rbx
 lea rsi,[rel cli_buffer_with_capacity_name]
 mov edx,cli_buffer_with_capacity_name_len
 call cli_token_equals
 test eax,eax
 jz .no
.method:
 cmp qword [r14+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI/RSI token pointers -> EAX boolean.  The source offsets are intentionally
; not identity: two declarations at different spans collide when their UTF-8
; owner bytes are equal.
cli_buffer_tokens_same_lexeme:
 push rbx
 push rcx
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_TOKEN_END_OFFSET]
 sub r14,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rax,[r13+NEBOC_TOKEN_END_OFFSET]
 sub rax,[r13+NEBOC_TOKEN_START_OFFSET]
 cmp r14,rax
 jne .no
 lea rbx,[rel cli_source]
 mov rdi,rbx
 add rdi,[r12+NEBOC_TOKEN_START_OFFSET]
 mov rsi,rbx
 add rsi,[r13+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.compare:
 cmp rcx,r14
 jae .yes
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jne .no
 inc rcx
 jmp .compare
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rcx
 pop rbx
 ret

; Return 1 when start() contains a statement outside the exact Buffer owner
; graph, 0 when the bounded historical Buffer backend consumed the complete
; body, and -1 on corrupt token/owner state.  This is the coverage invariant
; for the only remaining whole-source Buffer route: a recognized constructor
; alone is never sufficient authority to replace unrelated statements.
cli_buffer_source_requires_composition:
 push rbx
 push r12
 push r13
 push r14
 push r15
 ; The active function-scoped call adapter consumes eight more bytes.  Five
 ; saved registers plus this padded local frame leave its pre-call state at 0.
 sub rsp,24
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d                 ; original token index
 xor r14d,r14d                 ; active start-body brace depth
 xor r15d,r15d                 ; statement-start flag
 mov qword [rsp],0             ; saw canonical start token
.scan:
 cmp r13,r12
 jae .finish
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 test r14,r14
 jnz .in_body
 cmp qword [rsp],0
 jne .await_start_brace
 cmp rax,NEBOC_TOKEN_KW_START
 jne .next
 mov qword [rsp],1
 jmp .next
.await_start_brace:
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .next
 mov r14d,1
 mov r15d,1
 jmp .next
.in_body:
 cmp rax,NEBOC_TOKEN_LBRACE
 je .open
 cmp rax,NEBOC_TOKEN_RBRACE
 je .close
 cmp rax,NEBOC_TOKEN_SEMICOLON
 je .semicolon
 cmp r14,1
 jne .next
 test r15d,r15d
 jz .next
 ; A constructor is an authenticated owner-root statement.
 mov rax,r13
 call cli_buffer_token_is_constructor
 test eax,eax
 jnz .owned_statement
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .owned_name_scan
 ; Preserve the historical explicit Int start status, but require the complete
 ; `.return` prefix so an arbitrary scalar statement cannot be swallowed.
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .compose
 lea rax,[r13+2]
 cmp rax,r12
 jae .corrupt
 cmp qword [rbx+1*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .compose
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_RETURN
 jne .compose
 jmp .owned_statement
.owned_name_scan:
 xor ecx,ecx
.owner_loop:
 cmp rcx,[rel cli_buffer_owner_count]
 jae .compose
 mov rax,rcx
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 lea rdx,[rel cli_buffer]
 add rdx,rax
 mov [rsp+8],rdx
 mov rax,[rdx+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 cmp rax,[rdx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .corrupt
 imul rax,NEBOC_TOKEN_SIZE
 mov rsi,[rdx+NEBOC_BUFFER_TOKENS_OFFSET]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .owned_statement
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_BUFFER_FREEZE_COUNT_OFFSET],0
 je .slice_name
 mov rax,[rdx+NEBOC_BUFFER_FROZEN_NAME_TOKEN_OFFSET]
 cmp rax,[rdx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .corrupt
 imul rax,NEBOC_TOKEN_SIZE
 mov rsi,[rdx+NEBOC_BUFFER_TOKENS_OFFSET]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .owned_statement
.slice_name:
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_SLICE_VIEW_COUNT_OFFSET],0
 je .owner_next
 mov rax,[rdx+NEBOC_SLICE_NAME_TOKEN_OFFSET]
 cmp rax,[rdx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET]
 jae .corrupt
 imul rax,NEBOC_TOKEN_SIZE
 mov rsi,[rdx+NEBOC_BUFFER_TOKENS_OFFSET]
 add rsi,rax
 mov rdi,rbx
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .owned_statement
.owner_next:
 inc rcx
 jmp .owner_loop
.owned_statement:
 xor r15d,r15d
 jmp .next
.open:
 inc r14
 jmp .next
.close:
 test r14,r14
 jz .corrupt
 dec r14
 jnz .next
 jmp .finish
.semicolon:
 cmp r14,1
 jne .next
 mov r15d,1
.next:
 inc r13
 jmp .scan
.finish:
 cmp qword [rsp],0
 je .corrupt
 test r14,r14
 jnz .corrupt
 xor eax,eax
 jmp .done
.compose:
 mov eax,1
 jmp .done
.corrupt:
 mov rax,-1
.done:
 add rsp,24
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Parse, analyze and lower every bounded Buffer owner in lexical order.  Each
; parser sees only its own token interval, which makes name-token equality and
; view generations owner-local without changing the parser's public contract.
cli_recognize_buffer:
 push rbp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 mov qword [rel cli_buffer_owner_count],0
 lea rdi,[rel cli_buffer]
 mov ecx,NEBOC_BUFFER_F11_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_buffer_plan]
 mov ecx,NEBOC_BUFFER_PLAN_F11_QWORDS
 xor eax,eax
 rep stosq
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
.scan:
 cmp r13,r12
 jae .success
 mov rax,r13
 call cli_buffer_token_is_constructor
 test eax,eax
 jnz .owner_start
 inc r13
 jmp .scan
.owner_start:
 mov r15,r13
 inc r13
.find_owner_end:
 cmp r13,r12
 jae .owner_end
 mov rax,r13
 call cli_buffer_token_is_constructor
 test eax,eax
 jnz .owner_end
 inc r13
 jmp .find_owner_end
.owner_end:
 cmp r14,NEBOC_MULTI_OWNER_MAX
 jae .capacity
 mov rax,r14
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 lea rbx,[rel cli_buffer]
 add rbx,rax
 mov rdi,rbx
 mov ecx,NEBOC_BUFFER_F11_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,r14
 imul rax,NEBOC_BUFFER_PLAN_F11_SIZE
 lea rbp,[rel cli_buffer_plan]
 add rbp,rax
 mov rdi,rbp
 mov ecx,NEBOC_BUFFER_PLAN_F11_QWORDS
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_BUFFER_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_BUFFER_SOURCE_LENGTH_OFFSET],rax
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rax
 mov [rbx+NEBOC_BUFFER_TOKENS_OFFSET],rdx
 mov rax,r12
 sub rax,r15
 mov [rbx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET],rax
 mov rdi,rbx
 call neboc_buffer_parse
 test eax,eax
 jnz .owner_error
 cmp qword [rbx+NEBOC_BUFFER_FOUND_OFFSET],0
 je .owner_internal
 xor ecx,ecx
.owner_name_unique:
 cmp rcx,r14
 jae .owner_name_ready
 mov rax,[rbx+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 imul rax,NEBOC_TOKEN_SIZE
 mov rdi,[rbx+NEBOC_BUFFER_TOKENS_OFFSET]
 add rdi,rax
 mov rax,rcx
 imul rax,NEBOC_BUFFER_F11_REQUEST_SIZE
 lea rdx,[rel cli_buffer]
 add rdx,rax
 mov rax,[rdx+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 imul rax,NEBOC_TOKEN_SIZE
 mov rsi,[rdx+NEBOC_BUFFER_TOKENS_OFFSET]
 add rsi,rax
 call cli_buffer_tokens_same_lexeme
 test eax,eax
 jnz .owner_collision
 inc rcx
 jmp .owner_name_unique
.owner_collision:
 mov qword [rbx+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_ALIAS
 mov rax,[rbx+NEBOC_BUFFER_NAME_TOKEN_OFFSET]
 mov [rbx+NEBOC_BUFFER_ERROR_TOKEN_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .owner_error
.owner_name_ready:
 mov rdi,rbx
 call neboc_buffer_analyze
 test eax,eax
 jnz .owner_error
 mov rdi,rbx
 mov rsi,rbp
 call neboc_buffer_lower
 test eax,eax
 jnz .owner_error
 ; Parsing remains isolated up to the next constructor, but composition-time
 ; result lookup must also see later operations on this exact owner (for
 ; example release/clear after other owners are declared).  The request token
 ; base is already the immutable original constructor position; expose the
 ; bounded remainder only after parse/analyze/lower have certified the owner.
 mov rax,r12
 sub rax,r15
 mov [rbx+NEBOC_BUFFER_TOKEN_COUNT_OFFSET],rax
 inc r14
 mov [rel cli_buffer_owner_count],r14
 jmp .scan
.owner_internal:
 mov qword [rbx+NEBOC_BUFFER_FOUND_OFFSET],1
 mov qword [rbx+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.owner_error:
 mov r12,rax
 test r14,r14
 jz .error_return
 mov rax,[rbx+NEBOC_BUFFER_DIAGNOSTIC_OFFSET]
 mov [rel cli_buffer+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],rax
 mov rax,[rbx+NEBOC_BUFFER_ERROR_TOKEN_OFFSET]
 add rax,r15
 mov [rel cli_buffer+NEBOC_BUFFER_ERROR_TOKEN_OFFSET],rax
.error_return:
 mov rax,r12
 jmp .done
.capacity:
 mov qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],1
 mov qword [rel cli_buffer+NEBOC_BUFFER_DIAGNOSTIC_OFFSET],NEBOC_BUFFER_DIAG_INTERNAL
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.success:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
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

; Authenticate every top-level enum owner independently with the existing
; nominal parser/semantic/lowering vertical.  Each request receives a token
; slice beginning at its own declaration, while token byte spans remain tied
; to the one original source.  The compiler-private registry is later handed
; to FunctionTable codegen; no nominal surface is reimplemented here.
%undef call
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
cli_recognize_nominal_owners:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov qword [rel cli_nominal_owner_count],0
 lea rdi,[rel cli_nominal_owners]
 mov ecx,NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_nominal_owner_variants]
 mov ecx,NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_nominal_owner_plans]
 mov ecx,NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS*NEBOC_NOM_PLAN_QWORDS
 xor eax,eax
 rep stosq
 xor r12d,r12d
 xor r13d,r13d
 mov r14,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
.scan:
 cmp r12,r14
 jae .ok
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 test r13,r13
 jnz .brace_state
 cmp rax,NEBOC_TOKEN_KW_ENUM
 je .nominal_owner_candidate
 mov rax,r12
 call cli_token_is_identifier_nominal_declaration
 test eax,eax
 jz .brace_state
.nominal_owner_candidate:
 mov r15,[rel cli_nominal_owner_count]
 cmp r15,NEBOC_FUNCTION_CODEGEN_MAX_NOMINAL_OWNERS
 jae .limit
 mov rax,r15
 imul rax,NEBOC_NOM_REQUEST_SIZE
 lea rbx,[rel cli_nominal_owners]
 add rbx,rax
 mov [rsp],rbx
 lea rax,[rel cli_source]
 mov [rbx+NEBOC_NOM_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_NOM_SOURCE_LENGTH_OFFSET],rax
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rcx,[rel cli_tokens]
 add rax,rcx
 mov [rbx+NEBOC_NOM_TOKENS_OFFSET],rax
 mov rax,r14
 sub rax,r12
 mov [rbx+NEBOC_NOM_TOKEN_COUNT_OFFSET],rax
 mov rax,r15
 imul rax,NEBOC_NOM_MAX_VARIANTS*NEBOC_NOM_VARIANT_SIZE
 lea rcx,[rel cli_nominal_owner_variants]
 add rax,rcx
 mov [rbx+NEBOC_NOM_VARIANTS_OFFSET],rax
 mov qword [rbx+NEBOC_NOM_VARIANT_CAPACITY_OFFSET],NEBOC_NOM_MAX_VARIANTS
 mov rdi,rbx
 call neboc_nominal_parse
 test eax,eax
 jnz .done
 mov rbx,[rsp]
 cmp qword [rbx+NEBOC_NOM_FOUND_OFFSET],1
 jne .invalid
 mov rdi,rbx
 call neboc_nominal_analyze
 test eax,eax
 jnz .done
 mov rbx,[rsp]
 mov rax,r15
 imul rax,NEBOC_NOM_PLAN_SIZE
 lea rsi,[rel cli_nominal_owner_plans]
 add rsi,rax
 mov rdi,rbx
 call neboc_nominal_lower
 test eax,eax
 jnz .done
 inc qword [rel cli_nominal_owner_count]
 mov rax,[rbx+NEBOC_NOM_KIND_OFFSET]
 cmp rax,NEBOC_NOM_KIND_ALIAS
 je .brace_state
 cmp rax,NEBOC_NOM_KIND_NEWTYPE
 je .brace_state
 cmp rax,NEBOC_NOM_KIND_ENUM
 jne .invalid
.brace_state:
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .brace_close
 inc r13
 jmp .next
.brace_close:
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .next
 test r13,r13
 jz .invalid
 dec r13
.next:
 inc r12
 jmp .scan
.ok:
 test r13,r13
 jnz .invalid
 xor eax,eax
 jmp .done
.limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
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
 lea rax,[rel cli_branch_a_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_A_COUNTS_OFFSET],rax
 lea rax,[rel cli_branch_b_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_B_COUNTS_OFFSET],rax
 lea rax,[rel cli_loop_snapshots]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_LOOP_SNAPSHOTS_OFFSET],rax
 lea rax,[rel cli_loop_bodies]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_LOOP_BODIES_OFFSET],rax
 lea rax,[rel cli_loop_body_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET],rax
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .start_tokens_original
 lea rax,[rel cli_general_tokens]
 mov rdx,[rel cli_general_token_count]
 jmp .start_tokens_ready
.start_tokens_original:
 lea rax,[rel cli_tokens]
 mov rdx,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
.start_tokens_ready:
 mov [rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET],rdx
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
 jz .materialize_nested_bodies
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .function_tokens_original
 lea rax,[rel cli_general_tokens]
 mov rdx,[rel cli_general_token_count]
 jmp .function_tokens_ready
.function_tokens_original:
 lea rax,[rel cli_tokens]
 mov rdx,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
.function_tokens_ready:
 mov [rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET],rdx
 mov rax,[rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_ID_OFFSET],rax
 lea rax,[rel cli_source]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_DATA_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_BUILDER_OFFSET],rbx
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r15
 mov qword [rel cli_stmt_request+NEBOC_STMT_MAX_NESTING_OFFSET],NEBOC_STMT_DEFAULT_MAX_NESTING
 lea rax,[rel cli_expr_request]
 mov [rel cli_stmt_request+NEBOC_STMT_EXPR_REQUEST_OFFSET],rax
 mov qword [rel cli_stmt_request+NEBOC_STMT_FLAGS_OFFSET],NEBOC_STMT_FLAG_NPT37_OUTER_FUNCTION_BODY
 mov rdi,r15
 call cli_npt37_block_has_direct_nested
 test eax,eax
 jz .ordinary_function_block
 mov rdi,[rsp+16]
 mov rsi,r15
 call cli_npt37_parse_outer_block
 test eax,eax
 jnz .bad
 jmp .decl_next
.ordinary_function_block:
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
.materialize_nested_bodies:
 call cli_npt37_materialize_nested_bodies
 test eax,eax
 jnz .bad
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

; token_index -> EAX 1 only for the existing receiver-first declaration
; prefix `(Type.receiver)name(` in the active statement token buffer.
cli_npt37_is_function_prefix:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,[rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET]
 test rbx,rbx
 jz .no
 lea rax,[r12+6]
 cmp rax,[rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r12
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .no
 lea rax,[r12+1]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 lea rax,[r12+2]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .no
 lea rax,[r12+3]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 lea rax,[r12+4]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .no
 lea rax,[r12+5]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 lea rax,[r12+6]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r12
 pop rbx
 ret

; EAX 1 when the original lexer stream contains the existing receiver-first
; function prefix at any nonzero brace depth.  This is routing only; the exact
; direct-outer/depth/context policy remains owned by materialization.
cli_npt37_source_has_nested_prefix:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
.scan:
 cmp r13,r12
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea r15,[rbx+rax]
 mov rax,[r15+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 je .open
 cmp rax,NEBOC_TOKEN_RBRACE
 je .close
 test r14,r14
 jz .next
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rax,[r13+6]
 cmp rax,r12
 jae .next
 lea rax,[r13+1]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+2]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 lea rax,[r13+3]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+4]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .next
 lea rax,[r13+5]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+6]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 je .yes
 jmp .next
.open:
 inc r14
 jmp .next
.close:
 test r14,r14
 jz .next
 dec r14
.next:
 inc r13
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Return 1 after the second receiver-first declaration at program depth zero.
; Two or more owners require the shared Program/FunctionTable path before a
; legacy whole-source recognizer can claim an incidental body token.  An exact
; one-owner parameters/defaults source retains its authenticated bounded F02
; vertical; ordinary one-owner sources that F02 does not own still fall through
; to the shared parser.
cli_source_has_top_level_function_prefix:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,8
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
 xor r15d,r15d
.scan:
 cmp r13,r12
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,rbx
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 je .open
 cmp rax,NEBOC_TOKEN_RBRACE
 je .close
 test r14,r14
 jnz .next
 cmp rax,NEBOC_TOKEN_LPAREN
 jne .next
 lea rax,[r13+6]
 cmp rax,r12
 jae .next
 lea rax,[r13+1]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+2]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 lea rax,[r13+3]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+4]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RPAREN
 jne .next
 lea rax,[r13+5]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 lea rax,[r13+6]
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .next
 inc r15d
 cmp r15d,2
 jae .yes
 jmp .next
.open:
 inc r14
 jmp .next
.close:
 test r14,r14
 jz .next
 dec r14
.next:
 inc r13
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; opening-brace token index -> EAX 1 when an exact declaration prefix occurs
; at direct depth zero of this outer body.  Nested braces are skipped so
; branch/loop attempts remain owned by the statement context diagnostic.
cli_npt37_block_has_direct_nested:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,[rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET]
 mov r13,[rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 lea r14,[rdi+1]
 xor r15d,r15d
.scan:
 cmp r14,r13
 jae .no
 mov rax,r14
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[r12+rax]
 mov rax,[rbx+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_RBRACE
 jne .check_open
 test r15,r15
 jz .no
 dec r15
 jmp .next
.check_open:
 cmp rax,NEBOC_TOKEN_LBRACE
 jne .check_prefix
 inc r15
 jmp .next
.check_prefix:
 test r15,r15
 jnz .next
 mov rdi,r14
 call cli_npt37_is_function_prefix
 test eax,eax
 jnz .yes
.next:
 inc r14
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; original opaque Block*, opening-brace token index -> status.  Ordinary
; statements retain the shared parser; only an exact direct prefix delegates
; to the existing receiver-first function parser and publishes a private AST
; declaration in source order.
cli_npt37_parse_outer_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 mov qword [rsp+32],0
 lea rbx,[rel cli_ast_builder]
 mov r12,[rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET]
 mov r13,[rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET]
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 lea rax,[r12+rax]
 mov rdx,[rsp]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdx+NEBOC_AST_NODE_START_OFFSET],rcx
 mov r14,[rsp+8]
 inc r14
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r14
.outer_loop:
 mov r14,[rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET]
 cmp r14,r13
 jae .expected
 mov rax,r14
 imul rax,NEBOC_TOKEN_SIZE
 lea r15,[r12+rax]
 mov rax,[r15+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_RBRACE
 je .outer_finish
 cmp rax,NEBOC_TOKEN_EOF
 je .expected
 mov rdi,r14
 call cli_npt37_is_function_prefix
 test eax,eax
 jz .ordinary_statement
 mov [rel cli_parser_request+NEBOC_PARSER_INDEX_OFFSET],r14
 mov qword [rel cli_parser_request+NEBOC_PARSER_ERROR_CODE_OFFSET],0
 mov qword [rel cli_parser_request+NEBOC_PARSER_ERROR_TOKEN_OFFSET],0
 lea rdi,[rel cli_parser_request]
 call neboc_parser_parse_function
 test eax,eax
 jnz .done
 mov rax,[rel cli_parser_request+NEBOC_PARSER_INDEX_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],rax
 mov r15,[rel cli_parser_request+NEBOC_PARSER_LAST_NODE_ID_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp+48]
 or qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jmp .link_statement
.ordinary_statement:
 lea rdi,[rel cli_stmt_request]
 call neboc_statement_parse
 test eax,eax
 jnz .done
 mov r15,[rel cli_stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 test r15,r15
 jz .bad
.link_statement:
 cmp qword [rsp+16],0
 jne .link_after_first
 mov [rsp+16],r15
 mov [rsp+24],r15
 jmp .count_statement
.link_after_first:
 mov rdi,rbx
 mov rsi,[rsp+24]
 lea rdx,[rsp+48]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp+48]
 mov [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],r15
 mov [rsp+24],r15
.count_statement:
 inc qword [rsp+32]
 jmp .outer_loop
.outer_finish:
 mov rdx,[rsp]
 mov rax,[r15+NEBOC_TOKEN_END_OFFSET]
 mov [rdx+NEBOC_AST_NODE_END_OFFSET],rax
 mov rax,[rsp+16]
 mov [rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET],rax
 mov rax,[rsp+32]
 mov [rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rax
 and qword [rdx+NEBOC_AST_NODE_FLAGS_OFFSET],~NEBOC_AST_FLAG_BODY_OPAQUE
 mov qword [rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 mov qword [rdx+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 inc r14
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r14
 xor eax,eax
 jmp .done
.expected:
 lea rdi,[rel cli_stmt_request]
 mov esi,NEBOC_PARSE_DIAG_EXPECTED_TOKEN
 mov rdx,r14
 call neboc_statement_set_error
 jmp .done
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Materialize every flagged private declaration only after all direct outer
; blocks have been published.  NESTED_FUNCTION_BODY makes any declaration in
; this body a typed depth-two rejection.
cli_npt37_materialize_nested_bodies:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r13d,1
.nested_scan:
 cmp r13,r12
 ja .nested_ok
 mov rdi,rbx
 mov rsi,r13
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .nested_bad
 mov r14,[rsp]
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .nested_next
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_NESTED_PRIVATE
 jz .nested_next
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.nested_find_block:
 test r15,r15
 jz .nested_bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .nested_bad
 mov rax,[rsp+8]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .nested_block_found
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .nested_find_block
.nested_block_found:
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_BODY_OPAQUE
 jz .nested_next
 mov [rsp+16],rax
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 test r15,r15
 jz .nested_bad
 dec r15
 lea rdi,[rel cli_stmt_request]
 mov ecx,NEBOC_STMT_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_expr_request]
 mov ecx,NEBOC_EXPR_REQUEST_SIZE/8
 xor eax,eax
 rep stosq
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .nested_tokens_original
 lea rax,[rel cli_general_tokens]
 mov rdx,[rel cli_general_token_count]
 jmp .nested_tokens_ready
.nested_tokens_original:
 lea rax,[rel cli_tokens]
 mov rdx,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
.nested_tokens_ready:
 mov [rel cli_stmt_request+NEBOC_STMT_TOKENS_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_TOKEN_COUNT_OFFSET],rdx
 mov rax,[rel cli_parser_request+NEBOC_PARSER_SOURCE_ID_OFFSET]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_ID_OFFSET],rax
 lea rax,[rel cli_source]
 mov [rel cli_stmt_request+NEBOC_STMT_SOURCE_DATA_OFFSET],rax
 mov [rel cli_stmt_request+NEBOC_STMT_BUILDER_OFFSET],rbx
 mov [rel cli_stmt_request+NEBOC_STMT_INDEX_OFFSET],r15
 mov qword [rel cli_stmt_request+NEBOC_STMT_MAX_NESTING_OFFSET],NEBOC_STMT_DEFAULT_MAX_NESTING
 mov qword [rel cli_stmt_request+NEBOC_STMT_FLAGS_OFFSET],NEBOC_STMT_FLAG_NPT37_NESTED_FUNCTION_BODY
 lea rax,[rel cli_expr_request]
 mov [rel cli_stmt_request+NEBOC_STMT_EXPR_REQUEST_OFFSET],rax
 lea rdi,[rel cli_stmt_request]
 call neboc_statement_parse_block
 test eax,eax
 jnz .nested_done
 mov rsi,[rel cli_stmt_request+NEBOC_STMT_RESULT_NODE_OFFSET]
 test rsi,rsi
 jz .nested_bad
 mov rdi,rbx
 lea rdx,[rsp+24]
 call neboc_ast_builder_node
 test eax,eax
 jnz .nested_bad
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
.nested_next:
 inc r13
 jmp .nested_scan
.nested_ok:
 xor eax,eax
 jmp .nested_done
.nested_bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.nested_done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Return 1 when a receiver-first source contains a material mutable marker or
; assignment token sequence inside a brace-delimited body.  This pre-AST
; classifier exists only to prevent the legacy parameter and mutable scanners
; from claiming a body `=` as a parameter-default marker.  Final ownership is
; still proved structurally after body materialization.
cli_tokens_contain_function_body_mutation:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_tokens]
 mov r12,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 test r12,r12
 jz .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_LPAREN
 jne .no
 xor r13d,r13d
 xor r14d,r14d
.scan:
 cmp r13,r12
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 lea r15,[rbx+rax]
 mov rax,[r15+NEBOC_TOKEN_KIND_OFFSET]
 cmp rax,NEBOC_TOKEN_LBRACE
 je .open
 cmp rax,NEBOC_TOKEN_RBRACE
 je .close
 test r14,r14
 jz .next
 cmp rax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 ; `.mutable` is the material declaration marker.
 mov rdi,r15
 lea rsi,[rel cli_function_mutable_name]
 mov edx,cli_function_mutable_name_len
 call cli_token_equals
 test eax,eax
 jz .assignment
 test r13,r13
 jz .assignment
 mov rax,r13
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 je .yes
.assignment:
 lea rax,[r13+1]
 cmp rax,r12
 jae .next
 imul rax,NEBOC_TOKEN_SIZE
 mov rcx,[rbx+rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp rcx,NEBOC_TOKEN_RESERVED_EQUAL
 je .yes
 cmp rcx,NEBOC_TOKEN_PLUS
 je .compound
 cmp rcx,NEBOC_TOKEN_MINUS
 je .compound
 cmp rcx,NEBOC_TOKEN_STAR
 je .compound
 cmp rcx,NEBOC_TOKEN_SLASH
 je .compound
 cmp rcx,NEBOC_TOKEN_PERCENT
 je .compound
 cmp rcx,NEBOC_TOKEN_CARET
 jne .nested_immutable_binding
.compound:
 lea rax,[r13+2]
 cmp rax,r12
 jae .next
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RESERVED_EQUAL
 je .yes
 jmp .next
.nested_immutable_binding:
 ; The durable B01 helper permits its own immutable Int local.  A declaration
 ; terminal inside the helper sits at brace depth >=2 and has exact existing
 ; `.name;` spelling.  Route that source past legacy whole-source parameter
 ; heuristics while excluding `.return;` and `.mutable;` terminals.
 cmp r14,2
 jb .next
 test r13,r13
 jz .next
 mov rax,r13
 dec rax
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 lea rax,[r13+1]
 cmp rax,r12
 jae .next
 imul rax,NEBOC_TOKEN_SIZE
 cmp qword [rbx+rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_SEMICOLON
 jne .next
 mov rdi,r15
 lea rsi,[rel cli_function_return_name]
 mov edx,cli_function_return_name_len
 call cli_token_equals
 test eax,eax
 jnz .next
 mov rdi,r15
 lea rsi,[rel cli_function_mutable_name]
 mov edx,cli_function_mutable_name_len
 call cli_token_equals
 test eax,eax
 jnz .next
 jmp .yes
.open:
 inc r14
 jmp .next
.close:
 test r14,r14
 jz .next
 dec r14
.next:
 inc r13
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
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

; Return 1 only for a parsed program containing a receiver-first function or
; the structural StartDecl, bounded if/else and at least one Char literal.
; C03-F04 admits the direct start-status form through the same typed shared
; backend while retaining the certified straight-line F02 textual route.
cli_program_is_char_exit_flow:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp r13,r12
 jae .finish
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_FUNCTION_DECL
 je .declaration
 cmp rax,NEBOC_AST_START_DECL
 jne .check_if
.declaration:
 or r14d,1
 jmp .next
.check_if:
 cmp rax,NEBOC_AST_IF_STMT
 jne .check_char
 or r14d,2
 jmp .next
.check_char:
 cmp rax,NEBOC_AST_CHAR_LITERAL
 jne .next
 or r14d,4
.next:
 inc r13
 jmp .loop
.finish:
 xor eax,eax
 cmp r14d,7
 sete al
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

; Return 1 for the exact structural root of NPT-LANG-10: at least one
; receiver-first declaration and one bounded if/else node in the shared AST.
cli_program_is_function_exit_flow:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp r13,r12
 jae .finish
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_FUNCTION_DECL
 jne .check_if
 or r14d,1
 jmp .next
.check_if:
 cmp rax,NEBOC_AST_IF_STMT
 jne .next
 or r14d,2
.next:
 inc r13
 jmp .loop
.finish:
 xor eax,eax
 cmp r14d,3
 sete al
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

; Return 1 only when a binding statement is span-contained by both a concrete
; if statement and a receiver-first function declaration. This is a routing
; classifier: the shared function backend remains the sole scope/type owner.
cli_program_is_function_branch_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.binding_loop:
 cmp r13,r12
 jae .no
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .binding_next
 xor r14d,r14d
.function_loop:
 cmp r14,r12
 jae .binding_next
 lea rsi,[r14+1]
 mov rdi,rbx
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .function_next
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .function_next
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .function_next
 xor r15d,r15d
.if_loop:
 cmp r15,r12
 jae .function_next
 lea rsi,[r15+1]
 mov rdi,rbx
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .if_next
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .if_next
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .if_next
 ; The containing if must itself remain within the same function.
 mov rcx,[rdx+NEBOC_AST_NODE_START_OFFSET]
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[rbx+NEBOC_AST_BUILDER_DATA_OFFSET]
 cmp rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 jb .if_next
 mov rcx,[rdx+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 ja .if_next
 mov eax,1
 jmp .done
.if_next:
 inc r15
 jmp .if_loop
.function_next:
 inc r14
 jmp .function_loop
.binding_next:
 inc r13
 jmp .binding_loop
.no:
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

; Return 1 when the shared AST contains either of the two already-public I/O
; calls whose function-body composition is owned by the shared function
; backend.  Keep the classifiers separate so Console never depends on Scan
; and each spelling retains an exact structural-containment proof.
cli_program_is_function_composition:
 sub rsp,8
 call cli_program_is_function_console
 cmp eax,0
 jne .done
 call cli_program_is_function_scan
 cmp eax,0
 jne .done
 call cli_program_is_function_mutation
 cmp eax,0
 jne .done
 call cli_program_is_function_loop
.done:
 add rsp,8
 ret

; Return 1 only when an explicit ReturnStmt is span-contained by start().
; Start I/O fallthrough keeps its frozen Practical-I/O route; this structural
; witness selects FunctionTable only for the distinct explicit-status form.
cli_program_has_start_explicit_return:
 push rbx
 push r12
 push r13
 push r14
 ; Four saved registers require eight bytes of local padding in addition to
 ; the two node-pointer slots to establish the System V pre-call state 0.
 sub rsp,24
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.return_loop:
 cmp r13,r12
 jae .no
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rax,[rsp]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne .return_next
 xor r14d,r14d
.start_loop:
 cmp r14,r12
 jae .return_next
 lea rsi,[r14+1]
 mov rdi,rbx
 lea rdx,[rsp+8]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .start_next
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .start_next
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 cmp rcx,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .start_next
 mov eax,1
 jmp .done
.start_next:
 inc r14
 jmp .start_loop
.return_next:
 inc r13
 jmp .return_loop
.no:
 xor eax,eax
 jmp .done
.bad:
 mov eax,-1
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Return 1 only when a material mutable binding terminal or assignment
; statement is structurally contained by a receiver-first function.  This is
; routing only: the shared function backend remains the lexical/type owner.
cli_program_is_function_mutation:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.mutation_scan:
 cmp r13,r12
 jae .no
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 je .find_function
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .next
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .next
.find_function:
 xor r14d,r14d
.function_scan:
 cmp r14,r12
 jae .next
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 mov rdx,[rbx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rdx,rax
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .function_next
 mov rax,[r15+NEBOC_AST_NODE_START_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .function_next
 mov rax,[r15+NEBOC_AST_NODE_END_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .function_next
 mov eax,1
 jmp .done
.function_next:
 inc r14
 jmp .function_scan
.next:
 inc r13
 jmp .mutation_scan
.no:
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

; Return 1 only when a material loop/while node is span-contained by a
; receiver-first function. Range/collection loops remain owned by their
; separate collection vertical and are deliberately excluded.
cli_program_is_function_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.loop_scan:
 cmp r13,r12
 jae .no
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .find_function
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 jne .next
.find_function:
 xor r14d,r14d
.function_scan:
 cmp r14,r12
 jae .next
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 mov rdx,[rbx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rdx,rax
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .function_next
 mov rax,[r15+NEBOC_AST_NODE_START_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .function_next
 mov rax,[r15+NEBOC_AST_NODE_END_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .function_next
 mov eax,1
 jmp .done
.function_next:
 inc r14
 jmp .function_scan
.next:
 inc r13
 jmp .loop_scan
.no:
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

; Return 1 only when the shared AST contains the existing zero-option
; console() call spelling inside a receiver-first function declaration span.
; A top-level Console plus an unrelated function must retain its established
; vertical owner.  This is a routing classifier, not a type checker: the
; function backend validates the already-public Text/Int/Bool receiver set and
; rejects every adjacent surface.
cli_program_is_function_console:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 call cli_program_has_start_explicit_return
 cmp eax,-1
 je .bad
 mov [rsp+8],rax
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .finish
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .next
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .next
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .next
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .next
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rax
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,cli_function_console_name_len
 jne .next
 lea rsi,[rel cli_source]
 add rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel cli_function_console_name]
 mov ecx,cli_function_console_name_len
 cld
 repe cmpsb
 jne .next
 ; Prove structural containment rather than merely finding a FunctionDecl
 ; somewhere else in the same program.
 xor r14d,r14d
.function_scan:
 cmp r14,r12
 jae .next
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 mov rdx,[rbx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rdx,rax
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 je .function_container
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .function_next
 cmp qword [rsp+8],1
 jne .function_next
.function_container:
 mov rax,[r15+NEBOC_AST_NODE_START_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .function_next
 mov rax,[r15+NEBOC_AST_NODE_END_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .function_next
 mov eax,1
 jmp .done
.function_next:
 inc r14
 jmp .function_scan
.next:
 inc r13
 jmp .loop
.finish:
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
 cld
 ret

; Return 1 only when the shared AST contains the canonical zero-option
; scan() binding call inside a receiver-first function declaration span.
; This is routing only: the function backend validates the receiver and the
; unchanged binding terminal syntax before emitting the canonical Scan ABI.
cli_program_is_function_scan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 call cli_program_has_start_explicit_return
 cmp eax,-1
 je .bad
 mov [rsp+8],rax
 lea rbx,[rel cli_ast_builder]
 mov r12,[rbx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r12
 jae .finish
 lea rsi,[r13+1]
 mov rdi,rbx
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .bad
 mov r15,[rsp]
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .next
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .next
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .next
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .next
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .bad
 imul rax,NEBOC_TOKEN_SIZE
 lea rdx,[rel cli_tokens]
 add rdx,rax
 cmp qword [rdx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rcx,[rdx+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rdx+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,cli_function_scan_name_len
 jne .next
 lea rsi,[rel cli_source]
 add rsi,[rdx+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel cli_function_scan_name]
 mov ecx,cli_function_scan_name_len
 cld
 repe cmpsb
 jne .next
 ; A top-level Scan plus an unrelated function must retain the top-level
 ; binding vertical.  Require the call's half-open span to be contained by a
 ; concrete receiver-first declaration.
 xor r14d,r14d
.function_scan:
 cmp r14,r12
 jae .next
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 mov rdx,[rbx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rdx,rax
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 je .function_container
 cmp qword [rdx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .function_next
 cmp qword [rsp+8],1
 jne .function_next
.function_container:
 mov rax,[r15+NEBOC_AST_NODE_START_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_START_OFFSET]
 jb .function_next
 mov rax,[r15+NEBOC_AST_NODE_END_OFFSET]
 cmp rax,[rdx+NEBOC_AST_NODE_END_OFFSET]
 ja .function_next
 mov eax,1
 jmp .done
.function_next:
 inc r14
 jmp .function_scan
.next:
 inc r13
 jmp .loop
.finish:
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
 cld
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
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .entry_prelude_ready
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 jne .ordinary_entry_prelude
 lea rdi,[rel cli_format]
 lea rsi,[rel cli_test_runner_label]
 mov rdx,[rel cli_test_runner_request+NEBOC_TEST_RUNNER_REQUEST_LABEL_LEN]
 call neboc_format_adapter_emit_named_entry_prelude
 test eax,eax
 jnz .bad
 jmp .entry_prelude_ready
.ordinary_entry_prelude:
 lea rdi,[rel cli_format]
 mov esi,1
 call neboc_format_adapter_emit_entry_prelude
 test eax,eax
 jnz .bad
.entry_prelude_ready:
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .function_program
 cmp qword [rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_FOUND_OFFSET],0
 jne .text_char_bytes_program
 cmp qword [rel cli_buffer+NEBOC_BUFFER_FOUND_OFFSET],0
 je .buffer_dispatch_ready
 call cli_program_requires_function_codegen
 cmp eax,-1
 je .bad
 test eax,eax
 jnz .function_program
 jmp ._buffer_program
.buffer_dispatch_ready:
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jnz .function_program
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
 lea rdi,[rel cli_writer]
 lea rsi,[rel cli_text_equal_extern]
 mov edx,cli_text_equal_extern_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .bad
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
 lea rax,[rel cli_branch_a_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_A_COUNTS_OFFSET],rax
 lea rax,[rel cli_branch_b_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_B_COUNTS_OFFSET],rax
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_BRANCH_SNAPSHOT_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_BRANCH_SNAPSHOT_COUNT_OFFSET],rax
 lea rax,[rel cli_loop_bodies]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_LOOP_BODIES_OFFSET],rax
 lea rax,[rel cli_loop_body_counts]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_LOOP_BODY_COUNTS_OFFSET],rax
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+NEBOC_VERTICAL_LOOP_SNAPSHOT_COUNT_OFFSET]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_LOOP_SNAPSHOT_COUNT_OFFSET],rax
 lea rax,[rel cli_binding_slot_catalog]
 mov [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_SLOT_CATALOG_OFFSET],rax
 mov qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_codegen_request+NEBOC_CODEGEN_SLOT_CATALOG_CAPACITY_OFFSET],NEBOC_CODEGEN_SLOT_CATALOG_CAPACITY
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
 mov ecx,(NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS*NEBOC_ABI_SIGNATURE_SIZE)/8
 xor eax,eax
 rep stosq
 lea rdi,[rel cli_function_plans]
 mov ecx,(NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS*NEBOC_FUNCTION_PLAN_SIZE)/8
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
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .codegen_tokens_original
 lea rax,[rel cli_general_tokens]
 mov rdx,[rel cli_general_token_count]
 jmp .codegen_tokens_ready
.codegen_tokens_original:
 lea rax,[rel cli_tokens]
 mov rdx,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
.codegen_tokens_ready:
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET],rax
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET],rdx
 lea rax,[rel cli_source]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel cli_literal_bytes]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET],rax
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_LENGTH_OFFSET],rax
 lea rax,[rel cli_array_range]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_ARRAY_RANGE_OFFSET],rax
 lea rax,[rel cli_buffer]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_BUFFER_OWNERS_OFFSET],rax
 mov rax,[rel cli_buffer_owner_count]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_BUFFER_OWNER_COUNT_OFFSET],rax
 lea rax,[rel cli_nominal_owners]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_NOMINAL_OWNERS_OFFSET],rax
 mov rax,[rel cli_nominal_owner_count]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_NOMINAL_OWNER_COUNT_OFFSET],rax
 lea rax,[rel cli_scientific_owners]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_OWNERS_OFFSET],rax
 mov rax,[rel cli_scientific_owner_count]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_OWNER_COUNT_OFFSET],rax
 lea rax,[rel cli_scientific_owner_source_starts]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_STARTS_OFFSET],rax
 lea rax,[rel cli_scientific_owner_source_ends]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_SOURCE_ENDS_OFFSET],rax
 lea rax,[rel cli_scientific_owner_result_source_starts]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SCIENTIFIC_RESULT_STARTS_OFFSET],rax
 lea rax,[rel cli_writer]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET],rax
 lea rax,[rel cli_backend]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET],rax
 lea rax,[rel cli_abi_adapter]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET],rax
 lea rax,[rel cli_function_signatures]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET],rax
 mov qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET],NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS
 lea rax,[rel cli_function_plans]
 mov [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET],rax
 mov qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET],NEBOC_FUNCTION_CODEGEN_MAX_INTERNAL_FUNCTIONS
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 je .function_codegen_allow_no_start
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 jne .function_codegen_policy_ready
.function_codegen_allow_no_start:
 mov qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_FLAG_ALLOW_NO_START
.function_codegen_policy_ready:
 cmp qword [rel cli_function_textual_validated],0
 je .function_codegen_textual_ready
 or qword [rel cli_function_codegen_request+NEBOC_FUNCTION_CODEGEN_REQUEST_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_FLAG_TEXTUAL_VALIDATED
.function_codegen_textual_ready:
 lea rdi,[rel cli_function_codegen]
 lea rsi,[rel cli_function_codegen_request]
 call neboc_function_codegen_init
 test eax,eax
 jnz .bad
 lea rdi,[rel cli_function_codegen]
 call neboc_function_codegen_emit
 test eax,eax
 jnz .function_codegen_failed
 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_TEST
 jne .program_emitted
 call cli_emit_test_runner
 test eax,eax
 jz .program_emitted
 jmp .bad
.function_codegen_failed:
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

; A rejected source invocation owns no publishable result. Remove only the
; exact output paths derived from the already-validated -o argument so a prior
; successful artifact cannot masquerade as this failed invocation.
cli_invalidate_rejected_source_outputs:
 push rbx
 mov rbx,[rel cli_state+NEBOC_CLI_STATE_MODE_OFFSET]
 cmp rbx,NEBOC_CLI_MODE_CHECK
 je .done
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 test rdi,rdi
 jz .done
 call cli_unlink_path
 cmp rbx,NEBOC_CLI_MODE_BUILD
 jne .done
 lea rdi,[rel cli_temp_asm_path]
 mov rsi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 lea rdx,[rel suffix_asm]
 mov ecx,suffix_asm_len
 call cli_make_suffixed_path
 test eax,eax
 jnz .object
 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
.object:
 lea rdi,[rel cli_temp_obj_path]
 mov rsi,[rel cli_state+NEBOC_CLI_STATE_OUTPUT_PTR_OFFSET]
 lea rdx,[rel suffix_obj]
 mov ecx,suffix_obj_len
 call cli_make_suffixed_path
 test eax,eax
 jnz .done
 lea rdi,[rel cli_temp_obj_path]
 call cli_unlink_path
.done:
 xor eax,eax
 pop rbx
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

 cmp qword [rel cli_entrypoint_target_kind],NEBOC_TARGET_KIND_LIBRARY
 jne .link_executable
 lea rdi,[rel cli_temp_obj_path]
 mov rsi,r12
 mov eax,82
 syscall
 cmp rax,-4095
 jae .library_commit_fail
 mov rax,[rel cli_toolchain+NEBOC_TOOLCHAIN_INVOCATION_COUNT_OFFSET]
 mov [rel cli_state+NEBOC_CLI_STATE_TOOLCHAIN_COUNT_OFFSET],rax
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .ok
 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
 jmp .ok

.link_executable:

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
.library_commit_fail:
 lea rdi,[rel cli_temp_obj_path]
 call cli_unlink_path
 cmp qword [rel cli_state+NEBOC_CLI_STATE_KEEP_TEMP_OFFSET],0
 jne .library_io
 lea rdi,[rel cli_temp_asm_path]
 call cli_unlink_path
.library_io:
 mov eax,NEBOC_CLI_EXIT_IO_ERROR
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

; Build one canonical diagnostic from the first causal owner that rejected the
; source.  Serializers consume this record; none reclassifies final prose.
cli_prepare_canonical_diagnostic:
 push rbx
 push r12
 push r13
 push r14
 push r15
 lea rdi,[rel cli_canonical_diagnostic]
 mov ecx,NEBOC_DIAGNOSTIC_QWORDS
 xor eax,eax
 rep stosq
 mov r12d,NEBOC_DIAG_PARSE_UNEXPECTED_TOKEN
 xor r13d,r13d
 mov r14,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 test r14,r14
 jz .lexer
 mov r14d,1
.lexer:
 cmp qword [rel cli_lexer_request+NEBOC_LEXER_REQUEST_ERROR_COUNT_OFFSET],0
 jne .lexer_scan_begin
 cmp qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],NEBOC_API_DIAG_UNKNOWN
 je .textual_unknown
 cmp qword [rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_FOUND_OFFSET],0
 jne .scientific
 jmp .array
.lexer_scan_begin:
 xor r15d,r15d
.lexer_scan:
 cmp r15,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .array
 mov rax,r15
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 add rbx,rax
 test qword [rbx+NEBOC_TOKEN_FLAGS_OFFSET],NEBOC_TOKEN_FLAG_ERROR
 jz .lexer_next
 mov rax,[rbx+NEBOC_TOKEN_PAYLOAD_OFFSET]
 cmp rax,NEBOC_DIAG_LEX_INVALID_UTF8
 je .lexer_owned
 cmp rax,NEBOC_DIAG_LEX_INVALID_CHARACTER
 je .lexer_owned
 cmp rax,NEBOC_DIAG_LEX_UNTERMINATED_TEXT
 jb .lexer_default
 cmp rax,NEBOC_DIAG_LEX_UNSUPPORTED_BLOCK_COMMENT
 jbe .lexer_owned
.lexer_default:
 mov eax,NEBOC_DIAG_LEX_INVALID_CHARACTER
.lexer_owned:
 mov r12,rax
 mov r13,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r14,[rbx+NEBOC_TOKEN_END_OFFSET]
 jmp .selected
.lexer_next:
 inc r15
 jmp .lexer_scan

.textual_unknown:
 mov r12d,NEBOC_DIAG_BEHAVIOR_UNSUPPORTED
 mov rdi,[rel cli_textual_frontend_error_token]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.scientific:
 mov rax,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET]
 cmp rax,11
 je .scientific_dtype
 cmp rax,12
 je .scientific_limit
 cmp rax,13
 je .scientific_syntax
 cmp rax,16
 je .scientific_deferred
 cmp rax,17
 je .scientific_tensor_dtype
 cmp rax,18
 je .scientific_tensor_syntax
 cmp rax,19
 je .scientific_tensor_type
 cmp rax,20
 je .scientific_tensor_limit
 cmp rax,21
 je .scientific_tensor_limit
 cmp rax,22
 je .scientific_tensor_deferred
 cmp rax,23
 jne .array
.scientific_tensor_deferred:
 mov r12d,NEBOC_DIAG_BEHAVIOR_UNSUPPORTED
 jmp .scientific_tensor_span
.scientific_deferred:
 mov r12d,NEBOC_DIAG_BEHAVIOR_UNSUPPORTED
 jmp .scientific_span
.scientific_dtype:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .scientific_span
.scientific_limit:
 mov r12d,NEBOC_DIAG_LIMIT_EXCEEDED
 jmp .scientific_span
.scientific_syntax:
 mov r12d,NEBOC_DIAG_PARSE_UNEXPECTED_TOKEN
.scientific_span:
 xor r13d,r13d
 mov r14,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 test r14,r14
 jz .selected
 mov r14d,1
 jmp .selected
.scientific_tensor_dtype:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .scientific_tensor_span
.scientific_tensor_syntax:
 mov r12d,NEBOC_DIAG_PARSE_UNEXPECTED_TOKEN
 jmp .scientific_tensor_span
.scientific_tensor_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .scientific_tensor_span
.scientific_tensor_limit:
 mov r12d,NEBOC_DIAG_LIMIT_EXCEEDED
.scientific_tensor_span:
 mov rdi,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .scientific_span
 mov r13,rax
 mov r14,rdx
 jmp .selected

.array:
 mov rax,[rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 je .array_control_pair
 cmp rax,NEBOC_PARSE_DIAG_CONTROL_HEADER_RPAREN_REQUIRED
 je .array_control_delimiter
 cmp rax,NEBOC_AR_DIAG_CONST_LENGTH
 je .array_length
 cmp rax,NEBOC_AR_DIAG_RECORD_CAPACITY
 je .array_records
 cmp rax,NEBOC_AR_DIAG_VALUE_CAPACITY
 je .array_values
 jmp .tuple
.array_control_pair:
 mov r12d,NEBOC_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jmp .array_span
.array_control_delimiter:
 mov r12d,NEBOC_DIAG_CONTROL_HEADER_DELIMITER
 jmp .array_span
.array_length:
 mov r12d,NEBOC_DIAG_ARRAY_LENGTH_PUBLIC
 jmp .array_span
.array_records:
 mov r12d,NEBOC_DIAG_COLLECTION_RECORD_CAPACITY
 jmp .array_span
.array_values:
 mov r12d,NEBOC_DIAG_COLLECTION_SCALAR_POOL_CAPACITY
.array_span:
 mov rdi,[rel cli_array_range+NEBOC_AR_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.tuple:
 cmp qword [rel cli_struct_tuple+NEBOC_ST_FOUND_OFFSET],0
 je .binding
 mov rax,[rel cli_struct_tuple+NEBOC_ST_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_DIAG_WRONG_ARITY
 je .tuple_arity
 cmp rax,NEBOC_DIAG_TUPLE_BOUNDS
 je .tuple_bounds
 cmp rax,NEBOC_DIAG_TUPLE_DEPTH
 je .tuple_depth
 cmp rax,NEBOC_DIAG_TUPLE_TYPE
 je .tuple_type
 cmp rax,NEBOC_DIAG_TUPLE_DUPLICATE_BINDING
 jne .binding
 mov r12d,NEBOC_DIAG_TUPLE_DUPLICATE_BINDING_PUBLIC
 jmp .tuple_span
.tuple_type:
 mov r12d,NEBOC_DIAG_TUPLE_INVALID_RECEIVER
 jmp .tuple_span
.tuple_arity:
 mov r12d,NEBOC_DIAG_TUPLE_ARITY
 jmp .tuple_span
.tuple_bounds:
 mov r12d,NEBOC_DIAG_TUPLE_INDEX_OUT_OF_RANGE
 jmp .tuple_span
.tuple_depth:
 mov r12d,NEBOC_DIAG_TUPLE_NESTING_LIMIT
.tuple_span:
 mov rdi,[rel cli_struct_tuple+NEBOC_ST_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.binding:
 mov rax,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET]
 test rax,rax
 jz .mutable
 cmp rax,NEBOC_DIAG_BREAK_OUTSIDE_LOOP
 je .binding_break
 cmp rax,NEBOC_DIAG_CONTINUE_OUTSIDE_LOOP
 je .binding_continue
 cmp rax,NEBOC_DIAG_WHILE_CONDITION_TYPE
 je .binding_while_condition
 cmp rax,NEBOC_BIND_DIAG_UNDEFINED_NAME
 je .binding_undefined
 cmp rax,NEBOC_BIND_DIAG_USE_BEFORE_INITIALIZATION
 je .binding_flow
 cmp rax,NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 je .binding_flow
 cmp rax,NEBOC_BIND_DIAG_DUPLICATE_DECLARATION
 je .binding_duplicate
 cmp rax,NEBOC_BIND_DIAG_SHADOWING_FORBIDDEN
 je .binding_shadow
 cmp rax,NEBOC_BIND_DIAG_TYPE_MISMATCH
 je .binding_type
 cmp rax,NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
 je .binding_assignment_type
 jmp .mutable
.binding_break:
 mov r12d,NEBOC_DIAG_LOOP_BREAK_OUTSIDE
 jmp .binding_span
.binding_continue:
 mov r12d,NEBOC_DIAG_LOOP_CONTINUE_OUTSIDE
 jmp .binding_span
.binding_while_condition:
 mov r12d,NEBOC_DIAG_WHILE_CONDITION_TYPE_PUBLIC
 jmp .binding_span
.binding_undefined:
 mov r12d,NEBOC_DIAG_NAME_UNDEFINED
 jmp .binding_span
.binding_flow:
 mov r12d,NEBOC_DIAG_BINDING_NOT_DEFINITELY_INITIALIZED
 jmp .binding_span
.binding_duplicate:
 mov r12d,NEBOC_DIAG_NAME_DUPLICATE
 jmp .binding_span
.binding_shadow:
 mov r12d,NEBOC_DIAG_NAME_SHADOW
 jmp .binding_span
.binding_type:
 mov r12d,NEBOC_DIAG_BINDING_TYPE_MISMATCH
 jmp .binding_span
.binding_assignment_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
.binding_span:
 mov r13,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET]
 mov r14,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET]
 cmp r14,r13
 ja .selected
 mov rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected
.binding_token_span:
 mov rdi,[rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.mutable:
 mov rax,[rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_DIAG_BREAK_OUTSIDE_LOOP
 je .mutable_break
 cmp rax,NEBOC_DIAG_CONTINUE_OUTSIDE_LOOP
 je .mutable_continue
 cmp rax,NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
 je .cli_semantic_assignment_type
 jmp .cli_semantic_module
.mutable_continue:
 mov r12d,NEBOC_DIAG_LOOP_CONTINUE_OUTSIDE
 jmp .mutable_span
.mutable_break:
 mov r12d,NEBOC_DIAG_LOOP_BREAK_OUTSIDE
.mutable_span:
 mov rdi,[rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.cli_semantic_assignment_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov rdi,[rel literais_numericos_bases_e_representacao_cli_parse_request+NEBOC_PARSE_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

; Canonical diagnostics: the bounded owners below already parsed and semantically
; rejected their public surfaces.  Machine reporting must project that first
; causal owner instead of retaining the generic parser fallback initialized at
; function entry.
.cli_semantic_module:
 mov rax,[rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_MODULE_DIAG_PRIVATE_ACCESS
 je .cli_semantic_module_owned
 cmp rax,NEBOC_MODULE_DIAG_MISSING_EXPORT
 jne .cli_semantic_ownership
.cli_semantic_module_owned:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .cli_semantic_whole_source_span

.cli_semantic_ownership:
 mov rax,[rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_DIAG_USE_AFTER_MOVE
 jne .cli_semantic_policy
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov r13,[rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_ERROR_START_OFFSET_semantic_memory_native_vertical]
 mov r14,[rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_ERROR_END_OFFSET_semantic_memory_native_vertical]
 cmp r14,r13
 ja .selected
 mov rdi,[rel text_char_unicode_e_bytes_cli_semantic+NEBOC_SEM_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.cli_semantic_policy:
 cmp qword [rel effects_capabilities_e_politicas_cli_frontend_diagnostic],neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
 jne .cli_semantic_programmer_type
 mov r12d,neboc_effects_capabilities_e_politicas_DIAG_SECURITY_diagnostics
 mov r13,[rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_SOURCE_START_OFFSET]
 mov r14,[rel effects_capabilities_e_politicas_cli_semantic_request+NEBOC_SEMANTIC_SOURCE_END_OFFSET]
 cmp r14,r13
 ja .selected
 jmp .cli_semantic_whole_source_span

.cli_semantic_programmer_type:
 cmp qword [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],4
 jne .cli_semantic_parameters
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .cli_semantic_whole_source_span

.cli_semantic_parameters:
 cmp qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_MISSING_ARGUMENT
 jne .cli_semantic_result
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov rdi,[rel cli_parameters+NEBOC_PARAM_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.cli_semantic_result:
 cmp qword [rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_NON_EXHAUSTIVE
 jne .cli_semantic_numeric
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov rdi,[rel cli_result+NEBOC_RESULT_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.cli_semantic_numeric:
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 je .cli_semantic_numeric_owned_text
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 jne .function
.cli_semantic_numeric_owned_safety:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov r13,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_START_OFFSET]
 mov r14,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_END_OFFSET]
 cmp r14,r13
 ja .selected
 mov rdi,[rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected
.cli_semantic_numeric_owned_text:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 mov r13,[rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_START_OFFSET]
 mov r14,[rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_END_OFFSET]
 cmp r14,r13
 ja .selected
 mov rdi,[rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_TOKEN_OFFSET]
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx
 jmp .selected

.cli_semantic_whole_source_span:
 xor r13d,r13d
 mov r14,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 jmp .selected

.function:
 mov rax,[rel cli_function_codegen+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET]
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 je .function_call_limit
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_CALL_LIMIT
 je .function_call_limit
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_MISSING_RETURN
 je .function_missing_return
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_INCONSISTENT_RETURN
 je .function_inconsistent_return
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 je .function_condition
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_UNDECLARED
 je .function_assignment_undeclared
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_IMMUTABLE
 je .function_assignment_immutable
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_TYPE
 je .function_assignment_type
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ASSIGNMENT_COMPOUND
 je .function_assignment_compound
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_MUTABLE_TYPE
 je .function_mutable_type
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_SLICE_ELEMENT_MISMATCH
 je .function_slice_element_type
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION
 je .function_recursion
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_FORWARD_CALL
 je .function_recursion
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_UNDEFINED_CALL
 je .function_undefined_call
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_SURFACE
 je .function_recursion_surface
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_SHAPE
 je .function_recursion_shape
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_NONTAIL
 je .function_recursion_nontail
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION_FRAME
 je .function_recursion_frame
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CALL_BEFORE
 je .function_nested_before
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SCOPE
 je .function_nested_scope
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_DUPLICATE
 je .function_nested_duplicate
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPTURE
 je .function_nested_capture
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_ESCAPE
 je .function_nested_escape
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECURSION
 je .function_nested_recursion
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECURSIVE_OUTER
 je .function_nested_recursive_outer
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RECEIVER
 je .function_nested_receiver
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_PARAMETER
 je .function_nested_parameter
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_RETURN
 je .function_nested_return
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SURFACE
 je .function_nested_surface
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_SYMBOL_COLLISION
 je .function_nested_collision
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CAPACITY
 je .function_nested_capacity
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_NESTED_CONTEXT
 je .function_nested_context
 cmp rax,NEBOC_FUNCTION_CODEGEN_ERROR_ENTRYPOINT_STATUS
 je .function_entrypoint_status
 jmp .parser
.function_call_limit:
 mov r12d,NEBOC_DIAG_FUNCTION_CALL_CAPACITY
 jmp .function_span
.function_missing_return:
 mov r12d,NEBOC_DIAG_TYPE_MISSING_RETURN
 jmp .function_span
.function_inconsistent_return:
 mov r12d,NEBOC_DIAG_TYPE_INCONSISTENT_RETURN
 jmp .function_span
.function_condition:
 mov r12d,NEBOC_DIAG_CONTROL_CONDITION_TYPE
 jmp .function_span
.function_assignment_undeclared:
 mov r12d,NEBOC_DIAG_NAME_UNDEFINED
 jmp .function_span
.function_assignment_immutable:
 mov r12d,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR
 jmp .function_span
.function_assignment_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .function_span
.function_assignment_compound:
 mov r12d,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR
 jmp .function_span
.function_mutable_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .function_span
.function_slice_element_type:
 mov r12d,NEBOC_DIAG_TYPE_MISMATCH
 jmp .function_span
.function_recursion:
 mov r12d,NEBOC_DIAG_CALL_RECURSION
 jmp .function_span
.function_undefined_call:
 mov r12d,NEBOC_DIAG_CALL_UNDEFINED
 jmp .function_span
.function_recursion_surface:
 mov r12d,NEBOC_DIAG_CALL_RECURSION_SURFACE
 jmp .function_span
.function_recursion_shape:
 mov r12d,NEBOC_DIAG_CALL_RECURSION_SHAPE
 jmp .function_span
.function_recursion_nontail:
 mov r12d,NEBOC_DIAG_CALL_RECURSION_NONTAIL
 jmp .function_span
.function_recursion_frame:
 mov r12d,NEBOC_DIAG_CALL_RECURSION_FRAME
 jmp .function_span
.function_nested_before:
 mov r12d,NEBOC_DIAG_NESTED_CALL_BEFORE_DECLARATION
 jmp .function_span
.function_nested_scope:
 mov r12d,NEBOC_DIAG_NESTED_SCOPE
 jmp .function_span
.function_nested_duplicate:
 mov r12d,NEBOC_DIAG_NESTED_DUPLICATE
 jmp .function_span
.function_nested_capture:
 mov r12d,NEBOC_DIAG_NESTED_CAPTURE_UNSUPPORTED
 jmp .function_span
.function_nested_escape:
 mov r12d,NEBOC_DIAG_NESTED_ESCAPE
 jmp .function_span
.function_nested_recursion:
 mov r12d,NEBOC_DIAG_NESTED_RECURSION
 jmp .function_span
.function_nested_recursive_outer:
 mov r12d,NEBOC_DIAG_NESTED_RECURSIVE_OUTER
 jmp .function_span
.function_nested_receiver:
 mov r12d,NEBOC_DIAG_NESTED_RECEIVER_UNSUPPORTED
 jmp .function_span
.function_nested_parameter:
 mov r12d,NEBOC_DIAG_NESTED_PARAMETER_UNSUPPORTED
 jmp .function_span
.function_nested_return:
 mov r12d,NEBOC_DIAG_NESTED_RETURN_UNSUPPORTED
 jmp .function_span
.function_nested_surface:
 mov r12d,NEBOC_DIAG_NESTED_SURFACE
 jmp .function_span
.function_nested_collision:
 mov r12d,NEBOC_DIAG_NESTED_SYMBOL_COLLISION
 jmp .function_span
.function_nested_capacity:
 mov r12d,NEBOC_DIAG_NESTED_CAPACITY
 jmp .function_span
.function_nested_context:
 mov r12d,NEBOC_DIAG_NESTED_CONTEXT
 jmp .function_span
.function_entrypoint_status:
 mov r12d,NEBOC_DIAG_ENTRYPOINT_INVALID_SIGNATURE
.function_span:
 mov r13,[rel cli_function_codegen+NEBOC_FUNCTION_CODEGEN_ERROR_START_OFFSET]
 mov r14,[rel cli_function_codegen+NEBOC_FUNCTION_CODEGEN_ERROR_END_OFFSET]
 jmp .selected

.parser:
 mov rax,[rel cli_parser_request+NEBOC_PARSER_ERROR_CODE_OFFSET]
 mov rdi,[rel cli_parser_request+NEBOC_PARSER_ERROR_TOKEN_OFFSET]
 call cli_diag_select_parser_owner
 test ecx,ecx
 jnz .parser_owned
 mov rax,[rel cli_stmt_request+NEBOC_STMT_ERROR_CODE_OFFSET]
 mov rdi,[rel cli_stmt_request+NEBOC_STMT_ERROR_TOKEN_OFFSET]
 call cli_diag_select_parser_owner
 test ecx,ecx
 jnz .parser_owned
 mov rax,[rel cli_expr_request+NEBOC_EXPR_ERROR_CODE_OFFSET]
 mov rdi,[rel cli_expr_request+NEBOC_EXPR_ERROR_TOKEN_OFFSET]
 call cli_diag_select_parser_owner
 test ecx,ecx
 jz .selected
.parser_owned:
 mov r12,rax
 call cli_diag_span_from_token
 test ecx,ecx
 jz .selected
 mov r13,rax
 mov r14,rdx

.selected:
 ; A real token must have a non-empty half-open span.  Preserve the factual
 ; zero-width case only when the source itself has no byte to designate.
 cmp r14,r13
 ja .bounded
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp r13,rax
 jae .bounded
 lea r14,[r13+1]
.bounded:
 lea rbx,[rel cli_canonical_diagnostic]
 mov qword [rbx+NEBOC_DIAGNOSTIC_ID_OFFSET],1
 mov [rbx+NEBOC_DIAGNOSTIC_CODE_OFFSET],r12
 lea rsi,[rel cli_diag_catalog_entry]
 mov rdi,r12
 call neboc_diagnostic_catalog_lookup
 test eax,eax
 jnz .done
 lea rax,[rel cli_diag_catalog_entry]
 mov rdx,[rax+NEBOC_DIAG_ENTRY_NAME_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],rdx
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],rdx
 mov rdx,[rax+NEBOC_DIAG_ENTRY_NAME_LENGTH_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],rdx
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],rdx
 mov rdx,[rax+NEBOC_DIAG_ENTRY_SEVERITY_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_SEVERITY_OFFSET],rdx
 mov rdx,[rax+NEBOC_DIAG_ENTRY_PHASE_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],rdx
 call cli_enrich_scientific_diagnostic
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_TYPE
 cmp rdx,NEBOC_DIAGNOSTIC_PHASE_LEX
 je .syntax_category
 cmp rdx,NEBOC_DIAGNOSTIC_PHASE_PARSE
 je .syntax_category
 cmp r12,NEBOC_DIAG_ENTRYPOINT_MISSING
 je .syntax_category
 cmp r12,NEBOC_DIAG_ENTRYPOINT_DUPLICATE
 je .syntax_category
 cmp r12,NEBOC_DIAG_ENTRYPOINT_AMBIGUOUS
 je .syntax_category
 cmp r12,NEBOC_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 jne .category_ready
.syntax_category:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_SYNTAX
.category_ready:
 call cli_enrich_cli_semantic_diagnostic
 mov qword [rbx+NEBOC_DIAGNOSTIC_SCHEMA_VERSION_OFFSET],NEBOC_DIAGNOSTIC_SCHEMA_V1
 mov qword [rbx+NEBOC_DIAGNOSTIC_EXIT_CODE_OFFSET],NEBOC_DIAGNOSTIC_EXIT_USER_ERROR
 mov qword [rbx+NEBOC_DIAGNOSTIC_HAS_PRIMARY_OFFSET],1
 mov qword [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],1
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],r13
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],r14
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],rax
 cmp r12,NEBOC_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 je .control_fixits
 cmp r12,NEBOC_DIAG_CONTROL_HEADER_DELIMITER
 jne .record_ready
.control_fixits:
 mov rax,[rel cli_array_range+NEBOC_AR_DIAGNOSTIC_OFFSET]
 cmp rax,r12
 jne .statement_control_fixits
 mov rax,[rel cli_array_range+NEBOC_AR_CONTROL_FIXIT_COUNT_OFFSET]
 mov r13,[rel cli_array_range+NEBOC_AR_CONTROL_FIXIT0_START_OFFSET]
 mov r14,[rel cli_array_range+NEBOC_AR_CONTROL_FIXIT0_KIND_OFFSET]
 mov r15,[rel cli_array_range+NEBOC_AR_CONTROL_FIXIT1_START_OFFSET]
 mov r10d,NEBOC_AR_CONTROL_FIXIT_INSERT_RPAREN
 jmp .control_fixits_loaded
.statement_control_fixits:
 mov rax,[rel cli_stmt_request+NEBOC_STMT_FIXIT_COUNT_OFFSET]
 mov r13,[rel cli_stmt_request+NEBOC_STMT_FIXIT0_START_OFFSET]
 mov r14,[rel cli_stmt_request+NEBOC_STMT_FIXIT0_KIND_OFFSET]
 mov r15,[rel cli_stmt_request+NEBOC_STMT_FIXIT1_START_OFFSET]
 mov r10,[rel cli_stmt_request+NEBOC_STMT_FIXIT1_KIND_OFFSET]
.control_fixits_loaded:
 test rax,rax
 jz .record_ready
 cmp rax,2
 ja .record_ready
 mov [rbx+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET],rax
 or qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SUGGESTION|NEBOC_DIAGNOSTIC_FLAG_HAS_FIXITS
 lea rcx,[rel cli_control_fix_suggestion]
 mov [rbx+NEBOC_DIAGNOSTIC_SUGGESTION_OFFSET],rcx
 mov qword [rbx+NEBOC_DIAGNOSTIC_SUGGESTION_LENGTH_OFFSET],cli_control_fix_suggestion_end-cli_control_fix_suggestion
 mov rcx,r13
 mov [rbx+NEBOC_DIAGNOSTIC_INSERTION_OFFSET],rcx
 lea rdx,[rbx+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET]
 mov qword [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_TYPE_OFFSET],NEBOC_DIAGNOSTIC_ARGUMENT_TEXT
 mov [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET],rcx
 mov rax,r14
 lea rcx,[rel cli_fix_lparen]
 cmp rax,NEBOC_STMT_FIXIT_INSERT_LPAREN
 je .fix0_text
 lea rcx,[rel cli_fix_rparen]
.fix0_text:
 mov [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_DATA_OFFSET],rcx
 mov qword [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET],1
 cmp qword [rbx+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET],2
 jne .record_ready
 add rdx,NEBOC_DIAGNOSTIC_ARGUMENT_SIZE
 mov qword [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_TYPE_OFFSET],NEBOC_DIAGNOSTIC_ARGUMENT_TEXT
 mov rcx,r15
 mov [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET],rcx
 mov rax,r10
 lea rcx,[rel cli_fix_lparen]
 cmp rax,NEBOC_STMT_FIXIT_INSERT_LPAREN
 je .fix1_text
 lea rcx,[rel cli_fix_rparen]
.fix1_text:
 mov [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_DATA_OFFSET],rcx
 mov qword [rdx+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET],1
.record_ready:
 mov rdi,rbx
 call cli_enrich_entrypoint_diagnostic
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Project the C11 scientific owner into the canonical diagnostic without
; teaching the global catalog a partially implemented Matrix/Tensor surface.
; The underlying numeric id retains its established broad category; every
; renderer receives the exact stable public code and message selected here.
cli_enrich_scientific_diagnostic:
 mov rax,[rel vetores_matrizes_tensores_e_computacao_cientifica_cli_vertical_request+NEBOC_VECTOR_VERTICAL_DIAGNOSTIC_OFFSET]
 cmp rax,11
 je .matrix_dtype
 cmp rax,12
 je .matrix_limit
 cmp rax,13
 je .matrix_syntax
 cmp rax,16
 je .matrix_deferred
 cmp rax,17
 je .tensor_dtype
 cmp rax,18
 je .tensor_syntax
 cmp rax,19
 je .tensor_extent
 cmp rax,20
 je .tensor_overflow
 cmp rax,21
 je .tensor_limit
 cmp rax,22
 je .tensor_copy
 cmp rax,23
 je .tensor_deferred
 ret
.matrix_dtype:
 lea r8,[rel scientific_cli_code_matrix_dtype]
 mov r9d,scientific_cli_code_matrix_dtype_end-scientific_cli_code_matrix_dtype
 lea r10,[rel scientific_cli_message_matrix_dtype]
 mov r11d,scientific_cli_message_matrix_dtype_end-scientific_cli_message_matrix_dtype
 jmp .write
.matrix_limit:
 lea r8,[rel scientific_cli_code_matrix_limit]
 mov r9d,scientific_cli_code_matrix_limit_end-scientific_cli_code_matrix_limit
 lea r10,[rel scientific_cli_message_matrix_limit]
 mov r11d,scientific_cli_message_matrix_limit_end-scientific_cli_message_matrix_limit
 jmp .write
.matrix_syntax:
 lea r8,[rel scientific_cli_code_matrix_syntax]
 mov r9d,scientific_cli_code_matrix_syntax_end-scientific_cli_code_matrix_syntax
 lea r10,[rel scientific_cli_message_matrix_syntax]
 mov r11d,scientific_cli_message_matrix_syntax_end-scientific_cli_message_matrix_syntax
 jmp .write
.matrix_deferred:
 lea r8,[rel scientific_cli_code_matrix_deferred]
 mov r9d,scientific_cli_code_matrix_deferred_end-scientific_cli_code_matrix_deferred
 lea r10,[rel scientific_cli_message_matrix_deferred]
 mov r11d,scientific_cli_message_matrix_deferred_end-scientific_cli_message_matrix_deferred
 jmp .write
.tensor_dtype:
 lea r8,[rel scientific_cli_code_tensor_dtype]
 mov r9d,scientific_cli_code_tensor_dtype_end-scientific_cli_code_tensor_dtype
 lea r10,[rel scientific_cli_message_tensor_dtype]
 mov r11d,scientific_cli_message_tensor_dtype_end-scientific_cli_message_tensor_dtype
 jmp .write
.tensor_syntax:
 lea r8,[rel scientific_cli_code_tensor_syntax]
 mov r9d,scientific_cli_code_tensor_syntax_end-scientific_cli_code_tensor_syntax
 lea r10,[rel scientific_cli_message_tensor_syntax]
 mov r11d,scientific_cli_message_tensor_syntax_end-scientific_cli_message_tensor_syntax
 jmp .write
.tensor_extent:
 lea r8,[rel scientific_cli_code_tensor_extent]
 mov r9d,scientific_cli_code_tensor_extent_end-scientific_cli_code_tensor_extent
 lea r10,[rel scientific_cli_message_tensor_extent]
 mov r11d,scientific_cli_message_tensor_extent_end-scientific_cli_message_tensor_extent
 jmp .write
.tensor_overflow:
 lea r8,[rel scientific_cli_code_tensor_overflow]
 mov r9d,scientific_cli_code_tensor_overflow_end-scientific_cli_code_tensor_overflow
 lea r10,[rel scientific_cli_message_tensor_overflow]
 mov r11d,scientific_cli_message_tensor_overflow_end-scientific_cli_message_tensor_overflow
 jmp .write
.tensor_limit:
 lea r8,[rel scientific_cli_code_tensor_limit]
 mov r9d,scientific_cli_code_tensor_limit_end-scientific_cli_code_tensor_limit
 lea r10,[rel scientific_cli_message_tensor_limit]
 mov r11d,scientific_cli_message_tensor_limit_end-scientific_cli_message_tensor_limit
 jmp .write
.tensor_copy:
 lea r8,[rel scientific_cli_code_tensor_copy]
 mov r9d,scientific_cli_code_tensor_copy_end-scientific_cli_code_tensor_copy
 lea r10,[rel scientific_cli_message_tensor_copy]
 mov r11d,scientific_cli_message_tensor_copy_end-scientific_cli_message_tensor_copy
 jmp .write
.tensor_deferred:
 lea r8,[rel scientific_cli_code_tensor_deferred]
 mov r9d,scientific_cli_code_tensor_deferred_end-scientific_cli_code_tensor_deferred
 lea r10,[rel scientific_cli_message_tensor_deferred]
 mov r11d,scientific_cli_message_tensor_deferred_end-scientific_cli_message_tensor_deferred
.write:
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],r8
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],r8
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],r9
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],r9
 mov [rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_OFFSET],r10
 mov [rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_LENGTH_OFFSET],r11
 ret

; Project existing semantic owners into the shared diagnostic record.
; Public identities remain the exact frozen RF27 identities; the catalog's
; TYPE/SECURITY phases are the authenticated machine-level representation of
; the finer ownership, effect and module phase-depth taxonomy.
cli_enrich_cli_semantic_diagnostic:
 cmp qword [rel text_char_unicode_e_bytes_cli_frontend_diagnostic],NEBOC_API_DIAG_UNKNOWN
 je .textual_unknown
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
 je .binding_flow
 mov rax,[rel cli_module_request+NEBOC_MODULE_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_MODULE_DIAG_PRIVATE_ACCESS
 je .module_private
 cmp rax,NEBOC_MODULE_DIAG_MISSING_EXPORT
 je .module_export
 mov rax,[rel text_char_unicode_e_bytes_cli_semantic+neboc_text_char_unicode_e_bytes_SEM_DIAGNOSTIC_OFFSET]
 cmp rax,NEBOC_DIAG_USE_AFTER_MOVE
 je .use_after_move
 cmp qword [rel effects_capabilities_e_politicas_cli_frontend_diagnostic],neboc_effects_capabilities_e_politicas_DIAG_SECURITY_driver_cli_linux_x86_64
 je .policy_security
 cmp qword [rel structs_enums_variants_e_tipos_do_programador_cli_vertical_request+neboc_structs_enums_variants_e_tipos_do_programador_VERTICAL_DIAGNOSTIC_OFFSET],4
 je .duplicate_field
 cmp qword [rel cli_parameters+NEBOC_PARAM_DIAGNOSTIC_OFFSET],NEBOC_DIAG_MISSING_ARGUMENT
 je .missing_argument
 cmp qword [rel cli_result+neboc_bindings_constantes_mutabilidade_e_definite_assignment_RESULT_DIAGNOSTIC_OFFSET],NEBOC_RESULT_DIAG_NON_EXHAUSTIVE
 je .result_non_exhaustive
 cmp qword [rel bindings_constantes_mutabilidade_e_definite_assignment_cli_vertical_request+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
 je .assignment_type
 cmp qword [rel literais_numericos_bases_e_representacao_cli_parse_request+neboc_literais_numericos_bases_e_representacao_PARSE_DIAGNOSTIC_OFFSET],NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
 je .assignment_type
 cmp qword [rel text_char_unicode_e_bytes_cli_vertical_request+neboc_text_char_unicode_e_bytes_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 je .bit_receiver
 cmp qword [rel seguranca_numerica_conversoes_e_overflow_cli_vertical_request+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 je .bit_receiver
 ret
.textual_unknown:
 lea r8,[rel cli_semantic_code_textual_unknown]
 mov r9d,cli_semantic_code_textual_unknown_end-cli_semantic_code_textual_unknown
 lea r10,[rel cli_semantic_message_textual_unknown]
 mov r11d,cli_semantic_message_textual_unknown_end-cli_semantic_message_textual_unknown
 jmp .write_type
.binding_flow:
 mov qword [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_NAME
 ret
.module_private:
 lea r8,[rel cli_semantic_code_module_private]
 mov r9d,cli_semantic_code_module_private_end-cli_semantic_code_module_private
 lea r10,[rel cli_semantic_message_module_private]
 mov r11d,cli_semantic_message_module_private_end-cli_semantic_message_module_private
 jmp .write_type
.module_export:
 lea r8,[rel cli_semantic_code_module_export]
 mov r9d,cli_semantic_code_module_export_end-cli_semantic_code_module_export
 lea r10,[rel cli_semantic_message_module_export]
 mov r11d,cli_semantic_message_module_export_end-cli_semantic_message_module_export
 jmp .write_type
.use_after_move:
 lea r8,[rel cli_semantic_code_use_after_move]
 mov r9d,cli_semantic_code_use_after_move_end-cli_semantic_code_use_after_move
 lea r10,[rel cli_semantic_message_use_after_move]
 mov r11d,cli_semantic_message_use_after_move_end-cli_semantic_message_use_after_move
 jmp .write_ownership
.policy_security:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_EFFECT
 mov qword [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_SECURITY
 ret
.duplicate_field:
 lea r8,[rel cli_semantic_code_duplicate_field]
 mov r9d,cli_semantic_code_duplicate_field_end-cli_semantic_code_duplicate_field
 lea r10,[rel cli_semantic_message_duplicate_field]
 mov r11d,cli_semantic_message_duplicate_field_end-cli_semantic_message_duplicate_field
 jmp .write_type
.missing_argument:
 lea r8,[rel cli_semantic_code_missing_argument]
 mov r9d,cli_semantic_code_missing_argument_end-cli_semantic_code_missing_argument
 lea r10,[rel cli_semantic_message_missing_argument]
 mov r11d,cli_semantic_message_missing_argument_end-cli_semantic_message_missing_argument
 jmp .write_type
.result_non_exhaustive:
 lea r8,[rel cli_semantic_code_result_non_exhaustive]
 mov r9d,cli_semantic_code_result_non_exhaustive_end-cli_semantic_code_result_non_exhaustive
 lea r10,[rel cli_semantic_message_result_non_exhaustive]
 mov r11d,cli_semantic_message_result_non_exhaustive_end-cli_semantic_message_result_non_exhaustive
 jmp .write_type
.assignment_type:
 lea r8,[rel cli_semantic_code_assignment_type]
 mov r9d,cli_semantic_code_assignment_type_end-cli_semantic_code_assignment_type
 lea r10,[rel cli_semantic_message_assignment_type]
 mov r11d,cli_semantic_message_assignment_type_end-cli_semantic_message_assignment_type
 jmp .write_type
.bit_receiver:
 lea r8,[rel cli_semantic_code_bit_receiver]
 mov r9d,cli_semantic_code_bit_receiver_end-cli_semantic_code_bit_receiver
 lea r10,[rel cli_semantic_message_bit_receiver]
 mov r11d,cli_semantic_message_bit_receiver_end-cli_semantic_message_bit_receiver
.write_type:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_TYPE
 mov qword [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_TYPE
 jmp .write
.write_ownership:
 mov qword [rbx+NEBOC_DIAGNOSTIC_CATEGORY_OFFSET],NEBOC_DIAGNOSTIC_CATEGORY_OWNERSHIP
 mov qword [rbx+NEBOC_DIAGNOSTIC_PHASE_OFFSET],NEBOC_DIAGNOSTIC_PHASE_TYPE
.write:
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET],r8
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_OFFSET],r8
 mov [rbx+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET],r9
 mov [rbx+NEBOC_DIAGNOSTIC_MESSAGE_KEY_LENGTH_OFFSET],r9
 mov [rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_OFFSET],r10
 mov [rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_LENGTH_OFFSET],r11
 ret

; RAX diagnostic id, RDI error token -> RAX id, RDI token, ECX selected.
cli_diag_select_parser_owner:
 test rax,rax
 jz .no
 cmp rax,NEBOC_PARSE_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 je .control_pair
 cmp rax,NEBOC_PARSE_DIAG_CONTROL_HEADER_RPAREN_REQUIRED
 je .control_delimiter
 cmp rax,NEBOC_DIAG_PARSE_EXPECTED_TOKEN
 je .yes
 cmp rax,NEBOC_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 je .yes
 cmp rax,NEBOC_DIAG_PARSE_DUPLICATE_START
 je .entrypoint_duplicate
 cmp rax,NEBOC_DIAG_PARSE_MISSING_START
 je .entrypoint_missing
 cmp rax,NEBOC_DIAG_PARSE_DUPLICATE_START
 jb .no
 cmp rax,NEBOC_DIAG_PARSE_UNEXPECTED_TOKEN
 jbe .yes
 cmp rax,NEBOC_DIAG_PARSE_NONASSOCIATIVE_CHAIN
 je .yes
 cmp rax,NEBOC_DIAG_NESTED_CONTEXT
 je .yes
 cmp rax,NEBOC_DIAG_NESTED_CAPACITY
 jne .no
.yes:
 mov ecx,1
 ret
.control_pair:
 mov eax,NEBOC_DIAG_CONTROL_HEADER_PARENS_REQUIRED
 jmp .yes
.control_delimiter:
 mov eax,NEBOC_DIAG_CONTROL_HEADER_DELIMITER
 jmp .yes
.entrypoint_duplicate:
 mov eax,NEBOC_DIAG_ENTRYPOINT_DUPLICATE
 jmp .yes
.entrypoint_missing:
 mov eax,NEBOC_DIAG_ENTRYPOINT_MISSING
 jmp .yes
.no:
 xor ecx,ecx
 ret

; Add the frozen C03-F03 entrypoint note/related-span projection to the CLI's
; canonical diagnostic.  Parser ownership already selected the later duplicate
; token as primary; the AST supplies the first declaration's identity span.
cli_enrich_entrypoint_diagnostic:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov rbx,rdi
 mov rax,[rbx+NEBOC_DIAGNOSTIC_CODE_OFFSET]
 cmp rax,NEBOC_DIAG_ENTRYPOINT_MISSING
 je .missing
 cmp rax,NEBOC_DIAG_ENTRYPOINT_DUPLICATE
 je .duplicate
 cmp rax,NEBOC_DIAG_ENTRYPOINT_INVALID_SIGNATURE
 je .invalid_signature
 cmp rax,NEBOC_DIAG_ENTRYPOINT_AMBIGUOUS
 je .ambiguous
 cmp rax,NEBOC_DIAG_ENTRYPOINT_FORBIDDEN_FOR_TARGET
 je .forbidden
 jmp .done
.missing:
 lea r12,[rel cli_entrypoint_note_missing]
 mov r13d,cli_entrypoint_note_missing_end-cli_entrypoint_note_missing
 jmp .note
.invalid_signature:
 lea r12,[rel cli_entrypoint_note_invalid]
 mov r13d,cli_entrypoint_note_invalid_end-cli_entrypoint_note_invalid
 jmp .note
.ambiguous:
 lea r12,[rel cli_entrypoint_note_ambiguous]
 mov r13d,cli_entrypoint_note_ambiguous_end-cli_entrypoint_note_ambiguous
 jmp .note
.forbidden:
 lea r12,[rel cli_entrypoint_note_forbidden]
 mov r13d,cli_entrypoint_note_forbidden_end-cli_entrypoint_note_forbidden
 jmp .note
.duplicate:
 lea r12,[rel cli_entrypoint_note_duplicate]
 mov r13d,cli_entrypoint_note_duplicate_end-cli_entrypoint_note_duplicate
 mov rsi,[rel cli_parser_request+NEBOC_PARSER_ROOT_ID_OFFSET]
 test rsi,rsi
 jz .note
 lea rdi,[rel cli_ast_builder]
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .note
 mov r14,[rsp]
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .note
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_first_start:
 test rsi,rsi
 jz .note
 lea rdi,[rel cli_ast_builder]
 lea rdx,[rsp]
 call neboc_ast_builder_node
 test eax,eax
 jnz .note
 mov r14,[rsp]
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .first_start
 mov rsi,[r14+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_first_start
.first_start:
 mov rax,[r14+NEBOC_AST_NODE_SOURCE_ID_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_ID_OFFSET],rax
 mov rax,[r14+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET],rax
 add rax,5
 mov rcx,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,rcx
 cmova rax,rcx
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_END_OFFSET],rax
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_SOURCE_LENGTH_OFFSET],rcx
 lea rax,[rel cli_entrypoint_label_duplicate]
 mov [rbx+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_OFFSET],rax
 mov qword [rbx+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_LENGTH_OFFSET],cli_entrypoint_label_duplicate_end-cli_entrypoint_label_duplicate
 or qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
.note:
 mov [rbx+NEBOC_DIAGNOSTIC_NOTE_OFFSET],r12
 mov [rbx+NEBOC_DIAGNOSTIC_NOTE_LENGTH_OFFSET],r13
 or qword [rbx+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; token index -> RAX start, RDX end, ECX found.
cli_diag_span_from_token:
 test qword [rel cli_array_range+NEBOC_AR_FOR_FLAGS_OFFSET],NEBOC_AR_FOR_FLAG_GENERAL_BODY
 jz .original_tokens
 cmp rdi,[rel cli_general_token_count]
 jae .none
 mov rax,rdi
 imul rax,NEBOC_TOKEN_SIZE
 lea r8,[rel cli_general_tokens]
 jmp .token_ready
.original_tokens:
 cmp rdi,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 jae .none
 mov rax,rdi
 imul rax,NEBOC_TOKEN_SIZE
 lea r8,[rel cli_tokens]
.token_ready:
 add r8,rax
 mov rax,[r8+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[r8+NEBOC_TOKEN_END_OFFSET]
 mov ecx,1
 ret
.none:
 xor eax,eax
 xor edx,edx
 xor ecx,ecx
 ret

cli_emit_canonical_diagnostic:
 mov rax,[rel cli_message_format]
 cmp rax,3
 jb cli_emit_canonical_human
 sub rsp,8
 lea rax,[rel cli_diag_output]
 mov [rel cli_diag_writer+NEBOC_WRITER_BYTES_OFFSET],rax
 mov qword [rel cli_diag_writer+NEBOC_WRITER_CAPACITY_OFFSET],NEBOC_MACHINE_MAX_OUTPUT
 mov qword [rel cli_diag_writer+NEBOC_WRITER_LENGTH_OFFSET],0
 lea rdi,[rel cli_canonical_diagnostic]
 mov esi,NEBOC_MACHINE_SCHEMA_V1
 lea rdx,[rel cli_diag_writer]
 cmp qword [rel cli_message_format],3
 je .json
 cmp qword [rel cli_message_format],4
 je .json_lines
 call neboc_diagnostic_encoder_sarif
 jmp .encoded
.json:
 call neboc_diagnostic_encoder_json
 jmp .encoded
.json_lines:
 call neboc_diagnostic_encoder_json_lines
.encoded:
 test eax,eax
 jnz .done
 lea rdi,[rel cli_diag_output]
 mov rsi,[rel cli_diag_writer+NEBOC_WRITER_LENGTH_OFFSET]
 call cli_write_stderr_raw
 xor eax,eax
.done:
 add rsp,8
 ret

; Emit the exact zero-width insertion edits already carried by the canonical
; diagnostic. The byte offsets and replacement bytes are identical to the
; JSON/JSONL/SARIF payloads; source application remains explicit.
cli_emit_exact_control_fixits:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r14,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_ARGUMENT_COUNT_OFFSET]
 xor r13d,r13d
.loop:
 cmp r13,r14
 jae .done
 mov rax,r13
 imul rax,NEBOC_DIAGNOSTIC_ARGUMENT_SIZE
 lea r12,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_ARGUMENTS_OFFSET]
 add r12,rax
 lea rdi,[rel cli_exact_fix_prefix]
 mov esi,cli_exact_fix_prefix_len
 call cli_write_stderr_raw
 mov rdi,[r12+NEBOC_DIAGNOSTIC_ARGUMENT_DATA_OFFSET]
 mov rsi,[r12+NEBOC_DIAGNOSTIC_ARGUMENT_LENGTH_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_exact_fix_offset]
 mov esi,cli_exact_fix_offset_len
 call cli_write_stderr_raw
 mov rdi,[r12+NEBOC_DIAGNOSTIC_ARGUMENT_VALUE_OFFSET]
 call cli_write_u64_stderr
 lea rdi,[rel cli_diag_human_newline]
 mov esi,1
 call cli_write_stderr_raw
 inc r13
 jmp .loop
.done:
 xor eax,eax
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

cli_emit_canonical_human:
 push rbx
 push r12
 push r13
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_cstr_length
 mov rsi,rax
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_separator]
 mov esi,1
 call cli_write_stderr_raw
 mov rdi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_PRIMARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call cli_diag_line_column
 mov r12,rax
 mov r13,rdx
 mov rdi,r12
 call cli_write_u64_stderr
 lea rdi,[rel cli_diag_human_separator]
 mov esi,1
 call cli_write_stderr_raw
 mov rdi,r13
 call cli_write_u64_stderr
 lea rdi,[rel cli_diag_human_error]
 mov esi,cli_diag_human_error_len
 call cli_write_stderr_raw
 mov rdi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_PUBLIC_CODE_OFFSET]
 mov rsi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_PUBLIC_CODE_LENGTH_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_message]
 mov esi,2
 call cli_write_stderr_raw
 mov rdi,[rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_OFFSET]
 mov rsi,[rel cli_diag_catalog_entry+NEBOC_DIAG_ENTRY_MESSAGE_LENGTH_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_newline]
 mov esi,1
 call cli_write_stderr_raw
 test qword [rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_SECONDARY
 jz .note
 lea rdi,[rel cli_diag_human_related]
 mov esi,cli_diag_human_related_len
 call cli_write_stderr_raw
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_cstr_length
 mov rsi,rax
 mov rdi,[rel cli_state+NEBOC_CLI_STATE_INPUT_PTR_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_separator]
 mov esi,1
 call cli_write_stderr_raw
 mov rdi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_SECONDARY_SPAN_OFFSET+NEBOC_SOURCE_SPAN_START_OFFSET]
 call cli_diag_line_column
 mov r12,rax
 mov r13,rdx
 mov rdi,r12
 call cli_write_u64_stderr
 lea rdi,[rel cli_diag_human_separator]
 mov esi,1
 call cli_write_stderr_raw
 mov rdi,r13
 call cli_write_u64_stderr
 lea rdi,[rel cli_diag_human_message]
 mov esi,2
 call cli_write_stderr_raw
 mov rdi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_OFFSET]
 mov rsi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_SECONDARY_LABEL_LENGTH_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_newline]
 mov esi,1
 call cli_write_stderr_raw
.note:
 test qword [rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_FLAGS_OFFSET],NEBOC_DIAGNOSTIC_FLAG_HAS_NOTE
 jz .done
 lea rdi,[rel cli_diag_human_note]
 mov esi,cli_diag_human_note_len
 call cli_write_stderr_raw
 mov rdi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_NOTE_OFFSET]
 mov rsi,[rel cli_canonical_diagnostic+NEBOC_DIAGNOSTIC_NOTE_LENGTH_OFFSET]
 call cli_write_stderr_raw
 lea rdi,[rel cli_diag_human_newline]
 mov esi,1
 call cli_write_stderr_raw
.done:
 xor eax,eax
 pop r13
 pop r12
 pop rbx
 ret

; byte offset -> 1-based Unicode code-point line/column, CRLF aware.
cli_diag_line_column:
 mov r8,rdi
 lea r9,[rel cli_source]
 xor ecx,ecx
 mov eax,1
 mov edx,1
.scan:
 cmp rcx,r8
 jae .done
 movzx r10d,byte [r9+rcx]
 cmp r10b,13
 je .cr
 cmp r10b,10
 je .lf
 mov r11d,r10d
 and r11d,0c0h
 cmp r11d,080h
 je .next
 inc rdx
.next:
 inc rcx
 jmp .scan
.cr:
 inc rax
 mov edx,1
 inc rcx
 cmp rcx,r8
 jae .scan
 cmp byte [r9+rcx],10
 jne .scan
 inc rcx
 jmp .scan
.lf:
 inc rax
 mov edx,1
 inc rcx
 jmp .scan
.done:
 ret

cli_cstr_length:
 xor eax,eax
.loop:
 cmp byte [rdi+rax],0
 je .done
 inc rax
 jmp .loop
.done:
 ret

cli_write_u64_stderr:
 sub rsp,40
 mov rax,rdi
 lea rsi,[rsp+40]
 xor ecx,ecx
 test rax,rax
 jnz .digits
 dec rsi
 mov byte [rsi],'0'
 mov ecx,1
 jmp .emit
.digits:
 mov r8d,10
.digit_loop:
 xor edx,edx
 div r8
 add dl,'0'
 dec rsi
 mov [rsi],dl
 inc ecx
 test rax,rax
 jnz .digit_loop
.emit:
 mov rdi,rsi
 mov esi,ecx
 call cli_write_stderr_raw
 add rsp,40
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
