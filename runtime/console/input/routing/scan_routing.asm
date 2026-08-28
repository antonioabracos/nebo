; Nebo runtime scan routing — MF046
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/document/console_document.inc"
%include "runtime/console/input/routing/scan_routing.inc"

; These provider symbols are forward labels in the same monolithic runtime_core
; translation unit. Declaring them extern here makes NASM reject their later
; definitions as inconsistent redefinitions. Keep only references to providers
; that are already textually included before this module.

extern nebo_input_registry_init
extern nebo_input_registry_validate
extern nebo_input_registry_get
extern nebo_input_registry_state_hash
extern nebo_pending_registry_init
extern nebo_pending_registry_validate
extern nebo_pending_registry_get
extern nebo_pending_registry_state_hash

global nebo_input_runtime_init
global nebo_input_runtime_validate
global nebo_input_runtime_registry_for_console
global nebo_console_scan_route
global nebo_console_scan_cancel
global nebo_input_runtime_state_hash

section .text

; input_runtime_init(runtime*, ConsoleRuntimeContext*, storage*) -> status
nebo_input_runtime_init:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r12, r12
    jz .init_invalid_no_runtime
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_INPUT_RUNTIME_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .init_invalid
    test r14, r14
    jz .init_invalid
    mov rdi, r13
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .init_state
    mov r15, [r14+NEBO_INPUT_RUNTIME_STORAGE_CONSOLE_CAPACITY_OFFSET]
    mov rbx, [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_CAPACITY_OFFSET]
    test r15, r15
    jz .init_invalid
    cmp r15, NEBO_CONSOLE_MAX_ACTIVE
    ja .init_limit
    test rbx, rbx
    jz .init_invalid
    cmp rbx, NEBO_INPUT_MAX_PER_CONSOLE
    ja .init_limit
    cmp qword [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET], 0
    je .init_invalid
    cmp qword [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET], 0
    je .init_invalid
    cmp qword [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET], 0
    je .init_invalid
    cmp qword [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET], 0
    je .init_invalid

    mov rdi, [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET]
    xor eax, eax
    imul rcx, r15, NEBO_INPUT_REGISTRY_QWORDS
    cld
    rep stosq
    mov rdi, [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET]
    xor eax, eax
    imul rcx, r15, NEBO_PENDING_REGISTRY_QWORDS
    cld
    rep stosq
    mov rax, r15
    mul rbx
    test rdx, rdx
    jnz .init_limit
    mov [rsp], rax
    mov rdi, [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET]
    xor eax, eax
    mov rcx, [rsp]
    imul rcx, NEBO_INPUT_RECORD_QWORDS
    cld
    rep stosq
    mov rdi, [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET]
    xor eax, eax
    mov rcx, [rsp]
    imul rcx, NEBO_PENDING_RECORD_QWORDS
    cld
    rep stosq

    mov [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET], r13
    mov rax, [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_REGISTRIES_PTR_OFFSET]
    mov [r12+NEBO_INPUT_RUNTIME_INPUT_REGISTRIES_PTR_OFFSET], rax
    mov rax, [r14+NEBO_INPUT_RUNTIME_STORAGE_INPUT_RECORDS_PTR_OFFSET]
    mov [r12+NEBO_INPUT_RUNTIME_INPUT_RECORDS_PTR_OFFSET], rax
    mov rax, [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_REGISTRIES_PTR_OFFSET]
    mov [r12+NEBO_INPUT_RUNTIME_PENDING_REGISTRIES_PTR_OFFSET], rax
    mov rax, [r14+NEBO_INPUT_RUNTIME_STORAGE_PENDING_RECORDS_PTR_OFFSET]
    mov [r12+NEBO_INPUT_RUNTIME_PENDING_RECORDS_PTR_OFFSET], rax
    mov [r12+NEBO_INPUT_RUNTIME_CONSOLE_CAPACITY_OFFSET], r15
    mov [r12+NEBO_INPUT_RUNTIME_INPUT_CAPACITY_OFFSET], rbx
    mov qword [r12+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET], 0
    mov qword [r12+NEBO_INPUT_RUNTIME_FLAGS_OFFSET], NEBO_INPUT_RUNTIME_REQUIRED_FLAGS
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    mov eax, NEBO_SCAN_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_INPUT_RUNTIME_STATE_HASH_OFFSET], rax
    lea rsi, [r12+NEBO_INPUT_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_input_runtime_state_hash
    jmp .init_done
.init_state:
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_BAD_RUNTIME
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .init_done
.init_limit:
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_INPUT_LIMIT
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .init_done
.init_invalid:
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_BAD_ARGUMENT
.init_invalid_no_runtime:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.init_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_input_runtime_validate:
    test rdi, rdi
    jz .validate_invalid
    cmp qword [rdi+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET], 0
    je .validate_invalid
    cmp qword [rdi+NEBO_INPUT_RUNTIME_INPUT_REGISTRIES_PTR_OFFSET], 0
    je .validate_invalid
    cmp qword [rdi+NEBO_INPUT_RUNTIME_INPUT_RECORDS_PTR_OFFSET], 0
    je .validate_invalid
    cmp qword [rdi+NEBO_INPUT_RUNTIME_PENDING_REGISTRIES_PTR_OFFSET], 0
    je .validate_invalid
    cmp qword [rdi+NEBO_INPUT_RUNTIME_PENDING_RECORDS_PTR_OFFSET], 0
    je .validate_invalid
    mov rax, [rdi+NEBO_INPUT_RUNTIME_CONSOLE_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_state
    cmp rax, NEBO_CONSOLE_MAX_ACTIVE
    ja .validate_state
    mov rax, [rdi+NEBO_INPUT_RUNTIME_INPUT_CAPACITY_OFFSET]
    test rax, rax
    jz .validate_state
    cmp rax, NEBO_INPUT_MAX_PER_CONSOLE
    ja .validate_state
    mov rax, [rdi+NEBO_INPUT_RUNTIME_FLAGS_OFFSET]
    and eax, NEBO_INPUT_RUNTIME_REQUIRED_FLAGS
    cmp eax, NEBO_INPUT_RUNTIME_REQUIRED_FLAGS
    jne .validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; registry_for_console(runtime*, handle, out_input_registry**, out_pending_registry**)
nebo_input_runtime_registry_for_console:
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
    test r14, r14
    jz .registry_invalid
    test r15, r15
    jz .registry_invalid
    mov qword [r14], 0
    mov qword [r15], 0
    mov rdi, r12
    call nebo_input_runtime_validate
    test eax, eax
    jnz .registry_done
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .registry_done
    mov eax, r13d
    cmp rax, [r12+NEBO_INPUT_RUNTIME_CONSOLE_CAPACITY_OFFSET]
    jae .registry_invalid
    mov rbx, rax
    imul rax, NEBO_INPUT_REGISTRY_SIZE
    add rax, [r12+NEBO_INPUT_RUNTIME_INPUT_REGISTRIES_PTR_OFFSET]
    mov [r14], rax
    imul rdx, rbx, NEBO_PENDING_REGISTRY_SIZE
    add rdx, [r12+NEBO_INPUT_RUNTIME_PENDING_REGISTRIES_PTR_OFFSET]
    mov [r15], rdx
    cmp qword [rax+NEBO_INPUT_REGISTRY_FLAGS_OFFSET], 0
    jne .registry_validate_existing
    mov rcx, [r12+NEBO_INPUT_RUNTIME_INPUT_CAPACITY_OFFSET]
    mov rsi, rbx
    imul rsi, rcx
    shl rsi, 7
    add rsi, [r12+NEBO_INPUT_RUNTIME_INPUT_RECORDS_PTR_OFFSET]
    mov rdi, rax
    mov rdx, rcx
    mov rcx, r13
    call nebo_input_registry_init
    test eax, eax
    jnz .registry_done
    mov rcx, [r12+NEBO_INPUT_RUNTIME_INPUT_CAPACITY_OFFSET]
    mov rsi, rbx
    imul rsi, rcx
    imul rsi, NEBO_PENDING_RECORD_SIZE
    add rsi, [r12+NEBO_INPUT_RUNTIME_PENDING_RECORDS_PTR_OFFSET]
    mov rdi, [r15]
    mov rdx, rcx
    mov rcx, r13
    call nebo_pending_registry_init
    jmp .registry_done
.registry_validate_existing:
    mov rdi, [r14]
    call nebo_input_registry_validate
    test eax, eax
    jnz .registry_done
    mov rdi, [r15]
    call nebo_pending_registry_validate
    jmp .registry_done
.registry_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.registry_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Cancel one exact routed Scan without fabricating a result.
; RDI=InputRuntime*, RSI=ScanRouteDescriptor* -> Console status.
; Both generational records and all three active counters transition exactly
; once. Resolved, stale, foreign, or mismatched handles are rejected.
nebo_console_scan_cancel:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 56
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .cancel_invalid_no_route
    test r13, r13
    jz .cancel_invalid_no_route
    mov rbx, [r13+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET]
    mov r14, [r13+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET]
    mov r15, [r13+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET]
    test rbx, rbx
    jz .cancel_invalid
    test r14, r14
    jz .cancel_invalid
    test r15, r15
    jz .cancel_invalid
    mov rdi, r12
    call nebo_input_runtime_validate
    test eax, eax
    jnz .cancel_state
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rsi, rbx
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .cancel_state
    mov rdi, r12
    mov rsi, rbx
    lea rdx, [rsp+8]
    lea rcx, [rsp+16]
    call nebo_input_runtime_registry_for_console
    test eax, eax
    jnz .cancel_state
    mov rdi, [rsp+8]
    mov rsi, r14
    lea rdx, [rsp+24]
    call nebo_input_registry_get
    test eax, eax
    jnz .cancel_handle
    mov rdi, [rsp+16]
    mov rsi, r15
    lea rdx, [rsp+32]
    call nebo_pending_registry_get
    test eax, eax
    jnz .cancel_handle

    ; Cross-check the complete route identity before any state mutation.
    mov r10, [rsp+24]
    mov r11, [rsp+32]
    cmp [r10+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], r15
    jne .cancel_state
    cmp [r11+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], r14
    jne .cancel_state
    cmp [r10+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], rbx
    jne .cancel_state
    cmp [r11+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], rbx
    jne .cancel_state
    mov rax, [r13+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    cmp [r10+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], rax
    jne .cancel_state
    cmp [r11+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], rax
    jne .cancel_state
    mov rax, [r13+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET]
    cmp [r10+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], rax
    jne .cancel_state
    cmp [r11+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], rax
    jne .cancel_state
    mov rax, [rsp+8]
    cmp qword [rax+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    je .cancel_state
    mov rax, [rsp+16]
    cmp qword [rax+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    je .cancel_state
    mov rax, [rsp]
    cmp qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 0
    je .cancel_state

    ; Commit the paired cancellation and accounting as one single-writer step.
    inc qword [r12+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET]
    mov rax, [r12+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET]
    mov r10, [rsp+24]
    mov dword [r10+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_CANCELLED
    and dword [r10+NEBO_INPUT_RECORD_FLAGS_OFFSET], ~(NEBO_INPUT_FLAG_ACTIVE | NEBO_INPUT_FLAG_VALIDATION_ERROR)
    mov qword [r10+NEBO_INPUT_RECORD_VALIDATION_ERROR_OFFSET], 0
    mov r11, [rsp+32]
    mov dword [r11+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_CANCELLED
    and qword [r11+NEBO_PENDING_RECORD_FLAGS_OFFSET], ~NEBO_PENDING_FLAG_ACTIVE
    mov [r11+NEBO_PENDING_RECORD_RESOLUTION_SEQUENCE_OFFSET], rax
    mov qword [r11+NEBO_PENDING_RECORD_RESULT_LENGTH_OFFSET], 0
    mov r10, [rsp+8]
    dec qword [r10+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET]
    mov r11, [rsp+16]
    dec qword [r11+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET]
    mov rax, [rsp]
    dec qword [rax+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET]
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET], 0

    mov rdi, r10
    lea rsi, [r10+NEBO_INPUT_REGISTRY_STATE_HASH_OFFSET]
    call nebo_input_registry_state_hash
    test eax, eax
    jnz .cancel_state_after_commit
    mov r11, [rsp+16]
    mov rdi, r11
    lea rsi, [r11+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    call nebo_pending_registry_state_hash
    test eax, eax
    jnz .cancel_state_after_commit
    mov rdi, r12
    lea rsi, [r12+NEBO_INPUT_RUNTIME_STATE_HASH_OFFSET]
    call nebo_input_runtime_state_hash
    test eax, eax
    jnz .cancel_state_after_commit
    mov qword [r13+NEBO_SCAN_ROUTE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r13+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    xor eax, eax
    jmp .cancel_done
.cancel_state_after_commit:
    ; All pointers were prevalidated; a hash failure is an internal invariant.
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SCAN_ERROR_BAD_RUNTIME
    jmp .cancel_publish
.cancel_handle:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov edx, NEBO_SCAN_ERROR_BAD_ROUTE
    jmp .cancel_publish
.cancel_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SCAN_ERROR_BAD_RUNTIME
    jmp .cancel_publish
.cancel_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_SCAN_ERROR_BAD_ROUTE
.cancel_publish:
    mov [r13+NEBO_SCAN_ROUTE_LAST_STATUS_OFFSET], rax
    mov [r13+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET], rdx
    mov [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], rax
    mov [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], rdx
    jmp .cancel_done
.cancel_invalid_no_route:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.cancel_done:
    add rsp, 56
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; scan_route(runtime*, ScanRouteDescriptor*) -> status
nebo_console_scan_route:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 120
    mov r12, rdi
    mov r13, rsi
    test r13, r13
    jz .scan_invalid_no_descriptor
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_PROMPT_NODE_ID_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_OUT_INPUT_NODE_ID_OFFSET], 0
    mov qword [r13+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    mov rdi, r12
    call nebo_input_runtime_validate
    test eax, eax
    jnz .scan_bad_runtime
    mov eax, [r13+NEBO_SCAN_ROUTE_FLAGS_OFFSET]
    and eax, NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    cmp eax, NEBO_SCAN_ROUTE_REQUIRED_FLAGS
    jne .scan_bad_metadata
    cmp qword [r13+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET], 0
    je .scan_bad_metadata
    cmp qword [r13+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET], 0
    je .scan_bad_metadata
    mov ebp, [r13+NEBO_SCAN_ROUTE_KIND_OFFSET]
    cmp ebp, NEBO_SCAN_ROUTE_TEXT_DEFAULT_ROW
    je .scan_default
    cmp ebp, NEBO_SCAN_ROUTE_CONSOLE_INLINE
    je .scan_existing
    cmp ebp, NEBO_SCAN_ROUTE_ANONYMOUS_INLINE
    je .scan_anonymous
    jmp .scan_bad_route
.scan_default:
    mov rdi, [r13+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET]
    call .scan_validate_prompt
    test eax, eax
    jnz .scan_bad_metadata
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    lea rsi, [rsp]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .scan_bad_console_status
    jmp .scan_console_ready
.scan_existing:
    cmp qword [r13+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET], 0
    jne .scan_bad_metadata
    mov rax, [r13+NEBO_SCAN_ROUTE_TARGET_CONSOLE_HANDLE_OFFSET]
    test rax, rax
    jz .scan_bad_console
    mov [rsp], rax
    jmp .scan_console_ready
.scan_anonymous:
    mov rdi, [r13+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET]
    call .scan_validate_prompt
    test eax, eax
    jnz .scan_bad_metadata
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    lea rsi, [rsp]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz .scan_bad_console_status
.scan_console_ready:
    mov r14, [rsp]
    mov [r13+NEBO_SCAN_ROUTE_OUT_CONSOLE_HANDLE_OFFSET], r14
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rsi, r14
    lea rdx, [rsp+8]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .scan_bad_console_status
    mov r15, [rsp+8]                   ; ConsoleSlot*
    mov rdi, [r12+NEBO_INPUT_RUNTIME_CONTEXT_PTR_OFFSET]
    mov rsi, r14
    lea rdx, [rsp+16]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .scan_bad_console_status
    mov rax, [rsp+16]
    mov rax, [rax+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .scan_document
    mov [rsp+24], rax                  ; document*
    mov rdi, r12
    mov rsi, r14
    lea rdx, [rsp+32]
    lea rcx, [rsp+40]
    call nebo_input_runtime_registry_for_console
    test eax, eax
    jnz .scan_bad_runtime
    mov rbx, [rsp+32]                  ; input registry
    mov r11, [rsp+40]                  ; pending registry
    mov rax, [rbx+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET]
    cmp rax, [rbx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .scan_limit
    mov rax, [r11+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET]
    cmp rax, [r11+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .scan_limit
    cmp qword [r15+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], NEBO_INPUT_MAX_PER_CONSOLE
    jae .scan_limit

    ; Stable BindingId and compiler PendingId must be unique per Console.
    xor ecx, ecx
    mov rdx, [rbx+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
.scan_duplicate_loop:
    cmp rcx, [rbx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .scan_find_slots
    mov rax, rcx
    shl rax, 7
    add rax, rdx
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_FREE
    je .scan_duplicate_next
    mov r8, [r13+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    cmp [rax+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], r8
    je .scan_duplicate_binding
    mov r8, [r13+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET]
    cmp [rax+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], r8
    je .scan_duplicate_pending
.scan_duplicate_next:
    inc rcx
    jmp .scan_duplicate_loop

.scan_find_slots:
    xor ecx, ecx
.scan_find_input:
    cmp rcx, [rbx+NEBO_INPUT_REGISTRY_CAPACITY_OFFSET]
    jae .scan_limit
    mov rax, rcx
    shl rax, 7
    add rax, [rbx+NEBO_INPUT_REGISTRY_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_FREE
    je .scan_input_slot_found
    inc rcx
    jmp .scan_find_input
.scan_input_slot_found:
    mov [rsp+48], rcx                  ; input slot index
    mov [rsp+56], rax                  ; input record*
    xor ecx, ecx
.scan_find_pending:
    cmp rcx, [r11+NEBO_PENDING_REGISTRY_CAPACITY_OFFSET]
    jae .scan_limit
    imul rax, rcx, NEBO_PENDING_RECORD_SIZE
    add rax, [r11+NEBO_PENDING_REGISTRY_RECORDS_PTR_OFFSET]
    cmp dword [rax+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_FREE
    je .scan_pending_slot_found
    inc rcx
    jmp .scan_find_pending
.scan_pending_slot_found:
    mov [rsp+64], rcx                  ; pending slot
    mov [rsp+72], rax                  ; pending record*

    mov rdi, [rsp+24]
    mov esi, ebp
    mov rdx, [r13+NEBO_SCAN_ROUTE_PROMPT_DESCRIPTOR_PTR_OFFSET]
    lea rcx, [rsp+80]
    call nebo_console_document_append_scan
    test eax, eax
    jnz .scan_document_status
    mov rbx, [rsp+32]
    mov r11, [rsp+40]

    ; Build handles from the preserved slot generations.
    mov rdx, [rsp+56]
    mov eax, [rsp+48]
    mov ecx, [rdx+NEBO_INPUT_RECORD_GENERATION_OFFSET]
    shl rcx, NEBO_INPUT_HANDLE_GENERATION_SHIFT
    or rax, rcx
    mov [rsp+112], rax                 ; input handle
    mov rdx, [rsp+72]
    mov eax, [rsp+64]
    mov ecx, [rdx+NEBO_PENDING_RECORD_GENERATION_OFFSET]
    shl rcx, NEBO_PENDING_HANDLE_GENERATION_SHIFT
    or rax, rcx
    mov [rsp+104], rax                 ; pending handle

    inc qword [r12+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET]
    mov r10, [r12+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET]
    mov rdx, [rsp+56]
    mov dword [rdx+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    mov rax, [rsp+112]
    mov [rdx+NEBO_INPUT_RECORD_HANDLE_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_INPUT_NODE_ID_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_NODE_ID_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_ROW_NODE_ID_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_ROW_NODE_ID_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_PROMPT_NODE_ID_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_PROMPT_NODE_ID_OFFSET], rax
    mov rax, [rsp+104]
    mov [rdx+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], rax
    mov rax, [r13+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], rax
    mov rax, [r13+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], rax
    mov [rdx+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], r14
    mov [rdx+NEBO_INPUT_RECORD_ROUTE_KIND_OFFSET], ebp
    mov dword [rdx+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_REQUIRED_FLAGS
    mov rax, [r13+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET], rax
    mov [rdx+NEBO_INPUT_RECORD_CREATION_SEQUENCE_OFFSET], r10
    mov rax, [rsp+24]
    mov rax, [rax+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [rdx+NEBO_INPUT_RECORD_DOCUMENT_REVISION_OFFSET], rax

    mov rdx, [rsp+72]
    mov dword [rdx+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    mov rax, [rsp+104]
    mov [rdx+NEBO_PENDING_RECORD_HANDLE_OFFSET], rax
    mov rax, [rsp+112]
    mov [rdx+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], rax
    mov rax, [r13+NEBO_SCAN_ROUTE_COMPILER_PENDING_ID_OFFSET]
    mov [rdx+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], rax
    mov rax, [r13+NEBO_SCAN_ROUTE_BINDING_ID_OFFSET]
    mov [rdx+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], rax
    mov [rdx+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], r14
    mov qword [rdx+NEBO_PENDING_RECORD_TYPE_TAG_OFFSET], NEBO_PENDING_TYPE_TEXT
    mov rax, [r13+NEBO_SCAN_ROUTE_SOURCE_ORDER_OFFSET]
    mov [rdx+NEBO_PENDING_RECORD_SOURCE_ORDER_OFFSET], rax
    mov [rdx+NEBO_PENDING_RECORD_CREATION_SEQUENCE_OFFSET], r10
    mov qword [rdx+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_REQUIRED_FLAGS

    inc qword [rbx+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET]
    inc qword [rbx+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET]
    inc qword [r11+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET]
    inc qword [r11+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET]
    inc qword [r15+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET]
    lea rsi, [rbx+NEBO_INPUT_REGISTRY_STATE_HASH_OFFSET]
    mov rdi, rbx
    call nebo_input_registry_state_hash
    mov r11, [rsp+40]
    lea rsi, [r11+NEBO_PENDING_REGISTRY_STATE_HASH_OFFSET]
    mov rdi, r11
    call nebo_pending_registry_state_hash
    lea rsi, [r12+NEBO_INPUT_RUNTIME_STATE_HASH_OFFSET]
    mov rdi, r12
    call nebo_input_runtime_state_hash

    mov rax, [rsp+112]
    mov [r13+NEBO_SCAN_ROUTE_OUT_INPUT_HANDLE_OFFSET], rax
    mov rax, [rsp+104]
    mov [r13+NEBO_SCAN_ROUTE_OUT_PENDING_HANDLE_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_ROW_NODE_ID_OFFSET]
    mov [r13+NEBO_SCAN_ROUTE_OUT_ROW_NODE_ID_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_PROMPT_NODE_ID_OFFSET]
    mov [r13+NEBO_SCAN_ROUTE_OUT_PROMPT_NODE_ID_OFFSET], rax
    mov rax, [rsp+80+NEBO_SCAN_DOCUMENT_INPUT_NODE_ID_OFFSET]
    mov [r13+NEBO_SCAN_ROUTE_OUT_INPUT_NODE_ID_OFFSET], rax
    mov qword [r13+NEBO_SCAN_ROUTE_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r13+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov qword [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], NEBO_SCAN_ERROR_NONE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .scan_done

.scan_validate_prompt:
    sub rsp, 8
    test rdi, rdi
    jz .scan_prompt_invalid
    cmp word [rdi+NEBO_RUNTIME_TEXT_ENCODING_OFFSET], NEBO_RUNTIME_TEXT_ENCODING_UTF8
    jne .scan_prompt_invalid
    mov rsi, [rdi+NEBO_RUNTIME_TEXT_LENGTH_OFFSET]
    cmp rsi, NEBO_INPUT_TEXT_MAX_BYTES
    ja .scan_prompt_invalid
    test rsi, rsi
    jz .scan_prompt_valid
    mov rdi, [rdi+NEBO_RUNTIME_TEXT_DATA_OFFSET]
    test rdi, rdi
    jz .scan_prompt_invalid
    call nebo_console_basic_validate_utf8
    add rsp, 8
    ret
.scan_prompt_valid:
    xor eax, eax
    add rsp, 8
    ret
.scan_prompt_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    add rsp, 8
    ret

.scan_duplicate_binding:
    mov edx, NEBO_SCAN_ERROR_DUPLICATE_BINDING
    jmp .scan_duplicate
.scan_duplicate_pending:
    mov edx, NEBO_SCAN_ERROR_DUPLICATE_PENDING
.scan_duplicate:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .scan_publish
.scan_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    mov edx, NEBO_SCAN_ERROR_INPUT_LIMIT
    jmp .scan_publish
.scan_document_status:
    mov edx, NEBO_SCAN_ERROR_DOCUMENT
    jmp .scan_publish
.scan_document:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    mov edx, NEBO_SCAN_ERROR_DOCUMENT
    jmp .scan_publish
.scan_bad_console_status:
    mov edx, NEBO_SCAN_ERROR_BAD_CONSOLE
    jmp .scan_publish
.scan_bad_console:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_INVALID
    mov edx, NEBO_SCAN_ERROR_BAD_CONSOLE
    jmp .scan_publish
.scan_bad_route:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_SCAN_ERROR_BAD_ROUTE
    jmp .scan_publish
.scan_bad_metadata:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    mov edx, NEBO_SCAN_ERROR_BAD_METADATA
    jmp .scan_publish
.scan_bad_runtime:
    mov edx, NEBO_SCAN_ERROR_BAD_RUNTIME
    jmp .scan_publish
.scan_invalid_no_descriptor:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .scan_done
.scan_publish:
    mov [r13+NEBO_SCAN_ROUTE_LAST_STATUS_OFFSET], rax
    mov [r13+NEBO_SCAN_ROUTE_LAST_ERROR_OFFSET], rdx
    mov [r12+NEBO_INPUT_RUNTIME_LAST_STATUS_OFFSET], rax
    mov [r12+NEBO_INPUT_RUNTIME_LAST_ERROR_OFFSET], rdx
.scan_done:
    add rsp, 120
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

nebo_input_runtime_state_hash:
    push rbx
    test rdi, rdi
    jz .hash_invalid
    test rsi, rsi
    jz .hash_invalid
    mov eax, NEBO_SCAN_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [rdi+NEBO_INPUT_RUNTIME_CONSOLE_CAPACITY_OFFSET]
    call .mix_qword
    mov rdx, [rdi+NEBO_INPUT_RUNTIME_INPUT_CAPACITY_OFFSET]
    call .mix_qword
    mov rdx, [rdi+NEBO_INPUT_RUNTIME_SEQUENCE_OFFSET]
    call .mix_qword
    mov [rsi], rax
    mov [rdi+NEBO_INPUT_RUNTIME_STATE_HASH_OFFSET], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    pop rbx
    ret
.hash_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    pop rbx
    ret
.mix_qword:
    push rcx
    mov ecx, 8
.mix_byte:
    xor al, dl
    imul eax, eax, NEBO_SCAN_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .mix_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
