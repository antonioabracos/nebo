; Practical-I/O X11 event driver. Test-only, direct protocol, no C/libc/Xlib.
; argv: SOCKET COOKIE_HEX WINDOW_XID c
;    or SOCKET COOKIE_HEX WINDOW_XID t TEXT
;    or SOCKET COOKIE_HEX WINDOW_XID p X_HEX Y_HEX  (primary click)
;    or SOCKET COOKIE_HEX WINDOW_XID v X_HEX Y_HEX  (pointer move)
;    or SOCKET COOKIE_HEX WINDOW_XID r W_HEX H_HEX  (configure size)
;    or SOCKET COOKIE_HEX WINDOW_XID g X_HEX Y_HEX  (configure position)
;    or SOCKET COOKIE_HEX WINDOW_XID m              (map/restore)
;    or SOCKET COOKIE_HEX WINDOW_XID i              (ICCCM minimize request)
;    or SOCKET COOKIE_HEX WINDOW_XID e              (Expose)
;    or SOCKET COOKIE_HEX WINDOW_XID P X_HEX Y_HEX  (XTEST absolute motion + primary press)
;    or SOCKET COOKIE_HEX WINDOW_XID U              (XTEST primary release)
;    or SOCKET COOKIE_HEX WINDOW_XID W X_HEX Y_HEX  (XTEST absolute motion)
;    or SOCKET COOKIE_HEX WINDOW_XID B SX SY TX TY   (queued XTEST press + motion)
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_protocol.inc"

extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown

global _start

%define DRIVER_SCRATCH_BYTES 65536
%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_NANOSLEEP 35
%define SYS_EXIT 60
%define X11_OP_QUERY_EXTENSION 98
%define X11_OP_GET_INPUT_FOCUS 43
%define XTEST_FAKE_INPUT 2

section .rodata
auth_name: db "MIT-MAGIC-COOKIE-1"

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
config: resb NEBO_X11_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb DRIVER_SCRATCH_BYTES
request: resb 44
query_reply: resb 32
xtest_opcode: resb 1
target_xid: resd 1
target_x: resd 1
target_y: resd 1
wait_spec: resq 2

section .text
_start:
 mov rax,[rsp]
 cmp rax,5
 jb .usage
 mov r12,[rsp+16]
 mov r13,[rsp+24]
 mov rdi,[rsp+32]
 call parse_u32
 test eax,eax
 jz .usage
 mov [rel target_xid],eax
 lea rdi,[rel socket_address]
 xor eax,eax
 mov ecx,NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
 cld
 rep stosb
 mov word [rel socket_address],NEBO_LINUX_AF_UNIX
 lea rdi,[rel socket_address+2]
 xor ecx,ecx
.copy_socket:
 cmp ecx,107
 jae .fail
 mov al,[r12+rcx]
 mov [rdi+rcx],al
 test al,al
 jz .socket_ready
 inc ecx
 jmp .copy_socket
.socket_ready:
 lea r14,[rcx+3]
 mov rdi,r13
 lea rsi,[rel auth_cookie]
 mov edx,NEBO_X11_MAX_AUTH_BYTES
 lea rcx,[rel auth_cookie_length]
 call parse_hex
 test eax,eax
 jnz .fail
 lea rdi,[rel config]
 xor eax,eax
 mov ecx,NEBO_X11_CONFIG_QWORDS
 cld
 rep stosq
 lea rax,[rel socket_address]
 mov [rel config+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET],rax
 mov [rel config+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET],r14
 lea rax,[rel auth_name]
 mov [rel config+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET],rax
 mov qword [rel config+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET],NEBO_X11_AUTH_NAME_LENGTH
 lea rax,[rel auth_cookie]
 mov [rel config+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET],rax
 mov rax,[rel auth_cookie_length]
 mov [rel config+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET],rax
 lea rax,[rel scratch]
 mov [rel config+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET],rax
 mov qword [rel config+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET],DRIVER_SCRATCH_BYTES
 mov qword [rel config+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET],NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
 mov qword [rel config+NEBO_X11_CONFIG_FLAGS_OFFSET],NEBO_X11_CONFIG_REQUIRED_FLAGS
 lea rdi,[rel adapter]
 lea rsi,[rel config]
 call nebo_x11_adapter_init
 test eax,eax
 jnz .fail
 mov rax,[rsp+40]
 cmp byte [rax],'c'
 je .close
 cmp byte [rax],'t'
 je .text
 cmp byte [rax],'p'
 je .pointer
 cmp byte [rax],'v'
 je .motion
 cmp byte [rax],'r'
 je .resize
 cmp byte [rax],'g'
 je .geometry
 cmp byte [rax],'m'
 je .map
 cmp byte [rax],'i'
 je .minimize
 cmp byte [rax],'e'
 je .expose
 cmp byte [rax],'P'
 je .xtest_press
 cmp byte [rax],'U'
 je .xtest_release
 cmp byte [rax],'W'
 je .xtest_motion
 cmp byte [rax],'B'
 je .xtest_press_motion
 jmp .cleanup_fail
