; Nebo Console lifecycle, cancellation and safe reclaim — MF049
bits 64
default rel

%include "runtime/console/lifecycle/console_lifecycle.inc"

global nebo_console_lifecycle_runtime_init
global nebo_console_lifecycle_runtime_validate
global nebo_console_lifecycle_register
global nebo_console_lifecycle_validate
global nebo_console_lifecycle_sync
global nebo_console_lifecycle_minimize
global nebo_console_lifecycle_maximize
global nebo_console_lifecycle_restore
global nebo_console_lifecycle_request_close
global nebo_console_lifecycle_drain
global nebo_console_lifecycle_advance_epoch
global nebo_console_lifecycle_try_reclaim
global nebo_console_lifecycle_event_accept
global nebo_console_lifecycle_mark_start_completed
global nebo_console_lifecycle_can_shutdown
global nebo_console_lifecycle_shutdown_if_safe
global nebo_console_lifecycle_state_hash
global nebo_console_lifecycle_runtime_state_hash

section .text

; runtime_init(runtime*, records*, capacity, ConsoleRuntimeContext*)
nebo_console_lifecycle_runtime_init:
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
    jz .runtime_init_invalid_no_runtime
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_LIFECYCLE_RUNTIME_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .runtime_init_invalid
    test r14, r14
    jz .runtime_init_invalid
    cmp r14, NEBO_CONSOLE_MAX_ACTIVE
    ja .runtime_init_limit
    test rbx, rbx
    jz .runtime_init_invalid
    mov rdi, rbx
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .runtime_init_done
    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    imul rcx, NEBO_LIFECYCLE_RECORD_QWORDS
    cld
    rep stosq
    mov [r12+NEBO_LIFECYCLE_RUNTIME_CONTEXT_PTR_OFFSET], rbx
    mov [r12+NEBO_LIFECYCLE_RUNTIME_RECORDS_PTR_OFFSET], r13
    mov [r12+NEBO_LIFECYCLE_RUNTIME_CAPACITY_OFFSET], r14
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET], 1
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_FLAGS_OFFSET], NEBO_LIFECYCLE_RUNTIME_REQUIRED_FLAGS
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_NONE
    lea rsi, [r12+NEBO_LIFECYCLE_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_lifecycle_runtime_state_hash
    xor eax, eax
    jmp .runtime_init_done
.runtime_init_limit:
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_BAD_ARGUMENT
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .runtime_init_done
.runtime_init_invalid:
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_BAD_ARGUMENT
.runtime_init_invalid_no_runtime:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.runtime_init_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_runtime_validate:
    test rdi, rdi
    jz .runtime_validate_invalid
    cmp qword [rdi+NEBO_LIFECYCLE_RUNTIME_CONTEXT_PTR_OFFSET], 0
    je .runtime_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RUNTIME_RECORDS_PTR_OFFSET], 0
    je .runtime_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RUNTIME_CAPACITY_OFFSET]
    test rax, rax
    jz .runtime_validate_state
    cmp rax, NEBO_CONSOLE_MAX_ACTIVE
    ja .runtime_validate_state
    cmp [rdi+NEBO_LIFECYCLE_RUNTIME_COUNT_OFFSET], rax
    ja .runtime_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RUNTIME_FLAGS_OFFSET]
    and eax, NEBO_LIFECYCLE_RUNTIME_REQUIRED_FLAGS
    cmp eax, NEBO_LIFECYCLE_RUNTIME_REQUIRED_FLAGS
    jne .runtime_validate_state
    xor eax, eax
    ret
