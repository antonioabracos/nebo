; Nebo Assembly — BINDINGS-CONSTANTES-MUTABILIDADE-E-DEFINITE-ASSIGNMENT-PF005 public immutable binding codegen
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/lowering/scalars/foundation_float_lowering.inc"
%include "compiler/parser/binding_definite_assignment_contract.inc"
%include "compiler/semantic/bindings/binding_vertical.inc"
%include "compiler/codegen/bindings/x86_64/binding_codegen.inc"
extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_i64_decimal
extern neboc_assembly_writer_append_u64_decimal
extern neboc_foundation_float_materialize_literal
extern neboc_scoped_slots_assign

section .rodata
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
prologue_a: db '    push rbp',10,'    mov rbp, rsp',10,'    sub rsp, '
prologue_a_len equ $-prologue_a
newline: db 10
newline_len equ $-newline
epilogue: db '    mov rsp, rbp',10,'    pop rbp',10,'    xor eax, eax',10,'    ret',10
epilogue_len equ $-epilogue
overflow_trap: db '.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
overflow_trap_len equ $-overflow_trap
mov_rax: db '    mov rax, '
mov_rax_len equ $-mov_rax
mov_eax: db '    mov eax, '
mov_eax_len equ $-mov_eax
movq_xmm0: db '    movq xmm0, rax',10
movq_xmm0_len equ $-movq_xmm0
lea_text: db '    lea rax, [rel nebo_text_desc'
lea_text_len equ $-lea_text
lea_bytes: db '    lea rax, [rel nebo_bytes_desc'
lea_bytes_len equ $-lea_bytes
close_bracket: db ']',10
close_bracket_len equ $-close_bracket
binding_codegen_push_rax: db '    push rax',10
push_rax_len equ $-binding_codegen_push_rax
compound_add: db '    mov rcx, rax',10,'    pop rax',10,'    add rax, rcx',10,'    jo .nebo_trap_overflow',10
compound_add_len equ $-compound_add
compound_sub: db '    mov rcx, rax',10,'    pop rax',10,'    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
compound_sub_len equ $-compound_sub
bit_and: db '    pop rcx',10,'    and rax, rcx',10
bit_and_len equ $-bit_and
bit_or: db '    pop rcx',10,'    or rax, rcx',10
bit_or_len equ $-bit_or
bit_xor: db '    pop rcx',10,'    xor rax, rcx',10
bit_xor_len equ $-bit_xor
bit_not: db '    not rax',10
bit_not_len equ $-bit_not
shift_left: db '    shl rax, '
shift_left_len equ $-shift_left
shift_right: db '    sar rax, '
shift_right_len equ $-shift_right
test_bit: db '    bt rax, '
test_bit_len equ $-test_bit
binding_codegen_test_bit_suffix: db 10,'    setc al',10,'    movzx rax, al',10
test_bit_suffix_len equ $-binding_codegen_test_bit_suffix
with_bit_position: db '    mov ecx, '
with_bit_position_len equ $-with_bit_position
with_bit_suffix: db 10,'    neg rax',10,'    mov rdx, rax',10,'    pop rax',10,'    btr rax, rcx',10,'    mov r8, 1',10,'    shl r8, cl',10,'    and r8, rdx',10,'    or rax, r8',10
with_bit_suffix_len equ $-with_bit_suffix
store_byte: db '    mov [rbp - '
store_byte_len equ $-store_byte
store_byte_suffix: db '], al',10
store_byte_suffix_len equ $-store_byte_suffix
store_dword_suffix: db '], eax',10
store_dword_suffix_len equ $-store_dword_suffix
store_qword_suffix: db '], rax',10
store_qword_suffix_len equ $-store_qword_suffix
store_float_prefix: db '    movsd [rbp - '
store_float_prefix_len equ $-store_float_prefix
store_float_suffix: db '], xmm0',10
store_float_suffix_len equ $-store_float_suffix
load_bool_prefix: db '    movzx eax, byte [rbp - '
load_bool_prefix_len equ $-load_bool_prefix
load_int_prefix: db '    mov rax, [rbp - '
load_int_prefix_len equ $-load_int_prefix
load_char_prefix: db '    mov eax, [rbp - '
load_char_prefix_len equ $-load_char_prefix
load_float_prefix: db '    movsd xmm0, [rbp - '
load_float_prefix_len equ $-load_float_prefix
mem_suffix: db ']',10
mem_suffix_len equ $-mem_suffix
test_rax: db '    test rax, rax',10,'    jz ._else'
test_rax_len equ $-test_rax
jmp_end: db '    jmp ._end'
jmp_end_len equ $-jmp_end
label_else: db '._else'
label_else_len equ $-label_else
label_end: db '._end'
label_end_len equ $-label_end
colon_nl: db ':',10
colon_nl_len equ $-colon_nl
loop_header: db '._loop_header'
loop_header_len equ $-loop_header
loop_exit: db '._loop_exit'
loop_exit_len equ $-loop_exit
loop_test_exit: db '    test rax, rax',10,'    jz ._loop_exit'
loop_test_exit_len equ $-loop_test_exit
loop_jump_header: db '    jmp ._loop_header'
loop_jump_header_len equ $-loop_jump_header
loop_jump_exit: db '    jmp ._loop_exit'
loop_jump_exit_len equ $-loop_jump_exit
mov_rdi_rax: db '    mov rdi, rax',10
mov_rdi_rax_len equ $-mov_rdi_rax
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
call_text_byte_length: db '    call nebo_runtime_textual_text_byte_length',10
call_text_byte_length_len equ $-call_text_byte_length
call_text_codepoint_count: db '    call nebo_runtime_textual_text_codepoint_count',10
call_text_codepoint_count_len equ $-call_text_codepoint_count
call_char_codepoint: db '    call nebo_runtime_textual_char_codepoint',10
call_char_codepoint_len equ $-call_char_codepoint
call_bytes_empty: db '    call nebo_runtime_textual_bytes_empty',10
call_bytes_empty_len equ $-call_bytes_empty
call_bytes_byte_length: db '    call nebo_runtime_textual_bytes_byte_length',10
call_bytes_byte_length_len equ $-call_bytes_byte_length
call_console_publish_text: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_text',10
call_console_publish_text_len equ $-call_console_publish_text
call_console_publish_int: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_int',10
call_console_publish_int_len equ $-call_console_publish_int
call_console_publish_bool: db '    mov rdi, rax',10,'    call nebo_runtime_console_publish_bool',10
call_console_publish_bool_len equ $-call_console_publish_bool
binary_restore: db '    mov rcx, rax',10,'    pop rax',10
binary_restore_len equ $-binary_restore
binary_add: db '    add rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_add_len equ $-binary_add
binary_sub: db '    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_sub_len equ $-binary_sub
binary_mul: db '    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
binary_mul_len equ $-binary_mul
binary_div_prefix: db '    test rcx, rcx',10,'    jz .nebo_trap_division_by_zero',10,'    mov rdx, 0x8000000000000000',10,'    cmp rax, rdx',10,'    jne ._div_ok'
binary_div_prefix_len equ $-binary_div_prefix
binary_div_mid: db 10,'    cmp rcx, -1',10,'    je .nebo_trap_overflow',10,'._div_ok'
binary_div_mid_len equ $-binary_div_mid
binary_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10
binary_div_tail_len equ $-binary_div_tail
binary_mod_tail: db '    mov rax, rdx',10
binary_mod_tail_len equ $-binary_mod_tail
division_trap: db '.nebo_trap_division_by_zero:',10,'    jmp nebo_runtime_trap_division_by_zero',10
division_trap_len equ $-division_trap
neg_rax: db '    neg rax',10,'    jo .nebo_trap_overflow',10
neg_rax_len equ $-neg_rax
not_rax: db '    test rax, rax',10,'    sete al',10,'    movzx eax, al',10
not_rax_len equ $-not_rax
cmp_prefix: db '    push rax',10
cmp_prefix_len equ $-cmp_prefix
cmp_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    sete al',10,'    movzx eax, al',10
cmp_suffix_len equ $-cmp_suffix
cmp_ne_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setne al',10,'    movzx eax, al',10
cmp_ne_suffix_len equ $-cmp_ne_suffix
cmp_lt_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setl al',10,'    movzx eax, al',10
cmp_lt_suffix_len equ $-cmp_lt_suffix
cmp_le_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setle al',10,'    movzx eax, al',10
cmp_le_suffix_len equ $-cmp_le_suffix
cmp_gt_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setg al',10,'    movzx eax, al',10
cmp_gt_suffix_len equ $-cmp_gt_suffix
cmp_ge_suffix: db '    mov rcx, rax',10,'    pop rax',10,'    cmp rax, rcx',10,'    setge al',10,'    movzx eax, al',10
cmp_ge_suffix_len equ $-cmp_ge_suffix

