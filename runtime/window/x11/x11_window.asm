; Nebo CONTROLO-DE-FLUXO-ESTRUTURADO-F05 — bounded direct-X11 Window backend
bits 64
default rel

%define NEBO_X11_WINDOW_IMPLEMENTATION 1
%include "runtime/window/x11/x11_window.inc"

extern nebo_x11_adapter_init
extern nebo_x11_adapter_validate
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_normalize_event

; The included dependency contracts already emit the remaining adapter,
; headless Window and cancellation extern declarations. Repeating them here
; is a NASM label-redef warning and therefore an error under -Wall -Werror.

global nebo_x11_runtime_init
global nebo_x11_runtime_shutdown
global nebo_x11_window_create
global nebo_x11_window_show
global nebo_x11_window_hide
global nebo_x11_window_resize
global nebo_x11_window_set_title
global nebo_x11_window_request_redraw
global nebo_x11_window_close
global nebo_x11_window_events
global nebo_x11_event_stream_poll
global nebo_x11_event_stream_wait
global nebo_x11_event_stream_release
global nebo_x11_window_reclaim
global nebo_x11_window_pump_once
global nebo_x11_window_translate_raw
global nebo_x11_window_event_kind
global nebo_x11_window_event_key
global nebo_x11_window_event_pointer
global nebo_x11_window_event_text_input
global nebo_x11_window_event_resize
global nebo_x11_window_event_prevent_default

section .text

; ---------------------------------------------------------------------------
; Internal bounded validation and storage helpers
; ---------------------------------------------------------------------------

; rdi=a pointer, rsi=a length, rdx=b pointer, rcx=b length.
; eax=1 when the half-open ranges overlap or arithmetic wraps; otherwise 0.
x11_ranges_overlap:
    test rdi, rdi
    jz .overlap
    test rdx, rdx
    jz .overlap
    test rsi, rsi
    jz .no_overlap
    test rcx, rcx
    jz .no_overlap
    mov r8, rdi
    add r8, rsi
    jc .overlap
    mov r9, rdx
    add r9, rcx
    jc .overlap
    cmp rdi, r9
    jae .no_overlap
    cmp rdx, r8
    jae .no_overlap
.overlap:
    mov eax, 1
    ret
.no_overlap:
    xor eax, eax
    ret

; Strict canonical UTF-8 validation. rdi=bytes, rsi=length; eax=WindowError.
x11_validate_utf8:
    test rsi, rsi
    jz .utf8_ok
    test rdi, rdi
    jz .utf8_invalid
    xor ecx, ecx
.utf8_loop:
    cmp rcx, rsi
    jae .utf8_ok
    movzx eax, byte [rdi+rcx]
    cmp eax, 0x7f
    jbe .utf8_one
    cmp eax, 0xc2
    jb .utf8_invalid
    cmp eax, 0xdf
    jbe .utf8_two
    cmp eax, 0xef
    jbe .utf8_three
    cmp eax, 0xf4
    jbe .utf8_four
    jmp .utf8_invalid
.utf8_one:
    inc rcx
    jmp .utf8_loop
.utf8_two:
    lea r8, [rcx+1]
    cmp r8, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+r8]
    and edx, 0xc0
    cmp edx, 0x80
    jne .utf8_invalid
    add rcx, 2
    jmp .utf8_loop
.utf8_three:
    lea r8, [rcx+2]
    cmp r8, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    movzx r8d, byte [rdi+rcx+2]
    mov r9d, edx
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .utf8_invalid
    mov r9d, r8d
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .utf8_invalid
    cmp eax, 0xe0
    jne .utf8_three_not_e0
    cmp edx, 0xa0
    jb .utf8_invalid
.utf8_three_not_e0:
    cmp eax, 0xed
    jne .utf8_three_ready
    cmp edx, 0xa0
    jae .utf8_invalid
.utf8_three_ready:
    add rcx, 3
    jmp .utf8_loop
.utf8_four:
    lea r8, [rcx+3]
    cmp r8, rsi
    jae .utf8_invalid
    movzx edx, byte [rdi+rcx+1]
    movzx r8d, byte [rdi+rcx+2]
    movzx r9d, byte [rdi+rcx+3]
    mov r10d, edx
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .utf8_invalid
    mov r10d, r8d
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .utf8_invalid
    mov r10d, r9d
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .utf8_invalid
    cmp eax, 0xf0
    jne .utf8_four_not_f0
    cmp edx, 0x90
    jb .utf8_invalid
.utf8_four_not_f0:
    cmp eax, 0xf4
    jne .utf8_four_ready
    cmp edx, 0x90
    jae .utf8_invalid
.utf8_four_ready:
    add rcx, 4
    jmp .utf8_loop
.utf8_ok:
    xor eax, eax
    ret
.utf8_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    ret

; Decode one canonical UTF-8 scalar from packed little-endian bytes.
; rdi=packed bytes, rsi=length; eax=WindowError, r8=scalar.
x11_decode_scalar:
    xor r8d, r8d
    cmp rsi, 1
    je .decode_one
    cmp rsi, 2
    je .decode_two
    cmp rsi, 3
    je .decode_three
    cmp rsi, 4
    jne .decode_invalid
.decode_one:
    movzx r8d, dil
    cmp r8d, 0x7f
    ja .decode_invalid
    xor eax, eax
    ret
.decode_two:
    mov eax, edi
    and eax, 0xff
    cmp eax, 0xc2
    jb .decode_invalid
    cmp eax, 0xdf
    ja .decode_invalid
    mov edx, edi
    shr edx, 8
    and edx, 0xff
    mov ecx, edx
    and ecx, 0xc0
    cmp ecx, 0x80
    jne .decode_invalid
    and eax, 0x1f
    shl eax, 6
    and edx, 0x3f
    or eax, edx
    mov r8d, eax
    xor eax, eax
    ret
.decode_three:
    mov eax, edi
    and eax, 0xff
    cmp eax, 0xe0
    jb .decode_invalid
    cmp eax, 0xef
    ja .decode_invalid
    mov edx, edi
    shr edx, 8
    and edx, 0xff
    mov ecx, edi
    shr ecx, 16
    and ecx, 0xff
    mov r9d, edx
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .decode_invalid
    mov r9d, ecx
    and r9d, 0xc0
    cmp r9d, 0x80
    jne .decode_invalid
    cmp eax, 0xe0
    jne .decode_three_not_e0
    cmp edx, 0xa0
    jb .decode_invalid
.decode_three_not_e0:
    cmp eax, 0xed
    jne .decode_three_ready
    cmp edx, 0xa0
    jae .decode_invalid
.decode_three_ready:
    and eax, 0x0f
    shl eax, 12
    and edx, 0x3f
    shl edx, 6
    and ecx, 0x3f
    or eax, edx
    or eax, ecx
    mov r8d, eax
    xor eax, eax
    ret
.decode_four:
    mov eax, edi
    and eax, 0xff
    cmp eax, 0xf0
    jb .decode_invalid
    cmp eax, 0xf4
    ja .decode_invalid
    mov edx, edi
    shr edx, 8
    and edx, 0xff
    mov ecx, edi
    shr ecx, 16
    and ecx, 0xff
    mov r9d, edi
    shr r9d, 24
    and r9d, 0xff
    mov r10d, edx
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .decode_invalid
    mov r10d, ecx
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .decode_invalid
    mov r10d, r9d
    and r10d, 0xc0
    cmp r10d, 0x80
    jne .decode_invalid
    cmp eax, 0xf0
    jne .decode_four_not_f0
    cmp edx, 0x90
    jb .decode_invalid
.decode_four_not_f0:
    cmp eax, 0xf4
    jne .decode_four_ready
    cmp edx, 0x90
    jae .decode_invalid
.decode_four_ready:
    and eax, 0x07
    shl eax, 18
    and edx, 0x3f
    shl edx, 12
    and ecx, 0x3f
    shl ecx, 6
    and r9d, 0x3f
    or eax, edx
    or eax, ecx
    or eax, r9d
    cmp eax, 0x10ffff
    ja .decode_invalid
    mov r8d, eax
    xor eax, eax
    ret
