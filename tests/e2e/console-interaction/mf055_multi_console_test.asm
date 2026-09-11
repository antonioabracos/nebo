; Nebo Assembly — MF055 multi-Console scan independence and native visual E2E
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/routing/scan_routing.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/render/output_conformance.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/console/renderer-registry/renderer_registry.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"
%include "runtime/console/platform/input/native_input_bridge.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_protocol.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_named_create
extern nebo_console_domain_from_handle
extern nebo_console_document_append_text
extern nebo_input_runtime_init
extern nebo_input_runtime_registry_for_console
extern nebo_console_scan_route
extern nebo_input_registry_get
extern nebo_pending_registry_get
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_console_behavior_store_init
extern nebo_console_renderer_registry_init
extern nebo_console_render_tree_init
extern nebo_console_render_tree_build
extern nebo_console_output_apply_styles
extern nebo_draw_command_buffer_init
extern nebo_console_draw_commands_build
extern nebo_console_output_append_chrome_controls
extern nebo_software_surface_init
extern nebo_software_surface_execute
extern nebo_software_surface_state_hash
extern nebo_focus_manager_init
extern nebo_focus_manager_sync
extern nebo_focus_manager_focus_handle
extern nebo_dependency_bridge_init
extern nebo_input_submission_init
extern nebo_native_input_bridge_init
extern nebo_native_input_bridge_dispatch
extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_report
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern mf055_append_input_visuals
extern mf055_overlay_document_glyphs
extern mf055_overlay_editor_glyphs
extern mf055_write_ppm
extern neboc_host_process_exit

global _start

%define TEST_CONSOLE_CAPACITY 4
%define TEST_QUEUE_CAPACITY 8
%define TEST_NODE_CAPACITY 64
%define TEST_TEXT_CAPACITY 2048
%define TEST_INPUT_CAPACITY 8
%define TEST_BOX_CAPACITY 96
%define TEST_RENDER_CAPACITY 96
%define TEST_COMMAND_CAPACITY 256
%define TEST_BEHAVIOR_CAPACITY 8
%define TEST_RENDERER_CAPACITY 8
%define TEST_INPUT_TEXT_STRIDE 64
%define TEST_CONTINUATION_CAPACITY 8
%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_SURFACE_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_SCRATCH_BYTES 65536
%define TEST_REQUIRED_CAPABILITIES NEBO_PLATFORM_MF053_REQUIRED_CAPABILITIES

; Generic per-Console visual/input model descriptor.
%define MODEL_HANDLE 0
%define MODEL_DOCUMENT 8
%define MODEL_INPUT_REGISTRY 16
%define MODEL_PENDING_REGISTRY 24
%define MODEL_PROVIDER 32
%define MODEL_LAYOUT 40
%define MODEL_BOXES 48
%define MODEL_RENDER_TREE 56
%define MODEL_RENDER_NODES 64
%define MODEL_BEHAVIOR_STORE 72
%define MODEL_BEHAVIOR_SETS 80
%define MODEL_RENDERER_REGISTRY 88
%define MODEL_RENDERER_ENTRIES 96
%define MODEL_DRAW_BUFFER 104
%define MODEL_DRAW_COMMANDS 112
%define MODEL_SURFACE 120
%define MODEL_SURFACE_PIXELS 128
%define MODEL_FOCUS_STORAGE 136
%define MODEL_FOCUS_MANAGER 144
%define MODEL_EDITORS 152
%define MODEL_TEXT_BUFFERS 160
%define MODEL_DEPENDENCY_BRIDGE 168
%define MODEL_CONTINUATIONS 176
%define MODEL_SUBMISSION_STORAGE 184
%define MODEL_SUBMISSION_VALUES 192
%define MODEL_SUBMISSION_CONTEXT 200
%define MODEL_SUBMISSION_RESULT 208
%define MODEL_NATIVE_BRIDGE 216
%define MODEL_WINDOW 224
%define MODEL_SURFACE_HASH 232
%define MODEL_SIZE 240
%define MODEL_QWORDS 30

section .rodata align=8
name_musica_bytes: db 109,117,115,105,99,97
name_musica:
    dq name_musica_bytes,6
             dd 0
             dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
name_programacao_bytes: db 112,114,111,103,114,97,109,97,99,97,111
name_programacao:
    dq name_programacao_bytes,11
                  dd 0
                  dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
name_a_bytes: db 97
name_a:
    dq name_a_bytes,1
        dd 0
        dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
name_b_bytes: db 98
name_b:
    dq name_b_bytes,1
        dd 0
        dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_m_bytes: db 77,58,32
prompt_m:
    dq prompt_m_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_p_bytes: db 80,58,32
prompt_p:
    dq prompt_p_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_a_bytes: db 65,58,32
prompt_a:
    dq prompt_a_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_b_bytes: db 66,58,32
prompt_b:
    dq prompt_b_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
prompt_n_bytes: db 78,58,32
prompt_n:
    dq prompt_n_bytes,3
          dd 0
          dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
text_som: db 115,111,109
text_codigo: db 99,111,100,105,103,111
text_um: db 117,109
text_dois: db 100,111,105,115
text_a: db 97
text_b: db 98
text_c: db 99
text_n: db 110,101,98,111
auth_name: db 77,73,84,45,77,65,71,73,67,45,67,79,79,75,73,69,45,49
%define AUTH_NAME_LENGTH 18

section .bss align=64
; Runtime + scan routing storage.
context: resb NEBO_CONSOLE_CONTEXT_SIZE
slots: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_SLOT_SIZE
clock: resb NEBO_FAKE_CLOCK_SIZE
fake_platform: resb NEBO_FAKE_PLATFORM_SIZE
scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers: resb TEST_CONSOLE_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers: resb TEST_CONSOLE_CAPACITY*TEST_QUEUE_CAPACITY*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
documents: resb TEST_CONSOLE_CAPACITY*NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_CONSOLE_CAPACITY*TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_CONSOLE_CAPACITY*TEST_TEXT_CAPACITY
headless_storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
input_runtime: resb NEBO_INPUT_RUNTIME_SIZE
input_storage: resb NEBO_INPUT_RUNTIME_STORAGE_SIZE
input_registries: resb TEST_CONSOLE_CAPACITY*NEBO_INPUT_REGISTRY_SIZE
input_records: resb TEST_CONSOLE_CAPACITY*TEST_INPUT_CAPACITY*NEBO_INPUT_RECORD_SIZE
pending_registries: resb TEST_CONSOLE_CAPACITY*NEBO_PENDING_REGISTRY_SIZE
pending_records: resb TEST_CONSOLE_CAPACITY*TEST_INPUT_CAPACITY*NEBO_PENDING_RECORD_SIZE
route_a: resb NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
route_b: resb NEBO_SCAN_ROUTE_DESCRIPTOR_SIZE
record_ptr_a: resq 1
record_ptr_b: resq 1
pending_ptr_a: resq 1
pending_ptr_b: resq 1
domain_ptr: resq 1
handle_a: resq 1
handle_b: resq 1

