; Nebo Assembly — MF052 native custom chrome and lifecycle contracts
bits 64
default rel

%include "runtime/console/chrome/window_chrome.inc"
%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_console_chrome_hit_test
extern nebo_console_chrome_action_for_region
extern nebo_console_chrome_render
extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_report
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern nebo_x11_adapter_normalize_event
extern nebo_x11_adapter_minimize_window
extern nebo_x11_adapter_maximize_window
extern nebo_x11_adapter_restore_window
extern nebo_x11_adapter_begin_window_drag
extern nebo_x11_adapter_begin_window_resize
extern nebo_x11_adapter_set_window_size
extern nebo_x11_adapter_request_close
extern neboc_host_process_exit

global _start

%define TEST_WIDTH 320
%define TEST_HEIGHT 200
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_SURFACE_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_SCRATCH_BYTES 65536
%define RESIZE_WIDTH 400
%define RESIZE_HEIGHT 240
%define SYS_WRITE 1

section .rodata align=8
auth_name: db "MIT-MAGIC-COOKIE-1"

section .bss align=64
report: resb NEBO_PLATFORM_REPORT_SIZE
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
normalized_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
raw_event: resb NEBO_X11_EVENT_SIZE
x11_config: resb NEBO_X11_CONFIG_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb TEST_SCRATCH_BYTES
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels: resb TEST_SURFACE_BYTES
socket_arg: resq 1
cookie_arg: resq 1
out_region: resd 1
out_action: resd 1
external_request: resb 64

section .text
_start:
    mov rax, [rsp]
    cmp rax, 4
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_usage
    cmp eax, 4
    ja test_usage
    mov r12, [rsp+24]
    mov [rel socket_arg], r12
    mov r12, [rsp+32]
    mov [rel cookie_arg], r12
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    jmp scenario_4

; NEBO-PLATFORM-NATIVE-005: deterministic chrome plus real minimize/restore.
scenario_1:
    call zero_live_state
    call init_surface
    lea rdi, [rel surface]
    mov esi, TEST_WIDTH
    mov edx, TEST_HEIGHT
    xor ecx, ecx
    call nebo_console_chrome_render
    test eax, eax
    jnz test_fail
    cmp dword [rel surface_pixels], NEBO_CHROME_COLOR_BORDER
    jne test_fail
    cmp dword [rel surface_pixels+(10*TEST_STRIDE)+(10*4)], NEBO_CHROME_COLOR_BACKGROUND
    jne test_fail
    cmp dword [rel surface_pixels+(18*TEST_STRIDE)+((TEST_WIDTH-NEBO_CHROME_CONTROLS_WIDTH_PX+8)*4)], NEBO_CHROME_COLOR_FOREGROUND
    jne test_fail
    cmp dword [rel surface_pixels+(9*TEST_STRIDE)+((TEST_WIDTH-19)*4)], NEBO_CHROME_COLOR_FOREGROUND
    jne test_fail
    cmp dword [rel surface_pixels+(40*TEST_STRIDE)+(10*4)], 0xff101010
    jne test_fail

    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_WIDTH-1
    xor ecx, ecx
    lea r8, [rel out_region]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_region], NEBO_CHROME_REGION_CLOSE
    jne test_fail
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, 10
    mov ecx, 10
    lea r8, [rel out_region]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_region], NEBO_CHROME_REGION_DRAG
    jne test_fail
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    xor edx, edx
    mov ecx, 100
    lea r8, [rel out_region]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_region], NEBO_CHROME_REGION_RESIZE_BORDER
    jne test_fail
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, 10
    mov ecx, 40
    lea r8, [rel out_region]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    cmp dword [rel out_region], NEBO_CHROME_REGION_CONTENT
    jne test_fail
    mov edi, NEBO_CHROME_REGION_MAXIMIZE_RESTORE
    xor esi, esi
    lea rdx, [rel out_action]
    call nebo_console_chrome_action_for_region
    test eax, eax
    jnz test_fail
    cmp dword [rel out_action], NEBO_CHROME_ACTION_MAXIMIZE
    jne test_fail
    mov edi, NEBO_CHROME_REGION_MAXIMIZE_RESTORE
    mov esi, NEBO_CHROME_WINDOW_FLAG_MAXIMIZED
    lea rdx, [rel out_action]
    call nebo_console_chrome_action_for_region
    test eax, eax
    jnz test_fail
    cmp dword [rel out_action], NEBO_CHROME_ACTION_RESTORE
    jne test_fail

    call live_init_window
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    call wait_for_event
    test eax, eax
    jnz test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_restore_window
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    call wait_for_event
    test eax, eax
    jnz test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz test_fail
    call live_destroy_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-PLATFORM-NATIVE-006: real maximize/restore and controlled resize.
