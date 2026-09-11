; Source-visible bounded IPv4 loopback values and native resource ownership.
; Socket records outlive source temporaries. Exactly 32 constructions and
; 4096 bytes per connection are admitted; all handles close on exit or trap.
bits 64
default rel
%include "runtime/network/socket.inc"
%include "compiler/semantic/collections/list_core.inc"
extern neboc_list_new
extern neboc_list_validate
extern nebo_cancellation_check
extern neboc_runtime_store_integer
extern nebo_runtime_trap_arithmetic_domain
extern nebo_http_public
extern nebo_runtime_trace_setting
global nebo_network_public
global nebo_network_public_allocate
global nebo_network_public_configure
global nebo_network_public_capability
global nebo_network_public_cleanup
global nebo_network_public_closed
section .bss
align 8
nebo_network_public_capability: resb 64
network_public_records: resb 32*64
network_public_used: resq 1
network_public_opened: resq 1
network_public_explicit_closed: resq 1
network_public_automatic_closed: resq 1
section .rodata
network_public_trace_key: db 'NEBO_TEST_NETWORK_TRACE=1',0
network_public_trace_key_len equ $-network_public_trace_key
section .text
nebo_network_public:
 extern nebo_runtime_network_cleanup_hook
 lea rax,[rel nebo_network_public_cleanup]
 mov [rel nebo_runtime_network_cleanup_hook],rax
 cmp edi,240
 jae nebo_http_public
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
 cmp ebx,207
 jbe .buffer
 cmp ebx,210
 je .ip
 cmp ebx,211
 je .address
 cmp ebx,212
 je .address_text
 cmp ebx,225
 je .close
 cmp ebx,226
 je .local_address
 cmp ebx,233
 je .datagram_count
 cmp ebx,234
 je .datagram_sender
 cmp ebx,220
 je .open
 cmp ebx,221
 je .open
 cmp ebx,222
 je .connect_check
 cmp ebx,230
 je .open
 cmp ebx,223
 je .read
 cmp ebx,224
 je .write
 cmp ebx,231
 je .send
 cmp ebx,232
 je .receive
 jmp .trap
.buffer:
 cmp ebx,201
 jbe .buffer_new
 mov rdi,r12
 call neboc_list_validate
 test eax,eax
 jnz .trap
 cmp ebx,202
 je .buffer_length
 cmp ebx,203
 je .buffer_capacity
 cmp ebx,206
 je .buffer_freeze
 cmp ebx,207
 je .buffer_push
 cmp r13,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jae .trap
 mov rcx,[r12+NEBOC_LIST_DATA_OFFSET]
 movzx eax,byte [rcx+r13]
 cmp ebx,204
 je .done
 cmp r14,255
 ja .trap
 mov [rcx+r13],r14b
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 jmp .done
.buffer_new:
 cmp r13,64
 ja .trap
 mov rdi,r15
 mov esi,1
 mov edx,1
 mov ecx,1
 call neboc_list_new
 test eax,eax
 jnz .trap
 mov [r15+NEBOC_LIST_CAPACITY_OFFSET],r13
 lea rax,[r15+64]
 mov [r15+NEBOC_LIST_DATA_OFFSET],rax
 cmp ebx,201
 jne .descriptor
 mov [r15+NEBOC_LIST_LENGTH_OFFSET],r13
 mov rdi,rax
 mov rcx,r13
 xor eax,eax
 rep stosb
 jmp .descriptor
.buffer_push:
 cmp r13,255
 ja .trap
 mov rcx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 cmp rcx,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jae .trap
 mov rax,[r12+NEBOC_LIST_DATA_OFFSET]
 mov [rax+rcx],r13b
 inc qword [r12+NEBOC_LIST_LENGTH_OFFSET]
 inc qword [r12+NEBOC_LIST_GENERATION_OFFSET]
 xor eax,eax
 jmp .done
