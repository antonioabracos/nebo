bits 64
default rel
%include "compiler/toolchain/hermetic_build.inc"
global _start
extern neboc_hermetic_build_context_new,neboc_hermetic_deny_network,neboc_hermetic_path_remap
extern neboc_hermetic_fixed_locale,neboc_cli_build_hermetic,neboc_host_process_exit
section .bss align=16
context: resb NEBOC_HERM_SIZE
report: resq 2
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 mov esi,1
 mov edx,1
 mov ecx,1
 call neboc_hermetic_build_context_new
 lea rdi,[rel context]
 call neboc_hermetic_deny_network
 lea rdi,[rel context]
 mov esi,1
 mov edx,2
 call neboc_hermetic_path_remap
 lea rdi,[rel context]
 mov esi,1
 call neboc_hermetic_fixed_locale
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_build_hermetic
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
