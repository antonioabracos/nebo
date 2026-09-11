; Nebo practical live Console frontend — direct local X11, no C/libc/Xlib.
bits 64
default rel

%include "runtime/console/live/live_console.inc"

extern nebo_console_domain_from_handle
extern nebo_input_runtime_registry_for_console
extern nebo_console_scan_cancel
extern nebo_fake_glyph_provider_init
extern nebo_console_layout_init
extern nebo_console_layout_document
extern nebo_focus_manager_init
extern nebo_focus_manager_sync
extern nebo_focus_manager_set_window_active
extern nebo_focus_manager_current_editor
extern nebo_dependency_bridge_init
extern nebo_input_submission_init
extern nebo_native_input_bridge_init
extern nebo_native_input_bridge_dispatch
extern nebo_x11_adapter_init
extern nebo_x11_adapter_shutdown
extern nebo_x11_adapter_create_window
extern nebo_x11_adapter_destroy_window
extern nebo_x11_adapter_present
extern nebo_x11_adapter_poll_event
extern nebo_x11_adapter_normalize_event
extern nebo_x11_adapter_minimize_window
extern nebo_x11_adapter_maximize_window
extern nebo_x11_adapter_restore_window
extern nebo_x11_adapter_begin_window_drag
extern nebo_x11_adapter_begin_window_resize
extern nebo_x11_adapter_set_resize_cursor
extern nebo_x11_adapter_request_close
extern nebo_console_chrome_hit_test
extern nebo_console_chrome_motion_hit_test
extern nebo_console_chrome_resize_direction
extern nebo_console_chrome_action_for_region
extern nebo_runtime_live_visual_render

global nebo_runtime_live_finalize
global nebo_runtime_live_scan_roundtrip
global nebo_runtime_live_console_set_title
global nebo_runtime_live_console_set_icon
global nebo_runtime_live_console_metadata_snapshot
global nebo_runtime_live_available
global nebo_runtime_live_input_security
global nebo_runtime_live_input_wipe

%define SYS_READ 0
%define SYS_CLOSE 3
%define SYS_MMAP 9
%define SYS_MUNMAP 11
%define SYS_OPENAT 257
%define PROT_READ_WRITE 3
%define MAP_PRIVATE_ANONYMOUS 0x22
%define AT_FDCWD -100
%define FAMILY_LOCAL 256
%define FAMILY_WILD 65535

section .rodata align=8
live_auth_name: db "MIT-MAGIC-COOKIE-1"
live_auth_name_len equ $-live_auth_name
live_socket_prefix: db "/tmp/.X11-unix/X"
live_socket_prefix_len equ $-live_socket_prefix
live_xauthority_suffix: db "/.Xauthority",0
live_xauthority_suffix_len equ $-live_xauthority_suffix
live_env_display: db "DISPLAY="
live_env_display_len equ $-live_env_display
live_env_xauthority: db "XAUTHORITY="
live_env_xauthority_len equ $-live_env_xauthority
live_env_home: db "HOME="
live_env_home_len equ $-live_env_home
live_unix_prefix: db "unix/"
live_unix_prefix_len equ $-live_unix_prefix
live_localhost_prefix: db "localhost"
live_localhost_prefix_len equ $-live_localhost_prefix
live_default_title: db "NEBO CONSOLE"
live_default_title_len equ $-live_default_title

section .bss align=64
live_state: resq 1
live_display_value: resq 1
live_xauthority_value: resq 1
live_home_value: resq 1
live_display_number: resb 4
live_display_number_length: resq 1
live_socket_address: resb NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
live_socket_address_length: resq 1
live_xauthority_path: resb NEBO_LIVE_XAUTH_PATH_BYTES
live_xauth_file: resb NEBO_LIVE_XAUTH_BYTES
live_xauth_length: resq 1
live_auth_cookie: resb NEBO_X11_MAX_AUTH_BYTES
live_auth_cookie_length: resq 1
live_x11_config: resb NEBO_X11_CONFIG_SIZE
live_window_config: resb NEBO_X11_WINDOW_CONFIG_SIZE
live_adapter: resb NEBO_X11_ADAPTER_SIZE
live_window: resb NEBO_X11_WINDOW_SIZE
live_event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
live_raw_event: resb NEBO_X11_EVENT_SIZE
live_check_pending_text: resq 1
live_surface: resb NEBO_SOFTWARE_SURFACE_SIZE
live_surface_pixels: resq 1
live_surface_capacity: resq 1
live_render_width: resq 1
live_render_height: resq 1
live_window_flags: resq 1
live_hover_region: resq 1
; One private capture bit pairs a primary custom-chrome press with its release.
; The WM may move/resize the window before that grabbed release is delivered.
live_chrome_press_active: resq 1
live_x11_scratch: resb NEBO_LIVE_X11_SCRATCH_BYTES
live_document: resq 1

; Bounded, runtime-owned live window metadata. Callers never lend storage.
live_metadata_initialized: resq 1
live_metadata_revision: resq 1
live_title_length: resq 1
live_title_storage: resb NEBO_LIVE_TITLE_MAX_BYTES
live_icon_width: resq 1
live_icon_height: resq 1
live_icon_stride: resq 1
live_icon_storage: resb NEBO_LIVE_ICON_BYTES
live_visual_config: resb NEBO_LIVE_CONFIG_SIZE

; Canonical Console input engine frontend storage. Semantic records remain in
; runtime_core; these buffers own only layout, editing and immutable results.
live_input_registry: resq 1
live_pending_registry: resq 1
live_provider: resb NEBO_FAKE_GLYPH_PROVIDER_SIZE
live_layout: resb NEBO_LAYOUT_TREE_SIZE
live_layout_boxes: resb NEBO_LIVE_LAYOUT_BOX_CAPACITY*NEBO_LAYOUT_BOX_SIZE
live_focus_storage: resb NEBO_FOCUS_STORAGE_SIZE
live_focus_manager: resb NEBO_FOCUS_MANAGER_SIZE
live_editors: resb NEBO_LIVE_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE
live_editor_text: resb NEBO_LIVE_INPUT_CAPACITY*NEBO_LIVE_INPUT_TEXT_STRIDE
live_dependency_bridge: resb NEBO_DEPENDENCY_BRIDGE_SIZE
live_continuations: resb NEBO_LIVE_INPUT_CAPACITY*NEBO_DEPENDENCY_CONTINUATION_SIZE
live_submission_storage: resb NEBO_SUBMISSION_STORAGE_SIZE
live_submission_values: resb NEBO_LIVE_INPUT_CAPACITY*NEBO_LIVE_INPUT_TEXT_STRIDE
live_submission_context: resb NEBO_SUBMISSION_CONTEXT_SIZE
live_native_bridge: resb NEBO_NATIVE_INPUT_BRIDGE_SIZE
live_editor_ptr: resq 1
live_input_ready: resq 1
live_input_security: resq 1
live_chrome_region: resd 1
live_chrome_action: resd 1
live_resize_direction_value: resd 1
live_pointer_x: resq 1
live_pointer_y: resq 1

section .text
; Internal acquisition bridge: zero means a usable local display, one means
; no display (the caller may use stdin); other values are real backend errors.
nebo_runtime_live_available:
 jmp live_adapter_prepare

nebo_runtime_live_input_security:
 mov [rel live_input_security],rdi
 ret

nebo_runtime_live_input_wipe:
 ; The editor arena belongs to one synchronous acquisition. A new anonymous
 ; console can reuse input slot numbers; stale resolved editor handles must
 ; not be mistaken for the new registry's pending input.
 lea rdi,[rel live_editors]
 mov ecx,NEBO_LIVE_INPUT_CAPACITY*NEBO_TEXT_EDIT_RECORD_SIZE/8
 xor eax,eax
 cld
 rep stosq
 mov qword [rel live_editor_ptr],0
 mov qword [rel live_input_ready],0
 lea rdi,[rel live_editor_text]
 mov ecx,NEBO_LIVE_INPUT_CAPACITY*NEBO_LIVE_INPUT_TEXT_STRIDE/8
 xor eax,eax
 cld
 rep stosq
 lea rdi,[rel live_submission_values]
 mov ecx,NEBO_LIVE_INPUT_CAPACITY*NEBO_LIVE_INPUT_TEXT_STRIDE/8
 rep stosq
 ret

