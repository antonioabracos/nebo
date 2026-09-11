; Typed scalar source program. Each complete statement becomes one immutable
; record (operation, type, terminal, operands[3], source start, source end).
; Literal arguments are bounded to Int64 / canonical binary64. The parser
; consumes every token; lowering never rescans source or selects a seed.
%define SP_CAPACITY 128
%define SP_SIZE 64
%define SP_OP 0
%define SP_TYPE 8
%define SP_RETURN 16
%define SP_ARGS 24
%define SP_START 48
%define SP_END 56
%define SP_INT 1
%define SP_FLOAT 2
section .bss align=16
sp_records: resb SP_CAPACITY*SP_SIZE
sp_count: resq 1
sp_found: resq 1
sp_math_seen: resq 1
sp_diagnostic: resq 1
sp_error_start: resq 1
sp_error_end: resq 1
section .rodata
sp_std: db 'std'
sp_math: db 'math'
%macro SP_OPERATION 4
sp_name_%1: db %2
sp_name_%1_len equ $-sp_name_%1
%endmacro
SP_OPERATION abs,'abs',1,1
SP_OPERATION clamp,'clamp',3,1
SP_OPERATION min,'min',2,1
SP_OPERATION max,'max',2,1
SP_OPERATION sqrt,'sqrt',1,2
SP_OPERATION pow,'pow',2,2
SP_OPERATION hypot,'hypot',2,2
SP_OPERATION sin,'sin',1,2
SP_OPERATION cos,'cos',1,2
SP_OPERATION tan,'tan',1,2
SP_OPERATION atan2,'atan2',2,2
SP_OPERATION exp,'exp',1,2
SP_OPERATION log,'log',1,2
SP_OPERATION log2,'log2',1,2
%undef SP_OPERATION
section .text
%macro SP_KIND 1
 cmp rbx,r14
 jae .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],%1
 jne .not_owned
 add rbx,NEBOC_TOKEN_SIZE
%endmacro
%macro SP_NAME 2
 cmp rbx,r14
 jae .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .not_owned
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%2
 call cli_token_equals
 test eax,eax
 jz .not_owned
 add rbx,NEBOC_TOKEN_SIZE
%endmacro
cli_recognize_scalar_program:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov qword [rel sp_count],0
 mov qword [rel sp_found],0
 mov qword [rel sp_math_seen],0
 mov qword [rel sp_diagnostic],0
 mov qword [rel sp_error_start],0
 mov qword [rel sp_error_end],0
 lea rbx,[rel cli_tokens]
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 imul rax,NEBOC_TOKEN_SIZE
 lea r14,[rbx+rax]
 SP_KIND NEBOC_TOKEN_KW_START
 SP_KIND NEBOC_TOKEN_LPAREN
 SP_KIND NEBOC_TOKEN_RPAREN
 SP_KIND NEBOC_TOKEN_LBRACE
 ; A namespace witness chooses the grammar, never the result. Once selected,
 ; failure cannot be reinterpreted by a legacy whole-file mode/seed owner.
 call sp_contains_namespace
 mov [rel sp_math_seen],rax
.statement:
 cmp rbx,r14
 jae .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 je .finish
 mov rax,[rel sp_count]
 cmp rax,SP_CAPACITY
 jae .capacity_error
 imul rax,SP_SIZE
 lea r15,[rel sp_records]
 add r15,rax
 mov rdi,r15
 xor eax,eax
 mov ecx,SP_SIZE/8
 rep stosq
 mov rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov [r15+SP_START],rax
 mov [rel sp_error_start],rax
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 je .math
 call sp_literal
 test ecx,ecx
 jz .literal_type_error
 mov [r15+SP_TYPE],rcx
 mov [r15+SP_ARGS],rax
 jmp .terminal
.math:
 SP_NAME sp_std,3
 SP_KIND NEBOC_TOKEN_DOT
 SP_NAME sp_math,4
 SP_KIND NEBOC_TOKEN_DOT
 cmp rbx,r14
 jae .not_owned
