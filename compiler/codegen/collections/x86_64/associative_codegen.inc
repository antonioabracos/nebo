; Typed associative source expressions share Program AST, lexical bindings,
; function frames and the generic return epilogue. Native storage/hash/mutation
; remain exclusively owned by runtime/collections/dict.asm and set.asm.
section .rodata
ac_rel_hasCycle: db 'hasCycle'
ac_rel_topologicalSort: db 'topologicalSort'
ac_rel_shortestPathUnweighted: db 'shortestPathUnweighted'
ac_rel_dijkstra: db 'dijkstra'
ac_rel_connectedComponents: db 'connectedComponents'
ac_rel_breadthFirst: db 'breadthFirst'
ac_rel_depthFirst: db 'depthFirst'
ac_rel_stopWhen: db 'stopWhen'
ac_rel_path: db 'path'
ac_data_Stream: db 'Stream'
ac_data_Event: db 'Event'
ac_data_Flow: db 'Flow'
ac_data_sink: db 'sink'
ac_data_batch: db 'batch'
ac_data_window: db 'window'
ac_data_Schema: db 'Schema'
ac_data_Row: db 'Row'
ac_data_Table: db 'Table'
ac_data_Dataset: db 'Dataset'
ac_data_fromTables: db 'fromTables'
ac_data_schema: db 'schema'
ac_data_partitionCount: db 'partitionCount'
ac_data_scan: db 'scan'
ac_data_repartition: db 'repartition'
ac_data_cache: db 'cache'
ac_data_groupBy: db 'groupBy'
ac_data_join: db 'join'
ac_data_validate: db 'validate'
ac_data_invalidRows: db 'invalidRows'
ac_data_fromColumns: db 'fromColumns'
ac_data_rowCount: db 'rowCount'
ac_data_columnCount: db 'columnCount'
ac_data_sortBy: db 'sortBy'
ac_data_select: db 'select'
ac_data_project: db 'project'
ac_data_toTuple: db 'toTuple'
ac_data_field: db 'field'
ac_data_indexOf: db 'indexOf'
ac_data_Column: db 'Column'
ac_data_sum: db 'sum'
ac_data_min: db 'min'
ac_data_max: db 'max'
ac_data_countMissing: db 'countMissing'
ac_data_isMissing: db 'isMissing'
ac_data_fillMissing: db 'fillMissing'
ac_data_dropMissing: db 'dropMissing'
ac_data_coalesce: db 'coalesce'
ac_data_cast: db 'cast'
ac_data_UInt: db 'UInt'
ac_rel_tree: db 'Tree'
ac_rel_node: db 'Node'
ac_rel_graph: db 'Graph'
ac_rel_root: db 'root'
ac_rel_addChild: db 'addChild'
ac_rel_removeSubtree: db 'removeSubtree'
ac_rel_parent: db 'parent'
ac_rel_children: db 'children'
ac_rel_height: db 'height'
ac_rel_value: db 'value'
ac_rel_id: db 'id'
ac_rel_replaceValue: db 'replaceValue'
ac_rel_degree: db 'degree'
ac_rel_lowestCommonAncestor: db 'lowestCommonAncestor'
ac_rel_preorder: db 'preorder'
ac_rel_postorder: db 'postorder'
ac_rel_directed: db 'directed'
ac_rel_undirected: db 'undirected'
ac_rel_addNode: db 'addNode'
ac_rel_addEdge: db 'addEdge'
ac_rel_removeNode: db 'removeNode'
ac_rel_removeEdge: db 'removeEdge'
ac_rel_neighbors: db 'neighbors'
ac_rel_arg3: db '    mov [r12+24], rax',10
ac_rel_arg3_len equ $-ac_rel_arg3
ac_dict: db 'Dict'
ac_set: db 'Set'
ac_new: db 'new'
ac_with_capacity: db 'withCapacity'
ac_length: db 'length'
ac_capacity: db 'capacity'
ac_insert: db 'insert'
ac_get: db 'get'
ac_contains: db 'containsKey'
ac_remove: db 'remove'
ac_clear: db 'clear'
ac_set_contains: db 'contains'
ac_is_some: db 'isSome'
ac_is_none: db 'isNone'
ac_unwrap_or: db 'unwrapOr'
ac_expect: db 'expect'
ac_move: db 'move'
ac_drop: db 'drop'
ac_is_moved: db 'isMoved'
ac_union: db 'union'
ac_intersection: db 'intersection'
ac_difference: db 'difference'
ac_subset: db 'isSubsetOf'
ac_reserve: db 'reserve'
ac_invariants: db 'validateInvariants'
ac_collisions: db 'collisionCount'
ac_max_probe: db 'maxProbeLength'
ac_release: db 'release'
ac_load_factor: db 'loadFactor'
ac_keys: db 'keys'
ac_values: db 'values'
ac_next: db 'next'
ac_entries: db 'entries'
ac_at: db 'at'
ac_hasher: db 'Hasher'
ac_int: db 'Int'
ac_write_bytes: db 'writeBytes'
ac_finish: db 'finish'
ac_equals: db 'equals'
ac_hash: db 'hash'
ac_hash_stable: db 'hashStable'
ac_reseed: db 'reseed'
ac_get_mutable: db 'getMutable'
ac_read: db 'read'
ac_write: db 'write'
ac_entry: db 'entry'
ac_sorted_entries: db 'toSortedEntries'
ac_iteration_order: db 'iterationOrder'
ac_deterministic: db 'deterministic'
ac_randomized: db 'randomized'
ac_retain: db 'retain'
ac_list: db 'List'
ac_from: db 'from'
ac_seq_append: db '    mov rdx, rax',10,'    lea rsi, [rbp - '
ac_seq_append_len equ $-ac_seq_append
ac_seq_append_end: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 113',10,'    call nebo_associative_call',10
ac_seq_append_end_len equ $-ac_seq_append_end
ac_data_append_stream: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 380',10,'    call nebo_associative_call',10
ac_data_append_stream_len equ $-ac_data_append_stream
ac_data_append_int: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 330',10,'    call nebo_associative_call',10
ac_data_append_int_len equ $-ac_data_append_int
ac_data_append_option: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 331',10,'    call nebo_associative_call',10
ac_data_append_option_len equ $-ac_data_append_option
ac_row_append_int: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 421',10,'    call nebo_associative_call',10
ac_row_append_int_len equ $-ac_row_append_int
ac_row_append_option: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 422',10,'    call nebo_associative_call',10
ac_row_append_option_len equ $-ac_row_append_option
ac_row_finish: db '    mov rsi, rax',10,'    xor edx, edx',10,'    xor ecx, ecx',10,'    mov r8, rax',10,'    mov edi, 423',10,'    call nebo_associative_call',10
ac_row_finish_len equ $-ac_row_finish
ac_row_project_append: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 426',10,'    call nebo_associative_call',10
ac_row_project_append_len equ $-ac_row_project_append
ac_row_project_finish: db '    mov rsi, rax',10,'    xor edx, edx',10,'    xor ecx, ecx',10,'    mov r8, rax',10,'    mov edi, 427',10,'    call nebo_associative_call',10
ac_row_project_finish_len equ $-ac_row_project_finish
ac_schema_name_save: db '    sub rsp, 16',10,'    mov [rsp], rax',10
ac_schema_name_save_len equ $-ac_schema_name_save
ac_schema_field_args: db '    mov rcx, rax',10,'    mov rdx, [rsp]',10,'    add rsp, 16',10,'    lea rsi, [rbp - '
ac_schema_field_args_len equ $-ac_schema_field_args
ac_schema_field_append: db ']',10,'    xor r8d, r8d',10,'    mov edi, 401',10,'    call nebo_associative_call',10
ac_schema_field_append_len equ $-ac_schema_field_append
ac_table_column_append: db ']',10,'    xor r8d, r8d',10,'    mov edi, 451',10,'    call nebo_associative_call',10
ac_table_column_append_len equ $-ac_table_column_append
ac_table_finish: db '    mov rsi, rax',10,'    xor edx, edx',10,'    xor ecx, ecx',10,'    mov r8, rax',10,'    mov edi, 452',10,'    call nebo_associative_call',10
ac_table_finish_len equ $-ac_table_finish
ac_table_select_append: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 459',10,'    call nebo_associative_call',10
ac_table_select_append_len equ $-ac_table_select_append
ac_table_select_finish: db '    mov rsi, rax',10,'    xor edx, edx',10,'    xor ecx, ecx',10,'    mov r8, rax',10,'    mov edi, 460',10,'    call nebo_associative_call',10
ac_table_select_finish_len equ $-ac_table_select_finish
ac_dataset_append: db ']',10,'    xor ecx, ecx',10,'    xor r8d, r8d',10,'    mov edi, 501',10,'    call nebo_associative_call',10
ac_dataset_append_len equ $-ac_dataset_append
ac_dataset_finish: db '    mov rsi, rax',10,'    xor edx, edx',10,'    xor ecx, ecx',10,'    mov r8, rax',10,'    mov edi, 502',10,'    call nebo_associative_call',10
ac_dataset_finish_len equ $-ac_dataset_finish
ac_seq_result: db '    lea rax, [rbp - '
ac_seq_result_len equ $-ac_seq_result
ac_stack: db 'Stack'
ac_queue: db 'Queue'
ac_deque: db 'Deque'
ac_push: db 'push'
ac_pop: db 'pop'
ac_peek: db 'peek'
ac_swap_remove: db 'swapRemove'
ac_enqueue: db 'enqueue'
ac_dequeue: db 'dequeue'
ac_push_front: db 'pushFront'
ac_push_back: db 'pushBack'
ac_pop_front: db 'popFront'
ac_pop_back: db 'popBack'
ac_find: db 'find'
ac_map: db 'map'
ac_filter: db 'filter'
ac_sort: db 'sort'
ac_deduplicate: db 'deduplicate'
ac_iterator: db 'iterator'
ac_iterator_mutable: db 'iteratorMutable'
ac_take: db 'take'
ac_skip: db 'skip'
ac_collect: db 'collect'
ac_enumerate: db 'enumerate'
ac_seq_cb_pointer: db '    lea rax, [rel .nebo_seq_callback_'
ac_seq_cb_pointer_len equ $-ac_seq_cb_pointer
ac_seq_cb_skip: db '    jmp .nebo_seq_callback_end_'
ac_seq_cb_skip_len equ $-ac_seq_cb_skip
ac_seq_cb_label: db 10,'.nebo_seq_callback_'
ac_seq_cb_label_len equ $-ac_seq_cb_label
ac_seq_cb_unary: db ':',10,'    push rbx',10,'    mov rbx, rsi',10,'    mov rdi, [rdi]',10,'    call nebo_fn_'
ac_seq_cb_unary_len equ $-ac_seq_cb_unary
ac_seq_cb_predicate: db ':',10,'    push rbx',10,'    mov rbx, rdx',10,'    mov rdi, [rdi]',10,'    call nebo_fn_'
ac_seq_cb_predicate_len equ $-ac_seq_cb_predicate
ac_seq_cb_binary: db ':',10,'    push rbx',10,'    mov rbx, rdx',10,'    mov rdi, [rdi]',10,'    mov rsi, [rsi]',10,'    call nebo_fn_'
ac_seq_cb_binary_len equ $-ac_seq_cb_binary
ac_seq_cb_tail: db 10,'    mov [rbx], rax',10,'    xor eax, eax',10,'    pop rbx',10,'    ret',10,'.nebo_seq_callback_end_'
ac_seq_cb_tail_len equ $-ac_seq_cb_tail
; Source Ordering uses Less/Equal/Greater tags 0/1/2. The native List
; comparator ABI uses signed -1/0/+1, so its typed bridge converts the encoding.
ac_seq_cb_ordering: db 10,'    sub rax, 1'
ac_seq_cb_ordering_len equ $-ac_seq_cb_ordering
ac_seq_cb_end: db ':',10
ac_seq_cb_end_len equ $-ac_seq_cb_end
ac_function_pointer: db '    lea rax, [rel nebo_fn_'
ac_function_pointer_len equ $-ac_function_pointer
ac_function_pointer_end: db ']',10
ac_function_pointer_end_len equ $-ac_function_pointer_end
; A child expression may retain an owned result below RSP. Argument locations
; therefore belong to a linked, stable frame, not offsets from the last child.
ac_operand_frame:
 db '    mov r11, rsp',10,'    sub r11, 64',10,'    jc nebo_runtime_trap_stack_budget',10
 db '    cmp r11, [rel nebo_runtime_owned_stack_floor]',10,'    jb nebo_runtime_trap_stack_budget',10
 db '    mov [r11+32], r12',10,'    mov r12, r11',10,'    mov rsp, r11',10,'    mov qword [r12+24], 0',10
