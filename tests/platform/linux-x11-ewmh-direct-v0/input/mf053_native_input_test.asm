; Nebo Assembly — MF053 native pointer, keyboard and Text input contract
bits 64
default rel

%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/platform/input/native_input_bridge.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"

extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_report
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_poll_event
extern nebo_input_registry_init
extern nebo_pending_registry_init
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_focus_manager_init
extern nebo_focus_manager_sync
extern nebo_focus_manager_current_editor
extern nebo_dependency_bridge_init
extern nebo_input_submission_init
extern nebo_native_input_bridge_init
extern nebo_native_input_bridge_dispatch
extern neboc_host_process_exit

global _start

%define TEST_WIDTH 320
%define TEST_HEIGHT 200
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_SURFACE_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_SCRATCH_BYTES 65536
%define INPUT_CAP 2
%define INPUT_TEXT_STRIDE 64
%define LAYOUT_CAP 8
%define CONTINUATION_CAP 4

section .rodata align=8
auth_name: db "MIT-MAGIC-COOKIE-1"

section .bss align=64
report: resb NEBO_PLATFORM_REPORT_SIZE
adapter: resb NEBO_X11_ADAPTER_SIZE
window: resb NEBO_X11_WINDOW_SIZE
normalized_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
manual_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
x11_config: resb NEBO_X11_CONFIG_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb TEST_SCRATCH_BYTES
send_buffer: resb 64
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels: resb TEST_SURFACE_BYTES
socket_arg: resq 1
cookie_arg: resq 1

input_registry: resb NEBO_INPUT_REGISTRY_SIZE
input_records: resb INPUT_CAP*NEBO_INPUT_RECORD_SIZE
pending_registry: resb NEBO_PENDING_REGISTRY_SIZE
pending_records: resb INPUT_CAP*NEBO_PENDING_RECORD_SIZE
provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout: resb NEBO_LAYOUT_TREE_SIZE
layout_boxes: resb LAYOUT_CAP*NEBO_LAYOUT_BOX_SIZE
focus_storage: resb NEBO_FOCUS_STORAGE_SIZE
focus_manager: resb NEBO_FOCUS_MANAGER_SIZE
editors: resb INPUT_CAP*NEBO_TEXT_EDIT_RECORD_SIZE
text_buffers: resb INPUT_CAP*INPUT_TEXT_STRIDE
dependency_bridge: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations: resb CONTINUATION_CAP*NEBO_DEPENDENCY_CONTINUATION_SIZE
submission_storage: resb NEBO_SUBMISSION_STORAGE_SIZE
submission_values: resb INPUT_CAP*INPUT_TEXT_STRIDE
submission_context: resb NEBO_SUBMISSION_CONTEXT_SIZE
submission_result: resb NEBO_SUBMISSION_RESULT_SIZE
native_bridge: resb NEBO_NATIVE_INPUT_BRIDGE_SIZE
editor_ptr: resq 1
key_state: resd 1

