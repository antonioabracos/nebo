; Nebo Assembly — MF022 fundamental type assignment and checked constants
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/diagnostics/catalog.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/ast/store/ast_store.inc"
%include "compiler/semantic/symbol/symbol_table.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/types/type_checker.inc"

extern neboc_operator_unary_type
extern neboc_operator_binary_type
extern neboc_checked_int_unary
extern neboc_checked_int_binary
extern neboc_quantity_normalize_constant

section .rodata
name_void: db 'Void'
name_void_len equ $-name_void
name_bool: db 'Bool'
name_bool_len equ $-name_bool
name_int: db 'Int'
name_int_len equ $-name_int
name_text: db 'Text'
name_text_len equ $-name_text
name_console_type: db 'Console'
name_console_type_len equ $-name_console_type
name_console_call: db 'console'
name_console_call_len equ $-name_console_call
name_scan_call: db 'scan'
name_scan_call_len equ $-name_scan_call

section .text

; type_check(request*)
NEBOC_ABI_FUNCTION neboc_type_check
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .check_invalid
 mov r13,[r12+NEBOC_TYPE_REQUEST_AST_STORE_OFFSET]
 mov r14,[r12+NEBOC_TYPE_REQUEST_TYPE_TABLE_OFFSET]
 mov r15,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TABLE_OFFSET]
 test r13,r13
 jz .check_invalid
 test r14,r14
 jz .check_invalid
 test r15,r15
 jz .check_invalid
 cmp qword [r13+NEBOC_AST_STORE_STATE_OFFSET],NEBOC_AST_STORE_STATE_VALIDATED
 jne .check_invalid
 cmp qword [r14+NEBOC_TYPE_TABLE_STATE_OFFSET],NEBOC_TYPE_TABLE_STATE_FROZEN
 jne .check_invalid
 cmp qword [r14+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_BUILTIN_COUNT
 je .check_type_table_ready
 cmp qword [r14+NEBOC_TYPE_TABLE_COUNT_OFFSET],NEBOC_TYPE_QUANTITY_MAX_COUNT
 jne .check_invalid
.check_type_table_ready:
 cmp qword [r15+NEBOC_SYMBOL_TABLE_STATE_OFFSET],NEBOC_SYMBOL_TABLE_STATE_FROZEN
 jne .check_invalid
 mov rbx,[r13+NEBOC_AST_STORE_COUNT_OFFSET]
 test rbx,rbx
 jz .check_invalid
 cmp rbx,[r12+NEBOC_TYPE_REQUEST_NODE_CAPACITY_OFFSET]
 ja .check_limit
 mov rax,[r15+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET]
 ja .check_limit
 cmp qword [r12+NEBOC_TYPE_REQUEST_TOKENS_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_SOURCE_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_NODE_SYMBOLS_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET],0
 je .check_invalid
 cmp qword [r12+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET],0
 je .check_invalid

 mov qword [r12+NEBOC_TYPE_REQUEST_ERROR_CODE_OFFSET],0
 mov qword [r12+NEBOC_TYPE_REQUEST_ERROR_NODE_ID_OFFSET],0
 mov qword [r12+NEBOC_TYPE_REQUEST_ERROR_TOKEN_OFFSET],0
 mov qword [r12+NEBOC_TYPE_REQUEST_HASH_OFFSET],0
 ; Clear node side tables.
 mov rdi,[r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 xor eax,eax
 mov rcx,rbx
 rep stosq
 mov rdi,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rcx,rbx
 rep stosq
 mov rdi,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET]
 mov rcx,rbx
 rep stosq
 ; Clear symbol type side table.
 mov rdi,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET]
 mov rcx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET]
 rep stosq

 mov rdi,r12
 call tc_predeclare_symbol_types
 test eax,eax
 jnz .check_done
 mov rsi,[r13+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 mov rdi,r12
 call tc_type_node
 test rax,rax
 jz .check_source_error
 ; Every expression/terminal node must carry a non-zero TypeId.
 xor r14d,r14d
.check_all_loop:
 cmp r14,rbx
 jae .check_all_done
 mov rax,r14
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[r13+NEBOC_AST_STORE_DATA_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_IDENTIFIER_EXPR
 jb .check_all_next
 cmp rcx,NEBOC_AST_RETURN_TERMINAL
 ja .check_all_next
 mov rdx,[r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 cmp qword [rdx+r14*8],0
 jne .check_all_next
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_MISMATCH
 lea rdx,[r14+1]
 xor ecx,ecx
 call tc_fail
 jmp .check_done
.check_all_next:
 inc r14
 jmp .check_all_loop
.check_all_done:
 mov rdi,r12
 call tc_compute_hash
 test eax,eax
 jnz .check_done
 xor eax,eax
 jmp .check_done
.check_source_error:
 cmp qword [r12+NEBOC_TYPE_REQUEST_ERROR_CODE_OFFSET],0
 jne .check_source_status
 mov rdi,r12
 mov esi,NEBOC_DIAG_INTERNAL_ERROR
 mov rdx,[r13+NEBOC_AST_STORE_ROOT_ID_OFFSET]
 xor ecx,ecx
 call tc_fail
 jmp .check_done
.check_source_status:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .check_done
.check_limit:
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .check_done
.check_invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.check_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; tc_node_ptr(request*, node_id) -> RAX or zero
tc_node_ptr:
 test rdi,rdi
 jz .node_bad
 test rsi,rsi
 jz .node_bad
 mov rax,[rdi+NEBOC_TYPE_REQUEST_AST_STORE_OFFSET]
 cmp rsi,[rax+NEBOC_AST_STORE_COUNT_OFFSET]
 ja .node_bad
 mov rax,[rax+NEBOC_AST_STORE_DATA_OFFSET]
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 add rax,rsi
 ret
.node_bad:
 xor eax,eax
 ret

; tc_token_ptr(request*, token_index) -> RAX or zero
tc_token_ptr:
 test rdi,rdi
 jz .token_bad
 cmp rsi,[rdi+NEBOC_TYPE_REQUEST_TOKEN_COUNT_OFFSET]
 jae .token_bad
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_TYPE_REQUEST_TOKENS_OFFSET]
 ret
.token_bad:
 xor eax,eax
 ret

; tc_fail(request*, diagnostic_code, node_id, token_index)
tc_fail:
 mov [rdi+NEBOC_TYPE_REQUEST_ERROR_CODE_OFFSET],rsi
 mov [rdi+NEBOC_TYPE_REQUEST_ERROR_NODE_ID_OFFSET],rdx
 mov [rdi+NEBOC_TYPE_REQUEST_ERROR_TOKEN_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret

; tc_set_node_type(request*, node_id, type_id)
tc_set_node_type:
 test rsi,rsi
 jz .set_type_bad
 cmp rsi,[rdi+NEBOC_TYPE_REQUEST_NODE_CAPACITY_OFFSET]
 ja .set_type_bad
 mov rax,[rdi+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 dec rsi
 mov [rax+rsi*8],rdx
 xor eax,eax
 ret
.set_type_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; tc_set_constant(request*, node_id, value)
tc_set_constant:
 test rsi,rsi
 jz .set_constant_bad
 cmp rsi,[rdi+NEBOC_TYPE_REQUEST_NODE_CAPACITY_OFFSET]
 ja .set_constant_bad
 mov rax,[rdi+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rcx,[rdi+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET]
 dec rsi
 mov [rax+rsi*8],rdx
 mov qword [rcx+rsi*8],NEBOC_TYPE_CONSTANT_VALID
 xor eax,eax
 ret
.set_constant_bad:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

; tc_token_matches(request*, token_index, ascii*, length) -> EAX 1/0
tc_token_matches:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rdx
 mov r14,rcx
 call tc_token_ptr
 test rax,rax
 jz .matches_no
 mov rbx,rax
 mov r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[rbx+NEBOC_TOKEN_END_OFFSET]
 cmp r8,r9
 ja .matches_no
 cmp r9,[r12+NEBOC_TYPE_REQUEST_SOURCE_LENGTH_OFFSET]
 ja .matches_no
 sub r9,r8
 cmp r9,r14
 jne .matches_no
 mov rsi,[r12+NEBOC_TYPE_REQUEST_SOURCE_OFFSET]
 add rsi,r8
 mov rdi,r13
 mov rcx,r14
 repe cmpsb
 sete al
 movzx eax,al
 jmp .matches_done
.matches_no:
 xor eax,eax
.matches_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; tc_type_from_token(request*, token_index) -> RAX TypeId or zero
tc_type_from_token:
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 lea rdx,[rel name_void]
 mov ecx,name_void_len
 call tc_token_matches
 test eax,eax
 jnz .type_void
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bool]
 mov ecx,name_bool_len
 call tc_token_matches
 test eax,eax
 jnz .type_bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_int]
 mov ecx,name_int_len
 call tc_token_matches
 test eax,eax
 jnz .type_int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_text]
 mov ecx,name_text_len
 call tc_token_matches
 test eax,eax
 jnz .type_text
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_console_type]
 mov ecx,name_console_type_len
 call tc_token_matches
 test eax,eax
 jnz .type_console
 xor eax,eax
 jmp .type_done
.type_void: mov eax,NEBOC_TYPE_ID_VOID
 jmp .type_done
.type_bool: mov eax,NEBOC_TYPE_ID_BOOL
 jmp .type_done
.type_int: mov eax,NEBOC_TYPE_ID_INT
 jmp .type_done
.type_text: mov eax,NEBOC_TYPE_ID_TEXT
 jmp .type_done
.type_console: mov eax,NEBOC_TYPE_ID_CONSOLE
.type_done:
 add rsp,8
 pop r13
 pop r12
 ret

; Resolve receiver/parameter declaration types before expression traversal.
tc_predeclare_symbol_types:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TABLE_OFFSET]
 xor ebx,ebx
