; Interpolation uses ordinary typed AST children and the canonical effect
; policy, then lowers to the same immutable percent-node renderer as format.
%include "compiler/semantic/effect/effect_policy.inc"
extern neboc_policy_evaluate

; RDI state, RSI AST id, RDX depth -> inferred effect mask.
; Calls require an authenticated pure intrinsic owner; unresolved/effectful
; calls fail closed instead of trusting an identifier spelling in raw Text.
fcg_interpolation_effects:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .unknown
 call fcg_node_ptr
 test rax,rax
 jz .unknown
 mov r14,rax
 mov rax,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .pure
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .pure
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .pure
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .pure
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .pure
 cmp rax,NEBOC_AST_MATH_CONSTANT
 je .pure
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .pure
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .children
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .children
 cmp rax,NEBOC_AST_INTERPOLATED_TEXT
 je .children
 cmp rax,NEBOC_AST_INTERPOLATION_VALUE
 je .value
 cmp rax,NEBOC_AST_NAMED_ARGUMENT
 je .children
 cmp rax,NEBOC_AST_STRUCT_CONSTRUCTOR
 je .children
 cmp rax,NEBOC_AST_ARRAY_LITERAL
 je .children
 cmp rax,NEBOC_AST_BLOCK
 je .children
 cmp rax,NEBOC_AST_RETURN_STMT
 je .children
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .children
 cmp rax,NEBOC_AST_EXPRESSION_STMT
 je .children
 cmp rax,NEBOC_AST_IF_STMT
 je .children
 cmp rax,NEBOC_AST_BINDING_STMT
 je .binding
 cmp rax,NEBOC_AST_BINDING_TERMINAL
 je .binding
 cmp rax,NEBOC_AST_CALL_EXPR
 jne .unknown
 mov rdi,rbx
 mov rsi,r12
 call fcg_tuple_call_shape
 test eax,eax
 jz .not_constant_geometry
 mov rdi,rbx
 mov rsi,r12
 call fcg_tensor_shape_info
 cmp eax,1
 je .pure
 mov rdi,rbx
 mov rsi,r12
 call fcg_tensor_peers_info
 test eax,eax
 jnz .pure
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_signature_info
 test eax,eax
 jnz .pure
.not_constant_geometry:
 mov rdi,rbx
 mov rsi,r12
 call fcg_native_text_candidate
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_call_info
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_numeric_call_info
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_vector_info
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_tensor_info
 cmp eax,26
 je .tensor_callback
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 call fcg_matrix_info
 cmp eax,38
 je .unknown
 cmp eax,30
 je .matrix_callback
 test eax,eax
 jnz .children
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r13
 call fcg_interpolation_callee_effects
 test rax,rax
 jnz .done
 jmp .children
.tensor_callback:
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,rbx
 xor edx,edx
 mov ecx,NEBOC_TYPE_ID_FLOAT
 mov r8,rcx
 call fcg_typed_callable_with_receiver
 mov r8,rax
.matrix_callback:
 ; A map is pure only if the resolved typed function body is pure. Merely
 ; passing an identifier is not evidence about the function's effects.
 mov rdi,rbx
 mov rsi,r8
 mov rdx,r13
 call fcg_interpolation_symbol_effects
 test rax,rax
 jnz .done
 jmp .children
.binding:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jnz .unknown
.children:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor r15d,r15d
.child:
 test r12,r12
 jz .joined
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .child_scope_ready
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
.child_scope_ready:
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_interpolation_effects
 or r15,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .unknown
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child
.joined:
 mov rax,r15
 jmp .done
.value:
 ; A profile is compiler metadata, not an evaluated child expression. Its
 ; registry/type/parameter validation remains mandatory in the inner plan.
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_interpolation_effects
 jmp .done
.pure:
 xor eax,eax
 jmp .done
.unknown:
 mov eax,NEBOC_EFFECT_UNSAFE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Resolve the actual typed callee, then inspect its ordinary AST body in an
; isolated lexical state. No identifier spelling grants purity and no callee
; executes during compilation. Recursion remains bounded by the same depth.
fcg_interpolation_symbol_effects:
 mov r9d,1
 jmp fcg_interpolation_function_effects
fcg_interpolation_callee_effects:
 xor r9d,r9d
fcg_interpolation_function_effects:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,NEBOC_FUNCTION_CODEGEN_SIZE
 mov r12,rsi
 mov r13,rdx
 mov r14,r9
 mov rsi,rdi
 mov rdi,rsp
 mov ecx,NEBOC_FUNCTION_CODEGEN_QWORDS
 rep movsq
 mov rbx,rsp
 test r14,r14
 jnz .symbol_given
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 test rax,rax
 jz .unknown
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_CALL_NESTED_OWNER_ID_OFFSET],0
 jne .unknown
 mov r14,rax
 jmp .symbol_ready
.symbol_given:
 mov r14,r12
.symbol_ready:
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .unknown
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15d,2
.decl:
 test r12,r12
 jz .unknown
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .unknown
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .next
 cmp r15,r14
 je .found
 inc r15
