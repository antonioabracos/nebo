; Nebo Assembly — MF054 native visual output conformance
; Test-only fixture rasterizer preserves the deferred production-font decision.
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/behavior/console_behavior.inc"
%include "runtime/console/renderer-registry/renderer_registry.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"
%include "runtime/console/render/software_surface.inc"
%include "runtime/console/render/output_conformance.inc"
%include "runtime/console/platform/adapter_contract.inc"
%include "runtime/console/platform/linux-x11-ewmh-direct-v0/x11_adapter.inc"

extern nebo_console_document_init
extern nebo_console_document_append_text
extern nebo_console_document_append_newline
extern nebo_console_document_set_behavior_set
extern nebo_console_document_copy_plain_text
extern nebo_console_behavior_set_build
extern nebo_console_behavior_store_init
extern nebo_console_behavior_store_register
extern nebo_console_renderer_registry_init
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_console_render_tree_init
extern nebo_console_render_tree_build
extern nebo_console_output_apply_styles
extern nebo_draw_command_buffer_init
extern nebo_console_draw_commands_build
extern nebo_console_output_append_chrome_controls
extern nebo_software_surface_init
extern nebo_software_surface_execute
extern nebo_software_surface_state_hash
extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_report
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern neboc_host_process_exit

global _start

%define TEST_WIDTH 640
%define TEST_HEIGHT 400
%define TEST_STRIDE (TEST_WIDTH*4)
%define TEST_SURFACE_BYTES (TEST_STRIDE*TEST_HEIGHT)
%define TEST_RGB_BYTES (TEST_WIDTH*TEST_HEIGHT*3)
%define TEST_NODE_CAPACITY 32
%define TEST_TEXT_CAPACITY 512
%define TEST_BOX_CAPACITY 64
%define TEST_RENDER_CAPACITY 64
%define TEST_COMMAND_CAPACITY 128
%define TEST_BEHAVIOR_CAPACITY 4
%define TEST_RENDERER_CAPACITY 4
%define TEST_SCRATCH_BYTES 65536
%define TEST_REQUIRED_CAPABILITIES NEBO_PLATFORM_MF052_REQUIRED_CAPABILITIES
%define SYS_WRITE 1
%define SYS_CLOSE 3
%define SYS_NANOSLEEP 35
%define SYS_OPENAT 257
%define AT_FDCWD -100
%define O_WRONLY_CREAT_TRUNC 577
%define MODE_0644 420

section .rodata align=8
auth_name: db "MIT-MAGIC-COOKIE-1"

hello_bytes: db "Ola Nebo"
hello_text:
    dq hello_bytes,8
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
question_bytes: db "Tudo bem?"
question_text:
    dq question_bytes,9
    dd 0
    dw NEBO_RUNTIME_TEXT_ENCODING_UTF8,NEBO_RUNTIME_TEXT_LIFETIME_STATIC
concat_bytes: db "Ola NeboTudo bem?"
newline_bytes: db "Ola Nebo"
newline_lf: db 10
newline_tail: db "Tudo bem?"

red_descriptor:
    dd NEBO_BEHAVIOR_KIND_FOREGROUND_COLOR
    dd NEBO_BEHAVIOR_VERSION_V0
    dq NEBO_COLOR_ID_RED

ppm_header: db "P6"
ppm_header_lf1: db 10
ppm_header_dims: db "640 400"
ppm_header_lf2: db 10
ppm_header_max: db "255"
ppm_header_lf3: db 10
%define PPM_HEADER_LEN 15

; Fixture-only 5x7 glyphs. Each row uses bits 4..0 from left to right.
font_chars: db 32,63,79,78,84,108,97,101,98,111,117,100,109
%define FONT_CHAR_COUNT 13
font_rows:
    db 0,0,0,0,0,0,0                         ; space
    db 14,17,1,2,4,0,4                        ; ?
    db 14,17,17,17,17,17,14                   ; O
    db 17,25,21,19,17,17,17                   ; N
    db 31,4,4,4,4,4,4                         ; T
    db 6,4,4,4,4,4,14                         ; l
    db 0,0,14,1,15,17,15                      ; a
    db 0,0,14,17,31,16,14                     ; e
    db 16,16,30,17,17,17,30                   ; b
    db 0,0,14,17,17,17,14                     ; o
    db 0,0,17,17,17,19,13                     ; u
    db 1,1,15,17,17,17,15                     ; d
    db 0,0,26,21,21,21,21                     ; m