scenario_2:
    call live_init_window
    test eax, eax
    jnz test_fail
    call drain_window_events
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_maximize_window
    test eax, eax
    jnz test_fail
    ; A pre-action ConfigureNotify must not complete the new maximize action.
    call verify_stale_configure_preserves_maximize
    test eax, eax
    jnz test_fail
    call wait_for_maximize_geometry
    test eax, eax
    jnz test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET], TEST_WIDTH
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET], TEST_HEIGHT
    jne test_fail
    call drain_window_events
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_restore_window
    test eax, eax
    jnz test_fail
    call wait_for_restore_geometry
    test eax, eax
    jnz test_fail
    call drain_window_events
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, RESIZE_WIDTH
    mov ecx, RESIZE_HEIGHT
    call nebo_x11_adapter_set_window_size
    test eax, eax
    jnz test_fail
    call wait_for_resize_geometry
    test eax, eax
    jnz test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], RESIZE_WIDTH
    jne test_fail
    cmp qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], RESIZE_HEIGHT
    jne test_fail
    ; Invalid drag/resize inputs are refused without touching native state.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    call nebo_x11_adapter_begin_window_drag
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    xor edx, edx
    xor ecx, ecx
    mov r8d, 8
    mov r9d, 1
    call nebo_x11_adapter_begin_window_resize
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jne test_fail
    call live_destroy_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-PLATFORM-NATIVE-007: close request enters the safe native pipeline.
scenario_3:
    call live_init_window
    test eax, eax
    jnz test_fail
    mov edi, TEST_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_WIDTH-1
    xor ecx, ecx
    lea r8, [rel out_region]
    call nebo_console_chrome_hit_test
    test eax, eax
    jnz test_fail
    mov edi, [rel out_region]
    xor esi, esi
    lea rdx, [rel out_action]
    call nebo_console_chrome_action_for_region
    test eax, eax
    jnz test_fail
    cmp dword [rel out_action], NEBO_CHROME_ACTION_CLOSE
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel normalized_event]
    call nebo_x11_adapter_request_close
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel normalized_event]
    call nebo_x11_adapter_request_close
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 0
    jne test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jne test_fail
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

; NPT-CONSOLE-WINDOW-STATE-001: reproduce the exact external WM transition
; without pointer input. The window is Iconic/Unmapped, then the same X11
; connection issues MapWindow followed by an EWMH maximize request without
; mutating the runtime pending/cache fields. The raw event path must converge
; on the queried WM state and leave the native controls immediately usable.
scenario_4:
    call live_init_window
    test eax, eax
    jnz test_fail
    call drain_window_events
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    call wait_for_event
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail
    call external_map_maximize
    test eax, eax
    jnz test_fail
    call wait_for_external_maximized
    test eax, eax
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne test_fail
    mov eax, [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET]
    and eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    cmp eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    jne test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz test_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne test_fail
    ; The immediately following minimize is the first formerly blocked
    ; control. It must be accepted without a move/configure workaround.
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_minimize_window
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    call wait_for_event
    test eax, eax
    jnz test_fail
    call live_destroy_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

