; FILESYSTEM-PATHS-E-FORMATOS-PF002 canonical pure lexical Path query parser
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/parser/path_query_contract.inc"
section .rodata
p_root: db 'path.'
p_root_len equ $-p_root
p_abs: db 'isAbsolute("'
p_abs_len equ $-p_abs
p_rel: db 'isRelative("'
p_rel_len equ $-p_rel
p_depth: db 'depth("'
p_depth_len equ $-p_depth
p_end: db '");'
p_end_len equ $-p_end
section .text
NEBOC_ABI_FUNCTION neboc_path_query_parse
 test rdi,rdi
 jz .invalid
 test rdi,7
 jnz .invalid
 mov rax,[rdi+neboc_filesystem_paths_e_formatos_PARSE_SOURCE_OFFSET]
 test rax,rax
 jz .invalid
 mov rax,[rdi+neboc_filesystem_paths_e_formatos_PARSE_OUTPUT_OFFSET]
 test rax,rax
 jz .invalid
 test rax,7
 jnz .invalid
 mov rax,[rdi+neboc_filesystem_paths_e_formatos_PARSE_SOURCE_LENGTH_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,neboc_filesystem_paths_e_formatos_PARSE_MAX_SOURCE_BYTES
 ja .limit
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,[r12+neboc_filesystem_paths_e_formatos_PARSE_SOURCE_OFFSET]
 mov r14,r13
 add r14,rax
 jc .invalid_pushed
 mov r15,r13
 mov rbx,[r12+neboc_filesystem_paths_e_formatos_PARSE_OUTPUT_OFFSET]
 mov rdi,rbx
 mov ecx,neboc_filesystem_paths_e_formatos_SYNTAX_QWORDS
 xor eax,eax
 rep stosq
 mov qword [r12+neboc_filesystem_paths_e_formatos_PARSE_ERROR_OFFSET_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_PARSE_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_PARSE_CONSUMED_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_PARSE_CANONICAL_HASH_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_PARSE_FEATURE_MASK_OFFSET],0
 mov qword [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_FLAGS_OFFSET],neboc_filesystem_paths_e_formatos_SYNTAX_REQUIRED_FLAGS
 lea rsi,[rel p_root]
 mov ecx,p_root_len
 call filesystem_paths_e_formatos_match
 jc .lex
 cmp r15,r14
 jae .lex
 cmp byte [r15],'i'
 je .is_query
 cmp byte [r15],'d'
 jne .lex
 lea rsi,[rel p_depth]
 mov ecx,p_depth_len
 call filesystem_paths_e_formatos_match
 jc .lex
 mov qword [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_OPERATION_OFFSET],NEBOC_OP_DEPTH
 jmp .operation_done
.is_query:
 lea rsi,[rel p_abs]
 mov ecx,p_abs_len
 call filesystem_paths_e_formatos_match
 jnc .absolute_op
 ; restore to immediately after path. and try isRelative.
 lea r15,[r13+p_root_len]
 lea rsi,[rel p_rel]
 mov ecx,p_rel_len
 call filesystem_paths_e_formatos_match
 jc .lex
 mov qword [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_OPERATION_OFFSET],NEBOC_OP_IS_RELATIVE
 jmp .operation_done
.absolute_op:
 mov qword [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_OPERATION_OFFSET],NEBOC_OP_IS_ABSOLUTE
.operation_done:
 mov qword [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_ARITY_OFFSET],1
 or qword [r12+neboc_filesystem_paths_e_formatos_PARSE_FEATURE_MASK_OFFSET],neboc_filesystem_paths_e_formatos_FEATURE_NAMESPACE
 mov r10,r15
 cmp r15,r14
 jae .parse
 xor r11d,r11d
 xor r9d,r9d
 xor r8d,r8d
 xor ecx,ecx
 cmp byte [r15],'/'
 jne .path_loop
 mov ecx,1
.path_loop:
 cmp r15,r14
 jae .parse
 mov al,[r15]
 cmp al,'"'
 je .path_done
 mov rdx,r15
 sub rdx,r10
 cmp rdx,63
 jae .type
 cmp al,'/'
 je .slash
 cmp al,'.'
 je .dot
 cmp al,'-'
 je .component
 cmp al,'_'
 je .component
 cmp al,'0'
 jb .type
 cmp al,'9'
 jbe .component
 cmp al,'A'
 jb .type
 cmp al,'Z'
 jbe .component
 cmp al,'a'
 jb .type
 cmp al,'z'
 ja .type
.component:
 test r9d,r9d
 jnz .component_seen
 inc r11d
 mov r9d,1
.component_seen:
 xor r8d,r8d
 inc r15
 jmp .path_loop
.dot:
 test r8d,r8d
 jnz .security
 test r9d,r9d
 jnz .dot_seen
 inc r11d
 mov r9d,1
.dot_seen:
 mov r8d,1
 inc r15
 jmp .path_loop
.slash:
 cmp r15,r10
 jne .slash_after_start
 test ecx,ecx
 jz .type
 inc r15
 jmp .path_loop
.slash_after_start:
 test r9d,r9d
 jz .type
 xor r9d,r9d
 xor r8d,r8d
 inc r15
 jmp .path_loop
.path_done:
 mov rdx,r15
 sub rdx,r10
 test rdx,rdx
 jz .type
 cmp rdx,1
 je .root_or_one
 test r9d,r9d
 jz .type
.root_or_one:
 mov [rbx+NEBOC_SYNTAX_DEPTH_OFFSET],r11
 mov [rbx+NEBOC_SYNTAX_ABSOLUTE_OFFSET],rcx
 mov [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_ARGUMENT_SPAN_OFFSET],rdx
 mov rsi,r10
 mov ecx,edx
 call filesystem_paths_e_formatos_hash_range
 mov [rbx+NEBOC_SYNTAX_PATH_HASH_OFFSET],rax
 lea rsi,[rel p_end]
 mov ecx,p_end_len
 call filesystem_paths_e_formatos_match
 jc .parse
 or qword [r12+neboc_filesystem_paths_e_formatos_PARSE_FEATURE_MASK_OFFSET],neboc_filesystem_paths_e_formatos_FEATURE_ARGUMENT|neboc_filesystem_paths_e_formatos_FEATURE_TERMINATOR
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
 mov [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_STATEMENT_LENGTH_OFFSET],rax
 mov [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_CALL_SPAN_OFFSET],rax
 mov [r12+neboc_filesystem_paths_e_formatos_PARSE_CONSUMED_OFFSET],rax
 mov rsi,rbx
 mov ecx,neboc_filesystem_paths_e_formatos_SYNTAX_HASHED_BYTES
 call filesystem_paths_e_formatos_hash_range
 mov [rbx+neboc_filesystem_paths_e_formatos_SYNTAX_SHAPE_HASH_OFFSET],rax
 mov [r12+neboc_filesystem_paths_e_formatos_PARSE_CANONICAL_HASH_OFFSET],rax
 xor eax,eax
 jmp .done
.lex:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_LEX_driver_cli_linux_x86_64
 jmp .failure
.parse:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_PARSE_driver_cli_linux_x86_64
 jmp .failure
.type:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .failure
.security:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_SECURITY_codegen_stdlib_x86_64
.failure:
 mov [r12+neboc_filesystem_paths_e_formatos_PARSE_DIAGNOSTIC_OFFSET],rax
 mov rdx,r15
 sub rdx,r13
 mov [r12+neboc_filesystem_paths_e_formatos_PARSE_ERROR_OFFSET_OFFSET],rdx
 mov [r12+neboc_filesystem_paths_e_formatos_PARSE_CONSUMED_OFFSET],rdx
 mov rdi,rbx
 mov ecx,neboc_filesystem_paths_e_formatos_SYNTAX_QWORDS
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
filesystem_paths_e_formatos_match:
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
filesystem_paths_e_formatos_hash_range:
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
