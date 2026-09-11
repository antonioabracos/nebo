%ifndef NEBO_SOCKET_INC
%define NEBO_SOCKET_INC 1
%include "runtime/network/address.inc"
%define NEBO_SOCKET_FD 0
%define NEBO_SOCKET_STATE 8
%define NEBO_SOCKET_CAPABILITY 16
%define NEBO_SOCKET_BYTES_READ 24
%define NEBO_SOCKET_BYTES_WRITTEN 32
%define NEBO_SOCKET_FAMILY 40
%define NEBO_SOCKET_PORT 48
%define NEBO_SOCKET_FLAGS 56
%define NEBO_SOCKET_FLAG_LISTENER 1
%define NEBO_SOCKET_FLAG_STREAM 2
%define NEBO_SOCKET_FLAG_DATAGRAM 4
%ifndef NEBO_SOCKET_IMPLEMENTATION
 extern nebo_network_capability_init
 extern nebo_tcp_listener_bind
 extern nebo_tcp_listener_accept
 extern nebo_tcp_stream_connect
 extern nebo_tcp_stream_read
 extern nebo_tcp_stream_write
 extern nebo_tcp_stream_write_all
 extern nebo_tcp_stream_shutdown
 extern nebo_socket_close
 extern nebo_udp_socket_bind
 extern nebo_udp_socket_send_to
 extern nebo_udp_socket_receive_from
 extern nebo_udp_socket_receive_from_address
%endif
%endif
