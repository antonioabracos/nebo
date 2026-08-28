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

%define LS_MAX_COLLECTIONS 2
%define LS_COLLECTION_VALUES 4
%define LS_NO_TOKEN 0xffffffffffffffff

section .rodata
ls_n_array: db 'Array'
ls_n_array_len equ $-ls_n_array
ls_n_as_slice: db 'asSlice'
ls_n_as_slice_len equ $-ls_n_as_slice
ls_n_list: db 'List'
ls_n_list_len equ $-ls_n_list
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
ls_collection_names: resq LS_MAX_COLLECTIONS
ls_collection_values: resq LS_MAX_COLLECTIONS*LS_COLLECTION_VALUES
ls_collection_value_counts: resq LS_MAX_COLLECTIONS
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
 ; Preserve deferred ownership priority structurally.
 lea rsi,[rel ls_n_list]
 mov edx,ls_n_list_len
 call ls_contains_atom
 test eax,eax
 jnz .list
 lea rsi,[rel ls_n_dict]
 mov edx,ls_n_dict_len
 call ls_contains_atom
 test eax,eax
 jnz .dict
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
.list:
 mov edi,6
 call ls_error
 jmp .done
.dict:
 mov edi,7
 call ls_error
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
NEBOC_ABI_FUNCTION neboc_vector_vertical_recognize
 push rbp
 mov rbp,rsp
 sub rsp,16
 call ls_initialize
 test eax,eax
 jz .invalid
 mov qword [rel ls_mode],11
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
 cmp qword [rel ls_collection_count],LS_MAX_COLLECTIONS
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
 call ls_parse_matrix_f01
 jmp .done
.tensor:
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
 cmp qword [rel ls_collection_count],LS_MAX_COLLECTIONS
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
