; Nebo Assembly — MF038 receiver-first function/call/.return codegen
bits 64
default rel

%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/tokens/token.inc"
%include "compiler/tokens/token_kind.inc"
%include "compiler/lexer/lexer.inc"
%include "compiler/ast/ast_node.inc"
%include "compiler/semantic/types/type_table.inc"
%include "compiler/lowering/function_lowering_plan.inc"
%include "compiler/codegen/asm-writer/assembly_writer.inc"
%include "compiler/codegen/arch/x86_64/architecture_backend.inc"
%include "compiler/codegen/abi/x86_64/abi_adapter.inc"
%include "compiler/codegen/functions/x86_64/function_codegen.inc"
%include "runtime/core/runtime_core.inc"

extern neboc_assembly_writer_append_bytes
extern neboc_assembly_writer_append_u64_decimal
extern neboc_assembly_writer_append_i64_decimal
extern neboc_arch_backend_begin_function
extern neboc_abi_signature_init
extern neboc_abi_adapter_begin_function
extern neboc_abi_adapter_emit_parameter_copy
extern neboc_abi_adapter_emit_prepared_call
extern neboc_abi_adapter_emit_return_rax
extern neboc_function_plan_compute_hash

section .rodata
fcg_type_int: db 'Int'
fcg_type_bool: db 'Bool'
fcg_type_text: db 'Text'

fcg_mov_rax: db '    mov rax, '
fcg_mov_rax_len equ $-fcg_mov_rax
fcg_mov_true: db '    mov eax, 1',10
fcg_mov_true_len equ $-fcg_mov_true
fcg_mov_false: db '    xor eax, eax',10
fcg_mov_false_len equ $-fcg_mov_false
fcg_load_slot: db '    mov rax, [rbp - '
fcg_load_slot_len equ $-fcg_load_slot
fcg_close_bracket: db ']',10
fcg_close_bracket_len equ $-fcg_close_bracket
fcg_newline: db 10
fcg_newline_len equ $-fcg_newline
fcg_push_rax: db '    push rax',10
fcg_push_rax_len equ $-fcg_push_rax
fcg_restore_binary: db '    mov rcx, rax',10,'    pop rax',10
fcg_restore_binary_len equ $-fcg_restore_binary
fcg_add: db '    add rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_add_len equ $-fcg_add
fcg_sub: db '    sub rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_sub_len equ $-fcg_sub
fcg_mul: db '    imul rax, rcx',10,'    jo .nebo_trap_overflow',10
fcg_mul_len equ $-fcg_mul
fcg_neg: db '    neg rax',10,'    jo .nebo_trap_overflow',10
fcg_neg_len equ $-fcg_neg
fcg_not: db '    test rax, rax',10,'    sete al',10,'    movzx eax, al',10
fcg_not_len equ $-fcg_not
fcg_cmp_eq: db '    cmp rax, rcx',10,'    sete al',10,'    movzx eax, al',10
fcg_cmp_eq_len equ $-fcg_cmp_eq
fcg_cmp_ne: db '    cmp rax, rcx',10,'    setne al',10,'    movzx eax, al',10
fcg_cmp_ne_len equ $-fcg_cmp_ne
fcg_cmp_lt: db '    cmp rax, rcx',10,'    setl al',10,'    movzx eax, al',10
fcg_cmp_lt_len equ $-fcg_cmp_lt
fcg_cmp_le: db '    cmp rax, rcx',10,'    setle al',10,'    movzx eax, al',10
fcg_cmp_le_len equ $-fcg_cmp_le
fcg_cmp_gt: db '    cmp rax, rcx',10,'    setg al',10,'    movzx eax, al',10
fcg_cmp_gt_len equ $-fcg_cmp_gt
fcg_cmp_ge: db '    cmp rax, rcx',10,'    setge al',10,'    movzx eax, al',10
fcg_cmp_ge_len equ $-fcg_cmp_ge
fcg_div_prefix: db '    test rcx, rcx',10,'    jz .nebo_trap_division_by_zero',10,'    mov rdx, 0x8000000000000000',10,'    cmp rax, rdx',10,'    jne .nebo_div_ok_'
fcg_div_prefix_len equ $-fcg_div_prefix
fcg_div_mid: db 10,'    cmp rcx, -1',10,'    je .nebo_trap_overflow',10,'.nebo_div_ok_'
fcg_div_mid_len equ $-fcg_div_mid
fcg_div_tail: db ':',10,'    cqo',10,'    idiv rcx',10
fcg_div_tail_len equ $-fcg_div_tail
fcg_mod_tail: db '    mov rax, rdx',10
fcg_mod_tail_len equ $-fcg_mod_tail
fcg_and_branch: db '    test rax, rax',10,'    jz .nebo_bool_false_'
fcg_and_branch_len equ $-fcg_and_branch
fcg_or_branch: db '    test rax, rax',10,'    jnz .nebo_bool_true_'
fcg_or_branch_len equ $-fcg_or_branch
fcg_bool_canon_done: db '    test rax, rax',10,'    setne al',10,'    movzx eax, al',10,'    jmp .nebo_bool_end_'
fcg_bool_canon_done_len equ $-fcg_bool_canon_done
fcg_false_label: db 10,'.nebo_bool_false_'
fcg_false_label_len equ $-fcg_false_label
fcg_false_body: db ':',10,'    xor eax, eax',10,'.nebo_bool_end_'
fcg_false_body_len equ $-fcg_false_body
fcg_true_label: db 10,'.nebo_bool_true_'
fcg_true_label_len equ $-fcg_true_label
fcg_true_body: db ':',10,'    mov eax, 1',10,'.nebo_bool_end_'
fcg_true_body_len equ $-fcg_true_body
fcg_label_end: db ':',10
fcg_label_end_len equ $-fcg_label_end
fcg_store_slot: db '    mov [rbp - '
fcg_store_slot_len equ $-fcg_store_slot
fcg_store_slot_suffix: db '], rax',10
fcg_store_slot_suffix_len equ $-fcg_store_slot_suffix
fcg_if_test: db '    test rax, rax',10,'    jz .nebo_if_else_'
fcg_if_test_len equ $-fcg_if_test
fcg_if_jump_end: db '    jmp .nebo_if_end_'
fcg_if_jump_end_len equ $-fcg_if_jump_end
fcg_if_else_label: db '.nebo_if_else_'
fcg_if_else_label_len equ $-fcg_if_else_label
fcg_if_end_label: db '.nebo_if_end_'
fcg_if_end_label_len equ $-fcg_if_end_label
fcg_lea_text_desc: db '    lea rax, [rel nebo_text_desc_'
fcg_lea_text_desc_len equ $-fcg_lea_text_desc
fcg_lea_text_desc_suffix: db ']',10
fcg_lea_text_desc_suffix_len equ $-fcg_lea_text_desc_suffix
fcg_text_equal_extern: db 'extern nebo_runtime_text_equal',10
fcg_text_equal_extern_len equ $-fcg_text_equal_extern
fcg_text_equal_call: db '    mov rsi, rax',10,'    pop rdi',10,'    call nebo_runtime_text_equal',10
fcg_text_equal_call_len equ $-fcg_text_equal_call
fcg_text_not_equal: db '    xor eax, 1',10
fcg_text_not_equal_len equ $-fcg_text_not_equal
fcg_rodata_header: db 10,'section .rodata align=8',10
fcg_rodata_header_len equ $-fcg_rodata_header
fcg_align8: db 'align 8',10
fcg_align8_len equ $-fcg_align8
fcg_text_data_prefix: db 'nebo_text_data_'
fcg_text_data_prefix_len equ $-fcg_text_data_prefix
fcg_text_data_mid: db ': db '
fcg_text_data_mid_len equ $-fcg_text_data_mid
fcg_text_desc_prefix: db 'nebo_text_desc_'
fcg_text_desc_prefix_len equ $-fcg_text_desc_prefix
fcg_text_desc_mid: db ':',10,'    dq nebo_text_data_'
fcg_text_desc_mid_len equ $-fcg_text_desc_mid
fcg_text_desc_length: db 10,'    dq '
fcg_text_desc_length_len equ $-fcg_text_desc_length
fcg_text_desc_tail: db 10,'    dd 0',10,'    dw 1',10,'    dw 1',10
fcg_text_desc_tail_len equ $-fcg_text_desc_tail
fcg_comma: db ','
fcg_comma_len equ $-fcg_comma
fcg_zero: db '0'
fcg_zero_len equ $-fcg_zero
fcg_text_section: db 10,'section .text',10
fcg_text_section_len equ $-fcg_text_section
fcg_trap_overflow: db '.nebo_trap_overflow:',10,'    jmp nebo_runtime_trap_overflow',10
fcg_trap_overflow_len equ $-fcg_trap_overflow
fcg_trap_divzero: db '.nebo_trap_division_by_zero:',10,'    jmp nebo_runtime_trap_division_by_zero',10
fcg_trap_divzero_len equ $-fcg_trap_divzero

