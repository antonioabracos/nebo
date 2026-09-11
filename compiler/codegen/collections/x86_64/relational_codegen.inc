; Part of fcg_assoc_info. Relational handles carry their native owner and
; generation; source Int payloads are independent of stable node identity.
.relational_constructor:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_rel_tree]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jnz .tree_type
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_rel_node]
 mov ecx,4
 call fcg_token_matches_literal
 test eax,eax
 jz .graph_constructor
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_INT
 mov qword [rsp+32],201
 jmp .relational_one_type
.graph_constructor:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel ac_rel_graph]
 mov ecx,5
 call fcg_token_matches_literal
 test eax,eax
 jz .data_constructor
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .invalid
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.graph_type_loop:
 test r15,r15
 jz .graph_constructor_method
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 jmp .graph_type_loop
.graph_constructor_method:
 mov qword [rsp],0
 mov qword [rsp+24],FCG_TYPE_NATIVE_GRAPH_INT
 AC_MATCH ac_rel_directed,8,.graph_directed
 AC_MATCH ac_rel_undirected,10,.graph_undirected
 jmp .invalid
.graph_directed:
 mov qword [rsp+32],250
 jmp .ownership_arity
.graph_undirected:
 mov qword [rsp+32],251
 jmp .ownership_arity
.tree_type:
 mov qword [rsp+24],FCG_TYPE_NATIVE_TREE_INT
 mov qword [rsp+32],200
.relational_one_type:
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
 test qword [r13+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_PREFIX_TYPED_CONSTRUCTOR
 jnz .relational_new
 AC_MATCH ac_new,3,.relational_new
 jmp .invalid
.relational_new:
 mov r15d,1
 jmp .int_arguments
.relational_method:
 cmp rax,FCG_TYPE_NATIVE_COLUMN_INT
 jae .data_methods
 mov [rsp+40],rax
 cmp rax,FCG_TYPE_NATIVE_COMPONENTS
 je .components_methods
 cmp rax,FCG_TYPE_OPTION_NODE_SEQUENCE
 je .optional_sequence_methods
 cmp rax,FCG_TYPE_NATIVE_GRAPH_TRAVERSAL
 je .graph_traversal_methods
 cmp rax,FCG_TYPE_NATIVE_GRAPH_INT
 je .graph_methods
 cmp rax,FCG_TYPE_NATIVE_TREE_INT
 je .tree_methods
 cmp rax,FCG_TYPE_NATIVE_NODE_INT
 je .node_methods
 cmp rax,FCG_TYPE_OPTION_NODE_INT
 je .option_node_methods
 cmp rax,FCG_TYPE_NATIVE_NODE_SEQUENCE
 je .node_sequence_methods
 jmp .no
.tree_methods:
 AC_MATCH ac_rel_root,4,.tree_root
 AC_MATCH ac_rel_addChild,8,.tree_add
 AC_MATCH ac_rel_removeSubtree,13,.tree_remove
 AC_MATCH ac_rel_parent,6,.tree_parent
 AC_MATCH ac_rel_children,8,.tree_children
 AC_MATCH ac_rel_height,6,.tree_height
 AC_MATCH ac_rel_lowestCommonAncestor,20,.tree_lca
 AC_MATCH ac_rel_preorder,8,.tree_preorder
 AC_MATCH ac_rel_postorder,9,.tree_postorder
 jmp .invalid
.tree_root:
 mov qword [rsp+32],202
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_INT
 jmp .ownership_arity
.tree_height:
 mov qword [rsp+32],203
 jmp .seq_int_query
.tree_add:
 mov qword [rsp+32],204
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_INT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 jmp .relational_node_argument
.tree_remove:
 mov qword [rsp+32],205
 mov qword [rsp+24],NEBOC_TYPE_ID_INT
 jmp .relational_one_node
.tree_parent:
 mov qword [rsp+32],206
 mov qword [rsp+24],FCG_TYPE_OPTION_NODE_INT
 jmp .relational_one_node
.tree_children:
 mov qword [rsp+32],207
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
.relational_one_node:
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
.relational_node_argument:
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_NODE_INT
 jne .invalid
 jmp .ok
.tree_lca:
 mov qword [rsp+32],208
 mov qword [rsp+24],FCG_TYPE_OPTION_NODE_INT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_NODE_INT
 jne .invalid
 jmp .relational_node_argument
.tree_preorder:
 mov qword [rsp+32],209
 jmp .tree_order
.tree_postorder:
 mov qword [rsp+32],210
.tree_order:
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 jmp .ownership_arity
.node_methods:
 AC_MATCH ac_rel_value,5,.node_value
 AC_MATCH ac_rel_id,2,.node_id
 AC_MATCH ac_rel_replaceValue,12,.node_replace
 AC_MATCH ac_rel_degree,6,.node_degree
 jmp .invalid
.node_value:
 mov qword [rsp+32],220
 jmp .seq_int_query
.node_id:
 mov qword [rsp+32],221
 jmp .seq_int_query
.node_replace:
 mov qword [rsp+32],222
 jmp .seq_one_int
.node_degree:
 mov qword [rsp+32],223
 jmp .seq_int_query
.option_node_methods:
 AC_MATCH ac_is_some,6,.option_node_some
 AC_MATCH ac_is_none,6,.option_node_none
 AC_MATCH ac_expect,6,.option_node_expect
 jmp .invalid
.option_node_some:
 mov qword [rsp+32],241
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_node_none:
 mov qword [rsp+32],242
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.option_node_expect:
 mov qword [rsp+32],243
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_INT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 jmp .ok
.node_sequence_methods:
 AC_MATCH ac_next,4,.node_sequence_next
 AC_MATCH ac_length,6,.node_sequence_length
 jmp .invalid
.node_sequence_next:
 mov qword [rsp+32],244
 mov qword [rsp+24],FCG_TYPE_OPTION_NODE_INT
 jmp .ownership_arity
.node_sequence_length:
 mov qword [rsp+32],245
 jmp .seq_int_query

.graph_methods:
 AC_MATCH ac_rel_connectedComponents,19,.graph_components
 AC_MATCH ac_rel_hasCycle,8,.graph_cycle
 AC_MATCH ac_rel_topologicalSort,15,.graph_topological
 AC_MATCH ac_rel_shortestPathUnweighted,22,.graph_shortest
 AC_MATCH ac_rel_dijkstra,8,.graph_dijkstra
 AC_MATCH ac_rel_breadthFirst,12,.graph_bfs
 AC_MATCH ac_rel_depthFirst,10,.graph_dfs
 AC_MATCH ac_rel_addNode,7,.graph_add_node
 AC_MATCH ac_rel_addEdge,7,.graph_add_edge
 AC_MATCH ac_rel_removeNode,10,.graph_remove_node
 AC_MATCH ac_rel_removeEdge,10,.graph_remove_edge
 AC_MATCH ac_rel_neighbors,9,.graph_neighbors
 jmp .invalid
.graph_add_node:
 mov qword [rsp+32],252
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_INT
 mov r15d,1
 jmp .int_arguments
.graph_add_edge:
 mov qword [rsp+32],253
 mov qword [rsp+24],FCG_TYPE_NATIVE_EDGE_INT
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],3
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_INT
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_NODE_INT
 jne .invalid
 jmp .relational_node_argument
