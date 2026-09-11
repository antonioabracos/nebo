; Nebo Assembly — MF049 lifecycle, cancellation and safe reclaim scenarios
bits 64
default rel
%include "runtime/console/lifecycle/console_lifecycle.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/queues/console_queue.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_anonymous_create
extern nebo_console_manager_handle_validate
extern nebo_console_domain_from_handle
extern nebo_console_scheduler_run
extern nebo_console_domain_event_enqueue
extern nebo_input_registry_init
extern nebo_pending_registry_init
extern nebo_dependency_bridge_init
extern nebo_dependency_bridge_register
extern nebo_console_lifecycle_runtime_init
extern nebo_console_lifecycle_register
extern nebo_console_lifecycle_sync
extern nebo_console_lifecycle_minimize
extern nebo_console_lifecycle_maximize
extern nebo_console_lifecycle_restore
extern nebo_console_lifecycle_request_close
extern nebo_console_lifecycle_drain
extern nebo_console_lifecycle_advance_epoch
extern nebo_console_lifecycle_try_reclaim
extern nebo_console_lifecycle_event_accept
extern nebo_console_lifecycle_mark_start_completed
extern nebo_console_lifecycle_can_shutdown
extern nebo_console_lifecycle_shutdown_if_safe
extern neboc_host_process_exit

global _start

%define CONSOLE_CAP 2
%define QUEUE_CAP 8
%define INPUT_CAP 2
%define CONT_CAP 4

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

lifecycle_runtime: resb NEBO_LIFECYCLE_RUNTIME_SIZE
lifecycle_records: resb CONSOLE_CAP*NEBO_LIFECYCLE_RECORD_SIZE
binding_a: resb NEBO_LIFECYCLE_BINDING_SIZE
binding_b: resb NEBO_LIFECYCLE_BINDING_SIZE

input_registry_a: resb NEBO_INPUT_REGISTRY_SIZE
input_records_a: resb INPUT_CAP*NEBO_INPUT_RECORD_SIZE
pending_registry_a: resb NEBO_PENDING_REGISTRY_SIZE
pending_records_a: resb INPUT_CAP*NEBO_PENDING_RECORD_SIZE
bridge_a: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations_a: resb CONT_CAP*NEBO_DEPENDENCY_CONTINUATION_SIZE

input_registry_b: resb NEBO_INPUT_REGISTRY_SIZE
input_records_b: resb INPUT_CAP*NEBO_INPUT_RECORD_SIZE
pending_registry_b: resb NEBO_PENDING_REGISTRY_SIZE
pending_records_b: resb INPUT_CAP*NEBO_PENDING_RECORD_SIZE
bridge_b: resb NEBO_DEPENDENCY_BRIDGE_SIZE
continuations_b: resb CONT_CAP*NEBO_DEPENDENCY_CONTINUATION_SIZE

handle_a: resq 1
handle_b: resq 1
old_handle: resq 1
domain_a: resq 1
domain_b: resq 1
record_a: resq 1
record_b: resq 1
progress: resq 1
out_slot: resq 1
out_bool: resq 1
event_desc: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE

section .text
_start:
    cmp qword [rsp], 2
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx], '1'
    jne .parse_single
    cmp byte [rbx+1], '0'
    jne .parse_single
    cmp byte [rbx+2], 0
    je scenario_10
.parse_single:
    cmp byte [rbx+1], 0
    jne test_usage
    movzx eax, byte [rbx]
    sub eax, '0'
    cmp eax, 1
    jb test_usage
    cmp eax, 9
    jbe .single_digit
    jmp test_usage
.single_digit:
    cmp eax, 1
    je scenario_1
    cmp eax, 2
    je scenario_2
    cmp eax, 3
    je scenario_3
    cmp eax, 4
    je scenario_4
    cmp eax, 5
    je scenario_5
    cmp eax, 6
    je scenario_6
    cmp eax, 7
    je scenario_7
    cmp eax, 8
    je scenario_8
    cmp eax, 9
    je scenario_9
    jmp test_usage

; create -> mount -> visible -> active
scenario_1:
    call setup_base
    test eax, eax
    jnz test_fail
    call create_a_unmounted
    test eax, eax
    jnz test_fail
    mov rbx, [rel record_a]
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_CREATED
    jne test_fail
    mov rdi, rbx
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MOUNTING
    jne test_fail
    call run_scheduler
    test eax, eax
    jnz test_fail
    mov rdi, rbx
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_VISIBLE
    jne test_fail
    mov rdi, rbx
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_ACTIVE
    jne test_fail
    jmp test_pass