section .text
NEBOC_ABI_FUNCTION neboc_binding_codegen_emit_start
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 test r12,r12
 jz .invalid
 mov r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_BUILDER_OFFSET]
 test r13,r13
 jz .invalid
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 test r14,r14
 jz .invalid
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_NODE_OFFSET],0
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],0
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET],0
 jne .depth_ready
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_DEFAULT
.depth_ready:
 mov rdi,r12
 call neboc_scoped_slots_assign
 test eax,eax
 jnz .done
 ; Find start block.
 mov rdi,r12
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ROOT_ID_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.find_start:
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 je .start
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .find_start
.start:
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 ; Emit frame prologue.
 mov rdi,r12
 lea rsi,[rel prologue_a]
 mov edx,prologue_a_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FRAME_SIZE_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r15
 xor edx,edx
 call g05c_emit_block
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel epilogue]
 mov edx,epilogue_len
 call g05c_append
 test eax,eax
 jnz .done
 cmp qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],0
 je .done
 mov rdi,r12
 lea rsi,[rel overflow_trap]
 mov edx,overflow_trap_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel division_trap]
 mov edx,division_trap_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
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

; request* -> assign aligned rbp-relative offsets to final symbols
g05c_assign_slots:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 xor r13d,r13d
 xor r14d,r14d
