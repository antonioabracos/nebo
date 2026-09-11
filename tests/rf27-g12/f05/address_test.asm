bits 64
default rel
%include "runtime/network/address.inc"
section .rodata
ipv4 db '127.0.0.1'
ipv4_bad db '127.00.0.1'
ipv6_loop db '::1'
ipv6_full db '2001:0db8:0000:0000:0000:0000:0000:0001'
host db 'LocalHost.Example'
host_bad db '-bad.local'
section .bss
ip resb 24
ip2 resb 24
socket resb 32
hostname resb 32
output resb 64
section .text
global _start
_start:
 lea rdi,[ip]
 lea rsi,[ipv4]
 mov edx,9
 call nebo_ip_parse
 test eax,eax
 jnz .fail1
 cmp qword [ip],NEBO_IP_FAMILY_V4
 jne .fail2
 cmp byte [ip+8],127
 jne .fail3
 cmp byte [ip+11],1
 jne .fail4
 lea rdi,[ip]
 lea rsi,[output]
 mov edx,64
 call nebo_ip_format
 test eax,eax
 jnz .fail5
 cmp rdx,9
 jne .fail6
 mov rax,[output]
 cmp rax,[ipv4]
 jne .fail7
 lea rdi,[ip2]
 lea rsi,[output]
 mov rdx,9
 call nebo_ip_parse
 test eax,eax
 jnz .fail8
 mov rax,[ip+8]
 cmp rax,[ip2+8]
 jne .fail9
 lea rdi,[ip2]
 lea rsi,[ipv4_bad]
 mov edx,10
 call nebo_ip_parse
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail10
 lea rdi,[ip]
 lea rsi,[ipv6_loop]
 mov edx,3
 call nebo_ip_parse
 test eax,eax
 jnz .fail11
 cmp qword [ip],NEBO_IP_FAMILY_V6
 jne .fail12
 cmp byte [ip+23],1
 jne .fail13
 lea rdi,[ip]
 lea rsi,[output]
 mov edx,64
 call nebo_ip_format
 test eax,eax
 jnz .fail14
 cmp rdx,3
 jne .fail15
 cmp word [output],0x3a3a
 jne .fail16
 cmp byte [output+2],'1'
 jne .fail17
 lea rdi,[ip]
 lea rsi,[ipv6_full]
 mov edx,39
 call nebo_ip_parse
 test eax,eax
 jnz .fail18
 lea rdi,[ip]
 lea rsi,[output]
 mov edx,39
 call nebo_ip_format
 test eax,eax
 jnz .fail19
 cmp rdx,39
 jne .fail20
 lea rdi,[socket]
 lea rsi,[ip]
 mov edx,65535
 call nebo_socket_address_new
 test eax,eax
 jnz .fail21
 cmp qword [socket+NEBO_SOCKET_ADDRESS_PORT],65535
 jne .fail22
 lea rdi,[socket]
 lea rsi,[ip]
 mov rdx,65536
 call nebo_socket_address_new
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail23
 lea rdi,[hostname]
 lea rsi,[host]
 mov edx,17
 call nebo_hostname_parse
 test eax,eax
 jnz .fail24
 cmp qword [hostname+NEBO_HOSTNAME_LABELS],2
 jne .fail25
 lea rdi,[hostname]
 lea rsi,[output]
 mov edx,64
 call nebo_hostname_format
 test eax,eax
 jnz .fail26
 cmp rdx,17
 jne .fail27
 cmp byte [output],'l'
 jne .fail28
 cmp byte [output+10],'e'
 jne .fail29
 lea rdi,[hostname]
 lea rsi,[host_bad]
 mov edx,10
 call nebo_hostname_parse
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail30
 lea rdi,[ip]
 lea rsi,[ipv4]
 mov edx,8
 call nebo_ip_parse
 cmp eax,NEBO_SYSTEM_ERROR_INVALID_ARGUMENT
 jne .fail31
 xor edi,edi
 jmp .exit
%assign i 1
%rep 31
.fail%+i: mov edi,i
 jmp .exit
%assign i i+1
%endrep
.exit:
 mov eax,60
 syscall