; Minimize preserves active Pending state.
scenario_2:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call seed_pending_a
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_minimize
    test eax, eax
    jnz test_fail
    mov rbx, [rel record_a]
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MINIMIZED
    jne test_fail
    cmp dword [rel input_records_a+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    jne test_fail
    cmp dword [rel pending_records_a+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    jne test_fail
    cmp qword [rel pending_registry_a+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    jne test_fail
    jmp test_pass

; Maximize/restore preserves geometry.
scenario_3:
    call setup_a_active
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    mov esi, 160
    mov edx, 50
    call nebo_console_lifecycle_maximize
    test eax, eax
    jnz test_fail
    mov rbx, [rel record_a]
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_MAXIMIZED
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET], 160
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET], 50
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_WIDTH_OFFSET], 80
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_RESTORE_HEIGHT_OFFSET], 25
    jne test_fail
    mov rdi, rbx
    call nebo_console_lifecycle_restore
    test eax, eax
    jnz test_fail
    cmp dword [rbx+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_ACTIVE
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_WIDTH_OFFSET], 80
    jne test_fail
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_CURRENT_HEIGHT_OFFSET], 25
    jne test_fail
    jmp test_pass

; Close without Pending reaches CLOSED then safe reclaim.
scenario_4:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call close_drain_reclaim_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    lea rdx, [rel out_slot]
    call nebo_console_manager_handle_validate
    cmp eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jne test_fail
    cmp dword [rel lifecycle_records+NEBO_LIFECYCLE_RECORD_STATE_OFFSET], NEBO_LIFECYCLE_STATE_RECLAIMED
    jne test_fail
    jmp test_pass

