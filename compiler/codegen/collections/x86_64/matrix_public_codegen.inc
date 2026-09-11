; Public Matrix calls use the ordinary typed AST and existing native layouts.
; Runtime descriptors carry shape/stride/storage identity; private TypeIds
; preserve the element family without treating source operands as metadata.
section .text
fcg_matrix_type_decode:
 cmp rdi,FCG_TYPE_MATRIX_INT
 je .integer
 cmp rdi,FCG_TYPE_MATRIX_FLOAT
 jne .no
 mov eax,NEBOC_TYPE_ID_FLOAT
 mov edx,2
 ret
.integer:
 mov eax,NEBOC_TYPE_ID_INT
 mov edx,1
 ret
.no:
 xor eax,eax
 xor edx,edx
 ret

%macro MP_MATCH 3
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro

; State, call id -> operation EAX, exact result TypeId RCX, native dtype RDX.
fcg_matrix_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+16],0
 mov qword [rsp+24],0
 inc qword [rbx+FCG_ASSOC_DEPTH]
 cmp qword [rbx+FCG_ASSOC_DEPTH],64
 ja .no
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 mov r13,rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .method
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .method
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel mp_Matrix]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 je .integer
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .bad
 mov qword [rsp+48],2
 mov qword [rsp+56],FCG_TYPE_MATRIX_FLOAT
 jmp .constructor
.integer:
 mov qword [rsp+48],1
 mov qword [rsp+56],FCG_TYPE_MATRIX_INT
.constructor:
 mov [rsp+32],rax
 MP_MATCH mp_zeros,5,.zeros
 MP_MATCH mp_filled,6,.filled
 MP_MATCH mp_fromRows,8,.from_rows
 MP_MATCH mp_fromBuffer,10,.from_buffer
 jmp .bad
.from_buffer:
 mov qword [rsp+40],22
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],4
 je .buffer_type
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],5
 jne .bad
.buffer_type:
 ; Native Vector lanes are also contiguous typed storage. Their existing
 ; extent-bearing TypeId supplies the count; no conversion erases dtype.
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 test rax,rax
 jz .buffer_slice
 cmp rax,[rsp+32]
 jne .bad
 mov [rsp+16],rdx
 mov qword [rsp+24],1
 jmp .buffer_dimensions
.buffer_slice:
 ; A borrowed source buffer is a live canonical Slice, never a source-text
 ; array substituted for a value. The descriptor supplies its runtime count.
 cmp qword [rsp+48],1
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .bad
 cmp qword [rax+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 jne .bad
 mov rdi,rbx
 mov rsi,rax
 mov rdx,[r13+NEBOC_AST_NODE_START_OFFSET]
 call fcg_slice_live_at_source
 cmp eax,2
 je .released
 cmp eax,1
 jne .bad
.buffer_dimensions:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+64],0
.buffer_dimension:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+64]
 cmp qword [rsp+64],2
 jb .buffer_dimension
 test r15,r15
 jz .yes
 ; Current native construction copies row-major storage. An occupied
 ; lexical name cannot silently acquire the meaning of layout metadata.
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov r15,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 mov rsi,r15
 call fcg_resolve_identifier
 test rax,rax
 jnz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[rel mp_rowMajor]
 mov ecx,8
 call fcg_token_matches_literal
 test eax,eax
 jz .bad
 jmp .yes
.from_rows:
 mov qword [rsp+40],13
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .bad
 mov rdx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov [rsp+16],rdx
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+64],0
.row_literal:
 test r14,r14
 jz .rows_done
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .bad
 mov rdx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp qword [rsp+64],0
 jne .same_columns
 mov [rsp+24],rdx
.same_columns:
 cmp rdx,[rsp+24]
 jne .bad
 inc qword [rsp+64]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.cell_literal:
 test r15,r15
 jz .row_literal
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .cell_literal
.rows_done:
 mov ecx,64
 cmp qword [rsp+48],2
 je .shape_limits
 mov ecx,8
.shape_limits:
 cmp [rsp+16],rcx
 ja .bounds
 cmp [rsp+24],rcx
 ja .bounds
 jmp .yes
.zeros:
 mov qword [rsp+40],1
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 jmp .dimensions
.filled:
 mov qword [rsp+40],2
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],4
 jne .bad
.dimensions:
 mov r15,[rsp+8]
 mov qword [rsp+64],0
