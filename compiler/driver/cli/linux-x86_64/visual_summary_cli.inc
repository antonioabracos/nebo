; console_visual_dashboard_e_plots public CLI recognizer and exact diagnostic reporter; included by cli_driver.asm.
section .text
cli_recognize_visual_summary:
 push rbx
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 cmp rax,7
 jb .none
 lea rbx,[rel cli_source]
 mov al,[rbx]
 cmp al,'v'
 je .tail
 cmp al,'V'
 jne .none
.tail:
 cmp byte [rbx+1],'i'
 jne .none
 cmp byte [rbx+2],'s'
 jne .none
 cmp byte [rbx+3],'u'
 jne .none
 cmp byte [rbx+4],'a'
 jne .none
 cmp byte [rbx+5],'l'
 jne .none
 cmp byte [rbx+6],'.'
 jne .none
 mov qword [rel console_visual_dashboard_e_plots_cli_found],1
 lea rdi,[rel console_visual_dashboard_e_plots_cli_parse_request]
 mov ecx,neboc_console_visual_dashboard_e_plots_PARSE_REQUEST_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel console_visual_dashboard_e_plots_cli_syntax]
 mov ecx,(neboc_console_visual_dashboard_e_plots_SYNTAX_SIZE+neboc_console_visual_dashboard_e_plots_RECORD_SIZE+neboc_console_visual_dashboard_e_plots_SEM_SIZE+neboc_console_visual_dashboard_e_plots_IR_SIZE+neboc_console_visual_dashboard_e_plots_NATIVE_SIZE+neboc_console_visual_dashboard_e_plots_RUNTIME_SIZE)/8
 xor eax,eax
 rep stosq
 lea rax,[rel cli_source]
 mov [rel console_visual_dashboard_e_plots_cli_parse_request+neboc_console_visual_dashboard_e_plots_PARSE_SOURCE_OFFSET],rax
 mov rax,[rel cli_state+NEBOC_CLI_STATE_SOURCE_LENGTH_OFFSET]
 mov [rel console_visual_dashboard_e_plots_cli_parse_request+neboc_console_visual_dashboard_e_plots_PARSE_SOURCE_LENGTH_OFFSET],rax
 lea rax,[rel console_visual_dashboard_e_plots_cli_syntax]
 mov [rel console_visual_dashboard_e_plots_cli_parse_request+neboc_console_visual_dashboard_e_plots_PARSE_OUTPUT_OFFSET],rax
 lea rdi,[rel console_visual_dashboard_e_plots_cli_parse_request]
 call neboc_visual_summary_parse
 test eax,eax
 jnz .parser
 lea rdi,[rel console_visual_dashboard_e_plots_cli_authority]
 mov rsi,[rel console_visual_dashboard_e_plots_cli_syntax+neboc_console_visual_dashboard_e_plots_SYNTAX_OPERATION_OFFSET]
 mov rdx,[rel console_visual_dashboard_e_plots_cli_syntax+neboc_console_visual_dashboard_e_plots_SYNTAX_VALUE_OFFSET]
 mov rcx,[rel console_visual_dashboard_e_plots_cli_syntax+neboc_console_visual_dashboard_e_plots_SYNTAX_DIGIT_COUNT_OFFSET]
 mov r8,[rel console_visual_dashboard_e_plots_cli_syntax+neboc_console_visual_dashboard_e_plots_SYNTAX_LITERAL_HASH_OFFSET]
 mov r9d,neboc_console_visual_dashboard_e_plots_REQUIRED_FLAGS
 call neboc_visual_summary_init
 test eax,eax
 jnz .type
 lea rdi,[rel console_visual_dashboard_e_plots_cli_syntax]
 lea rsi,[rel console_visual_dashboard_e_plots_cli_authority]
 lea rdx,[rel console_visual_dashboard_e_plots_cli_semantic]
 call neboc_visual_summary_semantic_build
 test eax,eax
 jnz .semantic
 lea rdi,[rel console_visual_dashboard_e_plots_cli_semantic]
 lea rsi,[rel console_visual_dashboard_e_plots_cli_ir]
 call neboc_visual_summary_ir_lower
 test eax,eax
 jnz .ir
 lea rdi,[rel console_visual_dashboard_e_plots_cli_ir]
 lea rsi,[rel console_visual_dashboard_e_plots_cli_plan]
 call neboc_visual_summary_native_lower
 test eax,eax
 jnz .native
 lea rdi,[rel console_visual_dashboard_e_plots_cli_plan]
 lea rsi,[rel console_visual_dashboard_e_plots_cli_runtime_state]
 call neboc_visual_summary_runtime_execute
 test eax,eax
 jnz .runtime
 xor eax,eax
 jmp .done
