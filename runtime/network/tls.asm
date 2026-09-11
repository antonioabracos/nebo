; Pinned local authenticated transport profile for the G012 TLS layering gate.
; It performs an on-stream HMAC-SHA256 identity proof. It is intentionally not
; advertised as general Internet PKI or a TLS 1.3 implementation.
bits 64
default rel
%define NEBO_TLS_IMPLEMENTATION 1
%include "runtime/network/tls.inc"

section .text
global nebo_tls_config_with_trust_store
global nebo_tls_stream_connect

; rdi=config, rsi=canonical server name, rdx=name len, rcx=trust key, r8=key len.
nebo_tls_config_with_trust_store:
 test rdi,rdi
 jz .config_invalid
 test rsi,rsi
 jz .config_invalid
 test rdx,rdx
 jz .config_invalid
 cmp rdx,253
 ja .config_limit
 test rcx,rcx
 jz .config_invalid
 test r8,r8
 jz .config_invalid
 cmp r8,64
 ja .config_limit
 mov rax,NEBO_TLS_CONFIG_MAGIC_VALUE
 mov [rdi+NEBO_TLS_CONFIG_MAGIC],rax
 mov [rdi+NEBO_TLS_CONFIG_SERVER_NAME],rsi
 mov [rdi+NEBO_TLS_CONFIG_SERVER_NAME_LENGTH],rdx
 mov [rdi+NEBO_TLS_CONFIG_TRUST_KEY],rcx
 mov [rdi+NEBO_TLS_CONFIG_TRUST_KEY_LENGTH],r8
 mov qword [rdi+NEBO_TLS_CONFIG_PROFILE],NEBO_TLS_PROFILE_PINNED_HMAC_SHA256_LOCAL_V1
 xor eax,eax
 ret
.config_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.config_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=TlsStream out, rsi=connected TcpStream, rdx=server name, rcx=name len,
; r8=TlsConfig. Reads and verifies the peer's 32-byte identity proof.
nebo_tls_stream_connect:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov rbx,r8
 test r12,r12
 jz .connect_invalid
 test r13,r13
 jz .connect_invalid
 test r14,r14
 jz .connect_invalid
 test r15,r15
 jz .connect_invalid
 cmp qword [r13+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .connect_closed
 test rbx,rbx
 jz .connect_invalid
 mov rax,NEBO_TLS_CONFIG_MAGIC_VALUE
 cmp [rbx+NEBO_TLS_CONFIG_MAGIC],rax
 jne .connect_denied
 cmp r15,[rbx+NEBO_TLS_CONFIG_SERVER_NAME_LENGTH]
 jne .connect_denied
 mov r8,[rbx+NEBO_TLS_CONFIG_SERVER_NAME]
 xor ecx,ecx
.name_compare:
 cmp rcx,r15
 jae .name_ok
 mov al,[r14+rcx]
 cmp al,[r8+rcx]
 jne .connect_denied
 inc rcx
 jmp .name_compare
.name_ok:
 sub rsp,64
 mov rdi,[rbx+NEBO_TLS_CONFIG_TRUST_KEY]
 mov rsi,[rbx+NEBO_TLS_CONFIG_TRUST_KEY_LENGTH]
 mov rdx,r14
 mov rcx,r15
 lea r8,[rsp+32]
 call nebo_hmac_sha256
 test eax,eax
 jnz .stack_return
 xor r15d,r15d
.proof_read:
 cmp r15,32
 jae .proof_compare
 mov rdi,r13
 lea rsi,[rsp+r15]
 mov edx,32
 sub rdx,r15
 call nebo_tcp_stream_read
 test eax,eax
 jnz .stack_return
 test rdx,rdx
 jz .connect_protocol_stack
 add r15,rdx
 jmp .proof_read
.proof_compare:
 xor ecx,ecx
 xor edx,edx
.proof_byte:
 mov al,[rsp+rcx]
 xor al,[rsp+32+rcx]
 or dl,al
 inc rcx
 cmp rcx,32
 jb .proof_byte
 test dl,dl
 jnz .connect_denied_stack
 mov [r12+NEBO_TLS_STREAM_SOCKET],r13
 mov qword [r12+NEBO_TLS_STREAM_STATE],NEBO_RESOURCE_STATE_OPEN
 mov qword [r12+NEBO_TLS_STREAM_PROFILE],NEBO_TLS_PROFILE_PINNED_HMAC_SHA256_LOCAL_V1
 mov [r12+NEBO_TLS_STREAM_SERVER_NAME],r14
 xor eax,eax
 jmp .stack_return
.connect_denied_stack:
 mov eax,NEBO_SYSTEM_ERROR_CRYPTO
 jmp .stack_return
.connect_protocol_stack:
 mov eax,NEBO_SYSTEM_ERROR_PROTOCOL
.stack_return:
 mov r15d,eax
 xor eax,eax
 mov ecx,8
 mov rdi,rsp
 rep stosq
 mfence
 add rsp,64
 mov eax,r15d
 jmp .connect_return
.connect_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .connect_return
.connect_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 jmp .connect_return
.connect_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
.connect_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
