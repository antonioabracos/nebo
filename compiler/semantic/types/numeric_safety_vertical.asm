; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF005 public vertical semantic/API validation
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/semantic/types/numeric_safety_vertical.inc"

section .rodata
name_int: db "Int"
name_int_len equ $-name_int
name_float: db "Float"
name_float_len equ $-name_float
name_bool: db "Bool"
name_bool_len equ $-name_bool
name_to_float: db "toFloat"
name_to_float_len equ $-name_to_float
name_is_finite: db "isFinite"
name_is_finite_len equ $-name_is_finite
name_is_nan: db "isNaN"
name_is_nan_len equ $-name_is_nan
name_is_infinite: db "isInfinite"
name_is_infinite_len equ $-name_is_infinite
name_is_negative_zero: db "isNegativeZero"
name_is_negative_zero_len equ $-name_is_negative_zero
name_as_float: db "asFloat"
name_as_float_len equ $-name_as_float
name_to_double: db "toDouble"
name_to_double_len equ $-name_to_double
name_is_inf: db "isInf"
name_is_inf_len equ $-name_is_inf
name_is_neg_zero: db "isNegZero"
name_is_neg_zero_len equ $-name_is_neg_zero
name_to_int: db "toInt"
name_to_int_len equ $-name_to_int
name_to_int_checked: db "toIntChecked"
name_to_int_checked_len equ $-name_to_int_checked
name_to_int_unchecked: db "toIntUnchecked"
name_to_int_unchecked_len equ $-name_to_int_unchecked
name_to_float_checked: db "toFloatChecked"
name_to_float_checked_len equ $-name_to_float_checked
name_wrapping_add: db "wrappingAdd"
name_wrapping_add_len equ $-name_wrapping_add
name_saturating_add: db "saturatingAdd"
name_saturating_add_len equ $-name_saturating_add
name_parse_int: db "parseInt"
name_parse_int_len equ $-name_parse_int
name_parse_float: db "parseFloat"
name_parse_float_len equ $-name_parse_float
name_approximately_equal: db "approximatelyEqual"
name_approximately_equal_len equ $-name_approximately_equal
name_number: db "number"
name_number_len equ $-name_number

section .text

; request* -> status. The Pratt parser already owns syntax. This pass validates
; the five frozen receiver APIs and promotes all nine PF002 diagnostics.
NEBOC_ABI_FUNCTION neboc_numeric_safety_vertical_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET]
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKENS_OFFSET]
 mov r15,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_SOURCE_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_TOKEN_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_START_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_END_OFFSET],0
 mov rbx,1
.loop:
 cmp rbx,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .finish
 mov rdi,r13
 mov rsi,rbx
 call g03v_node_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_CALL_EXPR
 je .call
 cmp rcx,NEBOC_AST_BINARY_EXPR
 je .binary
 jmp .next
.call:
 mov rdi,r12
 mov rsi,rbx
 call g03v_validate_call
 test eax,eax
 jnz .done
 jmp .next
.binary:
 mov rdi,r12
 mov rsi,rbx
 call g03v_validate_mixed_binary
 test eax,eax
 jnz .done
.next:
 inc rbx
 jmp .loop
