; Shared typed Float values reuse the foundation decimal materializer and
; its IEEE-754 binary64/SSE2 arithmetic contract. RAX carries canonical bits
; between generic value owners; XMM0 is available to native Float callees.
extern neboc_foundation_float_materialize_literal
section .rodata
fcg_aligned_binary_save equ fcg_assignment_save
fcg_aligned_binary_save_len equ fcg_assignment_save_len
fcg_aligned_binary_restore equ fcg_assignment_restore
fcg_aligned_binary_restore_len equ fcg_assignment_restore_len
fv_operands: db '    movq xmm0, rax',10,'    movq xmm1, rcx',10
fv_operands_len equ $-fv_operands
fv_to_xmm: db 10,'    movq xmm0, rax',10
fv_to_xmm_len equ $-fv_to_xmm
fv_add: db '    addsd xmm0, xmm1',10,'    movq rax, xmm0',10
fv_add_len equ $-fv_add
fv_sub: db '    subsd xmm0, xmm1',10,'    movq rax, xmm0',10
fv_sub_len equ $-fv_sub
fv_mul: db '    mulsd xmm0, xmm1',10,'    movq rax, xmm0',10
fv_mul_len equ $-fv_mul
fv_div: db '    divsd xmm0, xmm1',10,'    movq rax, xmm0',10
fv_div_len equ $-fv_div
fv_power:
 db '    mov rdi, rax',10,'    mov rsi, rcx',10,'    call nebo_runtime_checked_float_power_int',10
fv_power_len equ $-fv_power
fv_eq: db '    ucomisd xmm0, xmm1',10,'    sete al',10,'    setnp dl',10,'    and al, dl',10,'    movzx eax, al',10
fv_eq_len equ $-fv_eq
fv_ne: db '    ucomisd xmm0, xmm1',10,'    setne al',10,'    setp dl',10,'    or al, dl',10,'    movzx eax, al',10
fv_ne_len equ $-fv_ne
fv_lt: db '    ucomisd xmm0, xmm1',10,'    setb al',10,'    setnp dl',10,'    and al, dl',10,'    movzx eax, al',10
fv_lt_len equ $-fv_lt
fv_le: db '    ucomisd xmm0, xmm1',10,'    setbe al',10,'    setnp dl',10,'    and al, dl',10,'    movzx eax, al',10
fv_le_len equ $-fv_le
fv_gt: db '    ucomisd xmm0, xmm1',10,'    seta al',10,'    movzx eax, al',10
fv_gt_len equ $-fv_gt
fv_ge: db '    ucomisd xmm0, xmm1',10,'    setae al',10,'    movzx eax, al',10
fv_ge_len equ $-fv_ge
section .text
; state*, authenticated FloatLiteral AstNode* -> status.
fcg_emit_float_literal:
 push rbx
 push r12
 sub rsp,88
 mov rbx,rdi
 mov r12,rsi
 mov rdi,rsp
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 mov rax,[r12+NEBOC_AST_NODE_START_OFFSET]
 mov rdx,[r12+NEBOC_AST_NODE_END_OFFSET]
 sub rdx,rax
 add rax,[rbx+NEBOC_FUNCTION_CODEGEN_SOURCE_OFFSET]
 mov [rsp+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rax
 mov [rsp+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 lea rax,[rsp+64]
 mov [rsp+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 mov rdi,rsp
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .invalid
 mov rdi,rbx
 lea rsi,[rel fcg_mov_rax]
 mov edx,fcg_mov_rax_len
 call fcg_append
 test eax,eax
 jnz .done
 mov rdi,[rbx+NEBOC_FUNCTION_CODEGEN_WRITER_OFFSET]
 mov rsi,[rsp+64]
 call neboc_assembly_writer_append_i64_decimal
 test eax,eax
 jnz .done
 mov rdi,rbx
 lea rsi,[rel fv_to_xmm]
 mov edx,fv_to_xmm_len
 call fcg_append
 jmp .done
.invalid:
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_TYPE_ASSERTION
.done:
 add rsp,88
 pop r12
 pop rbx
 ret

; state*, exact operator kind. Both operand types were independently checked.
fcg_emit_float_binary:
 push rbx
 push r12
 sub rsp,8
 mov rbx,rdi
 mov r12,rsi
 lea rsi,[rel fv_operands]
 mov edx,fv_operands_len
 call fcg_append
 test eax,eax
 jnz .done
%macro FV_OPERATION 2
 cmp r12,%1
 jne %%next
 mov rdi,rbx
 lea rsi,[rel %2]
 mov edx,%2 %+ _len
 call fcg_append
 jmp .done
%%next:
%endmacro
 FV_OPERATION NEBOC_TOKEN_PLUS,fv_add
 FV_OPERATION NEBOC_TOKEN_MINUS,fv_sub
 FV_OPERATION NEBOC_TOKEN_STAR,fv_mul
 FV_OPERATION NEBOC_TOKEN_SLASH,fv_div
 FV_OPERATION NEBOC_TOKEN_CARET,fv_power
 FV_OPERATION NEBOC_TOKEN_EQUAL_EQUAL,fv_eq
 FV_OPERATION NEBOC_TOKEN_BANG_EQUAL,fv_ne
 FV_OPERATION NEBOC_TOKEN_LESS,fv_lt
 FV_OPERATION NEBOC_TOKEN_LESS_EQUAL,fv_le
 FV_OPERATION NEBOC_TOKEN_GREATER,fv_gt
 FV_OPERATION NEBOC_TOKEN_GREATER_EQUAL,fv_ge
%undef FV_OPERATION
 mov qword [rbx+NEBOC_FUNCTION_CODEGEN_LAST_ERROR_OFFSET],NEBOC_FUNCTION_CODEGEN_ERROR_UNSUPPORTED_TYPE
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 add rsp,8
 pop r12
 pop rbx
 ret