section .bss align=64
; Shared document -> draw -> surface pipeline.
document: resb NEBO_CONSOLE_DOCUMENT_SIZE
nodes: resb TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE
text_store: resb TEST_TEXT_CAPACITY
plain_text: resb TEST_TEXT_CAPACITY
plain_text_length: resq 1
provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
layout_tree: resb NEBO_LAYOUT_TREE_SIZE
layout_boxes: resb TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
render_tree: resb NEBO_RENDER_TREE_SIZE
render_nodes: resb TEST_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE
draw_buffer: resb NEBO_DRAW_BUFFER_SIZE
draw_commands: resb TEST_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE
surface: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels: resb TEST_SURFACE_BYTES
behavior_set_temp: resb NEBO_BEHAVIOR_SET_SIZE
behavior_sets: resb TEST_BEHAVIOR_CAPACITY*NEBO_BEHAVIOR_SET_SIZE
behavior_store: resb NEBO_BEHAVIOR_STORE_SIZE
renderer_registry: resb NEBO_RENDERER_REGISTRY_SIZE
renderer_entries: resb TEST_RENDERER_CAPACITY*NEBO_RENDERER_ENTRY_SIZE
surface_hash: resq 1

; Scenario 4 retains two surfaces at once.
surface_a: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_b: resb NEBO_SOFTWARE_SURFACE_SIZE
surface_pixels_a: resb TEST_SURFACE_BYTES
surface_pixels_b: resb TEST_SURFACE_BYTES

; Native adapter/window state.
report: resb NEBO_PLATFORM_REPORT_SIZE
adapter: resb NEBO_X11_ADAPTER_SIZE
window_a: resb NEBO_X11_WINDOW_SIZE
window_b: resb NEBO_X11_WINDOW_SIZE
normalized_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
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

; Deterministic PPM export buffer.
rgb_buffer: resb TEST_RGB_BYTES
sleep_request: resq 2
fail_code: resd 1

section .text
_start:
    mov rax, [rsp]
    cmp rax, 5
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
    mov r12d, eax
    mov rax, [rsp+24]
    mov [rel socket_arg], rax
    mov rax, [rsp+32]
    mov [rel cookie_arg], rax
    mov rax, [rsp+40]
    mov [rel output_path_a], rax
    cmp r12d, 4
    jne .argc_ready
    cmp qword [rsp], 6
    jne test_usage
    mov rax, [rsp+48]
    mov [rel output_path_b], rax
.argc_ready:
    cmp r12d, 1
    je scenario_1
    cmp r12d, 2
    je scenario_2
    cmp r12d, 3
    je scenario_3
    cmp r12d, 4
    je scenario_4
    jmp scenario_5