ac_operand_frame_len equ $-ac_operand_frame
ac_save: db '    mov [r12+'
ac_save_len equ $-ac_save
ac_save_end: db '], rax',10
ac_save_end_len equ $-ac_save_end
ac_frame: db '    lea r8, [rbp - '
ac_frame_len equ $-ac_frame
ac_args: db ']',10,'    mov rsi, [r12]',10,'    mov rdx, [r12+8]',10,'    mov rcx, [r12+16]',10,'    mov r9, [r12+24]',10,'    mov edi, '
ac_args_len equ $-ac_args
ac_call: db 10,'%ifndef NEBO_ASSOCIATIVE_CALL_DECLARED',10,'%define NEBO_ASSOCIATIVE_CALL_DECLARED 1',10,'extern nebo_associative_call',10,'%endif',10,'    call nebo_associative_call',10,'    movq xmm0, rax',10
ac_call_len equ $-ac_call
; Native results reside in the caller's canonical owner slots. Operand-owned
; storage is released only after the native owner has consumed all arguments.
ac_operands_release: db '    mov rsp, r12',10,'    mov r12, [r12+32]',10,'    add rsp, 64',10
ac_operands_release_len equ $-ac_operands_release
ac_zero: db '    xor eax, eax',10
ac_zero_len equ $-ac_zero
ac_lifecycle_frame: db '    sub rsp, 16',10,'    mov [rsp], rax',10,'    movq [rsp+8], xmm0',10,'    lea rsi, [rbp - '
ac_lifecycle_frame_len equ $-ac_lifecycle_frame
ac_lifecycle_op: db ']',10,'    mov edi, '
ac_lifecycle_op_len equ $-ac_lifecycle_op
ac_lifecycle_restore: db '    mov rax, [rsp]',10,'    movq xmm0, [rsp+8]',10,'    add rsp, 16',10
ac_lifecycle_restore_len equ $-ac_lifecycle_restore

%macro AC_MATCH 3
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro
section .text
; Exact private types produced by native typed plans can occupy an immutable
; local in any function. They use the same frame and lifecycle owners as start.
fcg_native_type_is_material:
%macro NATIVE_TYPE_RANGE 2
 cmp rdi,%1
 jb %%next
 cmp rdi,%2
 jbe .yes
%%next:
%endmacro
 NATIVE_TYPE_RANGE FCG_TYPE_CANCEL_TOKEN,FCG_TYPE_ATOMIC_EXCHANGE
 NATIVE_TYPE_RANGE FCG_TAGGED_OPTION_BASE+1,FCG_TAGGED_RESULT_BASE+8
 NATIVE_TYPE_RANGE FCG_TYPE_RANDOM_STATE,FCG_TYPE_RANDOM_STATE
 NATIVE_TYPE_RANGE FCG_TYPE_MATRIX_INT,FCG_TYPE_MATRIX_QR_TUPLE
 NATIVE_TYPE_RANGE FCG_TYPE_TENSOR_BOOL,FCG_TYPE_TENSOR_PARTS
 NATIVE_TYPE_RANGE FCG_TYPE_FORMAT_TEMPLATE,FCG_TYPE_FORMAT_PARSE_RESULT
 NATIVE_TYPE_RANGE FCG_TYPE_CONSOLE_HANDLE,FCG_TYPE_COLOR_RESULT
 NATIVE_TYPE_RANGE FCG_TYPE_PATH,FCG_TYPE_PATH
 NATIVE_TYPE_RANGE FCG_TYPE_REGEX,FCG_TYPE_REGEX
 NATIVE_TYPE_RANGE FCG_TYPE_RENDER_PLAN,FCG_TYPE_RENDER_PLAN
 NATIVE_TYPE_RANGE FCG_TYPE_VECTOR_INT_BASE,FCG_TYPE_VECTOR_INT_BASE+64
 NATIVE_TYPE_RANGE FCG_TYPE_VECTOR_FLOAT_BASE,FCG_TYPE_VECTOR_FLOAT_BASE+64
 NATIVE_TYPE_RANGE FCG_TYPE_DICT_INT_INT,FCG_TYPE_SORTED_INT_ENTRIES
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_LIST_INT,FCG_TYPE_NATIVE_ITERATOR_INT
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_TREE_INT,FCG_TYPE_OPTION_NODE_SEQUENCE
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_COLUMN_INT,FCG_TYPE_NATIVE_UINT
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_STREAM_INT,FCG_TYPE_OPTION_LIST_INT
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_SCHEMA_INT,FCG_TYPE_NATIVE_SCHEMA_FIELD
 NATIVE_TYPE_RANGE FCG_TYPE_NATIVE_ROW_INT,FCG_TYPE_NATIVE_TABLE_GROUPS_INT
%undef NATIVE_TYPE_RANGE
 xor eax,eax
 ret
.yes:
 mov eax,1
 ret

; Existing Tuple(name, Column<Int>) names a real source column.
fcg_table_column_shape:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp rdx,2
 jne .no
 mov r12,rcx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .no
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_COLUMN_INT
 jne .no
 mov rdx,r12
 mov rcx,r13
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, field Tuple AST -> EAX valid, RDX name expression, RCX nullable
; expression. The current native schema profile admits exact Int cell types.
fcg_schema_field_shape:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp rdx,3
 jne .no
 mov r12,rcx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .no
 mov rdi,rbx
 mov rsi,r13
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .no
 mov rdx,r12
 mov rcx,r13
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Resolve a noncapturing top-level predicate with exactly Int receiver,
; one Int argument and Bool return. Reuse FunctionTable's return/type owners.
; state*, identifier node -> exact native function symbol or zero.
fcg_data_callback_symbol:
 mov rax,rdx
 xor edx,edx
 cmp eax,515
 jne .not_dataset_callback
 mov ecx,NEBOC_TYPE_ID_VOID
 mov r8d,FCG_TYPE_NATIVE_TABLE_INT
 jmp fcg_typed_callable_with_receiver
