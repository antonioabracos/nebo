bits 64
default rel
%include "runtime/network/socket.inc"
section .rodata
tcp_payload db 'tcp-loop'
udp_payload db 'udp-loop'
external_ip db 8,8,8,8
section .bss
cap resb NEBO_NETWORK_CAPABILITY_SIZE
ip resb NEBO_IP_ADDRESS_SIZE
tcp_addr resb NEBO_SOCKET_ADDRESS_SIZE
udp_addr resb NEBO_SOCKET_ADDRESS_SIZE
listener resb NEBO_TCP_LISTENER_SIZE
client resb NEBO_TCP_STREAM_SIZE
server resb NEBO_TCP_STREAM_SIZE
udp_server resb NEBO_UDP_SOCKET_SIZE
udp_client resb NEBO_UDP_SOCKET_SIZE
udp_sender resb NEBO_SOCKET_ADDRESS_SIZE
buffer resb 32
section .text
global _start
_start:
 lea rdi,[cap]
 mov esi,NEBO_NETWORK_CAP_ALL
 mov edx,8
 mov ecx,4096
 mov r8d,1000000000
 call nebo_network_capability_init
 test eax,eax
 jnz .fail1
 mov qword [ip+NEBO_IP_FAMILY],NEBO_IP_FAMILY_V4
 mov dword [ip+NEBO_IP_BYTES],0x0100007f
 lea rdi,[tcp_addr]
 lea rsi,[ip]
 ; Port zero asks the kernel for an ephemeral loopback port, avoiding flaky
 ; collisions with unrelated local processes.
 xor edx,edx
 call nebo_socket_address_new
 test eax,eax
 jnz .fail2
 lea rdi,[listener]
 lea rsi,[tcp_addr]
 lea rdx,[cap]
 mov ecx,4
 call nebo_tcp_listener_bind
 test eax,eax
 jnz .fail3
 mov rax,[listener+NEBO_SOCKET_PORT]
 test rax,rax
 jz .fail3
 mov [tcp_addr+NEBO_SOCKET_ADDRESS_PORT],rax
 lea rdi,[client]
 lea rsi,[tcp_addr]
 lea rdx,[cap]
 call nebo_tcp_stream_connect
 test eax,eax
 jnz .fail4
 lea rdi,[server]
 lea rsi,[listener]
 call nebo_tcp_listener_accept
 test eax,eax
 jnz .fail5
 cmp qword [cap+NEBO_NETWORK_CAPABILITY_GENERATION],3
 jne .fail6
 lea rdi,[client]
 lea rsi,[tcp_payload]
 mov edx,8
 call nebo_tcp_stream_write_all
 test eax,eax
 jnz .fail7
 cmp rdx,8
 jne .fail8
 lea rdi,[server]
 lea rsi,[buffer]
 mov edx,8
 call nebo_tcp_stream_read
 test eax,eax
 jnz .fail9
 cmp rdx,8
 jne .fail10
 mov rax,[buffer]
 cmp rax,[tcp_payload]
 jne .fail11
 lea rdi,[client]
 call nebo_tcp_stream_shutdown
 test eax,eax
 jnz .fail12
 lea rdi,[client]
 lea rsi,[tcp_payload]
 mov edx,1
 call nebo_tcp_stream_write
 cmp eax,NEBO_SYSTEM_ERROR_CLOSED
 jne .fail13
 lea rdi,[client]
 call nebo_socket_close
 test eax,eax
 jnz .fail14
 lea rdi,[server]
 call nebo_socket_close
 test eax,eax
 jnz .fail15
 lea rdi,[listener]
 call nebo_socket_close
 test eax,eax
 jnz .fail16
 lea rdi,[udp_addr]
 lea rsi,[ip]
 xor edx,edx
 call nebo_socket_address_new
 test eax,eax
 jnz .fail17
 lea rdi,[udp_server]
 lea rsi,[udp_addr]
 lea rdx,[cap]
 call nebo_udp_socket_bind
 test eax,eax
 jnz .fail18
 mov rax,[udp_server+NEBO_SOCKET_PORT]
 test rax,rax
 jz .fail18
 mov [udp_addr+NEBO_SOCKET_ADDRESS_PORT],rax
 ; client UDP socket binds a distinct loopback port.
 lea rdi,[tcp_addr]
 lea rsi,[ip]
 xor edx,edx
 call nebo_socket_address_new
 lea rdi,[udp_client]
 lea rsi,[tcp_addr]
 lea rdx,[cap]
 call nebo_udp_socket_bind
 test eax,eax
 jnz .fail19
 lea rdi,[udp_client]
 lea rsi,[udp_payload]
 mov edx,8
 lea rcx,[udp_addr]
 call nebo_udp_socket_send_to
 test eax,eax
 jnz .fail20
 cmp rdx,8
 jne .fail21
 lea rdi,[udp_server]
 lea rsi,[buffer]
 mov edx,16
 lea rcx,[udp_sender]
 call nebo_udp_socket_receive_from_address
 test eax,eax
 jnz .fail22
 cmp rdx,8
 jne .fail23
 mov rax,[buffer]
 cmp rax,[udp_payload]
 jne .fail24
 mov rax,[udp_sender+NEBO_SOCKET_ADDRESS_PORT]
 cmp rax,[udp_client+NEBO_SOCKET_PORT]
 jne .fail30
 lea rdi,[udp_client]
 call nebo_socket_close
 test eax,eax
 jnz .fail25
 lea rdi,[udp_server]
 call nebo_socket_close
 test eax,eax
 jnz .fail26
 cmp qword [cap+NEBO_NETWORK_CAPABILITY_GENERATION],0
 jne .fail27
 ; external IPv4 is rejected before socket/connect.
 mov dword [ip+NEBO_IP_BYTES],0x08080808
 lea rdi,[tcp_addr]
 lea rsi,[ip]
 mov edx,443
 call nebo_socket_address_new
 lea rdi,[client]
 lea rsi,[tcp_addr]
 lea rdx,[cap]
 call nebo_tcp_stream_connect
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail28
 mov qword [cap+NEBO_NETWORK_CAPABILITY_MAGIC],0
 lea rdi,[listener]
 lea rsi,[udp_addr]
 lea rdx,[cap]
 mov ecx,1
 call nebo_tcp_listener_bind
 cmp eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 jne .fail29
 xor edi,edi
 jmp .exit
%assign i 1
%rep 30
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
