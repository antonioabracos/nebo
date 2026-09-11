bits 64
default rel
%include "compiler/toolchain/hermetic_build.inc"
global _start
extern neboc_hermetic_build_context_new,neboc_hermetic_allow_environment,neboc_hermetic_allow_files
extern neboc_hermetic_deny_network,neboc_hermetic_fixed_epoch,neboc_hermetic_path_remap
extern neboc_hermetic_fixed_locale,neboc_hermetic_fixed_random_seed,neboc_hermetic_record_inputs
extern neboc_reproducibility_compare,neboc_reproducibility_first_difference
extern neboc_cli_build_hermetic,neboc_cli_reproducibility_report,neboc_host_process_exit
section .bss align=16
context: resb NEBOC_HERM_SIZE
report: resq 4
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 mov esi,1
 mov edx,0x11
 mov ecx,0x22
 call neboc_hermetic_build_context_new
 test eax,eax
 jne .f1
 lea rdi,[rel context]
 mov esi,3
 mov edx,0x33
 call neboc_hermetic_allow_environment
 test eax,eax
 jne .f2
 lea rdi,[rel context]
 mov esi,4
 mov edx,0x44
 call neboc_hermetic_allow_files
 test eax,eax
 jne .f3
 lea rdi,[rel context]
 call neboc_hermetic_deny_network
 test eax,eax
 jne .f4
 lea rdi,[rel context]
 xor esi,esi
 call neboc_hermetic_fixed_epoch
 lea rdi,[rel context]
 mov esi,0x55
 mov edx,0x66
 call neboc_hermetic_path_remap
 test eax,eax
 jne .f5
 lea rdi,[rel context]
 mov esi,1
 call neboc_hermetic_fixed_locale
 test eax,eax
 jne .f6
 lea rdi,[rel context]
 mov esi,0x77
 call neboc_hermetic_fixed_random_seed
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_hermetic_record_inputs
 test eax,eax
 jne .f7
 cmp qword [rel report+8],15
 jne .f8
 mov rdi,[rel report]
 mov rsi,rdi
 mov edx,1
 lea rcx,[rel report+16]
 call neboc_reproducibility_compare
 cmp qword [rel report+16],1
 jne .f9
 lea rdi,[rel report+16]
 lea rsi,[rel report]
 call neboc_reproducibility_first_difference
 cmp qword [rel report],-1
 jne .f10
 lea rdi,[rel context]
 lea rsi,[rel report]
 call neboc_cli_build_hermetic
 test eax,eax
 jne .f11
 mov edi,1
 mov esi,2
 mov edx,1
 lea rcx,[rel report]
 call neboc_cli_reproducibility_report
 cmp qword [rel report],4
 jne .f12
 lea rdi,[rel context]
 mov esi,9
 xor edx,edx
 call neboc_hermetic_allow_environment
 cmp eax,8
 jne .f13
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 13
.f%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
