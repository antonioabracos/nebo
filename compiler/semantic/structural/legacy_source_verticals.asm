; ARRAY-VERTICAL-AUD-001 structural replacement for the historical STRUCTS-ENUMS-VARIANTS-E-TIPOS-DO-PROGRAMADOR exact-source
; recognizers.  All ownership and semantic decisions are made from canonical
; lexer tokens, token lexemes, bounded declarations and evaluated values.
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/semantic/types/programmer_type_vertical.inc"
%include "compiler/semantic/collections/array_vertical.inc"
%include "compiler/semantic/collections/vector_vertical.inc"
%include "compiler/semantic/collections/column_vertical.inc"

%define LS_COLLECTION_CAPACITY 3
%define LS_LEGACY_MAX_COLLECTIONS 2
%define LS_COLLECTION_VALUES 4
%define LS_NO_TOKEN 0xffffffffffffffff

section .rodata
ls_n_array: db 'Array'
ls_n_array_len equ $-ls_n_array
ls_n_as_slice: db 'asSlice'
ls_n_as_slice_len equ $-ls_n_as_slice
ls_n_list: db 'List'
ls_n_list_len equ $-ls_n_list
ls_n_stack: db 'Stack'
ls_n_stack_len equ $-ls_n_stack
ls_n_queue: db 'Queue'
ls_n_queue_len equ $-ls_n_queue
ls_n_deque: db 'Deque'
ls_n_deque_len equ $-ls_n_deque
ls_n_dict: db 'Dict'
ls_n_dict_len equ $-ls_n_dict
ls_n_vector: db 'Vector'
ls_n_vector_len equ $-ls_n_vector
ls_n_matrix: db 'Matrix'
ls_n_matrix_len equ $-ls_n_matrix
ls_n_zeros: db 'zeros'
ls_n_zeros_len equ $-ls_n_zeros
ls_n_filled: db 'filled'
ls_n_filled_len equ $-ls_n_filled
ls_n_from_buffer: db 'fromBuffer'
ls_n_from_buffer_len equ $-ls_n_from_buffer
ls_n_from_rows: db 'fromRows'
ls_n_from_rows_len equ $-ls_n_from_rows
ls_n_from_nested: db 'fromNested'
ls_n_from_nested_len equ $-ls_n_from_nested
ls_n_tuple: db 'Tuple'
ls_n_tuple_len equ $-ls_n_tuple
ls_n_of: db 'of'
ls_n_of_len equ $-ls_n_of
ls_n_add: db 'add'
ls_n_add_len equ $-ls_n_add
ls_n_rows: db 'rows'
ls_n_rows_len equ $-ls_n_rows
ls_n_columns: db 'columns'
ls_n_columns_len equ $-ls_n_columns
ls_n_layout: db 'layout'
ls_n_layout_len equ $-ls_n_layout
ls_n_at: db 'at'
ls_n_at_len equ $-ls_n_at
ls_n_set: db 'set'
ls_n_set_len equ $-ls_n_set
ls_n_row: db 'row'
ls_n_row_len equ $-ls_n_row
ls_n_column_method: db 'column'
ls_n_column_method_len equ $-ls_n_column_method
ls_n_slice_method: db 'slice'
ls_n_slice_method_len equ $-ls_n_slice_method
ls_n_transpose_view: db 'transposeView'
ls_n_transpose_view_len equ $-ls_n_transpose_view
ls_n_contiguous: db 'contiguous'
ls_n_contiguous_len equ $-ls_n_contiguous
ls_n_subtract: db 'subtract'
ls_n_subtract_len equ $-ls_n_subtract
ls_n_multiply_elements: db 'multiplyElements'
ls_n_multiply_elements_len equ $-ls_n_multiply_elements
ls_n_scale: db 'scale'
ls_n_scale_len equ $-ls_n_scale
ls_n_trace: db 'trace'
ls_n_trace_len equ $-ls_n_trace
ls_n_is_square: db 'isSquare'
ls_n_is_square_len equ $-ls_n_is_square
ls_n_matmul: db 'matmul'
ls_n_matmul_len equ $-ls_n_matmul
ls_n_matmul_into: db 'matmulInto'
ls_n_matmul_into_len equ $-ls_n_matmul_into
ls_n_serialized_size_nbm1: db 'serializedSizeNBM1'
ls_n_serialized_size_nbm1_len equ $-ls_n_serialized_size_nbm1
ls_n_serialize_nbm1: db 'serializeNBM1'
ls_n_serialize_nbm1_len equ $-ls_n_serialize_nbm1
ls_n_deserialize_nbm1: db 'deserializeNBM1'
ls_n_deserialize_nbm1_len equ $-ls_n_deserialize_nbm1
ls_n_length: db 'length'
ls_n_length_len equ $-ls_n_length
ls_n_return: db 'return'
ls_n_return_len equ $-ls_n_return
ls_n_self: db 'self'
ls_n_self_len equ $-ls_n_self
; pointer, length, operation, argument count, identifier-argument, result kind.
; The table is the bounded public Matrix<Int> operation registry consumed by
; the structural parser; it is independent of source paths and fixture names.
ls_matrix_operation_table:
 dq ls_n_rows,ls_n_rows_len,NEBOC_MATRIX_OPERATION_ROWS,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_columns,ls_n_columns_len,NEBOC_MATRIX_OPERATION_COLUMNS,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_layout,ls_n_layout_len,NEBOC_MATRIX_OPERATION_LAYOUT,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_at,ls_n_at_len,NEBOC_MATRIX_OPERATION_AT,2,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_set,ls_n_set_len,NEBOC_MATRIX_OPERATION_SET,3,0,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_row,ls_n_row_len,NEBOC_MATRIX_OPERATION_ROW,1,0,NEBOC_MATRIX_RESULT_VIEW
 dq ls_n_column_method,ls_n_column_method_len,NEBOC_MATRIX_OPERATION_COLUMN,1,0,NEBOC_MATRIX_RESULT_VIEW
 dq ls_n_slice_method,ls_n_slice_method_len,NEBOC_MATRIX_OPERATION_SLICE,4,0,NEBOC_MATRIX_RESULT_VIEW
 dq ls_n_transpose_view,ls_n_transpose_view_len,NEBOC_MATRIX_OPERATION_TRANSPOSE_VIEW,0,0,NEBOC_MATRIX_RESULT_VIEW
 dq ls_n_contiguous,ls_n_contiguous_len,NEBOC_MATRIX_OPERATION_CONTIGUOUS,0,0,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_add,ls_n_add_len,NEBOC_MATRIX_OPERATION_ADD,1,1,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_subtract,ls_n_subtract_len,NEBOC_MATRIX_OPERATION_SUBTRACT,1,1,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_multiply_elements,ls_n_multiply_elements_len,NEBOC_MATRIX_OPERATION_MULTIPLY_ELEMENTS,1,1,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_scale,ls_n_scale_len,NEBOC_MATRIX_OPERATION_SCALE,1,0,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_sum,ls_n_sum_len,NEBOC_MATRIX_OPERATION_SUM,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_min,ls_n_min_len,NEBOC_MATRIX_OPERATION_MIN,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_max,ls_n_max_len,NEBOC_MATRIX_OPERATION_MAX,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_trace,ls_n_trace_len,NEBOC_MATRIX_OPERATION_TRACE,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_is_square,ls_n_is_square_len,NEBOC_MATRIX_OPERATION_IS_SQUARE,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_matmul,ls_n_matmul_len,NEBOC_MATRIX_OPERATION_MATMUL,1,1,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_matmul_into,ls_n_matmul_into_len,NEBOC_MATRIX_OPERATION_MATMUL_INTO,1,1,NEBOC_MATRIX_RESULT_OWNED
 dq ls_n_serialized_size_nbm1,ls_n_serialized_size_nbm1_len,NEBOC_MATRIX_OPERATION_SERIALIZED_SIZE_NBM1,0,0,NEBOC_MATRIX_RESULT_SCALAR
 dq ls_n_serialize_nbm1,ls_n_serialize_nbm1_len,NEBOC_MATRIX_OPERATION_SERIALIZE_NBM1,0,0,NEBOC_MATRIX_RESULT_ARRAY_I64_70
 dq ls_n_deserialize_nbm1,ls_n_deserialize_nbm1_len,NEBOC_MATRIX_OPERATION_DESERIALIZE_NBM1,2,1,NEBOC_MATRIX_RESULT_OWNED
ls_matrix_operation_count equ 24
ls_matrix_operation_row_qwords equ 6
ls_n_tensor: db 'Tensor'
ls_n_tensor_len equ $-ls_n_tensor
ls_n_sparse: db 'sparse'
ls_n_sparse_len equ $-ls_n_sparse
ls_n_column: db 'Column'
ls_n_column_len equ $-ls_n_column
ls_n_table: db 'Table'
ls_n_table_len equ $-ls_n_table
ls_n_dataset: db 'Dataset'
ls_n_dataset_len equ $-ls_n_dataset
ls_n_option: db 'Option'
ls_n_option_len equ $-ls_n_option
ls_n_int: db 'Int'
ls_n_int_len equ $-ls_n_int
ls_n_float: db 'Float'
ls_n_float_len equ $-ls_n_float
ls_n_len: db 'len'
ls_n_len_len equ $-ls_n_len
ls_n_sum: db 'sum'
ls_n_sum_len equ $-ls_n_sum
ls_n_dot: db 'dot'
ls_n_dot_len equ $-ls_n_dot
ls_n_cross: db 'cross'
ls_n_cross_len equ $-ls_n_cross
ls_n_hadamard: db 'hadamard'
ls_n_hadamard_len equ $-ls_n_hadamard
ls_n_tensor_product: db 'tensorProduct'
ls_n_tensor_product_len equ $-ls_n_tensor_product
ls_n_direct_sum: db 'directSum'
ls_n_direct_sum_len equ $-ls_n_direct_sum
ls_n_compose: db 'compose'
ls_n_compose_len equ $-ls_n_compose
ls_n_orthogonal: db 'isOrthogonalTo'
ls_n_orthogonal_len equ $-ls_n_orthogonal
ls_n_parallel: db 'isParallelTo'
ls_n_parallel_len equ $-ls_n_parallel
ls_n_apply: db 'apply'
ls_n_apply_len equ $-ls_n_apply
align 8
; Portable named APIs converge on the same semantic operation IDs as the
; exact Registry spellings; source spelling never selects a separate result.
ls_g134_method_table:
 dq ls_n_dot,ls_n_dot_len,NEBOC_TOKEN_LINEAR_DOT
 dq ls_n_cross,ls_n_cross_len,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 dq ls_n_hadamard,ls_n_hadamard_len,NEBOC_TOKEN_LINEAR_HADAMARD
 dq ls_n_tensor_product,ls_n_tensor_product_len,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 dq ls_n_direct_sum,ls_n_direct_sum_len,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 dq ls_n_compose,ls_n_compose_len,NEBOC_TOKEN_LINEAR_COMPOSE
 dq ls_n_orthogonal,ls_n_orthogonal_len,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 dq ls_n_parallel,ls_n_parallel_len,NEBOC_TOKEN_LINEAR_PARALLEL
ls_g134_method_count equ 8
ls_n_to: db 'to'
ls_n_to_len equ $-ls_n_to
ls_n_min: db 'min'
ls_n_min_len equ $-ls_n_min
ls_n_max: db 'max'
ls_n_max_len equ $-ls_n_max
ls_n_count_missing: db 'countMissing'
ls_n_count_missing_len equ $-ls_n_count_missing
ls_n_join: db 'join'
ls_n_join_len equ $-ls_n_join
ls_n_with_capacity: db 'withCapacity'
ls_n_with_capacity_len equ $-ls_n_with_capacity
ls_n_value: db 'value'
ls_n_value_len equ $-ls_n_value
ls_n_uncertain: db 'Uncertain'
ls_n_uncertain_len equ $-ls_n_uncertain
ls_n_measurement: db 'Measurement'
ls_n_measurement_len equ $-ls_n_measurement
ls_n_mutate: db 'mutate'
ls_n_mutate_len equ $-ls_n_mutate
ls_n_async: db 'async'
ls_n_async_len equ $-ls_n_async

; Expected and explicitly rejected alternate semantic-wrapper names.  Each row
; is expected pointer,length, alternate pointer,length, bounded diagnostic.
ls_wrapper_specs:
 dq ls_n_event,ls_n_event_len,ls_n_stream,ls_n_stream_len,11
 dq ls_n_node,ls_n_node_len,ls_n_graph,ls_n_graph_len,12
 dq ls_n_callback,ls_n_callback_len,ls_n_lambda,ls_n_lambda_len,13
 dq ls_n_call_behavior,ls_n_call_behavior_len,ls_n_call_policy,ls_n_call_policy_len,14
 dq ls_n_flow,ls_n_flow_len,ls_n_pipeline,ls_n_pipeline_len,15
 dq ls_n_loop,ls_n_loop_len,ls_n_control,ls_n_control_len,16
 dq ls_n_pattern,ls_n_pattern_len,ls_n_match,ls_n_match_len,17
 dq ls_n_task,ls_n_task_len,ls_n_scheduler,ls_n_scheduler_len,18
ls_wrapper_spec_count equ 8
ls_n_event: db 'Event'
ls_n_event_len equ $-ls_n_event
ls_n_stream: db 'Stream'
ls_n_stream_len equ $-ls_n_stream
ls_n_node: db 'Node'
ls_n_node_len equ $-ls_n_node
ls_n_graph: db 'Graph'
ls_n_graph_len equ $-ls_n_graph
ls_n_callback: db 'Callback'
ls_n_callback_len equ $-ls_n_callback
ls_n_lambda: db 'Lambda'
ls_n_lambda_len equ $-ls_n_lambda
ls_n_call_behavior: db 'CallBehavior'
ls_n_call_behavior_len equ $-ls_n_call_behavior
ls_n_call_policy: db 'CallPolicy'
ls_n_call_policy_len equ $-ls_n_call_policy
ls_n_flow: db 'Flow'
ls_n_flow_len equ $-ls_n_flow
ls_n_pipeline: db 'Pipeline'
ls_n_pipeline_len equ $-ls_n_pipeline
ls_n_loop: db 'Loop'
ls_n_loop_len equ $-ls_n_loop
ls_n_control: db 'Control'
ls_n_control_len equ $-ls_n_control
ls_n_pattern: db 'Pattern'
ls_n_pattern_len equ $-ls_n_pattern
ls_n_match: db 'Match'
ls_n_match_len equ $-ls_n_match
ls_n_task: db 'Task'
ls_n_task_len equ $-ls_n_task
ls_n_scheduler: db 'Scheduler'
ls_n_scheduler_len equ $-ls_n_scheduler

section .bss align=16
ls_request: resq 1
ls_source: resq 1
ls_tokens: resq 1
ls_token_count: resq 1
ls_cursor: resq 1
ls_mode: resq 1
ls_scalar_name: resq 1
ls_scalar_value: resq 1
ls_collection_count: resq 1
ls_collection_names: resq LS_COLLECTION_CAPACITY
ls_collection_values: resq LS_COLLECTION_CAPACITY*LS_COLLECTION_VALUES
ls_collection_value_counts: resq LS_COLLECTION_CAPACITY
ls_g134_result_values: resq LS_COLLECTION_VALUES
ls_wrapper_spec: resq 1
ls_tensor_source_name: resq 1
ls_tensor_source_extent: resq 1
ls_tensor_filled_binding: resq 1
ls_tensor_filled_rank: resq 1
ls_tensor_filled_dim0: resq 1
ls_tensor_filled_dim1: resq 1
ls_tensor_filled_dim2: resq 1
ls_tensor_filled_count: resq 1
ls_tensor_filled_value: resq 1
ls_scratch_end:

section .text

