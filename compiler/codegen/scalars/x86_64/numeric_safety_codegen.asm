; Nebo Assembly — SEGURANCA-NUMERICA-CONVERSOES-E-OVERFLOW-PF005 public x86-64 numeric-safety codegen
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/codegen/scalars/x86_64/numeric_safety_codegen.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal
extern neboc_foundation_float_materialize_literal

section .rodata
name_int: db "Int"
name_int_len equ $-name_int
name_float: db "Float"
name_float_len equ $-name_float
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
prologue: db '    push rbp',10,'    mov rbp, rsp',10,'    sub rsp, 16',10
prologue_len equ $-prologue
epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    xor eax, eax',10,'    ret',10,'.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
epilogue_len equ $-epilogue
mov_rdi: db '    mov rdi, '
mov_rdi_len equ $-mov_rdi
newline: db 10
newline_len equ $-newline
int_neg: db '    neg rdi',10,'    jo .nebo_trap_overflow',10
int_neg_len equ $-int_neg
float_literal_prefix: db '    mov rax, '
float_literal_prefix_len equ $-float_literal_prefix
float_literal_suffix: db 10,'    movq xmm0, rax',10
float_literal_suffix_len equ $-float_literal_suffix
float_spill: db '    sub rsp, 16',10,'    movsd [rsp], xmm0',10
float_spill_len equ $-float_spill
float_restore: db '    movsd xmm1, xmm0',10,'    movsd xmm0, [rsp]',10,'    add rsp, 16',10
float_restore_len equ $-float_restore
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
call_to_float: db '    call nebo_runtime_numeric_safety_int_to_float',10
call_to_float_len equ $-call_to_float
call_is_finite: db '    call nebo_runtime_numeric_safety_is_finite',10
call_is_finite_len equ $-call_is_finite
call_is_nan: db '    call nebo_runtime_numeric_safety_is_nan',10
call_is_nan_len equ $-call_is_nan
call_is_infinite: db '    call nebo_runtime_numeric_safety_is_infinite',10
call_is_infinite_len equ $-call_is_infinite
call_is_negative_zero: db '    call nebo_runtime_numeric_safety_is_negative_zero',10
call_is_negative_zero_len equ $-call_is_negative_zero

section .text
NEBOC_ABI_FUNCTION neboc_numeric_safety_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET]
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DEPTH_OFFSET],0
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .depth_ok
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_DEFAULT
.depth_ok:
 mov rdi,r13
 mov rsi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ROOT_ID_OFFSET]
 call g03c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 xor r15d,r15d
.find_start:
 test rbx,rbx
 jz .ast
 mov rdi,r13
 mov rsi,rbx
 call g03c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 je .unsupported
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 test r15,r15
 jnz .ast
 mov r15,rbx
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r13
 mov rsi,rbx
 call g03c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov [rsp],rax
 mov rdi,r12
 lea rsi,[rel prologue]
 mov edx,prologue_len
 call g03c_append
 test eax,eax
 jnz .done
 mov rax,[rsp]
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test rbx,rbx
 jz .tail
 mov rdi,r13
 mov rsi,rbx
 call g03c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp+8],rax
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BINDING_STMT
 je .stmt
 cmp rcx,NEBOC_AST_EXPRESSION_STMT
 jne .unsupported
.stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r13
 call g03c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .expr_ready
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.expr_ready:
 mov [rsp+16],rsi
 mov rdi,r12
 call g03c_subtree_has_api
 test eax,eax
 jz .unsupported
 mov rdi,r12
 mov rsi,[rsp+16]
 call g03c_emit_any
 test eax,eax
 jnz .done
.next_stmt:
 mov rbx,r15
 jmp .statement_loop
.tail:
 cmp qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_OPERATION_COUNT_OFFSET],0
 je .unsupported
 mov rdi,r12
 lea rsi,[rel epilogue]
 mov edx,epilogue_len
 call g03c_append
 jmp .done
.unsupported:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
 jmp .done
.invalid:
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

; Emit canonical call; return value remains XMM0 (Float) or RAX (Bool).
g03c_emit_any:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 inc qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DEPTH_OFFSET]
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DEPTH_OFFSET]
 cmp rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_MAX_DEPTH_OFFSET]
 ja .unsupported
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g03c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,rax
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .unsupported
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .unsupported
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_to_float]
 mov ecx,name_to_float_len
 call g03c_token_match
 test eax,eax
 jnz .to_float
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_finite]
 mov ecx,name_is_finite_len
 call g03c_token_match
 test eax,eax
 jnz .finite
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_nan]
 mov ecx,name_is_nan_len
 call g03c_token_match
 test eax,eax
 jnz .nan
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_infinite]
 mov ecx,name_is_infinite_len
 call g03c_token_match
 test eax,eax
 jnz .infinite
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_negative_zero]
 mov ecx,name_is_negative_zero_len
 call g03c_token_match
 test eax,eax
 jnz .negative_zero
 jmp .unsupported
.to_float:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_int
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_to_float]
 mov edx,call_to_float_len
 call g03c_append
 jmp .count
.finite:
 lea r13,[rel call_is_finite]
 mov r14d,call_is_finite_len
 jmp .classifier
.nan:
 lea r13,[rel call_is_nan]
 mov r14d,call_is_nan_len
 jmp .classifier
.infinite:
 lea r13,[rel call_is_infinite]
 mov r14d,call_is_infinite_len
 jmp .classifier
.negative_zero:
 lea r13,[rel call_is_negative_zero]
 mov r14d,call_is_negative_zero_len
