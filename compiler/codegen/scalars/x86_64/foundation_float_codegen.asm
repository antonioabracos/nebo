; Nebo Assembly — TIPOS-PRIMITIVOS-ESCALARES-PF005 Float vertical x86-64/SSE2 codegen
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/codegen/scalars/x86_64/foundation_float_codegen.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_foundation_float_materialize_literal

section .rodata
float_fn_prologue:
 db '    push rbp',10
 db '    mov rbp, rsp',10
 db '    sub rsp, 16',10
float_fn_prologue_len equ $-float_fn_prologue
float_fn_epilogue:
 db '    mov rsp, rbp',10
 db '    pop rbp',10
 db '    xor eax, eax',10
 db '    ret',10
float_fn_epilogue_len equ $-float_fn_epilogue
float_literal_prefix: db '    mov rax, '
float_literal_prefix_len equ $-float_literal_prefix
float_literal_suffix: db 10,'    movq xmm0, rax',10
float_literal_suffix_len equ $-float_literal_suffix
float_store_result: db '    movsd [rbp - 8], xmm0',10
float_store_result_len equ $-float_store_result
float_spill_lhs: db '    sub rsp, 16',10,'    movsd [rsp], xmm0',10
float_spill_lhs_len equ $-float_spill_lhs
float_restore_operands: db '    movsd xmm1, xmm0',10,'    movsd xmm0, [rsp]',10,'    add rsp, 16',10
float_restore_operands_len equ $-float_restore_operands
float_add: db '    addsd xmm0, xmm1',10
float_add_len equ $-float_add
float_sub: db '    subsd xmm0, xmm1',10
float_sub_len equ $-float_sub
float_mul: db '    mulsd xmm0, xmm1',10
float_mul_len equ $-float_mul
float_div: db '    divsd xmm0, xmm1',10
float_div_len equ $-float_div
float_neg: db '    movq rax, xmm0',10,'    btc rax, 63',10,'    movq xmm0, rax',10
float_neg_len equ $-float_neg
float_name: db 'Float'
float_name_len equ $-float_name

section .text

