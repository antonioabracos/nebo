; NPT-CONSOLE-RESIZE-R2 real-server cursor resource oracle.
; argv[1]=AF_UNIX socket path, argv[2]=MIT-MAGIC-COOKIE-1 hex.
; This test creates one bounded X11 window and changes its cursor through the
; adapter API.  It never synthesizes input and never controls the pointer.
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/chrome/window_chrome.inc"

extern nebo_x11_adapter_init
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_set_resize_cursor
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_shutdown

global _start

%define SYS_READ 0
%define SYS_WRITE 1
%define SYS_EXIT 60
%define LIVE_WIDTH 320
%define LIVE_HEIGHT 180
%define LIVE_SCRATCH_BYTES 65536

section .rodata
auth_name: db "MIT-MAGIC-COOKIE-1"

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
config: resb NEBO_X11_CONFIG_SIZE
window: resb NEBO_X11_WINDOW_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb LIVE_SCRATCH_BYTES
sync_message: resb NEBO_X11_EVENT_SIZE
failure_code: resd 1
window_created: resd 1

section .text
_start:
    mov dword [rel failure_code], 1
    cmp qword [rsp], 3
    jne .usage
    mov r12, [rsp+16]
    mov r13, [rsp+24]

    lea rdi, [rel socket_address]
    mov word [rdi], NEBO_LINUX_AF_UNIX
    lea rdi, [rdi+2]
    xor ecx, ecx
.copy_socket:
    cmp ecx, 107
    jae .fail
    mov al, [r12+rcx]
    mov [rdi+rcx], al
    test al, al
    jz .socket_ready
    inc ecx
    jmp .copy_socket
.socket_ready:
    lea r14, [rcx+3]

    mov rdi, r13
    lea rsi, [rel auth_cookie]
    mov edx, NEBO_X11_MAX_AUTH_BYTES
    lea rcx, [rel auth_cookie_length]
    call parse_hex
    test eax, eax
    jnz .fail

    lea rdi, [rel config]
    xor eax, eax
    mov ecx, NEBO_X11_CONFIG_QWORDS
    cld
    rep stosq
    lea rax, [rel socket_address]
    mov [rel config+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET], rax
    mov [rel config+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET], r14
    lea rax, [rel auth_name]
    mov [rel config+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET], rax
    mov qword [rel config+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET], NEBO_X11_AUTH_NAME_LENGTH
    lea rax, [rel auth_cookie]
    mov [rel config+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET], rax
    mov rax, [rel auth_cookie_length]
    mov [rel config+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET], rax
    lea rax, [rel scratch]
    mov [rel config+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET], rax
    mov qword [rel config+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET], LIVE_SCRATCH_BYTES
    mov qword [rel config+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [rel config+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS

    mov dword [rel failure_code], 2
    lea rdi, [rel adapter]
    lea rsi, [rel config]
    call nebo_x11_adapter_init
    test eax, eax
    jnz .init_fail

    lea rdi, [rel window_config]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    rep stosq
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], LIVE_WIDTH
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], LIVE_HEIGHT
    mov dword [rel window_config+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], (NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS | NEBO_X11_WINDOW_CONFIG_FLAG_DEFER_MAP | NEBO_X11_WINDOW_CONFIG_FLAG_NO_SURFACE)
    mov dword [rel failure_code], 3
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel window_config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jnz .shutdown_fail
    mov dword [rel window_created], 1

    mov dword [rel failure_code], 4
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    mov ecx, NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    call nebo_x11_adapter_set_window_minimum_size
    test eax, eax
    jnz .destroy_fail
    cmp qword [rel window+NEBO_X11_WINDOW_MINIMUM_WIDTH_OFFSET], NEBO_CHROME_MIN_WINDOW_WIDTH_PX
    jne .destroy_fail
    cmp qword [rel window+NEBO_X11_WINDOW_MINIMUM_HEIGHT_OFFSET], NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
    jne .destroy_fail

    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_map_window
    test eax, eax
    jnz .destroy_fail

    mov dword [rel failure_code], 5
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_HORIZONTAL
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .destroy_fail
    mov eax, [rel adapter+NEBO_X11_ADAPTER_CURSOR_HORIZONTAL_XID_OFFSET]
    test eax, eax
    jz .destroy_fail
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_RESOURCE_STATE_OFFSET], NEBO_X11_CURSOR_RESOURCE_STATE_READY
    jne .destroy_fail

    mov dword [rel failure_code], 6
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_VERTICAL
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .destroy_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_NWSE
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .destroy_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_NESW
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .destroy_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, NEBO_X11_CURSOR_KIND_DEFAULT
    call nebo_x11_adapter_set_resize_cursor
    test eax, eax
    jnz .destroy_fail
    cmp dword [rel window+NEBO_X11_WINDOW_CURSOR_KIND_OFFSET], NEBO_X11_CURSOR_KIND_DEFAULT
    jne .destroy_fail

    ; GetInputFocus is used only as a protocol round-trip barrier.  Any X11
    ; error generated by window/cursor creation or ChangeWindowAttributes is
    ; observed before its reply.  No input state is changed.
    mov dword [rel failure_code], 7
    lea rdi, [rel adapter]
    call sync_server
    test eax, eax
    jnz .destroy_fail

    mov dword [rel failure_code], 8
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .shutdown_fail
    mov dword [rel window_created], 0
    lea rdi, [rel adapter]
    call sync_server
    test eax, eax
    jnz .shutdown_fail

    mov dword [rel failure_code], 9
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    test eax, eax
    jnz .fail
    cmp dword [rel adapter+NEBO_X11_ADAPTER_CURSOR_RESOURCE_STATE_OFFSET], NEBO_X11_CURSOR_RESOURCE_STATE_EMPTY
    jne .fail
    xor edi, edi
    jmp .exit