; Initialize the bounded metadata store and default geometry exactly once.
live_metadata_init:
 cmp qword [rel live_metadata_initialized],0
 jne .metadata_init_ok
 lea rsi,[rel live_default_title]
 lea rdi,[rel live_title_storage]
 mov ecx,live_default_title_len
 cld
 rep movsb
 mov qword [rel live_title_length],live_default_title_len
 mov qword [rel live_metadata_revision],1
 mov qword [rel live_render_width],NEBO_LIVE_DEFAULT_WIDTH
 mov qword [rel live_render_height],NEBO_LIVE_DEFAULT_HEIGHT
 mov qword [rel live_metadata_initialized],1
.metadata_init_ok:
 xor eax,eax
 ret

; set_title(bytes*, length) -> metadata status. An empty title restores the
; product default. No NUL scan is ever performed and caller storage is copied.
nebo_runtime_live_console_set_title:
 push rbx
 push r12
 push r13
 mov r12,rdi
 mov r13,rsi
 call live_metadata_init
 cmp r13,NEBO_LIVE_TITLE_MAX_BYTES
 ja .title_limit
 test r13,r13
 jz .title_default
 test r12,r12
 jz .title_invalid
 jmp .title_copy
.title_default:
 lea r12,[rel live_default_title]
 mov r13d,live_default_title_len
.title_copy:
 lea rdi,[rel live_title_storage]
 mov rsi,r12
 mov rcx,r13
 cld
 rep movsb
 mov [rel live_title_length],r13
 inc qword [rel live_metadata_revision]
 call live_metadata_apply_if_window
 test eax,eax
 jnz .title_state
 xor eax,eax
 jmp .title_done
.title_invalid:
 mov eax,NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT
 jmp .title_done
.title_limit:
 mov eax,NEBO_LIVE_METADATA_STATUS_LIMIT
 jmp .title_done
.title_state:
 mov eax,NEBO_LIVE_METADATA_STATUS_BAD_STATE
.title_done:
 pop r13
 pop r12
 pop rbx
 ret

; set_icon(BGRA8 premultiplied pixels*, width, height, source_stride)
; -> metadata status. All-zero arguments clear the icon. Valid pixels are
; copied row-wise into fixed runtime-owned storage before the state is exposed.
nebo_runtime_live_console_set_icon:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov r15,rcx
 call live_metadata_init
 mov rax,r12
 or rax,r13
 or rax,r14
 or rax,r15
 jz .icon_clear
 test r12,r12
 jz .icon_invalid
 test r13,r13
 jz .icon_invalid
 test r14,r14
 jz .icon_invalid
 cmp r13,NEBO_LIVE_ICON_MAX_WIDTH
 ja .icon_limit
 cmp r14,NEBO_LIVE_ICON_MAX_HEIGHT
 ja .icon_limit
 mov rax,r13
 shl rax,2
 jc .icon_limit
 mov [rsp],rax
 cmp r15,rax
 jb .icon_invalid
 cmp r15,4096
 ja .icon_limit
 mov rax,r15
 mul r14
 test rdx,rdx
 jnz .icon_limit
 cmp rax,NEBO_SURFACE_MAX_BYTES
 ja .icon_limit
 lea rdi,[rel live_icon_storage]
 xor eax,eax
 mov ecx,NEBO_LIVE_ICON_BYTES/8
 cld
 rep stosq
 xor ebx,ebx
.icon_copy_row:
 cmp rbx,r14
 jae .icon_commit
 mov rax,rbx
 imul rax,r15
 lea rsi,[r12+rax]
 mov rax,rbx
 imul rax,NEBO_LIVE_ICON_MAX_WIDTH*4
 lea rdi,[rel live_icon_storage]
 add rdi,rax
 mov rcx,[rsp]
 cld
 rep movsb
 inc rbx
 jmp .icon_copy_row
.icon_commit:
 mov [rel live_icon_width],r13
 mov [rel live_icon_height],r14
 mov qword [rel live_icon_stride],NEBO_LIVE_ICON_MAX_WIDTH*4
 jmp .icon_changed
.icon_clear:
 lea rdi,[rel live_icon_storage]
 xor eax,eax
 mov ecx,NEBO_LIVE_ICON_BYTES/8
 cld
 rep stosq
 mov qword [rel live_icon_width],0
 mov qword [rel live_icon_height],0
 mov qword [rel live_icon_stride],0
.icon_changed:
 inc qword [rel live_metadata_revision]
 call live_metadata_apply_if_window
 test eax,eax
 jnz .icon_state
 xor eax,eax
 jmp .icon_done
.icon_invalid:
 mov eax,NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT
 jmp .icon_done
.icon_limit:
 mov eax,NEBO_LIVE_METADATA_STATUS_LIMIT
 jmp .icon_done
.icon_state:
 mov eax,NEBO_LIVE_METADATA_STATUS_BAD_STATE
.icon_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; metadata_snapshot(LiveConfig*) -> metadata status.
nebo_runtime_live_console_metadata_snapshot:
 push rbx
 mov rbx,rdi
 test rbx,rbx
 jz .snapshot_invalid
 call live_metadata_init
 mov rdi,rbx
 call live_metadata_fill_config
 xor eax,eax
 jmp .snapshot_done
.snapshot_invalid:
 mov eax,NEBO_LIVE_METADATA_STATUS_INVALID_ARGUMENT
.snapshot_done:
 pop rbx
 ret

; Populate a caller-owned render snapshot from current owned state.
live_metadata_fill_config:
 mov rax,[rel live_render_width]
 mov [rdi+NEBO_LIVE_CONFIG_WIDTH_OFFSET],rax
 mov rax,[rel live_render_height]
 mov [rdi+NEBO_LIVE_CONFIG_HEIGHT_OFFSET],rax
 mov rax,[rel live_window_flags]
 cmp qword [rel live_state],NEBO_LIVE_STATE_WINDOW
 jne .config_hover
 test dword [rel live_window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET],NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
 jz .config_hover
 or rax,NEBO_CHROME_WINDOW_FLAG_MAXIMIZED
.config_hover:
 cmp qword [rel live_hover_region],NEBO_CHROME_REGION_MINIMIZE
 jne .config_hover_max
 or rax,NEBO_CHROME_WINDOW_FLAG_HOVER_MINIMIZE
.config_hover_max:
 cmp qword [rel live_hover_region],NEBO_CHROME_REGION_MAXIMIZE_RESTORE
 jne .config_hover_close
 or rax,NEBO_CHROME_WINDOW_FLAG_HOVER_MAXIMIZE
.config_hover_close:
 cmp qword [rel live_hover_region],NEBO_CHROME_REGION_CLOSE
 jne .config_flags_ready
 or rax,NEBO_CHROME_WINDOW_FLAG_HOVER_CLOSE
.config_flags_ready:
 mov [rdi+NEBO_LIVE_CONFIG_WINDOW_FLAGS_OFFSET],rax
 lea rax,[rel live_title_storage]
 mov [rdi+NEBO_LIVE_CONFIG_TITLE_PTR_OFFSET],rax
 mov rax,[rel live_title_length]
 mov [rdi+NEBO_LIVE_CONFIG_TITLE_LENGTH_OFFSET],rax
 lea rax,[rel live_icon_storage]
 mov [rdi+NEBO_LIVE_CONFIG_ICON_PTR_OFFSET],rax
 mov rax,[rel live_icon_width]
 mov [rdi+NEBO_LIVE_CONFIG_ICON_WIDTH_OFFSET],rax
 mov rax,[rel live_icon_height]
 mov [rdi+NEBO_LIVE_CONFIG_ICON_HEIGHT_OFFSET],rax
 mov rax,[rel live_icon_stride]
 mov [rdi+NEBO_LIVE_CONFIG_ICON_STRIDE_OFFSET],rax
 mov rax,[rel live_metadata_revision]
 mov [rdi+NEBO_LIVE_CONFIG_REVISION_OFFSET],rax
 ret

