; LOCAL-DAEMON-F07 bounded, offline, caller-owned local daemon state machine.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "compiler/support/status/status_codes.inc"
%include "compiler/scheduler/local_daemon.inc"

section .text
; rdi=server rsi=id -> rax=workspace or zero.
daemon_find_workspace:
 mov rax,[rdi+NEBOC_DAEMON_WORKSPACES_OFFSET]
 xor ecx,ecx
.loop:
 cmp rcx,[rdi+NEBOC_DAEMON_CAPACITY_OFFSET]
 jae .missing
 cmp qword [rax+NEBOC_WORKSPACE_ACTIVE_OFFSET],1
 jne .next
 cmp [rax+NEBOC_WORKSPACE_ID_OFFSET],rsi
 je .done
.next:
 add rax,NEBOC_WORKSPACE_SIZE
 inc rcx
 jmp .loop
.missing:
 xor eax,eax
.done:
 ret

NEBOC_ABI_FUNCTION neboc_compiler_server_start
 ; rdi=server rsi=config. Endpoint and capability are opaque local tokens.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rsi+NEBOC_DAEMON_CONFIG_ENDPOINT_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_DAEMON_CONFIG_CAPABILITY_OFFSET],0
 je .invalid
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_MAX_WORKSPACES_OFFSET]
 test rax,rax
 jz .invalid
 cmp rax,NEBOC_DAEMON_MAX_WORKSPACES
 ja .limit
 cmp qword [rsi+NEBOC_DAEMON_CONFIG_MAX_BYTES_OFFSET],0
 je .invalid
 cmp qword [rsi+NEBOC_DAEMON_CONFIG_WORKSPACES_OFFSET],0
 je .invalid
 cmp rax,[rsi+NEBOC_DAEMON_CONFIG_CAPACITY_OFFSET]
 ja .invalid
 mov r10,rdi
 xor eax,eax
 mov ecx,NEBOC_DAEMON_SIZE/8
 rep stosq
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_ENDPOINT_OFFSET]
 mov [r10+NEBOC_DAEMON_ENDPOINT_OFFSET],rax
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_CAPABILITY_OFFSET]
 mov [r10+NEBOC_DAEMON_CAPABILITY_OFFSET],rax
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_MAX_WORKSPACES_OFFSET]
 mov [r10+NEBOC_DAEMON_MAX_WORKSPACES_OFFSET],rax
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_MAX_BYTES_OFFSET]
 mov [r10+NEBOC_DAEMON_MAX_BYTES_OFFSET],rax
 mov rax,[rsi+NEBOC_DAEMON_CONFIG_WORKSPACES_OFFSET]
 mov [r10+NEBOC_DAEMON_WORKSPACES_OFFSET],rax
 mov rdx,[rsi+NEBOC_DAEMON_CONFIG_CAPACITY_OFFSET]
 mov [r10+NEBOC_DAEMON_CAPACITY_OFFSET],rdx
 mov qword [r10+NEBOC_DAEMON_NEXT_ID_OFFSET],1
 mov qword [r10+NEBOC_DAEMON_ACTIVE_OFFSET],1
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_compiler_client_connect
 ; rdi=server rsi=endpoint rdx=expected version rcx=capability r8=mode r9=report.
 test r9,r9
 jz .invalid
 mov qword [r9+NEBOC_CONNECT_CONNECTED_OFFSET],0
 mov qword [r9+NEBOC_CONNECT_FALLBACK_OFFSET],0
 mov qword [r9+NEBOC_CONNECT_VERSION_OFFSET],NEBOC_DAEMON_PROTOCOL_VERSION
 cmp r8,NEBOC_DAEMON_MODE_OFF
 je .fallback
 cmp r8,NEBOC_DAEMON_MODE_AUTO
 je .try
 cmp r8,NEBOC_DAEMON_MODE_EXPLICIT
 jne .invalid
.try:
 test rdi,rdi
 jz .unavailable
 cmp qword [rdi+NEBOC_DAEMON_ACTIVE_OFFSET],1
 jne .unavailable
 cmp [rdi+NEBOC_DAEMON_ENDPOINT_OFFSET],rsi
 jne .unavailable
 cmp [rdi+NEBOC_DAEMON_CAPABILITY_OFFSET],rcx
 jne .unavailable
 cmp rdx,NEBOC_DAEMON_PROTOCOL_VERSION
 jne .mismatch
 mov qword [r9+NEBOC_CONNECT_CONNECTED_OFFSET],1
 xor eax,eax
 ret
.mismatch:
 inc qword [rdi+NEBOC_DAEMON_MISMATCHES_OFFSET]
