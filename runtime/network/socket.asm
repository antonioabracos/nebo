bits 64
default rel
%define NEBO_SOCKET_IMPLEMENTATION 1
%include "runtime/network/socket.inc"
%define SYS_READ 0
%define socket_SYS_WRITE 1
%define EINTR 4
%define EACCES 13
%define EADDRINUSE 98
%define ECONNREFUSED 111
%define SOCK_CLOEXEC 0x80000
%define MSG_NOSIGNAL 0x4000
%define SHUT_RDWR 2

section .text
global nebo_network_capability_init
global nebo_tcp_listener_bind
global nebo_tcp_listener_accept
global nebo_tcp_stream_connect
global nebo_tcp_stream_read
global nebo_tcp_stream_write
global nebo_tcp_stream_shutdown
global nebo_socket_close
global nebo_udp_socket_bind
global nebo_udp_socket_send_to
global nebo_udp_socket_receive_from

; rdi=capability, rsi=permissions, rdx=max connections, rcx=max bytes,
; r8=max deadline ns. Loopback set is intrinsic.
nebo_network_capability_init:
 test rdi,rdi
 jz .cap_denied
 test rsi,~NEBO_NETWORK_CAP_ALL
 jnz .cap_denied
 test rsi,rsi
 jz .cap_denied
 test rdx,rdx
 jz .cap_limit
 cmp rdx,NEBO_NETWORK_MAX_CONNECTIONS
 ja .cap_limit
 test rcx,rcx
 jz .cap_limit
 cmp rcx,NEBO_NETWORK_MAX_IO_BYTES
 ja .cap_limit
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_NETWORK
 mov [rdi+NEBO_NETWORK_CAPABILITY_MAGIC],rax
 mov qword [rdi+NEBO_NETWORK_CAPABILITY_ADDRESS_SET],NEBO_NETWORK_LOOPBACK_ONLY
 mov qword [rdi+NEBO_NETWORK_CAPABILITY_ADDRESS_COUNT],1
 mov [rdi+NEBO_NETWORK_CAPABILITY_PERMISSIONS],rsi
 mov [rdi+NEBO_NETWORK_CAPABILITY_MAX_CONNECTIONS],rdx
 mov [rdi+NEBO_NETWORK_CAPABILITY_MAX_BYTES],rcx
 mov [rdi+NEBO_NETWORK_CAPABILITY_MAX_DEADLINE_NS],r8
 mov qword [rdi+NEBO_NETWORK_CAPABILITY_GENERATION],0
 xor eax,eax
 ret
.cap_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.cap_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=listener out, rsi=SocketAddress, rdx=capability, rcx=backlog.
nebo_tcp_listener_bind:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 test r12,r12
 jz .listener_invalid
 test rbx,rbx
 jz .listener_invalid
 cmp rbx,32
 ja .listener_limit
 mov rdi,r14
 mov esi,NEBO_NETWORK_CAP_BIND | NEBO_NETWORK_CAP_LISTEN
 call network_validate
 test eax,eax
 jnz .listener_return
 mov rdi,r13
 call loopback_address_validate
 test eax,eax
 jnz .listener_return
 mov rdi,r14
 call socket_reserve
 test eax,eax
 jnz .listener_return
 mov eax,NEBO_LINUX_X86_64_SYS_SOCKET
 mov edi,NEBO_NETWORK_AF_INET
 mov esi,NEBO_NETWORK_SOCK_STREAM | SOCK_CLOEXEC
 xor edx,edx
 syscall
 cmp rax,-4095
 jae .listener_socket_error
 mov r8,rax
 sub rsp,16
 mov rdi,rsp
 mov rsi,r13
 call make_sockaddr4
 mov eax,NEBO_LINUX_X86_64_SYS_BIND
 mov rdi,r8
 mov rsi,rsp
 mov edx,16
 syscall
 add rsp,16
 cmp rax,-4095
 jae .listener_fd_error
 mov eax,NEBO_LINUX_X86_64_SYS_LISTEN
 mov rdi,r8
 mov rsi,rbx
 syscall
 cmp rax,-4095
 jae .listener_fd_error
 mov rdi,r12
 mov rsi,r8
 mov rdx,r14
 mov rcx,r13
 mov r8d,NEBO_SOCKET_FLAG_LISTENER
 call socket_publish
 xor eax,eax
 jmp .listener_return
