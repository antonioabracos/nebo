; FILESYSTEM-PATHS-E-FORMATOS-PF001 bounded pure lexical Path query authority
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/path_query_foundation.inc"
section .text
NEBOC_ABI_FUNCTION neboc_path_query_init
 test rdi,rdi
 jz .bad_transport
 test rdi,neboc_filesystem_paths_e_formatos_ALIGNMENT-1
 jnz .bad_transport
 cmp rsi,NEBOC_OP_IS_ABSOLUTE
 jb .bad_source
 cmp rsi,NEBOC_OP_DEPTH
 ja .bad_source
 cmp rdx,63
 ja .bad_source
 cmp rcx,1
 ja .bad_source
 test r8,r8
 jz .bad_source
 cmp r9,neboc_filesystem_paths_e_formatos_REQUIRED_FLAGS
 jne .bad_source
 cmp qword [rdi+neboc_filesystem_paths_e_formatos_MAGIC_OFFSET],0
 jne .bad_source
 push r12
 mov r12,rdi
 mov rax,neboc_filesystem_paths_e_formatos_MAGIC
 mov [r12+neboc_filesystem_paths_e_formatos_MAGIC_OFFSET],rax
 mov [r12+neboc_filesystem_paths_e_formatos_OPERATION_OFFSET],rsi
 mov [r12+NEBOC_DEPTH_OFFSET],rdx
 mov [r12+NEBOC_ABSOLUTE_OFFSET],rcx
 mov [r12+NEBOC_PATH_HASH_OFFSET],r8
 mov [r12+neboc_filesystem_paths_e_formatos_FLAGS_OFFSET],r9
 mov qword [r12+neboc_filesystem_paths_e_formatos_INITIALIZED_OFFSET],1
 mov qword [r12+neboc_filesystem_paths_e_formatos_IMMUTABLE_RESERVED_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_RESULT_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_DECISION_OFFSET],neboc_filesystem_paths_e_formatos_DECISION_PERMIT
 mov qword [r12+neboc_filesystem_paths_e_formatos_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_EVALUATION_COUNT_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_RESERVED0_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_RESERVED1_OFFSET],0
 mov qword [r12+neboc_filesystem_paths_e_formatos_RESERVED2_OFFSET],0
 call filesystem_paths_e_formatos_hash
 mov [r12+neboc_filesystem_paths_e_formatos_STATE_HASH_OFFSET],rax
 xor eax,eax
 pop r12
 ret
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bad_transport:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
NEBOC_ABI_FUNCTION neboc_path_query_evaluate
 test rdi,rdi
 jz .eval_transport
 test rdi,neboc_filesystem_paths_e_formatos_ALIGNMENT-1
 jnz .eval_transport
 push r12
 mov r12,rdi
 mov rax,neboc_filesystem_paths_e_formatos_MAGIC
 cmp [r12+neboc_filesystem_paths_e_formatos_MAGIC_OFFSET],rax
 jne .type
 cmp qword [r12+neboc_filesystem_paths_e_formatos_INITIALIZED_OFFSET],1
 jne .type
 call filesystem_paths_e_formatos_hash
 cmp rax,[r12+neboc_filesystem_paths_e_formatos_STATE_HASH_OFFSET]
 jne .security
 mov rcx,[r12+neboc_filesystem_paths_e_formatos_OPERATION_OFFSET]
 cmp rcx,NEBOC_OP_IS_ABSOLUTE
 je .absolute
 cmp rcx,NEBOC_OP_IS_RELATIVE
 je .relative
 cmp rcx,NEBOC_OP_DEPTH
 jne .type
 mov rax,[r12+NEBOC_DEPTH_OFFSET]
 jmp .success
.absolute:
 mov rax,[r12+NEBOC_ABSOLUTE_OFFSET]
 jmp .success
.relative:
 mov rax,[r12+NEBOC_ABSOLUTE_OFFSET]
 xor rax,1
.success:
 mov [r12+neboc_filesystem_paths_e_formatos_RESULT_OFFSET],rax
 mov qword [r12+neboc_filesystem_paths_e_formatos_DECISION_OFFSET],neboc_filesystem_paths_e_formatos_DECISION_PERMIT
 mov qword [r12+neboc_filesystem_paths_e_formatos_DIAGNOSTIC_OFFSET],0
 inc qword [r12+neboc_filesystem_paths_e_formatos_EVALUATION_COUNT_OFFSET]
 xor eax,eax
 pop r12
 ret
.type:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .deny
.security:
 mov eax,neboc_filesystem_paths_e_formatos_DIAG_SECURITY_codegen_stdlib_x86_64
.deny:
 mov qword [r12+neboc_filesystem_paths_e_formatos_DECISION_OFFSET],neboc_filesystem_paths_e_formatos_DECISION_DENY
 mov [r12+neboc_filesystem_paths_e_formatos_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop r12
 ret
.eval_transport:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
filesystem_paths_e_formatos_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp rcx,neboc_filesystem_paths_e_formatos_HASHED_BYTES
 jae .done
 movzx edx,byte [r12+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
