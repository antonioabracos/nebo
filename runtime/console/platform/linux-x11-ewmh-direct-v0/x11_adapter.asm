; Nebo linux-x11-ewmh-direct-v0 Platform Adapter — MF051–MF053
bits 64
default rel

%define NEBO_X11_ADAPTER_IMPLEMENTATION 1
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_capabilities_certify
extern nebo_platform_window_handle_make
extern nebo_platform_report_init
extern nebo_platform_report_certify

global nebo_x11_adapter_init
global nebo_x11_adapter_validate
global nebo_x11_adapter_shutdown
global nebo_x11_adapter_report
global nebo_x11_adapter_create_window
global nebo_x11_adapter_destroy_window
global nebo_x11_adapter_present
global nebo_x11_adapter_poll_event
global nebo_x11_adapter_normalize_event
global nebo_x11_adapter_minimize_window
global nebo_x11_adapter_maximize_window
global nebo_x11_adapter_restore_window
global nebo_x11_adapter_begin_window_drag
global nebo_x11_adapter_begin_window_resize
global nebo_x11_adapter_set_window_size
global nebo_x11_adapter_request_close
global nebo_x11_adapter_poll_raw
global nebo_x11_adapter_map_window
global nebo_x11_adapter_unmap_window
global nebo_x11_adapter_set_window_title
global nebo_x11_adapter_configure_window_bounded

section .rodata align=8
x11_atom_motif_hints: db "_MOTIF_WM_HINTS"
x11_atom_wm_protocols: db "WM_PROTOCOLS"
x11_atom_wm_delete_window: db "WM_DELETE_WINDOW"
x11_atom_wm_change_state: db "WM_CHANGE_STATE"
x11_atom_net_wm_state: db "_NET_WM_STATE"
x11_atom_net_wm_state_max_horz: db "_NET_WM_STATE_MAXIMIZED_HORZ"
x11_atom_net_wm_state_max_vert: db "_NET_WM_STATE_MAXIMIZED_VERT"
x11_atom_net_wm_moveresize: db "_NET_WM_MOVERESIZE"
x11_atom_utf8_string: db "UTF8_STRING"
x11_atom_net_wm_name: db "_NET_WM_NAME"

section .text

; ---------------------------------------------------------------------------
; Internal I/O and validation helpers
; ---------------------------------------------------------------------------

; write_all(fd, bytes*, length) -> status
x11_write_all_internal:
    test rsi, rsi
    jz .write_invalid
    test rdx, rdx
    jz .write_ok
    mov r8, rsi
    mov r9, rdx
.write_loop:
    mov eax, NEBO_LINUX_SYS_WRITE
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jg .write_progress
    cmp rax, -NEBO_LINUX_EINTR
    je .write_loop
    mov eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    ret
.write_progress:
    add r8, rax
    sub r9, rax
    jnz .write_loop
.write_ok:
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.write_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; read_exact(fd, bytes*, length) -> status
x11_read_exact_internal:
    test rsi, rsi
    jz .read_invalid
    test rdx, rdx
    jz .read_ok
    mov r8, rsi
    mov r9, rdx
.read_loop:
    mov eax, NEBO_LINUX_SYS_READ
    mov rsi, r8
    mov rdx, r9
    syscall
    test rax, rax
    jg .read_progress
    cmp rax, -NEBO_LINUX_EINTR
    je .read_loop
    mov eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    ret
.read_progress:
    add r8, rax
    sub r9, rax
    jnz .read_loop
.read_ok:
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.read_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; adapter failure helper. RDI adapter*, ESI status, EDX error.
x11_adapter_failure_internal:
    test rdi, rdi
    jz .failure_return
    mov [rdi+NEBO_X11_ADAPTER_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_X11_ADAPTER_LAST_ERROR_OFFSET], rdx
.failure_return:
    mov eax, esi
    ret

; allocate one native XID from the server-provided base/mask.
x11_allocate_xid_internal:
    test rdi, rdi
    jz .xid_invalid
    mov eax, [rdi+NEBO_X11_ADAPTER_RESOURCE_COUNTER_OFFSET]
    inc eax
    jz .xid_limit
    mov [rdi+NEBO_X11_ADAPTER_RESOURCE_COUNTER_OFFSET], eax
    and eax, [rdi+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET]
    test eax, eax
    jz .xid_limit
    or eax, [rdi+NEBO_X11_ADAPTER_RESOURCE_ID_BASE_OFFSET]
    ret
.xid_limit:
.xid_invalid:
    xor eax, eax
    ret