.dimension:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+64]
 cmp qword [rsp+64],2
 jb .dimension
 cmp qword [rsp+40],2
 jne .yes
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
 jmp .yes
.method:
 mov rdi,rbx
 mov rsi,[rsp]
 mov edx,1
 call fcg_probe_receiver_type
 mov [rsp+72],rax
 cmp rax,FCG_TYPE_MATRIX_LU_TUPLE
 je .decomposition_projection
 cmp rax,FCG_TYPE_MATRIX_QR_TUPLE
 je .decomposition_projection
 mov rdi,rax
 call fcg_matrix_type_decode
 test rax,rax
 jz .vector_method
 mov [rsp+32],rax
 mov [rsp+48],rdx
 mov qword [rsp+56],NEBOC_TYPE_ID_INT
 MP_MATCH mp_rows,4,.rows
 MP_MATCH mp_columns,7,.columns
 MP_MATCH mp_layout,6,.layout
 MP_MATCH mp_at,2,.at
 MP_MATCH mp_isSquare,8,.square
 MP_MATCH mp_trace,5,.trace
 MP_MATCH mp_transposeView,13,.transpose
 MP_MATCH mp_contiguous,10,.contiguous
 MP_MATCH mp_row,3,.row
 MP_MATCH mp_column,6,.column
 MP_MATCH mp_add,3,.add
 MP_MATCH mp_subtract,8,.subtract
 MP_MATCH mp_multiplyElements,16,.multiply
 MP_MATCH mp_divideElements,14,.divide
 MP_MATCH mp_scale,5,.scale
 MP_MATCH mp_clamp,5,.clamp
 MP_MATCH mp_matmul,6,.matmul
 MP_MATCH mp_matmulInto,10,.matmul_into
 MP_MATCH mp_matvec,6,.matvec
 MP_MATCH mp_solve,5,.solve
 MP_MATCH mp_lu,2,.lu
 MP_MATCH mp_qr,2,.qr
 MP_MATCH mp_get,3,.get
 MP_MATCH mp_sum,3,.sum
 MP_MATCH mp_mean,4,.mean
 MP_MATCH mp_min,3,.minimum
 MP_MATCH mp_max,3,.maximum
 MP_MATCH mp_dotFlattened,12,.dot_flattened
 MP_MATCH mp_determinant,11,.determinant
 MP_MATCH mp_inverse,7,.inverse
 MP_MATCH mp_cholesky,8,.cholesky
 MP_MATCH mp_conditionEstimate,17,.condition
 MP_MATCH mp_slice,5,.slice
 MP_MATCH mp_map,3,.map
 jmp .no
.decomposition_projection:
 ; Preserve the native product's exact member types through the existing
 ; Tuple positional syntax (.0/.1 or .at(constant)). No erased scalar token.
 MP_MATCH mp_length,6,.decomposition_length
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_projection_info
 test eax,eax
 jz .bad
 cmp rdx,1
 ja .bounds
 lea rax,[rdx+41]
 mov [rsp+40],rax
 mov qword [rsp+48],2
 mov qword [rsp+56],FCG_TYPE_MATRIX_FLOAT
 test rdx,rdx
 jz .yes
 cmp qword [rsp+72],FCG_TYPE_MATRIX_QR_TUPLE
 je .yes
 mov qword [rsp+48],1
 mov qword [rsp+56],FCG_TYPE_VECTOR_INT_BASE
 jmp .yes
.decomposition_length:
 mov qword [rsp+40],43
 mov qword [rsp+48],2
 mov qword [rsp+56],NEBOC_TYPE_ID_INT
 jmp .none
.lu:
 mov qword [rsp+40],39
 mov qword [rsp+56],FCG_TYPE_MATRIX_LU_TUPLE
 jmp .decomposition
.qr:
 mov qword [rsp+40],40
 mov qword [rsp+56],FCG_TYPE_MATRIX_QR_TUPLE
.decomposition:
 cmp qword [rsp+48],2
 jne .bad
 jmp .none
.vector_method:
 mov rdi,[rsp+72]
 call fcg_vector_type_decode
 test rax,rax
 jz .no
 mov [rsp+32],rax
 mov [rsp+16],rdx
 mov qword [rsp+48],1
 mov qword [rsp+56],FCG_TYPE_MATRIX_INT
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .outer_name
 mov qword [rsp+48],2
 mov qword [rsp+56],FCG_TYPE_MATRIX_FLOAT
