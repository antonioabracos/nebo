bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/net_port_foundation.inc"
extern neboc_net_port_init
extern neboc_net_port_evaluate
extern neboc_host_process_exit
section .bss align=16
record: resb neboc_rede_e_protocolos_RECORD_SIZE
section .text
global _start
_start:
 mov r15d,10
 xor edi,edi
 call neboc_net_port_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 lea rdi,[rel record]
 mov ecx,neboc_rede_e_protocolos_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov r15d,20
 lea rdi,[rel record]
 mov esi,NEBOC_OP_PARSE_PORT
 mov edx,443
 mov ecx,3
 mov r8,0x443443
 mov r9d,neboc_rede_e_protocolos_REQUIRED_FLAGS
 call neboc_net_port_init
 test eax,eax
 jnz fail
 lea rdi,[rel record]
 call neboc_net_port_evaluate
 test eax,eax
 jnz fail
 cmp qword [rel record+neboc_rede_e_protocolos_RESULT_OFFSET],443
 jne fail
 mov r15d,30
 lea rdi,[rel record]
 mov ecx,neboc_rede_e_protocolos_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel record]
 mov esi,NEBOC_OP_PARSE_PORT
 xor edx,edx
 mov ecx,1
 mov r8,0x30
 mov r9d,neboc_rede_e_protocolos_REQUIRED_FLAGS
 call neboc_net_port_init
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 mov r15d,40
 lea rdi,[rel record]
 mov ecx,neboc_rede_e_protocolos_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel record]
 mov esi,NEBOC_OP_PARSE_PORT
 mov edx,65535
 mov ecx,5
 mov r8,0x65535
 mov r9d,neboc_rede_e_protocolos_REQUIRED_FLAGS
 call neboc_net_port_init
 test eax,eax
 jnz fail
 inc qword [rel record+neboc_rede_e_protocolos_LITERAL_HASH_OFFSET]
 lea rdi,[rel record]
 call neboc_net_port_evaluate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel record+neboc_rede_e_protocolos_DIAGNOSTIC_OFFSET],neboc_rede_e_protocolos_DIAG_SECURITY_codegen_stdlib_x86_64
 jne fail
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
