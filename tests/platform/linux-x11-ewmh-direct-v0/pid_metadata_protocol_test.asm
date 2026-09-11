; Bounded wire oracle for canonical _NET_WM_PID publication.
bits 64
default rel

%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_report_init
extern nebo_x11_adapter_create_window
extern neboc_host_process_exit

global _start

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_GETPID 39
%define SYS_SOCKETPAIR 53
%define AF_UNIX 1
%define SOCK_STREAM 1
%define WIRE_BYTES 124
%define WM_PROTOCOLS_OFFSET 60
%define NET_WM_PID_OFFSET 88
%define MAP_WINDOW_OFFSET 116
%define TEST_WM_PROTOCOLS_ATOM 0x301
%define TEST_WM_DELETE_ATOM 0x302
%define TEST_NET_WM_PID_ATOM 0x303

section .bss align=16
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
scratch: resb 256
wire: resb WIRE_BYTES
sockets: resd 2
expected_pid: resd 1

section .text
_start:
    mov eax, SYS_SOCKETPAIR
    mov edi, AF_UNIX
    mov esi, SOCK_STREAM
    xor edx, edx
    lea r10, [rel sockets]
    syscall
    test rax, rax
    js test_fail

    mov eax, SYS_GETPID
    syscall
    mov [rel expected_pid], eax

    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    mov eax, [rel sockets]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [rel adapter+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [rel adapter+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_BASE_OFFSET], 0x10000000
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET], 0x000fffff
    mov dword [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET], 0x100
    mov dword [rel adapter+NEBO_X11_ADAPTER_ROOT_VISUAL_OFFSET], 0x20
    mov byte [rel adapter+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET], 24
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    mov qword [rel adapter+NEBO_X11_ADAPTER_NEXT_WINDOW_SLOT_OFFSET], 1
    mov qword [rel adapter+NEBO_X11_ADAPTER_NEXT_WINDOW_GENERATION_OFFSET], 1
    lea rax, [rel scratch]
    mov [rel adapter+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], 256
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET], TEST_WM_PROTOCOLS_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET], TEST_WM_DELETE_ATOM
    mov dword [rel adapter+NEBO_X11_ADAPTER_NET_WM_PID_ATOM_OFFSET], TEST_NET_WM_PID_ATOM

    lea rdi, [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz test_fail

    lea rdi, [rel window_config]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    cld
    rep stosq
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], 320
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], 200
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], (NEBO_X11_WINDOW_CONFIG_FLAG_MANAGED | NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS | NEBO_X11_WINDOW_CONFIG_FLAG_NO_SURFACE)
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel window_config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jnz test_fail

    mov edi, [rel sockets+4]
    lea rsi, [rel wire]
    mov edx, WIRE_BYTES
    call read_exact
    test eax, eax
    jnz test_fail

    cmp byte [rel wire+WM_PROTOCOLS_OFFSET], NEBO_X11_OP_CHANGE_PROPERTY
    jne test_fail
    cmp byte [rel wire+NET_WM_PID_OFFSET], NEBO_X11_OP_CHANGE_PROPERTY
    jne test_fail
    cmp byte [rel wire+NET_WM_PID_OFFSET+1], NEBO_X11_PROP_MODE_REPLACE
    jne test_fail
    cmp word [rel wire+NET_WM_PID_OFFSET+2], 7
    jne test_fail
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    cmp [rel wire+NET_WM_PID_OFFSET+4], eax
    jne test_fail
    cmp dword [rel wire+NET_WM_PID_OFFSET+8], TEST_NET_WM_PID_ATOM
    jne test_fail
    cmp dword [rel wire+NET_WM_PID_OFFSET+12], NEBO_X11_ATOM_CARDINAL
    jne test_fail
    cmp byte [rel wire+NET_WM_PID_OFFSET+16], 32
    jne test_fail
    cmp dword [rel wire+NET_WM_PID_OFFSET+20], 1
    jne test_fail
    mov eax, [rel expected_pid]
    cmp [rel wire+NET_WM_PID_OFFSET+24], eax
    jne test_fail
    cmp byte [rel wire+MAP_WINDOW_OFFSET], NEBO_X11_OP_MAP_WINDOW
    jne test_fail
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    cmp [rel wire+MAP_WINDOW_OFFSET+4], eax
    jne test_fail
    cmp qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET], 5
    jne test_fail
    jmp test_pass

read_exact:
    mov r8, rsi
    mov r9, rdx
.loop:
    mov eax, SYS_READ
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jle .fail
    add r8, rax
    sub r9, rax
    jnz .loop
    xor eax, eax
    ret
.fail:
    mov eax, 1
    ret

close_sockets:
    mov eax, SYS_CLOSE
    mov edi, [rel sockets]
    syscall
    mov eax, SYS_CLOSE
    mov edi, [rel sockets+4]
    syscall
    ret

test_pass:
    call close_sockets
    xor edi, edi
    call neboc_host_process_exit
    ud2

test_fail:
    call close_sockets
    mov edi, 1
    call neboc_host_process_exit
    ud2