.parser:
 mov rax,[rel console_visual_dashboard_e_plots_cli_parse_request+neboc_console_visual_dashboard_e_plots_PARSE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .publish
.type:
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.semantic:
 mov rax,[rel console_visual_dashboard_e_plots_cli_semantic+neboc_console_visual_dashboard_e_plots_SEM_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .publish
.ir:
 mov rax,[rel console_visual_dashboard_e_plots_cli_ir+neboc_console_visual_dashboard_e_plots_IR_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_SECURITY_codegen_stdlib_x86_64
 jmp .publish
.native:
 mov rax,[rel console_visual_dashboard_e_plots_cli_plan+neboc_console_visual_dashboard_e_plots_NATIVE_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_CODEGEN_codegen_stdlib_x86_64
 jmp .publish
.runtime:
 mov rax,[rel console_visual_dashboard_e_plots_cli_runtime_state+neboc_console_visual_dashboard_e_plots_RUNTIME_DIAGNOSTIC_OFFSET]
 test rax,rax
 jnz .publish
 mov eax,neboc_console_visual_dashboard_e_plots_DIAG_RUNTIME_driver_cli_linux_x86_64
.publish:
 mov [rel console_visual_dashboard_e_plots_cli_frontend_diagnostic],rax
 mov eax,1
 jmp .done
.none:
 xor eax,eax
.done:
 pop rbx
 ret

%define call NEBOC_ABI_FUNCTION_SCOPED_CALL
console_visual_dashboard_e_plots_cli_report_frontend_diagnostic:
 mov rax,[rel console_visual_dashboard_e_plots_cli_frontend_diagnostic]
 test rax,rax
 jz .none
 cmp rax,neboc_console_visual_dashboard_e_plots_DIAG_LEX_driver_cli_linux_x86_64
 je .lex
 cmp rax,neboc_console_visual_dashboard_e_plots_DIAG_PARSE_driver_cli_linux_x86_64
 je .parse
 cmp rax,neboc_console_visual_dashboard_e_plots_DIAG_TYPE_driver_cli_linux_x86_64
 je .type
 cmp rax,neboc_console_visual_dashboard_e_plots_DIAG_RUNTIME_driver_cli_linux_x86_64
 je .runtime
 cmp rax,neboc_console_visual_dashboard_e_plots_DIAG_SECURITY_codegen_stdlib_x86_64
 je .security
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_codegen]
 mov esi,console_visual_dashboard_e_plots_cli_error_codegen_end-console_visual_dashboard_e_plots_cli_error_codegen
 jmp .emit
.lex:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_lex]
 mov esi,console_visual_dashboard_e_plots_cli_error_lex_end-console_visual_dashboard_e_plots_cli_error_lex
 jmp .emit
.parse:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_parse]
 mov esi,console_visual_dashboard_e_plots_cli_error_parse_end-console_visual_dashboard_e_plots_cli_error_parse
 jmp .emit
.type:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_type]
 mov esi,console_visual_dashboard_e_plots_cli_error_type_end-console_visual_dashboard_e_plots_cli_error_type
 jmp .emit
.runtime:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_runtime]
 mov esi,console_visual_dashboard_e_plots_cli_error_runtime_end-console_visual_dashboard_e_plots_cli_error_runtime
 jmp .emit
.security:
 lea rdi,[rel console_visual_dashboard_e_plots_cli_error_security]
 mov esi,console_visual_dashboard_e_plots_cli_error_security_end-console_visual_dashboard_e_plots_cli_error_security
.emit:
 call cli_write_stderr
 mov eax,1
 ret
.none:
 xor eax,eax
 ret
%undef call