.graph_remove_node:
 mov qword [rsp+32],254
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 jmp .relational_one_node
.graph_remove_edge:
 mov qword [rsp+32],255
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_EDGE_INT
 jne .invalid
 jmp .ok
.graph_neighbors:
 mov qword [rsp+32],256
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 jmp .relational_one_node

.graph_cycle:
 mov qword [rsp+32],260
 mov qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jmp .ownership_arity
.graph_topological:
 mov qword [rsp+32],261
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 jmp .ownership_arity
.graph_shortest:
 mov qword [rsp+32],262
 jmp .graph_path_arguments
.graph_dijkstra:
 mov qword [rsp+32],263
.graph_path_arguments:
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+16]
 mov edx,1
 call fcg_infer_type
 cmp rax,FCG_TYPE_NATIVE_NODE_INT
 jne .invalid
 jmp .relational_node_argument
.graph_bfs:
 mov qword [rsp+32],270
 jmp .graph_traversal_new
.graph_dfs:
 mov qword [rsp+32],271
.graph_traversal_new:
 mov qword [rsp+24],FCG_TYPE_NATIVE_GRAPH_TRAVERSAL
 jmp .relational_one_node
.graph_traversal_methods:
 AC_MATCH ac_next,4,.graph_traversal_next
 AC_MATCH ac_release,7,.graph_traversal_release
 AC_MATCH ac_rel_stopWhen,8,.graph_traversal_stop
 AC_MATCH ac_rel_path,4,.graph_traversal_path
 jmp .invalid
.graph_traversal_next:
 mov qword [rsp+32],272
 mov qword [rsp+24],FCG_TYPE_OPTION_NODE_INT
 jmp .ownership_arity
.graph_traversal_release:
 mov qword [rsp+32],273
 jmp .seq_void_query
.graph_traversal_path:
 mov qword [rsp+32],277
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 jmp .ownership_arity
.graph_traversal_stop:
 mov qword [rsp+32],276
 mov qword [rsp+24],NEBOC_TYPE_ID_VOID
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_BOOL
 call fcg_typed_callable_symbol
 test rax,rax
 jz .invalid
 jmp .ok

.graph_components:
 mov qword [rsp+32],264
 mov qword [rsp+24],FCG_TYPE_NATIVE_COMPONENTS
 jmp .ownership_arity
.components_methods:
 AC_MATCH ac_length,6,.node_sequence_length
 AC_MATCH ac_next,4,.components_next
 jmp .invalid
.components_next:
 mov qword [rsp+32],280
 mov qword [rsp+24],FCG_TYPE_OPTION_NODE_SEQUENCE
 jmp .ownership_arity
.optional_sequence_methods:
 AC_MATCH ac_is_some,6,.option_node_some
 AC_MATCH ac_is_none,6,.option_node_none
 AC_MATCH ac_expect,6,.optional_sequence_expect
 jmp .invalid
.optional_sequence_expect:
 mov qword [rsp+32],243
 mov qword [rsp+24],FCG_TYPE_NATIVE_NODE_SEQUENCE
 cmp qword [r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .invalid
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov edx,1
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .invalid
 jmp .ok
