; Nebo headless output conformance: styles, controls and visual state — MF045
bits 64
default rel

%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/output_conformance.inc"

extern nebo_console_document_validate
extern nebo_console_document_node_from_id
extern nebo_console_render_tree_validate
extern nebo_console_render_tree_state_hash
extern nebo_console_renderer_registry_lookup
extern nebo_console_behavior_store_lookup
extern nebo_console_behavior_set_validate
extern nebo_draw_command_buffer_validate
extern nebo_draw_command_buffer_append
extern nebo_draw_command_buffer_state_hash
extern nebo_console_layout_validate

global nebo_console_visual_state_init
global nebo_console_visual_state_validate
global nebo_console_visual_state_hash
global nebo_console_output_apply_styles
global nebo_console_output_append_chrome_controls
global nebo_console_output_append_visual_state
global nebo_console_output_state_hash

section .text

nebo_console_visual_state_hash:
    push rbx
    test rdi, rdi
    jz .visual_hash_invalid
    test rsi, rsi
    jz .visual_hash_invalid
    mov eax, NEBO_OUTPUT_HASH_FNV1A32_OFFSET_BASIS
    xor edx, edx
.visual_hash_field:
    cmp edx, NEBO_OUTPUT_VISUAL_STATE_HASH_OFFSET
    jae .visual_hash_done
    mov rbx, [rdi+rdx]
    mov ecx, 8
.visual_hash_bytes:
    xor al, bl
    imul rax, rax, NEBO_OUTPUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .visual_hash_bytes
    add edx, 8
    jmp .visual_hash_field
.visual_hash_done:
    mov [rdi+NEBO_OUTPUT_VISUAL_STATE_HASH_OFFSET], rax
    mov [rsi], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    pop rbx
    ret
.visual_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    pop rbx
    ret

; visual_state_init(state*, flags, focused_node, input_node, geometry*)
; Geometry points to 8 qwords: caret x/y/w/h, input x/y/w/h.
nebo_console_visual_state_init:
    push r12
    push r13
    sub rsp, 8
    mov r12, rdi
    mov r13, r8
    test r12, r12
    jz .visual_init_invalid
    test r13, r13
    jz .visual_init_invalid
    push rsi
    push rdx
    push rcx
    push rdi
    xor eax, eax
    mov ecx, NEBO_OUTPUT_VISUAL_STATE_QWORDS
    cld
    rep stosq
    pop rdi
    pop rcx
    pop rdx
    pop rsi
    test esi, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    jz .visual_init_invalid
    mov [r12+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET], rsi
    mov [r12+NEBO_OUTPUT_VISUAL_FOCUSED_NODE_ID_OFFSET], rdx
    mov [r12+NEBO_OUTPUT_VISUAL_INPUT_NODE_ID_OFFSET], rcx
    mov rax, [r13]
    mov [r12+NEBO_OUTPUT_VISUAL_CARET_X_OFFSET], rax
    mov rax, [r13+8]
    mov [r12+NEBO_OUTPUT_VISUAL_CARET_Y_OFFSET], rax
    mov rax, [r13+16]
    mov [r12+NEBO_OUTPUT_VISUAL_CARET_WIDTH_OFFSET], rax
    mov rax, [r13+24]
    mov [r12+NEBO_OUTPUT_VISUAL_CARET_HEIGHT_OFFSET], rax
    mov rax, [r13+32]
    mov [r12+NEBO_OUTPUT_VISUAL_INPUT_X_OFFSET], rax
    mov rax, [r13+40]
    mov [r12+NEBO_OUTPUT_VISUAL_INPUT_Y_OFFSET], rax
    mov rax, [r13+48]
    mov [r12+NEBO_OUTPUT_VISUAL_INPUT_WIDTH_OFFSET], rax
    mov rax, [r13+56]
    mov [r12+NEBO_OUTPUT_VISUAL_INPUT_HEIGHT_OFFSET], rax
    mov rdi, r12
    lea rsi, [r12+NEBO_OUTPUT_VISUAL_STATE_HASH_OFFSET]
    call nebo_console_visual_state_hash
    jmp .visual_init_done
.visual_init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.visual_init_done:
    add rsp, 8
    pop r13
    pop r12
    ret

