; Part of fcg_assoc_info: the same typed call plan and generic return pipeline
; cover sequential owners. Native List/Stack/ring owners retain all storage.
.sequential_constructor:
%macro SEQ_CONSTRUCTOR 4
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel %1]
 mov ecx,%2
 call fcg_token_matches_literal
 test eax,eax
 jz %%next
 mov qword [rsp+24],%3
 mov qword [rsp+32],%4
 jmp .sequential_type
%%next:
%endmacro
 SEQ_CONSTRUCTOR ac_list,4,FCG_TYPE_NATIVE_LIST_INT,100
 SEQ_CONSTRUCTOR ac_stack,5,FCG_TYPE_NATIVE_STACK_INT,101
 SEQ_CONSTRUCTOR ac_queue,5,FCG_TYPE_NATIVE_QUEUE_INT,102
 SEQ_CONSTRUCTOR ac_deque,5,FCG_TYPE_NATIVE_DEQUE_INT,103
 jmp .relational_constructor
%undef SEQ_CONSTRUCTOR
.sequential_type:
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
 AC_MATCH ac_new,3,.ownership_arity
 cmp qword [rsp+24],FCG_TYPE_NATIVE_LIST_INT
 jne .invalid
 AC_MATCH ac_with_capacity,12,.seq_capacity_constructor
 AC_MATCH ac_from,4,.seq_from
 jmp .invalid
.seq_from:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ARRAY_LITERAL
 jne .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],16
 ja .capacity_invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.seq_element_type:
 test r15,r15
 jz .seq_from_typed
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
 jmp .seq_element_type
.seq_from_typed:
 mov qword [rsp+32],105
 jmp .ok
.seq_capacity_constructor:
 mov qword [rsp+32],104
 mov r15d,1
 jmp .int_arguments
.sequential:
 mov [rsp+40],rax
 AC_MATCH ac_iterator,8,.seq_iterator
 AC_MATCH ac_iterator_mutable,15,.seq_iterator_mutable
 AC_MATCH ac_length,6,.seq_length
 AC_MATCH ac_clear,5,.seq_clear
 cmp qword [rsp+40],FCG_TYPE_NATIVE_QUEUE_INT
 je .seq_queue
 cmp qword [rsp+40],FCG_TYPE_NATIVE_DEQUE_INT
 je .seq_deque
 AC_MATCH ac_push,4,.seq_push
 AC_MATCH ac_pop,3,.seq_pop
 cmp qword [rsp+40],FCG_TYPE_NATIVE_STACK_INT
 je .seq_stack
 AC_MATCH ac_capacity,8,.seq_capacity
 AC_MATCH ac_reserve,7,.seq_reserve
 AC_MATCH ac_at,2,.seq_at
 AC_MATCH ac_get,3,.seq_get
 AC_MATCH ac_insert,6,.seq_insert
 AC_MATCH ac_remove,6,.seq_remove
 AC_MATCH ac_swap_remove,10,.seq_swap_remove
 AC_MATCH ac_set_contains,8,.seq_contains
 AC_MATCH ac_find,4,.seq_find
 AC_MATCH ac_map,3,.seq_map
 AC_MATCH ac_filter,6,.seq_filter
 AC_MATCH ac_retain,6,.seq_retain
 AC_MATCH ac_sort,4,.seq_sort
 AC_MATCH ac_deduplicate,11,.seq_deduplicate
 jmp .invalid
.seq_stack:
 AC_MATCH ac_peek,4,.seq_peek
 jmp .invalid
.seq_queue:
 AC_MATCH ac_enqueue,7,.seq_enqueue
 AC_MATCH ac_dequeue,7,.seq_dequeue
 AC_MATCH ac_peek,4,.seq_queue_peek
 jmp .invalid
.seq_deque:
 AC_MATCH ac_push_front,9,.seq_push_front
 AC_MATCH ac_push_back,8,.seq_push_back
 AC_MATCH ac_pop_front,8,.seq_pop_front
 AC_MATCH ac_pop_back,7,.seq_pop_back
 jmp .invalid
.seq_length:
 mov qword [rsp+32],110
 cmp qword [rsp+40],FCG_TYPE_NATIVE_QUEUE_INT
 jb .seq_int_query
 mov qword [rsp+32],130
 jmp .seq_int_query
.seq_capacity:
 mov qword [rsp+32],111
 jmp .seq_int_query
.seq_clear:
 mov qword [rsp+32],121
 cmp qword [rsp+40],FCG_TYPE_NATIVE_QUEUE_INT
 jb .seq_void_query
 mov qword [rsp+32],131
.seq_void_query:
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .ownership_arity
.seq_int_query:
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .ownership_arity
.seq_reserve:
 mov qword [rsp+32],112
 jmp .seq_one_void
.seq_push:
 mov qword [rsp+32],113
 jmp .seq_one_void
.seq_pop:
 mov qword [rsp+32],114
 jmp .seq_option_query