; ---------------------------------------------------------------------------
; Shared token primitives.  These inspect canonical lexer tokens and never
; hash the complete source or depend on source byte length/profile identity.
; ---------------------------------------------------------------------------

; RDI token index -> RAX token pointer or zero.
ls_token_ptr:
 cmp rdi,[rel ls_token_count]
 jae .bad
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 ret
.bad:
 xor eax,eax
 ret

; RDI token index -> RAX token kind, INVALID when out of range.
ls_kind_at:
 sub rsp,8
 call ls_token_ptr
 add rsp,8
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 ret
.bad:
 xor eax,eax
 ret

; RDI token index, RSI bytes, RDX length -> EAX boolean.
ls_token_match:
 cmp rdi,[rel ls_token_count]
 jae .no
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rcx,rdx
 jne .no
 mov r8,[rel ls_source]
 add r8,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r8+rcx]
 cmp al,[rsi+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; RDI first token index, RSI second token index -> EAX boolean lexeme equality.
ls_name_equal:
 cmp rdi,[rel ls_token_count]
 jae .no
 cmp rsi,[rel ls_token_count]
 jae .no
 imul rax,rdi,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 imul rcx,rsi,NEBOC_TOKEN_SIZE
 add rcx,[rel ls_tokens]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov r8,[rcx+NEBOC_TOKEN_END_OFFSET]
 sub r8,[rcx+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,r8
 jne .no
 mov r9,[rel ls_source]
 mov r10,r9
 add r9,[rax+NEBOC_TOKEN_START_OFFSET]
 add r10,[rcx+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r9+rcx]
 cmp al,[r10+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes:
 mov eax,1
 ret
.no:
 xor eax,eax
 ret

; EDI expected kind -> EAX boolean, advances global cursor on success.
ls_expect_kind:
 sub rsp,8
 mov r9d,edi
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,r9d
 jne .no
 inc qword [rel ls_cursor]
 mov eax,1
 add rsp,8
 ret
.no:
 xor eax,eax
 add rsp,8
 ret

; RSI atom, EDX length -> EAX boolean, advances cursor on success.
ls_expect_atom:
 sub rsp,8
 mov rdi,[rel ls_cursor]
 call ls_token_match
 test eax,eax
 jz .done
 inc qword [rel ls_cursor]
.done:
 add rsp,8
 ret

; Parse optional minus plus INTEGER at global cursor.
; EAX=1 success, RDX=signed value; EAX=0 leaves cursor unchanged.
ls_parse_signed_int:
 sub rsp,8
 mov r8,[rel ls_cursor]
 mov rdi,r8
 call ls_kind_at
 xor r9d,r9d
 cmp eax,NEBOC_TOKEN_MINUS
 jne .integer
 mov r9d,1
 inc r8
 mov rdi,r8
 call ls_kind_at
.integer:
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .no
 mov rdi,r8
 call ls_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r9d,r9d
 jz .store
 neg rdx
.store:
 inc r8
 mov [rel ls_cursor],r8
 mov eax,1
 add rsp,8
 ret
.no:
 xor eax,eax
 add rsp,8
 ret

; Validate start() { and leave cursor at first statement.
ls_start_header:
 sub rsp,8
 mov edi,NEBOC_TOKEN_KW_START
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 ret

; Require ; } EOF after one final expression.
ls_finish_program:
 sub rsp,8
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_EOF
 call ls_expect_kind
 test eax,eax
 jz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 ret

; Clear bounded shared compiler scratch and initialize common request fields.
; RDI request.  EAX=1 valid, 0 invalid.
ls_initialize:
 push rbp
 mov rbp,rsp
 sub rsp,16
 mov [rsp],rdi
 lea rdi,[rel ls_source]
 mov ecx,(ls_scratch_end-ls_source)/8
 xor eax,eax
 rep stosq
 mov rdi,[rsp]
 mov [rel ls_request],rdi
 test rdi,rdi
 jz .bad
 test rdi,7
 jnz .bad
 mov rax,[rdi]
 mov [rel ls_source],rax
 mov rax,[rdi+56]
 mov [rel ls_tokens],rax
 mov rax,[rdi+64]
 mov [rel ls_token_count],rax
 cmp qword [rel ls_source],0
 je .bad
 cmp qword [rel ls_tokens],0
 je .bad
 cmp qword [rel ls_token_count],0
 je .bad
 mov qword [rdi+16],0
 mov qword [rdi+24],0
 mov qword [rdi+32],0
 mov qword [rdi+40],0
 mov qword [rdi+48],0
 mov qword [rel ls_scalar_name],LS_NO_TOKEN
 mov eax,1
 jmp .done
.bad:
 xor eax,eax
.done:
 leave
 ret

; EDI diagnostic -> INVALID_SOURCE and found=1.
ls_error:
 mov rax,[rel ls_request]
 mov qword [rax+16],1
 mov [rax+24],rdi
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; RDI output, RSI flags, RDX structural family key -> success.
ls_success:
 mov rax,[rel ls_request]
 mov qword [rax+16],1
 mov qword [rax+24],0
 mov [rax+32],rdi
 mov [rax+40],rsi
 xor rdx,rdi
 mov [rax+48],rdx
 xor eax,eax
 ret

; Current token atom match helper. RSI atom, EDX length -> EAX.
ls_current_atom:
 sub rsp,8
 mov rdi,[rel ls_cursor]
 call ls_token_match
 add rsp,8
 ret

; Scan all tokens for atom. RSI atom, EDX len -> EAX bool.
ls_contains_atom:
 push rbx
 sub rsp,16
 mov [rsp],rsi
 mov [rsp+8],rdx
 xor ebx,ebx
.loop:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,[rsp+8]
 call ls_token_match
 test eax,eax
 jnz .yes
 inc rbx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop rbx
 ret

; Current typed operator groups are owned by the Pratt/type/codegen pipeline.
; Keep the historical collection recognizer disjoint when it sees their
; public constructors or any exact Registry-backed UTF-8 token.
g131_is_program:
 push rbx
 sub rsp,16
 lea rsi,[rel ls_n_uncertain]
 mov edx,ls_n_uncertain_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 lea rsi,[rel ls_n_measurement]
 mov edx,ls_n_measurement_len
 call ls_contains_atom
 test eax,eax
 jnz .yes
 xor ebx,ebx
.loop:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS_MINUS
 je .yes
 cmp eax,NEBOC_TOKEN_APPROX_EQUAL
 je .yes
 cmp eax,NEBOC_TOKEN_NOT_APPROX_EQUAL
 je .yes
 cmp eax,NEBOC_TOKEN_EQUIVALENT
 je .yes
 cmp eax,NEBOC_TOKEN_DIVIDES
 je .yes
 cmp eax,NEBOC_TOKEN_NOT_DIVIDES
 je .yes
 cmp eax,NEBOC_TOKEN_PROPORTIONAL
 je .yes
 cmp eax,NEBOC_TOKEN_SET_MEMBERSHIP
 je .yes
 cmp eax,NEBOC_TOKEN_SET_NON_MEMBERSHIP
 je .yes
 cmp eax,NEBOC_TOKEN_SET_UNION
 je .yes
 cmp eax,NEBOC_TOKEN_SET_INTERSECTION
 je .yes
 cmp eax,NEBOC_TOKEN_SET_DIFFERENCE
 je .yes
 cmp eax,NEBOC_TOKEN_SET_SYMMETRIC_DIFFERENCE
 je .yes
 cmp eax,NEBOC_TOKEN_SET_SUBSET
 je .yes
 cmp eax,NEBOC_TOKEN_SET_PROPER_SUBSET
 je .yes
 cmp eax,NEBOC_TOKEN_SET_SUPERSET
 je .yes
 cmp eax,NEBOC_TOKEN_SET_PROPER_SUPERSET
 je .yes
 cmp eax,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .yes
 cmp eax,NEBOC_TOKEN_EMPTY_SET
 je .yes
 inc rbx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop rbx
 ret

; Find collection record by binding-name token index RDI.
; RAX record index, or -1.
ls_find_collection:
 xor ecx,ecx
.loop:
 cmp rcx,[rel ls_collection_count]
 jae .no
 mov rsi,[ls_collection_names+rcx*8]
 push rcx
 call ls_name_equal
 pop rcx
 test eax,eax
 jnz .yes
 inc rcx
 jmp .loop
.yes:
 mov rax,rcx
 ret
.no:
 mov rax,-1
 ret

; Parse exactly one [signed Int,...] list into record RDI (0 or 1).
; EAX=0 success, positive diagnostic on bounded semantic failure, -1 syntax.
ls_parse_int4_list:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 sub rsp,16
 mov r12,rdi
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor ebx,ebx
.loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .done_values
 cmp ebx,LS_COLLECTION_VALUES
 jae .arity_skip
 call ls_parse_signed_int
 test eax,eax
 jz .type
 mov rax,r12
 imul rax,LS_COLLECTION_VALUES
 add rax,rbx
 mov [ls_collection_values+rax*8],rdx
 inc ebx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .done_values
 inc qword [rel ls_cursor]
 jmp .loop
.arity_skip:
 ; Additional valid signed integers still prove arity rather than syntax/type.
 call ls_parse_signed_int
 test eax,eax
 jz .type
 inc ebx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .done_values
 inc qword [rel ls_cursor]
 jmp .arity_skip
.done_values:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov [ls_collection_value_counts+r12*8],rbx
 cmp ebx,LS_COLLECTION_VALUES
 jne .arity
 xor eax,eax
 jmp .done
.arity:
 mov eax,1
 jmp .done
.type:
 mov eax,2
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,16
 pop r12
 pop rbx
 pop rbp
 ret

; Parse `.binding;` and commit collection record RDI.
ls_parse_collection_binding:
 push rbp
 mov rbp,rsp
 push rbx
 sub rsp,8
 mov rbx,rdi
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rel ls_cursor]
 mov [ls_collection_names+rbx*8],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rax,rbx
 inc rax
 cmp rax,[rel ls_collection_count]
 jbe .yes
 mov [rel ls_collection_count],rax
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rbx
 pop rbp
 ret

; Parse one collection atom for Array/Vector/Column.
; EDI mode (10,11,12).  EAX status: 0 success, >0 diagnostic, -1 syntax.
; RDX evaluated value.
ls_parse_collection_atom:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r13,[rel ls_cursor]
 inc qword [rel ls_cursor]
 mov rdi,r13
 call ls_find_collection
 cmp rax,-1
 je .constant
 mov rbx,rax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .index
 cmp eax,NEBOC_TOKEN_DOT
 jne .syntax
 inc qword [rel ls_cursor]
 ; Method/member token.
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov r13,[rel ls_cursor]
 inc qword [rel ls_cursor]
 mov rdi,r13
 lea rsi,[rel ls_n_len]
 mov edx,ls_n_len_len
 call ls_token_match
 test eax,eax
 jnz .length
 cmp r12,10
 je .mutation
 mov rdi,r13
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_token_match
 test eax,eax
 jnz .sum
 cmp r12,11
 je .vector_methods
 ; Column-only methods.
 mov rdi,r13
 lea rsi,[rel ls_n_min]
 mov edx,ls_n_min_len
 call ls_token_match
 test eax,eax
 jnz .min
 mov rdi,r13
 lea rsi,[rel ls_n_max]
 mov edx,ls_n_max_len
 call ls_token_match
 test eax,eax
 jnz .max
 mov rdi,r13
 lea rsi,[rel ls_n_count_missing]
 mov edx,ls_n_count_missing_len
 call ls_token_match
 test eax,eax
 jnz .count_missing
 mov rdi,r13
 lea rsi,[rel ls_n_join]
 mov edx,ls_n_join_len
 call ls_token_match
 test eax,eax
 jnz .join
 jmp .dtype
.vector_methods:
 mov rdi,r13
 lea rsi,[rel ls_n_dot]
 mov edx,ls_n_dot_len
 call ls_token_match
 test eax,eax
 jnz .dot
 mov rdi,r13
 lea rsi,[rel ls_n_to]
 mov edx,ls_n_to_len
 call ls_token_match
 test eax,eax
 jnz .device
 jmp .dtype
.length:
 mov edx,4
 xor eax,eax
 jmp .done
.index:
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_MINUS
 je .bounds_consume
 cmp eax,NEBOC_TOKEN_INTEGER
 je .constant_index
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .constant_consume
 jmp .constant
.bounds_consume:
 call ls_parse_signed_int
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 mov eax,3
 jmp .done
.constant_index:
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 mov rcx,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 cmp rcx,4
 jae .bounds
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 mov rdx,[ls_collection_values+rax*8]
 xor eax,eax
 jmp .done
.constant_consume:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 mov eax,4
 jmp .done
.constant:
 mov eax,4
 jmp .done
.bounds:
 mov eax,3
 jmp .done
.mutation:
 mov eax,5
 jmp .done
.sum:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor r13d,r13d
 xor ecx,ecx
.sum_loop:
 cmp ecx,LS_COLLECTION_VALUES
 jae .sum_ok
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 mov rdx,[ls_collection_values+rax*8]
 mov r8,r13
 add r8,rdx
 jo .overflow
 mov r13,r8
 inc ecx
 jmp .sum_loop
.sum_ok:
 mov rdx,r13
 xor eax,eax
 jmp .done
.min:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 mov rdx,[ls_collection_values+rax*8]
 mov ecx,1
.min_loop:
 cmp ecx,LS_COLLECTION_VALUES
 jae .method_ok
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 mov r8,[ls_collection_values+rax*8]
 cmp r8,rdx
 cmovl rdx,r8
 inc ecx
 jmp .min_loop
.max:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 mov rdx,[ls_collection_values+rax*8]
 mov ecx,1
.max_loop:
 cmp ecx,LS_COLLECTION_VALUES
 jae .method_ok
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 mov r8,[ls_collection_values+rax*8]
 cmp r8,rdx
 cmovg rdx,r8
 inc ecx
 jmp .max_loop
.count_missing:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor edx,edx
.method_ok:
 xor eax,eax
 jmp .done
.join:
 mov eax,9
 jmp .done
.dot:
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 inc qword [rel ls_cursor]
 call ls_find_collection
 cmp rax,-1
 je .constant
 mov r13,rax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor edx,edx
 xor ecx,ecx
.dot_loop:
 cmp ecx,LS_COLLECTION_VALUES
 jae .dot_ok
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 mov r8,[ls_collection_values+rax*8]
 mov rax,r13
 imul rax,LS_COLLECTION_VALUES
 add rax,rcx
 imul r8,[ls_collection_values+rax*8]
 jo .overflow
 mov r9,rdx
 add r9,r8
 jo .overflow
 mov rdx,r9
 inc ecx
 jmp .dot_loop
.dot_ok:
 xor eax,eax
 jmp .done
.device:
 mov eax,8
 jmp .done
.dtype:
 mov eax,5
 jmp .done
.overflow:
 mov eax,10
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; ---------------------------------------------------------------------------
; colecoes_primitivas Array<Int,4>
; ---------------------------------------------------------------------------
NEBOC_ABI_FUNCTION neboc_array_vertical_recognize
 push rbp
 mov rbp,rsp
 sub rsp,16
 call ls_initialize
 test eax,eax
 jz .invalid
 mov qword [rel ls_mode],10
 ; G131 sources belong to the typed uncertainty/operator owner and must never
 ; enter this legacy Array<Int,4> compatibility grammar.
 call g131_is_program
 test eax,eax
 jnz .not_owned
 ; The SlashPlan root is disjoint from RenderPlan and owns the bounded Slash
 ; micro-language before the broader textual/rendering verticals.
 call sc_is_program
 test eax,eax
 jnz .slash_core
 ; G029 owns its disjoint contract/proof micro-language before the adjacent
 ; solver and metaprogramming owners can interpret shared formal atoms.
 call g29_is_program
 test eax,eax
 jnz .g029
 ; G030 owns its disjoint formal-methods micro-language before broad textual
 ; or metaprogramming owners can interpret shared atoms.
 call g30_is_program
 test eax,eax
 jnz .g030
 ; G046 owns the compiler-platform API micro-language before generic method
 ; names such as add, transform, and report reach broader owners.
 call g46_is_program
 test eax,eax
 jnz .g046
 ; G035 owns the bounded exact/scientific-math micro-language before broad
 ; numeric and collection recognizers can interpret shared method atoms.
 call g35_is_program
 test eax,eax
 jnz .g035
 call g28_is_program
 test eax,eax
 jnz .g028
 ; G084 owns the disjoint RF84 integration/closeout evidence facade.
 call g84_is_program
 test eax,eax
 jnz .g084
 ; G083 owns the disjoint regex/formatter/linter/LSP evidence facade.
 call g83_is_program
 test eax,eax
 jnz .g083
 ; G082 owns bounded Text collection/data programs before format-specific roots.
 call g82_is_program
 test eax,eax
 jnz .g082
 ; G081 owns bounded advanced textual formats before the concrete G080 layer.
 call g81_is_program
 test eax,eax
 jnz .g081
 ; G080 owns concrete CSV/TSV/JSON/JSONL grammars before common formats.
 call g80_is_program
 test eax,eax
 jnz .g080
 ; G079 owns common bounded format contracts before concrete format grammars.
 call g79_is_program
 test eax,eax
 jnz .g079
 ; G116 owns the RF116 closeout profile before every constituent profile.
 call g116_is_program
 test eax,eax
 jnz .g116
 ; G115 owns the Console ABI renderer-plugin profile before G114/G104.
 call g115_is_program
 test eax,eax
 jnz .g115
 ; G114 owns the export-privacy-service RenderPlan profile before G113/G104.
 call g114_is_program
 test eax,eax
 jnz .g114
 ; G113 owns the domain-visual-service RenderPlan profile before G112/G104.
 call g113_is_program
 test eax,eax
 jnz .g113
 ; G112 owns the chart-table-service RenderPlan profile before G111/G104.
 call g112_is_program
 test eax,eax
 jnz .g112
 ; G111 owns the observability-service RenderPlan profile before G110/G104.
 call g111_is_program
 test eax,eax
 jnz .g111
 ; G110 owns the narrow internal-service RenderPlan profile before G104 and
 ; the earlier Console schema families.
 call g110_is_program
 test eax,eax
 jnz .g110
 ; G109 owns structured diagnostics before testability and earlier Console schemas.
 call g109_is_program
 test eax,eax
 jnz .g109
 ; G108 owns deterministic capture/replay before earlier Console schemas.
 call g108_is_program
 test eax,eax
 jnz .g108
 ; G107 owns explicit sink routing before earlier Console schema families.
 call g107_is_program
 test eax,eax
 jnz .g107
 ; G106 owns explicit privacy schema composition before visual/source families.
 call g106_is_program
 test eax,eax
 jnz .g106
 ; G105 owns the bounded ScanPlan/Console composition before the inherited
 ; G075-G078 ScanPlan families inspect their individual surface subsets.
 call g105_is_program
 test eax,eax
 jnz .g105
 ; G078 owns bounded ScanPlan multiline/editor/source/form metadata programs.
 call g78_is_program
 test eax,eax
 jnz .g078
 ; G077 owns bounded ScanPlan privacy, cancellation/EOF, and safe parsing.
 call g77_is_program
 test eax,eax
 jnz .g077
 ; G076 owns bounded ScanPlan validation, choices, retry and UX.
 call g76_is_program
 test eax,eax
 jnz .g076
 ; G075 owns the bounded ScanPlan type/empty/normalization vertical.
 call g75_is_program
 test eax,eax
 jnz .g075
 ; G104 owns the complete live-console profile before its G103 subset.
 call g104_is_program
 test eax,eax
 jnz .g104
 ; G103 owns the complete internal headless JSONL contract before older visual families.
 call g103_is_program
 test eax,eax
 jnz .g103
 ; G102 owns animation, capture and export roots before older visual families.
 call g102_is_program
 test eax,eax
 jnz .g102
 ; G101 owns bounded large-data visual roots before observability and older views.
 call g101_is_program
 test eax,eax
 jnz .g101
 ; G100 owns bounded live observability roots before dashboard and older views.
 call g100_is_program
 test eax,eax
 jnz .g100
 ; G099 owns dashboard/panel/cell roots before graph, scientific and layout views.
 call g99_is_program
 test eax,eax
 jnz .g099
 ; G098 owns graph/tree/embedding/projection roots before scientific and 3D views.
 call g98_is_program
 test eax,eax
 jnz .g098
 ; G097 owns bounded scientific Matrix/Tensor/Volume roots before 3D/2D views.
 call g97_is_program
 test eax,eax
 jnz .g097
 ; G096 owns target-neutral 3D scene roots before 2D/chart/layout families.
 call g96_is_program
 test eax,eax
 jnz .g096
 ; G095 owns target-neutral 2D chart roots before G094, G018 and RF84 families.
 call g95_is_program
 test eax,eax
 jnz .g095
 ; G094 owns bounded structured-view roots before layout and RF84 families.
 call g94_is_program
 test eax,eax
 jnz .g094
 ; G093 owns composite-layout roots before style, geometry and RF84 families.
 call g93_is_program
 test eax,eax
 jnz .g093
 ; G092 owns style/status/typography roots before layout and RF84 families.
 call g92_is_program
 test eax,eax
 jnz .g092
 ; G091 owns ConsoleDocument geometry roots before G090/RF84 Console families.
 call g91_is_program
 test eax,eax
 jnz .g091
 ; G090 owns typed adapter model roots before G089/RF84 Console families.
 call g90_is_program
 test eax,eax
 jnz .g090
 ; G089 owns its nominal ConsoleCall/ConsoleOption/RenderIntent model before
 ; the RF84 RenderPlan owners can claim shared console and plan atoms.
 call g89_is_program
 test eax,eax
 jnz .g089
 ; G072's complete target/sink signatures precede G069 because the explicit
 ; JSON target profile legitimately shares RenderPlan and json atoms.
 call g72_is_program
 test eax,eax
 jnz .g072
 ; G069's specific developer-view witnesses precede G073's intentionally
 ; broader explain marker, which is shared by diagnostic inspection views.
 call g69_is_program
 test eax,eax
 jnz .g069
 ; G074 owns policy/catalog/editor closeout before broader RenderPlan groups.
 call g74_is_program
 test eax,eax
 jnz .g074
 ; G073 owns bounded testability/education/conditional/scoped rendering.
 call g73_is_program
 test eax,eax
 jnz .g073
 ; G071 owns security/policy rendering before operational/developer roots.
 call g71_is_program
 test eax,eax
 jnz .g071
 ; G070 owns operational rendering before developer/layout/style/base roots.
 call g70_is_program
 test eax,eax
 jnz .g070
 ; G068 owns structured layout programs before style/base RenderPlan roots.
 call g68_is_program
 test eax,eax
 jnz .g068
 ; G067 owns styled RenderPlan programs before G066 claims the shared root.
 call g67_is_program
 test eax,eax
 jnz .g067
 ; G066 owns base RenderPlan/Console programs before formatting or historical
 ; Text recognizers can claim shared atoms such as pad, join or console.
 call g66_is_program
 test eax,eax
 jnz .g066
 ; G063 owns raw/multiline/tagged templates before interpolation and the more
 ; general formatting chains can claim shared Text atoms.
 call g63_is_program
 test eax,eax
 jnz .g063
 ; G060 owns statically validated percent templates before typed profiles and
 ; the more general G059 format chain can claim shared format atoms.
 call g61_is_program
 test eax,eax
 jnz .g061
 call g60_is_program
 test eax,eax
 jnz .g060
 ; G062 owns typed profiles before the more general G059 format chain.
 call g62_is_program
 test eax,eax
 jnz .g062
 ; G059 owns typed formatting and the format(...).console() chain before media,
 ; visual or historical Text recognizers can claim their shared atoms.
 call g59_is_program
 test eax,eax
 jnz .g059
 ; G088 owns typed color-role programs before the Color value/media verticals.
 call g88_is_program
 test eax,eax
 jnz .g088
 ; G087 owns the public Color value surface before the older media vertical can
 ; interpret the shared Color/rgb/rgba atoms.
 call g87_is_program
 test eax,eax
 jnz .g087
 ; G019 public media programs are complete token-owned verticals. Select them
 ; before visual and historical collection recognizers interpret shared image,
 ; color, line, frame or stream atoms.
 call g19_is_program
 test eax,eax
 jnz .g019
 ; G018 public visual programs are complete token-owned verticals. Select them
 ; before historical collection recognizers interpret shared atoms such as
 ; row, column, line or text.
 call g18_is_program
 test eax,eax
 jnz .g018
 xor ecx,ecx
.declaration_guard_10:
 cmp rcx,[rel ls_token_count]
 jae .declaration_guard_10_done
 imul rax,rcx,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp eax,NEBOC_TOKEN_KW_STRUCT
 je .not_owned
 cmp eax,NEBOC_TOKEN_KW_ENUM
 je .not_owned
 inc rcx
 jmp .declaration_guard_10
.declaration_guard_10_done:
 ; A canonical borrowed-Slice conversion belongs to array_range, not to this
 ; legacy collection owner.  Match the token sequence structurally so an
 ; unrelated binding named asSlice does not affect ownership.
 mov qword [rbp-8],0
.canonical_slice_scan:
 mov rcx,[rbp-8]
 cmp rcx,[rel ls_token_count]
 jae .canonical_slice_scan_done
 mov rdi,rcx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .canonical_slice_scan_next
 mov rdi,[rbp-8]
 inc rdi
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .canonical_slice_scan_next
 mov rdi,[rbp-8]
 inc rdi
 lea rsi,[rel ls_n_as_slice]
 mov edx,ls_n_as_slice_len
 call ls_token_match
 test eax,eax
 jz .canonical_slice_scan_next
 mov rdi,[rbp-8]
 add rdi,2
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .canonical_slice_scan_next
 mov rdi,[rbp-8]
 add rdi,3
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .not_owned
.canonical_slice_scan_next:
 inc qword [rbp-8]
 jmp .canonical_slice_scan
.canonical_slice_scan_done:
 ; G016 corrected Tensor programs must precede the historical bounded Tensor
 ; recognizer, just as G015 precedes the historical Matrix profile.
 call g16_is_program
 test eax,eax
 jnz .g016
 ; G015 corrected dense Matrix programs must precede the historical bounded
 ; Matrix recognizer, which intentionally owns only the earlier C11 profile.
 call g15_is_program
 test eax,eax
 jnz .g015
 ; G014 owns complete public math programs before generic Vector and Random
 ; owners. These discriminators are specific to the corrected contract.
 lea rsi,[rel g14_n_hypot]
 mov edx,g14_n_hypot_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
 lea rsi,[rel g14_n_atan2]
 mov edx,g14_n_atan2_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
 lea rsi,[rel g14_n_approx_equals]
 mov edx,g14_n_approx_equals_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
 lea rsi,[rel g14_n_standard_deviation]
 mov edx,g14_n_standard_deviation_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
 lea rsi,[rel g14_n_categorical]
 mov edx,g14_n_categorical_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
 lea rsi,[rel g14_n_normalize]
 mov edx,g14_n_normalize_len
 call ls_contains_atom
 test eax,eax
 jz .g014_normalize_not_owned
 lea rsi,[rel g14_n_vector_type]
 mov edx,g14_n_vector_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g014
.g014_normalize_not_owned:
 ; Preserve deferred ownership priority structurally.
 lea rsi,[rel g13_n_thread]
 mov edx,g13_n_thread_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_task_group]
 mov edx,g13_n_task_group_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_future]
 mov edx,g13_n_future_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_cancellation_token]
 mov edx,g13_n_cancellation_token_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_channel]
 mov edx,g13_n_channel_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_mutex]
 mov edx,g13_n_mutex_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 lea rsi,[rel g13_n_scheduler]
 mov edx,g13_n_scheduler_len
 call ls_contains_atom
 test eax,eax
 jnz .g013
 ; Bounded database programs use current-only public type atoms and must be
 ; selected before generic Query, Stream, Table and transaction heuristics.
 lea rsi,[rel g32_n_database_type]
 mov edx,g32_n_database_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g032
 lea rsi,[rel g32_n_db_schema_type]
 mov edx,g32_n_db_schema_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g032
 lea rsi,[rel g32_n_storage_options_type]
 mov edx,g32_n_storage_options_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g032
 lea rsi,[rel g32_n_query_type]
 mov edx,g32_n_query_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g032
 lea rsi,[rel g32_n_migration_type]
 mov edx,g32_n_migration_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g032
 ; Bounded reactive programs use current-only public type atoms and must be
 ; selected before generic Stream, List, Graph and Cell recognizers.
 lea rsi,[rel g31_n_signal_type]
 mov edx,g31_n_signal_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g31_n_cell_type]
 mov edx,g31_n_cell_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g31_n_computed_type]
 mov edx,g31_n_computed_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g31_n_reactive_list_type]
 mov edx,g31_n_reactive_list_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g31_n_dataflow_graph_type]
 mov edx,g31_n_dataflow_graph_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g31_n_reactive]
 mov edx,g31_n_reactive_len
 call ls_contains_atom
 test eax,eax
 jnz .g031
 lea rsi,[rel g12_n_instant]
 mov edx,g12_n_instant_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_random]
 mov edx,g12_n_random_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_process]
 mov edx,g12_n_process_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_ip_address]
 mov edx,g12_n_ip_address_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_tcp_listener]
 mov edx,g12_n_tcp_listener_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_http_request]
 mov edx,g12_n_http_request_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g12_n_sha256]
 mov edx,g12_n_sha256_len
 call ls_contains_atom
 test eax,eax
 jnz .g012
 lea rsi,[rel g11_n_path_type]
 mov edx,g11_n_path_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel g11_n_file_type]
 mov edx,g11_n_file_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel g11_n_directory_type]
 mov edx,g11_n_directory_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel g11_n_binary_encoder]
 mov edx,g11_n_binary_encoder_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel g11_n_json]
 mov edx,g11_n_json_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel g11_n_csv]
 mov edx,g11_n_csv_len
 call ls_contains_atom
 test eax,eax
 jnz .g011
 lea rsi,[rel ls_n_list]
 mov edx,ls_n_list_len
 call ls_contains_atom
 test eax,eax
 jnz .g007
 lea rsi,[rel ls_n_stack]
 mov edx,ls_n_stack_len
 call ls_contains_atom
 test eax,eax
 jnz .g007
 lea rsi,[rel ls_n_queue]
 mov edx,ls_n_queue_len
 call ls_contains_atom
 test eax,eax
 jnz .g007
 lea rsi,[rel ls_n_deque]
 mov edx,ls_n_deque_len
 call ls_contains_atom
 test eax,eax
 jnz .g007
 lea rsi,[rel g8_n_hasher]
 mov edx,g8_n_hasher_len
 call ls_contains_atom
 test eax,eax
 jnz .g008
 lea rsi,[rel g8_n_set_type]
 mov edx,g8_n_set_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g008
 lea rsi,[rel ls_n_dict]
 mov edx,ls_n_dict_len
 call ls_contains_atom
 test eax,eax
 jnz .g008
 lea rsi,[rel g9_n_node]
 mov edx,g9_n_node_len
 call ls_contains_atom
 test eax,eax
 jz .g009_tree
 lea rsi,[rel g9_n_replace_value]
 mov edx,g9_n_replace_value_len
 call ls_contains_atom
 test eax,eax
 jnz .g009