.loop:
 cmp r13,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 jae .finish
 mov rax,r13
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .size1
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .size4
 cmp rax,NEBOC_BIND_TYPE_INT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_TEXT
 je .size8
 cmp rax,NEBOC_BIND_TYPE_BYTES
 je .size8
 jmp .bad
.size1: mov ecx,1
 mov edx,1
 jmp .place
.size4: mov ecx,4
 mov edx,4
 jmp .place
.size8: mov ecx,8
 mov edx,8
.place:
 mov eax,r14d
 add eax,edx
 dec ecx
 add eax,ecx
 not ecx
 and eax,ecx
 mov r14d,eax
 mov [rbx+NEBOC_SYMBOL_SLOT_OFFSET],rax
 inc r13
 jmp .loop
.finish:
 mov eax,r14d
 add eax,15
 and eax,-16
 test eax,eax
 jnz .store
 mov eax,16
.store:
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FRAME_SIZE_OFFSET],rax
 xor eax,eax
 jmp .done
.bad:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, block id, depth
g05c_emit_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET]
 jae .unsupported
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .ast
 mov rbx,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test rbx,rbx
 jz .ok
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
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
 je .loop_stmt
 cmp rcx,NEBOC_AST_LOOP_STMT
 je .loop_stmt
 cmp rcx,NEBOC_AST_BREAK_STMT
 je .control
 cmp rcx,NEBOC_AST_CONTINUE_STMT
 je .control
 jmp .unsupported
.binding:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_binding
 jmp .checked
.assignment:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_assignment
 jmp .checked
.expression:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 jmp .checked
.if:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_if
 jmp .checked
.loop_stmt:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_loop
 jmp .checked
.control:
 mov rdi,r12
 mov rsi,rbx
 call g05c_emit_loop_control
.checked:
 test eax,eax
 jnz .done
 mov rbx,r15
 jmp .loop
.ok: xor eax,eax
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, while/loop node id, depth -> status
g05c_emit_loop:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 mov [rsp],rax
 cmp rax,NEBOC_AST_WHILE_STMT
 je .shape
 cmp rax,NEBOC_AST_LOOP_STMT
 jne .ast