.listener_fd_error:
 push rax
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r8
 syscall
 pop rdi
 call network_map_errno
 mov rdi,r14
 call socket_unreserve
 jmp .listener_return
.listener_socket_error:
 mov rdi,rax
 call network_map_errno
 mov rdi,r14
 call socket_unreserve
 jmp .listener_return
.listener_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .listener_return
.listener_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
.listener_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=stream out, rsi=listener.
nebo_tcp_listener_accept:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 test r12,r12
 jz .accept_invalid
 test rbx,rbx
 jz .accept_invalid
 cmp qword [rbx+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .accept_closed
 test qword [rbx+NEBO_SOCKET_FLAGS],NEBO_SOCKET_FLAG_LISTENER
 jz .accept_invalid
 mov rdi,[rbx+NEBO_SOCKET_CAPABILITY]
 mov esi,NEBO_NETWORK_CAP_LISTEN
 call network_validate
 test eax,eax
 jnz .accept_return
 mov rdi,[rbx+NEBO_SOCKET_CAPABILITY]
 call socket_reserve
 test eax,eax
 jnz .accept_return
.accept_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_ACCEPT4
 mov rdi,[rbx+NEBO_SOCKET_FD]
 xor esi,esi
 xor edx,edx
 mov r10d,SOCK_CLOEXEC
 syscall
 cmp rax,-EINTR
 je .accept_retry
 cmp rax,-4095
 jae .accept_error
 mov rsi,rax
 mov rdi,r12
 mov rdx,[rbx+NEBO_SOCKET_CAPABILITY]
 mov rcx,rbx
 mov r8d,NEBO_SOCKET_FLAG_STREAM
 call socket_publish
 xor eax,eax
 jmp .accept_return
.accept_error:
 mov rdi,rax
 call network_map_errno
 mov rdi,[rbx+NEBO_SOCKET_CAPABILITY]
 call socket_unreserve
 jmp .accept_return
.accept_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .accept_return
.accept_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
.accept_return:
 pop r12
 pop rbx
 ret

; rdi=stream out, rsi=SocketAddress, rdx=capability.
nebo_tcp_stream_connect:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .connect_invalid
 mov rdi,rbx
 mov esi,NEBO_NETWORK_CAP_CONNECT
 call network_validate
 test eax,eax
 jnz .connect_return
 mov rdi,r13
 call loopback_address_validate
 test eax,eax
 jnz .connect_return
 mov rdi,rbx
 call socket_reserve
 test eax,eax
 jnz .connect_return
 mov eax,NEBO_LINUX_X86_64_SYS_SOCKET
 mov edi,NEBO_NETWORK_AF_INET
 mov esi,NEBO_NETWORK_SOCK_STREAM | SOCK_CLOEXEC
 xor edx,edx
 syscall
 cmp rax,-4095
 jae .connect_socket_error
 mov r8,rax
 sub rsp,16
 mov rdi,rsp
 mov rsi,r13
 call make_sockaddr4
.connect_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_CONNECT
 mov rdi,r8
 mov rsi,rsp
 mov edx,16
 syscall
 cmp rax,-EINTR
 je .connect_retry
 add rsp,16
 cmp rax,-4095
 jae .connect_fd_error
 mov rdi,r12
 mov rsi,r8
 mov rdx,rbx
 mov rcx,r13
 mov r8d,NEBO_SOCKET_FLAG_STREAM
 call socket_publish
 xor eax,eax
 jmp .connect_return
.connect_fd_error:
 push rax
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r8
 syscall
 pop rdi
 call network_map_errno
 mov rdi,rbx
 call socket_unreserve
 jmp .connect_return
.connect_socket_error:
 mov rdi,rax
 call network_map_errno
 mov rdi,rbx
 call socket_unreserve
 jmp .connect_return
.connect_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.connect_return:
 pop r13
 pop r12
 pop rbx
 ret

nebo_tcp_stream_read:
 mov r8,SYS_READ
 xor r9d,r9d
 jmp stream_io

nebo_tcp_stream_write:
 mov r8,socket_SYS_WRITE
 mov r9d,1
 jmp stream_io

nebo_tcp_stream_shutdown:
 test rdi,rdi
 jz .shutdown_invalid
 cmp qword [rdi+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .shutdown_closed
 mov r8,rdi
 mov eax,NEBO_LINUX_X86_64_SYS_SHUTDOWN
 mov rdi,[r8+NEBO_SOCKET_FD]
 mov esi,SHUT_RDWR
 syscall
 cmp rax,-4095
 jae .shutdown_error
 mov qword [r8+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_HALF_CLOSED
 xor eax,eax
 ret
.shutdown_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.shutdown_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 ret
.shutdown_error:
 mov eax,NEBO_SYSTEM_ERROR_IO
 ret

; rdi=UdpSocket out, rsi=SocketAddress, rdx=capability.
nebo_udp_socket_bind:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .udp_bind_invalid
 mov rdi,rbx
 mov esi,NEBO_NETWORK_CAP_BIND | NEBO_NETWORK_CAP_DATAGRAM
 call network_validate
 test eax,eax
 jnz .udp_bind_return
 mov rdi,r13
 call loopback_address_validate
 test eax,eax
 jnz .udp_bind_return
 mov rdi,rbx
 call socket_reserve
 test eax,eax
 jnz .udp_bind_return
 mov eax,NEBO_LINUX_X86_64_SYS_SOCKET
 mov edi,NEBO_NETWORK_AF_INET
 mov esi,NEBO_NETWORK_SOCK_DGRAM | SOCK_CLOEXEC
 xor edx,edx
 syscall
 cmp rax,-4095
 jae .udp_bind_socket_error
 mov r8,rax
 sub rsp,16
 mov rdi,rsp
 mov rsi,r13
 call make_sockaddr4
 mov eax,NEBO_LINUX_X86_64_SYS_BIND
 mov rdi,r8
 mov rsi,rsp
 mov edx,16
 syscall
 add rsp,16
 cmp rax,-4095
 jae .udp_bind_fd_error
 mov rdi,r12
 mov rsi,r8
 mov rdx,rbx
 mov rcx,r13
 mov r8d,NEBO_SOCKET_FLAG_DATAGRAM
 call socket_publish
 xor eax,eax
 jmp .udp_bind_return
.udp_bind_fd_error:
 push rax
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,r8
 syscall
 pop rdi
 call network_map_errno
 mov rdi,rbx
 call socket_unreserve
 jmp .udp_bind_return
.udp_bind_socket_error:
 mov rdi,rax
 call network_map_errno
 mov rdi,rbx
 call socket_unreserve
 jmp .udp_bind_return
.udp_bind_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.udp_bind_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=UdpSocket, rsi=buffer, rdx=bytes, rcx=SocketAddress.
nebo_udp_socket_send_to:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 mov rdi,r12
 mov rsi,r14
 mov edx,1
 call socket_io_validate
 test eax,eax
 jnz .send_return
 mov rdi,rbx
 call loopback_address_validate
 test eax,eax
 jnz .send_return
 sub rsp,16
 mov rdi,rsp
 mov rsi,rbx
 call make_sockaddr4
.send_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_SENDTO
 mov rdi,[r12+NEBO_SOCKET_FD]
 mov rsi,r13
 mov rdx,r14
 mov r10d,MSG_NOSIGNAL
 mov r8,rsp
 mov r9d,16
 syscall
 cmp rax,-EINTR
 je .send_retry
 add rsp,16
 cmp rax,-4095
 jae .send_error
 add [r12+NEBO_SOCKET_BYTES_WRITTEN],rax
 mov rdx,rax
 xor eax,eax
 jmp .send_return
.send_error:
 mov eax,NEBO_SYSTEM_ERROR_IO
 xor edx,edx
.send_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=UdpSocket, rsi=buffer, rdx=capacity. Sender address is not published.
nebo_udp_socket_receive_from:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 mov rdi,r12
 mov rsi,rbx
 xor edx,edx
 call socket_io_validate
 test eax,eax
 jnz .recv_return
.recv_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_RECVFROM
 mov rdi,[r12+NEBO_SOCKET_FD]
 mov rsi,r13
 mov rdx,rbx
 xor r10d,r10d
 xor r8d,r8d
 xor r9d,r9d
 syscall
 cmp rax,-EINTR
 je .recv_retry
 cmp rax,-4095
 jae .recv_error
 add [r12+NEBO_SOCKET_BYTES_READ],rax
 mov rdx,rax
 xor eax,eax
 jmp .recv_return
.recv_error:
 mov eax,NEBO_SYSTEM_ERROR_IO
 xor edx,edx
.recv_return:
 pop r13
 pop r12
 pop rbx
 ret

nebo_socket_close:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .close_invalid
 mov rax,[rbx+NEBO_SOCKET_STATE]
 cmp rax,NEBO_RESOURCE_STATE_OPEN
 je .close_do
 cmp rax,NEBO_RESOURCE_STATE_HALF_CLOSED
 jne .close_closed
.close_do:
.close_retry:
 mov eax,NEBO_LINUX_X86_64_SYS_CLOSE
 mov rdi,[rbx+NEBO_SOCKET_FD]
 syscall
 cmp rax,-EINTR
 je .close_retry
 mov qword [rbx+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_CLOSED
 mov rdi,[rbx+NEBO_SOCKET_CAPABILITY]
 call socket_unreserve
 cmp rax,-4095
 jae .close_error
 xor eax,eax
 jmp .close_return
.close_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .close_return
.close_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 jmp .close_return
.close_error:
 mov eax,NEBO_SYSTEM_ERROR_IO
.close_return:
 pop rbx
 ret

; Helpers.
network_validate:
 test rdi,rdi
 jz .network_denied
 mov rax,NEBO_SYSTEM_CAPABILITY_MAGIC_NETWORK
 cmp [rdi+NEBO_NETWORK_CAPABILITY_MAGIC],rax
 jne .network_denied
 mov rax,[rdi+NEBO_NETWORK_CAPABILITY_PERMISSIONS]
 mov rcx,rax
 and rcx,rsi
 cmp rcx,rsi
 jne .network_denied
 xor eax,eax
 ret
.network_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret

loopback_address_validate:
 test rdi,rdi
 jz .address_denied
 cmp qword [rdi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_FAMILY],NEBO_IP_FAMILY_V4
 jne .address_denied
 cmp byte [rdi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES],127
 jne .address_denied
 cmp byte [rdi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES+1],0
 jne .address_denied
 cmp byte [rdi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES+2],0
 jne .address_denied
 cmp byte [rdi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES+3],1
 jne .address_denied
 cmp qword [rdi+NEBO_SOCKET_ADDRESS_PORT],0
 je .address_denied
 cmp qword [rdi+NEBO_SOCKET_ADDRESS_PORT],65535
 ja .address_denied
 xor eax,eax
 ret
.address_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret

socket_reserve:
 test rdi,rdi
 jz .reserve_limit
 mov rax,[rdi+NEBO_NETWORK_CAPABILITY_GENERATION]
 cmp rax,[rdi+NEBO_NETWORK_CAPABILITY_MAX_CONNECTIONS]
 jae .reserve_limit
 inc qword [rdi+NEBO_NETWORK_CAPABILITY_GENERATION]
 xor eax,eax
 ret
.reserve_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

socket_unreserve:
 test rdi,rdi
 jz .unreserve_done
 cmp qword [rdi+NEBO_NETWORK_CAPABILITY_GENERATION],0
 je .unreserve_done
 dec qword [rdi+NEBO_NETWORK_CAPABILITY_GENERATION]
.unreserve_done:
 ret

; rdi=resource, rsi=fd, rdx=cap, rcx=SocketAddress/resource, r8=flags.
socket_publish:
 mov [rdi+NEBO_SOCKET_FD],rsi
 mov qword [rdi+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 mov [rdi+NEBO_SOCKET_CAPABILITY],rdx
 mov qword [rdi+NEBO_SOCKET_BYTES_READ],0
 mov qword [rdi+NEBO_SOCKET_BYTES_WRITTEN],0
 mov qword [rdi+NEBO_SOCKET_FAMILY],NEBO_IP_FAMILY_V4
 mov rax,[rcx+NEBO_SOCKET_PORT]
 mov [rdi+NEBO_SOCKET_PORT],rax
 mov [rdi+NEBO_SOCKET_FLAGS],r8
 ret

; rdi=16-byte sockaddr, rsi=SocketAddress.
make_sockaddr4:
 mov word [rdi],NEBO_NETWORK_AF_INET
 mov ax,[rsi+NEBO_SOCKET_ADDRESS_PORT]
 xchg al,ah
 mov [rdi+2],ax
 mov eax,[rsi+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES]
 mov [rdi+4],eax
 mov qword [rdi+8],0
 ret

; rdi=stream, rsi=bytes, edx direction. eax=status.
socket_io_validate:
 test rdi,rdi
 jz .io_invalid
 cmp qword [rdi+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .io_closed
 test rsi,rsi
 jz .io_invalid
 mov rcx,[rdi+NEBO_SOCKET_BYTES_READ]
 add rcx,[rdi+NEBO_SOCKET_BYTES_WRITTEN]
 jc .io_limit
 add rcx,rsi
 jc .io_limit
 mov rax,[rdi+NEBO_SOCKET_CAPABILITY]
 cmp rcx,[rax+NEBO_NETWORK_CAPABILITY_MAX_BYTES]
 ja .io_limit
 xor eax,eax
 ret
.io_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret
.io_closed:
 mov eax,NEBO_SYSTEM_ERROR_CLOSED
 ret
.io_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 ret

; rdi=stream rsi=buffer rdx=bytes r8=syscall r9=direction.
stream_io:
 push rbx
 push r12
 push r13
 mov rbx,rdi
 mov r12,rsi
 mov r13,rdx
 mov rsi,rdx
 mov edx,r9d
 call socket_io_validate
 test eax,eax
 jnz .stream_return_zero
.stream_retry:
 mov rax,r8
 mov rdi,[rbx+NEBO_SOCKET_FD]
 mov rsi,r12
 mov rdx,r13
 syscall
 cmp rax,-EINTR
 je .stream_retry
 cmp rax,-4095
 jae .stream_error
 test r9d,r9d
 jz .stream_read_count
 add [rbx+NEBO_SOCKET_BYTES_WRITTEN],rax
 jmp .stream_success
.stream_read_count:
 add [rbx+NEBO_SOCKET_BYTES_READ],rax
.stream_success:
 mov rdx,rax
 xor eax,eax
 jmp .stream_return
.stream_error:
 mov eax,NEBO_SYSTEM_ERROR_IO
.stream_return_zero:
 xor edx,edx
.stream_return:
 pop r13
 pop r12
 pop rbx
 ret

network_map_errno:
 cmp rdi,-EACCES
 je .map_denied
 cmp rdi,-EADDRINUSE
 je .map_address
 cmp rdi,-ECONNREFUSED
 je .map_refused
 mov eax,NEBO_SYSTEM_ERROR_IO
 ret
.map_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
 ret
.map_address:
 mov eax,NEBO_SYSTEM_ERROR_ADDRESS_IN_USE
 ret
.map_refused:
 mov eax,NEBO_SYSTEM_ERROR_CONNECTION_REFUSED
 ret
