; Nebo Assembly — MF037 Int/Bool checked value codegen for x86-64
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/core/x86_64/value_codegen.inc"

extern neboc_assembly_writer_validate
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal

section .rodata
vcg_mov_rax: db '    mov rax, '
vcg_mov_rax_len equ $-vcg_mov_rax
vcg_mov_true: db '    mov eax, 1',10
vcg_mov_true_len equ $-vcg_mov_true
vcg_mov_false: db '    xor eax, eax',10
vcg_mov_false_len equ $-vcg_mov_false
vcg_newline: db 10
vcg_newline_len equ $-vcg_newline
vcg_push_rax: db '    push rax',10
vcg_push_rax_len equ $-vcg_push_rax
vcg_restore_binary: db '    mov rcx, rax',10,'    pop rax',10
vcg_restore_binary_len equ $-vcg_restore_binary
vcg_add: db '    add rax, rcx',10,'    jo .nebo_trap_overflow',10
vcg_add_len equ $-vcg_add
vcg_sub: db '    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
vcg_sub_len equ $-vcg_sub
vcg_mul: db '    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
vcg_mul_len equ $-vcg_mul
vcg_neg: db '    neg rax',10,'    jo .nebo_trap_overflow',10
vcg_neg_len equ $-vcg_neg
vcg_not: db '    test rax, rax',10,'    sete al',10,'    movzx eax, al',10
vcg_not_len equ $-vcg_not
vcg_cmp_eq: db '    cmp rax, rcx',10,'    sete al',10,'    movzx eax, al',10
vcg_cmp_eq_len equ $-vcg_cmp_eq
vcg_cmp_ne: db '    cmp rax, rcx',10,'    setne al',10,'    movzx eax, al',10
vcg_cmp_ne_len equ $-vcg_cmp_ne
vcg_cmp_lt: db '    cmp rax, rcx',10,'    setl al',10,'    movzx eax, al',10
vcg_cmp_lt_len equ $-vcg_cmp_lt
vcg_cmp_le: db '    cmp rax, rcx',10,'    setle al',10,'    movzx eax, al',10
vcg_cmp_le_len equ $-vcg_cmp_le
vcg_cmp_gt: db '    cmp rax, rcx',10,'    setg al',10,'    movzx eax, al',10
vcg_cmp_gt_len equ $-vcg_cmp_gt
vcg_cmp_ge: db '    cmp rax, rcx',10,'    setge al',10,'    movzx eax, al',10
vcg_cmp_ge_len equ $-vcg_cmp_ge
vcg_div_prefix: db '    test rcx, rcx',10,'    jz .nebo_trap_division_by_zero',10,'    mov rdx, 0x8000000000000000',10,'    cmp rax, rdx',10,'    jne .nebo_div_ok_'
vcg_div_prefix_len equ $-vcg_div_prefix
vcg_div_mid: db 10,'    cmp rcx, -1',10,'    je .nebo_trap_overflow',10,'.nebo_div_ok_'
vcg_div_mid_len equ $-vcg_div_mid
vcg_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10
vcg_div_tail_len equ $-vcg_div_tail
vcg_mod_tail: db '    mov rax, rdx',10
vcg_mod_tail_len equ $-vcg_mod_tail
vcg_and_branch: db '    test rax, rax',10,'    jz .nebo_bool_false_'
vcg_and_branch_len equ $-vcg_and_branch
vcg_or_branch: db '    test rax, rax',10,'    jnz .nebo_bool_true_'
vcg_or_branch_len equ $-vcg_or_branch
vcg_branch_nl: db 10
vcg_branch_nl_len equ $-vcg_branch_nl
vcg_bool_canon_done: db '    test rax, rax',10,'    setne al',10,'    movzx eax, al',10,'    jmp .nebo_bool_done_'
vcg_bool_canon_done_len equ $-vcg_bool_canon_done
vcg_false_label: db 10,'.nebo_bool_false_'
vcg_false_label_len equ $-vcg_false_label
vcg_false_body: db ':',10,'    xor eax, eax',10,'.nebo_bool_done_'
vcg_false_body_len equ $-vcg_false_body
vcg_true_label: db 10,'.nebo_bool_true_'
vcg_true_label_len equ $-vcg_true_label
vcg_true_body: db ':',10,'    mov eax, 1',10,'.nebo_bool_done_'
vcg_true_body_len equ $-vcg_true_body
vcg_label_end: db ':',10
vcg_label_end_len equ $-vcg_label_end
vcg_return: db '    xor eax, eax',10,'    ret',10
vcg_return_len equ $-vcg_return
vcg_trap_overflow: db '.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
vcg_trap_overflow_len equ $-vcg_trap_overflow
vcg_trap_divzero: db '.nebo_trap_division_by_zero:',10,'    jmp nebo_runtime_trap_division_by_zero',10
vcg_trap_divzero_len equ $-vcg_trap_divzero