.g009_tree:
 lea rsi,[rel g9_n_tree]
 mov edx,g9_n_tree_len
 call ls_contains_atom
 test eax,eax
 jnz .g009
 lea rsi,[rel g9_n_graph]
 mov edx,g9_n_graph_len
 call ls_contains_atom
 test eax,eax
 jnz .g009
 lea rsi,[rel g10_n_schema_type]
 mov edx,g10_n_schema_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 lea rsi,[rel g10_n_row_type]
 mov edx,g10_n_row_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 lea rsi,[rel g10_n_table_type]
 mov edx,g10_n_table_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 lea rsi,[rel g10_n_dataset_type]
 mov edx,g10_n_dataset_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 ; General Column and Stream programs are distinguished from the historical
 ; bounded profiles by current-contract operations.
 lea rsi,[rel g10_n_cast]
 mov edx,g10_n_cast_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 lea rsi,[rel g10_n_drop_missing]
 mov edx,g10_n_drop_missing_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 lea rsi,[rel g10_n_batch]
 mov edx,g10_n_batch_len
 call ls_contains_atom
 test eax,eax
 jnz .g010
 ; G025 owns only current security/policy public type atoms.  It must run
 ; before the historical Policy/Quality recognizers later in this file.
 lea rsi,[rel g25_n_file_capability]
 mov edx,g25_n_file_capability_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_effects]
 mov edx,g25_n_effects_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_permit]
 mov edx,g25_n_permit_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_sensitive_type]
 mov edx,g25_n_sensitive_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_metrics]
 mov edx,g25_n_metrics_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_provenance_type]
 mov edx,g25_n_provenance_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel g25_n_audit_type]
 mov edx,g25_n_audit_type_len
 call ls_contains_atom
 test eax,eax
 jnz .g025
 lea rsi,[rel ls_n_array]
 mov edx,ls_n_array_len
 call ls_contains_atom
 test eax,eax
 jnz .claimed
 ; An untyped bracket literal is the legacy bounded Array surface.
 xor ecx,ecx
