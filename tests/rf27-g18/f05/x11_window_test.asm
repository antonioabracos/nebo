bits 64
default rel
%include "runtime/window/x11/x11_window.inc"

%macro ASSERT_EQ_Q 3
    inc r15d ; assert_%3
    mov rax, %1
    cmp rax, %2
    jne .fail
%endmacro
%macro ASSERT_EQ_D 3
    inc r15d ; assert_%3
    mov eax, %1
    cmp eax, %2
    jne .fail
%endmacro
%macro ASSERT_ZERO 2
    inc r15d ; assert_%2
    test %1, %1
    jne .fail
%endmacro
%macro ASSERT_NONZERO 2
    inc r15d ; assert_%2
    test %1, %1
    jz .fail
%endmacro
%macro RAW_CLEAR 0
    lea rdi, [rel raw_event]
    xor eax, eax
    mov ecx, 4
    cld
    rep stosq
%endmacro
%macro TRANSLATE 0
    lea rdi, [rel runtime]
    lea rsi, [rel raw_event]
    call nebo_x11_window_translate_raw
%endmacro

section .bss
align 8
runtime resb NEBO_X11_RUNTIME_SIZE
records resb NEBO_WINDOW_SIZE*2
native_records resb NEBO_X11_WINDOW_SIZE*2
adapter resb NEBO_X11_ADAPTER_SIZE
raw_event resb NEBO_X11_EVENT_SIZE
stream1 resb NEBO_HEADLESS_STREAM_SIZE
stream2 resb NEBO_HEADLESS_STREAM_SIZE
event_out resb NEBO_WINDOW_EVENT_SIZE
title1 resb 256
title2 resb 256
events1 resb NEBO_WINDOW_EVENT_SIZE*64
events2 resb NEBO_WINDOW_EVENT_SIZE*64

section .text
global _start

