; Nebo deterministic headless flow layout — MF044
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/render/fake_glyph_provider.inc"

extern nebo_console_document_validate
extern nebo_console_document_node_from_id
extern nebo_fake_glyph_provider_validate
extern nebo_fake_glyph_utf8_next

global nebo_console_layout_init
global nebo_console_layout_validate
global nebo_console_layout_document
global nebo_console_flow_layout_items
global nebo_console_layout_box_from_id
global nebo_console_layout_state_hash

section .text

; Internal status/error publisher. RDI=layout*, ESI=status, EDX=error.
nebo_console_layout_set_failure_internal:
    test rdi, rdi
    jz .set_failure_return
    mov [rdi+NEBO_LAYOUT_TREE_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_LAYOUT_TREE_LAST_ERROR_OFFSET], rdx
.set_failure_return:
    mov eax, esi
    ret

; Internal box clear. RDI=box*.
nebo_console_layout_clear_box_internal:
    xor eax, eax
    mov ecx, NEBO_LAYOUT_BOX_QWORDS
    cld
    rep stosq
    ret

; Internal line advance. RDI=layout*.
nebo_console_layout_new_line_internal:
    mov rax, [rdi+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    mov [rdi+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET], rax
    mov rax, [rdi+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET]
    add rax, [rdi+NEBO_LAYOUT_TREE_LINE_HEIGHT_OFFSET]
    jo .new_line_overflow
    mov [rdi+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.new_line_overflow:
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_LAYOUT_ERROR_OVERFLOW
    jmp nebo_console_layout_set_failure_internal

; append_item_internal(layout*, item*) -> status
; Applies inline/wrap/row policy and appends one pointer-free LayoutBox.
nebo_console_layout_append_item_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .append_invalid
    test r13, r13
    jz .append_invalid
    mov r14, [r13+NEBO_LAYOUT_ITEM_WIDTH_OFFSET]
    mov r15, [r13+NEBO_LAYOUT_ITEM_HEIGHT_OFFSET]
    test r14, r14
    jz .append_invalid
    test r15, r15
    jz .append_invalid
    cmp r14, [r12+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET]
    ja .append_overflow
    cmp r15, [r12+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET]
    ja .append_overflow

    mov eax, [r13+NEBO_LAYOUT_ITEM_FLAGS_OFFSET]
    test eax, NEBO_LAYOUT_ITEM_FLAG_ROW
    jz .append_wrap_check
    mov rbx, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    cmp rbx, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    je .append_wrap_check
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .append_done

.append_wrap_check:
    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    add rax, r14
    jo .append_overflow
    mov rbx, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    add rbx, [r12+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET]
    jo .append_overflow
    cmp rax, rbx
    jbe .append_capacity
    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    cmp rax, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    je .append_overflow
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .append_done

.append_capacity:
    mov rax, [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    cmp rax, [r12+NEBO_LAYOUT_TREE_BOX_CAPACITY_OFFSET]
    jae .append_limit
    cmp rax, NEBO_LAYOUT_MAX_BOXES_PER_FRAME
    jae .append_limit
    imul rbx, rax, NEBO_LAYOUT_BOX_SIZE
    add rbx, [r12+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    mov rdi, rbx
    call nebo_console_layout_clear_box_internal

    mov rax, [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    inc rax
    mov [rbx+NEBO_LAYOUT_BOX_ID_OFFSET], rax
    mov eax, [r13+NEBO_LAYOUT_ITEM_KIND_OFFSET]
    cmp eax, NEBO_LAYOUT_ITEM_KIND_TEXT
    je .append_kind_text
    cmp eax, NEBO_LAYOUT_ITEM_KIND_PROMPT
    je .append_kind_prompt
    cmp eax, NEBO_LAYOUT_ITEM_KIND_INPUT_INLINE
    je .append_kind_input
    cmp eax, NEBO_LAYOUT_ITEM_KIND_INPUT_ROW
    je .append_kind_row
    jmp .append_invalid
.append_kind_text:
    mov dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_TEXT
    jmp .append_kind_done
.append_kind_prompt:
    mov dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_PROMPT
    jmp .append_kind_done
.append_kind_input:
    mov dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    jmp .append_kind_done
.append_kind_row:
    mov dword [rbx+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_ROW
.append_kind_done:
    mov eax, [r13+NEBO_LAYOUT_ITEM_FLAGS_OFFSET]
    mov edx, NEBO_LAYOUT_BOX_FLAG_LIVE
    test eax, NEBO_LAYOUT_ITEM_FLAG_INLINE
    jz .append_no_inline
    or edx, NEBO_LAYOUT_BOX_FLAG_INLINE
.append_no_inline:
    test eax, NEBO_LAYOUT_ITEM_FLAG_ROW
    jz .append_no_row
    or edx, NEBO_LAYOUT_BOX_FLAG_ROW
.append_no_row:
    mov [rbx+NEBO_LAYOUT_BOX_FLAGS_OFFSET], edx
    mov rax, [r13+NEBO_LAYOUT_ITEM_NODE_ID_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_NODE_ID_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_X_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_Y_OFFSET], rax
    mov [rbx+NEBO_LAYOUT_BOX_WIDTH_OFFSET], r14
    mov [rbx+NEBO_LAYOUT_BOX_HEIGHT_OFFSET], r15
    mov rax, [r12+NEBO_LAYOUT_TREE_GLYPH_PROVIDER_PTR_OFFSET]
    mov rax, [rax+NEBO_FAKE_GLYPH_BASELINE_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_BASELINE_OFFSET], rax
    mov rax, [r13+NEBO_LAYOUT_ITEM_SOURCE_OFFSET_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_SOURCE_OFFSET_OFFSET], rax
    mov rax, [r13+NEBO_LAYOUT_ITEM_SOURCE_LENGTH_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_SOURCE_LENGTH_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET]
    sub rax, [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET]
    xor edx, edx
    div qword [r12+NEBO_LAYOUT_TREE_LINE_HEIGHT_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_LINE_INDEX_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    mov [rbx+NEBO_LAYOUT_BOX_ORDER_OFFSET], rax
    inc qword [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]

    mov rax, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    add rax, r14
    jo .append_overflow
    mov [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET], rax

    mov rax, [rbx+NEBO_LAYOUT_BOX_Y_OFFSET]
    add rax, r15
    jo .append_overflow
    mov rcx, [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET]
    add rcx, [r12+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET]
    jo .append_overflow
    cmp rax, rcx
    jbe .append_row_after
    or dword [rbx+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_CLIPPED
    or qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], NEBO_LAYOUT_TREE_FLAG_HAS_OVERFLOW
    sub rax, rcx
    cmp rax, [r12+NEBO_LAYOUT_TREE_MAX_SCROLL_OFFSET]
    jbe .append_row_after
    mov [r12+NEBO_LAYOUT_TREE_MAX_SCROLL_OFFSET], rax

.append_row_after:
    mov eax, [r13+NEBO_LAYOUT_ITEM_FLAGS_OFFSET]
    test eax, NEBO_LAYOUT_ITEM_FLAG_ROW
    jz .append_success
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .append_done
.append_success:
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .append_done
.append_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_LAYOUT_ERROR_BOX_LIMIT
    call nebo_console_layout_set_failure_internal
    jmp .append_done
.append_overflow:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_LAYOUT_ERROR_OVERFLOW
    call nebo_console_layout_set_failure_internal
    jmp .append_done
.append_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_LAYOUT_ERROR_BAD_ARGUMENT
    call nebo_console_layout_set_failure_internal
.append_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; layout_init(layout*, boxes*, capacity, width_26_6, height_26_6, provider*)
nebo_console_layout_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    test r12, r12
    jz .init_invalid_no_layout
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_LAYOUT_TREE_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    cmp r14, 2
    jb .init_box_limit
    cmp r14, NEBO_LAYOUT_MAX_BOXES_PER_FRAME
    ja .init_box_limit
    cmp r15, NEBO_LAYOUT_MIN_WIDTH
    jb .init_viewport
    cmp rbx, NEBO_LAYOUT_MIN_HEIGHT
    jb .init_viewport
    test r9, r9
    jz .init_invalid
    mov rdi, r9
    call nebo_fake_glyph_provider_validate
    test eax, eax
    jnz .init_provider

    mov [r12+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET], r13
    mov [r12+NEBO_LAYOUT_TREE_BOX_CAPACITY_OFFSET], r14
    mov qword [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 2
    mov [r12+NEBO_LAYOUT_TREE_VIEWPORT_WIDTH_OFFSET], r15
    mov [r12+NEBO_LAYOUT_TREE_VIEWPORT_HEIGHT_OFFSET], rbx
    mov qword [r12+NEBO_LAYOUT_TREE_CHROME_BOX_ID_OFFSET], 1
    mov qword [r12+NEBO_LAYOUT_TREE_CONTENT_BOX_ID_OFFSET], 2
    mov qword [r12+NEBO_LAYOUT_TREE_LINE_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    mov qword [r12+NEBO_LAYOUT_TREE_GLYPH_ADVANCE_OFFSET], NEBO_LAYOUT_GLYPH_ADVANCE
    mov qword [r12+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET], 0
    mov qword [r12+NEBO_LAYOUT_TREE_DOCUMENT_REVISION_OFFSET], 0
    mov qword [r12+NEBO_LAYOUT_TREE_MAX_SCROLL_OFFSET], 0
    mov qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], NEBO_LAYOUT_TREE_REQUIRED_FLAGS
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_ERROR_OFFSET], NEBO_LAYOUT_ERROR_NONE
    mov [r12+NEBO_LAYOUT_TREE_GLYPH_PROVIDER_PTR_OFFSET], r9

    ; Chrome/content geometry.
    mov rax, NEBO_LAYOUT_BORDER
    mov [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET], rax
    add rax, NEBO_LAYOUT_CONTENT_PADDING_X
    mov [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET], rax
    mov rax, NEBO_LAYOUT_BORDER + NEBO_LAYOUT_CHROME_HEIGHT + NEBO_LAYOUT_CONTENT_PADDING_Y
    mov [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET], rax
    mov rax, r15
    sub rax, 2*NEBO_LAYOUT_BORDER + 2*NEBO_LAYOUT_CONTENT_PADDING_X
    jbe .init_viewport
    mov [r12+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET], rax
    mov rax, rbx
    sub rax, 2*NEBO_LAYOUT_BORDER + NEBO_LAYOUT_CHROME_HEIGHT + 2*NEBO_LAYOUT_CONTENT_PADDING_Y
    jbe .init_viewport
    mov [r12+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    mov [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET]
    mov [r12+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET], rax

    ; Box 1: custom chrome logical region.
    mov rdi, r13
    call nebo_console_layout_clear_box_internal
    mov qword [r13+NEBO_LAYOUT_BOX_ID_OFFSET], 1
    mov dword [r13+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CHROME
    mov dword [r13+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_LIVE | NEBO_LAYOUT_BOX_FLAG_SYNTHETIC
    mov qword [r13+NEBO_LAYOUT_BOX_X_OFFSET], NEBO_LAYOUT_BORDER
    mov qword [r13+NEBO_LAYOUT_BOX_Y_OFFSET], NEBO_LAYOUT_BORDER
    mov rax, r15
    sub rax, 2*NEBO_LAYOUT_BORDER
    mov [r13+NEBO_LAYOUT_BOX_WIDTH_OFFSET], rax
    mov qword [r13+NEBO_LAYOUT_BOX_HEIGHT_OFFSET], NEBO_LAYOUT_CHROME_HEIGHT
    mov qword [r13+NEBO_LAYOUT_BOX_ORDER_OFFSET], 0

    ; Box 2: padded content region.
    lea r13, [r13+NEBO_LAYOUT_BOX_SIZE]
    mov rdi, r13
    call nebo_console_layout_clear_box_internal
    mov qword [r13+NEBO_LAYOUT_BOX_ID_OFFSET], 2
    mov dword [r13+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CONTENT
    mov dword [r13+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_LIVE | NEBO_LAYOUT_BOX_FLAG_SYNTHETIC
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    mov [r13+NEBO_LAYOUT_BOX_X_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET]
    mov [r13+NEBO_LAYOUT_BOX_Y_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET]
    mov [r13+NEBO_LAYOUT_BOX_WIDTH_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET]
    mov [r13+NEBO_LAYOUT_BOX_HEIGHT_OFFSET], rax
    mov qword [r13+NEBO_LAYOUT_BOX_ORDER_OFFSET], 1

    lea rsi, [r12+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_layout_state_hash
    jmp .init_done
.init_provider:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_LAYOUT_ERROR_GLYPH_PROVIDER
    call nebo_console_layout_set_failure_internal
    jmp .init_done
.init_box_limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_LAYOUT_ERROR_BOX_LIMIT
    call nebo_console_layout_set_failure_internal
    jmp .init_done
.init_viewport:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_LAYOUT_ERROR_BAD_VIEWPORT
    call nebo_console_layout_set_failure_internal
    jmp .init_done
.init_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_LAYOUT_ERROR_BAD_ARGUMENT
    call nebo_console_layout_set_failure_internal
    jmp .init_done
.init_invalid_no_layout:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; layout_validate(layout*) -> status
nebo_console_layout_validate:
    test rdi, rdi
    jz .validate_invalid
    mov rax, [rdi+NEBO_LAYOUT_TREE_FLAGS_OFFSET]
    and eax, NEBO_LAYOUT_TREE_REQUIRED_FLAGS
    cmp eax, NEBO_LAYOUT_TREE_REQUIRED_FLAGS
    jne .validate_state
    cmp qword [rdi+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET], 0
    je .validate_state
    mov rax, [rdi+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    cmp rax, 2
    jb .validate_state
    cmp rax, [rdi+NEBO_LAYOUT_TREE_BOX_CAPACITY_OFFSET]
    ja .validate_state
    cmp qword [rdi+NEBO_LAYOUT_TREE_GLYPH_PROVIDER_PTR_OFFSET], 0
    je .validate_state
    cmp qword [rdi+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET], 0
    jle .validate_state
    cmp qword [rdi+NEBO_LAYOUT_TREE_CONTENT_HEIGHT_OFFSET], 0
    jle .validate_state
    mov rax, [rdi+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    cmp qword [rax+NEBO_LAYOUT_BOX_ID_OFFSET], 1
    jne .validate_state
    cmp dword [rax+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CHROME
    jne .validate_state
    add rax, NEBO_LAYOUT_BOX_SIZE
    cmp qword [rax+NEBO_LAYOUT_BOX_ID_OFFSET], 2
    jne .validate_state
    cmp dword [rax+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_CONTENT
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; flow_layout_items(layout*, items*, count) -> status
nebo_console_flow_layout_items:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_console_layout_validate
    test eax, eax
    jnz .flow_done
    test r14, r14
    jz .flow_success
    test r13, r13
    jz .flow_invalid
    xor ebx, ebx
.flow_loop:
    cmp rbx, r14
    jae .flow_success
    mov rax, rbx
    imul rax, NEBO_LAYOUT_ITEM_SIZE
    lea rsi, [r13+rax]
    mov rdi, r12
    call nebo_console_layout_append_item_internal
    test eax, eax
    jnz .flow_done
    inc rbx
    jmp .flow_loop
.flow_success:
    inc qword [r12+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET]
    or qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], NEBO_LAYOUT_TREE_FLAG_DIRTY
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_ERROR_OFFSET], NEBO_LAYOUT_ERROR_NONE
    lea rsi, [r12+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_layout_state_hash
    jmp .flow_done
.flow_invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_LAYOUT_ERROR_BAD_ARGUMENT
    call nebo_console_layout_set_failure_internal
.flow_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; layout_document(layout*, document*) -> status
nebo_console_layout_document:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 144
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_console_layout_validate
    test eax, eax
    jnz .document_done
    mov rdi, r13
    call nebo_console_document_validate
    test eax, eax
    jnz .document_corrupt

    ; Reset derived content boxes while preserving chrome/content.
    mov qword [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET], 2
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    mov [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET], rax
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_Y_OFFSET]
    mov [r12+NEBO_LAYOUT_TREE_CURSOR_Y_OFFSET], rax
    mov qword [r12+NEBO_LAYOUT_TREE_MAX_SCROLL_OFFSET], 0
    and qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], ~(NEBO_LAYOUT_TREE_FLAG_HAS_OVERFLOW | NEBO_LAYOUT_TREE_FLAG_REFLOWED)
    mov [r12+NEBO_LAYOUT_TREE_DOCUMENT_PTR_OFFSET], r13
    mov rax, [r13+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [r12+NEBO_LAYOUT_TREE_DOCUMENT_REVISION_OFFSET], rax

    mov rax, [r13+NEBO_CONSOLE_DOCUMENT_NODE_STORE_PTR_OFFSET]
    mov r14, [rax+NEBO_CONSOLE_NODE_FIRST_CHILD_ID_OFFSET]
.document_node_loop:
    test r14, r14
    jz .document_success
    mov rdi, r13
    mov rsi, r14
    lea rdx, [rsp+64]
    call nebo_console_document_node_from_id
    test eax, eax
    jnz .document_corrupt
    mov r15, [rsp+64]
    mov eax, [r15+NEBO_CONSOLE_NODE_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_NODE_KIND_LINE_BREAK
    je .document_line_break
    cmp eax, NEBO_CONSOLE_NODE_KIND_TEXT
    je .document_text
    cmp eax, NEBO_CONSOLE_NODE_KIND_INT
    je .document_text
    cmp eax, NEBO_CONSOLE_NODE_KIND_BOOL
    je .document_text
    cmp eax, NEBO_CONSOLE_NODE_KIND_PROMPT
    je .document_text
    cmp eax, NEBO_CONSOLE_NODE_KIND_INPUT
    je .document_input
    cmp eax, NEBO_CONSOLE_NODE_KIND_INPUT_ROW
    je .document_next
    jmp .document_next
.document_input:
    mov dword [rsp+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_INPUT_INLINE
    mov dword [rsp+NEBO_LAYOUT_ITEM_FLAGS_OFFSET], NEBO_LAYOUT_ITEM_FLAG_INLINE
    mov rax, [r15+NEBO_CONSOLE_NODE_ID_OFFSET]
    mov [rsp+NEBO_LAYOUT_ITEM_NODE_ID_OFFSET], rax
    mov qword [rsp+NEBO_LAYOUT_ITEM_WIDTH_OFFSET], 12*NEBO_LAYOUT_GLYPH_ADVANCE
    mov qword [rsp+NEBO_LAYOUT_ITEM_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    mov qword [rsp+NEBO_LAYOUT_ITEM_SOURCE_OFFSET_OFFSET], 0
    mov qword [rsp+NEBO_LAYOUT_ITEM_SOURCE_LENGTH_OFFSET], 0
    mov rdi, r12
    mov rsi, rsp
    call nebo_console_layout_append_item_internal
    test eax, eax
    jnz .document_done
    jmp .document_next

.document_line_break:
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .document_done
    jmp .document_next

.document_text:
    mov rax, [r15+NEBO_CONSOLE_NODE_PAYLOAD_LENGTH_OFFSET]
    mov [rsp+80], rax                    ; total bytes
    test rax, rax
    jz .document_next
    mov rax, [r15+NEBO_CONSOLE_NODE_PAYLOAD_OFFSET_OFFSET]
    mov [rsp+88], rax                    ; payload base offset
    add rax, [r13+NEBO_CONSOLE_DOCUMENT_TEXT_STORE_PTR_OFFSET]
    mov [rsp+96], rax                    ; data pointer
    mov qword [rsp+104], 0               ; consumed bytes
.document_segment_loop:
    mov rax, [rsp+104]
    cmp rax, [rsp+80]
    jae .document_next
    mov rax, [r12+NEBO_LAYOUT_TREE_CONTENT_X_OFFSET]
    add rax, [r12+NEBO_LAYOUT_TREE_CONTENT_WIDTH_OFFSET]
    sub rax, [r12+NEBO_LAYOUT_TREE_CURSOR_X_OFFSET]
    jle .document_force_newline
    xor edx, edx
    div qword [r12+NEBO_LAYOUT_TREE_GLYPH_ADVANCE_OFFSET]
    test rax, rax
    jz .document_force_newline
    mov [rsp+128], rax                   ; max glyphs
    mov qword [rsp+112], 0               ; line bytes
    mov qword [rsp+120], 0               ; glyph count
.document_scan_loop:
    mov rax, [rsp+104]
    cmp rax, [rsp+80]
    jae .document_emit_segment
    mov rax, [rsp+120]
    cmp rax, [rsp+128]
    jae .document_emit_segment
    mov rdi, [rsp+96]
    add rdi, [rsp+104]
    mov rsi, [rsp+80]
    sub rsi, [rsp+104]
    lea rdx, [rsp+48]
    lea rcx, [rsp+56]
    call nebo_fake_glyph_utf8_next
    test eax, eax
    jnz .document_invalid_utf8
    mov rax, [rsp+56]
    add [rsp+104], rax
    add [rsp+112], rax
    inc qword [rsp+120]
    jmp .document_scan_loop
.document_emit_segment:
    mov rax, [rsp+120]
    test rax, rax
    jz .document_force_newline
    mul qword [r12+NEBO_LAYOUT_TREE_GLYPH_ADVANCE_OFFSET]
    test rdx, rdx
    jnz .document_overflow
    mov [rsp+136], rax                   ; preserve segment width across kind dispatch
    ; Build a temporary LayoutItem at rsp.
    mov eax, [r15+NEBO_CONSOLE_NODE_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_NODE_KIND_PROMPT
    jne .document_item_text_kind
    mov dword [rsp+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_PROMPT
    jmp .document_item_kind_ready
.document_item_text_kind:
    mov dword [rsp+NEBO_LAYOUT_ITEM_KIND_OFFSET], NEBO_LAYOUT_ITEM_KIND_TEXT
.document_item_kind_ready:
    mov dword [rsp+NEBO_LAYOUT_ITEM_FLAGS_OFFSET], NEBO_LAYOUT_ITEM_FLAG_INLINE
    mov rcx, [r15+NEBO_CONSOLE_NODE_ID_OFFSET]
    mov [rsp+NEBO_LAYOUT_ITEM_NODE_ID_OFFSET], rcx
    mov rax, [rsp+136]
    mov [rsp+NEBO_LAYOUT_ITEM_WIDTH_OFFSET], rax
    mov qword [rsp+NEBO_LAYOUT_ITEM_HEIGHT_OFFSET], NEBO_LAYOUT_LINE_HEIGHT
    mov rcx, [rsp+88]
    mov rdx, [rsp+104]
    sub rdx, [rsp+112]
    add rcx, rdx
    mov [rsp+NEBO_LAYOUT_ITEM_SOURCE_OFFSET_OFFSET], rcx
    mov rcx, [rsp+112]
    mov [rsp+NEBO_LAYOUT_ITEM_SOURCE_LENGTH_OFFSET], rcx
    mov rdi, r12
    mov rsi, rsp
    call nebo_console_layout_append_item_internal
    test eax, eax
    jnz .document_done
    mov rax, [rsp+104]
    cmp rax, [rsp+80]
    jae .document_segment_loop
    ; Mark previous box wrapped then advance.
    mov rax, [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    dec rax
    imul rax, NEBO_LAYOUT_BOX_SIZE
    add rax, [r12+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    or dword [rax+NEBO_LAYOUT_BOX_FLAGS_OFFSET], NEBO_LAYOUT_BOX_FLAG_WRAPPED
    or qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], NEBO_LAYOUT_TREE_FLAG_REFLOWED
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .document_done
    jmp .document_segment_loop
.document_force_newline:
    mov rdi, r12
    call nebo_console_layout_new_line_internal
    test eax, eax
    jnz .document_done
    jmp .document_segment_loop

.document_next:
    mov r14, [r15+NEBO_CONSOLE_NODE_NEXT_SIBLING_ID_OFFSET]
    jmp .document_node_loop
.document_success:
    inc qword [r12+NEBO_LAYOUT_TREE_LAYOUT_REVISION_OFFSET]
    or qword [r12+NEBO_LAYOUT_TREE_FLAGS_OFFSET], NEBO_LAYOUT_TREE_FLAG_DIRTY
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_LAYOUT_TREE_LAST_ERROR_OFFSET], NEBO_LAYOUT_ERROR_NONE
    lea rsi, [r12+NEBO_LAYOUT_TREE_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_layout_state_hash
    jmp .document_done
.document_invalid_utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_LAYOUT_ERROR_INVALID_UTF8
    call nebo_console_layout_set_failure_internal
    jmp .document_done
.document_corrupt:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_LAYOUT_ERROR_DOCUMENT_CORRUPT
    call nebo_console_layout_set_failure_internal
    jmp .document_done
.document_overflow:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_LAYOUT_ERROR_OVERFLOW
    call nebo_console_layout_set_failure_internal
.document_done:
    add rsp, 144
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; box_from_id(layout*, id, out_box**) -> status
nebo_console_layout_box_from_id:
    test rdx, rdx
    jz .box_invalid
    mov qword [rdx], 0
    test rdi, rdi
    jz .box_invalid
    test rsi, rsi
    jz .box_invalid
    cmp rsi, [rdi+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    ja .box_invalid
    mov rax, rsi
    dec rax
    imul rax, NEBO_LAYOUT_BOX_SIZE
    add rax, [rdi+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
    cmp [rax+NEBO_LAYOUT_BOX_ID_OFFSET], rsi
    jne .box_state
    mov [rdx], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.box_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.box_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; layout_state_hash(layout*, out_hash*) -> status
nebo_console_layout_state_hash:
    push rbx
    push r12
    push r13
    push r14
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .hash_invalid
    test r13, r13
    jz .hash_invalid
    mov eax, NEBO_LAYOUT_HASH_FNV1A32_OFFSET_BASIS
    ; Hash logical tree fields: box count and offsets 32..168, excluding status/error hash/provider.
    mov r14, [r12+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    mov rbx, r14
    mov ecx, 8
.hash_count_bytes:
    xor al, bl
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_count_bytes
    mov edx, 32
.hash_tree_fields:
    cmp edx, 160
    jae .hash_boxes
    mov rbx, [r12+rdx]
    mov ecx, 8
.hash_tree_bytes:
    xor al, bl
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_tree_bytes
    add edx, 8
    jmp .hash_tree_fields
.hash_boxes:
    xor r8d, r8d
    mov r9, [r12+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
.hash_box_loop:
    cmp r8, r14
    jae .hash_done
    mov r10, r8
    imul r10, NEBO_LAYOUT_BOX_SIZE
    lea r10, [r9+r10]
    xor r11d, r11d
.hash_box_qword:
    cmp r11d, NEBO_LAYOUT_BOX_QWORDS
    jae .hash_next_box
    mov rbx, [r10+r11*8]
    mov ecx, 8
.hash_box_bytes:
    xor al, bl
    imul rax, rax, NEBO_LAYOUT_HASH_FNV1A32_PRIME
    shr rbx, 8
    dec ecx
    jnz .hash_box_bytes
    inc r11d
    jmp .hash_box_qword
.hash_next_box:
    inc r8
    jmp .hash_box_loop
.hash_done:
    mov [r13], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .hash_return
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.hash_return:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