.text:
 cmp qword [rsp],6
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call send_text
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.pointer:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 mov edi,NEBO_X11_EVENT_BUTTON_PRESS
 mov esi,[rel target_x]
 mov edx,[rel target_y]
 call send_pointer
 test eax,eax
 jnz .cleanup_fail
 mov edi,NEBO_X11_EVENT_BUTTON_RELEASE
 mov esi,[rel target_x]
 mov edx,[rel target_y]
 call send_pointer
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.motion:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 mov edi,NEBO_X11_EVENT_MOTION_NOTIFY
 mov esi,[rel target_x]
 mov edx,[rel target_y]
 call send_pointer
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.resize:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 call send_resize
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.geometry:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 call send_geometry
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.map:
 cmp qword [rsp],5
 jne .cleanup_fail
 call send_map
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.minimize:
 cmp qword [rsp],5
 jne .cleanup_fail
 call send_minimize
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.expose:
 cmp qword [rsp],5
 jne .cleanup_fail
 call send_expose
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.xtest_press:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 call query_xtest
 test eax,eax
 jnz .cleanup_fail
 call send_xtest_motion
 test eax,eax
 jnz .cleanup_fail
 mov edi,NEBO_X11_EVENT_BUTTON_PRESS
 call send_xtest_button
 test eax,eax
 jnz .cleanup_fail
 call sync_server
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.xtest_release:
 cmp qword [rsp],5
 jne .cleanup_fail
 call query_xtest
 test eax,eax
 jnz .cleanup_fail
 mov edi,NEBO_X11_EVENT_BUTTON_RELEASE
 call send_xtest_button
 test eax,eax
 jnz .cleanup_fail
 call sync_server
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.xtest_motion:
 cmp qword [rsp],7
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 call query_xtest
 test eax,eax
 jnz .cleanup_fail
 call send_xtest_motion
 test eax,eax
 jnz .cleanup_fail
 call sync_server
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.xtest_press_motion:
 cmp qword [rsp],9
 jne .cleanup_fail
 mov rdi,[rsp+48]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+56]
 call parse_u32
 mov [rel target_y],eax
 call query_xtest
 test eax,eax
 jnz .cleanup_fail
 call send_xtest_motion
 test eax,eax
 jnz .cleanup_fail
 mov edi,NEBO_X11_EVENT_BUTTON_PRESS
 call send_xtest_button
 test eax,eax
 jnz .cleanup_fail
 ; Deliberately do not insert a reply barrier here.  The target motion is
 ; queued behind the physical press before the client can process its implicit
 ; grab, matching a fast human edge drag without adding product timing.
 mov rdi,[rsp+64]
 call parse_u32
 mov [rel target_x],eax
 mov rdi,[rsp+72]
 call parse_u32
 mov [rel target_y],eax
 call send_xtest_motion
 test eax,eax
 jnz .cleanup_fail
 call sync_server
 test eax,eax
 jnz .cleanup_fail
 jmp .cleanup_ok
.close:
 cmp byte [rax+1],0
 jne .cleanup_fail
 call send_close
 test eax,eax
 jnz .cleanup_fail
.cleanup_ok:
 call driver_wait
 lea rdi,[rel adapter]
 call nebo_x11_adapter_shutdown
 xor edi,edi
 jmp .exit
.cleanup_fail:
 lea rdi,[rel adapter]
 call nebo_x11_adapter_shutdown
.fail:
 mov edi,1
 jmp .exit
.usage:
 mov edi,2
.exit:
 mov eax,SYS_EXIT
 syscall
 ud2

driver_wait:
 mov qword [rel wait_spec],0
 mov qword [rel wait_spec+8],100000000
 mov eax,SYS_NANOSLEEP
 lea rdi,[rel wait_spec]
 xor esi,esi
 syscall
 ret