.not_dataset_callback:
 cmp eax,456
 jne .not_table_callback
 mov ecx,NEBOC_TYPE_ID_BOOL
 mov r8d,FCG_TYPE_NATIVE_ROW_INT
 jmp fcg_typed_callable_with_receiver
.not_table_callback:
 cmp eax,369
 jne .scalar_receiver
 mov ecx,NEBOC_TYPE_ID_VOID
 mov r8d,FCG_TYPE_NATIVE_LIST_INT
 jmp fcg_typed_callable_with_receiver
.scalar_receiver:
 mov ecx,NEBOC_TYPE_ID_INT
 cmp eax,360
 je fcg_typed_callable_symbol
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp eax,361
 je fcg_typed_callable_symbol
 mov ecx,NEBOC_TYPE_ID_VOID
 jmp fcg_typed_callable_symbol

fcg_assoc_predicate_symbol:
 mov edx,1
 mov ecx,NEBOC_TYPE_ID_BOOL
 jmp fcg_typed_callable_symbol

; state*, identifier, sequential operation -> native FunctionTable symbol.
fcg_seq_callback_symbol:
 mov rax,rdx
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp eax,135
 jne .not_map
 mov ecx,NEBOC_TYPE_ID_INT
.not_map:
 cmp eax,138
 jne fcg_typed_callable_symbol
 mov edx,1
 mov ecx,NEBOC_TYPE_ID_ORDERING
fcg_typed_callable_symbol:
 mov r8d,NEBOC_TYPE_ID_INT
fcg_typed_callable_with_receiver:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov [rsp+24],rdx
 mov [rsp+32],rcx
 mov [rsp+40],r8
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r12,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_identifier
 test rax,rax
 jnz .no
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r14d,2
 xor r15d,r15d
.scan:
 test r13,r13
 jz .matched
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov [rsp],rax
 mov rdx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rdx
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .next
 mov rdx,[rsp+24]
 cmp [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
 jne .advance
 add rdx,2
 cmp [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],rdx
 jne .advance
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .advance
 mov rax,[rsp]
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+16],rsi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .advance
 mov rsi,[rsp+16]
 mov rdi,rbx
 call fcg_decl_type_from_node
 cmp rax,[rsp+40]
 jne .advance
 cmp qword [rsp+24],0
 je .parameter_typed
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_decl_type_from_node
 cmp rax,NEBOC_TYPE_ID_INT
 jne .advance
.parameter_typed:
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 cmp rax,1
 je .return_type
 cmp r14,rax
 jae .no
.return_type:
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r14
 call fcg_function_return_type
 cmp rax,[rsp+32]
 jne .advance
 test r15,r15
 jnz .no
 mov r15,r14
.advance:
 inc r14
.next:
 mov r13,[rsp+8]
 jmp .scan
.matched:
 mov rax,r15
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, exact AST id -> authenticated current-function plan pointer or zero.
fcg_assoc_find_plan:
 xor ecx,ecx
.scan:
 cmp rcx,[rdi+FCG_ASSOC_COUNT]
 jae .no
 mov rax,rcx
 shl rax,6
 lea rax,[rdi+rax+FCG_ASSOC_PLANS]
 cmp [rax],rsi
 je .done
 inc rcx
 jmp .scan
.no:
 xor eax,eax
.done:
 ret

; state*, containing AST node (zero = function), mode 59 release / 60 init /
; 65 release only unbound temporaries at the end of their full statement.
; Every view slot starts released, including untaken branches. Cleanup can
; therefore share the canonical epilogue and safely skip explicit releases.
; Runtime scalar return registers survive each native cleanup call.
fcg_assoc_emit_view_lifecycle:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov [rsp],rdx
 xor r12d,r12d
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET]
 test rsi,rsi
 jz .range_ready
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov r13,[rax+NEBOC_AST_NODE_END_OFFSET]
.range_ready:
 xor r14d,r14d
.scan:
 cmp r14,[rbx+FCG_ASSOC_COUNT]
 jae .ok
 mov r15,r14
 shl r15,6
 lea r15,[rbx+r15+FCG_ASSOC_PLANS]
 inc r14
 mov rax,[r15+8]
 cmp eax,700
 jae .view
 cmp eax,270
 je .view
 cmp eax,271
 je .view
 cmp eax,38
 je .view
 cmp eax,39
 je .view
 cmp eax,42
 je .view
 cmp eax,61
 je .view
 cmp eax,66
 je .view
 cmp eax,140
 jb .scan
 cmp eax,143
 ja .scan
.view:
 mov rdi,rbx
 mov rsi,[r15]
 call fcg_node_ptr
 cmp [rax+NEBOC_AST_NODE_START_OFFSET],r12
 jb .scan
 cmp [rax+NEBOC_AST_NODE_END_OFFSET],r13
 ja .scan
 cmp qword [rsp],65
 jne .emit_lifecycle
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_LEXICAL_BORROW
 jnz .scan
.emit_lifecycle:
 mov rdi,rbx
 lea rsi,[rel ac_lifecycle_frame]
 mov edx,ac_lifecycle_frame_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rsi,[r15+24]
 add rsi,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET]
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_lifecycle_op]
 mov edx,ac_lifecycle_op_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 cmp qword [r15+8],700
 jb .collection_lifecycle
 mov esi,77
 cmp qword [rsp],60
 jne .lifecycle_op_ready
 mov esi,78
 jmp .lifecycle_op_ready
.collection_lifecycle:
 cmp qword [r15+8],270
 jb .ordinary_lifecycle_op
 mov esi,274
 cmp qword [rsp],60
 jne .lifecycle_op_ready
 mov esi,275
 jmp .lifecycle_op_ready
.ordinary_lifecycle_op:
 cmp esi,60
 je .lifecycle_op_ready
 cmp qword [r15+8],140
 jb .lifecycle_op_ready
 mov esi,152
.lifecycle_op_ready:
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_call]
 mov edx,ac_call_len
 cmp qword [r15+8],700
 jb .append_lifecycle_call
 lea rsi,[rel sy_lifecycle_call]
 mov edx,sy_lifecycle_call_len
.append_lifecycle_call:
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_lifecycle_restore]
 mov edx,ac_lifecycle_restore_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .scan
.bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call id -> EAX operation (zero unclaimed/invalid), RCX exact TypeId,
; RDX receiver node (zero for constructors), R8/R9 value argument node ids.
fcg_assoc_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+40],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rsi,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov rax,[r14+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 test rax,rax
 jz .arguments_ready
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rax
.arguments_ready:
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .typed_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_data_Schema]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jnz .schema_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_data_Row]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jnz .row_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_data_Table]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jnz .table_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_data_Dataset]
 mov ecx,7
 call fcg_token_matches_literal
 test eax,eax
 jnz .dataset_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_hasher]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jnz .hasher_constructor
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_hash]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jnz .hash_policy
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_int]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jz .typed_constructor
 AC_MATCH ac_hash_stable,10,.int_hash_stable
.typed_constructor:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .method
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_dict]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .set_constructor
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .invalid
 mov qword [rsp+24],FCG_TYPE_DICT_INT_INT
 mov qword [rsp+32],1
 jmp .types
.set_constructor:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_set]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jz .sequential_constructor
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov qword [rsp+24],FCG_TYPE_HASH_SET_INT
 mov qword [rsp+32],2
.types:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.type_loop:
 test r15,r15
 jz .constructor_method
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 jmp .type_loop
.constructor_method:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_new]
 mov ecx,3
 call fcg_token_matches_literal
 test eax,eax
 jz .with_capacity
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 jmp .constructor_ok
.with_capacity:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_with_capacity]
 mov ecx,12
 call fcg_token_matches_literal
 test eax,eax
 jz .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .dynamic_capacity
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,8
 jb .capacity_invalid
 cmp rax,64
 ja .capacity_invalid
 lea rdx,[rax-1]
 test rax,rdx
 jnz .capacity_invalid
.dynamic_capacity:
 add qword [rsp+32],14
.constructor_ok:
 mov qword [rsp],0
 jmp .ok
.method:
 mov rdi,rbx
 mov rsi,[rsp]
 mov edx,1
 call fcg_probe_receiver_type
 cmp rax,FCG_TYPE_DICT_INT_INT
 je .dictionary
 cmp rax,FCG_TYPE_HASH_SET_INT
 je .dictionary
 cmp rax,FCG_TYPE_OPTION_INT
 je .optional
 cmp rax,FCG_TYPE_OPTION_FLOAT
 je .optional
 cmp rax,FCG_TYPE_OPTION_INT_REF
 je .optional
 cmp rax,FCG_TYPE_DICT_INT_VIEW
 je .view
 cmp rax,FCG_TYPE_DICT_ENTRY_VIEW
 je .view
 cmp rax,FCG_TYPE_OPTION_INT_PAIR
 je .pair_option
 cmp rax,FCG_TYPE_INT_PAIR
 je .pair
 cmp rax,FCG_TYPE_HASHER
 je .hasher
 cmp rax,FCG_TYPE_DICT_INT_UNIQUE_REF
 je .unique_ref
 cmp rax,FCG_TYPE_SORTED_INT_ENTRIES
 je .sorted_entries_value
 cmp rax,FCG_TYPE_NATIVE_ITERATOR_INT
 je .sequence_iterator
 cmp rax,FCG_TYPE_NATIVE_LIST_INT
 jb .nonsequential_method
 cmp rax,FCG_TYPE_NATIVE_DEQUE_INT
 jbe .sequential
