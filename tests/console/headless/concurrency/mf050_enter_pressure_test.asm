; Nebo Assembly — MF050 ENTER under queue pressure and close-race scenarios
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/input/registry/input_registry.inc"
%include "runtime/console/pending/pending_registry.inc"
%include "runtime/console/input/editing/text_editor.inc"
%include "runtime/console/focus/focus_manager.inc"
%include "runtime/console/layout/console_layout.inc"
%include "runtime/console/dependency-bridge/dependency_bridge.inc"
%include "runtime/console/input/submission/input_submission.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_handle_validate
extern nebo_console_manager_close
extern nebo_console_domain_from_handle
extern nebo_console_domain_send
extern nebo_console_domain_step
extern nebo_console_scheduler_run
extern nebo_input_registry_init
extern nebo_pending_registry_init
extern nebo_text_edit_init
extern nebo_text_edit_insert_utf8
extern nebo_dependency_bridge_init
extern nebo_input_submission_init
extern nebo_input_submission_key
extern neboc_host_process_exit

global _start

%define CONSOLE_CAP 2
%define QUEUE_CAP 2
%define INPUT_CAP 1
%define VALUE_STRIDE 32
%define CONT_CAP 2

section .rodata
enter_text: db 'ok'

section .bss align=64
context: resb NEBO_CONSOLE_CONTEXT_SIZE
slots: resb CONSOLE_CAP*NEBO_CONSOLE_SLOT_SIZE
clock: resb NEBO_FAKE_CLOCK_SIZE
platform: resb NEBO_FAKE_PLATFORM_SIZE
scheduler: resb NEBO_CONSOLE_SCHEDULER_SIZE
domains: resb CONSOLE_CAP*NEBO_CONSOLE_DOMAIN_SIZE
command_buffers: resb CONSOLE_CAP*QUEUE_CAP*NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event_buffers: resb CONSOLE_CAP*QUEUE_CAP*NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
storage: resb NEBO_CONSOLE_HEADLESS_STORAGE_SIZE
handle: resq 1
domain_ptr: resq 1
slot_ptr: resq 1
progress: resq 1
command: resb NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE

input_registry: resb NEBO_INPUT_REGISTRY_SIZE
input_records: resb INPUT_CAP*NEBO_INPUT_RECORD_SIZE
pending_registry: resb NEBO_PENDING_REGISTRY_SIZE
pending_records: resb INPUT_CAP*NEBO_PENDING_RECORD_SIZE
layout_dummy: resb NEBO_LAYOUT_TREE_SIZE
focus: resb NEBO_FOCUS_MANAGER_SIZE
editors: resb INPUT_CAP*NEBO_TEXT_EDIT_RECORD_SIZE
edit_buffers: resb INPUT_CAP*VALUE_STRIDE
bridge: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations: resb CONT_CAP*NEBO_DEPENDENCY_CONTINUATION_SIZE
submission: resb NEBO_SUBMISSION_CONTEXT_SIZE
submission_storage: resb NEBO_SUBMISSION_STORAGE_SIZE
values: resb INPUT_CAP*VALUE_STRIDE
result: resb NEBO_SUBMISSION_RESULT_SIZE

section .text
_start:
    cmp qword [rsp], 2
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    cmp byte [rbx], '1'
    je scenario_1
    cmp byte [rbx], '2'
    je scenario_2
    jmp test_usage

