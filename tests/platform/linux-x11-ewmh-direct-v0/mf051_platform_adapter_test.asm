; Nebo Assembly — MF051 direct X11 Platform Adapter contracts
bits 64
default rel

%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_capabilities_certify
extern nebo_platform_window_handle_make
extern nebo_platform_window_handle_validate
extern nebo_platform_report_init
extern nebo_platform_report_certify
extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_report
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern nebo_x11_adapter_normalize_event
extern neboc_host_process_exit

global _start

%define TEST_WIDTH 320
%define TEST_HEIGHT 200
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_SURFACE_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_SCRATCH_BYTES 65536

section .rodata align=8
auth_name: db "MIT-MAGIC-COOKIE-1"

section .bss align=64
report_a: resb NEBO_PLATFORM_REPORT_SIZE
report_b: resb NEBO_PLATFORM_REPORT_SIZE
missing_caps: resq 1
opaque_handle: resq 1
out_slot: resd 1
out_generation: resd 1
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
raw_event: resb NEBO_X11_EVENT_SIZE
normalized_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
x11_config: resb NEBO_X11_CONFIG_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb TEST_SCRATCH_BYTES
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels: resb TEST_SURFACE_BYTES
sleep_spec: resq 2

section .text
_start:
    mov rax, [rsp]
    cmp rax, 2
    jb test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_usage
    cmp eax, 5
    ja test_usage
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    cmp eax, 4
    je scenario_4
    jmp scenario_5

; Required capabilities and pointer-free adapter report certify.
scenario_1:
    lea rdi, [rel report_a]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel report_a]
    call nebo_platform_report_certify
    test eax, eax
    jnz test_fail
    cmp qword [rel report_a+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    jne test_fail
    cmp qword [rel report_a+NEBO_PLATFORM_REPORT_MISSING_CAPABILITIES_OFFSET], 0
    jne test_fail
    cmp qword [rel report_a+NEBO_PLATFORM_REPORT_NATIVE_HANDLE_LEAKS_OFFSET], 0
    jne test_fail
    jmp test_pass

; X11 Map/Configure/ClientMessage events normalize to the common event model.
scenario_2:
    call zero_adapter_window_events
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET], 100
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET], 101
    lea rax, [rel adapter]
    mov [rel window+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], 0x12345678
    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_HEIGHT
    mov edi, 7
    mov esi, 9
    lea rdx, [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    call nebo_platform_window_handle_make
    test eax, eax
    jnz test_fail
    mov byte [rel raw_event], NEBO_X11_EVENT_MAP_NOTIFY
    mov dword [rel raw_event+8], 0x12345678
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw_event]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne test_fail
    mov rax, [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    cmp [rel normalized_event+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
    jne test_fail
    lea rdi, [rel raw_event]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    cld
    rep stosq
    mov byte [rel raw_event], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw_event+8], 0x12345678
    mov word [rel raw_event+20], 800
    mov word [rel raw_event+22], 600
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw_event]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail
    cmp qword [rel normalized_event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], 800
    jne test_fail
    cmp qword [rel normalized_event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], 600
    jne test_fail
    lea rdi, [rel raw_event]
    xor eax, eax
    mov ecx, NEBO_X11_EVENT_SIZE/8
    cld
    rep stosq
    mov byte [rel raw_event], NEBO_X11_EVENT_CLIENT_MESSAGE
    mov byte [rel raw_event+1], 32
    mov dword [rel raw_event+4], 0x12345678
    mov dword [rel raw_event+8], 100
    mov dword [rel raw_event+12], 101
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel raw_event]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_normalize_event
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jne test_fail
    jmp test_pass