fcg_pop_rdi: db '    pop rdi',10
fcg_pop_rdi_len equ $-fcg_pop_rdi
fcg_pop_rsi: db '    pop rsi',10
fcg_pop_rsi_len equ $-fcg_pop_rsi
fcg_pop_rdx: db '    pop rdx',10
fcg_pop_rdx_len equ $-fcg_pop_rdx
fcg_pop_rcx: db '    pop rcx',10
fcg_pop_rcx_len equ $-fcg_pop_rcx
fcg_pop_r8: db '    pop r8',10
fcg_pop_r8_len equ $-fcg_pop_r8
fcg_pop_r9: db '    pop r9',10
fcg_pop_r9_len equ $-fcg_pop_r9
fcg_pop_ptrs: dq fcg_pop_rdi,fcg_pop_rsi,fcg_pop_rdx,fcg_pop_rcx,fcg_pop_r8,fcg_pop_r9
fcg_pop_lens: dq fcg_pop_rdi_len,fcg_pop_rsi_len,fcg_pop_rdx_len,fcg_pop_rcx_len,fcg_pop_r8_len,fcg_pop_r9_len

section .text

; function_codegen_init(state*, request*)
NEBOC_ABI_FUNCTION neboc_function_codegen_init
 push rbx
 push r12
 mov rbx,rdi
 mov r12,rsi
 test rbx,rbx
 jz .invalid_return
 test r12,r12
 jz .invalid
 mov qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ERROR_CODE_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUILDER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ROOT_ID_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET],0
 je .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET],1
 jb .invalid
 cmp qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET],1
 jb .invalid
 mov rdi,rbx
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_CODEGEN_QWORDS
 rep stosq
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BUILDER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ROOT_ID_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKENS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_TOKEN_COUNT_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SOURCE_LENGTH_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_LENGTH_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_WRITER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_BACKEND_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ADAPTER_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURES_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURES_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_SIGNATURE_CAPACITY_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLANS_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_PLANS_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_PLAN_CAPACITY_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_BYTES_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET],rax
 mov rax,[r12+NEBOC_FUNCTION_CODEGEN_REQUEST_LITERAL_LENGTH_OFFSET]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET],rax
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_ARGUMENT
 mov qword [r12+NEBOC_FUNCTION_CODEGEN_REQUEST_ERROR_CODE_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_ARGUMENT
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 pop r12
 pop rbx
 ret

; function_codegen_emit(state*)
NEBOC_ABI_FUNCTION neboc_function_codegen_emit
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 test rbx,rbx
 jz .invalid_return
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PROGRAM
 jne .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0              ; function count
 mov qword [rsp+8],0            ; start node id
.first_pass:
 test r12,r12
 jz .first_done
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .check_start
 inc qword [rsp]
 cmp qword [rsp],NEBOC_FUNCTION_CODEGEN_MAX_FUNCTIONS
 ja .limit
 jmp .first_next
.check_start:
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_START_DECL
 jne .ast
 cmp qword [rsp+8],0
 jne .ast
 mov [rsp+8],r12
.first_next:
 mov r12,r13
 jmp .first_pass
.first_done:
 cmp qword [rsp+8],0
 je .ast
 mov rax,[rsp]
 inc rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET]
 ja .limit
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET]
 ja .limit
 mov rax,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_FUNCTION_COUNT_OFFSET],rax
 mov rdi,rbx
 call fcg_emit_text_literals
 test eax,eax
 jnz .done

 ; Emit receiver-first functions in stable source order. This is a valid
 ; topological order because forward/self calls are rejected by resolve_call.
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r14,2                    ; symbol id, start reserves 1
 mov r15,1                    ; source order
.emit_functions:
 test r12,r12
 jz .emit_start
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r13,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .emit_next
 mov rdi,rbx
 mov rsi,r12
 mov rdx,r14
 mov rcx,r15
 call fcg_emit_function
 test eax,eax
 jnz .done
 inc r14
 inc r15
