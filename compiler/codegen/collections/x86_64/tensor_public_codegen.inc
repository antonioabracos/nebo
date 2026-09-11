; Public Tensor plans retain dtype, ordered arguments and native geometry.
; Shape inputs are constant Tuple values or actual Int Vector values.
section .rodata
tp_Tensor: db 'Tensor'
tp_name_zeros: db 'zeros'
tp_name_filled: db 'filled'
tp_name_fromBuffer: db 'fromBuffer'
tp_name_dtype: db 'dtype'
tp_name_device: db 'device'
tp_name_storageId: db 'storageId'
tp_name_shape: db 'shape'
tp_name_rank: db 'rank'
tp_name_elementCount: db 'elementCount'
tp_name_strides: db 'strides'
tp_name_isContiguous: db 'isContiguous'
tp_name_axisSize: db 'axisSize'
tp_name_at: db 'at'
tp_name_slice: db 'slice'
tp_name_select: db 'select'
tp_name_narrow: db 'narrow'
tp_name_permute: db 'permute'
tp_name_reshape: db 'reshape'
tp_name_contiguous: db 'contiguous'
tp_name_broadcastTo: db 'broadcastTo'
tp_name_add: db 'add'
tp_name_multiply: db 'multiply'
tp_name_divide: db 'divide'
tp_name_maximum: db 'maximum'
tp_name_where: db 'where'
tp_name_map: db 'map'
tp_name_sum: db 'sum'
tp_name_mean: db 'mean'
tp_name_min: db 'min'
tp_name_max: db 'max'
tp_name_argMax: db 'argMax'
tp_name_all: db 'all'
tp_name_any: db 'any'
tp_name_matmul: db 'matmul'
tp_name_pad: db 'pad'
tp_name_concatenate: db 'concatenate'
tp_name_stack: db 'stack'
tp_name_split: db 'split'
tp_name_length: db 'length'
align 8
tp_methods:
 dq tp_name_zeros,5,1,1,0,2
 dq tp_name_filled,6,2,2,0,770
 dq tp_name_fromBuffer,10,3,2,0,516
 dq tp_name_fromBuffer,10,3,3,0,131588
 dq tp_name_dtype,5,4,0,1,0
 dq tp_name_device,6,5,0,1,0
 dq tp_name_storageId,9,6,0,1,0
 dq tp_name_shape,5,7,0,4,0
 dq tp_name_rank,4,8,0,1,0
 dq tp_name_elementCount,12,9,0,1,0
 dq tp_name_strides,7,10,0,4,0
 dq tp_name_isContiguous,12,11,0,2,0
 dq tp_name_axisSize,8,12,1,1,1
 dq tp_name_at,2,13,1,3,2
 dq tp_name_slice,5,14,1,0,2
 dq tp_name_select,6,15,2,0,257
 dq tp_name_narrow,6,16,3,0,65793
 dq tp_name_permute,7,17,1,0,2
 dq tp_name_reshape,7,18,1,0,2
 dq tp_name_contiguous,10,19,0,0,0
 dq tp_name_broadcastTo,11,20,1,0,2
 dq tp_name_add,3,21,1,0,5
 dq tp_name_multiply,8,22,1,0,5
 dq tp_name_divide,6,23,1,0,5
 dq tp_name_maximum,7,24,1,0,5
 dq tp_name_where,5,25,2,0,1286
 dq tp_name_map,3,26,1,0,7
 dq tp_name_sum,3,27,2,0,2050
 dq tp_name_mean,4,28,2,0,2050
 dq tp_name_min,3,29,2,0,2050
 dq tp_name_max,3,30,2,0,2050
 dq tp_name_argMax,6,31,1,5,1
 dq tp_name_all,3,32,1,0,1
 dq tp_name_any,3,33,1,0,1
 dq tp_name_matmul,6,37,1,0,5
 dq tp_name_pad,3,39,2,0,770
 dq tp_name_concatenate,11,34,2,0,265
 dq tp_name_stack,5,35,2,0,265
 dq tp_name_split,5,36,2,7,258