; Model A storage.
model_a: resb MODEL_SIZE
provider_a: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout_a: resb NEBO_LAYOUT_TREE_SIZE
boxes_a: resb TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
render_tree_a: resb NEBO_RENDER_TREE_SIZE
render_nodes_a: resb TEST_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE
behavior_store_a: resb NEBO_BEHAVIOR_STORE_SIZE
behavior_sets_a: resb TEST_BEHAVIOR_CAPACITY*NEBO_BEHAVIOR_SET_SIZE
renderer_registry_a: resb NEBO_RENDERER_REGISTRY_SIZE
renderer_entries_a: resb TEST_RENDERER_CAPACITY*NEBO_RENDERER_ENTRY_SIZE
draw_buffer_a: resb NEBO_DRAW_BUFFER_SIZE
draw_commands_a: resb TEST_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE
surface_a: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels_a: resb TEST_SURFACE_BYTES
focus_storage_a: resb NEBO_FOCUS_STORAGE_SIZE
focus_manager_a: resb NEBO_FOCUS_MANAGER_SIZE
editors_a: resb TEST_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE
editor_text_a: resb TEST_INPUT_CAPACITY*TEST_INPUT_TEXT_STRIDE
dependency_bridge_a: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations_a: resb TEST_CONTINUATION_CAPACITY*NEBO_DEPENDENCY_CONTINUATION_SIZE
submission_storage_a: resb NEBO_SUBMISSION_STORAGE_SIZE
submission_values_a: resb TEST_INPUT_CAPACITY*TEST_INPUT_TEXT_STRIDE
submission_context_a: resb NEBO_SUBMISSION_CONTEXT_SIZE
submission_result_a: resb NEBO_SUBMISSION_RESULT_SIZE
native_bridge_a: resb NEBO_NATIVE_INPUT_BRIDGE_SIZE
window_a: resb NEBO_X11_WINDOW_SIZE
surface_hash_a: resq 1

; Model B storage.
model_b: resb MODEL_SIZE
provider_b: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout_b: resb NEBO_LAYOUT_TREE_SIZE
boxes_b: resb TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
render_tree_b: resb NEBO_RENDER_TREE_SIZE
render_nodes_b: resb TEST_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE
behavior_store_b: resb NEBO_BEHAVIOR_STORE_SIZE
behavior_sets_b: resb TEST_BEHAVIOR_CAPACITY*NEBO_BEHAVIOR_SET_SIZE
renderer_registry_b: resb NEBO_RENDERER_REGISTRY_SIZE
renderer_entries_b: resb TEST_RENDERER_CAPACITY*NEBO_RENDERER_ENTRY_SIZE
draw_buffer_b: resb NEBO_DRAW_BUFFER_SIZE
draw_commands_b: resb TEST_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE
surface_b: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels_b: resb TEST_SURFACE_BYTES
focus_storage_b: resb NEBO_FOCUS_STORAGE_SIZE
focus_manager_b: resb NEBO_FOCUS_MANAGER_SIZE
editors_b: resb TEST_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE
editor_text_b: resb TEST_INPUT_CAPACITY*TEST_INPUT_TEXT_STRIDE
dependency_bridge_b: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations_b: resb TEST_CONTINUATION_CAPACITY*NEBO_DEPENDENCY_CONTINUATION_SIZE
submission_storage_b: resb NEBO_SUBMISSION_STORAGE_SIZE
submission_values_b: resb TEST_INPUT_CAPACITY*TEST_INPUT_TEXT_STRIDE
submission_context_b: resb NEBO_SUBMISSION_CONTEXT_SIZE
submission_result_b: resb NEBO_SUBMISSION_RESULT_SIZE
native_bridge_b: resb NEBO_NATIVE_INPUT_BRIDGE_SIZE
window_b: resb NEBO_X11_WINDOW_SIZE
surface_hash_b: resq 1

; Native adapter state.
report: resb NEBO_PLATFORM_REPORT_SIZE
adapter: resb NEBO_X11_ADAPTER_SIZE
normalized_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
manual_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
x11_config: resb NEBO_X11_CONFIG_SIZE
window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
auth_cookie_length: resq 1
scratch: resb TEST_SCRATCH_BYTES
socket_arg: resq 1
cookie_arg: resq 1
output_path_a: resq 1
output_path_b: resq 1
fail_code: resd 1

section .text
_start:
    cmp qword [rsp], 5
    jb test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_usage
    cmp eax, 7
    ja test_usage
    mov r12d, eax
    mov rax, [rsp+24]
    mov [rel socket_arg], rax
    mov rax, [rsp+32]
    mov [rel cookie_arg], rax
    mov rax, [rsp+40]
    mov [rel output_path_a], rax
    cmp r12d, 1
    je .need_two
    cmp r12d, 2
    je .need_two
    cmp r12d, 7
    je .need_two
    jmp .argc_ready
.need_two:
    cmp qword [rsp], 6
    jne test_usage
    mov rax, [rsp+48]
    mov [rel output_path_b], rax
.argc_ready:
    call init_model_descriptors
    call setup_runtime
    test eax, eax
    jnz test_fail
    cmp r12d, 1
    je scenario_1
    cmp r12d, 2
    je scenario_2
    cmp r12d, 3
    je scenario_3
    cmp r12d, 4
    je scenario_4
    cmp r12d, 5
    je scenario_5
    cmp r12d, 6
    je scenario_6
    jmp scenario_7

; Named musica/programacao scans remain independent.
scenario_1:
    mov dword [rel fail_code], 101
    lea rdi, [rel name_musica]
    lea rsi, [rel handle_a]
    call create_named
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 102
    lea rdi, [rel name_programacao]
    lea rsi, [rel handle_b]
    call create_named
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 103
    mov rdi, [rel handle_a]
    lea rsi, [rel prompt_m]
    mov edx, 1101
    mov ecx, 2101
    mov r8d, 1
    lea r9, [rel route_a]
    call route_inline
    test eax, eax
    jz .scenario1_route_a_ok
    mov eax, [rel route_a+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET]
    add eax, 120
    mov [rel fail_code], eax
    jmp test_fail