section .text
_start:
    cmp qword [rsp], 3
    jne test_usage
    mov rax, [rsp+16]
    mov [rel socket_arg], rax
    mov rax, [rsp+24]
    mov [rel cookie_arg], rax
    call live_init_window
    test eax, eax
    jnz test_fail
    call setup_input_model
    test eax, eax
    jnz test_fail
    lea rdi, [rel native_bridge]
    lea rsi, [rel focus_manager]
    lea rdx, [rel submission_context]
    mov rcx, [rel adapter+NEBO_X11_ADAPTER_SCALE_FACTOR_OFFSET]
    call nebo_native_input_bridge_init
    test eax, eax
    jnz test_fail

    ; Focus activation/deactivation must cross the native event boundary.
    mov edi, NEBO_X11_EVENT_FOCUS_OUT
    call send_focus_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    cmp qword [rel focus_manager+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 0
    jne test_fail
    mov edi, NEBO_X11_EVENT_FOCUS_IN
    call send_focus_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    cmp qword [rel focus_manager+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    jne test_fail

    ; Native pointer move/down/up and focus selection for the second input.
    mov edi, NEBO_X11_EVENT_MOTION_NOTIFY
    mov esi, 24
    mov edx, 104
    xor ecx, ecx
    call send_pointer_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_POINTER_MOVE
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_PRESS
    mov esi, 24
    mov edx, 104
    mov ecx, NEBO_PLATFORM_POINTER_BUTTON_PRIMARY
    call send_pointer_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_POINTER_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov rax, 0x0000000100000001
    cmp [rel focus_manager+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    jne test_fail
    mov edi, NEBO_X11_EVENT_BUTTON_RELEASE
    mov esi, 24
    mov edx, 104
    mov ecx, NEBO_PLATFORM_POINTER_BUTTON_PRIMARY
    call send_pointer_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_POINTER_UP
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail

    ; Dynamic server keymap: shifted A becomes native Text input, then Backspace.
    mov edi, 'A'
    call find_keycode_for_keysym
    test eax, eax
    jz test_fail
    mov esi, eax
    mov ecx, edx
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_TEXT_INPUT
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    lea rdi, [rel focus_manager]
    lea rdx, [rel editor_ptr]
    call nebo_focus_manager_current_editor
    test eax, eax
    jnz test_fail
    mov rbx, [rel editor_ptr]
    cmp qword [rbx+NEBO_TEXT_EDIT_LENGTH_OFFSET], 1
    jne test_fail
    cmp byte [rel text_buffers+INPUT_TEXT_STRIDE], 'A'
    jne test_fail

    mov edi, NEBO_X11_KEYSYM_BACKSPACE
    call find_keycode_for_keysym
    test eax, eax
    jz test_fail
    mov esi, eax
    mov ecx, edx
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    cmp qword [rbx+NEBO_TEXT_EDIT_LENGTH_OFFSET], 0
    jne test_fail

    ; Lowercase b, KeyUp and document-order Tab/Shift+Tab.
    mov edi, 'b'
    call find_keycode_for_keysym
    test eax, eax
    jz test_fail
    mov esi, eax
    mov [rel key_state], edx
    mov ecx, edx
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_TEXT_INPUT
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    cmp byte [rel text_buffers+INPUT_TEXT_STRIDE], 'b'
    jne test_fail
    mov edi, 'b'
    call find_keycode_for_keysym
    mov esi, eax
    mov ecx, edx
    mov edi, NEBO_X11_EVENT_KEY_RELEASE
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_UP
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail

    mov edi, NEBO_X11_KEYSYM_TAB
    call find_keycode_for_keysym
    test eax, eax
    jz test_fail
    mov esi, eax
    mov ecx, NEBO_X11_STATE_SHIFT
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov rax, 0x0000000100000000
    cmp [rel focus_manager+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    jne test_fail
    mov edi, NEBO_X11_KEYSYM_TAB
    call find_keycode_for_keysym
    mov esi, eax
    xor ecx, ecx
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    xor esi, esi
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    mov rax, 0x0000000100000001
    cmp [rel focus_manager+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    jne test_fail

    ; Basic HiDPI fixed-point path: physical 48x208 at scale 2 maps to 24x104.
    mov qword [rel native_bridge+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET], 128
    lea rdi, [rel manual_event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel manual_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_POINTER_DOWN
    mov eax, (48*NEBO_PLATFORM_SCALE_ONE)
    mov edx, (208*NEBO_PLATFORM_SCALE_ONE)
    shl rdx, 32
    or rax, rdx
    mov [rel manual_event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], rax
    mov qword [rel manual_event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], NEBO_PLATFORM_POINTER_BUTTON_PRIMARY
    lea rdi, [rel native_bridge]
    lea rsi, [rel manual_event]
    xor edx, edx
    call nebo_native_input_bridge_dispatch
    test eax, eax
    jnz test_fail
    mov rax, 0x0000000100000001
    cmp [rel focus_manager+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    jne test_fail
    mov qword [rel native_bridge+NEBO_NATIVE_INPUT_BRIDGE_SCALE_FACTOR_OFFSET], NEBO_PLATFORM_SCALE_ONE

    ; ENTER travels as a native logical key and resolves the correct Binding/Pending.
    mov edi, NEBO_X11_KEYSYM_RETURN
    call find_keycode_for_keysym
    test eax, eax
    jz test_fail
    mov esi, eax
    mov ecx, edx
    mov edi, NEBO_X11_EVENT_KEY_PRESS
    call send_key_event
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_EVENT_KEY_DOWN
    lea rsi, [rel submission_result]
    call poll_dispatch_expected
    test eax, eax
    jnz test_fail
    cmp qword [rel submission_result+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], 202
    jne test_fail
    cmp qword [rel submission_result+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET], 1002
    jne test_fail
    cmp qword [rel submission_result+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET], 1
    jne test_fail
    mov rax, [rel submission_result+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET]
    cmp byte [rax], 'b'
    jne test_fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne test_fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_SIZE+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    jne test_fail
    cmp dword [rel pending_records+NEBO_PENDING_RECORD_SIZE+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_RESOLVED
    jne test_fail

    cmp qword [rel native_bridge+NEBO_NATIVE_INPUT_BRIDGE_POINTER_COUNT_OFFSET], 4
    jb test_fail
    cmp qword [rel native_bridge+NEBO_NATIVE_INPUT_BRIDGE_TEXT_COUNT_OFFSET], 2
    jne test_fail
    cmp qword [rel native_bridge+NEBO_NATIVE_INPUT_BRIDGE_ENTER_COUNT_OFFSET], 1
    jne test_fail
    call live_destroy_shutdown
    test eax, eax
    jnz test_fail
    jmp test_pass

; ---------------------------------------------------------------------------
; Input model setup
; ---------------------------------------------------------------------------
setup_input_model:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    lea rdi, [rel input_registry]
    lea rsi, [rel input_records]
    mov edx, INPUT_CAP
    mov rcx, 0x0000000100000000
    call nebo_input_registry_init
    test eax, eax
    jnz .model_done
    lea rdi, [rel pending_registry]
    lea rsi, [rel pending_records]
    mov edx, INPUT_CAP
    mov rcx, 0x0000000100000000
    call nebo_pending_registry_init
    test eax, eax
    jnz .model_done
    xor ebx, ebx
.model_record_loop:
    cmp ebx, INPUT_CAP
    jae .model_layout
    mov eax, ebx
    shl rax, 7
    lea r12, [rel input_records]
    add r12, rax
    mov dword [r12+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    mov eax, ebx
    mov edx, 1
    shl rdx, 32
    or rax, rdx
    mov [r12+NEBO_INPUT_RECORD_HANDLE_OFFSET], rax
    mov qword [r12+NEBO_INPUT_RECORD_NODE_ID_OFFSET], 101
    add [r12+NEBO_INPUT_RECORD_NODE_ID_OFFSET], rbx
    mov [r12+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], rax
    mov rdx, 1001
    add rdx, rbx
    mov [r12+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], rdx
    mov rdx, 201
    add rdx, rbx
    mov [r12+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], rdx
    mov rdx, 0x0000000100000000
    mov [r12+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], rdx
    mov dword [r12+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_REQUIRED_FLAGS
    mov rdx, rbx
    inc rdx
    mov [r12+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET], rdx
    mov rax, rbx
    imul rax, NEBO_PENDING_RECORD_SIZE
    lea r13, [rel pending_records]
    add r13, rax
    mov dword [r13+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    mov eax, ebx
    mov edx, 1
    shl rdx, 32
    or rax, rdx
    mov [r13+NEBO_PENDING_RECORD_HANDLE_OFFSET], rax
    mov [r13+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], rax
    mov rdx, 1001
    add rdx, rbx
    mov [r13+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], rdx
    mov rdx, 201
    add rdx, rbx
    mov [r13+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], rdx
    mov rdx, 0x0000000100000000
    mov [r13+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], rdx
    mov qword [r13+NEBO_PENDING_RECORD_TYPE_TAG_OFFSET], NEBO_PENDING_TYPE_TEXT
    mov qword [r13+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_REQUIRED_FLAGS
    inc ebx
    jmp .model_record_loop
.model_layout:
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], INPUT_CAP
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET], INPUT_CAP
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], INPUT_CAP
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET], INPUT_CAP
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .model_done
    lea rdi, [rel layout]
    lea rsi, [rel layout_boxes]
    mov edx, LAYOUT_CAP
    mov ecx, TEST_WIDTH*NEBO_LAYOUT_ONE
    mov r8, TEST_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .model_done
    lea r12, [rel layout_boxes]
    mov qword [r12+NEBO_LAYOUT_BOX_ID_OFFSET], 1
    mov dword [r12+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    mov dword [r12+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_LIVE
    mov qword [r12+NEBO_LAYOUT_BOX_NODE_ID_OFFSET], 101
    mov qword [r12+NEBO_LAYOUT_BOX_X_OFFSET], 20*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_Y_OFFSET], 60*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_WIDTH_OFFSET], 160*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_HEIGHT_OFFSET], 24*NEBO_LAYOUT_ONE
    lea r12, [rel layout_boxes+NEBO_LAYOUT_BOX_SIZE]
    mov qword [r12+NEBO_LAYOUT_BOX_ID_OFFSET], 2
    mov dword [r12+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    mov dword [r12+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_LIVE
    mov qword [r12+NEBO_LAYOUT_BOX_NODE_ID_OFFSET], 102
    mov qword [r12+NEBO_LAYOUT_BOX_X_OFFSET], 20*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_Y_OFFSET], 100*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_WIDTH_OFFSET], 160*NEBO_LAYOUT_ONE
    mov qword [r12+NEBO_LAYOUT_BOX_HEIGHT_OFFSET], 24*NEBO_LAYOUT_ONE
    mov qword [rel layout+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 2
    lea rax, [rel editors]
    mov [rel focus_storage+NEBO_FOCUS_STORAGE_EDITORS_PTR_OFFSET], rax
    mov qword [rel focus_storage+NEBO_FOCUS_STORAGE_EDITOR_CAPACITY_OFFSET], INPUT_CAP
    lea rax, [rel text_buffers]
    mov [rel focus_storage+NEBO_FOCUS_STORAGE_TEXT_PTR_OFFSET], rax
    mov qword [rel focus_storage+NEBO_FOCUS_STORAGE_TEXT_STRIDE_OFFSET], INPUT_TEXT_STRIDE
    lea rdi, [rel focus_manager]
    lea rsi, [rel input_registry]
    lea rdx, [rel layout]
    lea rcx, [rel focus_storage]
    call nebo_focus_manager_init
    test eax, eax
    jnz .model_done
    lea rdi, [rel focus_manager]
    call nebo_focus_manager_sync
    test eax, eax
    jnz .model_done
    lea rdi, [rel dependency_bridge]
    lea rsi, [rel continuations]
    mov edx, CONTINUATION_CAP
    mov rcx, 0x0000000100000000
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .model_done
    lea rax, [rel submission_values]
    mov [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET], rax
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET], INPUT_TEXT_STRIDE
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET], INPUT_CAP
    lea rdi, [rel submission_context]
    lea rsi, [rel input_registry]
    lea rdx, [rel pending_registry]
    lea rcx, [rel focus_manager]
    lea r8, [rel dependency_bridge]
    lea r9, [rel submission_storage]
    call nebo_input_submission_init
.model_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; ---------------------------------------------------------------------------
; Live X11 setup and event transport
; ---------------------------------------------------------------------------
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
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    lea rsi, [rel x11_config]
    call nebo_x11_adapter_init
    test eax, eax
    jnz .live_fail
    cmp byte [rel adapter+NEBO_X11_ADAPTER_KEYMAP_READY_OFFSET], 1
    jne .live_fail
    lea rdi, [rel adapter]
    lea rsi, [rel report]
    call nebo_x11_adapter_report
    test eax, eax
    jnz .live_fail
    mov rax, [rel report+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET]
    and rax, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    cmp rax, NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES
    jne .live_fail
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
    jnz .live_fail
    mov edi, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    call wait_for_native_kind
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

wait_for_native_kind:
    push r12
    push r13
    mov r12d, edi
    mov r13d, 80
.native_wait:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .native_next
    test eax, eax
    jnz .native_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], r12d
    je .native_ok
.native_next:
    dec r13d
    jnz .native_wait
.native_fail:
    mov eax, -1
    jmp .native_done
.native_ok:
    xor eax, eax
.native_done:
    pop r13
    pop r12
    ret

; EDI expected kind, RSI optional submission result.
poll_dispatch_expected:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12d, edi
    mov r13, rsi
    mov r14d, 80
.dispatch_wait:
    lea rdi, [rel adapter]
    lea rsi, [rel window]
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .dispatch_next
    test eax, eax
    jnz .dispatch_fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], r12d
    jne .dispatch_next
    lea rdi, [rel native_bridge]
    lea rsi, [rel normalized_event]
    mov rdx, r13
    call nebo_native_input_bridge_dispatch
    test eax, eax
    jnz .dispatch_fail
    xor eax, eax
    jmp .dispatch_done
.dispatch_next:
    dec r14d
    jnz .dispatch_wait
.dispatch_fail:
    mov eax, -1
.dispatch_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Find a keycode dynamically from the server mapping.
; EDI=keysym -> EAX=keycode, EDX=state required (zero/Shift).
find_keycode_for_keysym:
    movzx ecx, byte [rel adapter+NEBO_X11_ADAPTER_MIN_KEYCODE_OFFSET]
    movzx r8d, byte [rel adapter+NEBO_X11_ADAPTER_MAX_KEYCODE_OFFSET]
.key_find_loop:
    cmp ecx, r8d
    ja .key_not_found
    mov eax, ecx
    shl rax, 3
    lea r9, [rel adapter+NEBO_X11_ADAPTER_KEYMAP_OFFSET]
    add r9, rax
    cmp [r9+NEBO_X11_KEYMAP_ENTRY_UNSHIFTED_OFFSET], edi
    je .key_unshifted
    cmp [r9+NEBO_X11_KEYMAP_ENTRY_SHIFTED_OFFSET], edi
    je .key_shifted
    inc ecx
    jmp .key_find_loop
.key_unshifted:
    mov eax, ecx
    xor edx, edx
    ret
.key_shifted:
    mov eax, ecx
    mov edx, NEBO_X11_STATE_SHIFT
    ret
.key_not_found:
    xor eax, eax
    xor edx, edx
    ret

; Build and send one SendEvent request. The 32-byte event starts at +12.
send_request:
    push r12
    mov r12, rsi
    mov r8, rdx
.send_write_loop:
    mov eax, NEBO_LINUX_SYS_WRITE
    mov rdi, [rel adapter+NEBO_X11_ADAPTER_FD_OFFSET]
    mov rsi, r12
    mov rdx, r8
    syscall
    test rax, rax
    jle .send_fail
    add r12, rax
    sub r8, rax
    jnz .send_write_loop
    inc qword [rel adapter+NEBO_X11_ADAPTER_PROTOCOL_SEQUENCE_OFFSET]
    xor eax, eax
    jmp .send_done
.send_fail:
    mov eax, -1
.send_done:
    pop r12
    ret

prepare_send_event:
    lea rdi, [rel send_buffer]
    xor eax, eax
    mov ecx, 8
    cld
    rep stosq
    mov byte [rel send_buffer], NEBO_X11_OP_SEND_EVENT
    mov word [rel send_buffer+2], 11
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel send_buffer+4], eax
    mov dword [rel send_buffer+8], 0
    ret

; EDI FocusIn/FocusOut.
send_focus_event:
    push r12
    mov r12d, edi
    call prepare_send_event
    or r12b, NEBO_X11_EVENT_SEND_EVENT_MASK
    mov [rel send_buffer+12], r12b
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel send_buffer+16], eax
    lea rsi, [rel send_buffer]
    mov edx, 44
    call send_request
    pop r12
    ret

; EDI type, ESI=x pixels, EDX=y pixels, ECX=button (zero for motion).
send_pointer_event:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12d, edi
    mov r13d, esi
    mov r14d, edx
    mov ebx, ecx
    call prepare_send_event
    or r12b, NEBO_X11_EVENT_SEND_EVENT_MASK
    mov [rel send_buffer+12], r12b
    mov [rel send_buffer+13], bl
    mov eax, [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [rel send_buffer+20], eax
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel send_buffer+24], eax
    mov [rel send_buffer+32], r13w
    mov [rel send_buffer+34], r14w
    mov [rel send_buffer+36], r13w
    mov [rel send_buffer+38], r14w
    mov word [rel send_buffer+40], 0
    mov byte [rel send_buffer+42], 1
    lea rsi, [rel send_buffer]
    mov edx, 44
    call send_request
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI type, ESI=keycode, ECX=X11 state.
send_key_event:
    push rbx
    push r12
    push r13
    sub rsp, 8
    mov r12d, edi
    mov r13d, esi
    mov ebx, ecx
    call prepare_send_event
    or r12b, NEBO_X11_EVENT_SEND_EVENT_MASK
    mov [rel send_buffer+12], r12b
    mov [rel send_buffer+13], r13b
    mov eax, [rel adapter+NEBO_X11_ADAPTER_ROOT_WINDOW_OFFSET]
    mov [rel send_buffer+20], eax
    mov eax, [rel window+NEBO_X11_WINDOW_XID_OFFSET]
    mov [rel send_buffer+24], eax
    mov word [rel send_buffer+40], bx
    mov byte [rel send_buffer+42], 1
    lea rsi, [rel send_buffer]
    mov edx, 44
    call send_request
    add rsp, 8
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
    jnz .destroy_done
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
.destroy_done:
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

section .note.GNU-stack noalloc noexec nowrite progbits