; A full Console command queue cannot lose or duplicate an independent ENTER.
scenario_1:
    call setup_domain
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_TEXT
    mov esi, 1
    call send_command
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_INT
    mov esi, 2
    call send_command
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_BOOL
    mov esi, 3
    call send_command
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne test_fail
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], QUEUE_CAP
    jne test_fail
    call setup_submission
    test eax, eax
    jnz test_fail
    lea rdi, [rel editors]
    lea rsi, [rel enter_text]
    mov edx, 2
    call nebo_text_edit_insert_utf8
    test eax, eax
    jnz test_fail
    lea rdi, [rel submission]
    mov esi, NEBO_FOCUS_KEY_ENTER
    lea rdx, [rel result]
    call nebo_input_submission_key
    test eax, eax
    jnz test_fail
    cmp qword [rel result+NEBO_SUBMISSION_RESULT_VALUE_LENGTH_OFFSET], 2
    jne test_fail
    cmp dword [rel input_records+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_RESOLVED
    jne test_fail
    cmp dword [rel pending_records+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_RESOLVED
    jne test_fail
    cmp qword [rel pending_registry+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], QUEUE_CAP
    jne test_fail
    mov dword [rbx+NEBO_CONSOLE_DOMAIN_FAIRNESS_BUDGET_OFFSET], 1
    mov rdi, rbx
    mov rsi, [rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
    lea rdx, [rel progress]
    call nebo_console_domain_step
    test eax, eax
    jnz test_fail
    cmp qword [rel progress], 1
    jne test_fail
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET], NEBO_CONSOLE_COMMAND_APPEND_TEXT
    jne test_fail
    mov rdi, rbx
    mov rsi, [rbx+NEBO_CONSOLE_DOMAIN_OWNER_EXECUTION_CONTEXT_OFFSET]
    lea rdx, [rel progress]
    call nebo_console_domain_step
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_LAST_COMMAND_KIND_OFFSET], NEBO_CONSOLE_COMMAND_APPEND_INT
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    jmp test_pass

; A close request that races a full queue is rejected atomically, then succeeds
; after owner progress and reaches the delayed-reclaim boundary without UAF.
scenario_2:
    call setup_domain
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_TEXT
    mov esi, 1
    call send_command
    test eax, eax
    jnz test_fail
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_INT
    mov esi, 2
    call send_command
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel handle]
    lea rdx, [rel slot_ptr]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel handle]
    call nebo_console_manager_close
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne test_fail
    mov rax, [rel slot_ptr]
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    jne test_fail
    mov rbx, [rel domain_ptr]
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_NONE
    jne test_fail
    lea rdi, [rel context]
    mov esi, 1
    lea rdx, [rel progress]
    call nebo_console_scheduler_run
    test eax, eax
    jnz test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    lea rdi, [rel context]
    mov rsi, [rel handle]
    call nebo_console_manager_close
    test eax, eax
    jnz test_fail
    mov rax, [rel slot_ptr]
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSING
    jne test_fail
    lea rdi, [rel context]
    mov esi, 4
    lea rdx, [rel progress]
    call nebo_console_scheduler_run
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_STOPPED
    jne test_fail
    mov rax, [rel slot_ptr]
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_CLOSED_WAITING_RECLAIM
    jne test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rel platform+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET], 1
    jne test_fail
    jmp test_pass

setup_domain:
    push rbx
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, CONSOLE_CAP
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .domain_done
    lea rax, [rel clock]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_CLOCK_PTR_OFFSET], rax
    lea rax, [rel platform]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_PLATFORM_PTR_OFFSET], rax
    lea rax, [rel scheduler]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_SCHEDULER_PTR_OFFSET], rax
    lea rax, [rel domains]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAINS_PTR_OFFSET], rax
    lea rax, [rel command_buffers]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_COMMAND_BUFFERS_PTR_OFFSET], rax
    lea rax, [rel event_buffers]
    mov [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_EVENT_BUFFERS_PTR_OFFSET], rax
    mov qword [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOMAIN_CAPACITY_OFFSET], CONSOLE_CAP
    mov qword [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_QUEUE_CAPACITY_OFFSET], QUEUE_CAP
    mov qword [rel storage+NEBO_CONSOLE_HEADLESS_STORAGE_DOCUMENT_FLAGS_OFFSET], 0
    lea rdi, [rel context]
    lea rsi, [rel storage]
    call nebo_console_runtime_headless_bind
    test eax, eax
    jnz .domain_done
    lea rdi, [rel context]
    lea rsi, [rel handle]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .domain_done
    lea rdi, [rel context]
    mov rsi, [rel handle]
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .domain_done
    lea rdi, [rel context]
    mov esi, 1
    lea rdx, [rel progress]
    call nebo_console_scheduler_run
.domain_done:
    pop rbx
    ret

; EDI=kind, ESI=source-order.
send_command:
    push r12
    push r13
    sub rsp, 8
    mov r12d, edi
    mov r13d, esi
    lea rdi, [rel command]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_COMMAND_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov [rel command+NEBO_CONSOLE_COMMAND_KIND_OFFSET], r12d
    mov [rel command+NEBO_CONSOLE_COMMAND_SOURCE_ORDER_OFFSET], r13
    lea rdi, [rel context]
    mov rsi, [rel handle]
    lea rdx, [rel command]
    call nebo_console_domain_send
    add rsp, 8
    pop r13
    pop r12
    ret