tp_methods_end:
tp_parts_methods:
 dq tp_name_at,2,40,1,6,1
 dq tp_name_length,6,41,0,1,0
tp_parts_methods_end:
section .text
fcg_tensor_type_decode:
 mov rdx,rdi
 sub rdx,FCG_TYPE_TENSOR_BOOL
 cmp rdx,2
 ja .no
 inc rdx
 mov eax,NEBOC_TYPE_ID_BOOL
 cmp edx,1
 je .done
 mov eax,NEBOC_TYPE_ID_INT
 cmp edx,2
 je .done
 mov eax,NEBOC_TYPE_ID_FLOAT
.done: ret
.no: xor eax,eax
 xor edx,edx
 ret

; Shape kind EAX: 1 constant Tuple, 2 static Vector<Int>, 3 shaped Vector<Int>.
; RDX constructor id for Tuple; RCX extent for constant/static cases.
fcg_tensor_shape_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 xor edx,edx
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 cmp eax,NEBOC_TYPE_ID_INT
 jne .tuple
 mov rcx,rdx
 mov eax,2
 test rdx,rdx
 jnz .done
 mov eax,3
 jmp .done
.tuple:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .no
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 cmp rdx,6
 ja .no
 mov [rsp+8],rdx
 mov r14,rcx
 mov r15,rdx
.member:
 test r15,r15
 jz .tuple_ready
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 ; Constant Tuple geometry is metadata. Effectful members cannot be replayed
 ; at use sites; dynamic geometry must use the material Vector owner.
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r15
 jmp .member
.tuple_ready:
 mov eax,1
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 jmp .done
.no: xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; State, parsed call -> operation EAX, result type RCX, dtype RDX, table R8.
fcg_tensor_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
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
 mov qword [rsp+16],0
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .method
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .method
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel tp_Tensor]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 mov edx,1
 cmp eax,NEBOC_TYPE_ID_BOOL
 je .constructor_type
 mov edx,2
 cmp eax,NEBOC_TYPE_ID_INT
 je .constructor_type
 mov edx,3
 cmp eax,NEBOC_TYPE_ID_FLOAT
 jne .bad
.constructor_type:
 mov [rsp+24],rax
 mov [rsp+32],rdx
 lea rax,[rdx+FCG_TYPE_TENSOR_BOOL-1]
 mov [rsp+40],rax
 mov qword [rsp+16],1
 jmp .lookup
.method:
 mov rdi,rbx
 mov rsi,[rsp]
 mov edx,1
 call fcg_probe_receiver_type
 mov [rsp+40],rax
 cmp rax,FCG_TYPE_TENSOR_PARTS
 je .parts_lookup
 mov rdi,rax
 call fcg_tensor_type_decode
 test eax,eax
 jz .no
 mov [rsp+24],rax
 mov [rsp+32],rdx
 jmp .lookup
.parts_lookup:
 mov qword [rsp+24],NEBOC_TYPE_ID_FLOAT
 mov qword [rsp+32],3
 lea r15,[rel tp_parts_methods]
 jmp .row
.lookup:
 lea r15,[rel tp_methods]
.row:
 lea rax,[rel tp_methods_end]
 cmp qword [rsp+40],FCG_TYPE_TENSOR_PARTS
 jne .table_end_ready
 lea rax,[rel tp_parts_methods_end]
.table_end_ready:
 cmp r15,rax
 jae .bad
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[r15]
 mov rcx,[r15+8]
 call fcg_token_matches_literal
 test eax,eax
 jnz .signature
.next_row:
 add r15,48
 jmp .row
.signature:
 mov rax,[r15+16]
 cmp eax,21
 jb .dtype_ready
 cmp eax,32
 jb .numeric_method
 cmp eax,33
 jbe .bool_method
 cmp qword [rsp+32],3
 jne .bad
 jmp .dtype_ready