.seq_peek:
 mov qword [rsp+32],115
 jmp .seq_int_query
.seq_at:
 mov qword [rsp+32],116
 jmp .seq_one_int
.seq_get:
 mov qword [rsp+32],117
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 mov r15d,1
 jmp .int_arguments
.seq_insert:
 mov qword [rsp+32],118
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 mov r15d,2
 jmp .int_arguments
.seq_remove:
 mov qword [rsp+32],119
 jmp .seq_one_int
.seq_swap_remove:
 mov qword [rsp+32],120
 jmp .seq_one_int
.seq_enqueue:
 mov qword [rsp+32],122
 jmp .seq_one_void
.seq_dequeue:
 mov qword [rsp+32],123
 jmp .seq_option_query
.seq_queue_peek:
 mov qword [rsp+32],124
 jmp .seq_int_query
.seq_push_front:
 mov qword [rsp+32],125
 jmp .seq_one_void
.seq_push_back:
 mov qword [rsp+32],126
 jmp .seq_one_void
.seq_pop_front:
 mov qword [rsp+32],127
 jmp .seq_int_query
.seq_pop_back:
 mov qword [rsp+32],128
 jmp .seq_int_query
.seq_one_void:
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 mov r15d,1
 jmp .int_arguments
.seq_one_int:
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 mov r15d,1
 jmp .int_arguments
.seq_contains:
 mov qword [rsp+32],132
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 mov r15d,1
 jmp .int_arguments
.seq_find:
 mov qword [rsp+32],134
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .seq_callback
.seq_map:
 mov qword [rsp+32],135
 mov qword [rsp+24],FCG_TYPE_NATIVE_LIST_INT
 jmp .seq_callback
.seq_filter:
 mov qword [rsp+32],136
 mov qword [rsp+24],FCG_TYPE_NATIVE_LIST_INT
 jmp .seq_callback
.seq_retain:
 mov qword [rsp+32],137
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .seq_callback
.seq_sort:
 mov qword [rsp+32],138
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
.seq_callback:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov rdx,[rsp+32]
 call fcg_seq_callback_symbol
 test rax,rax
 jz .invalid
 jmp .ok
.seq_deduplicate:
 mov qword [rsp+32],139
 jmp .seq_void_query
.seq_option_query:
 mov qword [rsp+24],FCG_TYPE_OPTION_INT
 jmp .ownership_arity
.seq_iterator:
 mov qword [rsp+32],140
 jmp .seq_iterator_kind
.seq_iterator_mutable:
 mov qword [rsp+32],141
.seq_iterator_kind:
 cmp qword [rsp+40],FCG_TYPE_NATIVE_QUEUE_INT
 jb .seq_iterator_typed
 add qword [rsp+32],2
.seq_iterator_typed:
 mov qword [rsp+24],FCG_TYPE_NATIVE_ITERATOR_INT
 jmp .ownership_arity
.sequence_iterator:
 mov [rsp+40],rax
 AC_MATCH ac_next,4,.seq_iterator_next
 AC_MATCH ac_take,4,.seq_iterator_take
 AC_MATCH ac_skip,4,.seq_iterator_skip
 AC_MATCH ac_release,7,.seq_iterator_release
 AC_MATCH ac_collect,7,.seq_iterator_collect
 AC_MATCH ac_enumerate,9,.seq_iterator_enumerate
 jmp .invalid
.seq_iterator_next:
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 call fcg_seq_is_enumerated
 test eax,eax
 jnz .seq_iterator_next_pair
 mov qword [rsp+32],144
 jmp .seq_option_query
.seq_iterator_next_pair:
 mov qword [rsp+32],150
 mov qword [rsp+24],FCG_TYPE_OPTION_INT_PAIR
 jmp .ownership_arity
.seq_iterator_take:
 mov qword [rsp+32],146
 jmp .seq_one_void
.seq_iterator_skip:
 mov qword [rsp+32],147
 jmp .seq_one_void
.seq_iterator_release:
 mov qword [rsp+32],149
 jmp .seq_void_query
.seq_iterator_collect:
 mov rdi,rbx
 mov rsi,[rsp]
 mov rdx,r12
 call fcg_seq_is_enumerated
 test eax,eax
 jnz .invalid ; enumerated Pair elements cannot be silently collected as Int
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_GENERIC_METHOD
 jz .invalid
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .invalid
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_APPLICATION
 jz .invalid
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 lea rdx,[rel ac_list]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .invalid
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov qword [rsp+32],148
 mov qword [rsp+24],FCG_TYPE_NATIVE_LIST_INT
 jmp .ok
.seq_iterator_enumerate:
 ; The element-type transition must dominate subsequent uses. A named
 ; iterator may transition only in its declaration's lexical block, keeping
 ; conditional branches from producing incompatible next() result types.
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_seq_iterator_factory
 test rax,rax
 jz .invalid
 shr rdx,16
 and edx,65535
 cmp rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 jne .invalid
 mov qword [rsp+32],145
 jmp .seq_void_query
