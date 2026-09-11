; Public Vector expressions retain element type and extent in the ordinary
; Program AST. This backend owns no numeric algorithm: its typed plan calls
; runtime/numeric/vector.asm and allocates separate owned storage per result.
section .text

; Private identity -> scalar TypeId, extent. Extent zero means a runtime
; descriptor, not an empty literal; zero scalar TypeId means not a Vector.
fcg_vector_type_decode:
 mov rdx,rdi
 sub rdx,FCG_TYPE_VECTOR_INT_BASE
 cmp rdx,64
 ja .float
 mov eax,NEBOC_TYPE_ID_INT
 ret
.float:
 mov rdx,rdi
 sub rdx,FCG_TYPE_VECTOR_FLOAT_BASE
 cmp rdx,64
 ja .no
 mov eax,NEBOC_TYPE_ID_FLOAT
 ret
.no:
 xor eax,eax
 xor edx,edx
 ret

%macro NV_MATCH 3
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro

; state, call id -> operation, result type RCX, vector type RDX, extent R8.
; Every source operand is validated without evaluating it. A constructor's
; type arguments are AST metadata, never runtime arguments or erased tokens.
fcg_vector_info:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov qword [rsp+72],0
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
 lea rdx,[rel nv_Vector]
 mov ecx,6
 call fcg_token_matches_literal
 test eax,eax
 jz .no
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 je .element_ready
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .bad
.element_ready:
 mov [rsp+32],rax
 mov qword [rsp+24],0
 test r15,r15
 jz .extent_ready
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .bad
 cmp qword [rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET],0
 jne .bad
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,1
 jb .bounds
 cmp rax,64
 ja .bounds
 mov [rsp+24],rax
.extent_ready:
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR
 jnz .literal
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 NV_MATCH nv_filled,6,.filled
 jmp .bad
.filled:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
 mov qword [rsp+40],1
 jmp .constructor_type
.literal:
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .bad
 mov rcx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp rcx,1
 jb .bounds
 cmp rcx,64
 ja .bounds
 cmp qword [rsp+24],0
 je .literal_extent
 cmp rcx,[rsp+24]
 jne .bad
.literal_extent:
 mov [rsp+24],rcx
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+56],0
.literal_element:
 test r15,r15
 jz .literal_done
 inc qword [rsp+56]
 mov rdi,rbx
 mov rsi,r15
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+32]
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .literal_element
.literal_done:
 mov rax,[rsp+56]
 cmp rax,[rsp+24]
 jne .bad
 mov qword [rsp+40],2
.constructor_type:
 mov rax,FCG_TYPE_VECTOR_INT_BASE
 cmp qword [rsp+32],NEBOC_TYPE_ID_FLOAT
 jne .constructor_int
 mov rax,FCG_TYPE_VECTOR_FLOAT_BASE
.constructor_int:
 add rax,[rsp+24]
 mov [rsp+16],rax
 mov [rsp+48],rax
 jmp .yes
.method:
 mov rdi,rbx
 mov rsi,[rsp]
 mov edx,1
 call fcg_probe_receiver_type
 mov [rsp+16],rax
 mov rdi,rax
 call fcg_vector_type_decode
 test rax,rax
 jz .no
 mov [rsp+32],rax
 mov [rsp+24],rdx
 NV_MATCH ac_at,2,.at
 NV_MATCH nv_add,3,.add
 NV_MATCH nv_scale,5,.scale
 NV_MATCH nv_dot,3,.dot
 NV_MATCH nv_norm,4,.norm
 NV_MATCH nv_normalize,9,.normalize
 NV_MATCH nv_sum,3,.sum
 NV_MATCH nv_mean,4,.mean
 NV_MATCH nv_variance,8,.variance
 NV_MATCH nv_stddev,17,.stddev
 NV_MATCH nv_quantile,8,.quantile
 NV_MATCH nv_median,6,.median
 NV_MATCH nv_correlation,11,.correlation
 ; Ordinary methods such as console() continue to their own typed owners.
 jmp .no