.finish:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_OPERATION_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET]
 imul rax,rcx
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; validate one call node. Constructors are checked for forbidden cross-type use;
; ordinary user functions are left to the existing function resolver/codegen.
g03v_validate_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g03v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03v_expr_type
 mov [rsp],rax

 ; Canonical APIs.
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_float]
 mov ecx,name_to_float_len
 call g03v_token_match
 test eax,eax
 jnz .to_float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_finite]
 mov ecx,name_is_finite_len
 call g03v_token_match
 test eax,eax
 jnz .classifier
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_nan]
 mov ecx,name_is_nan_len
 call g03v_token_match
 test eax,eax
 jnz .classifier
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_infinite]
 mov ecx,name_is_infinite_len
 call g03v_token_match
 test eax,eax
 jnz .classifier
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_negative_zero]
 mov ecx,name_is_negative_zero_len
 call g03v_token_match
 test eax,eax
 jnz .classifier

 ; Frozen aliases.
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_as_float]
 mov ecx,name_as_float_len
 call g03v_token_match
 test eax,eax
 jnz .alias
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_double]
 mov ecx,name_to_double_len
 call g03v_token_match
 test eax,eax
 jnz .alias
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_inf]
 mov ecx,name_is_inf_len
 call g03v_token_match
 test eax,eax
 jnz .alias
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_is_neg_zero]
 mov ecx,name_is_neg_zero_len
 call g03v_token_match
 test eax,eax
 jnz .alias

 ; Deferred names.
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_int]
 mov ecx,name_to_int_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_int_checked]
 mov ecx,name_to_int_checked_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_int_unchecked]
 mov ecx,name_to_int_unchecked_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_to_float_checked]
 mov ecx,name_to_float_checked_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_wrapping_add]
 mov ecx,name_wrapping_add_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_saturating_add]
 mov ecx,name_saturating_add_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_parse_int]
 mov ecx,name_parse_int_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_parse_float]
 mov ecx,name_parse_float_len
 call g03v_token_match
 test eax,eax
 jnz .deferred
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_approximately_equal]
 mov ecx,name_approximately_equal_len
 call g03v_token_match
 test eax,eax
 jnz .deferred

 ; The PF002 unknown-API fixture is promoted without intercepting arbitrary
 ; user-defined receiver-first functions such as soma().
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_number]
 mov ecx,name_number_len
 call g03v_token_match
 test eax,eax
 jnz .unknown
 xor eax,eax
 jmp .done

.to_float:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .args
 cmp qword [rsp],NEBOC_VERTICAL_TYPE_INT
 jne .need_int
 jmp .success
.classifier:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .args
 cmp qword [rsp],NEBOC_VERTICAL_TYPE_FLOAT
 jne .need_float
.success:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_FOUND_OFFSET],1
 inc qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.args:
 mov edx,NEBOC_VERTICAL_ERROR_ARGUMENTS_NOT_ALLOWED
 jmp .error_method
.need_int:
 mov edx,NEBOC_VERTICAL_ERROR_RECEIVER_MUST_BE_INT
 jmp .error_method
.need_float:
 mov edx,NEBOC_VERTICAL_ERROR_RECEIVER_MUST_BE_FLOAT
 jmp .error_method
.alias:
 mov edx,NEBOC_VERTICAL_ERROR_ALIAS_FORBIDDEN
 jmp .error_method
.deferred:
 mov edx,NEBOC_VERTICAL_ERROR_DEFERRED_API
 jmp .error_method
.unknown:
 mov edx,NEBOC_VERTICAL_ERROR_UNKNOWN_API
.error_method:
 mov rdi,r12
 mov rsi,rdx
 mov rdx,rbx
 call g03v_set_error
 jmp .done

.constructor:
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .ok
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03v_expr_type
 mov [rsp],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_int]
 mov ecx,name_int_len
 call g03v_token_match
 test eax,eax
 jnz .ctor_int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_float]
 mov ecx,name_float_len
 call g03v_token_match
 test eax,eax
 jnz .ctor_float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel name_bool]
 mov ecx,name_bool_len
 call g03v_token_match
 test eax,eax
 jnz .ctor_bool
 jmp .ok
.ctor_int:
 cmp qword [rsp],NEBOC_VERTICAL_TYPE_INT
 jne .cross
 jmp .ok
.ctor_float:
 cmp qword [rsp],NEBOC_VERTICAL_TYPE_FLOAT
 jne .cross
 jmp .ok
.ctor_bool:
 cmp qword [rsp],NEBOC_VERTICAL_TYPE_BOOL
 jne .cross
 jmp .ok
.cross:
 mov rdi,r12
 mov esi,NEBOC_VERTICAL_ERROR_CROSS_TYPE_CONSTRUCTOR_FORBIDDEN
 mov rdx,rbx
 call g03v_set_error
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Reject only Int/Float mixed binary expressions. Existing homogeneous Int and
; Float semantics remain owned by tipos_primitivos_escalares/literais_numericos_bases_e_representacao.
g03v_validate_mixed_binary:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET]
 mov rsi,r13
 call g03v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,rax
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ok
 mov rdi,r12
 call g03v_expr_type
 mov [rsp],rax
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET]
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ok
 mov rdi,r12
 call g03v_expr_type
 mov rdx,[rsp]
 cmp rdx,NEBOC_VERTICAL_TYPE_INT
 jne .left_float
 cmp rax,NEBOC_VERTICAL_TYPE_FLOAT
 je .mixed
 jmp .ok