.numeric_method:
 cmp qword [rsp+32],1
 je .bad
 cmp eax,23
 jb .dtype_ready
 cmp eax,27
 je .dtype_ready
 cmp qword [rsp+32],3
 jne .bad
 jmp .dtype_ready
.bool_method:
 cmp qword [rsp+32],1
 jne .bad
.dtype_ready:
 xor eax,eax
 cmp qword [r15+16],3
 seta al
 xor rax,[rsp+16]
 cmp rax,1
 jne .bad
 mov rax,[r15+24]
 cmp rax,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jne .next_row
 inc rax
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad
 mov r14,[rsp+8]
 mov rax,[r15+40]
 mov [rsp+48],rax
.argument:
 test r14,r14
 jz .result
 mov rax,[rsp+48]
 and eax,255
 cmp eax,2
 je .shape_argument
 cmp eax,4
 je .buffer_argument
 cmp eax,7
 je .kernel_argument
 cmp eax,9
 je .peers_argument
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,r14
 mov edx,1
 call fcg_infer_type
 mov rcx,NEBOC_TYPE_ID_INT
 cmp qword [rsp+56],1
 je .argument_type
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp qword [rsp+56],8
 je .argument_type
 mov ecx,FCG_TYPE_TENSOR_BOOL
 cmp qword [rsp+56],6
 je .argument_type
 mov rcx,[rsp+24]
 cmp qword [rsp+56],5
 jne .argument_type
 mov rcx,[rsp+40]
.argument_type:
 cmp rax,rcx
 jne .bad
 jmp .next_argument
.shape_argument:
 mov rdi,rbx
 mov rsi,r14
 call fcg_tensor_shape_info
 test eax,eax
 jz .bad
 jmp .next_argument
.peers_argument:
 mov rdi,rbx
 mov rsi,r14
 call fcg_tensor_peers_info
 test eax,eax
 jz .bad
 jmp .next_argument
.kernel_argument:
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 mov rcx,[rsp+24]
 mov r8,rcx
 call fcg_typed_callable_with_receiver
 test rax,rax
 jz .bad
 jmp .next_argument
.buffer_argument:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+24]
 call fcg_tensor_buffer_info
 test eax,eax
 jz .bad
.next_argument:
 shr qword [rsp+48],8
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .argument
.result:
 mov rcx,[rsp+40]
 mov rax,[r15+32]
 test rax,rax
 jz .ready
 mov ecx,NEBOC_TYPE_ID_INT
 cmp eax,1
 je .ready
 mov ecx,NEBOC_TYPE_ID_BOOL
 cmp eax,2
 je .ready
 mov rcx,[rsp+24]
 cmp eax,3
 je .ready
 mov ecx,FCG_TYPE_TENSOR_PARTS
 cmp eax,7
 je .ready
 mov ecx,FCG_TYPE_TENSOR_FLOAT
 cmp eax,6
 je .ready
 mov ecx,FCG_TYPE_TENSOR_INT
 cmp eax,5
 je .ready
 mov ecx,FCG_TYPE_VECTOR_INT_BASE
.ready:
 mov rax,[r15+16]
 mov rdx,[rsp+32]
 mov r8,r15
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.no: xor eax,eax
.done:
 dec qword [rbx+FCG_ASSOC_DEPTH]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Material numeric Vector or a live Int Slice. Return the same representation
; tags as shape_info, so all source buffers normalize to {data,count}.
fcg_tensor_buffer_info:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov edx,1
 call fcg_infer_type
 cmp r13,NEBOC_TYPE_ID_BOOL
 jne .numeric_buffer
 cmp rax,NEBOC_TYPE_ID_BYTES
 jne .no
 mov eax,3
 xor ecx,ecx
 jmp .done
