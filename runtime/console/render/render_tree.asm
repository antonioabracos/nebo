; Nebo deterministic RenderTree — MF044
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"
%include "runtime/console/render/render_tree.inc"

extern nebo_console_layout_validate
extern nebo_console_document_validate
extern nebo_fake_glyph_provider_measure_utf8

global nebo_console_render_tree_init
global nebo_console_render_tree_validate
global nebo_console_render_tree_build
global nebo_console_render_tree_state_hash

section .text

nebo_console_render_tree_set_failure_internal:
    test rdi, rdi
    jz .failure_return
    mov [rdi+NEBO_RENDER_TREE_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_RENDER_TREE_LAST_ERROR_OFFSET], rdx
.failure_return:
    mov eax, esi
    ret

; render_tree_init(tree*, nodes*, capacity) -> status
nebo_console_render_tree_init:
    test rdi, rdi
    jz .init_invalid_no_tree
    push rdi
    mov r8, rsi
    mov r9, rdx
    xor eax, eax
    mov ecx, NEBO_RENDER_TREE_QWORDS
    cld
    rep stosq
    pop rdi
    test r8, r8
    jz .init_invalid
    test r9, r9
    jz .init_limit
    cmp r9, NEBO_LAYOUT_MAX_BOXES_PER_FRAME
    ja .init_limit
    mov [rdi+NEBO_RENDER_TREE_NODES_PTR_OFFSET], r8
    mov [rdi+NEBO_RENDER_TREE_NODE_CAPACITY_OFFSET], r9
    mov qword [rdi+NEBO_RENDER_TREE_NODE_COUNT_OFFSET], 0
    mov qword [rdi+NEBO_RENDER_TREE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [rdi+NEBO_RENDER_TREE_LAST_ERROR_OFFSET], NEBO_RENDER_TREE_ERROR_NONE
    mov eax, NEBO_LAYOUT_HASH_FNV1A32_OFFSET_BASIS
    mov [rdi+NEBO_RENDER_TREE_STATE_HASH_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.init_limit:
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_RENDER_TREE_ERROR_NODE_LIMIT
    jmp nebo_console_render_tree_set_failure_internal
.init_invalid:
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_RENDER_TREE_ERROR_BAD_ARGUMENT
    jmp nebo_console_render_tree_set_failure_internal
.init_invalid_no_tree:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_console_render_tree_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_RENDER_TREE_NODES_PTR_OFFSET], 0
    je .validate_state
    mov rax, [rdi+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    cmp rax, [rdi+NEBO_RENDER_TREE_NODE_CAPACITY_OFFSET]
    ja .validate_state
    cmp qword [rdi+NEBO_RENDER_TREE_NODE_CAPACITY_OFFSET], 0
    je .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; render_tree_build(tree*, layout*, document*) -> status
nebo_console_render_tree_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_console_render_tree_validate
    test eax, eax
    jnz .build_done
    mov rdi, r13
    call nebo_console_layout_validate
    test eax, eax
    jnz .build_layout
    mov rdi, r14
    call nebo_console_document_validate
    test eax, eax
    jnz .build_document
    cmp [r13+NEBO_LAYOUT_TREE_DOCUMENT_PTR_OFFSET], r14
    jne .build_layout

    mov qword [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET], 0
    mov rax, [r13+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET]
    mov [r12+NEBO_RENDER_TREE_LAYOUT_REVISION_OFFSET], rax
    mov rax, [r14+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [r12+NEBO_RENDER_TREE_DOCUMENT_REVISION_OFFSET], rax
    mov r15, 2
.build_box_loop:
    cmp r15, [r13+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    jae .build_success
    mov rax, r15
    imul rax, NEBO_LAYOUT_BOX_SIZE
    add rax, [r13+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    mov rbx, rax
    mov eax, [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET]
    cmp eax, NEBO_LAYOUT_BOX_KIND_TEXT
    je .build_glyph
    cmp eax, NEBO_LAYOUT_BOX_KIND_PROMPT
    je .build_glyph
    cmp eax, NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    je .build_glyph
    cmp eax, NEBO_LAYOUT_BOX_KIND_INPUT_ROW
    jne .build_next
.build_glyph:
    mov rax, [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    cmp rax, [r12+NEBO_RENDER_TREE_NODE_CAPACITY_OFFSET]
    jae .build_limit
    mov r10, rax
    imul r10, NEBO_RENDER_NODE_SIZE
    add r10, [r12+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
    push rdi
    mov rdi, r10
    xor eax, eax
    mov ecx, NEBO_RENDER_NODE_QWORDS
    cld
    rep stosq
    pop rdi
    mov rax, [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    inc rax
    mov [r10+NEBO_RENDER_NODE_ID_OFFSET], rax
    mov dword [r10+NEBO_RENDER_NODE_KIND_OFFSET], NEBO_RENDER_NODE_KIND_GLYPH_RUN
    mov edx, NEBO_RENDER_NODE_FLAG_LIVE
    test dword [rbx+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_CLIPPED
    jz .build_not_clipped
    or edx, NEBO_RENDER_NODE_FLAG_CLIPPED
.build_not_clipped:
    mov [r10+NEBO_RENDER_NODE_FLAGS_OFFSET], edx
    mov rax, [rbx+NEBO_LAYOUT_BOX_ID_OFFSET]
    mov [r10+NEBO_RENDER_NODE_LAYOUT_BOX_ID_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_NODE_ID_OFFSET]
    mov [r10+NEBO_RENDER_NODE_DOCUMENT_NODE_ID_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_WHITE
    mov [r10+NEBO_RENDER_NODE_FOREGROUND_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_BLACK
    mov [r10+NEBO_RENDER_NODE_BACKGROUND_OFFSET], rax
    mov eax, NEBO_COLOR_BGRA_GREY
    mov [r10+NEBO_RENDER_NODE_BORDER_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_SOURCE_OFFSET_OFFSET]
    mov [r10+NEBO_RENDER_NODE_SOURCE_OFFSET_OFFSET], rax
    mov rax, [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET]
    mov [r10+NEBO_RENDER_NODE_SOURCE_LENGTH_OFFSET], rax
    mov [rsp+16], r10

    ; Measure exact glyph count from the document text store.
    mov rdi, [r13+NEBO_LAYOUT_TREE_GLYPH_PROVIDER_PTR_OFFSET]
    mov rsi, [r14+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    add rsi, [rbx+NEBO_LAYOUT_BOX_SOURCE_OFFSET_OFFSET]
    mov rdx, [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET]
    lea rcx, [rsp]
    lea r8, [rsp+8]
    call nebo_fake_glyph_provider_measure_utf8
    test eax, eax
    jnz .build_layout
    mov r10, [rsp+16]
    mov rax, [rsp+8]
    mov [r10+NEBO_RENDER_NODE_GLYPH_COUNT_OFFSET], rax
    mov qword [r10+NEBO_RENDER_NODE_Z_ORDER_OFFSET], 2
    mov rax, [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    mov [r10+NEBO_RENDER_NODE_ORDER_OFFSET], rax
    inc qword [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
.build_next:
    inc r15
    jmp .build_box_loop
.build_success:
    mov qword [r12+NEBO_RENDER_TREE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_RENDER_TREE_LAST_ERROR_OFFSET], NEBO_RENDER_TREE_ERROR_NONE
    lea rsi, [r12+NEBO_RENDER_TREE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_render_tree_state_hash
    jmp .build_done
.build_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_RENDER_TREE_ERROR_NODE_LIMIT
    call nebo_console_render_tree_set_failure_internal
    jmp .build_done
.build_layout:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_RENDER_TREE_ERROR_LAYOUT_CORRUPT
    call nebo_console_render_tree_set_failure_internal
    jmp .build_done
.build_document:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_RENDER_TREE_ERROR_BAD_STATE
    call nebo_console_render_tree_set_failure_internal
.build_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; render_tree_state_hash(tree*, out*) -> status
nebo_console_render_tree_state_hash:
    push rbx
    push r12
    push r13
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .hash_invalid
    test r13, r13
    jz .hash_invalid
    mov eax, NEBO_LAYOUT_HASH_FNV1A32_OFFSET_BASIS
    mov edx, NEBO_RENDER_TREE_NODE_COUNT_OFFSET
.hash_tree_loop:
    cmp edx, NEBO_RENDER_TREE_STATE_HASH_OFFSET
    jae .hash_nodes
    mov rbx, [r12+rdx]
    mov ecx, 8
.hash_tree_bytes:
    xor al, bl
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_tree_bytes
    add edx, 8
    jmp .hash_tree_loop
.hash_nodes:
    xor r8d, r8d
    mov r9, [r12+NEBO_RENDER_TREE_NODES_PTR_OFFSET]
.hash_node_loop:
    cmp r8, [r12+NEBO_RENDER_TREE_NODE_COUNT_OFFSET]
    jae .hash_done
    mov r10, r8
    imul r10, NEBO_RENDER_NODE_SIZE
    add r10, r9
    xor r11d, r11d
.hash_node_qword:
    cmp r11d, NEBO_RENDER_NODE_QWORDS
    jae .hash_next_node
    mov rbx, [r10+r11*8]
    mov ecx, 8
.hash_node_bytes:
    xor al, bl
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_node_bytes
    inc r11d
    jmp .hash_node_qword
.hash_next_node:
    inc r8
    jmp .hash_node_loop
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