.emit_next:
 mov r12,r13
 jmp .emit_functions
.emit_start:
 mov rdi,rbx
 mov rsi,[rsp+8]
 mov rcx,r15
 call fcg_emit_start
 test eax,eax
 jnz .done
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 xor eax,eax
 jmp .done
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.invalid_return:
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, function_decl_id, symbol_id, source_order
fcg_emit_function:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,96
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],r13
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .ast
 mov rax,[r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rax
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS
 ja .parameter
 mov [rsp],rax               ; total parameter count
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .ast
 mov [rsp+8],rax             ; block id
 mov rdi,rbx
 mov rsi,rax
 mov rdx,[rsp]
 call fcg_prepare_bindings
 cmp rax,-1
 je .binding_error
 mov [rsp+40],rax            ; total local slots (parameters + bindings)
 mov [rsp+48],rdx            ; binding count
 mov rdi,rbx
 mov rsi,[rsp+8]
 xor edx,edx
 call fcg_count_calls
 cmp rax,-1
 je .depth
 mov [rsp+16],rax            ; call count
 mov rdi,rbx
 mov rsi,r13
 mov rdx,r14
 mov rcx,[rsp]
 mov r8,[rsp+40]
 mov r9,[rsp+16]
 call fcg_prepare_contracts
 test rax,rax
 jz .abi
 mov [rsp+24],rax            ; signature ptr
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET]
 mov rsi,r13
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .abi
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp+24]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .abi
 xor r15d,r15d
.copy_params:
 cmp r15,[rsp]
 jae .body
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,r15
 lea rdx,[r15+1]
 call neboc_abi_adapter_emit_parameter_copy
 test eax,eax
 jnz .abi
 inc r15
 jmp .copy_params
.body:
 mov rdi,rbx
 mov rsi,[rsp+8]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+32],0        ; return count
.statement_loop:
 test r12,r12
 jz .body_done
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rdx,NEBOC_AST_EXPRESSION_STMT
 je .expression_stmt
 cmp rdx,NEBOC_AST_BINDING_STMT
 je .binding_stmt
 cmp rdx,NEBOC_AST_IF_STMT
 je .if_stmt
 cmp rdx,NEBOC_AST_RETURN_STMT
 je .return_stmt
 jmp .unsupported
.expression_stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 xor edx,edx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.binding_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_binding
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.if_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_if
 test eax,eax
 jnz .done
 mov r12,r15
 jmp .statement_loop
.return_stmt:
 inc qword [rsp+32]
 cmp qword [rsp+32],1
 jne .multiple_return
 test r15,r15
 jnz .multiple_return
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 xor edx,edx
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 call neboc_abi_adapter_emit_return_rax
 test eax,eax
 jnz .abi
 xor r12d,r12d
 jmp .body_done
.body_done:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 cmp qword [rsp+32],1
 jne .missing_return
 mov rdi,rbx
 call fcg_emit_traps
 jmp .done
.binding_error:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 je .parameter
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.missing_return:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_MISSING_RETURN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.multiple_return:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_MULTIPLE_RETURN
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,96
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, start_decl_id, source_order
fcg_emit_start:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov r14,rcx
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],0
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],1
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .ast
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 xor edx,edx
 call fcg_prepare_bindings
 cmp rax,-1
 je .binding_error
 mov [rsp+32],rax            ; total local slots
 mov [rsp+40],rdx            ; binding count
 mov rdi,rbx
 mov rsi,[rsp]
 xor edx,edx
 call fcg_count_calls
 cmp rax,-1
 je .depth
 mov [rsp+8],rax
 mov rdi,rbx
 mov esi,1
 mov rdx,r14
 xor ecx,ecx
 mov r8,[rsp+32]
 mov r9,[rsp+8]
 call fcg_prepare_contracts
 test rax,rax
 jz .abi
 mov [rsp+16],rax
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_BACKEND_OFFSET]
 mov esi,1
 call neboc_arch_backend_begin_function
 test eax,eax
 jnz .abi
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_abi_adapter_begin_function
 test eax,eax
 jnz .abi
 mov rdi,rbx
 mov rsi,[rsp]
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+24],0
.statement_loop:
 test r12,r12
 jz .tail
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r12
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rdx,NEBOC_AST_EXPRESSION_STMT
 je .expression_stmt
 cmp rdx,NEBOC_AST_BINDING_STMT
 je .binding_stmt
 cmp rdx,NEBOC_AST_IF_STMT
 je .if_stmt
 jmp .unsupported
.expression_stmt:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .ast
 mov rdi,rbx
 xor edx,edx
 call fcg_emit_expr
 jmp .emitted
.binding_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_binding
 jmp .emitted
.if_stmt:
 mov rdi,rbx
 mov rsi,r12
 xor edx,edx
 call fcg_emit_if
.emitted:
 test eax,eax
 jnz .done
 inc qword [rsp+24]
 mov r12,r15
 jmp .statement_loop
.tail:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 cmp qword [rsp+24],0
 jne .return
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 test eax,eax
 jnz .done
.return:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 call neboc_abi_adapter_emit_return_rax
 test eax,eax
 jnz .abi
 mov rdi,rbx
 call fcg_emit_traps
 jmp .done
