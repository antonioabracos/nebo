bits 64
default rel
global _start
extern neboc_cli_host_package_verify,neboc_host_process_exit
section .data
package: dq 1,1,0x1234,1,0,2,32
section .text
_start:
 sub rsp,8
 lea rdi,[rel package]
 call neboc_cli_host_package_verify
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