.sum:
 mov qword [rsp+40],9
 mov rax,[rsp+32]
 mov [rsp+48],rax
 jmp .stats_zero
.mean:
 mov qword [rsp+40],10
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 jmp .stats_zero
.median:
 mov qword [rsp+40],14
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
.stats_zero:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 jmp .yes
.variance:
 mov qword [rsp+40],11
 jmp .stats_kind
.stddev:
 mov qword [rsp+40],12
.stats_kind:
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_vector_policy
 test edx,edx
 jz .bad
 cmp rax,1
 ja .bad
 mov [rsp+72],rax
 test rax,rax
 jz .yes
 cmp qword [rsp+24],0
 je .yes
 cmp qword [rsp+24],2
 jb .bounds
 jmp .yes
.quantile:
 mov qword [rsp+40],13
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],3
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_FLOAT
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 call fcg_vector_policy
 test edx,edx
 jz .bad
 cmp rax,2
 jne .bad
 mov [rsp+72],rax
 jmp .yes
.correlation:
 mov qword [rsp+40],15
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 mov rax,[rsp+16]
 mov [rsp+64],rax
 jmp .one_argument
.at:
 mov qword [rsp+40],3
 mov rax,[rsp+32]
 mov [rsp+48],rax
 mov qword [rsp+64],NEBOC_TYPE_ID_INT
 jmp .one_argument
.add:
 mov qword [rsp+40],4
 mov rax,[rsp+16]
 mov [rsp+48],rax
 mov [rsp+64],rax
 jmp .one_argument
.scale:
 mov qword [rsp+40],5
 mov rax,[rsp+16]
 mov [rsp+48],rax
 mov rax,[rsp+32]
 mov [rsp+64],rax
 jmp .one_argument
.dot:
 mov qword [rsp+40],6
 mov rax,[rsp+32]
 mov [rsp+48],rax
 mov rax,[rsp+16]
 mov [rsp+64],rax
 jmp .one_argument
.norm:
 mov qword [rsp+40],7
 mov qword [rsp+48],NEBOC_TYPE_ID_FLOAT
 jmp .zero_argument
.normalize:
 mov qword [rsp+40],8
 mov rax,[rsp+16]
 mov [rsp+48],rax
