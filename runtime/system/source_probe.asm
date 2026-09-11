; G012 source-to-effect probe. One source-derived subgroup and seed reach their
; actual runtime owners; the observable process result remains deterministic.
bits 64
default rel
%include "runtime/system/time.inc"
%include "runtime/system/random.inc"
%include "runtime/system/process.inc"
%include "runtime/network/address.inc"
%include "runtime/network/socket.inc"
%include "runtime/network/http.inc"
%include "runtime/network/tls.inc"
%include "runtime/crypto/aead_kdf.inc"

section .rodata
loopback_text db '127.0.0.1'
http_response db 'HTTP/1.1 204 No Content',13,10,'Content-Length: 0',13,10,13,10
http_response_len equ $-http_response
local_name db 'localhost'
trust_key db 'Jefe'

section .text
global nebo_g012_source_probe
nebo_g012_source_probe:
 push rbx
 push r12
 push r13
 mov r12d,edi
 mov r13d,esi
 sub rsp,1024
 cmp r12d,1
 je .time
 cmp r12d,2
 je .random
 cmp r12d,3
 je .process
 cmp r12d,4
 je .address
 cmp r12d,5
 je .socket
 cmp r12d,6
 je .http_tls
 cmp r12d,7
 je .crypto
 jmp .failure
.time:
 mov rdi,rsp
 mov rsi,r13
 call nebo_duration_from_millis
 test eax,eax
 jnz .failure
 mov rdi,rsp
 call nebo_duration_as_nanos
 test eax,eax
 jnz .failure
 test rdx,rdx
 jz .failure
 jmp .success
.random:
 mov rdi,rsp
 mov rsi,r13
 call nebo_random_seed
 test eax,eax
 jnz .failure
 mov rdi,rsp
 call nebo_random_next_u64
 test eax,eax
 jnz .failure
 jmp .success
.process:
 call nebo_process_current_pid
 test eax,eax
 jnz .failure
 test rdx,rdx
 jz .failure
 jmp .success
.address:
 mov rdi,rsp
 lea rsi,[loopback_text]
 mov edx,9
 call nebo_ip_parse
 test eax,eax
 jnz .failure
 mov rdi,rsp
 lea rsi,[rsp+64]
 mov edx,64
 call nebo_ip_format
 test eax,eax
 jnz .failure
 cmp rdx,9
 jne .failure
 jmp .success
.socket:
 lea rdi,[rsp]
 mov esi,NEBO_NETWORK_CAP_ALL
 mov edx,2
 mov ecx,1024
 mov r8d,1000000
 call nebo_network_capability_init
 test eax,eax
 jnz .failure
 mov qword [rsp+64+NEBO_IP_FAMILY],NEBO_IP_FAMILY_V4
 mov dword [rsp+64+NEBO_IP_BYTES],0x0100007f
 lea rdi,[rsp+96]
 lea rsi,[rsp+64]
 xor edx,edx
 call nebo_socket_address_new
 test eax,eax
 jnz .failure
 lea rdi,[rsp+128]
 lea rsi,[rsp+96]
 lea rdx,[rsp]
 call nebo_udp_socket_bind
 test eax,eax
 jnz .failure
 cmp qword [rsp+128+NEBO_SOCKET_PORT],0
 je .failure_socket
 lea rdi,[rsp+128]
 call nebo_socket_close
 test eax,eax
 jnz .failure
 jmp .success
.failure_socket:
 lea rdi,[rsp+128]
 call nebo_socket_close
 jmp .failure
.http_tls:
 lea rdi,[rsp]
 lea rsi,[http_response]
 mov edx,http_response_len
 mov ecx,8
 mov r8d,4
 call nebo_http_parse_response
 test eax,eax
 jnz .failure
 mov rdi,rsp
 call nebo_http_response_status
 test eax,eax
 jnz .failure
 cmp rdx,204
 jne .failure
 lea rdi,[rsp+64]
 lea rsi,[local_name]
 mov edx,9
 lea rcx,[trust_key]
 mov r8d,4
 call nebo_tls_config_with_trust_store
 test eax,eax
 jnz .failure
 jmp .success
.crypto:
 mov byte [rsp],r13b
 lea rdi,[rsp]
 mov esi,1
 lea rdx,[rsp+64]
 call nebo_sha256_hash
 test eax,eax
 jnz .failure
 mov rax,[rsp+64]
 test rax,rax
 jz .failure
.success:
 mov eax,r13d
 jmp .return
.failure:
 lea eax,[r12+70]
.return:
 add rsp,1024
 pop r13
 pop r12
 pop rbx
 ret