.scenario1_route_a_ok:
    mov dword [rel fail_code], 104
    mov rdi, [rel handle_b]
    lea rsi, [rel prompt_p]
    mov edx, 1102
    mov ecx, 2102
    mov r8d, 2
    lea r9, [rel route_b]
    call route_inline
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 105
    call bind_models_from_handles
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 106
    lea rdi, [rel model_a]
    lea rsi, [rel text_som]
    mov edx, 3
    call dispatch_text
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 107
    lea rdi, [rel model_a]
    call dispatch_enter
    test eax, eax
    jnz test_fail
    cmp qword [rel submission_result_a+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], 1101
    jne test_fail
    mov dword [rel fail_code], 108
    lea rdi, [rel model_b]
    lea rsi, [rel text_codigo]
    mov edx, 6
    call dispatch_text
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 109
    lea rdi, [rel model_b]
    call dispatch_enter
    test eax, eax
    jnz test_fail
    cmp qword [rel submission_result_b+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], 1102
    jne test_fail
    mov dword [rel fail_code], 110
    call render_present_two
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 111
    call write_two
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; Two anonymous scan chains own different Console handles/windows.
scenario_2:
    lea rdi, [rel prompt_a]
    mov esi, 1201
    mov edx, 2201
    mov ecx, 1
    lea r8, [rel route_a]
    call route_anonymous
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_a], rax
    lea rdi, [rel prompt_b]
    mov esi, 1202
    mov edx, 2202
    mov ecx, 2
    lea r8, [rel route_b]
    call route_anonymous
    test eax, eax
    jnz test_fail
    mov rax, [rel route_b+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_b], rax
    cmp rax, [rel handle_a]
    je test_fail
    call bind_models_from_handles
    test eax, eax
    jnz test_fail
    lea rdi, [rel model_a]
    lea rsi, [rel text_a]
    mov edx, 1
    call dispatch_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel model_b]
    lea rsi, [rel text_b]
    mov edx, 1
    call dispatch_text
    test eax, eax
    jnz test_fail
    call render_present_two
    test eax, eax
    jnz test_fail_cleanup
    call write_two
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; One default scan remains functional through native visual output.
scenario_3:
    lea rdi, [rel prompt_n]
    mov esi, 1301
    mov edx, 2301
    mov ecx, 1
    lea r8, [rel route_a]
    call route_default
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_a], rax
    lea rdi, [rel model_a]
    mov rsi, rax
    call bind_model
    test eax, eax
    jnz test_fail
    lea rdi, [rel model_a]
    lea rsi, [rel text_n]
    mov edx, 4
    call dispatch_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel model_a]
    call dispatch_enter
    test eax, eax
    jnz test_fail
    cmp qword [rel submission_result_a+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET], 2301
    jne test_fail
    call render_present_one
    test eax, eax
    jnz test_fail_cleanup
    call write_one
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; Multiple default scans coexist active in one document/window.
scenario_4:
    lea rdi, [rel prompt_a]
    mov esi, 1401
    mov edx, 2401
    mov ecx, 1
    lea r8, [rel route_a]
    call route_default
    test eax, eax
    jnz test_fail
    lea rdi, [rel prompt_b]
    mov esi, 1402
    mov edx, 2402
    mov ecx, 2
    lea r8, [rel route_b]
    call route_default
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    cmp rax, [rel route_b+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    jne test_fail
    mov [rel handle_a], rax
    lea rdi, [rel model_a]
    mov rsi, rax
    call bind_model
    test eax, eax
    jnz test_fail
    mov rax, [rel model_a+MODEL_INPUT_REGISTRY]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 2
    jne test_fail
    mov rax, [rel model_a+MODEL_PENDING_REGISTRY]
    cmp qword [rax+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 2
    jne test_fail
    call render_present_one
    test eax, eax
    jnz test_fail_cleanup
    call write_one
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; Resolve the second default input first; first Binding/Pending remains pending.
scenario_5:
    mov dword [rel fail_code], 151
    lea rdi, [rel prompt_a]
    mov esi, 1501
    mov edx, 2501
    mov ecx, 1
    lea r8, [rel route_a]
    call route_default
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 152
    lea rdi, [rel prompt_b]
    mov esi, 1502
    mov edx, 2502
    mov ecx, 2
    lea r8, [rel route_b]
    call route_default
    test eax, eax
    jnz test_fail
    mov rax, [rel route_a+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov [rel handle_a], rax
    mov dword [rel fail_code], 153
    lea rdi, [rel model_a]
    mov rsi, rax
    call bind_model
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 154
    lea rdi, [rel model_a]
    mov rsi, [rel route_b+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    call focus_handle
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 155
    lea rdi, [rel model_a]
    lea rsi, [rel text_dois]
    mov edx, 4
    call dispatch_text
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 156
    lea rdi, [rel model_a]
    call dispatch_enter
    test eax, eax
    jnz test_fail
    cmp qword [rel submission_result_a+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], 1502
    jne test_fail
    cmp qword [rel submission_result_a+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET], 2502
    jne test_fail
    mov dword [rel fail_code], 157
    mov rdi, [rel model_a+MODEL_INPUT_REGISTRY]
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    lea rdx, [rel record_ptr_a]
    call nebo_input_registry_get
    test eax, eax
    jnz test_fail
    mov rax, [rel record_ptr_a]
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne test_fail
    mov dword [rel fail_code], 158
    ; registry_get intentionally exposes only PENDING handles; inspect the immutable resolved slot directly.
    mov rax, [rel route_b+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    mov eax, eax
    shl rax, 7
    mov rdx, [rel model_a+MODEL_INPUT_REGISTRY]
    add rax, [rdx+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    mov [rel record_ptr_b], rax
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    jne test_fail
    cmp qword [rax+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], 1502
    jne test_fail
    cmp qword [rax+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], 2502
    jne test_fail
    mov dword [rel fail_code], 159
    mov rdi, [rel model_a+MODEL_PENDING_REGISTRY]
    mov rsi, [rel route_a+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    lea rdx, [rel pending_ptr_a]
    call nebo_pending_registry_get
    test eax, eax
    jnz test_fail
    mov rax, [rel pending_ptr_a]
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne test_fail
    mov dword [rel fail_code], 160
    call render_present_one
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 161
    call write_one
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; Closing one native window must not interrupt input/present on the other.
scenario_6:
    lea rdi, [rel name_a]
    lea rsi, [rel handle_a]
    call create_named
    test eax, eax
    jnz test_fail
    lea rdi, [rel name_b]
    lea rsi, [rel handle_b]
    call create_named
    test eax, eax
    jnz test_fail
    mov rdi, [rel handle_a]
    lea rsi, [rel prompt_a]
    mov edx, 1601
    mov ecx, 2601
    mov r8d, 1
    lea r9, [rel route_a]
    call route_inline
    test eax, eax
    jnz test_fail
    mov rdi, [rel handle_b]
    lea rsi, [rel prompt_b]
    mov edx, 1602
    mov ecx, 2602
    mov r8d, 2
    lea r9, [rel route_b]
    call route_inline
    test eax, eax
    jnz test_fail
    call bind_models_from_handles
    test eax, eax
    jnz test_fail
    call render_two
    test eax, eax
    jnz test_fail
    call live_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel model_a]
    call create_present_model
    test eax, eax
    jnz test_fail_cleanup
    lea rdi, [rel model_b]
    call create_present_model
    test eax, eax
    jnz test_fail_cleanup
    lea rdi, [rel model_a]
    call destroy_model_window
    test eax, eax
    jnz test_fail_cleanup
    cmp qword [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 1
    jne test_fail_cleanup
    lea rdi, [rel model_b]
    lea rsi, [rel text_um]
    mov edx, 2
    call dispatch_text
    test eax, eax
    jnz test_fail_cleanup
    lea rdi, [rel model_b]
    call dispatch_enter
    test eax, eax
    jnz test_fail_cleanup
    lea rdi, [rel model_b]
    call render_model
    test eax, eax
    jnz test_fail_cleanup
    lea rdi, [rel model_b]
    call present_model
    test eax, eax
    jnz test_fail_cleanup
    cmp qword [rel window_b+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET], 2
    jb test_fail_cleanup
    call write_one_b_as_a
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; Interleaved progress on two Consoles proves neither blocks the other.
scenario_7:
    lea rdi, [rel name_a]
    lea rsi, [rel handle_a]
    call create_named
    test eax, eax
    jnz test_fail
    lea rdi, [rel name_b]
    lea rsi, [rel handle_b]
    call create_named
    test eax, eax
    jnz test_fail
    mov rdi, [rel handle_a]
    lea rsi, [rel prompt_a]
    mov edx, 1701
    mov ecx, 2701
    mov r8d, 1
    lea r9, [rel route_a]
    call route_inline
    test eax, eax
    jnz test_fail
    mov rdi, [rel handle_b]
    lea rsi, [rel prompt_b]
    mov edx, 1702
    mov ecx, 2702
    mov r8d, 2
    lea r9, [rel route_b]
    call route_inline
    test eax, eax
    jnz test_fail
    call bind_models_from_handles
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 170
    call render_present_two
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 171
    lea rdi, [rel model_a]
    lea rsi, [rel text_a]
    mov edx, 1
    call dispatch_text
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 172
    lea rdi, [rel model_b]
    lea rsi, [rel text_b]
    mov edx, 1
    call dispatch_text
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 173
    lea rdi, [rel model_a]
    lea rsi, [rel text_c]
    mov edx, 1
    call dispatch_text
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 174
    lea rdi, [rel model_b]
    lea rsi, [rel text_um]
    mov edx, 2
    call dispatch_text
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 175
    lea rdi, [rel model_b]
    call dispatch_enter
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 176
    lea rdi, [rel model_a]
    call dispatch_enter
    test eax, eax
    jz .scenario7_enter_a_ok
    add eax, 200
    mov [rel fail_code], eax
    jmp test_fail_cleanup
.scenario7_enter_a_ok:
    cmp qword [rel native_bridge_a+NEBO_NATIVE_INPUT_BRIDGE_TEXT_COUNT_OFFSET], 2
    jne test_fail_cleanup
    cmp qword [rel native_bridge_b+NEBO_NATIVE_INPUT_BRIDGE_TEXT_COUNT_OFFSET], 3
    jne test_fail_cleanup
    cmp qword [rel native_bridge_a+NEBO_NATIVE_INPUT_BRIDGE_ENTER_COUNT_OFFSET], 1
    jne test_fail_cleanup
    cmp qword [rel native_bridge_b+NEBO_NATIVE_INPUT_BRIDGE_ENTER_COUNT_OFFSET], 1
    jne test_fail_cleanup
    mov dword [rel fail_code], 177
    call render_two
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 178
    lea rdi, [rel model_a]
    call present_model
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 179
    lea rdi, [rel model_b]
    call present_model
    test eax, eax
    jnz test_fail_cleanup
    mov dword [rel fail_code], 180
    call write_two
    test eax, eax
    jnz test_fail_cleanup
    jmp test_pass_cleanup

; ---------------------------------------------------------------------------
; Runtime/routing/model helpers
; ---------------------------------------------------------------------------
init_model_descriptors:
    lea rdi, [rel model_a]
    xor eax, eax
    mov ecx, MODEL_QWORDS
    cld
    rep stosq
    lea rdi, [rel model_b]
    mov ecx, MODEL_QWORDS
    rep stosq
    lea rax, [rel provider_a]
    mov [rel model_a+MODEL_PROVIDER], rax
    lea rax, [rel layout_a]
    mov [rel model_a+MODEL_LAYOUT], rax
    lea rax, [rel boxes_a]
    mov [rel model_a+MODEL_BOXES], rax
    lea rax, [rel render_tree_a]
    mov [rel model_a+MODEL_RENDER_TREE], rax
    lea rax, [rel render_nodes_a]
    mov [rel model_a+MODEL_RENDER_NODES], rax
    lea rax, [rel behavior_store_a]
    mov [rel model_a+MODEL_BEHAVIOR_STORE], rax
    lea rax, [rel behavior_sets_a]
    mov [rel model_a+MODEL_BEHAVIOR_SETS], rax
    lea rax, [rel renderer_registry_a]
    mov [rel model_a+MODEL_RENDERER_REGISTRY], rax
    lea rax, [rel renderer_entries_a]
    mov [rel model_a+MODEL_RENDERER_ENTRIES], rax
    lea rax, [rel draw_buffer_a]
    mov [rel model_a+MODEL_DRAW_BUFFER], rax
    lea rax, [rel draw_commands_a]
    mov [rel model_a+MODEL_DRAW_COMMANDS], rax
    lea rax, [rel surface_a]
    mov [rel model_a+MODEL_SURFACE], rax
    lea rax, [rel surface_pixels_a]
    mov [rel model_a+MODEL_SURFACE_PIXELS], rax
    lea rax, [rel focus_storage_a]
    mov [rel model_a+MODEL_FOCUS_STORAGE], rax
    lea rax, [rel focus_manager_a]
    mov [rel model_a+MODEL_FOCUS_MANAGER], rax
    lea rax, [rel editors_a]
    mov [rel model_a+MODEL_EDITORS], rax
    lea rax, [rel editor_text_a]
    mov [rel model_a+MODEL_TEXT_BUFFERS], rax
    lea rax, [rel dependency_bridge_a]
    mov [rel model_a+MODEL_DEPENDENCY_BRIDGE], rax
    lea rax, [rel continuations_a]
    mov [rel model_a+MODEL_CONTINUATIONS], rax
    lea rax, [rel submission_storage_a]
    mov [rel model_a+MODEL_SUBMISSION_STORAGE], rax
    lea rax, [rel submission_values_a]
    mov [rel model_a+MODEL_SUBMISSION_VALUES], rax
    lea rax, [rel submission_context_a]
    mov [rel model_a+MODEL_SUBMISSION_CONTEXT], rax
    lea rax, [rel submission_result_a]
    mov [rel model_a+MODEL_SUBMISSION_RESULT], rax
    lea rax, [rel native_bridge_a]
    mov [rel model_a+MODEL_NATIVE_BRIDGE], rax
    lea rax, [rel window_a]
    mov [rel model_a+MODEL_WINDOW], rax
    lea rax, [rel surface_hash_a]
    mov [rel model_a+MODEL_SURFACE_HASH], rax
    lea rax, [rel provider_b]
    mov [rel model_b+MODEL_PROVIDER], rax
    lea rax, [rel layout_b]
    mov [rel model_b+MODEL_LAYOUT], rax
    lea rax, [rel boxes_b]
    mov [rel model_b+MODEL_BOXES], rax
    lea rax, [rel render_tree_b]
    mov [rel model_b+MODEL_RENDER_TREE], rax
    lea rax, [rel render_nodes_b]
    mov [rel model_b+MODEL_RENDER_NODES], rax
    lea rax, [rel behavior_store_b]
    mov [rel model_b+MODEL_BEHAVIOR_STORE], rax
    lea rax, [rel behavior_sets_b]
    mov [rel model_b+MODEL_BEHAVIOR_SETS], rax
    lea rax, [rel renderer_registry_b]
    mov [rel model_b+MODEL_RENDERER_REGISTRY], rax
    lea rax, [rel renderer_entries_b]
    mov [rel model_b+MODEL_RENDERER_ENTRIES], rax
    lea rax, [rel draw_buffer_b]
    mov [rel model_b+MODEL_DRAW_BUFFER], rax
    lea rax, [rel draw_commands_b]
    mov [rel model_b+MODEL_DRAW_COMMANDS], rax
    lea rax, [rel surface_b]
    mov [rel model_b+MODEL_SURFACE], rax
    lea rax, [rel surface_pixels_b]
    mov [rel model_b+MODEL_SURFACE_PIXELS], rax
    lea rax, [rel focus_storage_b]
    mov [rel model_b+MODEL_FOCUS_STORAGE], rax
    lea rax, [rel focus_manager_b]
    mov [rel model_b+MODEL_FOCUS_MANAGER], rax
    lea rax, [rel editors_b]
    mov [rel model_b+MODEL_EDITORS], rax
    lea rax, [rel editor_text_b]
    mov [rel model_b+MODEL_TEXT_BUFFERS], rax
    lea rax, [rel dependency_bridge_b]
    mov [rel model_b+MODEL_DEPENDENCY_BRIDGE], rax
    lea rax, [rel continuations_b]
    mov [rel model_b+MODEL_CONTINUATIONS], rax
    lea rax, [rel submission_storage_b]
    mov [rel model_b+MODEL_SUBMISSION_STORAGE], rax
    lea rax, [rel submission_values_b]
    mov [rel model_b+MODEL_SUBMISSION_VALUES], rax
    lea rax, [rel submission_context_b]
    mov [rel model_b+MODEL_SUBMISSION_CONTEXT], rax
    lea rax, [rel submission_result_b]
    mov [rel model_b+MODEL_SUBMISSION_RESULT], rax
    lea rax, [rel native_bridge_b]
    mov [rel model_b+MODEL_NATIVE_BRIDGE], rax
    lea rax, [rel window_b]
    mov [rel model_b+MODEL_WINDOW], rax
    lea rax, [rel surface_hash_b]
    mov [rel model_b+MODEL_SURFACE_HASH], rax
    ret

setup_runtime:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, TEST_CONSOLE_CAPACITY
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .done
    lea rax, [rel clock]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel fake_platform]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET], rax
    lea rax, [rel scheduler]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET], rax
    lea rax, [rel domains]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET], rax
    lea rax, [rel command_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET], rax
    lea rax, [rel event_buffers]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET], rax
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET], TEST_CONSOLE_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET], TEST_QUEUE_CAPACITY
    lea rax, [rel documents]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET], rax
    lea rax, [rel nodes]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET], rax
    lea rax, [rel text_store]
    mov [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET], rax
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET], TEST_NODE_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET], TEST_TEXT_CAPACITY
    mov qword [rel headless_storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
    lea rdi, [rel context]
    lea rsi, [rel headless_storage]
    call nebo_console_runtime_headless_bind
    test eax, eax
    jnz .done
    lea rax, [rel input_registries]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel input_records]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET], rax
    lea rax, [rel pending_registries]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET], rax
    lea rax, [rel pending_records]
    mov [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET], rax
    mov qword [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_CONSOLE_CAPACITY_OFFSET], TEST_CONSOLE_CAPACITY
    mov qword [rel input_storage+NEBO_INPUT_RUNTIME_STORAGE_INPUT_CAPACITY_OFFSET], TEST_INPUT_CAPACITY
    lea rdi, [rel input_runtime]
    lea rsi, [rel context]
    lea rdx, [rel input_storage]
    call nebo_input_runtime_init
