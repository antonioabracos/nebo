; rede_e_protocolos public CLI recognizer and exact diagnostic reporter; included by cli_driver.asm.
section .text
cli_recognize_net_port:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,4
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'n'
 je .tail
 cmp al,'N'
 jne .none
.tail:
 cmp byte [rbx+1],'e'
 jne .none
 cmp byte [rbx+2],'t'
 jne .none
 cmp byte [rbx+3],'.'
 jne .none
 mov qword [rel rede_e_protocolos_cli_found],1
 lea rdi,[rel rede_e_protocolos_cli_parse_request]
 mov ecx,neboc_rede_e_protocolos_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel rede_e_protocolos_cli_syntax]
 mov ecx,(neboc_rede_e_protocolos_SYNTAX_SIZE+neboc_rede_e_protocolos_RECORD_SIZE+neboc_rede_e_protocolos_SEM_SIZE+neboc_rede_e_protocolos_IR_SIZE+neboc_rede_e_protocolos_NATIVE_SIZE+neboc_rede_e_protocolos_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel rede_e_protocolos_cli_parse_request+neboc_rede_e_protocolos_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel rede_e_protocolos_cli_parse_request+neboc_rede_e_protocolos_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel rede_e_protocolos_cli_syntax]
 mov [rel rede_e_protocolos_cli_parse_request+neboc_rede_e_protocolos_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel rede_e_protocolos_cli_parse_request]
 call neboc_net_port_parse
 test eax,eax
 jnz .parser
 lea rdi,[rel rede_e_protocolos_cli_authority]
 mov rsi,[rel rede_e_protocolos_cli_syntax+neboc_rede_e_protocolos_SYNTAX_OPERATION_OFFSET]
 mov rdx,[rel rede_e_protocolos_cli_syntax+NEBOC_SYNTAX_PORT_OFFSET]
 mov rcx,[rel rede_e_protocolos_cli_syntax+neboc_rede_e_protocolos_SYNTAX_DIGIT_COUNT_OFFSET]
 mov r8,[rel rede_e_protocolos_cli_syntax+neboc_rede_e_protocolos_SYNTAX_LITERAL_HASH_OFFSET]
 mov r9d,neboc_rede_e_protocolos_REQUIRED_FLAGS
 call neboc_net_port_init
 test eax,eax
 jnz .type
 lea rdi,[rel rede_e_protocolos_cli_syntax]
 lea rsi,[rel rede_e_protocolos_cli_authority]
 lea rdx,[rel rede_e_protocolos_cli_semantic]
 call neboc_net_port_semantic_build
 test eax,eax
 jnz .semantic
 lea rdi,[rel rede_e_protocolos_cli_semantic]
 lea rsi,[rel rede_e_protocolos_cli_ir]
 call neboc_net_port_ir_lower
 test eax,eax
 jnz .ir
 lea rdi,[rel rede_e_protocolos_cli_ir]
 lea rsi,[rel rede_e_protocolos_cli_plan]
 call neboc_net_port_native_lower
 test eax,eax
 jnz .native
 lea rdi,[rel rede_e_protocolos_cli_plan]
 lea rsi,[rel rede_e_protocolos_cli_runtime_state]
 call neboc_net_port_runtime_execute
 test eax,eax
 jnz .runtime
 xor eax,eax
 jmp .done
.parser:
 mov rax,[rel rede_e_protocolos_cli_parse_request+neboc_rede_e_protocolos_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_rede_e_protocolos_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.type:
 mov eax,neboc_rede_e_protocolos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic:
 mov rax,[rel rede_e_protocolos_cli_semantic+neboc_rede_e_protocolos_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_rede_e_protocolos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir:
 mov rax,[rel rede_e_protocolos_cli_ir+neboc_rede_e_protocolos_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_rede_e_protocolos_DIAG_SECURITY_codegen_stdlib_x86_64
 jmp .publish
.native:
 mov rax,[rel rede_e_protocolos_cli_plan+neboc_rede_e_protocolos_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_rede_e_protocolos_DIAG_CODEGEN_codegen_stdlib_x86_64
 jmp .publish
.runtime:
 mov rax,[rel rede_e_protocolos_cli_runtime_state+neboc_rede_e_protocolos_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_rede_e_protocolos_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel rede_e_protocolos_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
rede_e_protocolos_cli_report_frontend_diagnostic:
 mov rax,[rel rede_e_protocolos_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,neboc_rede_e_protocolos_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_rede_e_protocolos_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_rede_e_protocolos_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_rede_e_protocolos_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_rede_e_protocolos_DIAG_SECURITY_codegen_stdlib_x86_64
 je .security
 lea rdi,[rel rede_e_protocolos_cli_error_codegen]
 mov esi,rede_e_protocolos_cli_error_codegen_end-rede_e_protocolos_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel rede_e_protocolos_cli_error_lex]
 mov esi,rede_e_protocolos_cli_error_lex_end-rede_e_protocolos_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel rede_e_protocolos_cli_error_parse]
 mov esi,rede_e_protocolos_cli_error_parse_end-rede_e_protocolos_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel rede_e_protocolos_cli_error_type]
 mov esi,rede_e_protocolos_cli_error_type_end-rede_e_protocolos_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel rede_e_protocolos_cli_error_runtime]
 mov esi,rede_e_protocolos_cli_error_runtime_end-rede_e_protocolos_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel rede_e_protocolos_cli_error_security]
 mov esi,rede_e_protocolos_cli_error_security_end-rede_e_protocolos_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret
%undef call
