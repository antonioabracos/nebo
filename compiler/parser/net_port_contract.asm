; REDE-E-PROTOCOLOS-PF002 canonical offline decimal network-port parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/net_port_contract.inc"
section .rodata
p_call: db 'net.parsePort("'
p_call_len equ $-p_call
p_end: db '");'
p_end_len equ $-p_end
section .text
NEBOC_ABI_FUNCTION neboc_net_port_parse
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov rax,[rdi+neboc_rede_e_protocolos_PARSE_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdi+neboc_rede_e_protocolos_PARSE_OUTPUT_OFFSET]
 test rax,rax
 jz .invalid
 test rax,7
 jnz .invalid
 mov rax,[rdi+neboc_rede_e_protocolos_PARSE_SOURCE_LENGTH_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,neboc_rede_e_protocolos_PARSE_MAX_SOURCE_BYTES
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,[r12+neboc_rede_e_protocolos_PARSE_SOURCE_OFFSET]
 mov r14,r13
 add r14,rax
 jc .invalid_pushed
 mov r15,r13
 mov rbx,[r12+neboc_rede_e_protocolos_PARSE_OUTPUT_OFFSET]
 mov rdi,rbx
 mov ecx,neboc_rede_e_protocolos_SYNTAX_QWORDS
 xor eax,eax
 rep stosq
 mov qword [rbx+neboc_rede_e_protocolos_SYNTAX_FLAGS_OFFSET],neboc_rede_e_protocolos_SYNTAX_REQUIRED_FLAGS
 lea rsi,[rel p_call]
 mov ecx,p_call_len
 call rede_e_protocolos_match
 jc .lex
 mov qword [rbx+neboc_rede_e_protocolos_SYNTAX_OPERATION_OFFSET],NEBOC_OP_PARSE_PORT
 mov qword [rbx+neboc_rede_e_protocolos_SYNTAX_ARITY_OFFSET],1
 or qword [r12+neboc_rede_e_protocolos_PARSE_FEATURE_MASK_OFFSET],neboc_rede_e_protocolos_FEATURE_NAMESPACE
 mov r10,r15
 cmp r15,r14
 jae .parse
 xor r11d,r11d
 xor r9d,r9d
 cmp byte [r15],'0'
 jne .digit_loop
 inc r15
 inc r11d
 cmp r15,r14
 jae .parse
 cmp byte [r15],'"'
 je .type
 jmp .security
.digit_loop:
 cmp r15,r14
 jae .parse
 movzx eax,byte [r15]
 cmp al,'"'
 je .digits_done
 cmp al,'0'
 jb .type
 cmp al,'9'
 ja .type
 inc r11d
 cmp r11d,5
 ja .type
 imul r9d,r9d,10
 sub eax,'0'
 add r9d,eax
 cmp r9d,65535
 ja .type
 inc r15
 jmp .digit_loop
.digits_done:
 test r11d,r11d
 jz .type
 test r9d,r9d
 jz .type
 mov [rbx+NEBOC_SYNTAX_PORT_OFFSET],r9
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_DIGIT_COUNT_OFFSET],r11
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_ARGUMENT_SPAN_OFFSET],r11
 mov rsi,r10
 mov ecx,r11d
 call rede_e_protocolos_hash_range
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_LITERAL_HASH_OFFSET],rax
 lea rsi,[rel p_end]
 mov ecx,p_end_len
 call rede_e_protocolos_match
 jc .parse
 or qword [r12+neboc_rede_e_protocolos_PARSE_FEATURE_MASK_OFFSET],neboc_rede_e_protocolos_FEATURE_ARGUMENT|neboc_rede_e_protocolos_FEATURE_TERMINATOR
 cmp r15,r14
 je .finish
 cmp byte [r15],10
 jne .parse
 inc r15
 cmp r15,r14
 jne .parse
.finish:
 mov rax,r15
 sub rax,r13
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_STATEMENT_LENGTH_OFFSET],rax
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_CALL_SPAN_OFFSET],rax
 mov [r12+neboc_rede_e_protocolos_PARSE_CONSUMED_OFFSET],rax
 mov rsi,rbx
 mov ecx,neboc_rede_e_protocolos_SYNTAX_HASHED_BYTES
 call rede_e_protocolos_hash_range
 mov [rbx+neboc_rede_e_protocolos_SYNTAX_SHAPE_HASH_OFFSET],rax
 mov [r12+neboc_rede_e_protocolos_PARSE_CANONICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.lex:
 mov eax,neboc_rede_e_protocolos_DIAG_LEX_driver_cli_linux_x86_64
 jmp .failure
.parse:
 mov eax,neboc_rede_e_protocolos_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .failure
.type:
 mov eax,neboc_rede_e_protocolos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .failure
.security:
 mov eax,neboc_rede_e_protocolos_DIAG_SECURITY_codegen_stdlib_x86_64
.failure:
 mov [r12+neboc_rede_e_protocolos_PARSE_DIAGNOSTIC_OFFSET],rax
 mov rdx,r15
 sub rdx,r13
 mov [r12+neboc_rede_e_protocolos_PARSE_ERROR_OFFSET_OFFSET],rdx
 mov [r12+neboc_rede_e_protocolos_PARSE_CONSUMED_OFFSET],rdx
 mov rdi,rbx
 mov ecx,neboc_rede_e_protocolos_SYNTAX_QWORDS
 xor eax,eax
 rep stosq
 mov eax,NEBOC_STATUS_INVALID_SOURCE
.done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
.invalid_pushed:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
.invalid:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
.limit:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_LIMIT_EXCEEDED
rede_e_protocolos_match:
 mov rdx,r14
 sub rdx,r15
 cmp rdx,rcx
 jb .bad
.loop:
 test ecx,ecx
 jz .ok
 mov al,[r15]
 cmp al,[rsi]
 jne .bad
 inc r15
 inc rsi
 dec ecx
 jmp .loop
.ok:
 clc
 ret
.bad:
 stc
 ret
rede_e_protocolos_hash_range:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor edx,edx
.loop:
 cmp edx,ecx
 jae .done
 movzx r9d,byte [rsi+rdx]
 xor rax,r9
 imul rax,r8
 inc edx
 jmp .loop
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