nebo_console_visual_state_validate:
    test rdi, rdi
    jz .visual_validate_invalid
    mov rax, [rdi+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET]
    test eax, NEBO_OUTPUT_VISUAL_FLAG_INITIALIZED
    jz .visual_validate_state
    test eax, NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT
    jz .visual_validate_no_input
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_INPUT_NODE_ID_OFFSET], 0
    je .visual_validate_state
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_INPUT_WIDTH_OFFSET], 0
    jle .visual_validate_state
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_INPUT_HEIGHT_OFFSET], 0
    jle .visual_validate_state
.visual_validate_no_input:
    test eax, NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    jz .visual_validate_ok
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_FOCUSED_NODE_ID_OFFSET], 0
    je .visual_validate_state
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_CARET_WIDTH_OFFSET], 0
    jle .visual_validate_state
    cmp qword [rdi+NEBO_OUTPUT_VISUAL_CARET_HEIGHT_OFFSET], 0
    jle .visual_validate_state
.visual_validate_ok:
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.visual_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.visual_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; apply_styles(render_tree*, document*, renderer_registry*, behavior_store*)
nebo_console_output_apply_styles:
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
    call nebo_console_render_tree_validate
    test eax, eax
    jnz .styles_done
    mov rdi, r13
    call nebo_console_document_validate
    test eax, eax
    jnz .styles_state
    xor ebx, ebx