.shape:
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 cmp rax,NEBOC_CODEGEN_MAX_LOOP_DEPTH
 jae .unsupported
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_STACK_OFFSET]
 test rcx,rcx
 jz .ast
 mov [rcx+rax*8],r13
 inc qword [r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rdi,r12
 lea rsi,[rel loop_header]
 mov edx,loop_header_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 cmp qword [rsp],NEBOC_AST_WHILE_STMT
 jne .explicit_body
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast_pop
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 lea rsi,[rel loop_test_exit]
 mov edx,loop_test_exit_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast_pop
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast_pop
 jmp .emit_body
.explicit_body:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast_pop
.emit_body:
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_block
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 lea rsi,[rel loop_jump_header]
 mov edx,loop_jump_header_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,r12
 lea rsi,[rel loop_exit]
 mov edx,loop_exit_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer_pop
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .pop_done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
.pop_done:
 mov [rsp+8],rax
 dec qword [r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 mov rax,[rsp+8]
 jmp .done
.writer_pop:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .pop_done
.ast_pop:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .pop_done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, break/continue node id -> status
g05c_emit_loop_control:
 push rbx
 push r12
 push r13
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov rax,[r12+NEBOC_CODEGEN_LOOP_DEPTH_OFFSET]
 test rax,rax
 jz .unsupported
 dec rax
 mov rcx,[r12+NEBOC_CODEGEN_LOOP_STACK_OFFSET]
 test rcx,rcx
 jz .ast
 mov rbx,[rcx+rax*8]
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rax,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_BREAK_STMT
 je .break
 cmp rax,NEBOC_AST_CONTINUE_STMT
 jne .ast
 lea rsi,[rel loop_jump_header]
 mov edx,loop_jump_header_len
 jmp .emit
.break:
 lea rsi,[rel loop_jump_exit]
 mov edx,loop_jump_exit_len
.emit:
 mov rdi,r12
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,rbx
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r13
 pop r12
 pop rbx
 ret

; request*, binding statement, depth
g05c_emit_binding:
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
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .ast
 ; Preserve the terminal AST node ID.  g05c_node_ptr consumes node IDs, not
 ; materialized pointers; storing RAX here made every initialized binding fail
 ; codegen during `neboc check` after the semantic pass had succeeded.
 mov [rsp],rbx
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_type_ref
 test eax,eax
 jnz .typed_no_code
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[rsp+8]
 call g05c_emit_store
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.typed_no_code:
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, assignment statement, depth. Semantic validation already proved a
; mutable local scalar; codegen evaluates RHS once and emits exactly one store.
g05c_emit_assignment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_ASSIGNMENT_STMT
 jne .ast
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 test qword [rax+NEBOC_SYMBOL_FLAGS_OFFSET],NEBOC_SYMBOL_FLAG_MUTABLE
 jz .symbol
 mov [rsp],rax
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov [rsp+8],rax
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rsi,rsi
 jz .ast
 cmp qword [rsp+8],0
 je .emit_rhs
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_load
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
.emit_rhs:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rax,[rsp+8]
 test rax,rax
 jz .store
 cmp rax,NEBOC_TOKEN_PLUS
 je .add
 cmp rax,NEBOC_TOKEN_MINUS
 jne .ast
 mov rdi,r12
 lea rsi,[rel compound_sub]
 mov edx,compound_sub_len
 call g05c_append
 jmp .compound_checked
.add:
 mov rdi,r12
 lea rsi,[rel compound_add]
 mov edx,compound_add_len
 call g05c_append
.compound_checked:
 test eax,eax
 jnz .done
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],1
.store:
 mov rdi,r12
 mov rsi,[rsp]
 call g05c_emit_store
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, if node, depth
g05c_emit_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov [rsp],rax
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 mov [rsp+8],rax
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,r12
 mov rsi,r15
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel test_rax]
 mov edx,test_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,r15
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_A_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_A_COUNT_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 call g05c_emit_block
 mov [rsp+16],rax
 mov rax,[rsp]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+16]
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel jmp_end]
 mov edx,jmp_end_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel label_else]
 mov edx,label_else_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rbx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rbx,rbx
 jz .no_else
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_B_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[r12+NEBOC_CODEGEN_BRANCH_B_COUNT_OFFSET]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 call g05c_emit_block
 mov [rsp+16],rax
 mov rax,[rsp]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET],rax
 mov rax,[rsp+8]
 mov [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET],rax
 mov rax,[rsp+16]
 test eax,eax
 jnz .done
.no_else:
 mov rdi,r12
 lea rsi,[rel label_end]
 mov edx,label_end_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel colon_nl]
 mov edx,colon_nl_len
 call g05c_append
 test eax,eax
 jnz .done
 inc qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_OPERATION_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, expression node, depth
g05c_emit_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 cmp r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_MAX_DEPTH_OFFSET]
 jae .unsupported
 mov rdi,r12
 mov rsi,r13
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .integer
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .boolean
 cmp rax,NEBOC_AST_CHAR_LITERAL
 je .char
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_FLOAT_LITERAL
 je .float
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 jmp .unsupported
.integer:
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.boolean:
 mov rdi,r12
 lea rsi,[rel mov_eax]
 mov edx,mov_eax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.char:
 mov rdi,r12
 lea rsi,[rel mov_eax]
 mov edx,mov_eax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov esi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.text:
 mov rdi,r12
 lea rsi,[rel lea_text]
 mov edx,lea_text_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel close_bracket]
 mov edx,close_bracket_len
 call g05c_append
 jmp .done
.float:
 mov rbx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_REQUEST_OFFSET]
 test rbx,rbx
 jz .literal_bad
 mov rdi,rbx
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 ; FloatLiteral payload0 carries normalized numeric/provenance data. Resolve
 ; the exact source spelling through payload1, the lexer token index, matching
 ; the certified tipos_primitivos_escalares/seguranca_numerica_conversoes_e_overflow Float codegen paths.
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .ast
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKENS_OFFSET]
 mov rdx,[rax+NEBOC_TOKEN_END_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jbe .literal_bad
 sub rdx,rcx
 add rcx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rcx
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_BITS_OFFSET]
 mov [rbx+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 mov rdi,rbx
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .literal_bad
 mov rdi,r12
 lea rsi,[rel mov_rax]
 mov edx,mov_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_FLOAT_BITS_OFFSET]
 mov rsi,[rax]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel movq_xmm0]
 mov edx,movq_xmm0_len
 call g05c_append
 jmp .done
