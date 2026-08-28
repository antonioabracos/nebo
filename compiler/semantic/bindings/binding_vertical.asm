; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF005 public binding/definite-assignment semantic pass
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/parser/text_char_bytes_api_contract.inc"
%include "compiler/parser/mutable_assignment_parser.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"

section .rodata
n_void: db "Void"
n_void_len equ $-n_void
n_bool: db "Bool"
n_bool_len equ $-n_bool
n_int: db "Int"
n_int_len equ $-n_int
n_text: db "Text"
n_text_len equ $-n_text
n_float: db "Float"
n_float_len equ $-n_float
n_char: db "Char"
n_char_len equ $-n_char
n_bytes: db "Bytes"
n_bytes_len equ $-n_bytes
n_console_type: db "Console"
n_console_type_len equ $-n_console_type
n_console: db "console"
n_console_len equ $-n_console
n_scan: db "scan"
n_scan_len equ $-n_scan
n_to_float: db "toFloat"
n_to_float_len equ $-n_to_float
n_is_finite: db "isFinite"
n_is_finite_len equ $-n_is_finite
n_is_nan: db "isNaN"
n_is_nan_len equ $-n_is_nan
n_is_infinite: db "isInfinite"
n_is_infinite_len equ $-n_is_infinite
n_is_negative_zero: db "isNegativeZero"
n_is_negative_zero_len equ $-n_is_negative_zero
n_byte_length: db "byteLength"
n_byte_length_len equ $-n_byte_length
n_codepoint_count: db "codepointCount"
n_codepoint_count_len equ $-n_codepoint_count
n_codepoint: db "codepoint"
n_codepoint_len equ $-n_codepoint
n_empty: db "empty"
n_empty_len equ $-n_empty
n_from_byte: db "fromByte"
n_from_byte_len equ $-n_from_byte
n_from_values: db "fromValues"
n_from_values_len equ $-n_from_values
n_bit_and: db "bitAnd"
n_bit_and_len equ $-n_bit_and
n_bit_or: db "bitOr"
n_bit_or_len equ $-n_bit_or
n_bit_xor: db "bitXor"
n_bit_xor_len equ $-n_bit_xor
n_bit_not: db "bitNot"
n_bit_not_len equ $-n_bit_not
n_shift_left: db "shiftLeft"
n_shift_left_len equ $-n_shift_left
n_shift_right: db "shiftRight"
n_shift_right_len equ $-n_shift_right
n_test_bit: db "testBit"
n_test_bit_len equ $-n_test_bit
n_with_bit: db "withBit"
n_with_bit_len equ $-n_with_bit

section .text
NEBOC_ABI_FUNCTION neboc_binding_vertical_recognize
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_BRANCH_A_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_BRANCH_B_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_LOOP_SNAPSHOTS_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_LOOP_BODIES_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[r12+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET]
 test rax,rax
 jz .invalid
 cmp qword [r12+NEBOC_VERTICAL_SYMBOL_CAPACITY_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS
 jb .invalid
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_TOKEN_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_HASH_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_CR_001_CLOSED_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_BRANCH_A_COUNT_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_BRANCH_B_COUNT_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_BRANCH_SNAPSHOT_COUNT_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET],0
 mov qword [r12+NEBOC_VERTICAL_LOOP_SNAPSHOT_COUNT_OFFSET],0
 mov rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov [r12+NEBOC_VERTICAL_ROOT_SYMBOLS_OFFSET],rax
 cmp qword [r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET],0
 jne .depth_ready
 mov qword [r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET],NEBOC_VERTICAL_DEFAULT_MAX_DEPTH
.depth_ready:
 ; Typed/mutable bindings remain BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-OWNED.  AUD-002 additionally claims a
 ; program only when a binding terminal coexists with a standalone expression
 ; statement whose direct call is identifier.console().  Literal Console calls
 ; and nested Console/Scan binding chains remain on the historical text_char_unicode_e_bytes route.
 mov qword [rsp+8],0             ; saw binding terminal
 mov qword [rsp+16],0            ; saw canonical console() call
 mov qword [rsp+32],0            ; saw public control-flow statement
 mov rbx,1
.scan:
 cmp rbx,[r13+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .scan_done
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 je .scan_binding
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_EXPRESSION_STMT
 je .scan_expression
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 je .scan_found
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_WHILE_STMT
 je .scan_found
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_LOOP_STMT
 je .scan_found
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BREAK_STMT
 je .scan_found
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CONTINUE_STMT
 je .scan_found
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .scan_if
 jmp .scan_next
.scan_if:
 mov qword [rsp+32],1
 cmp qword [rsp+16],0
 je .scan_next
 jmp .scan_found
.scan_binding:
 mov qword [rsp+8],1
 cmp qword [rsp+16],0
 jne .scan_found
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jnz .scan_found
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r12
 call g05v_type_ref
 test eax,eax
 jnz .scan_found
 ; Inferred binding initializers and discarded expressions share the same
 ; closed core scalar operator contract.  Validate before ownership routing so
 ; consuming the result cannot be the condition that enables type checking.
 mov rdi,r12
 mov rsi,[rsp]
 xor edx,edx
 call g05v_core_discarded_expr_type
 cmp rax,-1
 je .scan_semantic_error
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .scan_next
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_scan]
 mov ecx,n_scan_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call g05v_token_match
 test eax,eax
 jnz .scan_found
 mov rdi,r12
 mov rsi,[rsp]
 call g05v_node_ptr
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call g05v_token_match
 test eax,eax
 jz .scan_next
 jmp .scan_found
.scan_expression:
 ; A result-discarded core scalar expression still owns a semantic contract.
 ; Validate the self-contained Int/Bool/Text subset during classification even
 ; when no binding later claims the program.  Unknown receiver/call families
 ; remain delegated to their established vertical owner.
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+24],rsi
 mov rdi,r12
 xor edx,edx
 call g05v_core_discarded_expr_type
 cmp rax,-1
 je .scan_semantic_error
 ; AUD-002 owns a standalone receiver call whenever the same body contains a
 ; binding and the receiver is one of the closed Text forms that this vertical
 ; can analyze and lower: identifier, literal, or direct Text constructor.
 ;     binding_statement; identifier.console();
 ;     binding_statement; "literal".console();
 ;     binding_statement; Text("literal").console();
 ; A Console call nested inside another expression/binding chain (for example
 ; literal.console().scan().name) remains on the historical Console/Scan path.
 mov rsi,[rsp+24]
 mov rdi,r12
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .scan_next
 mov [rsp+24],rax
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g05v_token_match
 test eax,eax
 jz .scan_next
 mov rax,[rsp+24]
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .scan_console_owned
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 je .scan_console_owned
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .scan_console_owned
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BOOL_LITERAL
 je .scan_console_owned
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .scan_next
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .scan_next
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05v_token_match
 test eax,eax
 jz .scan_next