.outer_name:
 MP_MATCH mp_outer,5,.outer
 jmp .no
.outer:
 mov qword [rsp+40],36
 jmp .typed_vector_argument
.matvec:
 mov qword [rsp+40],35
 jmp .vector_return_type
.solve:
 cmp qword [rsp+48],2
 jne .bad
 mov qword [rsp+40],37
.vector_return_type:
 mov qword [rsp+56],FCG_TYPE_VECTOR_INT_BASE
 cmp qword [rsp+48],2
 jne .typed_vector_argument
 mov qword [rsp+56],FCG_TYPE_VECTOR_FLOAT_BASE
.typed_vector_argument:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 cmp rax,[rsp+32]
 jne .bad
 cmp qword [rsp+40],36
 je .outer_extent
 mov [rsp+16],rdx
 jmp .yes
.outer_extent:
 mov [rsp+24],rdx
 jmp .yes
.map:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 xor edx,edx
 mov rcx,[rsp+32]
 mov r8,rcx
 call fcg_typed_callable_with_receiver
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 mov rax,[rsp+72]
 mov [rsp+56],rax
 mov qword [rsp+40],30
 jmp .yes
.slice:
 mov qword [rsp+40],29
 mov rax,[rsp+72]
 mov [rsp+56],rax
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],5
 je .slice_scalar_arguments
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_matrix_range_info
 test eax,eax
 jz .bad
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_matrix_range_info
 test eax,eax
 jz .bad
 mov [rsp+24],rax
 jmp .yes
.slice_scalar_arguments:
 mov r15,[rsp+8]
.slice_scalar:
 test r15,r15
 jz .yes
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .slice_scalar
.dot_flattened:
 mov qword [rsp+40],24
 cmp qword [rsp+48],2
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rax,[rsp+32]
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+72]
 jne .bad
 jmp .yes
.determinant:
 mov qword [rsp+40],25
 jmp .float_scalar_none
.condition:
 mov qword [rsp+40],28
.float_scalar_none:
 cmp qword [rsp+48],2
 jne .bad
 mov rax,[rsp+32]
 mov [rsp+56],rax
 jmp .none
.inverse:
 mov qword [rsp+40],26
 jmp .float_matrix_none
.cholesky:
 mov qword [rsp+40],27
.float_matrix_none:
 cmp qword [rsp+48],2
 jne .bad
 jmp .matrix_none
.sum_axis:
 mov qword [rsp+40],31
 jmp .axis
.mean:
 mov qword [rsp+40],32
 jmp .axis
.minimum:
 mov qword [rsp+40],33
 jmp .axis
.maximum:
 mov qword [rsp+40],34
.axis:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov qword [rsp+56],FCG_TYPE_VECTOR_FLOAT_BASE
 cmp qword [rsp+48],2
 je .yes
 cmp qword [rsp+40],32
 je .yes
 mov qword [rsp+56],FCG_TYPE_VECTOR_INT_BASE
 jmp .yes
.sum:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .sum_axis
 mov qword [rsp+40],23
 mov rax,[rsp+32]
 mov [rsp+56],rax
 jmp .none
.rows:
 mov qword [rsp+40],3
 jmp .none
.columns:
 mov qword [rsp+40],4
 jmp .none
.layout:
 mov qword [rsp+40],5
 jmp .none
.at:
 mov qword [rsp+40],6
 mov rax,[rsp+32]
 mov [rsp+56],rax
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 ; The common dimension loop validates row and column as material Ints.
 jmp .dimensions
.get:
 mov qword [rsp+40],21
 mov qword [rsp+56],FCG_TYPE_OPTION_INT
 cmp qword [rsp+48],1
 je .get_indices
 mov qword [rsp+56],FCG_TYPE_OPTION_FLOAT
.get_indices:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 jmp .dimensions
.square:
 mov qword [rsp+40],7
 mov qword [rsp+56],NEBOC_TYPE_ID_BOOL
 jmp .none
.trace:
 mov qword [rsp+40],8
 mov rax,[rsp+32]
 mov [rsp+56],rax
 jmp .none
.transpose:
 mov qword [rsp+40],9
 jmp .matrix_none
.contiguous:
 mov qword [rsp+40],10
.matrix_none:
 mov rax,[rsp+72]
 mov [rsp+56],rax
 jmp .none
.row:
 mov qword [rsp+40],11
 jmp .matrix_index
.column:
 mov qword [rsp+40],12