.nonsequential_method:
 cmp rax,FCG_TYPE_NATIVE_TREE_INT
 jae .relational_method
 cmp rax,NEBOC_TYPE_ID_INT
 je .int_hash
 jmp .no
%include "compiler/codegen/collections/x86_64/sequential_codegen.inc"
%include "compiler/codegen/collections/x86_64/relational_codegen.inc"
%include "compiler/codegen/collections/x86_64/data_codegen.inc"
.hasher_constructor:
 AC_MATCH ac_new,3,.hasher_new
 jmp .invalid
.hash_policy:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jnz .method
 AC_MATCH ac_deterministic,13,.hash_deterministic
 AC_MATCH ac_randomized,10,.hash_randomized
 jmp .invalid
.hash_deterministic:
 mov qword [rsp],0
 mov qword [rsp+32],57
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 mov r15d,1
 jmp .int_arguments
.hash_randomized:
 mov qword [rsp],0
 mov qword [rsp+32],58
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.int_hash_stable:
 mov qword [rsp],0
 mov qword [rsp+32],55
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.hasher_new:
 mov qword [rsp],0
 mov qword [rsp+32],50
 mov qword [rsp+24],FCG_TYPE_HASHER
 mov r15d,1
 jmp .int_arguments
.hasher:
 AC_MATCH ac_write_bytes,10,.hasher_write
 AC_MATCH ac_finish,6,.hasher_finish
 jmp .invalid
.hasher_write:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BYTES
 jne .invalid
 mov qword [rsp+32],51
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ok
.hasher_finish:
 mov qword [rsp+32],52
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.int_hash:
 AC_MATCH ac_equals,6,.int_equals
 AC_MATCH ac_hash,4,.int_feed_hash
 jmp .no
.int_equals:
 mov qword [rsp+32],53
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 mov r15d,1
 jmp .int_arguments
.int_feed_hash:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_HASHER
 jne .invalid
 mov qword [rsp+32],54
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ok
.dictionary:
 mov [rsp+40],rax
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_length]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .capacity
 mov qword [rsp+32],3
 jmp .scalar_query
.capacity:
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_capacity]
 mov ecx,8
 call fcg_token_matches_literal
 test eax,eax
 jz .other_method
 mov qword [rsp+32],4
.scalar_query:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ok
.other_method:
 AC_MATCH ac_insert,6,.insert
 AC_MATCH ac_get,3,.get
 AC_MATCH ac_get_mutable,10,.get_mutable
 AC_MATCH ac_entry,5,.entry
 AC_MATCH ac_sorted_entries,15,.sorted_entries
 AC_MATCH ac_iteration_order,14,.iteration_order
 AC_MATCH ac_retain,6,.retain
 AC_MATCH ac_contains,11,.contains
 AC_MATCH ac_set_contains,8,.set_contains
 AC_MATCH ac_remove,6,.remove
 AC_MATCH ac_clear,5,.clear
 AC_MATCH ac_move,4,.move
 AC_MATCH ac_drop,4,.drop
 AC_MATCH ac_is_moved,7,.is_moved
 AC_MATCH ac_union,5,.union
 AC_MATCH ac_intersection,12,.intersection
 AC_MATCH ac_difference,10,.difference
 AC_MATCH ac_subset,10,.subset
 AC_MATCH ac_reserve,7,.reserve
 AC_MATCH ac_invariants,18,.invariants
 AC_MATCH ac_collisions,14,.collisions
 AC_MATCH ac_max_probe,14,.max_probe
 AC_MATCH ac_load_factor,10,.load_factor
 AC_MATCH ac_keys,4,.keys
 AC_MATCH ac_values,6,.values
 AC_MATCH ac_entries,7,.entries
 AC_MATCH ac_reseed,6,.reseed
 jmp .invalid
.keys:
 mov qword [rsp+32],38
 jmp .view_constructor
.values:
 mov qword [rsp+32],39
 jmp .view_constructor
.entries:
 mov qword [rsp+32],42
.view_constructor:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 mov qword [rsp+24],FCG_TYPE_DICT_INT_VIEW
 cmp qword [rsp+32],42
 jne .ownership_arity
 mov qword [rsp+24],FCG_TYPE_DICT_ENTRY_VIEW
 jmp .ownership_arity
.view:
 mov [rsp+40],rax
 AC_MATCH ac_next,4,.view_next
 AC_MATCH ac_release,7,.view_release
 jmp .invalid
.view_next:
 mov qword [rsp+32],40
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 cmp qword [rsp+40],FCG_TYPE_DICT_ENTRY_VIEW
 jne .ownership_arity
 mov qword [rsp+32],43
 mov qword [rsp+24],FCG_TYPE_OPTION_INT_PAIR
 jmp .ownership_arity
.view_release:
 mov qword [rsp+32],41
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.pair_option:
 AC_MATCH ac_expect,6,.pair_expect
 AC_MATCH ac_is_some,6,.pair_is_some
 AC_MATCH ac_is_none,6,.pair_is_none
 jmp .invalid
.pair_expect:
 mov qword [rsp+32],44
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 mov qword [rsp+24],FCG_TYPE_INT_PAIR
 jmp .ok
.pair_is_some:
 mov qword [rsp+32],47
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.pair_is_none:
 mov qword [rsp+32],48
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.pair:
 AC_MATCH ac_at,2,.pair_at
 AC_MATCH ac_length,6,.pair_length
 jmp .invalid
.pair_at:
 mov qword [rsp+32],45
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 mov r15d,1
 jmp .int_arguments
.pair_length:
 mov qword [rsp+32],46
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.insert:
 mov qword [rsp+32],5
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 mov r15d,2
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 jne .int_arguments
 mov qword [rsp+32],17
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 mov r15d,1
 jmp .int_arguments
.get:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 mov qword [rsp+32],6
 mov qword [rsp+24],FCG_TYPE_OPTION_INT_REF
 mov r15d,1
 jmp .int_arguments
.get_mutable:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 mov qword [rsp+32],61
 jmp .unique_constructor
.entry:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 mov qword [rsp+32],66
.unique_constructor:
 mov qword [rsp+24],FCG_TYPE_DICT_INT_UNIQUE_REF
 mov r15d,1
 jmp .int_arguments
.unique_ref:
 mov [rsp+40],rax
 AC_MATCH ac_read,4,.unique_read
 AC_MATCH ac_write,5,.unique_write
 AC_MATCH ac_release,7,.unique_release
 jmp .invalid
.unique_read:
 mov qword [rsp+32],62
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.unique_write:
 mov qword [rsp+32],63
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 mov r15d,1
 jmp .int_arguments
.unique_release:
 mov qword [rsp+32],64
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.sorted_entries:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 mov qword [rsp+32],68
 mov qword [rsp+24],FCG_TYPE_SORTED_INT_ENTRIES
 jmp .ownership_arity
.retain:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_assoc_predicate_symbol
 test rax,rax
 jz .invalid
 mov qword [rsp+32],67
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ok
.iteration_order:
 mov qword [rsp+32],71
 mov qword [rsp+24],NEBOC_TYPE_ID_TEXT
 jmp .ownership_arity
.sorted_entries_value:
 AC_MATCH ac_length,6,.sorted_length
 AC_MATCH ac_at,2,.sorted_at
 jmp .invalid
.sorted_length:
 mov qword [rsp+32],70
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.sorted_at:
 mov qword [rsp+32],69
 mov qword [rsp+24],FCG_TYPE_INT_PAIR
 mov r15d,1
 jmp .int_arguments
.contains:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 jne .invalid
 jmp .contains_ready
.set_contains:
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 jne .invalid
.contains_ready:
 mov qword [rsp+32],7
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 mov r15d,1
 jmp .int_arguments
.remove:
 mov qword [rsp+32],8
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 jne .remove_ready
 mov qword [rsp+32],18
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
.remove_ready:
 mov r15d,1
 jmp .int_arguments
.clear:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov qword [rsp+32],9
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ok
.union:
 mov qword [rsp+32],22
 jmp .set_algebra
.intersection:
 mov qword [rsp+32],23
 jmp .set_algebra
.difference:
 mov qword [rsp+32],24
 jmp .set_algebra
.subset:
 mov qword [rsp+32],25
.set_algebra:
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 jne .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_HASH_SET_INT
 jne .invalid
 mov [rsp+24],rax
 cmp qword [rsp+32],25
 jne .ok
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ok
.reserve:
 mov qword [rsp+32],31
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 mov r15d,1
 jmp .int_arguments
