; Nebo ConsoleDomain and cooperative scheduler — MF042 headless infrastructure
bits 64
default rel

%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/document/console_document.inc"

global nebo_console_runtime_headless_bind
global nebo_console_runtime_domain_attach
global nebo_console_domain_init
global nebo_console_domain_validate
global nebo_console_domain_from_handle
global nebo_console_domain_send
global nebo_console_domain_request_close
global nebo_console_domain_event_enqueue
global nebo_console_domain_step
global nebo_console_domain_state_hash
global nebo_console_scheduler_init
global nebo_console_scheduler_run
global nebo_console_scheduler_state_hash
global nebo_console_runtime_headless_shutdown

section .text

; headless_bind(context*, HeadlessStorage*)
nebo_console_runtime_headless_bind:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .bind_invalid
    test r13, r13
    jz .bind_invalid
    mov rdi, r12
    call nebo_console_runtime_context_validate
    test eax, eax
    jnz .bind_done
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    jne .bind_state
    cmp qword [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET], 0
    jne .bind_state
    mov r14, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET]
    mov r15, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET]
    test r14, r14
    jz .bind_invalid
    cmp r14, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jb .bind_invalid
    cmp r14, NEBO_CONSOLE_MAX_ACTIVE
    ja .bind_limit
    test r15, r15
    jz .bind_invalid
    cmp r15, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    ja .bind_limit
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET]
    test rax, rax
    jz .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET]
    test rax, rax
    jz .bind_documents_absent
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET], 0
    je .bind_invalid
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET], 0
    je .bind_invalid
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET]
    test rax, rax
    jz .bind_invalid
    cmp rax, NEBO_CONSOLE_MAX_NODES_PER_CONSOLE
    ja .bind_limit
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    test rax, rax
    jz .bind_invalid
    cmp rax, NEBO_CONSOLE_MAX_TEXT_BYTES_PER_CONSOLE
    ja .bind_limit
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], NEBO_CONSOLE_CONTEXT_DOCUMENT_REQUIRED_FLAGS
    jne .bind_invalid
    jmp .bind_documents_ready
.bind_documents_absent:
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET], 0
    jne .bind_invalid
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET], 0
    jne .bind_invalid
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET], 0
    jne .bind_invalid
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET], 0
    jne .bind_invalid
    cmp qword [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], 0
    jne .bind_invalid
.bind_documents_ready:

    mov rdi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET]
    xor eax, eax
    mov rcx, r14
    shl rcx, 5
    cld
    rep stosq

    mov rdi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET]
    xor esi, esi
    mov edx, 1
    call nebo_fake_clock_init
    test eax, eax
    jnz .bind_done
    mov rdi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET]
    mov rsi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET]
    call nebo_fake_platform_init
    test eax, eax
    jnz .bind_done
    mov rdi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET]
    mov rsi, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET]
    mov rdx, r14
    call nebo_console_scheduler_init
    test eax, eax
    jnz .bind_done

    mov [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_STORAGE_PTR_OFFSET], r13
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_SCHEDULER_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOMAINS_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_COMMAND_BUFFERS_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_EVENT_BUFFERS_PTR_OFFSET], rax
    mov [r12+NEBO_CONSOLE_CONTEXT_DOMAIN_CAPACITY_OFFSET], r14
    mov [r12+NEBO_CONSOLE_CONTEXT_QUEUE_CAPACITY_OFFSET], r15
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENTS_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENTS_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODES_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODES_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_PTR_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_PTR_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_NODE_CAPACITY_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODE_CAPACITY_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_TEXT_CAPACITY_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_CAPACITY_OFFSET], rax
    mov rax, [r13+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET]
    mov [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_FLAGS_OFFSET], rax
    mov qword [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET], NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    mov eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_TRACE_HASH_OFFSET], rax
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .bind_done
.bind_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .bind_done
.bind_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .bind_done
.bind_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.bind_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_init(domain*, context*, handle, domain_id, command_buffer*, event_buffer*)
nebo_console_domain_init:
    push rbp
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 8
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    mov r15, rcx
    mov rbx, r8
    mov rbp, r9
    test r12, r12
    jz .domain_init_invalid
    mov rdi, r12
    xor eax, eax
    mov ecx, NEBO_CONSOLE_DOMAIN_QWORDS
    cld
    rep stosq
    test r13, r13
    jz .domain_init_invalid
    test r14, r14
    jz .domain_init_invalid
    test r15, r15
    jz .domain_init_invalid
    test rbx, rbx
    jz .domain_init_invalid
    test rbp, rbp
    jz .domain_init_invalid
    mov rax, [r13+NEBO_CONSOLE_CONTEXT_QUEUE_CAPACITY_OFFSET]
    test rax, rax
    jz .domain_init_invalid
    cmp rax, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    ja .domain_init_limit
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET]
    mov rsi, rbx
    mov rdx, rax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
    mov r8d, NEBO_CONSOLE_QUEUE_FLAG_COMMAND
    call nebo_console_queue_init
    test eax, eax
    jnz .domain_init_done
    mov rax, [r13+NEBO_CONSOLE_CONTEXT_QUEUE_CAPACITY_OFFSET]
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    mov rsi, rbp
    mov rdx, rax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
    mov r8d, NEBO_CONSOLE_QUEUE_FLAG_EVENT
    call nebo_console_queue_init
    test eax, eax
    jnz .domain_init_done
    mov [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET], r13
    mov [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET], r14
    mov [r12+NEBO_CONSOLE_DOMAIN_ID_OFFSET], r15
    mov [r12+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET], r15
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_READY
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_MOUNT_REQUESTED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_FRAME_STATE_OFFSET], NEBO_CONSOLE_FRAME_CLEAN
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_NONE
    mov dword [r12+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET], NEBO_CONSOLE_DEFAULT_FAIRNESS_BUDGET
    mov dword [r12+NEBO_CONSOLE_DOMAIN_FLAGS_OFFSET], NEBO_CONSOLE_DOMAIN_REQUIRED_FLAGS
    mov qword [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET], 0
    mov eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_OFFSET_BASIS
    mov [r12+NEBO_CONSOLE_DOMAIN_TRACE_HASH_OFFSET], rax
    mov qword [r12+NEBO_CONSOLE_DOMAIN_TRACE_SEQUENCE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOMAIN_DOCUMENT_REVISION_OFFSET], 0
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .domain_init_done
.domain_init_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .domain_init_done
.domain_init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.domain_init_done:
    add rsp, 8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    pop rbp
    ret