.binding_error:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 je .parameter
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 test eax,eax
 jnz .done
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, symbol_id, source_order, parameter_count, local_count, call_count
; returns signature pointer or zero.
fcg_prepare_contracts:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 mov [rsp],r9
 mov rax,r12
 dec rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURE_CAPACITY_OFFSET]
 jae .bad
 mov rdx,NEBOC_ABI_SIGNATURE_SIZE
 imul rax,rdx
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SIGNATURES_OFFSET]
 mov [rsp+8],rax
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_ABI_SIGNATURE_QWORDS
 rep stosq
 mov rdi,[rsp+8]
 mov rsi,r12
 mov rdx,r14
 mov rcx,r15
 mov r8d,NEBOC_ABI_RETURN_SCALAR
 mov r9,[rsp]
 call neboc_abi_signature_init
 test eax,eax
 jnz .bad
 mov rax,r12
 dec rax
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLAN_CAPACITY_OFFSET]
 jae .bad
 mov rdx,NEBOC_FUNCTION_PLAN_SIZE
 imul rax,rdx
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_PLANS_OFFSET]
 mov [rsp+16],rax
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_FUNCTION_PLAN_QWORDS
 rep stosq
 mov rax,[rsp+16]
 mov [rax+NEBOC_FUNCTION_PLAN_ID_OFFSET],r12
 mov [rax+NEBOC_FUNCTION_PLAN_FUNCTION_ID_OFFSET],r12
 mov [rax+NEBOC_FUNCTION_PLAN_SOURCE_ORDER_OFFSET],r13
 mov qword [rax+NEBOC_FUNCTION_PLAN_FIRST_OPERATION_ID_OFFSET],0
 mov rdx,[rsp]
 inc rdx
 mov [rax+NEBOC_FUNCTION_PLAN_OPERATION_COUNT_OFFSET],rdx
 mov qword [rax+NEBOC_FUNCTION_PLAN_FIRST_CONTINUATION_ID_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_CONTINUATION_COUNT_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_EXIT_PATH_COUNT_OFFSET],1
 mov qword [rax+NEBOC_FUNCTION_PLAN_FLAGS_OFFSET],NEBOC_LOWERING_PLAN_FLAG_TARGET_INDEPENDENT|NEBOC_LOWERING_PLAN_FLAG_SOURCE_ORDERED
 mov qword [rax+NEBOC_FUNCTION_PLAN_CANCELLATION_POLICY_OFFSET],0
 mov qword [rax+NEBOC_FUNCTION_PLAN_STATE_OFFSET],NEBOC_FUNCTION_PLAN_STATE_FROZEN
 mov [rax+NEBOC_FUNCTION_PLAN_PARAMETER_COUNT_OFFSET],r14
 mov [rax+NEBOC_FUNCTION_PLAN_LOCAL_BINDING_COUNT_OFFSET],r15
 mov rdi,rax
 call neboc_function_plan_compute_hash
 test eax,eax
 jnz .bad
 mov rax,[rsp+8]
 jmp .done
.bad:
 xor eax,eax
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, expression_node_id, depth -> status
fcg_emit_expr:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,80
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .integer
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .boolean
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text_literal
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
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 jmp .done
.boolean:
 cmp qword [r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET],0
 je .bool_false
 mov rdi,rbx
 lea rsi,[rel fcg_mov_true]
 mov edx,fcg_mov_true_len
 call fcg_append
 jmp .done
.bool_false:
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 jmp .done
.text_literal:
 mov rdi,rbx
 lea rsi,[rel fcg_lea_text_desc]
 mov edx,fcg_lea_text_desc_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_lea_text_desc_suffix]
 mov edx,fcg_lea_text_desc_suffix_len
 call fcg_append
 jmp .done
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jz .unsupported
 mov r15,rax
 shl r15,3
 mov rdi,rbx
 lea rsi,[rel fcg_load_slot]
 mov edx,fcg_load_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r15
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_close_bracket]
 mov edx,fcg_close_bracket_len
 call fcg_append
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
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
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_neg]
 mov edx,fcg_neg_len
 call fcg_append
 jmp .done
.unary_not:
 mov rdi,rbx
 lea rsi,[rel fcg_not]
 mov edx,fcg_not_len
 call fcg_append
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
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
 cmp rax,NEBOC_TOKEN_EQUAL_EQUAL
 je .maybe_text_equality
 cmp rax,NEBOC_TOKEN_BANG_EQUAL
 je .maybe_text_equality
 jmp .generic_binary
.maybe_text_equality:
 mov [rsp+40],rax
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .generic_binary
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_TEXT
 jne .unsupported
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_equal_call]
 mov edx,fcg_text_equal_call_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+40],NEBOC_TOKEN_BANG_EQUAL
 jne .ok
 mov rdi,rbx
 lea rsi,[rel fcg_text_not_equal]
 mov edx,fcg_text_not_equal_len
 call fcg_append
 jmp .done
.generic_binary:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_restore_binary]
 mov edx,fcg_restore_binary_len
 call fcg_append
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
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_add]
 mov edx,fcg_add_len
 call fcg_append
 jmp .done
.sub:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_sub]
 mov edx,fcg_sub_len
 call fcg_append
 jmp .done
.mul:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 mov rdi,rbx
 lea rsi,[rel fcg_mul]
 mov edx,fcg_mul_len
 call fcg_append
 jmp .done
.div:
 xor r15d,r15d
 jmp .division_common
.mod:
 mov r15d,1
.division_common:
 or qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW|NEBOC_FUNCTION_CODEGEN_TRAP_DIV_ZERO
 mov rdi,rbx
 lea rsi,[rel fcg_div_prefix]
 mov edx,fcg_div_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_div_mid]
 mov edx,fcg_div_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_div_tail]
 mov edx,fcg_div_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 test r15d,r15d
 jz .ok
 mov rdi,rbx
 lea rsi,[rel fcg_mod_tail]
 mov edx,fcg_mod_tail_len
 call fcg_append
 jmp .done
.eq:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_eq]
 mov edx,fcg_cmp_eq_len
 call fcg_append
 jmp .done
.ne:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_ne]
 mov edx,fcg_cmp_ne_len
 call fcg_append
 jmp .done
.lt:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_lt]
 mov edx,fcg_cmp_lt_len
 call fcg_append
 jmp .done
.le:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_le]
 mov edx,fcg_cmp_le_len
 call fcg_append
 jmp .done
.gt:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_gt]
 mov edx,fcg_cmp_gt_len
 call fcg_append
 jmp .done
.ge:
 mov rdi,rbx
 lea rsi,[rel fcg_cmp_ge]
 mov edx,fcg_cmp_ge_len
 call fcg_append
 jmp .done
.logical_and:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_and_branch]
 mov edx,fcg_and_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_bool_canon_done]
 mov edx,fcg_bool_canon_done_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_false_label]
 mov edx,fcg_false_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_false_body]
 mov edx,fcg_false_body_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 jmp .done
.logical_or:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_or_branch]
 mov edx,fcg_or_branch_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_bool_canon_done]
 mov edx,fcg_bool_canon_done_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_true_label]
 mov edx,fcg_true_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_true_body]
 mov edx,fcg_true_body_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 jmp .done
.call:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .type_constructor
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 test rax,rax
 jz .unsupported
 mov [rsp],rax              ; callee symbol
 mov [rsp+8],rdx            ; return type
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 inc rax
 cmp rax,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS
 ja .parameter
 mov [rsp+16],rax           ; total receiver + args
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+24],0
.call_eval_loop:
 mov rax,[rsp+24]
 cmp rax,[rsp+16]
 jae .call_pop_start
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_push_rax]
 mov edx,fcg_push_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+24]
 jmp .call_eval_loop
