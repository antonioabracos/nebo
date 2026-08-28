bits 64
default rel
%include "compiler/target/cross_compilation.inc"
global _start
extern neboc_cli_target_pack_verify,neboc_host_process_exit
section .data
target: dq 1
pack: dq 1,target,0x12345678,3,0x1f,1
section .text
_start:
 sub rsp,8
 lea rdi,[rel pack]
 call neboc_cli_target_pack_verify
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
