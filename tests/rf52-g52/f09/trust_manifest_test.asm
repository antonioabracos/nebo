bits 64
default rel
%include "compiler/toolchain/trust_manifest.inc"
global _start
extern neboc_trust_manifest_new,neboc_trust_manifest_add_component,neboc_trust_manifest_add_environment
extern neboc_trust_manifest_add_license,neboc_trust_manifest_add_review,neboc_trust_manifest_add_build_input
extern neboc_trust_manifest_add_reproducibility,neboc_trust_manifest_tcb,neboc_trust_manifest_diff
extern neboc_trust_manifest_sign,neboc_trust_manifest_verify,neboc_cli_trust_manifest
extern neboc_cli_provenance_verify,neboc_host_process_exit
section .bss align=16
manifest: resb NEBOC_TRUST_SIZE
other: resb NEBOC_TRUST_SIZE
out: resq 12
section .text
_start:
 sub rsp,8
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,1
 call neboc_trust_manifest_new
 test eax,eax
 jne .f1
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,1
 mov ecx,0x11
 call neboc_trust_manifest_add_component
 test eax,eax
 jne .f2
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,2
 mov ecx,3
 call neboc_trust_manifest_add_environment
 test eax,eax
 jne .f3
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,0x22
 call neboc_trust_manifest_add_license
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,1
 mov ecx,0x33
 call neboc_trust_manifest_add_review
 lea rdi,[rel manifest]
 mov esi,1
 mov edx,0x44
 call neboc_trust_manifest_add_build_input
 lea rdi,[rel manifest]
 mov esi,1
 call neboc_trust_manifest_add_reproducibility
 lea rdi,[rel manifest]
 lea rsi,[rel out]
 call neboc_trust_manifest_tcb
 cmp qword [rel out],1
 jne .f4
 cmp qword [rel out+8],7
 jne .f5
 lea rdi,[rel manifest]
 call neboc_trust_manifest_sign
 cmp eax,6
 jne .f6
 mov rsi,[rel manifest+64]
 lea rdi,[rel manifest]
 lea rdx,[rel out]
 call neboc_trust_manifest_verify
 test eax,eax
 jne .f7
 cmp qword [rel out+8],0
 jne .f8
 lea rdi,[rel other]
 mov esi,1
 mov edx,1
 call neboc_trust_manifest_new
 lea rdi,[rel manifest]
 lea rsi,[rel other]
 lea rdx,[rel out]
 call neboc_trust_manifest_diff
 cmp qword [rel out+8],1
 jne .f9
 lea rdi,[rel manifest]
 lea rsi,[rel out]
 call neboc_cli_trust_manifest
 cmp qword [rel out+16],1
 jne .f10
 mov rsi,[rel manifest+64]
 lea rdi,[rel manifest]
 lea rdx,[rel out]
 call neboc_cli_provenance_verify
 test eax,eax
 jne .f11
 lea rdi,[rel manifest]
 xor esi,esi
 mov edx,1
 mov ecx,1
 call neboc_trust_manifest_add_component
 cmp eax,4
 jne .f12
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 12
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