section .text

; init(state*, ast_builder*, root_id, assembly_writer*)
NEBOC_ABI_FUNCTION neboc_core_value_codegen_init
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 test rbx,rbx
 jz .invalid
 test r12,r12
 jz .invalid
 test r13,r13
 jz .invalid
 test r14,r14
 jz .invalid
 cmp qword [rbx+NEBOC_CORE_VALUE_CODEGEN_STATE_OFFSET],NEBOC_CORE_VALUE_CODEGEN_STATE_EMPTY
 jne .invalid
 cmp r13,[r12+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .invalid
 mov rdi,r14
 call neboc_assembly_writer_validate
 test eax,eax
 jnz .invalid
 mov [rbx+NEBOC_CORE_VALUE_CODEGEN_BUILDER_OFFSET],r12
 mov [rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET],r14
 mov [rbx+NEBOC_CORE_VALUE_CODEGEN_ROOT_ID_OFFSET],r13
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_MAX_DEPTH_OFFSET],NEBOC_CORE_VALUE_CODEGEN_MAX_DEPTH
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_EXPRESSION_COUNT_OFFSET],0
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],0
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_NONE
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_STATE_OFFSET],NEBOC_CORE_VALUE_CODEGEN_STATE_READY
 xor eax,eax
 jmp .done
.invalid:
 test rbx,rbx
 jz .invalid_return
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; emit_start(state*)
NEBOC_ABI_FUNCTION neboc_core_value_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 cmp qword [rbx+NEBOC_CORE_VALUE_CODEGEN_STATE_OFFSET],NEBOC_CORE_VALUE_CODEGEN_STATE_READY
 jne .state
 mov rsi,[rbx+NEBOC_CORE_VALUE_CODEGEN_ROOT_ID_OFFSET]
 mov rdi,rbx
 call vcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rsi,r12
 mov rdi,rbx
 call vcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .ast
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rsi,r13
 mov rdi,rbx
 call vcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.statement_loop:
 test r12,r12
 jz .tail
 mov rsi,r12
 mov rdi,rbx
 call vcg_node_ptr
 test rax,rax
 jz .ast
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_EXPRESSION_STMT
 jne .unsupported
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call vcg_emit_expr
 test eax,eax
 jnz .done
 inc qword [rbx+NEBOC_CORE_VALUE_CODEGEN_EXPRESSION_COUNT_OFFSET]
 mov r12,r14
 jmp .statement_loop
.tail:
 mov rdi,rbx
 lea rsi,[rel vcg_return]
 mov edx,vcg_return_len
 call vcg_append
 test eax,eax
 jnz .done
 test qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW
 jz .maybe_divzero
 mov rdi,rbx
 lea rsi,[rel vcg_trap_overflow]
 mov edx,vcg_trap_overflow_len
 call vcg_append
 test eax,eax
 jnz .done
.maybe_divzero:
 test qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_DIV_ZERO
 jz .success
 mov rdi,rbx
 lea rsi,[rel vcg_trap_divzero]
 mov edx,vcg_trap_divzero_len
 call vcg_append
 test eax,eax
 jnz .done
.success:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_STATE_OFFSET],NEBOC_CORE_VALUE_CODEGEN_STATE_EMITTED
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_NONE
 xor eax,eax
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.state:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_BAD_STATE
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> status
vcg_emit_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,[rbx+NEBOC_CORE_VALUE_CODEGEN_MAX_DEPTH_OFFSET]
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call vcg_node_ptr
 test rax,rax
 jz .ast
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .integer
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .boolean
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 jmp .unsupported
.integer:
 mov rdi,rbx
 lea rsi,[rel vcg_mov_rax]
 mov edx,vcg_mov_rax_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_newline]
 mov edx,vcg_newline_len
 call vcg_append
 jmp .done
.boolean:
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 je .bool_false
 mov rdi,rbx
 lea rsi,[rel vcg_mov_true]
 mov edx,vcg_mov_true_len
 call vcg_append
 jmp .done
.bool_false:
 mov rdi,rbx
 lea rsi,[rel vcg_mov_false]
 mov edx,vcg_mov_false_len
 call vcg_append
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .ok
 cmp rax,NEBOC_TOKEN_MINUS
 je .unary_minus
 cmp rax,NEBOC_TOKEN_BANG
 je .unary_not
 jmp .unsupported