.reseed:
 mov qword [rsp+32],56
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.invariants:
 mov qword [rsp+32],33
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.collisions:
 mov qword [rsp+32],34
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.load_factor:
 mov qword [rsp+32],37
 mov qword [rsp+24],NEBOC_TYPE_ID_FLOAT
 jmp .ownership_arity
.max_probe:
 mov qword [rsp+32],35
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.move:
 mov qword [rsp+32],19
 mov rax,[rsp+40]
 mov [rsp+24],rax
 jmp .ownership_arity
.drop:
 mov qword [rsp+32],20
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.is_moved:
 mov qword [rsp+32],21
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
.ownership_arity:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 jmp .ok
.int_arguments:
 cmp [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],r15
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 cmp r15,2
 jne .ok
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 jmp .ok
.optional:
 mov [rsp+40],rax
 AC_MATCH ac_is_some,6,.is_some
 AC_MATCH ac_is_none,6,.is_none
 AC_MATCH ac_unwrap_or,8,.unwrap_or
 AC_MATCH ac_expect,6,.expect
 AC_MATCH ac_release,7,.release
 jmp .invalid
.release:
 cmp qword [rsp+40],FCG_TYPE_OPTION_INT_REF
 jne .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov qword [rsp+32],26
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ok
.is_some:
 mov qword [rsp+32],11
 jmp .option_query
.is_none:
 mov qword [rsp+32],12
.option_query:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .option_ready
.unwrap_or:
 mov qword [rsp+32],13
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp qword [rsp+40],FCG_TYPE_OPTION_FLOAT
 jne .unwrap_int_type
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .invalid
 jmp .option_value
.unwrap_int_type:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 jmp .option_value
.expect:
 mov qword [rsp+32],14
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
.option_value:
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 cmp qword [rsp+40],FCG_TYPE_OPTION_FLOAT
 jne .option_ready
 mov qword [rsp+24],NEBOC_TYPE_ID_FLOAT
.option_ready:
 cmp qword [rsp+40],FCG_TYPE_OPTION_INT_REF
 jne .ok
 add qword [rsp+32],16
.ok:
 cmp qword [rsp+32],21
 je .live_checked
 cmp qword [rsp+40],FCG_TYPE_NATIVE_GRAPH_TRAVERSAL
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_NATIVE_ITERATOR_INT
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_OPTION_INT_REF
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_VIEW
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_DICT_ENTRY_VIEW
 je .check_live
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_UNIQUE_REF
 jne .live_checked
.check_live:
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 call fcg_assoc_is_live
 test eax,eax
 jnz .live_checked
 mov r15d,4
 jmp .record_error
.live_checked:
 cmp qword [rsp+40],FCG_TYPE_NATIVE_LIST_INT
 jb .associative_exclusive_check
 cmp qword [rsp+40],FCG_TYPE_NATIVE_DEQUE_INT
 jbe .exclusive_check
.associative_exclusive_check:
 cmp qword [rsp+40],FCG_TYPE_DICT_INT_INT
 je .exclusive_check
 cmp qword [rsp+40],FCG_TYPE_HASH_SET_INT
 jne .exclusive_checked
.exclusive_check:
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 mov r8d,1
 call fcg_assoc_has_live_borrow
 test eax,eax
 jz .exclusive_checked
 mov r15d,6
 jmp .record_error
.exclusive_checked:
 mov rax,[rsp+32]
 cmp eax,140
 jb .sequential_mutations
 cmp eax,143
 jbe .check_borrow
.sequential_mutations:
 cmp eax,270
 je .check_borrow
 cmp eax,271
 je .check_borrow
 cmp eax,252
 jb .non_graph_mutation
 cmp eax,255
 jbe .check_borrow
.non_graph_mutation:
 cmp eax,112
 jb .associative_mutations
 cmp eax,139
 ja .associative_mutations
 cmp eax,115
 je .borrow_checked
 cmp eax,116
 je .borrow_checked
 cmp eax,117
 je .borrow_checked
 cmp eax,124
 je .borrow_checked
 cmp eax,130
 je .borrow_checked
 cmp eax,132
 je .borrow_checked
 cmp eax,134
 je .borrow_checked
 cmp eax,135
 je .borrow_checked
 cmp eax,136
 je .borrow_checked
 jmp .check_borrow
.associative_mutations:
 cmp eax,5
 je .check_borrow
 cmp eax,8
 je .check_borrow
 cmp eax,9
 je .check_borrow
 cmp eax,17
 jb .borrow_checked
 cmp eax,20
 jbe .check_borrow
 cmp eax,31
 je .check_borrow
 cmp eax,56
 je .check_borrow
 cmp eax,61
 je .check_borrow
 cmp eax,66
 je .check_borrow
 cmp eax,67
 jne .borrow_checked
.check_borrow:
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 xor r8d,r8d
 call fcg_assoc_has_live_borrow
 test eax,eax
 jz .borrow_checked
 mov r15d,6
 jmp .record_error
.borrow_checked:
 mov rax,[rsp+32]
 mov rcx,[rsp+24]
 mov rdx,[rsp]
 mov r8,[rsp+8]
 mov r9,[rsp+16]
 jmp .done
.capacity_invalid:
 mov r15d,2
 jmp .record_error
.invalid:
 mov r15d,1
.record_error:
 cmp qword [rbx+FCG_ASSOC_ERROR],0
 jne .error_recorded
 mov [rbx+FCG_ASSOC_ERROR],r15
 mov rax,[r13+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+FCG_ASSOC_ERROR_START],rax
 mov rax,[r13+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+FCG_ASSOC_ERROR_END],rax
.error_recorded:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 mov rdi,rbx
 mov rsi,r12
 call fcg_capture_node_span
.no:
 xor eax,eax
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Plan expressions only: each surrounding block owns its scope and statements.
; Each 64-byte record carries AST id, operation, exact return type, frame slot,
; receiver/argument nodes and the resolved lexical owner slot. Source spans
; stay attached to the AST id. No source effect is pre-evaluated.
fcg_assoc_plan_expression:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 test r12,r12
 jz .ok
 cmp r13,64
 jae .bad
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .ok
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .value_children
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jnz .ok
.value_children:
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.children:
 test r15,r15
 jz .classify
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_assoc_plan_expression
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .children
.classify:
 mov rdi,rbx
 mov rsi,r12
 call fcg_assoc_info
 test eax,eax
 jnz .plan_ready
 mov rdi,rbx
 mov rsi,r12
 call fcg_system_public_info
 cmp eax,63
 jb .ok
 cmp eax,66
 ja .ok
 ; Guard storage belongs to the existing lexical frame/lifecycle planner.
 add eax,637
 xor edx,edx
 xor r8d,r8d
 xor r9d,r9d
.plan_ready:
 mov r10,[rbx+FCG_ASSOC_COUNT]
 cmp r10,FCG_ASSOC_MAX
 jae .bad
 inc qword [rbx+FCG_ASSOC_COUNT]
 shl r10,6
 lea r10,[rbx+r10+FCG_ASSOC_PLANS]
 mov [r10],r12
 mov [r10+8],rax
 mov [r10+16],rcx
 mov [r10+32],rdx
 mov [r10+40],r8
 mov [r10+48],r9
 mov qword [r10+56],0
 mov [rsp],r10
 mov edx,4
 cmp eax,700
 jae .size_ready
 mov edx,512 ; two alternating native rehash buffers for a looped reserve
 cmp eax,31
 je .size_ready
 cmp eax,56
 je .size_ready
 mov edx,640
 cmp rcx,FCG_TYPE_NATIVE_TABLE_GROUPS_INT
 jne .not_table_groups_size
 mov edx,20520
 jmp .size_ready
.not_table_groups_size:
 cmp rcx,FCG_TYPE_NATIVE_DATASET_ROWS_INT
 jne .not_dataset_rows_size
 mov edx,4360
 jmp .size_ready
.not_dataset_rows_size:
 cmp rcx,FCG_TYPE_OPTION_ROW_INT
 jne .not_option_row_size
 mov edx,304
 jmp .size_ready
.not_option_row_size:
 cmp rcx,FCG_TYPE_NATIVE_TABLE_INT
 je .size_ready
 mov edx,656
 cmp rcx,FCG_TYPE_OPTION_TABLE_INT
 je .size_ready
 mov edx,16
 cmp rcx,FCG_TYPE_NATIVE_DATASET_SCAN_INT
 je .size_ready
 mov edx,5440
 cmp rcx,FCG_TYPE_NATIVE_DATASET_INT
 je .size_ready
 mov edx,288
 cmp rcx,FCG_TYPE_NATIVE_ROW_INT
 je .size_ready
 mov edx,16
 cmp rcx,FCG_TYPE_NATIVE_ROW_TUPLE_INT
 je .size_ready
 mov edx,256
 cmp rcx,FCG_TYPE_NATIVE_SCHEMA_INT
 je .size_ready
 cmp rcx,FCG_TYPE_NATIVE_BATCH_STREAM_INT
 je .size_ready
 cmp rcx,FCG_TYPE_NATIVE_STREAM_INT
 je .size_ready
 mov edx,24
 cmp rcx,FCG_TYPE_NATIVE_SCHEMA_FIELD
 je .size_ready
 mov edx,88
 cmp rcx,FCG_TYPE_OPTION_LIST_INT
 je .size_ready
 mov edx,16
 cmp rcx,FCG_TYPE_NATIVE_FLOW_INT
 je .size_ready
 mov edx,40
 cmp rcx,FCG_TYPE_NATIVE_COLUMN_INT
 je .size_ready
 cmp rcx,FCG_TYPE_NATIVE_COLUMN_UINT
 je .size_ready
 mov edx,144
 cmp eax,260
 jb .not_graph_algorithm_size
 cmp eax,264
 jbe .size_ready
 cmp eax,277
 je .size_ready