; Close with Pending cancels Input and Pending.
scenario_5:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call seed_pending_a
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_request_close
    test eax, eax
    jnz test_fail
    cmp dword [rel input_records_a+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_CANCELLED
    jne test_fail
    cmp dword [rel pending_records_a+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_CANCELLED
    jne test_fail
    cmp qword [rel input_registry_a+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rel pending_registry_a+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    call drain_reclaim_a
    test eax, eax
    jnz test_fail
    jmp test_pass

; Close cancels matching dependents without activation.
scenario_6:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call seed_pending_a
    lea rdi, [rel bridge_a]
    mov esi, 11
    mov edx, 1001
    mov ecx, 201
    mov r8d, 20
    mov r9d, 901
    call nebo_dependency_bridge_register
    test eax, eax
    jnz test_fail
    lea rdi, [rel bridge_a]
    mov esi, 12
    mov edx, 1001
    mov ecx, 201
    mov r8d, 10
    mov r9d, 902
    call nebo_dependency_bridge_register
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_request_close
    test eax, eax
    jnz test_fail
    cmp dword [rel continuations_a+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_CANCELLED
    jne test_fail
    cmp dword [rel continuations_a+NEBO_DEPENDENCY_CONTINUATION_SIZE+NEBO_DEPENDENCY_STATE_OFFSET], NEBO_DEPENDENCY_STATE_CANCELLED
    jne test_fail
    cmp qword [rel bridge_a+NEBO_DEPENDENCY_BRIDGE_ACTIVATED_COUNT_OFFSET], 0
    jne test_fail
    call drain_reclaim_a
    test eax, eax
    jnz test_fail
    jmp test_pass

; Closing one Console does not stop another.
scenario_7:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call create_b_active
    test eax, eax
    jnz test_fail
    call close_drain_reclaim_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel handle_b]
    lea rdx, [rel out_slot]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_b]
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_RUNNABLE
    jne test_fail
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STOP_STATE_OFFSET], NEBO_CONSOLE_STOP_NONE
    jne test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 1
    jne test_fail
    jmp test_pass

; Old-generation event is rejected after default recreation.
scenario_8:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call close_drain_reclaim_a
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_a]
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FREE
    jne test_fail
    call recreate_default_a
    test eax, eax
    jnz test_fail
    mov rax, [rel handle_a]
    cmp rax, [rel old_handle]
    je test_fail
    mov edx, eax
    cmp edx, dword [rel old_handle]
    jne test_fail
    lea rdi, [rel event_desc]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov dword [rel event_desc+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TIMER_TICK
    mov rax, [rel old_handle]
    mov [rel event_desc+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
    mov rdi, [rel domain_a]
    lea rsi, [rel event_desc]
    call nebo_console_domain_event_enqueue
    cmp eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jne test_fail
    mov rdi, [rel record_a]
    mov rsi, [rel old_handle]
    call nebo_console_lifecycle_event_accept
    cmp eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jne test_fail
    mov rbx, [rel record_a]
    cmp qword [rbx+NEBO_LIFECYCLE_RECORD_LATE_EVENTS_DROPPED_OFFSET], 1
    jne test_fail
    jmp test_pass

; Reclaim is blocked before drain and before safe epoch.
scenario_9:
    call setup_a_active
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_request_close
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_try_reclaim
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne test_fail
    mov rdi, [rel record_a]
    lea rsi, [rel progress]
    call nebo_console_lifecycle_drain
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_try_reclaim
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne test_fail
    lea rdi, [rel lifecycle_runtime]
    call nebo_console_lifecycle_advance_epoch
    test eax, eax
    jnz test_fail
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_try_reclaim
    test eax, eax
    jnz test_fail
    jmp test_pass

; scenario 10 is selected by the string "10".
scenario_10:
    call setup_a_active
    test eax, eax
    jnz test_fail
    call close_drain_reclaim_a
    test eax, eax
    jnz test_fail
    lea rdi, [rel lifecycle_runtime]
    call nebo_console_lifecycle_mark_start_completed
    test eax, eax
    jnz test_fail
    lea rdi, [rel lifecycle_runtime]
    lea rsi, [rel out_bool]
    call nebo_console_lifecycle_can_shutdown
    test eax, eax
    jnz test_fail
    cmp qword [rel out_bool], 1
    jne test_fail
    lea rdi, [rel lifecycle_runtime]
    call nebo_console_lifecycle_shutdown_if_safe
    test eax, eax
    jnz test_fail
    cmp qword [rel platform+NEBO_FAKE_PLATFORM_STATE_OFFSET], NEBO_FAKE_PLATFORM_STATE_SHUTDOWN
    jne test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_STATE_OFFSET], NEBO_CONSOLE_CONTEXT_STATE_SHUTDOWN
    jne test_fail
    jmp test_pass

; Parses scenario 10 before single digit dispatch.
parse_scenario_10:
    ret

setup_base:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, CONSOLE_CAP
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .setup_base_done
    lea rdi, [rel storage]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_HEADLESS_STORAGE_QWORDS
    cld
    rep stosq
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
    lea rdi, [rel context]
    lea rsi, [rel storage]
    call nebo_console_runtime_headless_bind
    test eax, eax
    jnz .setup_base_done
    lea rdi, [rel lifecycle_runtime]
    lea rsi, [rel lifecycle_records]
    mov edx, CONSOLE_CAP
    lea rcx, [rel context]
    call nebo_console_lifecycle_runtime_init
.setup_base_done:
    add rsp, 16
    pop rbx
    ret

create_a_unmounted:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel handle_a]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .create_a_done
    lea rdi, [rel context]
    mov rsi, [rel handle_a]
    lea rdx, [rel domain_a]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .create_a_done
    lea rdi, [rel input_registry_a]
    lea rsi, [rel input_records_a]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_a]
    call nebo_input_registry_init
    test eax, eax
    jnz .create_a_done
    lea rdi, [rel pending_registry_a]
    lea rsi, [rel pending_records_a]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_a]
    call nebo_pending_registry_init
    test eax, eax
    jnz .create_a_done
    lea rdi, [rel bridge_a]
    lea rsi, [rel continuations_a]
    mov edx, CONT_CAP
    mov rcx, [rel handle_a]
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .create_a_done
    lea rdi, [rel binding_a]
    xor eax, eax
    mov ecx, NEBO_LIFECYCLE_BINDING_QWORDS
    cld
    rep stosq
    mov rax, [rel handle_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_CONSOLE_HANDLE_OFFSET], rax
    mov rax, [rel domain_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_DOMAIN_PTR_OFFSET], rax
    lea rax, [rel input_registry_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_INPUT_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel pending_registry_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_PENDING_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel bridge_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_DEPENDENCY_BRIDGE_PTR_OFFSET], rax
    mov qword [rel binding_a+NEBO_LIFECYCLE_BINDING_INITIAL_WIDTH_OFFSET], 80
    mov qword [rel binding_a+NEBO_LIFECYCLE_BINDING_INITIAL_HEIGHT_OFFSET], 25
    lea rdi, [rel lifecycle_runtime]
    lea rsi, [rel binding_a]
    lea rdx, [rel record_a]
    call nebo_console_lifecycle_register
.create_a_done:
    add rsp, 16
    pop rbx
    ret

