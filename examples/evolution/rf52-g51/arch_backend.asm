bits 64
default rel
%include "compiler/target/target_registry.inc"
%include "compiler/target/arch_backend.inc"
global _start
extern neboc_arch_backend_new,neboc_cli_emit_asm_target,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x1f,3
section .bss align=16
backend: resb NEBOC_BACKEND_SIZE
out: resq 2
section .text
_start:
 sub rsp,8
 lea rdi,[rel backend]
 lea rsi,[rel target]
 call neboc_arch_backend_new
 test eax,eax
 jne .done
 lea rdi,[rel backend]
 mov esi,1
 lea rdx,[rel out]
 call neboc_cli_emit_asm_target
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