.predeclare_loop:
 cmp rbx,[r13+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 jae .predeclare_done_ok
 mov rax,rbx
 imul rax,NEBOC_SYMBOL_ENTRY_SIZE
 add rax,[r13+NEBOC_SYMBOL_TABLE_DATA_OFFSET]
 mov r14,rax
 mov r15,[r14+NEBOC_SYMBOL_ENTRY_KIND_OFFSET]
 cmp r15,NEBOC_SYMBOL_KIND_RECEIVER
 je .predeclare_typed
 cmp r15,NEBOC_SYMBOL_KIND_PARAMETER
 jne .predeclare_next
.predeclare_typed:
 mov rdi,r12
 mov rsi,[r14+NEBOC_SYMBOL_ENTRY_DECL_NODE_ID_OFFSET]
 call tc_node_ptr
 test rax,rax
 jz .predeclare_internal
 mov [rsp],rax
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 call tc_type_from_token
 test rax,rax
 jz .predeclare_mismatch
 mov rdx,[r14+NEBOC_SYMBOL_ENTRY_ID_OFFSET]
 test rdx,rdx
 jz .predeclare_internal
 cmp rdx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET]
 ja .predeclare_internal
 mov rcx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET]
 dec rdx
 mov [rcx+rdx*8],rax
 mov rdx,rax
 mov rsi,[r14+NEBOC_SYMBOL_ENTRY_DECL_NODE_ID_OFFSET]
 mov rdi,r12
 call tc_set_node_type
 test eax,eax
 jnz .predeclare_done