; foundation_float_codegen_emit_start(request*)
; The surrounding CLI has already emitted module and entry prelude and has
; opened nebo_fn_1. This function emits the bounded public Float start body.
NEBOC_ABI_FUNCTION neboc_foundation_float_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid_no_record
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_NONE
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],0
 mov qword [r12+NEBOC_FLOAT_CODEGEN_FLAGS_OFFSET],0
 mov qword [r12+NEBOC_FLOAT_CODEGEN_DEPTH_OFFSET],0
 mov qword [r12+NEBOC_FLOAT_CODEGEN_STATEMENT_COUNT_OFFSET],0
 cmp qword [r12+NEBOC_FLOAT_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .depth_ready
 mov qword [r12+NEBOC_FLOAT_CODEGEN_MAX_DEPTH_OFFSET],NEBOC_FLOAT_CODEGEN_MAX_DEPTH_DEFAULT
.depth_ready:
 mov r13,[r12+NEBOC_FLOAT_CODEGEN_BUILDER_OFFSET]
 mov r14,[r12+NEBOC_FLOAT_CODEGEN_WRITER_OFFSET]
 mov r15,[r12+NEBOC_FLOAT_CODEGEN_TOKENS_OFFSET]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 test r15,r15
 jz .invalid
 mov rdi,r13
 mov rsi,[r12+NEBOC_FLOAT_CODEGEN_ROOT_ID_OFFSET]
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0
.decl_loop:
 test rbx,rbx
 jz .decl_done
 mov rdi,r13
 mov rsi,rbx
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 je .unsupported_at_decl
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .decl_next
 cmp qword [rsp],0
 jne .ast
 mov [rsp],rbx
.decl_next:
 mov rax,[rsp+8]
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .decl_loop
.decl_done:
 cmp qword [rsp],0
 je .ast
 mov rdi,r13
 mov rsi,[rsp]
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r13
 mov rsi,rbx
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov [rsp+16],rax
 mov rdi,r12
 lea rsi,[rel float_fn_prologue]
 mov edx,float_fn_prologue_len
 call float_codegen_append
 test eax,eax
 jnz .done
 mov rax,[rsp+16]
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test rbx,rbx
 jz .statements_done
 mov rdi,r12
 mov rsi,rbx
 call float_codegen_emit_statement
 test eax,eax
 jnz .done
 mov rdi,r13
 mov rsi,rbx
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .statement_loop
.statements_done:
 cmp qword [r12+NEBOC_FLOAT_CODEGEN_STATEMENT_COUNT_OFFSET],0
 je .unsupported
 mov rdi,r12
 lea rsi,[rel float_fn_epilogue]
 mov edx,float_fn_epilogue_len
 call float_codegen_append
 test eax,eax
 jnz .done
 mov qword [r12+NEBOC_FLOAT_CODEGEN_FLAGS_OFFSET],NEBOC_FLOAT_CODEGEN_REQUIRED_FLAGS
 xor eax,eax
 jmp .done
.unsupported_at_decl:
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],rbx
.unsupported:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_UNSUPPORTED_CONTEXT
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_BAD_ARGUMENT
.invalid_no_record:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; emit_statement(request*, statement_node_id)
%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
float_codegen_emit_statement:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+NEBOC_FLOAT_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov rbx,rax
 mov rax,[rbx+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_BINDING_STMT
 je .statement_ok
 cmp rax,NEBOC_AST_EXPRESSION_STMT
 jne .unsupported
.statement_ok:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r14
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .expression_ready
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 jmp .have_expression
.expression_ready:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.have_expression:
 mov [rsp],rsi
 mov rdi,r14
 call float_codegen_subtree_contains
 test eax,eax
 jz .non_float_statement
 mov rdi,r12
 mov rsi,[rsp]
 call float_codegen_emit_expression
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel float_store_result]
 mov edx,float_store_result_len
 call float_codegen_append
 test eax,eax
 jnz .done
 inc qword [r12+NEBOC_FLOAT_CODEGEN_STATEMENT_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.non_float_statement:
 ; Side-effecting/control non-Float nodes are rejected by semantic conformance.
 ; Literal-only legacy statements can coexist and need no Float machine code.
 xor eax,eax
 jmp .done
.unsupported:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_UNSUPPORTED_CONTEXT
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_AST
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; emit_expression(request*, node_id) -> XMM0
%undef call
float_codegen_emit_expression:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 inc qword [r12+NEBOC_FLOAT_CODEGEN_DEPTH_OFFSET]
 mov rax,[r12+NEBOC_FLOAT_CODEGEN_DEPTH_OFFSET]
 cmp rax,[r12+NEBOC_FLOAT_CODEGEN_MAX_DEPTH_OFFSET]
 ja .depth
 mov r14,[r12+NEBOC_FLOAT_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rbx,NEBOC_AST_FLOAT_LITERAL
 je .literal
 cmp rbx,NEBOC_AST_CALL_EXPR
 je .constructor
 cmp rbx,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rbx,NEBOC_AST_BINARY_EXPR
 je .binary
 jmp .unsupported

.literal:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rax,[r12+NEBOC_FLOAT_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .ast
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_FLOAT_CODEGEN_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 jne .ast
 mov [rsp],rax
 mov rdi,[r12+NEBOC_FLOAT_CODEGEN_LOWERING_REQUEST_OFFSET]
 test rdi,rdi
 jz .ast
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jbe .literal_error
 sub rdx,rcx
 add rcx,[r12+NEBOC_FLOAT_CODEGEN_SOURCE_OFFSET]
 mov rdi,[r12+NEBOC_FLOAT_CODEGEN_LOWERING_REQUEST_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rcx
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 mov rax,[r12+NEBOC_FLOAT_CODEGEN_LOWERING_BITS_OFFSET]
 test rax,rax
 jz .ast
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .literal_error
 mov rdi,r12
 lea rsi,[rel float_literal_prefix]
 mov edx,float_literal_prefix_len
 call float_codegen_append
 test eax,eax
 jnz .expression_done
 mov rdi,[r12+NEBOC_FLOAT_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+NEBOC_FLOAT_CODEGEN_LOWERING_BITS_OFFSET]
 mov rsi,[rsi]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_error
 mov rdi,r12
 lea rsi,[rel float_literal_suffix]
 mov edx,float_literal_suffix_len
 call float_codegen_append
 jmp .expression_done

.constructor:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .unsupported
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call float_codegen_token_is_float_name
 test eax,eax
 jz .unsupported
 cmp qword [r15+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .unsupported
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call float_codegen_emit_expression
 jmp .expression_done

.unary:
 cmp qword [r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsupported
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call float_codegen_emit_expression
 test eax,eax
 jnz .expression_done
 mov rdi,r12
 lea rsi,[rel float_neg]
 mov edx,float_neg_len
 call float_codegen_append
 jmp .expression_done

.binary:
 mov rax,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 mov rdi,r14
 mov rsi,rax
 call float_codegen_node_ptr
 test rax,rax
 jz .ast
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .ast
 mov [rsp+16],rax
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov [rsp+24],rax
 mov rdi,r12
 mov rsi,[rsp+8]
 call float_codegen_emit_expression
 test eax,eax
 jnz .expression_done
 mov rdi,r12
 lea rsi,[rel float_spill_lhs]
 mov edx,float_spill_lhs_len
 call float_codegen_append
 test eax,eax
 jnz .expression_done
 mov rdi,r12
 mov rsi,[rsp+16]
 call float_codegen_emit_expression
 test eax,eax
 jnz .expression_done
 mov rdi,r12
 lea rsi,[rel float_restore_operands]
 mov edx,float_restore_operands_len
 call float_codegen_append
 test eax,eax
 jnz .expression_done
 mov rax,[rsp+24]
 cmp rax,NEBOC_TOKEN_PLUS
 je .emit_add
 cmp rax,NEBOC_TOKEN_MINUS
 je .emit_sub
 cmp rax,NEBOC_TOKEN_STAR
 je .emit_mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .emit_div
 jmp .unsupported
.emit_add:
 lea rsi,[rel float_add]
 mov edx,float_add_len
 jmp .emit_operator
.emit_sub:
 lea rsi,[rel float_sub]
 mov edx,float_sub_len
 jmp .emit_operator
.emit_mul:
 lea rsi,[rel float_mul]
 mov edx,float_mul_len
 jmp .emit_operator
.emit_div:
 lea rsi,[rel float_div]
 mov edx,float_div_len
.emit_operator:
 mov rdi,r12
 call float_codegen_append
 jmp .expression_done

.depth:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_DEPTH
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .expression_done
.literal_error:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_LITERAL
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .expression_done
.writer_error:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_WRITER
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .expression_done
.unsupported:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_UNSUPPORTED_CONTEXT
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .expression_done
.ast:
 mov qword [r12+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_AST
 mov [r12+NEBOC_FLOAT_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.expression_done:
 dec qword [r12+NEBOC_FLOAT_CODEGEN_DEPTH_OFFSET]
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

float_codegen_append:
 push rbx
 mov rbx,rdi
 mov rdi,[rbx+NEBOC_FLOAT_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jz .append_done
 mov qword [rbx+NEBOC_FLOAT_CODEGEN_ERROR_CODE_OFFSET],NEBOC_FLOAT_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.append_done:
 pop rbx
 ret

float_codegen_node_ptr:
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

float_codegen_subtree_contains:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rdi,r12
 mov rsi,r13
 call float_codegen_node_ptr
 test rax,rax
 jz .no
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FLOAT_LITERAL
 je .yes
 mov rbx,[r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 mov r13,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test rbx,rbx
 jz .no
 test r13,r13
 jz .no
 mov rdi,r12
 mov rsi,r13
 call float_codegen_subtree_contains
 test eax,eax
 jnz .yes
 mov rdi,r12
 mov rsi,r13
 call float_codegen_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec rbx
 jmp .loop
.yes:
 mov eax,1
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

float_codegen_token_is_float_name:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 cmp r13,[r12+NEBOC_FLOAT_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+NEBOC_FLOAT_CODEGEN_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rbx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rbx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rbx,float_name_len
 jne .no
 mov rsi,[r12+NEBOC_FLOAT_CODEGEN_SOURCE_OFFSET]
 add rsi,[rax+NEBOC_TOKEN_START_OFFSET]
 lea rdi,[rel float_name]
 mov rcx,float_name_len
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

section .note.GNU-stack noalloc noexec nowrite progbits
