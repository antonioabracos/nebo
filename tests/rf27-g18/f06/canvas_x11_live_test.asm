; CONTROLO-DE-FLUXO-ESTRUTURADO-F06 optional live direct-X11 Canvas presentation smoke.
; argv[1]=AF_UNIX socket path, argv[2]=MIT-MAGIC-COOKIE-1 hex.
bits 64
default rel
%include "runtime/canvas/canvas_x11.inc"

%define LIVE_WIDTH 320
%define LIVE_HEIGHT 200
%define LIVE_OWNER 0x5246323747313846
%define LIVE_SCRATCH_BYTES 65536
%define LIVE_EVENT_CAPACITY 32
%define LIVE_EVENT_MASK_REQUIRED 0x07

section .rodata align=8
auth_name: db 'MIT-MAGIC-COOKIE-1'
live_title: db 'Nebo Canvas F06'
live_title_end:
live_text: db 'NEBO F06'

section .data align=8
live_line_paint: dd 0xffcc00ff, NEBO_CANVAS_PAINT_MODE_STROKE, 1, 0
live_fill_paint: dd 0x2060ffff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0
live_text_paint: dd 0xffffffff, NEBO_CANVAS_PAINT_MODE_FILL, 1, 0

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
live_canvas: resb NEBO_CANVAS_SIZE
live_pixels: resb LIVE_WIDTH*LIVE_HEIGHT*4
live_commands: resb NEBO_CANVAS_COMMAND_SIZE*16
live_present_result: resb NEBO_CANVAS_PRESENT_RESULT_SIZE

section .text
global _start
_start:
    mov rax,[rsp]
    cmp rax,3
    jne .usage
    mov r12,[rsp+16]
    mov r13,[rsp+24]

    lea rdi,[rel live_socket_address]
    mov word [rdi],NEBO_LINUX_AF_UNIX
    lea rdi,[rdi+2]
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
    lea rsi,[rel live_auth_cookie]
    mov edx,NEBO_X11_MAX_AUTH_BYTES
    lea rcx,[rel live_auth_cookie_length]
    call parse_hex
    test eax,eax
    jnz .fail

    lea rdi,[rel live_scheduler_budget]
    mov esi,1
    mov edx,1
    mov ecx,1
    mov r8d,4
    mov r9d,16
    call nebo_scheduler_budget_init
    test eax,eax
    jnz .fail
    lea rdi,[rel live_task_group]
    lea rsi,[rel live_scheduler_budget]
    lea rdx,[rel live_task_storage]
    mov ecx,1
    call nebo_task_group_init
    test eax,eax
    jnz .fail
    lea rdi,[rel live_cancel_budget]
    mov esi,1
    mov edx,1
    mov ecx,1000000000
    call nebo_cancellation_budget_init
    test eax,eax
    jnz .fail
    lea rdi,[rel live_cancel_token]
    lea rsi,[rel live_cancel_budget]
    xor edx,edx
    xor ecx,ecx
    xor r8d,r8d
    xor r9d,r9d
    call nebo_cancellation_token_init
    test eax,eax
    jnz .fail

    lea rdi,[rel live_x11_config]
    lea rax,[rel live_socket_address]
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET],rax
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET],r14
    lea rax,[rel auth_name]
    mov [rdi+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET],rax
    mov qword [rdi+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET],NEBO_X11_AUTH_NAME_LENGTH
    lea rax,[rel live_auth_cookie]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET],rax
    mov rax,[rel live_auth_cookie_length]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET],rax
    lea rax,[rel live_scratch]
    mov [rdi+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET],rax
    mov qword [rdi+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET],LIVE_SCRATCH_BYTES
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET],NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET],NEBO_X11_CONFIG_REQUIRED_FLAGS

    lea rdi,[rel live_runtime]
    lea rsi,[rel live_records]
    lea rdx,[rel live_native_records]
    mov ecx,1
    lea r8,[rel live_adapter]
    lea r9,[rel live_x11_config]
    call nebo_x11_runtime_init
    test eax,eax
    jnz .fail

    lea rdi,[rel live_options]
    mov ecx,NEBO_WINDOW_OPTIONS_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET],LIVE_WIDTH
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET],LIVE_HEIGHT
    lea rax,[rel live_title]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET],rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET],live_title_end-live_title
    lea rax,[rel live_title_storage]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET],rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET],256
    lea rax,[rel live_event_storage]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET],rax
    mov qword [rel live_options+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET],LIVE_EVENT_CAPACITY
    lea rax,[rel live_cancel_token]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET],rax
    lea rax,[rel live_task_group]
    mov [rel live_options+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET],rax
    mov dword [rel live_options+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET],NEBO_WINDOW_BACKEND_X11_DIRECT
    mov dword [rel live_options+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET],NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED | NEBO_WINDOW_OPTION_TEXT_INPUT
    mov rax,LIVE_OWNER
    mov [rel live_options+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET],rax
    lea rdi,[rel live_runtime]
    lea rsi,[rel live_options]
    lea rdx,[rel live_handle]
    call nebo_x11_window_create
    test eax,eax
    jnz .fail
    lea rdi,[rel live_runtime]
    mov rsi,[rel live_handle]
    mov rdx,LIVE_OWNER
    lea rcx,[rel live_stream]
    call nebo_x11_window_events
    test eax,eax
    jnz .fail
    lea rdi,[rel live_runtime]
    mov rsi,[rel live_handle]
    mov rdx,LIVE_OWNER
    call nebo_x11_window_show
    test eax,eax
    jnz .fail

    lea rdi,[rel live_canvas]
    lea rsi,[rel live_pixels]
    mov edx,LIVE_WIDTH*LIVE_HEIGHT*4
    mov ecx,LIVE_WIDTH
    mov r8d,LIVE_HEIGHT
    lea r9,[rel live_commands]
    sub rsp,16
    mov qword [rsp],16
    call nebo_canvas_create
    add rsp,16
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    mov esi,0x102030ff
    call nebo_canvas_clear
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    mov rsi,-20
    xor edx,edx
    mov ecx,LIVE_WIDTH-1
    mov r8d,LIVE_HEIGHT-1
    lea r9,[rel live_line_paint]
    call nebo_canvas_line
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    mov esi,32
    mov edx,30
    mov ecx,160
    mov r8d,80
    lea r9,[rel live_fill_paint]
    call nebo_canvas_rectangle
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    mov esi,245
    mov edx,100
    mov ecx,42
    lea r8,[rel live_line_paint]
    call nebo_canvas_circle
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    lea rsi,[rel live_text]
    mov edx,8
    mov ecx,48
    mov r8d,48
    lea r9,[rel live_text_paint]
    call nebo_canvas_text
    test eax,eax
    jnz .fail

    lea rdi,[rel live_runtime]
    mov rsi,[rel live_handle]
    mov rdx,LIVE_OWNER
    call nebo_x11_window_request_redraw
    test eax,eax
    jnz .fail
    lea rdi,[rel live_canvas]
    lea rsi,[rel live_runtime]
    mov rdx,[rel live_handle]
    mov rcx,LIVE_OWNER
    lea r8,[rel live_present_result]
    call nebo_canvas_present_x11
    test eax,eax
    jnz .fail
    cmp qword [rel live_present_result+NEBO_CANVAS_PRESENT_FRAME_SEQUENCE_OFFSET],1
    jne .fail
    cmp qword [rel live_present_result+NEBO_CANVAS_PRESENT_COMMAND_COUNT_OFFSET],5
    jne .fail
    cmp qword [rel live_native_records+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET],1
    jne .fail
    cmp qword [rel live_native_records+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET],0
    jne .fail

    mov qword [rel live_sleep_spec],0
    mov qword [rel live_sleep_spec+8],150000000
    mov eax,NEBO_LINUX_SYS_NANOSLEEP
    lea rdi,[rel live_sleep_spec]
    xor esi,esi
    syscall

    lea rdi,[rel live_canvas]
    call nebo_canvas_close
    test eax,eax
    jnz .fail
    lea rdi,[rel live_runtime]
    mov rsi,[rel live_handle]
    mov rdx,LIVE_OWNER
    call nebo_x11_window_close
    test eax,eax
    jnz .fail

    xor r14d,r14d
    mov r15d,128