; domain_validate(domain*)
nebo_console_domain_validate:
    test rdi, rdi
    jz .domain_validate_invalid
    mov rax, [rdi+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    test rax, rax
    jz .domain_validate_invalid
    cmp qword [rdi+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET], 0
    je .domain_validate_invalid
    cmp qword [rdi+NEBO_CONSOLE_DOMAIN_ID_OFFSET], 0
    je .domain_validate_invalid
    mov eax, [rdi+NEBO_CONSOLE_DOMAIN_STATE_OFFSET]
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_READY
    jb .domain_validate_state
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_FAILED
    ja .domain_validate_state
    mov eax, [rdi+NEBO_CONSOLE_DOMAIN_FLAGS_OFFSET]
    and eax, NEBO_CONSOLE_DOMAIN_REQUIRED_FLAGS
    cmp eax, NEBO_CONSOLE_DOMAIN_REQUIRED_FLAGS
    jne .domain_validate_state
    push rdi
    add rdi, NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET
    call nebo_console_queue_validate
    pop rdi
    test eax, eax
    jnz .domain_validate_done
    push rdi
    add rdi, NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET
    call nebo_console_queue_validate
    pop rdi
    test eax, eax
    jnz .domain_validate_done
    mov rdx, [rdi+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    cmp qword [rdx+NEBO_CONSOLE_CONTEXT_DOCUMENT_FLAGS_OFFSET], 0
    jne .domain_validate_document_required
    mov rax, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .domain_validate_done
    jmp .domain_validate_document
.domain_validate_document_required:
    mov rax, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rax, rax
    jz .domain_validate_state
.domain_validate_document:
    push rdi
    mov rdi, rax
    call nebo_console_document_validate
    pop rdi
    test eax, eax
    jnz .domain_validate_done
    mov rax, [rdi+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    cmp [rax+NEBO_CONSOLE_DOCUMENT_OWNER_DOMAIN_PTR_OFFSET], rdi
    jne .domain_validate_state
    mov rdx, [rdi+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    cmp [rax+NEBO_CONSOLE_DOCUMENT_HANDLE_OFFSET], rdx
    jne .domain_validate_state
    mov eax, NEBO_CONSOLE_STATUS_OK
.domain_validate_done:
    ret
.domain_validate_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    ret
.domain_validate_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; domain_attach(context*, handle) — called by ConsoleManager after slot commit.
nebo_console_runtime_domain_attach:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .attach_invalid
    mov rax, [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    jne .attach_state
    mov eax, r13d
    cmp rax, [r12+NEBO_CONSOLE_CONTEXT_DOMAIN_CAPACITY_OFFSET]
    jae .attach_invalid
    mov [rsp], rax
    mov r14, [r12+NEBO_CONSOLE_CONTEXT_DOMAINS_PTR_OFFSET]
    mov rbx, rax
    shl rbx, 8
    add r14, rbx
    cmp dword [r14+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FREE
    jne .attach_state
    mov r15, [r12+NEBO_CONSOLE_CONTEXT_QUEUE_CAPACITY_OFFSET]
    mov rbx, rax
    imul rbx, r15
    shl rbx, 6
    mov r8, [r12+NEBO_CONSOLE_CONTEXT_COMMAND_BUFFERS_PTR_OFFSET]
    add r8, rbx
    mov r9, [r12+NEBO_CONSOLE_CONTEXT_EVENT_BUFFERS_PTR_OFFSET]
    add r9, rbx
    mov rdi, r14
    mov rsi, r12
    mov rdx, r13
    mov rcx, rax
    inc rcx
    call nebo_console_domain_init
    test eax, eax
    jnz .attach_done
    cmp qword [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_FLAGS_OFFSET], 0
    je .attach_platform
    mov rax, [rsp]
    imul rax, NEBO_CONSOLE_DOCUMENT_SIZE
    add rax, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENTS_PTR_OFFSET]
    mov [rsp+8], rax
    mov rdx, [rsp]
    imul rdx, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODE_CAPACITY_OFFSET]
    imul rdx, NEBO_CONSOLE_NODE_HEADER_SIZE
    add rdx, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODES_PTR_OFFSET]
    mov r8, [rsp]
    imul r8, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_CAPACITY_OFFSET]
    add r8, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_PTR_OFFSET]
    mov rdi, rax
    mov rsi, r13
    mov rcx, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_NODE_CAPACITY_OFFSET]
    mov r9, [r12+NEBO_CONSOLE_CONTEXT_DOCUMENT_TEXT_CAPACITY_OFFSET]
    call nebo_console_document_init
    test eax, eax
    jnz .attach_failed_domain
    mov rax, [rsp+8]
    mov [rax+NEBO_CONSOLE_DOCUMENT_OWNER_DOMAIN_PTR_OFFSET], r14
    mov [r14+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET], rax
    mov rdx, [rax+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [r14+NEBO_CONSOLE_DOMAIN_DOCUMENT_REVISION_OFFSET], rdx
.attach_platform:
    mov rdi, [r12+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
    mov rsi, r14
    call nebo_fake_platform_mount
    test eax, eax
    jnz .attach_failed_domain
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov r15, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov eax, r13d
    shl rax, 6
    add r15, rax
    or dword [r15+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], NEBO_CONSOLE_SLOT_FLAG_DOMAIN_BOUND
    mov rbx, [r12+NEBO_CONSOLE_CONTEXT_SCHEDULER_PTR_OFFSET]
    inc qword [rbx+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET]
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .attach_done
.attach_failed_domain:
    mov r15d, eax
    mov rdi, [r14+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rdi, rdi
    jz .attach_clear_domain
    xor eax, eax
    mov ecx, NEBO_CONSOLE_DOCUMENT_QWORDS
    cld
    rep stosq
.attach_clear_domain:
    mov rdi, r14
    xor eax, eax
    mov ecx, NEBO_CONSOLE_DOMAIN_QWORDS
    cld
    rep stosq
    mov eax, r15d
    jmp .attach_done
.attach_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .attach_done
.attach_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.attach_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_from_handle(context*, handle, out_domain**). Active handles only.
nebo_console_domain_from_handle:
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
    jz .from_invalid
    mov qword [r14], 0
    test r12, r12
    jz .from_invalid
    mov rax, [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    jne .from_state
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .from_done
    mov eax, r13d
    cmp rax, [r12+NEBO_CONSOLE_CONTEXT_DOMAIN_CAPACITY_OFFSET]
    jae .from_invalid
    shl rax, 8
    add rax, [r12+NEBO_CONSOLE_CONTEXT_DOMAINS_PTR_OFFSET]
    cmp [rax+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET], r13
    jne .from_state
    mov edx, [rax+NEBO_CONSOLE_DOMAIN_STATE_OFFSET]
    cmp edx, NEBO_CONSOLE_DOMAIN_STATE_READY
    jb .from_state
    cmp edx, NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    ja .from_state
    mov [r14], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .from_done
.from_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .from_done
.from_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.from_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_send(context*, handle, ConsoleCommandDescriptor*)
nebo_console_domain_send:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    xor r15d, r15d
    test r14, r14
    jz .send_invalid
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp+64]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .send_done
    mov r15, [rsp+64]
    mov eax, [r14+NEBO_CONSOLE_COMMAND_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_COMMAND_KIND_MIN
    jb .send_invalid
    cmp eax, NEBO_CONSOLE_COMMAND_KIND_MAX
    ja .send_invalid
    mov rsi, r14
    mov rdi, rsp
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep movsq
    lea rbx, [r15+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET]
    mov rax, [rbx+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    inc rax
    jz .send_limit
    mov [rsp+NEBO_CONSOLE_COMMAND_ID_OFFSET], rax
    mov [rsp+NEBO_CONSOLE_COMMAND_HANDLE_OFFSET], r13
    mov rdi, rbx
    mov rsi, rsp
    call nebo_console_queue_enqueue
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    je .send_full
    test eax, eax
    jnz .send_status
    mov qword [r15+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NONE
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    inc qword [r12+NEBO_CONSOLE_CONTEXT_GLOBAL_EVENT_SEQUENCE_OFFSET]
    cmp dword [r15+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_ACTIVE
    jae .send_ok
    mov eax, r13d
    shl rax, 6
    add rax, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    cmp qword [rax+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET], NEBO_CONSOLE_MAX_PREMOUNT_COMMANDS
    jae .send_limit
    inc qword [rax+NEBO_CONSOLE_SLOT_PREMOUNT_COMMAND_COUNT_OFFSET]
.send_ok:
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .send_done
.send_full:
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_COMMAND_QUEUE_FULL
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_QUEUE_FULL
    mov qword [r15+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_QUEUE_FULL
    mov eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jmp .send_done
.send_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .send_status
.send_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jmp .send_status
.send_status:
    test r15, r15
    jz .send_done
    mov [r15+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], rax
.send_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_request_close(context*, handle). Queue first, then publish CLOSING.
nebo_console_domain_request_close:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov r12, rdi
    mov r13, rsi
    mov rdi, rsp
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rsp+NEBO_CONSOLE_COMMAND_KIND_OFFSET], NEBO_CONSOLE_COMMAND_REQUEST_CLOSE
    test r12, r12
    jz .request_close_invalid
    mov rdi, r12
    mov rsi, r13
    lea rdx, [rsp+64]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz .request_close_done
    mov r14, [rsp+64]
    cmp dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    jne .request_close_state
    mov rdi, r12
    mov rsi, r13
    mov rdx, rsp
    call nebo_console_domain_send
    test eax, eax
    jnz .request_close_done
    mov dword [r14+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .request_close_done
.request_close_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .request_close_done
.request_close_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.request_close_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_event_enqueue(domain*, PlatformEventDescriptor*)
nebo_console_domain_event_enqueue:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 64
    mov r12, rdi
    mov r13, rsi
    test r12, r12
    jz .event_invalid
    test r13, r13
    jz .event_invalid
    mov rdi, r12
    call nebo_console_domain_validate
    test eax, eax
    jnz .event_done
    mov eax, [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET]
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_READY
    je .event_state_ready
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    jne .event_state
.event_state_ready:
    mov eax, [r13+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_EVENT_KIND_MIN
    jb .event_invalid
    cmp eax, NEBO_CONSOLE_EVENT_KIND_MAX
    ja .event_invalid
    mov rax, [r13+NEBO_CONSOLE_EVENT_HANDLE_OFFSET]
    test rax, rax
    jz .event_handle_ready
    cmp rax, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    jne .event_stale
.event_handle_ready:
    mov rsi, r13
    mov rdi, rsp
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep movsq
    lea rbx, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    mov rax, [rbx+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    inc rax
    jz .event_limit
    mov [rsp+NEBO_CONSOLE_EVENT_ID_OFFSET], rax
    cmp qword [rsp+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], 0
    jne .event_enqueue_ready
    mov rax, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    mov [rsp+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
.event_enqueue_ready:
    mov rdi, rbx
    mov rsi, rsp
    call nebo_console_queue_enqueue
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    je .event_full
    test eax, eax
    jnz .event_status
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_done
.event_full:
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_QUEUE_FULL
    mov r14, [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    lea rbx, [r14+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_EVENT_QUEUE_FULL
    mov qword [r14+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_QUEUE_FULL
    mov eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jmp .event_done
.event_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jmp .event_status
.event_stale:
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jmp .event_done
.event_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .event_status
.event_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.event_status:
    test r12, r12
    jz .event_done
    mov [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], rax
.event_done:
    add rsp, 64
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; domain_step(domain*, owner_execution_context, out_progress*)
nebo_console_domain_step:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 80
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    xor r15d, r15d
    test r14, r14
    jz .step_invalid
    mov qword [r14], 0
    mov rdi, r12
    call nebo_console_domain_validate
    test eax, eax
    jnz .step_done
    cmp [r12+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET], r13
    jne .step_owner
    mov ebx, [r12+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET]
    test ebx, ebx
    jnz .step_budget_ready
    mov ebx, 1
.step_budget_ready:
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    mov rsi, rsp
    call nebo_console_queue_peek
    test eax, eax
    jnz .step_commands
    mov eax, [rsp+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    call .is_lifecycle_event
    test eax, eax
    jz .step_commands
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    mov rsi, rsp
    call nebo_console_queue_dequeue
    test eax, eax
    jnz .step_done
    mov rdi, r12
    mov rsi, rsp
    call .apply_event
    test eax, eax
    jnz .step_done
    inc r15
    dec ebx
.step_commands:
    test ebx, ebx
    jz .step_finalize
.step_command_loop:
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET]
    mov rsi, rsp
    call nebo_console_queue_dequeue
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_EMPTY
    je .step_events
    test eax, eax
    jnz .step_done
    mov rdi, r12
    mov rsi, rsp
    call .apply_command
    test eax, eax
    jnz .step_done
    inc r15
    dec ebx
    jnz .step_command_loop
    jmp .step_finalize
.step_events:
    test ebx, ebx
    jz .step_finalize
.step_event_loop:
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    mov rsi, rsp
    call nebo_console_queue_dequeue
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_EMPTY
    je .step_finalize
    test eax, eax
    jnz .step_done
    mov rdi, r12
    mov rsi, rsp
    call .apply_event
    test eax, eax
    jnz .step_done
    inc r15
    dec ebx
    jnz .step_event_loop
.step_finalize:
    cmp dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_REQUESTED
    jne .step_success
    cmp qword [r12+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne .step_success
    cmp qword [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne .step_success
    mov r13, [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    cmp qword [r12+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], 0
    je .step_finalize_manager
    mov rdi, [r13+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
    mov rsi, r12
    call nebo_fake_platform_close
    test eax, eax
    jnz .step_done
.step_finalize_manager:
    mov rdi, r13
    mov rsi, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    call nebo_console_manager_finalize_close
    test eax, eax
    jnz .step_done
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_STOPPED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_CLOSED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_COMPLETE
    mov rax, [r13+NEBO_CONSOLE_CONTEXT_SCHEDULER_PTR_OFFSET]
    cmp qword [rax+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET], 0
    je .step_finalize_count_ready
    dec qword [rax+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET]
.step_finalize_count_ready:
    inc r15
.step_success:
    mov [r14], r15
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_OK
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .step_done
.step_owner:
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_BAD_STATE
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .step_done
.step_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.step_done:
    add rsp, 80
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal helper: mark the domain's live slot CLOSING if still ACTIVE.
; RDI=domain*. Returns status in EAX.
.mark_slot_closing:
    push rbx
    push r12
    mov r12, rdi
    mov rax, [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    test rax, rax
    jz .mark_slot_invalid
    lea rbx, [rax+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov eax, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    cmp rax, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    jae .mark_slot_invalid
    shl rax, 6
    add rax, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov ecx, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET+4]
    cmp [rax+NEBO_CONSOLE_SLOT_GENERATION_OFFSET], ecx
    jne .mark_slot_closed
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    je .mark_slot_commit
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
    je .mark_slot_ok
    jmp .mark_slot_state
.mark_slot_commit:
    mov dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
.mark_slot_ok:
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .mark_slot_done
.mark_slot_closed:
    mov eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jmp .mark_slot_done
.mark_slot_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .mark_slot_done
.mark_slot_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.mark_slot_done:
    pop r12
    pop rbx
    ret

; Internal command mutation by the single domain owner.
.apply_command:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    inc qword [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET]
    inc qword [r12+NEBO_CONSOLE_DOMAIN_TRACE_SEQUENCE_OFFSET]
    mov eax, [r13+NEBO_CONSOLE_COMMAND_KIND_OFFSET]
    mov [r12+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET], eax
    mov rdi, r12
    mov rsi, [r13+NEBO_CONSOLE_COMMAND_ID_OFFSET]
    mov rdx, [r13+NEBO_CONSOLE_COMMAND_SOURCE_ORDER_OFFSET]
    call nebo_console_domain_trace_pair_internal
    mov eax, [r13+NEBO_CONSOLE_COMMAND_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_COMMAND_CREATE_INITIAL_CONTENT
    jb .command_control
    cmp eax, NEBO_CONSOLE_COMMAND_APPEND_BOOL
    jbe .command_document
.command_control:
    cmp eax, NEBO_CONSOLE_COMMAND_REQUEST_CLOSE
    je .command_close
    cmp eax, NEBO_CONSOLE_COMMAND_SHUTDOWN
    je .command_close
    cmp eax, NEBO_CONSOLE_COMMAND_PLATFORM_MOUNTED
    je .command_mounted
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .command_apply_done
.command_document:
    mov rdi, [r12+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    test rdi, rdi
    jz .command_document_state
    mov rsi, r13
    call nebo_console_document_apply_command
    test eax, eax
    jnz .command_apply_done
    mov rdi, [r12+NEBO_CONSOLE_DOMAIN_DOCUMENT_PTR_OFFSET]
    mov rax, [rdi+NEBO_CONSOLE_DOCUMENT_REVISION_OFFSET]
    mov [r12+NEBO_CONSOLE_DOMAIN_DOCUMENT_REVISION_OFFSET], rax
    mov dword [r12+NEBO_CONSOLE_DOMAIN_FRAME_STATE_OFFSET], NEBO_CONSOLE_FRAME_DIRTY_LAYOUT
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .command_apply_done
.command_document_state:
    ; MF042 regression contexts may intentionally bind no document storage.
    ; Preserve the historical queue-only no-op only when the context explicitly
    ; advertises the document-absent compatibility mode.
    mov rax, [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    cmp qword [rax+NEBO_CONSOLE_CONTEXT_DOCUMENT_FLAGS_OFFSET], 0
    jne .command_document_missing
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .command_apply_done
.command_document_missing:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .command_apply_done
.command_mounted:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_ACTIVE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .command_apply_done
.command_close:
    mov rdi, r12
    call .mark_slot_closing
    test eax, eax
    jnz .command_apply_done
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_REQUESTED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_CLOSING
    mov eax, NEBO_CONSOLE_STATUS_OK
.command_apply_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal normalized event mutation by the single domain owner.
.apply_event:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov r13, rsi
    inc qword [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    inc qword [r12+NEBO_CONSOLE_DOMAIN_TRACE_SEQUENCE_OFFSET]
    mov eax, [r13+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    mov [r12+NEBO_CONSOLE_DOMAIN_LAST_EVENT_KIND_OFFSET], eax
    mov rdi, r12
    mov rsi, [r13+NEBO_CONSOLE_EVENT_ID_OFFSET]
    mov rdx, [r13+NEBO_CONSOLE_EVENT_SEQUENCE_OFFSET]
    call nebo_console_domain_trace_pair_internal
    mov eax, [r13+NEBO_CONSOLE_EVENT_KIND_OFFSET]
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    je .event_mounted
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_ACTIVATED
    je .event_active
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_DEACTIVATED
    je .event_inactive
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MINIMIZED
    je .event_minimized
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MAXIMIZED
    je .event_maximized
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_RESTORED
    je .event_active
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    je .event_close
    cmp eax, NEBO_CONSOLE_EVENT_PLATFORM_FAILURE
    je .event_failure
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_mounted:
    mov rax, [r13+NEBO_CONSOLE_EVENT_PAYLOAD0_OFFSET]
    test rax, rax
    jz .event_failure
    mov [r12+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET], rax
    or dword [r12+NEBO_CONSOLE_DOMAIN_FLAGS_OFFSET], NEBO_CONSOLE_DOMAIN_FLAG_MOUNT_EVENT_SEEN
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_ACTIVE
    mov r14, [r12+NEBO_CONSOLE_DOMAIN_CONTEXT_PTR_OFFSET]
    lea rbx, [r14+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov eax, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    shl rax, 6
    add rax, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    or dword [rax+NEBO_CONSOLE_SLOT_FLAGS_OFFSET], NEBO_CONSOLE_SLOT_FLAG_MOUNTED
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_active:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_ACTIVE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_inactive:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_INACTIVE
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_minimized:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_MINIMIZED
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_maximized:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_MAXIMIZED
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_close:
    mov rdi, r12
    call .mark_slot_closing
    test eax, eax
    jnz .event_apply_done
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_REQUESTED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_CLOSING
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .event_apply_done
.event_failure:
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FAILED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET], NEBO_CONSOLE_LIFECYCLE_FAILED
    mov dword [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_REQUESTED
    mov qword [r12+NEBO_CONSOLE_DOMAIN_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_PLATFORM_FAILURE
    mov eax, NEBO_CONSOLE_STATUS_PLATFORM_FAILURE
.event_apply_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

.is_lifecycle_event:
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_MOUNTED
    jb .not_lifecycle
    cmp eax, NEBO_CONSOLE_EVENT_WINDOW_CLOSE_REQUESTED
    jbe .lifecycle
    cmp eax, NEBO_CONSOLE_EVENT_PLATFORM_FAILURE
    je .lifecycle
.not_lifecycle:
    xor eax, eax
    ret
.lifecycle:
    mov eax, 1
    ret

; scheduler_init(scheduler*, domains*, capacity)
nebo_console_scheduler_init:
    test rdi, rdi
    jz .scheduler_init_invalid
    mov r8, rdi
    xor eax, eax
    mov ecx, NEBO_CONSOLE_SCHEDULER_QWORDS
    cld
    rep stosq
    test rsi, rsi
    jz .scheduler_init_invalid_after_zero
    test rdx, rdx
    jz .scheduler_init_invalid_after_zero
    cmp rdx, NEBO_CONSOLE_MAX_ACTIVE
    ja .scheduler_init_limit
    mov [r8+NEBO_CONSOLE_SCHEDULER_DOMAINS_PTR_OFFSET], rsi
    mov [r8+NEBO_CONSOLE_SCHEDULER_CAPACITY_OFFSET], rdx
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET], 0
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_RUN_SEQUENCE_OFFSET], 0
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_TOTAL_PROGRESS_OFFSET], 0
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_FAIRNESS_QUANTUM_OFFSET], NEBO_CONSOLE_DEFAULT_FAIRNESS_BUDGET
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET], 0
    mov qword [r8+NEBO_CONSOLE_SCHEDULER_FLAGS_OFFSET], NEBO_CONSOLE_SCHEDULER_REQUIRED_FLAGS
    mov eax, NEBO_CONSOLE_STATUS_OK
    ret
.scheduler_init_limit:
    mov eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    ret
.scheduler_init_invalid_after_zero:
.scheduler_init_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    ret

; scheduler_run(context*, max_rounds, out_total_progress*)
nebo_console_scheduler_run:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 32
    mov r12, rdi
    mov r13, rsi
    mov r14, rdx
    test r14, r14
    jz .scheduler_run_invalid
    mov qword [r14], 0
    test r12, r12
    jz .scheduler_run_invalid
    test r13, r13
    jz .scheduler_run_invalid
    mov r15, [r12+NEBO_CONSOLE_CONTEXT_SCHEDULER_PTR_OFFSET]
    test r15, r15
    jz .scheduler_run_state
    mov rax, [r15+NEBO_CONSOLE_SCHEDULER_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_SCHEDULER_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_SCHEDULER_REQUIRED_FLAGS
    jne .scheduler_run_state
    mov qword [rsp+8], 0
    xor ebx, ebx
.scheduler_round_loop:
    cmp rbx, r13
    jae .scheduler_run_success
    mov qword [rsp], 0
    mov qword [rsp+24], 0
.scheduler_domain_loop:
    mov rcx, [r15+NEBO_CONSOLE_SCHEDULER_CAPACITY_OFFSET]
    mov r10, [rsp+24]
    cmp r10, rcx
    jae .scheduler_round_done
    mov rax, [r15+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET]
    add rax, r10
    cmp rax, rcx
    jb .scheduler_index_ready
    sub rax, rcx
.scheduler_index_ready:
    shl rax, 8
    add rax, [r15+NEBO_CONSOLE_SCHEDULER_DOMAINS_PTR_OFFSET]
    mov eax, [rax+NEBO_CONSOLE_DOMAIN_STATE_OFFSET]
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_READY
    je .scheduler_step_domain
    cmp eax, NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    jne .scheduler_domain_next
.scheduler_step_domain:
    mov rax, [r15+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET]
    add rax, [rsp+24]
    mov rcx, [r15+NEBO_CONSOLE_SCHEDULER_CAPACITY_OFFSET]
    cmp rax, rcx
    jb .scheduler_step_index_ready
    sub rax, rcx
.scheduler_step_index_ready:
    shl rax, 8
    add rax, [r15+NEBO_CONSOLE_SCHEDULER_DOMAINS_PTR_OFFSET]
    mov rdi, rax
    mov rsi, [rax+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
    lea rdx, [rsp+16]
    call nebo_console_domain_step
    test eax, eax
    jnz .scheduler_run_done
    mov rax, [rsp+16]
    add [rsp], rax
.scheduler_domain_next:
    inc qword [rsp+24]
    jmp .scheduler_domain_loop
.scheduler_round_done:
    inc qword [r15+NEBO_CONSOLE_SCHEDULER_RUN_SEQUENCE_OFFSET]
    mov rax, [r15+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET]
    inc rax
    cmp rax, [r15+NEBO_CONSOLE_SCHEDULER_CAPACITY_OFFSET]
    jb .scheduler_cursor_ready
    xor eax, eax
.scheduler_cursor_ready:
    mov [r15+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET], rax
    mov rax, [rsp]
    add [rsp+8], rax
    add [r15+NEBO_CONSOLE_SCHEDULER_TOTAL_PROGRESS_OFFSET], rax
    test rax, rax
    jz .scheduler_run_success
    inc rbx
    jmp .scheduler_round_loop
.scheduler_run_success:
    mov rax, [rsp+8]
    mov [r14], rax
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .scheduler_run_done
.scheduler_run_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .scheduler_run_done
.scheduler_run_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.scheduler_run_done:
    add rsp, 32
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Close every active headless Console and run domains until idle.
nebo_console_runtime_headless_shutdown:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp, 16
    mov r12, rdi
    test r12, r12
    jz .headless_shutdown_invalid
    mov rax, [r12+NEBO_CONSOLE_CONTEXT_HEADLESS_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_CONTEXT_HEADLESS_REQUIRED_FLAGS
    jne .headless_shutdown_state
    lea rbx, [r12+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET]
    mov r13, [rbx+NEBO_CONSOLE_MANAGER_SLOTS_PTR_OFFSET]
    mov r14, [rbx+NEBO_CONSOLE_MANAGER_CAPACITY_OFFSET]
    xor r15d, r15d
.headless_shutdown_close_loop:
    cmp r15, r14
    jae .headless_shutdown_run
    cmp dword [r13+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    jne .headless_shutdown_next
    mov eax, [r13+NEBO_CONSOLE_SLOT_GENERATION_OFFSET]
    shl rax, NEBO_CONSOLE_HANDLE_GENERATION_SHIFT
    or rax, r15
    mov rdi, r12
    mov rsi, rax
    call nebo_console_manager_close
    test eax, eax
    jnz .headless_shutdown_done
.headless_shutdown_next:
    add r13, NEBO_CONSOLE_SLOT_SIZE
    inc r15
    jmp .headless_shutdown_close_loop
.headless_shutdown_run:
    mov rdi, r12
    mov esi, NEBO_CONSOLE_MAX_QUEUED_COMMANDS
    lea rdx, [rsp]
    call nebo_console_scheduler_run
    test eax, eax
    jnz .headless_shutdown_done
    cmp qword [rbx+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    jne .headless_shutdown_no_progress
    mov rax, [r12+NEBO_CONSOLE_CONTEXT_PLATFORM_PTR_OFFSET]
    mov qword [rax+NEBO_FAKE_PLATFORM_STATE_OFFSET], NEBO_FAKE_PLATFORM_STATE_SHUTDOWN
    mov eax, NEBO_CONSOLE_STATUS_OK
    jmp .headless_shutdown_done
.headless_shutdown_no_progress:
    mov qword [rbx+NEBO_CONSOLE_MANAGER_LAST_ERROR_OFFSET], NEBO_CONSOLE_ERROR_NO_PROGRESS
    mov qword [r12+NEBO_CONSOLE_CONTEXT_LAST_STATUS_OFFSET], NEBO_CONSOLE_STATUS_NO_PROGRESS
    mov eax, NEBO_CONSOLE_STATUS_NO_PROGRESS
    jmp .headless_shutdown_done
.headless_shutdown_state:
    mov eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jmp .headless_shutdown_done
.headless_shutdown_invalid:
    mov eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
.headless_shutdown_done:
    add rsp, 16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Canonical pointer-free domain hash including both queue hashes.
nebo_console_domain_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    mov rdi, r12
    call nebo_console_domain_validate
    test eax, eax
    jnz .domain_hash_invalid
    mov eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_HANDLE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_ID_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov edx, [r12+NEBO_CONSOLE_DOMAIN_STATE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov edx, [r12+NEBO_CONSOLE_DOMAIN_LIFECYCLE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov edx, [r12+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_TRACE_HASH_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_TRACE_SEQUENCE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_DOMAIN_FAKE_WINDOW_HANDLE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov edx, [r12+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov edx, [r12+NEBO_CONSOLE_DOMAIN_LAST_EVENT_KIND_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov r15d, eax
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET]
    call nebo_console_queue_state_hash
    mov r13d, eax
    lea rdi, [r12+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET]
    call nebo_console_queue_state_hash
    mov r14d, eax
    mov eax, r15d
    mov edx, r13d
    call nebo_console_domain_hash_qword_internal
    mov edx, r14d
    call nebo_console_domain_hash_qword_internal
    test eax, eax
    jnz .domain_hash_done
    mov eax, 1
    jmp .domain_hash_done
.domain_hash_invalid:
    xor eax, eax
.domain_hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_console_scheduler_state_hash:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12, rdi
    test r12, r12
    jz .scheduler_hash_invalid
    mov rax, [r12+NEBO_CONSOLE_SCHEDULER_FLAGS_OFFSET]
    and rax, NEBO_CONSOLE_SCHEDULER_REQUIRED_FLAGS
    cmp rax, NEBO_CONSOLE_SCHEDULER_REQUIRED_FLAGS
    jne .scheduler_hash_invalid
    mov eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_OFFSET_BASIS
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_CAPACITY_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_CURSOR_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_RUN_SEQUENCE_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_TOTAL_PROGRESS_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_FAIRNESS_QUANTUM_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET]
    call nebo_console_domain_hash_qword_internal
    mov rdx, [r12+NEBO_CONSOLE_SCHEDULER_FLAGS_OFFSET]
    call nebo_console_domain_hash_qword_internal
    test eax, eax
    jnz .scheduler_hash_done
    mov eax, 1
    jmp .scheduler_hash_done
.scheduler_hash_invalid:
    xor eax, eax
.scheduler_hash_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; Internal pointer-free trace update over two qwords.
nebo_console_domain_trace_pair_internal:
    push rbx
    mov eax, [rdi+NEBO_CONSOLE_DOMAIN_TRACE_HASH_OFFSET]
    test eax, eax
    jnz .domain_trace_seeded
    mov eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_OFFSET_BASIS
.domain_trace_seeded:
    mov r8, rdx
    mov rdx, rsi
    call nebo_console_domain_hash_qword_internal
    mov rdx, r8
    call nebo_console_domain_hash_qword_internal
    mov [rdi+NEBO_CONSOLE_DOMAIN_TRACE_HASH_OFFSET], rax
    pop rbx
    ret
nebo_console_domain_hash_qword_internal:
    push rcx
    mov ecx, 8
.domain_hash_byte:
    movzx esi, dl
    xor eax, esi
    imul eax, eax, NEBO_CONSOLE_DOMAIN_HASH_FNV1A32_PRIME
    shr rdx, 8
    dec ecx
    jnz .domain_hash_byte
    pop rcx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
