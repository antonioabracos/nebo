bits 64
default rel
%include "compiler/toolchain/trust_manifest.inc"
global _start
extern neboc_trust_manifest_new,neboc_trust_manifest_add_component,neboc_cli_trust_manifest,neboc_host_process_exit
section .bss align=16
manifest: resb NEBOC_TRUST_SIZE
out: resq 10
section .text
_start:
 sub rsp,8
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,1
 call neboc_trust_manifest_new
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,1
 mov ecx,1
 call neboc_trust_manifest_add_component
 lea rdi,[rel manifest]
 lea rsi,[rel out]
 call neboc_cli_trust_manifest
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