.call_pop_start:
 mov rax,[rsp+16]
 mov [rsp+32],rax
.call_pop_loop:
 cmp qword [rsp+32],0
 je .call_emit
 dec qword [rsp+32]
 mov r10,[rsp+32]
 lea rax,[rel fcg_pop_ptrs]
 mov rsi,[rax+r10*8]
 lea rax,[rel fcg_pop_lens]
 mov rdx,[rax+r10*8]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .writer
 jmp .call_pop_loop
.call_emit:
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_ADAPTER_OFFSET]
 mov rsi,[rsp]
 call neboc_abi_adapter_emit_prepared_call
 test eax,eax
 jnz .abi
 xor eax,eax
 jmp .done
.type_constructor:
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .unsupported
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .unsupported
 mov [rsp+48],rax
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .ast
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,[rsp+48]
 jne .type_assertion
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 jmp .done
.type_assertion:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.unsupported:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .unsupported_status
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_NODE
.unsupported_status:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.abi:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_ABI
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 jmp .done
.ok:
 xor eax,eax
.done:
 add rsp,80
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, call_node_id -> RAX symbol id, RDX return TypeId, zero on failure.
fcg_resolve_call:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,128
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r13,rax
 cmp qword [r13+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .bad_ast
 mov r14,[r13+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 cmp r14,NEBOC_FUNCTION_CODEGEN_MAX_PARAMETERS-1
 ja .parameter
 mov rax,r14
 inc rax
 cmp rax,[r13+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad_ast
 mov r15,[r13+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad_ast
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .failed
 mov [rsp],rax              ; receiver type
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 xor ecx,ecx
.arg_types:
 cmp rcx,r14
 jae .search
 test r15,r15
 jz .bad_ast
 mov [rsp+120],rcx
 mov rdi,rbx
 mov rsi,r15
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .failed
 mov rcx,[rsp+120]
 mov [rsp+8+rcx*8],rax
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov rcx,[rsp+120]
 inc rcx
 jmp .arg_types
.search:
 mov qword [rsp+56],0       ; matched symbol
 mov qword [rsp+64],0       ; matched return type
 mov qword [rsp+72],0       ; candidate count
 mov rdi,rbx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_ROOT_ID_OFFSET]
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov r15,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+80],2
.candidate_loop:
 test r15,r15
 jz .search_done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov [rsp+88],rax
 mov rdx,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+96],rdx
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .candidate_next
 mov rdi,rbx
 mov rsi,[r13+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jz .candidate_advance
 mov rax,[rsp+88]
 cmp r14,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 jne .candidate_advance
 mov rdx,r14
 add rdx,2
 cmp rdx,[rax+NEBOC_AST_NODE_CHILD_COUNT_OFFSET]
 jne .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RECEIVER
 jne .bad_ast
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 cmp rax,[rsp]
 jne .candidate_advance
 mov r11,[rsp+88]
 mov rsi,[r11+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov qword [rsp+112],0
 xor ecx,ecx
.param_compare:
 cmp rcx,r14
 jae .candidate_match
 test rsi,rsi
 jz .bad_ast
 mov [rsp+104],rsi
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_PARAMETER
 jne .candidate_advance
 mov rdi,rbx
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 mov rcx,[rsp+112]
 cmp rax,[rsp+8+rcx*8]
 jne .candidate_advance
 mov rsi,[rsp+104]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad_ast
 mov rsi,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc qword [rsp+112]
 mov rcx,[rsp+112]
 jmp .param_compare
.candidate_match:
 inc qword [rsp+72]
 cmp qword [rsp+72],1
 jne .undefined
 mov rax,[rsp+80]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 cmp rax,rdx
 je .recursion
 cmp rdx,1
 je .candidate_type
 cmp rax,rdx
 ja .forward
.candidate_type:
 mov [rsp+56],rax
 mov rdi,rbx
 mov rsi,r15
 mov rdx,[rsp+80]
 call fcg_function_return_type
 test rax,rax
 jz .failed
 mov [rsp+64],rax
.candidate_advance:
 inc qword [rsp+80]
.candidate_next:
 mov r15,[rsp+96]
 mov qword [rsp+112],0
 jmp .candidate_loop
.search_done:
 cmp qword [rsp+72],1
 jne .undefined
 mov rax,[rsp+56]
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 cmp rax,rdx
 je .recursion
 cmp rdx,1
 je .success
 cmp rax,rdx
 ja .forward
.success:
 mov rdx,[rsp+64]
 jmp .done
.recursion:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_RECURSION
 xor eax,eax
 xor edx,edx
 jmp .done
.forward:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_FORWARD_CALL
 xor eax,eax
 xor edx,edx
 jmp .done
.undefined:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNDEFINED_CALL
 xor eax,eax
 xor edx,edx
 jmp .done
.parameter:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 xor eax,eax
 xor edx,edx
 jmp .done
.bad_ast:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.failed:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,128
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, identifier_token_index -> RAX one-based local slot, RDX TypeId.
fcg_resolve_identifier:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 test r13,r13
 jz .bindings
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bindings
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_FUNCTION_DECL
 jne .bindings
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov r15,1
.parameter_loop:
 test r14,r14
 jz .bindings
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bindings
 mov [rsp],rax
 mov rcx,[rax+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rcx,NEBOC_AST_BLOCK
 je .bindings
 cmp rcx,NEBOC_AST_RECEIVER
 je .candidate
 cmp rcx,NEBOC_AST_PARAMETER
 jne .bindings
.candidate:
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .parameter_found
 mov rax,[rsp]
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 inc r15
 jmp .parameter_loop
.parameter_found:
 mov rax,[rsp]
 mov rsi,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rdi,rbx
 call fcg_type_from_token
 test rax,rax
 jz .bindings
 mov rdx,rax
 mov rax,r15
 jmp .done
.bindings:
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 test rdx,rdx
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_prior_binding
 test rax,rax
 jz .no
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov rcx,[rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,ecx
 mov rdx,rcx
 shr rdx,32
 test rax,rax
 jz .no
 test rdx,rdx
 jz .no
 jmp .done
.no:
 xor eax,eax
 xor edx,edx
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, function_decl_id, symbol_id -> RAX return TypeId or zero.
fcg_function_return_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET]
 mov [rsp],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET]
 mov [rsp+24],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 mov [rsp+32],rax
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET]
 mov [rsp+40],rax
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],r12
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],r13
 mov rdi,rbx
 mov rsi,r12
 call fcg_find_block
 test rax,rax
 jz .bad
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rax
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r13,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp+8],0
.loop:
 test r13,r13
 jz .finish
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r13
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_STMT
 jne .next
 inc qword [rsp+8]
 cmp qword [rsp+8],1
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_RETURN_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .bad
 mov [rsp+16],rax