.matrix_index:
 mov rax,[rsp+72]
 mov [rsp+56],rax
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 jmp .yes
.add:
 mov qword [rsp+40],14
 jmp .binary_matrix
.subtract:
 mov qword [rsp+40],15
 jmp .binary_matrix
.multiply:
 mov qword [rsp+40],16
 jmp .binary_matrix
.divide:
 cmp qword [rsp+48],2
 jne .bad
 mov qword [rsp+40],17
 jmp .binary_matrix
.matmul:
 mov qword [rsp+40],20
 jmp .binary_matrix
.matmul_into:
 ; The destination is an existing typed Matrix value, not a constructor
 ; placeholder. Native ownership/shape/overlap preflight precedes writes.
 mov qword [rsp+40],38
 mov qword [rsp+56],NEBOC_TYPE_ID_VOID
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov r15,[rsp+8]
.into_argument:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+72]
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 je .into_output
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jnz .into_argument
 jmp .yes
.into_output:
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_matrix_is_parameter_borrow
 test eax,eax
 jz .yes
 mov rdi,rbx
 mov rsi,r12
 mov edx,4
 call fcg_vector_error
 jmp .no
.binary_matrix:
 mov rax,[rsp+72]
 mov [rsp+56],rax
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+72]
 jne .bad
 jmp .yes
.scale:
 mov qword [rsp+40],18
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 jmp .scalar_argument
.clamp:
 cmp qword [rsp+48],2
 jne .bad
 mov qword [rsp+40],19
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
.scalar_argument:
 mov rax,[rsp+72]
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
 jmp .yes
.none:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
.yes:
 mov rax,[rsp+40]
 mov rcx,[rsp+56]
 mov rdx,[rsp+48]
 mov r8,[rsp+16]
 mov r9,[rsp+24]
 jmp .done
.bounds:
 mov rdi,rbx
 mov rsi,r12
 mov edx,2
 call fcg_vector_error
 jmp .no
.released:
 mov rdi,rbx
 mov rsi,r12
 mov edx,3
 call fcg_vector_error
 jmp .no
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.no:
 xor eax,eax
 xor ecx,ecx
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; A range is an ordinary binary AST node with two independently typed Int
; operands. Its inclusivity is retained for normalization during lowering.
fcg_matrix_range_info:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 jne .no
 mov r13,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp r13,NEBOC_TOKEN_RANGE_INCLUSIVE
 jb .no
 cmp r13,NEBOC_TOKEN_RANGE_EXCLUSIVE
 ja .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r12,r12
 jnz .child
 mov rax,r13
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

%macro MP_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
%macro MP_NUMBER 1
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,%1
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
%endmacro
fcg_matrix_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+48],rdx
 call fcg_matrix_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+72],rcx
 mov [rsp+32],r8
 mov [rsp+56],r9
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+16],rsi
 mov rdi,rbx
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+24],rax
 MP_APPEND mp_extern
 MP_APPEND ftm_frame_head
 mov esi,160
 cmp qword [rsp],41
 jae .frame
 cmp qword [rsp],39
 jae .decomposition_frame
 cmp qword [rsp],38
 je .frame
 cmp qword [rsp],37
 je .algebra_frame
 cmp qword [rsp],29
 je .frame
 cmp qword [rsp],25
 jb .not_algebra_frame
 cmp qword [rsp],28
 jbe .algebra_frame
.not_algebra_frame:
 cmp qword [rsp],24
 je .frame
 cmp qword [rsp],21
 je .frame
 cmp qword [rsp],23
 je .frame
 cmp qword [rsp],14
 jae .owned_frame
 cmp qword [rsp],13
 je .rows_frame
 cmp qword [rsp],10
 je .owned_frame
 cmp qword [rsp],2
 ja .frame
.owned_frame:
 mov esi,672
 cmp qword [rsp],35
 jb .owned_size
 mov esi,864
.owned_size:
 cmp qword [rsp+8],1
 je .frame
 mov esi,32928
 jmp .frame
.algebra_frame:
 ; Result payload (64*64), LU (32*32), pivots and two solve vectors.
 mov esi,41920
 jmp .frame
.decomposition_frame:
 ; Two native descriptors plus disjoint 32x32 payloads, or LU/pivot storage.
 mov esi,16672
 jmp .frame
.rows_frame:
 mov esi,1184
 cmp qword [rsp+8],1
 je .frame
 mov esi,65696