.zero_argument:
 cmp qword [rsp+32],NEBOC_TYPE_ID_FLOAT
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 jmp .yes
.one_argument:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .bad
 cmp qword [r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .bad
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,[rsp+64]
 je .argument_type_ready
 ; Static/dynamic shapes compose only with the same exact element type.
 ; Two different static extents remain a type error; dynamic extents are
 ; compared before native computation by the shared runtime ABI bridge.
 cmp qword [rsp+40],4
 je .mixed_vector_argument
 cmp qword [rsp+40],6
 je .mixed_vector_argument
 cmp qword [rsp+40],15
 jne .bad
.mixed_vector_argument:
 mov rdi,rax
 call fcg_vector_type_decode
 cmp rax,[rsp+32]
 jne .bad
 test rdx,rdx
 jz .argument_type_ready
 cmp qword [rsp+24],0
 jne .bad
.argument_type_ready:
 cmp qword [rsp+40],3
 jne .yes
 ; Constant indices can be checked at the typed owner. Dynamic Int indices
 ; retain the same canonical native bounds check at runtime.
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .constant_index
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 jne .yes
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .yes
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 jne .yes
 cmp qword [rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 jne .bounds
 jmp .yes
.constant_index:
 cmp qword [rsp+24],0
 je .yes
 mov rax,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,[rsp+24]
 jae .bounds
.yes:
 mov rax,[rsp+40]
 mov rcx,[rsp+48]
 mov rdx,[rsp+16]
 mov r8,[rsp+24]
 mov r9,[rsp+72]
 jmp .done
.bounds:
 mov edx,2
 jmp .error
.bad:
 mov edx,1
.error:
 mov rdi,rbx
 mov rsi,r12
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

; Policy names are static public metadata. A lexical value cannot silently
; acquire enum meaning from its spelling; occupied names fail type checking.
fcg_vector_policy:
 push rbx
 push r12
 push r13
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
%macro NV_POLICY 3
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jnz %3
%endmacro
 NV_POLICY nv_population,10,.population
 NV_POLICY nv_sample,6,.sample
 NV_POLICY nv_linear,11,.linear
.no:
 xor eax,eax
 xor edx,edx
 jmp .done
.population:
 xor eax,eax
 jmp .yes
.sample:
 mov eax,1
 jmp .yes
.linear:
 mov eax,2
.yes:
 mov edx,1
.done:
 pop r13
 pop r12
 pop rbx
 ret

fcg_vector_error:
 push rbx
 mov rbx,rdi
 cmp qword [rbx+FCG_VECTOR_ERROR],0
 jne .done
 mov [rbx+FCG_VECTOR_ERROR],rdx
 call fcg_node_ptr
 test rax,rax
 jz .done
 mov rdx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [rbx+FCG_VECTOR_ERROR_START],rdx
 mov rdx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [rbx+FCG_VECTOR_ERROR_END],rdx
.done:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret

%macro NV_APPEND 1
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%1 %+ _len
 call fcg_append
 test eax,eax
 jnz .done
%endmacro
%macro NV_NUMBER 1
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,%1
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .done
%endmacro

; Every expression owns a linked, budget-checked frame. Arguments are emitted
; once in source order and survive nested calls. No helper return becomes the
; program status: scalar results are adapted only after native status checks.
fcg_vector_emit:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 call fcg_vector_info
 test eax,eax
 jz .bad
 mov [rsp],rax
 mov [rsp+8],rdx
 mov [rsp+16],r8
 mov [rsp+56],r9
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov r14,rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+24],rsi
 mov rdi,rbx
 call fcg_node_ptr
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+32],rax
 cmp qword [rsp+16],0
 je .runtime_shape
 cmp qword [rsp],4
 je .check_other_shape
 cmp qword [rsp],6
 je .check_other_shape
 cmp qword [rsp],15
 jne .static_shape
.check_other_shape:
 mov rdi,rbx
 mov rsi,[rsp+32]
 mov edx,1
 call fcg_infer_type
 mov rdi,rax
 call fcg_vector_type_decode
 test rdx,rdx
 jnz .static_shape
.runtime_shape:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_shaped_vector_emit
 jmp .done
.static_shape:
 mov rax,[rsp+16]
 shl rax,4
 add rax,47
 and rax,-16
 cmp qword [rsp],9
 jb .frame_sized
 mov eax,1600
.frame_sized:
 mov [rsp+40],rax
 NV_APPEND nv_externs
 NV_APPEND ftm_frame_head
 NV_NUMBER [rsp+40]
 NV_APPEND ftm_frame_tail
 cmp qword [rsp],2
 je .literal
 cmp qword [rsp],1
 je .argument
 mov rdi,rbx
 mov rsi,[rsp+24]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_save_receiver
 cmp qword [rsp],9
 jae .statistics
.argument:
 cmp qword [rsp],7
 jae .invoke
 mov rdi,rbx
 mov rsi,[rsp+32]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_save_argument
.invoke:
 NV_APPEND nv_extent
 NV_NUMBER [rsp+16]
 NV_APPEND fcg_newline
 ; Immutable table selects only an ABI adapter, never a computed answer.
 mov rax,[rsp]
 dec rax
 cmp qword [rsp+8],FCG_TYPE_VECTOR_FLOAT_BASE
 jb .integer_table
 add rax,8
.integer_table:
 shl rax,4
 lea rdx,[rel nv_adapters]
 add rdx,rax
 mov rsi,[rdx]
 mov edx,[rdx+8]
 mov rdi,rbx
 call fcg_append
 jmp .done