.scan_console_owned:
 mov qword [rsp+16],1
 cmp qword [rsp+8],0
 jne .scan_found
 cmp qword [rsp+32],0
 je .scan_next
 jmp .scan_found
.scan_semantic_error:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.scan_found:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],1
 jmp .scan_done
.scan_next:
 inc rbx
 jmp .scan
.scan_done:
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 jne .scan_classified
 cmp qword [rsp+8],0
 je .scan_control_console_pair
 cmp qword [rsp+32],0
 jne .scan_mark_found
 cmp qword [rsp+16],0
 jne .scan_mark_found
 jmp .scan_classified
.scan_control_console_pair:
 cmp qword [rsp+32],0
 je .scan_classified
 cmp qword [rsp+16],0
 je .scan_classified
.scan_mark_found:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],1
.scan_classified:
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET],0
 je .finish
 ; Find start() and its materialized block.
 mov rdi,r12
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ROOT_ID_OFFSET]
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .internal
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test r14,r14
 jz .internal
 mov rdi,r12
 mov rsi,r14
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .internal
 mov rdi,r12
 mov rsi,r15
 xor edx,edx
 call g05v_analyze_block
 test eax,eax
 jnz .done
 ; A successful public semantic pass closes the pre-existing Float bypass:
 ; repeated binding is now rejected by the same symbol-state machine.
 mov qword [r12+NEBOC_VERTICAL_CR_001_CLOSED_OFFSET],1
.finish:
 mov rax,1469598103934665603
 mov rcx,1099511628211
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_FOUND_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 imul rax,rcx
 xor rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET]
 imul rax,rcx
 xor rax,[r12+NEBOC_VERTICAL_CR_001_CLOSED_OFFSET]
 imul rax,rcx
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; request*, expression node id, depth -> core TypeId, zero when another
; semantic vertical owns the expression, or -1 after a typed diagnostic.
;
; This classifier-side check is deliberately limited to the closed public
; Int/Bool/Text operator table.  It prevents value-discard from becoming a
; typecheck bypass without preempting Float, Char, Bytes or receiver-call
; verticals whose representation and operator contracts are separate.
g05v_core_discarded_expr_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET]
 jae .internal
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 jmp .unowned
.unary:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_core_discarded_expr_type
 cmp rax,-1
 je .done
 test rax,rax
 jz .unowned
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,NEBOC_TOKEN_MINUS
 je .unary_minus
 cmp rcx,NEBOC_TOKEN_BANG
 jne .type_error_unary
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .type_error_unary
 jmp .bool
.unary_minus:
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .type_error_unary
 jmp .int
.binary:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .internal
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05v_core_discarded_expr_type
 cmp rax,-1
 je .done
 test rax,rax
 jz .unowned
 mov [rsp],rax
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_core_discarded_expr_type
 cmp rax,-1
 je .done
 test rax,rax
 jz .unowned
 mov [rsp+8],rax
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,NEBOC_TOKEN_PLUS
 je .binary_int
 cmp rcx,NEBOC_TOKEN_MINUS
 je .binary_int
 cmp rcx,NEBOC_TOKEN_STAR
 je .binary_int
 cmp rcx,NEBOC_TOKEN_SLASH
 je .binary_int
 cmp rcx,NEBOC_TOKEN_PERCENT
 je .binary_int
 cmp rcx,NEBOC_TOKEN_CARET
 je .binary_int
 cmp rcx,NEBOC_TOKEN_AND_AND
 je .binary_bool
 cmp rcx,NEBOC_TOKEN_OR_OR
 je .binary_bool
 cmp rcx,NEBOC_TOKEN_XOR
 je .binary_xor
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je .binary_equal
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je .binary_equal
 cmp rcx,NEBOC_TOKEN_LESS
 je .binary_order
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je .binary_order
 cmp rcx,NEBOC_TOKEN_GREATER
 je .binary_order
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 jne .type_error_binary
.binary_order:
 cmp qword [rsp],NEBOC_BIND_TYPE_INT
 jne .type_error_binary
 cmp qword [rsp+8],NEBOC_BIND_TYPE_INT
 jne .type_error_binary
 jmp .bool
.binary_equal:
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jne .type_error_binary
 cmp rax,NEBOC_BIND_TYPE_INT
 je .bool
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .bool
 cmp rax,NEBOC_BIND_TYPE_TEXT
 jne .type_error_binary
 jmp .bool
.binary_xor:
 mov rax,[rsp]
 cmp rax,[rsp+8]
 jne .type_error_binary
 cmp rax,NEBOC_BIND_TYPE_INT
 je .int
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .type_error_binary
 jmp .bool
.binary_bool:
 cmp qword [rsp],NEBOC_BIND_TYPE_BOOL
 jne .type_error_binary
 cmp qword [rsp+8],NEBOC_BIND_TYPE_BOOL
 jne .type_error_binary
 jmp .bool
.binary_int:
 cmp qword [rsp],NEBOC_BIND_TYPE_INT
 jne .type_error_binary
 cmp qword [rsp+8],NEBOC_BIND_TYPE_INT
 jne .type_error_binary
 jmp .int
.type_error_unary:
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 jmp .type_error
.type_error_binary:
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
.type_error:
 mov rdi,r12
 mov esi,NEBOC_BIND_DIAG_TYPE_MISMATCH
 call g05v_set_error
 mov rax,-1
 jmp .done