.claim_scan:
 cmp rcx,[rel ls_token_count]
 jae .not_owned
 mov rdi,rcx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_LBRACKET
 je .claimed
 inc rcx
 jmp .claim_scan
.claimed:
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 ; Optional unrelated scalar binding used to prove dynamic-index rejection.
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 je .scalar
 cmp eax,NEBOC_TOKEN_MINUS
 jne .explicit
.scalar:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel ls_scalar_value],rdx
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[rel ls_cursor]
 mov [rel ls_scalar_name],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .syntax
.explicit:
 lea rsi,[rel ls_n_array]
 mov edx,ls_n_array_len
 call ls_current_atom
 test eax,eax
 jz .literal
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .capacity
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .capacity
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .capacity
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 test rax,rax
 jz .capacity
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .capacity
 cmp qword [rax+NEBOC_TOKEN_PAYLOAD_OFFSET],4
 jne .capacity
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .capacity
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 je .capacity
.literal:
 xor edi,edi
 call ls_parse_int4_list
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 xor edi,edi
 call ls_parse_collection_binding
 test eax,eax
 jz .syntax
 mov edi,10
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_EQUAL
 je .mutation
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 mov edi,10
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov rax,[rsp]
 add rax,rdx
 jo .mutation
 mov [rsp],rax
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_ARRAY_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323747313000
 call ls_success
 jmp .done
.semantic:
 mov edi,eax
 call ls_error
 jmp .done
.g007:
 call neboc_g007_source_parse
 jmp .done
.g008:
 call neboc_g008_source_parse
 jmp .done
.g009:
 call neboc_g009_source_parse
 jmp .done
.g010:
 call neboc_g010_source_parse
 jmp .done
.g025:
 call neboc_g025_source_parse
 jmp .done
.g031:
 call neboc_g031_source_parse
 jmp .done
.g032:
 call neboc_g032_source_parse
 jmp .done
.g014:
 call neboc_g014_source_parse
 jmp .done
.g015:
 call neboc_g015_source_parse
 jmp .done
.g016:
 call neboc_g016_source_parse
 jmp .done
.g018:
 call neboc_g018_source_parse
 jmp .done
.g019:
 call neboc_g019_source_parse
 jmp .done
.g087:
 call neboc_g087_source_parse
 jmp .done
.g088:
 call neboc_g088_source_parse
 jmp .done
.g089:
 call neboc_g089_source_parse
 jmp .done
.g090:
 call neboc_g090_source_parse
 jmp .done
.g091:
 call neboc_g091_source_parse
 jmp .done
.g092:
 call neboc_g092_source_parse
 jmp .done
.g093:
 call neboc_g093_source_parse
 jmp .done
.g094:
 call neboc_g094_source_parse
 jmp .done
.g095:
 call neboc_g095_source_parse
 jmp .done
.g096:
 call neboc_g096_source_parse
 jmp .done
.g097:
 call neboc_g097_source_parse
 jmp .done
.g098:
 call neboc_g098_source_parse
 jmp .done
.g099:
 call neboc_g099_source_parse
 jmp .done
.g100:
 call neboc_g100_source_parse
 jmp .done
.g101:
 call neboc_g101_source_parse
 jmp .done
.g102:
 call neboc_g102_source_parse
 jmp .done
.g103:
 call neboc_g103_source_parse
 jmp .done
.g104:
 call neboc_g104_source_parse
 jmp .done
.g105:
 ; The historical ScanPlan/mode/seed probe has no source binding or input
 ; semantics. Native adapter probes remain available to owner tests, while
 ; public scans use the typed function pipeline and consume every operand.
 mov edi,24
 call ls_error
 jmp .done
.g106:
 call neboc_g106_source_parse
 jmp .done
.g107:
 call neboc_g107_source_parse
 jmp .done
.g108:
 call neboc_g108_source_parse
 jmp .done
.g109:
 call neboc_g109_source_parse
 jmp .done
.g110:
 call neboc_g110_source_parse
 jmp .done
.g111:
 call neboc_g111_source_parse
 jmp .done
.g112:
 call neboc_g112_source_parse
 jmp .done
.g113:
 call neboc_g113_source_parse
 jmp .done
.g114:
 call neboc_g114_source_parse
 jmp .done
.g115:
 call neboc_g115_source_parse
 jmp .done
.g116:
 call neboc_g116_source_parse
 jmp .done
.slash_core:
 call neboc_slash_core_source_parse
 jmp .done
.g069:
 call neboc_g069_source_parse
 jmp .done
.g070:
 call neboc_g070_source_parse
 jmp .done
.g071:
 call neboc_g071_source_parse
 jmp .done
.g072:
 call neboc_g072_source_parse
 jmp .done
.g073:
 call neboc_g073_source_parse
 jmp .done
.g074:
 call neboc_g074_source_parse
 jmp .done
.g075:
 call neboc_g075_source_parse
 jmp .done
.g076:
 call neboc_g076_source_parse
 jmp .done
.g077:
 call neboc_g077_source_parse
 jmp .done
.g078:
 call neboc_g078_source_parse
 jmp .done
.g079:
 call neboc_g079_source_parse
 jmp .done
.g080:
 call neboc_g080_source_parse
 jmp .done
.g081:
 call neboc_g081_source_parse
 jmp .done
.g082:
 call neboc_g082_source_parse
 jmp .done
.g083:
 call neboc_g083_source_parse
 jmp .done
.g084:
 call neboc_g084_source_parse
 jmp .done
.g028:
 call neboc_g028_source_parse
 jmp .done
.g029:
 call neboc_g029_source_parse
 jmp .done
.g030:
 call neboc_g030_source_parse
 jmp .done
.g046:
 call neboc_g046_source_parse
 jmp .done
.g035:
 call neboc_g035_source_parse
 jmp .done
.g068:
 call neboc_g068_source_parse
 jmp .done
.g067:
 call neboc_g067_source_parse
 jmp .done
.g066:
 call neboc_g066_source_parse
 jmp .done
.g060:
 call neboc_g060_source_parse
 jmp .done
.g061:
 call neboc_g061_source_parse
 jmp .done
.g063:
 call neboc_g063_source_parse
 jmp .done
.g062:
 call neboc_g062_source_parse
 jmp .done
.g059:
 call neboc_g059_source_parse
 jmp .done
.g011:
 call neboc_g011_source_parse
 jmp .done
.g012:
 call neboc_g012_source_parse
 jmp .done
.g013:
 call neboc_g013_source_parse
 jmp .done
.capacity:
 mov edi,8
 call ls_error
 jmp .done
.mutation:
 mov edi,5
 call ls_error
 jmp .done
.syntax:
 mov edi,8
 call ls_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 leave
 ret

%include "compiler/semantic/collections/sequential_collections_source_vertical.inc"
%include "compiler/semantic/collections/associative_collections_source_vertical.inc"
%include "compiler/semantic/graph/graph_tree_source_vertical.inc"
%include "compiler/semantic/data/typed_data_source_vertical.inc"
%include "compiler/semantic/security/effect_privacy_policy_source_vertical.inc"
%include "compiler/semantic/reactive/reactive_streams_source_vertical.inc"
%include "compiler/semantic/database/database_query_source_vertical.inc"
%include "compiler/semantic/numeric/scalar_vector_math_source_vertical.inc"
%include "compiler/semantic/matrix/dense_matrix_source_vertical.inc"
%include "compiler/semantic/matrix/matrix_notation_source_vertical.inc"
%include "compiler/semantic/calculus/integrals_source_vertical.inc"
%include "compiler/semantic/calculus/differential_calculus_source_vertical.inc"
%include "compiler/semantic/probability/probability_notation_source_vertical.inc"
%include "compiler/semantic/formal/formal_logic_source_vertical.inc"
%include "compiler/semantic/graph/graph_notation_source_vertical.inc"
%include "compiler/semantic/textual/text_pattern_source_vertical.inc"
%include "compiler/semantic/textual/contextual_format_source_vertical.inc"
%include "compiler/semantic/meta/typed_annotations_source_vertical.inc"
%include "compiler/semantic/tensor/tensor_source_vertical.inc"
%include "compiler/semantic/visual/visual_console_source_vertical.inc"
%include "compiler/semantic/media/media_source_vertical.inc"
%include "compiler/semantic/visual/color_source_vertical.inc"
%include "compiler/semantic/visual/color_roles_source_vertical.inc"
%include "compiler/semantic/visual/console_options_source_vertical.inc"
%include "compiler/semantic/visual/console_values_source_vertical.inc"
%include "compiler/semantic/visual/document_geometry_source_vertical.inc"
%include "compiler/semantic/visual/text_style_source_vertical.inc"
%include "compiler/semantic/visual/composite_layout_source_vertical.inc"
%include "compiler/semantic/visual/structured_views_source_vertical.inc"
%include "compiler/semantic/visual/chart_source_vertical.inc"
%include "compiler/semantic/visual/scene_source_vertical.inc"
%include "compiler/semantic/visual/scientific_view_source_vertical.inc"
%include "compiler/semantic/visual/graph_view_source_vertical.inc"
%include "compiler/semantic/visual/dashboard_source_vertical.inc"
%include "compiler/semantic/visual/observability_source_vertical.inc"
%include "compiler/semantic/visual/large_data_source_vertical.inc"
%include "compiler/semantic/visual/animation_export_source_vertical.inc"
%include "compiler/semantic/visual/headless_protocol_source_vertical.inc"
%include "compiler/semantic/visual/live_console_source_vertical.inc"
%include "compiler/semantic/visual/console_scan_source_vertical.inc"
%include "compiler/semantic/visual/console_privacy_source_vertical.inc"
%include "compiler/semantic/visual/console_fallback_source_vertical.inc"
%include "compiler/semantic/visual/console_testability_source_vertical.inc"
%include "compiler/semantic/visual/console_diagnostics_source_vertical.inc"
%include "compiler/semantic/visual/console_scheduler_source_vertical.inc"
%include "compiler/semantic/visual/console_lifecycle_source_vertical.inc"
%include "compiler/semantic/visual/console_binding_source_vertical.inc"
%include "compiler/semantic/visual/console_workflow_source_vertical.inc"
%include "compiler/semantic/visual/console_export_source_vertical.inc"
%include "compiler/semantic/visual/console_abi_source_vertical.inc"
%include "compiler/semantic/visual/console_integration_source_vertical.inc"
%include "compiler/semantic/textual/slash_core_source_vertical.inc"
%include "compiler/semantic/formal/formal_verification_source_vertical.inc"
%include "compiler/semantic/formal/constraint_solver_source_vertical.inc"
%include "compiler/semantic/compiler/compiler_platform_source_vertical.inc"
%include "compiler/semantic/numeric/exact_scientific_math_source_vertical.inc"
%include "compiler/semantic/meta/typed_metaprogramming_source_vertical.inc"
%include "compiler/semantic/textual/text_console_integration_source_vertical.inc"
%include "compiler/semantic/textual/regex_tooling_source_vertical.inc"
%include "compiler/semantic/textual/text_data_source_vertical.inc"
%include "compiler/semantic/textual/text_formats_source_vertical.inc"
%include "compiler/semantic/textual/tabular_json_formats_source_vertical.inc"
%include "compiler/semantic/textual/format_contracts_source_vertical.inc"
%include "compiler/semantic/textual/scan_editor_source_vertical.inc"
%include "compiler/semantic/textual/scan_privacy_source_vertical.inc"
%include "compiler/semantic/textual/scan_validation_source_vertical.inc"
%include "compiler/semantic/textual/scan_plan_source_vertical.inc"
%include "compiler/semantic/textual/template_policy_source_vertical.inc"
%include "compiler/semantic/textual/render_conditions_source_vertical.inc"
%include "compiler/semantic/textual/render_targets_source_vertical.inc"
%include "compiler/semantic/textual/render_security_source_vertical.inc"
%include "compiler/semantic/textual/operational_render_source_vertical.inc"
%include "compiler/semantic/textual/developer_render_source_vertical.inc"
%include "compiler/semantic/textual/render_layout_source_vertical.inc"
%include "compiler/semantic/textual/render_nodes_source_vertical.inc"
%include "compiler/semantic/textual/render_console_source_vertical.inc"
%include "compiler/semantic/textual/raw_tagged_template_source_vertical.inc"
%include "compiler/semantic/textual/interpolation_source_vertical.inc"
%include "compiler/semantic/textual/percent_template_source_vertical.inc"
%include "compiler/semantic/textual/format_profiles_source_vertical.inc"
%include "compiler/semantic/textual/format_plan_source_vertical.inc"
%include "compiler/semantic/system/filesystem_source_vertical.inc"
%include "compiler/semantic/system/system_services_source_vertical.inc"
%include "compiler/semantic/concurrency/concurrency_source_vertical.inc"

; ---------------------------------------------------------------------------
; C11-F01 exact Matrix<Int>.zeros(rows, columns) parser/type vertical.
; ---------------------------------------------------------------------------
; Consume Matrix<Int>. and leave the cursor at the constructor atom.
ls_matrix_type_prefix:
 sub rsp,8
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_expect_atom
 test eax,eax
 jz .done
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .done
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .done
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .done
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
.done:
 add rsp,8
 ret

; Consume `.identifier;`.  EAX boolean, RDX identifier token index.
ls_matrix_binding:
 push rbx
 sub rsp,8
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rbx,[rel ls_cursor]
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdx,rbx
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rbx
 ret

; RDI receiver binding token -> consume receiver.sum(); } EOF.
ls_matrix_sum_tail:
 push rbx
 sub rsp,8
 mov rbx,rdi
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rsi,[rel ls_cursor]
 mov rdi,rbx
 call ls_name_equal
 test eax,eax
 jz .no
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_finish_program
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rbx
 ret

; Consume an identifier that must denote the binding at token index RDI.
ls_matrix_expect_same_identifier:
 push rbx
 sub rsp,8
 mov rbx,rdi
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rsi,[rel ls_cursor]
 mov rdi,rbx
 call ls_name_equal
 test eax,eax
 jz .no
 inc qword [rel ls_cursor]
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop rbx
 ret