.classifier:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_float
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r13
 mov edx,r14d
 call g03c_append
.count:
 test eax,eax
 jnz .done
 inc qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.unsupported:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_UNSUPPORTED
 mov [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_NODE_OFFSET],r13
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 dec qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_DEPTH_OFFSET]
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Emit Int receiver in RDI.
g03c_emit_int:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET]
 mov rsi,r13
 call g03c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,rax
 mov rax,[rbx+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .literal
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .constructor
 jmp .unsupported
.literal:
 mov rdi,r12
 lea rsi,[rel mov_rdi]
 mov edx,mov_rdi_len
 call g03c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g03c_append
 jmp .done
.unary:
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsupported
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_int
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel int_neg]
 mov edx,int_neg_len
 call g03c_append
 jmp .done
.constructor:
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .unsupported
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel name_int]
 mov ecx,name_int_len
 call g03c_token_match
 test eax,eax
 jz .unsupported
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_int
 jmp .done
.writer:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; Emit Float receiver in XMM0.
g03c_emit_float:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,24
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g03c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,rax
 mov rax,[rbx+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .literal
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unsupported
.literal:
 mov rax,[rbx+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .ast
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKENS_OFFSET]
 mov [rsp],rax
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_REQUEST_OFFSET]
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[rsp]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 sub rdx,rcx
 add rcx,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_SOURCE_OFFSET]
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_REQUEST_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rcx
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 mov rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_BITS_OFFSET]
 mov [rdi+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .literal_error
 mov rdi,r12
 lea rsi,[rel float_literal_prefix]
 mov edx,float_literal_prefix_len
 call g03c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 mov rsi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_FLOAT_BITS_OFFSET]
 mov rsi,[rsi]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel float_literal_suffix]
 mov edx,float_literal_suffix_len
 call g03c_append
 jmp .done
.unary:
 cmp qword [rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsupported
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_float
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel float_neg]
 mov edx,float_neg_len
 call g03c_append
 jmp .done
.binary:
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov [rsp],rsi
 mov rdi,r14
 call g03c_node_ptr
 test rax,rax
 jz .ast
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call g03c_emit_float
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel float_spill]
 mov edx,float_spill_len
 call g03c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 call g03c_emit_float
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel float_restore]
 mov edx,float_restore_len
 call g03c_append
 test eax,eax
 jnz .done
 mov rax,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .add
 cmp rax,NEBOC_TOKEN_MINUS
 je .sub
 cmp rax,NEBOC_TOKEN_STAR
 je .mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .div
 jmp .unsupported
.add:
 lea rsi,[rel float_add]
 mov edx,float_add_len
 jmp .op
.sub:
 lea rsi,[rel float_sub]
 mov edx,float_sub_len
 jmp .op
.mul:
 lea rsi,[rel float_mul]
 mov edx,float_mul_len
 jmp .op
.div:
 lea rsi,[rel float_div]
 mov edx,float_div_len
.op:
 mov rdi,r12
 call g03c_append
 jmp .done
.call:
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .constructor
 mov rdi,r12
 mov rsi,r13
 call g03c_emit_any
 jmp .done
.constructor:
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 lea rdx,[rel name_float]
 mov ecx,name_float_len
 call g03c_token_match
 test eax,eax
 jz .unsupported
 mov rdi,r12
 mov rsi,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g03c_emit_float
 jmp .done
.literal_error:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov eax,NEBOC_STATUS_INTERNAL_ERROR
.done:
 add rsp,24
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, node_id -> whether subtree contains a canonical seguranca_numerica_conversoes_e_overflow call.
g03c_subtree_has_api:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_BUILDER_OFFSET]
 mov rdi,r14
 mov rsi,r13
 call g03c_node_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 cmp qword [rbx+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 test qword [rbx+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .children
 mov r13,[rbx+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_to_float]
 mov ecx,name_to_float_len
 call g03c_token_match
 test eax,eax
 jnz .yes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_finite]
 mov ecx,name_is_finite_len
 call g03c_token_match
 test eax,eax
 jnz .yes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_nan]
 mov ecx,name_is_nan_len
 call g03c_token_match
 test eax,eax
 jnz .yes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_infinite]
 mov ecx,name_is_infinite_len
 call g03c_token_match
 test eax,eax
 jnz .yes
 mov rdi,r12
 mov rsi,r13
 lea rdx,[rel name_is_negative_zero]
 mov ecx,name_is_negative_zero_len
 call g03c_token_match
 test eax,eax
 jnz .yes
.children:
 mov r13,[rbx+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rbx,[rbx+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
.child:
 test rbx,rbx
 jz .no
 test r13,r13
 jz .no
 mov rdi,r12
 mov rsi,r13
 call g03c_subtree_has_api
 test eax,eax
 jnz .yes
 mov rdi,r14
 mov rsi,r13
 call g03c_node_ptr
 test rax,rax
 jz .no
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 dec rbx
 jmp .child
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

g03c_append:
 push rdi
 mov rdi,[rdi+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_WRITER_OFFSET_codegen_scalars_x86_64]
 call neboc_assembly_writer_append_bytes
 pop rcx
 test eax,eax
 jz .ret
 mov qword [rcx+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_CODE_OFFSET],neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_ERROR_WRITER
.ret:
 ret

g03c_token_match:
 push rbx
 push r12
 push r13
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 cmp r13,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .no
 mov rax,r13
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_TOKENS_OFFSET]
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov rsi,[r12+neboc_seguranca_numerica_conversoes_e_overflow_CODEGEN_SOURCE_OFFSET]
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
 ret

g03c_node_ptr:
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
