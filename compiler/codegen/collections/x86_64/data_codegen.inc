; Part of the shared typed call classifier. Source Column values preserve the
; element dtype and explicit missing state, using the canonical data owners.
.data_constructor:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_data_Column]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .stream_constructor
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR
 jnz .column_from
 AC_MATCH ac_from,4,.column_from
 jmp .invalid
.column_from:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov qword [rsp],0
 mov qword [rsp+24],FCG_TYPE_NATIVE_COLUMN_INT
 mov qword [rsp+32],300
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .column_from_list
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],32
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.column_element:
 test r15,r15
 jz .ok
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 je .column_element_next
 cmp rax,FCG_TYPE_OPTION_INT
 jne .invalid
.column_element_next:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .column_element
.column_from_list:
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_LIST_INT
 jne .invalid
 mov qword [rsp+32],301
 jmp .ok
.data_methods:
 mov [rsp+40],rax
 cmp rax,FCG_TYPE_NATIVE_TABLE_GROUPS_INT
 je .table_group_methods
 cmp rax,FCG_TYPE_NATIVE_DATASET_ROWS_INT
 je .dataset_rows_methods
 cmp rax,FCG_TYPE_OPTION_ROW_INT
 je .option_row_methods
 cmp rax,FCG_TYPE_NATIVE_DATASET_SCAN_INT
 je .dataset_scan_methods
 cmp rax,FCG_TYPE_OPTION_TABLE_INT
 je .option_table_methods
 cmp rax,FCG_TYPE_NATIVE_DATASET_INT
 je .dataset_methods
 cmp rax,FCG_TYPE_NATIVE_TABLE_INT
 je .table_methods
 cmp rax,FCG_TYPE_NATIVE_ROW_TUPLE_INT
 je .row_tuple_methods
 cmp rax,FCG_TYPE_NATIVE_ROW_INT
 je .row_methods
 cmp rax,FCG_TYPE_NATIVE_SCHEMA_INT
 je .schema_methods
 cmp rax,FCG_TYPE_NATIVE_SCHEMA_FIELD
 je .schema_field_methods
 cmp rax,FCG_TYPE_NATIVE_BATCH_STREAM_INT
 je .batch_stream_methods
 cmp rax,FCG_TYPE_OPTION_LIST_INT
 je .option_list_methods
 cmp rax,FCG_TYPE_NATIVE_STREAM_INT
 je .stream_methods
 cmp rax,FCG_TYPE_NATIVE_EVENT_INT
 je .event_methods
 cmp rax,FCG_TYPE_NATIVE_FLOW_INT
 je .flow_methods
 cmp rax,FCG_TYPE_OPTION_UINT
 je .option_uint_methods
 cmp rax,FCG_TYPE_NATIVE_COLUMN_INT
 je .column_methods
 cmp rax,FCG_TYPE_NATIVE_COLUMN_UINT
 jne .no
.column_methods:
 AC_MATCH ac_data_cast,4,.column_cast
 AC_MATCH ac_get,3,.column_get
 AC_MATCH ac_data_countMissing,12,.column_missing_count
 AC_MATCH ac_data_isMissing,9,.column_is_missing
 AC_MATCH ac_data_dropMissing,11,.column_drop_missing
 AC_MATCH ac_data_coalesce,8,.column_coalesce
 cmp qword [rsp+40],FCG_TYPE_NATIVE_COLUMN_INT
 jne .invalid
 AC_MATCH ac_data_sum,3,.column_sum
 AC_MATCH ac_data_min,3,.column_min
 AC_MATCH ac_data_max,3,.column_max
 AC_MATCH ac_data_fillMissing,11,.column_fill_missing
 jmp .invalid
.column_cast:
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_METHOD
 jz .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .invalid
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov r15,rsi
 lea rdx,[rel ac_data_UInt]
 mov ecx,4
 mov rdi,rbx
 call fcg_token_matches_literal
 test eax,eax
 jz .column_cast_int
 mov qword [rsp+32],308
 mov qword [rsp+24],FCG_TYPE_NATIVE_COLUMN_UINT
 jmp .ok