create_b_active:
    push rbx
    sub rsp, 16
    lea rdi, [rel context]
    lea rsi, [rel handle_b]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz .create_b_done
    lea rdi, [rel context]
    mov rsi, [rel handle_b]
    lea rdx, [rel domain_b]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .create_b_done
    lea rdi, [rel input_registry_b]
    lea rsi, [rel input_records_b]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_b]
    call nebo_input_registry_init
    test eax, eax
    jnz .create_b_done
    lea rdi, [rel pending_registry_b]
    lea rsi, [rel pending_records_b]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_b]
    call nebo_pending_registry_init
    test eax, eax
    jnz .create_b_done
    lea rdi, [rel bridge_b]
    lea rsi, [rel continuations_b]
    mov edx, CONT_CAP
    mov rcx, [rel handle_b]
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .create_b_done
    lea rdi, [rel binding_b]
    xor eax, eax
    mov ecx, NEBO_LIFECYCLE_BINDING_QWORDS
    cld
    rep stosq
    mov rax, [rel handle_b]
    mov [rel binding_b+NEBO_LIFECYCLE_BINDING_CONSOLE_HANDLE_OFFSET], rax
    mov rax, [rel domain_b]
    mov [rel binding_b+NEBO_LIFECYCLE_BINDING_DOMAIN_PTR_OFFSET], rax
    lea rax, [rel input_registry_b]
    mov [rel binding_b+NEBO_LIFECYCLE_BINDING_INPUT_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel pending_registry_b]
    mov [rel binding_b+NEBO_LIFECYCLE_BINDING_PENDING_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel bridge_b]
    mov [rel binding_b+NEBO_LIFECYCLE_BINDING_DEPENDENCY_BRIDGE_PTR_OFFSET], rax
    mov qword [rel binding_b+NEBO_LIFECYCLE_BINDING_INITIAL_WIDTH_OFFSET], 80
    mov qword [rel binding_b+NEBO_LIFECYCLE_BINDING_INITIAL_HEIGHT_OFFSET], 25
    lea rdi, [rel lifecycle_runtime]
    lea rsi, [rel binding_b]
    lea rdx, [rel record_b]
    call nebo_console_lifecycle_register
    test eax, eax
    jnz .create_b_done
    mov rdi, [rel record_b]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .create_b_done
    call run_scheduler
    test eax, eax
    jnz .create_b_done
    mov rdi, [rel record_b]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .create_b_done
    mov rdi, [rel record_b]
    call nebo_console_lifecycle_sync
.create_b_done:
    add rsp, 16
    pop rbx
    ret

setup_a_active:
    push rbx
    call setup_base
    test eax, eax
    jnz .setup_a_done
    call create_a_unmounted
    test eax, eax
    jnz .setup_a_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .setup_a_done
    call run_scheduler
    test eax, eax
    jnz .setup_a_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .setup_a_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
.setup_a_done:
    pop rbx
    ret

run_scheduler:
    lea rdi, [rel context]
    mov esi, 16
    lea rdx, [rel progress]
    jmp nebo_console_scheduler_run