.int:
 mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.text:
 mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.bool:
 mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.unowned:
 xor eax,eax
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov rax,-1
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, block node id, lexical depth -> status
g05v_analyze_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov qword [rsp],0
 cmp r14,[r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET]
 jae .internal
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .internal
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test rbx,rbx
 jz .ok
 cmp qword [rsp],0
 jne .unreachable
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BINDING_STMT
 je .binding
 cmp rcx,NEBOC_AST_ASSIGNMENT_STMT
 je .assignment
 cmp rcx,NEBOC_AST_EXPRESSION_STMT
 je .expression
 cmp rcx,NEBOC_AST_IF_STMT
 je .if
 cmp rcx,NEBOC_AST_WHILE_STMT
 je .while
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .loop_stmt
 cmp rcx,NEBOC_AST_BREAK_STMT
 je .break
 cmp rcx,NEBOC_AST_CONTINUE_STMT
 je .continue
 jmp .next
.binding:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r14
 call g05v_analyze_binding
 test eax,eax
 jnz .done
 jmp .next
.assignment:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r14
 call g05v_analyze_assignment
 test eax,eax
 jnz .done
 jmp .next
.expression:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 mov rdx,r14
 call g05v_expr_type
 cmp rax,-1
 je .error_passthrough
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 jmp .next
.if:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r14
 call g05v_analyze_if
 test eax,eax
 jnz .done
 jmp .next
.while:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r14
 call g05v_analyze_loop
 test eax,eax
 jnz .done
 jmp .next
.loop_stmt:
 mov rdi,r12
 mov rsi,rbx
 mov rdx,r14
 call g05v_analyze_loop
 test eax,eax
 jnz .done
 jmp .next
.break:
 cmp qword [r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET],0
 je .break_outside
 mov qword [rsp],1
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 jmp .next
.continue:
 cmp qword [r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET],0
 je .continue_outside
 mov qword [rsp],1
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 jmp .next
.next:
 mov rbx,r15
 jmp .loop
.ok: xor eax,eax
 jmp .done
.error_passthrough: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.break_outside:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_BREAK_OUTSIDE_LOOP
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.continue_outside:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_CONTINUE_OUTSIDE_LOOP
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unreachable:
 mov rdi,r12
 mov esi,NEBOC_DIAG_LOOP_CFG_INVARIANT
 xor edx,edx
 call g05v_set_error
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, while/loop node id, lexical depth -> status. The body is analyzed
; on the live table to validate every operation. A persistent body catalogue is
; retained for codegen while the separate preheader snapshot is restored: a
; while may execute zero times and loop-local declarations do not escape.
g05v_analyze_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 mov [rsp],rax
 cmp rax,NEBOC_AST_WHILE_STMT
 je .while
 cmp rax,NEBOC_AST_LOOP_STMT
 jne .internal
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .internal
 jmp .body_ready
.while:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .internal
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .error_passthrough
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .condition_type
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .internal
.body_ready:
 mov [rsp+8],rbx
 mov rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov [rsp+16],rax
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rsp+24],rax
 mov rcx,[r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET]
 cmp rcx,NEBOC_VERTICAL_MAX_LOOP_DEPTH
 jae .nesting
 mov rax,[r12+NEBOC_VERTICAL_LOOP_SNAPSHOT_COUNT_OFFSET]
 cmp rax,NEBOC_VERTICAL_MAX_LOOP_DEPTH
 jae .nesting
 mov [rsp+48],rax
 inc qword [r12+NEBOC_VERTICAL_LOOP_SNAPSHOT_COUNT_OFFSET]
 mov rcx,NEBOC_VERTICAL_LOOP_SNAPSHOT_BYTES
 imul rcx,rax
 mov rax,[r12+NEBOC_VERTICAL_LOOP_BODIES_OFFSET]
 add rax,rcx
 mov [rsp+56],rax
 mov rax,[r12+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET]
 mov rcx,[rsp+48]
 mov qword [rax+rcx*8],0
 mov rcx,[r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET]
 mov rax,neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_MAX_SYMBOLS*NEBOC_SYMBOL_RECORD_SIZE
 imul rax,rcx
 add rax,[r12+NEBOC_VERTICAL_LOOP_SNAPSHOTS_OFFSET]
 test rax,rax
 jz .internal
 mov [rsp+32],rax
 mov rdi,[rsp+16]
 mov rsi,rax
 mov rdx,[rsp+24]
 call g05v_copy_records
 inc qword [r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET]
 mov rdi,r12
 mov rsi,[rsp+8]
 lea rdx,[r14+1]
 call g05v_analyze_block
 mov [rsp+40],rax
 dec qword [r12+NEBOC_VERTICAL_LOOP_DEPTH_OFFSET]
 test eax,eax
 jnz .restore_preheader
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rsp+64],rax
 mov rdi,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov rsi,[rsp+56]
 mov rdx,rax
 call g05v_copy_records
 mov rax,[r12+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET]
 mov rcx,[rsp+48]
 mov rdx,[rsp+64]
 mov [rax+rcx*8],rdx
.restore_preheader:
 mov rdi,[rsp+32]
 mov rsi,[rsp+16]
 mov rdx,[rsp+24]
 call g05v_copy_records
 mov rax,[rsp+16]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+24]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+40]
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.condition_type:
 ; The condition AST, not token zero, is the causal semantic span.
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],NEBOC_DIAG_WHILE_CONDITION_TYPE
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_TOKEN_OFFSET],0
 mov rcx,[rax+NEBOC_AST_NODE_START_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_AST_NODE_END_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.nesting:
 mov rdi,r12
 mov esi,NEBOC_DIAG_LOOP_NESTING
 xor edx,edx
 call g05v_set_error
 jmp .done
.error_passthrough:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, binding statement id, depth -> status
g05v_analyze_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .internal
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .internal
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .internal
 mov [rsp],rax
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+8],rcx                  ; name token
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp+16],rsi                 ; value/type node
 mov rdi,r12
 call g05v_type_ref
 mov [rsp+24],rax                 ; declared type or zero
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05v_find_symbol
 mov [rsp+32],rax
 cmp qword [rsp+24],0
 jne .typed
 ; Direct binding or one-shot initialization.
 mov rdi,r12
 mov rsi,[rsp+16]
 mov rdx,r14
 call g05v_expr_type
 cmp rax,-1
 je .error_passthrough
 test rax,rax
 jz .internal
 mov [rsp+40],rax
 mov rbx,[rsp+32]
 mov rax,[rsp]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .existing_binding_allowed
 test rbx,rbx
 jz .existing_binding_allowed
 cmp r14,[rbx+NEBOC_SYMBOL_SCOPE_OFFSET]
 ja .direct
 jmp .duplicate
