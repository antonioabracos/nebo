; Nebo Assembly — MF021 scopes, symbols and deterministic name resolution
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/scope/scope_table.inc"
%include "compiler/semantic/symbol/symbol_table.inc"
%include "compiler/semantic/symbol/name_resolver.inc"

extern neboc_ast_store_require_clean
extern neboc_scope_table_reset
extern neboc_scope_table_append
extern neboc_scope_table_freeze
extern neboc_symbol_table_reset
extern neboc_symbol_table_append
extern neboc_symbol_table_freeze

section .text

; name_resolve(request*)
; Functions are collected in a top-level function namespace before values are
; visited. Receivers, parameters and bindings inhabit lexical value scopes.
NEBOC_ABI_FUNCTION neboc_name_resolve
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .resolve_invalid
 mov r13,[r12+NEBOC_NAME_REQUEST_AST_STORE_OFFSET]
 mov r14,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 mov r15,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 test r13,r13
 jz .resolve_invalid
 test r14,r14
 jz .resolve_invalid
 test r15,r15
 jz .resolve_invalid
 cmp qword [r13+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 jne .resolve_invalid
 mov rbx,[r13+NEBOC_AST_STORE_COUNT_OFFSET]
 test rbx,rbx
 jz .resolve_invalid
 cmp rbx,[r12+NEBOC_NAME_REQUEST_NODE_CAPACITY_OFFSET]
 ja .resolve_limit
 cmp qword [r12+NEBOC_NAME_REQUEST_TOKENS_OFFSET],0
 je .resolve_invalid
 cmp qword [r12+NEBOC_NAME_REQUEST_SOURCE_OFFSET],0
 je .resolve_invalid
 cmp qword [r12+NEBOC_NAME_REQUEST_NODE_SYMBOLS_OFFSET],0
 je .resolve_invalid
 cmp qword [r12+NEBOC_NAME_REQUEST_NODE_SCOPES_OFFSET],0
 je .resolve_invalid

 mov rdi,r13
 call neboc_ast_store_require_clean
 test eax,eax
 jnz .resolve_done
 mov rdi,r14
 call neboc_scope_table_reset
 test eax,eax
 jnz .resolve_done
 mov rdi,r15
 call neboc_symbol_table_reset
 test eax,eax
 jnz .resolve_done

 mov qword [r12+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_NAME_REQUEST_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_NAME_REQUEST_ROOT_SCOPE_ID_OFFSET],0
 mov qword [r12+NEBOC_NAME_REQUEST_HASH_OFFSET],0
 mov rdi,[r12+NEBOC_NAME_REQUEST_NODE_SYMBOLS_OFFSET]
 xor eax,eax
 mov rcx,rbx
 rep stosq
 mov rdi,[r12+NEBOC_NAME_REQUEST_NODE_SCOPES_OFFSET]
 mov rcx,rbx
 rep stosq

 ; Root must be a Program node.
 mov rsi,[r13+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 mov rdi,r12
 call nr_node_ptr
 test rax,rax
 jz .resolve_structure
 mov [rsp],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .resolve_structure

 ; Pass 1: collect all top-level functions independent of declaration order.
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
.collect_loop:
 test r15,r15
 jz .collect_done
 test r14,r14
 jz .resolve_structure
 mov rdi,r12
 mov rsi,r14
 call nr_node_ptr
 test rax,rax
 jz .resolve_structure
 mov [rsp+8],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .collect_next
 mov rdi,r12
 mov rsi,r14
 call nr_collect_function
 test eax,eax
 jnz .resolve_done
.collect_next:
 mov rax,[rsp+8]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r15
 jmp .collect_loop
.collect_done:
 test r14,r14
 jnz .resolve_structure

 ; Pass 2: create value scopes and resolve declarations/uses.
 mov rax,[rsp]
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
.visit_top_loop:
 test r15,r15
 jz .visit_top_done
 test r14,r14
 jz .resolve_structure
 mov rdi,r12
 mov rsi,r14
 xor edx,edx
 call nr_visit_node
 test eax,eax
 jnz .resolve_done
 mov rdi,r12
 mov rsi,r14
 call nr_node_ptr
 test rax,rax
 jz .resolve_structure
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r15
 jmp .visit_top_loop
.visit_top_done:
 test r14,r14
 jnz .resolve_structure

 mov rdi,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 call neboc_scope_table_freeze
 test eax,eax
 jnz .resolve_done
 mov rdi,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 call neboc_symbol_table_freeze
 test eax,eax
 jnz .resolve_done
 mov rdi,r12
 call nr_compute_hash
 test eax,eax
 jnz .resolve_done
 xor eax,eax
 jmp .resolve_done
.resolve_structure:
 mov rdi,r12
 mov esi,NEBOC_DIAG_INTERNAL_ERROR
 mov rdx,[r13+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 xor ecx,ecx
 call nr_fail
 jmp .resolve_done
.resolve_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .resolve_done
.resolve_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.resolve_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_node_ptr(request*, node_id) -> RAX node pointer or 0
nr_node_ptr:
 test rdi,rdi
 jz .node_bad
 test rsi,rsi
 jz .node_bad
 mov rax,[rdi+NEBOC_NAME_REQUEST_AST_STORE_OFFSET]
 test rax,rax
 jz .node_bad
 cmp rsi,[rax+NEBOC_AST_STORE_COUNT_OFFSET]
 ja .node_bad
 mov rax,[rax+NEBOC_AST_STORE_DATA_OFFSET]
 test rax,rax
 jz .node_bad
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 add rax,rsi
 ret
.node_bad:
 xor eax,eax
 ret

; nr_token_ptr(request*, token_index) -> RAX token pointer or 0
nr_token_ptr:
 test rdi,rdi
 jz .token_bad
 cmp rsi,[rdi+NEBOC_NAME_REQUEST_TOKEN_COUNT_OFFSET]
 jae .token_bad
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_NAME_REQUEST_TOKENS_OFFSET]
 ret
.token_bad:
 xor eax,eax
 ret

; nr_set_node_scope(request*, node_id, scope_id)
nr_set_node_scope:
 test rsi,rsi
 jz .set_scope_bad
 cmp rsi,[rdi+NEBOC_NAME_REQUEST_NODE_CAPACITY_OFFSET]
 ja .set_scope_bad
 mov rax,[rdi+NEBOC_NAME_REQUEST_NODE_SCOPES_OFFSET]
 dec rsi
 mov [rax+rsi*8],rdx
 xor eax,eax
 ret
.set_scope_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; nr_set_node_symbol(request*, node_id, symbol_id)
nr_set_node_symbol:
 test rsi,rsi
 jz .set_symbol_bad
 cmp rsi,[rdi+NEBOC_NAME_REQUEST_NODE_CAPACITY_OFFSET]
 ja .set_symbol_bad
 mov rax,[rdi+NEBOC_NAME_REQUEST_NODE_SYMBOLS_OFFSET]
 dec rsi
 mov [rax+rsi*8],rdx
 xor eax,eax
 ret
.set_symbol_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; nr_fail(request*, diagnostic_code, node_id, token_index)
nr_fail:
 mov [rdi+NEBOC_NAME_REQUEST_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_NAME_REQUEST_ERROR_NODE_ID_OFFSET],rdx
 mov [rdi+NEBOC_NAME_REQUEST_ERROR_TOKEN_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; nr_names_equal(request*, token_a, token_b) -> EAX 1/0
nr_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call nr_token_ptr
 test rax,rax
 jz .names_no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call nr_token_ptr
 test rax,rax
 jz .names_no
 mov r15,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp r8,r9
 ja .names_no
 mov r10,[r15+NEBOC_TOKEN_START_OFFSET]
 mov r11,[r15+NEBOC_TOKEN_END_OFFSET]
 cmp r10,r11
 ja .names_no
 cmp r9,[r12+NEBOC_NAME_REQUEST_SOURCE_LENGTH_OFFSET]
 ja .names_no
 cmp r11,[r12+NEBOC_NAME_REQUEST_SOURCE_LENGTH_OFFSET]
 ja .names_no
 sub r9,r8
 sub r11,r10
 cmp r9,r11
 jne .names_no
 mov rcx,r9
 mov rsi,[r12+NEBOC_NAME_REQUEST_SOURCE_OFFSET]
 add rsi,r8
 mov rdi,[r12+NEBOC_NAME_REQUEST_SOURCE_OFFSET]
 add rdi,r10
 repe cmpsb
 sete al
 movzx eax,al
 jmp .names_done
.names_no:
 xor eax,eax
.names_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_lookup_value(request*, start_scope_id, name_token, out_symbol_id*)
; EAX=0 found, EAX=1 not found.
nr_lookup_value:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 test r15,r15
 jz .lookup_value_missing
 mov qword [r15],0
.lookup_value_scope:
 test r13,r13
 jz .lookup_value_missing
 mov rbx,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov rax,[rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp],0
.lookup_value_symbol_loop:
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jae .lookup_value_parent
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,[rbx+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_FUNCTION
 je .lookup_value_symbol_next
 cmp [rax+NEBOC_SYMBOL_ENTRY_SCOPE_ID_OFFSET],r13
 jne .lookup_value_symbol_next
 mov rdx,[rax+NEBOC_SYMBOL_ENTRY_NAME_TOKEN_OFFSET]
 mov rdi,r12
 mov rsi,r14
 call nr_names_equal
 test eax,eax
 jz .lookup_value_symbol_next
 mov rax,[rsp+16]
 mov rax,[rax+NEBOC_SYMBOL_ENTRY_ID_OFFSET]
 mov [r15],rax
 xor eax,eax
 jmp .lookup_value_done
.lookup_value_symbol_next:
 inc qword [rsp]
 jmp .lookup_value_symbol_loop
.lookup_value_parent:
 mov rax,r13
 dec rax
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 mov rbx,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 add rax,[rbx+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 mov r13,[rax+NEBOC_SCOPE_ENTRY_PARENT_ID_OFFSET]
 jmp .lookup_value_scope
.lookup_value_missing:
 mov eax,1
.lookup_value_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_lookup_function(request*, name_token, out_symbol_id*)
; EAX=0 found, EAX=1 not found. First source-order candidate is stable;
; overload selection by receiver/type is deferred to MF023.
nr_lookup_function:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r14,r14
 jz .lookup_function_missing
 mov qword [r14],0
 mov rbx,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov rax,[rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp],0
.lookup_function_loop:
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jae .lookup_function_missing
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,[rbx+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_FUNCTION
 jne .lookup_function_next
 mov rdx,[rax+NEBOC_SYMBOL_ENTRY_NAME_TOKEN_OFFSET]
 mov rdi,r12
 mov rsi,r13
 call nr_names_equal
 test eax,eax
 jz .lookup_function_next
 mov rax,[rsp+16]
 mov rax,[rax+NEBOC_SYMBOL_ENTRY_ID_OFFSET]
 mov [r14],rax
 xor eax,eax
 jmp .lookup_function_done
.lookup_function_next:
 inc qword [rsp]
 jmp .lookup_function_loop
.lookup_function_missing:
 mov eax,1
.lookup_function_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_check_declaration(request*, scope_id, name_token)
; EAX=0 allowed, duplicate/shadow diagnostic code otherwise.
nr_check_declaration:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,r13
.check_scope_loop:
 test r15,r15
 jz .check_allowed
 mov rbx,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov rax,[rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 mov [rsp+8],rax
 mov qword [rsp],0
.check_symbol_loop:
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jae .check_parent
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,[rbx+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov [rsp+16],rax
 cmp qword [rax+NEBOC_SYMBOL_ENTRY_KIND_OFFSET],NEBOC_SYMBOL_KIND_FUNCTION
 je .check_symbol_next
 cmp [rax+NEBOC_SYMBOL_ENTRY_SCOPE_ID_OFFSET],r15
 jne .check_symbol_next
 mov rdx,[rax+NEBOC_SYMBOL_ENTRY_NAME_TOKEN_OFFSET]
 mov rdi,r12
 mov rsi,r14
 call nr_names_equal
 test eax,eax
 jz .check_symbol_next
 cmp r15,r13
 jne .check_shadow
 mov eax,NEBOC_DIAG_NAME_DUPLICATE
 jmp .check_done
.check_shadow:
 mov eax,NEBOC_DIAG_NAME_SHADOW
 jmp .check_done
.check_symbol_next:
 inc qword [rsp]
 jmp .check_symbol_loop
.check_parent:
 mov rax,r15
 dec rax
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 mov rbx,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 add rax,[rbx+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 mov r15,[rax+NEBOC_SCOPE_ENTRY_PARENT_ID_OFFSET]
 jmp .check_scope_loop
.check_allowed:
 xor eax,eax
.check_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_declare_value(request*, node_id, scope_id, token_index, symbol_kind)
nr_declare_value:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r14,r14
 jz .declare_invalid
 mov rdi,r12
 mov rsi,r15
 call nr_token_ptr
 test rax,rax
 jz .declare_invalid
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .declare_reserved
 mov rdi,r12
 mov rsi,r14
 mov rdx,r15
 call nr_check_declaration
 test eax,eax
 jnz .declare_conflict
 mov rdi,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov rsi,r15
 mov rdx,rbx
 mov rcx,r13
 mov r8,r14
 lea r9,[rsp]
 call neboc_symbol_table_append
 test eax,eax
 jnz .declare_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp]
 call nr_set_node_symbol
 test eax,eax
 jnz .declare_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call nr_set_node_scope
 test eax,eax
 jnz .declare_done
 mov rax,r14
 dec rax
 imul rax,NEBOC_SCOPE_ENTRY_SIZE
 mov rdx,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 add rax,[rdx+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 cmp qword [rax+NEBOC_SCOPE_ENTRY_FIRST_SYMBOL_ID_OFFSET],0
 jne .declare_increment
 mov rdx,[rsp]
 mov [rax+NEBOC_SCOPE_ENTRY_FIRST_SYMBOL_ID_OFFSET],rdx
.declare_increment:
 inc qword [rax+NEBOC_SCOPE_ENTRY_SYMBOL_COUNT_OFFSET]
 xor eax,eax
 jmp .declare_done
.declare_reserved:
 mov rdi,r12
 mov esi,NEBOC_DIAG_NAME_RESERVED
 mov rdx,r13
 mov rcx,r15
 call nr_fail
 jmp .declare_done
.declare_conflict:
 mov rsi,rax
 mov rdi,r12
 mov rdx,r13
 mov rcx,r15
 call nr_fail
 jmp .declare_done
.declare_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.declare_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_collect_function(request*, function_node_id)
nr_collect_function:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 call nr_node_ptr
 test rax,rax
 jz .collect_function_invalid
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r14
 call nr_token_ptr
 test rax,rax
 jz .collect_function_invalid
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .collect_function_reserved
 mov rdi,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov rsi,r14
 mov edx,NEBOC_SYMBOL_KIND_FUNCTION
 mov rcx,r13
 xor r8d,r8d
 lea r9,[rsp]
 call neboc_symbol_table_append
 test eax,eax
 jnz .collect_function_done
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp]
 call nr_set_node_symbol
 jmp .collect_function_done
.collect_function_reserved:
 mov rdi,r12
 mov esi,NEBOC_DIAG_NAME_RESERVED
 mov rdx,r13
 mov rcx,r14
 call nr_fail
 jmp .collect_function_done
.collect_function_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.collect_function_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_visit_child_chain(request*, first_child_id, child_count, scope_id)
nr_visit_child_chain:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
.visit_chain_loop:
 test r14,r14
 jz .visit_chain_end
 test r13,r13
 jz .visit_chain_invalid
 mov rdi,r12
 mov rsi,r13
 mov rdx,r15
 call nr_visit_node
 test eax,eax
 jnz .visit_chain_done
 mov rdi,r12
 mov rsi,r13
 call nr_node_ptr
 test rax,rax
 jz .visit_chain_invalid
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r14
 jmp .visit_chain_loop
.visit_chain_end:
 test r13,r13
 jnz .visit_chain_invalid
 xor eax,eax
 jmp .visit_chain_done
.visit_chain_invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.visit_chain_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_visit_node(request*, node_id, current_scope_id)
nr_visit_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call nr_node_ptr
 test rax,rax
 jz .visit_invalid
 mov r15,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call nr_set_node_scope
 test eax,eax
 jnz .visit_done
 mov rbx,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rbx,NEBOC_AST_START_DECL
 je .visit_start
 cmp rbx,NEBOC_AST_FUNCTION_DECL
 je .visit_function
 cmp rbx,NEBOC_AST_BINDING_STMT
 je .visit_binding
 cmp rbx,NEBOC_AST_IDENTIFIER_EXPR
 je .visit_identifier
 cmp rbx,NEBOC_AST_CALL_EXPR
 je .visit_call
 cmp rbx,NEBOC_AST_IF_STMT
 je .visit_if
 cmp rbx,NEBOC_AST_RECEIVER
 je .visit_no_children
 cmp rbx,NEBOC_AST_PARAMETER
 je .visit_no_children
 jmp .visit_generic

.visit_start:
 mov rdi,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 xor esi,esi
 mov edx,NEBOC_SCOPE_KIND_START
 mov rcx,r13
 lea r8,[rsp]
 call neboc_scope_table_append
 test eax,eax
 jnz .visit_done
 mov rbx,[rsp]
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call nr_set_node_scope
 test eax,eax
 jnz .visit_done
 cmp qword [r12+NEBOC_NAME_REQUEST_ROOT_SCOPE_ID_OFFSET],0
 jne .visit_start_children
 mov [r12+NEBOC_NAME_REQUEST_ROOT_SCOPE_ID_OFFSET],rbx
.visit_start_children:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rcx,rbx
 call nr_visit_child_chain
 jmp .visit_done

.visit_function:
 mov rdi,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 xor esi,esi
 mov edx,NEBOC_SCOPE_KIND_FUNCTION
 mov rcx,r13
 lea r8,[rsp]
 call neboc_scope_table_append
 test eax,eax
 jnz .visit_done
 mov rbx,[rsp]
 mov rdi,r12
 mov rsi,r13
 mov rdx,rbx
 call nr_set_node_scope
 test eax,eax
 jnz .visit_done
 mov r8,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r9,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
.function_child_loop:
 test r9,r9
 jz .function_child_end
 test r8,r8
 jz .visit_invalid
 mov [rsp+8],r8
 mov [rsp+16],r9
 mov rdi,r12
 mov rsi,r8
 call nr_node_ptr
 test rax,rax
 jz .visit_invalid
 mov r10,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp r10,NEBOC_AST_RECEIVER
 je .function_receiver
 cmp r10,NEBOC_AST_PARAMETER
 je .function_parameter
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,rbx
 call nr_visit_node
 jmp .function_after_child
.function_receiver:
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,rbx
 mov r8d,NEBOC_SYMBOL_KIND_RECEIVER
 call nr_declare_value
 jmp .function_after_child
.function_parameter:
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,rbx
 mov r8d,NEBOC_SYMBOL_KIND_PARAMETER
 call nr_declare_value
.function_after_child:
 test eax,eax
 jnz .visit_done
 mov rdi,r12
 mov rsi,[rsp+8]
 call nr_node_ptr
 mov r8,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r9,[rsp+16]
 dec r9
 jmp .function_child_loop
.function_child_end:
 test r8,r8
 jnz .visit_invalid
 xor eax,eax
 jmp .visit_done

.visit_binding:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rcx,r14
 call nr_visit_child_chain
 test eax,eax
 jnz .visit_done
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 mov r8d,NEBOC_SYMBOL_KIND_BINDING
 call nr_declare_value
 jmp .visit_done

.visit_identifier:
 lea rcx,[rsp]
 mov rdi,r12
 mov rsi,r14
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call nr_lookup_value
 test eax,eax
 jz .identifier_found
 mov rdi,r12
 mov esi,NEBOC_DIAG_NAME_UNDEFINED
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call nr_fail
 jmp .visit_done
.identifier_found:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp]
 call nr_set_node_symbol
 jmp .visit_done

.visit_call:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rcx,r14
 call nr_visit_child_chain
 test eax,eax
 jnz .visit_done
 lea rdx,[rsp]
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call nr_lookup_function
 test eax,eax
 jz .call_found
 mov rdi,r12
 mov esi,NEBOC_DIAG_NAME_UNDEFINED
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call nr_fail
 jmp .visit_done
.call_found:
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rsp]
 call nr_set_node_symbol
 jmp .visit_done

.visit_if:
 mov r8,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r9,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp r9,2
 jb .visit_invalid
 ; condition in current scope
 mov [rsp+8],r8
 mov [rsp+16],r9
 mov rdi,r12
 mov rsi,r8
 mov rdx,r14
 call nr_visit_node
 test eax,eax
 jnz .visit_done
 mov rdi,r12
 mov rsi,[rsp+8]
 call nr_node_ptr
 mov r8,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r8,r8
 jz .visit_invalid
 ; then block owns a child scope
 mov [rsp+8],r8
 mov rdi,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 mov rsi,r14
 mov edx,NEBOC_SCOPE_KIND_IF_BLOCK
 mov rcx,r8
 lea r8,[rsp]
 call neboc_scope_table_append
 test eax,eax
 jnz .visit_done
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp]
 call nr_visit_node
 test eax,eax
 jnz .visit_done
 mov rdi,r12
 mov rsi,[rsp+8]
 call nr_node_ptr
 mov r8,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r9,[rsp+16]
 sub r9,2
 jz .if_finished
 test r8,r8
 jz .visit_invalid
 mov [rsp+8],r8
 mov rdi,r12
 mov rsi,r8
 call nr_node_ptr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .if_else_if
 mov rdi,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 mov rsi,r14
 mov edx,NEBOC_SCOPE_KIND_ELSE_BLOCK
 mov rcx,[rsp+8]
 lea r8,[rsp]
 call neboc_scope_table_append
 test eax,eax
 jnz .visit_done
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp]
 call nr_visit_node
 jmp .visit_done
.if_else_if:
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,r14
 call nr_visit_node
 jmp .visit_done
.if_finished:
 test r8,r8
 jnz .visit_invalid
 xor eax,eax
 jmp .visit_done

.visit_generic:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rcx,r14
 call nr_visit_child_chain
 jmp .visit_done
.visit_no_children:
 xor eax,eax
 jmp .visit_done
.visit_invalid:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.visit_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_compute_hash(request*) — deterministic FNV-1a over scope/symbol entries
; and node side tables. Pointers in descriptors are deliberately excluded.
nr_compute_hash:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov eax,NEBOC_NAME_HASH_FNV1A32_OFFSET_BASIS
 mov rbx,[r12+NEBOC_NAME_REQUEST_SCOPE_TABLE_OFFSET]
 mov r13,[rbx+NEBOC_SCOPE_TABLE_DATA_OFFSET]
 mov r14,[rbx+NEBOC_SCOPE_TABLE_COUNT_OFFSET]
 imul r14,NEBOC_SCOPE_ENTRY_SIZE
 call nr_hash_bytes
 mov rbx,[r12+NEBOC_NAME_REQUEST_SYMBOL_TABLE_OFFSET]
 mov r13,[rbx+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov r14,[rbx+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 imul r14,NEBOC_SYMBOL_ENTRY_SIZE
 call nr_hash_bytes
 mov r13,[r12+NEBOC_NAME_REQUEST_NODE_SYMBOLS_OFFSET]
 mov r14,[r12+NEBOC_NAME_REQUEST_AST_STORE_OFFSET]
 mov r14,[r14+NEBOC_AST_STORE_COUNT_OFFSET]
 imul r14,8
 call nr_hash_bytes
 mov r13,[r12+NEBOC_NAME_REQUEST_NODE_SCOPES_OFFSET]
 mov r14,[r12+NEBOC_NAME_REQUEST_AST_STORE_OFFSET]
 mov r14,[r14+NEBOC_AST_STORE_COUNT_OFFSET]
 imul r14,8
 call nr_hash_bytes
 mov [r12+NEBOC_NAME_REQUEST_HASH_OFFSET],rax
 xor eax,eax
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; nr_hash_bytes: EAX current hash, R13 data, R14 byte count -> EAX hash
nr_hash_bytes:
 xor r15d,r15d
.hash_byte_loop:
 cmp r15,r14
 jae .hash_byte_done
 movzx ebx,byte [r13+r15]
 xor eax,ebx
 imul eax,eax,NEBOC_NAME_HASH_FNV1A32_PRIME
 inc r15
 jmp .hash_byte_loop
.hash_byte_done:
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