seed_pending_a:
    mov dword [rel input_records_a+NEBO_INPUT_RECORD_STATE_OFFSET], NEBO_INPUT_STATE_PENDING
    mov rax, 0x0000000100000000
    mov [rel input_records_a+NEBO_INPUT_RECORD_HANDLE_OFFSET], rax
    mov [rel input_records_a+NEBO_INPUT_RECORD_PENDING_HANDLE_OFFSET], rax
    mov qword [rel input_records_a+NEBO_INPUT_RECORD_COMPILER_PENDING_ID_OFFSET], 1001
    mov qword [rel input_records_a+NEBO_INPUT_RECORD_BINDING_ID_OFFSET], 201
    mov rax, [rel handle_a]
    mov [rel input_records_a+NEBO_INPUT_RECORD_CONSOLE_HANDLE_OFFSET], rax
    mov dword [rel input_records_a+NEBO_INPUT_RECORD_FLAGS_OFFSET], NEBO_INPUT_REQUIRED_FLAGS
    mov qword [rel input_records_a+NEBO_INPUT_RECORD_SOURCE_ORDER_OFFSET], 1
    mov dword [rel pending_records_a+NEBO_PENDING_RECORD_STATE_OFFSET], NEBO_PENDING_STATE_PENDING
    mov rax, 0x0000000100000000
    mov [rel pending_records_a+NEBO_PENDING_RECORD_HANDLE_OFFSET], rax
    mov [rel pending_records_a+NEBO_PENDING_RECORD_INPUT_HANDLE_OFFSET], rax
    mov qword [rel pending_records_a+NEBO_PENDING_RECORD_COMPILER_PENDING_ID_OFFSET], 1001
    mov qword [rel pending_records_a+NEBO_PENDING_RECORD_BINDING_ID_OFFSET], 201
    mov rax, [rel handle_a]
    mov [rel pending_records_a+NEBO_PENDING_RECORD_CONSOLE_HANDLE_OFFSET], rax
    mov qword [rel pending_records_a+NEBO_PENDING_RECORD_TYPE_TAG_OFFSET], NEBO_PENDING_TYPE_TEXT
    mov qword [rel pending_records_a+NEBO_PENDING_RECORD_FLAGS_OFFSET], NEBO_PENDING_REQUIRED_FLAGS
    mov qword [rel input_registry_a+NEBO_INPUT_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    mov qword [rel input_registry_a+NEBO_INPUT_REGISTRY_CREATED_COUNT_OFFSET], 1
    mov qword [rel pending_registry_a+NEBO_PENDING_REGISTRY_ACTIVE_COUNT_OFFSET], 1
    mov qword [rel pending_registry_a+NEBO_PENDING_REGISTRY_CREATED_COUNT_OFFSET], 1
    mov eax, [rel handle_a]
    shl rax, 6
    lea rdx, [rel slots]
    add rdx, rax
    mov qword [rdx+NEBO_CONSOLE_SLOT_PENDING_COUNT_OFFSET], 1
    ret

close_drain_reclaim_a:
    push rbx
    mov rax, [rel handle_a]
    mov [rel old_handle], rax
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_request_close
    test eax, eax
    jnz .close_all_done
    call drain_reclaim_a
.close_all_done:
    pop rbx
    ret

drain_reclaim_a:
    push rbx
    mov rdi, [rel record_a]
    lea rsi, [rel progress]
    call nebo_console_lifecycle_drain
    test eax, eax
    jnz .drain_reclaim_done
    lea rdi, [rel lifecycle_runtime]
    call nebo_console_lifecycle_advance_epoch
    test eax, eax
    jnz .drain_reclaim_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_try_reclaim
.drain_reclaim_done:
    pop rbx
    ret

recreate_default_a:
    push rbx
    ; Reuse slot zero with a new generation and rebind lifecycle metadata.
    lea rdi, [rel context]
    lea rsi, [rel handle_a]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .recreate_done
    lea rdi, [rel context]
    mov rsi, [rel handle_a]
    lea rdx, [rel domain_a]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .recreate_done
    lea rdi, [rel input_registry_a]
    lea rsi, [rel input_records_a]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_a]
    call nebo_input_registry_init
    test eax, eax
    jnz .recreate_done
    lea rdi, [rel pending_registry_a]
    lea rsi, [rel pending_records_a]
    mov edx, INPUT_CAP
    mov rcx, [rel handle_a]
    call nebo_pending_registry_init
    test eax, eax
    jnz .recreate_done
    lea rdi, [rel bridge_a]
    lea rsi, [rel continuations_a]
    mov edx, CONT_CAP
    mov rcx, [rel handle_a]
    call nebo_dependency_bridge_init
    test eax, eax
    jnz .recreate_done
    mov rax, [rel handle_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_CONSOLE_HANDLE_OFFSET], rax
    mov rax, [rel domain_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_DOMAIN_PTR_OFFSET], rax
    lea rax, [rel input_registry_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_INPUT_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel pending_registry_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_PENDING_REGISTRY_PTR_OFFSET], rax
    lea rax, [rel bridge_a]
    mov [rel binding_a+NEBO_LIFECYCLE_BINDING_DEPENDENCY_BRIDGE_PTR_OFFSET], rax
    lea rdi, [rel lifecycle_runtime]
    lea rsi, [rel binding_a]
    lea rdx, [rel record_a]
    call nebo_console_lifecycle_register
    test eax, eax
    jnz .recreate_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .recreate_done
    call run_scheduler
    test eax, eax
    jnz .recreate_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
    test eax, eax
    jnz .recreate_done
    mov rdi, [rel record_a]
    call nebo_console_lifecycle_sync
.recreate_done:
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
    ; Accept the decimal string "10" for the final scenario.
    cmp qword [rsp], 2
    jne .usage_exit
    mov rbx, [rsp+16]
    cmp byte [rbx], '1'
    jne .usage_exit
    cmp byte [rbx+1], '0'
    jne .usage_exit
    cmp byte [rbx+2], 0
    jne .usage_exit
    jmp scenario_10
.usage_exit:
    mov edi, 2
    call neboc_host_process_exit
    hlt

section .note.GNU-stack noalloc noexec nowrite progbits