.predeclare_next:
 inc rbx
 jmp .predeclare_loop
.predeclare_mismatch:
 mov rax,[rsp]
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_MISMATCH
 mov rdx,[r14+NEBOC_SYMBOL_ENTRY_DECL_NODE_ID_OFFSET]
 call tc_fail
 jmp .predeclare_done
.predeclare_internal:
 mov rdi,r12
 mov esi,NEBOC_DIAG_INTERNAL_ERROR
 mov rdx,[r14+NEBOC_SYMBOL_ENTRY_DECL_NODE_ID_OFFSET]
 xor ecx,ecx
 call tc_fail
 jmp .predeclare_done
.predeclare_done_ok:
 xor eax,eax
.predeclare_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; tc_type_children(request*, first_child_id, count) -> EAX status
tc_type_children:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
.children_loop:
 test r14,r14
 jz .children_end
 test r13,r13
 jz .children_bad
 mov rdi,r12
 mov rsi,r13
 call tc_type_node
 test rax,rax
 jz .children_bad
 mov rdi,r12
 mov rsi,r13
 call tc_node_ptr
 test rax,rax
 jz .children_bad
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r14
 jmp .children_loop
.children_end:
 test r13,r13
 jnz .children_bad
 xor eax,eax
 jmp .children_done
.children_bad:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.children_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; tc_type_node(request*, node_id) -> RAX TypeId or zero on failure
tc_type_node:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .node_failure
 cmp r13,[r12+NEBOC_TYPE_REQUEST_NODE_CAPACITY_OFFSET]
 ja .node_failure
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 lea rdx,[r13-1]
 mov r14,[rax+rdx*8]
 test r14,r14
 jnz .node_return_cached
 mov rdi,r12
 mov rsi,r13
 call tc_node_ptr
 test rax,rax
 jz .node_internal
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rbx,NEBOC_AST_INTEGER_LITERAL
 je .node_integer
 cmp rbx,NEBOC_AST_TEXT_LITERAL
 je .node_text
 cmp rbx,NEBOC_AST_BOOL_LITERAL
 je .node_bool
 cmp rbx,NEBOC_AST_IDENTIFIER_EXPR
 je .node_identifier
 cmp rbx,NEBOC_AST_UNARY_EXPR
 je .node_unary
 cmp rbx,NEBOC_AST_BINARY_EXPR
 je .node_binary
 cmp rbx,NEBOC_AST_CALL_EXPR
 je .node_call
 cmp rbx,NEBOC_AST_BINDING_TERMINAL
 je .node_terminal
 cmp rbx,NEBOC_AST_RETURN_TERMINAL
 je .node_terminal
 cmp rbx,NEBOC_AST_BINDING_STMT
 je .node_binding_stmt
 cmp rbx,NEBOC_AST_IF_STMT
 je .node_if
 cmp rbx,NEBOC_AST_RECEIVER
 je .node_declared
 cmp rbx,NEBOC_AST_PARAMETER
 je .node_declared
 cmp rbx,NEBOC_AST_ERROR_NODE
 je .node_invalid_source
 ; Program, declarations, blocks and ordinary statements type children and are Void.
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 call tc_type_children
 test eax,eax
 jnz .node_failure
 mov r14,NEBOC_TYPE_ID_VOID
 jmp .node_store

