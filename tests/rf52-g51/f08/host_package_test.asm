bits 64
default rel
%include "compiler/platform/host_package.inc"
global _start
extern neboc_host_compiler_plan_for_triple,neboc_host_compiler_plan_bootstrap_source
extern neboc_host_compiler_plan_platform_backend,neboc_host_compiler_plan_package_layout
extern neboc_host_compiler_plan_self_test_suite,neboc_host_compiler_package_verify
extern neboc_host_compiler_package_restore_test,neboc_host_compiler_compatibility_report
extern neboc_host_compiler_external_dependencies,neboc_cli_self_test_host
extern neboc_cli_host_package_verify,neboc_host_process_exit
section .data
package: dq 1,1,0x1234,1,0,2,32
package2: dq 1,1,0x5678,1,0,2,32
bad_package: dq 1,1,0,1,0,2,32
section .bss align=16
plan: resb NEBOC_HOST_PLAN_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel plan]
 mov esi,1
 call neboc_host_compiler_plan_for_triple
 test eax,eax
 jne .fail1
 lea rsi,[rel out]
 call neboc_host_compiler_plan_bootstrap_source
 test eax,eax
 jne .fail2
 cmp qword [rel out],1
 jne .fail3
 cmp qword [rel out+8],0
 jne .fail4
 call neboc_host_compiler_plan_platform_backend
 cmp qword [rel out],1
 jne .fail5
 call neboc_host_compiler_plan_package_layout
 cmp qword [rel out],0x1f
 jne .fail6
 call neboc_host_compiler_plan_self_test_suite
 cmp qword [rel out],0x1f
 jne .fail7
 lea rdi,[rel package]
 call neboc_host_compiler_package_verify
 test eax,eax
 jne .fail8
 lea rdi,[rel bad_package]
 call neboc_host_compiler_package_verify
 cmp eax,4
 jne .fail9
 lea rdi,[rel package]
 lea rsi,[rel out]
 call neboc_host_compiler_package_restore_test
 test eax,eax
 jne .fail10
 cmp qword [rel out],1
 jne .fail11
 lea rsi,[rel package2]
 lea rdx,[rel out]
 call neboc_host_compiler_compatibility_report
 test eax,eax
 jne .fail12
 cmp qword [rel out],1
 jne .fail13
 cmp qword [rel out+16],1
 jne .fail14
 lea rsi,[rel out]
 call neboc_host_compiler_external_dependencies
 test eax,eax
 jne .fail15
 cmp qword [rel out],0
 jne .fail16
 cmp qword [rel out+8],2
 jne .fail17
 lea rsi,[rel out]
 call neboc_cli_self_test_host
 test eax,eax
 jne .fail18
 call neboc_cli_host_package_verify
 test eax,eax
 jne .fail19
 lea rdi,[rel plan]
 mov esi,2
 call neboc_host_compiler_plan_for_triple
 cmp eax,6
 jne .fail20
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 20
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