; Classify and consume one selected operation atom.  Success returns EAX=1,
; operation in RDX, argc in RCX, identifier-argument flag in R8 and result kind
; in R9.  The complete source is never inspected or hashed by this classifier.
ls_matrix_operation_current:
 push rbx
 push r12
 sub rsp,8
 lea rbx,[rel ls_matrix_operation_table]
 mov r12d,ls_matrix_operation_count
.loop:
 mov rdi,[rel ls_cursor]
 mov rsi,[rbx]
 mov rdx,[rbx+8]
 call ls_token_match
 test eax,eax
 jnz .found
 add rbx,ls_matrix_operation_row_qwords*8
 dec r12
 jnz .loop
 xor eax,eax
 jmp .done
.found:
 inc qword [rel ls_cursor]
 mov rdx,[rbx+16]
 mov rcx,[rbx+24]
 mov r8,[rbx+32]
 mov r9,[rbx+40]
 mov eax,1
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; Parse Matrix<Int>.filled(rows, columns, value).binding; at the current
; cursor.  Success: EAX=1, RDX=binding token, RCX=rows, R8=columns, R9=fill.
ls_matrix_parse_filled_binding:
 push rbp
 mov rbp,rsp
 sub rsp,48
 call ls_matrix_type_prefix
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_filled]
 mov edx,ls_n_filled_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 test rdx,rdx
 js .no
 cmp rdx,8
 ja .no
 mov [rsp],rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 test rdx,rdx
 js .no
 cmp rdx,8
 ja .no
 mov [rsp+8],rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 mov [rsp+16],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rax,[rsp]
 imul rax,[rsp+8]
 jo .no
 cmp rax,NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 ja .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov [rsp+24],rdx
 mov rcx,[rsp]
 mov r8,[rsp+8]
 mov r9,[rsp+16]
 mov rdx,[rsp+24]
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 leave
 ret

; Consume `.return;` after a selected expression.
ls_matrix_return_tail:
 sub rsp,8
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_return]
 mov edx,ls_n_return_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 ret

; Parse the two selected Matrix function-boundary forms.  Identifiers are
; compared by token identity/equality; their spellings are intentionally not
; frozen.  EAX=1 success with a complete typed plan, 0 otherwise.
ls_matrix_parse_function_boundary:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,72
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_current_atom
 test eax,eax
 jnz .parameter
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_current_atom
 test eax,eax
 jz .no
 jmp .return

.parameter:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_self]
 mov edx,ls_n_self_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 ; Function symbol (arbitrary identifier).
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rel ls_cursor]
 mov [rsp],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_type_prefix
 test eax,eax
 jz .no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rel ls_cursor]
 mov [rsp+8],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rsp+8]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_return_tail
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_start_header
 test eax,eax
 jz .no
 call ls_matrix_parse_filled_binding
 test eax,eax
 jz .no
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov [rsp+32],r8
 mov [rsp+40],r9
 call ls_parse_signed_int
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rsp+16]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_return]
 mov edx,ls_n_return_len
 call ls_expect_atom
 test eax,eax
 jz .no
 call ls_finish_program
 test eax,eax
 jz .no
 mov r14d,NEBOC_VECTOR_MATRIX_KIND_FUNCTION_PARAMETER
 jmp .publish

.return:
 call ls_matrix_type_prefix
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_self]
 mov edx,ls_n_self_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rax,[rel ls_cursor]
 mov [rsp],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_parse_filled_binding
 test eax,eax
 jz .no
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov [rsp+32],r8
 mov [rsp+40],r9
 mov rdi,[rsp+16]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 call ls_matrix_return_tail
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RBRACE
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_start_header
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .no
 mov r14d,NEBOC_VECTOR_MATRIX_KIND_FUNCTION_RETURN

.publish:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],r14
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_CONSTRUCTOR0_OFFSET],NEBOC_MATRIX_CONSTRUCTOR_FILLED
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION0_OFFSET],NEBOC_MATRIX_OPERATION_SUM
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],NEBOC_MATRIX_RESULT_SCALAR
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_PRIMARY | NEBOC_MATRIX_PLAN_FLAG_FUNCTION
 mov rdx,[rsp+24]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET],rdx
 mov rdx,[rsp+32]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET],rdx
 mov rdx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET],rdx
 xor edi,edi
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x4331314631335232
 call ls_success
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,72
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; RDI primary binding.  Parse a selected Matrix value expression after a
; bounded filled constructor.  This records semantic constructor/operation
; identities and explicit arguments; it does not key on paths, source bytes,
; hashes, expected results, or user-selected identifier spellings.
ls_matrix_r2_filled_tail:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,72
 mov [rsp],rdi
 mov qword [rsp+8],LS_NO_TOKEN
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_CONSTRUCTOR0_OFFSET],NEBOC_MATRIX_CONSTRUCTOR_FILLED
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_PRIMARY

 ; A second explicit filled value is accepted before binary operations.
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_current_atom
 test eax,eax
 jz .operation
 call ls_matrix_type_prefix
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_filled]
 mov edx,ls_n_filled_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 test rdx,rdx
 js .no
 cmp rdx,8
 ja .no
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_ROWS_OFFSET],rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 test rdx,rdx
 js .no
 cmp rdx,8
 ja .no
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET],rdx
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_parse_signed_int
 test eax,eax
 jz .no
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_FILL_OFFSET],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov [rsp+8],rdx
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_CONSTRUCTOR1_OFFSET],NEBOC_MATRIX_CONSTRUCTOR_FILLED
 or qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_SECONDARY

.operation:
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_operation_current
 test eax,eax
 jz .no
 mov [rsp+24],rdx
 mov [rsp+32],rcx
 mov [rsp+40],r8
 mov [rsp+48],r9
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION0_OFFSET],rdx
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],r9
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 cmp qword [rsp+40],0
 je .integer_args
 ; Binary Matrix arguments must denote the independently bound second value.
 cmp qword [rsp+32],1
 jne .no
 cmp qword [rsp+8],LS_NO_TOKEN
 je .no
 mov rdi,[rsp+8]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 jmp .args_done
.integer_args:
 xor r15d,r15d
.integer_arg_loop:
 cmp r15,[rsp+32]
 jae .args_done
 call ls_parse_signed_int
 test eax,eax
 jz .no
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_ARG0_OFFSET+r15*8],rdx
 inc r15
 cmp r15,[rsp+32]
 jae .args_done
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 jmp .integer_arg_loop
.args_done:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no

 ; Scalar-returning calls terminate the program directly.
 cmp qword [rsp+48],NEBOC_MATRIX_RESULT_SCALAR
 jne .result_binding
 call ls_finish_program
 test eax,eax
 jz .no
 jmp .validate_plan

.result_binding:
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov [rsp+16],rdx
 cmp qword [rsp+24],NEBOC_MATRIX_OPERATION_SERIALIZE_NBM1
 je .serialized_tail
 cmp qword [rsp+24],NEBOC_MATRIX_OPERATION_TRANSPOSE_VIEW
 jne .ordinary_result
 ; A transpose result may be consumed by the selected contiguous materializer.
 mov r14,[rel ls_cursor]
 mov rdi,[rsp+16]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .restore_ordinary
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .restore_ordinary
 call ls_matrix_operation_current
 test eax,eax
 jz .restore_ordinary
 cmp rdx,NEBOC_MATRIX_OPERATION_CONTIGUOUS
 jne .restore_ordinary
 cmp rcx,0
 jne .restore_ordinary
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION1_OFFSET],NEBOC_MATRIX_OPERATION_CONTIGUOUS
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],NEBOC_MATRIX_RESULT_OWNED
 or qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_CHAIN
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .no
 jmp .validate_plan
.restore_ordinary:
 mov [rel ls_cursor],r14
.ordinary_result:
 mov rdi,[rsp+16]
 call ls_matrix_sum_tail
 test eax,eax
 jz .no
 jmp .validate_plan

.serialized_tail:
 ; Array<Int,70>.length() or the selected serialize/asSlice/deserialize route.
 mov rdi,[rsp+16]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_length]
 mov edx,ls_n_length_len
 call ls_current_atom
 test eax,eax
 jz .serialized_slice
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_finish_program
 test eax,eax
 jz .no
 mov rax,[rel ls_request]
 or qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_NBM1
 jmp .validate_plan
.serialized_slice:
 lea rsi,[rel ls_n_as_slice]
 mov edx,ls_n_as_slice_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov r13,rdx
 call ls_matrix_type_prefix
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_deserialize_nbm1]
 mov edx,ls_n_deserialize_nbm1_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,r13
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .no
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .no
 lea rsi,[rel ls_n_serialized_size_nbm1]
 mov edx,ls_n_serialized_size_nbm1_len
 call ls_expect_atom
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .no
 call ls_matrix_binding
 test eax,eax
 jz .no
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .no
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_OPERATION1_OFFSET],NEBOC_MATRIX_OPERATION_DESERIALIZE_NBM1
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_RESULT_KIND_OFFSET],NEBOC_MATRIX_RESULT_OWNED
 or qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_PLAN_FLAGS_OFFSET],NEBOC_MATRIX_PLAN_FLAG_CHAIN | NEBOC_MATRIX_PLAN_FLAG_NBM1

.validate_plan:
 ; Binary elementwise shapes must agree; matmul has the selected inner-shape
 ; rule.  These are the same public, bounded constraints as the runtime.
 cmp qword [rsp+8],LS_NO_TOKEN
 je .publish
 mov rax,[rel ls_request]
 mov rdx,[rsp+24]
 cmp rdx,NEBOC_MATRIX_OPERATION_MATMUL
 je .matmul_shape
 cmp rdx,NEBOC_MATRIX_OPERATION_MATMUL_INTO
 je .matmul_shape
 mov rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 cmp rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_ROWS_OFFSET]
 jne .no
 mov rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 cmp rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET]
 jne .no
 jmp .publish
.matmul_shape:
 mov rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET]
 cmp rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_ROWS_OFFSET]
 jne .no
 mov rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET]
 imul rcx,[rax+NEBOC_VECTOR_VERTICAL_MATRIX_SECOND_COLUMNS_OFFSET]
 jo .no
 cmp rcx,NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 ja .no
.publish:
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_GENERIC_VALUE_PLAN
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,72
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

ls_parse_matrix_f01:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,72
 mov qword [rel ls_cursor],0
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .start_form
 call ls_matrix_parse_function_boundary
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.start_form:
 call ls_start_header
 test eax,eax
 jz .syntax
 ; A Slice-backed fromBuffer may have the canonical bounded Array prefix.
 lea rsi,[rel ls_n_array]
 mov edx,ls_n_array_len
 call ls_current_atom
 test eax,eax
 jnz .from_buffer_prefix
 call ls_matrix_type_prefix
 test eax,eax
 jz .dtype_or_syntax
 lea rsi,[rel ls_n_filled]
 mov edx,ls_n_filled_len
 call ls_current_atom
 test eax,eax
 jnz .filled
 lea rsi,[rel ls_n_from_rows]
 mov edx,ls_n_from_rows_len
 call ls_current_atom
 test eax,eax
 jnz .from_rows
 lea rsi,[rel ls_n_zeros]
 mov edx,ls_n_zeros_len
 call ls_expect_atom
 test eax,eax
 jz .deferred
 ; First bounded zeros constructor.
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+16],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+24],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+16]
 imul rax,[rsp+24]
 jo .limit
 cmp rax,64
 ja .limit
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp],rdx
 ; Preserve the historical C11-F01 check-only form with a scalar tail.
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 je .zeros_legacy_scalar
 cmp eax,NEBOC_TOKEN_MINUS
 je .zeros_legacy_scalar
 ; One zeros value followed by its reduction is a real runtime route.
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_current_atom
 test eax,eax
 jnz .zeros_second
 mov rdi,[rsp]
 call ls_matrix_sum_tail
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_ZEROS_SUM
 jmp .publish_dimensions
.zeros_legacy_scalar:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+48],rdx
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp+48]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x4331314630310000
 call ls_success
 jmp .done
.zeros_second:
 call ls_matrix_type_prefix
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_zeros]
 mov edx,ls_n_zeros_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,[rsp+16]
 jne .shape
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 cmp rdx,[rsp+24]
 jne .shape
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp+8],rdx
 ; left.add(right).sum()
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rsi,[rel ls_cursor]
 mov rdi,[rsp]
 call ls_name_equal
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_add]
 mov edx,ls_n_add_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rsi,[rel ls_cursor]
 mov rdi,[rsp+8]
 call ls_name_equal
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_ZEROS_ADD_SUM
 jmp .publish_dimensions

.filled:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+16],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+24],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+48],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+16]
 imul rax,[rsp+24]
 jo .limit
 cmp rax,64
 ja .limit
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp],rdx
 mov rax,[rel ls_request]
 mov rdx,[rsp+16]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET],rdx
 mov rdx,[rsp+48]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET],rdx
 mov r14,[rel ls_cursor]
 mov rdi,rdx
 mov rdi,[rsp]
 call ls_matrix_sum_tail
 test eax,eax
 jz .filled_r2
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_FILLED_SUM
 mov rdx,[rsp+48]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET],rdx
 jmp .publish_dimensions
.filled_r2:
 mov [rel ls_cursor],r14
 mov rdi,[rsp]
 call ls_matrix_r2_filled_tail
 test eax,eax
 jz .syntax
 jmp .publish_dimensions

.from_buffer_prefix:
 ; Array<Int,N> [values...].owner; owner.asSlice().slice;
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .limit
 cmp rdx,NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 ja .limit
 mov [rsp+32],rdx
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov qword [rsp+40],0
.from_buffer_values:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .from_buffer_values_done
 cmp qword [rsp+40],NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 jae .limit
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov rcx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_VALUES_OFFSET+rcx*8],rdx
 inc qword [rsp+40]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .from_buffer_values
 inc qword [rel ls_cursor]
 jmp .from_buffer_values
.from_buffer_values_done:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+40]
 cmp rax,[rsp+32]
 jne .shape
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rsi,[rel ls_cursor]
 mov rdi,[rsp]
 call ls_name_equal
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_as_slice]
 mov edx,ls_n_as_slice_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp+8],rdx
 call ls_matrix_type_prefix
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_from_buffer]
 mov edx,ls_n_from_buffer_len
 call ls_expect_atom
 test eax,eax
 jz .deferred
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rsi,[rel ls_cursor]
 mov rdi,[rsp+8]
 call ls_name_equal
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+16],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+24],rdx
 test rdx,rdx
 js .limit
 cmp rdx,8
 ja .limit
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+16]
 imul rax,[rsp+24]
 jo .limit
 cmp rax,[rsp+40]
 jne .shape
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp],rdx
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_FROM_BUFFER_SUM
 mov rdx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_VALUE_COUNT_OFFSET],rdx
 jmp .publish_dimensions

.from_rows:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_tuple]
 mov edx,ls_n_tuple_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_of]
 mov edx,ls_n_of_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov qword [rsp+16],0
 mov qword [rsp+24],-1
 mov qword [rsp+40],0
.from_rows_row:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .from_rows_outer_done
 cmp qword [rsp+16],8
 jae .limit
 lea rsi,[rel ls_n_tuple]
 mov edx,ls_n_tuple_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_of]
 mov edx,ls_n_of_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 xor r12d,r12d
.from_rows_value:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .from_rows_value_done
 cmp r12,8
 jae .limit
 cmp qword [rsp+40],NEBOC_VECTOR_VERTICAL_MATRIX_MAX_VALUES
 jae .limit
 call ls_parse_signed_int
 test eax,eax
 jz .dtype
 mov rax,[rel ls_request]
 mov rcx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_VALUES_OFFSET+rcx*8],rdx
 inc qword [rsp+40]
 inc r12
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .from_rows_value
 inc qword [rel ls_cursor]
 jmp .from_rows_value