.node_declared:
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 lea rdx,[r13-1]
 mov r14,[rax+rdx*8]
 test r14,r14
 jz .node_internal
 jmp .node_return_cached

.node_integer:
 mov r14,NEBOC_TYPE_ID_INT
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call tc_set_constant
 test eax,eax
 jnz .node_failure
 jmp .node_store
.node_text:
 mov r14,NEBOC_TYPE_ID_TEXT
 jmp .node_store
.node_bool:
 mov r14,NEBOC_TYPE_ID_BOOL
 mov rdi,r12
 mov rsi,r13
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call tc_set_constant
 test eax,eax
 jnz .node_failure
 jmp .node_store

.node_identifier:
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_SYMBOLS_OFFSET]
 lea rdx,[r13-1]
 mov rcx,[rax+rdx*8]
 test rcx,rcx
 jz .node_mismatch
 cmp rcx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET]
 ja .node_internal
 mov rax,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET]
 dec rcx
 mov r14,[rax+rcx*8]
 test r14,r14
 jz .node_mismatch
 jmp .node_store

.node_terminal:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .node_internal
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov r14,rax
 jmp .node_store

.node_binding_stmt:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .node_internal
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov [rsp],rax
 mov rdx,[r12+NEBOC_TYPE_REQUEST_NODE_SYMBOLS_OFFSET]
 lea rcx,[r13-1]
 mov rcx,[rdx+rcx*8]
 test rcx,rcx
 jz .node_internal
 cmp rcx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_CAPACITY_OFFSET]
 ja .node_internal
 mov rdx,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET]
 dec rcx
 mov rax,[rsp]
 mov [rdx+rcx*8],rax
 mov r14,NEBOC_TYPE_ID_VOID
 jmp .node_store

.node_if:
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 cmp rdx,2
 jb .node_internal
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 call tc_type_node
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .node_truthiness
 mov rdi,r12
 mov rsi,[rsp]
 call tc_node_ptr
 test rax,rax
 jz .node_internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 dec rdx
 mov rdi,r12
 call tc_type_children
 test eax,eax
 jnz .node_failure
 mov r14,NEBOC_TYPE_ID_VOID
 jmp .node_store