.existing_binding_allowed:
 test rbx,rbx
 jz .direct
 cmp qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 je .already
 mov rax,[rsp+40]
 cmp rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 jne .mismatch
 mov qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 and qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],~NEBOC_SYMBOL_FLAG_NOT_DEFINITE
 or qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_DEFINITE|NEBOC_SYMBOL_FLAG_INITIALIZED_IN_BRANCH
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05v_token_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+NEBOC_SYMBOL_INIT_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+NEBOC_SYMBOL_INIT_END_OFFSET],rcx
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.direct:
 mov r9,NEBOC_SYMBOL_FLAG_IMMUTABLE|NEBOC_SYMBOL_FLAG_DIRECT|NEBOC_SYMBOL_FLAG_DEFINITE
 mov rax,[rsp]
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_MUTABLE_BINDING
 jz .direct_add
 cmp qword [rsp+40],NEBOC_BIND_TYPE_INT
 je .direct_mutable
 cmp qword [rsp+40],NEBOC_BIND_TYPE_BOOL
 je .direct_mutable
 cmp qword [rsp+40],NEBOC_BIND_TYPE_CHAR
 je .direct_mutable
 cmp qword [rsp+40],NEBOC_BIND_TYPE_FLOAT
 jne .mutable_type
.direct_mutable:
 mov r9,NEBOC_SYMBOL_FLAG_MUTABLE|NEBOC_SYMBOL_FLAG_DIRECT|NEBOC_SYMBOL_FLAG_DEFINITE
.direct_add:
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+40]
 mov rcx,NEBOC_BIND_STATE_INITIALIZED
 mov r8,r14
 call g05v_add_symbol
 test rax,rax
 jz .internal
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.typed:
 cmp qword [rsp+24],NEBOC_BIND_TYPE_VOID
 je .void
 mov rbx,[rsp+32]
 test rbx,rbx
 jz .typed_add
 cmp r14,[rbx+NEBOC_SYMBOL_SCOPE_OFFSET]
 ja .shadow
 jmp .duplicate
.typed_add:
 mov rdi,r12
 mov rsi,[rsp+8]
 mov rdx,[rsp+24]
 mov rcx,NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 mov r8,r14
 mov r9,NEBOC_SYMBOL_FLAG_IMMUTABLE|NEBOC_SYMBOL_FLAG_TYPED
 call g05v_add_symbol
 test rax,rax
 jz .internal
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.already:
 mov esi,NEBOC_BIND_DIAG_ALREADY_INITIALIZED
 jmp .diagnostic
.mismatch:
 mov esi,NEBOC_BIND_DIAG_TYPE_MISMATCH
 jmp .diagnostic
.void:
 mov esi,NEBOC_BIND_DIAG_VOID_FORBIDDEN
 jmp .diagnostic
.shadow:
 mov esi,NEBOC_BIND_DIAG_SHADOWING_FORBIDDEN
 jmp .diagnostic
.duplicate:
 mov esi,NEBOC_BIND_DIAG_DUPLICATE_DECLARATION
 jmp .diagnostic
.mutable_type:
 mov esi,NEBOC_DIAG_MUTABLE_UNSUPPORTED_TYPE
.diagnostic:
 mov rdi,r12
 mov rdx,[rsp+8]
 call g05v_set_error
 jmp .done
.error_passthrough: mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, assignment statement id, lexical depth -> status
g05v_analyze_assignment:
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
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 jne .internal
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g05v_find_symbol
 test rax,rax
 jz .undeclared
 mov [rsp],rax
 test qword [rax+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_MUTABLE
 jz .immutable
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+8],rax
 test rax,rax
 jz .operator_ready
 mov rcx,[rsp]
 cmp qword [rcx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_INT
 jne .compound
 cmp rax,NEBOC_TOKEN_PLUS
 je .operator_ready
 cmp rax,NEBOC_TOKEN_MINUS
 jne .compound
.operator_ready:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .not_lvalue
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .error_passthrough
 mov rcx,[rsp]
 cmp rax,[rcx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 jne .mismatch
 inc qword [rcx+NEBOC_SYMBOL_WRITE_GENERATION_OFFSET]
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.undeclared:
 mov rdi,r12
 mov rsi,rbx
 call g05v_name_in_closed_scope
 test eax,eax
 jnz .out_of_scope
 mov esi,NEBOC_DIAG_ASSIGNMENT_UNDECLARED
 jmp .diagnostic
.out_of_scope:
 mov esi,NEBOC_DIAG_ASSIGNMENT_OUT_OF_SCOPE
 jmp .diagnostic
.immutable:
 mov esi,NEBOC_DIAG_ASSIGNMENT_IMMUTABLE
 jmp .diagnostic
.not_lvalue:
 mov esi,NEBOC_DIAG_ASSIGNMENT_NOT_LVALUE
 jmp .diagnostic
.compound:
 mov esi,NEBOC_DIAG_COMPOUND_UNSUPPORTED
 jmp .diagnostic
.mismatch:
 mov esi,NEBOC_DIAG_ASSIGNMENT_TYPE_MISMATCH
.diagnostic:
 mov rdi,r12
 mov rdx,rbx
 call g05v_set_error
 jmp .done
.error_passthrough:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, if statement id, depth -> status. Every if owns a persistent pair
; of branch snapshots, allocated in semantic traversal order. This keeps nested
; and sequential flow states disjoint while retaining them for codegen.
g05v_analyze_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,112
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET]
 jae .internal
 mov rax,[r12+NEBOC_VERTICAL_BRANCH_SNAPSHOT_COUNT_OFFSET]
 cmp rax,NEBOC_VERTICAL_MAX_BRANCH_SNAPSHOTS
 jae .internal
 cmp qword [r12+NEBOC_VERTICAL_BRANCH_A_COUNTS_OFFSET],0
 je .internal
 cmp qword [r12+NEBOC_VERTICAL_BRANCH_B_COUNTS_OFFSET],0
 je .internal
 mov [rsp+56],rax                ; persistent snapshot index
 inc qword [r12+NEBOC_VERTICAL_BRANCH_SNAPSHOT_COUNT_OFFSET]
 mov rcx,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rcx,rax
 mov rdx,[r12+NEBOC_VERTICAL_BRANCH_A_OFFSET]
 add rdx,rcx
 mov [rsp+64],rdx                ; this if's then table
 mov rdx,[r12+NEBOC_VERTICAL_BRANCH_B_OFFSET]
 add rdx,rcx
 mov [rsp+72],rdx                ; this if's else table
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .internal
 mov [rsp],rax
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .internal
 ; condition must be Bool and reads are checked in the pre-branch state
 mov rdi,r12
 mov rsi,r15
 mov rdx,r14
 call g05v_expr_type
 cmp rax,-1
 je .error_passthrough
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .internal
 mov rdi,r12
 mov rsi,r15
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .internal
 mov [rsp+8],rbx                  ; then block
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+16],rbx                 ; else block/if or zero
 mov rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov [rsp+24],rax                 ; main ptr
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rsp+32],rax                 ; original count
 ; Copy main into both branch tables.
 mov rdi,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov rsi,[rsp+64]
 mov rdx,[rsp+32]
 call g05v_copy_records
 mov rdi,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov rsi,[rsp+72]
 mov rdx,[rsp+32]
 call g05v_copy_records
 ; Then branch.
 mov rax,[rsp+64]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
 mov rdi,r12
 mov rsi,[rsp+8]
 lea rdx,[r14+1]
 call g05v_analyze_block
 test eax,eax
 jnz .restore_error
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rsp+40],rax
 mov [r12+NEBOC_VERTICAL_BRANCH_A_COUNT_OFFSET],rax
 mov rcx,[r12+NEBOC_VERTICAL_BRANCH_A_COUNTS_OFFSET]
 mov rdx,[rsp+56]
 mov [rcx+rdx*8],rax
 ; Else branch or unchanged false path.
 mov rax,[rsp+72]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
 cmp qword [rsp+16],0
 je .else_done
 mov rdi,r12
 mov rsi,[rsp+16]
 call g05v_node_ptr
 test rax,rax
 jz .restore_internal
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .restore_internal
 mov rdi,r12
 mov rsi,[rsp+16]
 lea rdx,[r14+1]
 call g05v_analyze_if
 jmp .else_checked
