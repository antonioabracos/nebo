; Nebo Console UTF-8 Text editor — MF047
bits 64
default rel

%include "runtime/console/input/editing/text_editor.inc"

global nebo_text_edit_init
global nebo_text_edit_validate
global nebo_text_edit_set_text
global nebo_text_edit_insert_utf8
global nebo_text_edit_key
global nebo_text_edit_caret_from_column
global nebo_text_edit_state_hash

section .text

; Internal: publish status/error. RDI=edit*, ESI=status, EDX=error.
nebo_text_edit_set_result_internal:
    test rdi, rdi
    jz .done
    mov [rdi+NEBO_TEXT_EDIT_LAST_STATUS_OFFSET], rsi
    mov [rdi+NEBO_TEXT_EDIT_LAST_ERROR_OFFSET], rdx
.done:
    mov eax, esi
    ret

; Internal: EAX=1 when RSI is a UTF-8 boundary in edit RDI.
nebo_text_edit_is_boundary_internal:
    cmp rsi, [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    ja .no
    test rsi, rsi
    jz .yes
    cmp rsi, [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    je .yes
    mov rax, [rdi+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    movzx eax, byte [rax+rsi]
    and eax, 0xc0
    cmp eax, 0x80
    je .no
.yes:
    mov eax, 1
    ret
.no:
    xor eax, eax
    ret

; Internal: previous scalar boundary. RDI=edit*, RSI=current, RAX=boundary.
nebo_text_edit_previous_boundary_internal:
    mov rax, rsi
    test rax, rax
    jz .done
    dec rax
    mov rdx, [rdi+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
.loop:
    test rax, rax
    jz .done
    movzx ecx, byte [rdx+rax]
    and ecx, 0xc0
    cmp ecx, 0x80
    jne .done
    dec rax
    jmp .loop
.done:
    ret

; Internal: next scalar boundary. RDI=edit*, RSI=current, RAX=boundary.
nebo_text_edit_next_boundary_internal:
    mov rax, [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    cmp rsi, rax
    jae .done
    lea rax, [rsi+1]
    mov rdx, [rdi+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
.loop:
    cmp rax, [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .done
    movzx ecx, byte [rdx+rax]
    and ecx, 0xc0
    cmp ecx, 0x80
    jne .done
    inc rax
    jmp .loop
.done:
    ret

; edit_init(edit*, InputHandle, NodeId, buffer*, capacity) -> status
nebo_text_edit_init:
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
    jz .invalid_no_edit
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_TEXT_EDIT_RECORD_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    test rbx, rbx
    jz .invalid
    test r8, r8
    jz .invalid
    cmp r8, NEBO_TEXT_EDIT_MAX_BYTES
    ja .limit
    mov [r12+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], r13
    mov [r12+NEBO_TEXT_EDIT_NODE_ID_OFFSET], r14
    mov [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET], rbx
    mov [r12+NEBO_TEXT_EDIT_CAPACITY_OFFSET], r8
    mov qword [r12+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_REQUIRED_FLAGS
    mov qword [r12+NEBO_TEXT_EDIT_REVISION_OFFSET], 1
    mov eax, NEBO_TEXT_EDIT_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_TEXT_EDIT_STATE_HASH_OFFSET], rax
    mov rdi, r12
    xor esi, esi
    xor edx, edx
    call nebo_text_edit_set_result_internal
    jmp .done
.limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_TEXT_EDIT_ERROR_LIMIT
    call nebo_text_edit_set_result_internal
    jmp .done
.invalid:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_TEXT_EDIT_ERROR_BAD_ARGUMENT
    call nebo_text_edit_set_result_internal
    jmp .done
.invalid_no_edit:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_text_edit_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_TEXT_EDIT_NODE_ID_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET], 0
    je .state
    mov rax, [rdi+NEBO_TEXT_EDIT_CAPACITY_OFFSET]
    test rax, rax
    jz .state
    cmp rax, NEBO_TEXT_EDIT_MAX_BYTES
    ja .state
    cmp [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET], rax
    ja .state
    mov rax, [rdi+NEBO_TEXT_EDIT_CARET_OFFSET]
    cmp rax, [rdi+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    ja .state
    mov rsi, rax
    sub rsp, 8
    call nebo_text_edit_is_boundary_internal
    add rsp, 8
    test eax, eax
    jz .state
    mov rax, [rdi+NEBO_TEXT_EDIT_FLAGS_OFFSET]
    and eax, NEBO_TEXT_EDIT_REQUIRED_FLAGS
    cmp eax, NEBO_TEXT_EDIT_REQUIRED_FLAGS
    jne .state
    xor eax, eax
    ret
.state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; set_text(edit*, data*, length) -> status
nebo_text_edit_set_text:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_text_edit_validate
    test eax, eax
    jnz .done
    test qword [r12+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED
    jnz .resolved
    cmp r14, [r12+NEBO_TEXT_EDIT_CAPACITY_OFFSET]
    ja .limit
    mov rdi, r13
    mov rsi, r14
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .utf8
    test r14, r14
    jz .commit
    mov rdi, [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rsi, r13
    mov rcx, r14
    cld
    rep movsb
.commit:
    mov [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET], r14
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], r14
    inc qword [r12+NEBO_TEXT_EDIT_REVISION_OFFSET]
    lea rsi, [r12+NEBO_TEXT_EDIT_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_text_edit_state_hash
    xor eax, eax
    jmp .done
.limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_TEXT_EDIT_ERROR_LIMIT
    call nebo_text_edit_set_result_internal
    jmp .done
.utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_TEXT_EDIT_ERROR_INVALID_UTF8
    call nebo_text_edit_set_result_internal
    jmp .done
.resolved:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_TEXT_EDIT_ERROR_RESOLVED
    call nebo_text_edit_set_result_internal
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; insert_utf8(edit*, data*, length) -> status
nebo_text_edit_insert_utf8:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov rdi, r12
    call nebo_text_edit_validate
    test eax, eax
    jnz .done
    test qword [r12+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED
    jnz .resolved
    mov rdi, r13
    mov rsi, r14
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .utf8
    mov rax, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    add rax, r14
    jc .limit
    cmp rax, [r12+NEBO_TEXT_EDIT_CAPACITY_OFFSET]
    ja .limit
    mov r15, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    mov rdi, r12
    mov rsi, r15
    call nebo_text_edit_is_boundary_internal
    test eax, eax
    jz .boundary
    mov rbx, [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rcx, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
.shift:
    cmp rcx, r15
    jbe .copy
    dec rcx
    mov al, [rbx+rcx]
    lea rdx, [rbx+rcx]
    mov [rdx+r14], al
    jmp .shift
.copy:
    lea rdx, [rbx+r15]
    xor rcx, rcx
.copy_loop:
    cmp rcx, r14
    jae .commit
    mov al, [r13+rcx]
    mov [rdx+rcx], al
    inc rcx
    jmp .copy_loop
.commit:
    add [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET], r14
    add [r12+NEBO_TEXT_EDIT_CARET_OFFSET], r14
    inc qword [r12+NEBO_TEXT_EDIT_REVISION_OFFSET]
    lea rsi, [r12+NEBO_TEXT_EDIT_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_text_edit_state_hash
    xor eax, eax
    jmp .done
.limit:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_TEXT_EDIT_ERROR_LIMIT
    call nebo_text_edit_set_result_internal
    jmp .done
.utf8:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_TEXT_EDIT_ERROR_INVALID_UTF8
    call nebo_text_edit_set_result_internal
    jmp .done
.boundary:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_TEXT_EDIT_ERROR_CARET_BOUNDARY
    call nebo_text_edit_set_result_internal
    jmp .done
.resolved:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_TEXT_EDIT_ERROR_RESOLVED
    call nebo_text_edit_set_result_internal
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; key(edit*, key) -> status
nebo_text_edit_key:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13d, esi
    mov rdi, r12
    call nebo_text_edit_validate
    test eax, eax
    jnz .done
    test qword [r12+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED
    jnz .resolved
    cmp r13d, NEBO_TEXT_EDIT_KEY_LEFT
    je .left
    cmp r13d, NEBO_TEXT_EDIT_KEY_RIGHT
    je .right
    cmp r13d, NEBO_TEXT_EDIT_KEY_HOME
    je .home
    cmp r13d, NEBO_TEXT_EDIT_KEY_END
    je .end
    cmp r13d, NEBO_TEXT_EDIT_KEY_BACKSPACE
    je .backspace
    cmp r13d, NEBO_TEXT_EDIT_KEY_DELETE
    je .delete
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_TEXT_EDIT_ERROR_BAD_ARGUMENT
    call nebo_text_edit_set_result_internal
    jmp .done
.left:
    mov rdi, r12
    mov rsi, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    call nebo_text_edit_previous_boundary_internal
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], rax
    jmp .changed
.right:
    mov rdi, r12
    mov rsi, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    call nebo_text_edit_next_boundary_internal
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], rax
    jmp .changed
.home:
    mov qword [r12+NEBO_TEXT_EDIT_CARET_OFFSET], 0
    jmp .changed
.end:
    mov rax, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], rax
    jmp .changed
.backspace:
    mov r14, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    test r14, r14
    jz .success
    mov rdi, r12
    mov rsi, r14
    call nebo_text_edit_previous_boundary_internal
    mov r13, rax
    mov rbx, [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rcx, r14
.shift_back:
    cmp rcx, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .back_commit
    mov al, [rbx+rcx]
    mov rdx, rcx
    sub rdx, r14
    add rdx, r13
    mov [rbx+rdx], al
    inc rcx
    jmp .shift_back
.back_commit:
    mov rax, r14
    sub rax, r13
    sub [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET], rax
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], r13
    jmp .changed
.delete:
    mov r13, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    cmp r13, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .success
    mov rdi, r12
    mov rsi, r13
    call nebo_text_edit_next_boundary_internal
    mov r14, rax
    mov rbx, [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rcx, r14
.shift_delete:
    cmp rcx, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .delete_commit
    mov al, [rbx+rcx]
    mov rdx, rcx
    sub rdx, r14
    add rdx, r13
    mov [rbx+rdx], al
    inc rcx
    jmp .shift_delete
.delete_commit:
    mov rax, r14
    sub rax, r13
    sub [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET], rax
    jmp .changed
.changed:
    inc qword [r12+NEBO_TEXT_EDIT_REVISION_OFFSET]
    lea rsi, [r12+NEBO_TEXT_EDIT_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_text_edit_state_hash
.success:
    xor eax, eax
    jmp .done
.resolved:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_TEXT_EDIT_ERROR_RESOLVED
    call nebo_text_edit_set_result_internal
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; caret_from_column(edit*, glyph_column) -> status; updates caret safely.
nebo_text_edit_caret_from_column:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov rdi, r12
    call nebo_text_edit_validate
    test eax, eax
    jnz .done
    test qword [r12+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED
    jnz .resolved
    xor r14, r14
    xor rbx, rbx
.loop:
    cmp rbx, r13
    jae .commit
    cmp r14, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .commit
    mov rdi, r12
    mov rsi, r14
    call nebo_text_edit_next_boundary_internal
    mov r14, rax
    inc rbx
    jmp .loop
.commit:
    mov [r12+NEBO_TEXT_EDIT_CARET_OFFSET], r14
    xor eax, eax
    jmp .done
.resolved:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_TEXT_EDIT_ERROR_RESOLVED
    call nebo_text_edit_set_result_internal
.done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; state_hash(edit*, out_hash*) -> status
nebo_text_edit_state_hash:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .invalid
    test r13, r13
    jz .invalid
    mov eax, NEBO_TEXT_EDIT_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_TEXT_EDIT_NODE_ID_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_TEXT_EDIT_CARET_OFFSET]
    call .mix
    mov rdx, [r12+NEBO_TEXT_EDIT_REVISION_OFFSET]
    call .mix
    xor rbx, rbx
    mov r14, [r12+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
.bytes:
    cmp rbx, [r12+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    jae .commit
    mov dl, [r14+rbx]
    xor al, dl
    imul eax, eax, NEBO_TEXT_EDIT_HASH_FNV1A32_PRIME
    inc rbx
    jmp .bytes
.commit:
    mov [r13], rax
    mov [r12+NEBO_TEXT_EDIT_STATE_HASH_OFFSET], rax
    xor eax, eax
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 8
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
    imul eax, eax, NEBO_TEXT_EDIT_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
