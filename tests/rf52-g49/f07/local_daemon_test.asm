bits 64
default rel
%include "compiler/support/status/status_codes.inc"
%include "compiler/scheduler/local_daemon.inc"
global _start
extern neboc_compiler_server_start,neboc_compiler_client_connect
extern neboc_server_open_workspace,neboc_workspace_update
extern neboc_workspace_check,neboc_workspace_build
extern neboc_server_evict_workspace,neboc_server_memory_report
extern neboc_server_shutdown,neboc_cli_serve_local
extern neboc_cli_server_select,neboc_cli_server_admin
extern neboc_host_process_exit

section .bss align=16
server: resb NEBOC_DAEMON_SIZE
workspaces: resb NEBOC_WORKSPACE_SIZE*2
config: resb NEBOC_DAEMON_CONFIG_SIZE
connect_report: resb NEBOC_CONNECT_SIZE
request_report: resb neboc_local_daemon_REQUEST_SIZE
request_copy: resb neboc_local_daemon_REQUEST_SIZE
memory_report: resb NEBOC_MEMORY_SIZE
workspace_id: resq 1
workspace_id2: resq 1

section .text
init_config:
 mov qword [rel config+NEBOC_DAEMON_CONFIG_ENDPOINT_OFFSET],0xd00d
 mov qword [rel config+NEBOC_DAEMON_CONFIG_CAPABILITY_OFFSET],0xcafe
 mov qword [rel config+NEBOC_DAEMON_CONFIG_MAX_WORKSPACES_OFFSET],2
 mov qword [rel config+NEBOC_DAEMON_CONFIG_MAX_BYTES_OFFSET],64
 lea rax,[rel workspaces]
 mov [rel config+NEBOC_DAEMON_CONFIG_WORKSPACES_OFFSET],rax
 mov qword [rel config+NEBOC_DAEMON_CONFIG_CAPACITY_OFFSET],2
 ret