.column_cast_int:
 mov rdi,rbx
 mov rsi,r15
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov qword [rsp+32],309
 mov qword [rsp+24],FCG_TYPE_NATIVE_COLUMN_INT
 jmp .ok
.column_sum:
 mov qword [rsp+32],310
 jmp .seq_int_query
.column_min:
 mov qword [rsp+32],311
 jmp .seq_int_query
.column_max:
 mov qword [rsp+32],312
 jmp .seq_int_query
.column_missing_count:
 mov qword [rsp+32],313
 jmp .seq_int_query
.column_get:
 mov qword [rsp+32],314
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 cmp qword [rsp+40],FCG_TYPE_NATIVE_COLUMN_UINT
 jne .column_get_typed
 mov qword [rsp+24],FCG_TYPE_OPTION_UINT
.column_get_typed:
 mov r15d,1
 jmp .int_arguments
.column_is_missing:
 mov qword [rsp+32],315
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 mov r15d,1
 jmp .int_arguments
.column_fill_missing:
 mov qword [rsp+32],316
 jmp .seq_one_void
.column_drop_missing:
 mov qword [rsp+32],317
 mov rax,[rsp+40]
 mov [rsp+24],rax
 jmp .ownership_arity
.column_coalesce:
 mov qword [rsp+32],318
 mov rax,[rsp+40]
 mov [rsp+24],rax
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+40]
 jne .invalid
 jmp .ok
.option_uint_methods:
 AC_MATCH ac_is_some,6,.option_uint_some
 AC_MATCH ac_is_none,6,.option_uint_none
 AC_MATCH ac_expect,6,.option_uint_expect
 jmp .invalid
.option_uint_some:
 mov qword [rsp+32],332
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_uint_none:
 mov qword [rsp+32],333
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_uint_expect:
 mov qword [rsp+32],334
 mov qword [rsp+24],FCG_TYPE_NATIVE_UINT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 jmp .ok

.stream_constructor:
%macro DATA_CONSTRUCTOR 4
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jz %%next
 mov qword [rsp+24],%3
 mov qword [rsp+32],%4
 jmp .stream_element_type
%%next:
%endmacro
 DATA_CONSTRUCTOR ac_data_Stream,6,FCG_TYPE_NATIVE_STREAM_INT,350
 DATA_CONSTRUCTOR ac_data_Event,5,FCG_TYPE_NATIVE_EVENT_INT,352
 DATA_CONSTRUCTOR ac_data_Flow,4,FCG_TYPE_NATIVE_FLOW_INT,353
 jmp .no
%undef DATA_CONSTRUCTOR
.stream_element_type:
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov qword [rsp],0
 cmp qword [rsp+32],350
 je .stream_from_name
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR
 jz .invalid
 mov r15d,1
 jmp .int_arguments
.stream_from_name:
 AC_MATCH ac_from,4,.stream_from
 jmp .invalid
.stream_from:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .stream_from_list
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],64
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.stream_element:
 test r15,r15
 jz .ok
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .stream_element
.stream_from_list:
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_LIST_INT
 jne .invalid
 mov qword [rsp+32],351
 jmp .ok
.event_methods:
 AC_MATCH ac_rel_value,5,.event_value
 jmp .invalid
.event_value:
 mov qword [rsp+32],354
 jmp .seq_int_query
.flow_methods:
 AC_MATCH ac_rel_value,5,.flow_value
 jmp .invalid
.flow_value:
 mov qword [rsp+32],355
 jmp .seq_int_query
