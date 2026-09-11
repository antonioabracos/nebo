bits 64
default rel
%define NEBO_ADDRESS_IMPLEMENTATION 1
%include "runtime/network/address.inc"

section .text
global nebo_ip_parse
global nebo_ip_format
global nebo_socket_address_new
global nebo_hostname_parse
global nebo_hostname_format
global nebo_parse_port
global nebo_dns_resolve_local
global nebo_socket_address_format

section .rodata
local_host: db 'localhost'
local_host_len equ $-local_host

section .text

; rdi=ASCII decimal port, rsi=len. eax=status, rdx=1..65535.
nebo_parse_port:
 test rdi,rdi
 jz .port_invalid
 test rsi,rsi
 jz .port_invalid
 cmp rsi,5
 ja .port_invalid
 xor edx,edx
 xor ecx,ecx
.port_digit:
 movzx eax,byte [rdi+rcx]
 sub eax,'0'
 cmp eax,9
 ja .port_invalid
 imul edx,edx,10
 add edx,eax
 cmp edx,65535
 ja .port_invalid
 inc rcx
 cmp rcx,rsi
 jb .port_digit
 test edx,edx
 jz .port_invalid
 xor eax,eax
 ret
.port_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret

; Deterministic no-network resolver for the only capability address set.
; rdi=SocketAddress out, rsi=HostName, rdx=service text, rcx=service len.
nebo_dns_resolve_local:
 push rbx
 push r12
 mov r12,rdi
 mov rbx,rsi
 test r12,r12
 jz .dns_invalid
 test rbx,rbx
 jz .dns_invalid
 cmp qword [rbx+NEBO_HOSTNAME_LENGTH],local_host_len
 jne .dns_denied
 mov r8,[rbx+NEBO_HOSTNAME_TEXT]
 xor r9d,r9d
.dns_name:
 cmp r9,local_host_len
 jae .dns_port
 mov al,[r8+r9]
 cmp al,[local_host+r9]
 jne .dns_denied
 inc r9
 jmp .dns_name
.dns_port:
 mov rdi,rdx
 mov rsi,rcx
 call nebo_parse_port
 test eax,eax
 jnz .dns_return
 mov qword [r12+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_FAMILY],NEBO_IP_FAMILY_V4
 mov dword [r12+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES],0x0100007f
 mov qword [r12+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_BYTES+8],0
 mov [r12+NEBO_SOCKET_ADDRESS_PORT],rdx
 xor eax,eax
 jmp .dns_return
.dns_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jmp .dns_return
.dns_denied:
 mov eax,NEBO_SYSTEM_ERROR_PERMISSION_DENIED
.dns_return:
 pop r12
 pop rbx
 ret

; rdi=SocketAddress, rsi=output, rdx=capacity. Canonical ip:port or [ipv6]:port.
; Formatting is failure-atomic: the caller buffer is published only at the end.
nebo_socket_address_format:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .saf_invalid
 test r13,r13
 jz .saf_invalid
 test rbx,rbx
 jz .saf_limit
 sub rsp,80
 cmp qword [r12+NEBO_SOCKET_ADDRESS_IP+NEBO_IP_FAMILY],NEBO_IP_FAMILY_V6
 jne .saf_ipv4
 mov byte [rsp],'['
 mov rdi,r12
 lea rsi,[rsp+1]
 mov edx,63
 call nebo_ip_format
 test eax,eax
 jnz .saf_stack_return
 lea r14,[rdx+1]
 mov byte [rsp+r14],']'
 inc r14
 jmp .saf_port
.saf_ipv4:
 mov rdi,r12
 mov rsi,rsp
 mov edx,64
 call nebo_ip_format
 test eax,eax
 jnz .saf_stack_return
 mov r14,rdx
.saf_port:
 mov byte [rsp+r14],':'
 inc r14
 mov rax,[r12+NEBO_SOCKET_ADDRESS_PORT]
 xor ecx,ecx
.saf_digits:
 xor edx,edx
 mov r9,10
 div r9
 add dl,'0'
 mov [rsp+64+rcx],dl
 inc rcx
 test rax,rax
 jnz .saf_digits
 lea rax,[r14+rcx]
 cmp rax,rbx
 ja .saf_stack_limit