.numeric_buffer:
 mov rdi,rax
 call fcg_vector_type_decode
 test eax,eax
 jz .slice
 cmp rax,r13
 jne .no
 mov rcx,rdx
 mov eax,2
 test rdx,rdx
 jnz .done
 mov eax,3
 jmp .done
.slice:
 cmp r13,NEBOC_TYPE_ID_INT
 jne .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_collection_binding_for_node
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AR_BIND_KIND_OFFSET],NEBOC_AR_KIND_SLICE
 jne .no
 cmp qword [rax+NEBOC_AR_BIND_TYPE_OFFSET],NEBOC_AR_TYPE_INT
 jne .no
 mov r13,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov rdi,rbx
 mov rsi,r13
 call fcg_slice_live_at_source
 cmp eax,2
 je .released
 cmp eax,1
 jne .no
 mov eax,3
 xor ecx,ecx
 jmp .done
.released:
 mov rdi,rbx
 mov rsi,r12
 mov edx,3
 call fcg_vector_error
.no: xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; Existing Tuple syntax carries a bounded sequence of immutable Tensor names.
; Binding references are evaluated once; effectful constructor members are
; rejected until Tuple has a general material aggregate ABI.
fcg_tensor_peers_info:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov rbx,rdi
 xor edx,edx
 call fcg_tuple_resolve_aggregate
 test rax,rax
 jz .no
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_tuple_call_shape
 test eax,eax
 jz .no
 test rdx,rdx
 jz .no
 cmp rdx,6
 ja .no
 mov [rsp+8],rdx
 mov r12,rcx
 mov r13,rdx
.member:
 test r13,r13
 jz .yes
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .no
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_TENSOR_FLOAT
 jne .no
 mov r12,r14
 dec r13
 jmp .member
.yes:
 mov eax,1
 mov rdx,[rsp]
 mov rcx,[rsp+8]
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Every Tensor operation has a stable argument frame and separate result.
fcg_tensor_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov [rsp+64],rdx
 call fcg_tensor_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+16],rcx
 mov [rsp+24],r8
 mov qword [rsp+32],33408
; Derived Int indices may have the full geometry of a Float reduction.
 ; Fresh storage follows the native 4096-element bound for every dtype.
.size:
 MP_APPEND ftm_frame_head
 MP_NUMBER [rsp+32]
 MP_APPEND ftm_frame_tail
 MP_APPEND tp_initialize_optional
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SLICE_TEMP_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor r15d,r15d
 cmp qword [rsp],3
 ja .receiver
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .arg_start
.receiver:
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+64]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND tp_store_receiver
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
.arg_start:
 mov rax,[rsp+24]
 mov rax,[rax+40]
 mov [rsp+40],rax
.argument:
 test r14,r14
 jz .invoke
 mov rax,[rsp+40]
 and eax,255
 cmp eax,2
 je .shape
 cmp eax,4
 je .buffer
 cmp eax,7
 je .kernel
 cmp eax,9
 je .peers
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+64]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 jmp .store
.peers:
 mov rdi,rbx
 mov rsi,r14
 call fcg_tensor_peers_info
 mov [rsp+48],rcx
 mov rdi,rbx
 mov rsi,rdx
 call fcg_tuple_call_shape
 mov [rsp+72],rcx
 xor r13d,r13d
.peer_member:
 cmp r13,[rsp+48]
 jae .tuple_ready
 mov rdi,rbx
 mov rsi,[rsp+72]
 mov rdx,[rsp+64]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 MP_APPEND tp_peer_store
 lea rax,[r13*8+272]
 MP_NUMBER rax
 MP_APPEND fcg_call_store_tail
 mov rdi,rbx
 mov rsi,[rsp+72]
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+72],rax
 inc r13
 jmp .peer_member