.decode_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    xor r8d, r8d
    ret

; edi=X11 state mask. eax=backend-independent modifier bits.
x11_common_modifiers:
    xor eax, eax
    test edi, NEBO_X11_STATE_SHIFT
    jz .mods_no_shift
    or eax, NEBO_PLATFORM_MOD_SHIFT
.mods_no_shift:
    test edi, NEBO_X11_STATE_CONTROL
    jz .mods_no_control
    or eax, NEBO_PLATFORM_MOD_CONTROL
.mods_no_control:
    test edi, NEBO_X11_STATE_MOD1
    jz .mods_no_alt
    or eax, NEBO_PLATFORM_MOD_ALT
.mods_no_alt:
    test edi, NEBO_X11_STATE_MOD4
    jz .mods_done
    or eax, NEBO_PLATFORM_MOD_SUPER
.mods_done:
    ret

; eax=platform status -> eax=WindowError.
x11_map_platform_status:
    test eax, eax
    jz .map_ok
    cmp eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    je .map_invalid
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    je .map_state
    cmp eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    je .map_unavailable
    cmp eax, NEBO_PLATFORM_STATUS_AUTH_FAILURE
    je .map_unavailable
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .map_ok
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    ret
.map_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    ret
.map_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
    ret
.map_unavailable:
    mov eax, NEBO_WINDOW_ERROR_BACKEND_UNAVAILABLE
    ret
.map_ok:
    xor eax, eax
    ret