setup_submission:
    push rbx
    lea rdi, [rel input_registry]
    lea rsi, [rel input_records]
    mov edx, INPUT_CAP
    mov rcx, [rel handle]
    call nebo_input_registry_init
    test eax, eax
    jnz .submission_done
    lea rdi, [rel pending_registry]
    lea rsi, [rel pending_records]
    mov edx, INPUT_CAP
    mov rcx, [rel handle]
    call nebo_pending_registry_init
    test eax, eax
    jnz .submission_done
    mov rax, 0x0000000100000000
    mov [rel input_records+NEBO_INPUT_RECORD_HANDLE_OFFSET], rax
    mov dword [rel input_records+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    mov qword [rel input_records+NEBO_INPUT_RECORD_NODE_ID_OFFSET], 100
    mov [rel input_records+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], rax
    mov qword [rel input_records+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], 1001
    mov qword [rel input_records+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], 201
    mov rbx, [rel handle]
    mov [rel input_records+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], rbx
    mov qword [rel input_records+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET], 1
    mov dword [rel input_records+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_REQUIRED_FLAGS
    mov [rel pending_records+NEBO_PENDING_RECORD_HANDLE_OFFSET], rax
    mov dword [rel pending_records+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    mov [rel pending_records+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], rax
    mov qword [rel pending_records+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], 1001
    mov qword [rel pending_records+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], 201
    mov [rel pending_records+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], rbx
    mov qword [rel pending_records+NEBO_PENDING_RECORD_TYPE_TAG_OFFSET], NEBO_PENDING_TYPE_TEXT
    mov qword [rel pending_records+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_REQUIRED_FLAGS
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    mov qword [rel input_registry+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET], 1
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    mov qword [rel pending_registry+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET], 1
    lea rdi, [rel editors]
    mov rsi, rax
    mov edx, 100
    lea rcx, [rel edit_buffers]
    mov r8d, VALUE_STRIDE
    call nebo_text_edit_init
    test eax, eax
    jnz .submission_done
    lea rax, [rel input_registry]
    mov [rel focus+NEBO_FOCUS_MANAGER_INPUT_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel layout_dummy]
    mov [rel focus+NEBO_FOCUS_MANAGER_LAYOUT_PTR_OFFSET], rax
    lea rax, [rel editors]
    mov [rel focus+NEBO_FOCUS_MANAGER_EDITORS_PTR_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_EDITOR_CAPACITY_OFFSET], INPUT_CAP
    lea rax, [rel edit_buffers]
    mov [rel focus+NEBO_FOCUS_MANAGER_TEXT_PTR_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_TEXT_STRIDE_OFFSET], VALUE_STRIDE
    mov rax, 0x0000000100000000
    mov [rel focus+NEBO_FOCUS_MANAGER_FOCUSED_HANDLE_OFFSET], rax
    mov qword [rel focus+NEBO_FOCUS_MANAGER_WINDOW_ACTIVE_OFFSET], 1
    mov qword [rel focus+NEBO_FOCUS_MANAGER_FLAGS_OFFSET], NEBO_FOCUS_MANAGER_REQUIRED_FLAGS
    lea rdi, [rel bridge]
    lea rsi, [rel continuations]
    mov edx, CONT_CAP
    mov rcx, [rel handle]
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .submission_done
    lea rax, [rel values]
    mov [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUES_PTR_OFFSET], rax
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_STRIDE_OFFSET], VALUE_STRIDE
    mov qword [rel submission_storage+NEBO_SUBMISSION_STORAGE_VALUE_CAPACITY_OFFSET], INPUT_CAP
    lea rdi, [rel submission]
    lea rsi, [rel input_registry]
    lea rdx, [rel pending_registry]
    lea rcx, [rel focus]
    lea r8, [rel bridge]
    lea r9, [rel submission_storage]
    call nebo_input_submission_init
.submission_done:
    pop rbx
    ret

test_pass:
    xor edi, edi
    call neboc_host_process_exit
    hlt

test_fail:
    mov edi, 1
    call neboc_host_process_exit
    hlt

test_usage:
    mov edi, 2
    call neboc_host_process_exit
    hlt

section .note.GNU-stack noalloc noexec nowrite progbits
