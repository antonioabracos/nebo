; Nebo Console headless FocusManager — MF047
bits 64
default rel

%include "runtime/console/focus/focus_manager.inc"

global nebo_focus_manager_init
global nebo_focus_manager_validate
global nebo_focus_manager_set_window_active
global nebo_focus_manager_sync
global nebo_focus_manager_focus_handle
global nebo_focus_manager_hit_test
global nebo_focus_manager_pointer_down
global nebo_focus_manager_text_input
global nebo_focus_manager_key
global nebo_focus_manager_current_editor
global nebo_focus_manager_state_hash

section .text

nebo_focus_manager_set_result_internal:
    test rdi, rdi
    jz .done
    mov [rdi+NEBO_FOCUS_MANAGER_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_FOCUS_MANAGER_LAST_ERROR_OFFSET], rdx
.done:
    mov eax, esi
    ret

; find_editor(manager*, InputHandle, out_edit**) -> status
nebo_focus_manager_find_editor_internal:
    test rdx, rdx
    jz .invalid
    mov qword [rdx], 0
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .handle
    mov eax, esi
    cmp rax, [rdi+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET]
    jae .handle
    imul rax, rax, NEBO_TEXT_EDIT_RECORD_SIZE
    add rax, [rdi+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
    cmp [rax+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], rsi
    jne .handle
    mov [rdx], rax
    xor eax, eax
    ret
.handle:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; manager_init(manager*, input_registry*, layout*, storage*) -> status
nebo_focus_manager_init:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rbx, rcx
    test r12, r12
    jz .invalid_no_manager
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_FOCUS_MANAGER_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    test rbx, rbx
    jz .invalid
    cmp qword [rbx+NEBO_FOCUS_STORAGE_EDITORS_PTR_OFFSET], 0
    je .invalid
    mov rax, [rbx+NEBO_FOCUS_STORAGE_EDITOR_CAPACITY_OFFSET]
    test rax, rax
    jz .invalid
    cmp rax, [r13+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jb .limit
    cmp qword [rbx+NEBO_FOCUS_STORAGE_TEXT_PTR_OFFSET], 0
    je .invalid
    mov rdx, [rbx+NEBO_FOCUS_STORAGE_TEXT_STRIDE_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBO_TEXT_EDIT_MAX_BYTES
    ja .limit
    mov [r12+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], r13
    mov [r12+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET], r14
    mov rax, [rbx+NEBO_FOCUS_STORAGE_EDITORS_PTR_OFFSET]
    mov [r12+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET], rax
    mov rax, [rbx+NEBO_FOCUS_STORAGE_EDITOR_CAPACITY_OFFSET]
    mov [r12+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET], rax
    mov rax, [rbx+NEBO_FOCUS_STORAGE_TEXT_PTR_OFFSET]
    mov [r12+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET], rax
    mov rax, [rbx+NEBO_FOCUS_STORAGE_TEXT_STRIDE_OFFSET]
    mov [r12+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET], rax
    mov qword [r12+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    mov qword [r12+NEBO_FOCUS_MANAGER_FLAGS_OFFSET], NEBO_FOCUS_MANAGER_REQUIRED_FLAGS
    mov qword [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET], 1
    mov eax, NEBO_FOCUS_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_FOCUS_MANAGER_STATE_HASH_OFFSET], rax
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    call nebo_focus_manager_set_result_internal
    jmp .done
.limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_FOCUS_ERROR_BAD_STATE
    call nebo_focus_manager_set_result_internal
    jmp .done
.invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_FOCUS_ERROR_BAD_ARGUMENT
    call nebo_focus_manager_set_result_internal
    jmp .done
.invalid_no_manager:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_focus_manager_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET], 0
    je .state
    mov rax, [rdi+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET]
    test rax, rax
    jz .state
    mov rdx, [rdi+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET]
    cmp rax, [rdx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jb .state
    mov rax, [rdi+NEBO_FOCUS_MANAGER_FLAGS_OFFSET]
    and eax, NEBO_FOCUS_MANAGER_REQUIRED_FLAGS
    cmp eax, NEBO_FOCUS_MANAGER_REQUIRED_FLAGS
    jne .state
    mov rax, [rdi+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET]
    test rax, rax
    jz .ok
    sub rsp, 8
    mov rsi, rax
    lea rdx, [rsp]
    call nebo_focus_manager_find_editor_internal
    add rsp, 8
    test eax, eax
    jnz .state
.ok:
    xor eax, eax
    ret
.state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_focus_manager_set_window_active:
    test rdi, rdi
    jz .invalid
    cmp esi, 1
    ja .invalid
    mov [rdi+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], rsi
    inc qword [rdi+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    xor eax, eax
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; manager_sync(manager*) -> status. Initializes editor records and initial focus.
nebo_focus_manager_sync:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov rdi, r12
    call nebo_focus_manager_validate
    test eax, eax
    jnz .done
    mov r13, [r12+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET]
    mov r14, [r13+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    xor rbx, rbx
    xor r15, r15
    mov qword [rsp], 0                  ; first handle
    mov qword [rsp+8], -1               ; first source order
.loop:
    cmp rbx, [r13+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .commit
    mov rax, rbx
    shl rax, 7
    add rax, r14
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne .next
    test dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_FLAG_ACTIVE
    jz .next
    mov [rsp+16], rax
    mov rcx, rbx
    imul rcx, NEBO_TEXT_EDIT_RECORD_SIZE
    add rcx, [r12+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
    cmp qword [rcx+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], 0
    jne .already
    mov rdx, rbx
    imul rdx, [r12+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET]
    add rdx, [r12+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET]
    mov rdi, rcx
    mov rsi, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov rdx, [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET]
    mov rcx, rbx
    imul rcx, [r12+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET]
    add rcx, [r12+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET]
    mov r8, [r12+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET]
    call nebo_text_edit_init
    test eax, eax
    jnz .done
    mov rax, [rsp+16]
.already:
    inc r15
    mov rdx, [rax+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET]
    cmp rdx, [rsp+8]
    jae .next
    mov [rsp+8], rdx
    mov rdx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [rsp], rdx
.next:
    inc rbx
    jmp .loop
.commit:
    mov [r12+NEBO_FOCUS_MANAGER_FOCUS_COUNT_OFFSET], r15
    cmp qword [r12+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], 0
    jne .hash
    cmp qword [r12+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 0
    je .hash
    mov rsi, [rsp]
    test rsi, rsi
    jz .hash
    mov rdi, r12
    call nebo_focus_manager_focus_handle
    test eax, eax
    jnz .done
.hash:
    inc qword [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    lea rsi, [r12+NEBO_FOCUS_MANAGER_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_focus_manager_state_hash
    xor eax, eax
.done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; focus_handle(manager*, InputHandle) -> status
nebo_focus_manager_focus_handle:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 24
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_focus_manager_validate
    test eax, eax
    jnz .done
    mov rdi, [r12+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET]
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_input_registry_get
    test eax, eax
    jnz .handle
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp+8]
    call nebo_focus_manager_find_editor_internal
    test eax, eax
    jnz .handle
    mov [r12+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], r13
    mov rax, [rsp]
    mov rax, [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET]
    mov [r12+NEBO_FOCUS_MANAGER_HOVERED_NODE_ID_OFFSET], rax
    inc qword [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    call nebo_focus_manager_set_result_internal
    jmp .done
.handle:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov edx, NEBO_FOCUS_ERROR_HANDLE_INVALID
    call nebo_focus_manager_set_result_internal
.done:
    add rsp, 24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; hit_test(manager*, x26.6, y26.6, out_handle*) -> status
nebo_focus_manager_hit_test:
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
    test r15, r15
    jz .invalid
    mov qword [r15], 0
    mov rdi, r12
    call nebo_focus_manager_validate
    test eax, eax
    jnz .done
    mov rbx, [r12+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET]
    mov rcx, [rbx+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    mov rdx, [rbx+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
.box_loop:
    test rcx, rcx
    jz .no_target
    dec rcx
    imul rax, rcx, NEBO_LAYOUT_BOX_SIZE
    add rax, rdx
    cmp dword [rax+NEBO_LAYOUT_BOX_KIND_OFFSET], NEBO_LAYOUT_BOX_KIND_INPUT_INLINE
    jne .box_loop
    mov r8, [rax+NEBO_LAYOUT_BOX_X_OFFSET]
    cmp r13, r8
    jl .box_loop
    add r8, [rax+NEBO_LAYOUT_BOX_WIDTH_OFFSET]
    cmp r13, r8
    jge .box_loop
    mov r8, [rax+NEBO_LAYOUT_BOX_Y_OFFSET]
    cmp r14, r8
    jl .box_loop
    add r8, [rax+NEBO_LAYOUT_BOX_HEIGHT_OFFSET]
    cmp r14, r8
    jge .box_loop
    mov [rsp], rax
    mov r9, [rax+NEBO_LAYOUT_BOX_NODE_ID_OFFSET]
    mov rbx, [r12+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET]
    xor rcx, rcx
    mov rdx, [rbx+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
.record_loop:
    cmp rcx, [rbx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .no_target
    mov rax, rcx
    shl rax, 7
    add rax, rdx
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne .record_next
    cmp [rax+NEBO_INPUT_RECORD_NODE_ID_OFFSET], r9
    jne .record_next
    mov rax, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [r15], rax
    mov [r12+NEBO_FOCUS_MANAGER_HOVERED_NODE_ID_OFFSET], r9
    xor eax, eax
    jmp .done
.record_next:
    inc rcx
    jmp .record_loop
.no_target:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_NO_PROGRESS
    mov edx, NEBO_FOCUS_ERROR_NO_TARGET
    call nebo_focus_manager_set_result_internal
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; pointer_down(manager*, x26.6, y26.6) -> status
nebo_focus_manager_pointer_down:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 24
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    lea rcx, [rsp]
    call nebo_focus_manager_hit_test
    test eax, eax
    jnz .done
    mov rsi, [rsp]
    mov rdi, r12
    call nebo_focus_manager_focus_handle
    test eax, eax
    jnz .done
    mov rdi, r12
    mov rsi, [rsp]
    lea rdx, [rsp+8]
    call nebo_focus_manager_find_editor_internal
    test eax, eax
    jnz .done
    mov rbx, [r12+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET]
    mov rcx, [rbx+NEBO_LAYOUT_TREE_BOX_COUNT_OFFSET]
    mov rdx, [rbx+NEBO_LAYOUT_TREE_BOXES_PTR_OFFSET]
.find_box:
    test rcx, rcx
    jz .done_ok
    dec rcx
    imul rax, rcx, NEBO_LAYOUT_BOX_SIZE
    add rax, rdx
    mov r8, [rsp+8]
    mov r8, [r8+NEBO_TEXT_EDIT_NODE_ID_OFFSET]
    cmp [rax+NEBO_LAYOUT_BOX_NODE_ID_OFFSET], r8
    jne .find_box
    mov rsi, r13
    sub rsi, [rax+NEBO_LAYOUT_BOX_X_OFFSET]
    jle .column_zero
    xor rdx, rdx
    mov rax, rsi
    div qword [rbx+NEBO_LAYOUT_TREE_GLYPH_ADVANCE_OFFSET]
    mov rsi, rax
    jmp .set_caret
.column_zero:
    xor esi, esi
.set_caret:
    mov rdi, [rsp+8]
    call nebo_text_edit_caret_from_column
.done_ok:
    xor eax, eax
.done:
    add rsp, 24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_focus_manager_current_editor:
    test rdi, rdi
    jz .invalid
    mov rsi, [rdi+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET]
    jmp nebo_focus_manager_find_editor_internal
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; text_input(manager*, bytes*, length) -> status
nebo_focus_manager_text_input:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 24
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_focus_manager_validate
    test eax, eax
    jnz .done
    cmp qword [r12+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    jne .inactive
    mov rdi, r12
    lea rdx, [rsp]
    call nebo_focus_manager_current_editor
    test eax, eax
    jnz .done
    mov rdi, [rsp]
    mov rsi, r13
    mov rdx, r14
    call nebo_text_edit_insert_utf8
    test eax, eax
    jnz .done
    inc qword [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    xor eax, eax
    jmp .done
.inactive:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_FOCUS_ERROR_WINDOW_INACTIVE
    call nebo_focus_manager_set_result_internal
.done:
    add rsp, 24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal focus navigation. ESI=0 next, 1 previous.
nebo_focus_manager_cycle_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 48
    mov r12, rdi
    mov r13d, esi
    mov rbx, [r12+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET]
    mov r14, [rbx+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    mov qword [rsp], 0                  ; current order
    mov rax, [r12+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET]
    test rax, rax
    jz .scan
    mov eax, eax
    imul rax, NEBO_INPUT_RECORD_SIZE
    add rax, r14
    mov rax, [rax+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET]
    mov [rsp], rax
.scan:
    mov qword [rsp+8], 0                ; candidate handle
    mov qword [rsp+16], -1              ; candidate distance/order
    mov qword [rsp+24], 0               ; wrap handle
    cmp r13d, 0
    jne .prev_init
    mov qword [rsp+32], -1              ; wrap minimum order
    jmp .loop_init
.prev_init:
    mov qword [rsp+32], 0               ; wrap maximum order
.loop_init:
    xor r15, r15
.loop:
    cmp r15, [rbx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .choose
    mov rax, r15
    shl rax, 7
    add rax, r14
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne .next
    mov rdx, [rax+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET]
    cmp r13d, 0
    jne .consider_prev
    cmp rdx, [rsp+32]
    jae .next_wrap
    mov [rsp+32], rdx
    mov rcx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [rsp+24], rcx
.next_wrap:
    cmp rdx, [rsp]
    jbe .next
    cmp rdx, [rsp+16]
    jae .next
    mov [rsp+16], rdx
    mov rcx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [rsp+8], rcx
    jmp .next
.consider_prev:
    cmp rdx, [rsp+32]
    jbe .prev_wrap_done
    mov [rsp+32], rdx
    mov rcx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [rsp+24], rcx
.prev_wrap_done:
    cmp rdx, [rsp]
    jae .next
    cmp qword [rsp+8], 0
    je .set_prev
    cmp rdx, [rsp+16]
    jbe .next
.set_prev:
    mov [rsp+16], rdx
    mov rcx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [rsp+8], rcx
.next:
    inc r15
    jmp .loop
.choose:
    mov rsi, [rsp+8]
    test rsi, rsi
    jnz .focus
    mov rsi, [rsp+24]
.focus:
    test rsi, rsi
    jz .no_target
    mov rdi, r12
    call nebo_focus_manager_focus_handle
    jmp .done
.no_target:
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
.done:
    add rsp, 48
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; key(manager*, logical_key) -> status
nebo_focus_manager_key:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 24
    mov r12, rdi
    mov r13d, esi
    mov rdi, r12
    call nebo_focus_manager_validate
    test eax, eax
    jnz .done
    cmp qword [r12+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    jne .inactive
    cmp r13d, NEBO_FOCUS_KEY_TAB
    je .tab
    cmp r13d, NEBO_FOCUS_KEY_SHIFT_TAB
    je .shift_tab
    mov rdi, r12
    lea rdx, [rsp]
    call nebo_focus_manager_current_editor
    test eax, eax
    jnz .done
    mov rdi, [rsp]
    mov esi, r13d
    call nebo_text_edit_key
    test eax, eax
    jnz .done
    inc qword [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    xor eax, eax
    jmp .done
.tab:
    mov rdi, r12
    xor esi, esi
    call nebo_focus_manager_cycle_internal
    jmp .done
.shift_tab:
    mov rdi, r12
    mov esi, 1
    call nebo_focus_manager_cycle_internal
    jmp .done
.inactive:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_FOCUS_ERROR_WINDOW_INACTIVE
    call nebo_focus_manager_set_result_internal
.done:
    add rsp, 24
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; state_hash(manager*, out_hash*) -> status
nebo_focus_manager_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    mov eax, NEBO_FOCUS_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_FOCUS_MANAGER_HOVERED_NODE_ID_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_FOCUS_MANAGER_FOCUS_COUNT_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    call .mix
    xor rbx, rbx
    mov r14, [r12+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
.edit_loop:
    cmp rbx, [r12+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET]
    jae .commit
    mov r15, rbx
    imul r15, NEBO_TEXT_EDIT_RECORD_SIZE
    add r15, r14
    cmp qword [r15+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], 0
    je .edit_next
    mov rdx, [r15+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET]
    call .mix
    mov rdx, [r15+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    call .mix
    mov rdx, [r15+NEBO_TEXT_EDIT_CARET_OFFSET]
    call .mix
    mov rdx, [r15+NEBO_TEXT_EDIT_STATE_HASH_OFFSET]
    call .mix
.edit_next:
    inc rbx
    jmp .edit_loop
.commit:
    mov [r13], rax
    mov [r12+NEBO_FOCUS_MANAGER_STATE_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.mix:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_FOCUS_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
