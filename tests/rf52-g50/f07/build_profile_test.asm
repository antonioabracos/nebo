bits 64
default rel
%include "compiler/driver/build_profile.inc"
global _start
extern neboc_build_profile_debug,neboc_build_profile_release,neboc_build_profile_min_size
extern neboc_build_profile_custom,neboc_profile_optimization_level
extern neboc_profile_debug_info_policy,neboc_profile_diagnostic_table_policy
extern neboc_profile_runtime_policy,neboc_profile_reproducible,neboc_profile_manifest
extern neboc_cli_build_profile,neboc_cli_build_debug_control,neboc_cli_profile_explain
extern neboc_host_process_exit
section .data
custom: dq 4,9,4,2,2,3,1,NEBOC_PROFILE_SECURITY_CHECKS,0,0
section .bss align=16
profile: resb NEBOC_PROFILE_SIZE
manifest: resb NEBOC_PROFILE_SIZE
value: resq 1
section .text
_start:
 sub rsp,8
 lea rdi,[rel profile]
 call neboc_build_profile_debug
 test eax,eax
 jne .fail1
 cmp qword [rel profile+NEBOC_PROFILE_SECURITY_OFFSET],1
 jne .fail2
 lea rdi,[rel profile]
 mov esi,NEBOC_PROFILE_RELEASE
 call neboc_cli_build_profile
 test eax,eax
 jne .fail3
 lea rdi,[rel profile]
 lea rsi,[rel value]
 call neboc_profile_optimization_level
 test eax,eax
 jne .fail4
 cmp qword [rel value],2
 jne .fail5
 lea rdi,[rel profile]
 lea rsi,[rel value]
 call neboc_profile_debug_info_policy
 test eax,eax
 jne .fail6
 lea rdi,[rel profile]
 lea rsi,[rel value]
 call neboc_profile_diagnostic_table_policy
 test eax,eax
 jne .fail7
 lea rdi,[rel profile]
 lea rsi,[rel value]
 call neboc_profile_runtime_policy
 test eax,eax
 jne .fail8
 lea rdi,[rel profile]
 xor esi,esi
 call neboc_profile_reproducible
 test eax,eax
 jne .fail9
 lea rdi,[rel profile]
 mov esi,3
 mov edx,0xabc
 call neboc_cli_build_debug_control
 test eax,eax
 jne .fail10
 lea rdi,[rel profile]
 lea rsi,[rel manifest]
 call neboc_profile_manifest
 test eax,eax
 jne .fail11
 cmp qword [rel manifest+NEBOC_PROFILE_SPLIT_TOKEN_OFFSET],0xabc
 jne .fail12
 lea rdi,[rel profile]
 lea rsi,[rel manifest]
 call neboc_cli_profile_explain
 test eax,eax
 jne .fail13
 lea rdi,[rel profile]
 call neboc_build_profile_min_size
 test eax,eax
 jne .fail14
 cmp qword [rel profile+NEBOC_PROFILE_SECURITY_OFFSET],1
 jne .fail15
 lea rdi,[rel profile]
 lea rsi,[rel custom]
 call neboc_build_profile_custom
 test eax,eax
 jne .fail16
 cmp qword [rel profile+NEBOC_PROFILE_VERSION_OFFSET],9
 jne .fail17
 ; Custom profile without security proof is rejected.
 mov qword [rel custom+NEBOC_PROFILE_SECURITY_OFFSET],0
 lea rdi,[rel profile]
 lea rsi,[rel custom]
 call neboc_build_profile_custom
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