.not_graph_algorithm_size:
 mov edx,64
 cmp rcx,FCG_TYPE_NATIVE_GRAPH_TRAVERSAL
 je .size_ready
 mov edx,56
 cmp rcx,FCG_TYPE_OPTION_NODE_SEQUENCE
 je .size_ready
 mov edx,128
 cmp eax,201
 je .size_ready
 mov edx,96
 cmp rcx,FCG_TYPE_NATIVE_TREE_INT
 je .size_ready
 mov edx,48
 cmp rcx,FCG_TYPE_NATIVE_NODE_SEQUENCE
 je .size_ready
 mov edx,1280
 cmp rcx,FCG_TYPE_NATIVE_GRAPH_INT
 je .size_ready
 mov edx,8
 cmp eax,138
 jne .not_sort_size
 mov edx,80
 jmp .size_ready
.not_sort_size:
 cmp rcx,FCG_TYPE_SORTED_INT_ENTRIES
 jne .ordinary_size
 mov edx,112 ; count, 48 native Int pairs, independent temporary view
 jmp .size_ready
.ordinary_size:
 cmp rcx,FCG_TYPE_NATIVE_LIST_INT
 jne .other_sequence_size
 mov edx,80 ; native List descriptor and up to 64 cells from stream batches
 jmp .size_ready
.other_sequence_size:
 cmp rcx,FCG_TYPE_NATIVE_LIST_INT
 jb .associative_size
 cmp rcx,FCG_TYPE_NATIVE_DEQUE_INT
 ja .associative_size
 mov edx,40 ; native descriptor plus 16 Int cells, aligned caller storage
 jmp .size_ready
.associative_size:
 cmp rcx,FCG_TYPE_DICT_INT_INT
 je .constructor_size
 cmp rcx,FCG_TYPE_HASH_SET_INT
 jne .size_ready
.constructor_size:
 mov edx,270 ; aligned descriptor + maximum native 64-bucket storage
.size_ready:
 add [rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET],rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_SLOT_COUNT_OFFSET]
 mov [r10+24],rax
 cmp qword [r10+8],360
 jb .not_data_callback
 cmp qword [r10+8],456
 je .plan_data_callback
 cmp qword [r10+8],515
 je .plan_data_callback
 cmp qword [r10+8],369
 je .plan_data_callback
 cmp qword [r10+8],362
 ja .not_data_callback
.plan_data_callback:
 mov rdi,rbx
 mov rsi,[r10+40]
 mov rdx,[r10+8]
 call fcg_data_callback_symbol
 test rax,rax
 jz .bad
 mov r10,[rsp]
 mov [r10+56],rax
 jmp .ok
.not_data_callback:
 cmp qword [r10+8],276
 je .plan_traversal_callback
 cmp qword [r10+8],67
 jne .plan_sequence_callback
 mov rdi,rbx
 mov rsi,[r10+40]
 call fcg_assoc_predicate_symbol
 test rax,rax
 jz .bad
 mov r10,[rsp]
 mov [r10+56],rax
 jmp .ok
.plan_traversal_callback:
 cmp qword [r10+8],276
 jne .plan_sequence_callback
 mov rdi,rbx
 mov rsi,[r10+40]
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_BOOL
 call fcg_typed_callable_symbol
 test rax,rax
 jz .bad
 mov r10,[rsp]
 mov [r10+56],rax
 jmp .ok
.plan_sequence_callback:
 cmp qword [r10+8],134
 jb .plan_ownership
 cmp qword [r10+8],138
 ja .plan_ownership
 mov rdi,rbx
 mov rsi,[r10+40]
 mov rdx,[r10+8]
 call fcg_seq_callback_symbol
 test rax,rax
 jz .bad
 mov r10,[rsp]
 mov [r10+56],rax
 jmp .ok
.plan_ownership:
 cmp qword [r10+8],270
 je .ownership_slot
 cmp qword [r10+8],271
 je .ownership_slot
 cmp qword [r10+8],273
 je .release_scope
 cmp qword [r10+8],140
 jb .associative_plan_ownership
 cmp qword [r10+8],143
 jbe .ownership_slot
 cmp qword [r10+8],149
 je .release_scope
 cmp qword [r10+8],145
 je .ownership_slot
.associative_plan_ownership:
 cmp qword [r10+8],19
 je .ownership_slot
 cmp qword [r10+8],20
 je .ownership_slot
 cmp qword [r10+8],6
 je .ownership_slot
 cmp qword [r10+8],38
 je .ownership_slot
 cmp qword [r10+8],39
 je .ownership_slot
 cmp qword [r10+8],42
 je .ownership_slot
 cmp qword [r10+8],61
 je .ownership_slot
 cmp qword [r10+8],66
 je .ownership_slot
 cmp qword [r10+8],64
 je .release_scope
 cmp qword [r10+8],41
 je .release_scope
 cmp qword [r10+8],26
 jne .ok
.release_scope:
 ; A release only ends a borrow for control paths in its own lexical scope.
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 shl rax,16
 or [r14+NEBOC_AST_NODE_FLAGS_OFFSET],rax
.ownership_slot:
 mov rdi,rbx
 mov rsi,[r10+32]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ok
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_resolve_identifier
 mov r10,[rsp]
 mov [r10+56],rax
.ok:
 xor eax,eax
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

 ; A lexical slot is consumed only by an earlier move/drop of that same
 ; resolved owner. Later source nodes and different shadowed slots cannot match.
fcg_assoc_is_live:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_node_ptr
 test rax,rax
 jz .yes
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .yes
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_resolve_identifier
 test rax,rax
 jz .yes
 mov r12,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_START_OFFSET]
 xor r14d,r14d
.scan:
 cmp r14,[rbx+FCG_ASSOC_COUNT]
 jae .yes
 mov r15,r14
 shl r15,6
 lea r15,[rbx+r15+FCG_ASSOC_PLANS]
 inc r14
 cmp [r15+56],r12
 jne .scan
 cmp qword [r15+8],19
 je .consumed
 cmp qword [r15+8],20
 je .consumed
 cmp qword [r15+8],26
 je .consumed
 cmp qword [r15+8],41
 je .consumed
 cmp qword [r15+8],64
 je .consumed
 cmp qword [r15+8],273
 je .consumed
 cmp qword [r15+8],149
 jne .scan
.consumed:
 mov rdi,rbx
 mov rsi,[r15]
 call fcg_node_ptr
 cmp [rax+NEBOC_AST_NODE_END_OFFSET],r13
 ja .scan
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

 ; EAX true only when an earlier lexical get borrow of this resolved owner
 ; remains active in the current scope and has no dominating explicit release.
fcg_assoc_has_live_borrow:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov [rsp+8],r8
 mov rbx,rdi
 mov r13,rdx
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov r12,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_START_OFFSET]
 xor r14d,r14d
.scan:
 cmp r14,[rbx+FCG_ASSOC_COUNT]
 jae .no
 mov r15,r14
 shl r15,6
 lea r15,[rbx+r15+FCG_ASSOC_PLANS]
 inc r14
 cmp qword [r15+8],61
 je .borrow_owner
 cmp qword [r15+8],66
 je .borrow_owner
 cmp qword [r15+8],141
 je .borrow_owner
 cmp qword [r15+8],143
 je .borrow_owner
 cmp qword [rsp+8],0
 jne .scan
 cmp qword [r15+8],270
 je .borrow_owner
 cmp qword [r15+8],271
 je .borrow_owner
 cmp qword [r15+8],6
 je .borrow_owner
 cmp qword [r15+8],38
 je .borrow_owner
 cmp qword [r15+8],39
 je .borrow_owner
 cmp qword [r15+8],42
 je .borrow_owner
 cmp qword [r15+8],140
 je .borrow_owner
 cmp qword [r15+8],142
 jne .scan
.borrow_owner:
 cmp [r15+56],r12
 jne .scan
 mov rdi,rbx
 mov rsi,[r15]
 call fcg_node_ptr
 cmp [rax+NEBOC_AST_NODE_END_OFFSET],r13
 ja .scan
 mov rcx,[rax+NEBOC_AST_NODE_FLAGS_OFFSET]
 test rcx,NEBOC_AST_FLAG_LEXICAL_BORROW
 jz .scan
 mov rdx,rcx
 shr rdx,32
 mov [rsp],rdx
 shr rcx,16
 and ecx,65535
 call fcg_assoc_scope_active
 test eax,eax
 jz .scan
 xor r15d,r15d