.drain:
    lea rdi,[rel live_stream]
    lea rsi,[rel live_event]
    call nebo_x11_event_stream_poll
    test eax,eax
    jnz .fail
    test edx,edx
    jz .drained
    mov eax,[rel live_event+NEBO_WINDOW_EVENT_KIND_OFFSET]
    cmp eax,NEBO_WINDOW_EVENT_CREATED
    jne .not_created
    or r14d,1
.not_created:
    cmp eax,NEBO_WINDOW_EVENT_SHOWN
    jne .not_shown
    or r14d,2
.not_shown:
    cmp eax,NEBO_WINDOW_EVENT_CLOSED
    jne .not_closed
    or r14d,4
.not_closed:
    dec r15d
    jnz .drain
    jmp .fail
.drained:
    cmp r14d,LIVE_EVENT_MASK_REQUIRED
    jne .fail
    lea rdi,[rel live_stream]
    call nebo_x11_event_stream_release
    test eax,eax
    jnz .fail
    lea rdi,[rel live_runtime]
    mov rsi,[rel live_handle]
    mov rdx,LIVE_OWNER
    call nebo_x11_window_reclaim
    test eax,eax
    jnz .fail
    lea rdi,[rel live_runtime]
    call nebo_x11_runtime_shutdown
    test eax,eax
    jnz .fail
    xor edi,edi
    jmp .exit
.usage:
    mov edi,64
    jmp .exit
.fail:
    mov edi,1
.exit:
    mov eax,60
    syscall

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
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r15,r15
    jz .invalid
    mov qword [r15],0
    xor ebx,ebx
.loop:
    movzx edi,byte [r12]
    test dil,dil
    jz .done
    movzx esi,byte [r12+1]
    test sil,sil
    jz .invalid
    call hex_nibble
    test eax,eax
    js .invalid
    shl eax,4
    mov r10d,eax
    mov edi,esi
    call hex_nibble
    test eax,eax
    js .invalid
    or eax,r10d
    cmp rbx,r14
    jae .invalid
    mov [r13+rbx],al
    inc rbx
    add r12,2
    jmp .loop
.done:
    test rbx,rbx
    jz .invalid
    mov [r15],rbx
    xor eax,eax
    jmp .return
.invalid:
    mov eax,-1
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hex_nibble:
    movzx eax,dil
    cmp al,'0'
    jb .bad
    cmp al,'9'
    jbe .decimal
    or al,0x20
    cmp al,'a'
    jb .bad
    cmp al,'f'
    ja .bad
    sub al,'a'-10
    movzx eax,al
    ret
.decimal:
    sub al,'0'
    movzx eax,al
    ret
.bad:
    mov eax,-1
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
