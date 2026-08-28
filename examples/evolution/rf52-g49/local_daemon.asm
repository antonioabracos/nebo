bits 64
default rel
%include "compiler/scheduler/local_daemon.inc"
global _start
extern neboc_cli_serve_local,neboc_cli_server_admin,neboc_host_process_exit
section .bss align=16
server: resb NEBOC_DAEMON_SIZE
workspaces: resb NEBOC_WORKSPACE_SIZE
config: resb NEBOC_DAEMON_CONFIG_SIZE
section .text
_start:
 sub rsp,8
 mov qword [rel config+NEBOC_DAEMON_CONFIG_ENDPOINT_OFFSET],1
 mov qword [rel config+NEBOC_DAEMON_CONFIG_CAPABILITY_OFFSET],2
 mov qword [rel config+NEBOC_DAEMON_CONFIG_MAX_WORKSPACES_OFFSET],1
 mov qword [rel config+NEBOC_DAEMON_CONFIG_MAX_BYTES_OFFSET],64
 lea rax,[rel workspaces]
 mov [rel config+NEBOC_DAEMON_CONFIG_WORKSPACES_OFFSET],rax
 mov qword [rel config+NEBOC_DAEMON_CONFIG_CAPACITY_OFFSET],1
 lea rdi,[rel server]
 lea rsi,[rel config]
 mov edx,1
 call neboc_cli_serve_local
 test eax,eax
 jne .done
 lea rdi,[rel server]
 mov esi,NEBOC_DAEMON_ADMIN_STOP
 mov edx,1
 xor ecx,ecx
 call neboc_cli_server_admin
.done:
 mov edi,eax
 call neboc_host_process_exit
section .note.GNU-stack noalloc noexec nowrite progbits