.releases:
 cmp r15,[rbx+FCG_ASSOC_COUNT]
 jae .yes
 mov rax,r15
 shl rax,6
 lea rax,[rbx+rax+FCG_ASSOC_PLANS]
 inc r15
 cmp qword [rax+8],26
 je .release_owner
 cmp qword [rax+8],41
 je .release_owner
 cmp qword [rax+8],64
 je .release_owner
 cmp qword [rax+8],273
 je .release_owner
 cmp qword [rax+8],149
 jne .releases
.release_owner:
 mov rcx,[rsp]
 cmp [rax+56],rcx
 jne .releases
 mov rdi,rbx
 mov rsi,[rax]
 call fcg_node_ptr
 cmp [rax+NEBOC_AST_NODE_END_OFFSET],r13
 ja .releases
 mov rcx,[rax+NEBOC_AST_NODE_FLAGS_OFFSET]
 shr rcx,16
 and ecx,65535
 call fcg_assoc_scope_active
 test eax,eax
 jz .releases
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RBX state, RCX lexical block id -> EAX true iff block is an active ancestor.
fcg_assoc_scope_active:
 xor edx,edx
.scan:
 cmp rdx,[rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_DEPTH_OFFSET]
 jae .no
 cmp [rbx+NEBOC_FUNCTION_CODEGEN_SCOPE_BLOCKS_OFFSET+rdx*8],rcx
 je .yes
 inc rdx
 jmp .scan
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

fcg_assoc_validate_binding:
 cmp rcx,FCG_TYPE_NATIVE_TABLE_GROUPS_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_DATASET_ROWS_INT
 je .owned
 cmp rcx,FCG_TYPE_OPTION_ROW_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_DATASET_SCAN_INT
 je .owned
 cmp rcx,FCG_TYPE_OPTION_TABLE_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_DATASET_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_TABLE_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_ROW_TUPLE_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_ROW_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_SCHEMA_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_BATCH_STREAM_INT
 je .owned
 cmp rcx,FCG_TYPE_OPTION_LIST_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_STREAM_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_FLOW_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_COLUMN_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_COLUMN_UINT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_NODE_SEQUENCE
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_COMPONENTS
 je .owned
 cmp rcx,FCG_TYPE_OPTION_NODE_SEQUENCE
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_GRAPH_TRAVERSAL
 je .borrow
 cmp rcx,FCG_TYPE_NATIVE_TREE_INT
 je .owned
 cmp rcx,FCG_TYPE_SYNC_GUARD
 je .borrow
 cmp rcx,FCG_TYPE_MUTEX_INT
 je .owned
 cmp rcx,FCG_TYPE_RWLOCK_INT
 je .owned
 cmp rcx,FCG_TYPE_ATOMIC_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_GRAPH_INT
 je .owned
 cmp rcx,FCG_TYPE_NATIVE_ITERATOR_INT
 je .borrow
 cmp rcx,FCG_TYPE_NATIVE_LIST_INT
 jb .associative_binding
 cmp rcx,FCG_TYPE_NATIVE_DEQUE_INT
 jbe .owned
.associative_binding:
 cmp rcx,FCG_TYPE_DICT_INT_UNIQUE_REF
 je .borrow
 cmp rcx,FCG_TYPE_DICT_ENTRY_VIEW
 je .borrow
 cmp rcx,FCG_TYPE_DICT_INT_VIEW
 je .borrow
 cmp rcx,FCG_TYPE_OPTION_INT_REF
 je .borrow
 cmp rcx,FCG_TYPE_DICT_INT_INT
 je .owned
 cmp rcx,FCG_TYPE_HASHER
 je .owned
 cmp rcx,FCG_TYPE_HASH_SET_INT
 jne .ok
.borrow:
 push rbx
 mov rbx,rdi
 mov rsi,rdx
 call fcg_node_ptr
 test rax,rax
 jz .valid
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .copy_error
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .valid
 mov rcx,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_PARAMETER_BASE_OFFSET]
 add rcx,[rbx+NEBOC_FUNCTION_CODEGEN_PREPARE_BINDING_COUNT_OFFSET]
 inc rcx
 shl rcx,32
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 shl rdx,16
 or rcx,rdx
 or rcx,NEBOC_AST_FLAG_LEXICAL_BORROW
 or [rax+NEBOC_AST_NODE_FLAGS_OFFSET],rcx
 jmp .valid
.owned:
 push rbx
 mov rbx,rdi
 mov rsi,rdx
 call fcg_node_ptr
 test rax,rax
 jz .valid
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .valid
.copy_error:
 mov qword [rbx+FCG_ASSOC_ERROR],5
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+FCG_ASSOC_ERROR_START],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+FCG_ASSOC_ERROR_END],rcx
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret
.valid:
 pop rbx
.ok:
 xor eax,eax
 ret

fcg_assoc_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 xor eax,eax
.find:
 cmp rax,[rbx+FCG_ASSOC_COUNT]
 jae .bad
 mov r14,rax
 shl r14,6
 lea r14,[rbx+r14+FCG_ASSOC_PLANS]
 cmp [r14],r12
 je .found
 inc rax
 jmp .find
.found:
 mov rdi,rbx
 lea rsi,[rel ac_operand_frame]
 mov edx,ac_operand_frame_len
 call fcg_append
 test eax,eax
 jnz .done
 xor r15d,r15d
.operand:
 cmp qword [r14+8],500
 je .zero
 cmp qword [r14+8],450
 je .zero
 cmp qword [r14+8],425
 je .project_operand
 cmp qword [r14+8],455
 jne .not_row_project_operand
.project_operand:
 cmp r15,1
 je .zero
.not_row_project_operand:
 cmp qword [r14+8],420
 jne .not_row_array_operand
 cmp r15,2
 je .zero
.not_row_array_operand:
 cmp qword [r14+8],400
 je .zero
 cmp qword [r14+8],350
 je .zero
 cmp qword [r14+8],300
 je .zero
 cmp qword [r14+8],308
 je .data_cast_operand
 cmp qword [r14+8],309
 jne .data_ordinary_operand
.data_cast_operand:
 cmp r15,1
 je .zero
.data_ordinary_operand:
 cmp qword [r14+8],105
 je .zero
 cmp qword [r14+8],148
 jne .ordinary_callback_check
 cmp r15,1
 je .zero
.ordinary_callback_check:
 cmp qword [r14+8],515
 je .callback_operand
 cmp qword [r14+8],456
 je .callback_operand
 cmp qword [r14+8],369
 je .callback_operand
 cmp qword [r14+8],360
 jb .not_data_callback_operand
 cmp qword [r14+8],362
 jbe .callback_operand
.not_data_callback_operand:
 cmp qword [r14+8],276
 je .callback_operand
 cmp qword [r14+8],67
 je .callback_operand
 cmp qword [r14+8],134
 jb .ordinary_operand
 cmp qword [r14+8],138
 ja .ordinary_operand
.callback_operand:
 cmp r15,1
 je .predicate_operand
.ordinary_operand:
 mov rsi,[r14+32+r15*8]
 test rsi,rsi
 jz .zero
 cmp qword [r14+8],550
 jne .not_table_join_key
 cmp r15,2
 jne .not_table_join_key
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.not_table_join_key:
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 jmp .operand_done
.predicate_operand:
 mov rdi,rbx
 lea rsi,[rel ac_function_pointer]
 mov edx,ac_function_pointer_len
 cmp qword [r14+8],360
 jae .callback_pointer_ready
 cmp qword [r14+8],276
 je .callback_pointer_ready
 cmp qword [r14+8],67
 je .callback_pointer_ready
 lea rsi,[rel ac_seq_cb_pointer]
 mov edx,ac_seq_cb_pointer_len
.callback_pointer_ready:
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+56]
 cmp qword [r14+8],360
 jae .callback_symbol_ready
 cmp qword [r14+8],276
 je .callback_symbol_ready
 cmp qword [r14+8],67
 je .callback_symbol_ready
 mov rsi,[r14]
.callback_symbol_ready:
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_function_pointer_end]
 mov edx,ac_function_pointer_end_len
 call fcg_append
 jmp .operand_done
.zero:
 mov rdi,rbx
 lea rsi,[rel ac_zero]
 mov edx,ac_zero_len
 call fcg_append
.operand_done:
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_save]
 mov edx,ac_save_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rsi,r15
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_save_end]
 mov edx,ac_save_end_len
 call fcg_append
 test eax,eax
 jnz .done
 inc r15
 cmp r15,3
 jb .operand
 ; Three-argument native calls preserve receiver and the first two arguments
 ; on aligned expression-stack slots while evaluating the final operand once.
 cmp qword [r14+8],253
 je .native_third_operand
 cmp qword [r14+8],550
 jne .relational_operands_ready
.native_third_operand:
 mov rdi,rbx
 mov rsi,[r14+48]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_rel_arg3]
 mov edx,ac_rel_arg3_len
 call fcg_append
 test eax,eax
 jnz .done
