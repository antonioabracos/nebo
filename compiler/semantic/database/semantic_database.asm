; Nebo Assembly — MF025 Validated AST completeness database
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/database/control_flow_table.inc"
%include "compiler/semantic/database/constant_value_table.inc"
%include "compiler/semantic/database/semantic_database.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/intrinsic/intrinsic_table.inc"
%include "compiler/semantic/console-routing/console_routing_table.inc"
%include "compiler/dependency/pending/pending_table.inc"
%include "compiler/dependency/graph/dependency_graph.inc"

section .text

; semantic_database_validate(database*)
; Audits caller-owned NodeId-indexed semantic side tables. Route and Pending
; dependency entries are consumed as already-produced IDs; MF025 does not build
; those later-front domains.
NEBOC_ABI_FUNCTION neboc_semantic_database_validate
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .bad_argument_no_request
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_EMPTY
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_NONE
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_HASH_OFFSET],0
 mov r13,[r12+NEBOC_SEMANTIC_DATABASE_AST_STORE_OFFSET]
 test r13,r13
 jz .bad_database
 cmp qword [r13+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 jne .ast_not_validated
 mov r14,[r13+NEBOC_AST_STORE_COUNT_OFFSET]
 test r14,r14
 jz .bad_database
 cmp r14,[r12+NEBOC_SEMANTIC_DATABASE_NODE_COUNT_OFFSET]
 jne .bad_count
 mov r15,[r12+NEBOC_SEMANTIC_DATABASE_REQUIRED_MASKS_OFFSET]
 test r15,r15
 jz .bad_database
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_INTRINSIC_TABLE_OFFSET]
 test r8,r8
 jz .intrinsic_tables_checked
 cmp qword [r8+NEBOC_INTRINSIC_TABLE_STATE_OFFSET],NEBOC_INTRINSIC_TABLE_STATE_FROZEN
 jne .bad_intrinsic_table
 cmp qword [r8+NEBOC_INTRINSIC_TABLE_COUNT_OFFSET],NEBOC_INTRINSIC_COUNT
 jne .bad_intrinsic_table
 mov r9,[r12+NEBOC_SEMANTIC_DATABASE_TYPE_TABLE_OFFSET]
 test r9,r9
 jz .bad_intrinsic_types
 cmp qword [r9+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_FROZEN
 jne .bad_intrinsic_types
 cmp qword [r9+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_MAX_COUNT
 jne .bad_intrinsic_types
.intrinsic_tables_checked:
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_ROUTE_TABLE_OFFSET]
 test r8,r8
 jz .route_table_checked
 cmp qword [r8+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_FROZEN
 jne .bad_route_table
 cmp qword [r8+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],0
 je .bad_route_table
.route_table_checked:
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_PENDING_TABLE_OFFSET]
 mov r9,[r12+NEBOC_SEMANTIC_DATABASE_DEPENDENCY_GRAPH_OFFSET]
 test r8,r8
 jz .pending_table_absent
 cmp qword [r8+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_FROZEN
 jne .bad_pending_table
 cmp qword [r8+NEBOC_PENDING_TABLE_COUNT_OFFSET],0
 je .bad_pending_table
 test r9,r9
 jz .bad_dependency_graph
 cmp qword [r9+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_FROZEN
 jne .bad_dependency_graph
 cmp [r9+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET],r8
 jne .bad_dependency_graph
 mov r10,[r8+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 cmp r10,[r9+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 jne .bad_dependency_graph
 mov r10,[r9+NEBOC_DEPENDENCY_GRAPH_FLAGS_OFFSET]
 and r10,NEBOC_DEPENDENCY_GRAPH_REQUIRED_FLAGS
 cmp r10,NEBOC_DEPENDENCY_GRAPH_REQUIRED_FLAGS
 jne .bad_dependency_graph
 jmp .dependency_tables_checked
.pending_table_absent:
 test r9,r9
 jnz .bad_dependency_graph
.dependency_tables_checked:
 mov rax,[r13+NEBOC_AST_STORE_FLAGS_OFFSET]
 test rax,NEBOC_AST_STORE_FLAG_HAS_ERROR
 jnz .error_node_from_store
 mov rax,[r13+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET]
 test rax,rax
 jnz .error_node_known

 xor ebx,ebx
.audit_loop:
 cmp rbx,r14
 jae .audit_done
 mov r10,[r13+NEBOC_AST_STORE_DATA_OFFSET]
 test r10,r10
 jz .bad_database
 mov rax,rbx
 imul rax,NEBOC_AST_NODE_SIZE
 add r10,rax
 cmp qword [r10+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ERROR_NODE
 je .error_node_current
 mov r11,[r15+rbx*8]
 mov rax,r11
 and rax,~NEBOC_SEMANTIC_REQUIRE_ALL
 jnz .bad_mask

 test r11,NEBOC_SEMANTIC_REQUIRE_TYPE
 jz .symbol_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_TYPES_OFFSET]
 test r8,r8
 jz .missing_type
 cmp qword [r8+rbx*8],0
 je .missing_type
.symbol_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_SYMBOL
 jz .effect_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_SYMBOLS_OFFSET]
 test r8,r8
 jz .missing_symbol
 cmp qword [r8+rbx*8],0
 je .missing_symbol
.effect_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_EFFECT
 jz .call_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_EFFECTS_OFFSET]
 test r8,r8
 jz .missing_effect
 cmp qword [r8+rbx*8],0
 je .missing_effect
.call_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_CALL
 jz .behavior_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_CALLS_OFFSET]
 test r8,r8
 jz .missing_call
 cmp qword [r8+rbx*8],0
 je .missing_call
.behavior_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_BEHAVIOR
 jz .route_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_BEHAVIORS_OFFSET]
 test r8,r8
 jz .missing_behavior
 cmp qword [r8+rbx*8],0
 je .missing_behavior
.route_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_ROUTE
 jz .dependency_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_ROUTES_OFFSET]
 test r8,r8
 jz .missing_route
 cmp qword [r8+rbx*8],0
 je .missing_route