.stream_methods:
 AC_MATCH ac_data_batch,5,.stream_batch
 AC_MATCH ac_data_window,6,.stream_window
 AC_MATCH ac_map,3,.stream_map
 AC_MATCH ac_filter,6,.stream_filter
 AC_MATCH ac_data_sink,4,.stream_sink
 AC_MATCH ac_next,4,.stream_next
 jmp .invalid
.stream_map:
 mov qword [rsp+32],360
 mov qword [rsp+24],FCG_TYPE_NATIVE_STREAM_INT
 jmp .stream_callback
.stream_filter:
 mov qword [rsp+32],361
 mov qword [rsp+24],FCG_TYPE_NATIVE_STREAM_INT
 jmp .stream_callback
.stream_sink:
 mov qword [rsp+32],362
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
.stream_callback:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov rdx,[rsp+32]
 call fcg_data_callback_symbol
 test rax,rax
 jz .invalid
 jmp .ok
.stream_next:
 mov qword [rsp+32],363
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .ownership_arity
.stream_window:
 mov qword [rsp+32],370
 jmp .stream_grouped
.stream_batch:
 mov qword [rsp+32],364
.stream_grouped:
 mov qword [rsp+24],FCG_TYPE_NATIVE_BATCH_STREAM_INT
 mov r15d,1
 jmp .int_arguments
.batch_stream_methods:
 AC_MATCH ac_data_sink,4,.batch_stream_sink
 AC_MATCH ac_next,4,.batch_stream_next
 jmp .invalid
.batch_stream_sink:
 mov qword [rsp+32],369
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .stream_callback
.batch_stream_next:
 mov qword [rsp+32],365
 mov qword [rsp+24],FCG_TYPE_OPTION_LIST_INT
 jmp .ownership_arity
.option_list_methods:
 AC_MATCH ac_is_some,6,.option_list_some
 AC_MATCH ac_is_none,6,.option_list_none
 AC_MATCH ac_expect,6,.option_list_expect
 jmp .invalid
.option_list_some:
 mov qword [rsp+32],366
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_list_none:
 mov qword [rsp+32],367
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_list_expect:
 mov qword [rsp+32],368
 mov qword [rsp+24],FCG_TYPE_NATIVE_LIST_INT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 jmp .ok

; The existing ordered Tuple spelling supplies each field's name, type and
; nullability. Type references are validated here, never executed as values.
.schema_constructor:
 AC_MATCH ac_new,3,.schema_new
 jmp .invalid
.schema_new:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jb .capacity_invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],8
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.schema_field_type:
 test r15,r15
 jz .schema_typed
 mov rdi,rbx
 mov rsi,r15
 call fcg_schema_field_shape
 test eax,eax
 jz .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .schema_field_type
.schema_typed:
 mov qword [rsp],0
 mov qword [rsp+32],400
 mov qword [rsp+24],FCG_TYPE_NATIVE_SCHEMA_INT
 jmp .ok
.schema_methods:
 AC_MATCH ac_data_indexOf,7,.schema_index
 AC_MATCH ac_data_field,5,.schema_field_query
 jmp .invalid
.schema_index:
 mov qword [rsp+32],402
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .data_text_argument
.schema_field_query:
 mov qword [rsp+32],403
 mov qword [rsp+24],FCG_TYPE_NATIVE_SCHEMA_FIELD
.data_text_argument:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 jmp .ok
.schema_field_methods:
 AC_MATCH ac_length,6,.schema_field_length
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_projection_info
 test eax,eax
 jz .invalid
 cmp rdx,2
 ja .capacity_invalid
 lea rax,[rdx+410]
 mov [rsp+32],rax
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 cmp rdx,1
 je .ok
 mov qword [rsp+24],NEBOC_TYPE_ID_TEXT
 test rdx,rdx
 jz .ok
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ok
.schema_field_length:
 mov qword [rsp+32],413
 jmp .seq_int_query
.row_constructor:
 AC_MATCH ac_from,4,.row_from
 jmp .invalid
