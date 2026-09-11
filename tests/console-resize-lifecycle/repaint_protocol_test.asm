; R3 atomic-present wire oracle. No display, input, pointer, or libc is used.
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_platform_report_init
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern nebo_x11_adapter_destroy_window

global _start

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_SOCKETPAIR 53
%define SYS_EXIT 60
%define TEST_WIDTH 128
%define TEST_HEIGHT 66
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_GROW_WIDTH 160
%define TEST_GROW_HEIGHT 80
%define TEST_GROW_STRIDE (TEST_GROW_WIDTH*4)
%define TEST_GROW_BYTES (TEST_GROW_STRIDE*TEST_GROW_HEIGHT)
%define TEST_MAX_REQUEST_UNITS 1030
%define TEST_ROWS_PER_UPLOAD 8
%define TEST_UPLOAD_COUNT 9
%define TEST_STRESS_COUNT 500
%define TEST_PENDING_WIDTH 130
%define TEST_WINDOW_BYTES NEBO_X11_WINDOW_SIZE
%define TEST_PIXMAP_XID_OFFSET 272
%define TEST_PIXMAP_WIDTH_OFFSET 276
%define TEST_PIXMAP_HEIGHT_OFFSET 280
%define TEST_LAST_SURFACE_GEN_OFFSET 288
%define TEST_LAST_PRESENT_WIDTH_OFFSET 296
%define TEST_LAST_PRESENT_HEIGHT_OFFSET 304
%define TEST_BACKBUFFER_ALLOCATIONS_OFFSET 312
%define TEST_PRESENT_GEOMETRY_GUARD_OFFSET 320
%define TEST_LAST_ACTUAL_WIDTH_OFFSET 328
%define TEST_LAST_ACTUAL_HEIGHT_OFFSET 336
%define TEST_PENDING_CONFIGURE_COUNT_OFFSET 344
%define TEST_LATEST_PENDING_X_OFFSET 352
%define TEST_LATEST_PENDING_WIDTH_OFFSET 368
%define TEST_PRESENT_GEOMETRY_MISMATCH_COUNT_OFFSET 384
%define TEST_SKIPPED_STALE_PRESENT_COUNT_OFFSET 392
%define TEST_GEOMETRY_GENERATION_OFFSET 400
%define TEST_LAST_PRESENT_GEOMETRY_GENERATION_OFFSET 408
%define TEST_GEOMETRY_QUERY_COUNT_OFFSET 416
%define TEST_BACKGROUND_RGB 0x00111821

%ifndef NEBO_X11_OP_CREATE_PIXMAP
%define NEBO_X11_OP_CREATE_PIXMAP 53
%endif
%ifndef NEBO_X11_OP_FREE_PIXMAP
%define NEBO_X11_OP_FREE_PIXMAP 54
%endif
%ifndef NEBO_X11_OP_COPY_AREA
%define NEBO_X11_OP_COPY_AREA 62
%endif
%ifndef NEBO_X11_OP_GET_GEOMETRY
%define NEBO_X11_OP_GET_GEOMETRY 14
%endif

section .bss align=64
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb TEST_WINDOW_BYTES
config: resb NEBO_X11_WINDOW_CONFIG_SIZE
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
scratch: resb NEBO_X11_MIN_SCRATCH_CAPACITY
pixels: resb TEST_GROW_BYTES
wire_header: resb 64
wire_payload: resb 4096
socket_fds: resd 2
failure: resd 1
old_pixmap: resd 1
expected_geometry_query: resd 1
expected_stale_present: resd 1
present_count_before: resq 1