.from_rows_value_done:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 cmp qword [rsp+24],-1
 jne .from_rows_compare_width
 mov [rsp+24],r12
 jmp .from_rows_width_ok
.from_rows_compare_width:
 cmp r12,[rsp+24]
 jne .shape
.from_rows_width_ok:
 inc qword [rsp+16]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 jne .from_rows_row
 inc qword [rel ls_cursor]
 jmp .from_rows_row
.from_rows_outer_done:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 cmp qword [rsp+24],-1
 jne .from_rows_have_columns
 mov qword [rsp+24],0
.from_rows_have_columns:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+16]
 imul rax,[rsp+24]
 jo .limit
 cmp rax,[rsp+40]
 jne .shape
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp],rdx
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],NEBOC_VECTOR_MATRIX_KIND_FROM_ROWS_SUM
 mov rdx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_VALUE_COUNT_OFFSET],rdx

.publish_dimensions:
 mov rax,[rel ls_request]
 mov rdx,[rsp+16]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_ROWS_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_COLUMNS_OFFSET],rdx
 xor edi,edi
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x4331314631330001
 call ls_success
 jmp .done
.dtype_or_syntax:
 ; A Matrix atom was already observed by the caller, so a malformed generic
 ; prefix is type/syntax owned rather than silently falling through.
 mov edi,11
 call ls_error
 jmp .done
.dtype:
 mov edi,11
 call ls_error
 jmp .done
.limit:
 mov edi,12
 call ls_error
 jmp .done
.deferred:
 mov edi,16
 call ls_error
 jmp .done
.shape:
 mov edi,12
 call ls_error
 jmp .done
.syntax:
 mov edi,13
 call ls_error
.done:
 add rsp,72
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; ---------------------------------------------------------------------------
; C12-F01 exact Tensor<Int> parser/typechecker identity vertical.
; ---------------------------------------------------------------------------
; Parse Tuple.of() or Tuple.of(d0[,d1[,d2]]).  Success returns EAX=1,
; rank in RDX, checked element count in RCX and dimensions in R8/R9/R10.
; EAX=0 is malformed syntax, -1 is a selected rank/dimension/product limit
; and -2 is checked product overflow.  No value is published on failure.
ls_tensor_parse_shape:
 push rbp
 mov rbp,rsp
 sub rsp,48
 lea rsi,[rel ls_n_tuple]
 mov edx,ls_n_tuple_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_of]
 mov edx,ls_n_of_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 mov qword [rsp+32],1
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .close
.dimension:
 cmp qword [rsp+24],NEBOC_TENSOR_MAX_RANK
 jae .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .syntax
 cmp rdx,NEBOC_TENSOR_MAX_DIMENSION
 ja .limit
 mov rax,[rsp+24]
 mov [rsp+rax*8],rdx
 test rdx,rdx
 jz .zero_product
 cmp qword [rsp+32],0
 je .product_ready
 mov rax,[rsp+32]
 imul rax,rdx
 jo .overflow
 cmp rax,NEBOC_TENSOR_MAX_ELEMENTS
 ja .limit
 mov [rsp+32],rax
 jmp .product_ready
.zero_product:
 mov qword [rsp+32],0
.product_ready:
 inc qword [rsp+24]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .close
 cmp eax,NEBOC_TOKEN_COMMA
 jne .syntax
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RPAREN
 je .syntax
 jmp .dimension
.close:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdx,[rsp+24]
 mov rcx,[rsp+32]
 mov r8,[rsp]
 mov r9,[rsp+8]
 mov r10,[rsp+16]
 mov eax,1
 jmp .done
.syntax:
 xor eax,eax
 jmp .done
.limit:
 mov eax,-1
 jmp .done
.overflow:
 mov eax,-2
.done:
 leave
 ret

; Parse the optional bounded Array<Int,N> owner and its exact asSlice binding
; used by the selected explicit-copy fromBuffer signature.  EAX=1 success,
; 0 syntax, -1 non-Int source type, -2 source limit, -3 extent mismatch.
ls_tensor_parse_optional_source:
 push rbp
 mov rbp,rsp
 sub rsp,48
 mov qword [rel ls_tensor_source_name],LS_NO_TOKEN
 mov qword [rel ls_tensor_source_extent],0
 lea rsi,[rel ls_n_array]
 mov edx,ls_n_array_len
 call ls_current_atom
 test eax,eax
 jnz .array
 mov eax,1
 jmp .done
.array:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 test rdx,rdx
 js .limit
 cmp rdx,NEBOC_TENSOR_MAX_ELEMENTS
 ja .limit
 mov [rsp],rdx
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov qword [rsp+8],0
.value:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .values_done
 cmp qword [rsp+8],NEBOC_TENSOR_MAX_ELEMENTS
 jae .limit
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 inc qword [rsp+8]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .value
 cmp eax,NEBOC_TOKEN_COMMA
 jne .syntax
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_RESERVED_RBRACKET
 je .syntax
 jmp .value
.values_done:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rax,[rsp+8]
 cmp rax,[rsp]
 jne .extent
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rsp+16],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rsi,[rel ls_cursor]
 mov rdi,[rsp+16]
 call ls_name_equal
 test eax,eax
 jz .syntax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_as_slice]
 mov edx,ls_n_as_slice_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov [rel ls_tensor_source_name],rdx
 mov rax,[rsp]
 mov [rel ls_tensor_source_extent],rax
 mov eax,1
 jmp .done
.syntax:
 xor eax,eax
 jmp .done
.dtype:
 mov eax,-1
 jmp .done
.limit:
 mov eax,-2
 jmp .done
.extent:
 mov eax,-3
.done:
 leave
 ret

; EDI Tensor diagnostic -> remember the first causal token before publishing
; the common invalid-source result.
ls_tensor_error:
 mov rax,[rel ls_request]
 mov rdx,[rel ls_cursor]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ERROR_TOKEN_OFFSET],rdx
 jmp ls_error

; Consume Tensor<Int>. and leave the cursor at the selected member.
ls_tensor_type_prefix:
 sub rsp,8
 lea rsi,[rel ls_n_tensor]
 mov edx,ls_n_tensor_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_type_done
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .tensor_type_done
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_type_done
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .tensor_type_done
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
.tensor_type_done:
 add rsp,8
 ret

; Parse Tensor<Int>.filled(Tuple.of(...), value).binding; and publish its
; bounded constructor fields to dedicated scratch slots.
ls_tensor_parse_filled_binding:
 push rbp
 mov rbp,rsp
 sub rsp,64
 call ls_tensor_type_prefix
 test eax,eax
 jz .tensor_filled_no
 lea rsi,[rel ls_n_filled]
 mov edx,ls_n_filled_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_filled_no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_filled_no
 call ls_tensor_parse_shape
 test eax,eax
 jle .tensor_filled_no
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov [rsp+16],r8
 mov [rsp+24],r9
 mov [rsp+32],r10
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .tensor_filled_no
 call ls_parse_signed_int
 test eax,eax
 jz .tensor_filled_no
 mov [rsp+40],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_filled_no
 call ls_matrix_binding
 test eax,eax
 jz .tensor_filled_no
 mov [rel ls_tensor_filled_binding],rdx
 mov rax,[rsp]
 mov [rel ls_tensor_filled_rank],rax
 mov rax,[rsp+8]
 mov [rel ls_tensor_filled_count],rax
 mov rax,[rsp+16]
 mov [rel ls_tensor_filled_dim0],rax
 mov rax,[rsp+24]
 mov [rel ls_tensor_filled_dim1],rax
 mov rax,[rsp+32]
 mov [rel ls_tensor_filled_dim2],rax
 mov rax,[rsp+40]
 mov [rel ls_tensor_filled_value],rax
 mov eax,1
 jmp .tensor_filled_done
.tensor_filled_no:
 xor eax,eax
.tensor_filled_done:
 leave
 ret

; Parse the two selected Tensor function-boundary forms using token identity.
ls_tensor_parse_function_boundary:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,40
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_current_atom
 test eax,eax
 jnz .tensor_function_parameter
 lea rsi,[rel ls_n_tensor]
 mov edx,ls_n_tensor_len
 call ls_current_atom
 test eax,eax
 jz .tensor_function_no
 jmp .tensor_function_return

.tensor_function_parameter:
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 lea rsi,[rel ls_n_self]
 mov edx,ls_n_self_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .tensor_function_no
 mov rax,[rel ls_cursor]
 mov [rsp],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_tensor_type_prefix
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .tensor_function_no
 mov rax,[rel ls_cursor]
 mov [rsp+8],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_LBRACE
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rsp+8]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_matrix_return_tail
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RBRACE
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_start_header
 test eax,eax
 jz .tensor_function_no
 call ls_tensor_parse_filled_binding
 test eax,eax
 jz .tensor_function_no
 call ls_parse_signed_int
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rel ls_tensor_filled_binding]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 lea rsi,[rel ls_n_return]
 mov edx,ls_n_return_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_function_no
 call ls_finish_program
 test eax,eax
 jz .tensor_function_no
 mov r14d,NEBOC_VECTOR_MATRIX_KIND_TENSOR_FUNCTION_PARAMETER
 jmp .tensor_function_publish

.tensor_function_return:
 call ls_tensor_type_prefix
 test eax,eax
 jz .tensor_function_no
 lea rsi,[rel ls_n_self]
 mov edx,ls_n_self_len
 call ls_expect_atom
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .tensor_function_no
 mov rax,[rel ls_cursor]
 mov [rsp],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_LBRACE
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_tensor_parse_filled_binding
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rel ls_tensor_filled_binding]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .tensor_function_no
 call ls_matrix_return_tail
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RBRACE
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_start_header
 test eax,eax
 jz .tensor_function_no
 call ls_parse_signed_int
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov rdi,[rsp]
 call ls_matrix_expect_same_identifier
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .tensor_function_no
 call ls_matrix_binding
 test eax,eax
 jz .tensor_function_no
 mov rdi,rdx
 call ls_matrix_sum_tail
 test eax,eax
 jz .tensor_function_no
 mov r14d,NEBOC_VECTOR_MATRIX_KIND_TENSOR_FUNCTION_RETURN

.tensor_function_publish:
 mov rax,[rel ls_request]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_KIND_OFFSET],r14
 mov qword [rax+NEBOC_VECTOR_VERTICAL_TENSOR_TYPE_OFFSET],NEBOC_TENSOR_TYPE_INT
 mov qword [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DTYPE_OFFSET],NEBOC_TENSOR_DTYPE_INT
 mov rdx,[rel ls_tensor_filled_rank]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],rdx
 mov rdx,[rel ls_tensor_filled_dim0]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET],rdx
 mov rdx,[rel ls_tensor_filled_dim1]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET],rdx
 mov rdx,[rel ls_tensor_filled_dim2]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET],rdx
 mov rdx,[rel ls_tensor_filled_count]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ELEMENT_COUNT_OFFSET],rdx
 mov rdx,[rel ls_tensor_filled_value]
 mov [rax+NEBOC_VECTOR_VERTICAL_MATRIX_FILL_OFFSET],rdx
 mov qword [rax+NEBOC_VECTOR_VERTICAL_TENSOR_FLAGS_OFFSET],NEBOC_TENSOR_FLAG_TYPECHECKED|NEBOC_TENSOR_FLAG_SHAPE_CHECKED
 xor edi,edi
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x4331324631330001
 call ls_success
 mov eax,1
 jmp .tensor_function_done
.tensor_function_no:
 xor eax,eax
.tensor_function_done:
 add rsp,40
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; Parse one or more selected Tensor declarations followed by the historical
; scalar proof expression.  The emitted scalar proves check/emit/build parity
; without implementing Tensor storage or any runtime constructor.
ls_parse_tensor_f01:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,104
 mov qword [rel ls_cursor],0
 xor edi,edi
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .tensor_declaration_program
 call ls_tensor_parse_function_boundary
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.tensor_declaration_program:
 call ls_start_header
 test eax,eax
 jz .syntax
 call ls_tensor_parse_optional_source
 test eax,eax
 jz .syntax
 cmp eax,-1
 je .copy
 cmp eax,-2
 je .limit
 cmp eax,-3
 je .shape_mismatch
 mov qword [rsp+72],0
.declaration:
 lea rsi,[rel ls_n_tensor]
 mov edx,ls_n_tensor_len
 call ls_current_atom
 test eax,eax
 jz .scalar
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .dtype
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_zeros]
 mov edx,ls_n_zeros_len
 call ls_current_atom
 test eax,eax
 jnz .zeros
 lea rsi,[rel ls_n_filled]
 mov edx,ls_n_filled_len
 call ls_current_atom
 test eax,eax
 jnz .filled
 lea rsi,[rel ls_n_from_buffer]
 mov edx,ls_n_from_buffer_len
 call ls_current_atom
 test eax,eax
 jnz .from_buffer
 lea rsi,[rel ls_n_from_nested]
 mov edx,ls_n_from_nested_len
 call ls_current_atom
 test eax,eax
 jnz .deferred
 jmp .deferred
.zeros:
 inc qword [rel ls_cursor]
 mov qword [rsp+40],NEBOC_TENSOR_CONSTRUCTOR_ZEROS
 mov qword [rsp+64],NEBOC_TENSOR_FLAG_TYPECHECKED|NEBOC_TENSOR_FLAG_SHAPE_CHECKED
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_tensor_parse_shape
 jmp .shape_result
.filled:
 inc qword [rel ls_cursor]
 mov qword [rsp+40],NEBOC_TENSOR_CONSTRUCTOR_FILLED
 mov qword [rsp+64],NEBOC_TENSOR_FLAG_TYPECHECKED|NEBOC_TENSOR_FLAG_SHAPE_CHECKED
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_tensor_parse_shape
 test eax,eax
 jz .syntax
 cmp eax,-1
 je .limit
 cmp eax,-2
 je .overflow
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov [rsp+16],r8
 mov [rsp+24],r9
 mov [rsp+32],r10
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+48],rdx
 jmp .constructor_close
.from_buffer:
 inc qword [rel ls_cursor]
 mov qword [rsp+40],NEBOC_TENSOR_CONSTRUCTOR_FROM_BUFFER
 mov qword [rsp+64],NEBOC_TENSOR_FLAG_TYPECHECKED|NEBOC_TENSOR_FLAG_SHAPE_CHECKED|NEBOC_TENSOR_FLAG_EXPLICIT_COPY
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .copy
 mov rdi,[rel ls_tensor_source_name]
 mov rsi,[rel ls_cursor]
 call ls_name_equal
 test eax,eax
 jz .copy
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_tensor_parse_shape
.shape_result:
 test eax,eax
 jz .syntax
 cmp eax,-1
 je .limit
 cmp eax,-2
 je .overflow
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov [rsp+16],r8
 mov [rsp+24],r9
 mov [rsp+32],r10
 cmp qword [rsp+40],NEBOC_TENSOR_CONSTRUCTOR_FROM_BUFFER
 jne .constructor_close
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_COMMA
 je .copy
 mov rax,[rel ls_tensor_source_extent]
 cmp rax,[rsp+8]
 jne .shape_mismatch
