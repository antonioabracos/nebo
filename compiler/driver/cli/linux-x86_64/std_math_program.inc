; A bounded, token-parsed entry to the existing pure integer std.math owner.
; Grammar: start() { std.math.{abs,clamp,min,max}(signed Int literals)[.return]; }
; The entire token stream must be consumed. No fixture names, seed values,
; ignored statements, or synthetic native self-tests participate in lowering.
section .rodata
smp_std: db 'std'
smp_math: db 'math'
smp_abs: db 'abs'
smp_clamp: db 'clamp'
smp_min: db 'min'
smp_max: db 'max'

section .text
%macro SMP_KIND 1
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],%1
 jne .not_owned
 add rbx,NEBOC_TOKEN_SIZE
%endmacro
%macro SMP_NAME 2
 mov rdi,rbx
 lea rsi,[rel %1]
 mov edx,%2
 call cli_token_equals
 test eax,eax
 jz .not_owned
 add rbx,NEBOC_TOKEN_SIZE
%endmacro

cli_recognize_std_math_program:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,88
 cld
 mov rax,[rel cli_lexer_request+NEBOC_LEXER_REQUEST_COUNT_OFFSET]
 ; The largest accepted stream has three signed arguments and .return.
 cmp rax,15
 jb .not_owned
 cmp rax,24
 ja .not_owned
 imul rax,NEBOC_TOKEN_SIZE
 lea rbx,[rel cli_tokens]
 lea r14,[rbx+rax]
 mov rdi,rsp
 mov ecx,neboc_biblioteca_padrao_por_dominios_SYNTAX_QWORDS
 xor eax,eax
 rep stosq
 SMP_KIND NEBOC_TOKEN_KW_START
 SMP_KIND NEBOC_TOKEN_LPAREN
 SMP_KIND NEBOC_TOKEN_RPAREN
 SMP_KIND NEBOC_TOKEN_LBRACE
 SMP_NAME smp_std,3
 SMP_KIND NEBOC_TOKEN_DOT
 SMP_NAME smp_math,4
 SMP_KIND NEBOC_TOKEN_DOT
 mov rdi,rbx
 lea rsi,[rel smp_abs]
 mov edx,3
 call cli_token_equals
 mov r12d,NEBOC_OP_ABS
 mov r13d,1
 test eax,eax
 jnz .operation
 mov rdi,rbx
 lea rsi,[rel smp_clamp]
 mov edx,5
 call cli_token_equals
 mov r12d,NEBOC_OP_CLAMP
 mov r13d,3
 test eax,eax
 jnz .operation
 mov rdi,rbx
 lea rsi,[rel smp_min]
 mov edx,3
 call cli_token_equals
 mov r12d,NEBOC_OP_MIN
 mov r13d,2
 test eax,eax
 jnz .operation
 mov rdi,rbx
 lea rsi,[rel smp_max]
 mov edx,3
 call cli_token_equals
 mov r12d,NEBOC_OP_MAX
 test eax,eax
 jz .not_owned
.operation:
 mov [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_OPERATION_OFFSET],r12
 mov [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_ARITY_OFFSET],r13
 add rbx,NEBOC_TOKEN_SIZE
 SMP_KIND NEBOC_TOKEN_LPAREN
 xor r12d,r12d
.argument:
 ; Reserve room for the integer, closing tokens and EOF before any read.
 lea rax,[rbx+4*NEBOC_TOKEN_SIZE]
 cmp rax,r14
 ja .not_owned
 xor edx,edx
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_MINUS
 jne .unsigned
 mov edx,1
 add rbx,NEBOC_TOKEN_SIZE
.unsigned:
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_INTEGER
 jne .not_owned
 mov rax,[rbx+NEBOC_TOKEN_PAYLOAD_OFFSET]
 test edx,edx
 jz .positive
 mov rcx,0x8000000000000000
 cmp rax,rcx
 ja .not_owned
 neg rax
 jmp .value
.positive:
 test rax,rax
 js .not_owned
.value:
 mov [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_VALUE_OFFSET+r12*8],rax
 add rbx,NEBOC_TOKEN_SIZE
 inc r12
 cmp r12,r13
 je .arguments_done
 SMP_KIND NEBOC_TOKEN_COMMA
 jmp .argument
.arguments_done:
 ; From this point, every optional token is bounds checked.
 SMP_KIND NEBOC_TOKEN_RPAREN
 lea rax,[rbx+3*NEBOC_TOKEN_SIZE]
 cmp rax,r14
 ja .not_owned
 cmp qword [rbx+NEBOC_TOKEN_KIND_OFFSET],NEBOC_TOKEN_DOT
 jne .semicolon
 add rbx,NEBOC_TOKEN_SIZE
 SMP_KIND NEBOC_TOKEN_KW_RETURN
 lea rax,[rbx+3*NEBOC_TOKEN_SIZE]
 cmp rax,r14
 ja .not_owned
.semicolon:
 SMP_KIND NEBOC_TOKEN_SEMICOLON
 SMP_KIND NEBOC_TOKEN_RBRACE
 SMP_KIND NEBOC_TOKEN_EOF
 cmp rbx,r14
 jne .not_owned
 mov qword [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_FLAGS_OFFSET],neboc_biblioteca_padrao_por_dominios_SYNTAX_REQUIRED_FLAGS
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_STATEMENT_LENGTH_OFFSET],rax
 ; Authenticate the same syntax record consumed by the existing semantic owner.
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.hash:
 cmp ecx,neboc_biblioteca_padrao_por_dominios_SYNTAX_HASHED_BYTES
 jae .publish
 movzx edx,byte [rsp+rcx]
 xor rax,rdx
 imul rax,r8
 inc ecx
 jmp .hash
.publish:
 mov [rsp+neboc_biblioteca_padrao_por_dominios_SYNTAX_SHAPE_HASH_OFFSET],rax
 lea rdi,[rel biblioteca_padrao_por_dominios_cli_syntax]
 mov rsi,rsp
 mov ecx,neboc_biblioteca_padrao_por_dominios_SYNTAX_QWORDS
 rep movsq
 mov qword [rel biblioteca_padrao_por_dominios_cli_found],1
 add rsp,88
 pop r14
 pop r13
 pop r12
 ; The shared semantic/lowering continuation owns the remaining saved RBX.
 jmp cli_recognize_std_math.lower_syntax
.not_owned:
 xor eax,eax
 add rsp,88
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

%undef SMP_NAME
%undef SMP_KIND