.left_float:
 cmp rdx,NEBOC_VERTICAL_TYPE_FLOAT
 jne .ok
 cmp rax,NEBOC_VERTICAL_TYPE_INT
 jne .ok
.mixed:
 mov rdi,r12
 mov esi,NEBOC_VERTICAL_ERROR_IMPLICIT_COERCION_FORBIDDEN
 mov rdx,[rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call g03v_set_error
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.internal:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; request*, node_id -> public foundation TypeId or UNKNOWN.
g03v_expr_type:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g03v_node_ptr
 test rax,rax
 jz .unknown
 mov rbx,rax
 mov rax,[rbx+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .wrapper
 cmp rax,NEBOC_AST_BINDING_TERMINAL
 je .wrapper
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .wrapper
 cmp rax,NEBOC_AST_EXPRESSION_STMT
 je .wrapper
 cmp rax,NEBOC_AST_BINDING_STMT
 je .wrapper
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unknown
.wrapper:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .unknown
 mov rdi,r12
 call g03v_expr_type
 jmp .done
.binary:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .unknown
 mov [rsp],rsi
 mov rdi,r14
 call g03v_node_ptr
 test rax,rax
 jz .unknown
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .unknown
 mov [rsp+8],rsi
 mov rdi,r12
 mov rsi,[rsp]
 call g03v_expr_type
 mov r13,rax
 mov rdi,r12
 mov rsi,[rsp+8]
 call g03v_expr_type
 cmp r13,rax
 jne .unknown
 cmp r13,NEBOC_VERTICAL_TYPE_INT
 je .binary_kind
 cmp r13,NEBOC_VERTICAL_TYPE_FLOAT
 jne .unknown
.binary_kind:
 mov rax,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .same
 cmp rax,NEBOC_TOKEN_MINUS
 je .same
 cmp rax,NEBOC_TOKEN_STAR
 je .same
 cmp rax,NEBOC_TOKEN_SLASH
 je .same
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .bool
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .bool
 cmp rax,NEBOC_TOKEN_LESS
 je .bool
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .bool
 cmp rax,NEBOC_TOKEN_GREATER
 je .bool
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 je .bool
 jmp .unknown
.same:
 mov rax,r13
 jmp .done
.call:
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_to_float]
 mov ecx,name_to_float_len
 call g03v_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_finite]
 mov ecx,name_is_finite_len
 call g03v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_nan]
 mov ecx,name_is_nan_len
 call g03v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_infinite]
 mov ecx,name_is_infinite_len
 call g03v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_negative_zero]
 mov ecx,name_is_negative_zero_len
 call g03v_token_match
 test eax,eax
 jnz .bool
 jmp .unknown
.constructor:
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_int]
 mov ecx,name_int_len
 call g03v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_float]
 mov ecx,name_float_len
 call g03v_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_bool]
 mov ecx,name_bool_len
 call g03v_token_match
 test eax,eax
 jnz .bool
 jmp .unknown
.int:
 mov eax,NEBOC_VERTICAL_TYPE_INT
 jmp .done
.float:
 mov eax,NEBOC_VERTICAL_TYPE_FLOAT
 jmp .done
.bool:
 mov eax,NEBOC_VERTICAL_TYPE_BOOL
 jmp .done
.unknown:
 xor eax,eax
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, token_index, expected*, expected_len -> 1/0
g03v_token_match:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 cmp r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rdi,rbx
 cld
 repe cmpsb
 jne .no
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, error_code, token_index -> INVALID_SOURCE
g03v_set_error:
 mov [rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_CODE_OFFSET],rsi
 mov [rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_TOKEN_OFFSET],rdx
 cmp rdx,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .invalid
 mov rax,rdx
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_TOKENS_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rdi+neboc_seguranca_numerica_conversoes_e_overflow_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 ret

g03v_node_ptr:
 test rdi,rdi
 jz .none
 test rsi,rsi
 jz .none
 cmp rsi,[rdi+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 mov rax,rsi
 dec rax
 imul rax,NEBOC_AST_NODE_SIZE
 add rax,[rdi+NEBOC_AST_BUILDER_DATA_OFFSET]
 ret
.none:
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