.next:
 mov r13,r14
 jmp .loop
.finish:
 cmp qword [rsp+8],1
 jne .bad
 mov rax,[rsp+16]
 jmp .restore
.bad:
 xor eax,eax
.restore:
 mov rdx,[rsp]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_DECL_OFFSET],rdx
 mov rdx,[rsp+24]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_SYMBOL_OFFSET],rdx
 mov rdx,[rsp+32]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],rdx
 mov rdx,[rsp+40]
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],rdx
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX TypeId or zero.
fcg_infer_type:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 mov rax,[r14+NEBOC_AST_NODE_KIND_OFFSET]
 cmp rax,NEBOC_AST_INTEGER_LITERAL
 je .int
 cmp rax,NEBOC_AST_BOOL_LITERAL
 je .bool
 cmp rax,NEBOC_AST_TEXT_LITERAL
 je .text
 cmp rax,NEBOC_AST_IDENTIFIER_EXPR
 je .identifier
 cmp rax,NEBOC_AST_UNARY_EXPR
 je .unary
 cmp rax,NEBOC_AST_BINARY_EXPR
 je .binary
 cmp rax,NEBOC_AST_CALL_EXPR
 je .call
 cmp rax,NEBOC_AST_RETURN_TERMINAL
 je .terminal
 jmp .bad
.int:
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.bool:
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.text:
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.identifier:
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 mov rax,rdx
 jmp .done
.unary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 cmp r15,NEBOC_TOKEN_BANG
 je .unary_bool
 cmp r15,NEBOC_TOKEN_PLUS
 je .unary_int
 cmp r15,NEBOC_TOKEN_MINUS
 jne .bad
.unary_int:
 cmp rax,NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.unary_bool:
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.binary:
 mov r15,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov rax,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rdi,rbx
 mov rsi,rax
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov rax,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test rax,rax
 jz .bad
 mov [rsp+8],rax
 mov rdi,rbx
 mov rsi,[rsp]
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 mov [rsp+16],rax
 mov rdi,rbx
 mov rsi,[rsp+8]
 lea rdx,[r13+1]
 call fcg_infer_type
 test rax,rax
 jz .bad
 mov [rsp+24],rax
 cmp r15,NEBOC_TOKEN_AND_AND
 je .logical
 cmp r15,NEBOC_TOKEN_OR_OR
 je .logical
 cmp r15,NEBOC_TOKEN_EQUAL_EQUAL
 je .equality
 cmp r15,NEBOC_TOKEN_BANG_EQUAL
 je .equality
 cmp r15,NEBOC_TOKEN_LESS
 je .relational
 cmp r15,NEBOC_TOKEN_LESS_EQUAL
 je .relational
 cmp r15,NEBOC_TOKEN_GREATER
 je .relational
 cmp r15,NEBOC_TOKEN_GREATER_EQUAL
 je .relational
 cmp r15,NEBOC_TOKEN_PLUS
 je .arithmetic
 cmp r15,NEBOC_TOKEN_MINUS
 je .arithmetic
 cmp r15,NEBOC_TOKEN_STAR
 je .arithmetic
 cmp r15,NEBOC_TOKEN_SLASH
 je .arithmetic
 cmp r15,NEBOC_TOKEN_PERCENT
 jne .bad