; Opaque handle contains only slot/generation and never equals the native XID.
scenario_3:
    mov edi, 17
    mov esi, 23
    lea rdx, [rel opaque_handle]
    call nebo_platform_window_handle_make
    test eax, eax
    jnz test_fail
    mov rdi, [rel opaque_handle]
    lea rsi, [rel out_slot]
    lea rdx, [rel out_generation]
    call nebo_platform_window_handle_validate
    test eax, eax
    jnz test_fail
    cmp dword [rel out_slot], 17
    jne test_fail
    cmp dword [rel out_generation], 23
    jne test_fail
    cmp qword [rel opaque_handle], 0x00abcdef
    je test_fail
    mov qword [rel report_a+NEBO_PLATFORM_REPORT_NATIVE_HANDLE_LEAKS_OFFSET], 0
    jmp test_pass

; Live direct-X11 smoke: setup/auth, managed decorationless window, BGRA surface,
; normalized MapNotify, PutImage presentation, destroy and shutdown.
scenario_4:
    cmp qword [rsp], 4
    jne test_usage
    call zero_live_state
    mov r12, [rsp+24]
    mov r13, [rsp+32]
    lea rdi, [rel socket_address]
    mov word [rdi], NEBO_LINUX_AF_UNIX
    lea rdi, [rdi+2]
    mov rsi, r12
    xor ecx, ecx
.copy_socket_path:
    cmp ecx, 107
    jae test_fail
    mov al, [rsi+rcx]
    mov [rdi+rcx], al
    test al, al
    jz .socket_path_ready
    inc ecx
    jmp .copy_socket_path
.socket_path_ready:
    lea r14, [rcx+3]
    mov rdi, r13
    lea rsi, [rel auth_cookie]
    mov edx, NEBO_X11_MAX_AUTH_BYTES
    lea rcx, [rel auth_cookie_length]
    call parse_hex
    test eax, eax
    jnz test_fail
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
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    lea rsi, [rel x11_config]
    call nebo_x11_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    lea rsi, [rel report_b]
    call nebo_x11_adapter_report
    test eax, eax
    jnz test_fail
    mov rax, [rel report_b+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET]
    and rax, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    cmp rax, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    jne test_fail
    cmp qword [rel report_b+NEBO_PLATFORM_REPORT_NATIVE_HANDLE_LEAKS_OFFSET], 0
    jne test_fail
    call init_surface
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
    jnz test_fail
    mov eax, [rel window+NEBO_X11_WINDOW_FLAGS_OFFSET]
    and eax, NEBO_X11_WINDOW_REQUIRED_FLAGS
    cmp eax, NEBO_X11_WINDOW_REQUIRED_FLAGS
    jne test_fail
    cmp dword [rel window+NEBO_X11_WINDOW_XID_OFFSET], 0
    je test_fail
    mov rax, [rel window+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    mov edx, dword [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    cmp rax, rdx
    je test_fail
    mov r12d, 40
.wait_for_map:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .map_next
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    je .mapped
.map_next:
    dec r12d
    jnz .wait_for_map
    jmp test_fail
.mapped:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz test_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
    jne test_fail
    mov qword [rel sleep_spec], 0
    mov qword [rel sleep_spec+8], 250000000
    mov eax, NEBO_LINUX_SYS_NANOSLEEP
    lea rdi, [rel sleep_spec]
    xor esi, esi
    syscall
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz test_fail
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

; Missing required capability explicitly refuses platform certification.
scenario_5:
    mov rdi, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    and rdi, ~NEBO_PLATFORM_CAP_CUSTOM_CHROME_HINTS
    mov rsi, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    lea rdx, [rel missing_caps]
    call nebo_platform_capabilities_certify
    cmp eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jne test_fail
    cmp qword [rel missing_caps], NEBO_PLATFORM_CAP_CUSTOM_CHROME_HINTS
    jne test_fail
    jmp test_pass

zero_adapter_window_events:
    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel raw_event]
    mov ecx, NEBO_X11_EVENT_SIZE/8
    rep stosq
    lea rdi, [rel normalized_event]
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    rep stosq
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

; input character in DIL, returns nibble or -1.
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
