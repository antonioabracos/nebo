; Nebo Console ENTER submission and Pending<Text> resolution — MF048
bits 64
default rel
%include "runtime/console/input/submission/input_submission.inc"

global nebo_input_submission_init
global nebo_input_submission_validate
global nebo_input_submission_enter
global nebo_input_submission_key
global nebo_input_submission_state_hash

; Monolithic runtime_core forward references.

section .text
nebo_input_submission_init:
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
    mov [rsp], r9
    test r12, r12
    jz .invalid_no_context
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_SUBMISSION_CONTEXT_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .invalid
    test r14, r14
    jz .invalid
    test r15, r15
    jz .invalid
    test rbx, rbx
    jz .invalid
    mov rax, [rsp]
    test rax, rax
    jz .invalid
    cmp qword [rax+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET], 0
    je .invalid
    mov rdx, [rax+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp rdx, NEBO_INPUT_TEXT_MAX_BYTES
    ja .limit
    mov rcx, [rax+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET]
    test rcx, rcx
    jz .invalid
    cmp rcx, NEBO_INPUT_MAX_PER_CONSOLE
    ja .limit

    ; Every component belongs to the same Console and is structurally valid.
    mov rdi, r13
    call nebo_input_registry_validate
    test eax, eax
    jnz .invalid
    mov rdi, r14
    call nebo_pending_registry_validate
    test eax, eax
    jnz .invalid
    mov rdi, r15
    call nebo_focus_manager_validate
    test eax, eax
    jnz .invalid
    mov rdi, rbx
    call nebo_dependency_bridge_validate
    test eax, eax
    jnz .invalid
    cmp [r15+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], r13
    jne .invalid
    mov rdx, [r13+NEBO_INPUT_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET]
    test rdx, rdx
    jz .invalid
    cmp [r14+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .invalid
    cmp [rbx+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .invalid
    mov rax, [rsp]
    mov rcx, [rax+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET]
    cmp rcx, [r14+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jb .limit

    mov [r12+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET], r13
    mov [r12+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET], r14
    mov [r12+NEBO_SUBMISSION_CONTEXT_FOCUS_MANAGER_PTR_OFFSET], r15
    mov [r12+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET], rbx
    mov rdx, [rax+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET]
    mov [r12+NEBO_SUBMISSION_CONTEXT_VALUES_PTR_OFFSET], rdx
    mov rdx, [rax+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET]
    mov [r12+NEBO_SUBMISSION_CONTEXT_VALUE_STRIDE_OFFSET], rdx
    mov rcx, [rax+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET]
    mov [r12+NEBO_SUBMISSION_CONTEXT_VALUE_CAPACITY_OFFSET], rcx
    mov qword [r12+NEBO_SUBMISSION_CONTEXT_FLAGS_OFFSET], NEBO_SUBMISSION_CONTEXT_REQUIRED_FLAGS
    xor eax, eax
    jmp .done
.limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .done
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .done
.invalid_no_context:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_input_submission_validate:
    test rdi, rdi
    jz .invalid
    cmp qword [rdi+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_SUBMISSION_CONTEXT_FOCUS_MANAGER_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET], 0
    je .state
    cmp qword [rdi+NEBO_SUBMISSION_CONTEXT_VALUES_PTR_OFFSET], 0
    je .state
    mov rax, [rdi+NEBO_SUBMISSION_CONTEXT_VALUE_STRIDE_OFFSET]
    test rax, rax
    jz .state
    cmp rax, NEBO_INPUT_TEXT_MAX_BYTES
    ja .state
    mov rax, [rdi+NEBO_SUBMISSION_CONTEXT_VALUE_CAPACITY_OFFSET]
    test rax, rax
    jz .state
    cmp rax, NEBO_INPUT_MAX_PER_CONSOLE
    ja .state
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET]
    cmp rax, [rcx+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jb .state
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    mov rdx, [rcx+NEBO_INPUT_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET]
    test rdx, rdx
    jz .state
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET]
    cmp [rcx+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .state
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET]
    cmp [rcx+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .state
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_FOCUS_MANAGER_PTR_OFFSET]
    mov rax, [rdi+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    cmp [rcx+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], rax
    jne .state
    mov rax, [rdi+NEBO_SUBMISSION_CONTEXT_FLAGS_OFFSET]
    and eax, NEBO_SUBMISSION_CONTEXT_REQUIRED_FLAGS
    cmp eax, NEBO_SUBMISSION_CONTEXT_REQUIRED_FLAGS
    jne .state
    xor eax, eax
    ret
.state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; key(context*, logical_key, result*) -> status
nebo_input_submission_key:
    cmp esi, NEBO_FOCUS_KEY_ENTER
    jne .invalid
    mov rsi, rdx
    jmp nebo_input_submission_enter
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; enter(context*, result*) -> status
nebo_input_submission_enter:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp, 104
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .invalid_no_result
    mov rdi, r13
    xor eax, eax
    mov ecx, NEBO_SUBMISSION_RESULT_QWORDS
    cld
    rep stosq
    mov rdi, r12
    call nebo_input_submission_validate
    test eax, eax
    jnz .publish_direct
    mov r14, [r12+NEBO_SUBMISSION_CONTEXT_FOCUS_MANAGER_PTR_OFFSET]
    mov rdi, r14
    lea rdx, [rsp]
    call nebo_focus_manager_current_editor
    test eax, eax
    jnz .no_focus
    mov r15, [rsp]                         ; editor*
    mov rbx, [r15+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET]
    test rbx, rbx
    jz .no_focus

    ; Resolve InputRecord by generational slot, accepting PENDING/RESOLVED.
    mov rbp, [r12+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    mov eax, ebx
    cmp rax, [rbp+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .input_handle
    mov rdx, rbx
    shr rdx, NEBO_INPUT_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .input_handle
    shl rax, 7
    add rax, [rbp+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_INPUT_RECORD_GENERATION_OFFSET], edx
    jne .input_handle
    cmp [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET], rbx
    jne .input_handle
    mov [rsp+8], rax                       ; input record*
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    je .duplicate
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne .input_handle

    mov rbx, [rax+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET]
    mov rbp, [r12+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET]
    mov eax, ebx
    cmp rax, [rbp+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .pending_handle
    mov rdx, rbx
    shr rdx, NEBO_PENDING_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .pending_handle
    imul rax, rax, NEBO_PENDING_RECORD_SIZE
    add rax, [rbp+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_PENDING_RECORD_GENERATION_OFFSET], edx
    jne .pending_handle
    cmp [rax+NEBO_PENDING_RECORD_HANDLE_OFFSET], rbx
    jne .pending_handle
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_RESOLVED
    je .duplicate
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne .pending_handle
    mov [rsp+16], rax                      ; pending record*
    mov rdx, [rsp+8]
    mov rcx, [rdx+NEBO_INPUT_RECORD_BINDING_ID_OFFSET]
    cmp [rax+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], rcx
    jne .binding
    mov rcx, [rdx+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET]
    cmp [rax+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], rcx
    jne .binding

    mov rbx, [r15+NEBO_TEXT_EDIT_LENGTH_OFFSET]
    cmp rbx, [r12+NEBO_SUBMISSION_CONTEXT_VALUE_STRIDE_OFFSET]
    ja .value_limit
    cmp rbx, NEBO_INPUT_TEXT_MAX_BYTES
    ja .value_limit
    test rbx, rbx
    jz .utf8_ok
    mov rdi, [r15+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rsi, rbx
    call nebo_console_basic_validate_utf8
    test eax, eax
    jnz .utf8
.utf8_ok:
    mov rdi, [r12+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET]
    call nebo_dependency_bridge_validate
    test eax, eax
    jnz .bridge

    ; Copy immutable Text to slot-derived result storage before state commit.
    mov rax, [rsp+16]
    mov edx, [rax+NEBO_PENDING_RECORD_HANDLE_OFFSET]
    cmp rdx, [r12+NEBO_SUBMISSION_CONTEXT_VALUE_CAPACITY_OFFSET]
    jae .value_limit
    imul rdx, [r12+NEBO_SUBMISSION_CONTEXT_VALUE_STRIDE_OFFSET]
    add rdx, [r12+NEBO_SUBMISSION_CONTEXT_VALUES_PTR_OFFSET]
    mov [rsp+24], rdx                      ; result ptr
    test rbx, rbx
    jz .commit
    mov rdi, rdx
    mov rsi, [r15+NEBO_TEXT_EDIT_BUFFER_PTR_OFFSET]
    mov rcx, rbx
    cld
    rep movsb
.commit:
    inc qword [r12+NEBO_SUBMISSION_CONTEXT_SEQUENCE_OFFSET]
    mov rcx, [r12+NEBO_SUBMISSION_CONTEXT_SEQUENCE_OFFSET]
    mov rax, [rsp+16]
    mov dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_RESOLVED
    mov [rax+NEBO_PENDING_RECORD_RESOLUTION_SEQUENCE_OFFSET], rcx
    mov [rax+NEBO_PENDING_RECORD_RESULT_LENGTH_OFFSET], rbx
    or qword [rax+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_FLAG_RESULT_UTF8 | NEBO_PENDING_FLAG_RESOLVED_IMMUTABLE
    mov rdx, [rsp+8]
    mov dword [rdx+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    and dword [rdx+NEBO_INPUT_RECORD_FLAGS_OFFSET], ~(NEBO_INPUT_FLAG_ACTIVE | NEBO_INPUT_FLAG_VALIDATION_ERROR)
    mov qword [rdx+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], 0
    or qword [r15+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED | NEBO_TEXT_EDIT_FLAG_IMMUTABLE
    cmp qword [rbp+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    je .input_count
    dec qword [rbp+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET]
.input_count:
    mov rdx, [r12+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    cmp qword [rdx+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    je .notify
    dec qword [rdx+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET]
.notify:
    mov rax, [rsp+16]
    mov rdi, [r12+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET]
    mov rsi, [rax+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET]
    mov rdx, [rax+NEBO_PENDING_RECORD_BINDING_ID_OFFSET]
    lea rcx, [rsp+32]
    call nebo_dependency_bridge_notify_resolved
    test eax, eax
    jnz .bridge_after_commit
    mov rdi, r14
    mov qword [r14+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], 0
    call nebo_focus_manager_sync
    test eax, eax
    jnz .bridge_after_commit
    mov rdi, [r12+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    lea rsi, [rdi+NEBO_INPUT_REGISTRY_STATE_HASH_OFFSET]
    call nebo_input_registry_state_hash
    mov rdi, [r12+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET]
    lea rsi, [rdi+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    call nebo_pending_registry_state_hash
    lea rsi, [r12+NEBO_SUBMISSION_CONTEXT_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_input_submission_state_hash

    mov rax, [rsp+8]
    mov rdx, [rax+NEBO_INPUT_RECORD_HANDLE_OFFSET]
    mov [r13+NEBO_SUBMISSION_RESULT_INPUT_HANDLE_OFFSET], rdx
    mov rax, [rsp+16]
    mov rdx, [rax+NEBO_PENDING_RECORD_HANDLE_OFFSET]
    mov [r13+NEBO_SUBMISSION_RESULT_PENDING_HANDLE_OFFSET], rdx
    mov rdx, [rax+NEBO_PENDING_RECORD_BINDING_ID_OFFSET]
    mov [r13+NEBO_SUBMISSION_RESULT_BINDING_ID_OFFSET], rdx
    mov rdx, [rax+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET]
    mov [r13+NEBO_SUBMISSION_RESULT_COMPILER_PENDING_ID_OFFSET], rdx
    mov rdx, [rsp+24]
    mov [r13+NEBO_SUBMISSION_RESULT_VALUE_PTR_OFFSET], rdx
    mov [r13+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET], rbx
    mov rdx, [rsp+32]
    mov [r13+NEBO_SUBMISSION_RESULT_ACTIVATION_COUNT_OFFSET], rdx
    mov qword [r13+NEBO_SUBMISSION_RESULT_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    xor eax, eax
    jmp .done

.bridge_after_commit:
    ; Bridge was prevalidated and has no bounded enqueue; reaching this path is internal.
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SUBMISSION_ERROR_DEPENDENCY_BRIDGE
    jmp .publish
.duplicate:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SUBMISSION_ERROR_DUPLICATE_RESOLUTION
    jmp .publish
.value_limit:
    mov rax, [rsp+8]
    or dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_FLAG_VALIDATION_ERROR
    mov qword [rax+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], NEBO_SUBMISSION_ERROR_VALUE_LIMIT
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SUBMISSION_ERROR_VALUE_LIMIT
    jmp .publish
.utf8:
    mov rax, [rsp+8]
    or dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_FLAG_VALIDATION_ERROR
    mov qword [rax+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], NEBO_SUBMISSION_ERROR_INVALID_UTF8
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_SUBMISSION_ERROR_INVALID_UTF8
    jmp .publish
.binding:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SUBMISSION_ERROR_BINDING_MISMATCH
    jmp .publish
.pending_handle:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov edx, NEBO_SUBMISSION_ERROR_PENDING_HANDLE
    jmp .publish
.input_handle:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov edx, NEBO_SUBMISSION_ERROR_INPUT_HANDLE
    jmp .publish
.no_focus:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SUBMISSION_ERROR_NO_FOCUS
    jmp .publish
.bridge:
    mov edx, NEBO_SUBMISSION_ERROR_DEPENDENCY_BRIDGE
.publish:
    mov [r12+NEBO_SUBMISSION_CONTEXT_LAST_STATUS_OFFSET], rax
    mov [r12+NEBO_SUBMISSION_CONTEXT_LAST_ERROR_OFFSET], rdx
    mov [r13+NEBO_SUBMISSION_RESULT_STATUS_OFFSET], rax
    jmp .done
.publish_direct:
    mov [r13+NEBO_SUBMISSION_RESULT_STATUS_OFFSET], rax
    jmp .done
.invalid_no_result:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.done:
    add rsp, 104
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

nebo_input_submission_state_hash:
    sub rsp, 8
    test rdi, rdi
    jz .invalid
    test rsi, rsi
    jz .invalid
    mov eax, NEBO_SUBMISSION_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [rdi+NEBO_SUBMISSION_CONTEXT_SEQUENCE_OFFSET]
    call .mix
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_INPUT_REGISTRY_PTR_OFFSET]
    mov rdx, [rcx+NEBO_INPUT_REGISTRY_STATE_HASH_OFFSET]
    call .mix
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_PENDING_REGISTRY_PTR_OFFSET]
    mov rdx, [rcx+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    call .mix
    mov rcx, [rdi+NEBO_SUBMISSION_CONTEXT_DEPENDENCY_BRIDGE_PTR_OFFSET]
    mov rdx, [rcx+NEBO_DEPENDENCY_BRIDGE_STATE_HASH_OFFSET]
    call .mix
    mov [rsi], rax
    mov [rdi+NEBO_SUBMISSION_CONTEXT_STATE_HASH_OFFSET], rax
    xor eax, eax
    add rsp, 8
    ret
.invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    add rsp, 8
    ret
.mix:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_SUBMISSION_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
