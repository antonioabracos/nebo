; filesystem_paths_e_formatos public CLI recognizer and exact diagnostic reporter; included by cli_driver.asm.
section .text
cli_recognize_path_query:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,5
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'p'
 je .tail
 cmp al,'P'
 jne .none
.tail:
 cmp byte [rbx+1],'a'
 jne .none
 cmp byte [rbx+2],'t'
 jne .none
 cmp byte [rbx+3],'h'
 jne .none
 cmp byte [rbx+4],'.'
 jne .none
 mov qword [rel filesystem_paths_e_formatos_cli_found],1
 lea rdi,[rel filesystem_paths_e_formatos_cli_parse_request]
 mov ecx,neboc_filesystem_paths_e_formatos_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel filesystem_paths_e_formatos_cli_syntax]
 mov ecx,(neboc_filesystem_paths_e_formatos_SYNTAX_SIZE+neboc_filesystem_paths_e_formatos_RECORD_SIZE+neboc_filesystem_paths_e_formatos_SEM_SIZE+neboc_filesystem_paths_e_formatos_IR_SIZE+neboc_filesystem_paths_e_formatos_NATIVE_SIZE+neboc_filesystem_paths_e_formatos_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel filesystem_paths_e_formatos_cli_parse_request+neboc_filesystem_paths_e_formatos_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel filesystem_paths_e_formatos_cli_parse_request+neboc_filesystem_paths_e_formatos_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel filesystem_paths_e_formatos_cli_syntax]
 mov [rel filesystem_paths_e_formatos_cli_parse_request+neboc_filesystem_paths_e_formatos_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel filesystem_paths_e_formatos_cli_parse_request]
 call neboc_path_query_parse
 test eax,eax
 jnz .parser
 lea rdi,[rel filesystem_paths_e_formatos_cli_authority]
 mov rsi,[rel filesystem_paths_e_formatos_cli_syntax+neboc_filesystem_paths_e_formatos_SYNTAX_OPERATION_OFFSET]
 mov rdx,[rel filesystem_paths_e_formatos_cli_syntax+NEBOC_SYNTAX_DEPTH_OFFSET]
 mov rcx,[rel filesystem_paths_e_formatos_cli_syntax+NEBOC_SYNTAX_ABSOLUTE_OFFSET]
 mov r8,[rel filesystem_paths_e_formatos_cli_syntax+NEBOC_SYNTAX_PATH_HASH_OFFSET]
 mov r9d,neboc_filesystem_paths_e_formatos_REQUIRED_FLAGS
 call neboc_path_query_init
 test eax,eax
 jnz .type
 lea rdi,[rel filesystem_paths_e_formatos_cli_syntax]
 lea rsi,[rel filesystem_paths_e_formatos_cli_authority]
 lea rdx,[rel filesystem_paths_e_formatos_cli_semantic]
 call neboc_path_query_semantic_build
 test eax,eax
 jnz .semantic
 lea rdi,[rel filesystem_paths_e_formatos_cli_semantic]
 lea rsi,[rel filesystem_paths_e_formatos_cli_ir]
 call neboc_path_query_ir_lower
 test eax,eax
 jnz .ir
 lea rdi,[rel filesystem_paths_e_formatos_cli_ir]
 lea rsi,[rel filesystem_paths_e_formatos_cli_plan]
 call neboc_path_query_native_lower
 test eax,eax
 jnz .native
 lea rdi,[rel filesystem_paths_e_formatos_cli_plan]
 lea rsi,[rel filesystem_paths_e_formatos_cli_runtime_state]
 call neboc_path_query_runtime_execute
 test eax,eax
 jnz .runtime
 xor eax,eax
 jmp .done
.parser:
 mov rax,[rel filesystem_paths_e_formatos_cli_parse_request+neboc_filesystem_paths_e_formatos_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.type:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic:
 mov rax,[rel filesystem_paths_e_formatos_cli_semantic+neboc_filesystem_paths_e_formatos_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir:
 mov rax,[rel filesystem_paths_e_formatos_cli_ir+neboc_filesystem_paths_e_formatos_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_SECURITY_codegen_stdlib_x86_64
 jmp .publish
.native:
 mov rax,[rel filesystem_paths_e_formatos_cli_plan+neboc_filesystem_paths_e_formatos_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_CODEGEN_codegen_stdlib_x86_64
 jmp .publish
.runtime:
 mov rax,[rel filesystem_paths_e_formatos_cli_runtime_state+neboc_filesystem_paths_e_formatos_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel filesystem_paths_e_formatos_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
filesystem_paths_e_formatos_cli_report_frontend_diagnostic:
 mov rax,[rel filesystem_paths_e_formatos_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,neboc_filesystem_paths_e_formatos_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_filesystem_paths_e_formatos_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_filesystem_paths_e_formatos_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_filesystem_paths_e_formatos_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_filesystem_paths_e_formatos_DIAG_SECURITY_codegen_stdlib_x86_64
 je .security
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_codegen]
 mov esi,filesystem_paths_e_formatos_cli_error_codegen_end-filesystem_paths_e_formatos_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_lex]
 mov esi,filesystem_paths_e_formatos_cli_error_lex_end-filesystem_paths_e_formatos_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_parse]
 mov esi,filesystem_paths_e_formatos_cli_error_parse_end-filesystem_paths_e_formatos_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_type]
 mov esi,filesystem_paths_e_formatos_cli_error_type_end-filesystem_paths_e_formatos_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_runtime]
 mov esi,filesystem_paths_e_formatos_cli_error_runtime_end-filesystem_paths_e_formatos_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel filesystem_paths_e_formatos_cli_error_security]
 mov esi,filesystem_paths_e_formatos_cli_error_security_end-filesystem_paths_e_formatos_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret
%undef call