.saf_copy:
 dec rcx
 mov al,[rsp+64+rcx]
 mov [rsp+r14],al
 inc r14
 test rcx,rcx
 jnz .saf_copy
 mov rdi,r13
 mov rsi,rsp
 mov rcx,r14
 rep movsb
 mov rdx,r14
 xor eax,eax
 jmp .saf_stack_return
.saf_stack_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
.saf_stack_return:
 add rsp,80
 jmp .saf_return
.saf_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 jmp .saf_return
.saf_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
.saf_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=IpAddress out, rsi=text, rdx=len. eax=status.
nebo_ip_parse:
 push rbx
 push r12
 push r13
 push r14
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r12,r12
 jz .parse_invalid
 test r13,r13
 jz .parse_invalid
 test r14,r14
 jz .parse_invalid
 sub rsp,24
 mov qword [rsp],0
 mov qword [rsp+8],0
 mov qword [rsp+16],0
 cmp r14,2
 jne .check_v6_loopback
 cmp word [r13],0x3a3a
 jne .parse_v4
 mov qword [rsp],NEBO_IP_FAMILY_V6
 jmp .parse_publish
.check_v6_loopback:
 cmp r14,3
 jne .parse_v6_or_v4
 cmp word [r13],0x3a3a
 jne .parse_v4
 cmp byte [r13+2],'1'
 jne .parse_v4
 mov qword [rsp],NEBO_IP_FAMILY_V6
 mov byte [rsp+23],1
 jmp .parse_publish
.parse_v6_or_v4:
 mov rax,r13
 mov rcx,r14
 xor r8d,r8d
.colon_scan:
 cmp r8,rcx
 jae .parse_v4
 cmp byte [rax+r8],':'
 je .parse_v6
 inc r8
 jmp .colon_scan
.parse_v6:
 mov qword [rsp],NEBO_IP_FAMILY_V6
 xor ebx,ebx
 xor r8d,r8d
.v6_group:
 cmp ebx,8
 jae .v6_done
 cmp r8,r14
 jae .parse_fail_stack
 xor eax,eax
 xor ecx,ecx
.v6_digit:
 cmp r8,r14
 jae .v6_group_end
 movzx edx,byte [r13+r8]
 cmp dl,':'
 je .v6_group_end
 cmp ecx,4
 jae .parse_fail_stack
 shl eax,4
 cmp dl,'0'
 jb .parse_fail_stack
 cmp dl,'9'
 jbe .v6_num
 or dl,0x20
 cmp dl,'a'
 jb .parse_fail_stack
 cmp dl,'f'
 ja .parse_fail_stack
 sub dl,'a'-10
 jmp .v6_add
.v6_num:
 sub dl,'0'
.v6_add:
 movzx edx,dl
 add eax,edx
 inc ecx
 inc r8
 jmp .v6_digit
.v6_group_end:
 test ecx,ecx
 jz .parse_fail_stack
 mov [rsp+8+rbx*2],ah
 mov [rsp+9+rbx*2],al
 inc ebx
 cmp ebx,8
 jae .v6_done
 cmp r8,r14
 jae .parse_fail_stack
 inc r8
 jmp .v6_group
.v6_done:
 cmp r8,r14
 jne .parse_fail_stack
 jmp .parse_publish
.parse_v4:
 mov qword [rsp],NEBO_IP_FAMILY_V4
 xor ebx,ebx
 xor r8d,r8d
.v4_segment:
 cmp ebx,4
 jae .v4_done
 cmp r8,r14
 jae .parse_fail_stack
 xor eax,eax
 xor ecx,ecx
 mov r9b,[r13+r8]
.v4_digit:
 cmp r8,r14
 jae .v4_segment_end
 movzx edx,byte [r13+r8]
 cmp dl,'.'
 je .v4_segment_end
 cmp dl,'0'
 jb .parse_fail_stack
 cmp dl,'9'
 ja .parse_fail_stack
 cmp ecx,3
 jae .parse_fail_stack
 imul eax,eax,10
 sub edx,'0'
 add eax,edx
 cmp eax,255
 ja .parse_fail_stack
 inc ecx
 inc r8
 jmp .v4_digit
