bits 64
default rel
%include "compiler/target/cross_compilation.inc"
global _start
extern neboc_cross_compilation_new,neboc_target_pack_runtime_objects
extern neboc_target_pack_system_contracts,neboc_target_pack_verify
extern neboc_cross_runner_new,neboc_runner_execute,neboc_runner_environment_manifest
extern neboc_runner_copy_artifact,neboc_runner_classify_result
extern neboc_cli_build_target,neboc_cli_run_target,neboc_cli_target_pack_verify
extern neboc_host_process_exit
section .data
host: dq 1
target: dq 1
pack: dq 1,target,0x12345678,3,0x1f,1
bad_pack: dq 1,target,0,3,0x1f,1
section .bss align=16
context: resb NEBOC_CROSS_CONTEXT_SIZE
runner: resb NEBOC_RUNNER_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel context]
 lea rsi,[rel host]
 lea rdx,[rel target]
 lea rcx,[rel pack]
 call neboc_cross_compilation_new
 test eax,eax
 jne .fail1
 lea rdi,[rel pack]
 lea rsi,[rel out]
 call neboc_target_pack_runtime_objects
 cmp qword [rel out],3
 jne .fail2
 call neboc_target_pack_system_contracts
 cmp qword [rel out],0x1f
 jne .fail3
 call neboc_target_pack_verify
 test eax,eax
 jne .fail4
 lea rdi,[rel bad_pack]
 call neboc_target_pack_verify
 cmp eax,4
 jne .fail5
 lea rdi,[rel runner]
 mov esi,1
 mov edx,1
 mov ecx,1000
 mov r8d,1
 call neboc_cross_runner_new
 test eax,eax
 jne .fail6
 mov esi,1
 lea rdx,[rel out]
 call neboc_runner_execute
 test eax,eax
 jne .fail7
 cmp qword [rel out],0
 jne .fail8
 lea rsi,[rel out]
 call neboc_runner_environment_manifest
 test eax,eax
 jne .fail9
 cmp qword [rel out],1
 jne .fail10
 mov esi,1
 mov edx,4096
 call neboc_runner_copy_artifact
 test eax,eax
 jne .fail11
 mov esi,2
 call neboc_runner_copy_artifact
 cmp eax,6
 jne .fail12
 lea rsi,[rel out]
 call neboc_runner_classify_result
 cmp qword [rel out],3
 jne .fail13
 lea rdi,[rel context]
 lea rsi,[rel out]
 call neboc_cli_build_target
 test eax,eax
 jne .fail14
 cmp qword [rel out],1
 jne .fail15
 lea rdi,[rel runner]
 mov esi,1
 lea rdx,[rel out]
 call neboc_cli_run_target
 test eax,eax
 jne .fail16
 lea rdi,[rel pack]
 call neboc_cli_target_pack_verify
 test eax,eax
 jne .fail17
 lea rdi,[rel runner]
 mov esi,2
 mov edx,2
 mov ecx,1000
 xor r8d,r8d
 call neboc_cross_runner_new
 test eax,eax
 jne .fail18
 mov esi,1
 lea rdx,[rel out]
 call neboc_runner_execute
 cmp eax,6
 jne .fail19
 lea rsi,[rel out]
 call neboc_runner_classify_result
 cmp qword [rel out],4
 jne .fail20
 lea rdi,[rel runner]
 mov esi,4
 mov ecx,1
 call neboc_cross_runner_new
 cmp eax,4
 jne .fail21
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 21
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
