; CONTROLO-DE-FLUXO-ESTRUTURADO-F05 optional live direct-X11 Window smoke.
; argv[1]=AF_UNIX socket path, argv[2]=MIT-MAGIC-COOKIE-1 hex.
bits 64
default rel
%include "runtime/window/x11/x11_window.inc"

%define LIVE_WIDTH 480
%define LIVE_HEIGHT 320
%define LIVE_RESIZED_WIDTH 640
%define LIVE_RESIZED_HEIGHT 360
%define LIVE_OWNER 0x5246323747313846
%define LIVE_SCRATCH_BYTES 65536
%define LIVE_EVENT_CAPACITY 64
%define LIVE_EVENT_MASK_REQUIRED 0x1f

section .rodata align=8
auth_name: db "MIT-MAGIC-COOKIE-1"
live_title: db "Nebo X11 F05"
live_title_end:
live_title_next: db "Nebo X11 bounded"
live_title_next_end:

section .bss align=64
live_runtime: resb NEBO_X11_RUNTIME_SIZE
live_records: resb NEBO_WINDOW_SIZE
live_native_records: resb NEBO_X11_WINDOW_SIZE
live_adapter: resb NEBO_X11_ADAPTER_SIZE
live_x11_config: resb NEBO_X11_CONFIG_SIZE
live_socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
live_auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
live_auth_cookie_length: resq 1
live_scratch: resb LIVE_SCRATCH_BYTES
live_options: resb NEBO_WINDOW_OPTIONS_SIZE
live_title_storage: resb 256
live_event_storage: resb NEBO_WINDOW_EVENT_SIZE*LIVE_EVENT_CAPACITY
live_scheduler_budget: resb NEBO_SCHEDULER_BUDGET_SIZE
live_task_group: resb NEBO_TASK_GROUP_SIZE
live_task_storage: resb nebo_concurrency_contract_TASK_SIZE
live_cancel_budget: resb NEBO_CANCELLATION_BUDGET_SIZE
live_cancel_token: resb NEBO_CANCELLATION_TOKEN_SIZE
live_stream: resb NEBO_HEADLESS_STREAM_SIZE
live_event: resb NEBO_WINDOW_EVENT_SIZE
live_handle: resq 1
live_sleep_spec: resq 2