send_close:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_SEND_EVENT
 mov word [rel request+2],11
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov byte [rel request+12],(NEBO_X11_EVENT_CLIENT_MESSAGE | NEBO_X11_EVENT_SEND_EVENT_MASK)
 mov byte [rel request+13],32
 mov [rel request+16],eax
 mov eax,[rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET]
 mov [rel request+20],eax
 mov eax,[rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET]
 mov [rel request+24],eax
 jmp write_request

send_map:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_MAP_WINDOW
 mov word [rel request+2],2
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov edx,8
 jmp write_request_length

; Ask the window manager to enter IconicState.  This is a protocol-level
; lifecycle request, not synthetic pointer or keyboard input.
send_minimize:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_SEND_EVENT
 mov word [rel request+2],11
 mov eax,[rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
 mov [rel request+4],eax
 mov dword [rel request+8],(NEBO_X11_EVENT_MASK_SUBSTRUCTURE_NOTIFY | NEBO_X11_EVENT_MASK_SUBSTRUCTURE_REDIRECT)
 mov byte [rel request+12],NEBO_X11_EVENT_CLIENT_MESSAGE
 mov byte [rel request+13],32
 mov eax,[rel target_xid]
 mov [rel request+16],eax
 mov eax,[rel adapter+NEBO_X11_ADAPTER_WM_CHANGE_STATE_ATOM_OFFSET]
 mov [rel request+20],eax
 mov dword [rel request+24],NEBO_X11_ICCCM_ICONIC_STATE
 mov edx,44
 jmp write_request_length

send_resize:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_CONFIGURE_WINDOW
 mov word [rel request+2],5
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov word [rel request+8],(NEBO_X11_CONFIG_WINDOW_WIDTH | NEBO_X11_CONFIG_WINDOW_HEIGHT)
 mov eax,[rel target_x]
 mov [rel request+12],eax
 mov eax,[rel target_y]
 mov [rel request+16],eax
 mov edx,20
 jmp write_request_length

send_geometry:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_CONFIGURE_WINDOW
 mov word [rel request+2],5
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov word [rel request+8],(NEBO_X11_CONFIG_WINDOW_X | NEBO_X11_CONFIG_WINDOW_Y)
 mov eax,[rel target_x]
 mov [rel request+12],eax
 mov eax,[rel target_y]
 mov [rel request+16],eax
 mov edx,20
 jmp write_request_length

send_expose:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_SEND_EVENT
 mov word [rel request+2],11
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov dword [rel request+8],NEBO_X11_EVENT_MASK_EXPOSURE
 mov byte [rel request+12],(NEBO_X11_EVENT_EXPOSE | NEBO_X11_EVENT_SEND_EVENT_MASK)
 mov [rel request+16],eax
 jmp write_request

; Resolve the server-assigned XTEST major opcode on this direct connection.
; The five-byte name is padded to a four-byte request boundary.
query_xtest:
 push r12
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],X11_OP_QUERY_EXTENSION
 mov word [rel request+2],4
 mov word [rel request+4],5
 mov byte [rel request+8],'X'
 mov byte [rel request+9],'T'
 mov byte [rel request+10],'E'
 mov byte [rel request+11],'S'
 mov byte [rel request+12],'T'
 mov edx,16
 call write_request_length
 test eax,eax
 jnz .xtest_query_done
 lea r12,[rel query_reply]
 mov r8d,32