.kernel:
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_FLOAT
 mov r8,rcx
 call fcg_typed_callable_with_receiver
 mov [rsp+56],rax
 MP_APPEND tp_callback_pointer
 MP_NUMBER r12
 MP_APPEND tp_callback_pointer_tail
 MP_NUMBER r12
 MP_APPEND tp_callback_label
 MP_NUMBER r12
 MP_APPEND mp_callback_float
 MP_NUMBER [rsp+56]
 MP_APPEND mp_callback_float_result
 MP_APPEND tp_callback_tail
 MP_NUMBER r12
 MP_APPEND mp_callback_end
 jmp .invoke
.shape:
 mov rdi,rbx
 mov rsi,r14
 call fcg_tensor_shape_info
 jmp .aggregate_argument
.buffer:
 mov rdi,[rsp+16]
 call fcg_tensor_type_decode
 mov rdx,rax
 mov rdi,rbx
 mov rsi,r14
 call fcg_tensor_buffer_info
.aggregate_argument:
 mov [rsp+48],rcx
 mov [rsp+56],rax
 cmp eax,1
 je .tuple
 mov rdi,rbx
 mov rsi,r14
 mov rdx,[rsp+64]
 inc rdx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 cmp qword [rsp+56],3
 je .store
 MP_APPEND tp_shape_static_head
 mov rax,r15
 shl rax,6
 add rax,256
 MP_NUMBER rax
 MP_APPEND tp_shape_static_mid
 MP_NUMBER [rsp+48]
 MP_APPEND tp_shape_static_tail
 jmp .store
.tuple:
 mov rdi,rbx
 mov rsi,rdx
 call fcg_tuple_call_shape
 mov [rsp+72],rcx
 xor r13d,r13d
.tuple_member:
 cmp r13,[rsp+48]
 jae .tuple_ready
 mov rdi,rbx
 mov rsi,[rsp+72]
 call fcg_node_ptr
 mov rcx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+72],rcx
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+56],rcx
 MP_APPEND tp_tuple_member_head
 MP_NUMBER [rsp+56]
 MP_APPEND tp_tuple_member_mid
 mov rax,r15
 shl rax,6
 lea rax,[rax+r13*8+272]
 MP_NUMBER rax
 MP_APPEND tp_tuple_member_tail
 inc r13
 jmp .tuple_member
.tuple_ready:
 MP_APPEND tp_tuple_head
 mov rax,r15
 shl rax,6
 add rax,256
 MP_NUMBER rax
 MP_APPEND tp_tuple_mid
 MP_NUMBER [rsp+48]
 MP_APPEND tp_tuple_tail
.store:
 MP_APPEND fcg_call_store_head
 lea rax,[r15+1]
 shl rax,3
 cmp rax,24
 jb .slot
 add rax,8
.slot:
 MP_NUMBER rax
 MP_APPEND fcg_call_store_tail
 shr qword [rsp+40],8
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .argument
.invoke:
 MP_APPEND tp_invoke_head
 MP_NUMBER [rsp]
 MP_APPEND tp_invoke_dtype
 MP_NUMBER [rsp+8]
 MP_APPEND tp_invoke_tail
 mov rdi,[rsp+16]
 call fcg_native_type_is_material
 test eax,eax
 jnz .keep_result
 MP_APPEND tp_reclaim_head
 MP_NUMBER [rsp+32]
 MP_APPEND tp_reclaim_tail