; Validate a bound canonical software surface without importing renderer code.
; RDI=surface*, RSI=expected width, RDX=expected height.
x11_surface_validate_internal:
    test rdi, rdi
    jz .surface_invalid
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], 0
    je .surface_state
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], rsi
    jne .surface_state
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], rdx
    jne .surface_state
    cmp qword [rdi+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    jne .surface_format
    mov rax, rsi
    shl rax, 2
    cmp rax, [rdi+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    jne .surface_format
    mov rax, [rdi+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET]
    and rax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    cmp rax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    jne .surface_state
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.surface_format:
    mov eax, NEBO_PLATFORM_STATUS_UNSUPPORTED_FORMAT
    ret
.surface_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    ret
.surface_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; Emit one normalized PlatformEventDescriptor.
; RDI=adapter*, RSI=window*, RDX=out event*, ECX=kind, R8=payload0, R9=payload1.
x11_emit_event_internal:
    test rdi, rdi
    jz .emit_invalid
    test rsi, rsi
    jz .emit_invalid
    test rdx, rdx
    jz .emit_invalid
    inc qword [rdi+NEBO_X11_ADAPTER_EVENT_SEQUENCE_OFFSET]
    mov rax, [rdi+NEBO_X11_ADAPTER_EVENT_SEQUENCE_OFFSET]
    mov [rdx+NEBO_CONSOLE_EVENT_ID_OFFSET], rax
    mov r10, [rsi+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    mov [rdx+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], r10
    mov [rdx+NEBO_CONSOLE_EVENT_KIND_OFFSET], ecx
    mov dword [rdx+NEBO_CONSOLE_EVENT_FLAGS_OFFSET], NEBO_PLATFORM_EVENT_FLAG_NATIVE
    mov qword [rdx+NEBO_CONSOLE_EVENT_TIMESTAMP_OFFSET], 0
    mov [rdx+NEBO_CONSOLE_EVENT_SEQUENCE_OFFSET], rax
    mov [rdx+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], r8
    mov [rdx+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], r9
    mov qword [rdx+NEBO_CONSOLE_EVENT_RESERVED_OFFSET], 0
    mov [rsi+NEBO_X11_WINDOW_LAST_EVENT_SEQUENCE_OFFSET], rax
    mov qword [rsi+NEBO_X11_WINDOW_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    mov qword [rsi+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_NONE
    mov eax, NEBO_PLATFORM_STATUS_OK
    ret
.emit_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    ret

; Translate X11 modifier state to the common platform modifier contract.
; EDI=native state -> EAX=NEBO_PLATFORM_MOD_*.
x11_common_modifiers_internal:
    xor eax, eax
    test edi, NEBO_X11_STATE_SHIFT
    jz .mods_control
    or eax, NEBO_PLATFORM_MOD_SHIFT
.mods_control:
    test edi, NEBO_X11_STATE_CONTROL
    jz .mods_alt
    or eax, NEBO_PLATFORM_MOD_CONTROL
.mods_alt:
    test edi, NEBO_X11_STATE_MOD1
    jz .mods_super
    or eax, NEBO_PLATFORM_MOD_ALT
.mods_super:
    test edi, NEBO_X11_STATE_MOD4
    jz .mods_done
    or eax, NEBO_PLATFORM_MOD_SUPER
.mods_done:
    ret

; Lookup the server-provided keysym for one keycode and modifier state.
; RDI=adapter*, ESI=keycode, EDX=X11 state -> EAX=keysym or zero.
x11_lookup_keysym_internal:
    test rdi, rdi
    jz .lookup_missing
    cmp byte [rdi+NEBO_X11_ADAPTER_KEYMAP_READY_OFFSET], 1
    jne .lookup_missing
    movzx ecx, byte [rdi+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET]
    cmp esi, ecx
    jb .lookup_missing
    movzx ecx, byte [rdi+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET]
    cmp esi, ecx
    ja .lookup_missing
    mov eax, esi
    shl rax, 3
    lea rcx, [rdi+NEBO_X11_ADAPTER_KEYMAP_OFFSET+rax]
    mov eax, [rcx+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET]
    mov r8d, [rcx+NEBO_X11_KEYMAP_ENTRY_SHIFTED_OFFSET]
    test r8d, r8d
    jnz .lookup_shift_ready
    mov r8d, eax
.lookup_shift_ready:
    mov r9d, edx
    and r9d, (NEBO_X11_STATE_SHIFT | NEBO_X11_STATE_LOCK)
    cmp eax, 'a'
    jb .lookup_plain_shift
    cmp eax, 'z'
    ja .lookup_plain_shift
    cmp r9d, NEBO_X11_STATE_SHIFT
    je .lookup_shifted
    cmp r9d, NEBO_X11_STATE_LOCK
    je .lookup_shifted
    ret
.lookup_plain_shift:
    test edx, NEBO_X11_STATE_SHIFT
    jz .lookup_done
.lookup_shifted:
    mov eax, r8d
.lookup_done:
    ret
.lookup_missing:
    xor eax, eax
    ret

; Map selected X11 keysyms to the frozen logical editing key contract.
; EDI=keysym -> EAX=NEBO_PLATFORM_KEY_*.
x11_keysym_to_logical_internal:
    mov eax, NEBO_PLATFORM_KEY_BACKSPACE
    cmp edi, NEBO_X11_KEYSYM_BACKSPACE
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_TAB
    cmp edi, NEBO_X11_KEYSYM_TAB
    je .logical_done
    cmp edi, NEBO_X11_KEYSYM_ISO_LEFT_TAB
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_ENTER
    cmp edi, NEBO_X11_KEYSYM_RETURN
    je .logical_done
    cmp edi, NEBO_X11_KEYSYM_KP_ENTER
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_HOME
    cmp edi, NEBO_X11_KEYSYM_HOME
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_LEFT
    cmp edi, NEBO_X11_KEYSYM_LEFT
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_RIGHT
    cmp edi, NEBO_X11_KEYSYM_RIGHT
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_END
    cmp edi, NEBO_X11_KEYSYM_END
    je .logical_done
    mov eax, NEBO_PLATFORM_KEY_DELETE
    cmp edi, NEBO_X11_KEYSYM_DELETE
    je .logical_done
    xor eax, eax
.logical_done:
    ret

; Convert one printable keysym to packed UTF-8.
; EDI=keysym -> RAX=bytes little-endian, EDX=length (zero for non-text).
x11_keysym_to_utf8_internal:
    xor eax, eax
    xor edx, edx
    mov ecx, edi
    cmp ecx, 0x20
    jb .utf8_done
    cmp ecx, 0x7e
    jbe .utf8_codepoint
    cmp ecx, 0xa0
    jb .utf8_unicode_form
    cmp ecx, 0xff
    jbe .utf8_codepoint
.utf8_unicode_form:
    mov eax, ecx
    and eax, 0xff000000
    cmp eax, 0x01000000
    jne .utf8_done
    and ecx, 0x00ffffff
.utf8_codepoint:
    cmp ecx, 0x10ffff
    ja .utf8_done
    cmp ecx, 0xd800
    jb .utf8_encode
    cmp ecx, 0xdfff
    jbe .utf8_done
.utf8_encode:
    cmp ecx, 0x7f
    ja .utf8_two
    mov eax, ecx
    mov edx, 1
    ret
.utf8_two:
    cmp ecx, 0x7ff
    ja .utf8_three
    mov eax, ecx
    and eax, 0x3f
    or eax, 0x80
    shl eax, 8
    mov r8d, ecx
    shr r8d, 6
    or r8d, 0xc0
    or eax, r8d
    mov edx, 2
    ret
.utf8_three:
    cmp ecx, 0xffff
    ja .utf8_four
    mov eax, ecx
    and eax, 0x3f
    or eax, 0x80
    shl eax, 8
    mov r8d, ecx
    shr r8d, 6
    and r8d, 0x3f
    or r8d, 0x80
    or eax, r8d
    shl eax, 8
    mov r8d, ecx
    shr r8d, 12
    or r8d, 0xe0
    or eax, r8d
    mov edx, 3
    ret
.utf8_four:
    mov eax, ecx
    and eax, 0x3f
    or eax, 0x80
    shl eax, 8
    mov r8d, ecx
    shr r8d, 6
    and r8d, 0x3f
    or r8d, 0x80
    or eax, r8d
    shl eax, 8
    mov r8d, ecx
    shr r8d, 12
    and r8d, 0x3f
    or r8d, 0x80
    or eax, r8d
    shl eax, 8
    mov r8d, ecx
    shr r8d, 18
    or r8d, 0xf0
    or eax, r8d
    mov edx, 4
.utf8_done:
    ret

; Load the canonical server keyboard mapping using the X11 core protocol.
; RDI=adapter* -> platform status.
x11_load_keyboard_mapping_internal:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    test r12, r12
    jz .keymap_invalid
    movzx r14d, byte [r12+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET]
    movzx eax, byte [r12+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET]
    cmp eax, r14d
    jb .keymap_protocol
    sub eax, r14d
    inc eax
    test eax, eax
    jz .keymap_protocol
    cmp eax, 255
    ja .keymap_protocol
    mov r13d, eax
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 4
    cld
    rep stosq
    mov byte [rbx], NEBO_X11_OP_GET_KEYBOARD_MAPPING
    mov word [rbx+2], 2
    mov byte [rbx+4], r14b
    mov byte [rbx+5], r13b
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .keymap_done
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 32
    call x11_read_exact_internal
    test eax, eax
    jnz .keymap_done
    cmp byte [rbx], 1
    jne .keymap_protocol
    movzx r15d, byte [rbx+1]
    test r15d, r15d
    jz .keymap_protocol
    mov eax, [rbx+4]
    mov ecx, r13d
    imul ecx, r15d
    cmp eax, ecx
    jne .keymap_protocol
    mov ebp, eax
    shl rbp, 2
    mov rax, rbp
    add rax, 32
    cmp rax, [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET]
    ja .keymap_capability
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    lea rsi, [rbx+32]
    mov rdx, rbp
    call x11_read_exact_internal
    test eax, eax
    jnz .keymap_done
    mov [r12+NEBO_X11_ADAPTER_KEYSYMS_PER_KEYCODE_OFFSET], r15b
    xor ecx, ecx
.keymap_copy_loop:
    cmp ecx, r13d
    jae .keymap_ready
    mov eax, ecx
    add eax, r14d
    mov edx, eax
    shl rdx, 3
    lea rdi, [r12+NEBO_X11_ADAPTER_KEYMAP_OFFSET+rdx]
    mov eax, ecx
    imul eax, r15d
    shl rax, 2
    lea rsi, [rbx+32+rax]
    mov eax, [rsi]
    mov [rdi+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET], eax
    cmp r15d, 1
    je .keymap_copy_same
    mov eax, [rsi+4]
    test eax, eax
    jnz .keymap_copy_shift
.keymap_copy_same:
    mov eax, [rdi+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET]
.keymap_copy_shift:
    mov [rdi+NEBO_X11_KEYMAP_ENTRY_SHIFTED_OFFSET], eax
    inc ecx
    jmp .keymap_copy_loop
.keymap_ready:
    mov byte [r12+NEBO_X11_ADAPTER_KEYMAP_READY_OFFSET], 1
    mov qword [r12+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    xor eax, eax
    jmp .keymap_done
.keymap_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
    jmp .keymap_done
.keymap_capability:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jmp .keymap_done
.keymap_protocol:
    mov eax, NEBO_PLATFORM_STATUS_PROTOCOL_FAILURE
.keymap_done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; Send InternAtom and synchronously read its reply.
; RDI=adapter*, RSI=name*, RDX=name length, RCX=out atom*.
x11_intern_atom_internal:
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
    jz .atom_invalid
    test r13, r13
    jz .atom_invalid
    test r14, r14
    jz .atom_invalid
    test r15, r15
    jz .atom_invalid
    mov dword [r15], 0
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov r10, r14
    add r10, 3
    and r10, -4
    add r10, 8
    cmp r10, [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET]
    ja .atom_limit
    mov rdi, rbx
    xor eax, eax
    mov rcx, r10
    cld
    rep stosb
    mov byte [rbx], NEBO_X11_OP_INTERN_ATOM
    mov byte [rbx+1], 0
    mov rax, r10
    shr rax, 2
    mov [rbx+2], ax
    mov [rbx+4], r14w
    lea rdi, [rbx+8]
    mov rsi, r13
    mov rcx, r14
    cld
    rep movsb
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov rdx, r10
    call x11_write_all_internal
    test eax, eax
    jnz .atom_done
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, NEBO_X11_EVENT_SIZE
    call x11_read_exact_internal
    test eax, eax
    jnz .atom_done
    cmp byte [rbx], 1
    jne .atom_protocol
    mov eax, [rbx+8]
    test eax, eax
    jz .atom_protocol
    mov [r15], eax
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .atom_done
.atom_protocol:
    mov eax, NEBO_PLATFORM_STATUS_PROTOCOL_FAILURE
    jmp .atom_done
.atom_limit:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jmp .atom_done
.atom_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.atom_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Validate an adapter-owned live window for native actions.
; RDI=adapter*, RSI=window*.
x11_window_action_validate_internal:
    push r12
    push r13
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .action_validate_done
    test r13, r13
    jz .action_validate_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .action_validate_invalid
    cmp qword [r13+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], NEBO_PLATFORM_WINDOW_HANDLE_INVALID
    je .action_validate_invalid
    cmp dword [r13+NEBO_X11_WINDOW_XID_OFFSET], 0
    je .action_validate_state
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    je .action_validate_ok
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .action_validate_state
.action_validate_ok:
    xor eax, eax
    jmp .action_validate_done
.action_validate_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .action_validate_done
.action_validate_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.action_validate_done:
    add rsp, 8
    pop r13
    pop r12
    ret

; Send one ICCCM/EWMH ClientMessage to the root window.
; RDI=adapter*, RSI=window*, EDX=message atom, RCX=pointer to 5 dwords.
x11_send_client_message_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15, rcx
    test r15, r15
    jz .client_invalid
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 44
    cld
    rep stosb
    mov byte [rbx], NEBO_X11_OP_SEND_EVENT
    mov byte [rbx+1], 0
    mov word [rbx+2], 11
    mov eax, [r12+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [rbx+4], eax
    mov dword [rbx+8], (NEBO_X11_EVENT_MASK_SUBSTRUCTURE_NOTIFY | NEBO_X11_EVENT_MASK_SUBSTRUCTURE_REDIRECT)
    mov byte [rbx+12], NEBO_X11_EVENT_CLIENT_MESSAGE
    mov byte [rbx+13], 32
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rbx+16], eax
    mov [rbx+20], r14d
    mov eax, [r15]
    mov [rbx+24], eax
    mov eax, [r15+4]
    mov [rbx+28], eax
    mov eax, [r15+8]
    mov [rbx+32], eax
    mov eax, [r15+12]
    mov [rbx+36], eax
    mov eax, [r15+16]
    mov [rbx+40], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 44
    call x11_write_all_internal
    test eax, eax
    jnz .client_done
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_X11_ADAPTER_NATIVE_ACTION_SEQUENCE_OFFSET]
    mov rax, [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [r13+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], rax
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .client_done
.client_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.client_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Perform X11 connection setup and parse the first screen/pixmap format.
; RDI=adapter*, RSI=config*.
x11_setup_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov r14, [r13+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET]
    mov r15, [r13+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET]
    cmp r14, NEBO_X11_MAX_AUTH_BYTES
    ja .setup_capability
    cmp r15, NEBO_X11_MAX_AUTH_BYTES
    ja .setup_capability
    test r14, r14
    jz .setup_no_auth_name
    cmp r14, NEBO_X11_AUTH_NAME_LENGTH
    jne .setup_auth
    cmp qword [r13+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET], 0
    je .setup_auth
.setup_no_auth_name:
    test r15, r15
    jz .setup_lengths
    test r14, r14
    jz .setup_auth
    cmp qword [r13+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET], 0
    je .setup_auth
.setup_lengths:
    mov r8, r14
    add r8, 3
    and r8, -4
    mov r9, r15
    add r9, 3
    and r9, -4
    lea r10, [r8+r9+12]
    cmp r10, [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET]
    ja .setup_capability
    mov rdi, rbx
    xor eax, eax
    mov rcx, r10
    cld
    rep stosb
    mov byte [rbx], 'l'
    mov word [rbx+2], 11
    mov word [rbx+4], 0
    mov [rbx+6], r14w
    mov [rbx+8], r15w
    test r14, r14
    jz .setup_copy_auth_data
    lea rdi, [rbx+12]
    mov rsi, [r13+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET]
    mov rcx, r14
    cld
    rep movsb
.setup_copy_auth_data:
    test r15, r15
    jz .setup_send
    lea rdi, [rbx+12+r8]
    mov rsi, [r13+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET]
    mov rcx, r15
    cld
    rep movsb
.setup_send:
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov rdx, r10
    call x11_write_all_internal
    test eax, eax
    jnz .setup_done
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 8
    call x11_read_exact_internal
    test eax, eax
    jnz .setup_done
    cmp byte [rbx], NEBO_X11_SETUP_SUCCESS
    jne .setup_auth
    movzx r14d, word [rbx+6]
    shl r14, 2
    cmp r14, [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET]
    ja .setup_capability
    cmp r14, 72
    jb .setup_protocol
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov rdx, r14
    call x11_read_exact_internal
    test eax, eax
    jnz .setup_done
    mov eax, [rbx+4]
    mov [r12+NEBO_X11_ADAPTER_RESOURCE_ID_BASE_OFFSET], eax
    mov eax, [rbx+8]
    mov [r12+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET], eax
    movzx eax, word [rbx+18]
    mov [r12+NEBO_X11_ADAPTER_MAX_REQUEST_UNITS_OFFSET], eax
    mov al, [rbx+22]
    mov [r12+NEBO_X11_ADAPTER_IMAGE_BYTE_ORDER_OFFSET], al
    mov al, [rbx+26]
    mov [r12+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET], al
    mov al, [rbx+27]
    mov [r12+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET], al
    cmp byte [rbx+20], 1
    jb .setup_protocol
    movzx r8d, word [rbx+16]
    add r8, 3
    and r8, -4
    movzx r9d, byte [rbx+21]
    lea r10, [rbx+NEBO_X11_SETUP_FIXED_SIZE+r8]
    mov r11, r9
    shl r11, 3
    add r10, r11
    mov rax, r10
    sub rax, rbx
    add rax, NEBO_X11_SCREEN_FIXED_SIZE
    cmp rax, r14
    ja .setup_protocol
    mov eax, [r10]
    mov [r12+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET], eax
    mov eax, [r10+8]
    mov [r12+NEBO_X11_ADAPTER_WHITE_PIXEL_OFFSET], eax
    mov eax, [r10+12]
    mov [r12+NEBO_X11_ADAPTER_BLACK_PIXEL_OFFSET], eax
    movzx eax, word [r10+20]
    mov [r12+NEBO_X11_ADAPTER_SCREEN_WIDTH_OFFSET], ax
    movzx eax, word [r10+22]
    mov [r12+NEBO_X11_ADAPTER_SCREEN_HEIGHT_OFFSET], ax
    mov eax, [r10+32]
    mov [r12+NEBO_X11_ADAPTER_ROOT_VISUAL_OFFSET], eax
    mov al, [r10+38]
    mov [r12+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET], al
    lea r11, [rbx+NEBO_X11_SETUP_FIXED_SIZE+r8]
    xor ecx, ecx
.setup_format_loop:
    cmp rcx, r9
    jae .setup_format_missing
    mov al, [r11]
    cmp al, [r12+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET]
    je .setup_format_found
    add r11, NEBO_X11_PIXMAP_FORMAT_SIZE
    inc rcx
    jmp .setup_format_loop
.setup_format_found:
    mov al, [r11+1]
    mov [r12+NEBO_X11_ADAPTER_BITS_PER_PIXEL_OFFSET], al
    mov al, [r11+2]
    mov [r12+NEBO_X11_ADAPTER_SCANLINE_PAD_OFFSET], al
    cmp byte [r12+NEBO_X11_ADAPTER_IMAGE_BYTE_ORDER_OFFSET], NEBO_X11_BYTE_ORDER_LSB_FIRST
    jne .setup_format_missing
    cmp byte [r12+NEBO_X11_ADAPTER_BITS_PER_PIXEL_OFFSET], 32
    jne .setup_format_missing
    cmp byte [r12+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET], 24
    jne .setup_format_missing
    cmp byte [r12+NEBO_X11_ADAPTER_SCANLINE_PAD_OFFSET], 32
    jne .setup_format_missing
    cmp dword [r12+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET], 1
    jb .setup_protocol
    cmp dword [r12+NEBO_X11_ADAPTER_MAX_REQUEST_UNITS_OFFSET], 7
    jb .setup_protocol
    mov qword [r12+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    mov qword [r12+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF052_REQUIRED_CAPABILITIES
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .setup_done
.setup_format_missing:
    mov eax, NEBO_PLATFORM_STATUS_UNSUPPORTED_FORMAT
    jmp .setup_done
.setup_auth:
    mov eax, NEBO_PLATFORM_STATUS_AUTH_FAILURE
    jmp .setup_done
.setup_capability:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jmp .setup_done
.setup_protocol:
    mov eax, NEBO_PLATFORM_STATUS_PROTOCOL_FAILURE
.setup_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Public adapter lifecycle
; ---------------------------------------------------------------------------

; init(adapter*, config*) -> platform status
nebo_x11_adapter_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .init_invalid
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    mov qword [r12+NEBO_X11_ADAPTER_FD_OFFSET], -1
    test r13, r13
    jz .init_invalid_after_zero
    mov rax, [r13+NEBO_X11_CONFIG_FLAGS_OFFSET]
    and rax, NEBO_X11_CONFIG_REQUIRED_FLAGS
    cmp rax, NEBO_X11_CONFIG_REQUIRED_FLAGS
    jne .init_invalid_after_zero
    cmp qword [r13+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET], 0
    je .init_invalid_after_zero
    mov rax, [r13+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET]
    cmp rax, 3
    jb .init_invalid_after_zero
    cmp rax, NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
    ja .init_invalid_after_zero
    cmp qword [r13+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET], 0
    je .init_invalid_after_zero
    cmp qword [r13+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET], NEBO_X11_MIN_SCRATCH_CAPACITY
    jb .init_invalid_after_zero
    mov rax, [r13+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET]
    test rax, rax
    jnz .init_required_ready
    mov rax, NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
.init_required_ready:
    mov [r12+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], rax
    mov rax, [r13+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET]
    mov [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov rax, [r13+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET]
    mov [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], rax
    mov dword [r12+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_SLOT_OFFSET], 1
    mov qword [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_GENERATION_OFFSET], 1
    mov eax, NEBO_LINUX_SYS_SOCKET
    mov edi, NEBO_LINUX_AF_UNIX
    mov esi, NEBO_LINUX_SOCK_STREAM
    xor edx, edx
    syscall
    test rax, rax
    js .init_socket
    mov r14, rax
    mov [r12+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov eax, NEBO_LINUX_SYS_CONNECT
    mov rdi, r14
    mov rsi, [r13+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET]
    mov rdx, [r13+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET]
    syscall
    test rax, rax
    js .init_connect
    mov rdi, r12
    mov rsi, r13
    call x11_setup_internal
    test eax, eax
    jnz .init_setup_failure
    mov rdi, r12
    call x11_load_keyboard_mapping_internal
    test eax, eax
    jnz .init_keymap_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_motif_hints]
    mov edx, 15
    lea rcx, [r12+NEBO_X11_ADAPTER_MOTIF_HINTS_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_wm_protocols]
    mov edx, 12
    lea rcx, [r12+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_wm_delete_window]
    mov edx, 16
    lea rcx, [r12+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_wm_change_state]
    mov edx, 15
    lea rcx, [r12+NEBO_X11_ADAPTER_WM_CHANGE_STATE_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_net_wm_state]
    mov edx, 13
    lea rcx, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_net_wm_state_max_horz]
    mov edx, 28
    lea rcx, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_HORZ_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_net_wm_state_max_vert]
    mov edx, 28
    lea rcx, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_VERT_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_net_wm_moveresize]
    mov edx, 18
    lea rcx, [r12+NEBO_X11_ADAPTER_NET_WM_MOVERESIZE_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_utf8_string]
    mov edx, 11
    lea rcx, [r12+NEBO_X11_ADAPTER_UTF8_STRING_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, r12
    lea rsi, [rel x11_atom_net_wm_name]
    mov edx, 12
    lea rcx, [r12+NEBO_X11_ADAPTER_NET_WM_NAME_ATOM_OFFSET]
    call x11_intern_atom_internal
    test eax, eax
    jnz .init_atom_failure
    mov rdi, [r12+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET]
    mov rsi, [r12+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET]
    lea rdx, [r12+NEBO_X11_ADAPTER_REPORT_OFFSET+NEBO_PLATFORM_REPORT_MISSING_CAPABILITIES_OFFSET]
    call nebo_platform_capabilities_certify
    test eax, eax
    jnz .init_capability_failure
    lea rdi, [r12+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, [r12+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET]
    mov rcx, [r12+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET]
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz .init_setup_failure
    mov rax, [r12+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET]
    mov [r12+NEBO_X11_ADAPTER_REPORT_OFFSET+NEBO_PLATFORM_REPORT_REQUIRED_CAPABILITIES_OFFSET], rax
    lea rdi, [r12+NEBO_X11_ADAPTER_REPORT_OFFSET]
    call nebo_platform_report_certify
    test eax, eax
    jnz .init_capability_failure
    mov dword [r12+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov qword [r12+NEBO_X11_ADAPTER_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    mov qword [r12+NEBO_X11_ADAPTER_LAST_ERROR_OFFSET], NEBO_X11_ERROR_NONE
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .init_done
.init_atom_failure:
    mov r15d, eax
    mov edx, NEBO_X11_ERROR_ATOM
    jmp .init_close_failure
.init_keymap_failure:
    mov r15d, eax
    mov edx, NEBO_X11_ERROR_KEYMAP
    jmp .init_close_failure
.init_capability_failure:
    mov r15d, eax
    mov edx, NEBO_X11_ERROR_CAPABILITY
    jmp .init_close_failure
.init_setup_failure:
    mov r15d, eax
    mov edx, NEBO_X11_ERROR_SETUP
    jmp .init_close_failure
.init_connect:
    mov r15d, NEBO_PLATFORM_STATUS_IO_FAILURE
    mov edx, NEBO_X11_ERROR_CONNECT
    jmp .init_close_failure
.init_socket:
    mov r15d, NEBO_PLATFORM_STATUS_IO_FAILURE
    mov edx, NEBO_X11_ERROR_SOCKET
    mov dword [r12+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_FAILED
    mov rdi, r12
    mov esi, r15d
    call x11_adapter_failure_internal
    jmp .init_done
.init_close_failure:
    mov ebx, edx
    mov eax, NEBO_LINUX_SYS_CLOSE
    mov rdi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    syscall
    mov qword [r12+NEBO_X11_ADAPTER_FD_OFFSET], -1
    mov dword [r12+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_FAILED
    mov rdi, r12
    mov esi, r15d
    mov edx, ebx
    call x11_adapter_failure_internal
    jmp .init_done
.init_invalid_after_zero:
.init_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_x11_adapter_validate:
    push r12
    mov r12, rdi
    test r12, r12
    jz .validate_invalid
    cmp dword [r12+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    jne .validate_state
    cmp qword [r12+NEBO_X11_ADAPTER_FD_OFFSET], 0
    jl .validate_state
    mov eax, [r12+NEBO_X11_ADAPTER_FLAGS_OFFSET]
    and eax, NEBO_X11_ADAPTER_REQUIRED_FLAGS
    cmp eax, NEBO_X11_ADAPTER_REQUIRED_FLAGS
    jne .validate_state
    lea rdi, [r12+NEBO_X11_ADAPTER_REPORT_OFFSET]
    call nebo_platform_report_certify
    jmp .validate_done
.validate_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .validate_done
.validate_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.validate_done:
    pop r12
    ret

; copy the pointer-free report to caller-owned storage.
nebo_x11_adapter_report:
    push r12
    push r13
    push r14
    mov r13, rdi
    mov r12, rsi
    test r12, r12
    jz .report_invalid
    mov rdi, r13
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .report_done
    lea rsi, [r13+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rdi, r12
    mov ecx, NEBO_PLATFORM_REPORT_QWORDS
    cld
    rep movsq
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .report_done
.report_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.report_done:
    pop r14
    pop r13
    pop r12
    ret

nebo_x11_adapter_shutdown:
    push r12
    mov r12, rdi
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .shutdown_done
    cmp qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 0
    jne .shutdown_state
    mov eax, NEBO_LINUX_SYS_CLOSE
    mov rdi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    syscall
    test rax, rax
    js .shutdown_io
    mov qword [r12+NEBO_X11_ADAPTER_FD_OFFSET], -1
    mov dword [r12+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_SHUTDOWN
    mov qword [r12+NEBO_X11_ADAPTER_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .shutdown_done
.shutdown_io:
    mov eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    jmp .shutdown_done
.shutdown_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
.shutdown_done:
    pop r12
    ret

; ---------------------------------------------------------------------------
; Window creation, events and presentation
; ---------------------------------------------------------------------------

; create_window(adapter*, window*, config*) -> platform status
nebo_x11_adapter_create_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .create_done
    test r13, r13
    jz .create_invalid
    mov rdi, r13
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_QWORDS
    cld
    rep stosq
    test r14, r14
    jz .create_invalid_after_zero
    mov eax, [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET]
    test eax, ~NEBO_X11_WINDOW_CONFIG_KNOWN_FLAGS
    jnz .create_invalid_after_zero
    test eax, NEBO_X11_WINDOW_CONFIG_FLAG_MANAGED
    jz .create_invalid_after_zero
    mov ecx, eax
    and ecx, (NEBO_X11_WINDOW_CONFIG_FLAG_CUSTOM_CHROME | NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS)
    cmp ecx, NEBO_X11_WINDOW_CONFIG_FLAG_CUSTOM_CHROME
    je .create_flags_ready
    cmp ecx, NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS
    jne .create_invalid_after_zero
.create_flags_ready:
    mov r15, [r14+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET]
    mov rbx, [r14+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET]
    test r15, r15
    jz .create_invalid_after_zero
    test rbx, rbx
    jz .create_invalid_after_zero
    cmp r15, 65535
    ja .create_limit
    cmp rbx, 65535
    ja .create_limit
    test dword [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_FLAG_NO_SURFACE
    jnz .create_surface_ready
    mov rdi, [r14+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET]
    mov rsi, r15
    mov rdx, rbx
    call x11_surface_validate_internal
    test eax, eax
    jnz .create_surface
.create_surface_ready:
    cmp qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], NEBO_X11_ADAPTER_MAX_WINDOWS
    jae .create_limit
    mov rdi, r12
    call x11_allocate_xid_internal
    test eax, eax
    jz .create_limit
    mov [r13+NEBO_X11_WINDOW_XID_OFFSET], eax
    mov rdi, r12
    call x11_allocate_xid_internal
    test eax, eax
    jz .create_limit
    mov [r13+NEBO_X11_WINDOW_GC_XID_OFFSET], eax
    mov edi, [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_SLOT_OFFSET]
    mov esi, [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_GENERATION_OFFSET]
    lea rdx, [r13+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    call nebo_platform_window_handle_make
    test eax, eax
    jnz .create_limit
    inc qword [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_SLOT_OFFSET]
    mov rax, [r12+NEBO_X11_ADAPTER_NEXT_WINDOW_GENERATION_OFFSET]
    mov [r13+NEBO_X11_WINDOW_GENERATION_OFFSET], rax
    mov [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    mov rax, [r14+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET]
    mov [r13+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET], rax
    mov [r13+NEBO_X11_WINDOW_WIDTH_OFFSET], r15
    mov [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET], rbx
    mov qword [r13+NEBO_X11_WINDOW_X_OFFSET], 32
    mov qword [r13+NEBO_X11_WINDOW_Y_OFFSET], 32
    mov qword [r13+NEBO_X11_WINDOW_RESTORE_X_OFFSET], 32
    mov qword [r13+NEBO_X11_WINDOW_RESTORE_Y_OFFSET], 32
    mov [r13+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET], r15
    mov [r13+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET], rbx
    mov eax, (NEBO_X11_WINDOW_FLAG_MANAGED | NEBO_X11_WINDOW_FLAG_WM_DELETE)
    test dword [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS
    jnz .create_window_flags_ready
    or eax, (NEBO_X11_WINDOW_FLAG_CUSTOM_CHROME | NEBO_X11_WINDOW_FLAG_MOTIF_HINTS)
    jmp .create_window_flags_ready
.create_window_flags_ready:
    test dword [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS
    jz .create_window_flags_store
    or eax, NEBO_X11_WINDOW_FLAG_NATIVE_DECORATIONS
.create_window_flags_store:
    mov [r13+NEBO_X11_WINDOW_FLAGS_OFFSET], eax
    mov r10, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    ; CreateWindow: managed InputOutput child of root, no override-redirect.
    mov rdi, r10
    xor eax, eax
    mov ecx, 40
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_CREATE_WINDOW
    mov al, [r12+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET]
    mov [r10+1], al
    mov word [r10+2], 10
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [r10+8], eax
    mov word [r10+12], 32
    mov word [r10+14], 32
    mov [r10+16], r15w
    mov [r10+18], bx
    mov word [r10+20], 0
    mov word [r10+22], NEBO_X11_WINDOW_CLASS_INPUT_OUTPUT
    mov eax, [r12+NEBO_X11_ADAPTER_ROOT_VISUAL_OFFSET]
    mov [r10+24], eax
    mov dword [r10+28], (NEBO_X11_CW_BACK_PIXEL | NEBO_X11_CW_EVENT_MASK)
    mov eax, [r12+NEBO_X11_ADAPTER_BLACK_PIXEL_OFFSET]
    mov [r10+32], eax
    mov dword [r10+36], NEBO_X11_MF053_EVENT_MASK
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 40
    call x11_write_all_internal
    test eax, eax
    jnz .create_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    ; CreateGC.
    mov rdi, r10
    xor eax, eax
    mov ecx, 16
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_CREATE_GC
    mov word [r10+2], 4
    mov eax, [r13+NEBO_X11_WINDOW_GC_XID_OFFSET]
    mov [r10+4], eax
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+8], eax
    mov dword [r10+12], 0
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 16
    call x11_write_all_internal
    test eax, eax
    jnz .create_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    ; _MOTIF_WM_HINTS is emitted only for the historical custom-chrome mode.
    test dword [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_FLAG_NATIVE_DECORATIONS
    jnz .create_wm_protocols
    mov rdi, r10
    xor eax, eax
    mov ecx, 44
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_CHANGE_PROPERTY
    mov byte [r10+1], NEBO_X11_PROP_MODE_REPLACE
    mov word [r10+2], 11
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_MOTIF_HINTS_ATOM_OFFSET]
    mov [r10+8], eax
    mov [r10+12], eax
    mov byte [r10+16], 32
    mov dword [r10+20], 5
    mov dword [r10+24], 2
    mov dword [r10+28], 0
    mov dword [r10+32], 0
    mov dword [r10+36], 0
    mov dword [r10+40], 0
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 44
    call x11_write_all_internal
    test eax, eax
    jnz .create_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
.create_wm_protocols:
    ; ICCCM WM_PROTOCOLS / WM_DELETE_WINDOW registration.
    mov rdi, r10
    xor eax, eax
    mov ecx, 28
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_CHANGE_PROPERTY
    mov byte [r10+1], NEBO_X11_PROP_MODE_REPLACE
    mov word [r10+2], 7
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET]
    mov [r10+8], eax
    mov dword [r10+12], NEBO_X11_ATOM_ATOM
    mov byte [r10+16], 32
    mov dword [r10+20], 1
    mov eax, [r12+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET]
    mov [r10+24], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 28
    call x11_write_all_internal
    test eax, eax
    jnz .create_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    test dword [r14+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_FLAG_DEFER_MAP
    jnz .create_deferred
    ; Historical mode maps immediately.
    mov rdi, r10
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_MAP_WINDOW
    mov word [r10+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .create_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    jmp .create_success
.create_deferred:
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
.create_success:
    mov qword [r13+NEBO_X11_WINDOW_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    inc qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET]
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .create_done
.create_surface:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_SURFACE
    jmp .create_done
.create_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_FAILED
    jmp .create_done
.create_limit:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_WINDOW
    jmp .create_done
.create_invalid_after_zero:
.create_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.create_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; normalize_event(adapter*, window*, raw32*, out PlatformEventDescriptor*)
nebo_x11_adapter_normalize_event:
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
    jz .event_invalid
    test r13, r13
    jz .event_invalid
    test r14, r14
    jz .event_invalid
    test r15, r15
    jz .event_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .event_invalid
    cmp qword [r13+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], NEBO_PLATFORM_WINDOW_HANDLE_INVALID
    je .event_invalid
    cmp dword [r13+NEBO_X11_WINDOW_XID_OFFSET], 0
    je .event_invalid
    mov rdi, r15
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    movzx ebx, byte [r14]
    and ebx, 0x7f
    test ebx, ebx
    jz .event_protocol_error
    cmp ebx, NEBO_X11_EVENT_MAP_NOTIFY
    je .event_map
    cmp ebx, NEBO_X11_EVENT_CONFIGURE_NOTIFY
    je .event_configure
    cmp ebx, NEBO_X11_EVENT_MOTION_NOTIFY
    je .event_motion
    cmp ebx, NEBO_X11_EVENT_BUTTON_PRESS
    je .event_button_press
    cmp ebx, NEBO_X11_EVENT_BUTTON_RELEASE
    je .event_button_release
    cmp ebx, NEBO_X11_EVENT_KEY_PRESS
    je .event_key_press
    cmp ebx, NEBO_X11_EVENT_KEY_RELEASE
    je .event_key_release
    cmp ebx, NEBO_X11_EVENT_FOCUS_IN
    je .event_focus_in
    cmp ebx, NEBO_X11_EVENT_FOCUS_OUT
    je .event_focus_out
    cmp ebx, NEBO_X11_EVENT_CLIENT_MESSAGE
    je .event_client
    cmp ebx, NEBO_X11_EVENT_UNMAP_NOTIFY
    je .event_unmap
    cmp ebx, NEBO_X11_EVENT_DESTROY_NOTIFY
    je .event_destroy
    mov eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jmp .event_done
.event_map:
    mov eax, [r14+8]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov eax, [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET]
    cmp eax, NEBO_X11_WINDOW_ACTION_SHOW
    jne .event_map_not_show
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    jmp .event_map_emit
.event_map_not_show:
    cmp eax, NEBO_X11_WINDOW_ACTION_RESTORE
    je .event_map_restored
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz .event_map_restored
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    jmp .event_map_emit
.event_map_restored:
    and dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~(NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED | NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED)
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
.event_map_emit:
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov r8, [r13+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov r9, [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    call x11_emit_event_internal
    jmp .event_done
.event_configure:
    mov eax, [r14+8]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    movsx rax, word [r14+16]
    mov [r13+NEBO_X11_WINDOW_X_OFFSET], rax
    movsx rax, word [r14+18]
    mov [r13+NEBO_X11_WINDOW_Y_OFFSET], rax
    movzx r8d, word [r14+20]
    movzx r9d, word [r14+22]
    mov [r13+NEBO_X11_WINDOW_WIDTH_OFFSET], r8
    mov [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET], r9
    mov eax, [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET]
    cmp eax, NEBO_X11_WINDOW_ACTION_MAXIMIZE
    je .event_configure_check_sequence
    cmp eax, NEBO_X11_WINDOW_ACTION_RESTORE
    je .event_configure_check_sequence
    cmp eax, NEBO_X11_WINDOW_ACTION_RESIZE
    jne .event_configure_resized
.event_configure_check_sequence:
    movzx edx, word [r14+2]
    cmp dx, word [r13+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET]
    jne .event_configure_resized
    cmp eax, NEBO_X11_WINDOW_ACTION_MAXIMIZE
    je .event_configure_maximized
    cmp eax, NEBO_X11_WINDOW_ACTION_RESTORE
    je .event_configure_restored
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
.event_configure_resized:
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jmp .event_configure_emit
.event_configure_maximized:
    and dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], (NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED | NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED)
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    jmp .event_configure_emit
.event_configure_restored:
    and dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~(NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED | NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED)
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
.event_configure_emit:
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    call x11_emit_event_internal
    jmp .event_done
.event_motion:
    mov eax, [r14+12]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    movsx r8, word [r14+24]
    shl r8, NEBO_PLATFORM_SCALE_FRACTION_BITS
    movsx r9, word [r14+26]
    shl r9, NEBO_PLATFORM_SCALE_FRACTION_BITS
    mov eax, r8d
    mov r10d, r9d
    shl r10, 32
    or r8, r10
    movzx edi, word [r14+28]
    call x11_common_modifiers_internal
    shl rax, 32
    mov r9, rax
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_POINTER_MOVE
    call x11_emit_event_internal
    jmp .event_done
.event_button_press:
    mov r11d, NEBO_CONSOLE_EVENT_POINTER_DOWN
    jmp .event_button_common
.event_button_release:
    mov r11d, NEBO_CONSOLE_EVENT_POINTER_UP
.event_button_common:
    mov eax, [r14+12]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    movsx r8, word [r14+24]
    shl r8, NEBO_PLATFORM_SCALE_FRACTION_BITS
    movsx r9, word [r14+26]
    shl r9, NEBO_PLATFORM_SCALE_FRACTION_BITS
    mov eax, r8d
    mov r10d, r9d
    shl r10, 32
    or r8, r10
    movzx r10d, byte [r14+1]
    movzx edi, word [r14+28]
    call x11_common_modifiers_internal
    shl rax, 32
    mov r9, rax
    or r9, r10
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, r11d
    call x11_emit_event_internal
    jmp .event_done
.event_key_press:
    mov r11d, NEBO_CONSOLE_EVENT_KEY_DOWN
    jmp .event_key_common
.event_key_release:
    mov r11d, NEBO_CONSOLE_EVENT_KEY_UP
.event_key_common:
    mov eax, [r14+12]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    movzx esi, byte [r14+1]
    movzx edx, word [r14+28]
    mov rdi, r12
    call x11_lookup_keysym_internal
    mov r10d, eax
    mov edi, r10d
    call x11_keysym_to_logical_internal
    mov ebx, eax
    cmp r11d, NEBO_CONSOLE_EVENT_KEY_DOWN
    jne .event_key_payload
    movzx eax, word [r14+28]
    test eax, (NEBO_X11_STATE_CONTROL | NEBO_X11_STATE_MOD1 | NEBO_X11_STATE_MOD4)
    jnz .event_key_payload
    mov edi, r10d
    call x11_keysym_to_utf8_internal
    test edx, edx
    jz .event_key_payload
    cmp dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], 0
    jne .event_protocol_error
    mov dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    mov [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], rax
    mov [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], rdx
.event_key_payload:
    mov r8d, ebx
    movzx eax, byte [r14+1]
    shl rax, 32
    or r8, rax
    movzx edi, word [r14+28]
    call x11_common_modifiers_internal
    mov r9d, eax
    mov eax, r10d
    shl rax, 32
    or r9, rax
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, r11d
    call x11_emit_event_internal
    jmp .event_done
.event_focus_in:
    mov eax, [r14+4]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .event_done
.event_focus_out:
    mov eax, [r14+4]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .event_done
.event_client:
    cmp byte [r14+1], 32
    jne .event_no_event
    mov eax, [r14+4]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    mov eax, [r14+8]
    cmp eax, [r12+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET]
    jne .event_no_event
    mov eax, [r14+12]
    cmp eax, [r12+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET]
    jne .event_no_event
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_CLOSE
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .event_done
.event_unmap:
    mov eax, [r14+8]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    and dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], ~NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_NONE
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .event_done
.event_destroy:
    mov eax, [r14+8]
    cmp eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    jne .event_no_event
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    cmp qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 0
    je .event_destroy_emit
    dec qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET]
.event_destroy_emit:
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .event_done
.event_protocol_error:
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_FAILED
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_EVENT
    mov eax, NEBO_PLATFORM_STATUS_PROTOCOL_FAILURE
    jmp .event_done
.event_no_event:
    mov eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jmp .event_done
.event_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.event_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; poll_event(adapter*, window*, timeout_ms, out_event*)
nebo_x11_adapter_poll_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .poll_done
    test r13, r13
    jz .poll_invalid
    test r15, r15
    jz .poll_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .poll_invalid
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    je .poll_window_ready
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .poll_invalid
.poll_window_ready:
    mov ecx, [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET]
    test ecx, ecx
    jz .poll_native_socket
    mov r8, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET]
    mov r9, [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET]
    mov dword [r13+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD0_OFFSET], 0
    mov qword [r13+NEBO_X11_WINDOW_PENDING_INPUT_PAYLOAD1_OFFSET], 0
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    call x11_emit_event_internal
    jmp .poll_done
.poll_native_socket:
    mov eax, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov [rsp], eax
    mov word [rsp+4], NEBO_LINUX_POLLIN
    mov word [rsp+6], 0
    mov eax, NEBO_LINUX_SYS_POLL
    mov rdi, rsp
    mov esi, 1
    mov rdx, r14
    syscall
    test rax, rax
    jz .poll_timeout
    js .poll_io
    test word [rsp+6], NEBO_LINUX_POLLIN
    jz .poll_timeout
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, NEBO_X11_EVENT_SIZE
    call x11_read_exact_internal
    test eax, eax
    jnz .poll_done
    mov rdi, r12
    mov rsi, r13
    mov rdx, rbx
    mov rcx, r15
    call nebo_x11_adapter_normalize_event
    jmp .poll_done
.poll_timeout:
    mov eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jmp .poll_done
.poll_io:
    cmp rax, -NEBO_LINUX_EINTR
    je .poll_timeout
    mov eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    jmp .poll_done
.poll_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.poll_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; poll_raw(adapter*, timeout_ms, out_raw_32*) -> platform status.
; This is the F05 multi-window seam: one socket read is routed by XID by the
; caller, so an event for another window is never consumed and discarded.
nebo_x11_adapter_poll_raw:
    push rbx
    push r12
    push r13
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .raw_done
    test rbx, rbx
    jz .raw_invalid
    mov eax, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov [rsp], eax
    mov word [rsp+4], NEBO_LINUX_POLLIN
    mov word [rsp+6], 0
    mov eax, NEBO_LINUX_SYS_POLL
    mov rdi, rsp
    mov esi, 1
    mov rdx, r13
    syscall
    test rax, rax
    jz .raw_timeout
    js .raw_io
    test word [rsp+6], NEBO_LINUX_POLLIN
    jz .raw_timeout
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, NEBO_X11_EVENT_SIZE
    call x11_read_exact_internal
    jmp .raw_done
.raw_timeout:
    mov eax, NEBO_PLATFORM_STATUS_NO_EVENT
    jmp .raw_done
.raw_io:
    cmp rax, -NEBO_LINUX_EINTR
    je .raw_timeout
    mov eax, NEBO_PLATFORM_STATUS_IO_FAILURE
    jmp .raw_done
.raw_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.raw_done:
    add rsp, 16
    pop r13
    pop r12
    pop rbx
    ret

; map_window(adapter*, window*) -> platform status. The caller observes
; MapNotify before publishing the canonical VISIBLE state.
nebo_x11_adapter_map_window:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .map_done
    test r13, r13
    jz .map_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .map_invalid
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne .map_state
    mov r14, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r14
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r14], NEBO_X11_OP_MAP_WINDOW
    mov word [r14+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r14+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r14
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .map_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_SHOW
    xor eax, eax
    jmp .map_done
.map_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .map_done
.map_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .map_done
.map_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.map_done:
    pop r14
    pop r13
    pop r12
    ret

; unmap_window(adapter*, window*) -> platform status. UnmapNotify confirms the
; canonical HIDDEN transition.
nebo_x11_adapter_unmap_window:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .unmap_done
    test r13, r13
    jz .unmap_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .unmap_invalid
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .unmap_state
    mov r14, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r14
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r14], NEBO_X11_OP_UNMAP_WINDOW
    mov word [r14+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r14+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r14
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .unmap_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPING
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_HIDE
    xor eax, eax
    jmp .unmap_done
.unmap_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .unmap_done
.unmap_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .unmap_done
.unmap_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.unmap_done:
    pop r14
    pop r13
    pop r12
    ret

; configure_window_bounded(adapter*, window*, width, height) -> status.
; Unlike the historical Console resize helper this F05 seam accepts the full
; Window contract range 1..2048 and unmapped windows.
nebo_x11_adapter_configure_window_bounded:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .bounded_size_done
    test r13, r13
    jz .bounded_size_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .bounded_size_invalid
    cmp r14, 1
    jb .bounded_size_limit
    cmp r15, 1
    jb .bounded_size_limit
    cmp r14, 2048
    ja .bounded_size_limit
    cmp r15, 2048
    ja .bounded_size_limit
    mov eax, [r13+NEBO_X11_WINDOW_STATE_OFFSET]
    cmp eax, NEBO_X11_WINDOW_STATE_UNMAPPED
    je .bounded_size_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_MAPPING
    je .bounded_size_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_MAPPED
    je .bounded_size_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_UNMAPPING
    jne .bounded_size_state
.bounded_size_state_ready:
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 20
    cld
    rep stosb
    mov byte [rbx], NEBO_X11_OP_CONFIGURE_WINDOW
    mov word [rbx+2], 5
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rbx+4], eax
    mov word [rbx+8], (NEBO_X11_CONFIG_WINDOW_WIDTH | NEBO_X11_CONFIG_WINDOW_HEIGHT)
    mov [rbx+12], r14d
    mov [rbx+16], r15d
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 20
    call x11_write_all_internal
    test eax, eax
    jnz .bounded_size_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_X11_ADAPTER_NATIVE_ACTION_SEQUENCE_OFFSET]
    mov rax, [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [r13+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], rax
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    xor eax, eax
    jmp .bounded_size_done
.bounded_size_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .bounded_size_done
.bounded_size_limit:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jmp .bounded_size_done
.bounded_size_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .bounded_size_done
.bounded_size_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.bounded_size_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; set_window_title(adapter*, window*, utf8*, byte_length) -> platform status.
; The canonical runtime validates UTF-8. This layer sends exactly one bounded
; _NET_WM_NAME/UTF8_STRING Replace request, avoiding a partially updated pair
; of title properties.
nebo_x11_adapter_set_window_title:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .title_done
    test r13, r13
    jz .title_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .title_invalid
    cmp r15, 256
    ja .title_limit
    test r15, r15
    jz .title_pointer_ready
    test r14, r14
    jz .title_invalid
.title_pointer_ready:
    mov eax, [r13+NEBO_X11_WINDOW_STATE_OFFSET]
    cmp eax, NEBO_X11_WINDOW_STATE_UNMAPPED
    je .title_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_MAPPING
    je .title_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_MAPPED
    je .title_state_ready
    cmp eax, NEBO_X11_WINDOW_STATE_UNMAPPING
    jne .title_state
.title_state_ready:
    mov rbx, r15
    add rbx, 3
    and rbx, -4
    add rbx, 24
    cmp rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET]
    ja .title_limit
    mov r10, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r10
    xor eax, eax
    mov rcx, rbx
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_CHANGE_PROPERTY
    mov byte [r10+1], NEBO_X11_PROP_MODE_REPLACE
    mov rax, rbx
    shr rax, 2
    mov [r10+2], ax
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_NET_WM_NAME_ATOM_OFFSET]
    mov [r10+8], eax
    mov eax, [r12+NEBO_X11_ADAPTER_UTF8_STRING_ATOM_OFFSET]
    mov [r10+12], eax
    mov byte [r10+16], 8
    mov [r10+20], r15d
    test r15, r15
    jz .title_send
    lea rdi, [r10+24]
    mov rsi, r14
    mov rcx, r15
    cld
    rep movsb
.title_send:
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov rdx, rbx
    call x11_write_all_internal
    test eax, eax
    jnz .title_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    xor eax, eax
    jmp .title_done
.title_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .title_done
.title_limit:
    mov eax, NEBO_PLATFORM_STATUS_CAPABILITY_MISSING
    jmp .title_done
.title_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .title_done
.title_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.title_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; present(adapter*, window*, surface*, out_event*)
nebo_x11_adapter_present:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .present_done
    test r13, r13
    jz .present_invalid
    test r15, r15
    jz .present_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .present_invalid
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    jne .present_state
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz .present_state
    cmp r14, [r13+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET]
    jne .present_state
    mov rdi, r14
    mov rsi, [r13+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov rdx, [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    call x11_surface_validate_internal
    test eax, eax
    jnz .present_surface
    movzx rax, word [r12+NEBO_X11_ADAPTER_MAX_REQUEST_UNITS_OFFSET]
    shl rax, 2
    sub rax, 24
    jbe .present_format
    mov rbx, [r14+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    xor edx, edx
    div rbx
    test rax, rax
    jz .present_format
    mov [rsp+8], rax
    mov rax, [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    mov [rsp+16], rax
    mov qword [rsp], 0
.present_loop:
    mov r9, [rsp]
    cmp r9, [rsp+16]
    jae .present_success
    mov r8, [rsp+16]
    sub r8, r9
    cmp r8, [rsp+8]
    jbe .present_rows_ready
    mov r8, [rsp+8]
.present_rows_ready:
    cmp r8, 65535
    jbe .present_rows_limit_ready
    mov r8, 65535
.present_rows_limit_ready:
    mov [rsp+24], r8
    mov rdx, r8
    imul rdx, rbx
    mov r10, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r10
    xor eax, eax
    mov ecx, 24
    cld
    rep stosb
    mov byte [r10], NEBO_X11_OP_PUT_IMAGE
    mov byte [r10+1], NEBO_X11_IMAGE_FORMAT_Z_PIXMAP
    mov rcx, rdx
    add rcx, 24
    shr rcx, 2
    mov [r10+2], cx
    mov ecx, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r10+4], ecx
    mov ecx, [r13+NEBO_X11_WINDOW_GC_XID_OFFSET]
    mov [r10+8], ecx
    mov rcx, [r13+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov [r10+12], cx
    mov r8, [rsp+24]
    mov [r10+14], r8w
    mov word [r10+16], 0
    mov r9, [rsp]
    mov [r10+18], r9w
    mov byte [r10+20], 0
    mov cl, [r12+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET]
    mov [r10+21], cl
    mov word [r10+22], 0
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r10
    mov edx, 24
    call x11_write_all_internal
    test eax, eax
    jnz .present_request
    mov rax, [rsp]
    imul rax, rbx
    add rax, [r14+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rax
    mov rdx, [rsp+24]
    imul rdx, rbx
    call x11_write_all_internal
    test eax, eax
    jnz .present_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov rax, [rsp+24]
    add [rsp], rax
    jmp .present_loop
.present_success:
    inc qword [r12+NEBO_X11_ADAPTER_PRESENT_SEQUENCE_OFFSET]
    inc qword [r13+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET]
    mov rdi, r12
    mov rsi, r13
    mov rdx, r15
    mov ecx, NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
    mov r8, [r12+NEBO_X11_ADAPTER_PRESENT_SEQUENCE_OFFSET]
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .present_done
.present_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .present_done
.present_surface:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_SURFACE
    jmp .present_done
.present_format:
    mov eax, NEBO_PLATFORM_STATUS_UNSUPPORTED_FORMAT
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_SURFACE
    jmp .present_done
.present_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .present_done
.present_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.present_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; minimize_window(adapter*, window*)
nebo_x11_adapter_minimize_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .minimize_done
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], (NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED | NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED)
    jnz .minimize_state
    mov dword [rsp], NEBO_X11_ICCCM_ICONIC_STATE
    mov dword [rsp+4], 0
    mov dword [rsp+8], 0
    mov dword [rsp+12], 0
    mov dword [rsp+16], 0
    mov rdi, r12
    mov rsi, r13
    mov edx, [r12+NEBO_X11_ADAPTER_WM_CHANGE_STATE_ATOM_OFFSET]
    mov rcx, rsp
    call x11_send_client_message_internal
    test eax, eax
    jnz .minimize_request
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MINIMIZE
    mov qword [r13+NEBO_X11_WINDOW_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    xor eax, eax
    jmp .minimize_done
.minimize_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .minimize_done
.minimize_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
.minimize_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; maximize_window(adapter*, window*)
nebo_x11_adapter_maximize_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .maximize_done
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], (NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED | NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED)
    jnz .maximize_state
    mov rax, [r13+NEBO_X11_WINDOW_X_OFFSET]
    mov [r13+NEBO_X11_WINDOW_RESTORE_X_OFFSET], rax
    mov rax, [r13+NEBO_X11_WINDOW_Y_OFFSET]
    mov [r13+NEBO_X11_WINDOW_RESTORE_Y_OFFSET], rax
    mov rax, [r13+NEBO_X11_WINDOW_WIDTH_OFFSET]
    mov [r13+NEBO_X11_WINDOW_RESTORE_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    mov [r13+NEBO_X11_WINDOW_RESTORE_HEIGHT_OFFSET], rax
    mov dword [rsp], NEBO_X11_NET_WM_STATE_ADD
    mov eax, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_HORZ_ATOM_OFFSET]
    mov [rsp+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_VERT_ATOM_OFFSET]
    mov [rsp+8], eax
    mov dword [rsp+12], NEBO_X11_NET_WM_SOURCE_APPLICATION
    mov dword [rsp+16], 0
    mov rdi, r12
    mov rsi, r13
    mov edx, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_ATOM_OFFSET]
    mov rcx, rsp
    call x11_send_client_message_internal
    test eax, eax
    jnz .maximize_request
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_MAXIMIZE
    mov qword [r13+NEBO_X11_WINDOW_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    xor eax, eax
    jmp .maximize_done
.maximize_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .maximize_done
.maximize_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
.maximize_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; restore_window(adapter*, window*)
nebo_x11_adapter_restore_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jz .restore_valid
    ; A minimized window is intentionally UNMAPPED after UnmapNotify.  Only
    ; restore may relax the generic live-action state check for that exact
    ; owned, non-stale state; every other action keeps requiring MAPPING/MAPPED.
    cmp eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jne .restore_done
    cmp dword [r13+NEBO_X11_WINDOW_XID_OFFSET], 0
    je .restore_done
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    jne .restore_done
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jz .restore_done
    xor eax, eax
.restore_valid:
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .restore_state
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jnz .restore_map
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
    jz .restore_state
    mov dword [rsp], NEBO_X11_NET_WM_STATE_REMOVE
    mov eax, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_HORZ_ATOM_OFFSET]
    mov [rsp+4], eax
    mov eax, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_MAX_VERT_ATOM_OFFSET]
    mov [rsp+8], eax
    mov dword [rsp+12], NEBO_X11_NET_WM_SOURCE_APPLICATION
    mov dword [rsp+16], 0
    mov rdi, r12
    mov rsi, r13
    mov edx, [r12+NEBO_X11_ADAPTER_NET_WM_STATE_ATOM_OFFSET]
    mov rcx, rsp
    call x11_send_client_message_internal
    test eax, eax
    jnz .restore_request
    jmp .restore_mark
.restore_map:
    mov r14, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r14
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r14], NEBO_X11_OP_MAP_WINDOW
    mov word [r14+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r14+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r14
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .restore_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_X11_ADAPTER_NATIVE_ACTION_SEQUENCE_OFFSET]
    mov rax, [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [r13+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], rax
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
.restore_mark:
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESTORE
    mov qword [r13+NEBO_X11_WINDOW_LAST_STATUS_OFFSET], NEBO_PLATFORM_STATUS_OK
    xor eax, eax
    jmp .restore_done
.restore_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .restore_done
.restore_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
.restore_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; begin_window_drag(adapter*, window*, root_x, root_y, button)
nebo_x11_adapter_begin_window_drag:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15d, ecx
    mov ebx, r8d
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .drag_done
    test ebx, ebx
    jz .drag_invalid
    mov [rsp], r14d
    mov [rsp+4], r15d
    mov dword [rsp+8], NEBO_X11_NET_WM_MOVERESIZE_MOVE
    mov [rsp+12], ebx
    mov dword [rsp+16], NEBO_X11_NET_WM_SOURCE_APPLICATION
    mov rdi, r12
    mov rsi, r13
    mov edx, [r12+NEBO_X11_ADAPTER_NET_WM_MOVERESIZE_ATOM_OFFSET]
    mov rcx, rsp
    call x11_send_client_message_internal
    test eax, eax
    jnz .drag_done
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_DRAG
    xor eax, eax
    jmp .drag_done
.drag_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.drag_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; begin_window_resize(adapter*, window*, root_x, root_y, direction, button)
nebo_x11_adapter_begin_window_resize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    mov r15d, ecx
    mov ebx, r8d
    mov [rsp+20], r9d
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .begin_resize_done
    cmp ebx, NEBO_X11_NET_WM_MOVERESIZE_SIZE_LEFT
    ja .begin_resize_invalid
    mov r10d, [rsp+20]
    test r10d, r10d
    jz .begin_resize_invalid
    mov [rsp], r14d
    mov [rsp+4], r15d
    mov [rsp+8], ebx
    mov [rsp+12], r10d
    mov dword [rsp+16], NEBO_X11_NET_WM_SOURCE_APPLICATION
    mov rdi, r12
    mov rsi, r13
    mov edx, [r12+NEBO_X11_ADAPTER_NET_WM_MOVERESIZE_ATOM_OFFSET]
    mov rcx, rsp
    call x11_send_client_message_internal
    test eax, eax
    jnz .begin_resize_done
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    xor eax, eax
    jmp .begin_resize_done
.begin_resize_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.begin_resize_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; set_window_size(adapter*, window*, width, height)
nebo_x11_adapter_set_window_size:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .size_done
    cmp r14, 128
    jb .size_limit
    cmp r15, 64
    jb .size_limit
    cmp r14, NEBO_SURFACE_MAX_AXIS_PIXELS
    ja .size_limit
    cmp r15, NEBO_SURFACE_MAX_AXIS_PIXELS
    ja .size_limit
    mov rbx, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, rbx
    xor eax, eax
    mov ecx, 20
    cld
    rep stosb
    mov byte [rbx], NEBO_X11_OP_CONFIGURE_WINDOW
    mov word [rbx+2], 5
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rbx+4], eax
    mov word [rbx+8], (NEBO_X11_CONFIG_WINDOW_WIDTH | NEBO_X11_CONFIG_WINDOW_HEIGHT)
    mov [rbx+12], r14d
    mov [rbx+16], r15d
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, rbx
    mov edx, 20
    call x11_write_all_internal
    test eax, eax
    jnz .size_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_X11_ADAPTER_NATIVE_ACTION_SEQUENCE_OFFSET]
    mov rax, [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov [r13+NEBO_X11_WINDOW_PENDING_PROTOCOL_SEQUENCE_OFFSET], rax
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_RESIZE
    xor eax, eax
    jmp .size_done
.size_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .size_done
.size_limit:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.size_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; request_close(adapter*, window*, out_event*)
nebo_x11_adapter_request_close:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r14, r14
    jz .request_close_invalid
    mov rdi, r12
    mov rsi, r13
    call x11_window_action_validate_internal
    test eax, eax
    jnz .request_close_done
    test dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    jnz .request_close_state
    or dword [r13+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_CLOSE_REQUESTED
    mov dword [r13+NEBO_X11_WINDOW_PENDING_ACTION_OFFSET], NEBO_X11_WINDOW_ACTION_CLOSE
    mov rdi, r12
    mov rsi, r13
    mov rdx, r14
    mov ecx, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    xor r8d, r8d
    xor r9d, r9d
    call x11_emit_event_internal
    jmp .request_close_done
.request_close_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .request_close_done
.request_close_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.request_close_done:
    pop r14
    pop r13
    pop r12
    ret

; destroy_window(adapter*, window*)
nebo_x11_adapter_destroy_window:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_x11_adapter_validate
    test eax, eax
    jnz .destroy_done
    test r13, r13
    jz .destroy_invalid
    cmp [r13+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], r12
    jne .destroy_invalid
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPING
    je .destroy_send
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    je .destroy_send
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    je .destroy_send
    cmp dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPING
    jne .destroy_state
.destroy_send:
    mov r14, [r12+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET]
    mov rdi, r14
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r14], NEBO_X11_OP_FREE_GC
    mov word [r14+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_GC_XID_OFFSET]
    mov [r14+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r14
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .destroy_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov rdi, r14
    xor eax, eax
    mov ecx, 8
    cld
    rep stosb
    mov byte [r14], NEBO_X11_OP_DESTROY_WINDOW
    mov word [r14+2], 2
    mov eax, [r13+NEBO_X11_WINDOW_XID_OFFSET]
    mov [r14+4], eax
    mov edi, [r12+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r14
    mov edx, 8
    call x11_write_all_internal
    test eax, eax
    jnz .destroy_request
    inc qword [r12+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    mov dword [r13+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED
    mov dword [r13+NEBO_X11_WINDOW_XID_OFFSET], 0
    mov dword [r13+NEBO_X11_WINDOW_GC_XID_OFFSET], 0
    cmp qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 0
    je .destroy_ok
    dec qword [r12+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET]
.destroy_ok:
    mov eax, NEBO_PLATFORM_STATUS_OK
    jmp .destroy_done
.destroy_request:
    mov qword [r13+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], NEBO_X11_ERROR_REQUEST
    jmp .destroy_done
.destroy_state:
    mov eax, NEBO_PLATFORM_STATUS_BAD_STATE
    jmp .destroy_done
.destroy_invalid:
    mov eax, NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.destroy_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