.identifier:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .symbol
 mov rdi,r12
 mov rsi,rax
 call g05c_emit_load
 jmp .done
.unary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_MINUS
 je .neg
 cmp rax,NEBOC_TOKEN_BANG
 je .not
 xor eax,eax
 jmp .done
.neg:
 mov rdi,r12
 lea rsi,[rel neg_rax]
 mov edx,neg_rax_len
 call g05c_append
 jmp .done
.not:
 mov rdi,r12
 lea rsi,[rel not_rax]
 mov edx,not_rax_len
 call g05c_append
 jmp .done
.binary:
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_STAR
 je .binary_supported
 cmp rax,NEBOC_TOKEN_SLASH
 je .binary_supported
 cmp rax,NEBOC_TOKEN_PERCENT
 je .binary_supported
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_LESS
 je .binary_supported
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .binary_supported
 cmp rax,NEBOC_TOKEN_GREATER
 je .binary_supported
 cmp rax,NEBOC_TOKEN_GREATER_EQUAL
 jne .unsupported
.binary_supported:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rbx,rbx
 jz .ast
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel cmp_prefix]
 mov edx,cmp_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 cmp rax,NEBOC_TOKEN_PLUS
 je .binary_add
 cmp rax,NEBOC_TOKEN_MINUS
 je .binary_sub
 cmp rax,NEBOC_TOKEN_STAR
 je .binary_mul
 cmp rax,NEBOC_TOKEN_SLASH
 je .binary_div
 cmp rax,NEBOC_TOKEN_PERCENT
 je .binary_mod
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .cmp_eq
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .cmp_ne
 cmp rax,NEBOC_TOKEN_LESS
 je .cmp_lt
 cmp rax,NEBOC_TOKEN_LESS_EQUAL
 je .cmp_le
 cmp rax,NEBOC_TOKEN_GREATER
 je .cmp_gt
 lea rsi,[rel cmp_ge_suffix]
 mov edx,cmp_ge_suffix_len
 jmp .cmp_emit
.binary_add:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_add]
 mov edx,binary_add_len
 call g05c_append
 jmp .binary_checked_done
.binary_sub:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_sub]
 mov edx,binary_sub_len
 call g05c_append
 jmp .binary_checked_done
.binary_mul:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_mul]
 mov edx,binary_mul_len
 call g05c_append
 jmp .binary_checked_done
.binary_div:
 xor ebx,ebx
 jmp .binary_div_common
.binary_mod:
 mov ebx,1
.binary_div_common:
 lea rsi,[rel binary_restore]
 mov edx,binary_restore_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binary_div_prefix]
 mov edx,binary_div_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel binary_div_mid]
 mov edx,binary_div_mid_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel binary_div_tail]
 mov edx,binary_div_tail_len
 call g05c_append
 test eax,eax
 jnz .done
 test ebx,ebx
 jz .binary_checked_done
 mov rdi,r12
 lea rsi,[rel binary_mod_tail]
 mov edx,binary_mod_tail_len
 call g05c_append
.binary_checked_done:
 test eax,eax
 jnz .done
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_DEPTH_OFFSET],1
 xor eax,eax
 jmp .done
.cmp_eq:
 lea rsi,[rel cmp_suffix]
 mov edx,cmp_suffix_len
 jmp .cmp_emit
.cmp_ne:
 lea rsi,[rel cmp_ne_suffix]
 mov edx,cmp_ne_suffix_len
 jmp .cmp_emit
.cmp_lt:
 lea rsi,[rel cmp_lt_suffix]
 mov edx,cmp_lt_suffix_len
 jmp .cmp_emit
.cmp_le:
 lea rsi,[rel cmp_le_suffix]
 mov edx,cmp_le_suffix_len
 jmp .cmp_emit
.cmp_gt:
 lea rsi,[rel cmp_gt_suffix]
 mov edx,cmp_gt_suffix_len
.cmp_emit:
 call g05c_append
 jmp .done