.else_block:
 mov rdi,r12
 mov rsi,[rsp+16]
 lea rdx,[r14+1]
 call g05v_analyze_block
.else_checked:
 test eax,eax
 jnz .restore_error
.else_done:
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 mov [rsp+48],rax
 mov [r12+NEBOC_VERTICAL_BRANCH_B_COUNT_OFFSET],rax
 mov rcx,[r12+NEBOC_VERTICAL_BRANCH_B_COUNTS_OFFSET]
 mov rdx,[rsp+56]
 mov [rcx+rdx*8],rax
 ; Restore main table and merge only symbols visible before the branch.
 mov rax,[rsp+24]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
 xor r15d,r15d
.merge:
 cmp r15,[rsp+32]
 jae .merged
 mov rax,r15
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 mov rbx,[rsp+24]
 add rbx,rax
 mov rcx,[rsp+64]
 add rcx,rax
 mov rdx,[rsp+72]
 add rdx,rax
 mov rax,[rcx+NEBOC_SYMBOL_WRITE_GENERATION_OFFSET]
 mov rsi,[rdx+NEBOC_SYMBOL_WRITE_GENERATION_OFFSET]
 cmp rax,rsi
 cmovb rax,rsi
 mov [rbx+NEBOC_SYMBOL_WRITE_GENERATION_OFFSET],rax
 cmp qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 je .merge_next
 cmp qword [rcx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne .not_definite
 cmp qword [rdx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 jne .not_definite
 mov qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 and qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],~NEBOC_SYMBOL_FLAG_NOT_DEFINITE
 or qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_DEFINITE
 jmp .merge_next
.not_definite:
 mov qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_DECLARED_UNINITIALIZED
 or qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_NOT_DEFINITE
 and qword [rbx+NEBOC_SYMBOL_FLAGS_OFFSET],~NEBOC_SYMBOL_FLAG_DEFINITE
.merge_next:
 inc r15
 jmp .merge
.merged:
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.restore_error:
 mov rbx,rax
 mov rax,[rsp+24]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
 mov eax,ebx
 jmp .done
.restore_internal:
 mov rax,[rsp+24]
 mov [r12+NEBOC_VERTICAL_SYMBOLS_OFFSET],rax
 mov rax,[rsp+32]
 mov [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET],rax
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.error_passthrough: mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,112
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, expression node id, depth -> TypeId, -1 on diagnosed error
g05v_expr_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+NEBOC_VERTICAL_MAX_DEPTH_OFFSET]
 jae .internal
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .internal
.identifier:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05v_find_symbol
 test rax,rax
 jz .undefined
 cmp qword [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],NEBOC_BIND_STATE_INITIALIZED
 je .identifier_ok
 test qword [rax+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_NOT_DEFINITE
 jnz .not_definite
 mov esi,NEBOC_BIND_DIAG_USE_BEFORE_INITIALIZATION
 jmp .identifier_error
.not_definite:
 mov esi,NEBOC_BIND_DIAG_NOT_DEFINITELY_INITIALIZED
.identifier_error:
 mov rdi,r12
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05v_set_error
 mov rax,-1
 jmp .done
.undefined:
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 call g05v_name_in_closed_scope
 test eax,eax
 jnz .identifier_out_of_scope
 mov rdi,r12
 mov esi,NEBOC_BIND_DIAG_UNDEFINED_NAME
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05v_set_error
 mov rax,-1
 jmp .done
.identifier_out_of_scope:
 mov rdi,r12
 mov esi,NEBOC_DIAG_ASSIGNMENT_OUT_OF_SCOPE
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05v_set_error
 mov rax,-1
 jmp .done
.identifier_ok:
 mov rax,[rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 jmp .done
.unary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05v_expr_type
 jmp .done
.binary:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .internal
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 mov [rsp],rax
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 cmp rax,[rsp]
 jne .binary_type_error
 mov rcx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rcx,NEBOC_TOKEN_EQUAL_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_BANG_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_LESS
 je .bool
 cmp rcx,NEBOC_TOKEN_LESS_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_GREATER
 je .bool
 cmp rcx,NEBOC_TOKEN_GREATER_EQUAL
 je .bool
 cmp rcx,NEBOC_TOKEN_AND_AND
 je .binary_need_bool
 cmp rcx,NEBOC_TOKEN_OR_OR
 je .binary_need_bool
 ; The bounded composition profile lowers checked integer arithmetic.  Reject
 ; non-Int arithmetic structurally instead of letting codegen reinterpret Float,
 ; Text, Char, Bytes or Bool payload bits as signed integers.
 cmp rcx,NEBOC_TOKEN_PLUS
 je .binary_need_int
 cmp rcx,NEBOC_TOKEN_MINUS
 je .binary_need_int
 cmp rcx,NEBOC_TOKEN_STAR
 je .binary_need_int
 cmp rcx,NEBOC_TOKEN_SLASH
 je .binary_need_int
 cmp rcx,NEBOC_TOKEN_PERCENT
 jne .binary_type_error
.binary_need_int:
 cmp qword [rsp],NEBOC_BIND_TYPE_INT
 jne .binary_type_error
 mov rax,NEBOC_BIND_TYPE_INT
 jmp .done
.binary_need_bool:
 cmp qword [rsp],NEBOC_BIND_TYPE_BOOL
 jne .binary_type_error
 mov rax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.binary_type_error:
 mov rdi,r12
 mov esi,NEBOC_BIND_DIAG_TYPE_MISMATCH
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call g05v_set_error
 mov rax,-1
 jmp .done
.call:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g05v_token_match
 test eax,eax
 jnz .call_console
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_scan]
 mov ecx,n_scan_len
 call g05v_token_match
 test eax,eax
 jnz .call_scan
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05v_token_match
 test eax,eax
 jnz .call_bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call g05v_token_match
 test eax,eax
 jnz .call_bit_binary
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call g05v_token_match
 test eax,eax
 jnz .call_bit_binary
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call g05v_token_match
 test eax,eax
 jnz .call_bit_binary
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call g05v_token_match
 test eax,eax
 jnz .call_bit_not
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call g05v_token_match
 test eax,eax
 jnz .call_shift
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call g05v_token_match
 test eax,eax
 jnz .call_shift
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call g05v_token_match
 test eax,eax
 jnz .call_test_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call g05v_token_match
 test eax,eax
 jnz .call_with_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05v_token_match
 test eax,eax
 jnz .call_bytes_constructor
 ; Every seguranca_numerica_conversoes_e_overflow/text_char_unicode_e_bytes foundation API used inside a bindings_constantes_mutabilidade_e_definite_assignment initializer remains arity zero.
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .call_type_error
 ; Bytes.empty() is the sole type-receiver operation in the bounded profile.
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05v_token_match
 test eax,eax
 jnz .call_empty
 ; All other operations use an instance receiver whose type is resolved through
 ; the same bindings_constantes_mutabilidade_e_definite_assignment SymbolTable used for declaration/initialization checks.
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 mov [rsp],rax
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_to_float]
 mov ecx,n_to_float_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_int_float_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_finite]
 mov ecx,n_is_finite_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_float_bool_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_nan]
 mov ecx,n_is_nan_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_float_bool_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_infinite]
 mov ecx,n_is_infinite_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_float_bool_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_negative_zero]
 mov ecx,n_is_negative_zero_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_float_bool_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_text_or_bytes_int_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint_count]
 mov ecx,n_codepoint_count_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_text_int_result
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call g05v_token_match
 test eax,eax
 jnz .call_need_char_int_result
 jmp .internal
