; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF005 Float vertical semantic conformance
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/foundation_scalar_descriptor.inc"
%include "compiler/semantic/types/foundation_float_semantic.inc"

section .rodata
float_name: db "Float"
float_name_len equ $-float_name

section .text

; foundation_float_recognize(request*)
; TIPOS-PRIMITIVOS-ESCALARES-PF005 accepts strict Float literals, Float(expr), unary minus and
; homogeneous Float + - * / expressions. It rejects implicit coercion,
; identifier reuse, function/control contexts and all other operators.
NEBOC_ABI_FUNCTION neboc_foundation_float_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+NEBOC_FLOAT_SEM_BUILDER_OFFSET]
 mov r14,[r12+NEBOC_FLOAT_SEM_TOKENS_OFFSET]
 mov r15,[r12+NEBOC_FLOAT_SEM_SOURCE_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 mov rbx,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 test rbx,rbx
 jz .invalid
 mov qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],0
 mov qword [r12+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_NONE
 mov qword [r12+NEBOC_FLOAT_SEM_ERROR_NODE_OFFSET],0
 mov rax,NEBOC_FLOAT_SEM_HASH_OFFSET_BASIS
 mov [r12+NEBOC_FLOAT_SEM_HASH_OFFSET],rax
 mov qword [rsp],1                 ; node id
 mov qword [rsp+16],0              ; first FunctionDecl
 mov qword [rsp+24],0              ; first globally unsupported node

.node_loop:
 mov rax,[rsp]
 cmp rax,rbx
 ja .finish
 mov rdi,r13
 mov rsi,rax
 call float_node_ptr
 test rax,rax
 jz .internal
 mov [rsp+8],rax
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 mov rdx,[r12+NEBOC_FLOAT_SEM_HASH_OFFSET]
 xor rdx,rcx
 mov r10,NEBOC_FLOAT_SEM_HASH_PRIME
 imul rdx,r10
 xor rdx,[rsp]
 imul rdx,r10
 mov [r12+NEBOC_FLOAT_SEM_HASH_OFFSET],rdx

 cmp rcx,NEBOC_AST_FLOAT_LITERAL
 je .float_literal
 cmp rcx,NEBOC_AST_CALL_EXPR
 je .call_node
 cmp rcx,NEBOC_AST_BINARY_EXPR
 je .binary_node
 cmp rcx,NEBOC_AST_UNARY_EXPR
 je .unary_node
 cmp rcx,NEBOC_AST_FUNCTION_DECL
 je .remember_function
 cmp rcx,NEBOC_AST_IF_STMT
 je .remember_unsupported
 cmp rcx,NEBOC_AST_RETURN_STMT
 je .remember_unsupported
 cmp rcx,NEBOC_AST_RETURN_TERMINAL
 je .restricted_if_float
 jmp .next

.float_literal:
 mov qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],1
 jmp .next

.remember_function:
 cmp qword [rsp+16],0
 jne .restricted_if_float
 mov rax,[rsp]
 mov [rsp+16],rax
 jmp .restricted_if_float

.remember_unsupported:
 cmp qword [rsp+24],0
 jne .restricted_if_float
 mov rax,[rsp]
 mov [rsp+24],rax
 jmp .restricted_if_float

.restricted_if_float:
 mov rdx,[rsp+8]
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 test rsi,rsi
 jz .next
 mov rdi,r13
 call float_child_chain_contains
 test eax,eax
 jnz .unsupported
 jmp .next

