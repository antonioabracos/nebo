; Nebo Console Runtime ABI v0 — headless ConsoleManager, registry and lifecycle
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/document/console_document.inc"

global nebo_console_runtime_abi_version
global nebo_console_runtime_context_init
global nebo_console_runtime_context_validate
global nebo_console_runtime_shutdown
global nebo_console_manager_default_get_or_create
global nebo_console_manager_named_create
global nebo_console_manager_anonymous_create
global nebo_console_manager_handle_validate
global nebo_console_manager_close
global nebo_console_manager_finalize_close
global nebo_console_manager_reclaim_closed
global nebo_console_manager_note_logical_command
global nebo_console_manager_state_hash
global nebo_console_manager_diagnostic_name

section .rodata align=8
nebo_console_runtime_abi_version: dq NEBO_CONSOLE_RUNTIME_ABI_VERSION

console_diag_none: db 'none'
console_diag_none_len equ $-console_diag_none
console_diag_bad_context: db 'bad-context'
console_diag_bad_context_len equ $-console_diag_bad_context
console_diag_abi_mismatch: db 'abi-mismatch'
console_diag_abi_mismatch_len equ $-console_diag_abi_mismatch
console_diag_bad_capacity: db 'bad-capacity'
console_diag_bad_capacity_len equ $-console_diag_bad_capacity
console_diag_handle_invalid: db 'handle-invalid'
console_diag_handle_invalid_len equ $-console_diag_handle_invalid
console_diag_handle_closed: db 'handle-closed'
console_diag_handle_closed_len equ $-console_diag_handle_closed
console_diag_limit: db 'limit-exceeded'
console_diag_limit_len equ $-console_diag_limit
console_diag_bad_name: db 'bad-name'
console_diag_bad_name_len equ $-console_diag_bad_name
console_diag_bad_state: db 'bad-state'
console_diag_bad_state_len equ $-console_diag_bad_state
console_diag_command_queue_full: db 'command-queue-full'
console_diag_command_queue_full_len equ $-console_diag_command_queue_full
console_diag_event_queue_full: db 'event-queue-full'
console_diag_event_queue_full_len equ $-console_diag_event_queue_full
console_diag_platform_failure: db 'platform-failure'
console_diag_platform_failure_len equ $-console_diag_platform_failure
console_diag_no_progress: db 'no-progress'
console_diag_no_progress_len equ $-console_diag_no_progress

section .text

; context_init(context*, slots*, capacity, runtime_abi_version)
nebo_console_runtime_context_init:
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
    jz .init_invalid_no_context
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_CONSOLE_CONTEXT_QWORDS
    rep stosq
    cmp r15, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    jne .init_abi_mismatch
    test r13, r13
    jz .init_bad_capacity
    test r14, r14
    jz .init_bad_capacity
    cmp r14, NEBO_CONSOLE_MAX_ACTIVE
    ja .init_bad_capacity

    mov rdi, r13
    xor eax, eax
    mov rcx, r14
    shl rcx, 3
    rep stosq
    xor ebx, ebx
.init_generation_loop:
    cmp rbx, r14
    jae .init_commit
    mov rax, rbx
    shl rax, 6
    mov dword [r13+rax+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], 1
    inc rbx
    jmp .init_generation_loop

.init_commit:
    mov qword [r12+NEBO_CONSOLE_CONTEXT_VERSION_OFFSET], NEBO_CONSOLE_RUNTIME_ABI_VERSION
    mov qword [r12+NEBO_CONSOLE_CONTEXT_STATE_OFFSET], NEBO_CONSOLE_CONTEXT_STATE_READY
    mov [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET], r13
    mov [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET], r14
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_FLAGS_OFFSET], NEBO_CONSOLE_MANAGER_REQUIRED_FLAGS
    mov qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_SHUTDOWN_STATE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_CONTEXT_RESOURCE_MAX_CONSOLES_OFFSET], NEBO_CONSOLE_MAX_ACTIVE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .init_done

.init_abi_mismatch:
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_ABI_MISMATCH
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_ABI_MISMATCH
    mov eax, NEBO_CONSOLE_STATUS_ABI_MISMATCH
    jmp .init_done