section .text
_start:
    mov dword [rel failure], 1
    mov eax, SYS_SOCKETPAIR
    mov edi, NEBO_LINUX_AF_UNIX
    mov esi, NEBO_LINUX_SOCK_STREAM
    xor edx, edx
    lea r10, [rel socket_fds]
    syscall
    test eax, eax
    js test_fail

    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    rep stosq
    mov eax, [rel socket_fds]
    mov [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET], rax
    mov dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    mov dword [rel adapter+NEBO_X11_ADAPTER_FLAGS_OFFSET], NEBO_X11_ADAPTER_REQUIRED_FLAGS
    mov qword [rel adapter+NEBO_X11_ADAPTER_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov qword [rel adapter+NEBO_X11_ADAPTER_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF051_REQUIRED_CAPABILITIES
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_BASE_OFFSET], 0x02000000
    mov dword [rel adapter+NEBO_X11_ADAPTER_RESOURCE_ID_MASK_OFFSET], 0x001fffff
    mov qword [rel adapter+NEBO_X11_ADAPTER_NEXT_WINDOW_SLOT_OFFSET], 1
    mov qword [rel adapter+NEBO_X11_ADAPTER_NEXT_WINDOW_GENERATION_OFFSET], 1
    mov dword [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET], 0x00000100
    mov dword [rel adapter+NEBO_X11_ADAPTER_ROOT_VISUAL_OFFSET], 0x00000200
    mov dword [rel adapter+NEBO_X11_ADAPTER_BLACK_PIXEL_OFFSET], 0
    mov word [rel adapter+NEBO_X11_ADAPTER_MAX_REQUEST_UNITS_OFFSET], TEST_MAX_REQUEST_UNITS
    mov byte [rel adapter+NEBO_X11_ADAPTER_ROOT_DEPTH_OFFSET], 24
    mov byte [rel adapter+NEBO_X11_ADAPTER_BITS_PER_PIXEL_OFFSET], 32
    mov byte [rel adapter+NEBO_X11_ADAPTER_SCANLINE_PAD_OFFSET], 32
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE
    mov dword [rel adapter+NEBO_X11_ADAPTER_MOTIF_HINTS_ATOM_OFFSET], 0x300
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_PROTOCOLS_ATOM_OFFSET], 0x301
    mov dword [rel adapter+NEBO_X11_ADAPTER_WM_DELETE_WINDOW_ATOM_OFFSET], 0x302
    lea rax, [rel scratch]
    mov [rel adapter+NEBO_X11_ADAPTER_SCRATCH_PTR_OFFSET], rax
    mov qword [rel adapter+NEBO_X11_ADAPTER_SCRATCH_CAPACITY_OFFSET], NEBO_X11_MIN_SCRATCH_CAPACITY
    lea rdi, [rel adapter+NEBO_X11_ADAPTER_REPORT_OFFSET]
    mov rsi, NEBO_X11_ADAPTER_ID_HASH
    mov rdx, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov rcx, NEBO_PLATFORM_SCALE_ONE
    mov r8d, NEBO_PLATFORM_REPORT_REQUIRED_FLAGS
    call nebo_platform_report_init
    test eax, eax
    jnz test_fail_close

    lea rdi, [rel pixels]
    mov eax, 0xff112233
    mov ecx, TEST_GROW_BYTES/4
    rep stosd
    lea rdi, [rel surface]
    xor eax, eax
    mov ecx, NEBO_SOFTWARE_SURFACE_QWORDS
    rep stosq
    lea rax, [rel pixels]
    mov [rel surface+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET], rax
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], TEST_BYTES
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], TEST_STRIDE
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], 1
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET], NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS

    lea rdi, [rel config]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    rep stosq
    lea rax, [rel surface]
    mov [rel config+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET], rax
    mov qword [rel config+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel config+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel config+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS | NEBO_X11_WINDOW_CONFIG_FLAG_DEFER_MAP
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jnz test_fail_close

    ; Creation must allocate one retained pixmap between window and GC setup.
    mov dword [rel failure], 10
    mov edx, 44
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CREATE_WINDOW
    jne test_fail_close
    cmp word [rel wire_header+2], 11
    jne test_fail_close
    cmp dword [rel wire_header+28], (NEBO_X11_CW_BACK_PIXEL | NEBO_X11_CW_BIT_GRAVITY | NEBO_X11_CW_EVENT_MASK)
    jne test_fail_close
    cmp dword [rel wire_header+32], TEST_BACKGROUND_RGB
    jne test_fail_close
    cmp dword [rel wire_header+36], NEBO_X11_BIT_GRAVITY_FORGET
    jne test_fail_close
    cmp dword [rel wire_header+40], NEBO_X11_MF053_EVENT_MASK
    jne test_fail_close
    mov edx, 16
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CREATE_PIXMAP
    jne test_fail_close
    mov eax, [rel window+TEST_PIXMAP_XID_OFFSET]
    test eax, eax
    jz test_fail_close
    cmp [rel wire_header+4], eax
    jne test_fail_close
    cmp word [rel wire_header+12], TEST_WIDTH
    jne test_fail_close
    cmp word [rel wire_header+14], TEST_HEIGHT
    jne test_fail_close
    mov edx, 16
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CREATE_GC
    jne test_fail_close
    mov edx, 44
    call read_wire
    test eax, eax
    jnz test_fail_close
    mov edx, 28
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CHANGE_PROPERTY
    jne test_fail_close
    ; _NET_WM_PID is the third create-time property.  Consume it before the
    ; first private-frame oracle so it cannot be mistaken for PutImage.
    mov edx, 28
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CHANGE_PROPERTY
    jne test_fail_close
    cmp dword [rel window+TEST_PIXMAP_WIDTH_OFFSET], TEST_WIDTH
    jne test_fail_close
    cmp dword [rel window+TEST_PIXMAP_HEIGHT_OFFSET], TEST_HEIGHT
    jne test_fail_close
    cmp qword [rel window+TEST_BACKBUFFER_ALLOCATIONS_OFFSET], 1
    jne test_fail_close

    mov dword [rel window+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    or dword [rel window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MAPPED
    mov r12d, TEST_STRESS_COUNT
    mov r13, 1
.stress:
    mov [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], r13
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz test_fail_close
    call validate_frame_wire
    test eax, eax
    jnz test_fail_close
    cmp [rel window+TEST_LAST_SURFACE_GEN_OFFSET], r13
    jne test_generation_fail

    cmp qword [rel window+TEST_LAST_PRESENT_WIDTH_OFFSET], TEST_WIDTH
    jne test_generation_fail
    cmp qword [rel window+TEST_LAST_PRESENT_HEIGHT_OFFSET], TEST_HEIGHT
    jne test_generation_fail
    inc r13
    dec r12d
    jnz .stress
    cmp qword [rel window+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET], TEST_STRESS_COUNT
    jne test_generation_fail
    cmp qword [rel window+TEST_BACKBUFFER_ALLOCATIONS_OFFSET], 1
    jne test_generation_fail

    ; Grow once: ensure must allocate one larger pixmap before upload, then
    ; release the old resource. The visible window still changes once.
    mov eax, [rel window+TEST_PIXMAP_XID_OFFSET]
    mov [rel old_pixmap], eax
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_GROW_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_GROW_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], TEST_GROW_BYTES
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], TEST_GROW_WIDTH
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], TEST_GROW_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], TEST_GROW_STRIDE
    mov [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], r13
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 31
    mov edx, 16
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_CREATE_PIXMAP
    jne test_fail_close
    mov eax, [rel window+TEST_PIXMAP_XID_OFFSET]
    cmp [rel wire_header+4], eax
    jne test_fail_close
    cmp word [rel wire_header+12], TEST_WIDTH*2
    jne test_fail_close
    cmp word [rel wire_header+14], TEST_HEIGHT*2
    jne test_fail_close
    mov edx, 8
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_FREE_PIXMAP
    jne test_fail_close
    mov eax, [rel old_pixmap]
    cmp [rel wire_header+4], eax
    jne test_fail_close
    call validate_frame_wire
    test eax, eax
    jnz test_fail_close
    cmp qword [rel window+TEST_BACKBUFFER_ALLOCATIONS_OFFSET], 2
    jne test_generation_fail
    cmp dword [rel window+TEST_PIXMAP_WIDTH_OFFSET], TEST_WIDTH*2
    jne test_generation_fail
    cmp dword [rel window+TEST_PIXMAP_HEIGHT_OFFSET], TEST_HEIGHT*2
    jne test_generation_fail
    cmp [rel window+TEST_LAST_SURFACE_GEN_OFFSET], r13
    jne test_generation_fail
    inc r13

    ; Shrink reuses the larger pixmap and copies only the current rectangle.
    mov qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], TEST_BYTES
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], TEST_STRIDE
    mov [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], r13
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz test_fail_close
    call validate_frame_wire
    test eax, eax
    jnz test_fail_close
    cmp qword [rel window+TEST_BACKBUFFER_ALLOCATIONS_OFFSET], 2
    jne test_generation_fail
    cmp [rel window+TEST_LAST_SURFACE_GEN_OFFSET], r13
    jne test_generation_fail

    ; A newer ConfigureNotify may already be queued after this 128px frame was
    ; rendered. GetGeometry sees the actual 130px drawable, so the obsolete
    ; private frame must not reach CopyArea. The deferred event is then adopted
    ; and exactly one reconciled 130px frame is committed.
    mov dword [rel failure], 35
    call queue_pending_configure
    test eax, eax
    jnz test_fail_close
    mov qword [rel window+TEST_PRESENT_GEOMETRY_GUARD_OFFSET], 1
    inc qword [rel window+TEST_GEOMETRY_GENERATION_OFFSET]
    mov rax, [rel window+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET]
    mov [rel present_count_before], rax
    lea rdi, [rel event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel expected_geometry_query], 1
    mov dword [rel expected_stale_present], 1
    mov qword [rel window+NEBO_X11_WINDOW_LAST_ERROR_OFFSET], 0
    mov dword [rel failure], 41
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel event]
    call nebo_x11_adapter_present
    cmp eax, NEBO_PLATFORM_STATUS_STALE_GEOMETRY
    jne test_fail_close
    mov dword [rel failure], 42
    call validate_frame_wire
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 43
    mov rax, [rel present_count_before]
    cmp [rel window+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET], rax
    jne test_fail_close
    cmp qword [rel window+TEST_LAST_ACTUAL_WIDTH_OFFSET], TEST_PENDING_WIDTH
    jne test_fail_close
    cmp qword [rel window+TEST_LAST_ACTUAL_HEIGHT_OFFSET], TEST_HEIGHT
    jne test_fail_close
    cmp qword [rel window+TEST_PENDING_CONFIGURE_COUNT_OFFSET], 1
    jne test_fail_close
    cmp qword [rel window+TEST_LATEST_PENDING_X_OFFSET], -2
    jne test_fail_close
    cmp qword [rel window+TEST_LATEST_PENDING_WIDTH_OFFSET], TEST_PENDING_WIDTH
    jne test_fail_close
    cmp qword [rel window+TEST_PRESENT_GEOMETRY_MISMATCH_COUNT_OFFSET], 1
    jne test_fail_close
    cmp qword [rel window+TEST_SKIPPED_STALE_PRESENT_COUNT_OFFSET], 1
    jne test_fail_close
    cmp qword [rel window+TEST_GEOMETRY_QUERY_COUNT_OFFSET], 1
    jne test_fail_close

    mov dword [rel failure], 44
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    xor edx, edx
    lea rcx, [rel event]
    call nebo_x11_adapter_poll_event
    test eax, eax
    jnz test_fail_close
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_WINDOW_RESIZED
    jne test_fail_close
    cmp qword [rel window+NEBO_X11_WINDOW_X_OFFSET], -2
    jne test_fail_close
    cmp qword [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET], TEST_PENDING_WIDTH
    jne test_fail_close

    mov dword [rel failure], 45
    inc r13
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_BYTE_CAPACITY_OFFSET], TEST_PENDING_WIDTH*TEST_HEIGHT*4
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET], TEST_PENDING_WIDTH
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel surface+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET], TEST_PENDING_WIDTH*4
    mov [rel surface+NEBO_SOFTWARE_SURFACE_GENERATION_OFFSET], r13
    mov edi, TEST_PENDING_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_PENDING_WIDTH
    call queue_geometry_reply
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 46
    lea rdi, [rel event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel expected_geometry_query], 1
    mov dword [rel failure], 47
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    lea rdx, [rel surface]
    lea rcx, [rel event]
    call nebo_x11_adapter_present
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 48
    call validate_frame_wire
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 49
    mov rax, [rel present_count_before]
    inc rax
    cmp [rel window+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET], rax
    jne test_fail_close
    cmp qword [rel window+TEST_PRESENT_GEOMETRY_GUARD_OFFSET], 0
    jne test_fail_close
    cmp qword [rel window+TEST_GEOMETRY_QUERY_COUNT_OFFSET], 2
    jne test_fail_close
    cmp qword [rel window+TEST_PRESENT_GEOMETRY_MISMATCH_COUNT_OFFSET], 1
    jne test_fail_close
    cmp qword [rel window+TEST_SKIPPED_STALE_PRESENT_COUNT_OFFSET], 1
    jne test_fail_close
    mov rax, [rel window+TEST_GEOMETRY_GENERATION_OFFSET]
    cmp [rel window+TEST_LAST_PRESENT_GEOMETRY_GENERATION_OFFSET], rax
    jne test_fail_close
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
    jne test_fail_close

    lea rdi, [rel adapter]
    lea rsi, [rel window]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz test_fail_close
    mov dword [rel failure], 40
    mov edx, 8
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_FREE_PIXMAP
    jne test_fail_close
    mov edx, 8
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_FREE_GC
    jne test_fail_close
    mov edx, 8
    call read_wire
    test eax, eax
    jnz test_fail_close
    cmp byte [rel wire_header], NEBO_X11_OP_DESTROY_WINDOW
    jne test_fail_close
    cmp dword [rel window+TEST_PIXMAP_XID_OFFSET], 0
    jne test_fail_close
    xor edi, edi
    jmp test_exit_close