.call_console:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .call_type_error
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 cmp rax,NEBOC_BIND_TYPE_TEXT
 je .console
 cmp rax,NEBOC_BIND_TYPE_INT
 je .console
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .call_type_error
.console:
 mov eax,NEBOC_BIND_TYPE_CONSOLE
 jmp .done
.call_scan:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .call_type_error
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 cmp rax,NEBOC_BIND_TYPE_TEXT
 je .text
 cmp rax,NEBOC_BIND_TYPE_CONSOLE
 jne .call_type_error
 jmp .text
.call_bytes_constructor:
 ; TIPOS-PRIMITIVOS-ESCALARES validates exact arity, literal-only arguments and 0..255 range in
 ; the text_char_unicode_e_bytes pass. bindings_constantes_mutabilidade_e_definite_assignment only transports the resulting immutable Bytes type.
 jmp .bytes
.call_bit_binary:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .call_type_error
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_type_error
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_type_error
 jmp .int
.call_bit_not:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],0
 jne .call_type_error
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_type_error
 jmp .int
.call_shift:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .call_arity
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_receiver
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 xor edx,edx
 call g05v_validate_position
 test eax,eax
 jnz ._error
 jmp .int
.call_test_bit:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .call_arity
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_receiver
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 mov edx,1
 call g05v_validate_position
 test eax,eax
 jnz ._error
 jmp .bool
.call_with_bit:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],2
 jne .call_arity
 mov r13,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_INT
 jne .call_receiver
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov r13,rsi
 mov rdi,r12
 mov edx,1
 call g05v_validate_position
 test eax,eax
 jnz ._error
 mov rdi,r12
 mov rsi,r13
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,NEBOC_BIND_TYPE_BOOL
 jne .call_argument
 jmp .int
.call_arity:
 mov esi,NEBOC_DIAG_BITWISE_WRONG_ARITY
 jmp .call_error
.call_receiver:
 mov esi,NEBOC_DIAG_BITWISE_WRONG_RECEIVER
 jmp .call_error
.call_argument:
 mov esi,NEBOC_DIAG_BITWISE_WRONG_ARGUMENT
.call_error:
 mov rdi,r12
 mov rdx,rbx
 call g05v_set_error
._error:
 mov rax,-1
 jmp .done
.call_empty:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05v_type_ref
 cmp rax,NEBOC_BIND_TYPE_BYTES
 jne .call_type_error
 jmp .bytes
.call_need_int_float_result:
 cmp qword [rsp],NEBOC_BIND_TYPE_INT
 jne .call_type_error
 jmp .float
.call_need_float_bool_result:
 cmp qword [rsp],NEBOC_BIND_TYPE_FLOAT
 jne .call_type_error
 jmp .bool
