; REDE-E-PROTOCOLOS-PF001 bounded pure decimal network-port authority
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/net_port_foundation.inc"
section .text
NEBOC_ABI_FUNCTION neboc_net_port_init
 test rdi,rdi
 jz .bad_transport
 test rdi,neboc_rede_e_protocolos_ALIGNMENT-1
 jnz .bad_transport
 cmp rsi,NEBOC_OP_PARSE_PORT
 jne .bad_source
 test rdx,rdx
 jz .bad_source
 cmp rdx,65535
 ja .bad_source
 test rcx,rcx
 jz .bad_source
 cmp rcx,5
 ja .bad_source
 test r8,r8
 jz .bad_source
 cmp r9,neboc_rede_e_protocolos_REQUIRED_FLAGS
 jne .bad_source
 cmp qword [rdi+neboc_rede_e_protocolos_MAGIC_OFFSET],0
 jne .bad_source
 push r12
 mov r12,rdi
 mov rax,neboc_rede_e_protocolos_MAGIC
 mov [r12+neboc_rede_e_protocolos_MAGIC_OFFSET],rax
 mov [r12+neboc_rede_e_protocolos_OPERATION_OFFSET],rsi
 mov [r12+NEBOC_PORT_OFFSET],rdx
 mov [r12+neboc_rede_e_protocolos_DIGIT_COUNT_OFFSET],rcx
 mov [r12+neboc_rede_e_protocolos_LITERAL_HASH_OFFSET],r8
 mov [r12+neboc_rede_e_protocolos_FLAGS_OFFSET],r9
 mov qword [r12+neboc_rede_e_protocolos_INITIALIZED_OFFSET],1
 mov qword [r12+neboc_rede_e_protocolos_IMMUTABLE_RESERVED_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_RESULT_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_DECISION_OFFSET],neboc_rede_e_protocolos_DECISION_PERMIT
 mov qword [r12+neboc_rede_e_protocolos_DIAGNOSTIC_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_EVALUATION_COUNT_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_RESERVED0_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_RESERVED1_OFFSET],0
 mov qword [r12+neboc_rede_e_protocolos_RESERVED2_OFFSET],0
 call rede_e_protocolos_hash
 mov [r12+neboc_rede_e_protocolos_STATE_HASH_OFFSET],rax
 xor eax,eax
 pop r12
 ret
.bad_source:
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.bad_transport:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
NEBOC_ABI_FUNCTION neboc_net_port_evaluate
 test rdi,rdi
 jz .transport
 test rdi,neboc_rede_e_protocolos_ALIGNMENT-1
 jnz .transport
 push r12
 mov r12,rdi
 mov rax,neboc_rede_e_protocolos_MAGIC
 cmp [r12+neboc_rede_e_protocolos_MAGIC_OFFSET],rax
 jne .type
 cmp qword [r12+neboc_rede_e_protocolos_INITIALIZED_OFFSET],1
 jne .type
 call rede_e_protocolos_hash
 cmp rax,[r12+neboc_rede_e_protocolos_STATE_HASH_OFFSET]
 jne .security
 cmp qword [r12+neboc_rede_e_protocolos_OPERATION_OFFSET],NEBOC_OP_PARSE_PORT
 jne .type
 mov rax,[r12+NEBOC_PORT_OFFSET]
 mov [r12+neboc_rede_e_protocolos_RESULT_OFFSET],rax
 mov qword [r12+neboc_rede_e_protocolos_DECISION_OFFSET],neboc_rede_e_protocolos_DECISION_PERMIT
 mov qword [r12+neboc_rede_e_protocolos_DIAGNOSTIC_OFFSET],0
 inc qword [r12+neboc_rede_e_protocolos_EVALUATION_COUNT_OFFSET]
 xor eax,eax
 pop r12
 ret
.type:
 mov eax,neboc_rede_e_protocolos_DIAG_TYPE_driver_cli_linux_x86_64
 jmp .deny
.security:
 mov eax,neboc_rede_e_protocolos_DIAG_SECURITY_codegen_stdlib_x86_64
.deny:
 mov qword [r12+neboc_rede_e_protocolos_DECISION_OFFSET],neboc_rede_e_protocolos_DECISION_DENY
 mov [r12+neboc_rede_e_protocolos_DIAGNOSTIC_OFFSET],rax
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 pop r12
 ret
.transport:
 NEBOC_ABI_RETURN_STATUS NEBOC_STATUS_INVALID_ARGUMENT
rede_e_protocolos_hash:
 mov rax,14695981039346656037
 mov r8,1099511628211
 xor ecx,ecx
.loop:
 cmp rcx,neboc_rede_e_protocolos_HASHED_BYTES
 jae .done
 movzx edx,byte [r12+rcx]
 xor rax,rdx
 imul rax,r8
 inc rcx
 jmp .loop
.done:
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