test_generation_fail:
    mov dword [rel failure], 30
    jmp test_fail_close

; Validate all private PutImage uploads followed by one visible CopyArea.
validate_frame_wire:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov dword [rel failure], 20
    xor r12d, r12d
    mov r13d, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    mov eax, (TEST_MAX_REQUEST_UNITS*4)-24
    xor edx, edx
    mov ebx, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    shl ebx, 2
    div ebx
    mov r14d, eax
.upload:
    mov edx, 24
    call read_wire
    test eax, eax
    jnz .wire_fail
    cmp byte [rel wire_header], NEBO_X11_OP_PUT_IMAGE
    jne .wire_fail
    mov eax, [rel window+TEST_PIXMAP_XID_OFFSET]
    cmp [rel wire_header+4], eax
    jne .wire_fail
    mov eax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    cmp [rel wire_header+12], ax
    jne .wire_fail
    mov eax, r13d
    cmp eax, r14d
    jbe .rows_ready
    mov eax, r14d
.rows_ready:
    cmp [rel wire_header+14], ax
    jne .wire_fail
    mov r15d, eax
    mov eax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    sub eax, r13d
    cmp [rel wire_header+18], ax
    jne .wire_fail
    mov edx, r15d
    mov ecx, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    shl ecx, 2
    imul edx, ecx
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire_payload]
    call read_exact
    test eax, eax
    jnz .wire_fail
    cmp dword [rel wire_payload], 0xff112233
    jne .wire_fail
    sub r13d, r15d
    inc r12d
    test r13d, r13d
    jnz .upload
    cmp dword [rel expected_geometry_query], 0
    je .copy_area
    mov edx, 8
    call read_wire
    test eax, eax
    jnz .wire_fail
    cmp byte [rel wire_header], NEBO_X11_OP_GET_GEOMETRY
    jne .wire_fail
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    cmp [rel wire_header+4], eax
    jne .wire_fail
    mov dword [rel expected_geometry_query], 0
    cmp dword [rel expected_stale_present], 0
    je .copy_area
    mov dword [rel expected_stale_present], 0
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], 0
    jne .wire_fail
    xor eax, eax
    jmp .wire_done