.frame:
 mov [rsp+64],rsi
 MP_NUMBER rsi
 MP_APPEND ftm_frame_tail
 cmp qword [rsp],13
 je .emit_rows
 cmp qword [rsp],22
 je .buffer_arguments
 cmp qword [rsp],2
 jbe .arguments
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov rdx,[rsp+48]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND mp_receiver
 cmp qword [rsp],36
 jne .receiver_ready
 cmp qword [rsp+32],0
 je .receiver_ready
 MP_APPEND mp_outer_receiver
 MP_NUMBER [rsp+32]
 MP_APPEND mp_outer_receiver_tail
.receiver_ready:
 cmp qword [rsp],41
 jae .invoke
 cmp qword [rsp],30
 je .emit_callback
 cmp qword [rsp],29
 jne .arguments
 cmp qword [rsp+32],0
 jne .emit_ranges
 jmp .arguments
.buffer_arguments:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET],0
.arguments:
 mov qword [rsp+40],0
.argument:
 cmp qword [rsp],22
 jne .argument_expression
 cmp qword [rsp+40],3
 jae .invoke
.argument_expression:
 mov rsi,[rsp+24]
 test rsi,rsi
 jz .invoke
 mov rdi,rbx
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,[rsp+24]
 mov rdx,[rsp+48]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND mp_store_head
 mov rsi,[rsp+40]
 inc rsi
 shl rsi,3
 cmp rsi,24
 jb .offset
 add rsi,8
.offset:
 MP_NUMBER rsi
 MP_APPEND mp_store_tail
 cmp qword [rsp],36
 je .outer_argument
 cmp qword [rsp],35
 je .vector_argument
 cmp qword [rsp],37
 je .vector_argument
 cmp qword [rsp],22
 jne .argument_stored
 cmp qword [rsp+40],0
 jne .argument_stored
 cmp qword [rsp+56],1
 jne .argument_stored
 cmp qword [rsp+32],0
 je .argument_stored
.vector_argument:
 cmp qword [rsp+32],0
 je .argument_stored
 MP_APPEND mp_vector_buffer
 MP_NUMBER [rsp+32]
 MP_APPEND mp_vector_buffer_tail
 jmp .argument_stored
.outer_argument:
 cmp qword [rsp+56],0
 je .argument_stored
 MP_APPEND mp_outer_argument
 MP_NUMBER [rsp+56]
 MP_APPEND mp_outer_argument_tail
.argument_stored:
 mov [rsp+24],r14
 inc qword [rsp+40]
 jmp .argument
.emit_callback:
 ; Only the resolved FunctionTable symbol enters this bridge. The callback
 ; receives one exact scalar value; it never captures a caller-local frame.
 MP_APPEND mp_callback_pointer
 MP_NUMBER r12
 MP_APPEND mp_callback_pointer_tail
 MP_NUMBER r12
 MP_APPEND mp_callback_label
 MP_NUMBER r12
 cmp qword [rsp+8],2
 je .float_callback
 MP_APPEND mp_callback_int
 jmp .callback_function
.float_callback:
 MP_APPEND mp_callback_float
.callback_function:
 MP_NUMBER [rsp+32]
 cmp qword [rsp+8],2
 jne .callback_tail
 MP_APPEND mp_callback_float_result
.callback_tail:
 MP_APPEND mp_callback_tail
 MP_NUMBER r12
 MP_APPEND mp_callback_end
 jmp .invoke
.emit_ranges:
 mov qword [rsp+40],0
 mov r14,[rsp+24]
.emit_range:
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.emit_range_bound:
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rsp+48]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[rsp+32]
 cmp qword [rsp+40],2
 jb .range_policy
 mov rax,[rsp+56]
.range_policy:
 test qword [rsp+40],1
 jnz .range_end_policy
 cmp rax,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 jae .range_increment
 jmp .range_store
.range_end_policy:
 cmp rax,NEBOC_TOKEN_RANGE_INCLUSIVE
 je .range_increment
 cmp rax,NEBOC_TOKEN_RANGE_EXCLUSIVE_START
 jne .range_store
.range_increment:
 MP_APPEND mp_bound_increment
.range_store:
 MP_APPEND mp_store_head
 mov rsi,[rsp+40]
 inc rsi
 shl rsi,3
 cmp rsi,24
 jb .range_offset
 add rsi,8
