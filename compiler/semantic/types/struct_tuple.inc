%ifndef NEBOC_STRUCT_TUPLE_INC
%define NEBOC_STRUCT_TUPLE_INC 1

; OPTION-RESULT-NULL-EXTERNO-E-ERROS-TIPADOS-F02 allocation-free bounded named-product/Tuple vertical.
%define NEBOC_ST_SOURCE_OFFSET 0
%define NEBOC_ST_SOURCE_LENGTH_OFFSET 8
%define NEBOC_ST_TOKENS_OFFSET 16
%define NEBOC_ST_TOKEN_COUNT_OFFSET 24
%define NEBOC_ST_DECLS_OFFSET 32
%define NEBOC_ST_DECL_CAPACITY_OFFSET 40
%define NEBOC_ST_VALUES_OFFSET 48
%define NEBOC_ST_VALUE_CAPACITY_OFFSET 56
%define NEBOC_ST_BINDINGS_OFFSET 64
%define NEBOC_ST_BINDING_CAPACITY_OFFSET 72
%define NEBOC_ST_FOUND_OFFSET 80
%define NEBOC_ST_DIAGNOSTIC_OFFSET 88
%define NEBOC_ST_ERROR_TOKEN_OFFSET 96
%define NEBOC_ST_CURSOR_OFFSET 104
%define NEBOC_ST_DECL_COUNT_OFFSET 112
%define NEBOC_ST_VALUE_COUNT_OFFSET 120
%define NEBOC_ST_BINDING_COUNT_OFFSET 128
%define NEBOC_ST_CONSTRUCT_COUNT_OFFSET 136
%define NEBOC_ST_ACCESS_COUNT_OFFSET 144
%define NEBOC_ST_RESULT_TYPE_OFFSET 152
%define NEBOC_ST_RESULT_VALUE_OFFSET 160
%define NEBOC_ST_LAYOUT_SIZE_OFFSET 168
%define NEBOC_ST_LAYOUT_ALIGN_OFFSET 176
%define NEBOC_ST_DROP_COUNT_OFFSET 184
%define NEBOC_ST_CLEANUP_HASH_OFFSET 192
%define NEBOC_ST_SEMANTIC_HASH_OFFSET 200
%define NEBOC_ST_REQUEST_SIZE 208
%define NEBOC_ST_REQUEST_QWORDS 26

%define NEBOC_ST_MAX_DECLS 8
%define NEBOC_ST_MAX_FIELDS 8
%define NEBOC_ST_MAX_VALUES 32
%define NEBOC_ST_MAX_BINDINGS 16
%define NEBOC_ST_MAX_LAYOUT 1048576

; Declaration records contain only token indices and canonical scalar facts.
%define NEBOC_DECL_NAME_OFFSET 0
%define NEBOC_DECL_FIELD_COUNT_OFFSET 8
%define NEBOC_DECL_SIZE_OFFSET 16
%define NEBOC_DECL_ALIGN_OFFSET 24
%define NEBOC_DECL_DROP_COUNT_OFFSET 32
%define NEBOC_DECL_FIELD_TYPES_OFFSET 40
%define NEBOC_DECL_FIELD_NAMES_OFFSET 104
%define NEBOC_DECL_FIELD_OFFSETS_OFFSET 168
%define NEBOC_DECL_HASH_OFFSET 232
%define NEBOC_DECL_SIZE 240
%define NEBOC_DECL_QWORDS 30

; Value records represent immutable scalar/product values by pool indices.
%define NEBOC_VALUE_TYPE_OFFSET 0
%define NEBOC_VALUE_MEMBER_COUNT_OFFSET 8
%define NEBOC_VALUE_SIZE_OFFSET 16
%define NEBOC_VALUE_ALIGN_OFFSET 24
%define NEBOC_VALUE_DROP_COUNT_OFFSET 32
%define NEBOC_VALUE_MEMBER_TYPES_OFFSET 40
%define NEBOC_VALUE_MEMBERS_OFFSET 104
%define NEBOC_VALUE_SIZE 168
%define NEBOC_VALUE_QWORDS 21

%define NEBOC_BINDING_NAME_OFFSET 0
%define NEBOC_BINDING_VALUE_INDEX_OFFSET 8
%define NEBOC_BINDING_SIZE 16
%define NEBOC_BINDING_QWORDS 2

%define neboc_option_result_null_externo_e_erros_tipados_TYPE_INT_semantic_types_native_vertical 1
%define neboc_option_result_null_externo_e_erros_tipados_TYPE_BOOL_semantic_types_native_vertical 2
%define neboc_option_result_null_externo_e_erros_tipados_TYPE_CHAR_semantic_types_native_vertical 3
%define neboc_option_result_null_externo_e_erros_tipados_TYPE_TEXT_semantic_types_native_vertical 4
%define NEBOC_TYPE_STRUCT_BASE 0x100
%define NEBOC_TYPE_TUPLE_MASK 0x4000000000000000

; Contract IDs 001/003/005 were reserved by F01. F02 adds 013..017.
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_NONE_semantic_types_native_vertical 0
%define NEBOC_DIAG_RECURSIVE_LAYOUT 1
%define NEBOC_DIAG_INVALID_ALIGNMENT 2
%define NEBOC_DIAG_LAYOUT_OVERFLOW 3
%define NEBOC_DIAG_TUPLE_BOUNDS 5
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_DUPLICATE_FIELD 13
%define NEBOC_DIAG_WRONG_ARITY 14
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_TYPE_MISMATCH 15
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_UNKNOWN_FIELD 16
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_SYNTAX 17
%define neboc_option_result_null_externo_e_erros_tipados_DIAG_INTERNAL_codegen_aggregates_x86_64_native_vertical 99

%define neboc_option_result_null_externo_e_erros_tipados_LAYOUT_ID 0x5246323747303641

%endif