.dependency_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_DEPENDENCY
 jz .control_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_DEPENDENCIES_OFFSET]
 test r8,r8
 jz .missing_dependency
 cmp qword [r8+rbx*8],0
 je .missing_dependency
.control_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_CONTROL
 jz .constant_check
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONTROL_TABLE_OFFSET]
 test r8,r8
 jz .missing_control
 cmp qword [r8+NEBOC_CONTROL_FLOW_TABLE_STATE_OFFSET],NEBOC_CONTROL_FLOW_TABLE_STATE_FROZEN
 jne .missing_control
 cmp r14,[r8+NEBOC_CONTROL_FLOW_TABLE_CAPACITY_OFFSET]
 ja .missing_control
 mov r9,[r8+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 test r9,r9
 jz .missing_control
 cmp qword [r9+rbx*8],0
 je .missing_control
.constant_check:
 test r11,NEBOC_SEMANTIC_REQUIRE_CONSTANT
 jz .next_node
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONSTANT_TABLE_OFFSET]
 test r8,r8
 jz .missing_constant
 cmp qword [r8+NEBOC_CONSTANT_VALUE_TABLE_STATE_OFFSET],NEBOC_CONSTANT_VALUE_TABLE_STATE_FROZEN
 jne .missing_constant
 cmp r14,[r8+NEBOC_CONSTANT_VALUE_TABLE_CAPACITY_OFFSET]
 ja .missing_constant
 mov r9,[r8+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 test r9,r9
 jz .missing_constant
 cmp qword [r9+rbx*8],NEBOC_CONSTANT_VALUE_VALID
 jne .missing_constant
.next_node:
 inc rbx
 jmp .audit_loop

.audit_done:
 mov rdi,r12
 call neboc_semantic_database_compute_hash
 test eax,eax
 jnz .bad_database
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_VALIDATED
 xor eax,eax
 jmp .done

.error_node_from_store:
 mov rax,[r13+NEBOC_AST_STORE_ERROR_NODE_ID_OFFSET]
 test rax,rax
 jnz .error_node_known
 mov eax,1
.error_node_known:
 mov rbx,rax
 jmp .error_node
.error_node_current:
 lea rbx,[rbx+1]
.error_node:
 mov eax,NEBOC_SEMANTIC_ERROR_ERROR_NODE
 jmp .invalid_source
.bad_count:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_NODE_COUNT
 jmp .invalid_source
.bad_mask:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_REQUIRED_MASK
 jmp .invalid_source
.missing_type:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_TYPE
 jmp .invalid_source
.missing_symbol:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_SYMBOL
 jmp .invalid_source
.missing_effect:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_EFFECT
 jmp .invalid_source
.missing_call:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_CALL
 jmp .invalid_source
.missing_behavior:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_BEHAVIOR
 jmp .invalid_source
.missing_route:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_ROUTE
 jmp .invalid_source
.missing_dependency:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_DEPENDENCY
 jmp .invalid_source
.missing_control:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_CONTROL
 jmp .invalid_source
.missing_constant:
 lea rbx,[rbx+1]
 mov eax,NEBOC_SEMANTIC_ERROR_MISSING_CONSTANT
 jmp .invalid_source
.bad_intrinsic_table:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_INTRINSIC_TABLE
 jmp .invalid_source
.bad_intrinsic_types:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_INTRINSIC_TYPES
 jmp .invalid_source
.bad_route_table:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_ROUTE_TABLE
 jmp .invalid_source
.bad_pending_table:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_PENDING_TABLE
 jmp .invalid_source
.bad_dependency_graph:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_DEPENDENCY_GRAPH
 jmp .invalid_source
.ast_not_validated:
 xor ebx,ebx
 mov eax,NEBOC_SEMANTIC_ERROR_AST_NOT_VALIDATED
 jmp .invalid_source
.bad_database:
 xor ebx,ebx
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_INVALID
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],NEBOC_SEMANTIC_ERROR_BAD_DATABASE
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],0
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.invalid_source:
 mov [r12+NEBOC_SEMANTIC_DATABASE_ERROR_CODE_OFFSET],rax
 mov [r12+NEBOC_SEMANTIC_DATABASE_ERROR_NODE_ID_OFFSET],rbx
 mov qword [r12+NEBOC_SEMANTIC_DATABASE_STATE_OFFSET],NEBOC_SEMANTIC_DATABASE_STATE_INVALID
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad_argument_no_request:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; semantic_database_attach_intrinsics(database*, intrinsic_table*, type_table*)
; Attaches frozen compiler-owned semantic tables without creating runtime state.
NEBOC_ABI_FUNCTION neboc_semantic_database_attach_intrinsics
 test rdi,rdi
 jz .attach_invalid
 test rsi,rsi
 jz .attach_invalid
 test rdx,rdx
 jz .attach_invalid
 cmp qword [rsi+NEBOC_INTRINSIC_TABLE_STATE_OFFSET],NEBOC_INTRINSIC_TABLE_STATE_FROZEN
 jne .attach_invalid
 cmp qword [rsi+NEBOC_INTRINSIC_TABLE_COUNT_OFFSET],NEBOC_INTRINSIC_COUNT
 jne .attach_invalid
 cmp qword [rdx+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_FROZEN
 jne .attach_invalid
 cmp qword [rdx+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_MAX_COUNT
 jne .attach_invalid
 mov [rdi+NEBOC_SEMANTIC_DATABASE_INTRINSIC_TABLE_OFFSET],rsi
 mov [rdi+NEBOC_SEMANTIC_DATABASE_TYPE_TABLE_OFFSET],rdx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.attach_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; semantic_database_attach_routes(database*, routing_table*)
; Attaches a frozen compile-time routing table. Runtime objects are not created.
NEBOC_ABI_FUNCTION neboc_semantic_database_attach_routes
 test rdi,rdi
 jz .attach_routes_invalid
 test rsi,rsi
 jz .attach_routes_invalid
 cmp qword [rsi+NEBOC_CONSOLE_ROUTING_TABLE_STATE_OFFSET],NEBOC_CONSOLE_ROUTING_TABLE_STATE_FROZEN
 jne .attach_routes_invalid
 cmp qword [rsi+NEBOC_CONSOLE_ROUTING_TABLE_COUNT_OFFSET],0
 je .attach_routes_invalid
 mov [rdi+NEBOC_SEMANTIC_DATABASE_ROUTE_TABLE_OFFSET],rsi
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.attach_routes_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; semantic_database_attach_dependencies(database*, pending_table*, dependency_graph*)
; Attaches frozen compile-time Pending records and their deterministic graph.
NEBOC_ABI_FUNCTION neboc_semantic_database_attach_dependencies
 test rdi,rdi
 jz .attach_dependencies_invalid
 test rsi,rsi
 jz .attach_dependencies_invalid
 test rdx,rdx
 jz .attach_dependencies_invalid
 cmp qword [rsi+NEBOC_PENDING_TABLE_STATE_OFFSET],NEBOC_PENDING_TABLE_STATE_FROZEN
 jne .attach_dependencies_invalid
 cmp qword [rsi+NEBOC_PENDING_TABLE_COUNT_OFFSET],0
 je .attach_dependencies_invalid
 cmp qword [rdx+NEBOC_DEPENDENCY_GRAPH_STATE_OFFSET],NEBOC_DEPENDENCY_GRAPH_STATE_FROZEN
 jne .attach_dependencies_invalid
 cmp [rdx+NEBOC_DEPENDENCY_GRAPH_PENDING_TABLE_OFFSET],rsi
 jne .attach_dependencies_invalid
 mov rax,[rsi+NEBOC_PENDING_TABLE_COUNT_OFFSET]
 cmp rax,[rdx+NEBOC_DEPENDENCY_GRAPH_NODE_COUNT_OFFSET]
 jne .attach_dependencies_invalid
 mov [rdi+NEBOC_SEMANTIC_DATABASE_PENDING_TABLE_OFFSET],rsi
 mov [rdi+NEBOC_SEMANTIC_DATABASE_DEPENDENCY_GRAPH_OFFSET],rdx
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_OK
.attach_dependencies_invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT

; semantic_database_compute_hash(database*)
; FNV-1a32 over semantic values and stable IDs only; all pointers are excluded.
NEBOC_ABI_FUNCTION neboc_semantic_database_compute_hash
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_SEMANTIC_DATABASE_AST_STORE_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+NEBOC_SEMANTIC_DATABASE_NODE_COUNT_OFFSET]
 test r14,r14
 jz .invalid
 mov eax,NEBOC_SEMANTIC_HASH_FNV1A32_OFFSET_BASIS
 mov rdx,[r13+NEBOC_AST_STORE_HASH_OFFSET]
 call .hash_qword
 mov rdx,r14
 call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_INTRINSIC_TABLE_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_intrinsic_table
 mov rdx,[r8+NEBOC_INTRINSIC_TABLE_HASH_OFFSET]
.hash_intrinsic_table: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_TYPE_TABLE_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_intrinsic_types
 mov rdx,[r8+NEBOC_TYPE_TABLE_HASH_OFFSET]
.hash_intrinsic_types: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_ROUTE_TABLE_OFFSET]
 test r8,r8
 jz .hash_route_table_done
 mov rdx,[r8+NEBOC_CONSOLE_ROUTING_TABLE_HASH_OFFSET]
 call .hash_qword