.statistics:
 NV_APPEND nv_stats_zero_arguments
 cmp qword [rsp],13
 je .statistics_argument
 cmp qword [rsp],15
 jne .statistics_invoke
.statistics_argument:
 mov rdi,rbx
 mov rsi,[rsp+32]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_save_argument
.statistics_invoke:
 NV_APPEND nv_stats_op
 NV_NUMBER [rsp]
 NV_APPEND nv_stats_count
 NV_NUMBER [rsp+16]
 NV_APPEND nv_stats_policy
 NV_NUMBER [rsp+56]
 cmp qword [rsp],15
 jne .statistics_dtype
 NV_APPEND nv_stats_other
.statistics_dtype:
 NV_APPEND nv_stats_dtype
 cmp qword [rsp+8],FCG_TYPE_VECTOR_FLOAT_BASE
 jb .statistics_int
 NV_NUMBER 1
 jmp .statistics_call
.statistics_int:
 NV_NUMBER 0
.statistics_call:
 NV_APPEND nv_stats_call
 cmp qword [rsp],9
 jne .statistics_float_result
 cmp qword [rsp+8],FCG_TYPE_VECTOR_FLOAT_BASE
 jae .statistics_float_result
 NV_APPEND nv_stats_int_result
 jmp .done
.statistics_float_result:
 NV_APPEND nv_stats_float_result
 jmp .done
.literal:
 mov rdi,rbx
 mov rsi,[rsp+32]
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+48],32
.literal_next:
 test r15,r15
 jz .literal_copy
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 NV_APPEND nv_literal_destination
 NV_NUMBER [rsp+48]
 cmp qword [rsp+8],FCG_TYPE_VECTOR_FLOAT_BASE
 jb .literal_integer
 NV_APPEND nv_literal_float
 jmp .literal_saved
.literal_integer:
 NV_APPEND nv_literal_integer
.literal_saved:
 add qword [rsp+48],8
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .literal_next
.literal_copy:
 ; Literal expressions populate a distinct staging span. The canonical copy
 ; initializer publishes the actual native Vector storage after all effects.
 NV_APPEND nv_literal_out
 NV_NUMBER [rsp+48]
 NV_APPEND nv_literal_copy_head
 NV_NUMBER [rsp+16]
 NV_APPEND nv_literal_copy_tail
 NV_NUMBER [rsp+48]
 NV_APPEND nv_literal_done
 xor eax,eax
 jmp .done
.bad:
 mov rdi,rbx
 mov rsi,r12
 mov edx,1
 call fcg_vector_error
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .rodata
nv_Vector: db 'Vector'
nv_filled: db 'filled'
nv_add: db 'add'
nv_scale: db 'scale'
nv_dot: db 'dot'
nv_norm: db 'norm'
nv_normalize: db 'normalize'
nv_sum: db 'sum'
nv_mean: db 'mean'
nv_variance: db 'variance'
nv_stddev: db 'standardDeviation'
nv_quantile: db 'quantile'
nv_median: db 'median'
nv_correlation: db 'correlation'
nv_population: db 'population'
nv_sample: db 'sample'
nv_linear: db 'linearType7'
nv_externs:
 db '%ifndef NEBO_PUBLIC_VECTOR_DECLARED',10
 db '%define NEBO_PUBLIC_VECTOR_DECLARED 1',10
 db 'extern nebo_vector_i64_copy',10
 db 'extern nebo_vector_i64_filled',10
 db 'extern nebo_vector_i64_at',10
 db 'extern nebo_vector_i64_add',10
 db 'extern nebo_vector_i64_scale',10
 db 'extern nebo_vector_i64_dot',10
 db 'extern nebo_vector_f64_copy',10
 db 'extern nebo_vector_f64_filled',10
 db 'extern nebo_vector_f64_at',10
 db 'extern nebo_vector_f64_add',10
 db 'extern nebo_vector_f64_scale',10
 db 'extern nebo_vector_f64_dot',10
 db 'extern nebo_vector_f64_norm',10
 db 'extern nebo_vector_f64_normalize',10
 db 'extern nebo_vector_statistics_call',10
 db '%endif',10
