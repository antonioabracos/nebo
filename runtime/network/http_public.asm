; Structured HTTP/1.1 over the canonical loopback transport. An explicit Host
; header selects only 127.0.0.1:port. No DNS, redirects or external endpoint.
bits 64
default rel
%include "runtime/network/http.inc"
extern nebo_network_public_allocate
extern nebo_network_public_configure
extern nebo_network_public_capability
extern nebo_network_public_closed
extern nebo_runtime_trap_arithmetic_domain
global nebo_http_public
section .rodata
http_public_host: db '127.0.0.1:'
section .text
nebo_http_public:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 mov ebx,edi
 mov r12,rsi
 mov r13,rdx
 mov r14,rcx
 mov r15,r8
 cmp ebx,240
 je .new
 cmp ebx,241
 je .header
 cmp ebx,242
 je .send
 mov rdi,r12
 cmp ebx,243
 je .status
 cmp ebx,244
 jne .trap
 mov rsi,r13
 cmp rsi,4096
 ja .trap
 call nebo_http_response_body
 test eax,eax
 jnz .trap
 lea rdi,[r15+32]
 mov [r15],rdi
 mov [r15+8],r8
 mov qword [r15+16],0
 mov rsi,rdx
 mov rcx,r8
 rep movsb
 mov rax,r15
 jmp .done
.status:
 call nebo_http_response_status
 test eax,eax
 jnz .trap
 mov rax,rdx
 jmp .done
.new:
 cmp qword [r13+8],16
 ja .trap
 cmp qword [r14+8],2048
 ja .trap
 mov rdi,r15
 xor eax,eax
 mov ecx,4416/8
 rep stosq
 lea rdi,[r15+128]
 mov rsi,[r13]
 mov rcx,[r13+8]
 rep movsb
 lea rdi,[r15+256]
 mov rsi,[r14]
 mov rcx,[r14+8]
 rep movsb
 mov rdi,r15
 lea rsi,[r15+128]
 mov rdx,[r13+8]
 lea rcx,[r15+256]
 mov r8,[r14+8]
 lea r9,[r15+2304]
 mov qword [rsp],2048
 call nebo_http_request_init
 test eax,eax
 jnz .trap
 mov rax,r15
 jmp .done
.header:
 mov qword [rsp],0
 cmp qword [r13+8],4
 jne .append_header
 mov rax,[r13]
 mov eax,[rax]
 or eax,0x20202020
 cmp eax,0x74736f68
 jne .append_header
 cmp qword [r12+96],0
 jne .trap
 cmp qword [r14+8],10
 jbe .trap
 mov rdi,[r14]
 lea rsi,[rel http_public_host]
 mov ecx,10
 repe cmpsb
 jne .trap
 mov rdi,[r14]
 add rdi,10
 mov rsi,[r14+8]
 sub rsi,10
 call nebo_parse_port
 test eax,eax
 jnz .trap
 mov [rsp+8],rdx
 mov qword [rsp],1
.append_header:
 mov rdi,r12
 mov rsi,[r13]
 mov rdx,[r13+8]
 mov rcx,[r14]
 mov r8,[r14+8]
 call nebo_http_request_header
 test eax,eax
 jnz .trap
 cmp qword [rsp],0
 je .header_done
 mov qword [r12+64],4
 mov qword [r12+72],0x0100007f
 mov qword [r12+80],0
 mov rax,[rsp+8]
 mov [r12+88],rax
 mov qword [r12+96],1
.header_done:
 xor eax,eax
 jmp .done
.send:
 cmp qword [r13+96],1
 jne .trap
 call nebo_network_public_allocate
 test rax,rax
 jz .trap
 mov r12,rax
 mov rdi,rax
 lea rsi,[r13+64]
 lea rdx,[rel nebo_network_public_capability]
 call nebo_tcp_stream_connect
 test eax,eax
 jnz .trap
 mov rdi,r12
 call nebo_network_public_configure
 test eax,eax
 jnz .trap
 mov [r15+64+NEBO_HTTP_TRANSACTION_RESPONSE],r15
 mov [r15+64+NEBO_HTTP_TRANSACTION_STREAM],r12
 mov [r15+64+NEBO_HTTP_TRANSACTION_REQUEST],r13
 lea rax,[r15+512]
 mov [r15+64+NEBO_HTTP_TRANSACTION_WIRE],rax
 mov qword [r15+64+NEBO_HTTP_TRANSACTION_WIRE_CAPACITY],4096
 lea rax,[r15+4608]
 mov [r15+64+NEBO_HTTP_TRANSACTION_RESPONSE_BYTES],rax
 mov qword [r15+64+NEBO_HTTP_TRANSACTION_RESPONSE_CAPACITY],8192
 mov qword [r15+64+NEBO_HTTP_TRANSACTION_MAX_BODY],4096
 mov qword [r15+64+NEBO_HTTP_TRANSACTION_MAX_HEADERS],64
 lea rdi,[r15+64]
 call nebo_http_client_send
 mov [rsp],rax
 mov rdi,r12
 call nebo_socket_close
 test eax,eax
 jnz .trap
 call nebo_network_public_closed
 cmp qword [rsp],0
 jne .trap
 mov rax,r15
 jmp .done
.trap:
 jmp nebo_runtime_trap_arithmetic_domain
.done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