.hash_route_table_done:
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_PENDING_TABLE_OFFSET]
 test r8,r8
 jz .hash_dependency_tables_done
 mov rdx,[r8+NEBOC_PENDING_TABLE_HASH_OFFSET]
 call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_DEPENDENCY_GRAPH_OFFSET]
 test r8,r8
 jz .hash_dependency_tables_done
 mov rdx,[r8+NEBOC_DEPENDENCY_GRAPH_HASH_OFFSET]
 call .hash_qword
.hash_dependency_tables_done:
 xor ebx,ebx
.hash_nodes:
 cmp rbx,r14
 jae .hash_done
 lea rdx,[rbx+1]
 call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_REQUIRED_MASKS_OFFSET]
 mov rdx,[r8+rbx*8]
 call .hash_qword

 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_TYPES_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_type
 mov rdx,[r8+rbx*8]
.hash_type: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_SYMBOLS_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_symbol
 mov rdx,[r8+rbx*8]
.hash_symbol: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_EFFECTS_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_effect
 mov rdx,[r8+rbx*8]
.hash_effect: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_CALLS_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_call
 mov rdx,[r8+rbx*8]
.hash_call: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_BEHAVIORS_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_behavior
 mov rdx,[r8+rbx*8]
.hash_behavior: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_ROUTES_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_route
 mov rdx,[r8+rbx*8]