nv_externs_len equ $-nv_externs
nv_save_receiver:
 db '    mov [r12], rax',10
nv_save_receiver_len equ $-nv_save_receiver
nv_save_argument:
 db '    mov [r12 + 8], rax',10
 db '    mov [r12 + 16], rax',10
nv_save_argument_len equ $-nv_save_argument
nv_extent:
 db '    mov r9, '
nv_extent_len equ $-nv_extent
nv_literal_destination:
 db '    lea rdi, [r12 + '
nv_literal_destination_len equ $-nv_literal_destination
nv_literal_integer:
 db ']',10
 db '    mov [rdi], rax',10
nv_literal_integer_len equ $-nv_literal_integer
nv_literal_float:
 db ']',10
 db '    mov [rdi], rax',10
nv_literal_float_len equ $-nv_literal_float
nv_literal_out:
 db '    lea rdi, [r12 + '
nv_literal_out_len equ $-nv_literal_out
nv_literal_copy_head:
 db ']',10
 db '    lea rsi, [r12 + 32]',10
 db '    mov rdx, '
nv_literal_copy_head_len equ $-nv_literal_copy_head
nv_literal_copy_tail:
 db '',10
 db '    call nebo_vector_i64_copy',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + '
nv_literal_copy_tail_len equ $-nv_literal_copy_tail
nv_literal_done:
 db ']',10
 db '    mov r12, [r12 + 24]',10
nv_literal_done_len equ $-nv_literal_done
nv_i64_1:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, r9',10
 db '    mov rdx, [r12 + 8]',10
 db '    call nebo_vector_i64_filled',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_i64_1_len equ $-nv_i64_1
nv_i64_2:
 db '    jmp nebo_runtime_trap_arithmetic_domain',10
nv_i64_2_len equ $-nv_i64_2
nv_i64_3:
 db '    mov rdi, [r12]',10
 db '    mov rsi, r9',10
 db '    mov rdx, [r12 + 8]',10
 db '    call nebo_vector_i64_at',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
nv_i64_3_len equ $-nv_i64_3
nv_i64_4:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12]',10
 db '    mov rdx, [r12 + 8]',10
 db '    mov rcx, r9',10
 db '    call nebo_vector_i64_add',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_i64_4_len equ $-nv_i64_4
nv_i64_5:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12]',10
 db '    mov rdx, [r12 + 8]',10
 db '    mov rcx, r9',10
 db '    call nebo_vector_i64_scale',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_i64_5_len equ $-nv_i64_5
nv_i64_6:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, r9',10
 db '    call nebo_vector_i64_dot',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
nv_i64_6_len equ $-nv_i64_6
nv_i64_7:
 db '    jmp nebo_runtime_trap_arithmetic_domain',10
nv_i64_7_len equ $-nv_i64_7
nv_i64_8:
 db '    jmp nebo_runtime_trap_arithmetic_domain',10
nv_i64_8_len equ $-nv_i64_8
nv_f64_1:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, r9',10
 db '    movq xmm0, [r12 + 16]',10
 db '    call nebo_vector_f64_filled',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_f64_1_len equ $-nv_f64_1
nv_f64_2:
 db '    jmp nebo_runtime_trap_arithmetic_domain',10
nv_f64_2_len equ $-nv_f64_2
nv_f64_3:
 db '    mov rdi, [r12]',10
 db '    mov rsi, r9',10
 db '    mov rdx, [r12 + 8]',10
 db '    call nebo_vector_f64_at',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