.range_offset:
 MP_NUMBER rsi
 MP_APPEND mp_store_tail
 inc qword [rsp+40]
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jnz .emit_range_bound
 test r14,r14
 jnz .emit_range
 MP_APPEND mp_range_counts
 jmp .invoke
.emit_rows:
 mov qword [rsp+40],0
 mov rdi,rbx
 mov rsi,[rsp+24]
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.emit_row:
 test r14,r14
 jz .emit_rows_shape
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.emit_cell:
 test r15,r15
 jz .emit_row
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rsp+48]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND mp_store_head
 mov rsi,[rsp+40]
 shl rsi,3
 cmp qword [rsp+8],1
 jne .float_cell_offset
 add rsi,672
 jmp .cell_offset
.float_cell_offset:
 add rsi,32928
.cell_offset:
 MP_NUMBER rsi
 MP_APPEND mp_store_tail
 inc qword [rsp+40]
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .emit_cell
.emit_rows_shape:
 MP_APPEND mp_literal_rows
 MP_NUMBER [rsp+32]
 MP_APPEND mp_literal_columns
 MP_NUMBER [rsp+56]
 MP_APPEND mp_literal_buffer
 mov esi,672
 cmp qword [rsp+8],1
 je .literal_offset
 mov esi,32928
.literal_offset:
 MP_NUMBER rsi
 MP_APPEND mp_literal_buffer_tail
.invoke:
 MP_APPEND mp_operation
 MP_NUMBER [rsp]
 MP_APPEND mp_dtype
 MP_NUMBER [rsp+8]
 MP_APPEND mp_call
 mov rax,[rsp+72]
 cmp rax,NEBOC_TYPE_ID_INT
 je .scalar_frame_release
 cmp rax,NEBOC_TYPE_ID_FLOAT
 je .scalar_frame_release
 cmp rax,NEBOC_TYPE_ID_BOOL
 je .scalar_frame_release
 cmp rax,NEBOC_TYPE_ID_VOID
 jne .frame_restore
.scalar_frame_release:
 MP_APPEND mp_scalar_frame_release
 MP_NUMBER [rsp+64]
 MP_APPEND mp_scalar_frame_release_tail
.frame_restore:
 MP_APPEND mp_frame_restore
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
mp_Matrix: db 'Matrix'
mp_zeros: db 'zeros'
mp_filled: db 'filled'
mp_rows: db 'rows'
mp_columns: db 'columns'
mp_layout: db 'layout'
mp_at: db 'at'
mp_isSquare: db 'isSquare'
mp_trace: db 'trace'
mp_transposeView: db 'transposeView'
mp_contiguous: db 'contiguous'
mp_row: db 'row'
mp_column: db 'column'
mp_fromRows: db 'fromRows'
mp_fromBuffer: db 'fromBuffer'
mp_rowMajor: db 'rowMajor'
mp_vector_buffer:
 db '    mov [r12 + 48], rax',10,'    mov qword [r12 + 56], '
mp_vector_buffer_len equ $-mp_vector_buffer
mp_vector_buffer_tail:
 db 10,'    lea rax, [r12 + 48]',10,'    mov [r12 + 8], rax',10
mp_vector_buffer_tail_len equ $-mp_vector_buffer_tail
mp_mean: db 'mean'
mp_min: db 'min'
mp_max: db 'max'
mp_sum: db 'sum'
mp_map: db 'map'
mp_slice: db 'slice'
mp_dotFlattened: db 'dotFlattened'
mp_determinant: db 'determinant'
mp_inverse: db 'inverse'
mp_cholesky: db 'cholesky'
mp_conditionEstimate: db 'conditionEstimate'
mp_bound_increment: db '    add rax, 1',10,'    jo nebo_runtime_trap_overflow',10
mp_bound_increment_len equ $-mp_bound_increment
mp_range_counts:
 db '    mov rax, [r12 + 8]',10,'    sub [r12 + 16], rax',10,'    jo nebo_runtime_trap_overflow',10
 db '    mov rax, [r12 + 32]',10,'    sub [r12 + 40], rax',10,'    jo nebo_runtime_trap_overflow',10