.call_need_text_or_bytes_int_result:
 cmp qword [rsp],NEBOC_BIND_TYPE_TEXT
 je .int
 cmp qword [rsp],NEBOC_BIND_TYPE_BYTES
 jne .call_type_error
 jmp .int
.call_need_text_int_result:
 cmp qword [rsp],NEBOC_BIND_TYPE_TEXT
 jne .call_type_error
 jmp .int
.call_need_char_int_result:
 cmp qword [rsp],NEBOC_BIND_TYPE_CHAR
 jne .call_type_error
 jmp .int
.call_type_error:
 mov rdi,r12
 mov esi,NEBOC_BIND_DIAG_TYPE_MISMATCH
 mov rdx,rbx
 call g05v_set_error
 mov rax,-1
 jmp .done
.constructor:
 ; Pratt direct-call AST stores the constructor type token in payload0 and the
 ; sole argument node directly in first_child.  It does not materialize a type
 ; receiver child or link the argument through next_sibling.
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05v_type_token_ref
 test eax,eax
 jz .internal
 mov [rsp],rax
 ; constructor must have exactly one argument and matching value type
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],1
 jne .internal
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .internal
 mov rdi,r12
 lea rdx,[r14+1]
 call g05v_expr_type
 cmp rax,-1
 je .done
 cmp rax,[rsp]
 jne .internal
 mov rax,[rsp]
 jmp .done
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.float: mov eax,NEBOC_BIND_TYPE_FLOAT
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.char: mov eax,NEBOC_BIND_TYPE_CHAR
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.bytes: mov eax,NEBOC_BIND_TYPE_BYTES
 jmp .done
.internal:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov rax,-1
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, AST node -> TypeId if built-in type reference, else zero
g05v_type_ref:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05v_node_ptr
 test rax,rax
 jz .none
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .none
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_void]
 mov ecx,n_void_len
 call g05v_token_match
 test eax,eax
 jnz .void
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call g05v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call g05v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call g05v_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call g05v_token_match
 test eax,eax
 jnz .char
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call g05v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console_type]
 mov ecx,n_console_type_len
 call g05v_token_match
 test eax,eax
 jnz .console_type
.none: xor eax,eax
 jmp .done
.void: mov eax,NEBOC_BIND_TYPE_VOID
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.float: mov eax,NEBOC_BIND_TYPE_FLOAT
 jmp .done
.char: mov eax,NEBOC_BIND_TYPE_CHAR
 jmp .done
.bytes: mov eax,NEBOC_BIND_TYPE_BYTES
 jmp .done
.console_type: mov eax,NEBOC_BIND_TYPE_CONSOLE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, lexer token index -> TypeId if built-in type name, else zero.
; Pratt type constructors keep the type token in CALL_EXPR payload0.
g05v_type_token_ref:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_void]
 mov ecx,n_void_len
 call g05v_token_match
 test eax,eax
 jnz .void
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call g05v_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call g05v_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05v_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call g05v_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call g05v_token_match
 test eax,eax
 jnz .char
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call g05v_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console_type]
 mov ecx,n_console_type_len
 call g05v_token_match
 test eax,eax
 jnz .console_type
.none: xor eax,eax
 jmp .done
.void: mov eax,NEBOC_BIND_TYPE_VOID
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.float: mov eax,NEBOC_BIND_TYPE_FLOAT
 jmp .done
.char: mov eax,NEBOC_BIND_TYPE_CHAR
 jmp .done
.bytes: mov eax,NEBOC_BIND_TYPE_BYTES
 jmp .done
.console_type: mov eax,NEBOC_BIND_TYPE_CONSOLE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, name token -> symbol record or zero (latest visible record)
g05v_find_symbol:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 test r14,r14
 jz .none
 dec r14
.loop:
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_NAME_TOKEN_OFFSET]
 call g05v_names_equal
 test eax,eax
 jnz .yes
 test r14,r14
 jz .none
 dec r14
 jmp .loop
.yes: mov rax,rbx
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, name token -> 1 iff a closed branch/loop-local declaration exists
; after the current root visibility boundary.
g05v_name_in_closed_scope:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 cmp rax,[r12+NEBOC_VERTICAL_ROOT_SYMBOLS_OFFSET]
 jne .no
 mov r15,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 cmp qword [r12+NEBOC_VERTICAL_BRANCH_A_COUNTS_OFFSET],0
 je .legacy
 cmp qword [r12+NEBOC_VERTICAL_BRANCH_B_COUNTS_OFFSET],0
 je .legacy
 mov qword [rsp],0
.snapshot:
 mov rax,[rsp]
 cmp rax,[r12+NEBOC_VERTICAL_BRANCH_SNAPSHOT_COUNT_OFFSET]
 jae .loop_snapshots
 mov rcx,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rcx,rax
 mov rbx,[r12+NEBOC_VERTICAL_BRANCH_A_OFFSET]
 add rbx,rcx
 mov rdx,[r12+NEBOC_VERTICAL_BRANCH_A_COUNTS_OFFSET]
 mov r14,[rdx+rax*8]
 call g05v_name_in_closed_table
 test eax,eax
 jnz .yes
 mov rax,[rsp]
 mov rcx,NEBOC_VERTICAL_BRANCH_SNAPSHOT_BYTES
 imul rcx,rax
 mov rbx,[r12+NEBOC_VERTICAL_BRANCH_B_OFFSET]
 add rbx,rcx
 mov rdx,[r12+NEBOC_VERTICAL_BRANCH_B_COUNTS_OFFSET]
 mov r14,[rdx+rax*8]
 call g05v_name_in_closed_table
 test eax,eax
 jnz .yes
 inc qword [rsp]
 jmp .snapshot
.legacy:
 mov rbx,[r12+NEBOC_VERTICAL_BRANCH_A_OFFSET]
 mov r14,[r12+NEBOC_VERTICAL_BRANCH_A_COUNT_OFFSET]
 call g05v_name_in_closed_table
 test eax,eax
 jnz .yes
 mov rbx,[r12+NEBOC_VERTICAL_BRANCH_B_OFFSET]
 mov r14,[r12+NEBOC_VERTICAL_BRANCH_B_COUNT_OFFSET]
 call g05v_name_in_closed_table
 test eax,eax
 jnz .yes