.arithmetic:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.equality:
 mov rax,[rsp+16]
 cmp rax,[rsp+24]
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.relational:
 cmp qword [rsp+16],NEBOC_TYPE_ID_INT
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_INT
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.logical:
 cmp qword [rsp+16],NEBOC_TYPE_ID_BOOL
 jne .bad
 cmp qword [rsp+24],NEBOC_TYPE_ID_BOOL
 jne .bad
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.call:
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jz .normal_call
 cmp qword [r14+NEBOC_AST_NODE_CHILD_COUNT_OFFSET],1
 jne .bad
 mov rdi,rbx
 mov rsi,[r14+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_type_from_token
 test rax,rax
 jz .bad
 mov [rsp],rax
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,[rsp]
 jne .type_assert_bad
 mov rax,[rsp]
 jmp .done
.type_assert_bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
 xor eax,eax
 jmp .done
.normal_call:
 mov rdi,rbx
 mov rsi,r12
 call fcg_resolve_call
 mov rax,rdx
 jmp .done
.terminal:
 mov rsi,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_infer_type
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
.bad:
 xor eax,eax
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, declaration_node_id -> RAX block node id or zero.
fcg_find_block:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r12,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r12,r12
 jz .no
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .no
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .yes
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.yes:
 mov rax,r12
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,8
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> RAX call count or -1.
fcg_count_calls:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .bad
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 xor r15d,r15d
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_CALL_EXPR
 jne .children
 test qword [r14+NEBOC_AST_NODE_FLAGS_OFFSET],NEBOC_AST_FLAG_TYPE_CONSTRUCTOR
 jnz .children
 inc r15
.children:
 mov r12,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.child_loop:
 test r12,r12
 jz .ok
 mov rdi,rbx
 mov rsi,r12
 lea rdx,[r13+1]
 call fcg_count_calls
 cmp rax,-1
 je .bad
 add r15,rax
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r12,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .child_loop
.ok:
 mov rax,r15
 jmp .done
.bad:
 mov rax,-1
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, token_a, token_b -> EAX 1/0.
fcg_names_equal:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r14,rax
 mov rdi,rbx
 mov rsi,r13
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r15,rax
 mov r8,[r14+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r14+NEBOC_TOKEN_END_OFFSET]
 mov r10,[r15+NEBOC_TOKEN_START_OFFSET]
 mov r11,[r15+NEBOC_TOKEN_END_OFFSET]
 sub r9,r8
 sub r11,r10
 cmp r9,r11
 jne .no
 mov rcx,r9
 cld
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rsi,r8
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add rdi,r10
 repe cmpsb
 sete al
 movzx eax,al
 jmp .done
.no:
 xor eax,eax
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 cld
 ret

; state*, type_token_index -> RAX TypeId or zero.
fcg_type_from_token:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rbx
 call fcg_token_ptr
 test rax,rax
 jz .no
 mov r13,rax
 mov r8,[r13+NEBOC_TOKEN_START_OFFSET]
 mov r9,[r13+NEBOC_TOKEN_END_OFFSET]
 sub r9,r8
 mov r10,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 add r10,r8
 cmp r9,3
 jne .check_bool
 cmp byte [r10],'I'
 jne .no
 cmp byte [r10+1],'n'
 jne .no
 cmp byte [r10+2],'t'
 jne .no
 mov eax,NEBOC_TYPE_ID_INT
 jmp .done
.check_bool:
 cmp r9,4
 jne .no
 cmp byte [r10],'B'
 jne .check_text
 cmp byte [r10+1],'o'
 jne .check_text
 cmp byte [r10+2],'o'
 jne .check_text
 cmp byte [r10+3],'l'
 jne .check_text
 mov eax,NEBOC_TYPE_ID_BOOL
 jmp .done
.check_text:
 cmp byte [r10],'T'
 jne .no
 cmp byte [r10+1],'e'
 jne .no
 cmp byte [r10+2],'x'
 jne .no
 cmp byte [r10+3],'t'
 jne .no
 mov eax,NEBOC_TYPE_ID_TEXT
 jmp .done
.no:
 xor eax,eax
.done:
 pop r13
 pop r12
 pop rbx
 ret

; state*, token_index -> token pointer or zero.
fcg_token_ptr:
 xor eax,eax
 test rdi,rdi
 jz .done
 cmp rsi,[rdi+NEBOC_FUNCTION_CODEGEN_TOKEN_COUNT_OFFSET]
 jae .done
 mov rax,rsi
 imul rax,NEBOC_TOKEN_SIZE
 add rax,[rdi+NEBOC_FUNCTION_CODEGEN_TOKENS_OFFSET]
.done:
 ret

; state*, node_id -> node pointer or zero.
fcg_node_ptr:
 xor eax,eax
 test rdi,rdi
 jz .done
 test rsi,rsi
 jz .done
 mov rcx,[rdi+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
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



; state*, block_id, parameter_count -> RAX total local slots, RDX binding count.
; Direct bindings are immutable, source ordered and stored in AST payload1 as
; high32=TypeId, low32=one-based frame slot. Bindings inside if/else scopes are
; intentionally deferred; MF039 rejects them rather than flattening scope.
fcg_prepare_bindings:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET],r12
 mov qword [rsp],0
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r14,r14
 jz .finish
 mov [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],r14
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,rax
 mov rax,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 mov [rsp+8],rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .binding
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .next
 mov rdi,rbx
 mov rsi,r14
 xor edx,edx
 call fcg_contains_nested_binding
 test eax,eax
 jnz .binding_scope
 jmp .next
.binding:
 mov rsi,[r15+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 mov [rsp+16],rax
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 xor edx,edx
 call fcg_infer_type
 test rax,rax
 jz .type
 cmp rax,NEBOC_TYPE_ID_VOID
 je .type
 mov [rsp+24],rax
 ; Reject duplicate names against receiver, parameters and prior bindings.
 mov rdi,rbx
 mov rsi,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_resolve_identifier
 test rax,rax
 jnz .duplicate
 inc qword [rsp]
 mov rax,r13
 add rax,[rsp]
 cmp rax,NEBOC_ABI_MAX_LOCAL_SLOTS
 ja .limit
 mov [rsp+32],rax
 mov rdx,[rsp+24]
 shl rdx,32
 or rdx,rax
 mov [r15+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
 mov rax,[rsp+16]
 mov [rax+NEBOC_AST_NODE_PAYLOAD1_OFFSET],rdx
.next:
 mov r14,[rsp+8]
 jmp .loop
.finish:
 mov rax,r13
 add rax,[rsp]
 mov rdx,[rsp]
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_STATEMENT_OFFSET],0
 jmp .done
.duplicate:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DUPLICATE_BINDING
 jmp .fail
.binding_scope:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 jmp .fail
.type:
 cmp qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_NONE
 jne .fail
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_TYPE
 jmp .fail
.limit:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_PARAMETER_LIMIT
 jmp .fail
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
.fail:
 mov rax,-1
 xor edx,edx
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, name_token, current_statement -> RAX prior binding statement or zero.
fcg_find_prior_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rsi,[rbx+NEBOC_FUNCTION_CODEGEN_CURRENT_BLOCK_OFFSET]
 mov rdi,rbx
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r14,r14
 jz .no
 cmp r14,r13
 je .no
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .no
 mov r15,rax
 cmp qword [r15+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .next
 mov rdi,rbx
 mov rsi,r12
 mov rdx,[r15+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 call fcg_names_equal
 test eax,eax
 jnz .yes
.next:
 mov r14,[r15+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
.yes:
 mov rax,r14
 jmp .done
.no:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, node_id, depth -> EAX 1 when an if/else subtree contains a binding.
fcg_contains_nested_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .yes
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .yes
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 je .yes
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
.loop:
 test r15,r15
 jz .no
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_contains_nested_binding
 test eax,eax
 jnz .yes
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .yes
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 jmp .loop
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

; state*, binding_statement_id, depth -> status.
fcg_emit_binding:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_STMT
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BINDING_TERMINAL
 jne .bad
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rax,[r14+NEBOC_AST_NODE_PAYLOAD1_OFFSET]
 mov eax,eax
 test rax,rax
 jz .bad
 shl rax,3
 mov [rsp],rax
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot]
 mov edx,fcg_store_slot_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_store_slot_suffix]
 mov edx,fcg_store_slot_suffix_len
 call fcg_append
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, if_node_id, depth -> status. Branch labels use the stable AST node ID.
fcg_emit_if:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,48
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r14,rax
 cmp qword [r14+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov r15,[r14+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_infer_type
 cmp rax,NEBOC_TYPE_ID_BOOL
 jne .control
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_expr
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_test]
 mov edx,fcg_if_test_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_nested_block
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_jump_end]
 mov edx,fcg_if_jump_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_else_label]
 mov edx,fcg_if_else_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 test r15,r15
 jz .no_else
 mov rdi,rbx
 mov rsi,r15
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 je .else_block
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 jne .bad
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_if
 jmp .after_else
.else_block:
 mov rdi,rbx
 mov rsi,r15
 lea rdx,[r13+1]
 call fcg_emit_nested_block
 jmp .after_else
.no_else:
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
.after_else:
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_if_end_label]
 mov edx,fcg_if_end_label_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r12
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_label_end]
 mov edx,fcg_label_end_len
 call fcg_append
 test eax,eax
 jnz .done
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_BRANCH_COUNT_OFFSET]
 xor eax,eax
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.control:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_CONTROL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,48
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state*, block_id, depth -> status. Nested branch blocks support expressions and
; nested if/else. Bindings and return terminals remain outside MF039 branch scope.
fcg_emit_nested_block:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 cmp r13,NEBOC_FUNCTION_CODEGEN_MAX_DEPTH
 jae .depth
 mov rdi,rbx
 mov rsi,r12
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_BLOCK
 jne .bad
 mov r14,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 mov qword [rsp],0