.copy_area:
    mov edx, 28
    call read_wire
    test eax, eax
    jnz .wire_fail
    cmp byte [rel wire_header], NEBO_X11_OP_COPY_AREA
    jne .wire_fail
    mov eax, [rel window+TEST_PIXMAP_XID_OFFSET]
    cmp [rel wire_header+4], eax
    jne .wire_fail
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    cmp [rel wire_header+8], eax
    jne .wire_fail
    mov eax, [rel window+NEBO_X11_WINDOW_WIDTH_OFFSET]
    cmp [rel wire_header+24], ax
    jne .wire_fail
    mov eax, [rel window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    cmp [rel wire_header+26], ax
    jne .wire_fail
    cmp dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
    jne .wire_fail
    xor eax, eax
    jmp .wire_done
.wire_fail:
    mov eax, 1
.wire_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Put one exact 32-byte ConfigureNotify followed by the matching GetGeometry
; reply on the client-facing socket. No pointer/input is generated.
queue_pending_configure:
    lea rdi, [rel wire_header]
    xor eax, eax
    mov ecx, 8
    cld
    rep stosd
    mov byte [rel wire_header], NEBO_X11_EVENT_CONFIGURE_NOTIFY
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel wire_header+8], eax
    mov word [rel wire_header+16], -2
    mov word [rel wire_header+18], 0
    mov word [rel wire_header+20], TEST_PENDING_WIDTH
    mov word [rel wire_header+22], TEST_HEIGHT
    mov eax, 1
    mov [rel wire_header+24], eax
    mov eax, 1
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire_header]
    mov edx, 32
    syscall
    cmp rax, 32
    jne .queue_fail
    mov edi, TEST_PENDING_WIDTH
    mov esi, TEST_HEIGHT
    mov edx, TEST_WIDTH
    jmp queue_geometry_reply