mp_range_counts_len equ $-mp_range_counts
mp_add: db 'add'
mp_subtract: db 'subtract'
mp_multiplyElements: db 'multiplyElements'
mp_divideElements: db 'divideElements'
mp_scale: db 'scale'
mp_clamp: db 'clamp'
mp_matvec: db 'matvec'
mp_solve: db 'solve'
mp_outer: db 'outer'
mp_matmul: db 'matmul'
mp_matmulInto: db 'matmulInto'
mp_lu: db 'lu'
mp_qr: db 'qr'
mp_length: db 'length'
mp_get: db 'get'
mp_literal_rows: db '    mov qword [r12 + 8], '
mp_literal_rows_len equ $-mp_literal_rows
mp_literal_columns: db 10,'    mov qword [r12 + 16], '
mp_literal_columns_len equ $-mp_literal_columns
mp_literal_buffer: db 10,'    lea rax, [r12 + '
mp_literal_buffer_len equ $-mp_literal_buffer
mp_literal_buffer_tail: db ']',10,'    mov [r12 + 32], rax',10
mp_literal_buffer_tail_len equ $-mp_literal_buffer_tail
mp_extern:
 db '%ifndef NEBO_PUBLIC_MATRIX_DECLARED',10,'%define NEBO_PUBLIC_MATRIX_DECLARED 1',10
 db 'extern nebo_matrix_public_dispatch',10,'%endif',10
mp_extern_len equ $-mp_extern
mp_receiver: db '    mov [r12], rax',10
mp_receiver_len equ $-mp_receiver
mp_store_head: db '    mov [r12 + '
mp_store_head_len equ $-mp_store_head
mp_store_tail: db '], rax',10
mp_store_tail_len equ $-mp_store_tail
mp_operation: db '    mov edi, '
mp_operation_len equ $-mp_operation
mp_dtype: db 10,'    mov esi, '
mp_dtype_len equ $-mp_dtype
mp_call:
 db 10,'    lea rdx, [r12 + 64]',10,'    mov rcx, r12',10,'    lea r8, [r12 + 160]',10
 db '    call nebo_matrix_public_dispatch',10,'    cmp eax, 4',10,'    je nebo_runtime_trap_overflow',10,'    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10,'    mov rax, rdx',10,'    movq xmm0, rax',10
mp_call_len equ $-mp_call
mp_scalar_frame_release: db '    lea rsp, [r12 + '
mp_scalar_frame_release_len equ $-mp_scalar_frame_release
mp_scalar_frame_release_tail: db ']',10
mp_scalar_frame_release_tail_len equ $-mp_scalar_frame_release_tail
mp_frame_restore: db '    mov r12, [r12 + 24]',10
mp_frame_restore_len equ $-mp_frame_restore
section .text

mp_callback_pointer: db '    lea rax, [rel .nebo_matrix_callback_'
mp_callback_pointer_len equ $-mp_callback_pointer
mp_callback_pointer_tail: db ']',10,'    mov [r12 + 8], rax',10,'    jmp .nebo_matrix_callback_end_'
mp_callback_pointer_tail_len equ $-mp_callback_pointer_tail
mp_callback_label: db 10,'.nebo_matrix_callback_'
mp_callback_label_len equ $-mp_callback_label
mp_callback_int: db ':',10,'    sub rsp, 8',10,'    mov rdi, rsi',10,'    call nebo_fn_'
mp_callback_int_len equ $-mp_callback_int
mp_callback_float: db ':',10,'    sub rsp, 8',10,'    movq rdi, xmm0',10,'    call nebo_fn_'
mp_callback_float_len equ $-mp_callback_float
mp_callback_float_result: db 10,'    movq xmm0, rax'
mp_callback_float_result_len equ $-mp_callback_float_result
mp_callback_tail: db 10,'    add rsp, 8',10,'    ret',10,'.nebo_matrix_callback_end_'
mp_callback_tail_len equ $-mp_callback_tail
mp_callback_end: db ':',10
mp_callback_end_len equ $-mp_callback_end

mp_outer_receiver: db '    mov [r12 + 48], rax',10,'    mov qword [r12 + 56], '
mp_outer_receiver_len equ $-mp_outer_receiver
mp_outer_receiver_tail: db 10,'    lea rax, [r12 + 48]',10,'    mov [r12], rax',10
mp_outer_receiver_tail_len equ $-mp_outer_receiver_tail
mp_outer_argument: db '    mov [r12 + 32], rax',10,'    mov qword [r12 + 40], '
mp_outer_argument_len equ $-mp_outer_argument
mp_outer_argument_tail: db 10,'    lea rax, [r12 + 32]',10,'    mov [r12 + 8], rax',10
mp_outer_argument_tail_len equ $-mp_outer_argument_tail