.call:
 test qword [r15+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .method
 ; Pratt direct-call AST stores the sole constructor argument directly in
 ; first_child; there is no synthetic type-receiver child or next sibling.
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 jmp .done
.method:
 mov rbx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console]
 mov ecx,n_console_len
 call g05c_token_match
 test eax,eax
 jnz .method_console
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05c_token_match
 test eax,eax
 jnz .method_bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_and]
 mov ecx,n_bit_and_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_and
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_or]
 mov ecx,n_bit_or_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_or
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_xor]
 mov ecx,n_bit_xor_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_xor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bit_not]
 mov ecx,n_bit_not_len
 call g05c_token_match
 test eax,eax
 jnz .method_bit_not
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_left]
 mov ecx,n_shift_left_len
 call g05c_token_match
 test eax,eax
 jnz .method_shift_left
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_shift_right]
 mov ecx,n_shift_right_len
 call g05c_token_match
 test eax,eax
 jnz .method_shift_right
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_test_bit]
 mov ecx,n_test_bit_len
 call g05c_token_match
 test eax,eax
 jnz .method_test_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_with_bit]
 mov ecx,n_with_bit_len
 call g05c_token_match
 test eax,eax
 jnz .method_with_bit
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05c_token_match
 test eax,eax
 jnz .method_bytes_constructor
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05c_token_match
 test eax,eax
 jnz .method_empty
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_to_float]
 mov ecx,n_to_float_len
 call g05c_token_match
 test eax,eax
 jnz .method_to_float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_finite]
 mov ecx,n_is_finite_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_finite
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_nan]
 mov ecx,n_is_nan_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_nan
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_infinite]
 mov ecx,n_is_infinite_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_infinite
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_is_negative_zero]
 mov ecx,n_is_negative_zero_len
 call g05c_token_match
 test eax,eax
 jnz .method_is_negative_zero
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_byte_length]
 mov ecx,n_byte_length_len
 call g05c_token_match
 test eax,eax
 jnz .method_byte_length
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint_count]
 mov ecx,n_codepoint_count_len
 call g05c_token_match
 test eax,eax
 jnz .method_codepoint_count
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_codepoint]
 mov ecx,n_codepoint_len
 call g05c_token_match
 test eax,eax
 jnz .method_codepoint
 jmp .unsupported
.method_console:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_receiver_type
 test eax,eax
 jz .unsupported
 mov ebx,eax
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp ebx,NEBOC_BIND_TYPE_TEXT
 je .method_console_text
 cmp ebx,NEBOC_BIND_TYPE_INT
 je .method_console_int
 cmp ebx,NEBOC_BIND_TYPE_BOOL
 jne .unsupported
 lea rsi,[rel call_console_publish_bool]
 mov edx,call_console_publish_bool_len
 jmp .method_console_emit
.method_console_text:
 lea rsi,[rel call_console_publish_text]
 mov edx,call_console_publish_text_len
 jmp .method_console_emit
.method_console_int:
 lea rsi,[rel call_console_publish_int]
 mov edx,call_console_publish_int_len
.method_console_emit:
 call g05c_append
 jmp .done
.method_bytes_constructor:
 mov rdi,r12
 lea rsi,[rel lea_bytes]
 mov edx,lea_bytes_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel close_bracket]
 mov edx,close_bracket_len
 call g05c_append
 jmp .done
.method_bit_and:
 mov r13d,1
 jmp .method_bit_binary
.method_bit_or:
 mov r13d,2
 jmp .method_bit_binary
.method_bit_xor:
 mov r13d,3
.method_bit_binary:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 cmp r13,1
 je .method_emit_and
 cmp r13,2
 je .method_emit_or
 lea rsi,[rel bit_xor]
 mov edx,bit_xor_len
 jmp .method_emit_bit
.method_emit_and:
 lea rsi,[rel bit_and]
 mov edx,bit_and_len
 jmp .method_emit_bit
.method_emit_or:
 lea rsi,[rel bit_or]
 mov edx,bit_or_len
.method_emit_bit:
 call g05c_append
 jmp .done
.method_bit_not:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel bit_not]
 mov edx,bit_not_len
 call g05c_append
 jmp .done
.method_shift_left:
 mov r13d,1
 jmp .method_bit_position
.method_shift_right:
 mov r13d,2
 jmp .method_bit_position
.method_test_bit:
 mov r13d,3
.method_bit_position:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rdi,r12
 cmp r13,1
 je .method_emit_shift_left
 cmp r13,2
 je .method_emit_shift_right
 lea rsi,[rel test_bit]
 mov edx,test_bit_len
 jmp .method_emit_position_prefix
.method_emit_shift_left:
 lea rsi,[rel shift_left]
 mov edx,shift_left_len
 jmp .method_emit_position_prefix
.method_emit_shift_right:
 lea rsi,[rel shift_right]
 mov edx,shift_right_len