%macro SP_SELECT 4
 mov rdi,rbx
 lea rsi,[rel sp_name_%1]
 mov edx,sp_name_%1_len
 call cli_token_equals
 mov r12d,%3
 mov r13d,%4
 mov qword [r15+SP_OP],%2
 test eax,eax
 jnz .operation
%endmacro
 SP_SELECT abs,1,1,SP_INT
 SP_SELECT clamp,2,3,SP_INT
 SP_SELECT min,3,2,SP_INT
 SP_SELECT max,4,2,SP_INT
 SP_SELECT sqrt,5,1,SP_FLOAT
 SP_SELECT pow,6,2,SP_FLOAT
 SP_SELECT hypot,7,2,SP_FLOAT
 SP_SELECT sin,8,1,SP_FLOAT
 SP_SELECT cos,9,1,SP_FLOAT
 SP_SELECT tan,10,1,SP_FLOAT
 SP_SELECT atan2,11,2,SP_FLOAT
 SP_SELECT exp,12,1,SP_FLOAT
 SP_SELECT log,13,1,SP_FLOAT
 SP_SELECT log2,14,1,SP_FLOAT
 jmp .not_owned
.operation:
 mov qword [rel sp_math_seen],1
 mov [r15+SP_TYPE],r13
 add rbx,NEBOC_TOKEN_SIZE
 SP_KIND NEBOC_TOKEN_LPAREN
 mov qword [rsp],0
.argument:
 call sp_literal
 test ecx,ecx
 jz .not_owned
 cmp rcx,r13
 jne .type_error
 mov rdx,[rsp]
 mov [r15+SP_ARGS+rdx*8],rax
 inc qword [rsp]
 cmp [rsp],r12
 je .arguments_done
 SP_KIND NEBOC_TOKEN_COMMA
 jmp .argument
.arguments_done:
 SP_KIND NEBOC_TOKEN_RPAREN
 ; Preserve the existing checked literal integer domains at semantic time.
 cmp qword [r15+SP_OP],1
 jne .clamp_domain
 mov rax,0x8000000000000000
 cmp [r15+SP_ARGS],rax
 je .not_owned
.clamp_domain:
 cmp qword [r15+SP_OP],2
 jne .terminal
 mov rax,[r15+SP_ARGS+8]
 cmp rax,[r15+SP_ARGS+16]
 jg .not_owned
.terminal:
 cmp rbx,r14
 jae .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .semicolon
 add rbx,NEBOC_TOKEN_SIZE
 SP_KIND NEBOC_TOKEN_KW_RETURN
 cmp qword [r15+SP_TYPE],SP_INT
 jne .type_error
 mov qword [r15+SP_RETURN],1
.semicolon:
 SP_KIND NEBOC_TOKEN_SEMICOLON
 mov rax,[rbx-NEBOC_TOKEN_SIZE+NEBOC_TOKEN_END_OFFSET]
 mov [r15+SP_END],rax
 inc qword [rel sp_count]
 cmp qword [r15+SP_RETURN],0
 je .statement
 ; The terminal return is consumed exactly once; trailing statements reject.
 cmp rbx,r14
 jae .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_RBRACE
 jne .not_owned
.finish:
 SP_KIND NEBOC_TOKEN_RBRACE
 SP_KIND NEBOC_TOKEN_EOF
 cmp rbx,r14
 jne .not_owned
 cmp qword [rel sp_math_seen],0
 je .not_owned
 mov qword [rel sp_found],1
 mov qword [rel biblioteca_padrao_por_dominios_cli_found],1
 jmp .success