external_map_maximize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    lea rbx, [rel external_request]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 8
    cld
    rep stosq
    mov byte [rbx], NEBO_X11_OP_MAP_WINDOW
    mov word [rbx+2], 2
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rbx+4], eax
    mov edi, [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 8
    call test_write_all
    test eax, eax
    jnz .external_action_done
    inc qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 8
    cld
    rep stosq
    mov byte [rbx], NEBO_X11_OP_SEND_EVENT
    mov word [rbx+2], 11
    mov eax, [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [rbx+4], eax
    mov dword [rbx+8], (NEBO_X11_EVENT_MASK_SUBSTRUCTURE_NOTIFY | NEBO_X11_EVENT_MASK_SUBSTRUCTURE_REDIRECT)
    mov byte [rbx+12], NEBO_X11_EVENT_CLIENT_MESSAGE
    mov byte [rbx+13], 32
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rbx+16], eax
    mov eax, [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_ATOM_OFFSET]
    mov [rbx+20], eax
    mov dword [rbx+24], NEBO_X11_NET_WM_STATE_ADD
    mov eax, [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_HORZ_ATOM_OFFSET]
    mov [rbx+28], eax
    mov eax, [rel adapter+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_VERT_ATOM_OFFSET]
    mov [rbx+32], eax
    mov dword [rbx+36], NEBO_X11_NET_WM_SOURCE_APPLICATION
    mov dword [rbx+40], 0
    mov edi, [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 44
    call test_write_all
    test eax, eax
    jnz .external_action_done
    inc qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    xor eax, eax
.external_action_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

wait_for_external_maximized:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d, 160
.external_wait_loop:
    lea rdi, [rel adapter]
    mov esi, 100
    lea rdx, [rel raw_event]
    call nebo_x11_adapter_poll_raw
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .external_wait_next
    test eax, eax
    jnz .external_wait_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw_event]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_normalize_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .external_check_state
    test eax, eax
    jnz .external_wait_fail
.external_check_state:
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .external_wait_next
    mov eax, [rel window+NEBO_X11_WINDOW_EWMH_STATE_FLAGS_OFFSET]
    and eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    cmp eax, NEBO_X11_WINDOW_EWMH_FLAG_MAXIMIZED
    jne .external_wait_next
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .external_wait_next
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    jne .external_wait_next
    xor eax, eax
    jmp .external_wait_done
.external_wait_next:
    dec r12d
    jnz .external_wait_loop
.external_wait_fail:
    mov eax, -1
.external_wait_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=fd, RSI=bytes, EDX=length.
test_write_all:
    mov r8, rsi
    mov r9, rdx
.test_write_loop:
    mov eax, SYS_WRITE
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .test_write_bad
    add r8, rax
    sub r9, rax
    jnz .test_write_loop
    xor eax, eax
    ret
.test_write_bad:
    mov eax, -1
    ret

; Initialize one authenticated live adapter/window and wait for MapNotify.
live_init_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    call zero_live_state
    mov r12, [rel socket_arg]
    mov r13, [rel cookie_arg]
    lea rdi, [rel socket_address]
    mov word [rdi], NEBO_LINUX_AF_UNIX
    lea rdi, [rdi+2]
    mov rsi, r12
    xor ecx, ecx
.copy_socket_path:
    cmp ecx, 107
    jae .live_fail
    mov al, [rsi+rcx]
    mov [rdi+rcx], al
    test al, al
    jz .socket_ready
    inc ecx
    jmp .copy_socket_path
.socket_ready:
    lea r14, [rcx+3]
    mov rdi, r13
    lea rsi, [rel auth_cookie]
    mov edx, NEBO_X11_MAX_AUTH_BYTES
    lea rcx, [rel auth_cookie_length]
    call parse_hex
    test eax, eax
    jnz .live_fail
    lea rdi, [rel x11_config]
    lea rax, [rel socket_address]
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET], rax
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET], r14
    lea rax, [rel auth_name]
    mov [rdi+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET], NEBO_X11_AUTH_NAME_LENGTH
    lea rax, [rel auth_cookie]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET], rax
    mov rax, [rel auth_cookie_length]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET], rax
    lea rax, [rel scratch]
    mov [rdi+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET], TEST_SCRATCH_BYTES
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF052_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    lea rsi, [rel x11_config]
    call nebo_x11_adapter_init
    test eax, eax
    jnz .live_fail
    lea rdi, [rel adapter]
    lea rsi, [rel report]
    call nebo_x11_adapter_report
    test eax, eax
    jnz .live_fail
    mov rax, [rel report+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET]
    and rax, NEBO_PLATFORM_MF052_REQUIRED_CAPABILITIES
    cmp rax, NEBO_PLATFORM_MF052_REQUIRED_CAPABILITIES
    jne .live_fail
    call init_surface
    lea rdi, [rel surface]
    mov esi, TEST_WIDTH
    mov edx, TEST_HEIGHT
    xor ecx, ecx
    call nebo_console_chrome_render
    test eax, eax
    jnz .live_fail
    lea rdi, [rel window_config]
    lea rax, [rel surface]
    mov [rdi+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel window_config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jnz .live_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    call wait_for_event
    test eax, eax
    jnz .live_fail
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz .live_fail
    xor eax, eax
    jmp .live_done
.live_fail:
    mov eax, -1
.live_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=expected event kind. Poll up to 80 * 100ms, ignoring unrelated events.
wait_for_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d, edi
    mov r13d, 80
.wait_loop:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .wait_next
    test eax, eax
    jnz .wait_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], r12d
    je .wait_ok
.wait_next:
    dec r13d
    jnz .wait_loop
.wait_fail:
    mov eax, -1
    jmp .wait_done
.wait_ok:
    xor eax, eax
.wait_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Drain already-queued native events before beginning a new WM action.
; This establishes a deterministic action boundary without discarding errors.
drain_window_events:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r13d, 128
.drain_loop:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    xor edx, edx
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .drain_ok
    test eax, eax
    jnz .drain_fail
    dec r13d
    jnz .drain_loop
.drain_fail:
    mov eax, -1
    jmp .drain_done
.drain_ok:
    xor eax, eax