.constructor_close:
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_matrix_binding
 test eax,eax
 jz .syntax
 mov rax,[rel ls_request]
 mov qword [rax+NEBOC_VECTOR_VERTICAL_TENSOR_TYPE_OFFSET],NEBOC_TENSOR_TYPE_INT
 mov qword [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DTYPE_OFFSET],NEBOC_TENSOR_DTYPE_INT
 mov rdx,[rsp]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_RANK_OFFSET],rdx
 mov rdx,[rsp+16]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM0_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM1_OFFSET],rdx
 mov rdx,[rsp+32]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DIM2_OFFSET],rdx
 mov rdx,[rsp+8]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_ELEMENT_COUNT_OFFSET],rdx
 mov rdx,[rsp+40]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_CONSTRUCTOR_OFFSET],rdx
 mov rdx,[rel ls_tensor_source_extent]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_SOURCE_EXTENT_OFFSET],rdx
 mov rdx,[rsp+64]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_FLAGS_OFFSET],rdx
 inc qword [rsp+72]
 mov rdx,[rsp+72]
 mov [rax+NEBOC_VECTOR_VERTICAL_TENSOR_DECLARATION_COUNT_OFFSET],rdx
 jmp .declaration
.scalar:
 cmp qword [rsp+72],0
 je .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rsp+80],rdx
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp+80]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x4331324630310001
 call ls_success
 jmp .done
.dtype:
 mov edi,17
 call ls_tensor_error
 jmp .done
.syntax:
 mov edi,18
 call ls_tensor_error
 jmp .done
.shape_mismatch:
 mov edi,19
 call ls_tensor_error
 jmp .done
.overflow:
 mov edi,20
 call ls_tensor_error
 jmp .done
.limit:
 mov edi,21
 call ls_tensor_error
 jmp .done
.copy:
 mov edi,22
 call ls_tensor_error
 jmp .done
.deferred:
 mov edi,23
 call ls_tensor_error
.done:
 add rsp,104
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 pop rbp
 ret

; ---------------------------------------------------------------------------
; vetores_matrizes_tensores_e_computacao_cientifica Vector<Int>#4
; ---------------------------------------------------------------------------

; G134 owns a bounded exact-Int Vector profile.  The scanner is structural:
; it consumes canonical tokens, authenticates names/extents and derives the
; emitted scalar from source values.  No path, fixture name or fixed output is
; consulted.  EAX is boolean and the token cursor is not material here.
ls_g134_is_program:
 push rbx
 xor ebx,ebx
.scan:
 cmp rbx,[rel ls_token_count]
 jae .no
 mov rdi,rbx
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LINEAR_DOT
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_HADAMARD
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_COMPOSE
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 je .yes
 cmp eax,NEBOC_TOKEN_LINEAR_PARALLEL
 je .yes
 cmp eax,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .yes
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .next
 mov rdi,rbx
 call ls_g134_method_kind_at
 test eax,eax
 jnz .yes
.next:
 inc rbx
 jmp .scan
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 pop rbx
 ret

; Method token index RDI -> EAX normalized G134 operation token or zero.
ls_g134_method_kind_at:
 push rbx
 push r12
 mov r12,rdi
 lea rbx,[rel ls_g134_method_table]
 mov ecx,ls_g134_method_count
.loop:
 push rcx
 mov rdi,r12
 mov rsi,[rbx]
 mov rdx,[rbx+8]
 call ls_token_match
 pop rcx
 test eax,eax
 jnz .found
 add rbx,24
 dec ecx
 jnz .loop
 xor eax,eax
 jmp .done
.found:
 mov rax,[rbx+16]
.done:
 pop r12
 pop rbx
 ret

; Current method token -> EAX normalized G134 operation token or zero.
ls_g134_method_kind:
 mov rdi,[rel ls_cursor]
 jmp ls_g134_method_kind_at

; Parse one `Vector<Int,N> [..].name;`, where 1 <= N <= 4.
; EAX=0 success, positive semantic diagnostic, or -1 for syntax.
ls_g134_parse_declaration:
 push rbx
 push r12
 push r13
 sub rsp,8
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 jne .arity
 mov rdi,[rel ls_cursor]
 call ls_token_ptr
 mov r12,[rax+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r12,r12
 jz .arity
 cmp r12,LS_COLLECTION_VALUES
 ja .arity
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_RESERVED_LBRACKET
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rbx,[rel ls_collection_count]
 xor r13d,r13d
.value_loop:
 cmp r13,r12
 jae .values_done
 call ls_parse_signed_int
 test eax,eax
 jz .type
 mov rax,rbx
 imul rax,LS_COLLECTION_VALUES
 add rax,r13
 mov [ls_collection_values+rax*8],rdx
 inc r13
 cmp r13,r12
 jae .values_done
 mov edi,NEBOC_TOKEN_COMMA
 call ls_expect_kind
 test eax,eax
 jz .arity
 jmp .value_loop
.values_done:
 mov edi,NEBOC_TOKEN_RESERVED_RBRACKET
 call ls_expect_kind
 test eax,eax
 jz .arity
 mov [ls_collection_value_counts+rbx*8],r12
 mov rdi,rbx
 call ls_parse_collection_binding
 test eax,eax
 jz .syntax
 xor eax,eax
 jmp .done
.arity:
 mov eax,1
 jmp .done
.type:
 mov eax,2
 jmp .done
.dtype:
 mov eax,5
 jmp .done
.syntax:
 mov rax,-1
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 ret

; Exact checked reduction of one Vector record. RDI=index -> EAX status,
; RDX=sum.  The bounded profile uses this as the independent scalar observer
; for vector-valued products.
ls_g134_vector_sum:
 push rbx
 push r12
 push r13
 mov r12,rdi
 cmp r12,[rel ls_collection_count]
 jae .type
 mov r13,[ls_collection_value_counts+r12*8]
 imul r12,LS_COLLECTION_VALUES
 xor ebx,ebx
 xor edx,edx
.loop:
 cmp rbx,r13
 jae .yes
 add rdx,[ls_collection_values+r12*8]
 jo .overflow
 inc r12
 inc rbx
 jmp .loop
.yes:
 xor eax,eax
 jmp .done
.type:
 mov eax,2
 xor edx,edx
 jmp .done
.overflow:
 mov eax,10
 xor edx,edx
.done:
 pop r13
 pop r12
 pop rbx
 ret

; RDI=normalized op, RSI=left record, RDX=right record.
; Returns the exact scalar observation in RDX.  Vector products are observed
; by checked sum, as authenticated by the source `.sum()` suffix.
ls_g134_compute_binary:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov [rsp],rdi
 mov [rsp+8],rsi
 mov [rsp+16],rdx
 cmp rsi,[rel ls_collection_count]
 jae .type
 cmp rdx,[rel ls_collection_count]
 jae .type
 mov r12,rsi
 imul r12,LS_COLLECTION_VALUES
 mov r13,rdx
 imul r13,LS_COLLECTION_VALUES
 mov r14,[ls_collection_value_counts+rsi*8]
 mov r15,[ls_collection_value_counts+rdx*8]
 mov rax,[rsp]
 cmp rax,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 je .tensor
 cmp rax,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 je .direct_sum
 cmp r14,r15
 jne .arity
 cmp rax,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .cross
 cmp rax,NEBOC_TOKEN_LINEAR_PARALLEL
 je .parallel
 ; Dot, Hadamard.sum and orthogonality share the same exact checked dot
 ; reduction, while retaining distinct token/Registry identities.
 cmp rax,NEBOC_TOKEN_LINEAR_DOT
 je .dot
 cmp rax,NEBOC_TOKEN_LINEAR_HADAMARD
 je .dot
 cmp rax,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 jne .type
.dot:
 mov qword [rsp+24],0
 xor ebx,ebx
.dot_loop:
 cmp rbx,r14
 jae .dot_done
 mov rax,[ls_collection_values+r12*8]
 imul rax,[ls_collection_values+r13*8]
 jo .overflow
 add [rsp+24],rax
 jo .overflow
 inc r12
 inc r13
 inc rbx
 jmp .dot_loop
.dot_done:
 mov rdx,[rsp+24]
 cmp qword [rsp],NEBOC_TOKEN_LINEAR_ORTHOGONAL
 jne .yes
 test rdx,rdx
 sete dl
 movzx edx,dl
 jmp .yes
.cross:
 cmp r14,3
 jne .arity
 ; c0 = a1*b2-a2*b1
 mov rax,[ls_collection_values+r12*8+8]
 imul rax,[ls_collection_values+r13*8+16]
 jo .overflow
 mov [rsp+24],rax
 mov rax,[ls_collection_values+r12*8+16]
 imul rax,[ls_collection_values+r13*8+8]
 jo .overflow
 sub [rsp+24],rax
 jo .overflow
 ; c1 = a2*b0-a0*b2
 mov rax,[ls_collection_values+r12*8+16]
 imul rax,[ls_collection_values+r13*8]
 jo .overflow
 mov [rsp+32],rax
 mov rax,[ls_collection_values+r12*8]
 imul rax,[ls_collection_values+r13*8+16]
 jo .overflow
 sub [rsp+32],rax
 jo .overflow
 ; c2 = a0*b1-a1*b0, then exact sum observation.
 mov rax,[ls_collection_values+r12*8]
 imul rax,[ls_collection_values+r13*8+8]
 jo .overflow
 mov [rsp+40],rax
 mov rax,[ls_collection_values+r12*8+8]
 imul rax,[ls_collection_values+r13*8]
 jo .overflow
 sub [rsp+40],rax
 jo .overflow
 mov rdx,[rsp+24]
 add rdx,[rsp+32]
 jo .overflow
 add rdx,[rsp+40]
 jo .overflow
 jmp .yes
.tensor:
 mov rdi,[rsp+8]
 call ls_g134_vector_sum
 test eax,eax
 jnz .done
 mov [rsp+24],rdx
 mov rdi,[rsp+16]
 call ls_g134_vector_sum
 test eax,eax
 jnz .done
 mov rax,[rsp+24]
 imul rax,rdx
 jo .overflow
 mov rdx,rax
 jmp .yes
.direct_sum:
 mov rdi,[rsp+8]
 call ls_g134_vector_sum
 test eax,eax
 jnz .done
 mov [rsp+24],rdx
 mov rdi,[rsp+16]
 call ls_g134_vector_sum
 test eax,eax
 jnz .done
 add rdx,[rsp+24]
 jo .overflow
 jmp .yes
.parallel:
 ; Exact linear-dependence oracle: all 2x2 minors must be zero.  This is
 ; deterministic for the bounded Int profile and needs no hidden tolerance.
 xor ebx,ebx
.parallel_i:
 cmp rbx,r14
 jae .parallel_true
 lea rcx,[rbx+1]
.parallel_j:
 cmp rcx,r14
 jae .parallel_next_i
 mov rdx,r12
 add rdx,rbx
 mov rax,[ls_collection_values+rdx*8]
 mov rdx,r13
 add rdx,rcx
 imul rax,[ls_collection_values+rdx*8]
 jo .overflow
 mov [rsp+24],rax
 mov rdx,r12
 add rdx,rcx
 mov rax,[ls_collection_values+rdx*8]
 mov rdx,r13
 add rdx,rbx
 imul rax,[ls_collection_values+rdx*8]
 jo .overflow
 cmp rax,[rsp+24]
 jne .parallel_false
 inc rcx
 jmp .parallel_j
.parallel_next_i:
 inc rbx
 jmp .parallel_i
.parallel_true:
 mov edx,1
 jmp .yes
.parallel_false:
 xor edx,edx
.yes:
 xor eax,eax
 jmp .done
.arity:
 mov eax,1
 xor edx,edx
 jmp .done
.type:
 mov eax,2
 xor edx,edx
 jmp .done
.overflow:
 mov eax,10
 xor edx,edx
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=outer diagonal map, RSI=inner diagonal map, RDX=input Vector.
; Output is sum(outer(inner(input))), preserving right-before-left order.
ls_g134_compute_compose:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 cmp rdi,[rel ls_collection_count]
 jae .type
 cmp rsi,[rel ls_collection_count]
 jae .type
 cmp rdx,[rel ls_collection_count]
 jae .type
 mov r14,[ls_collection_value_counts+rdi*8]
 cmp r14,[ls_collection_value_counts+rsi*8]
 jne .arity
 cmp r14,[ls_collection_value_counts+rdx*8]
 jne .arity
 mov r12,rdi
 imul r12,LS_COLLECTION_VALUES
 mov r13,rsi
 imul r13,LS_COLLECTION_VALUES
 mov r15,rdx
 imul r15,LS_COLLECTION_VALUES
 xor ebx,ebx
 mov qword [rsp],0
.loop:
 cmp rbx,r14
 jae .yes
 mov rax,[ls_collection_values+r13*8]
 imul rax,[ls_collection_values+r15*8]
 jo .overflow
 imul rax,[ls_collection_values+r12*8]
 jo .overflow
 add [rsp],rax
 jo .overflow
 inc r12
 inc r13
 inc r15
 inc rbx
 jmp .loop
.yes:
 mov rdx,[rsp]
 xor eax,eax
 jmp .done
.arity:
 mov eax,1
 xor edx,edx
 jmp .done
.type:
 mov eax,2
 xor edx,edx
 jmp .done
.overflow:
 mov eax,10
 xor edx,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Parse one symbolic or portable named operation and return its exact scalar
; observation. EAX follows the declaration parser status convention.
ls_g134_parse_term:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov qword [rsp+24],0
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_LPAREN
 jne .first
 inc qword [rel ls_cursor]
 mov qword [rsp+24],1
.first:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call ls_find_collection
 cmp rax,-1
 je .type
 mov [rsp],rax
 inc qword [rel ls_cursor]
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 mov r14,rax
 cmp r14,NEBOC_TOKEN_LINEAR_DOT
 je .symbol
 cmp r14,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_HADAMARD
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_COMPOSE
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_ORTHOGONAL
 je .symbol
 cmp r14,NEBOC_TOKEN_LINEAR_PARALLEL
 je .symbol
 cmp r14,NEBOC_TOKEN_DOT
 jne .syntax
 inc qword [rel ls_cursor]
 call ls_g134_method_kind
 test eax,eax
 jz .syntax
 mov r14,rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call .second_operand
 test eax,eax
 jnz .done
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 jmp .after_pair
.symbol:
 inc qword [rel ls_cursor]
 call .second_operand
 test eax,eax
 jnz .done
 cmp qword [rsp+24],0
 je .after_pair
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
.after_pair:
 mov [rsp+16],r14
 cmp r14,NEBOC_TOKEN_LINEAR_COMPOSE
 je .compose_suffix
 cmp r14,NEBOC_TOKEN_SET_CARTESIAN_PRODUCT
 je .sum_suffix
 cmp r14,NEBOC_TOKEN_LINEAR_HADAMARD
 je .sum_suffix
 cmp r14,NEBOC_TOKEN_LINEAR_TENSOR_PRODUCT
 je .sum_suffix
 cmp r14,NEBOC_TOKEN_LINEAR_DIRECT_SUM
 je .sum_suffix
 jmp .compute
.compose_suffix:
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_apply]
 mov edx,ls_n_apply_len
 call ls_expect_atom
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rdi,[rel ls_cursor]
 call ls_find_collection
 cmp rax,-1
 je .type
 mov [rsp+32],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call .expect_sum
 test eax,eax
 jnz .done
 mov rdi,[rsp]
 mov rsi,[rsp+8]
 mov rdx,[rsp+32]
 call ls_g134_compute_compose
 jmp .done
.sum_suffix:
 call .expect_sum
 test eax,eax
 jnz .done
.compute:
 mov rdi,[rsp+16]
 mov rsi,[rsp]
 mov rdx,[rsp+8]
 call ls_g134_compute_binary
 jmp .done

; Local callable: parse identifier operand into rsp+8.
.second_operand:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .second_syntax
 mov rdi,[rel ls_cursor]
 call ls_find_collection
 cmp rax,-1
 je .second_type
 ; This local helper is reached with CALL, so the caller's rsp+8 slot is
 ; sixteen bytes above the helper stack pointer (past the return address).
 mov [rsp+16],rax
 inc qword [rel ls_cursor]
 xor eax,eax
 ret
.second_type:
 mov eax,2
 ret