.row_from:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_SCHEMA_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],8
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.row_value_type:
 test r15,r15
 jz .row_typed
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 je .row_value_next
 cmp rax,FCG_TYPE_OPTION_INT
 jne .invalid
.row_value_next:
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .row_value_type
.row_typed:
 mov qword [rsp],0
 mov qword [rsp+32],420
 mov qword [rsp+24],FCG_TYPE_NATIVE_ROW_INT
 jmp .ok
.row_methods:
 AC_MATCH ac_get,3,.row_get
 AC_MATCH ac_data_project,7,.row_project
 AC_MATCH ac_data_toTuple,7,.row_to_tuple
 jmp .invalid
.row_get:
 mov qword [rsp+32],424
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .data_text_argument
.row_project:
 mov qword [rsp+32],425
 mov qword [rsp+24],FCG_TYPE_NATIVE_ROW_INT
.data_projection_names:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jb .capacity_invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],8
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.row_project_name:
 test r15,r15
 jz .row_project_typed
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .row_project_name
.row_project_typed:
 jmp .ok
.row_to_tuple:
 mov qword [rsp+32],428
 mov qword [rsp+24],FCG_TYPE_NATIVE_ROW_TUPLE_INT
 jmp .ownership_arity
.row_tuple_methods:
 AC_MATCH ac_length,6,.row_tuple_length
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_projection_info
 test eax,eax
 jz .invalid
 cmp rdx,7
 ja .capacity_invalid
 lea rax,[rdx+430]
 mov [rsp+32],rax
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .ok
.row_tuple_length:
 mov qword [rsp+32],438
 jmp .seq_int_query
.table_constructor:
 AC_MATCH ac_data_fromColumns,11,.table_from_columns
 jmp .invalid
.table_from_columns:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jb .capacity_invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],8
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.table_column_type:
 test r15,r15
 jz .table_typed
 mov rdi,rbx
 mov rsi,r15
 call fcg_table_column_shape
 test eax,eax
 jz .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .table_column_type
.table_typed:
 mov qword [rsp],0
 mov qword [rsp+32],450
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .ok
.table_methods:
 AC_MATCH ac_data_validate,8,.table_constraints
 AC_MATCH ac_data_invalidRows,11,.table_invalid_rows
 AC_MATCH ac_data_groupBy,7,.table_group_by
 AC_MATCH ac_data_join,4,.table_join
 AC_MATCH ac_data_select,6,.table_select
 AC_MATCH ac_data_sortBy,6,.table_sort
 AC_MATCH ac_filter,6,.table_filter
 AC_MATCH ac_data_rowCount,8,.table_rows
 AC_MATCH ac_data_columnCount,11,.table_columns
 jmp .invalid
.table_rows:
 mov qword [rsp+32],453
 jmp .seq_int_query
.table_columns:
 mov qword [rsp+32],454
 jmp .seq_int_query
.table_filter:
 mov qword [rsp+32],456
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .stream_callback
.table_sort:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .capacity_invalid
 mov rax,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp+32],457
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .data_text_argument
.table_select:
 mov qword [rsp+32],455
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .data_projection_names
.table_group_by:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov rax,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp+32],545
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_GROUPS_INT
 jmp .data_text_argument
.table_group_methods:
 AC_MATCH ac_length,6,.dataset_rows_length
 AC_MATCH ac_next,4,.dataset_scan_next
 AC_MATCH ac_data_sink,4,.dataset_scan_sink
 jmp .invalid
.table_join:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],3
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_TABLE_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov r15,rax
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov qword [rsp+32],550
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .ok
.table_constraints:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_SCHEMA_INT
 jne .invalid
 mov qword [rsp+32],560
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ok
.table_invalid_rows:
 mov qword [rsp+32],561
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .ownership_arity
.dataset_constructor:
 AC_MATCH ac_data_fromTables,10,.dataset_from_tables
 jmp .invalid
