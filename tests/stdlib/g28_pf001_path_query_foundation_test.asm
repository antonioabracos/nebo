bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/stdlib/path_query_foundation.inc"
extern neboc_path_query_init
extern neboc_path_query_evaluate
extern neboc_host_process_exit
section .bss align=16
record: resb neboc_filesystem_paths_e_formatos_RECORD_SIZE
section .text
global _start
_start:
 mov r15d,10
 xor edi,edi
 call neboc_path_query_init
 cmp eax,NEBOC_STATUS_INVALID_ARGUMENT
 jne fail
 lea rdi,[rel record]
 mov ecx,neboc_filesystem_paths_e_formatos_RECORD_QWORDS
 xor eax,eax
 rep stosq
 mov r15d,20
 lea rdi,[rel record]
 mov esi,NEBOC_OP_IS_ABSOLUTE
 mov edx,2
 mov ecx,1
 mov r8,0x1234
 mov r9d,neboc_filesystem_paths_e_formatos_REQUIRED_FLAGS
 call neboc_path_query_init
 test eax,eax
 jnz fail
 lea rdi,[rel record]
 call neboc_path_query_evaluate
 test eax,eax
 jnz fail
 cmp qword [rel record+neboc_filesystem_paths_e_formatos_RESULT_OFFSET],1
 jne fail
 mov r15d,30
 lea rdi,[rel record]
 mov ecx,neboc_filesystem_paths_e_formatos_RECORD_QWORDS
 xor eax,eax
 rep stosq
 lea rdi,[rel record]
 mov esi,NEBOC_OP_DEPTH
 mov edx,3
 xor ecx,ecx
 mov r8,0x5678
 mov r9d,neboc_filesystem_paths_e_formatos_REQUIRED_FLAGS
 call neboc_path_query_init
 test eax,eax
 jnz fail
 lea rdi,[rel record]
 call neboc_path_query_evaluate
 test eax,eax
 jnz fail
 cmp qword [rel record+neboc_filesystem_paths_e_formatos_RESULT_OFFSET],3
 jne fail
 mov r15d,40
 inc qword [rel record+NEBOC_PATH_HASH_OFFSET]
 lea rdi,[rel record]
 call neboc_path_query_evaluate
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne fail
 cmp qword [rel record+neboc_filesystem_paths_e_formatos_DIAGNOSTIC_OFFSET],neboc_filesystem_paths_e_formatos_DIAG_SECURITY_codegen_stdlib_x86_64
 jne fail
 xor edi,edi
 jmp neboc_host_process_exit
fail:
 mov edi,r15d
 jmp neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
