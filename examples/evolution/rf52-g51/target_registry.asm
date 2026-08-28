bits 64
default rel
%include "compiler/target/target_registry.inc"
global _start
extern neboc_target_registry_load,neboc_cli_targets,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,3,0x1f,3
registry: dq 0,0,0
out: dq 0
section .text
_start:
 sub rsp,8
 lea rdi,[rel registry]
 lea rsi,[rel target]
 mov edx,1
 mov ecx,1
 call neboc_target_registry_load
 test eax,eax
 jne .done
 lea rdi,[rel registry]
 lea rsi,[rel out]
 call neboc_cli_targets
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