; Apply committed metadata to a live window. The setter remains useful before
; window creation, while live updates change both WM metadata and pixels.
live_metadata_apply_if_window:
 push rbx
 cmp qword [rel live_state],NEBO_LIVE_STATE_WINDOW
 jne .metadata_apply_ok
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_title_storage]
 mov rcx,[rel live_title_length]
 call nebo_x11_adapter_set_window_title
 test eax,eax
 jnz .metadata_apply_done
 mov rdi,[rel live_document]
 test rdi,rdi
 jz .metadata_apply_ok
 mov rsi,[rel live_editor_ptr]
 call live_present_document
 jmp .metadata_apply_done
.metadata_apply_ok:
 xor eax,eax
.metadata_apply_done:
 pop rbx
 ret

; finalize(initial_stack, ConsoleRuntimeContext*, ConsoleHandle) -> status.
; An absent DISPLAY preserves the historical headless behavior. Once DISPLAY
; selects local X11, initialization failure is observable and never downgraded.
nebo_runtime_live_finalize:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 test r14,r14
 jz .final_bad
 mov rdi,r13
 mov rsi,r14
 lea rdx,[rel live_document]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .final_bad
 mov rax,[rel live_document]
 mov rax,[rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
 test rax,rax
 jz .final_bad
 mov [rel live_document],rax
 cmp qword [rel live_state],NEBO_LIVE_STATE_CLOSED
 je .final_headless
 mov rdi,r12
 call live_adapter_prepare
 cmp eax,NEBO_LIVE_STATUS_HEADLESS
 je .final_headless
 test eax,eax
 jnz .final_done
 mov rdi,[rel live_document]
 xor esi,esi
 call live_present_document
 test eax,eax
 jnz .final_cleanup_error
 call live_wait_until_close
 mov ebx,eax
 call live_cleanup
 mov eax,ebx
 jmp .final_done
.final_cleanup_error:
 mov ebx,eax
 call live_cleanup
 mov eax,ebx
 jmp .final_done
.final_headless:
 xor eax,eax
 jmp .final_done
.final_bad:
 mov eax,NEBO_LIVE_STATUS_RENDER
.final_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; live_scan_roundtrip(initial_stack, context*, input_runtime*, route*, result*)
; drives the canonical input registry/focus/submission stack until Enter.
nebo_runtime_live_scan_roundtrip:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 mov r13,rsi
 mov r14,rdx
 mov rbx,rcx
 mov r15,r8
 test rbx,rbx
 jz .scan_bad
 test r15,r15
 jz .scan_bad
 mov rdi,r12
 call live_adapter_prepare
 test eax,eax
 jnz .scan_no_live
 mov rdi,r13
 mov rsi,[rbx+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
 lea rdx,[rel live_document]
 call nebo_console_domain_from_handle
 test eax,eax
 jnz .scan_bad
 mov rax,[rel live_document]
 mov rax,[rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
 test rax,rax
 jz .scan_bad
 mov [rel live_document],rax
 mov rdi,r14
 mov rsi,[rbx+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
 lea rdx,[rel live_input_registry]
 lea rcx,[rel live_pending_registry]
 call nebo_input_runtime_registry_for_console
 test eax,eax
 jnz .scan_bad
 call live_input_model_init
 test eax,eax
 jnz .scan_bad
 mov rdi,[rel live_document]
 mov rsi,[rel live_editor_ptr]
 call live_present_document
 test eax,eax
 jnz .scan_bad
.scan_loop:
 mov edi,NEBO_LIVE_EVENT_WAIT_MS
 call live_poll_normalized
 cmp eax,NEBO_PLATFORM_STATUS_NO_EVENT
 je .scan_loop
 test eax,eax
 jnz .scan_bad
 lea rdi,[rel live_event]
 call live_handle_event
 cmp eax,NEBO_LIVE_EVENT_CLOSE
 je .scan_cancel
 cmp eax,NEBO_LIVE_EVENT_ERROR
 je .scan_bad
 cmp eax,NEBO_LIVE_EVENT_CONSUMED
 je .scan_loop
 mov eax,[rel live_event+NEBO_CONSOLE_EVENT_KIND_OFFSET]
 cmp eax,NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
 je .scan_dispatch
 cmp eax,NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
 je .scan_dispatch
 cmp eax,NEBO_CONSOLE_EVENT_POINTER_DOWN
 jb .scan_loop
 cmp eax,NEBO_CONSOLE_EVENT_TEXT_INPUT
 ja .scan_loop
.scan_dispatch:
 lea rdi,[rel live_native_bridge]
 lea rsi,[rel live_event]
 mov rdx,r15
 call nebo_native_input_bridge_dispatch
 cmp eax,NEBO_CONSOLE_STATUS_NO_PROGRESS
 je .scan_loop
 test eax,eax
 jnz .scan_bad
 lea rdi,[rel live_editor_ptr]
 mov qword [rdi],0
 lea rdi,[rel live_focus_manager]
 lea rdx,[rel live_editor_ptr]
 call nebo_focus_manager_current_editor
 test eax,eax
 jz .scan_render
 mov qword [rel live_editor_ptr],0
.scan_render:
 mov rdi,[rel live_document]
 mov rsi,[rel live_editor_ptr]
 call live_present_document
 test eax,eax
 jnz .scan_bad
 cmp qword [r15+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET],0
 je .scan_loop
 xor eax,eax
 jmp .scan_done
.scan_cancel:
 mov rdi,r14
 mov rsi,rbx
 call nebo_console_scan_cancel
 mov [rsp],rax
 call live_cleanup
 test eax,eax
 jnz .scan_bad
 cmp qword [rsp],0
 jne .scan_bad
 mov eax,NEBO_LIVE_STATUS_CANCELLED
 jmp .scan_done
.scan_no_live:
 cmp eax,NEBO_LIVE_STATUS_HEADLESS
 jne .scan_done
 mov eax,NEBO_LIVE_STATUS_ENV
 jmp .scan_done
.scan_bad:
 mov eax,NEBO_LIVE_STATUS_INPUT
.scan_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Bind layout/focus/submission adapters to the already-routed canonical state.
live_input_model_init:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 lea rdi,[rel live_provider]
 call nebo_fake_glyph_provider_init
 test eax,eax
 jnz .done
 lea rdi,[rel live_layout]
 lea rsi,[rel live_layout_boxes]
 mov edx,NEBO_LIVE_LAYOUT_BOX_CAPACITY
 mov rcx,[rel live_render_width]
 shl rcx,NEBO_LAYOUT_FRACTION_BITS
 mov r8,[rel live_render_height]
 shl r8,NEBO_LAYOUT_FRACTION_BITS
 lea r9,[rel live_provider]
 call nebo_console_layout_init
 test eax,eax
 jnz .done
 lea rdi,[rel live_layout]
 mov rsi,[rel live_document]
 call nebo_console_layout_document
 test eax,eax
 jnz .done
 lea rax,[rel live_editors]
 mov [rel live_focus_storage+NEBO_FOCUS_STORAGE_EDITORS_PTR_OFFSET],rax
 mov qword [rel live_focus_storage+NEBO_FOCUS_STORAGE_EDITOR_CAPACITY_OFFSET],NEBO_LIVE_INPUT_CAPACITY
 lea rax,[rel live_editor_text]
 mov [rel live_focus_storage+NEBO_FOCUS_STORAGE_TEXT_PTR_OFFSET],rax
 mov qword [rel live_focus_storage+NEBO_FOCUS_STORAGE_TEXT_STRIDE_OFFSET],NEBO_LIVE_INPUT_TEXT_STRIDE
 lea rdi,[rel live_focus_manager]
 mov rsi,[rel live_input_registry]
 lea rdx,[rel live_layout]
 lea rcx,[rel live_focus_storage]
 call nebo_focus_manager_init
 test eax,eax
 jnz .done
 lea rdi,[rel live_focus_manager]
 call nebo_focus_manager_sync
 test eax,eax
 jnz .done
 lea rdi,[rel live_editor_ptr]
 mov qword [rdi],0
 lea rdi,[rel live_focus_manager]
 lea rdx,[rel live_editor_ptr]
 call nebo_focus_manager_current_editor
 test eax,eax
 jnz .done
 lea rdi,[rel live_dependency_bridge]
 lea rsi,[rel live_continuations]
 mov edx,NEBO_LIVE_INPUT_CAPACITY
 mov rcx,[rel live_document]
 mov rcx,[rcx+NEBO_CONSOLE_DOCUMENT_HANDLE_OFFSET]
 call nebo_dependency_bridge_init
 test eax,eax
 jnz .done
 lea rax,[rel live_submission_values]
 mov [rel live_submission_storage+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET],rax
 mov qword [rel live_submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET],NEBO_LIVE_INPUT_TEXT_STRIDE
 mov qword [rel live_submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET],NEBO_LIVE_INPUT_CAPACITY
 lea rdi,[rel live_submission_context]
 mov rsi,[rel live_input_registry]
 mov rdx,[rel live_pending_registry]
 lea rcx,[rel live_focus_manager]
 lea r8,[rel live_dependency_bridge]
 lea r9,[rel live_submission_storage]
 call nebo_input_submission_init
 test eax,eax
 jnz .done
 lea rdi,[rel live_native_bridge]
 lea rsi,[rel live_focus_manager]
 lea rdx,[rel live_submission_context]
 mov ecx,NEBO_PLATFORM_SCALE_ONE
 call nebo_native_input_bridge_init
 test eax,eax
 jnz .done
 mov qword [rel live_input_ready],1
.done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Render the canonical document and optional focused editor; create/map once.
live_present_document:
 push rbx
 push r12
 push r13
 push r14
 sub rsp,8
 mov r12,rdi
 mov r13,rsi
 call live_metadata_init
 lea rdi,[rel live_visual_config]
 call live_metadata_fill_config
 mov rdi,r12
 mov rsi,r13
 ; No-echo/security input is never sent to the renderer. Semantic validation
 ; still consumes the immutable native submission through the caller bridge.
 test qword [rel live_input_security],1|2|4|16|64
 jz .render_editor_ready
 xor esi,esi
.render_editor_ready:
 lea rdx,[rel live_surface]
 mov rcx,[rel live_surface_pixels]
 mov r8,[rel live_surface_capacity]
 lea r9,[rel live_visual_config]
 call nebo_runtime_live_visual_render
 test eax,eax
 jnz .present_done
 cmp qword [rel live_state],NEBO_LIVE_STATE_WINDOW
 je .present_pixels
 lea rdi,[rel live_window_config]
 xor eax,eax
 mov ecx,NEBO_X11_WINDOW_CONFIG_QWORDS
 cld
 rep stosq
 lea rax,[rel live_surface]
 mov [rel live_window_config+NEBO_X11_WINDOW_CONFIG_SURFACE_PTR_OFFSET],rax
 mov rax,[rel live_render_width]
 mov [rel live_window_config+NEBO_X11_WINDOW_CONFIG_WIDTH_OFFSET],rax
 mov rax,[rel live_render_height]
 mov [rel live_window_config+NEBO_X11_WINDOW_CONFIG_HEIGHT_OFFSET],rax
 mov qword [rel live_window_config+NEBO_X11_WINDOW_CONFIG_FLAGS_OFFSET],(NEBO_X11_WINDOW_CONFIG_REQUIRED_FLAGS | NEBO_X11_WINDOW_CONFIG_FLAG_DEFER_MAP)
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_window_config]
 call nebo_x11_adapter_create_window
 test eax,eax
 jnz .window_fail
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 mov edx,NEBO_CHROME_MIN_WINDOW_WIDTH_PX
 mov ecx,NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
 call nebo_x11_adapter_set_window_minimum_size
 test eax,eax
 jnz .window_fail
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 call nebo_x11_adapter_map_window
 test eax,eax
 jnz .window_fail
 call live_wait_mounted
 test eax,eax
 jnz .window_fail
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_title_storage]
 mov rcx,[rel live_title_length]
 call nebo_x11_adapter_set_window_title
 test eax,eax
 jnz .window_fail
 mov qword [rel live_state],NEBO_LIVE_STATE_WINDOW
.present_pixels:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_surface]
 lea rcx,[rel live_event]
 call nebo_x11_adapter_present
 cmp eax,NEBO_PLATFORM_STATUS_STALE_GEOMETRY
 je .present_stale
 test eax,eax
 jz .present_done
.window_fail:
 mov eax,NEBO_LIVE_STATUS_WINDOW
 jmp .present_done
.present_stale:
 xor eax,eax
.present_done:
 add rsp,8
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

live_wait_mounted:
 push r12
 mov r12d,100
.mount_loop:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 mov edx,NEBO_LIVE_EVENT_WAIT_MS
 lea rcx,[rel live_event]
 call nebo_x11_adapter_poll_event
 cmp eax,NEBO_PLATFORM_STATUS_NO_EVENT
 je .mount_next
 test eax,eax
 jnz .mount_fail
 cmp dword [rel live_event+NEBO_CONSOLE_EVENT_KIND_OFFSET],NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
 je .mount_ok
.mount_next:
 dec r12d
 jnz .mount_loop
.mount_fail:
 mov eax,NEBO_LIVE_STATUS_WINDOW
 jmp .mount_done
.mount_ok:
 xor eax,eax
.mount_done:
 pop r12
 ret

live_wait_until_close:
 push r12
.close_loop:
 mov edi,NEBO_LIVE_EVENT_WAIT_MS
 call live_poll_normalized
 cmp eax,NEBO_PLATFORM_STATUS_NO_EVENT
 je .close_loop
 test eax,eax
 jnz .close_fail
 lea rdi,[rel live_event]
 call live_handle_event
 cmp eax,NEBO_LIVE_EVENT_CLOSE
 je .close_ok
 cmp eax,NEBO_LIVE_EVENT_ERROR
 je .close_fail
 jmp .close_loop
.close_ok:
 xor eax,eax
 jmp .close_done
.close_fail:
 mov eax,NEBO_LIVE_STATUS_WINDOW
.close_done:
 pop r12
 ret

; Apply window lifecycle/chrome events before the input bridge. Chrome clicks
; are consumed so title controls can never become Scan input.
live_handle_event:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov r12,rdi
 mov ebx,[r12+NEBO_CONSOLE_EVENT_KIND_OFFSET]
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
 je .event_close
 cmp ebx,NEBO_CONSOLE_EVENT_PLATFORM_FAILURE
 je .event_error
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
 je .event_consumed
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
 je .event_geometry
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_RESTORED
 je .event_geometry
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_RESIZED
 je .event_geometry
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
 je .event_activated
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
 je .event_deactivated
 cmp ebx,NEBO_CONSOLE_EVENT_POINTER_MOVE
 je .event_pointer_move
 cmp ebx,NEBO_CONSOLE_EVENT_POINTER_DOWN
 je .event_pointer_down
 cmp ebx,NEBO_CONSOLE_EVENT_POINTER_UP
 je .event_pointer_up
 cmp ebx,NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
 je .event_consumed
 cmp ebx,NEBO_CONSOLE_EVENT_PRESENT_COMPLETE
 je .event_consumed
 jmp .event_pass
.event_geometry:
 call live_sync_geometry
 test eax,eax
 jnz .event_error
 jmp .event_consumed
.event_activated:
 or qword [rel live_window_flags],NEBO_CHROME_WINDOW_FLAG_ACTIVE
 cmp qword [rel live_input_ready],0
 je .event_focus_repaint
 lea rdi,[rel live_focus_manager]
 mov esi,1
 call nebo_focus_manager_set_window_active
 test eax,eax
 jnz .event_error
.event_focus_repaint:
 call live_repaint
 test eax,eax
 jnz .event_error
 jmp .event_pass
.event_deactivated:
 and qword [rel live_window_flags],~NEBO_CHROME_WINDOW_FLAG_ACTIVE
 cmp qword [rel live_input_ready],0
 je .event_blur_repaint
 lea rdi,[rel live_focus_manager]
 xor esi,esi
 call nebo_focus_manager_set_window_active
 test eax,eax
 jnz .event_error
.event_blur_repaint:
 call live_repaint
 test eax,eax
 jnz .event_error
 jmp .event_pass
.event_pointer_move:
 mov rdi,r12
 call live_pointer_motion_hit
 test eax,eax
 jnz .event_error
 call live_update_pointer_cursor
 test eax,eax
 jnz .event_error
 mov eax,[rel live_chrome_region]
 cmp eax,NEBO_CHROME_REGION_MINIMIZE
 je .event_hover_ready
 cmp eax,NEBO_CHROME_REGION_MAXIMIZE_RESTORE
 je .event_hover_ready
 cmp eax,NEBO_CHROME_REGION_CLOSE
 je .event_hover_ready
 xor eax,eax
.event_hover_ready:
 cmp rax,[rel live_hover_region]
 je .event_pointer_classify
 mov [rel live_hover_region],rax
 call live_repaint
 test eax,eax
 jnz .event_error
.event_pointer_classify:
 cmp dword [rel live_chrome_region],NEBO_CHROME_REGION_CONTENT
 je .event_pass
 jmp .event_consumed
.event_pointer_down:
 mov qword [rel live_chrome_press_active],0
 mov rdi,r12
 call live_pointer_hit
 test eax,eax
 jnz .event_error
 cmp dword [rel live_chrome_region],NEBO_CHROME_REGION_CONTENT
 je .event_pass
 mov eax,[r12+NEBO_CONSOLE_EVENT_PAYLOAD1_OFFSET]
 cmp eax,1
 jne .event_consumed
 mov qword [rel live_chrome_press_active],1
 call live_dispatch_chrome_action
 cmp eax,NEBO_LIVE_EVENT_CLOSE
 je .event_done
 cmp eax,NEBO_LIVE_EVENT_ERROR
 je .event_done
 jmp .event_consumed
.event_pointer_up:
 cmp qword [rel live_chrome_press_active],0
 je .event_pointer_up_uncaptured
 mov qword [rel live_chrome_press_active],0
 jmp .event_consumed
.event_pointer_up_uncaptured:
 mov rdi,r12
 call live_pointer_hit
 test eax,eax
 jnz .event_error
 cmp dword [rel live_chrome_region],NEBO_CHROME_REGION_CONTENT
 je .event_pass
 jmp .event_consumed
.event_close:
 mov eax,NEBO_LIVE_EVENT_CLOSE
 jmp .event_done
.event_error:
 mov eax,NEBO_LIVE_EVENT_ERROR
 jmp .event_done
.event_consumed:
 mov eax,NEBO_LIVE_EVENT_CONSUMED
 jmp .event_done
.event_pass:
 mov eax,NEBO_LIVE_EVENT_PASS
.event_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Decode the normalized 26.6 pointer position and use canonical hit-testing.
live_pointer_hit:
 push rbx
 mov rax,[rdi+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
 movsxd rdx,eax
 sar rdx,NEBO_PLATFORM_SCALE_FRACTION_BITS
 mov [rel live_pointer_x],rdx
 sar rax,32
 sar rax,NEBO_PLATFORM_SCALE_FRACTION_BITS
 mov [rel live_pointer_y],rax
 mov rcx,rax
 mov rdi,[rel live_render_width]
 mov rsi,[rel live_render_height]
 lea r8,[rel live_chrome_region]
 call nebo_console_chrome_hit_test
 pop rbx
 ret

; Motion uses a no-hit policy for valid signed X11 coordinates outside the
; current viewport during implicit-grab and WM geometry transitions.
live_pointer_motion_hit:
 push rbx
 mov rax,[rdi+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
 movsxd rdx,eax
 sar rdx,NEBO_PLATFORM_SCALE_FRACTION_BITS
 mov [rel live_pointer_x],rdx
 sar rax,32
 sar rax,NEBO_PLATFORM_SCALE_FRACTION_BITS
 mov [rel live_pointer_y],rax
 mov rcx,rax
 mov rdi,[rel live_render_width]
 mov rsi,[rel live_render_height]
 lea r8,[rel live_chrome_region]
 call nebo_console_chrome_motion_hit_test
 pop rbx
 ret

; Map canonical resize directions to four reusable adapter-owned cursors.
; Controls, title, content and outside motion always restore the default.
live_update_pointer_cursor:
 push rbx
 push r12
 push r13
 push r14
 push r15
 xor ebx,ebx
 cmp dword [rel live_chrome_region],NEBO_CHROME_REGION_RESIZE_BORDER
 jne .cursor_apply
 mov rdi,[rel live_render_width]
 mov rsi,[rel live_render_height]
 mov rdx,[rel live_pointer_x]
 mov rcx,[rel live_pointer_y]
 lea r8,[rel live_resize_direction_value]
 call nebo_console_chrome_resize_direction
 test eax,eax
 jnz .cursor_done
 mov eax,[rel live_resize_direction_value]
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_LEFT
 je .cursor_horizontal
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_RIGHT
 je .cursor_horizontal
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_TOP
 je .cursor_vertical
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_BOTTOM
 je .cursor_vertical
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_TOPLEFT
 je .cursor_nwse
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_BOTTOMRIGHT
 je .cursor_nwse
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_TOPRIGHT
 je .cursor_nesw
 cmp eax,NEBO_CHROME_RESIZE_DIRECTION_BOTTOMLEFT
 jne .cursor_invalid
.cursor_nesw:
 mov ebx,NEBO_X11_CURSOR_KIND_NESW
 jmp .cursor_apply
.cursor_nwse:
 mov ebx,NEBO_X11_CURSOR_KIND_NWSE
 jmp .cursor_apply
.cursor_vertical:
 mov ebx,NEBO_X11_CURSOR_KIND_VERTICAL
 jmp .cursor_apply
.cursor_horizontal:
 mov ebx,NEBO_X11_CURSOR_KIND_HORIZONTAL
.cursor_apply:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 mov edx,ebx
 call nebo_x11_adapter_set_resize_cursor
 jmp .cursor_done
.cursor_invalid:
 mov eax,NEBO_PLATFORM_STATUS_INVALID_ARGUMENT
.cursor_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Execute one real adapter action for a primary-button chrome press.
live_dispatch_chrome_action:
 push rbx
 push r12
 push r13
 push r14
 push r15
 mov edi,[rel live_chrome_region]
 xor esi,esi
 test dword [rel live_window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET],NEBO_X11_WINDOW_NATIVE_FLAG_MAXIMIZED
 jz .action_flags_ready
 or esi,NEBO_CHROME_WINDOW_FLAG_MAXIMIZED
.action_flags_ready:
 lea rdx,[rel live_chrome_action]
 call nebo_console_chrome_action_for_region
 test eax,eax
 jnz .action_consumed
 mov eax,[rel live_chrome_action]
 cmp eax,NEBO_CHROME_ACTION_MINIMIZE
 je .action_minimize
 cmp eax,NEBO_CHROME_ACTION_MAXIMIZE
 je .action_maximize
 cmp eax,NEBO_CHROME_ACTION_RESTORE
 je .action_restore
 cmp eax,NEBO_CHROME_ACTION_CLOSE
 je .action_close
 cmp eax,NEBO_CHROME_ACTION_BEGIN_DRAG
 je .action_drag
 cmp eax,NEBO_CHROME_ACTION_BEGIN_RESIZE
 je .action_resize
 jmp .action_consumed
.action_minimize:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 call nebo_x11_adapter_minimize_window
 jmp .action_consumed
.action_maximize:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 call nebo_x11_adapter_maximize_window
 jmp .action_consumed
.action_restore:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 call nebo_x11_adapter_restore_window
 jmp .action_consumed
.action_close:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_event]
 call nebo_x11_adapter_request_close
 test eax,eax
 jnz .action_consumed
 mov eax,NEBO_LIVE_EVENT_CLOSE
 jmp .action_done
.action_drag:
 mov rdx,[rel live_window+NEBO_X11_WINDOW_X_OFFSET]
 add rdx,[rel live_pointer_x]
 mov rcx,[rel live_window+NEBO_X11_WINDOW_Y_OFFSET]
 add rcx,[rel live_pointer_y]
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 mov r8d,1
 call nebo_x11_adapter_begin_window_drag
 test eax,eax
 jnz .action_error
 jmp .action_consumed
.action_resize:
 mov rdi,[rel live_render_width]
 mov rsi,[rel live_render_height]
 mov rdx,[rel live_pointer_x]
 mov rcx,[rel live_pointer_y]
 lea r8,[rel live_resize_direction_value]
 call nebo_console_chrome_resize_direction
 test eax,eax
 jnz .action_error
 mov r8d,[rel live_resize_direction_value]
 mov rdx,[rel live_window+NEBO_X11_WINDOW_X_OFFSET]
 add rdx,[rel live_pointer_x]
 mov rcx,[rel live_window+NEBO_X11_WINDOW_Y_OFFSET]
 add rcx,[rel live_pointer_y]
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 mov r9d,1
 call nebo_x11_adapter_begin_window_resize
 test eax,eax
 jnz .action_error
.action_consumed:
 mov eax,NEBO_LIVE_EVENT_CONSUMED
 jmp .action_done
.action_error:
 mov eax,NEBO_LIVE_EVENT_ERROR
.action_done:
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; Adopt adapter-owned ConfigureNotify geometry after validating it against the
; screen-sized mmap. The document and editor storage are never rebuilt.
live_sync_geometry:
 push rbx
 push r12
 push r13
 mov r12,[rel live_window+NEBO_X11_WINDOW_WIDTH_OFFSET]
 mov r13,[rel live_window+NEBO_X11_WINDOW_HEIGHT_OFFSET]
 cmp r12,NEBO_CHROME_MIN_WINDOW_WIDTH_PX
 jb .sync_bad
 cmp r13,NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
 jb .sync_bad
 cmp r12,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .sync_bad
 cmp r13,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .sync_bad
 mov rax,r12
 shl rax,2
 jc .sync_bad
 mul r13
 test rdx,rdx
 jnz .sync_bad
 cmp rax,[rel live_surface_capacity]
 ja .sync_bad
 mov [rel live_render_width],r12
 mov [rel live_render_height],r13
 cmp qword [rel live_input_ready],0
 je .sync_repaint
 call live_layout_resize
 test eax,eax
 jnz .sync_bad
.sync_repaint:
 call live_repaint
 test eax,eax
 jnz .sync_bad
 xor eax,eax
 jmp .sync_done
.sync_bad:
 mov eax,NEBO_LIVE_STATUS_RENDER
.sync_done:
 pop r13
 pop r12
 pop rbx
 ret

live_layout_resize:
 push rbx
 lea rdi,[rel live_layout]
 lea rsi,[rel live_layout_boxes]
 mov edx,NEBO_LIVE_LAYOUT_BOX_CAPACITY
 mov rcx,[rel live_render_width]
 shl rcx,NEBO_LAYOUT_FRACTION_BITS
 mov r8,[rel live_render_height]
 shl r8,NEBO_LAYOUT_FRACTION_BITS
 lea r9,[rel live_provider]
 call nebo_console_layout_init
 test eax,eax
 jnz .layout_resize_done
 lea rdi,[rel live_layout]
 mov rsi,[rel live_document]
 call nebo_console_layout_document
.layout_resize_done:
 pop rbx
 ret

live_repaint:
 push rbx
 mov rdi,[rel live_document]
 test rdi,rdi
 jz .repaint_ok
 mov rsi,[rel live_editor_ptr]
 call live_present_document
 pop rbx
 ret
.repaint_ok:
 xor eax,eax
 pop rbx
 ret

; Poll one normalized event while retaining Expose as a live repaint signal.
; The adapter intentionally hides raw Expose from its public normalized event
; enum; this frontend consumes it through the existing raw seam and presents
; the already-rendered canonical surface again. KeyPress may stage one Text
; event inside the adapter, so the next call drains that staged event first.
live_poll_normalized:
 push r12
 mov r12d,edi
 cmp qword [rel live_check_pending_text],0
 je .poll_raw
 mov qword [rel live_check_pending_text],0
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 xor edx,edx
 lea rcx,[rel live_event]
 call nebo_x11_adapter_poll_event
 cmp eax,NEBO_PLATFORM_STATUS_NO_EVENT
 jne .poll_done
.poll_raw:
 lea rdi,[rel live_adapter]
 mov rsi,r12
 lea rdx,[rel live_raw_event]
 call nebo_x11_adapter_poll_raw
 cmp eax,NEBO_PLATFORM_STATUS_NO_EVENT
 je .poll_done
 test eax,eax
 jnz .poll_done
 movzx eax,byte [rel live_raw_event]
 and eax,0x7f
 cmp eax,NEBO_X11_EVENT_EXPOSE
 je .poll_expose
 cmp eax,NEBO_X11_EVENT_KEY_PRESS
 jne .poll_normalize
 mov qword [rel live_check_pending_text],1
.poll_normalize:
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 lea rdx,[rel live_raw_event]
 lea rcx,[rel live_event]
 call nebo_x11_adapter_normalize_event
 jmp .poll_done
.poll_expose:
 cmp dword [rel live_window+NEBO_X11_WINDOW_STATE_OFFSET],NEBO_X11_WINDOW_STATE_MAPPED
 jne .poll_expose_consumed
 test dword [rel live_window+NEBO_X11_WINDOW_NATIVE_FLAGS_OFFSET],NEBO_X11_WINDOW_NATIVE_FLAG_MINIMIZED
 jnz .poll_expose_consumed
 call live_repaint
 test eax,eax
 jnz .poll_done
.poll_expose_consumed:
 mov eax,NEBO_PLATFORM_STATUS_NO_EVENT
.poll_done:
 pop r12
 ret

live_cleanup:
 push r12
 cmp qword [rel live_state],NEBO_LIVE_STATE_WINDOW
 jne .cleanup_adapter
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_window]
 call nebo_x11_adapter_destroy_window
.cleanup_adapter:
 cmp dword [rel live_adapter+NEBO_X11_ADAPTER_STATE_OFFSET],NEBO_PLATFORM_ADAPTER_STATE_READY
 jne .cleanup_done
 lea rdi,[rel live_adapter]
 call nebo_x11_adapter_shutdown
.cleanup_done:
 mov rdi,[rel live_surface_pixels]
 test rdi,rdi
 jz .cleanup_state
 mov rsi,[rel live_surface_capacity]
 mov eax,SYS_MUNMAP
 syscall
 mov qword [rel live_surface_pixels],0
 mov qword [rel live_surface_capacity],0
.cleanup_state:
 mov qword [rel live_input_ready],0
 mov qword [rel live_chrome_press_active],0
 mov qword [rel live_state],NEBO_LIVE_STATE_CLOSED
 xor eax,eax
 pop r12
 ret

; Allocate one screen-bounded software surface via Linux mmap. ConfigureNotify
; can then change the viewport without reallocating or exposing stale storage.
live_surface_allocate:
 push rbx
 cmp qword [rel live_surface_pixels],0
 jne .surface_allocate_ok
 movzx rbx,word [rel live_adapter+NEBO_X11_ADAPTER_SCREEN_WIDTH_OFFSET]
 movzx r10,word [rel live_adapter+NEBO_X11_ADAPTER_SCREEN_HEIGHT_OFFSET]
 cmp rbx,NEBO_CHROME_MIN_WINDOW_WIDTH_PX
 jb .surface_allocate_bad
 cmp r10,NEBO_CHROME_MIN_WINDOW_HEIGHT_PX
 jb .surface_allocate_bad
 cmp rbx,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .surface_allocate_bad
 cmp r10,NEBO_SURFACE_MAX_AXIS_PIXELS
 ja .surface_allocate_bad
 mov rax,rbx
 shl rax,2
 jc .surface_allocate_bad
 mul r10
 test rdx,rdx
 jnz .surface_allocate_bad
 cmp rax,NEBO_SURFACE_MAX_BYTES
 ja .surface_allocate_bad
 mov [rel live_surface_capacity],rax
 mov rsi,rax
 mov eax,SYS_MMAP
 xor edi,edi
 mov edx,PROT_READ_WRITE
 mov r10d,MAP_PRIVATE_ANONYMOUS
 mov r8,-1
 xor r9d,r9d
 syscall
 cmp rax,-4095
 jae .surface_allocate_fault
 mov [rel live_surface_pixels],rax
 cmp qword [rel live_render_width],rbx
 jbe .surface_height
 mov [rel live_render_width],rbx
.surface_height:
 movzx rbx,word [rel live_adapter+NEBO_X11_ADAPTER_SCREEN_HEIGHT_OFFSET]
 cmp qword [rel live_render_height],rbx
 jbe .surface_allocate_ok
 mov [rel live_render_height],rbx
.surface_allocate_ok:
 xor eax,eax
 jmp .surface_allocate_done
.surface_allocate_fault:
 mov qword [rel live_surface_capacity],0
.surface_allocate_bad:
 mov eax,NEBO_LIVE_STATUS_RENDER
.surface_allocate_done:
 pop rbx
 ret

; Prepare direct X11 from the process environment and Xauthority file.
live_adapter_prepare:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov r12,rdi
 call live_metadata_init
 cmp qword [rel live_state],NEBO_LIVE_STATE_READY
 je .adapter_ok
 cmp qword [rel live_state],NEBO_LIVE_STATE_WINDOW
 je .adapter_ok
 cmp qword [rel live_state],NEBO_LIVE_STATE_EMPTY
 jne .adapter_failed
 mov rdi,r12
 call live_resolve_environment
 test eax,eax
 jnz .adapter_done
 lea rdi,[rel live_x11_config]
 xor eax,eax
 mov ecx,NEBO_X11_CONFIG_QWORDS
 cld
 rep stosq
 lea rax,[rel live_socket_address]
 mov [rel live_x11_config+NEBO_X11_CONFIG_SOCKADDR_PTR_OFFSET],rax
 mov rax,[rel live_socket_address_length]
 mov [rel live_x11_config+NEBO_X11_CONFIG_SOCKADDR_LENGTH_OFFSET],rax
 lea rax,[rel live_auth_name]
 mov [rel live_x11_config+NEBO_X11_CONFIG_AUTH_NAME_PTR_OFFSET],rax
 mov qword [rel live_x11_config+NEBO_X11_CONFIG_AUTH_NAME_LENGTH_OFFSET],live_auth_name_len
 lea rax,[rel live_auth_cookie]
 mov [rel live_x11_config+NEBO_X11_CONFIG_AUTH_DATA_PTR_OFFSET],rax
 mov rax,[rel live_auth_cookie_length]
 mov [rel live_x11_config+NEBO_X11_CONFIG_AUTH_DATA_LENGTH_OFFSET],rax
 lea rax,[rel live_x11_scratch]
 mov [rel live_x11_config+NEBO_X11_CONFIG_SCRATCH_PTR_OFFSET],rax
 mov qword [rel live_x11_config+NEBO_X11_CONFIG_SCRATCH_CAPACITY_OFFSET],NEBO_LIVE_X11_SCRATCH_BYTES
 mov qword [rel live_x11_config+NEBO_X11_CONFIG_REQUIRED_CAPABILITIES_OFFSET],NEBO_LIVE_REQUIRED_CAPABILITIES
 mov qword [rel live_x11_config+NEBO_X11_CONFIG_FLAGS_OFFSET],NEBO_X11_CONFIG_REQUIRED_FLAGS
 lea rdi,[rel live_adapter]
 lea rsi,[rel live_x11_config]
 call nebo_x11_adapter_init
 test eax,eax
 jnz .adapter_failed
 call live_surface_allocate
 test eax,eax
 jz .adapter_surface_ok
 lea rdi,[rel live_adapter]
 call nebo_x11_adapter_shutdown
 jmp .adapter_failed
.adapter_surface_ok:
 mov qword [rel live_chrome_press_active],0
 mov qword [rel live_state],NEBO_LIVE_STATE_READY
.adapter_ok:
 xor eax,eax
 jmp .adapter_done
.adapter_failed:
 mov qword [rel live_state],NEBO_LIVE_STATE_FAILED
 mov eax,NEBO_LIVE_STATUS_ADAPTER
.adapter_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; initial_stack -> local socket/auth fields. Returns HEADLESS only when DISPLAY
; is absent/empty; every selected-live failure is an explicit error.
live_resolve_environment:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,32
 test rdi,rdi
 jz .env_headless
 mov r12,rdi
 mov qword [rel live_display_value],0
 mov qword [rel live_xauthority_value],0
 mov qword [rel live_home_value],0
 mov rax,[r12]
 cmp rax,4096
 ja .env_error
 lea r13,[r12+rax*8+16]
.env_loop:
 mov rbx,[r13]
 test rbx,rbx
 jz .env_ready
 mov rdi,rbx
 lea rsi,[rel live_env_display]
 mov edx,live_env_display_len
 call live_env_match
 test rax,rax
 jz .env_xauth
 mov [rel live_display_value],rax
.env_xauth:
 mov rdi,rbx
 lea rsi,[rel live_env_xauthority]
 mov edx,live_env_xauthority_len
 call live_env_match
 test rax,rax
 jz .env_home
 mov [rel live_xauthority_value],rax
.env_home:
 mov rdi,rbx
 lea rsi,[rel live_env_home]
 mov edx,live_env_home_len
 call live_env_match
 test rax,rax
 jz .env_next
 mov [rel live_home_value],rax
.env_next:
 add r13,8
 jmp .env_loop
.env_ready:
 mov rdi,[rel live_display_value]
 test rdi,rdi
 jz .env_headless
 cmp byte [rdi],0
 je .env_headless
 call live_parse_display
 test eax,eax
 jnz .env_error
 call live_resolve_xauthority_path
 test eax,eax
 jnz .env_error
 call live_read_xauthority
 test eax,eax
 jnz .env_error
 call live_parse_xauthority
 test eax,eax
 jnz .env_auth
 xor eax,eax
 jmp .env_done
.env_headless:
 mov eax,NEBO_LIVE_STATUS_HEADLESS
 jmp .env_done
.env_auth:
 mov eax,NEBO_LIVE_STATUS_AUTH
 jmp .env_done
.env_error:
 mov eax,NEBO_LIVE_STATUS_ENV
.env_done:
 add rsp,32
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; env string, prefix, length -> value pointer or zero.
live_env_match:
 xor ecx,ecx
.match_loop:
 cmp ecx,edx
 jae .match_yes
 mov al,[rdi+rcx]
 cmp al,[rsi+rcx]
 jne .match_no
 inc ecx
 jmp .match_loop
.match_yes:
 lea rax,[rdi+rdx]
 ret
.match_no:
 xor eax,eax
 ret

live_parse_display:
 push rbx
 push r12
 sub rsp,8
 mov r12,rdi
 mov rdi,r12
 lea rsi,[rel live_unix_prefix]
 mov edx,live_unix_prefix_len
 call live_env_match
 test rax,rax
 jz .display_localhost
 mov r12,rax
.display_localhost:
 mov rdi,r12
 lea rsi,[rel live_localhost_prefix]
 mov edx,live_localhost_prefix_len
 call live_env_match
 test rax,rax
 jz .display_colon
 mov r12,rax
.display_colon:
 cmp byte [r12],':'
 jne .display_bad
 inc r12
 xor ebx,ebx
.display_digits:
 mov al,[r12+rbx]
 cmp al,'0'
 jb .display_end_digits
 cmp al,'9'
 ja .display_end_digits
 cmp ebx,3
 jae .display_bad
 lea rdx,[rel live_display_number]
 mov [rdx+rbx],al
 inc ebx
 jmp .display_digits
.display_end_digits:
 test ebx,ebx
 jz .display_bad
 cmp al,0
 je .display_build
 cmp al,'.'
 jne .display_bad
 inc rbx
.display_screen:
 mov al,[r12+rbx]
 test al,al
 jz .display_build
 cmp al,'0'
 jb .display_bad
 cmp al,'9'
 ja .display_bad
 inc rbx
 jmp .display_screen
.display_build:
 ; Recompute display-number length independently of optional screen digits.
 xor ecx,ecx
.display_number_len:
 cmp ecx,3
 jae .display_number_ready
 lea rdx,[rel live_display_number]
 cmp byte [rdx+rcx],0
 je .display_number_ready
 inc ecx
 jmp .display_number_len
.display_number_ready:
 mov [rel live_display_number_length],rcx
 lea rdi,[rel live_socket_address]
 xor eax,eax
 mov edx,NEBO_X11_MAX_SOCKET_ADDRESS_BYTES
 mov rcx,rdx
 cld
 rep stosb
 mov word [rel live_socket_address],NEBO_LINUX_AF_UNIX
 lea rdi,[rel live_socket_address+2]
 lea rsi,[rel live_socket_prefix]
 mov ecx,live_socket_prefix_len
 cld
 rep movsb
 lea rsi,[rel live_display_number]
 mov rcx,[rel live_display_number_length]
 cld
 rep movsb
 mov byte [rdi],0
 mov rax,[rel live_display_number_length]
 add rax,live_socket_prefix_len+3
 mov [rel live_socket_address_length],rax
 xor eax,eax
 jmp .display_done
.display_bad:
 mov eax,NEBO_LIVE_STATUS_ENV
.display_done:
 add rsp,8
 pop r12
 pop rbx
 ret

live_resolve_xauthority_path:
 mov rax,[rel live_xauthority_value]
 test rax,rax
 jnz .path_existing
 mov rsi,[rel live_home_value]
 test rsi,rsi
 jz .path_bad
 lea rdi,[rel live_xauthority_path]
 xor ecx,ecx
.path_home:
 cmp ecx,NEBO_LIVE_XAUTH_PATH_BYTES-live_xauthority_suffix_len
 jae .path_bad
 mov al,[rsi+rcx]
 test al,al
 jz .path_suffix
 mov [rdi+rcx],al
 inc ecx
 jmp .path_home
.path_suffix:
 lea rsi,[rel live_xauthority_suffix]
 mov edx,live_xauthority_suffix_len
.path_suffix_loop:
 test edx,edx
 jz .path_built
 mov al,[rsi]
 mov [rdi+rcx],al
 inc rsi
 inc ecx
 dec edx
 jmp .path_suffix_loop
.path_built:
 lea rax,[rel live_xauthority_path]
.path_existing:
 mov [rel live_xauthority_value],rax
 xor eax,eax
 ret
.path_bad:
 mov eax,NEBO_LIVE_STATUS_ENV
 ret

live_read_xauthority:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,16
 mov eax,SYS_OPENAT
 mov edi,AT_FDCWD
 mov rsi,[rel live_xauthority_value]
 xor edx,edx
 xor r10d,r10d
 syscall
 test rax,rax
 js .read_bad
 mov ebx,eax
 xor r12d,r12d
.read_loop:
 cmp r12,NEBO_LIVE_XAUTH_BYTES
 jae .read_close_bad
 mov eax,SYS_READ
 mov edi,ebx
 lea rsi,[rel live_xauth_file]
 add rsi,r12
 mov edx,NEBO_LIVE_XAUTH_BYTES
 sub rdx,r12
 syscall
 test rax,rax
 js .read_retry
 test rax,rax
 jz .read_close_ok
 add r12,rax
 jmp .read_loop
.read_retry:
 cmp rax,-4
 je .read_loop
 jmp .read_close_bad
.read_close_ok:
 mov eax,SYS_CLOSE
 mov edi,ebx
 syscall
 test r12,r12
 jz .read_bad
 mov [rel live_xauth_length],r12
 xor eax,eax
 jmp .read_done
.read_close_bad:
 mov eax,SYS_CLOSE
 mov edi,ebx
 syscall
.read_bad:
 mov eax,NEBO_LIVE_STATUS_AUTH
.read_done:
 add rsp,16
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

live_parse_xauthority:
 push rbx
 push r12
 push r13
 push r14
 push r15
 sub rsp,64
 lea r12,[rel live_xauth_file]
 mov r13,[rel live_xauth_length]
 add r13,r12
 mov r15d,3
 mov qword [rel live_auth_cookie_length],0
.record_loop:
 cmp r12,r13
 jae .records_done
 lea rax,[r12+2]
 cmp rax,r13
 ja .records_bad
 movzx ebx,word [r12]
 xchg bl,bh
 add r12,2
 mov rdi,r12
 mov rsi,r13
 call live_xauth_field
 test rax,rax
 jz .records_bad
 mov r12,rax
 mov rdi,r12
 mov rsi,r13
 call live_xauth_field
 test rax,rax
 jz .records_bad
 mov [rsp],rdx
 mov [rsp+8],rcx
 mov r12,rax
 mov rdi,r12
 mov rsi,r13
 call live_xauth_field
 test rax,rax
 jz .records_bad
 mov [rsp+16],rdx
 mov [rsp+24],rcx
 mov r12,rax
 mov rdi,r12
 mov rsi,r13
 call live_xauth_field
 test rax,rax
 jz .records_bad
 mov [rsp+32],rdx
 mov [rsp+40],rcx
 mov r12,rax
 cmp ebx,FAMILY_LOCAL
 je .rank_local
 cmp ebx,FAMILY_WILD
 jne .record_loop
 mov r14d,2
 jmp .rank_ready
.rank_local:
 mov r14d,1
.rank_ready:
 cmp r14d,r15d
 jae .record_loop
 mov rax,[rsp+8]
 cmp rax,[rel live_display_number_length]
 jne .record_loop
 mov rdi,[rsp]
 lea rsi,[rel live_display_number]
 mov rcx,rax
 cld
 repe cmpsb
 jne .record_loop
 cmp qword [rsp+24],live_auth_name_len
 jne .record_loop
 mov rdi,[rsp+16]
 lea rsi,[rel live_auth_name]
 mov ecx,live_auth_name_len
 cld
 repe cmpsb
 jne .record_loop
 mov rcx,[rsp+40]
 test rcx,rcx
 jz .record_loop
 cmp rcx,NEBO_X11_MAX_AUTH_BYTES
 ja .records_bad
 lea rdi,[rel live_auth_cookie]
 mov rsi,[rsp+32]
 cld
 rep movsb
 mov rax,[rsp+40]
 mov [rel live_auth_cookie_length],rax
 mov r15d,r14d
 jmp .record_loop
.records_done:
 cmp qword [rel live_auth_cookie_length],0
 je .records_bad
 xor eax,eax
 jmp .records_exit
.records_bad:
 mov eax,NEBO_LIVE_STATUS_AUTH
.records_exit:
 add rsp,64
 pop r15
 pop r14
 pop r13
 pop r12
 pop rbx
 ret

; RDI=cursor, RSI=end -> RAX=next, RDX=data, RCX=length; zero on fault.
live_xauth_field:
 lea rax,[rdi+2]
 cmp rax,rsi
 ja .field_bad
 movzx ecx,word [rdi]
 xchg cl,ch
 lea rdx,[rdi+2]
 lea rax,[rdx+rcx]
 cmp rax,rsi
 ja .field_bad
 ret
.field_bad:
 xor eax,eax
 ret

section .note.GNU-stack noalloc noexec nowrite progbits