.keep_result:
 MP_APPEND mp_frame_restore
 xor eax,eax
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
section .rodata
tp_store_receiver: db 32,32,32,32,109,111,118,32,91,114,49,50,93,44,32,114,97,120,10
tp_store_receiver_len equ $-tp_store_receiver
tp_initialize_optional: db '    mov qword [r12 + 32], 0',10
tp_initialize_optional_len equ $-tp_initialize_optional
tp_shape_static_head: db 32,32,32,32,108,101,97,32,114,49,49,44,32,91,114,49,50,32,43,32
tp_shape_static_head_len equ $-tp_shape_static_head
tp_shape_static_mid: db 93,10,32,32,32,32,109,111,118,32,91,114,49,49,93,44,32,114,97,120,10,32,32,32,32,109,111,118,32,113,119,111,114,100,32,91,114,49,49,32,43,32,56,93,44,32
tp_shape_static_mid_len equ $-tp_shape_static_mid
tp_shape_static_tail: db 10,32,32,32,32,109,111,118,32,114,97,120,44,32,114,49,49,10
tp_shape_static_tail_len equ $-tp_shape_static_tail
tp_tuple_member_head: db '    mov rax, '
tp_tuple_member_head_len equ $-tp_tuple_member_head
tp_tuple_member_mid: db 10,'    mov [r12 + '
tp_tuple_member_mid_len equ $-tp_tuple_member_mid
tp_tuple_member_tail: db '], rax',10
tp_tuple_member_tail_len equ $-tp_tuple_member_tail
tp_tuple_head: db 32,32,32,32,108,101,97,32,114,97,120,44,32,91,114,49,50,32,43,32
tp_tuple_head_len equ $-tp_tuple_head
tp_tuple_mid: db 93,10,32,32,32,32,108,101,97,32,114,49,49,44,32,91,114,97,120,32,43,32,49,54,93,10,32,32,32,32,109,111,118,32,91,114,97,120,93,44,32,114,49,49,10,32,32,32,32,109,111,118,32,113,119,111,114,100,32,91,114,97,120,32,43,32,56,93,44,32
tp_tuple_mid_len equ $-tp_tuple_mid
tp_tuple_tail: db 10
tp_tuple_tail_len equ $-tp_tuple_tail
tp_invoke_head: db 37,105,102,110,100,101,102,32,78,69,66,79,95,84,69,78,83,79,82,95,78,65,84,73,86,69,95,69,88,84,69,82,78,10,37,100,101,102,105,110,101,32,78,69,66,79,95,84,69,78,83,79,82,95,78,65,84,73,86,69,95,69,88,84,69,82,78,32,49,10,101,120,116,101,114,110,32,110,101,98,111,95,116,101,110,115,111,114,95,112,117,98,108,105,99,95,100,105,115,112,97,116,99,104,10,37,101,110,100,105,102,10,32,32,32,32,109,111,118,32,101,100,105,44,32
tp_invoke_head_len equ $-tp_invoke_head
tp_invoke_dtype: db 10,32,32,32,32,109,111,118,32,101,115,105,44,32
tp_invoke_dtype_len equ $-tp_invoke_dtype
tp_invoke_tail: db 10,'    lea rdx, [r12 + 64]',10,'    mov rcx, r12',10,'    lea r8, [r12 + 640]',10
 db '    call nebo_tensor_public_dispatch',10,'    cmp eax, 4',10,'    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10,'    jnz nebo_runtime_trap_arithmetic_domain',10,'    mov rax, rdx',10,'    movq xmm0, rax',10
tp_invoke_tail_len equ $-tp_invoke_tail
tp_reclaim_head: db 32,32,32,32,108,101,97,32,114,115,112,44,32,91,114,49,50,32,43,32
tp_reclaim_head_len equ $-tp_reclaim_head
tp_reclaim_tail: db 93,10
tp_reclaim_tail_len equ $-tp_reclaim_tail

tp_callback_pointer: db '    lea rax, [rel .nebo_tensor_callback_'
tp_callback_pointer_len equ $-tp_callback_pointer
tp_callback_pointer_tail: db ']',10,'    mov [r12 + 8], rax',10,'    jmp .nebo_tensor_callback_end_'
tp_callback_pointer_tail_len equ $-tp_callback_pointer_tail
tp_callback_label: db 10,'.nebo_tensor_callback_'
tp_callback_label_len equ $-tp_callback_label
tp_callback_tail: db 10,'    add rsp, 8',10,'    ret',10,'.nebo_tensor_callback_end_'
tp_callback_tail_len equ $-tp_callback_tail

tp_peer_store: db "    mov [r12 + "
tp_peer_store_len equ $-tp_peer_store
