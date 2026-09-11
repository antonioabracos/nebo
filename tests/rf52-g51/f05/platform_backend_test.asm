bits 64
default rel
%include "compiler/platform/platform_backend.inc"
global _start
extern neboc_platform_backend_for_target,neboc_platform_filesystem,neboc_platform_network
extern neboc_platform_process,neboc_platform_time,neboc_platform_random,neboc_platform_threads
extern neboc_platform_window,neboc_platform_error_map,neboc_platform_resource_limits
extern neboc_platform_self_test,neboc_cli_platform_report,neboc_host_process_exit
section .data
target: dq 1,1,1,64,16,1,1,1,1,1,0x1f,0x3f,3
aarch64: dq 2,1,1,64,16,2,1,1,1,2,1,7,1
section .bss align=16
backend: resb NEBOC_PLATFORM_SIZE
out: resq 8
section .text
_start:
 sub rsp,8
 lea rdi,[rel backend]
 lea rsi,[rel target]
 mov edx,0x3f
 call neboc_platform_backend_for_target
 test eax,eax
 jne .fail1
 lea rsi,[rel out]
 call neboc_platform_filesystem
 test eax,eax
 jne .fail2
 call neboc_platform_network
 test eax,eax
 jne .fail3
 call neboc_platform_process
 test eax,eax
 jne .fail4
 call neboc_platform_time
 test eax,eax
 jne .fail5
 call neboc_platform_random
 test eax,eax
 jne .fail6
 call neboc_platform_threads
 test eax,eax
 jne .fail7
 call neboc_platform_window
 cmp eax,6
 jne .fail8
 mov esi,13
 lea rdx,[rel out]
 call neboc_platform_error_map
 test eax,eax
 jne .fail9
 cmp qword [rel out+8],13
 jne .fail10
 lea rsi,[rel out]
 call neboc_platform_resource_limits
 test eax,eax
 jne .fail11
 cmp qword [rel out],1024
 jne .fail12
 call neboc_platform_self_test
 test eax,eax
 jne .fail13
 cmp qword [rel out],2
 jne .fail14
 call neboc_cli_platform_report
 test eax,eax
 jne .fail15
 cmp qword [rel out],1
 jne .fail16
 cmp qword [rel out+16],0x3f
 jne .fail17
 lea rdi,[rel backend]
 lea rsi,[rel target]
 mov edx,0x40
 call neboc_platform_backend_for_target
 cmp eax,6
 jne .fail18
 lea rsi,[rel aarch64]
 xor edx,edx
 call neboc_platform_backend_for_target
 cmp eax,6
 jne .fail19
 xor rdi,rdi
 lea rsi,[rel out]
 call neboc_platform_filesystem
 cmp eax,1
 jne .fail20
 lea rdi,[rel backend]
 lea rsi,[rel target]
 mov edx,0x1f
 call neboc_platform_backend_for_target
 test eax,eax
 jne .fail21
 lea rsi,[rel out]
 call neboc_cli_platform_report
 test eax,eax
 jne .fail22
 cmp qword [rel out+8],0x1f
 jne .fail23
 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 23
.fail%+n: mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