.done:
    add rsp, 16
    pop rbx
    ret

create_named:
    push r12
    mov r12, rsi
    mov rsi, rdi
    lea rdi, [rel context]
    mov rdx, r12
    call nebo_console_manager_named_create
    pop r12
    ret

; RDI handle, RSI prompt, EDX binding, ECX pending, R8 source, R9 route*.
route_inline:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp], r9
    ; Console.scan is inline: append the prompt explicitly, then route with null prompt metadata.
    test r12, r12
    jz .prompt_ready
    lea rdi, [rel context]
    mov rsi, rbx
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .route_done
    mov rax, [rel domain_ptr]
    mov rdi, [rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    mov rsi, r12
    call nebo_console_document_append_text
    test eax, eax
    jnz .route_done
.prompt_ready:
    mov rdi, [rsp]
    mov esi, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    xor edx, edx
    mov rcx, r13
    mov r8, r14
    mov r9, r15
    call build_route
    mov rax, [rsp]
    mov [rax+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET], rbx
    lea rdi, [rel input_runtime]
    mov rsi, rax
    call nebo_console_scan_route
.route_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI prompt, ESI binding, EDX pending, ECX source, R8 route*.
route_anonymous:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx
    mov rbx, r8
    mov rdi, rbx
    mov esi, NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    mov rdx, r12
    mov ecx, r13d
    mov r8d, r14d
    mov r9d, r15d
    call build_route
    lea rdi, [rel input_runtime]
    mov rsi, rbx
    call nebo_console_scan_route
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI prompt, ESI binding, EDX pending, ECX source, R8 route*.
route_default:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13d, esi
    mov r14d, edx
    mov r15d, ecx
    mov rbx, r8
    mov rdi, rbx
    mov esi, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    mov rdx, r12
    mov ecx, r13d
    mov r8d, r14d
    mov r9d, r15d
    call build_route
    lea rdi, [rel input_runtime]
    mov rsi, rbx
    call nebo_console_scan_route
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

build_route:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12d, esi
    mov r13, rdx
    mov r14, rcx
    mov r15, r8
    mov [rsp], r9
    mov rdi, rbx
    xor eax, eax
    mov ecx, NEBO_SCAN_ROUTE_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov [rbx+NEBO_SCAN_ROUTE_KIND_OFFSET], r12d
    mov dword [rbx+NEBO_SCAN_ROUTE_FLAGS_OFFSET], NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    mov [rbx+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET], r13
    mov [rbx+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], r14
    mov [rbx+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], r15
    mov rax, [rsp]
    mov [rbx+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET], rax
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

bind_models_from_handles:
    lea rdi, [rel model_a]
    mov rsi, [rel handle_a]
    call bind_model
    test eax, eax
    jnz .done
    lea rdi, [rel model_b]
    mov rsi, [rel handle_b]
    call bind_model
.done:
    ret

; RDI=model*, RSI=ConsoleHandle.
bind_model:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov [r12+MODEL_HANDLE], r13
    lea rdi, [rel context]
    mov rsi, r13
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .done
    mov rax, [rel domain_ptr]
    mov rax, [rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    mov [r12+MODEL_DOCUMENT], rax
    lea rdi, [rel input_runtime]
    mov rsi, r13
    lea rdx, [rsp]
    lea rcx, [rsp+8]
    call nebo_input_runtime_registry_for_console
    test eax, eax
    jnz .done
    mov rax, [rsp]
    mov [r12+MODEL_INPUT_REGISTRY], rax
    mov rax, [rsp+8]
    mov [r12+MODEL_PENDING_REGISTRY], rax
    mov rdi, [r12+MODEL_PROVIDER]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .done
    mov rdi, [r12+MODEL_LAYOUT]
    mov rsi, [r12+MODEL_BOXES]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, TEST_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_HEIGHT*NEBO_LAYOUT_ONE
    mov r9, [r12+MODEL_PROVIDER]
    call nebo_console_layout_init
    test eax, eax
    jnz .done
    mov rdi, [r12+MODEL_LAYOUT]
    mov rsi, [r12+MODEL_DOCUMENT]
    call nebo_console_layout_document
    test eax, eax
    jnz .done
    mov rax, [r12+MODEL_EDITORS]
    mov rbx, [r12+MODEL_FOCUS_STORAGE]
    mov [rbx+NEBO_FOCUS_STORAGE_EDITORS_PTR_OFFSET], rax
    mov qword [rbx+NEBO_FOCUS_STORAGE_EDITOR_CAPACITY_OFFSET], TEST_INPUT_CAPACITY
    mov rax, [r12+MODEL_TEXT_BUFFERS]
    mov [rbx+NEBO_FOCUS_STORAGE_TEXT_PTR_OFFSET], rax
    mov qword [rbx+NEBO_FOCUS_STORAGE_TEXT_STRIDE_OFFSET], TEST_INPUT_TEXT_STRIDE
    mov rdi, [r12+MODEL_FOCUS_MANAGER]
    mov rsi, [r12+MODEL_INPUT_REGISTRY]
    mov rdx, [r12+MODEL_LAYOUT]
    mov rcx, [r12+MODEL_FOCUS_STORAGE]
    call nebo_focus_manager_init
    test eax, eax
    jnz .done
    mov rdi, [r12+MODEL_FOCUS_MANAGER]
    call nebo_focus_manager_sync
    test eax, eax
    jnz .done
    mov rdi, [r12+MODEL_DEPENDENCY_BRIDGE]
    mov rsi, [r12+MODEL_CONTINUATIONS]
    mov edx, TEST_CONTINUATION_CAPACITY
    mov rcx, r13
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .done
    mov rbx, [r12+MODEL_SUBMISSION_STORAGE]
    mov rax, [r12+MODEL_SUBMISSION_VALUES]
    mov [rbx+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET], rax
    mov qword [rbx+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET], TEST_INPUT_TEXT_STRIDE
    mov qword [rbx+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET], TEST_INPUT_CAPACITY
    mov rdi, [r12+MODEL_SUBMISSION_CONTEXT]
    mov rsi, [r12+MODEL_INPUT_REGISTRY]
    mov rdx, [r12+MODEL_PENDING_REGISTRY]
    mov rcx, [r12+MODEL_FOCUS_MANAGER]
    mov r8, [r12+MODEL_DEPENDENCY_BRIDGE]
    mov r9, [r12+MODEL_SUBMISSION_STORAGE]
    call nebo_input_submission_init
    test eax, eax
    jnz .done
    mov rdi, [r12+MODEL_NATIVE_BRIDGE]
    mov rsi, [r12+MODEL_FOCUS_MANAGER]
    mov rdx, [r12+MODEL_SUBMISSION_CONTEXT]
    mov ecx, NEBO_PLATFORM_SCALE_ONE
    call nebo_native_input_bridge_init
.done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

focus_handle:
    mov rax, [rdi+MODEL_FOCUS_MANAGER]
    mov rdi, rax
    jmp nebo_focus_manager_focus_handle

; RDI=model*, RSI=bytes*, EDX=len. Sends one-byte normalized Text events.
dispatch_text:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14d, edx
    xor ebx, ebx
.loop:
    cmp ebx, r14d
    jae .ok
    lea rdi, [rel manual_event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel manual_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TEXT_INPUT
    mov dword [rel manual_event+NEBO_CONSOLE_EVENT_FLAGS_OFFSET], NEBO_PLATFORM_EVENT_FLAG_SYNTHETIC
    movzx eax, byte [r13+rbx]
    mov [rel manual_event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], rax
    mov qword [rel manual_event+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET], 1
    mov rdi, [r12+MODEL_NATIVE_BRIDGE]
    lea rsi, [rel manual_event]
    xor edx, edx
    call nebo_native_input_bridge_dispatch
    test eax, eax
    jnz .done
    inc ebx
    jmp .loop
.ok:
    xor eax, eax
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI=model*.
dispatch_enter:
    push r12
    mov r12, rdi
    lea rdi, [rel manual_event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel manual_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_KEY_DOWN
    mov dword [rel manual_event+NEBO_CONSOLE_EVENT_FLAGS_OFFSET], NEBO_PLATFORM_EVENT_FLAG_SYNTHETIC
    mov qword [rel manual_event+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET], NEBO_PLATFORM_KEY_ENTER
    mov rdi, [r12+MODEL_NATIVE_BRIDGE]
    lea rsi, [rel manual_event]
    mov rdx, [r12+MODEL_SUBMISSION_RESULT]
    call nebo_native_input_bridge_dispatch
    pop r12
    ret

; Rebuild production document->surface for one model.
render_model:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov dword [rel fail_code], 130
    mov rdi, [r12+MODEL_LAYOUT]
    mov rsi, [r12+MODEL_DOCUMENT]
    call nebo_console_layout_document
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 131
    mov rdi, [r12+MODEL_FOCUS_MANAGER]
    call nebo_focus_manager_sync
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 133
    mov rdi, [r12+MODEL_RENDER_TREE]
    mov rsi, [r12+MODEL_RENDER_NODES]
    mov edx, TEST_RENDER_CAPACITY
    call nebo_console_render_tree_init
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 134
    mov rdi, [r12+MODEL_RENDER_TREE]
    mov rsi, [r12+MODEL_LAYOUT]
    mov rdx, [r12+MODEL_DOCUMENT]
    call nebo_console_render_tree_build
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 137
    mov rdi, [r12+MODEL_DRAW_BUFFER]
    mov rsi, [r12+MODEL_DRAW_COMMANDS]
    mov edx, TEST_COMMAND_CAPACITY
    mov rcx, [r12+MODEL_DOCUMENT]
    call nebo_draw_command_buffer_init
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 138
    mov rdi, [r12+MODEL_DRAW_BUFFER]
    mov rsi, [r12+MODEL_LAYOUT]
    mov rdx, [r12+MODEL_RENDER_TREE]
    call nebo_console_draw_commands_build
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 139
    mov rdi, [r12+MODEL_DRAW_BUFFER]
    mov rsi, [r12+MODEL_LAYOUT]
    call nebo_console_output_append_chrome_controls
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 140
    mov rdi, [r12+MODEL_DRAW_BUFFER]
    mov rsi, [r12+MODEL_LAYOUT]
    mov rdx, [r12+MODEL_INPUT_REGISTRY]
    mov rcx, [r12+MODEL_FOCUS_MANAGER]
    call mf055_append_input_visuals
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 141
    mov rdi, [r12+MODEL_SURFACE]
    mov rsi, [r12+MODEL_SURFACE_PIXELS]
    mov edx, TEST_SURFACE_BYTES
    mov ecx, TEST_WIDTH
    mov r8d, TEST_HEIGHT
    call nebo_software_surface_init
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 142
    mov rdi, [r12+MODEL_SURFACE]
    mov rsi, [r12+MODEL_DRAW_BUFFER]
    mov rdx, [r12+MODEL_PROVIDER]
    call nebo_software_surface_execute
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 143
    mov rdi, [r12+MODEL_SURFACE]
    mov rsi, [r12+MODEL_DRAW_BUFFER]
    call mf055_overlay_document_glyphs
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 144
    mov rdi, [r12+MODEL_SURFACE]
    mov rsi, [r12+MODEL_LAYOUT]
    mov rdx, [r12+MODEL_INPUT_REGISTRY]
    mov rcx, [r12+MODEL_FOCUS_MANAGER]
    call mf055_overlay_editor_glyphs
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 145
    mov rdi, [r12+MODEL_SURFACE]
    mov rsi, [r12+MODEL_SURFACE_HASH]
    call nebo_software_surface_state_hash
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

render_two:
    mov dword [rel fail_code], 120
    lea rdi, [rel model_a]
    call render_model
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 121
    lea rdi, [rel model_b]
    call render_model
.done:
    ret

render_present_one:
    lea rdi, [rel model_a]
    call render_model
    test eax, eax
    jnz .done
    call live_adapter_init
    test eax, eax
    jnz .done
    lea rdi, [rel model_a]
    call create_present_model
.done:
    ret

render_present_two:
    mov dword [rel fail_code], 112
    call render_two
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 113
    call live_adapter_init
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 114
    lea rdi, [rel model_a]
    call create_present_model
    test eax, eax
    jnz .done
    mov dword [rel fail_code], 115
    lea rdi, [rel model_b]
    call create_present_model
.done:
    ret

write_one:
    mov rdi, [rel model_a+MODEL_SURFACE]
    mov rsi, [rel output_path_a]
    jmp mf055_write_ppm

write_one_b_as_a:
    mov rdi, [rel model_b+MODEL_SURFACE]
    mov rsi, [rel output_path_a]
    jmp mf055_write_ppm

write_two:
    push r12
    mov rdi, [rel model_a+MODEL_SURFACE]
    mov rsi, [rel output_path_a]
    call mf055_write_ppm
    test eax, eax
    jnz .done
    mov rdi, [rel model_b+MODEL_SURFACE]
    mov rsi, [rel output_path_b]
    call mf055_write_ppm
.done:
    pop r12
    ret

; ---------------------------------------------------------------------------
; Direct X11 adapter helpers
; ---------------------------------------------------------------------------
live_adapter_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, [rel socket_arg]
    mov r13, [rel cookie_arg]
    lea rdi, [rel socket_address]
    mov word [rdi], NEBO_LINUX_AF_UNIX
    lea rdi, [rdi+2]
    mov rsi, r12
    xor ecx, ecx
.copy_socket:
    cmp ecx, 107
    jae .fail
    mov al, [rsi+rcx]
    mov [rdi+rcx], al
    test al, al
    jz .socket_ready
    inc ecx
    jmp .copy_socket
.socket_ready:
    lea r14, [rcx+3]
    mov rdi, r13
    lea rsi, [rel auth_cookie]
    mov edx, NEBO_X11_MAX_AUTH_BYTES
    lea rcx, [rel auth_cookie_length]
    call parse_hex
    test eax, eax
    jnz .fail
    lea rdi, [rel x11_config]
    lea rax, [rel socket_address]
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET], rax
    mov [rdi+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET], r14
    lea rax, [rel auth_name]
    mov [rdi+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET], AUTH_NAME_LENGTH
    lea rax, [rel auth_cookie]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET], rax
    mov rax, [rel auth_cookie_length]
    mov [rdi+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET], rax
    lea rax, [rel scratch]
    mov [rdi+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET], rax
    mov qword [rdi+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET], TEST_SCRATCH_BYTES
    mov qword [rdi+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET], TEST_REQUIRED_CAPABILITIES
    mov qword [rdi+NEBO_X11_CONFIG_FLAGS_OFFSET], NEBO_X11_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    lea rsi, [rel x11_config]
    call nebo_x11_adapter_init
    test eax, eax
    jnz .fail
    lea rdi, [rel adapter]
    lea rsi, [rel report]
    call nebo_x11_adapter_report
    test eax, eax
    jnz .fail
    mov rax, [rel report+NEBO_PLATFORM_REPORT_CAPABILITIES_OFFSET]
    and rax, TEST_REQUIRED_CAPABILITIES
    cmp rax, TEST_REQUIRED_CAPABILITIES
    jne .fail
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI=model*.
create_present_model:
    push r12
    mov r12, rdi
    lea rdi, [rel window_config]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    cld
    rep stosq
    mov rax, [r12+MODEL_SURFACE]
    mov [rel window_config+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET], rax
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rel window_config+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    mov rsi, [r12+MODEL_WINDOW]
    lea rdx, [rel window_config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jz .create_ok
    mov dword [rel fail_code], 181
    jmp .done
.create_ok:
    mov rdi, [r12+MODEL_WINDOW]
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    call wait_for_window_event
    test eax, eax
    jz .mounted_ok
    mov dword [rel fail_code], 182
    jmp .done
.mounted_ok:
    mov rdi, r12
    call present_model
    test eax, eax
    jz .done
    mov dword [rel fail_code], 183
.done:
    pop r12
    ret

present_model:
    push r12
    mov r12, rdi
    lea rdi, [rel adapter]
    mov rsi, [r12+MODEL_WINDOW]
    mov rdx, [r12+MODEL_SURFACE]
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_present
    pop r12
    ret

; RDI=model*.
destroy_model_window:
    push r12
    mov r12, rdi
    lea rdi, [rel adapter]
    mov rsi, [r12+MODEL_WINDOW]
    call nebo_x11_adapter_destroy_window
    pop r12
    ret

; RDI=window*, ESI expected kind.
wait_for_window_event:
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13d, esi
    mov r14d, 100
.loop:
    lea rdi, [rel adapter]
    mov rsi, r12
    mov edx, 100
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_poll_event
    cmp eax, NEBO_PLATFORM_STATUS_NO_EVENT
    je .next
    test eax, eax
    jnz .fail
    cmp dword [rel normalized_event+NEBO_CONSOLE_EVENT_KIND_OFFSET], r13d
    je .ok
.next:
    dec r14d
    jnz .loop
.fail:
    mov eax, -1
    jmp .done
.ok:
    xor eax, eax
.done:
    pop r14
    pop r13
    pop r12
    ret

cleanup_native:
    push r12
    cmp qword [rel window_b+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 0
    je .a
    lea rdi, [rel adapter]
    lea rsi, [rel window_b]
    call nebo_x11_adapter_destroy_window
.a:
    cmp qword [rel window_a+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET], 0
    je .shutdown
    lea rdi, [rel adapter]
    lea rsi, [rel window_a]
    call nebo_x11_adapter_destroy_window
.shutdown:
    cmp dword [rel adapter+NEBO_X11_ADAPTER_STATE_OFFSET], NEBO_PLATFORM_ADAPTER_STATE_READY
    jne .ok
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
.ok:
    xor eax, eax
    pop r12
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
    jz .invalid
    test r13, r13
    jz .invalid
    test r15, r15
    jz .invalid
    mov qword [r15], 0
    xor ebx, ebx
.loop:
    movzx edi, byte [r12]
    test dil, dil
    jz .done
    movzx esi, byte [r12+1]
    test sil, sil
    jz .invalid
    call hex_nibble
    test eax, eax
    js .invalid
    shl eax, 4
    mov r10d, eax
    mov edi, esi
    call hex_nibble
    test eax, eax
    js .invalid
    or eax, r10d
    cmp rbx, r14
    jae .invalid
    mov [r13+rbx], al
    inc rbx
    add r12, 2
    jmp .loop
.done:
    test rbx, rbx
    jz .invalid
    mov [r15], rbx
    xor eax, eax
    jmp .return
.invalid:
    mov eax, -1
.return:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hex_nibble:
    movzx eax, dil
    cmp al, '0'
    jb .bad
    cmp al, '9'
    jbe .decimal
    or al, 0x20
    cmp al, 'a'
    jb .bad
    cmp al, 'f'
    ja .bad
    sub al, 'a'-10
    movzx eax, al
    ret
.decimal:
    sub al, '0'
    movzx eax, al
    ret
.bad:
    mov eax, -1
    ret

test_pass_cleanup:
    call cleanup_native
    test eax, eax
    jnz test_fail
    jmp test_pass

test_fail_cleanup:
    call cleanup_native
    jmp test_fail

test_pass:
    xor edi, edi
    call neboc_host_process_exit
    ud2

test_usage:
    mov edi, 64
    call neboc_host_process_exit
    ud2

test_fail:
    mov edi, [rel fail_code]
    test edi, edi
    jnz .have_code
    mov edi, 1
.have_code:
    call neboc_host_process_exit
    ud2

section .note.GNU-stack noalloc noexec nowrite progbits