.unary_minus:
 or qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel vcg_neg]
 mov edx,vcg_neg_len
 call vcg_append
 jmp .done
.unary_not:
 mov rdi,rbx
 lea rsi,[rel vcg_not]
 mov edx,vcg_not_len
 call vcg_append
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 call vcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .ast
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_AND_AND
 je .logical_and
 cmp rax,NEBOC_TOKEN_OR_OR
 je .logical_or
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_push_rax]
 mov edx,vcg_push_rax_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_restore_binary]
 mov edx,vcg_restore_binary_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .add
 cmp rax,NEBOC_TOKEN_MINUS
 je .sub
 cmp rax,NEBOC_TOKEN_STAR
 je .mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .div
 cmp rax,NEBOC_TOKEN_PERCENT
 je .mod
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .eq
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .ne
 cmp rax,NEBOC_TOKEN_LESS
 je .lt
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .le
 cmp rax,NEBOC_TOKEN_GREATER
 je .gt
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 je .ge
 jmp .unsupported
.add:
 or qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel vcg_add]
 mov edx,vcg_add_len
 call vcg_append
 jmp .done
.sub:
 or qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel vcg_sub]
 mov edx,vcg_sub_len
 call vcg_append
 jmp .done
.mul:
 or qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel vcg_mul]
 mov edx,vcg_mul_len
 call vcg_append
 jmp .done
.div:
 xor r15d,r15d
 jmp .division_common
.mod:
 mov r15d,1
.division_common:
 or qword [rbx+NEBOC_CORE_VALUE_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_CORE_VALUE_TRAP_OVERFLOW|NEBOC_CORE_VALUE_TRAP_DIV_ZERO
 mov rdi,rbx
 lea rsi,[rel vcg_div_prefix]
 mov edx,vcg_div_prefix_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_div_mid]
 mov edx,vcg_div_mid_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_div_tail]
 mov edx,vcg_div_tail_len
 call vcg_append
 test eax,eax
 jnz .done
 test r15d,r15d
 jz .ok
 mov rdi,rbx
 lea rsi,[rel vcg_mod_tail]
 mov edx,vcg_mod_tail_len
 call vcg_append
 jmp .done
.eq:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_eq]
 mov edx,vcg_cmp_eq_len
 call vcg_append
 jmp .done
.ne:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_ne]
 mov edx,vcg_cmp_ne_len
 call vcg_append
 jmp .done
.lt:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_lt]
 mov edx,vcg_cmp_lt_len
 call vcg_append
 jmp .done
.le:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_le]
 mov edx,vcg_cmp_le_len
 call vcg_append
 jmp .done
.gt:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_gt]
 mov edx,vcg_cmp_gt_len
 call vcg_append
 jmp .done
.ge:
 mov rdi,rbx
 lea rsi,[rel vcg_cmp_ge]
 mov edx,vcg_cmp_ge_len
 call vcg_append
 jmp .done
.logical_and:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_and_branch]
 mov edx,vcg_and_branch_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_branch_nl]
 mov edx,vcg_branch_nl_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_bool_canon_done]
 mov edx,vcg_bool_canon_done_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_false_label]
 mov edx,vcg_false_label_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_false_body]
 mov edx,vcg_false_body_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_label_end]
 mov edx,vcg_label_end_len
 call vcg_append
 jmp .done
.logical_or:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_or_branch]
 mov edx,vcg_or_branch_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_branch_nl]
 mov edx,vcg_branch_nl_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call vcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel vcg_bool_canon_done]
 mov edx,vcg_bool_canon_done_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_true_label]
 mov edx,vcg_true_label_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_true_body]
 mov edx,vcg_true_body_len
 call vcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel vcg_label_end]
 mov edx,vcg_label_end_len
 call vcg_append
 jmp .done
.depth:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ok:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id -> node pointer or zero
vcg_node_ptr:
 xor eax,eax
 test rdi,rdi
 jz .done
 test rsi,rsi
 jz .done
 mov rcx,[rdi+NEBOC_CORE_VALUE_CODEGEN_BUILDER_OFFSET]
 test rcx,rcx
 jz .done
 cmp rsi,[rcx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .done
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 mov rax,[rcx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rax,rsi
.done:
 ret

; state*, bytes*, length -> status
vcg_append:
 push rbx
 mov rbx,rdi
 mov rdi,[rbx+NEBOC_CORE_VALUE_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jz .done
 mov qword [rbx+NEBOC_CORE_VALUE_CODEGEN_LAST_ERROR_OFFSET],NEBOC_CORE_VALUE_ERROR_WRITER
.done:
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