.init_bad_capacity:
    mov qword [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_CAPACITY
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .init_done
.init_invalid_no_context:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; context_validate(context*)
nebo_console_runtime_context_validate:
    test rdi, rdi
    jz .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_VERSION_OFFSET], NEBO_CONSOLE_RUNTIME_ABI_VERSION
    jne .context_abi
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_STATE_OFFSET], NEBO_CONSOLE_CONTEXT_STATE_READY
    jne .context_state
    mov rax, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    test rax, rax
    jz .context_invalid
    mov rax, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    test rax, rax
    jz .context_invalid
    cmp rax, NEBO_CONSOLE_MAX_ACTIVE
    ja .context_invalid
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp rcx, rax
    ja .context_state
    mov rdx, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
    cmp rdx, rcx
    ja .context_state
    mov rax, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_MANAGER_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_MANAGER_REQUIRED_FLAGS
    jne .context_state
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET]
    test rcx, rcx
    jz .context_ok
    cmp rcx, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_HEADLESS_STORAGE_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_SCHEDULER_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOMAINS_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_COMMAND_BUFFERS_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_EVENT_BUFFERS_PTR_OFFSET], 0
    je .context_invalid
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_DOMAIN_CAPACITY_OFFSET]
    cmp rcx, [rdi+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jb .context_state
    cmp rcx, NEBO_CONSOLE_MAX_ACTIVE
    ja .context_state
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_QUEUE_CAPACITY_OFFSET]
    test rcx, rcx
    jz .context_state
    cmp rcx, NEBO_CONSOLE_MAX_PREMOUNT_COMMANDS
    ja .context_state
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_FLAGS_OFFSET]
    test rcx, rcx
    jz .context_document_absent
    cmp rcx, NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENTS_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODES_PTR_OFFSET], 0
    je .context_invalid
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_PTR_OFFSET], 0
    je .context_invalid
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODE_CAPACITY_OFFSET]
    test rcx, rcx
    jz .context_state
    cmp rcx, NEBO_CONSOLE_MAX_NODES_PER_CONSOLE
    ja .context_state
    mov rcx, [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_CAPACITY_OFFSET]
    test rcx, rcx
    jz .context_state
    cmp rcx, NEBO_CONSOLE_MAX_TEXT_BYTES_PER_CONSOLE
    ja .context_state
    jmp .context_ok
.context_document_absent:
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENTS_PTR_OFFSET], 0
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODES_PTR_OFFSET], 0
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_PTR_OFFSET], 0
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODE_CAPACITY_OFFSET], 0
    jne .context_state
    cmp qword [rdi+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_CAPACITY_OFFSET], 0
    jne .context_state
.context_ok:
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.context_abi:
    mov eax, NEBO_CONSOLE_STATUS_ABI_MISMATCH
    ret