.next:
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .decl
.found:
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],r14
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .unknown
 mov r12,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_scope_reset
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_interpolation_effects
 jmp .done
.unknown:
 mov eax,NEBOC_EFFECT_UNSAFE
.done:
 add rsp,NEBOC_FUNCTION_CODEGEN_SIZE
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI state, RSI InterpolatedTextExpr, RDX caller-owned static format frame.
; Literal node KEY records the ordinary Text leaf ID for relocation only.
fcg_interpolation_plan:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,160
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,r13
 xor eax,eax
 mov ecx,TEXT_FORMAT_FRAME_SIZE/8
 rep stosq
 mov qword [rsp],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .type
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor r15d,r15d
.segment:
 test r14,r14
 jz .validate
 cmp r15,PERCENT_MAX_NODES
 jae .limit
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .type
 mov [rsp+8],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .literal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTERPOLATION_VALUE
 jne .type
 cmp qword [rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],2
 ja .type
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor edx,edx
 call fcg_interpolation_effects
 mov [rsp+152],rax
 lea rdi,[rsp+16]
 mov ecx,NEBOC_POLICY_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp+152]
 mov [rsp+16+NEBOC_POLICY_DIRECT_EFFECTS_OFFSET],rax
 mov qword [rsp+16+NEBOC_POLICY_DENY_OFFSET],NEBOC_EFFECT_MASK_KNOWN
 lea rdi,[rsp+16]
 call neboc_policy_evaluate
 test eax,eax
 jnz .effect
 mov rdi,rbx
 mov rsi,r14
 call fcg_format_argument_info
 test eax,eax
 jz .type
 mov rcx,[rsp]
 cmp rcx,PERCENT_MAX_ARGS
 jae .arity
 shl rcx,5
 lea rdx,[r13+TEXT_FORMAT_ARGS+rcx]
 mov [rdx+PERCENT_ARG_KIND],rax
 cmp eax,PERCENT_ARG_FLOAT
 jne .dummy_ready
 mov rax,0x3ff0000000000000
 mov [rdx+PERCENT_ARG_DATA],rax
.dummy_ready:
 imul rdx,r15,PERCENT_NODE_SIZE
 lea rdx,[r13+TEXT_FORMAT_NODES+rdx]
 mov qword [rdx+PERCENT_NODE_KIND],PERCENT_NODE_PLACEHOLDER
 mov qword [rdx+PERCENT_NODE_TYPE],PERCENT_TYPE_VALUE
 mov qword [rdx+PERCENT_NODE_PRECISION],-1
 mov rax,[rsp]
 mov [rdx+PERCENT_NODE_KEY],rax
 inc qword [rsp]
 mov rcx,[rsp]
 dec rcx
 shl rcx,5
 mov rcx,[r13+TEXT_FORMAT_ARGS+rcx+PERCENT_ARG_KIND]
 mov rdi,rbx
 mov rsi,r14
 call fcg_interpolation_profile
 test eax,eax
 jnz .error
 jmp .created
.literal:
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,ecx
 test eax,eax
 jz .next
 shr rcx,32
 mov rdx,rcx
 add rdx,rax
 jc .type
 cmp rdx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .type
 imul rdx,r15,PERCENT_NODE_SIZE
 lea rdx,[r13+TEXT_FORMAT_NODES+rdx]
 mov qword [rdx+PERCENT_NODE_KIND],PERCENT_NODE_LITERAL
 mov [rdx+PERCENT_NODE_LENGTH],rax
 add rcx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 mov [rdx+PERCENT_NODE_DATA],rcx
 mov [rdx+PERCENT_NODE_KEY],r14
.created:
 inc r15
.next:
 mov rax,[rsp+8]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .segment
.validate:
 lea rax,[r13+TEXT_FORMAT_NODES]
 mov [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODES],rax
 mov qword [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_CAP],PERCENT_MAX_NODES
 mov [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_NODE_COUNT],r15
 lea rax,[r13+TEXT_FORMAT_ARGS]
 mov [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARGS],rax
 mov rax,[rsp]
 mov [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_ARG_COUNT],rax
 mov qword [r13+TEXT_FORMAT_REQUEST+PERCENT_REQUEST_CAPACITY],PERCENT_MAX_OUTPUT
 lea rdi,[r13+TEXT_FORMAT_REQUEST]
 call neboc_percent_validate_plan_request
 test eax,eax
 jnz .error
 jmp .done
.type: mov eax,PERCENT_DIAG_TYPE_MISMATCH
 jmp .error
.limit: mov eax,PERCENT_DIAG_OUTPUT_LIMIT
 jmp .error
.arity: mov eax,PERCENT_DIAG_ARITY_MISMATCH
 jmp .error
.effect:
 mov eax,9                      ; compiler-private pure-expression failure
.error:
 mov rdi,rbx
 mov rsi,r12
 call fcg_format_record_error
.done:
 add rsp,160
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%include "compiler/codegen/textual/x86_64/interpolation_profiles.inc"
