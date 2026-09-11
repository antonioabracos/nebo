bits 64
default rel
%include "compiler/bootstrap/bootstrap.inc"
global _start
extern neboc_bootstrap_stage0,neboc_bootstrap_source_compiler,neboc_bootstrap_stage1,neboc_bootstrap_stage2
extern neboc_bootstrap_compare_stages,neboc_bootstrap_divergence_report,neboc_bootstrap_preserve_stage0
extern neboc_bootstrap_promote_component,neboc_bootstrap_rollback_promotion,neboc_bootstrap_stage_manifest
extern neboc_cli_bootstrap_stage,neboc_cli_bootstrap_verify,neboc_host_process_exit
section .bss align=16
state: resb NEBOC_BOOT_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel state]
 mov esi,0x11
 mov edx,0x22
 mov ecx,0x33
 call neboc_bootstrap_stage0
 test eax,eax
 jne .f1
 lea rdi,[rel state]
 lea rsi,[rel out]
 call neboc_bootstrap_preserve_stage0
 test eax,eax
 jne .f2
 cmp qword [rel out],1
 jne .f3
 lea rdi,[rel state]
 xor esi,esi
 lea rdx,[rel out]
 call neboc_bootstrap_stage_manifest
 cmp qword [rel out],0x11
 jne .f4
 cmp qword [rel out+24],1
 jne .f5
 lea rdi,[rel state]
 call neboc_bootstrap_source_compiler
 cmp eax,6
 jne .f6
 lea rdi,[rel state]
 call neboc_bootstrap_stage1
 cmp eax,6
 jne .f7
 lea rdi,[rel state]
 call neboc_bootstrap_stage2
 cmp eax,6
 jne .f8
 lea rdi,[rel state]
 lea rsi,[rel out]
 call neboc_bootstrap_compare_stages
 cmp eax,6
 jne .f9
 lea rdi,[rel state]
 lea rsi,[rel out]
 call neboc_bootstrap_divergence_report
 cmp qword [rel out],5
 jne .f10
 lea rdi,[rel state]
 mov esi,1
 lea rdx,[rel out]
 call neboc_cli_bootstrap_stage
 cmp eax,6
 jne .f11
 lea rdi,[rel state]
 lea rsi,[rel out]
 call neboc_cli_bootstrap_verify
 test eax,eax
 jne .f12
 lea rdi,[rel state]
 call neboc_bootstrap_promote_component
 cmp eax,6
 jne .f13
 lea rdi,[rel state]
 call neboc_bootstrap_rollback_promotion
 cmp eax,6
 jne .f14
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 14
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