.context_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.context_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; Internal allocator:
; RDI=context*, ESI=kind, RDX=TextDescriptor* or zero, RCX=out_handle*.
nebo_console_manager_allocate_internal:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13d, esi
    mov r14, rdx
    mov r15, rcx
    test r15, r15
    jz .allocate_invalid_output
    mov qword [r15], NEBO_CONSOLE_HANDLE_INVALID
    test r12, r12
    jz .allocate_bad_context
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .allocate_context_status
    cmp r13d, NEBO_CONSOLE_KIND_DEFAULT
    jb .allocate_bad_state
    cmp r13d, NEBO_CONSOLE_KIND_ANONYMOUS
    ja .allocate_bad_state

    xor r8d, r8d
    xor r9d, r9d
    cmp r13d, NEBO_CONSOLE_KIND_NAMED
    jne .allocate_name_ready
    test r14, r14
    jz .allocate_bad_name
    cmp word [r14+NEBO_RUNTIME_TEXT_ENCODING_OFFSET], NEBO_RUNTIME_TEXT_ENCODING_UTF8
    jne .allocate_bad_name
    mov r8, [r14+NEBO_RUNTIME_TEXT_DATA_OFFSET]
    mov r9, [r14+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
    test r9, r9
    jz .allocate_name_ready
    test r8, r8
    jz .allocate_bad_name

.allocate_name_ready:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov rax, [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp rax, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .allocate_limit
    cmp rax, NEBO_CONSOLE_MAX_ACTIVE
    jae .allocate_limit
    mov r10, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    xor edx, edx
.allocate_find_slot:
    cmp rdx, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .allocate_limit
    mov rax, rdx
    shl rax, 6
    lea r11, [r10+rax]
    cmp dword [r11+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    je .allocate_found
    inc rdx
    jmp .allocate_find_slot

.allocate_found:
    cmp dword [r11+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], 0
    jne .allocate_generation_ready
    mov dword [r11+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], 1
.allocate_generation_ready:
    mov dword [r11+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_RESERVED
    mov [r11+NEBO_CONSOLE_SLOT_KIND_OFFSET], r13d
    mov eax, NEBO_CONSOLE_SLOT_FLAG_LOGICAL_READY
    cmp r13d, NEBO_CONSOLE_KIND_DEFAULT
    jne .allocate_not_default
    or eax, NEBO_CONSOLE_SLOT_FLAG_DEFAULT
    jmp .allocate_flags_ready
.allocate_not_default:
    cmp r13d, NEBO_CONSOLE_KIND_NAMED
    jne .allocate_anonymous
    or eax, NEBO_CONSOLE_SLOT_FLAG_NAMED
    jmp .allocate_flags_ready
.allocate_anonymous:
    or eax, NEBO_CONSOLE_SLOT_FLAG_ANONYMOUS
.allocate_flags_ready:
    mov [r11+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], eax
    mov [r11+NEBO_CONSOLE_SLOT_NAME_PTR_OFFSET], r8
    mov [r11+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET], r9
    mov qword [r11+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], 0
    mov rax, [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    inc rax
    mov [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET], rax
    mov [r11+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET], rax
    mov qword [r11+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET], 1
    mov qword [r11+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    mov dword [r11+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    inc qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp r13d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .allocate_counts_ready
    inc qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
.allocate_counts_ready:
    mov eax, edx
    mov ecx, [r11+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    shl rcx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    or rax, rcx
    mov r14, rax
    cmp qword [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET], 0
    je .allocate_attach_ready
    mov rdi, r12
    mov rsi, r14
    call nebo_console_runtime_domain_attach
    test eax, eax
    jnz .allocate_attach_rollback
.allocate_attach_ready:
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    cmp r13d, NEBO_CONSOLE_KIND_DEFAULT
    jne .allocate_store
    mov [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], r14
.allocate_store:
    mov [r15], r14
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .allocate_done
.allocate_attach_rollback:
    mov r10d, eax
    mov eax, r14d
    shl rax, 6
    add rax, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    je .allocate_rollback_counts_ready
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp r13d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .allocate_rollback_counts_ready
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET], 0
    je .allocate_rollback_counts_ready
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
.allocate_rollback_counts_ready:
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET], 0
    je .allocate_rollback_sequence_ready
    dec qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
.allocate_rollback_sequence_ready:
    mov dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    mov dword [rax+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_NONE
    mov dword [rax+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_NAME_PTR_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET], 0
    mov qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    mov qword [r15], NEBO_CONSOLE_HANDLE_INVALID
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_PLATFORM_FAILURE
    mov [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], r10
    mov eax, r10d
    jmp .allocate_done

.allocate_bad_name:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_NAME
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .allocate_done
.allocate_limit:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_LIMIT
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .allocate_done
.allocate_bad_state:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_STATE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .allocate_done
.allocate_context_status:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_CONTEXT
    mov [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], rax
    jmp .allocate_done
.allocate_bad_context:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .allocate_done
.allocate_invalid_output:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.allocate_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; default_get_or_create(context*, out_handle*)
nebo_console_manager_default_get_or_create:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .default_invalid
    mov qword [r13], NEBO_CONSOLE_HANDLE_INVALID
    test r12, r12
    jz .default_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .default_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov r14, [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET]
    test r14, r14
    jz .default_create
    mov rdi, r12
    mov rsi, r14
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .default_stale
    mov [r13], r14
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .default_done
.default_stale:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], NEBO_CONSOLE_HANDLE_INVALID
.default_create:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_KIND_DEFAULT
    xor edx, edx
    mov rcx, r13
    call nebo_console_manager_allocate_internal
    jmp .default_done
.default_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.default_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; named_create(context*, TextDescriptor*, out_handle*)
nebo_console_manager_named_create:
    mov rcx, rdx
    mov rdx, rsi
    mov esi, NEBO_CONSOLE_KIND_NAMED
    jmp nebo_console_manager_allocate_internal

; anonymous_create(context*, out_handle*)
nebo_console_manager_anonymous_create:
    mov rcx, rsi
    xor edx, edx
    mov esi, NEBO_CONSOLE_KIND_ANONYMOUS
    jmp nebo_console_manager_allocate_internal

; handle_validate(context*, handle, out_slot_ptr*)
nebo_console_manager_handle_validate:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r14, r14
    jz .validate_invalid_output
    mov qword [r14], 0
    test r12, r12
    jz .validate_invalid_context
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .validate_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    test r13, r13
    jz .validate_invalid_handle
    mov rdx, r13
    shr rdx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .validate_invalid_handle
    mov eax, r13d
    cmp rax, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .validate_invalid_handle
    mov r15, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    shl rax, 6
    add r15, rax
    cmp [r15+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], edx
    jne .validate_closed
    cmp dword [r15+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    je .validate_ok
    cmp dword [r15+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    je .validate_closed
    cmp dword [r15+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    je .validate_closed
    jmp .validate_bad_state
.validate_ok:
    mov [r14], r15
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .validate_done
.validate_invalid_handle:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_HANDLE_INVALID
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    jmp .validate_done
.validate_closed:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_HANDLE_CLOSED
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jmp .validate_done
.validate_bad_state:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_STATE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .validate_done
.validate_invalid_context:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .validate_done
.validate_invalid_output:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.validate_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; close(context*, handle). MF041 reclaims immediately because no domain, native
; window or Pending can exist yet. Later lifecycle fronts replace this policy.
nebo_console_manager_close:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .close_invalid
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .close_done
    mov r14, [rsp]
    cmp qword [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET], 0
    je .close_logical_only
    mov rdi, r12
    mov rsi, r13
    call nebo_console_domain_request_close
    jmp .close_done
.close_logical_only:
    cmp qword [r14+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    jne .close_bad_state
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov r15d, [r14+NEBO_CONSOLE_SLOT_KIND_OFFSET]
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    je .close_bad_state
    cmp r15d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .close_validate_default
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET], 0
    je .close_bad_state
.close_validate_default:
    cmp r15d, NEBO_CONSOLE_KIND_DEFAULT
    jne .close_begin
    cmp [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], r13
    jne .close_bad_state
.close_begin:
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    cmp r15d, NEBO_CONSOLE_KIND_DEFAULT
    jne .close_not_default
    mov qword [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], NEBO_CONSOLE_HANDLE_INVALID
.close_not_default:
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp r15d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .close_counts_ready
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
.close_counts_ready:
    mov eax, [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    inc eax
    jnz .close_generation_ready
    mov eax, 1
.close_generation_ready:
    mov dword [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], eax
    mov dword [r14+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_NONE
    mov dword [r14+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_NAME_PTR_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    inc qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .close_done
.close_bad_state:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_STATE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .close_done
.close_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.close_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; finalize_close(context*, handle). Domain owner only, after queues drain.
nebo_console_manager_finalize_close:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .finalize_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .finalize_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    test r13, r13
    jz .finalize_invalid_handle
    mov rdx, r13
    shr rdx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .finalize_invalid_handle
    mov eax, r13d
    cmp rax, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .finalize_invalid_handle
    mov r14, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    shl rax, 6
    add r14, rax
    cmp [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], edx
    jne .finalize_closed
    cmp dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
    jne .finalize_state
    cmp qword [r14+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    jne .finalize_state
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    je .finalize_state
    mov r15d, [r14+NEBO_CONSOLE_SLOT_KIND_OFFSET]
    cmp r15d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .finalize_default_check
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET], 0
    je .finalize_state
.finalize_default_check:
    cmp r15d, NEBO_CONSOLE_KIND_DEFAULT
    jne .finalize_reclaim
    cmp [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], r13
    jne .finalize_state
    mov qword [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], NEBO_CONSOLE_HANDLE_INVALID
.finalize_reclaim:
    ; MF049 close policy: publish CLOSED_WAITING_RECLAIM after the domain has
    ; drained. Generation advancement and slot reuse happen only at an explicit
    ; safe reclaim epoch.
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    cmp r15d, NEBO_CONSOLE_KIND_ANONYMOUS
    jne .finalize_counts_ready
    dec qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
.finalize_counts_ready:
    inc qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .finalize_done
.finalize_invalid_handle:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_HANDLE_INVALID
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    jmp .finalize_done
.finalize_closed:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_HANDLE_CLOSED
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jmp .finalize_done
.finalize_state:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_STATE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .finalize_done
.finalize_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.finalize_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; reclaim_closed(context*, handle). MF049 only, after queue drain, domain
; join and a safe epoch proven by ConsoleLifecycle.
nebo_console_manager_reclaim_closed:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .reclaim_closed_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .reclaim_closed_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    test r13, r13
    jz .reclaim_closed_handle
    mov eax, r13d
    cmp rax, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .reclaim_closed_handle
    mov rdx, r13
    shr rdx, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    test edx, edx
    jz .reclaim_closed_handle
    mov r14, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    shl rax, 6
    add r14, rax
    cmp [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], edx
    jne .reclaim_closed_handle
    cmp dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    jne .reclaim_closed_state
    cmp qword [r14+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    jne .reclaim_closed_state
    mov eax, [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    inc eax
    jnz .reclaim_closed_generation
    mov eax, 1
.reclaim_closed_generation:
    mov dword [r14+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], eax
    mov dword [r14+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_NONE
    mov dword [r14+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_NAME_PTR_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET], 0
    mov qword [r14+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    inc qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    xor eax, eax
    jmp .reclaim_closed_done
.reclaim_closed_handle:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_HANDLE_CLOSED
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jmp .reclaim_closed_done
.reclaim_closed_state:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_BAD_STATE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .reclaim_closed_done
.reclaim_closed_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.reclaim_closed_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; note_logical_command(context*, handle). This only proves that a logically
; created Console accepts pre-mount work; MF042 owns queues and command payloads.
nebo_console_manager_note_logical_command:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .command_invalid
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .command_done
    mov r14, [rsp]
    mov rax, [r14+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET]
    cmp rax, NEBO_CONSOLE_MAX_PREMOUNT_COMMANDS
    jae .command_limit
    inc rax
    mov [r14+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], rax
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .command_done
.command_limit:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_LIMIT
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .command_done
.command_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.command_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Canonical pointer-free FNV-1a state hash for deterministic headless tests.
nebo_console_manager_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    test r12, r12
    jz .hash_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .hash_invalid
    lea r14, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov r15, [r14+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov eax, NEBO_CONSOLE_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    call .hash_qword
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET]
    call .hash_qword
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET]
    call .hash_qword
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET]
    call .hash_qword
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    call .hash_qword
    mov rdx, [r14+NEBO_CONSOLE_MANAGER_FLAGS_OFFSET]
    call .hash_qword
    xor ebx, ebx
    mov r13, [r14+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
.hash_slot_loop:
    cmp rbx, r13
    jae .hash_finish
    mov rdx, [r15+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_KIND_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET]
    call .hash_qword
    mov rdx, [r15+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET]
    call .hash_qword
    add r15, NEBO_CONSOLE_SLOT_SIZE
    inc rbx
    jmp .hash_slot_loop
.hash_finish:
    test eax, eax
    jnz .hash_done
    mov eax, 1
    jmp .hash_done
.hash_invalid:
    xor eax, eax
.hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.hash_qword:
    push rcx
    mov ecx, 8
.hash_byte:
    movzx esi, dl
    xor eax, esi
    imul eax, eax, NEBO_CONSOLE_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .hash_byte
    pop rcx
    ret

; runtime_shutdown(context*). Immediate logical reclaim is valid only for MF041.
nebo_console_runtime_shutdown:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    test r12, r12
    jz .shutdown_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .shutdown_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    cmp qword [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET], 0
    je .shutdown_logical_only
    mov rdi, r12
    call nebo_console_runtime_headless_shutdown
    test eax, eax
    jnz .shutdown_done
    jmp .shutdown_commit
.shutdown_logical_only:
    mov r13, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov r14, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    xor r15d, r15d
.shutdown_loop:
    cmp r15, r14
    jae .shutdown_commit
    cmp dword [r13+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    je .shutdown_next
    mov eax, [r13+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    inc eax
    jnz .shutdown_generation_ready
    mov eax, 1
.shutdown_generation_ready:
    mov dword [r13+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], eax
    mov dword [r13+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_FREE
    mov dword [r13+NEBO_CONSOLE_SLOT_KIND_OFFSET], NEBO_CONSOLE_KIND_NONE
    mov dword [r13+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_NAME_PTR_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_NAME_LENGTH_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_LOGICAL_SEQUENCE_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_PUBLIC_REFERENCE_COUNT_OFFSET], 0
    mov qword [r13+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
.shutdown_next:
    add r13, NEBO_CONSOLE_SLOT_SIZE
    inc r15
    jmp .shutdown_loop
.shutdown_commit:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    mov qword [rbx+NEBO_CONSOLE_MANAGER_ANONYMOUS_COUNT_OFFSET], 0
    mov qword [rbx+NEBO_CONSOLE_MANAGER_DEFAULT_HANDLE_OFFSET], NEBO_CONSOLE_HANDLE_INVALID
    inc qword [rbx+NEBO_CONSOLE_MANAGER_LOGICAL_SEQUENCE_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_SHUTDOWN_STATE_OFFSET], 1
    mov qword [r12+NEBO_CONSOLE_CONTEXT_STATE_OFFSET], NEBO_CONSOLE_CONTEXT_STATE_SHUTDOWN
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .shutdown_done
.shutdown_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.shutdown_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; diagnostic_name(error_code, out_ptr*, out_len*)
nebo_console_manager_diagnostic_name:
    test rsi, rsi
    jz .diag_invalid
    test rdx, rdx
    jz .diag_invalid
    mov qword [rsi], 0
    mov qword [rdx], 0
    cmp edi, NEBO_CONSOLE_ERROR_NONE
    je .diag_none
    cmp edi, NEBO_CONSOLE_ERROR_BAD_CONTEXT
    je .diag_bad_context
    cmp edi, NEBO_CONSOLE_ERROR_ABI_MISMATCH
    je .diag_abi
    cmp edi, NEBO_CONSOLE_ERROR_BAD_CAPACITY
    je .diag_capacity
    cmp edi, NEBO_CONSOLE_ERROR_HANDLE_INVALID
    je .diag_handle_invalid
    cmp edi, NEBO_CONSOLE_ERROR_HANDLE_CLOSED
    je .diag_handle_closed
    cmp edi, NEBO_CONSOLE_ERROR_LIMIT
    je .diag_limit
    cmp edi, NEBO_CONSOLE_ERROR_BAD_NAME
    je .diag_name
    cmp edi, NEBO_CONSOLE_ERROR_BAD_STATE
    je .diag_state
    cmp edi, NEBO_CONSOLE_ERROR_COMMAND_QUEUE_FULL
    je .diag_command_queue_full
    cmp edi, NEBO_CONSOLE_ERROR_EVENT_QUEUE_FULL
    je .diag_event_queue_full
    cmp edi, NEBO_CONSOLE_ERROR_PLATFORM_FAILURE
    je .diag_platform_failure
    cmp edi, NEBO_CONSOLE_ERROR_NO_PROGRESS
    je .diag_no_progress
    jmp .diag_invalid
.diag_none:
    lea rax, [rel console_diag_none]
    mov ecx, console_diag_none_len
    jmp .diag_store
.diag_bad_context:
    lea rax, [rel console_diag_bad_context]
    mov ecx, console_diag_bad_context_len
    jmp .diag_store
.diag_abi:
    lea rax, [rel console_diag_abi_mismatch]
    mov ecx, console_diag_abi_mismatch_len
    jmp .diag_store
.diag_capacity:
    lea rax, [rel console_diag_bad_capacity]
    mov ecx, console_diag_bad_capacity_len
    jmp .diag_store
.diag_handle_invalid:
    lea rax, [rel console_diag_handle_invalid]
    mov ecx, console_diag_handle_invalid_len
    jmp .diag_store
.diag_handle_closed:
    lea rax, [rel console_diag_handle_closed]
    mov ecx, console_diag_handle_closed_len
    jmp .diag_store
.diag_limit:
    lea rax, [rel console_diag_limit]
    mov ecx, console_diag_limit_len
    jmp .diag_store
.diag_name:
    lea rax, [rel console_diag_bad_name]
    mov ecx, console_diag_bad_name_len
    jmp .diag_store
.diag_state:
    lea rax, [rel console_diag_bad_state]
    mov ecx, console_diag_bad_state_len
    jmp .diag_store
.diag_command_queue_full:
    lea rax, [rel console_diag_command_queue_full]
    mov ecx, console_diag_command_queue_full_len
    jmp .diag_store
.diag_event_queue_full:
    lea rax, [rel console_diag_event_queue_full]
    mov ecx, console_diag_event_queue_full_len
    jmp .diag_store
.diag_platform_failure:
    lea rax, [rel console_diag_platform_failure]
    mov ecx, console_diag_platform_failure_len
    jmp .diag_store
.diag_no_progress:
    lea rax, [rel console_diag_no_progress]
    mov ecx, console_diag_no_progress_len
.diag_store:
    mov [rsi], rax
    mov [rdx], rcx
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.diag_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