.loop:
 test r14,r14
 jz .finish
 mov rdi,rbx
 mov rsi,r14
 call fcg_node_ptr
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_NODE_NEXT_SIBLING_OFFSET]
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_EXPRESSION_STMT
 je .expr
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_IF_STMT
 je .if
 jmp .scope
.expr:
 mov rsi,[rax+NEBOC_AST_NODE_FIRST_CHILD_OFFSET]
 test rsi,rsi
 jz .bad
 mov rdi,rbx
 lea rdx,[r13+1]
 call fcg_emit_expr
 jmp .emitted
.if:
 mov rdi,rbx
 mov rsi,r14
 lea rdx,[r13+1]
 call fcg_emit_if
.emitted:
 test eax,eax
 jnz .done
 inc qword [rsp]
 mov r14,r15
 jmp .loop
.finish:
 cmp qword [rsp],0
 jne .ok
 mov rdi,rbx
 lea rsi,[rel fcg_mov_false]
 mov edx,fcg_mov_false_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.scope:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BINDING_SCOPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.depth:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_DEPTH
 mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state* -> status. Emit every lexer-backed Text literal as a deterministic
; 24-byte runtime descriptor before function bodies. Labels use AST node IDs,
; so source order and repeated equal contents remain stable and collision-free.
fcg_emit_text_literals:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 mov rbx,rdi
 mov rax,[rbx+NEBOC_FUNCTION_CODEGEN_BUILDER_OFFSET]
 test rax,rax
 jz .bad
 mov r15,[rax+NEBOC_AST_BUILDER_COUNT_OFFSET]
 mov r13,1
 mov qword [rsp],0
.loop:
 cmp r13,r15
 ja .finish
 mov rdi,rbx
 mov rsi,r13
 call fcg_node_ptr
 test rax,rax
 jz .bad
 cmp qword [rax+NEBOC_AST_NODE_KIND_OFFSET],NEBOC_AST_TEXT_LITERAL
 jne .next
 mov [rsp+8],rax
 cmp qword [rsp],0
 jne .header_ready
 mov rdi,rbx
 lea rsi,[rel fcg_text_equal_extern]
 mov edx,fcg_text_equal_extern_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_rodata_header]
 mov edx,fcg_rodata_header_len
 call fcg_append
 test eax,eax
 jnz .done
.header_ready:
 mov rax,[rsp+8]
 mov r14,[rax+NEBOC_AST_NODE_PAYLOAD0_OFFSET]
 mov eax,r14d
 mov [rsp+16],rax
 shr r14,32
 mov [rsp+24],r14
 mov rax,[rsp+16]
 mov rdx,[rsp+24]
 add rax,rdx
 jc .text_error
 cmp rax,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_LENGTH_OFFSET]
 ja .text_error
 mov rdi,rbx
 lea rsi,[rel fcg_align8]
 mov edx,fcg_align8_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_data_prefix]
 mov edx,fcg_text_data_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_data_mid]
 mov edx,fcg_text_data_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 cmp qword [rsp+16],0
 jne .bytes
 mov rdi,rbx
 lea rsi,[rel fcg_zero]
 mov edx,fcg_zero_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .data_done
.bytes:
 mov qword [rsp+32],0
.byte_loop:
 mov rax,[rsp+32]
 cmp rax,[rsp+16]
 jae .data_done
 mov rdx,[rbx+NEBOC_FUNCTION_CODEGEN_LITERAL_BYTES_OFFSET]
 add rdx,[rsp+24]
 movzx esi,byte [rdx+rax]
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 inc qword [rsp+32]
 mov rax,[rsp+32]
 cmp rax,[rsp+16]
 jae .byte_loop
 mov rdi,rbx
 lea rsi,[rel fcg_comma]
 mov edx,fcg_comma_len
 call fcg_append
 test eax,eax
 jnz .done
 jmp .byte_loop
.data_done:
 mov rdi,rbx
 lea rsi,[rel fcg_newline]
 mov edx,fcg_newline_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_prefix]
 mov edx,fcg_text_desc_prefix_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_mid]
 mov edx,fcg_text_desc_mid_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,r13
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_length]
 mov edx,fcg_text_desc_length_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+16]
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .writer
 mov rdi,rbx
 lea rsi,[rel fcg_text_desc_tail]
 mov edx,fcg_text_desc_tail_len
 call fcg_append
 test eax,eax
 jnz .done
 inc qword [rsp]
 inc qword [rbx+NEBOC_FUNCTION_CODEGEN_TEXT_LITERAL_COUNT_OFFSET]
.next:
 inc r13
 jmp .loop
.finish:
 cmp qword [rsp],0
 je .ok
 mov rdi,rbx
 lea rsi,[rel fcg_text_section]
 mov edx,fcg_text_section_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
 jmp .done
.writer:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
 jmp .done
.text_error:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TEXT_LITERAL
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 jmp .done
.bad:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_BAD_AST
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; state* -> status
fcg_emit_traps:
 push rbx
 mov rbx,rdi
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_OVERFLOW
 jz .divzero
 mov rdi,rbx
 lea rsi,[rel fcg_trap_overflow]
 mov edx,fcg_trap_overflow_len
 call fcg_append
 test eax,eax
 jnz .done
.divzero:
 test qword [rbx+NEBOC_FUNCTION_CODEGEN_TRAP_FLAGS_OFFSET],NEBOC_FUNCTION_CODEGEN_TRAP_DIV_ZERO
 jz .ok
 mov rdi,rbx
 lea rsi,[rel fcg_trap_divzero]
 mov edx,fcg_trap_divzero_len
 call fcg_append
 jmp .done
.ok:
 xor eax,eax
.done:
 pop rbx
 ret

; state*, bytes*, length -> status
fcg_append:
 push rbx
 mov rbx,rdi
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jz .done
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_WRITER
.done:
 pop rbx
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