.buffer_length:
 mov rax,[r12+NEBOC_LIST_LENGTH_OFFSET]
 jmp .done
.buffer_capacity:
 mov rax,[r12+NEBOC_LIST_CAPACITY_OFFSET]
 jmp .done
.buffer_freeze:
 mov rsi,[r12+NEBOC_LIST_DATA_OFFSET]
 mov rdx,[r12+NEBOC_LIST_LENGTH_OFFSET]
 lea rdi,[r15+32]
 mov [r15],rdi
 mov [r15+8],rdx
 mov qword [r15+16],0
 mov rcx,rdx
 rep movsb
 jmp .descriptor
.ip:
 mov rdi,r15
 mov rsi,[r13]
 mov rdx,[r13+8]
 call nebo_ip_parse
 test eax,eax
 jnz .trap
 jmp .descriptor
.address:
 mov rdi,r15
 mov rsi,r13
 mov rdx,r14
 call nebo_socket_address_new
 test eax,eax
 jnz .trap
 jmp .descriptor
.address_text:
 mov rdi,r12
 lea rsi,[r15+32]
 mov edx,128
 call nebo_socket_address_format
 test eax,eax
 jnz .trap
 lea rax,[r15+32]
 mov [r15],rax
 mov [r15+8],rdx
 mov qword [r15+16],0
 mov word [r15+20],1
 jmp .descriptor
.connect_check:
 mov rdi,r14
 call nebo_cancellation_check
 test eax,eax
 jnz .trap
.open:
 call nebo_network_public_allocate
 test rax,rax
 jz .trap
 mov [rsp],rax
 mov rdi,rax
 mov rsi,r13
 lea rdx,[rel nebo_network_public_capability]
 cmp ebx,220
 je .bind
 cmp ebx,221
 je .accept
 cmp ebx,230
 je .udp_bind
 call nebo_tcp_stream_connect
 jmp .opened
.bind:
 mov ecx,4
 call nebo_tcp_listener_bind
 jmp .opened
.accept:
 mov rsi,r12
 call nebo_tcp_listener_accept
 jmp .opened
.udp_bind:
 call nebo_udp_socket_bind
.opened:
 test eax,eax
 jnz .trap
 mov rdi,[rsp]
 call nebo_network_public_configure
 test eax,eax
 jnz .trap
 mov rax,[rsp]
 jmp .done
.local_address:
 cmp qword [r12+NEBO_SOCKET_STATE],NEBO_RESOURCE_STATE_OPEN
 jne .trap
 mov qword [r15],4
 mov qword [r15+8],0x0100007f
 mov qword [r15+16],0
 mov rax,[r12+NEBO_SOCKET_PORT]
 mov [r15+24],rax
 jmp .descriptor
.read:
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .trap
 mov rdi,r12
 lea rsi,[r15+64]
 mov rdx,[r13+NEBOC_LIST_CAPACITY_OFFSET]
 call nebo_tcp_stream_read
 test eax,eax
 jnz .result
 call .publish_buffer
 jmp .result
.write:
 mov rdi,r12
 mov rsi,[r13]
 mov rdx,[r13+8]
 call nebo_tcp_stream_write_all
 jmp .result
.send:
 mov rdi,r12
 mov rsi,[r13]
 mov rdx,[r13+8]
 mov rcx,r14
 call nebo_udp_socket_send_to
 jmp .result
.receive:
 mov rdi,r13
 call neboc_list_validate
 test eax,eax
 jnz .trap
 mov rdi,r12
 lea rsi,[r15+64]
 mov rdx,[r13+NEBOC_LIST_CAPACITY_OFFSET]
 lea rcx,[r15+8]
 call nebo_udp_socket_receive_from_address
 test eax,eax
 jnz .trap
 call .publish_buffer
 mov [r15],rdx
 jmp .descriptor