.node_unary:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .node_internal
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov [rsp+8],rax
 mov rdi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,rax
 lea rdx,[rsp+16]
 call neboc_operator_unary_type
 test eax,eax
 jnz .node_operator_mismatch
 mov r14,[rsp+16]
 ; Constant propagation for Int unary minus and Bool bang.
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET]
 mov rdx,[rsp]
 dec rdx
 cmp qword [rax+rdx*8],NEBOC_TYPE_CONSTANT_VALID
 jne .node_store
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rsi,[rax+rdx*8]
 mov rdi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rdi,NEBOC_TOKEN_DEGREE
 jb .node_unary_scalar_constant
 cmp rdi,NEBOC_TOKEN_POSTFIX_PERCENT
 ja .node_unary_scalar_constant
 lea rdx,[rsp+24]
 call neboc_quantity_normalize_constant
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .node_overflow
 test eax,eax
 jnz .node_operator_mismatch
 mov rdx,[rsp+24]
 jmp .node_save_constant
.node_unary_scalar_constant:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_BANG
 je .node_unary_bang_constant
 mov rdi,NEBOC_TOKEN_MINUS
 lea rdx,[rsp+24]
 call neboc_checked_int_unary
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .node_overflow
 test eax,eax
 jnz .node_internal
 mov rdx,[rsp+24]
 jmp .node_save_constant
.node_unary_bang_constant:
 test rsi,rsi
 setz dl
 movzx edx,dl
.node_save_constant:
 mov rdi,r12
 mov rsi,r13
 call tc_set_constant
 test eax,eax
 jnz .node_failure
 jmp .node_store

.node_binary:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 jne .node_internal
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call tc_node_ptr
 test rax,rax
 jz .node_internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rsi
 mov rdi,r12
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov [rsp+24],rax
 mov rdi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[rsp+8]
 mov rdx,rax
 lea rcx,[rsp+32]
 call neboc_operator_binary_type
 test eax,eax
 jnz .node_operator_mismatch
 mov r14,[rsp+32]
 ; Constant propagation when both operands are compile-time values.
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET]
 mov rdx,[rsp]
 dec rdx
 cmp qword [rax+rdx*8],NEBOC_TYPE_CONSTANT_VALID
 jne .node_store
 mov rdx,[rsp+16]
 dec rdx
 cmp qword [rax+rdx*8],NEBOC_TYPE_CONSTANT_VALID
 jne .node_store
 cmp qword [rsp+8],NEBOC_TYPE_ID_INT
 jne .node_bool_constants
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rdx,[rsp]
 dec rdx
 mov rsi,[rax+rdx*8]
 mov rdx,[rsp+16]
 dec rdx
 mov rdx,[rax+rdx*8]
 mov rdi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rcx,[rsp+40]
 call neboc_checked_int_binary
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 je .node_overflow
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 je .node_div_zero
 test eax,eax
 jnz .node_store
 mov rdx,[rsp+40]
 mov rdi,r12
 mov rsi,r13
 call tc_set_constant
 test eax,eax
 jnz .node_failure
 jmp .node_store
.node_bool_constants:
 cmp qword [rsp+8],NEBOC_TYPE_ID_BOOL
 jne .node_store
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rdx,[rsp]
 dec rdx
 mov r8,[rax+rdx*8]
 mov rdx,[rsp+16]
 dec rdx
 mov r9,[rax+rdx*8]
 mov r10,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp r10,NEBOC_TOKEN_AND_AND
 je .node_bool_and
 cmp r10,NEBOC_TOKEN_OR_OR
 je .node_bool_or
 cmp r10,NEBOC_TOKEN_EQUAL_EQUAL
 je .node_bool_eq
 cmp r10,NEBOC_TOKEN_BANG_EQUAL
 jne .node_store
 xor edx,edx
 cmp r8,r9
 setne dl
 jmp .node_bool_save
.node_bool_and:
 test r8,r8
 setnz dl
 test r9,r9
 setnz al
 and dl,al
 movzx edx,dl
 jmp .node_bool_save
.node_bool_or:
 test r8,r8
 setnz dl
 test r9,r9
 setnz al
 or dl,al
 movzx edx,dl
 jmp .node_bool_save