.xtest_query_read:
 mov eax,SYS_READ
 mov edi,[rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
 mov rsi,r12
 mov edx,r8d
 syscall
 test rax,rax
 js .xtest_query_retry
 test rax,rax
 jz .xtest_query_bad
 add r12,rax
 sub r8,rax
 jnz .xtest_query_read
 cmp byte [rel query_reply],1
 jne .xtest_query_bad
 cmp byte [rel query_reply+8],1
 jne .xtest_query_bad
 mov al,[rel query_reply+9]
 test al,al
 jz .xtest_query_bad
 mov [rel xtest_opcode],al
 xor eax,eax
 jmp .xtest_query_done
.xtest_query_retry:
 cmp rax,-4
 je .xtest_query_read
.xtest_query_bad:
 mov eax,1
.xtest_query_done:
 pop r12
 ret

; Fake absolute root motion through the dynamically discovered XTEST opcode.
send_xtest_motion:
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov al,[rel xtest_opcode]
 mov [rel request],al
 mov byte [rel request+1],XTEST_FAKE_INPUT
 mov word [rel request+2],9
 mov byte [rel request+4],NEBO_X11_EVENT_MOTION_NOTIFY
 mov eax,[rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
 mov [rel request+12],eax
 mov eax,[rel target_x]
 mov [rel request+24],ax
 mov eax,[rel target_y]
 mov [rel request+26],ax
 mov edx,36
 jmp write_request_length

; EDI is ButtonPress or ButtonRelease. XTEST injects primary button detail 1.
send_xtest_button:
 mov r11d,edi
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov al,[rel xtest_opcode]
 mov [rel request],al
 mov byte [rel request+1],XTEST_FAKE_INPUT
 mov word [rel request+2],9
 mov [rel request+4],r11b
 mov byte [rel request+5],1
 mov eax,[rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
 mov [rel request+12],eax
 mov edx,36
 jmp write_request_length

; A reply-producing request is an exact server barrier for the preceding
; XTEST injection on this connection. This prevents cross-connection action
; reordering in lifecycle stress without timing sleeps or opcode hardcoding.
sync_server:
 push r12
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],X11_OP_GET_INPUT_FOCUS
 mov word [rel request+2],1
 mov edx,4
 call write_request_length
 test eax,eax
 jnz .sync_done
 lea r12,[rel query_reply]
 mov r8d,32
.sync_read:
 mov eax,SYS_READ
 mov edi,[rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
 mov rsi,r12
 mov edx,r8d
 syscall
 test rax,rax
 js .sync_retry
 test rax,rax
 jz .sync_bad
 add r12,rax
 sub r8,rax
 jnz .sync_read
 cmp byte [rel query_reply],1
 jne .sync_bad
 xor eax,eax
 jmp .sync_done
.sync_retry:
 cmp rax,-4
 je .sync_read
.sync_bad:
 mov eax,1
.sync_done:
 pop r12
 ret

; EDI=event type, ESI=x, EDX=y.
send_pointer:
 push r12
 push r13
 sub rsp,8
 mov r12d,edi
 mov r13d,esi
 mov r11d,edx
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_SEND_EVENT
 mov word [rel request+2],11
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 cmp r12d,NEBO_X11_EVENT_MOTION_NOTIFY
 je .pointer_detail_ready
 mov byte [rel request+13],1
.pointer_detail_ready:
 or r12b,NEBO_X11_EVENT_SEND_EVENT_MASK
 mov [rel request+12],r12b
 mov eax,[rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
 mov [rel request+20],eax
 mov eax,[rel target_xid]
 mov [rel request+24],eax
 mov [rel request+32],r13w
 mov [rel request+34],r11w
 mov [rel request+36],r13w
 mov [rel request+38],r11w
 mov byte [rel request+42],1
 call write_request
 add rsp,8
 pop r13
 pop r12
 ret

; RDI=NUL-terminated bounded ASCII. Each key uses a direct core SendEvent pair.
send_text:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 xor ebx,ebx
.text_loop:
 cmp ebx,4096
 jae .text_fail
 movzx edi,byte [r12+rbx]
 test dil,dil
 jz .text_enter
 call ascii_key
 test eax,eax
 jz .text_fail
 mov r13d,eax
 mov r14d,edx
 mov edi,NEBO_X11_EVENT_KEY_PRESS
 mov esi,r13d
 mov edx,r14d
 call send_key
 test eax,eax
 jnz .text_fail
 mov edi,NEBO_X11_EVENT_KEY_RELEASE
 mov esi,r13d
 mov edx,r14d
 call send_key
 test eax,eax
 jnz .text_fail
 inc ebx
 jmp .text_loop
.text_enter:
 mov edi,NEBO_X11_KEYSYM_RETURN
 call keysym_key
 test eax,eax
 jz .text_fail
 mov r13d,eax
 mov r14d,edx
 mov edi,NEBO_X11_EVENT_KEY_PRESS
 mov esi,r13d
 mov edx,r14d
 call send_key
 test eax,eax
 jnz .text_fail
 mov edi,NEBO_X11_EVENT_KEY_RELEASE
 mov esi,r13d
 mov edx,r14d
 call send_key
 jmp .text_done
.text_fail:
 mov eax,1
.text_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; EDI=event type, ESI=keycode, EDX=native state.
send_key:
 push r12
 push r13
 sub rsp,8
 mov r12d,edi
 mov r13d,esi
 mov r11d,edx
 lea rdi,[rel request]
 xor eax,eax
 mov ecx,44
 cld
 rep stosb
 mov byte [rel request],NEBO_X11_OP_SEND_EVENT
 mov word [rel request+2],11
 mov eax,[rel target_xid]
 mov [rel request+4],eax
 mov dword [rel request+8],0
 or r12b,NEBO_X11_EVENT_SEND_EVENT_MASK
 mov [rel request+12],r12b
 mov [rel request+13],r13b
 mov eax,[rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
 mov [rel request+20],eax
 mov eax,[rel target_xid]
 mov [rel request+24],eax
 mov [rel request+40],r11w
 mov byte [rel request+42],1
 call write_request
 add rsp,8
 pop r13
 pop r12
 ret

write_request:
 mov edx,44
write_request_length:
 push r12
 sub rsp,8
 lea r12,[rel request]
.write_loop:
 mov eax,SYS_WRITE
 mov edi,[rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
 mov rsi,r12
 syscall
 test rax,rax
 js .write_retry
 test rax,rax
 jz .write_fail
 add r12,rax
 sub rdx,rax
 jnz .write_loop
 xor eax,eax
 jmp .write_done
.write_retry:
 cmp rax,-4
 je .write_loop
.write_fail:
 mov eax,1
.write_done:
 add rsp,8
 pop r12
 ret

; ASCII -> EAX keycode, EDX ShiftMask.  Resolve against the keymap captured by
; the direct adapter so injected text is independent of QWERTY/AZERTY layout.
ascii_key:
 movzx edi,dil
keysym_key:
 mov r8d,edi
 movzx ecx,byte [rel adapter+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET]
 movzx r10d,byte [rel adapter+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET]
.keymap_loop:
 cmp ecx,r10d
 ja .keymap_missing
 mov eax,ecx
 shl rax,3
 lea r9,[rel adapter+NEBO_X11_ADAPTER_KEYMAP_OFFSET]
 add r9,rax
 cmp dword [r9+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET],r8d
 je .keymap_unshifted
 cmp dword [r9+NEBO_X11_KEYMAP_ENTRY_SHIFTED_OFFSET],r8d
 je .keymap_shifted
 inc ecx
 jmp .keymap_loop
.keymap_unshifted:
 mov eax,ecx
 xor edx,edx
 ret
.keymap_shifted:
 mov eax,ecx
 mov edx,NEBO_X11_STATE_SHIFT
 ret
.keymap_missing:
 xor eax,eax
 xor edx,edx
 ret

section .text
parse_u32:
 mov r8,rdi
 xor eax,eax
 xor ecx,ecx
 cmp byte [r8],'0'
 jne .number_loop
 mov dl,[r8+1]
 or dl,32
 cmp dl,'x'
 jne .number_loop
 add r8,2
.number_loop:
 movzx edx,byte [r8]
 test dl,dl
 jz .number_done
 cmp ecx,8
 jae .number_bad
 push rax
 mov edi,edx
 call hex_nibble
 mov edx,eax
 pop rax
 test edx,edx
 js .number_bad
 shl eax,4
 or eax,edx
 inc r8
 inc ecx
 jmp .number_loop
.number_done:
 test ecx,ecx
 jz .number_bad
 ret
.number_bad:
 xor eax,eax
 ret

parse_hex:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 mov qword [r15],0
 xor ebx,ebx
.hex_loop:
 movzx edi,byte [r12]
 test dil,dil
 jz .hex_done
 movzx esi,byte [r12+1]
 test sil,sil
 jz .hex_bad
 call hex_nibble
 test eax,eax
 js .hex_bad
 shl eax,4
 mov r10d,eax
 mov edi,esi
 call hex_nibble
 test eax,eax
 js .hex_bad
 or eax,r10d
 cmp rbx,r14
 jae .hex_bad
 mov [r13+rbx],al
 inc rbx
 add r12,2
 jmp .hex_loop
.hex_done:
 test rbx,rbx
 jz .hex_bad
 mov [r15],rbx
 xor eax,eax
 jmp .hex_return
.hex_bad:
 mov eax,1
.hex_return:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

hex_nibble:
 movzx eax,dil
 cmp al,'0'
 jb .nibble_bad
 cmp al,'9'
 jbe .decimal
 or al,32
 cmp al,'a'
 jb .nibble_bad
 cmp al,'f'
 ja .nibble_bad
 sub al,'a'-10
 movzx eax,al
 ret
.decimal:
 sub al,'0'
 movzx eax,al
 ret
.nibble_bad:
 mov eax,-1
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