.call_node:
 mov rdx,[rsp+8]
 test qword [rdx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .call_non_constructor
 mov rdi,r12
 mov rsi,[rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call float_token_is_name
 cmp eax,1
 jne .non_float_constructor
 mov qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],1
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .invalid_constructor
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .invalid_constructor
 mov rdi,r12
 call float_expression_kind
 cmp eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .invalid_constructor
 jmp .next
.non_float_constructor:
 mov rdx,[rsp+8]
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rdi,r13
 call float_child_chain_contains
 test eax,eax
 jnz .mixed
 jmp .next
.call_non_constructor:
 cmp qword [rsp+24],0
 jne .call_check_float
 mov rax,[rsp]
 mov [rsp+24],rax
.call_check_float:
 mov rdx,[rsp+8]
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rdi,r13
 call float_child_chain_contains
 test eax,eax
 jnz .unsupported
 jmp .next

.binary_node:
 mov rdx,[rsp+8]
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdx,[rdx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov rdi,r13
 call float_child_chain_contains
 test eax,eax
 jz .next
 mov qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],1
 mov rdx,[rsp+8]
 mov rax,[rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary_operator_ok
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary_operator_ok
 cmp rax,NEBOC_TOKEN_STAR
 je .binary_operator_ok
 cmp rax,NEBOC_TOKEN_SLASH
 jne .unsupported_operator
.binary_operator_ok:
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov [rsp+32],rsi
 mov rdi,r13
 call float_node_ptr
 test rax,rax
 jz .internal
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .internal
 mov [rsp+40],rax
 mov rdi,r12
 mov rsi,[rsp+32]
 call float_expression_kind
 cmp eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .mixed
 mov rdi,r12
 mov rsi,[rsp+40]
 call float_expression_kind
 cmp eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .mixed
 jmp .next

.unary_node:
 mov rdx,[rsp+8]
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r13
 call float_subtree_contains
 test eax,eax
 jz .next
 mov qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],1
 mov rdx,[rsp+8]
 cmp qword [rdx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsupported_operator
 mov rdi,r12
 mov rsi,[rdx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call float_expression_kind
 cmp eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .mixed
 jmp .next

.finish:
 cmp qword [r12+NEBOC_FLOAT_SEM_FOUND_OFFSET],0
 je .ok
 cmp qword [rsp+16],0
 jne .unsupported_saved_function
 cmp qword [rsp+24],0
 jne .unsupported_saved_node
 jmp .ok
.unsupported_saved_function:
 mov rax,[rsp+16]
 mov [r12+NEBOC_FLOAT_SEM_ERROR_NODE_OFFSET],rax
 mov qword [r12+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_CONTEXT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported_saved_node:
 mov rax,[rsp+24]
 mov [r12+NEBOC_FLOAT_SEM_ERROR_NODE_OFFSET],rax
 mov qword [r12+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_CONTEXT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done

.invalid_constructor:
 mov ecx,NEBOC_FLOAT_SEM_ERROR_INVALID_CONSTRUCTOR
 jmp .set_source_error
.mixed:
 mov ecx,NEBOC_FLOAT_SEM_ERROR_MIXED_NUMERIC_TYPES
 jmp .set_source_error
.unsupported_operator:
 mov ecx,NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_OPERATOR
 jmp .set_source_error
.unsupported:
 mov ecx,NEBOC_FLOAT_SEM_ERROR_UNSUPPORTED_CONTEXT
.set_source_error:
 mov [r12+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],rcx
 mov rax,[rsp]
 mov [r12+NEBOC_FLOAT_SEM_ERROR_NODE_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+NEBOC_FLOAT_SEM_ERROR_CODE_OFFSET],NEBOC_FLOAT_SEM_ERROR_INTERNAL
 mov rax,[rsp]
 mov [r12+NEBOC_FLOAT_SEM_ERROR_NODE_OFFSET],rax
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.next:
 inc qword [rsp]
 jmp .node_loop
.ok:
 xor eax,eax
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; float_expression_kind(request*, node_id) -> FLOAT/NON_FLOAT/UNKNOWN
float_expression_kind:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_FLOAT_SEM_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call float_node_ptr
 test rax,rax
 jz .unknown
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rbx,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rbx,NEBOC_AST_INTEGER_LITERAL
 je .non_float
 cmp rbx,NEBOC_AST_BOOL_LITERAL
 je .non_float
 cmp rbx,NEBOC_AST_TEXT_LITERAL
 je .non_float
 cmp rbx,NEBOC_AST_IDENTIFIER_EXPR
 je .non_float
 cmp rbx,NEBOC_AST_CALL_EXPR
 je .call
 cmp rbx,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rbx,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rbx,NEBOC_AST_BINDING_TERMINAL
 je .wrapper
 cmp rbx,NEBOC_AST_RETURN_TERMINAL
 je .wrapper
 cmp rbx,NEBOC_AST_EXPRESSION_STMT
 je .wrapper
 cmp rbx,NEBOC_AST_BINDING_STMT
 je .wrapper
 jmp .non_float
.call:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .non_float
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call float_token_is_name
 test eax,eax
 jz .non_float
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .unknown
 jmp .wrapper
.unary:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .non_float
 jmp .wrapper
.wrapper:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .unknown
 mov rdi,r12
 call float_expression_kind
 jmp .done_kind
.binary:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .unknown
 mov [rsp],rsi
 mov rdi,r14
 call float_node_ptr
 test rax,rax
 jz .unknown
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .unknown
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call float_expression_kind
 mov [rsp+16],rax
 mov rdi,r12
 mov rsi,[rsp+8]
 call float_expression_kind
 mov rdx,[rsp+16]
 cmp rdx,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .binary_non_float
 cmp eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jne .non_float
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .float
 cmp rax,NEBOC_TOKEN_MINUS
 je .float
 cmp rax,NEBOC_TOKEN_STAR
 je .float
 cmp rax,NEBOC_TOKEN_SLASH
 je .float
 jmp .non_float
.binary_non_float:
 cmp rdx,NEBOC_FLOAT_SEM_EXPR_NON_FLOAT
 jne .unknown
 cmp eax,NEBOC_FLOAT_SEM_EXPR_NON_FLOAT
 jne .non_float
 jmp .non_float
.float:
 mov eax,NEBOC_FLOAT_SEM_EXPR_FLOAT
 jmp .done_kind
.non_float:
 mov eax,NEBOC_FLOAT_SEM_EXPR_NON_FLOAT
 jmp .done_kind
.unknown:
 mov eax,NEBOC_FLOAT_SEM_EXPR_UNKNOWN
.done_kind:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; float_node_ptr(builder*, node_id) -> pointer or 0
float_node_ptr:
 test rdi,rdi
 jz .node_none
 test rsi,rsi
 jz .node_none
 cmp rsi,[rdi+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .node_none
 mov rax,rsi
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[rdi+NEBOC_AST_BUILDER_DATA_OFFSET]
 ret
.node_none:
 xor eax,eax
 ret

; float_child_chain_contains(builder*, first_node_id, child_count) -> 1/0
float_child_chain_contains:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
.chain_loop:
 test r14,r14
 jz .chain_no
 test r13,r13
 jz .chain_no
 mov rdi,r12
 mov rsi,r13
 call float_subtree_contains
 test eax,eax
 jnz .chain_yes
 mov rdi,r12
 mov rsi,r13
 call float_node_ptr
 test rax,rax
 jz .chain_no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec r14
 jmp .chain_loop
.chain_yes:
 mov eax,1
 jmp .chain_done
.chain_no:
 xor eax,eax
.chain_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; float_subtree_contains(builder*, node_id) -> 1/0
float_subtree_contains:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 test r13,r13
 jz .subtree_no
 mov rdi,r12
 mov rsi,r13
 call float_node_ptr
 test rax,rax
 jz .subtree_no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FLOAT_LITERAL
 je .subtree_yes
 mov rbx,[r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov r13,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test rbx,rbx
 jz .subtree_no
 test r13,r13
 jz .subtree_no
 mov rdi,r12
 mov rsi,r13
 call float_subtree_contains
 test eax,eax
 jnz .subtree_yes
 mov rdi,r12
 mov rsi,r13
 call float_node_ptr
 test rax,rax
 jz .subtree_no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec rbx
 jmp .child_loop
.subtree_yes:
 mov eax,1
 jmp .subtree_done
.subtree_no:
 xor eax,eax
.subtree_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; float_token_is_name(request*, token_index) -> 1 exact "Float", else 0
float_token_is_name:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 cmp r13,[r12+NEBOC_FLOAT_SEM_TOKEN_COUNT_OFFSET]
 jae .name_no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_FLOAT_SEM_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .name_no
 mov rbx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rbx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rbx,float_name_len
 jne .name_no
 mov rsi,[r12+NEBOC_FLOAT_SEM_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel float_name]
 mov rcx,float_name_len
 cld
 repe cmpsb
 jne .name_no
 mov eax,1
 jmp .name_done
.name_no:
 xor eax,eax
.name_done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 cld
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