.relational_operands_ready:
 mov rdi,rbx
 lea rsi,[rel ac_frame]
 mov edx,ac_frame_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rsi,[r14+24]
 add rsi,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET]
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_args]
 mov edx,ac_args_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rsi,[r14+8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_call]
 mov edx,ac_call_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_operands_release]
 mov edx,ac_operands_release_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [r14+8],400
 je .schema_fields
 cmp qword [r14+8],450
 je .schema_fields
 cmp qword [r14+8],420
 je .row_array_children
 cmp qword [r14+8],425
 je .sequence_array_children
 cmp qword [r14+8],455
 je .sequence_array_children
 cmp qword [r14+8],500
 je .sequence_array_children
 cmp qword [r14+8],350
 je .sequence_array_children
 cmp qword [r14+8],300
 je .sequence_array_children
 cmp qword [r14+8],105
 jne .sequence_callback_definition
.sequence_array_children:
 mov rdi,rbx
 mov rsi,[r14+40]
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .sequence_elements
.row_array_children:
 mov rdi,rbx
 mov rsi,[r14+48]
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 jmp .sequence_elements
.schema_fields:
 mov rdi,rbx
 mov rsi,[r14+40]
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.schema_field:
 test r15,r15
 jz .sequence_result
 mov rdi,rbx
 mov rsi,r15
 cmp qword [r14+8],450
 jne .schema_field_shape
 call fcg_table_column_shape
 jmp .schema_field_shape_ready
.schema_field_shape:
 call fcg_schema_field_shape
.schema_field_shape_ready:
 test eax,eax
 jz .bad
 mov [rsp+8],rcx
 mov rdi,rbx
 mov rsi,rdx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_schema_name_save]
 mov edx,ac_schema_name_save_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,[rsp+8]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_schema_field_args]
 mov edx,ac_schema_field_args_len
 call fcg_append
 test eax,eax
 jnz .done
 call .sequence_frame
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_schema_field_append]
 mov edx,ac_schema_field_append_len
 cmp qword [r14+8],450
 jne .schema_field_append_ready
 lea rsi,[rel ac_table_column_append]
 mov edx,ac_table_column_append_len
.schema_field_append_ready:
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .schema_field
.sequence_elements:
 test r15,r15
 jz .sequence_result
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_seq_append]
 mov edx,ac_seq_append_len
 call fcg_append
 test eax,eax
 jnz .done
 call .sequence_frame
 test eax,eax
 jnz .done
 cmp qword [r14+8],350
 jne .not_stream_append
 mov rdi,rbx
 lea rsi,[rel ac_data_append_stream]
 mov edx,ac_data_append_stream_len
 call fcg_append
 jmp .sequence_append_finished
.not_stream_append:
 cmp qword [r14+8],500
 jne .not_dataset_append
 mov rdi,rbx
 lea rsi,[rel ac_dataset_append]
 mov edx,ac_dataset_append_len
 call fcg_append
 jmp .sequence_append_finished
.not_dataset_append:
 cmp qword [r14+8],455
 jne .not_table_select_append
 mov rdi,rbx
 lea rsi,[rel ac_table_select_append]
 mov edx,ac_table_select_append_len
 call fcg_append
 jmp .sequence_append_finished
.not_table_select_append:
 cmp qword [r14+8],425
 jne .not_row_project_append
 mov rdi,rbx
 lea rsi,[rel ac_row_project_append]
 mov edx,ac_row_project_append_len
 call fcg_append
 jmp .sequence_append_finished
.not_row_project_append:
 cmp qword [r14+8],420
 je .row_append
 cmp qword [r14+8],300
 jne .ordinary_sequence_append
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 mov [rsp+8],rax
 mov rdi,rbx
 lea rsi,[rel ac_data_append_int]
 mov edx,ac_data_append_int_len
 cmp qword [rsp+8],FCG_TYPE_OPTION_INT
 jne .data_append_ready
 lea rsi,[rel ac_data_append_option]
 mov edx,ac_data_append_option_len
.data_append_ready:
 call fcg_append
 jmp .sequence_append_finished
.row_append:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 mov rcx,rax
 mov rdi,rbx
 lea rsi,[rel ac_row_append_int]
 mov edx,ac_row_append_int_len
 cmp rcx,FCG_TYPE_OPTION_INT
 jne .row_append_ready
 lea rsi,[rel ac_row_append_option]
 mov edx,ac_row_append_option_len
.row_append_ready:
 call fcg_append
 jmp .sequence_append_finished
.ordinary_sequence_append:
 mov rdi,rbx
 lea rsi,[rel ac_seq_append_end]
 mov edx,ac_seq_append_end_len
 call fcg_append
.sequence_append_finished:
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .sequence_elements
.sequence_result:
 mov rdi,rbx
 lea rsi,[rel ac_seq_result]
 mov edx,ac_seq_result_len
 call fcg_append
 test eax,eax
 jnz .done
 call .sequence_frame
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_function_pointer_end]
 mov edx,ac_function_pointer_end_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [r14+8],450
 jne .not_table_finish
 mov rdi,rbx
 lea rsi,[rel ac_table_finish]
 mov edx,ac_table_finish_len
 call fcg_append
 jmp .done
.not_table_finish:
 cmp qword [r14+8],500
 jne .not_dataset_finish
 mov rdi,rbx
 lea rsi,[rel ac_dataset_finish]
 mov edx,ac_dataset_finish_len
 call fcg_append
 jmp .done
.not_dataset_finish:
 cmp qword [r14+8],455
 jne .not_table_select_finish
 mov rdi,rbx
 lea rsi,[rel ac_table_select_finish]
 mov edx,ac_table_select_finish_len
 call fcg_append
 jmp .done
.not_table_select_finish:
 cmp qword [r14+8],420
 je .row_finish_emit
 cmp qword [r14+8],425
 jne .done
 mov rdi,rbx
 lea rsi,[rel ac_row_project_finish]
 mov edx,ac_row_project_finish_len
 call fcg_append
 jmp .done
.row_finish_emit:
 mov rdi,rbx
 lea rsi,[rel ac_row_finish]
 mov edx,ac_row_finish_len
 call fcg_append
 jmp .done
.sequence_callback_definition:
 cmp qword [r14+8],134
 jb .done
 cmp qword [r14+8],138
 ja .done
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_skip]
 mov edx,ac_seq_cb_skip_len
 call fcg_append
 test eax,eax
 jnz .done
 call .callback_ast_number
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_label]
 mov edx,ac_seq_cb_label_len
 call fcg_append
 test eax,eax
 jnz .done
 call .callback_ast_number
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_unary]
 mov edx,ac_seq_cb_unary_len
 cmp qword [r14+8],134
 jne .callback_not_find
 lea rsi,[rel ac_seq_cb_predicate]
 mov edx,ac_seq_cb_predicate_len
.callback_not_find:
 cmp qword [r14+8],138
 jne .callback_bridge_ready
 lea rsi,[rel ac_seq_cb_binary]
 mov edx,ac_seq_cb_binary_len
.callback_bridge_ready:
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+56]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
 cmp qword [r14+8],138
 jne .callback_store_result
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_ordering]
 mov edx,ac_seq_cb_ordering_len
 call fcg_append
 test eax,eax
 jnz .done
.callback_store_result:
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_tail]
 mov edx,ac_seq_cb_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 call .callback_ast_number
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel ac_seq_cb_end]
 mov edx,ac_seq_cb_end_len
 call fcg_append
 jmp .done
.callback_ast_number:
 sub rsp,8
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14]
 call neboc_assembly_writer_append_u64_decimal
 add rsp,8
 ret
.sequence_frame:
 sub rsp,8
 mov rsi,[r14+24]
 add rsi,[rbx+NEBOC_FUNCTION_CODEGEN_MUTABLE_ARRAY_BASE_SLOT_OFFSET]
 shl rsi,3
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 add rsp,8
 ret
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, named iterator AST -> resolved slot and its factory's lexical flags.
; The factory owns the declaration scope; source-name spelling is irrelevant.
fcg_seq_iterator_factory:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .no
 mov r12,rax
 xor r13d,r13d
.scan:
 cmp r13,[rbx+FCG_ASSOC_COUNT]
 jae .no
 mov rax,r13
 shl rax,6
 lea rax,[rbx+rax+FCG_ASSOC_PLANS]
 inc r13
 cmp qword [rax+8],140
 jb .scan
 cmp qword [rax+8],143
 ja .scan
 mov rdi,rbx
 mov rsi,[rax]
 call fcg_node_ptr
 mov rdx,[rax+NEBOC_AST_NODE_FLAGS_OFFSET]
 mov rax,rdx
 shr rax,32
 cmp rax,r12
 jne .scan
 mov rax,r12
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, receiver AST, current call AST -> whether the earlier, dominating
; enumerate operation changed this iterator's next() result to Option<Pair>.
fcg_seq_is_enumerated:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r13,rdx
 call fcg_seq_iterator_factory
 test rax,rax
 jz .no
 mov r12,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 mov r13,[rax+NEBOC_AST_NODE_START_OFFSET]
 xor r14d,r14d
.scan:
 cmp r14,[rbx+FCG_ASSOC_COUNT]
 jae .no
 mov r15,r14
 shl r15,6
 lea r15,[rbx+r15+FCG_ASSOC_PLANS]
 inc r14
 cmp qword [r15+8],145
 jne .scan
 cmp [r15+56],r12
 jne .scan
 mov rdi,rbx
 mov rsi,[r15]
 call fcg_node_ptr
 cmp [rax+NEBOC_AST_NODE_END_OFFSET],r13
 ja .scan
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