; rdi=record, rsi=handle, rdx=owner, rcx=title, r8=events.
init_record:
    push rbp
    mov rbp, rsp
    push rbx
    mov rbx, rdi
    mov [rbx+NEBO_WINDOW_HANDLE_OFFSET], rsi
    mov dword [rbx+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_CREATED
    mov dword [rbx+NEBO_WINDOW_BACKEND_OFFSET], NEBO_WINDOW_BACKEND_X11_DIRECT
    mov dword [rbx+NEBO_WINDOW_FLAGS_OFFSET], (NEBO_WINDOW_OPTION_RESIZABLE | NEBO_WINDOW_OPTION_DECORATED | NEBO_WINDOW_OPTION_TEXT_INPUT | NEBO_WINDOW_OPTION_CLOSE_PREVENTABLE | NEBO_HEADLESS_FLAG_ACCEPTING_EVENTS | NEBO_HEADLESS_FLAG_ACTIVE)
    mov [rbx+NEBO_WINDOW_OWNER_CONTEXT_OFFSET], rdx
    mov qword [rbx+NEBO_WINDOW_WIDTH_OFFSET], 640
    mov qword [rbx+NEBO_WINDOW_HEIGHT_OFFSET], 480
    mov [rbx+NEBO_WINDOW_TITLE_PTR_OFFSET], rcx
    mov qword [rbx+NEBO_WINDOW_TITLE_LENGTH_OFFSET], 0
    mov qword [rbx+NEBO_WINDOW_TITLE_CAPACITY_OFFSET], 256
    mov [rbx+NEBO_WINDOW_EVENT_STORAGE_PTR_OFFSET], r8
    mov qword [rbx+NEBO_WINDOW_EVENT_CAPACITY_OFFSET], 64
    mov qword [rbx+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET], 0
    lea rax, [rel runtime]
    mov [rbx+NEBO_WINDOW_BACKEND_CONTEXT_PTR_OFFSET], rax
    mov rax, rsi
    shr rax, NEBO_WINDOW_HANDLE_GENERATION_SHIFT
    mov [rbx+nebo_canvas_WINDOW_GENERATION_OFFSET], rax
    pop rbx
    pop rbp
    ret

; rdi=native, rsi=handle, edx=xid.
init_native:
    lea rax, [rel adapter]
    mov [rdi+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], rax
    mov [rdi+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], rsi
    mov [rdi+NEBO_X11_WINDOW_XID_OFFSET], edx
    mov dword [rdi+NEBO_X11_WINDOW_GC_XID_OFFSET], 0x700
    mov dword [rdi+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_UNMAPPED
    mov dword [rdi+NEBO_X11_WINDOW_FLAGS_OFFSET], (NEBO_X11_WINDOW_FLAG_MANAGED | NEBO_X11_WINDOW_FLAG_NATIVE_DECORATIONS | NEBO_X11_WINDOW_FLAG_WM_DELETE)
    mov qword [rdi+NEBO_X11_WINDOW_WIDTH_OFFSET], 640
    mov qword [rdi+NEBO_X11_WINDOW_HEIGHT_OFFSET], 480
    mov qword [rdi+NEBO_X11_WINDOW_GENERATION_OFFSET], 1
    ret

_start:
    xor r15d, r15d

%if NEBO_X11_RUNTIME_SIZE != 280
%error x11_runtime_size
%endif
%if NEBO_WINDOW_SIZE != 192
%error window_record_size
%endif
; 320 was the complete private-record prefix before the authorized
; present-geometry guard fields were appended.  Keep that historical boundary
; explicit, but derive the current exact size from independently checked field
; offsets instead of freezing another total-size magic literal.
%if (NEBO_X11_WINDOW_BACKBUFFER_ALLOCATION_COUNT_OFFSET + 8) != 320
%error x11_native_record_superseded_prefix_end
%endif
%if NEBO_X11_WINDOW_PRESENT_GEOMETRY_GUARD_OFFSET != 320
%error x11_native_record_present_geometry_guard_offset
%endif
%if NEBO_X11_WINDOW_LAST_ACTUAL_WIDTH_OFFSET != 328
%error x11_native_record_last_actual_width_offset
%endif
%if NEBO_X11_WINDOW_LAST_ACTUAL_HEIGHT_OFFSET != 336
%error x11_native_record_last_actual_height_offset
%endif
%if NEBO_X11_WINDOW_PENDING_CONFIGURE_COUNT_OFFSET != 344
%error x11_native_record_pending_configure_count_offset
%endif
%if NEBO_X11_WINDOW_LATEST_PENDING_X_OFFSET != 352
%error x11_native_record_latest_pending_x_offset
%endif
%if NEBO_X11_WINDOW_LATEST_PENDING_Y_OFFSET != 360
%error x11_native_record_latest_pending_y_offset
%endif
%if NEBO_X11_WINDOW_LATEST_PENDING_WIDTH_OFFSET != 368
%error x11_native_record_latest_pending_width_offset
%endif
%if NEBO_X11_WINDOW_LATEST_PENDING_HEIGHT_OFFSET != 376
%error x11_native_record_latest_pending_height_offset
%endif
%if NEBO_X11_WINDOW_PRESENT_GEOMETRY_MISMATCH_COUNT_OFFSET != 384
%error x11_native_record_present_geometry_mismatch_count_offset
%endif
%if NEBO_X11_WINDOW_STALE_PRESENT_SKIPPED_COUNT_OFFSET != 392
%error x11_native_record_stale_present_skipped_count_offset
%endif
%if NEBO_X11_WINDOW_GEOMETRY_GENERATION_OFFSET != 400
%error x11_native_record_geometry_generation_offset
%endif
%if NEBO_X11_WINDOW_LAST_PRESENT_GEOMETRY_GENERATION_OFFSET != 408
%error x11_native_record_last_present_geometry_generation_offset
%endif
%if NEBO_X11_WINDOW_GEOMETRY_QUERY_COUNT_OFFSET != 416
%error x11_native_record_geometry_query_count_offset
%endif
%if NEBO_X11_WINDOW_SIZE != (NEBO_X11_WINDOW_GEOMETRY_QUERY_COUNT_OFFSET + 8)
%error x11_native_record_last_field_end
%endif
%if (NEBO_X11_WINDOW_SIZE & 7) != 0
%error x11_native_record_alignment
%endif
%if (NEBO_X11_WINDOW_QWORDS * 8) != NEBO_X11_WINDOW_SIZE
%error x11_native_record_qword_capacity
%endif
%if NEBO_WINDOW_EVENT_SIZE != 64
%error window_event_size
%endif
%if NEBO_HEADLESS_STREAM_SIZE != 64
%error stream_size
%endif
%if NEBO_WINDOW_EVENT_SEQUENCE_OFFSET != 0
%error event_sequence_offset
%endif
%if NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET != 112
%error record_sequence_offset
%endif

    ; Zero all caller-owned state.
    lea rdi, [rel runtime]
    xor eax, eax
    mov ecx, (NEBO_X11_RUNTIME_SIZE + NEBO_WINDOW_SIZE*2 + NEBO_X11_WINDOW_SIZE*2 + NEBO_X11_ADAPTER_SIZE + NEBO_X11_EVENT_SIZE + NEBO_HEADLESS_STREAM_SIZE*2 + NEBO_WINDOW_EVENT_SIZE + 512 + NEBO_WINDOW_EVENT_SIZE*128)/8
    cld
    rep stosq

    ; Headless-compatible prefix and F05 descriptor.
    lea rax, [rel records]
    mov [rel runtime+NEBO_HEADLESS_RUNTIME_RECORDS_PTR_OFFSET], rax
    mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_CAPACITY_OFFSET], 2
    mov qword [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET], 2
    mov rax, NEBO_HEADLESS_RUNTIME_MAGIC
    mov [rel runtime+NEBO_HEADLESS_RUNTIME_MAGIC_OFFSET], rax
    lea rax, [rel adapter]
    mov [rel runtime+NEBO_X11_RUNTIME_ADAPTER_PTR_OFFSET], rax
    lea rax, [rel native_records]
    mov [rel runtime+NEBO_X11_RUNTIME_NATIVE_RECORDS_PTR_OFFSET], rax
    mov qword [rel runtime+NEBO_X11_RUNTIME_CAPACITY_OFFSET], 2
    mov qword [rel runtime+NEBO_X11_RUNTIME_FLAGS_OFFSET], (NEBO_X11_RUNTIME_FLAG_READY | NEBO_X11_RUNTIME_FLAG_LIVE)
    mov rax, NEBO_X11_RUNTIME_MAGIC
    mov [rel runtime+NEBO_X11_RUNTIME_MAGIC_OFFSET], rax

    ; Adapter fields needed by exact event normalization.
    mov qword [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], -1
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET], 0x11223344
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET], 0x55667788
    mov byte [rel adapter+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET], 8
    mov byte [rel adapter+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET], 255
    mov byte [rel adapter+NEBO_X11_ADAPTER_KEYSYMS_PER_KEYCODE_OFFSET], 2
    mov byte [rel adapter+NEBO_X11_ADAPTER_KEYMAP_READY_OFFSET], 1
    mov dword [rel adapter+NEBO_X11_ADAPTER_KEYMAP_OFFSET+38*NEBO_X11_KEYMAP_ENTRY_SIZE+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET], 0x61
    mov dword [rel adapter+NEBO_X11_ADAPTER_KEYMAP_OFFSET+38*NEBO_X11_KEYMAP_ENTRY_SIZE+NEBO_X11_KEYMAP_ENTRY_SHIFTED_OFFSET], 0x41
    mov qword [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 2

    ; Two independent canonical/native windows.
    lea rdi, [rel records]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    lea rcx, [rel title1]
    lea r8, [rel events1]
    call init_record
    lea rdi, [rel records+NEBO_WINDOW_SIZE]
    mov rsi, 0x0000000100000002
    mov rdx, 0x2222
    lea rcx, [rel title2]
    lea r8, [rel events2]
    call init_record
    lea rdi, [rel native_records]
    mov rsi, 0x0000000100000001
    mov edx, 0x111
    call init_native
    lea rdi, [rel native_records+NEBO_X11_WINDOW_SIZE]
    mov rsi, 0x0000000100000002
    mov edx, 0x222
    call init_native

    ; Basic rejection surfaces are atomic and do not touch queues.
    xor edi, edi
    lea rsi, [rel raw_event]
    call nebo_x11_window_translate_raw
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT, null_runtime
    ASSERT_EQ_D edx, 0, null_runtime_processed
    lea rdi, [rel runtime]
    xor esi, esi
    call nebo_x11_window_translate_raw
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT, null_raw
    ASSERT_EQ_D edx, 0, null_raw_processed
    lea rdi, [rel runtime]
    xor esi, esi
    xor edx, edx
    call nebo_x11_window_show
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT, show_invalid_handle
    lea rdi, [rel runtime]
    mov rsi, 0x0000000200000001
    mov rdx, 0x1111
    call nebo_x11_window_hide
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_STALE_HANDLE, hide_stale_handle
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    xor ecx, ecx
    mov r8d, 10
    call nebo_x11_window_resize
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_DIMENSION_OUT_OF_RANGE, resize_width_zero
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x9999
    lea rcx, [rel title1]
    xor r8d, r8d
    call nebo_x11_window_set_title
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_OWNER_MISMATCH, title_owner
    xor edi, edi
    call nebo_x11_window_event_kind
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_INVALID_ARGUMENT, kind_null
    ASSERT_EQ_D edx, 0, kind_null_present

    ; 1: MapNotify -> SHOWN for window 1 only.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_MAP_NOTIFY
    mov dword [rel raw_event+8], 0x111
    TRANSLATE
    ASSERT_ZERO eax, map_status
    ASSERT_EQ_D edx, 1, map_processed
    ASSERT_EQ_D [rel records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_VISIBLE, map_canonical_visible
    ASSERT_EQ_D [rel native_records+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED, map_native_mapped
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 1, map_count
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_SHOWN, map_kind
    inc r15d ; assert_map_opaque_handle
    mov rax, [rel events1+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
    mov rdx, 0x0000000100000001
    cmp rax, rdx
    jne .fail
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET], 1, map_sequence
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_TIMESTAMP_OFFSET], 1, map_timestamp
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_FLAGS_OFFSET], NEBO_WINDOW_EVENT_FLAG_NATIVE, map_native_flag
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_SIZE+NEBO_WINDOW_EVENT_COUNT_OFFSET], 0, map_no_cross_route

    ; 2: ConfigureNotify -> RESIZED with bounded dimensions.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov dword [rel raw_event+8], 0x111
    mov word [rel raw_event+20], 800
    mov word [rel raw_event+22], 600
    TRANSLATE
    ASSERT_ZERO eax, configure_status
    ASSERT_EQ_D edx, 1, configure_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_WIDTH_OFFSET], 800, configure_width
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_HEIGHT_OFFSET], 600, configure_height
    ASSERT_EQ_Q [rel native_records+NEBO_X11_WINDOW_WIDTH_OFFSET], 800, configure_native_width
    ASSERT_EQ_Q [rel native_records+NEBO_X11_WINDOW_HEIGHT_OFFSET], 600, configure_native_height
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_RESIZED, configure_kind
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SIZE+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET], 800, configure_payload_width
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SIZE+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET], 600, configure_payload_height

    ; Typed resize accessor is backend-independent.
    lea rdi, [rel events1+NEBO_WINDOW_EVENT_SIZE]
    call nebo_x11_window_event_resize
    ASSERT_ZERO eax, resize_accessor_status
    ASSERT_EQ_D edx, 1, resize_accessor_present
    ASSERT_EQ_Q r8, 800, resize_accessor_width
    ASSERT_EQ_Q r9, 600, resize_accessor_height

    ; 3: FocusIn.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_FOCUS_IN
    mov dword [rel raw_event+4], 0x111
    TRANSLATE
    ASSERT_ZERO eax, focus_status
    ASSERT_EQ_D edx, 1, focus_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*2+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_FOCUS_GAINED, focus_kind

    ; 4: MotionNotify packs signed 26.6 coordinates and common modifiers.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_MOTION_NOTIFY
    mov dword [rel raw_event+12], 0x111
    mov word [rel raw_event+24], 12
    mov word [rel raw_event+26], -3
    mov word [rel raw_event+28], (NEBO_X11_STATE_SHIFT | NEBO_X11_STATE_CONTROL)
    TRANSLATE
    ASSERT_ZERO eax, motion_status
    ASSERT_EQ_D edx, 1, motion_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*3+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_POINTER_MOVED, motion_kind
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*3+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET], 12*64, motion_x
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*3+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET+4], -3*64, motion_y
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*3+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET+4], (NEBO_PLATFORM_MOD_SHIFT | NEBO_PLATFORM_MOD_CONTROL), motion_modifiers

    ; Typed pointer accessor.
    lea rdi, [rel events1+NEBO_WINDOW_EVENT_SIZE*3]
    call nebo_x11_window_event_pointer
    ASSERT_ZERO eax, pointer_accessor_status
    ASSERT_EQ_D edx, 1, pointer_accessor_present
    ASSERT_EQ_D r8d, 12*64, pointer_accessor_x
    mov rax, r8
    shr rax, 32
    ASSERT_EQ_D eax, -3*64, pointer_accessor_y

    ; 5/6: button down/up.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_BUTTON_PRESS
    mov byte [rel raw_event+1], 1
    mov dword [rel raw_event+12], 0x111
    mov word [rel raw_event+24], 5
    mov word [rel raw_event+26], 7
    mov word [rel raw_event+28], NEBO_X11_STATE_MOD1
    TRANSLATE
    ASSERT_ZERO eax, button_down_status
    ASSERT_EQ_D edx, 1, button_down_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*4+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_POINTER_DOWN, button_down_kind
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*4+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET], 1, button_down_button
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*4+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET+4], NEBO_PLATFORM_MOD_ALT, button_down_mod
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw_event+1], 1
    mov dword [rel raw_event+12], 0x111
    mov word [rel raw_event+24], 5
    mov word [rel raw_event+26], 7
    TRANSLATE
    ASSERT_ZERO eax, button_up_status
    ASSERT_EQ_D edx, 1, button_up_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*5+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_POINTER_UP, button_up_kind

    ; 7: wheel press maps to POINTER_WHEEL; release is ignored.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_BUTTON_PRESS
    mov byte [rel raw_event+1], 4
    mov dword [rel raw_event+12], 0x111
    mov word [rel raw_event+24], 9
    mov word [rel raw_event+26], 10
    mov word [rel raw_event+28], (NEBO_X11_STATE_CONTROL | NEBO_X11_STATE_MOD4)
    TRANSLATE
    ASSERT_ZERO eax, wheel_status
    ASSERT_EQ_D edx, 1, wheel_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*6+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_POINTER_WHEEL, wheel_kind
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*6+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET], 0, wheel_dx
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*6+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET+4], 1, wheel_dy
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*6+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET], (NEBO_PLATFORM_MOD_CONTROL | NEBO_PLATFORM_MOD_SUPER), wheel_common_mods
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_BUTTON_RELEASE
    mov byte [rel raw_event+1], 4
    mov dword [rel raw_event+12], 0x111
    TRANSLATE
    ASSERT_ZERO eax, wheel_release_status
    ASSERT_EQ_D edx, 0, wheel_release_ignored
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 7, wheel_release_count_stable

    ; 8/9: KeyPress produces KEY_DOWN plus canonical TEXT_INPUT.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_KEY_PRESS
    mov byte [rel raw_event+1], 38
    mov dword [rel raw_event+12], 0x111
    TRANSLATE
    ASSERT_ZERO eax, key_down_status
    ASSERT_EQ_D edx, 1, key_down_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 9, key_down_two_events
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*7+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_KEY_DOWN, key_down_kind
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*8+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_TEXT_INPUT, text_kind
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SIZE*8+NEBO_WINDOW_EVENT_PAYLOAD0_OFFSET], 0x61, text_scalar
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SIZE*8+NEBO_WINDOW_EVENT_PAYLOAD1_OFFSET], 1, text_length
    ASSERT_EQ_Q [rel events1+NEBO_WINDOW_EVENT_SIZE*8+NEBO_WINDOW_EVENT_PAYLOAD2_OFFSET], 0x61, text_bytes
    ASSERT_EQ_D [rel native_records+NEBO_X11_WINDOW_PENDING_INPUT_KIND_OFFSET], 0, text_pending_cleared
    lea rdi, [rel events1+NEBO_WINDOW_EVENT_SIZE*7]
    call nebo_x11_window_event_key
    ASSERT_ZERO eax, key_accessor_status
    ASSERT_EQ_D edx, 1, key_accessor_present
    ASSERT_EQ_D r8d, NEBO_PLATFORM_KEY_UNMAPPED, key_accessor_logical
    mov rax, r8
    shr rax, 32
    ASSERT_EQ_D eax, 38, key_accessor_native
    lea rdi, [rel events1+NEBO_WINDOW_EVENT_SIZE*8]
    call nebo_x11_window_event_text_input
    ASSERT_ZERO eax, text_accessor_status
    ASSERT_EQ_D edx, 1, text_accessor_present
    ASSERT_EQ_Q r8, 0x61, text_accessor_scalar
    ASSERT_EQ_Q r9, 1, text_accessor_length
    ASSERT_EQ_Q r10, 0x61, text_accessor_bytes

    ; 10: key release never produces text.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_KEY_RELEASE
    mov byte [rel raw_event+1], 38
    mov dword [rel raw_event+12], 0x111
    TRANSLATE
    ASSERT_ZERO eax, key_up_status
    ASSERT_EQ_D edx, 1, key_up_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 10, key_up_count
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*9+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_KEY_UP, key_up_kind

    ; 11: Expose -> REDRAW_REQUESTED.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_EXPOSE
    mov dword [rel raw_event+4], 0x111
    TRANSLATE
    ASSERT_ZERO eax, expose_status
    ASSERT_EQ_D edx, 1, expose_processed
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*10+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_REDRAW_REQUESTED, expose_kind

    ; Window 2 is routed independently.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_FOCUS_OUT
    mov dword [rel raw_event+4], 0x222
    TRANSLATE
    ASSERT_ZERO eax, window2_status
    ASSERT_EQ_D edx, 1, window2_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_SIZE+NEBO_WINDOW_EVENT_COUNT_OFFSET], 1, window2_count
    ASSERT_EQ_D [rel events2+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_FOCUS_LOST, window2_kind
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 11, window1_count_unchanged

    ; Unknown target and unknown type do not contaminate queues.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_FOCUS_IN
    mov dword [rel raw_event+4], 0x999
    TRANSLATE
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_STALE_HANDLE, unknown_xid_status
    ASSERT_EQ_D edx, 0, unknown_xid_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 11, unknown_xid_window1_stable
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_SIZE+NEBO_WINDOW_EVENT_COUNT_OFFSET], 1, unknown_xid_window2_stable
    RAW_CLEAR
    mov byte [rel raw_event], 99
    TRANSLATE
    ASSERT_ZERO eax, unknown_type_status
    ASSERT_EQ_D edx, 0, unknown_type_processed

    ; 12: WM_DELETE is native and preventable, never exposes the XID as handle.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_CLIENT_MESSAGE
    mov byte [rel raw_event+1], 32
    mov dword [rel raw_event+4], 0x111
    mov dword [rel raw_event+8], 0x11223344
    mov dword [rel raw_event+12], 0x55667788
    TRANSLATE
    ASSERT_ZERO eax, close_request_status
    ASSERT_EQ_D edx, 1, close_request_processed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 12, close_request_count
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_KIND_OFFSET], NEBO_WINDOW_EVENT_CLOSE_REQUESTED, close_request_kind
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_FLAGS_OFFSET], (NEBO_WINDOW_EVENT_FLAG_NATIVE | NEBO_WINDOW_EVENT_FLAG_PREVENTABLE), close_request_flags
    inc r15d ; assert_close_request_opaque
    mov rax, [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
    mov rdx, 0x0000000100000001
    cmp rax, rdx
    jne .fail
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_HANDLE_OFFSET], 1, close_request_not_xid

    ; preventDefault is bound to the active stream, pointer and sequence.
    lea rdi, [rel stream1]
    lea rax, [rel runtime]
    mov [rdi+NEBO_HEADLESS_STREAM_RUNTIME_PTR_OFFSET], rax
    mov rax, 0x0000000100000001
    mov [rdi+NEBO_HEADLESS_STREAM_HANDLE_OFFSET], rax
    mov qword [rdi+NEBO_HEADLESS_STREAM_OWNER_CONTEXT_OFFSET], 0x1111
    mov qword [rdi+NEBO_HEADLESS_STREAM_GENERATION_OFFSET], 1
    mov qword [rdi+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET], 1
    lea rax, [rel events1+NEBO_WINDOW_EVENT_SIZE*11]
    mov [rdi+NEBO_HEADLESS_STREAM_DISPATCH_EVENT_PTR_OFFSET], rax
    mov rax, [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_SEQUENCE_OFFSET]
    mov [rdi+NEBO_HEADLESS_STREAM_DISPATCH_TOKEN_OFFSET], rax
    or dword [rel records+NEBO_WINDOW_FLAGS_OFFSET], NEBO_HEADLESS_FLAG_STREAM_BORROWED
    lea rdi, [rel stream2]
    mov qword [rdi+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET], 1
    lea rsi, [rel events1+NEBO_WINDOW_EVENT_SIZE*11]
    call nebo_x11_window_event_prevent_default
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_NOT_PREVENTABLE, prevent_cross_stream
    lea rdi, [rel stream1]
    lea rsi, [rel events1+NEBO_WINDOW_EVENT_SIZE*11]
    call nebo_x11_window_event_prevent_default
    ASSERT_ZERO eax, prevent_status
    ASSERT_EQ_D [rel events1+NEBO_WINDOW_EVENT_SIZE*11+NEBO_WINDOW_EVENT_FLAGS_OFFSET], (NEBO_WINDOW_EVENT_FLAG_NATIVE | NEBO_WINDOW_EVENT_FLAG_PREVENTABLE | NEBO_WINDOW_EVENT_FLAG_PREVENTED), prevent_flag
    lea rdi, [rel stream1]
    call nebo_x11_event_stream_release
    ASSERT_ZERO eax, release_prevented_stream
    ASSERT_EQ_D [rel records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_VISIBLE, prevented_close_preserves_state
    ASSERT_EQ_Q [rel stream1+NEBO_HEADLESS_STREAM_ACTIVE_OFFSET], 0, stream_released

    ; DestroyNotify from the server closes canonically without a second destroy.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_DESTROY_NOTIFY
    mov dword [rel raw_event+8], 0x111
    TRANSLATE
    ASSERT_ZERO eax, destroy_notify_status
    ASSERT_EQ_D edx, 1, destroy_notify_processed
    ASSERT_EQ_D [rel native_records+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED, destroy_native_state
    ASSERT_EQ_Q [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 1, destroy_active_decrement
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    call nebo_x11_window_close
    ASSERT_ZERO eax, destroy_canonical_close
    ASSERT_EQ_D [rel records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_CLOSED, destroy_canonical_closed
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_CLEANUP_COUNT_OFFSET], 1, destroy_cleanup_once
    ASSERT_EQ_D [rel native_records+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_DESTROYED, destroy_no_second_destroy
    ; Reclaim blocks while events remain, then succeeds after the caller drains.
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    call nebo_x11_window_reclaim
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_BAD_STATE, reclaim_pending_events
    mov qword [rel records+NEBO_WINDOW_EVENT_HEAD_OFFSET], 0
    mov qword [rel records+NEBO_WINDOW_EVENT_TAIL_OFFSET], 0
    mov qword [rel records+NEBO_WINDOW_EVENT_COUNT_OFFSET], 0
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    call nebo_x11_window_reclaim
    ASSERT_ZERO eax, reclaim_terminal
    ASSERT_EQ_D [rel records+NEBO_WINDOW_STATE_OFFSET], NEBO_WINDOW_STATE_RECLAIMED, reclaim_state
    ASSERT_EQ_Q [rel records+nebo_canvas_WINDOW_GENERATION_OFFSET], 2, reclaim_generation
    ASSERT_EQ_Q [rel runtime+NEBO_HEADLESS_RUNTIME_ACTIVE_COUNT_OFFSET], 1, reclaim_active_count
    ASSERT_EQ_Q [rel native_records+NEBO_X11_WINDOW_ADAPTER_PTR_OFFSET], 0, reclaim_native_zero
    lea rdi, [rel runtime]
    mov rsi, 0x0000000100000001
    mov rdx, 0x1111
    call nebo_x11_window_reclaim
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_STALE_HANDLE, reclaim_stale

    ; Malformed X11 error packet is reported and marks the runtime disconnected.
    RAW_CLEAR
    mov byte [rel raw_event], NEBO_X11_EVENT_ERROR
    TRANSLATE
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_BACKEND_FAILURE, malformed_status
    ASSERT_EQ_D edx, 0, malformed_processed
    mov eax, [rel runtime+NEBO_X11_RUNTIME_FLAGS_OFFSET]
    and eax, NEBO_X11_RUNTIME_FLAG_DISCONNECTED
    ASSERT_EQ_D eax, NEBO_X11_RUNTIME_FLAG_DISCONNECTED, malformed_disconnected
    ASSERT_EQ_Q [rel runtime+NEBO_X11_RUNTIME_LAST_ERROR_OFFSET], NEBO_X11_DIAG_PROTOCOL_MALFORMED, malformed_diag

    ; wait has an explicit 4096-cycle ceiling before any backend observation.
    lea rdi, [rel stream2]
    lea rsi, [rel event_out]
    mov edx, NEBO_X11_WAIT_MAX_CYCLES+1
    call nebo_x11_event_stream_wait
    ASSERT_EQ_D eax, NEBO_WINDOW_ERROR_LIMIT_EXCEEDED, wait_limit
    ASSERT_EQ_D edx, 0, wait_limit_ready

    ; Final invariants: no XID ever appears as the public Window handle.
    inc r15d ; assert_window2_opaque_handle
    mov rax, [rel events2+NEBO_WINDOW_EVENT_HANDLE_OFFSET]
    mov rdx, 0x0000000100000002
    cmp rax, rdx
    jne .fail
    ASSERT_EQ_D [rel events2+NEBO_WINDOW_EVENT_HANDLE_OFFSET], 2, window2_not_xid
    ASSERT_EQ_Q [rel runtime+NEBO_HEADLESS_RUNTIME_LOGICAL_CLOCK_OFFSET], 15, logical_clock_exact
    ASSERT_EQ_Q [rel records+NEBO_WINDOW_SIZE+NEBO_WINDOW_NEXT_EVENT_SEQUENCE_OFFSET], 1, window2_sequence_isolated

    mov eax, 60
    xor edi, edi
    syscall
.fail:
    mov edi, r15d
    mov eax, 60
    syscall