section .text
global _start
_start:
    mov rax, [rsp]
    cmp rax, 3
    jne .usage
    mov r12, [rsp+16]
    mov r13, [rsp+24]

    ; Resolve the local socket argument into sockaddr_un storage.
    lea rdi, [rel live_socket_address]
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
    lea rsi, [rel live_auth_cookie]
    mov edx, NEBO_X11_MAX_AUTH_BYTES
    lea rcx, [rel live_auth_cookie_length]
    call parse_hex
    test eax, eax
    jnz .fail

    lea rdi, [rel live_scheduler_budget]
    mov esi, 1
    mov edx, 1
    mov ecx, 1
    mov r8d, 4
    mov r9d, 16
    call nebo_scheduler_budget_init
    test eax, eax
    jnz .fail
    lea rdi, [rel live_task_group]
    lea rsi, [rel live_scheduler_budget]
    lea rdx, [rel live_task_storage]
    mov ecx, 1
    call nebo_task_group_init
    test eax, eax
    jnz .fail
    lea rdi, [rel live_cancel_budget]
    mov esi, 1
    mov edx, 1
    mov ecx, 1000000000
    call nebo_cancellation_budget_init
    test eax, eax
    jnz .fail
    lea rdi, [rel live_cancel_token]
    lea rsi, [rel live_cancel_budget]
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    xor r9d, r9d
    call nebo_cancellation_token_init
    test eax, eax
    jnz .fail

    ; Caller-owned direct-X11 runtime configuration.
    lea rdi, [rel live_x11_config]
    lea rax, [rel live_socket_address]
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET], rax
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET], r14
    lea rax, [rel auth_name]
    mov [rdi+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET], NEBO_X11_AUTH_NAME_LENGTH
    lea rax, [rel live_auth_cookie]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET], rax
    mov rax, [rel live_auth_cookie_length]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET], rax
    lea rax, [rel live_scratch]
    mov [rdi+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET], LIVE_SCRATCH_BYTES
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS

    lea rdi, [rel live_runtime]
    lea rsi, [rel live_records]
    lea rdx, [rel live_native_records]
    mov ecx, 1
    lea r8, [rel live_adapter]
    lea r9, [rel live_x11_config]
    call nebo_x11_runtime_init
    test eax, eax
    jnz .fail

    lea rdi, [rel live_options]
    mov ecx, NEBO_WINDOW_OPTIONS_QWORDS
    xor eax, eax
    cld
    rep stosq
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET], LIVE_WIDTH
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET], LIVE_HEIGHT
    lea rax, [rel live_title]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET], rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET], live_title_end-live_title
    lea rax, [rel live_title_storage]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET], rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET], 256
    lea rax, [rel live_event_storage]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET], rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET], LIVE_EVENT_CAPACITY
    lea rax, [rel live_cancel_token]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET], rax
    lea rax, [rel live_task_group]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET], rax
    mov dword [rel live_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    mov dword [rel live_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET], (NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED | NEBO_WINDOW_OPTION_TEXT_INPUT | NEBO_WINDOW_OPTION_CLOSE_PREVENTABLE)
    mov rax, LIVE_OWNER
    mov [rel live_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET], rax

    lea rdi, [rel live_runtime]
    lea rsi, [rel live_options]
    lea rdx, [rel live_handle]
    call nebo_x11_window_create
    test eax, eax
    jnz .fail
    cmp qword [rel live_handle], 0
    je .fail
    mov eax, [rel live_native_records+NEBO_X11_WINDOW_XID_OFFSET]
    test eax, eax
    jz .fail
    mov rdx, [rel live_handle]
    cmp rax, rdx
    je .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    lea rcx, [rel live_stream]
    call nebo_x11_window_events
    test eax, eax
    jnz .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_show
    test eax, eax
    jnz .fail
    cmp dword [rel live_records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_VISIBLE
    jne .fail
    cmp dword [rel live_native_records+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    lea rcx, [rel live_title_next]
    mov r8d, live_title_next_end-live_title_next
    call nebo_x11_window_set_title
    test eax, eax
    jnz .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    mov ecx, LIVE_RESIZED_WIDTH
    mov r8d, LIVE_RESIZED_HEIGHT
    call nebo_x11_window_resize
    test eax, eax
    jnz .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_hide
    test eax, eax
    jnz .fail
    cmp dword [rel live_records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_HIDDEN
    jne .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_show
    test eax, eax
    jnz .fail

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_request_redraw
    test eax, eax
    jnz .fail

    ; Leave the mapped window visible briefly; timeout remains external.
    mov qword [rel live_sleep_spec], 0
    mov qword [rel live_sleep_spec+8], 100000000
    mov eax, NEBO_LINUX_SYS_NANOSLEEP
    lea rdi, [rel live_sleep_spec]
    xor esi, esi
    syscall

    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_close
    test eax, eax
    jnz .fail

    ; Drain the bounded typed stream and prove lifecycle evidence.
    xor r14d, r14d
    mov r15d, 128
.drain:
    lea rdi, [rel live_stream]
    lea rsi, [rel live_event]
    call nebo_x11_event_stream_poll
    test eax, eax
    jnz .fail
    test edx, edx
    jz .drained
    mov eax, [rel live_event+NEBO_WINDOW_EVENT_KIND_OFFSET]
    cmp eax, NEBO_WINDOW_EVENT_CREATED
    jne .not_created
    or r14d, 1
.not_created:
    cmp eax, NEBO_WINDOW_EVENT_SHOWN
    jne .not_shown
    or r14d, 2
.not_shown:
    cmp eax, NEBO_WINDOW_EVENT_HIDDEN
    jne .not_hidden
    or r14d, 4
.not_hidden:
    cmp eax, NEBO_WINDOW_EVENT_RESIZED
    jne .not_resized
    or r14d, 8
.not_resized:
    cmp eax, NEBO_WINDOW_EVENT_CLOSED
    jne .not_closed
    or r14d, 16
.not_closed:
    dec r15d
    jnz .drain
    jmp .fail
.drained:
    cmp r14d, LIVE_EVENT_MASK_REQUIRED
    jne .fail

    lea rdi, [rel live_stream]
    call nebo_x11_event_stream_release
    test eax, eax
    jnz .fail
    lea rdi, [rel live_runtime]
    mov rsi, [rel live_handle]
    mov rdx, LIVE_OWNER
    call nebo_x11_window_reclaim
    test eax, eax
    jnz .fail
    cmp qword [rel live_runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET], 0
    jne .fail
    lea rdi, [rel live_runtime]
    call nebo_x11_runtime_shutdown
    test eax, eax
    jnz .fail

    xor edi, edi
    jmp .exit
.usage:
    mov edi, 64
    jmp .exit
.fail:
    mov edi, 1
.exit:
    mov eax, 60
    syscall

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
