; Nebo deterministic DrawCommandBuffer — MF044
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/render_tree.inc"
%include "runtime/console/render/draw_command.inc"

extern nebo_console_layout_validate
extern nebo_console_render_tree_validate

global nebo_draw_command_buffer_init
global nebo_draw_command_buffer_validate
global nebo_draw_command_buffer_append
global nebo_console_draw_commands_build
global nebo_draw_command_buffer_state_hash

section .text

nebo_draw_set_failure_internal:
    test rdi, rdi
    jz .failure_return
    mov [rdi+NEBO_DRAW_BUFFER_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_DRAW_BUFFER_LAST_ERROR_OFFSET], rdx
.failure_return:
    mov eax, esi
    ret

; append command copied from template. RDI=buffer*, RSI=template*.
nebo_draw_append_internal:
    mov rax, [rdi+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    cmp rax, [rdi+NEBO_DRAW_BUFFER_CAPACITY_OFFSET]
    jae .append_limit
    cmp rax, NEBO_DRAW_MAX_COMMANDS_PER_FRAME
    jae .append_limit
    mov rdx, rax
    imul rdx, NEBO_DRAW_COMMAND_SIZE
    add rdx, [rdi+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
    push rdi
    push rsi
    mov rdi, rdx
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep movsq
    pop rsi
    pop rdi
    mov rax, [rdi+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    mov rdx, rax
    imul rdx, NEBO_DRAW_COMMAND_SIZE
    add rdx, [rdi+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
    mov [rdx+NEBO_DRAW_COMMAND_ORDER_OFFSET], rax
    inc qword [rdi+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.append_limit:
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_DRAW_ERROR_COMMAND_LIMIT
    jmp nebo_draw_set_failure_internal

; Public bounded append used by MF045 conformance decoration.
nebo_draw_command_buffer_append:
    jmp nebo_draw_append_internal

; init(buffer*, commands*, capacity, document*) -> status
nebo_draw_command_buffer_init:
    test rdi, rdi
    jz .init_invalid_no_buffer
    push rdi
    mov r8, rsi
    mov r9, rdx
    mov r10, rcx
    xor eax, eax
    mov ecx, NEBO_DRAW_BUFFER_QWORDS
    cld
    rep stosq
    pop rdi
    test r8, r8
    jz .init_invalid
    test r10, r10
    jz .init_invalid
    test r9, r9
    jz .init_limit
    cmp r9, NEBO_DRAW_MAX_COMMANDS_PER_FRAME
    ja .init_limit
    mov [rdi+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET], r8
    mov [rdi+NEBO_DRAW_BUFFER_CAPACITY_OFFSET], r9
    mov [rdi+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET], r10
    mov qword [rdi+NEBO_DRAW_BUFFER_FLAGS_OFFSET], NEBO_DRAW_BUFFER_REQUIRED_FLAGS
    mov qword [rdi+NEBO_DRAW_BUFFER_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [rdi+NEBO_DRAW_BUFFER_LAST_ERROR_OFFSET], NEBO_DRAW_ERROR_NONE
    mov eax, NEBO_DRAW_HASH_FNV1A32_OFFSET_BASIS
    mov [rdi+NEBO_DRAW_BUFFER_STATE_HASH_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.init_limit:
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_DRAW_ERROR_COMMAND_LIMIT
    jmp nebo_draw_set_failure_internal
.init_invalid:
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_DRAW_ERROR_BAD_ARGUMENT
    jmp nebo_draw_set_failure_internal
.init_invalid_no_buffer:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_draw_command_buffer_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET], 0
    je .validate_state
    cmp qword [rdi+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET], 0
    je .validate_state
    mov rax, [rdi+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    cmp rax, [rdi+NEBO_DRAW_BUFFER_CAPACITY_OFFSET]
    ja .validate_state
    mov rax, [rdi+NEBO_DRAW_BUFFER_FLAGS_OFFSET]
    and eax, NEBO_DRAW_BUFFER_REQUIRED_FLAGS
    cmp eax, NEBO_DRAW_BUFFER_REQUIRED_FLAGS
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; build(buffer*, layout*, render_tree*) -> status
nebo_console_draw_commands_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, NEBO_DRAW_COMMAND_SIZE
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_draw_command_buffer_validate
    test eax, eax
    jnz .build_done
    mov rdi, r13
    call nebo_console_layout_validate
    test eax, eax
    jnz .build_layout
    mov rdi, r14
    call nebo_console_render_tree_validate
    test eax, eax
    jnz .build_render
    mov rax, [r13+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET]
    cmp rax, [r14+NEBO_RENDER_TREE_LAYOUT_REVISION_OFFSET]
    jne .build_render
    mov rax, [r13+NEBO_LAYOUT_TREE_DOCUMENT_PTR_OFFSET]
    cmp rax, [r12+NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET]
    jne .build_layout
    mov rax, [r14+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    add rax, 5
    cmp rax, [r12+NEBO_DRAW_BUFFER_CAPACITY_OFFSET]
    ja .build_limit
    mov qword [r12+NEBO_DRAW_BUFFER_COUNT_OFFSET], 0
    mov rax, [r13+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET]
    mov [r12+NEBO_DRAW_BUFFER_LAYOUT_REVISION_OFFSET], rax
    mov rax, [r14+NEBO_RENDER_TREE_DOCUMENT_REVISION_OFFSET]
    mov [r12+NEBO_DRAW_BUFFER_RENDER_REVISION_OFFSET], rax

    ; CLEAR black.
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_CLEAR
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS | NEBO_DRAW_COMMAND_FLAG_OPAQUE
    mov rax, [r13+NEBO_LAYOUT_TREE_VIEWPORT_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_LAYOUT_TREE_VIEWPORT_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_BLACK
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done

    ; FILL_RECT chrome.
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_FILL_RECT
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS | NEBO_DRAW_COMMAND_FLAG_OPAQUE
    mov rbx, [r13+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    mov rax, [rbx+NEBO_LAYOUT_BOX_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_CHROME_BACKGROUND
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done

    ; STROKE_RECT whole Console border.
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_STROKE_RECT
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS | NEBO_DRAW_COMMAND_FLAG_OPAQUE
    mov rax, [r13+NEBO_LAYOUT_TREE_VIEWPORT_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_LAYOUT_TREE_VIEWPORT_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_GREY
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done

    ; PUSH_CLIP content.
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_PUSH_CLIP
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    lea rbx, [rbx+NEBO_LAYOUT_BOX_SIZE]
    mov rax, [rbx+NEBO_LAYOUT_BOX_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov qword [rsp+NEBO_DRAW_COMMAND_CLIP_ID_OFFSET], 2
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done

    xor r15d, r15d
.build_node_loop:
    cmp r15, [r14+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    jae .build_pop_clip
    mov rax, r15
    imul rax, NEBO_RENDER_NODE_SIZE
    add rax, [r14+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
    mov rbx, rax
    mov rax, [rbx+NEBO_RENDER_NODE_LAYOUT_BOX_ID_OFFSET]
    dec rax
    imul rax, NEBO_LAYOUT_BOX_SIZE
    add rax, [r13+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    mov r10, rax
    test dword [rbx+NEBO_RENDER_NODE_FLAGS_OFFSET], NEBO_RENDER_NODE_FLAG_EXPLICIT_BACKGROUND
    jz .build_glyph_command
    push r10
    sub rsp, 8
    lea rdi, [rsp+16]
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+16+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_FILL_RECT
    mov dword [rsp+16+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov rax, [r10+NEBO_LAYOUT_BOX_X_OFFSET]
    mov [rsp+16+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov [rsp+16+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    mov [rsp+16+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    mov [rsp+16+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_BACKGROUND_OFFSET]
    mov [rsp+16+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rdi, r12
    lea rsi, [rsp+16]
    call nebo_draw_append_internal
    add rsp, 8
    pop r10
    test eax, eax
    jnz .build_done
.build_glyph_command:
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_DRAW_GLYPH_RUN
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov rax, [r10+NEBO_LAYOUT_BOX_X_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_X_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_Y_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_Y_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_WIDTH_OFFSET], rax
    mov rax, [r10+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_HEIGHT_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_FOREGROUND_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_COLOR_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_DOCUMENT_NODE_ID_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_NODE_ID_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_SOURCE_OFFSET_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_SOURCE_OFFSET_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_SOURCE_LENGTH_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_SOURCE_LENGTH_OFFSET], rax
    mov rax, [rbx+NEBO_RENDER_NODE_GLYPH_COUNT_OFFSET]
    mov [rsp+NEBO_DRAW_COMMAND_GLYPH_COUNT_OFFSET], rax
    mov qword [rsp+NEBO_DRAW_COMMAND_CLIP_ID_OFFSET], 2
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done
    inc r15
    jmp .build_node_loop

.build_pop_clip:
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_DRAW_COMMAND_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_DRAW_COMMAND_KIND_OFFSET], NEBO_DRAW_COMMAND_POP_CLIP
    mov dword [rsp+NEBO_DRAW_COMMAND_FLAGS_OFFSET], NEBO_DRAW_COMMAND_FLAG_LIVE | NEBO_DRAW_COMMAND_FLAG_LOGICAL_UNITS
    mov qword [rsp+NEBO_DRAW_COMMAND_CLIP_ID_OFFSET], 2
    mov rdi, r12
    mov rsi, rsp
    call nebo_draw_append_internal
    test eax, eax
    jnz .build_done
    mov qword [r12+NEBO_DRAW_BUFFER_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_DRAW_BUFFER_LAST_ERROR_OFFSET], NEBO_DRAW_ERROR_NONE
    lea rsi, [r12+NEBO_DRAW_BUFFER_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_draw_command_buffer_state_hash
    jmp .build_done
.build_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_DRAW_ERROR_COMMAND_LIMIT
    call nebo_draw_set_failure_internal
    jmp .build_done
.build_layout:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_DRAW_ERROR_LAYOUT_CORRUPT
    call nebo_draw_set_failure_internal
    jmp .build_done
.build_render:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_DRAW_ERROR_RENDER_CORRUPT
    call nebo_draw_set_failure_internal
.build_done:
    add rsp, NEBO_DRAW_COMMAND_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; buffer_state_hash(buffer*, out*) -> status
nebo_draw_command_buffer_state_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .hash_invalid
    test r13, r13
    jz .hash_invalid
    mov eax, NEBO_DRAW_HASH_FNV1A32_OFFSET_BASIS
    mov edx, NEBO_DRAW_BUFFER_COUNT_OFFSET
.hash_header:
    cmp edx, NEBO_DRAW_BUFFER_STATE_HASH_OFFSET
    jae .hash_commands
    cmp edx, NEBO_DRAW_BUFFER_DOCUMENT_PTR_OFFSET
    je .hash_skip_header
    mov rbx, [r12+rdx]
    mov ecx, 8
.hash_header_bytes:
    xor al, bl
    imul rax, rax, NEBO_DRAW_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_header_bytes
.hash_skip_header:
    add edx, 8
    jmp .hash_header
.hash_commands:
    xor r8d, r8d
    mov r9, [r12+NEBO_DRAW_BUFFER_COMMANDS_PTR_OFFSET]
.hash_command_loop:
    cmp r8, [r12+NEBO_DRAW_BUFFER_COUNT_OFFSET]
    jae .hash_done
    mov r10, r8
    imul r10, NEBO_DRAW_COMMAND_SIZE
    add r10, r9
    xor r11d, r11d
.hash_command_qword:
    cmp r11d, NEBO_DRAW_COMMAND_QWORDS
    jae .hash_next
    mov rbx, [r10+r11*8]
    mov ecx, 8
.hash_command_bytes:
    xor al, bl
    imul rax, rax, NEBO_DRAW_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_command_bytes
    inc r11d
    jmp .hash_command_qword
.hash_next:
    inc r8
    jmp .hash_command_loop
.hash_done:
    mov [r13], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .hash_return
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.hash_return:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
