%ifndef NEBO_ADDRESS_INC
%define NEBO_ADDRESS_INC 1
%include "compiler/semantic/system/system_contract.inc"
%define NEBO_IP_FAMILY 0
%define NEBO_IP_BYTES 8
%define NEBO_IP_FAMILY_V4 4
%define NEBO_IP_FAMILY_V6 6
%define NEBO_SOCKET_ADDRESS_IP 0
%define NEBO_SOCKET_ADDRESS_PORT 24
%define NEBO_HOSTNAME_TEXT 0
%define NEBO_HOSTNAME_LENGTH 8
%define NEBO_HOSTNAME_LABELS 16
%define NEBO_HOSTNAME_FLAGS 24
%define NEBO_HOSTNAME_FLAG_CANONICAL 1
%ifndef NEBO_ADDRESS_IMPLEMENTATION
 extern nebo_ip_parse
 extern nebo_ip_format
 extern nebo_socket_address_new
 extern nebo_hostname_parse
 extern nebo_hostname_format
 extern nebo_parse_port
 extern nebo_dns_resolve_local
 extern nebo_socket_address_format
%endif
%endif