.literal_type_error:
 ; A terminal Text return is a semantic mismatch, not an absent math owner.
 lea rax,[rbx+3*NEBOC_TOKEN_SIZE]
 cmp rax,r14
 ja .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_TEXT
 jne .not_owned
 cmp qword [rbx+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .not_owned
 cmp qword [rbx+2*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_KW_RETURN
 jne .not_owned
 mov qword [rel sp_math_seen],1
.type_error:
 mov qword [rel sp_diagnostic],NEBOC_DIAG_TYPE_MISMATCH
 jmp .not_owned
.capacity_error:
 mov qword [rel sp_diagnostic],NEBOC_DIAG_LIMIT_EXCEEDED
.not_owned:
 cmp qword [rel sp_math_seen],0
 je .declined
 cmp qword [rel sp_diagnostic],0
 jne .diagnostic_ready
 mov qword [rel sp_diagnostic],NEBOC_DIAG_PARSE_UNEXPECTED_TOKEN
.diagnostic_ready:
 mov rax,[rel sp_error_start]
 cmp rbx,r14
 jae .end_span
 mov rax,[rbx+NEBOC_TOKEN_END_OFFSET]
.end_span:
 mov [rel sp_error_end],rax
 mov eax,1
 jmp .done
.declined:
 mov qword [rel sp_diagnostic],0
.success:
 xor eax,eax
.done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

sp_contains_namespace:
 push rbx
.scan:
 lea rax,[rbx+4*NEBOC_TOKEN_SIZE]
 cmp rax,r14
 ja .no
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_IDENTIFIER
 jne .next
 cmp qword [rbx+NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 cmp qword [rbx+3*NEBOC_TOKEN_SIZE+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .next
 mov rdi,rbx
 lea rsi,[rel sp_std]
 mov edx,3
 call cli_token_equals
 test eax,eax
 jz .next
 lea rdi,[rbx+2*NEBOC_TOKEN_SIZE]
 lea rsi,[rel sp_math]
 mov edx,4
 call cli_token_equals
 test eax,eax
 jnz .yes
.next:
 add rbx,NEBOC_TOKEN_SIZE
 jmp .scan
.no:
 xor eax,eax
 jmp .done
.yes:
 mov eax,1
.done:
 pop rbx
 ret

; RBX cursor / R14 end -> RAX bits and ECX scalar type, or ECX=0.
; Advance only within the authenticated token extent; retain signed values.
sp_literal:
 push r12
 sub rsp,16
 xor r12d,r12d
 cmp rbx,r14
 jae .bad
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .kind
 mov r12d,1
 add rbx,NEBOC_TOKEN_SIZE
.kind:
 cmp rbx,r14
 jae .bad
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_FLOAT
 je .float
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .bad
 mov rax,[rbx+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test r12d,r12d
 jz .positive
 mov rdx,0x8000000000000000
 cmp rax,rdx
 ja .bad
 neg rax
 jmp .integer_done
.positive:
 test rax,rax
 js .bad
.integer_done:
 mov ecx,SP_INT
 jmp .done
.float:
 lea rdi,[rel cli_float_lowering_request]
 xor eax,eax
 mov ecx,NEBOC_FLOAT_LOWERING_REQUEST_QWORDS
 rep stosq
 mov rax,[rbx+NEBOC_TOKEN_START_OFFSET]
 mov rdx,[rbx+NEBOC_TOKEN_END_OFFSET]
 sub rdx,rax
 lea rcx,[rel cli_source]
 add rax,rcx
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_SOURCE_OFFSET],rax
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_LENGTH_OFFSET],rdx
 lea rax,[rel cli_float_lowering_bits]
 mov [rel cli_float_lowering_request+NEBOC_FLOAT_LOWERING_REQUEST_OUT_BITS_OFFSET],rax
 lea rdi,[rel cli_float_lowering_request]
 call neboc_foundation_float_materialize_literal
 test eax,eax
 jnz .bad
 mov rax,[rel cli_float_lowering_bits]
 test r12d,r12d
 jz .float_done
 btc rax,63
.float_done:
 mov ecx,SP_FLOAT
.done:
 add rbx,NEBOC_TOKEN_SIZE
 jmp .return
.bad:
 xor ecx,ecx
.return:
 add rsp,16
 pop r12
 ret
%undef SP_KIND
%undef SP_NAME
%undef SP_SELECT

; Native lowering reads typed records only. System V argument registers are
; explicit; helper status is checked separately from the mathematical result.
section .rodata
%macro SP_TEXT 2+
%1: db %2
%1_len equ $-%1
%endmacro
SP_TEXT sp_header,10,'extern nebo_math_abs_i64',10,'extern nebo_math_clamp_i64',10,'extern nebo_math_min_i64',10,'extern nebo_math_max_i64',10,'extern nebo_math_sqrt_f64',10,'extern nebo_math_pow_f64',10,'extern nebo_math_hypot_f64',10,'extern nebo_math_sin_f64',10,'extern nebo_math_cos_f64',10,'extern nebo_math_tan_f64',10,'extern nebo_math_atan2_f64',10,'extern nebo_math_exp_f64',10,'extern nebo_math_log_f64',10,'extern nebo_math_log2_f64',10,'extern nebo_runtime_math_observe',10,'section .text',10,'global nebo_fn_1',10,'nebo_fn_1:',10,'    sub rsp, 8',10
SP_TEXT sp_mov_rax,'    mov rax, '
SP_TEXT sp_mov_rdi,'    mov rdi, '
SP_TEXT sp_mov_rsi,'    mov rsi, '
SP_TEXT sp_mov_rdx,'    mov rdx, '
SP_TEXT sp_newline,10
SP_TEXT sp_xmm0,'    movq xmm0, rax',10
SP_TEXT sp_xmm1,'    movq xmm1, rax',10
SP_TEXT sp_abs_call,'    call nebo_math_abs_i64',10,'    test eax, eax',10,'    jnz .math_failure',10,'    mov rax, rdx',10
SP_TEXT sp_clamp_call,'    call nebo_math_clamp_i64',10,'    test eax, eax',10,'    jnz .math_failure',10,'    mov rax, rdx',10
SP_TEXT sp_min_call,'    call nebo_math_min_i64',10
SP_TEXT sp_max_call,'    call nebo_math_max_i64',10
SP_TEXT sp_sqrt_call,'    call nebo_math_sqrt_f64',10
SP_TEXT sp_pow_call,'    call nebo_math_pow_f64',10
SP_TEXT sp_hypot_call,'    call nebo_math_hypot_f64',10
SP_TEXT sp_sin_call,'    call nebo_math_sin_f64',10
SP_TEXT sp_cos_call,'    call nebo_math_cos_f64',10
SP_TEXT sp_tan_call,'    call nebo_math_tan_f64',10
SP_TEXT sp_atan2_call,'    call nebo_math_atan2_f64',10
SP_TEXT sp_exp_call,'    call nebo_math_exp_f64',10
SP_TEXT sp_log_call,'    call nebo_math_log_f64',10
SP_TEXT sp_log2_call,'    call nebo_math_log2_f64',10
SP_TEXT sp_float_result,'    test eax, eax',10,'    jnz .math_failure',10,'    movq rax, xmm0',10
SP_TEXT sp_save,'    mov [rsp], rax',10
SP_TEXT sp_observe,'    mov rdx, [rsp]',10,'    call nebo_runtime_math_observe',10,'    mov rax, [rsp]',10
SP_TEXT sp_zero,'    xor eax, eax',10
SP_TEXT sp_end,'    add rsp, 8',10,'    ret',10,'.math_failure:',10,'    add rsp, 8',10,'    jmp nebo_runtime_trap_arithmetic_domain',10
%undef SP_TEXT
section .text
%macro SP_EMIT 1
 lea rdi,[rel cli_writer]
 lea rsi,[rel %1]
 mov edx,%1_len
 call neboc_assembly_writer_append_bytes
 test eax,eax
 jnz .bad
%endmacro
%macro SP_NUMBER 1
 lea rdi,[rel cli_writer]
 mov rsi,%1
 call neboc_assembly_writer_append_u64_decimal
 test eax,eax
 jnz .bad
 SP_EMIT sp_newline
%endmacro
cli_emit_scalar_program:
 push rbx
 push r12
 push r13
 SP_EMIT sp_header
 lea rbx,[rel sp_records]
 xor r12d,r12d
.record:
 cmp r12,[rel sp_count]
 jae .finish
 mov r13,[rbx+SP_OP]
 test r13,r13
 jnz .arguments
 SP_EMIT sp_mov_rax
 SP_NUMBER [rbx+SP_ARGS]
 jmp .next
.arguments:
 cmp qword [rbx+SP_TYPE],SP_FLOAT
 je .float_arguments
 SP_EMIT sp_mov_rdi
 SP_NUMBER [rbx+SP_ARGS]
 cmp r13,1
 je .abs
 SP_EMIT sp_mov_rsi
 SP_NUMBER [rbx+SP_ARGS+8]
 cmp r13,2
 jne .integer_binary
 SP_EMIT sp_mov_rdx
 SP_NUMBER [rbx+SP_ARGS+16]
 SP_EMIT sp_clamp_call
 jmp .observe
.integer_binary:
 cmp r13,3
 jne .max
 SP_EMIT sp_min_call
 jmp .observe
.max:
 SP_EMIT sp_max_call
 jmp .observe
.abs:
 SP_EMIT sp_abs_call
 jmp .observe
.float_arguments:
 SP_EMIT sp_mov_rax
 SP_NUMBER [rbx+SP_ARGS]
 SP_EMIT sp_xmm0
 cmp r13,6
 je .float_second
 cmp r13,7
 je .float_second
 cmp r13,11
 jne .float_dispatch
.float_second:
 SP_EMIT sp_mov_rax
 SP_NUMBER [rbx+SP_ARGS+8]
 SP_EMIT sp_xmm1
.float_dispatch:
 cmp r13,5
 je .call_sqrt
 cmp r13,6
 je .call_pow
 cmp r13,7
 je .call_hypot
 cmp r13,8
 je .call_sin
 cmp r13,9
 je .call_cos
 cmp r13,10
 je .call_tan
 cmp r13,11
 je .call_atan2
 cmp r13,12
 je .call_exp
 cmp r13,13
 je .call_log
 cmp r13,14
 je .call_log2
 jmp .bad
.call_sqrt:
 SP_EMIT sp_sqrt_call
 jmp .float_result
.call_pow:
 SP_EMIT sp_pow_call
 jmp .float_result
.call_hypot:
 SP_EMIT sp_hypot_call
 jmp .float_result
.call_sin:
 SP_EMIT sp_sin_call
 jmp .float_result
.call_cos:
 SP_EMIT sp_cos_call
 jmp .float_result
.call_tan:
 SP_EMIT sp_tan_call
 jmp .float_result
.call_atan2:
 SP_EMIT sp_atan2_call
 jmp .float_result
.call_exp:
 SP_EMIT sp_exp_call
 jmp .float_result
.call_log:
 SP_EMIT sp_log_call
 jmp .float_result
.call_log2:
 SP_EMIT sp_log2_call
 jmp .float_result
.float_result:
 SP_EMIT sp_float_result
.observe:
 SP_EMIT sp_save
 SP_EMIT sp_mov_rdi
 SP_NUMBER r13
 SP_EMIT sp_mov_rsi
 SP_NUMBER [rbx+SP_TYPE]
 SP_EMIT sp_observe
.next:
 inc r12
 add rbx,SP_SIZE
 cmp qword [rbx-SP_SIZE+SP_RETURN],0
 je .record
 ; Lower the typed terminal explicitly. A malformed internal sequence with
 ; records after a return must fail, even if parser ownership is later changed.
 cmp r12,[rel sp_count]
 jne .bad
 cmp qword [rbx-SP_SIZE+SP_TYPE],SP_INT
 jne .bad
 jmp .epilogue
.finish:
 ; Explicit return is Int. A trailing Float expression has no process status.
 cmp qword [rbx-SP_SIZE+SP_TYPE],SP_INT
 je .epilogue
 SP_EMIT sp_zero
.epilogue:
 SP_EMIT sp_end
 xor eax,eax
 jmp .done
.bad:
 mov eax,1
.done:
 pop r13
 pop r12
 pop rbx
 ret
%undef SP_EMIT
%undef SP_NUMBER