.method_emit_position_prefix:
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 cmp r13,3
 jne .method_emit_position_newline
 lea rsi,[rel binding_codegen_test_bit_suffix]
 mov edx,test_bit_suffix_len
 call g05c_append
 jmp .done
.method_emit_position_newline:
 lea rsi,[rel newline]
 mov edx,newline_len
 call g05c_append
 jmp .done
.method_with_bit:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel binding_codegen_push_rax]
 mov edx,push_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 call g05c_node_ptr
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdi,r12
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel with_bit_position]
 mov edx,with_bit_position_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel with_bit_suffix]
 mov edx,with_bit_suffix_len
 call g05c_append
 jmp .done
.method_empty:
 mov rdi,r12
 lea rsi,[rel call_bytes_empty]
 mov edx,call_bytes_empty_len
 call g05c_append
 jmp .done
.method_to_float:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_to_float]
 mov edx,call_to_float_len
 call g05c_append
 jmp .done
.method_is_finite:
 lea rbx,[rel call_is_finite]
 mov r13d,call_is_finite_len
 jmp .method_classifier
.method_is_nan:
 lea rbx,[rel call_is_nan]
 mov r13d,call_is_nan_len
 jmp .method_classifier
.method_is_infinite:
 lea rbx,[rel call_is_infinite]
 mov r13d,call_is_infinite_len
 jmp .method_classifier
.method_is_negative_zero:
 lea rbx,[rel call_is_negative_zero]
 mov r13d,call_is_negative_zero_len
.method_classifier:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 mov edx,r13d
 call g05c_append
 jmp .done
.method_byte_length:
 mov rbx,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 call g05c_receiver_is_bytes
 test eax,eax
 jnz .method_bytes_length_call
 mov rdi,r12
 lea rsi,[rel call_text_byte_length]
 mov edx,call_text_byte_length_len
 call g05c_append
 jmp .done
.method_bytes_length_call:
 mov rdi,r12
 lea rsi,[rel call_bytes_byte_length]
 mov edx,call_bytes_byte_length_len
 call g05c_append
 jmp .done
.method_codepoint_count:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_text_codepoint_count]
 mov edx,call_text_codepoint_count_len
 call g05c_append
 jmp .done
.method_codepoint:
 mov rdi,r12
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r14+1]
 call g05c_emit_expr
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel mov_rdi_rax]
 mov edx,mov_rdi_rax_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,r12
 lea rsi,[rel call_char_codepoint]
 mov edx,call_char_codepoint_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.literal_bad:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.symbol:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_SYMBOL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_UNSUPPORTED
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; request*, symbol record -> store current value
g05c_emit_store:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .float
 mov rdi,r12
 lea rsi,[rel store_byte]
 mov edx,store_byte_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .byte_suffix
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .dword_suffix
 mov rdi,r12
 lea rsi,[rel store_qword_suffix]
 mov edx,store_qword_suffix_len
 call g05c_append
 jmp .done
.byte_suffix:
 mov rdi,r12
 lea rsi,[rel store_byte_suffix]
 mov edx,store_byte_suffix_len
 call g05c_append
 jmp .done
.dword_suffix:
 mov rdi,r12
 lea rsi,[rel store_dword_suffix]
 mov edx,store_dword_suffix_len
 call g05c_append
 jmp .done
.float:
 mov rdi,r12
 lea rsi,[rel store_float_prefix]
 mov edx,store_float_prefix_len
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel store_float_suffix]
 mov edx,store_float_suffix_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, symbol record -> load value
g05c_emit_load:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rax,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 cmp rax,NEBOC_BIND_TYPE_BOOL
 je .bool
 cmp rax,NEBOC_BIND_TYPE_CHAR
 je .char
 cmp rax,NEBOC_BIND_TYPE_FLOAT
 je .float
 lea rsi,[rel load_int_prefix]
 mov edx,load_int_prefix_len
 jmp .prefix
.bool: lea rsi,[rel load_bool_prefix]
 mov edx,load_bool_prefix_len
 jmp .prefix
.char: lea rsi,[rel load_char_prefix]
 mov edx,load_char_prefix_len
 jmp .prefix
.float: lea rsi,[rel load_float_prefix]
 mov edx,load_float_prefix_len
.prefix:
 mov rdi,r12
 call g05c_append
 test eax,eax
 jnz .done
 mov rdi,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 mov rsi,[rbx+NEBOC_SYMBOL_SLOT_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,r12
 lea rsi,[rel mem_suffix]
 mov edx,mem_suffix_len
 call g05c_append
 jmp .done
.writer:
 mov qword [r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_CODE_OFFSET],neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, name token -> symbol
g05c_find_symbol:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOL_COUNT_OFFSET]
 test r14,r14
 jz .none
 dec r14