_start:
 sub rsp,8
 call init_config
 ; Public opt-in CLI start; non-local profiles are rejected.
 lea rdi,[rel server]
 lea rsi,[rel config]
 mov edx,1
 call neboc_cli_serve_local
 test eax,eax
 jne .fail1
 cmp qword [rel server+NEBOC_DAEMON_ACTIVE_OFFSET],1
 jne .fail2

 ; Exact version/capability connects; auto mismatch falls back one-shot.
 lea rdi,[rel server]
 mov esi,NEBOC_DAEMON_MODE_AUTO
 mov edx,0xd00d
 mov ecx,0xcafe
 lea r8,[rel connect_report]
 call neboc_cli_server_select
 test eax,eax
 jne .fail3
 cmp qword [rel connect_report+NEBOC_CONNECT_CONNECTED_OFFSET],1
 jne .fail4
 lea rdi,[rel server]
 mov esi,0xd00d
 mov edx,2
 mov ecx,0xcafe
 mov r8d,NEBOC_DAEMON_MODE_AUTO
 lea r9,[rel connect_report]
 call neboc_compiler_client_connect
 test eax,eax
 jne .fail5
 cmp qword [rel connect_report+NEBOC_CONNECT_FALLBACK_OFFSET],1
 jne .fail6
 lea rdi,[rel server]
 mov esi,0xd00d
 mov edx,2
 mov ecx,0xcafe
 mov r8d,NEBOC_DAEMON_MODE_EXPLICIT
 lea r9,[rel connect_report]
 call neboc_compiler_client_connect
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail7
 lea rdi,[rel server]
 mov esi,NEBOC_DAEMON_MODE_OFF
 xor edx,edx
 xor ecx,ecx
 lea r8,[rel connect_report]
 call neboc_cli_server_select
 test eax,eax
 jne .fail8
 cmp qword [rel connect_report+NEBOC_CONNECT_FALLBACK_OFFSET],1
 jne .fail9

 ; Workspace file tokens are rooted by the high 32 bits.
 lea rdi,[rel server]
 mov esi,0x31
 mov edx,1
 lea rcx,[rel workspace_id]
 call neboc_server_open_workspace
 test eax,eax
 jne .fail10
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,0x31
 mov rcx,0x3200000001
 mov r8d,8
 mov r9d,0xabc
 call neboc_workspace_update
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail11
 cmp qword [rel workspaces+NEBOC_WORKSPACE_REVISION_OFFSET],0
 jne .fail12
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,0x31
 mov rcx,0x3100000001
 mov r8d,8
 mov r9d,0xabc
 call neboc_workspace_update
 test eax,eax
 jne .fail13
 cmp qword [rel workspaces+NEBOC_WORKSPACE_REVISION_OFFSET],1
 jne .fail14

 ; Check/build are snapshot-bound, deterministic, and zero stale output.
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,1
 mov ecx,0x55
 lea r8,[rel request_report]
 call neboc_workspace_check
 test eax,eax
 jne .fail15
 mov rax,[rel request_report+NEBOC_REQUEST_DIGEST_OFFSET]
 mov [rel request_copy+NEBOC_REQUEST_DIGEST_OFFSET],rax
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,1
 mov ecx,0x55
 lea r8,[rel request_report]
 call neboc_workspace_check
 test eax,eax
 jne .fail16
 mov rax,[rel request_copy+NEBOC_REQUEST_DIGEST_OFFSET]
 cmp rax,[rel request_report+NEBOC_REQUEST_DIGEST_OFFSET]
 jne .fail17
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,1
 mov ecx,0x66
 lea r8,[rel request_report]
 call neboc_workspace_build
 test eax,eax
 jne .fail18
 cmp qword [rel request_report+NEBOC_REQUEST_DIGEST_OFFSET],0
 je .fail19
 mov qword [rel request_report+NEBOC_REQUEST_REVISION_OFFSET],99
 mov qword [rel request_report+NEBOC_REQUEST_DIGEST_OFFSET],99
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 xor edx,edx
 mov ecx,0x66
 lea r8,[rel request_report]
 call neboc_workspace_build
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail20
 cmp qword [rel request_report+NEBOC_REQUEST_REVISION_OFFSET],0
 jne .fail21
 cmp qword [rel request_report+NEBOC_REQUEST_DIGEST_OFFSET],0
 jne .fail22

 ; A second capability-rooted workspace remains isolated.
 lea rdi,[rel server]
 mov esi,0x41
 mov edx,1
 lea rcx,[rel workspace_id2]
 call neboc_server_open_workspace
 test eax,eax
 jne .fail23
 lea rdi,[rel server]
 mov rsi,[rel workspace_id2]
 mov edx,0x41
 mov rcx,0x3100000002
 mov r8d,8
 mov r9d,0xdef
 call neboc_workspace_update
 cmp eax,NEBOC_STATUS_INVALID_SOURCE
 jne .fail24
 lea rdi,[rel server]
 mov esi,0x51
 mov edx,1
 lea rcx,[rel request_copy]
 call neboc_server_open_workspace
 cmp eax,NEBOC_STATUS_LIMIT_EXCEEDED
 jne .fail25

 ; Memory and eviction accounting are bounded and observable.
 lea rdi,[rel server]
 lea rsi,[rel memory_report]
 call neboc_server_memory_report
 test eax,eax
 jne .fail26
 cmp qword [rel memory_report+NEBOC_MEMORY_WORKSPACES_OFFSET],2
 jne .fail27
 cmp qword [rel memory_report+NEBOC_MEMORY_BYTES_OFFSET],8
 jne .fail28
 cmp qword [rel memory_report+NEBOC_MEMORY_HIGH_WATER_OFFSET],8
 jne .fail29
 cmp qword [rel memory_report+NEBOC_MEMORY_REQUESTS_OFFSET],3
 jne .fail30
 lea rdi,[rel server]
 mov rsi,[rel workspace_id]
 mov edx,1
 call neboc_server_evict_workspace
 test eax,eax
 jne .fail31
 cmp qword [rel server+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET],1
 jne .fail32
 cmp qword [rel server+NEBOC_DAEMON_BYTES_OFFSET],0
 jne .fail33

 ; CLI status and stop use the same state; shutdown clears sessions.
 lea rdi,[rel server]
 mov esi,NEBOC_DAEMON_ADMIN_STATUS
 xor edx,edx
 lea rcx,[rel memory_report]
 call neboc_cli_server_admin
 test eax,eax
 jne .fail34
 cmp qword [rel memory_report+NEBOC_MEMORY_EVICTIONS_OFFSET],1
 jne .fail35
 lea rdi,[rel server]
 mov esi,NEBOC_DAEMON_ADMIN_STOP
 mov edx,1
 xor ecx,ecx
 call neboc_cli_server_admin
 test eax,eax
 jne .fail36
 cmp qword [rel server+NEBOC_DAEMON_ACTIVE_OFFSET],0
 jne .fail37
 cmp qword [rel workspaces+NEBOC_WORKSPACE_ACTIVE_OFFSET],0
 jne .fail38
 cmp qword [rel workspaces+NEBOC_WORKSPACE_SIZE+NEBOC_WORKSPACE_ACTIVE_OFFSET],0
 jne .fail39

 xor edi,edi
 call neboc_host_process_exit
%assign n 1
%rep 39
.fail%+n:
 mov edi,n
 call neboc_host_process_exit
%assign n n+1
%endrep
section .note.GNU-stack noalloc noexec nowrite progbits