.publish_buffer:
 mov rdi,[r13+NEBOC_LIST_DATA_OFFSET]
 lea rsi,[r15+64]
 mov rcx,rdx
 rep movsb
 mov [r13+NEBOC_LIST_LENGTH_OFFSET],rdx
 inc qword [r13+NEBOC_LIST_GENERATION_OFFSET]
 ret
.datagram_count:
 mov rax,[r12]
 jmp .done
.datagram_sender:
 lea rax,[r12+8]
 jmp .done
.close:
 mov rdi,r12
 call nebo_socket_close
 test eax,eax
 jnz .result
 call nebo_network_public_closed
 xor edx,edx
.result:
 xor esi,esi
 test eax,eax
 jz .store_result
 mov esi,1
 mov edx,eax
.store_result:
 mov rdi,r15
 call neboc_runtime_store_integer
.descriptor:
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

nebo_network_public_allocate:
 sub rsp,8
 cmp qword [rel nebo_network_public_capability],0
 jne .ready
 lea rdi,[rel nebo_network_public_capability]
 mov esi,NEBO_NETWORK_CAP_ALL
 mov edx,32
 mov ecx,4096
 mov r8d,100000000
 call nebo_network_capability_init
 test eax,eax
 jnz .bad
.ready:
 mov rax,[rel network_public_used]
 cmp rax,32
 jae .bad
 inc qword [rel network_public_used]
 shl rax,6
 lea rdx,[rel network_public_records]
 add rax,rdx
 add rsp,8
 ret
.bad:
 xor eax,eax
 add rsp,8
 ret

; Add actual kernel receive/send deadlines to every newly published socket.
nebo_network_public_configure:
 push rbx
 sub rsp,16
 mov rbx,rdi
 inc qword [rel network_public_opened]
 mov qword [rsp],0
 mov qword [rsp+8],100000
 mov eax,54
 mov rdi,[rbx+NEBO_SOCKET_FD]
 mov esi,1
 mov edx,20
 mov r10,rsp
 mov r8d,16
 syscall
 test rax,rax
 jnz .done
 mov eax,54
 mov rdi,[rbx+NEBO_SOCKET_FD]
 mov esi,1
 mov edx,21
 mov r10,rsp
 mov r8d,16
 syscall
.done:
 add rsp,16
 pop rbx
 ret
nebo_network_public_closed:
 inc qword [rel network_public_explicit_closed]
 ret

nebo_network_public_cleanup:
 push rbx
 sub rsp,64
 xor ebx,ebx
.next:
 cmp rbx,[rel network_public_used]
 jae .trace
 mov rax,rbx
 shl rax,6
 lea rdi,[rel network_public_records]
 add rdi,rax
 mov rax,[rdi+NEBO_SOCKET_STATE]
 cmp rax,NEBO_RESOURCE_STATE_OPEN
 je .close
 cmp rax,NEBO_RESOURCE_STATE_HALF_CLOSED
 jne .skip
.close:
 call nebo_socket_close
 inc qword [rel network_public_automatic_closed]
.skip:
 inc rbx
 jmp .next
.trace:
 lea rsi,[rel network_public_trace_key]
 mov edx,network_public_trace_key_len
 call nebo_runtime_trace_setting
 test eax,eax
 jz .done
 mov rax,0x3154454e4f42454e
 mov [rsp],rax
 mov rax,[rel network_public_used]
 mov [rsp+8],rax
 mov rax,[rel network_public_opened]
 mov [rsp+16],rax
 mov rax,[rel network_public_explicit_closed]
 mov [rsp+24],rax
 mov rax,[rel network_public_automatic_closed]
 mov [rsp+32],rax
 mov rax,[rel nebo_network_public_capability+NEBO_NETWORK_CAPABILITY_GENERATION]
 mov [rsp+40],rax
 mov eax,1
 mov edi,1
 mov rsi,rsp
 mov edx,48
 syscall
.done:
 add rsp,64
 pop rbx
 ret
section .note.GNU-stack noalloc noexec nowrite progbits