.dataset_from_tables:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jb .capacity_invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],8
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.dataset_table_type:
 test r15,r15
 jz .dataset_typed
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_TABLE_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .dataset_table_type
.dataset_typed:
 mov qword [rsp],0
 mov qword [rsp+32],500
 mov qword [rsp+24],FCG_TYPE_NATIVE_DATASET_INT
 jmp .ok
.dataset_methods:
 AC_MATCH ac_collect,7,.dataset_collect
 AC_MATCH ac_data_repartition,11,.dataset_repartition
 AC_MATCH ac_data_cache,5,.dataset_cache
 AC_MATCH ac_data_scan,4,.dataset_scan
 AC_MATCH ac_data_schema,6,.dataset_schema
 AC_MATCH ac_data_partitionCount,14,.dataset_partitions
 jmp .invalid
.dataset_schema:
 mov qword [rsp+32],503
 mov qword [rsp+24],FCG_TYPE_NATIVE_SCHEMA_INT
 jmp .ownership_arity
.dataset_collect:
 mov qword [rsp+32],520
 mov qword [rsp+24],FCG_TYPE_NATIVE_DATASET_ROWS_INT
 jmp .ownership_arity
.dataset_repartition:
 mov qword [rsp+32],535
 mov qword [rsp+24],FCG_TYPE_NATIVE_DATASET_INT
 mov r15d,1
 jmp .int_arguments
.dataset_cache:
 mov qword [rsp+32],536
 jmp .seq_one_void
.dataset_rows_methods:
 AC_MATCH ac_length,6,.dataset_rows_length
 AC_MATCH ac_at,2,.dataset_rows_at
 AC_MATCH ac_next,4,.dataset_rows_next
 jmp .invalid
.dataset_rows_length:
 mov qword [rsp+32],521
 jmp .seq_int_query
.dataset_rows_at:
 mov qword [rsp+32],522
 mov qword [rsp+24],FCG_TYPE_NATIVE_ROW_INT
 mov r15d,1
 jmp .int_arguments
.dataset_rows_next:
 mov qword [rsp+32],523
 mov qword [rsp+24],FCG_TYPE_OPTION_ROW_INT
 jmp .ownership_arity
.option_row_methods:
 AC_MATCH ac_is_some,6,.option_row_some
 AC_MATCH ac_is_none,6,.option_row_none
 AC_MATCH ac_expect,6,.option_row_expect
 jmp .invalid
.option_row_some:
 mov qword [rsp+32],512
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_row_none:
 mov qword [rsp+32],513
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_row_expect:
 mov qword [rsp+32],524
 mov qword [rsp+24],FCG_TYPE_NATIVE_ROW_INT
 jmp .data_text_argument
.dataset_partitions:
 mov qword [rsp+32],504
 jmp .seq_int_query
.dataset_scan:
 mov qword [rsp+32],510
 mov qword [rsp+24],FCG_TYPE_NATIVE_DATASET_SCAN_INT
 jmp .ownership_arity
.dataset_scan_methods:
 AC_MATCH ac_next,4,.dataset_scan_next
 AC_MATCH ac_data_sink,4,.dataset_scan_sink
 jmp .invalid
.dataset_scan_next:
 mov qword [rsp+32],511
 mov qword [rsp+24],FCG_TYPE_OPTION_TABLE_INT
 jmp .ownership_arity
.dataset_scan_sink:
 mov qword [rsp+32],515
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .stream_callback
.option_table_methods:
 AC_MATCH ac_is_some,6,.option_table_some
 AC_MATCH ac_is_none,6,.option_table_none
 AC_MATCH ac_expect,6,.option_table_expect
 jmp .invalid
.option_table_some:
 mov qword [rsp+32],512
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_table_none:
 mov qword [rsp+32],513
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_table_expect:
 mov qword [rsp+32],514
 mov qword [rsp+24],FCG_TYPE_NATIVE_TABLE_INT
 jmp .data_text_argument