.second_syntax:
 mov rax,-1
 ret

; Local callable: require the exact zero-argument `.sum()` observer.
.expect_sum:
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .sum_syntax
 lea rsi,[rel ls_n_sum]
 mov edx,ls_n_sum_len
 call ls_expect_atom
 test eax,eax
 jz .sum_syntax
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .sum_syntax
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .sum_syntax
 xor eax,eax
 ret
.sum_syntax:
 mov rax,-1
 ret
.type:
 mov eax,2
 xor edx,edx
 jmp .done
.syntax:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Complete bounded G134 program: declarations followed by one or more scalar
; observations joined with ordinary checked `+`.
ls_g134_parse_program:
 push rbx
 sub rsp,16
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
.decl_loop:
 cmp qword [rel ls_collection_count],LS_COLLECTION_CAPACITY
 jae .expression
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_current_atom
 test eax,eax
 jz .expression
 call ls_g134_parse_declaration
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 jmp .decl_loop
.expression:
 cmp qword [rel ls_collection_count],2
 jb .type
 call ls_g134_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
.plus_loop:
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 call ls_g134_parse_term
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 add [rsp],rdx
 jo .overflow
 jmp .plus_loop
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246324747313334
 call ls_success
 jmp .done
.semantic:
 mov edi,eax
 call ls_error
 jmp .done
.type:
 mov edi,2
 call ls_error
 jmp .done
.overflow:
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 mov edi,5
 call ls_error
.done:
 add rsp,16
 pop rbx
 ret

NEBOC_ABI_FUNCTION neboc_vector_vertical_recognize
 push rbp
 mov rbp,rsp
 sub rsp,16
 call ls_initialize
 test eax,eax
 jz .invalid
 mov qword [rel ls_mode],11
 ; G143 owns `@name(...)` declaration metadata before declaration guards and
 ; every expression-oriented legacy route.  Bare/free `@` is still claimed so
 ; it fails with the annotation grammar's precise diagnostic.
 call g143_is_program
 test eax,eax
 jz .not_g143
 call g143_parse_program
 jmp .done
.not_g143:
 xor ecx,ecx
.declaration_guard_11:
 cmp rcx,[rel ls_token_count]
 jae .declaration_guard_11_done
 imul rax,rcx,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp eax,NEBOC_TOKEN_KW_STRUCT
 je .not_owned
 cmp eax,NEBOC_TOKEN_KW_ENUM
 je .not_owned
 inc rcx
 jmp .declaration_guard_11
.declaration_guard_11_done:
 ; G142 owns the integrated contextual template grammar before the historical
 ; FormatPlan, percent-format and Slash routes can claim its component atoms.
 call g142_is_program
 test eax,eax
 jz .not_g142
 call g142_parse_program
 jmp .done
.not_g142:
 ; G141 Text/Pattern operators and canonical APIs own complete bounded
 ; literal expressions before graph, formal and historical textual routes.
 call g141_is_program
 test eax,eax
 jz .not_g141
 call g141_parse_program
 jmp .done
.not_g141:
 ; G140 graph/workflow/statechart arrows and canonical APIs own complete
 ; bounded call expressions before formal and scientific source routes.
 call g140_is_program
 test eax,eax
 jz .not_g140
 call g140_parse_program
 jmp .done
.not_g140:
 ; G139 formal logic owns its exact Registry tokens and canonical portable
 ; spellings before probability/calculus and historical scientific routes.
 call g139_is_program
 test eax,eax
 jz .not_g139
 call g139_parse_program
 jmp .done
.not_g139:
 ; G138 probability relations and their portable spellings own complete
 ; bounded call expressions before the calculus/scientific heuristics.
 call g138_is_program
 test eax,eax
 jz .not_g138
 call g138_parse_program
 jmp .done
.not_g138:
 ; G137 differential binders/prefixes and portable APIs own complete bounded
 ; call expressions before integral and historical scientific heuristics.
 call g137_is_program
 test eax,eax
 jz .not_g137
 call g137_parse_program
 jmp .done
.not_g137:
 ; G136 integral binders and portable APIs own complete call expressions and
 ; therefore take precedence over historical Matrix/Vector name heuristics.
 call g136_is_program
 test eax,eax
 jz .not_g136
 call g136_parse_program
 jmp .done
.not_g136:
 ; G135 is authenticated by an explicit bounded extent plus one Registry
 ; spelling/API.  Give it first refusal before the historical Matrix profile.
 call g135_is_program
 test eax,eax
 jz .not_g135
 call g135_parse_program
 jmp .done
.not_g135:
 ; Explicit deferred surfaces retain deterministic ownership.
 lea rsi,[rel ls_n_matrix]
 mov edx,ls_n_matrix_len
 call ls_contains_atom
 test eax,eax
 jnz .matrix
 lea rsi,[rel ls_n_tensor]
 mov edx,ls_n_tensor_len
 call ls_contains_atom
 test eax,eax
 jnz .tensor
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_contains_atom
 test eax,eax
 jz .not_owned
 call ls_g134_is_program
 test eax,eax
 jz .legacy_vector
 call ls_g134_parse_program
 jmp .done
.legacy_vector:
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 ; Vector.sparse is identified structurally as Vector . sparse.
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_current_atom
 test eax,eax
 jz .scalar_or_decl
 mov r8,[rel ls_cursor]
 lea rdi,[r8+1]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_DOT
 jne .scalar_or_decl
 lea rdi,[r8+2]
 lea rsi,[rel ls_n_sparse]
 mov edx,ls_n_sparse_len
 call ls_token_match
 test eax,eax
 jnz .sparse
.scalar_or_decl:
 ; Optional scalar binding used by the dynamic-index negative.
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_INTEGER
 je .scalar
 cmp eax,NEBOC_TOKEN_MINUS
 jne .decl_loop
.scalar:
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel ls_scalar_value],rdx
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[rel ls_cursor]
 mov [rel ls_scalar_name],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .syntax
.decl_loop:
 cmp qword [rel ls_collection_count],LS_LEGACY_MAX_COLLECTIONS
 jae .expr
 lea rsi,[rel ls_n_vector]
 mov edx,ls_n_vector_len
 call ls_current_atom
 test eax,eax
 jz .expr
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_collection_count]
 call ls_parse_int4_list
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov rdi,[rel ls_collection_count]
 call ls_parse_collection_binding
 test eax,eax
 jz .syntax
 jmp .decl_loop
.expr:
 cmp qword [rel ls_collection_count],0
 je .not_owned
 mov edi,11
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 mov edi,11
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov rax,[rsp]
 add rax,rdx
 jo .overflow
 mov [rsp],rax
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_VECTOR_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323747313100
 call ls_success
 jmp .done
.semantic:
 mov edi,eax
 call ls_error
 jmp .done
.dtype:
 mov edi,5
 call ls_error
 jmp .done
.matrix:
 call g15_is_program
 test eax,eax
 jz .matrix_legacy
 call neboc_g015_source_parse
 jmp .done
.matrix_legacy:
 call ls_parse_matrix_f01
 jmp .done
.tensor:
 call g16_is_program
 test eax,eax
 jz .tensor_legacy
 call neboc_g016_source_parse
 jmp .done
.tensor_legacy:
 call ls_parse_tensor_f01
 jmp .done
.sparse:
 mov edi,9
 call ls_error
 jmp .done
.overflow:
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 mov edi,5
 call ls_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 leave
 ret

; Find wrapper specification for current token. EAX 1 expected, 2 alternate,
; 0 no wrapper; stores row pointer in ls_wrapper_spec.
ls_find_wrapper_current:
 push rbp
 mov rbp,rsp
 push rbx
 push r12
 lea rbx,[rel ls_wrapper_specs]
 mov r12d,ls_wrapper_spec_count
.loop:
 mov rdi,[rel ls_cursor]
 mov rsi,[rbx]
 mov rdx,[rbx+8]
 call ls_token_match
 test eax,eax
 jnz .expected
 mov rdi,[rel ls_cursor]
 mov rsi,[rbx+16]
 mov rdx,[rbx+24]
 call ls_token_match
 test eax,eax
 jnz .alternate
 add rbx,40
 dec r12d
 jnz .loop
 xor eax,eax
 jmp .done
.expected:
 mov [rel ls_wrapper_spec],rbx
 mov eax,1
 jmp .done
.alternate:
 mov [rel ls_wrapper_spec],rbx
 mov eax,2
.done:
 pop r12
 pop rbx
 pop rbp
 ret

; Parse one STREAM-EVENT-E-PROCESSAMENTO-CONTINUO semantic wrapper program after start header.
ls_parse_wrapper_program:
 push rbp
 mov rbp,rsp
 push rbx
 sub rsp,24
 call ls_find_wrapper_current
 test eax,eax
 jz .not_wrapper
 mov ebx,eax
 mov rax,[rel ls_wrapper_spec]
 mov r10,[rax+32]
 mov [rsp],r10
 test ebx,ebx
 cmp ebx,1
 jne .bounded
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .bounded
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .bounded
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .bounded
 call ls_parse_signed_int
 test eax,eax
 jz .bounded
 mov [rsp+8],rdx
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .bounded
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .binding_name_ok
 cmp eax,NEBOC_TOKEN_KW_LOOP
 jne .bounded
.binding_name_ok:
 mov rbx,[rel ls_cursor]
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .bounded
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 je .binding_use_ok
 cmp eax,NEBOC_TOKEN_KW_LOOP
 jne .bounded
.binding_use_ok:
 mov rdi,[rel ls_cursor]
 mov rsi,rbx
 call ls_name_equal
 test eax,eax
 jz .bounded
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .bounded
 lea rsi,[rel ls_n_value]
 mov edx,ls_n_value_len
 call ls_expect_atom
 test eax,eax
 jz .bounded
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .bounded
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .bounded
 call ls_finish_program
 test eax,eax
 jz .bounded
 mov rdi,[rsp+8]
 mov esi,NEBOC_COLUMN_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323747575200
 call ls_success
 jmp .done
.bounded:
 mov edi,[rsp]
 call ls_error
 jmp .done
.not_wrapper:
 mov rax,-1
.done:
 add rsp,24
 pop rbx
 pop rbp
 ret

; ---------------------------------------------------------------------------
; column_row_table_e_dataset Column<Int>#4 plus STREAM-EVENT-E-PROCESSAMENTO-CONTINUO semantic wrappers.
; ---------------------------------------------------------------------------
NEBOC_ABI_FUNCTION neboc_column_vertical_recognize
 push rbp
 mov rbp,rsp
 sub rsp,16
 call ls_initialize
 test eax,eax
 jz .invalid
 mov qword [rel ls_mode],12
 xor ecx,ecx
.declaration_guard_12:
 cmp rcx,[rel ls_token_count]
 jae .declaration_guard_12_done
 imul rax,rcx,NEBOC_TOKEN_SIZE
 add rax,[rel ls_tokens]
 mov rax,[rax+NEBOC_TOKEN_KIND_OFFSET]
 cmp eax,NEBOC_TOKEN_KW_STRUCT
 je .not_owned
 cmp eax,NEBOC_TOKEN_KW_ENUM
 je .not_owned
 inc rcx
 jmp .declaration_guard_12
.declaration_guard_12_done:
 lea rsi,[rel ls_n_table]
 mov edx,ls_n_table_len
 call ls_contains_atom
 test eax,eax
 jnz .table
 lea rsi,[rel ls_n_dataset]
 mov edx,ls_n_dataset_len
 call ls_contains_atom
 test eax,eax
 jnz .dataset
 ; Claim Column or any expected/alternate wrapper name.
 lea rsi,[rel ls_n_column]
 mov edx,ls_n_column_len
 call ls_contains_atom
 test eax,eax
 jnz .claimed
 xor ecx,ecx
.wrapper_claim_loop:
 cmp ecx,ls_wrapper_spec_count
 jae .not_owned
 lea rax,[rel ls_wrapper_specs]
 imul rdx,rcx,40
 add rax,rdx
 push rcx
 push rax
 mov rsi,[rax]
 mov rdx,[rax+8]
 call ls_contains_atom
 mov r8d,eax
 pop rax
 pop rcx
 test r8d,r8d
 jnz .claimed
 push rcx
 sub rsp,8
 mov rsi,[rax+16]
 mov rdx,[rax+24]
 call ls_contains_atom
 add rsp,8
 pop rcx
 test eax,eax
 jnz .claimed
 inc ecx
 jmp .wrapper_claim_loop
.claimed:
 mov qword [rel ls_cursor],0
 call ls_start_header
 test eax,eax
 jz .syntax
 call ls_parse_wrapper_program
 cmp eax,-1
 jne .done
.decl_loop:
 cmp qword [rel ls_collection_count],LS_LEGACY_MAX_COLLECTIONS
 jae .after_decls
 lea rsi,[rel ls_n_column]
 mov edx,ls_n_column_len
 call ls_current_atom
 test eax,eax
 jz .after_decls
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LESS
 call ls_expect_kind
 test eax,eax
 jz .syntax
 lea rsi,[rel ls_n_option]
 mov edx,ls_n_option_len
 call ls_current_atom
 test eax,eax
 jnz .missing
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_expect_atom
 test eax,eax
 jz .dtype
 mov edi,NEBOC_TOKEN_GREATER
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_collection_count]
 call ls_parse_int4_list
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov rdi,[rel ls_collection_count]
 call ls_parse_collection_binding
 test eax,eax
 jz .syntax
 jmp .decl_loop
.after_decls:
 cmp qword [rel ls_collection_count],0
 je .not_owned
 ; Optional Int(value).name scalar binding.
 lea rsi,[rel ls_n_int]
 mov edx,ls_n_int_len
 call ls_current_atom
 test eax,eax
 jz .expr
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_LPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 call ls_parse_signed_int
 test eax,eax
 jz .syntax
 mov [rel ls_scalar_value],rdx
 mov edi,NEBOC_TOKEN_RPAREN
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov edi,NEBOC_TOKEN_DOT
 call ls_expect_kind
 test eax,eax
 jz .syntax
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_IDENTIFIER
 jne .syntax
 mov rax,[rel ls_cursor]
 mov [rel ls_scalar_name],rax
 inc qword [rel ls_cursor]
 mov edi,NEBOC_TOKEN_SEMICOLON
 call ls_expect_kind
 test eax,eax
 jz .syntax
.expr:
 mov edi,12
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov [rsp],rdx
 mov rdi,[rel ls_cursor]
 call ls_kind_at
 cmp eax,NEBOC_TOKEN_PLUS
 jne .finish
 inc qword [rel ls_cursor]
 mov edi,12
 call ls_parse_collection_atom
 cmp eax,-1
 je .syntax
 test eax,eax
 jnz .semantic
 mov rax,[rsp]
 add rax,rdx
 jo .overflow
 mov [rsp],rax
.finish:
 call ls_finish_program
 test eax,eax
 jz .syntax
 mov rdi,[rsp]
 mov esi,NEBOC_COLUMN_VERTICAL_FLAGS_REQUIRED
 mov rdx,0x5246323747313200
 call ls_success
 jmp .done
.semantic:
 mov edi,eax
 call ls_error
 jmp .done
.dtype:
 mov edi,5
 call ls_error
 jmp .done
.missing:
 mov edi,8
 call ls_error
 jmp .done
.table:
 mov edi,6
 call ls_error
 jmp .done
.dataset:
 mov edi,7
 call ls_error
 jmp .done
.overflow:
 mov edi,10
 call ls_error
 jmp .done
.syntax:
 mov edi,5
 call ls_error
 jmp .done
.not_owned:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 leave
 ret

; structs_enums_variants_e_tipos_do_programador is implemented below after the bounded declaration/value helpers.

; Placeholder until the declaration parser section below.
; The actual global symbol is emitted at the end of this source.

section .note.GNU-stack noalloc noexec nowrite progbits