.v4_segment_end:
 test ecx,ecx
 jz .parse_fail_stack
 cmp ecx,1
 je .v4_store
 cmp r9b,'0'
 je .parse_fail_stack
.v4_store:
 mov [rsp+8+rbx],al
 inc ebx
 cmp ebx,4
 jae .v4_done
 cmp r8,r14
 jae .parse_fail_stack
 inc r8
 jmp .v4_segment
.v4_done:
 cmp r8,r14
 jne .parse_fail_stack
.parse_publish:
 mov rax,[rsp]
 mov [r12],rax
 mov rax,[rsp+8]
 mov [r12+8],rax
 mov rax,[rsp+16]
 mov [r12+16],rax
 add rsp,24
 xor eax,eax
 jmp .parse_return
.parse_fail_stack:
 add rsp,24
.parse_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
.parse_return:
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; rdi=IpAddress, rsi=output, rdx=capacity. eax=status, rdx=bytes.
nebo_ip_format:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 mov rbx,rdx
 test r12,r12
 jz .format_invalid
 test r13,r13
 jz .format_invalid
 cmp qword [r12],NEBO_IP_FAMILY_V4
 je .format_v4
 cmp qword [r12],NEBO_IP_FAMILY_V6
 jne .format_invalid
 mov rax,[r12+8]
 or rax,[r12+16]
 jnz .format_v6_loop_check
 cmp rbx,2
 jb .format_limit
 mov word [r13],0x3a3a
 mov edx,2
 xor eax,eax
 jmp .format_return
.format_v6_loop_check:
 cmp qword [r12+8],0
 jne .format_v6_full
 mov rax,[r12+16]
 mov rcx,0x0100000000000000
 cmp rax,rcx
 jne .format_v6_full
 cmp rbx,3
 jb .format_limit
 mov word [r13],0x3a3a
 mov byte [r13+2],'1'
 mov edx,3
 xor eax,eax
 jmp .format_return
.format_v6_full:
 cmp rbx,39
 jb .format_limit
 xor ebx,ebx
 xor r8d,r8d
.format_v6_group:
 movzx eax,byte [r12+8+rbx*2]
 shl eax,8
 mov al,[r12+9+rbx*2]
 mov r9d,12
.format_v6_nibble:
 mov edx,eax
 mov ecx,r9d
 shr edx,cl
 and edx,15
 cmp dl,9
 jbe .format_hex_num
 add dl,'a'-10
 jmp .format_hex_store
.format_hex_num:
 add dl,'0'
.format_hex_store:
 mov [r13+r8],dl
 inc r8
 sub r9d,4
 jns .format_v6_nibble
 inc ebx
 cmp ebx,8
 jae .format_v6_done
 mov byte [r13+r8],':'
 inc r8
 jmp .format_v6_group
.format_v6_done:
 mov rdx,r8
 xor eax,eax
 jmp .format_return
.format_v4:
 cmp rbx,15
 jb .format_limit
 xor ebx,ebx
 xor r8d,r8d
.format_v4_segment:
 movzx eax,byte [r12+8+rbx]
 cmp eax,100
 jb .format_v4_lt100
 xor edx,edx
 mov ecx,100
 div ecx
 add al,'0'
 mov [r13+r8],al
 inc r8
 mov eax,edx
 xor edx,edx
 mov ecx,10
 div ecx
 add al,'0'
 mov [r13+r8],al
 inc r8
 add dl,'0'
 mov [r13+r8],dl
 inc r8
 jmp .format_v4_next
.format_v4_lt100:
 cmp eax,10
 jb .format_v4_one
 xor edx,edx
 mov ecx,10
 div ecx
 add al,'0'
 mov [r13+r8],al
 inc r8
 add dl,'0'
 mov [r13+r8],dl
 inc r8
 jmp .format_v4_next
.format_v4_one:
 add al,'0'
 mov [r13+r8],al
 inc r8
.format_v4_next:
 inc ebx
 cmp ebx,4
 jae .format_v4_done
 mov byte [r13+r8],'.'
 inc r8
 jmp .format_v4_segment