.destroy_fail:
    cmp dword [rel window_created], 0
    je .shutdown_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    mov dword [rel window_created], 0
.shutdown_fail:
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    jmp .fail
.init_fail:
    mov edi, [rel adapter+NEBO_X11_ADAPTER_LAST_ERROR_OFFSET]
    add edi, 32
    jmp .exit
.fail:
    mov edi, [rel failure_code]
    test edi, edi
    jnz .exit
    mov edi, 1
    jmp .exit
.usage:
    mov edi, 64
.exit:
    mov eax, SYS_EXIT
    syscall
    ud2

; GetInputFocus round-trip barrier. RDI=adapter*. Returns 0 only when the
; matching reply arrives without any preceding core-protocol error.
sync_server:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13d, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    lea r14, [rel sync_message]
    mov dword [r14], 0x0001002b
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov r15w, [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov edi, r13d
    mov rsi, r14
    mov edx, 4
    call write_exact
    test eax, eax
    jnz .sync_fail
    mov ebx, 64
.sync_read:
    mov edi, r13d
    mov rsi, r14
    mov edx, NEBO_X11_EVENT_SIZE
    call read_exact
    test eax, eax
    jnz .sync_fail
    cmp byte [r14], NEBO_X11_EVENT_ERROR
    je .sync_fail
    cmp byte [r14], 1
    jne .sync_next
    cmp word [r14+2], r15w
    jne .sync_fail
    xor eax, eax
    jmp .sync_done
.sync_next:
    dec ebx
    jnz .sync_read
.sync_fail:
    mov eax, 1
.sync_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=fd, RSI=buffer, EDX=exact byte count.
write_exact:
    mov r8, rsi
    mov r9d, edx
.write_loop:
    mov eax, SYS_WRITE
    mov rsi, r8
    mov edx, r9d
    syscall
    test rax, rax
    jle .write_fail
    add r8, rax
    sub r9, rax
    jnz .write_loop
    xor eax, eax
    ret
.write_fail:
    mov eax, 1
    ret

; EDI=fd, RSI=buffer, EDX=exact byte count.
read_exact:
    mov r8, rsi
    mov r9d, edx
.read_loop:
    mov eax, SYS_READ
    mov rsi, r8
    mov edx, r9d
    syscall
    test rax, rax
    jle .read_fail
    add r8, rax
    sub r9, rax
    jnz .read_loop
    xor eax, eax
    ret
.read_fail:
    mov eax, 1
    ret

; parse_hex(input, out, capacity, out_length*).
parse_hex:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    test r12, r12
    jz .hex_invalid
    test r13, r13
    jz .hex_invalid
    test r15, r15
    jz .hex_invalid
    mov qword [r15], 0
    xor ebx, ebx
.hex_loop:
    movzx edi, byte [r12]
    test dil, dil
    jz .hex_done
    movzx esi, byte [r12+1]
    test sil, sil
    jz .hex_invalid
    call hex_nibble
    test eax, eax
    js .hex_invalid
    shl eax, 4
    mov r10d, eax
    mov edi, esi
    call hex_nibble
    test eax, eax
    js .hex_invalid
    or eax, r10d
    cmp rbx, r14
    jae .hex_invalid
    mov [r13+rbx], al
    inc rbx
    add r12, 2
    jmp .hex_loop
.hex_done:
    test rbx, rbx
    jz .hex_invalid
    mov [r15], rbx
    xor eax, eax
    jmp .hex_return
.hex_invalid:
    mov eax, -1
.hex_return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hex_nibble:
    movzx eax, dil
    cmp al, '0'
    jb .nibble_bad
    cmp al, '9'
    jbe .nibble_decimal
    or al, 0x20
    cmp al, 'a'
    jb .nibble_bad
    cmp al, 'f'
    ja .nibble_bad
    sub al, 'a'-10
    movzx eax, al
    ret
.nibble_decimal:
    sub al, '0'
    movzx eax, al
    ret
.nibble_bad:
    mov eax, -1
    ret