.queue_fail:
    mov eax, 1
    ret

; EDI=actual width, ESI=actual height, EDX=rendered width. Queue a core
; GetGeometry reply whose sequence accounts for the pending private uploads
; and the query itself. Actual and rendered widths intentionally differ in the
; stale-frame phase.
queue_geometry_reply:
    push rbx
    push r12
    push r13
    push r14
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    movzx eax, word [rel adapter+NEBO_X11_ADAPTER_MAX_REQUEST_UNITS_OFFSET]
    shl eax, 2
    sub eax, 24
    xor edx, edx
    mov ebx, r14d
    shl ebx, 2
    div ebx
    mov ebx, eax
    mov eax, r13d
    add eax, ebx
    dec eax
    xor edx, edx
    div ebx
    mov r10, [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    add r10, rax
    inc r10
    lea rdi, [rel wire_header]
    xor eax, eax
    mov ecx, 8
    cld
    rep stosd
    mov byte [rel wire_header], NEBO_X11_REPLY
    mov byte [rel wire_header+1], 24
    mov word [rel wire_header+2], r10w
    mov eax, [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [rel wire_header+8], eax
    mov word [rel wire_header+16], r12w
    mov word [rel wire_header+18], r13w
    mov eax, 1
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire_header]
    mov edx, 32
    syscall
    cmp rax, 32
    jne .geometry_reply_fail
    xor eax, eax
    jmp .geometry_reply_done
.geometry_reply_fail:
    mov eax, 1
.geometry_reply_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDX=count from peer socket into wire_header.
read_wire:
    mov edi, [rel socket_fds+4]
    lea rsi, [rel wire_header]
    jmp read_exact

; EDI=fd, RSI=buffer, EDX=count.
read_exact:
    push rbx
    mov ebx, edx
.read_loop:
    mov eax, SYS_READ
    mov edx, ebx
    syscall
    test rax, rax
    jle .read_fail
    add rsi, rax
    sub ebx, eax
    jnz .read_loop
    xor eax, eax
    pop rbx
    ret
.read_fail:
    mov eax, 1
    pop rbx
    ret

test_fail_close:
    mov edi, [rel failure]
    test edi, edi
    jnz test_exit_close
test_fail:
    mov edi, 99
test_exit_close:
    push rdi
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds]
    syscall
    mov eax, SYS_CLOSE
    mov edi, [rel socket_fds+4]
    syscall
    pop rdi
    mov eax, SYS_EXIT
    syscall
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
