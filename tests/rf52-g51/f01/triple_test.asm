bits 64
default rel
%include "compiler/target/triple.inc"
global _start
extern neboc_build_triple_current,neboc_host_triple_current,neboc_target_triple_parse
extern neboc_triple_normalize,neboc_triple_architecture,neboc_triple_operating_system
extern neboc_triple_environment,neboc_triple_compatibility,neboc_compilation_context_new
extern neboc_compilation_context_manifest,neboc_cli_host,neboc_cli_triple_normalize
extern neboc_host_process_exit
section .bss align=16
build: resb NEBOC_TRIPLE_SIZE
host: resb NEBOC_TRIPLE_SIZE
target: resb NEBOC_TRIPLE_SIZE
other: resb NEBOC_TRIPLE_SIZE
context: resb NEBOC_CONTEXT_SIZE
manifest: resb NEBOC_CONTEXT_SIZE
out: resq 2
section .text
_start:
 sub rsp,8
 lea rdi,[rel build]
 call neboc_build_triple_current
 test eax,eax
 jne .fail1
 lea rdi,[rel host]
 call neboc_host_triple_current
 test eax,eax
 jne .fail2
 lea rdi,[rel target]
 mov esi,2
 call neboc_target_triple_parse
 test eax,eax
 jne .fail3
 lea rdi,[rel target]
 lea rsi,[rel out]
 call neboc_triple_normalize
 test eax,eax
 jne .fail4
 cmp qword [rel out],2
 jne .fail5
 lea rdi,[rel target]
 lea rsi,[rel out]
 call neboc_triple_architecture
 cmp qword [rel out],NEBOC_ARCH_AARCH64
 jne .fail6
 cmp qword [rel out+8],64
 jne .fail7
 lea rdi,[rel target]
 lea rsi,[rel out]
 call neboc_triple_operating_system
 cmp qword [rel out],NEBOC_OS_LINUX
 jne .fail8
 lea rdi,[rel target]
 lea rsi,[rel out]
 call neboc_triple_environment
 cmp qword [rel out],NEBOC_ENV_SYSTEMV
 jne .fail9
 lea rdi,[rel target]
 lea rsi,[rel build]
 lea rdx,[rel out]
 call neboc_triple_compatibility
 test eax,eax
 jne .fail10
 cmp qword [rel out],NEBOC_COMPAT_SOURCE
 jne .fail11
 lea rdi,[rel context]
 lea rsi,[rel build]
 lea rdx,[rel host]
 lea rcx,[rel target]
 mov r8d,52
 mov r9d,7
 call neboc_compilation_context_new
 test eax,eax
 jne .fail12
 lea rdi,[rel context]
 lea rsi,[rel manifest]
 call neboc_compilation_context_manifest
 test eax,eax
 jne .fail13
 ; Address comparison requires the runtime address.
 lea rax,[rel target]
 cmp [rel manifest+NEBOC_CONTEXT_TARGET_OFFSET],rax
 jne .fail14
 lea rdi,[rel build]
 lea rsi,[rel host]
 call neboc_cli_host
 test eax,eax
 jne .fail15
 lea rdi,[rel other]
 mov esi,3
 lea rdx,[rel out]
 call neboc_cli_triple_normalize
 test eax,eax
 jne .fail16
 cmp qword [rel out],3
 jne .fail17
 lea rdi,[rel other]
 mov esi,99
 call neboc_target_triple_parse
 test eax,eax
 jz .fail18
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 18
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