nv_f64_3_len equ $-nv_f64_3
nv_f64_4:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12]',10
 db '    mov rdx, [r12 + 8]',10
 db '    mov rcx, r9',10
 db '    call nebo_vector_f64_add',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_f64_4_len equ $-nv_f64_4
nv_f64_5:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12]',10
 db '    movq xmm0, [r12 + 16]',10
 db '    mov rdx, r9',10
 db '    call nebo_vector_f64_scale',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_f64_5_len equ $-nv_f64_5
nv_f64_6:
 db '    mov rdi, [r12]',10
 db '    mov rsi, [r12 + 8]',10
 db '    mov rdx, r9',10
 db '    call nebo_vector_f64_dot',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
nv_f64_6_len equ $-nv_f64_6
nv_f64_7:
 db '    mov rdi, [r12]',10
 db '    mov rsi, r9',10
 db '    call nebo_vector_f64_norm',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
nv_f64_7_len equ $-nv_f64_7
nv_f64_8:
 db '    lea rdi, [r12 + 32]',10
 db '    mov rsi, [r12]',10
 db '    mov rdx, r9',10
 db '    call nebo_vector_f64_normalize',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
 db '    lea rax, [r12 + 32]',10
 db '    mov r12, [r12 + 24]',10
nv_f64_8_len equ $-nv_f64_8
align 8
nv_adapters:
 dq nv_i64_1,nv_i64_1_len
 dq nv_i64_2,nv_i64_2_len
 dq nv_i64_3,nv_i64_3_len
 dq nv_i64_4,nv_i64_4_len
 dq nv_i64_5,nv_i64_5_len
 dq nv_i64_6,nv_i64_6_len
 dq nv_i64_7,nv_i64_7_len
 dq nv_i64_8,nv_i64_8_len
 dq nv_f64_1,nv_f64_1_len
 dq nv_f64_2,nv_f64_2_len
 dq nv_f64_3,nv_f64_3_len
 dq nv_f64_4,nv_f64_4_len
 dq nv_f64_5,nv_f64_5_len
 dq nv_f64_6,nv_f64_6_len
 dq nv_f64_7,nv_f64_7_len
 dq nv_f64_8,nv_f64_8_len
section .text
section .rodata
nv_stats_op:
 db '    mov edi, '
nv_stats_op_len equ $-nv_stats_op
nv_stats_count:
 db '',10
 db '    mov rsi, [r12]',10
 db '    mov rcx, '
nv_stats_count_len equ $-nv_stats_count
nv_stats_policy:
 db '',10
 db '    mov rdx, '
nv_stats_policy_len equ $-nv_stats_policy
nv_stats_other:
 db '',10
 db '    mov rdx, [r12 + 8]'
nv_stats_other_len equ $-nv_stats_other
nv_stats_dtype:
 db '',10
 db '    mov r8d, '
nv_stats_dtype_len equ $-nv_stats_dtype
nv_stats_call:
 db '',10
 db '    lea r9, [r12 + 32]',10
 db '    movq xmm0, [r12 + 16]',10
 db '    call nebo_vector_statistics_call',10
 db '    cmp eax, 4',10
 db '    je nebo_runtime_trap_overflow',10
 db '    test eax, eax',10
 db '    jnz nebo_runtime_trap_arithmetic_domain',10
nv_stats_call_len equ $-nv_stats_call
nv_stats_int_result:
 db '    mov rax, rdx',10
 db '    mov r12, [r12 + 24]',10
nv_stats_int_result_len equ $-nv_stats_int_result
nv_stats_float_result:
 db '    movq rax, xmm0',10
 db '    mov r12, [r12 + 24]',10
nv_stats_float_result_len equ $-nv_stats_float_result
section .text

section .rodata
nv_stats_zero_arguments: db '    mov qword [r12 + 8], 0',10,'    mov qword [r12 + 16], 0',10
nv_stats_zero_arguments_len equ $-nv_stats_zero_arguments
section .text

%include "compiler/codegen/collections/x86_64/shaped_vector_codegen.inc"