; NEBO-E2E-E2E-004 — one default window with Ola Nebo.
scenario_1:
    mov dword [rel fail_code], 11
    mov edi, 1
    call build_fixture
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 12
    lea rdi, [rel plain_text]
    lea rsi, [rel hello_bytes]
    mov edx, 8
    call bytes_equal_exact
    test eax, eax
    jz test_fail
    mov dword [rel fail_code], 13
    call live_adapter_init
    test eax, eax
    jnz test_fail
    mov dword [rel fail_code], 14
    lea rdi, [rel window_a]
    lea rsi, [rel surface]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_adapter
    cmp qword [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 1
    jne test_fail_cleanup_all
    mov dword [rel fail_code], 15
    lea rdi, [rel surface]
    mov rsi, [rel output_path_a]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_all
    call live_cleanup_one
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-E2E-E2E-005 — two default appends concatenate without implicit space/newline.
scenario_2:
    mov edi, 2
    call build_fixture
    test eax, eax
    jnz test_fail
    lea rdi, [rel plain_text]
    lea rsi, [rel concat_bytes]
    mov edx, 17
    call bytes_equal_exact
    test eax, eax
    jz test_fail
    cmp qword [rel render_tree+NEBO_RENDER_TREE_NODE_COUNT_OFFSET], 2
    jne test_fail
    call live_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel window_a]
    lea rsi, [rel surface]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_adapter
    lea rdi, [rel surface]
    mov rsi, [rel output_path_a]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_all
    call live_cleanup_one
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-E2E-E2E-006 — explicit newline creates two visual/document lines.
scenario_3:
    mov edi, 3
    call build_fixture
    test eax, eax
    jnz test_fail
    lea rdi, [rel plain_text]
    lea rsi, [rel newline_bytes]
    mov edx, 18
    call bytes_equal_exact
    test eax, eax
    jz test_fail
    cmp qword [rel document+NEBO_CONSOLE_DOCUMENT_NODE_COUNT_OFFSET], 4
    jne test_fail
    call live_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel window_a]
    lea rsi, [rel surface]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_adapter
    lea rdi, [rel surface]
    mov rsi, [rel output_path_a]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_all
    call live_cleanup_one
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-E2E-E2E-007 — logical names a/b produce two independent native windows.
scenario_4:
    mov edi, 1
    call build_fixture
    test eax, eax
    jnz test_fail
    lea rdi, [rel surface_pixels_a]
    lea rsi, [rel surface_pixels]
    call copy_surface_pixels
    lea rdi, [rel surface_a]
    lea rsi, [rel surface_pixels_a]
    call init_surface_at
    test eax, eax
    jnz test_fail
    mov edi, 4
    call build_fixture
    test eax, eax
    jnz test_fail
    lea rdi, [rel plain_text]
    lea rsi, [rel question_bytes]
    mov edx, 9
    call bytes_equal_exact
    test eax, eax
    jz test_fail
    lea rdi, [rel surface_pixels_b]
    lea rsi, [rel surface_pixels]
    call copy_surface_pixels
    lea rdi, [rel surface_b]
    lea rsi, [rel surface_pixels_b]
    call init_surface_at
    test eax, eax
    jnz test_fail
    call live_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel window_a]
    lea rsi, [rel surface_a]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_adapter
    lea rdi, [rel window_b]
    lea rsi, [rel surface_b]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_all
    cmp qword [rel adapter+NEBO_X11_ADAPTER_ACTIVE_WINDOWS_OFFSET], 2
    jne test_fail_cleanup_both
    mov rax, [rel window_a+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    cmp rax, [rel window_b+NEBO_X11_WINDOW_OPAQUE_HANDLE_OFFSET]
    je test_fail_cleanup_both
    mov eax, [rel window_a+NEBO_X11_WINDOW_XID_OFFSET]
    cmp eax, [rel window_b+NEBO_X11_WINDOW_XID_OFFSET]
    je test_fail_cleanup_both
    lea rdi, [rel surface_a]
    mov rsi, [rel output_path_a]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_both
    lea rdi, [rel surface_b]
    mov rsi, [rel output_path_b]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_both
    call live_cleanup_two
    test eax, eax
    jnz test_fail
    jmp test_pass

; NEBO-E2E-E2E-015 — RED.color remains receiver-local through native present.
scenario_5:
    mov edi, 5
    call build_fixture
    test eax, eax
    jnz test_fail
    lea rbx, [rel render_nodes]
    mov eax, NEBO_COLOR_BGRA_RED
    cmp [rbx+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rax
    jne test_fail
    lea rbx, [rel draw_commands+4*NEBO_DRAW_COMMAND_SIZE]
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_GLYPH_RUN
    jne test_fail
    mov eax, NEBO_COLOR_BGRA_RED
    cmp [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    jne test_fail
    lea rdi, [rel surface_pixels]
    mov esi, NEBO_COLOR_BGRA_RED
    call count_color_pixels
    cmp rax, 20
    jb test_fail
    call live_adapter_init
    test eax, eax
    jnz test_fail
    lea rdi, [rel window_a]
    lea rsi, [rel surface]
    call live_create_present
    test eax, eax
    jnz test_fail_cleanup_adapter
    lea rdi, [rel surface]
    mov rsi, [rel output_path_a]
    call write_ppm
    test eax, eax
    jnz test_fail_cleanup_all
    call live_cleanup_one
    test eax, eax
    jnz test_fail
    jmp test_pass

; EDI fixture: 1 hello, 2 concat, 3 newline, 4 question, 5 red hello.
build_fixture:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12d, edi
    call zero_pipeline_state
    lea rdi, [rel document]
    mov rsi, 0x0000000100000000
    lea rdx, [rel nodes]
    mov ecx, TEST_NODE_CAPACITY
    lea r8, [rel text_store]
    mov r9d, TEST_TEXT_CAPACITY
    call nebo_console_document_init
    test eax, eax
    jnz .done
    cmp r12d, 4
    je .append_question
    lea rdi, [rel document]
    lea rsi, [rel hello_text]
    call nebo_console_document_append_text
    test eax, eax
    jnz .done
    cmp r12d, 1
    je .document_ready
    cmp r12d, 5
    je .document_ready
    cmp r12d, 3
    jne .append_question
    lea rdi, [rel document]
    call nebo_console_document_append_newline
    test eax, eax
    jnz .done
.append_question:
    lea rdi, [rel document]
    lea rsi, [rel question_text]
    call nebo_console_document_append_text
    test eax, eax
    jnz .done
.document_ready:
    lea rdi, [rel behavior_store]
    lea rsi, [rel behavior_sets]
    mov edx, TEST_BEHAVIOR_CAPACITY
    call nebo_console_behavior_store_init
    test eax, eax
    jnz .done
    cmp r12d, 5
    jne .provider
    lea rdi, [rel behavior_set_temp]
    mov esi, 1
    lea rdx, [rel red_descriptor]
    mov ecx, 1
    call nebo_console_behavior_set_build
    test eax, eax
    jnz .done
    lea rdi, [rel behavior_store]
    lea rsi, [rel behavior_set_temp]
    call nebo_console_behavior_store_register
    test eax, eax
    jnz .done
    lea rdi, [rel document]
    mov esi, 2
    mov edx, 1
    call nebo_console_document_set_behavior_set
    test eax, eax
    jnz .done
.provider:
    lea rdi, [rel provider]
    call nebo_fake_glyph_provider_init
    test eax, eax
    jnz .done
    lea rdi, [rel layout_tree]
    lea rsi, [rel layout_boxes]
    mov edx, TEST_BOX_CAPACITY
    mov ecx, TEST_WIDTH*NEBO_LAYOUT_ONE
    mov r8d, TEST_HEIGHT*NEBO_LAYOUT_ONE
    lea r9, [rel provider]
    call nebo_console_layout_init
    test eax, eax
    jnz .done
    lea rdi, [rel layout_tree]
    lea rsi, [rel document]
    call nebo_console_layout_document
    test eax, eax
    jnz .done
    lea rdi, [rel render_tree]
    lea rsi, [rel render_nodes]
    mov edx, TEST_RENDER_CAPACITY
    call nebo_console_render_tree_init
    test eax, eax
    jnz .done
    lea rdi, [rel render_tree]
    lea rsi, [rel layout_tree]
    lea rdx, [rel document]
    call nebo_console_render_tree_build
    test eax, eax
    jnz .done
    lea rdi, [rel renderer_registry]
    lea rsi, [rel renderer_entries]
    mov edx, TEST_RENDERER_CAPACITY
    call nebo_console_renderer_registry_init
    test eax, eax
    jnz .done
    lea rdi, [rel render_tree]
    lea rsi, [rel document]
    lea rdx, [rel renderer_registry]
    lea rcx, [rel behavior_store]
    call nebo_console_output_apply_styles
    test eax, eax
    jnz .done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel draw_commands]
    mov edx, TEST_COMMAND_CAPACITY
    lea rcx, [rel document]
    call nebo_draw_command_buffer_init
    test eax, eax
    jnz .done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel layout_tree]
    lea rdx, [rel render_tree]
    call nebo_console_draw_commands_build
    test eax, eax
    jnz .done
    lea rdi, [rel draw_buffer]
    lea rsi, [rel layout_tree]
    call nebo_console_output_append_chrome_controls
    test eax, eax
    jnz .done
    lea rdi, [rel surface]
    lea rsi, [rel surface_pixels]
    mov edx, TEST_SURFACE_BYTES
    mov ecx, TEST_WIDTH
    mov r8d, TEST_HEIGHT
    call nebo_software_surface_init
    test eax, eax
    jnz .done
    lea rdi, [rel surface]
    lea rsi, [rel draw_buffer]
    lea rdx, [rel provider]
    call nebo_software_surface_execute
    test eax, eax
    jnz .done
    ; Remove the production synthetic glyph rectangles from the content area.
    ; The MF054 conformance rasterizer remains test-only and preserves chrome.
    lea rdi, [rel surface]
    mov esi, 1
    mov edx, 31
    mov ecx, TEST_WIDTH-2
    mov r8d, TEST_HEIGHT-32
    mov r9d, NEBO_COLOR_BGRA_BLACK
    call test_fill_rect
    test eax, eax
    jnz .done
    lea rdi, [rel surface]
    lea rsi, [rel draw_buffer]
    call overlay_fixture_glyphs
    test eax, eax
    jnz .done
    lea rdi, [rel surface]
    lea rsi, [rel surface_hash]
    call nebo_software_surface_state_hash
    test eax, eax
    jnz .done
    lea rdi, [rel document]
    lea rsi, [rel plain_text]
    mov edx, TEST_TEXT_CAPACITY
    lea rcx, [rel plain_text_length]
    call nebo_console_document_copy_plain_text
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

zero_pipeline_state:
    lea rdi, [rel document]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_DOCUMENT_QWORDS
    cld
    rep stosq
    lea rdi, [rel nodes]
    mov ecx, (TEST_NODE_CAPACITY*NEBO_CONSOLE_NODE_HEADER_SIZE)/8
    rep stosq
    lea rdi, [rel text_store]
    mov ecx, TEST_TEXT_CAPACITY/8
    rep stosq
    lea rdi, [rel plain_text]
    mov ecx, TEST_TEXT_CAPACITY/8
    rep stosq
    lea rdi, [rel provider]
    mov ecx, NEBO_FAKE_GLYPH_PROVIDER_QWORDS
    rep stosq
    lea rdi, [rel layout_tree]
    mov ecx, NEBO_LAYOUT_TREE_QWORDS
    rep stosq
    lea rdi, [rel layout_boxes]
    mov ecx, (TEST_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE)/8
    rep stosq
    lea rdi, [rel render_tree]
    mov ecx, NEBO_RENDER_TREE_QWORDS
    rep stosq
    lea rdi, [rel render_nodes]
    mov ecx, (TEST_RENDER_CAPACITY*NEBO_RENDER_NODE_SIZE)/8
    rep stosq
    lea rdi, [rel draw_buffer]
    mov ecx, NEBO_DRAW_BUFFER_QWORDS
    rep stosq
    lea rdi, [rel draw_commands]
    mov ecx, (TEST_COMMAND_CAPACITY*NEBO_DRAW_COMMAND_SIZE)/8
    rep stosq
    lea rdi, [rel behavior_set_temp]
    mov ecx, NEBO_BEHAVIOR_SET_QWORDS
    rep stosq
    lea rdi, [rel behavior_sets]
    mov ecx, (TEST_BEHAVIOR_CAPACITY*NEBO_BEHAVIOR_SET_SIZE)/8
    rep stosq
    lea rdi, [rel behavior_store]
    mov ecx, NEBO_BEHAVIOR_STORE_QWORDS
    rep stosq
    lea rdi, [rel renderer_registry]
    mov ecx, NEBO_RENDERER_REGISTRY_QWORDS
    rep stosq
    lea rdi, [rel renderer_entries]
    mov ecx, (TEST_RENDERER_CAPACITY*NEBO_RENDERER_ENTRY_SIZE)/8
    rep stosq
    lea rdi, [rel surface]
    mov ecx, NEBO_SOFTWARE_SURFACE_QWORDS
    rep stosq
    lea rdi, [rel surface_pixels]
    mov ecx, TEST_SURFACE_BYTES/8
    rep stosq
    mov qword [rel plain_text_length], 0
    ret

; Test-only readable raster overlay. RDI surface*, RSI draw_buffer*.
overlay_fixture_glyphs:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rdi
    mov r13, rsi
    xor r14d, r14d
.command_loop:
    cmp r14, [r13+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    jae .success
    mov rax, r14
    imul rax, NEBO_DRAW_COMMAND_SIZE
    add rax, [r13+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
    mov rbx, rax
    cmp dword [rbx+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_GLYPH_RUN
    jne .next_command
    mov rax, [r13+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .failure
    mov r15, [rax+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add r15, [rbx+NEBO_DRAW_COMMAND_SOURCE_OFFSET_OFFSET]
    mov rax, [rbx+NEBO_DRAW_COMMAND_SOURCE_LENGTH_OFFSET]
    mov [rsp], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_X_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+8], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_Y_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+16], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_WIDTH_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+24], rax
    mov rax, [rbx+NEBO_DRAW_COMMAND_HEIGHT_OFFSET]
    sar rax, NEBO_LAYOUT_FRACTION_BITS
    mov [rsp+32], rax
    ; Clear production synthetic glyphs inside the run box.
    mov rdi, r12
    mov rsi, [rsp+8]
    mov rdx, [rsp+16]
    mov rcx, [rsp+24]
    mov r8, [rsp+32]
    mov r9d, NEBO_COLOR_BGRA_BLACK
    call test_fill_rect
    test eax, eax
    jnz .failure
    xor r10d, r10d
.glyph_loop:
    cmp r10, [rsp]
    jae .next_command
    movzx edi, byte [r15+r10]
    mov rsi, [rsp+8]
    mov rax, r10
    imul rax, 8
    add rsi, rax
    mov rdx, [rsp+16]
    add rdx, 4
    mov ecx, [rbx+NEBO_DRAW_COMMAND_COLOR_OFFSET]
    mov [rsp+40], r10
    mov r8, r12
    call draw_fixture_glyph_on_surface
    mov r10, [rsp+40]
    test eax, eax
    jnz .failure
    inc r10
    jmp .glyph_loop
.next_command:
    inc r14
    jmp .command_loop
.success:
    xor eax, eax
    jmp .done
.failure:
    mov eax, -1
.done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; The previous generic glyph helper needs the active surface. This direct helper
; is used by overlay_fixture_glyphs and keeps the rasterizer test-local.
; EDI ASCII, RSI x, RDX y, ECX BGRA, R8 surface*.
draw_fixture_glyph_on_surface:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12d, edi
    mov r13, rsi
    mov r14, rdx
    mov r15d, ecx
    mov [rsp], r8
    xor ebx, ebx
.g_find:
    cmp ebx, FONT_CHAR_COUNT
    jae .g_fallback
    lea rax, [rel font_chars]
    movzx eax, byte [rax+rbx]
    cmp eax, r12d
    je .g_found
    inc ebx
    jmp .g_find
.g_fallback:
    mov ebx, 1
.g_found:
    imul rbx, 7
    xor r10d, r10d
.g_row:
    cmp r10d, 7
    jae .g_ok
    lea rax, [rel font_rows]
    add rax, rbx
    movzx r11d, byte [rax+r10]
    xor r9d, r9d
.g_col:
    cmp r9d, 5
    jae .g_next_row
    mov eax, 4
    sub eax, r9d
    mov edx, 1
    mov ecx, eax
    shl edx, cl
    test r11d, edx
    jz .g_next_col
    mov rdi, [rsp]
    lea rsi, [r13+r9]
    lea rdx, [r14+r10]
    mov ecx, r15d
    call test_put_pixel
    test eax, eax
    jnz .g_fail
.g_next_col:
    inc r9d
    jmp .g_col
.g_next_row:
    inc r10d
    jmp .g_row
.g_ok:
    xor eax, eax
    jmp .g_done
.g_fail:
    mov eax, -1
.g_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; surface*, x, y, color.
test_put_pixel:
    test rdi, rdi
    jz .pixel_fail
    cmp rsi, [rdi+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    jae .pixel_ok
    cmp rdx, [rdi+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    jae .pixel_ok
    mov rax, rdx
    imul rax, [rdi+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    lea rax, [rax+rsi*4]
    add rax, [rdi+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    mov [rax], ecx
.pixel_ok:
    xor eax, eax
    ret
.pixel_fail:
    mov eax, -1
    ret

; surface*, x, y, width, height, color.
test_fill_rect:
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
    mov rbx, r8
    mov [rsp], r9d
    xor r10d, r10d
.fill_row:
    cmp r10, rbx
    jae .fill_ok
    xor r11d, r11d
.fill_col:
    cmp r11, r15
    jae .fill_next_row
    mov rdi, r12
    lea rsi, [r13+r11]
    lea rdx, [r14+r10]
    mov ecx, [rsp]
    call test_put_pixel
    test eax, eax
    jnz .fill_fail
    inc r11
    jmp .fill_col
.fill_next_row:
    inc r10
    jmp .fill_row
.fill_ok:
    xor eax, eax
    jmp .fill_done
.fill_fail:
    mov eax, -1
.fill_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Patch overlay call to direct surface-aware glyph helper.
; This trampoline keeps NASM labels explicit for static audits.
overlay_draw_one:
    jmp draw_fixture_glyph_on_surface

; Adapter init from explicit Unix socket/auth arguments.
live_adapter_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    call zero_native_state
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
    mov qword [rdi+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET], NEBO_X11_AUTH_NAME_LENGTH
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

; RDI window*, RSI surface*.
live_create_present:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    lea rdi, [rel window_config]
    xor eax, eax
    mov ecx, NEBO_X11_WINDOW_CONFIG_QWORDS
    cld
    rep stosq
    lea rdi, [rel window_config]
    mov [rdi+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET], r13
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET], TEST_WIDTH
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET], TEST_HEIGHT
    mov qword [rdi+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET], NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS
    lea rdi, [rel adapter]
    mov rsi, r12
    lea rdx, [rel window_config]
    call nebo_x11_adapter_create_window
    test eax, eax
    jz .create_ok
    mov dword [rel fail_code], 141
    jmp .fail
.create_ok:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    call wait_for_window_event
    test eax, eax
    jz .mount_ok
    mov dword [rel fail_code], 142
    jmp .fail
.mount_ok:
    cmp dword [r12+NEBO_X11_WINDOW_STATE_OFFSET], NEBO_X11_WINDOW_STATE_MAPPED
    je .pre_state_ok
    mov dword [rel fail_code], 161
    jmp .fail
.pre_state_ok:
    test dword [r12+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET], NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
    jz .pre_minimized_ok
    mov dword [rel fail_code], 162
    jmp .fail
.pre_minimized_ok:
    cmp r13, [r12+NEBO_X11_WINDOW_SURFACE_PTR_OFFSET]
    je .pre_ptr_ok
    mov dword [rel fail_code], 163
    jmp .fail
.pre_ptr_ok:
    mov rax, [r13+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    cmp rax, [r12+NEBO_X11_WINDOW_WIDTH_OFFSET]
    je .pre_width_ok
    mov dword [rel fail_code], 164
    jmp .fail
.pre_width_ok:
    mov rax, [r13+NEBO_SOFTWARE_SURFACE_HEIGHT_OFFSET]
    cmp rax, [r12+NEBO_X11_WINDOW_HEIGHT_OFFSET]
    je .pre_height_ok
    mov dword [rel fail_code], 165
    jmp .fail
.pre_height_ok:
    cmp qword [r13+NEBO_SOFTWARE_SURFACE_PIXEL_FORMAT_OFFSET], NEBO_SURFACE_PIXEL_FORMAT_BGRA8_PREMULTIPLIED
    je .pre_format_ok
    mov dword [rel fail_code], 166
    jmp .fail
.pre_format_ok:
    mov rax, [r13+NEBO_SOFTWARE_SURFACE_WIDTH_OFFSET]
    shl rax, 2
    cmp rax, [r13+NEBO_SOFTWARE_SURFACE_STRIDE_OFFSET]
    je .pre_stride_ok
    mov dword [rel fail_code], 167
    jmp .fail
.pre_stride_ok:
    mov rax, [r13+NEBO_SOFTWARE_SURFACE_FLAGS_OFFSET]
    and rax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    cmp rax, NEBO_SOFTWARE_SURFACE_REQUIRED_FLAGS
    je .pre_flags_ok
    mov dword [rel fail_code], 168
    jmp .fail
.pre_flags_ok:
    lea rdi, [rel adapter]
    mov rsi, r12
    mov rdx, r13
    lea rcx, [rel normalized_event]
    call nebo_x11_adapter_present
    test eax, eax
    jz .present_ok
    cmp eax, 256
    jb .present_status_small
    sub eax, 256
.present_status_small:
    add eax, 150
    mov dword [rel fail_code], eax
    jmp .fail
.present_ok:
    cmp qword [r12+NEBO_X11_WINDOW_PRESENT_COUNT_OFFSET], 1
    je .count_ok
    mov dword [rel fail_code], 144
    jmp .fail
.count_ok:
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

; RDI window*, ESI expected kind.
wait_for_window_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
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
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

live_cleanup_one:
    push r12
    lea rdi, [rel adapter]
    lea rsi, [rel window_a]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .done
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
.done:
    pop r12
    ret

live_cleanup_two:
    push r12
    lea rdi, [rel adapter]
    lea rsi, [rel window_b]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .done
    lea rdi, [rel adapter]
    lea rsi, [rel window_a]
    call nebo_x11_adapter_destroy_window
    test eax, eax
    jnz .done
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
.done:
    pop r12
    ret

zero_native_state:
    lea rdi, [rel adapter]
    xor eax, eax
    mov ecx, NEBO_X11_ADAPTER_QWORDS
    cld
    rep stosq
    lea rdi, [rel window_a]
    mov ecx, NEBO_X11_WINDOW_QWORDS
    rep stosq
    lea rdi, [rel window_b]
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
    ret

; RDI surface record, RSI pixel storage.
init_surface_at:
    push r12
    mov r12, rdi
    mov rdx, TEST_SURFACE_BYTES
    mov ecx, TEST_WIDTH
    mov r8d, TEST_HEIGHT
    call nebo_software_surface_init
    pop r12
    ret

copy_surface_pixels:
    mov rcx, TEST_SURFACE_BYTES/8
    cld
    rep movsq
    ret

; Compare plain_text_length and bytes. RDI actual, RSI expected, EDX length.
bytes_equal_exact:
    cmp [rel plain_text_length], rdx
    jne .not_equal
    mov rcx, rdx
    cld
    repe cmpsb
    jne .not_equal
    mov eax, 1
    ret
.not_equal:
    xor eax, eax
    ret

; Count exact BGRA pixels. RDI pixels*, ESI color -> RAX count.
count_color_pixels:
    xor eax, eax
    xor ecx, ecx
.count_loop:
    cmp ecx, TEST_SURFACE_BYTES/4
    jae .count_done
    cmp [rdi+rcx*4], esi
    jne .count_next
    inc rax
.count_next:
    inc rcx
    jmp .count_loop
.count_done:
    ret

; Write exact surface as deterministic P6 PPM. RDI surface*, RSI path*.
write_ppm:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .fail
    test r13, r13
    jz .fail
    mov r14, [r12+NEBO_SOFTWARE_SURFACE_BUFFER_PTR_OFFSET]
    lea r15, [rel rgb_buffer]
    xor rcx, rcx
.convert_loop:
    cmp rcx, TEST_WIDTH*TEST_HEIGHT
    jae .open
    mov eax, [r14+rcx*4]
    lea r8, [rcx+rcx*2]
    mov edx, eax
    shr edx, 16
    mov [r15+r8], dl
    mov edx, eax
    shr edx, 8
    mov [r15+r8+1], dl
    mov [r15+r8+2], al
    inc rcx
    jmp .convert_loop
.open:
    mov eax, SYS_OPENAT
    mov rdi, AT_FDCWD
    mov rsi, r13
    mov edx, O_WRONLY_CREAT_TRUNC
    mov r10d, MODE_0644
    syscall
    test rax, rax
    js .fail
    mov rbx, rax
    mov rdi, rbx
    lea rsi, [rel ppm_header]
    mov edx, PPM_HEADER_LEN
    call write_all
    test eax, eax
    jnz .close_fail
    mov rdi, rbx
    lea rsi, [rel rgb_buffer]
    mov edx, TEST_RGB_BYTES
    call write_all
    test eax, eax
    jnz .close_fail
    mov eax, SYS_CLOSE
    mov rdi, rbx
    syscall
    test rax, rax
    js .fail
    xor eax, eax
    jmp .done
.close_fail:
    mov eax, SYS_CLOSE
    mov rdi, rbx
    syscall
.fail:
    mov eax, -1
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; RDI fd, RSI bytes, RDX length.
write_all:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    mov rbx, rdx
.loop:
    test rbx, rbx
    jz .ok
    mov eax, SYS_WRITE
    mov rdi, r12
    mov rsi, r13
    mov rdx, rbx
    syscall
    test rax, rax
    jle .fail
    add r13, rax
    sub rbx, rax
    jmp .loop
.ok:
    xor eax, eax
    jmp .done
.fail:
    mov eax, -1
.done:
    pop r13
    pop r12
    pop rbx
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
    jz .done_hex
    call hex_nibble
    cmp eax, -1
    je .invalid
    mov r8d, eax
    movzx edi, byte [r12+1]
    test dil, dil
    jz .invalid
    call hex_nibble
    cmp eax, -1
    je .invalid
    cmp rbx, r14
    jae .invalid
    shl r8d, 4
    or r8d, eax
    mov [r13+rbx], r8b
    inc rbx
    add r12, 2
    jmp .loop
.done_hex:
    mov [r15], rbx
    xor eax, eax
    jmp .done
.invalid:
    mov eax, -1
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

hex_nibble:
    cmp dil, '0'
    jb .bad
    cmp dil, '9'
    jbe .digit
    cmp dil, 'a'
    jb .upper
    cmp dil, 'f'
    jbe .lower
.upper:
    cmp dil, 'A'
    jb .bad
    cmp dil, 'F'
    ja .bad
    movzx eax, dil
    sub eax, 'A'-10
    ret
.lower:
    movzx eax, dil
    sub eax, 'a'-10
    ret
.digit:
    movzx eax, dil
    sub eax, '0'
    ret
.bad:
    mov eax, -1
    ret

test_fail_cleanup_both:
    call live_cleanup_two
    jmp test_fail

test_fail_cleanup_all:
    call live_cleanup_one
    jmp test_fail

test_fail_cleanup_adapter:
    lea rdi, [rel adapter]
    call nebo_x11_adapter_shutdown
    jmp test_fail

test_pass:
    xor edi, edi
    jmp neboc_host_process_exit

test_usage:
    mov dword [rel fail_code], 2
test_fail:
    mov edi, [rel fail_code]
    test edi, edi
    jnz .have_fail_code
    mov edi, 1
.have_fail_code:
    jmp neboc_host_process_exit

section .note.GNU-stack noalloc noexec nowrite progbits