.unavailable:
 cmp r8,NEBOC_DAEMON_MODE_AUTO
 je .fallback
 mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.fallback:
 mov qword [r9+NEBOC_CONNECT_FALLBACK_OFFSET],1
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_server_open_workspace
 ; rdi=server rsi=root capability token rdx=policy rcx=out id.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 test rdx,rdx
 jz .invalid
 test rcx,rcx
 jz .invalid
 cmp qword [rdi+NEBOC_DAEMON_ACTIVE_OFFSET],1
 jne .invalid
 mov rax,[rdi+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET]
 cmp rax,[rdi+NEBOC_DAEMON_MAX_WORKSPACES_OFFSET]
 jae .limit
 mov rax,[rdi+NEBOC_DAEMON_WORKSPACES_OFFSET]
 xor r8d,r8d
.find:
 cmp r8,[rdi+NEBOC_DAEMON_CAPACITY_OFFSET]
 jae .limit
 cmp qword [rax+NEBOC_WORKSPACE_ACTIVE_OFFSET],0
 je .open
 add rax,NEBOC_WORKSPACE_SIZE
 inc r8
 jmp .find
.open:
 mov r9,[rdi+NEBOC_DAEMON_NEXT_ID_OFFSET]
 inc qword [rdi+NEBOC_DAEMON_NEXT_ID_OFFSET]
 mov [rax+NEBOC_WORKSPACE_ID_OFFSET],r9
 mov [rax+NEBOC_WORKSPACE_ROOT_OFFSET],rsi
 mov [rax+NEBOC_WORKSPACE_POLICY_OFFSET],rdx
 mov qword [rax+NEBOC_WORKSPACE_REVISION_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_BYTES_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_CONTENT_HASH_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_DIAGNOSTIC_HASH_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_ARTEFACT_HASH_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_GENERATION_OFFSET],1
 mov qword [rax+NEBOC_WORKSPACE_ACTIVE_OFFSET],1
 inc qword [rdi+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET]
 mov [rcx],r9
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_workspace_update
 ; rdi=server rsi=workspace id rdx=root token rcx=file token r8=bytes r9=content hash.
 test rdi,rdi
 jz .invalid
 test r8,r8
 jz .invalid
 test r9,r9
 jz .invalid
 mov r10,rdi
 mov r11,rcx
 call daemon_find_workspace
 test rax,rax
 jz .invalid_source
 cmp [rax+NEBOC_WORKSPACE_ROOT_OFFSET],rdx
 jne .invalid_source
 shr r11,32
 cmp r11,rdx
 jne .invalid_source
 mov rcx,[r10+NEBOC_DAEMON_BYTES_OFFSET]
 add rcx,r8
 jc .limit
 cmp rcx,[r10+NEBOC_DAEMON_MAX_BYTES_OFFSET]
 ja .limit
 mov [r10+NEBOC_DAEMON_BYTES_OFFSET],rcx
 cmp rcx,[r10+NEBOC_DAEMON_HIGH_WATER_OFFSET]
 jbe .water_done
 mov [r10+NEBOC_DAEMON_HIGH_WATER_OFFSET],rcx
.water_done:
 add [rax+NEBOC_WORKSPACE_BYTES_OFFSET],r8
 mov [rax+NEBOC_WORKSPACE_CONTENT_HASH_OFFSET],r9
 inc qword [rax+NEBOC_WORKSPACE_REVISION_OFFSET]
 inc qword [rax+NEBOC_WORKSPACE_GENERATION_OFFSET]
 mov qword [rax+NEBOC_WORKSPACE_DIAGNOSTIC_HASH_OFFSET],0
 mov qword [rax+NEBOC_WORKSPACE_ARTEFACT_HASH_OFFSET],0
 xor eax,eax
 ret
.limit: mov eax,NEBOC_STATUS_LIMIT_EXCEEDED
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_workspace_check
 ; rdi=server rsi=id rdx=expected revision rcx=request digest r8=result.
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov r10,rdi
 mov r9,rcx
 call daemon_find_workspace
 test rax,rax
 jz .invalid_source
 mov r11,[rax+NEBOC_WORKSPACE_REVISION_OFFSET]
 cmp r11,rdx
 jne .stale
 mov [r8+NEBOC_REQUEST_REVISION_OFFSET],r11
 mov rdx,[rax+NEBOC_WORKSPACE_CONTENT_HASH_OFFSET]
 xor rdx,r9
 rol rdx,17
 xor rdx,0x52465207
 mov [rax+NEBOC_WORKSPACE_DIAGNOSTIC_HASH_OFFSET],rdx
 mov [r8+NEBOC_REQUEST_DIGEST_OFFSET],rdx
 inc qword [r10+NEBOC_DAEMON_REQUESTS_OFFSET]
 xor eax,eax
 ret