; rdi=runtime. eax=WindowError.
x11_validate_runtime:
    test rdi, rdi
    jz .runtime_invalid
    test rdi, 7
    jnz .runtime_invalid
    mov rax, NEBO_X11_RUNTIME_MAGIC
    cmp qword [rdi+NEBO_X11_RUNTIME_MAGIC_OFFSET], rax
    jne .runtime_invalid
    mov eax, [rdi+NEBO_X11_RUNTIME_FLAGS_OFFSET]
    test eax, ~NEBO_X11_RUNTIME_KNOWN_FLAGS
    jnz .runtime_invalid
    test eax, NEBO_X11_RUNTIME_FLAG_READY
    jz .runtime_invalid
    cmp qword [rdi+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET], 0
    je .runtime_invalid
    cmp qword [rdi+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET], 0
    je .runtime_invalid
    mov rax, [rdi+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
    test rax, rax
    jz .runtime_invalid
    cmp rax, NEBO_WINDOW_MAX_WINDOWS
    ja .runtime_invalid
    mov rax, NEBO_HEADLESS_RUNTIME_MAGIC
    cmp qword [rdi+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET], rax
    jne .runtime_invalid
    xor eax, eax
    ret
.runtime_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    ret

; rdi=runtime, rsi=handle, rdx=owner or zero.
; rax=canonical record, r8=native record, ecx=WindowError.
x11_resolve:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    call x11_validate_runtime
    test eax, eax
    jnz .resolve_invalid
    test r12, r12
    jz .resolve_invalid
    mov ecx, r12d
    test ecx, ecx
    jz .resolve_invalid
    cmp rcx, [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
    ja .resolve_invalid
    mov r9, r12
    shr r9, NEBO_WINDOW_HANDLE_GENERATION_SHIFT
    test r9d, r9d
    jz .resolve_invalid
    dec ecx
    mov rax, rcx
    imul rax, NEBO_WINDOW_SIZE
    add rax, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    cmp [rax+NEBO_WINDOW_HANDLE_OFFSET], r12
    jne .resolve_stale
    cmp [rax+nebo_canvas_WINDOW_GENERATION_OFFSET], r9
    jne .resolve_stale
    mov r10d, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp r10d, NEBO_WINDOW_STATE_EMPTY
    je .resolve_stale
    cmp r10d, NEBO_WINDOW_STATE_RECLAIMED
    je .resolve_stale
    test rdx, rdx
    jz .resolve_owner_ready
    cmp [rax+NEBO_WINDOW_OWNER_CONTEXT_OFFSET], rdx
    jne .resolve_owner
.resolve_owner_ready:
    cmp dword [rax+NEBO_WINDOW_BACKEND_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    jne .resolve_state
    mov r8, rcx
    imul r8, NEBO_X11_WINDOW_SIZE
    add r8, [rbx+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET]
    cmp qword [r8+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], 0
    je .resolve_state
    mov r10, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    cmp [r8+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r10
    jne .resolve_state
    mov r11d, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp r11d, NEBO_WINDOW_STATE_CLOSED
    je .resolve_terminal
    cmp r11d, NEBO_WINDOW_STATE_FAILED
    je .resolve_terminal
    cmp [rax+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET], rbx
    jne .resolve_state
    cmp dword [r8+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    je .resolve_state
    cmp dword [r8+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_FAILED
    je .resolve_state
    cmp dword [r8+NEBO_X11_WINDOW_XID_OFFSET], 0
    je .resolve_state
    jmp .resolve_handle
.resolve_terminal:
    cmp dword [r8+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    jne .resolve_state
.resolve_handle:
    mov rcx, [r8+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    cmp rcx, r12
    jne .resolve_state
    xor ecx, ecx
    jmp .resolve_return
.resolve_invalid:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    jmp .resolve_return
.resolve_stale:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_STALE_HANDLE
    jmp .resolve_return
.resolve_owner:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_OWNER_MISMATCH
    jmp .resolve_return
.resolve_state:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_BAD_STATE
.resolve_return:
    add rsp, 8
    pop r12
    pop rbx
    ret

; Close-only recovery path for a server-destroyed native resource.
; The ordinary resolver deliberately rejects DESTROYED native records so that
; show/hide/resize/title/redraw cannot operate after DestroyNotify. Direct or
; default close still needs to complete the canonical exactly-once barrier.
; rdi=runtime, rsi=handle, rdx=owner. rax=canonical, r8=native, ecx=WindowError.
x11_resolve_destroyed_for_close:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    call x11_validate_runtime
    test eax, eax
    jnz .close_resolve_invalid
    test r12, r12
    jz .close_resolve_invalid
    mov ecx, r12d
    test ecx, ecx
    jz .close_resolve_invalid
    cmp rcx, [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
    ja .close_resolve_invalid
    mov r9, r12
    shr r9, NEBO_WINDOW_HANDLE_GENERATION_SHIFT
    test r9d, r9d
    jz .close_resolve_invalid
    dec ecx
    mov rax, rcx
    imul rax, NEBO_WINDOW_SIZE
    add rax, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    cmp [rax+NEBO_WINDOW_HANDLE_OFFSET], r12
    jne .close_resolve_stale
    cmp [rax+nebo_canvas_WINDOW_GENERATION_OFFSET], r9
    jne .close_resolve_stale
    mov r10d, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp r10d, NEBO_WINDOW_STATE_EMPTY
    je .close_resolve_stale
    cmp r10d, NEBO_WINDOW_STATE_RECLAIMED
    je .close_resolve_stale
    test rdx, rdx
    jz .close_resolve_owner_ok
    cmp [rax+NEBO_WINDOW_OWNER_CONTEXT_OFFSET], rdx
    jne .close_resolve_owner
.close_resolve_owner_ok:
    cmp dword [rax+NEBO_WINDOW_BACKEND_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    jne .close_resolve_state
    cmp [rax+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET], rbx
    jne .close_resolve_state
    cmp r10d, NEBO_WINDOW_STATE_CREATED
    je .close_resolve_active
    cmp r10d, NEBO_WINDOW_STATE_VISIBLE
    je .close_resolve_active
    cmp r10d, NEBO_WINDOW_STATE_HIDDEN
    je .close_resolve_active
    cmp r10d, NEBO_WINDOW_STATE_CLOSING
    je .close_resolve_active
    cmp r10d, NEBO_WINDOW_STATE_CLOSED
    je .close_resolve_active
    cmp r10d, NEBO_WINDOW_STATE_FAILED
    jne .close_resolve_state
.close_resolve_active:
    mov r8, rcx
    imul r8, NEBO_X11_WINDOW_SIZE
    add r8, [rbx+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET]
    mov r10, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    cmp [r8+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r10
    jne .close_resolve_state
    cmp dword [r8+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    jne .close_resolve_state
    cmp [r8+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], r12
    jne .close_resolve_state
    xor ecx, ecx
    jmp .close_resolve_return
.close_resolve_invalid:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    jmp .close_resolve_return
.close_resolve_stale:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_STALE_HANDLE
    jmp .close_resolve_return
.close_resolve_owner:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_OWNER_MISMATCH
    jmp .close_resolve_return
.close_resolve_state:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_BAD_STATE
.close_resolve_return:
    add rsp, 8
    pop r12
    pop rbx
    ret

; rdi=runtime, rsi=record. eax=WindowError for one ordinary event.
x11_queue_preflight:
    mov rax, [rsi+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET]
    cmp rax, -1
    je .queue_sequence
    cmp qword [rdi+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET], -1
    je .queue_sequence
    mov rax, [rsi+NEBO_WINDOW_EVENT_CAPACITY_OFFSET]
    cmp rax, NEBO_WINDOW_TERMINAL_EVENT_RESERVE
    jb .queue_full
    sub rax, NEBO_WINDOW_TERMINAL_EVENT_RESERVE
    cmp [rsi+NEBO_WINDOW_EVENT_COUNT_OFFSET], rax
    jae .queue_full
    xor eax, eax
    ret
.queue_full:
    mov eax, NEBO_WINDOW_ERROR_QUEUE_FULL
    ret
.queue_sequence:
    mov eax, NEBO_WINDOW_ERROR_SEQUENCE_EXHAUSTED
    ret

; Internal convention: rdi=runtime, rsi=handle, rdx=owner, ecx=kind,
; r8=payload0, r9=payload1, r10=payload2. eax=WindowError.
x11_push_template:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14d, ecx
    mov r15, r8
    mov r11, r9
    mov [rsp], r10
    lea rdi, [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET]
    xor eax, eax
    mov ecx, NEBO_WINDOW_EVENT_QWORDS
    cld
    rep stosq
    mov [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET+NEBO_WINDOW_EVENT_KIND_OFFSET], r14d
    mov [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET], r15
    mov [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET], r11
    mov rax, [rsp]
    mov [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET], rax
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    lea rcx, [rbx+NEBO_X11_RUNTIME_TEMPLATE_EVENT_OFFSET]
    call nebo_headless_window_push_event
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Return the raw event's target XID in eax and known-target flag in edx.
; Unknown-but-well-formed event types return edx=0. Error packets return
; eax=0xffffffff, edx=1 so the caller treats them as protocol failure.
x11_raw_xid:
    test rdi, rdi
    jz .raw_xid_unknown
    movzx ecx, byte [rdi]
    and ecx, 0x7f
    test ecx, ecx
    jz .raw_xid_error
    cmp ecx, NEBO_X11_EVENT_MAP_NOTIFY
    je .raw_xid_at8
    cmp ecx, NEBO_X11_EVENT_CONFIGURE_NOTIFY
    je .raw_xid_at8
    cmp ecx, NEBO_X11_EVENT_UNMAP_NOTIFY
    je .raw_xid_at8
    cmp ecx, NEBO_X11_EVENT_DESTROY_NOTIFY
    je .raw_xid_at8
    cmp ecx, NEBO_X11_EVENT_MOTION_NOTIFY
    je .raw_xid_at12
    cmp ecx, NEBO_X11_EVENT_BUTTON_PRESS
    je .raw_xid_at12
    cmp ecx, NEBO_X11_EVENT_BUTTON_RELEASE
    je .raw_xid_at12
    cmp ecx, NEBO_X11_EVENT_KEY_PRESS
    je .raw_xid_at12
    cmp ecx, NEBO_X11_EVENT_KEY_RELEASE
    je .raw_xid_at12
    cmp ecx, NEBO_X11_EVENT_FOCUS_IN
    je .raw_xid_at4
    cmp ecx, NEBO_X11_EVENT_FOCUS_OUT
    je .raw_xid_at4
    cmp ecx, NEBO_X11_EVENT_CLIENT_MESSAGE
    je .raw_xid_at4
    cmp ecx, NEBO_X11_EVENT_EXPOSE
    je .raw_xid_at4
.raw_xid_unknown:
    xor eax, eax
    xor edx, edx
    ret
.raw_xid_at4:
    mov eax, [rdi+4]
    mov edx, 1
    ret
.raw_xid_at8:
    mov eax, [rdi+8]
    mov edx, 1
    ret
.raw_xid_at12:
    mov eax, [rdi+12]
    mov edx, 1
    ret
.raw_xid_error:
    mov eax, -1
    mov edx, 1
    ret

; rdi=runtime, esi=xid. rax=canonical, r8=native, ecx=error.
x11_find_xid:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12d, esi
    xor r13d, r13d
    mov rcx, [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
.find_xid_loop:
    test rcx, rcx
    jz .find_xid_stale
    mov r8, r13
    imul r8, NEBO_X11_WINDOW_SIZE
    add r8, [rbx+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET]
    cmp [r8+NEBO_X11_WINDOW_XID_OFFSET], r12d
    jne .find_xid_next
    mov rax, r13
    imul rax, NEBO_WINDOW_SIZE
    add rax, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov edx, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp edx, NEBO_WINDOW_STATE_CREATED
    je .find_xid_active
    cmp edx, NEBO_WINDOW_STATE_VISIBLE
    je .find_xid_active
    cmp edx, NEBO_WINDOW_STATE_HIDDEN
    je .find_xid_active
    cmp edx, NEBO_WINDOW_STATE_CLOSING
    jne .find_xid_stale
.find_xid_active:
    xor ecx, ecx
    jmp .find_xid_return
.find_xid_next:
    inc r13
    dec rcx
    jmp .find_xid_loop
.find_xid_stale:
    xor eax, eax
    xor r8d, r8d
    mov ecx, NEBO_WINDOW_ERROR_STALE_HANDLE
.find_xid_return:
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Runtime initialization and exact native lifecycle
; ---------------------------------------------------------------------------

; rdi=runtime, rsi=WindowRecord storage, rdx=X11 native record storage,
; rcx=capacity, r8=adapter state, r9=X11 config.
nebo_x11_runtime_init:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp], r9
    test rbx, rbx
    jz .init_invalid
    test r12, r12
    jz .init_invalid
    test r13, r13
    jz .init_invalid
    test r15, r15
    jz .init_invalid
    cmp qword [rsp], 0
    je .init_invalid
    mov rax, rbx
    or rax, r12
    or rax, r13
    or rax, r15
    test rax, 7
    jnz .init_invalid
    test r14, r14
    jz .init_limit
    cmp r14, NEBO_WINDOW_MAX_WINDOWS
    ja .init_limit
    mov rdi, rbx
    mov esi, NEBO_X11_RUNTIME_SIZE
    mov rdx, r12
    mov rcx, r14
    imul rcx, NEBO_WINDOW_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, rbx
    mov esi, NEBO_X11_RUNTIME_SIZE
    mov rdx, r13
    mov rcx, r14
    imul rcx, NEBO_X11_WINDOW_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, r12
    mov rsi, r14
    imul rsi, NEBO_WINDOW_SIZE
    mov rdx, r13
    mov rcx, r14
    imul rcx, NEBO_X11_WINDOW_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, rbx
    mov esi, NEBO_X11_RUNTIME_SIZE
    mov rdx, r15
    mov ecx, NEBO_X11_ADAPTER_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, r12
    mov rsi, r14
    imul rsi, NEBO_WINDOW_SIZE
    mov rdx, r15
    mov ecx, NEBO_X11_ADAPTER_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, r13
    mov rsi, r14
    imul rsi, NEBO_X11_WINDOW_SIZE
    mov rdx, r15
    mov ecx, NEBO_X11_ADAPTER_SIZE
    call x11_ranges_overlap
    test eax, eax
    jnz .init_overlap
    mov rdi, rbx
    xor eax, eax
    mov ecx, NEBO_X11_RUNTIME_QWORDS
    cld
    rep stosq
    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    imul rcx, NEBO_X11_WINDOW_QWORDS
    cld
    rep stosq
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r14
    call nebo_headless_runtime_init
    test eax, eax
    jnz .init_return
    mov rdi, r15
    mov rsi, [rsp]
    call nebo_x11_adapter_init
    test eax, eax
    jnz .init_adapter
    mov [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET], r15
    mov [rbx+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET], r13
    mov [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET], r14
    mov dword [rbx+NEBO_X11_RUNTIME_FLAGS_OFFSET], (NEBO_X11_RUNTIME_FLAG_READY | NEBO_X11_RUNTIME_FLAG_LIVE)
    mov qword [rbx+NEBO_X11_RUNTIME_LAST_STATUS_OFFSET], 0
    mov qword [rbx+NEBO_X11_RUNTIME_LAST_ERROR_OFFSET], 0
    mov rax, NEBO_X11_RUNTIME_MAGIC
    mov [rbx+NEBO_X11_RUNTIME_MAGIC_OFFSET], rax
    xor eax, eax
    jmp .init_return
.init_adapter:
    call x11_map_platform_status
    jmp .init_return
.init_overlap:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    jmp .init_return
.init_limit:
    mov eax, NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
    jmp .init_return
.init_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
.init_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=runtime. Requires all windows reclaimed.
nebo_x11_runtime_shutdown:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    call x11_validate_runtime
    test eax, eax
    jnz .shutdown_return
    cmp qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET], 0
    jne .shutdown_state
    mov r12, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rdi, r12
    call nebo_x11_adapter_shutdown
    test eax, eax
    jnz .shutdown_adapter
    mov dword [rbx+NEBO_X11_RUNTIME_FLAGS_OFFSET], 0
    mov qword [rbx+NEBO_X11_RUNTIME_MAGIC_OFFSET], 0
    xor eax, eax
    jmp .shutdown_return
.shutdown_adapter:
    call x11_map_platform_status
    jmp .shutdown_return
.shutdown_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
.shutdown_return:
    add rsp, 8
    pop r12
    pop rbx
    ret

; Validate a WindowOptions value before creating any X11 resource.
; rdi=runtime, rsi=options. eax=WindowError, r8=free slot index.
x11_validate_create:
    push rbx
    push r12
    push r13
    mov rbx, rdi
    mov r12, rsi
    xor r8d, r8d
    call x11_validate_runtime
    test eax, eax
    jnz .create_validate_return
    test r12, r12
    jz .create_validate_invalid
    test r12, 7
    jnz .create_validate_invalid
    mov rax, [r12+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET]
    cmp rax, NEBO_WINDOW_MIN_WIDTH
    jb .create_validate_dimension
    cmp rax, NEBO_WINDOW_MAX_WIDTH
    ja .create_validate_dimension
    mov rax, [r12+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET]
    cmp rax, NEBO_WINDOW_MIN_HEIGHT
    jb .create_validate_dimension
    cmp rax, NEBO_WINDOW_MAX_HEIGHT
    ja .create_validate_dimension
    mov rax, [r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
    cmp rax, NEBO_WINDOW_MAX_TITLE_BYTES
    ja .create_validate_title
    cmp [r12+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET], rax
    jb .create_validate_title
    cmp qword [r12+NEBO_WINDOW_OPTIONS_TITLE_CAPACITY_OFFSET], NEBO_WINDOW_MAX_TITLE_BYTES
    ja .create_validate_title
    cmp qword [r12+NEBO_WINDOW_OPTIONS_TITLE_STORAGE_PTR_OFFSET], 0
    je .create_validate_invalid
    test rax, rax
    jz .create_validate_events
    cmp qword [r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET], 0
    je .create_validate_invalid
    mov rdi, [r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET]
    mov rsi, [r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
    call x11_validate_utf8
    test eax, eax
    jnz .create_validate_return
.create_validate_events:
    mov rax, [r12+NEBO_WINDOW_OPTIONS_EVENT_STORAGE_PTR_OFFSET]
    test rax, rax
    jz .create_validate_invalid
    test rax, 7
    jnz .create_validate_invalid
    mov rax, [r12+NEBO_WINDOW_OPTIONS_EVENT_CAPACITY_OFFSET]
    cmp rax, NEBO_WINDOW_MIN_EVENT_CAPACITY
    jb .create_validate_limit
    cmp rax, NEBO_WINDOW_MAX_EVENTS
    ja .create_validate_limit
    mov rax, [r12+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET]
    test rax, rax
    jz .create_validate_cancel
    test rax, 7
    jnz .create_validate_invalid
    mov r13, [r12+NEBO_WINDOW_OPTIONS_TASK_GROUP_PTR_OFFSET]
    test r13, r13
    jz .create_validate_task
    test r13, 7
    jnz .create_validate_invalid
    cmp qword [r13+NEBO_TASK_GROUP_JOINED], 0
    jne .create_validate_task
    cmp qword [r13+NEBO_TASK_GROUP_COUNT], 0
    jne .create_validate_task
    cmp qword [r12+NEBO_WINDOW_OPTIONS_OWNER_CONTEXT_OFFSET], 0
    je .create_validate_invalid
    mov eax, [r12+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET]
    cmp eax, NEBO_WINDOW_BACKEND_AUTO
    je .create_validate_backend
    cmp eax, NEBO_WINDOW_BACKEND_X11_DIRECT
    jne .create_validate_unavailable
.create_validate_backend:
    mov eax, [r12+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET]
    test eax, ~NEBO_WINDOW_OPTION_KNOWN_FLAGS
    jnz .create_validate_invalid
    mov rdi, [r12+NEBO_WINDOW_OPTIONS_CANCELLATION_PTR_OFFSET]
    call nebo_cancellation_check
    test eax, eax
    jz .create_validate_find
    mov eax, NEBO_WINDOW_ERROR_CANCELLED
    jmp .create_validate_return
.create_validate_find:
    mov r13, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    xor r8d, r8d
    mov rcx, [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
.create_validate_find_loop:
    mov eax, [r13+NEBO_WINDOW_STATE_OFFSET]
    cmp eax, NEBO_WINDOW_STATE_EMPTY
    je .create_validate_found
    cmp eax, NEBO_WINDOW_STATE_RECLAIMED
    je .create_validate_found
    add r13, NEBO_WINDOW_SIZE
    inc r8
    loop .create_validate_find_loop
    jmp .create_validate_limit
.create_validate_found:
    xor eax, eax
    jmp .create_validate_return
.create_validate_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    jmp .create_validate_return
.create_validate_dimension:
    mov eax, NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE
    jmp .create_validate_return
.create_validate_title:
    mov eax, NEBO_WINDOW_ERROR_TITLE_TOO_LONG
    jmp .create_validate_return
.create_validate_limit:
    mov eax, NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
    jmp .create_validate_return
.create_validate_cancel:
    mov eax, NEBO_WINDOW_ERROR_CANCELLATION_REQUIRED
    jmp .create_validate_return
.create_validate_task:
    mov eax, NEBO_WINDOW_ERROR_TASK_GROUP_REQUIRED
    jmp .create_validate_return
.create_validate_unavailable:
    mov eax, NEBO_WINDOW_ERROR_BACKEND_UNAVAILABLE
.create_validate_return:
    pop r13
    pop r12
    pop rbx
    ret

; rdi=runtime, rsi=WindowOptions, rdx=out WindowHandle.
nebo_x11_window_create:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 136
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    test r13, r13
    jz .window_create_invalid
    test r13, 7
    jnz .window_create_invalid
    mov qword [r13], 0
    mov rdi, rbx
    mov rsi, r12
    call x11_validate_create
    test eax, eax
    jnz .window_create_return
    mov r14, r8
    mov r15, r14
    imul r15, NEBO_X11_WINDOW_SIZE
    add r15, [rbx+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET]
    ; Build the private adapter config on the stack.
    lea rdi, [rsp]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    cld
    rep stosq
    mov rax, [r12+NEBO_WINDOW_OPTIONS_WIDTH_OFFSET]
    mov [rsp+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], rax
    mov rax, [r12+NEBO_WINDOW_OPTIONS_HEIGHT_OFFSET]
    mov [rsp+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], rax
    mov eax, (NEBO_X11_WINDOW_CONFIG_FLAG_MANAGED | NEBO_X11_WINDOW_CONFIG_FLAG_DEFER_MAP | NEBO_X11_WINDOW_CONFIG_FLAG_NO_SURFACE)
    test dword [r12+NEBO_WINDOW_OPTIONS_FLAGS_OFFSET], NEBO_WINDOW_OPTION_DECORATED
    jz .window_create_custom
    or eax, NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS
    jmp .window_create_flags
.window_create_custom:
    or eax, NEBO_X11_WINDOW_CONFIG_FLAG_CUSTOM_CHROME
.window_create_flags:
    mov [rsp+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], rax
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    lea rdx, [rsp]
    call nebo_x11_adapter_create_window
    test eax, eax
    jnz .window_create_adapter
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OPTIONS_TITLE_PTR_OFFSET]
    mov rcx, [r12+NEBO_WINDOW_OPTIONS_TITLE_LENGTH_OFFSET]
    call nebo_x11_adapter_set_window_title
    test eax, eax
    jnz .window_create_native_rollback
    ; Copy options and force the F04 allocator to its native Headless branch.
    lea rdi, [rsp+32]
    mov rsi, r12
    mov ecx, NEBO_WINDOW_OPTIONS_QWORDS
    cld
    rep movsq
    mov dword [rsp+32+NEBO_WINDOW_OPTIONS_BACKEND_PREFERENCE_OFFSET], NEBO_WINDOW_BACKEND_HEADLESS
    mov rdi, rbx
    lea rsi, [rsp+32]
    mov rdx, r13
    call nebo_headless_window_create
    test eax, eax
    jnz .window_create_headless_rollback
    mov eax, [r13]
    and eax, NEBO_WINDOW_HANDLE_SLOT_MASK
    dec eax
    cmp rax, r14
    jne .window_create_canonical_rollback
    ; Compute the canonical record directly from the frozen slot. The F04
    ; allocator still reports HEADLESS until the X11 backend patch below.
    mov rax, r14
    imul rax, NEBO_WINDOW_SIZE
    add rax, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov dword [rax+NEBO_WINDOW_BACKEND_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    mov [rax+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET], rbx
    mov rdx, [r13]
    mov [r15+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], rdx
    ; Patch the already-enqueued CREATED event's backend payload.
    mov rdx, [rax+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET]
    cmp qword [rax+NEBO_WINDOW_EVENT_COUNT_OFFSET], 1
    jne .window_create_canonical_rollback
    cmp dword [rdx+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_CREATED
    jne .window_create_canonical_rollback
    mov qword [rdx+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    xor eax, eax
    jmp .window_create_return
.window_create_canonical_rollback:
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    call nebo_x11_adapter_destroy_window
    ; Roll back the canonical create before the handle escapes.
    mov rax, r14
    imul rax, NEBO_WINDOW_SIZE
    add rax, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    mov r10, [rax+nebo_canvas_WINDOW_GENERATION_OFFSET]
    mov rdi, rax
    xor eax, eax
    mov ecx, NEBO_WINDOW_QWORDS
    cld
    rep stosq
    mov [rdi-NEBO_WINDOW_SIZE+nebo_canvas_WINDOW_GENERATION_OFFSET], r10
    dec qword [rbx+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET]
    mov qword [r13], 0
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
    jmp .window_create_return
.window_create_headless_rollback:
    mov [rsp+128], rax
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    call nebo_x11_adapter_destroy_window
    mov eax, [rsp+128]
    jmp .window_create_return
.window_create_native_rollback:
    mov [rsp+128], rax
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    call nebo_x11_adapter_destroy_window
    mov eax, [rsp+128]
    call x11_map_platform_status
    jmp .window_create_return
.window_create_adapter:
    call x11_map_platform_status
    jmp .window_create_return
.window_create_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
.window_create_return:
    add rsp, 136
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Mark a backend failure after releasing the native resource.
; rdi=runtime, rsi=handle, rdx=owner, rcx=detail.
x11_backend_failure:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jnz .backend_failure_resolve
    mov r15, r8
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r15
    call nebo_x11_adapter_destroy_window
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_HEADLESS_CLOSE_BACKEND_FAILED
    mov r8, r14
    call nebo_headless_window_backend_close
    jmp .backend_failure_return
.backend_failure_resolve:
    mov eax, ecx
.backend_failure_return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=runtime, rsi=handle, rdx=owner. Exact direct close.
nebo_x11_window_close:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jz .window_close_resolved
    cmp ecx, NEBO_WINDOW_ERROR_BAD_STATE
    jne .window_close_resolve
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve_destroyed_for_close
    test ecx, ecx
    jnz .window_close_resolve
.window_close_resolved:
    mov r14, r8
    cmp dword [r14+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    je .window_close_canonical
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r14
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .window_close_backend
.window_close_canonical:
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_HEADLESS_CLOSE_DIRECT
    xor r8d, r8d
    call nebo_headless_window_backend_close
    jmp .window_close_return
.window_close_backend:
    mov rcx, rax
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_backend_failure
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    jmp .window_close_return
.window_close_resolve:
    mov eax, ecx
.window_close_return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Raw protocol routing and canonical event translation
; ---------------------------------------------------------------------------

; rdi=runtime, rsi=canonical record, rdx=native record, rcx=PlatformEvent.
; eax=WindowError. May publish one key event plus one text event.
x11_translate_platform:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 24
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, [r12+NEBO_WINDOW_HANDLE_OFFSET]
    mov eax, [r14+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    je .platform_shown
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    je .platform_shown
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    je .platform_hidden
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    je .platform_focus_in
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    je .platform_focus_out
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    je .platform_resized
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    je .platform_close
    cmp eax, NEBO_CONSOLE_EVENT_POINTER_MOVE
    je .platform_pointer_move
    cmp eax, NEBO_CONSOLE_EVENT_POINTER_DOWN
    je .platform_pointer_down
    cmp eax, NEBO_CONSOLE_EVENT_POINTER_UP
    je .platform_pointer_up
    cmp eax, NEBO_CONSOLE_EVENT_KEY_DOWN
    je .platform_key_down
    cmp eax, NEBO_CONSOLE_EVENT_KEY_UP
    je .platform_key_up
    cmp eax, NEBO_CONSOLE_EVENT_TEXT_INPUT
    je .platform_text
    xor eax, eax
    jmp .platform_return
.platform_shown:
    mov dword [r12+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_VISIBLE
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_SHOWN
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_hidden:
    mov dword [r12+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_HIDDEN
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_HIDDEN
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_focus_in:
    mov ecx, NEBO_WINDOW_EVENT_FOCUS_GAINED
    jmp .platform_zero
.platform_focus_out:
    mov ecx, NEBO_WINDOW_EVENT_FOCUS_LOST
.platform_zero:
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_resized:
    mov r8, [r14+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov r9, [r14+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    cmp r8, NEBO_WINDOW_MIN_WIDTH
    jb .platform_invalid
    cmp r8, NEBO_WINDOW_MAX_WIDTH
    ja .platform_invalid
    cmp r9, NEBO_WINDOW_MIN_HEIGHT
    jb .platform_invalid
    cmp r9, NEBO_WINDOW_MAX_HEIGHT
    ja .platform_invalid
    mov [r12+NEBO_WINDOW_WIDTH_OFFSET], r8
    mov [r12+NEBO_WINDOW_HEIGHT_OFFSET], r9
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_RESIZED
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_close:
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_CLOSE_REQUESTED
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_pointer_move:
    mov ecx, NEBO_WINDOW_EVENT_POINTER_MOVED
    jmp .platform_pointer
.platform_pointer_down:
    mov ecx, NEBO_WINDOW_EVENT_POINTER_DOWN
    jmp .platform_pointer
.platform_pointer_up:
    mov ecx, NEBO_WINDOW_EVENT_POINTER_UP
.platform_pointer:
    mov r8, [r14+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov r9, [r14+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    xor r10d, r10d
    call x11_push_template
    jmp .platform_return
.platform_key_down:
    mov ecx, NEBO_WINDOW_EVENT_KEY_DOWN
    mov qword [rsp], 1
    jmp .platform_key
.platform_key_up:
    mov ecx, NEBO_WINDOW_EVENT_KEY_UP
    mov qword [rsp], 0
.platform_key:
    mov r8, [r14+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov r9, [r14+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    xor r10d, r10d
    call x11_push_template
    test eax, eax
    jnz .platform_return
    cmp qword [rsp], 1
    jne .platform_return
    cmp dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    jne .platform_return
    mov rdi, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET]
    mov rsi, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET]
    call x11_decode_scalar
    test eax, eax
    jnz .platform_pending_invalid
    mov [rsp+8], r8
    mov r10, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET]
    mov r9, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET]
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_TEXT_INPUT
    mov r8, [rsp+8]
    call x11_push_template
    test eax, eax
    jnz .platform_return
    mov dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 0
    jmp .platform_return
.platform_text:
    mov rdi, [r14+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov rsi, [r14+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    call x11_decode_scalar
    test eax, eax
    jnz .platform_invalid
    mov [rsp+8], r8
    mov r10, [r14+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    mov r9, [r14+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
    mov rdi, rbx
    mov rsi, r15
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_TEXT_INPUT
    mov r8, [rsp+8]
    call x11_push_template
    jmp .platform_return
.platform_pending_invalid:
    mov dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 0
.platform_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
.platform_return:
    add rsp, 24
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=runtime, rsi=raw 32-byte X11 event. eax=WindowError, edx=processed.
nebo_x11_window_translate_raw:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    xor edx, edx
    call x11_validate_runtime
    test eax, eax
    jnz .raw_translate_return
    test r12, r12
    jz .raw_translate_invalid
    mov rdi, r12
    call x11_raw_xid
    test edx, edx
    jz .raw_translate_no_event
    cmp eax, -1
    je .raw_translate_protocol
    test eax, eax
    jz .raw_translate_invalid
    mov rdi, rbx
    mov esi, eax
    call x11_find_xid
    test ecx, ecx
    jnz .raw_translate_stale
    mov r13, rax
    mov r14, r8
    movzx eax, byte [r12]
    and eax, 0x7f
    cmp eax, NEBO_X11_EVENT_EXPOSE
    je .raw_translate_expose
    ; Wheel buttons are normalized separately so press/release does not emit
    ; duplicate pointer-button events.
    cmp eax, NEBO_X11_EVENT_BUTTON_PRESS
    je .raw_translate_wheel_check
    cmp eax, NEBO_X11_EVENT_BUTTON_RELEASE
    jne .raw_translate_normalize
    movzx ecx, byte [r12+1]
    cmp ecx, 4
    jb .raw_translate_normalize
    cmp ecx, 7
    jbe .raw_translate_no_event
    jmp .raw_translate_normalize
.raw_translate_wheel_check:
    movzx ecx, byte [r12+1]
    cmp ecx, 4
    jb .raw_translate_normalize
    cmp ecx, 7
    ja .raw_translate_normalize
    movsx r8, word [r12+24]
    shl r8, NEBO_PLATFORM_SCALE_FRACTION_BITS
    movsx r9, word [r12+26]
    shl r9, NEBO_PLATFORM_SCALE_FRACTION_BITS
    mov eax, r8d
    mov r10d, r9d
    shl r10, 32
    or r8, r10
    xor r9d, r9d
    cmp ecx, 4
    jne .wheel_not_up
    mov r9, 1
    shl r9, 32
    jmp .wheel_delta_ready
.wheel_not_up:
    cmp ecx, 5
    jne .wheel_not_down
    mov r9, -1
    shl r9, 32
    jmp .wheel_delta_ready
.wheel_not_down:
    cmp ecx, 6
    jne .wheel_right
    mov r9d, -1
    jmp .wheel_delta_ready
.wheel_right:
    mov r9d, 1
.wheel_delta_ready:
    movzx edi, word [r12+28]
    call x11_common_modifiers
    mov r10d, eax
    mov rdi, rbx
    mov rsi, [r13+NEBO_WINDOW_HANDLE_OFFSET]
    mov rdx, [r13+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_POINTER_WHEEL
    call x11_push_template
    test eax, eax
    jnz .raw_translate_return
    mov edx, 1
    jmp .raw_translate_return
.raw_translate_expose:
    mov rdi, rbx
    mov rsi, [r13+NEBO_WINDOW_HANDLE_OFFSET]
    mov rdx, [r13+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_WINDOW_EVENT_REDRAW_REQUESTED
    xor r8d, r8d
    xor r9d, r9d
    xor r10d, r10d
    call x11_push_template
    test eax, eax
    jnz .raw_translate_return
    mov edx, 1
    jmp .raw_translate_return
.raw_translate_normalize:
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r14
    mov rdx, r12
    lea rcx, [rbx+NEBO_X11_RUNTIME_PLATFORM_EVENT_OFFSET]
    call nebo_x11_adapter_normalize_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .raw_translate_no_event
    test eax, eax
    jnz .raw_translate_adapter
    mov rdi, rbx
    mov rsi, r13
    mov rdx, r14
    lea rcx, [rbx+NEBO_X11_RUNTIME_PLATFORM_EVENT_OFFSET]
    call x11_translate_platform
    test eax, eax
    jnz .raw_translate_return
    mov edx, 1
    jmp .raw_translate_return
.raw_translate_adapter:
    call x11_map_platform_status
    jmp .raw_translate_return
.raw_translate_protocol:
    or dword [rbx+NEBO_X11_RUNTIME_FLAGS_OFFSET], NEBO_X11_RUNTIME_FLAG_DISCONNECTED
    mov qword [rbx+NEBO_X11_RUNTIME_LAST_ERROR_OFFSET], NEBO_X11_DIAG_PROTOCOL_MALFORMED
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    xor edx, edx
    jmp .raw_translate_return
.raw_translate_stale:
    mov eax, ecx
    xor edx, edx
    jmp .raw_translate_return
.raw_translate_no_event:
    xor eax, eax
    xor edx, edx
    jmp .raw_translate_return
.raw_translate_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    xor edx, edx
.raw_translate_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; Close every active X11 window as BACKEND_FAILED after a socket failure.
; rdi=runtime, rsi=detail. eax=first WindowError or zero.
x11_fail_all:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov [rsp], rsi
    xor r15d, r15d
    xor r14d, r14d
    mov r13, [rbx+NEBO_X11_RUNTIME_CAPACITY_OFFSET]
.fail_all_loop:
    cmp r14, r13
    jae .fail_all_done
    mov r12, r14
    imul r12, NEBO_WINDOW_SIZE
    add r12, [rbx+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET]
    cmp dword [r12+NEBO_WINDOW_BACKEND_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    jne .fail_all_next
    mov eax, [r12+NEBO_WINDOW_STATE_OFFSET]
    cmp eax, NEBO_WINDOW_STATE_CREATED
    je .fail_all_active
    cmp eax, NEBO_WINDOW_STATE_VISIBLE
    je .fail_all_active
    cmp eax, NEBO_WINDOW_STATE_HIDDEN
    jne .fail_all_next
.fail_all_active:
    mov rdi, rbx
    mov rsi, [r12+NEBO_WINDOW_HANDLE_OFFSET]
    mov rdx, [r12+NEBO_WINDOW_OWNER_CONTEXT_OFFSET]
    mov rcx, [rsp]
    call x11_backend_failure
    test eax, eax
    jz .fail_all_next
    test r15d, r15d
    jnz .fail_all_next
    mov r15d, eax
.fail_all_next:
    inc r14
    jmp .fail_all_loop
.fail_all_done:
    mov eax, r15d
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=runtime, rsi=timeout milliseconds. eax=WindowError, edx=processed.
nebo_x11_window_pump_once:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    xor edx, edx
    call x11_validate_runtime
    test eax, eax
    jnz .pump_return
    test dword [rbx+NEBO_X11_RUNTIME_FLAGS_OFFSET], NEBO_X11_RUNTIME_FLAG_DISCONNECTED
    jnz .pump_disconnected
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r12
    lea rdx, [rbx+NEBO_X11_RUNTIME_RAW_EVENT_OFFSET]
    call nebo_x11_adapter_poll_raw
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .pump_empty
    test eax, eax
    jnz .pump_failure
    mov rdi, rbx
    lea rsi, [rbx+NEBO_X11_RUNTIME_RAW_EVENT_OFFSET]
    call nebo_x11_window_translate_raw
    cmp eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    jne .pump_return
    mov r12, [rbx+NEBO_X11_RUNTIME_LAST_ERROR_OFFSET]
    test r12, r12
    jnz .pump_translate_detail
    mov r12d, NEBO_X11_DIAG_PROTOCOL_MALFORMED
.pump_translate_detail:
    mov rdi, rbx
    mov rsi, r12
    call x11_fail_all
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    xor edx, edx
    jmp .pump_return
.pump_failure:
    mov r12, rax
    or dword [rbx+NEBO_X11_RUNTIME_FLAGS_OFFSET], NEBO_X11_RUNTIME_FLAG_DISCONNECTED
    mov [rbx+NEBO_X11_RUNTIME_LAST_STATUS_OFFSET], r12
    mov qword [rbx+NEBO_X11_RUNTIME_LAST_ERROR_OFFSET], NEBO_X11_DIAG_DISCONNECTED
    mov rdi, rbx
    mov rsi, r12
    call x11_fail_all
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    xor edx, edx
    jmp .pump_return
.pump_disconnected:
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    xor edx, edx
    jmp .pump_return
.pump_empty:
    xor eax, eax
    xor edx, edx
.pump_return:
    add rsp, 8
    pop r12
    pop rbx
    ret

; Wait for a canonical state transition while continuing to route all windows.
; rdi=runtime, rsi=handle, rdx=owner, ecx=state, r8=max cycles.
x11_wait_state:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14d, ecx
    mov r15, r8
    cmp r15, NEBO_X11_WAIT_MAX_CYCLES
    ja .wait_state_limit
.wait_state_check:
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jnz .wait_state_resolve
    cmp [rax+NEBO_WINDOW_STATE_OFFSET], r14d
    je .wait_state_ok
    test r15, r15
    jz .wait_state_timeout
    mov rdi, rbx
    mov esi, NEBO_X11_WAIT_SLICE_MS
    call nebo_x11_window_pump_once
    cmp eax, NEBO_WINDOW_ERROR_STALE_HANDLE
    je .wait_state_next
    test eax, eax
    jnz .wait_state_return
.wait_state_next:
    dec r15
    jmp .wait_state_check
.wait_state_timeout:
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_X11_DIAG_LIFECYCLE_TIMEOUT
    call x11_backend_failure
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    jmp .wait_state_return
.wait_state_ok:
    xor eax, eax
    jmp .wait_state_return
.wait_state_limit:
    mov eax, NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
    jmp .wait_state_return
.wait_state_resolve:
    mov eax, ecx
.wait_state_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; ---------------------------------------------------------------------------
; Public bounded native lifecycle
; ---------------------------------------------------------------------------

; rdi=runtime, rsi=handle, rdx=owner.
nebo_x11_window_show:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    call x11_resolve
    test ecx, ecx
    jnz .show_resolve
    mov r14, r8
    mov ecx, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp ecx, NEBO_WINDOW_STATE_CREATED
    je .show_state
    cmp ecx, NEBO_WINDOW_STATE_HIDDEN
    jne .show_bad_state
.show_state:
    mov rdi, rbx
    mov rsi, rax
    call x11_queue_preflight
    test eax, eax
    jnz .show_return
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r14
    call nebo_x11_adapter_map_window
    test eax, eax
    jnz .show_adapter
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_WINDOW_STATE_VISIBLE
    mov r8d, NEBO_X11_WAIT_MAX_CYCLES
    call x11_wait_state
    jmp .show_return
.show_adapter:
    call x11_map_platform_status
    jmp .show_return
.show_resolve:
    mov eax, ecx
    jmp .show_return
.show_bad_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
.show_return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_x11_window_hide:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    call x11_resolve
    test ecx, ecx
    jnz .hide_resolve
    mov r14, r8
    cmp dword [rax+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_VISIBLE
    jne .hide_bad_state
    mov rdi, rbx
    mov rsi, rax
    call x11_queue_preflight
    test eax, eax
    jnz .hide_return
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r14
    call nebo_x11_adapter_unmap_window
    test eax, eax
    jnz .hide_adapter
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_WINDOW_STATE_HIDDEN
    mov r8d, NEBO_X11_WAIT_MAX_CYCLES
    call x11_wait_state
    jmp .hide_return
.hide_adapter:
    call x11_map_platform_status
    jmp .hide_return
.hide_resolve:
    mov eax, ecx
    jmp .hide_return
.hide_bad_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
.hide_return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=width, r8=height.
nebo_x11_window_resize:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    cmp r14, NEBO_WINDOW_MIN_WIDTH
    jb .resize_limit
    cmp r14, NEBO_WINDOW_MAX_WIDTH
    ja .resize_limit
    cmp r15, NEBO_WINDOW_MIN_HEIGHT
    jb .resize_limit
    cmp r15, NEBO_WINDOW_MAX_HEIGHT
    ja .resize_limit
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jnz .resize_resolve
    mov r10, r8
    mov ecx, [rax+NEBO_WINDOW_STATE_OFFSET]
    cmp ecx, NEBO_WINDOW_STATE_CREATED
    je .resize_state
    cmp ecx, NEBO_WINDOW_STATE_VISIBLE
    je .resize_state
    cmp ecx, NEBO_WINDOW_STATE_HIDDEN
    jne .resize_bad_state
.resize_state:
    mov rdi, rbx
    mov rsi, rax
    call x11_queue_preflight
    test eax, eax
    jnz .resize_return
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r10
    mov rdx, r14
    mov rcx, r15
    call nebo_x11_adapter_configure_window_bounded
    test eax, eax
    jnz .resize_adapter
    mov qword [rsp], NEBO_X11_WAIT_MAX_CYCLES
.resize_wait:
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jnz .resize_resolve
    cmp [rax+NEBO_WINDOW_WIDTH_OFFSET], r14
    jne .resize_pump
    cmp [rax+NEBO_WINDOW_HEIGHT_OFFSET], r15
    je .resize_ok
.resize_pump:
    cmp qword [rsp], 0
    je .resize_timeout
    mov rdi, rbx
    mov esi, NEBO_X11_WAIT_SLICE_MS
    call nebo_x11_window_pump_once
    test eax, eax
    jnz .resize_return
    dec qword [rsp]
    jmp .resize_wait
.resize_timeout:
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov ecx, NEBO_X11_DIAG_LIFECYCLE_TIMEOUT
    call x11_backend_failure
    mov eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    jmp .resize_return
.resize_ok:
    xor eax, eax
    jmp .resize_return
.resize_adapter:
    call x11_map_platform_status
    jmp .resize_return
.resize_resolve:
    mov eax, ecx
    jmp .resize_return
.resize_bad_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
    jmp .resize_return
.resize_limit:
    mov eax, NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE
.resize_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=runtime, rsi=handle, rdx=owner, rcx=UTF-8, r8=byte length.
nebo_x11_window_set_title:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    cmp r15, NEBO_WINDOW_MAX_TITLE_BYTES
    ja .set_title_limit
    mov rdi, r14
    mov rsi, r15
    call x11_validate_utf8
    test eax, eax
    jnz .set_title_return
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call x11_resolve
    test ecx, ecx
    jnz .set_title_resolve
    cmp [rax+NEBO_WINDOW_TITLE_CAPACITY_OFFSET], r15
    jb .set_title_limit
    mov r10, r8
    mov rdi, [rbx+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, r10
    mov rdx, r14
    mov rcx, r15
    call nebo_x11_adapter_set_window_title
    test eax, eax
    jnz .set_title_adapter
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    mov rcx, r14
    mov r8, r15
    call nebo_headless_window_set_title
    jmp .set_title_return
.set_title_adapter:
    call x11_map_platform_status
    jmp .set_title_return
.set_title_resolve:
    mov eax, ecx
    jmp .set_title_return
.set_title_limit:
    mov eax, NEBO_WINDOW_ERROR_TITLE_TOO_LONG
.set_title_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_x11_window_request_redraw:
    jmp nebo_headless_window_request_redraw

; rdi=runtime, rsi=handle, rdx=owner, rcx=out stream.
nebo_x11_window_events:
    jmp nebo_headless_window_events

; Complete the previous CLOSE_REQUESTED dispatch without letting the generic
; headless stream close skip native X11 cleanup. rdi=stream.
x11_finish_dispatch:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    test rbx, rbx
    jz .finish_invalid
    mov r12, [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET]
    test r12, r12
    jz .finish_ok
    cmp dword [r12+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_CLOSE_REQUESTED
    jne .finish_state
    mov rax, [r12+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
    cmp rax, [rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET]
    jne .finish_state
    mov rax, [r12+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
    cmp rax, [rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
    jne .finish_state
    mov eax, [r12+NEBO_WINDOW_EVENT_FLAGS_OFFSET]
    test eax, NEBO_WINDOW_EVENT_FLAG_PREVENTED
    jnz .finish_clear
    mov r13, [rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
    mov r14, [rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
    mov r15, [rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
    mov rdi, r13
    mov rsi, r14
    mov rdx, r15
    call nebo_x11_window_close
    cmp eax, NEBO_WINDOW_ERROR_ALREADY_CLOSED
    je .finish_clear
    test eax, eax
    jnz .finish_return
.finish_clear:
    mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET], 0
    mov qword [rbx+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET], 0
.finish_ok:
    xor eax, eax
    jmp .finish_return
.finish_invalid:
    mov eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT
    jmp .finish_return
.finish_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
.finish_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=stream, rsi=out event. eax=status, edx=ready.
nebo_x11_event_stream_poll:
    push rbx
    push r12
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov rdi, rbx
    call x11_finish_dispatch
    test eax, eax
    jnz .stream_poll_fail
    mov rdi, [rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
    xor esi, esi
    call nebo_x11_window_pump_once
    cmp eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE
    jne .stream_poll_delegate
    ; A backend failure enqueues terminal events; continue to dequeue them.
.stream_poll_delegate:
    mov rdi, rbx
    mov rsi, r12
    call nebo_headless_event_stream_poll
    jmp .stream_poll_return
.stream_poll_fail:
    xor edx, edx
.stream_poll_return:
    add rsp, 8
    pop r12
    pop rbx
    ret

; rdi=stream, rsi=out event, rdx=max 1ms waits.
nebo_x11_event_stream_wait:
    push rbp
    mov rbp, rsp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    cmp r13, NEBO_X11_WAIT_MAX_CYCLES
    ja .stream_wait_limit
    mov rdi, rbx
    mov rsi, r12
    call nebo_x11_event_stream_poll
    test eax, eax
    jnz .stream_wait_return
    test edx, edx
    jnz .stream_wait_return
    test r13, r13
    jz .stream_wait_empty
.stream_wait_loop:
    mov r14, [rbx+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET]
    mov r15, [rbx+NEBO_HEADLESS_STREAM_HANDLE_OFFSET]
    mov rdi, r14
    mov rsi, r15
    mov rdx, [rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
    call x11_resolve
    test ecx, ecx
    jnz .stream_wait_resolve
    mov [rsp], r8
    mov rdi, [rax+NEBO_WINDOW_CANCELLATION_PTR_OFFSET]
    call nebo_cancellation_check
    test eax, eax
    jz .stream_wait_pump
    mov rdi, [r14+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET]
    mov rsi, [rsp]
    call nebo_x11_adapter_destroy_window
    mov rdi, r14
    mov rsi, r15
    mov rdx, [rbx+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET]
    mov ecx, NEBO_HEADLESS_CLOSE_CANCELLED
    mov r8, rax
    call nebo_headless_window_backend_close
    mov rdi, rbx
    mov rsi, r12
    call nebo_x11_event_stream_poll
    jmp .stream_wait_return
.stream_wait_pump:
    mov rdi, r14
    mov esi, NEBO_X11_WAIT_SLICE_MS
    call nebo_x11_window_pump_once
    mov rdi, rbx
    mov rsi, r12
    call nebo_x11_event_stream_poll
    test eax, eax
    jnz .stream_wait_return
    test edx, edx
    jnz .stream_wait_return
    dec r13
    jnz .stream_wait_loop
.stream_wait_empty:
    xor eax, eax
    xor edx, edx
    jmp .stream_wait_return
.stream_wait_resolve:
    mov eax, ecx
    xor edx, edx
    jmp .stream_wait_return
.stream_wait_limit:
    mov eax, NEBO_WINDOW_ERROR_LIMIT_EXCEEDED
    xor edx, edx
.stream_wait_return:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; rdi=stream.
nebo_x11_event_stream_release:
    push rbx
    mov rbx, rdi
    mov rdi, rbx
    call x11_finish_dispatch
    test eax, eax
    jnz .stream_release_return
    mov rdi, rbx
    call nebo_headless_event_stream_release
.stream_release_return:
    pop rbx
    ret

; rdi=runtime, rsi=handle, rdx=owner.
nebo_x11_window_reclaim:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    call x11_resolve
    test ecx, ecx
    jnz .reclaim_resolve
    mov r14, r8
    mov eax, [r14+NEBO_X11_WINDOW_STATE_OFFSET]
    cmp eax, NEBO_X11_WINDOW_STATE_DESTROYED
    jne .reclaim_state
    mov rdi, rbx
    mov rsi, r12
    mov rdx, r13
    call nebo_headless_window_reclaim
    test eax, eax
    jnz .reclaim_return
    mov rdi, r14
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_QWORDS
    cld
    rep stosq
    xor eax, eax
    jmp .reclaim_return
.reclaim_resolve:
    mov eax, ecx
    jmp .reclaim_return
.reclaim_state:
    mov eax, NEBO_WINDOW_ERROR_BAD_STATE
.reclaim_return:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Typed event accessors: exact parity with F04 pointer-free WindowEvent.
; ---------------------------------------------------------------------------

nebo_x11_window_event_kind:
    jmp nebo_headless_window_event_kind

nebo_x11_window_event_key:
    jmp nebo_headless_window_event_key

nebo_x11_window_event_pointer:
    jmp nebo_headless_window_event_pointer

nebo_x11_window_event_text_input:
    jmp nebo_headless_window_event_text_input

nebo_x11_window_event_resize:
    jmp nebo_headless_window_event_resize

nebo_x11_window_event_prevent_default:
    jmp nebo_headless_window_event_prevent_default

section .note.GNU-stack noalloc noexec nowrite progbits