.node_bool_eq:
 xor edx,edx
 cmp r8,r9
 sete dl
.node_bool_save:
 mov rdi,r12
 mov rsi,r13
 call tc_set_constant
 test eax,eax
 jnz .node_failure
 jmp .node_store

.node_call:
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 test rdx,rdx
 jz .node_internal
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 call tc_type_node
 test rax,rax
 jz .node_failure
 mov [rsp+8],rax
 ; Type all positional arguments, but arity/signature checks are MF023.
 mov rdi,r12
 mov rsi,[rsp]
 call tc_node_ptr
 test rax,rax
 jz .node_internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 dec rdx
 mov rdi,r12
 call tc_type_children
 test eax,eax
 jnz .node_failure
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel name_console_call]
 mov ecx,name_console_call_len
 call tc_token_matches
 test eax,eax
 jnz .node_call_console
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel name_scan_call]
 mov ecx,name_scan_call_len
 call tc_token_matches
 test eax,eax
 jnz .node_call_scan
 jmp .node_mismatch
.node_call_console:
 mov r14,NEBOC_TYPE_ID_CONSOLE
 jmp .node_store
.node_call_scan:
 cmp qword [rsp+8],NEBOC_TYPE_ID_TEXT
 je .node_call_scan_ok
 cmp qword [rsp+8],NEBOC_TYPE_ID_CONSOLE
 jne .node_mismatch
.node_call_scan_ok:
 mov r14,NEBOC_TYPE_ID_PENDING_TEXT
 jmp .node_store

.node_truthiness:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_TRUTHINESS
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_operator_mismatch:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_UNSUPPORTED_OPERATOR
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_mismatch:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_MISMATCH
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_overflow:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_CONSTANT_OVERFLOW
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_div_zero:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_DIVISION_BY_ZERO
 mov rdx,r13
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_invalid_source:
 mov rdi,r12
 mov esi,NEBOC_DIAG_TYPE_MISMATCH
 mov rdx,r13
 xor ecx,ecx
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_internal:
 mov rdi,r12
 mov esi,NEBOC_DIAG_INTERNAL_ERROR
 mov rdx,r13
 xor ecx,ecx
 call tc_fail
 xor eax,eax
 jmp .node_done
.node_store:
 mov rdi,r12
 mov rsi,r13
 mov rdx,r14
 call tc_set_node_type
 test eax,eax
 jnz .node_failure
 mov rax,r14
 jmp .node_done
.node_return_cached:
 mov rax,r14
 jmp .node_done
.node_failure:
 xor eax,eax
.node_done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; Deterministic hash of TypeIds, constant facts and symbol TypeIds.
tc_compute_hash:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov ebx,NEBOC_TYPE_HASH_FNV1A32_OFFSET_BASIS
 xor r13d,r13d
 mov r14,[r12+NEBOC_TYPE_REQUEST_AST_STORE_OFFSET]
.hash_node_loop:
 cmp r13,[r14+NEBOC_AST_STORE_COUNT_OFFSET]
 jae .hash_symbol_start
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_TYPES_OFFSET]
 mov rdx,[rax+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANT_FLAGS_OFFSET]
 mov rcx,[rax+r13*8]
 xor ebx,ecx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 test rcx,rcx
 jz .hash_node_next
 mov rax,[r12+NEBOC_TYPE_REQUEST_NODE_CONSTANTS_OFFSET]
 mov rdx,[rax+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 shr rdx,32
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
.hash_node_next:
 inc r13
 jmp .hash_node_loop
.hash_symbol_start:
 xor r13d,r13d
 mov r14,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TABLE_OFFSET]
.hash_symbol_loop:
 cmp r13,[r14+NEBOC_SYMBOL_TABLE_COUNT_OFFSET]
 jae .hash_done
 mov rax,[r12+NEBOC_TYPE_REQUEST_SYMBOL_TYPES_OFFSET]
 mov rdx,[rax+r13*8]
 xor ebx,edx
 imul ebx,ebx,NEBOC_TYPE_HASH_FNV1A32_PRIME
 inc r13
 jmp .hash_symbol_loop
.hash_done:
 mov [r12+NEBOC_TYPE_REQUEST_HASH_OFFSET],rbx
 xor eax,eax
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