.format_v4_done:
 mov rdx,r8
 xor eax,eax
 jmp .format_return
.format_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 jmp .format_return
.format_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
.format_return:
 pop r13
 pop r12
 pop rbx
 ret

; rdi=SocketAddress out, rsi=IpAddress, rdx=port 0..65535.
nebo_socket_address_new:
 test rdi,rdi
 jz .socket_invalid
 test rsi,rsi
 jz .socket_invalid
 cmp rdx,65535
 ja .socket_invalid
 mov rax,[rsi]
 cmp rax,NEBO_IP_FAMILY_V4
 je .socket_store
 cmp rax,NEBO_IP_FAMILY_V6
 jne .socket_invalid
.socket_store:
 mov [rdi],rax
 mov rax,[rsi+8]
 mov [rdi+8],rax
 mov rax,[rsi+16]
 mov [rdi+16],rax
 mov [rdi+NEBO_SOCKET_ADDRESS_PORT],rdx
 xor eax,eax
 ret
.socket_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=Hostname out, rsi=text, rdx=len. ASCII DNS grammar, no resolution.
nebo_hostname_parse:
 test rdi,rdi
 jz .host_invalid
 test rsi,rsi
 jz .host_invalid
 test rdx,rdx
 jz .host_invalid
 cmp rdx,NEBO_NETWORK_MAX_HOSTNAME_BYTES
 ja .host_invalid
 xor ecx,ecx
 xor r8d,r8d
 xor r9d,r9d
.host_char:
 cmp rcx,rdx
 jae .host_end
 mov al,[rsi+rcx]
 cmp al,'.'
 je .host_dot
 cmp al,'-'
 je .host_hyphen
 or al,0x20
 cmp al,'a'
 jb .host_digit
 cmp al,'z'
 jbe .host_alnum
.host_digit:
 cmp al,'0'
 jb .host_invalid
 cmp al,'9'
 ja .host_invalid
.host_alnum:
 inc r8
 cmp r8,NEBO_NETWORK_MAX_LABEL_BYTES
 ja .host_invalid
 inc rcx
 jmp .host_char
.host_hyphen:
 test r8,r8
 jz .host_invalid
 inc r8
 cmp r8,NEBO_NETWORK_MAX_LABEL_BYTES
 ja .host_invalid
 inc rcx
 jmp .host_char
.host_dot:
 test r8,r8
 jz .host_invalid
 cmp byte [rsi+rcx-1],'-'
 je .host_invalid
 inc r9
 xor r8d,r8d
 inc rcx
 jmp .host_char
.host_end:
 test r8,r8
 jz .host_invalid
 cmp byte [rsi+rcx-1],'-'
 je .host_invalid
 inc r9
 mov [rdi+NEBO_HOSTNAME_TEXT],rsi
 mov [rdi+NEBO_HOSTNAME_LENGTH],rdx
 mov [rdi+NEBO_HOSTNAME_LABELS],r9
 mov qword [rdi+NEBO_HOSTNAME_FLAGS],NEBO_HOSTNAME_FLAG_CANONICAL
 xor eax,eax
 ret
.host_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 ret

; rdi=Hostname, rsi=output, rdx=capacity. Lowercase deterministic copy.
nebo_hostname_format:
 test rdi,rdi
 jz .host_format_invalid
 test rsi,rsi
 jz .host_format_invalid
 mov rcx,[rdi+NEBO_HOSTNAME_LENGTH]
 cmp rcx,rdx
 ja .host_format_limit
 mov r8,[rdi+NEBO_HOSTNAME_TEXT]
 xor eax,eax
.host_format_loop:
 cmp rax,rcx
 jae .host_format_done
 mov dl,[r8+rax]
 cmp dl,'A'
 jb .host_format_store
 cmp dl,'Z'
 ja .host_format_store
 add dl,32
.host_format_store:
 mov [rsi+rax],dl
 inc rax
 jmp .host_format_loop
.host_format_done:
 mov rdx,rcx
 xor eax,eax
 ret
.host_format_invalid:
 mov eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 xor edx,edx
 ret
.host_format_limit:
 mov eax,NEBO_SYSTEM_ERROR_LIMIT_EXCEEDED
 xor edx,edx
 ret