.hash_route: call .hash_qword
 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_NODE_DEPENDENCIES_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_dependency
 mov rdx,[r8+rbx*8]
.hash_dependency: call .hash_qword

 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONTROL_TABLE_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_control
 mov r9,[r8+NEBOC_CONTROL_FLOW_TABLE_DATA_OFFSET]
 test r9,r9
 jz .hash_control
 mov rdx,[r9+rbx*8]
.hash_control: call .hash_qword

 mov r8,[r12+NEBOC_SEMANTIC_DATABASE_CONSTANT_TABLE_OFFSET]
 xor edx,edx
 test r8,r8
 jz .hash_constant_value
 mov r9,[r8+NEBOC_CONSTANT_VALUE_TABLE_VALUES_OFFSET]
 test r9,r9
 jz .hash_constant_value
 mov rdx,[r9+rbx*8]
.hash_constant_value: call .hash_qword
 xor edx,edx
 test r8,r8
 jz .hash_constant_flag
 mov r9,[r8+NEBOC_CONSTANT_VALUE_TABLE_FLAGS_OFFSET]
 test r9,r9
 jz .hash_constant_flag
 mov rdx,[r9+rbx*8]
.hash_constant_flag: call .hash_qword
 inc rbx
 jmp .hash_nodes
.hash_done:
 mov [r12+NEBOC_SEMANTIC_DATABASE_HASH_OFFSET],rax
 xor eax,eax
 jmp .done_hash
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done_hash:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.hash_qword:
 push rcx
 mov ecx,8
.hq:
 movzx r15d,dl
 xor eax,r15d
 imul eax,eax,NEBOC_SEMANTIC_HASH_FNV1A32_PRIME
 shr rdx,8
 dec ecx
 jnz .hq
 pop rcx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