.loop:
 mov rax,r14
 imul rax,NEBOC_SYMBOL_RECORD_SIZE
 add rax,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SYMBOLS_OFFSET]
 mov rbx,rax
 mov rdi,r12
 mov rsi,r13
 mov rdx,[rbx+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_NAME_TOKEN_OFFSET]
 call g05c_names_equal
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

; request*, node -> built-in TypeId or zero
g05c_type_ref:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .none
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 jne .none
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bool]
 mov ecx,n_bool_len
 call g05c_token_match
 test eax,eax
 jnz .bool
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_int]
 mov ecx,n_int_len
 call g05c_token_match
 test eax,eax
 jnz .int
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_text]
 mov ecx,n_text_len
 call g05c_token_match
 test eax,eax
 jnz .text
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_float]
 mov ecx,n_float_len
 call g05c_token_match
 test eax,eax
 jnz .float
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_char]
 mov ecx,n_char_len
 call g05c_token_match
 test eax,eax
 jnz .char
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_bytes]
 mov ecx,n_bytes_len
 call g05c_token_match
 test eax,eax
 jnz .bytes
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_console_type]
 mov ecx,n_console_type_len
 call g05c_token_match
 test eax,eax
 jnz .console_type
.none: xor eax,eax
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

; request*, receiver node -> semantic scalar kind used by typed Console ABI.
g05c_receiver_type:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .none
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rcx,NEBOC_AST_UNARY_EXPR
 je .int
 cmp rcx,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rcx,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rcx,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rcx,NEBOC_AST_BINARY_EXPR
 jne .none
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
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
 jmp .int
.identifier:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .none
 mov rax,[rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET]
 jmp .done
.int: mov eax,NEBOC_BIND_TYPE_INT
 jmp .done
.bool: mov eax,NEBOC_BIND_TYPE_BOOL
 jmp .done
.text: mov eax,NEBOC_BIND_TYPE_TEXT
 jmp .done
.none: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, receiver node -> eax=1 when the validated receiver is Bytes.
g05c_receiver_is_bytes:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rbx,rsi
 mov rdi,r12
 mov rsi,rbx
 call g05c_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .no
 test qword [rax+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .no
 mov rbx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_empty]
 mov ecx,n_empty_len
 call g05c_token_match
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_byte]
 mov ecx,n_from_byte_len
 call g05c_token_match
 test eax,eax
 jnz .done
 mov rdi,r12
 mov rsi,rbx
 lea rdx,[rel n_from_values]
 mov ecx,n_from_values_len
 call g05c_token_match
 jmp .done
.identifier:
 mov rdi,r12
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call g05c_find_symbol
 test rax,rax
 jz .no
 cmp qword [rax+neboc_bindings_constantes_mutabilidade_e_definite_assignment_SYMBOL_TYPE_OFFSET],NEBOC_BIND_TYPE_BYTES
 sete al
 movzx eax,al
 jmp .done
.no: xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; request*, token -> token*
g05c_token_ptr:
 cmp rsi,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .none
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_TOKENS_OFFSET]
 ret
.none: xor eax,eax
 ret

; request*, node -> node*
g05c_node_ptr:
 test rsi,rsi
 jz .none
 mov rcx,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_BUILDER_OFFSET]
 cmp rsi,[rcx+NEBOC_AST_BUILDER_COUNT_OFFSET]
 ja .none
 dec rsi
 imul rsi,NEBOC_AST_NODE_SIZE
 mov rax,[rcx+NEBOC_AST_BUILDER_DATA_OFFSET]
 add rax,rsi
 ret
.none: xor eax,eax
 ret

; request*, token, expected*, length -> 1/0
g05c_token_match:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov r14,rcx
 call g05c_token_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .no
 mov rdx,[rax+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,rdx
 cmp rcx,r14
 jne .no
 add rdx,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
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
g05c_names_equal:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rsi,r13
 call g05c_token_ptr
 test rax,rax
 jz .no
 mov rbx,rax
 mov rdi,r12
 mov rsi,r14
 call g05c_token_ptr
 test rax,rax
 jz .no
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rcx,[rax+NEBOC_TOKEN_END_OFFSET]
 sub rcx,[rax+NEBOC_TOKEN_START_OFFSET]
 cmp rdx,rcx
 jne .no
 mov r8,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
 add r8,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r12+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_SOURCE_OFFSET]
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

g05c_append:
 mov rdi,[rdi+neboc_bindings_constantes_mutabilidade_e_definite_assignment_CODEGEN_WRITER_OFFSET]
 jmp neboc_assembly_writer_append_bytes
section .note.GNU-stack noalloc noexec nowrite progbits