.drain_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Inject one stale ConfigureNotify and prove it cannot consume the current
; maximize action. The real WM event remains pending on the socket.
verify_stale_configure_preserves_maximize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    lea rdi, [rel raw_event]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    cld
    rep stosq
    mov byte [rel raw_event], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov rax, [rel window+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET]
    dec ax
    mov word [rel raw_event+2], ax
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel raw_event+4], eax
    mov [rel raw_event+8], eax
    mov rax, [rel window+NEBO_X11_WINDOW_RESTORE_X_OFFSET]
    mov [rel raw_event+16], ax
    mov rax, [rel window+NEBO_X11_WINDOW_RESTORE_Y_OFFSET]
    mov [rel raw_event+18], ax
    mov rax, [rel window+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET]
    mov [rel raw_event+20], ax
    mov rax, [rel window+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET]
    mov [rel raw_event+22], ax
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw_event]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz .stale_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .stale_fail
    cmp dword [rel window+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    jne .stale_fail
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz .stale_fail
    xor eax, eax
    jmp .stale_done
.stale_fail:
    mov eax, -1
.stale_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Wait for both the normalized maximize event and the final larger geometry.
wait_for_maximize_geometry:
    push rbx
    push r12
    push r13
    push r14
    push r15
    xor r12d, r12d
    mov r13d, 120
.max_wait_loop:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .max_wait_next
    test eax, eax
    jnz .max_wait_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jne .max_check_geometry
    mov r12d, 1
.max_check_geometry:
    test r12d, r12d
    jz .max_wait_next
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .max_wait_next
    mov rax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    cmp rax, [rel window+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET]
    ja .max_wait_ok
    mov rax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    cmp rax, [rel window+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET]
    ja .max_wait_ok
.max_wait_next:
    dec r13d
    jnz .max_wait_loop
.max_wait_fail:
    mov eax, -1
    jmp .max_wait_done
.max_wait_ok:
    xor eax, eax
.max_wait_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Wait for a normalized restore event, then continue through any intermediate
; ConfigureNotify records until the saved pre-maximize geometry is restored.
wait_for_restore_geometry:
    push rbx
    push r12
    push r13
    push r14
    push r15
    xor r12d, r12d
    mov r13d, 120
.restore_wait_loop:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .restore_wait_next
    test eax, eax
    jnz .restore_wait_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    jne .restore_check_geometry
    mov r12d, 1
.restore_check_geometry:
    test r12d, r12d
    jz .restore_wait_next
    test dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jnz .restore_wait_next
    mov rax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    cmp rax, [rel window+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET]
    jne .restore_wait_next
    mov rax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    cmp rax, [rel window+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET]
    je .restore_wait_ok
.restore_wait_next:
    dec r13d
    jnz .restore_wait_loop
.restore_wait_fail:
    mov eax, -1
    jmp .restore_wait_done
.restore_wait_ok:
    xor eax, eax
.restore_wait_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Wait for the ConfigureNotify that commits the requested 400x240 geometry.
; A resize event must be observed, but later intermediate records are tolerated.
wait_for_resize_geometry:
    push rbx
    push r12
    push r13
    push r14
    push r15
    xor r12d, r12d
    mov r13d, 120
.resize_wait_loop:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .resize_wait_next
    test eax, eax
    jnz .resize_wait_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne .resize_check_geometry
    mov r12d, 1
.resize_check_geometry:
    test r12d, r12d
    jz .resize_wait_next
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], RESIZE_WIDTH
    jne .resize_wait_next
    cmp qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], RESIZE_HEIGHT
    je .resize_wait_ok
.resize_wait_next:
    dec r13d
    jnz .resize_wait_loop
.resize_wait_fail:
    mov eax, -1
    jmp .resize_wait_done
.resize_wait_ok:
    xor eax, eax
.resize_wait_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

live_destroy_shutdown:
    push r12
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .cleanup_done
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
.cleanup_done:
    pop r12
    ret

zero_live_state:
    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel x11_config]
    mov ecx, NEBO_X11_CONFIG_QWORDS
    rep stosq
    lea rdi, [rel window_config]
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    rep stosq
    lea rdi, [rel report]
    mov ecx, NEBO_PLATFORM_REPORT_QWORDS
    rep stosq
    lea rdi, [rel normalized_event]
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    rep stosq
    lea rdi, [rel raw_event]
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    lea rdi, [rel surface]
    mov ecx, NEBO_SOFTWARE_SURFACE_QWORDS
    rep stosq
    ret

init_surface:
    lea rax, [rel surface_pixels]
    mov [rel surface+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], rax
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], TEST_SURFACE_BYTES
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], TEST_STRIDE
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], 1
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET], NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    lea rdi, [rel surface_pixels]
    mov eax, 0xff101010
    mov ecx, TEST_SURFACE_BYTES/4
    cld
    rep stosd
    ret

; parse_hex(input, out, capacity, out_length*)
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

test_pass:
    xor edi, edi
    call neboc_host_process_exit
    ud2

test_usage:
    mov edi, 64
    call neboc_host_process_exit
    ud2

test_fail:
    mov edi, 1
    call neboc_host_process_exit
    ud2
