bits 64
default rel
%include "compiler/driver/build_profile.inc"
global _start
extern neboc_build_profile_release,neboc_cli_profile_explain,neboc_host_process_exit
section .bss align=16
profile: resb NEBOC_PROFILE_SIZE
manifest: resb NEBOC_PROFILE_SIZE
section .text
_start:
 sub rsp,8
 lea rdi,[rel profile]
 call neboc_build_profile_release
 test eax,eax
 jne .done
 lea rdi,[rel profile]
 lea rsi,[rel manifest]
 call neboc_cli_profile_explain
.done: mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