.loop_snapshots:
 cmp qword [r12+NEBOC_VERTICAL_LOOP_BODIES_OFFSET],0
 je .no
 cmp qword [r12+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET],0
 je .no
 mov qword [rsp+8],0
.loop_snapshot:
 mov rax,[rsp+8]
 cmp rax,[r12+NEBOC_VERTICAL_LOOP_SNAPSHOT_COUNT_OFFSET]
 jae .no
 mov rcx,NEBOC_VERTICAL_LOOP_SNAPSHOT_BYTES
 imul rcx,rax
 mov rbx,[r12+NEBOC_VERTICAL_LOOP_BODIES_OFFSET]
 add rbx,rcx
 mov rdx,[r12+NEBOC_VERTICAL_LOOP_BODY_COUNTS_OFFSET]
 mov r14,[rdx+rax*8]
 call g05v_name_in_closed_table
 test eax,eax
 jnz .yes
 inc qword [rsp+8]
 jmp .loop_snapshot
.no:
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; R12=request, R13=name token, RBX=table, R14=count, R15=root count.
g05v_name_in_closed_table:
 sub rsp,8
 cmp r14,r15
 jbe .no
 dec r14
.loop:
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 lea rdx,[rbx+rax]
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rdx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_NAME_TOKEN_OFFSET]
 call g05v_names_equal
 test eax,eax
 jnz .done
 cmp r14,r15
 jbe .no
 dec r14
 jmp .loop
.no:
 xor eax,eax
.done:
 add rsp,8
 ret

; request*, name token, type, state, scope, flags -> record or zero
g05v_add_symbol:
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
 mov [rsp],r9
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 cmp rax,[r12+NEBOC_VERTICAL_SYMBOL_CAPACITY_OFFSET]
 jae .none
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov rdi,rax
 mov ecx,NEBOC_SYMBOL_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_NAME_TOKEN_OFFSET],r13
 mov [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],r14
 mov [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_STATE_OFFSET],r15
 mov [rax+NEBOC_SYMBOL_SCOPE_OFFSET],rbx
 mov rcx,[rsp]
 mov [rax+NEBOC_SYMBOL_FLAGS_OFFSET],rcx
 mov rdi,r12
 mov rsi,r13
 call g05v_token_ptr
 test rax,rax
 jz .none
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rax,[r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+NEBOC_VERTICAL_SYMBOLS_OFFSET]
 mov [rax+NEBOC_SYMBOL_DECL_START_OFFSET],rdx
 mov [rax+NEBOC_SYMBOL_DECL_END_OFFSET],rcx
 mov [rax+NEBOC_SYMBOL_INIT_START_OFFSET],rdx
 mov [rax+NEBOC_SYMBOL_INIT_END_OFFSET],rcx
 inc qword [r12+NEBOC_VERTICAL_SYMBOL_COUNT_OFFSET]
 jmp .done
.none: xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; source record array, destination, count
; System V arguments arrive as RDI=source, RSI=destination.  MOVSB uses
; RSI=source and RDI=destination, so swap them before the copy.  Without this,
; the empty branch workspace overwrote the main SymbolTable and branch
; initializers diagnosed the pre-existing binding as undefined.
g05v_copy_records:
 test rdx,rdx
 jz .done
 imul rdx,NEBOC_SYMBOL_RECORD_SIZE
 mov rcx,rdx
 xchg rdi,rsi
 cld
 rep movsb
.done: ret

; request*, node id, 0 for shift count or 1 for bit position -> status.
g05v_validate_position:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 call g05v_node_ptr
 test rax,rax
 jz .internal
 mov rbx,rax
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_INTEGER_LITERAL
 je .literal
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_UNARY_EXPR
 je .range
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .dynamic
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINARY_EXPR
 je .dynamic
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 je .dynamic
 test r14,r14
 jnz .position_type
 mov esi,NEBOC_DIAG_SHIFT_WRONG_TYPE
 jmp .error
.position_type: mov esi,NEBOC_DIAG_POSITION_WRONG_TYPE
 jmp .error
.dynamic:
 test r14,r14
 jnz .position_dynamic
 mov esi,NEBOC_DIAG_SHIFT_DYNAMIC
 jmp .error
.position_dynamic: mov esi,NEBOC_DIAG_POSITION_DYNAMIC
 jmp .error
.range:
 test r14,r14
 jnz .position_range
 mov esi,NEBOC_DIAG_SHIFT_OUT_OF_RANGE
 jmp .error
.position_range: mov esi,NEBOC_DIAG_POSITION_OUT_OF_RANGE
 jmp .error
.literal:
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],63
 ja .range
 xor eax,eax
 jmp .done
.error:
 mov rdi,r12
 mov rdx,[rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call g05v_set_error
 jmp .done
.internal: mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, diag, token -> invalid-source status
g05v_set_error:
 push rbx
 mov rbx,rdi
 mov [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],rsi
 mov [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_TOKEN_OFFSET],rdx
 mov rsi,rdx
 call g05v_token_ptr
 test rax,rax
 jz .internal
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_START_OFFSET],rcx
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_END_OFFSET],rcx
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop rbx
 ret
.internal:
 mov qword [rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_ERROR_INTERNAL
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 pop rbx
 ret

; request*, token index -> token*
g05v_token_ptr:
 cmp rsi,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_TOKENS_OFFSET]
 ret
.none: xor eax,eax
 ret

; request*, node id -> node*
g05v_node_ptr:
 test rsi,rsi
 jz .none
 mov rcx,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_BUILDER_OFFSET]
 cmp rsi,[rcx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 mov rax,[rcx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rax,rsi
 ret
.none: xor eax,eax
 ret

; request*, token index, expected bytes, length -> 1/0
g05v_token_match:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r14,rcx
 call g05v_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,rdx
 cmp rcx,r14
 jne .no
 add rdx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_SOURCE_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,r14
 jae .yes
 mov al,[rdx+rcx]
 cmp al,[rbx+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, token A, token B -> 1/0
g05v_names_equal:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rsi,r13
 call g05v_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call g05v_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov r8,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_VERTICAL_SOURCE_OFFSET]
 add r9,[rax+NEBOC_TOKEN_START_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,rdx
 jae .yes
 mov al,[r8+rcx]
 cmp al,[r9+rcx]
 jne .no
 inc rcx
 jmp .loop
.yes: mov eax,1
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