.stale:
 mov qword [r8+NEBOC_REQUEST_REVISION_OFFSET],0
 mov qword [r8+NEBOC_REQUEST_DIGEST_OFFSET],0
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_workspace_build
 ; Same snapshot contract as one-shot reference; different domain separator.
 test rdi,rdi
 jz .invalid
 test rcx,rcx
 jz .invalid
 test r8,r8
 jz .invalid
 mov r10,rdi
 mov r9,rcx
 call daemon_find_workspace
 test rax,rax
 jz .invalid_source
 mov r11,[rax+NEBOC_WORKSPACE_REVISION_OFFSET]
 cmp r11,rdx
 jne .stale
 mov [r8+NEBOC_REQUEST_REVISION_OFFSET],r11
 mov rdx,[rax+NEBOC_WORKSPACE_CONTENT_HASH_OFFSET]
 xor rdx,r9
 rol rdx,29
 xor rdx,0x52465208
 mov [rax+NEBOC_WORKSPACE_ARTEFACT_HASH_OFFSET],rdx
 mov [r8+NEBOC_REQUEST_DIGEST_OFFSET],rdx
 inc qword [r10+NEBOC_DAEMON_REQUESTS_OFFSET]
 xor eax,eax
 ret
.stale:
 mov qword [r8+NEBOC_REQUEST_REVISION_OFFSET],0
 mov qword [r8+NEBOC_REQUEST_DIGEST_OFFSET],0
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_server_evict_workspace
 ; rdi=server rsi=id rdx=nonzero reason.
 test rdi,rdi
 jz .invalid
 test rdx,rdx
 jz .invalid
 mov r10,rdi
 call daemon_find_workspace
 test rax,rax
 jz .invalid_source
 mov r8,[rax+NEBOC_WORKSPACE_BYTES_OFFSET]
 sub [r10+NEBOC_DAEMON_BYTES_OFFSET],r8
 dec qword [r10+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET]
 inc qword [r10+NEBOC_DAEMON_EVICTIONS_OFFSET]
 mov rdi,rax
 xor eax,eax
 mov ecx,NEBOC_WORKSPACE_SIZE/8
 rep stosq
 xor eax,eax
 ret
.invalid_source: mov eax,NEBOC_STATUS_INVALID_SOURCE
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_server_memory_report
 ; rdi=server rsi=report.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 mov rax,[rdi+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET]
 mov [rsi+NEBOC_MEMORY_WORKSPACES_OFFSET],rax
 mov rax,[rdi+NEBOC_DAEMON_BYTES_OFFSET]
 mov [rsi+NEBOC_MEMORY_BYTES_OFFSET],rax
 mov rax,[rdi+NEBOC_DAEMON_HIGH_WATER_OFFSET]
 mov [rsi+NEBOC_MEMORY_HIGH_WATER_OFFSET],rax
 mov rax,[rdi+NEBOC_DAEMON_EVICTIONS_OFFSET]
 mov [rsi+NEBOC_MEMORY_EVICTIONS_OFFSET],rax
 mov rax,[rdi+NEBOC_DAEMON_REQUESTS_OFFSET]
 mov [rsi+NEBOC_MEMORY_REQUESTS_OFFSET],rax
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_server_shutdown
 ; rdi=server rsi=bounded nonzero deadline token.
 test rdi,rdi
 jz .invalid
 test rsi,rsi
 jz .invalid
 cmp qword [rdi+NEBOC_DAEMON_ACTIVE_OFFSET],1
 jne .invalid
 mov r10,rdi
 mov rdi,[r10+NEBOC_DAEMON_WORKSPACES_OFFSET]
 mov rdx,[r10+NEBOC_DAEMON_CAPACITY_OFFSET]
 xor r8d,r8d
.clear:
 cmp r8,rdx
 jae .closed
 xor eax,eax
 mov ecx,NEBOC_WORKSPACE_SIZE/8
 rep stosq
 inc r8
 jmp .clear
.closed:
 mov qword [r10+NEBOC_DAEMON_ACTIVE_OFFSET],0
 mov qword [r10+NEBOC_DAEMON_ENDPOINT_OFFSET],0
 mov qword [r10+NEBOC_DAEMON_WORKSPACE_COUNT_OFFSET],0
 mov qword [r10+NEBOC_DAEMON_BYTES_OFFSET],0
 xor eax,eax
 ret
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_serve_local
 ; rdi=server rsi=config rdx=local flag.
 cmp rdx,1
 jne .invalid
 jmp neboc_compiler_server_start
.invalid: mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret

NEBOC_ABI_FUNCTION neboc_cli_server_select
 ; rdi=server rsi=mode rdx=endpoint rcx=capability r8=report.
 mov r9,r8
 mov r8,rsi
 mov rsi,rdx
 mov edx,NEBOC_DAEMON_PROTOCOL_VERSION
 jmp neboc_compiler_client_connect

NEBOC_ABI_FUNCTION neboc_cli_server_admin
 ; rdi=server rsi=command rdx=deadline rcx=report.
 cmp rsi,NEBOC_DAEMON_ADMIN_STATUS
 je .status
 cmp rsi,NEBOC_DAEMON_ADMIN_STOP
 je .stop
 mov eax,NEBOC_STATUS_INVALID_ARGUMENT
 ret
.status:
 mov rsi,rcx
 jmp neboc_server_memory_report
.stop:
 mov rsi,rdx
 jmp neboc_server_shutdown

section .note.GNU-stack noalloc noexec nowrite progbits