.styles_loop:
    cmp rbx, [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    jae .styles_success
    mov rax, rbx
    imul rax, NEBO_RENDER_NODE_SIZE
    add rax, [r12+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
    mov [rsp], rax
    mov rsi, [rax+NEBO_RENDER_NODE_DOCUMENT_NODE_ID_OFFSET]
    test rsi, rsi
    jz .styles_state
    mov rdi, r13
    lea rdx, [rsp+8]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz .styles_state
    mov rax, [rsp+8]
    mov esi, [rax+NEBO_CONSOLE_NODE_KIND_OFFSET]
    mov rdi, r14
    lea rdx, [rsp+16]
    call nebo_console_renderer_registry_lookup
    test eax, eax
    jnz .styles_renderer_missing
    mov rax, [rsp]
    mov edx, NEBO_COLOR_BGRA_WHITE
    mov [rax+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rdx
    mov rcx, [rsp+8]
    mov rsi, [rcx+NEBO_CONSOLE_NODE_BEHAVIOR_SET_ID_OFFSET]
    test rsi, rsi
    jz .styles_next
    mov rdi, r15
    lea rdx, [rsp+24]
    call nebo_console_behavior_store_lookup
    test eax, eax
    jnz .styles_behavior_missing
    mov rdi, [rsp+24]
    call nebo_console_behavior_set_validate
    test eax, eax
    jnz .styles_behavior_missing
    mov rax, [rsp]
    mov rcx, [rsp+24]
    mov rdx, [rcx+NEBO_BEHAVIOR_SET_FOREGROUND_COLOR_OFFSET]
    test rdx, rdx
    jz .styles_behavior_missing
    mov [rax+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rdx
.styles_next:
    inc rbx
    jmp .styles_loop
.styles_success:
    mov rdi, r12
    lea rsi, [r12+NEBO_RENDER_TREE_STATE_HASH_OFFSET]
    call nebo_console_render_tree_state_hash
    jmp .styles_done
.styles_renderer_missing:
.styles_behavior_missing:
.styles_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.styles_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; append_chrome_controls(draw_buffer*, layout*) -> status
nebo_console_output_append_chrome_controls:
    push rbx
    push r12
    push r13
    sub rsp, NEBO_DRAW_COMMAND_SIZE
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_draw_command_buffer_validate
    test eax, eax
    jnz .controls_done
    mov rdi, r13
    call nebo_console_layout_validate
    test eax, eax
    jnz .controls_state
    xor ebx, ebx
.controls_loop:
    cmp ebx, NEBO_OUTPUT_CONTROL_COUNT
    jae .controls_success
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov rax, [r13+NEBO_LAYOUT_TREE_VIEWPORT_WIDTH_OFFSET]
    sub rax, NEBO_LAYOUT_BORDER
    sub rax, NEBO_OUTPUT_CONTROL_GAP
    mov rcx, rbx
    inc rcx
    imul rcx, NEBO_OUTPUT_CONTROL_SIZE + NEBO_OUTPUT_CONTROL_GAP
    sub rax, rcx
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov qword [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], NEBO_OUTPUT_CONTROL_TOP
    mov qword [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], NEBO_OUTPUT_CONTROL_SIZE
    mov qword [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], NEBO_OUTPUT_CONTROL_SIZE
    mov eax, NEBO_COLOR_BGRA_CHROME_FOREGROUND
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov qword [rsp+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], 0
    mov rax, rbx
    inc rax
    mov [rsp+NEBO_DRAW_COMMAND_CLIP_ID_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_command_buffer_append
    test eax, eax
    jnz .controls_done
    inc ebx
    jmp .controls_loop
.controls_success:
    mov rdi, r12
    lea rsi, [r12+NEBO_DRAW_BUFFER_STATE_HASH_OFFSET]
    call nebo_draw_command_buffer_state_hash
    jmp .controls_done
.controls_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.controls_done:
    add rsp, NEBO_DRAW_COMMAND_SIZE
    pop r13
    pop r12
    pop rbx
    ret

; append_visual_state(draw_buffer*, visual_state*) -> status
nebo_console_output_append_visual_state:
    push r12
    push r13
    sub rsp, NEBO_DRAW_COMMAND_SIZE + 8
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_draw_command_buffer_validate
    test eax, eax
    jnz .visual_commands_done
    mov rdi, r13
    call nebo_console_visual_state_validate
    test eax, eax
    jnz .visual_commands_state
    mov rax, [r13+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET]
    test eax, NEBO_OUTPUT_VISUAL_FLAG_INPUT_PRESENT
    jz .visual_commands_caret
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_FILL_RECT
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS | NEBO_DRAW_COMMAND_FLAG_OPAQUE
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_INPUT_BACKGROUND
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_NODE_ID_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_command_buffer_append
    test eax, eax
    jnz .visual_commands_done

    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov rdx, [r13+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET]
    test edx, NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    jz .visual_border_unfocused
    mov eax, NEBO_COLOR_BGRA_INPUT_FOCUS
    jmp .visual_border_ready
.visual_border_unfocused:
    mov eax, NEBO_COLOR_BGRA_INPUT_BORDER
.visual_border_ready:
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_INPUT_NODE_ID_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_command_buffer_append
    test eax, eax
    jnz .visual_commands_done
.visual_commands_caret:
    mov rax, [r13+NEBO_OUTPUT_VISUAL_FLAGS_OFFSET]
    test eax, NEBO_OUTPUT_VISUAL_FLAG_FOCUSED
    jz .visual_commands_success
    test eax, NEBO_OUTPUT_VISUAL_FLAG_INPUT_RESOLVED
    jnz .visual_commands_success
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_CARET
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov rax, [r13+NEBO_OUTPUT_VISUAL_CARET_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_CARET_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_CARET_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_CARET_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_CARET
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rax, [r13+NEBO_OUTPUT_VISUAL_FOCUSED_NODE_ID_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_command_buffer_append
    test eax, eax
    jnz .visual_commands_done
.visual_commands_success:
    mov rdi, r12
    lea rsi, [r12+NEBO_DRAW_BUFFER_STATE_HASH_OFFSET]
    call nebo_draw_command_buffer_state_hash
    jmp .visual_commands_done
.visual_commands_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.visual_commands_done:
    add rsp, NEBO_DRAW_COMMAND_SIZE + 8
    pop r13
    pop r12
    ret

; output_state_hash(draw_buffer*, surface_hash, visual_hash, out*) -> status
nebo_console_output_state_hash:
    push rbx
    test rdi, rdi
    jz .output_hash_invalid
    test rcx, rcx
    jz .output_hash_invalid
    mov eax, NEBO_OUTPUT_HASH_FNV1A32_OFFSET_BASIS
    mov rbx, [rdi+NEBO_DRAW_BUFFER_STATE_HASH_OFFSET]
    mov r8d, 8
.output_hash_draw:
    xor al, bl
    imul rax, rax, NEBO_OUTPUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec r8d
    jnz .output_hash_draw
    mov rbx, rsi
    mov r8d, 8
.output_hash_surface:
    xor al, bl
    imul rax, rax, NEBO_OUTPUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec r8d
    jnz .output_hash_surface
    mov rbx, rdx
    mov r8d, 8
.output_hash_visual:
    xor al, bl
    imul rax, rax, NEBO_OUTPUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec r8d
    jnz .output_hash_visual
    mov [rcx], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    pop rbx
    ret
.output_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