.runtime_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.runtime_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; register(runtime*, LifecycleBinding*, out_record**)
nebo_console_lifecycle_register:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r14, r14
    jz .register_invalid
    mov qword [r14], 0
    mov rdi, r12
    call nebo_console_lifecycle_runtime_validate
    test eax, eax
    jnz .register_done
    test r13, r13
    jz .register_invalid
    mov r15, [r13+NEBO_LIFECYCLE_BINDING_CONSOLE_HANDLE_OFFSET]
    test r15, r15
    jz .register_invalid
    mov rbx, [r12+NEBO_LIFECYCLE_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rdi, rbx
    mov rsi, r15
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .register_done
    mov eax, r15d
    cmp rax, [r12+NEBO_LIFECYCLE_RUNTIME_CAPACITY_OFFSET]
    jae .register_limit
    imul rax, rax, NEBO_LIFECYCLE_RECORD_SIZE
    add rax, [r12+NEBO_LIFECYCLE_RUNTIME_RECORDS_PTR_OFFSET]
    mov [rsp+8], rax
    cmp dword [rax+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_FREE
    je .register_record_ready
    cmp dword [rax+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_RECLAIMED
    jne .register_state
.register_record_ready:
    mov rdx, [r13+NEBO_LIFECYCLE_BINDING_DOMAIN_PTR_OFFSET]
    test rdx, rdx
    jz .register_invalid
    cmp [rdx+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET], r15
    jne .register_owner
    cmp [rdx+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET], rbx
    jne .register_owner
    mov rcx, [r13+NEBO_LIFECYCLE_BINDING_INPUT_REGISTRY_PTR_OFFSET]
    test rcx, rcx
    jz .register_invalid
    cmp [rcx+NEBO_INPUT_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], r15
    jne .register_owner
    mov r8, [r13+NEBO_LIFECYCLE_BINDING_PENDING_REGISTRY_PTR_OFFSET]
    test r8, r8
    jz .register_invalid
    cmp [r8+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], r15
    jne .register_owner
    mov r9, [r13+NEBO_LIFECYCLE_BINDING_DEPENDENCY_BRIDGE_PTR_OFFSET]
    test r9, r9
    jz .register_invalid
    cmp [r9+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], r15
    jne .register_owner
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_INITIAL_WIDTH_OFFSET]
    test rax, rax
    jz .register_invalid
    mov r11, [r13+NEBO_LIFECYCLE_BINDING_INITIAL_HEIGHT_OFFSET]
    test r11, r11
    jz .register_invalid
    mov r10, [rsp+8]
    mov r11d, [r10+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    mov rdi, r10
    xor eax, eax
    mov ecx, NEBO_LIFECYCLE_RECORD_QWORDS
    cld
    rep stosq
    mov [r10+NEBO_LIFECYCLE_RECORD_RUNTIME_PTR_OFFSET], r12
    mov [r10+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET], rbx
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_DOMAIN_PTR_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET], rax
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_INPUT_REGISTRY_PTR_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET], rax
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_PENDING_REGISTRY_PTR_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET], rax
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_DEPENDENCY_BRIDGE_PTR_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET], rax
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_FOCUS_MANAGER_PTR_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_FOCUS_MANAGER_PTR_OFFSET], rax
    mov [r10+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET], r15
    mov dword [r10+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CREATED
    mov dword [r10+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_REGISTERED
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_INITIAL_WIDTH_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET], rax
    mov [r10+NEBO_LIFECYCLE_RECORD_RESTORE_WIDTH_OFFSET], rax
    mov rax, [r13+NEBO_LIFECYCLE_BINDING_INITIAL_HEIGHT_OFFSET]
    mov [r10+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET], rax
    mov [r10+NEBO_LIFECYCLE_RECORD_RESTORE_HEIGHT_OFFSET], rax
    mov rax, [rsp]
    cmp dword [rax+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_DEFAULT
    jne .register_counts
    or dword [r10+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_DEFAULT_KIND
.register_counts:
    cmp r11d, NEBO_LIFECYCLE_STATE_FREE
    jne .register_active_count
    inc qword [r12+NEBO_LIFECYCLE_RUNTIME_COUNT_OFFSET]
.register_active_count:
    inc qword [r12+NEBO_LIFECYCLE_RUNTIME_ACTIVE_COUNT_OFFSET]
    cmp r11d, NEBO_LIFECYCLE_STATE_RECLAIMED
    jne .register_publish
    cmp qword [r12+NEBO_LIFECYCLE_RUNTIME_RECLAIMED_COUNT_OFFSET], 0
    je .register_publish
    dec qword [r12+NEBO_LIFECYCLE_RUNTIME_RECLAIMED_COUNT_OFFSET]
.register_publish:
    mov [r14], r10
    mov rdi, r10
    lea rsi, [r10+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    lea rsi, [r12+NEBO_LIFECYCLE_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_console_lifecycle_runtime_state_hash
    xor eax, eax
    jmp .register_done
.register_owner:
    mov qword [r12+NEBO_LIFECYCLE_RUNTIME_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_OWNER_MISMATCH
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .register_done
.register_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .register_done
.register_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .register_done
.register_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.register_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_validate:
    test rdi, rdi
    jz .record_validate_invalid
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_RUNTIME_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET], 0
    je .record_validate_state
    cmp qword [rdi+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET], 0
    je .record_validate_state
    mov eax, [rdi+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    cmp eax, NEBO_LIFECYCLE_STATE_CREATED
    jb .record_validate_state
    cmp eax, NEBO_LIFECYCLE_STATE_RECLAIMED
    ja .record_validate_state
    mov eax, [rdi+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET]
    and eax, NEBO_LIFECYCLE_REQUIRED_FLAGS
    cmp eax, NEBO_LIFECYCLE_REQUIRED_FLAGS
    jne .record_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET]
    mov rdx, [rdi+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    cmp [rax+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET], rdx
    jne .record_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET]
    cmp [rax+NEBO_INPUT_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .record_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET]
    cmp [rax+NEBO_PENDING_REGISTRY_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .record_validate_state
    mov rax, [rdi+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET]
    cmp [rax+NEBO_DEPENDENCY_BRIDGE_OWNER_CONSOLE_HANDLE_OFFSET], rdx
    jne .record_validate_state
    xor eax, eax
    ret
.record_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.record_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; Synchronize the retained lifecycle view with the single-writer domain state.
nebo_console_lifecycle_sync:
    push rbx
    mov rbx, rdi
    call nebo_console_lifecycle_validate
    test eax, eax
    jnz .sync_done
    mov rax, [rbx+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET]
    mov ecx, [rax+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET]
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_MOUNT_REQUESTED
    je .sync_mounting
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_ACTIVE
    je .sync_active
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_INACTIVE
    je .sync_active_commit
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_MINIMIZED
    je .sync_minimized
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_MAXIMIZED
    je .sync_maximized
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_CLOSING
    je .sync_closing
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_CLOSED
    je .sync_closed
    cmp ecx, NEBO_CONSOLE_LIFECYCLE_FAILED
    je .sync_failed
    xor eax, eax
    jmp .sync_done
.sync_mounting:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MOUNTING
    jmp .sync_commit
.sync_active:
    mov eax, [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    cmp eax, NEBO_LIFECYCLE_STATE_CREATED
    je .sync_visible
    cmp eax, NEBO_LIFECYCLE_STATE_MOUNTING
    je .sync_visible
.sync_active_commit:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_ACTIVE
    jmp .sync_commit
.sync_visible:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_VISIBLE
    jmp .sync_commit
.sync_minimized:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MINIMIZED
    jmp .sync_commit
.sync_maximized:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MAXIMIZED
    jmp .sync_commit
.sync_closing:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSING
    jmp .sync_commit
.sync_closed:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSED
    jmp .sync_commit
.sync_failed:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_FAILED
.sync_commit:
    mov rdi, rbx
    lea rsi, [rbx+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    xor eax, eax
.sync_done:
    pop rbx
    ret

; Internal platform event transition. RDI=record*, ESI=event kind.
nebo_console_lifecycle_transition_event_internal:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13d, esi
    mov rdi, r12
    call nebo_console_lifecycle_validate
    test eax, eax
    jnz .transition_done
    test dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_CLOSE_BARRIER
    jnz .transition_barrier
    mov r14, [r12+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET]
    mov rdi, [r14+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
    mov rsi, [r12+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET]
    mov edx, r13d
    xor ecx, ecx
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    test eax, eax
    jnz .transition_done
    mov rdi, r14
    mov esi, 1
    lea rdx, [rsp]
    call nebo_console_scheduler_run
    test eax, eax
    jnz .transition_done
    mov rdi, r12
    call nebo_console_lifecycle_sync
    jmp .transition_done
.transition_barrier:
    mov qword [r12+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_CLOSE_BARRIER
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.transition_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_minimize:
    push rbx
    mov rbx, rdi
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    call nebo_console_lifecycle_transition_event_internal
    test eax, eax
    jnz .minimize_done
    mov rax, [rbx+NEBO_LIFECYCLE_RECORD_FOCUS_MANAGER_PTR_OFFSET]
    test rax, rax
    jz .minimize_ok
    mov rdi, rax
    xor esi, esi
    call nebo_focus_manager_set_window_active
.minimize_ok:
    xor eax, eax
.minimize_done:
    pop rbx
    ret

; maximize(record*, width, height)
nebo_console_lifecycle_maximize:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov rbx, rdi
    mov r12, rsi
    mov r13, rdx
    test rbx, rbx
    jz .maximize_invalid
    test r12, r12
    jz .maximize_invalid
    test r13, r13
    jz .maximize_invalid
    mov r14, [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET]
    mov r15, [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET]
    mov eax, [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    mov [rsp], rax
    mov rdi, rbx
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    call nebo_console_lifecycle_transition_event_internal
    test eax, eax
    jnz .maximize_done
    cmp dword [rsp], NEBO_LIFECYCLE_STATE_MAXIMIZED
    je .maximize_geometry
    mov [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_WIDTH_OFFSET], r14
    mov [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_HEIGHT_OFFSET], r15
.maximize_geometry:
    mov [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET], r12
    mov [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET], r13
    mov rdi, rbx
    lea rsi, [rbx+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    xor eax, eax
    jmp .maximize_done
.maximize_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.maximize_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_restore:
    push rbx
    mov rbx, rdi
    mov rdi, rbx
    mov esi, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    call nebo_console_lifecycle_transition_event_internal
    test eax, eax
    jnz .restore_done
    mov rax, [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_WIDTH_OFFSET]
    mov [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET], rax
    mov rax, [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_HEIGHT_OFFSET]
    mov [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET], rax
    mov rax, [rbx+NEBO_LIFECYCLE_RECORD_FOCUS_MANAGER_PTR_OFFSET]
    test rax, rax
    jz .restore_ok
    mov rdi, rax
    mov esi, 1
    call nebo_focus_manager_set_window_active
.restore_ok:
    mov dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_ACTIVE
    mov rdi, rbx
    lea rsi, [rbx+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    xor eax, eax
.restore_done:
    pop rbx
    ret

; Direct deterministic cancellation. RDI=record*.
nebo_console_lifecycle_cancel_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov qword [rsp], 0
    mov qword [rsp+8], 0

    mov r13, [r12+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET]
    mov r14, [r13+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    xor ebx, ebx
.cancel_input_loop:
    cmp rbx, [r13+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .cancel_pending_begin
    mov rax, rbx
    shl rax, 7
    add rax, r14
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne .cancel_input_next
    mov dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_CANCELLED
    and dword [rax+NEBO_INPUT_RECORD_FLAGS_OFFSET], ~(NEBO_INPUT_FLAG_ACTIVE | NEBO_INPUT_FLAG_VALIDATION_ERROR)
    mov qword [rax+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], 0
.cancel_input_next:
    inc rbx
    jmp .cancel_input_loop
.cancel_pending_begin:
    mov qword [r13+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    mov r13, [r12+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET]
    mov r14, [r13+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET]
    xor ebx, ebx
.cancel_pending_loop:
    cmp rbx, [r13+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .cancel_dependency_begin
    imul rax, rbx, NEBO_PENDING_RECORD_SIZE
    add rax, r14
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne .cancel_pending_next
    mov dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_CANCELLED
    and qword [rax+NEBO_PENDING_RECORD_FLAGS_OFFSET], ~NEBO_PENDING_FLAG_ACTIVE
    mov qword [rax+NEBO_PENDING_RECORD_RESULT_LENGTH_OFFSET], 0
    inc qword [rsp]
.cancel_pending_next:
    inc rbx
    jmp .cancel_pending_loop
.cancel_dependency_begin:
    mov qword [r13+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    mov r13, [r12+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET]
    mov r14, [r13+NEBO_DEPENDENCY_BRIDGE_RECORDS_PTR_OFFSET]
    xor ebx, ebx
.cancel_dependency_loop:
    cmp rbx, [r13+NEBO_DEPENDENCY_BRIDGE_COUNT_OFFSET]
    jae .cancel_focus
    imul rax, rbx, NEBO_DEPENDENCY_CONTINUATION_SIZE
    add rax, r14
    cmp dword [rax+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_WAITING
    jne .cancel_dependency_next
    mov dword [rax+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_CANCELLED
    inc qword [rsp+8]
.cancel_dependency_next:
    inc rbx
    jmp .cancel_dependency_loop
.cancel_focus:
    mov r15, [r12+NEBO_LIFECYCLE_RECORD_FOCUS_MANAGER_PTR_OFFSET]
    test r15, r15
    jz .cancel_slot
    mov qword [r15+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], 0
    mov qword [r15+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 0
    inc qword [r15+NEBO_FOCUS_MANAGER_REVISION_OFFSET]
    mov r13, [r15+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET]
    xor ebx, ebx
.cancel_editor_loop:
    cmp rbx, [r15+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET]
    jae .cancel_slot
    imul rax, rbx, NEBO_TEXT_EDIT_RECORD_SIZE
    add rax, r13
    cmp qword [rax+NEBO_TEXT_EDIT_INPUT_HANDLE_OFFSET], 0
    je .cancel_editor_next
    or qword [rax+NEBO_TEXT_EDIT_FLAGS_OFFSET], NEBO_TEXT_EDIT_FLAG_RESOLVED | NEBO_TEXT_EDIT_FLAG_IMMUTABLE
.cancel_editor_next:
    inc rbx
    jmp .cancel_editor_loop
.cancel_slot:
    mov r13, [r12+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET]
    lea r14, [r13+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov eax, [r12+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    shl rax, 6
    add rax, [r14+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    mov rax, [rsp]
    mov [r12+NEBO_LIFECYCLE_RECORD_CANCELLED_PENDING_OFFSET], rax
    mov rax, [rsp+8]
    mov [r12+NEBO_LIFECYCLE_RECORD_CANCELLED_DEPENDENCIES_OFFSET], rax
    or dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_PENDING_CANCELLED | NEBO_LIFECYCLE_FLAG_DEPENDENCIES_CANCELLED

    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET]
    lea rsi, [rdi+NEBO_INPUT_REGISTRY_STATE_HASH_OFFSET]
    call nebo_input_registry_state_hash
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET]
    lea rsi, [rdi+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    call nebo_pending_registry_state_hash
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET]
    lea rsi, [rdi+NEBO_DEPENDENCY_BRIDGE_STATE_HASH_OFFSET]
    call nebo_dependency_bridge_state_hash
    test r15, r15
    jz .cancel_hash_record
    mov rdi, r15
    lea rsi, [r15+NEBO_FOCUS_MANAGER_STATE_HASH_OFFSET]
    call nebo_focus_manager_state_hash
.cancel_hash_record:
    mov rdi, r12
    lea rsi, [r12+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    xor eax, eax
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_request_close:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov rdi, r12
    call nebo_console_lifecycle_validate
    test eax, eax
    jnz .request_done
    mov eax, [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    cmp eax, NEBO_LIFECYCLE_STATE_VISIBLE
    jb .request_state
    cmp eax, NEBO_LIFECYCLE_STATE_MAXIMIZED
    ja .request_state
    test dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_CLOSE_BARRIER
    jnz .request_state
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_INPUT_REGISTRY_PTR_OFFSET]
    call nebo_input_registry_validate
    test eax, eax
    jnz .request_done
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_PENDING_REGISTRY_PTR_OFFSET]
    call nebo_pending_registry_validate
    test eax, eax
    jnz .request_done
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_DEPENDENCY_BRIDGE_PTR_OFFSET]
    call nebo_dependency_bridge_validate
    test eax, eax
    jnz .request_done
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET]
    mov rsi, [r12+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    call nebo_console_domain_request_close
    test eax, eax
    jnz .request_done
    mov dword [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSING
    or dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_CLOSE_BARRIER
    mov r13, [r12+NEBO_LIFECYCLE_RECORD_RUNTIME_PTR_OFFSET]
    inc qword [r13+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET]
    mov rax, [r13+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET]
    mov [r12+NEBO_LIFECYCLE_RECORD_CLOSE_SEQUENCE_OFFSET], rax
    cmp qword [r13+NEBO_LIFECYCLE_RUNTIME_ACTIVE_COUNT_OFFSET], 0
    je .request_counts
    dec qword [r13+NEBO_LIFECYCLE_RUNTIME_ACTIVE_COUNT_OFFSET]
.request_counts:
    inc qword [r13+NEBO_LIFECYCLE_RUNTIME_CLOSING_COUNT_OFFSET]
    mov rdi, r12
    call nebo_console_lifecycle_cancel_internal
    test eax, eax
    jnz .request_done
    mov rdi, r12
    lea rsi, [r12+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    lea rsi, [r13+NEBO_LIFECYCLE_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r13
    call nebo_console_lifecycle_runtime_state_hash
    xor eax, eax
    jmp .request_done
.request_state:
    mov qword [r12+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.request_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; drain(record*, out_progress*) — queue drain, fake-platform close and domain join.
nebo_console_lifecycle_drain:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .drain_invalid
    mov qword [r13], 0
    mov rdi, r12
    call nebo_console_lifecycle_validate
    test eax, eax
    jnz .drain_done
    cmp dword [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSING
    jne .drain_state
    test dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_CLOSE_BARRIER
    jz .drain_state
    mov r14, [r12+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET]
    mov rdi, r14
    mov esi, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    mov rdx, r13
    call nebo_console_scheduler_run
    test eax, eax
    jnz .drain_done
    mov rbx, [r12+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET]
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_COMPLETE
    jne .drain_required
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne .drain_required
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne .drain_required
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], 0
    jne .drain_required
    lea rax, [r14+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov edx, [r12+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    shl rdx, 6
    add rdx, [rax+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    cmp dword [rdx+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    jne .drain_required
    mov dword [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSED
    or dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_QUEUES_DRAINED | NEBO_LIFECYCLE_FLAG_DOMAIN_JOINED
    mov rbx, [r12+NEBO_LIFECYCLE_RECORD_RUNTIME_PTR_OFFSET]
    mov rax, [rbx+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET]
    mov [r12+NEBO_LIFECYCLE_RECORD_DRAIN_SEQUENCE_OFFSET], rax
    inc rax
    mov [r12+NEBO_LIFECYCLE_RECORD_RECLAIM_EPOCH_OFFSET], rax
    cmp qword [rbx+NEBO_LIFECYCLE_RUNTIME_CLOSING_COUNT_OFFSET], 0
    je .drain_counts
    dec qword [rbx+NEBO_LIFECYCLE_RUNTIME_CLOSING_COUNT_OFFSET]
.drain_counts:
    inc qword [rbx+NEBO_LIFECYCLE_RUNTIME_CLOSED_COUNT_OFFSET]
    mov rdi, r12
    lea rsi, [r12+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    xor eax, eax
    jmp .drain_done
.drain_required:
    mov qword [r12+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_DRAIN_REQUIRED
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
    jmp .drain_done
.drain_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .drain_done
.drain_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.drain_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_advance_epoch:
    push rbx
    mov rbx, rdi
    call nebo_console_lifecycle_runtime_validate
    test eax, eax
    jnz .epoch_done
    mov rax, [rbx+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET]
    inc rax
    jz .epoch_limit
    mov [rbx+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET], rax
    mov [rbx+NEBO_LIFECYCLE_RUNTIME_SAFE_EPOCH_OFFSET], rax
    xor eax, eax
    jmp .epoch_done
.epoch_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
.epoch_done:
    pop rbx
    ret

nebo_console_lifecycle_try_reclaim:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov rdi, r12
    call nebo_console_lifecycle_validate
    test eax, eax
    jnz .reclaim_done
    cmp dword [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CLOSED
    jne .reclaim_state
    mov eax, [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET]
    and eax, NEBO_LIFECYCLE_FLAG_QUEUES_DRAINED | NEBO_LIFECYCLE_FLAG_DOMAIN_JOINED
    cmp eax, NEBO_LIFECYCLE_FLAG_QUEUES_DRAINED | NEBO_LIFECYCLE_FLAG_DOMAIN_JOINED
    jne .reclaim_drain
    mov r13, [r12+NEBO_LIFECYCLE_RECORD_RUNTIME_PTR_OFFSET]
    mov rax, [r13+NEBO_LIFECYCLE_RUNTIME_SAFE_EPOCH_OFFSET]
    cmp rax, [r12+NEBO_LIFECYCLE_RECORD_RECLAIM_EPOCH_OFFSET]
    jb .reclaim_epoch
    mov rdi, [r12+NEBO_LIFECYCLE_RECORD_CONTEXT_PTR_OFFSET]
    mov rsi, [r12+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    call nebo_console_manager_reclaim_closed
    test eax, eax
    jnz .reclaim_done
    ; The manager releases the generational slot. Publish the already joined
    ; indexed domain storage as reusable before a new handle can attach to it.
    ; Retain the old handle as a tombstone until domain_init resets the block so
    ; the RECLAIMED lifecycle record remains self-consistent.
    mov rbx, [r12+NEBO_LIFECYCLE_RECORD_DOMAIN_PTR_OFFSET]
    mov dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FREE
    mov dword [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_RECLAIMED
    or dword [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET], NEBO_LIFECYCLE_FLAG_RECLAIM_READY
    cmp qword [r13+NEBO_LIFECYCLE_RUNTIME_CLOSED_COUNT_OFFSET], 0
    je .reclaim_counts
    dec qword [r13+NEBO_LIFECYCLE_RUNTIME_CLOSED_COUNT_OFFSET]
.reclaim_counts:
    inc qword [r13+NEBO_LIFECYCLE_RUNTIME_RECLAIMED_COUNT_OFFSET]
    mov rdi, r12
    lea rsi, [r12+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET]
    call nebo_console_lifecycle_state_hash
    lea rsi, [r13+NEBO_LIFECYCLE_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r13
    call nebo_console_lifecycle_runtime_state_hash
    xor eax, eax
    jmp .reclaim_done
.reclaim_epoch:
    mov qword [r12+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_SAFE_EPOCH_REQUIRED
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .reclaim_done
.reclaim_drain:
    mov qword [r12+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_DRAIN_REQUIRED
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .reclaim_done
.reclaim_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.reclaim_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; event_accept(record*, event_console_handle). Old generations are discarded.
nebo_console_lifecycle_event_accept:
    test rdi, rdi
    jz .event_accept_invalid
    cmp rsi, [rdi+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    jne .event_accept_stale
    mov eax, [rdi+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    cmp eax, NEBO_LIFECYCLE_STATE_CLOSING
    jae .event_accept_stale
    xor eax, eax
    ret
.event_accept_stale:
    inc qword [rdi+NEBO_LIFECYCLE_RECORD_LATE_EVENTS_DROPPED_OFFSET]
    mov qword [rdi+NEBO_LIFECYCLE_RECORD_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_STALE_EVENT
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    ret
.event_accept_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

nebo_console_lifecycle_mark_start_completed:
    push rbx
    mov rbx, rdi
    call nebo_console_lifecycle_runtime_validate
    test eax, eax
    jnz .start_done
    mov qword [rbx+NEBO_LIFECYCLE_RUNTIME_START_COMPLETED_OFFSET], 1
    xor eax, eax
.start_done:
    pop rbx
    ret

; can_shutdown(runtime*, out_bool*)
nebo_console_lifecycle_can_shutdown:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .can_shutdown_invalid
    mov qword [r13], 0
    mov rdi, r12
    call nebo_console_lifecycle_runtime_validate
    test eax, eax
    jnz .can_shutdown_done
    cmp qword [r12+NEBO_LIFECYCLE_RUNTIME_START_COMPLETED_OFFSET], 1
    jne .can_shutdown_false
    mov rbx, [r12+NEBO_LIFECYCLE_RUNTIME_CONTEXT_PTR_OFFSET]
    cmp qword [rbx+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    jne .can_shutdown_false
    cmp qword [r12+NEBO_LIFECYCLE_RUNTIME_CLOSING_COUNT_OFFSET], 0
    jne .can_shutdown_false
    cmp qword [r12+NEBO_LIFECYCLE_RUNTIME_CLOSED_COUNT_OFFSET], 0
    jne .can_shutdown_false
    xor ebx, ebx
    mov r14, [r12+NEBO_LIFECYCLE_RUNTIME_RECORDS_PTR_OFFSET]
.can_shutdown_loop:
    cmp rbx, [r12+NEBO_LIFECYCLE_RUNTIME_CAPACITY_OFFSET]
    jae .can_shutdown_true
    imul rax, rbx, NEBO_LIFECYCLE_RECORD_SIZE
    add rax, r14
    mov edx, [rax+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    cmp edx, NEBO_LIFECYCLE_STATE_FREE
    je .can_shutdown_next
    cmp edx, NEBO_LIFECYCLE_STATE_RECLAIMED
    jne .can_shutdown_false
.can_shutdown_next:
    inc rbx
    jmp .can_shutdown_loop
.can_shutdown_true:
    mov qword [r13], 1
.can_shutdown_false:
    xor eax, eax
    jmp .can_shutdown_done
.can_shutdown_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.can_shutdown_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_lifecycle_shutdown_if_safe:
    push rbx
    sub rsp, 16
    mov rbx, rdi
    mov rdi, rbx
    lea rsi, [rsp]
    call nebo_console_lifecycle_can_shutdown
    test eax, eax
    jnz .shutdown_safe_done
    cmp qword [rsp], 1
    jne .shutdown_unsafe
    mov rax, [rbx+NEBO_LIFECYCLE_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rdx, [rax+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
    mov qword [rdx+NEBO_FAKE_PLATFORM_STATE_OFFSET], NEBO_FAKE_PLATFORM_STATE_SHUTDOWN
    mov qword [rax+NEBO_CONSOLE_CONTEXT_SHUTDOWN_STATE_OFFSET], 1
    mov qword [rax+NEBO_CONSOLE_CONTEXT_STATE_OFFSET], NEBO_CONSOLE_CONTEXT_STATE_SHUTDOWN
    or qword [rbx+NEBO_LIFECYCLE_RUNTIME_FLAGS_OFFSET], NEBO_LIFECYCLE_RUNTIME_FLAG_SHUTDOWN_SAFE
    xor eax, eax
    jmp .shutdown_safe_done
.shutdown_unsafe:
    mov qword [rbx+NEBO_LIFECYCLE_RUNTIME_LAST_ERROR_OFFSET], NEBO_LIFECYCLE_ERROR_SHUTDOWN_UNSAFE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
.shutdown_safe_done:
    add rsp, 16
    pop rbx
    ret

nebo_console_lifecycle_state_hash:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .record_hash_invalid
    test r13, r13
    jz .record_hash_invalid
    mov eax, NEBO_LIFECYCLE_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CONSOLE_HANDLE_OFFSET]
    call .mix_record
    mov edx, [r12+NEBO_LIFECYCLE_RECORD_STATE_OFFSET]
    call .mix_record
    mov edx, [r12+NEBO_LIFECYCLE_RECORD_FLAGS_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_RESTORE_WIDTH_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_RESTORE_HEIGHT_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CLOSE_SEQUENCE_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CANCELLED_PENDING_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_CANCELLED_DEPENDENCIES_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_LATE_EVENTS_DROPPED_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_DRAIN_SEQUENCE_OFFSET]
    call .mix_record
    mov rdx, [r12+NEBO_LIFECYCLE_RECORD_RECLAIM_EPOCH_OFFSET]
    call .mix_record
    mov [r13], rax
    mov [r12+NEBO_LIFECYCLE_RECORD_STATE_HASH_OFFSET], rax
    xor eax, eax
    jmp .record_hash_done
.record_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.record_hash_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.mix_record:
    push rcx
    mov ecx, 8
.mix_record_byte:
    xor al, dl
    imul eax, eax, NEBO_LIFECYCLE_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_record_byte
    pop rcx
    ret

nebo_console_lifecycle_runtime_state_hash:
    push rbx
    push r12
    push r13
    push r14
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .runtime_hash_invalid
    test r13, r13
    jz .runtime_hash_invalid
    mov eax, NEBO_LIFECYCLE_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_CAPACITY_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_COUNT_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_EPOCH_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_SAFE_EPOCH_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_ACTIVE_COUNT_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_CLOSING_COUNT_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_CLOSED_COUNT_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_RECLAIMED_COUNT_OFFSET]
    call .mix_runtime
    mov rdx, [r12+NEBO_LIFECYCLE_RUNTIME_START_COMPLETED_OFFSET]
    call .mix_runtime
    mov [r13], rax
    mov [r12+NEBO_LIFECYCLE_RUNTIME_STATE_HASH_OFFSET], rax
    xor eax, eax
    jmp .runtime_hash_done
.runtime_hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.runtime_hash_done:
    add rsp, 8
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.mix_runtime:
    push rcx
    mov ecx, 8
.mix_runtime_byte:
    xor al, dl
    imul eax, eax, NEBO_LIFECYCLE_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_runtime_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
