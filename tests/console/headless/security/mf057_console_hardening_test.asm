; Nebo Assembly — MF057 Console fuzz, race and resource hardening
bits 64
default rel

%include "runtime/core/runtime_core.inc"
%include "runtime/console/handles/console_handle.inc"
%include "runtime/console/manager/console_manager.inc"
%include "runtime/console/queues/console_queue.inc"
%include "runtime/console/domain/console_domain.inc"
%include "runtime/console/platform/fake/fake_platform.inc"
%include "runtime/console/input/editing/text_editor.inc"

extern nebo_console_runtime_context_init
extern nebo_console_runtime_headless_bind
extern nebo_console_manager_default_get_or_create
extern nebo_console_manager_anonymous_create
extern nebo_console_manager_handle_validate
extern nebo_console_manager_close
extern nebo_console_manager_reclaim_closed
extern nebo_console_domain_from_handle
extern nebo_console_domain_send
extern nebo_console_domain_event_enqueue
extern nebo_console_domain_validate
extern nebo_console_scheduler_run
extern nebo_console_queue_validate
extern nebo_fake_platform_inject_event
extern nebo_text_edit_init
extern nebo_text_edit_set_text
extern nebo_text_edit_insert_utf8
extern nebo_text_edit_validate
extern neboc_host_process_exit

global _start

%define CONSOLE_CAP 8
%define QUEUE_CAP 4
%define EVENT_FUZZ_ITERATIONS 1024
%define HANDLE_ARRAY_COUNT CONSOLE_CAP

section .rodata
invalid_utf8_1: db 0x80
invalid_utf8_2: db 0xc0,0xaf
invalid_utf8_3: db 0xe0,0x80,0x80
invalid_utf8_4: db 0xed,0xa0,0x80
invalid_utf8_5: db 0xf4,0x90,0x80,0x80
invalid_utf8_6: db 0xf5,0x80,0x80,0x80
invalid_utf8_7: db 0xc2
invalid_utf8_8: db 0xe2,0x82
invalid_utf8_9: db 0xf0,0x9f,0x92
invalid_utf8_cases:
    dq invalid_utf8_1,1
    dq invalid_utf8_2,2
    dq invalid_utf8_3,3
    dq invalid_utf8_4,3
    dq invalid_utf8_5,4
    dq invalid_utf8_6,4
    dq invalid_utf8_7,1
    dq invalid_utf8_8,2
    dq invalid_utf8_9,3
invalid_utf8_case_count: equ 9
valid_utf8_max_scalar: db 0xf4,0x8f,0xbf,0xbf

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
handles: resq HANDLE_ARRAY_COUNT
handle: resq 1
old_handle: resq 1
new_handle: resq 1
domain_ptr: resq 1
slot_ptr: resq 1
progress: resq 1
seed: resq 1
baseline_events: resq 1
baseline_commands: resq 1
baseline_event_sequence: resq 1
baseline_command_enqueue_sequence: resq 1
baseline_event_enqueue_sequence: resq 1
snapshot_event_count: resq 1
snapshot_event_enqueue_sequence: resq 1
snapshot_platform_event_sequence: resq 1
failure_stage: resq 1
command: resb NEBO_CONSOLE_COMMAND_DESCRIPTOR_SIZE
event: resb NEBO_CONSOLE_EVENT_DESCRIPTOR_SIZE
editor: resb NEBO_TEXT_EDIT_RECORD_SIZE
edit_buffer: resb 64

section .text
_start:
    cmp qword [rsp], 2
    jne test_usage
    mov rbx, [rsp+16]
    cmp byte [rbx+1], 0
    jne test_usage
    cmp byte [rbx], '1'
    je scenario_event_fuzz
    cmp byte [rbx], '2'
    je scenario_invalid_utf8
    cmp byte [rbx], '3'
    je scenario_close_race_stale_callback
    cmp byte [rbx], '4'
    je scenario_resource_storm
    cmp byte [rbx], '5'
    je scenario_queue_exhaustion
    jmp test_usage

; Deterministic event-stream fuzz. Only non-destructive event kinds 9..16 are
; generated; invalid and stale events are checked explicitly after the stream.
scenario_event_fuzz:
    call setup_default_domain
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_ptr]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    mov [rel baseline_events], rax
    mov rax, 0x9e3779b97f4a7c15
    mov [rel seed], rax
    mov r15d, EVENT_FUZZ_ITERATIONS
.event_fuzz_loop:
    call prng_next
    mov r14, rax
    mov edx, eax
    and edx, 7
    add edx, NEBO_CONSOLE_EVENT_POINTER_MOVE
    lea rdi, [rel platform]
    mov rsi, [rel domain_ptr]
    mov rcx, r14
    mov r8, r14
    shr r8, 17
    call nebo_fake_platform_inject_event
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne .event_fuzz_status
    mov esi, 2
    call run_scheduler
    test eax, eax
    jnz test_fail
    mov edx, r14d
    and edx, 7
    add edx, NEBO_CONSOLE_EVENT_POINTER_MOVE
    lea rdi, [rel platform]
    mov rsi, [rel domain_ptr]
    mov rcx, r14
    mov r8, r14
    shr r8, 17
    call nebo_fake_platform_inject_event
.event_fuzz_status:
    test eax, eax
    jnz test_fail
    test r14b, 3
    jnz .event_fuzz_validate
    mov esi, 1
    call run_scheduler
    test eax, eax
    jnz test_fail
.event_fuzz_validate:
    mov rdi, [rel domain_ptr]
    call nebo_console_domain_validate
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    add rdi, NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    add rdi, NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail
    dec r15d
    jnz .event_fuzz_loop
    mov esi, EVENT_FUZZ_ITERATIONS
    call run_scheduler
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    sub rax, [rel baseline_events]
    cmp rax, EVENT_FUZZ_ITERATIONS
    jne test_fail
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FAILED
    je test_fail
    ; Invalid event kinds cannot mutate the queue.
    lea rdi, [rel platform]
    mov rsi, rbx
    xor edx, edx
    xor ecx, ecx
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    cmp eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jne test_fail
    lea rdi, [rel platform]
    mov rsi, rbx
    mov edx, NEBO_CONSOLE_EVENT_KIND_MAX+1
    xor ecx, ecx
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    cmp eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jne test_fail
    ; A callback carrying another generation is stale and is rejected.
    lea rdi, [rel event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rax, [rel handle]
    mov rdx, 0x100000000
    add rax, rdx
    mov [rel event+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
    mov dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TIMER_TICK
    mov rdi, rbx
    lea rsi, [rel event]
    call nebo_console_domain_event_enqueue
    cmp eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    jmp test_pass

; Strict UTF-8 rejection is transactional: malformed input never changes text,
; caret, revision-visible data or the editor's structural validity.
scenario_invalid_utf8:
    lea rdi, [rel editor]
    mov rsi, 1
    mov rdx, 1
    lea rcx, [rel edit_buffer]
    mov r8d, 64
    call nebo_text_edit_init
    test eax, eax
    jnz test_fail
    lea r12, [rel invalid_utf8_cases]
    mov r13d, invalid_utf8_case_count
.invalid_utf8_loop:
    lea rdi, [rel editor]
    mov rsi, [r12]
    mov rdx, [r12+8]
    call nebo_text_edit_set_text
    cmp eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jne test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_LAST_ERROR_OFFSET], NEBO_TEXT_EDIT_ERROR_INVALID_UTF8
    jne test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_LENGTH_OFFSET], 0
    jne test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_CARET_OFFSET], 0
    jne test_fail
    lea rdi, [rel editor]
    call nebo_text_edit_validate
    test eax, eax
    jnz test_fail
    add r12, 16
    dec r13d
    jnz .invalid_utf8_loop
    lea rdi, [rel editor]
    lea rsi, [rel valid_utf8_max_scalar]
    mov edx, 4
    call nebo_text_edit_set_text
    test eax, eax
    jnz test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_LENGTH_OFFSET], 4
    jne test_fail
    lea rdi, [rel editor]
    xor esi, esi
    xor edx, edx
    call nebo_text_edit_set_text
    test eax, eax
    jnz test_fail
    lea rdi, [rel editor]
    lea rsi, [rel invalid_utf8_5]
    mov edx, 4
    call nebo_text_edit_insert_utf8
    cmp eax, NEBO_CONSOLE_STATUS_INVALID_ARGUMENT
    jne test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_LENGTH_OFFSET], 0
    jne test_fail
    cmp qword [rel editor+NEBO_TEXT_EDIT_CARET_OFFSET], 0
    jne test_fail
    jmp test_pass

; Close pressure is serialized by the cooperative single writer. The old
; generation is then exercised as a stale callback against a reused slot.
scenario_close_race_stale_callback:
    call setup_default_domain
    test eax, eax
    jnz test_fail
    mov rax, [rel handle]
    mov [rel old_handle], rax
    xor r14d, r14d
.close_fill_loop:
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_INT
    mov esi, r14d
    inc esi
    call send_command
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, QUEUE_CAP
    jb .close_fill_loop
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    lea rdx, [rel slot_ptr]
    call nebo_console_manager_handle_validate
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    call nebo_console_manager_close
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne test_fail
    mov rax, [rel slot_ptr]
    cmp dword [rax+NEBO_CONSOLE_SLOT_STATE_OFFSET], NEBO_CONSOLE_SLOT_STATE_ACTIVE
    jne test_fail
    mov esi, 16
    call run_scheduler
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    call nebo_console_manager_close
    test eax, eax
    jnz test_fail
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    call nebo_console_manager_close
    cmp eax, NEBO_CONSOLE_STATUS_BAD_STATE
    jne test_fail
    mov esi, 32
    call run_scheduler
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_ptr]
    cmp dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_STOPPED
    jne test_fail
    lea rdi, [rel context]
    mov rsi, [rel old_handle]
    call nebo_console_manager_reclaim_closed
    test eax, eax
    jnz test_fail
    ; The harness is the sole cooperative owner and has already observed the
    ; domain STOPPED with both queues drained. Mirror the final publication in
    ; ConsoleLifecycle.try_reclaim so the indexed domain storage can be reused.
    mov rbx, [rel domain_ptr]
    mov dword [rbx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FREE
    lea rdi, [rel context]
    lea rsi, [rel new_handle]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz test_fail
    mov rax, [rel new_handle]
    cmp rax, [rel old_handle]
    je test_fail
    lea rdi, [rel context]
    mov rsi, rax
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz test_fail
    lea rdi, [rel event]
    xor eax, eax
    mov ecx, NEBO_CONSOLE_EVENT_DESCRIPTOR_QWORDS
    cld
    rep stosq
    mov rax, [rel old_handle]
    mov [rel event+NEBO_CONSOLE_EVENT_HANDLE_OFFSET], rax
    mov dword [rel event+NEBO_CONSOLE_EVENT_KIND_OFFSET], NEBO_CONSOLE_EVENT_TIMER_TICK
    mov rdi, [rel domain_ptr]
    lea rsi, [rel event]
    call nebo_console_domain_event_enqueue
    cmp eax, NEBO_CONSOLE_STATUS_HANDLE_CLOSED
    jne test_fail
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 1
    ; The mount event created with the new domain is the only queued event.
    jne test_fail
    mov esi, 8
    call run_scheduler
    test eax, eax
    jnz test_fail
    jmp test_pass

; Exhaust the configured Console/window budget without increasing it. Failure
; must be atomic, all resources must close, and the slots must remain reusable.
scenario_resource_storm:
    call setup_runtime
    test eax, eax
    jnz test_fail
    xor r14d, r14d
.resource_create_loop:
    lea rdi, [rel context]
    lea rax, [rel handles]
    lea rsi, [rax+r14*8]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, CONSOLE_CAP
    jb .resource_create_loop
    mov rax, 0xfeedfacefeedface
    mov [rel new_handle], rax
    lea rdi, [rel context]
    lea rsi, [rel new_handle]
    call nebo_console_manager_anonymous_create
    cmp eax, NEBO_CONSOLE_STATUS_LIMIT_EXCEEDED
    jne test_fail
    cmp qword [rel new_handle], NEBO_CONSOLE_HANDLE_INVALID
    jne test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], CONSOLE_CAP
    jne test_fail
    cmp qword [rel scheduler+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET], CONSOLE_CAP
    jne test_fail
    cmp qword [rel platform+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET], CONSOLE_CAP
    jne test_fail
    mov esi, 32
    call run_scheduler
    test eax, eax
    jnz test_fail
    xor r14d, r14d
.resource_close_loop:
    lea rdi, [rel context]
    lea rax, [rel handles]
    mov rsi, [rax+r14*8]
    call nebo_console_manager_close
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, CONSOLE_CAP
    jb .resource_close_loop
    mov esi, 128
    call run_scheduler
    test eax, eax
    jnz test_fail
    cmp qword [rel context+NEBO_CONSOLE_CONTEXT_MANAGER_OFFSET+NEBO_CONSOLE_MANAGER_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rel scheduler+NEBO_CONSOLE_SCHEDULER_ACTIVE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rel platform+NEBO_FAKE_PLATFORM_ACTIVE_WINDOWS_OFFSET], 0
    jne test_fail
    cmp qword [rel platform+NEBO_FAKE_PLATFORM_CLOSE_COUNT_OFFSET], CONSOLE_CAP
    jne test_fail
    xor r14d, r14d
.resource_reclaim_loop:
    lea rdi, [rel context]
    lea rax, [rel handles]
    mov rsi, [rax+r14*8]
    call nebo_console_manager_reclaim_closed
    test eax, eax
    jnz test_fail
    ; Manager reclaim releases the handle slot. The lifecycle owner then
    ; publishes the already joined indexed domain block as reusable.
    mov rax, r14
    shl rax, 8
    lea rdx, [rel domains]
    add rdx, rax
    mov dword [rdx+NEBO_CONSOLE_DOMAIN_STATE_OFFSET], NEBO_CONSOLE_DOMAIN_STATE_FREE
    inc r14d
    cmp r14d, CONSOLE_CAP
    jb .resource_reclaim_loop
    lea rdi, [rel context]
    lea rsi, [rel new_handle]
    call nebo_console_manager_anonymous_create
    test eax, eax
    jnz test_fail
    mov rax, [rel new_handle]
    cmp rax, [rel handles]
    je test_fail
    jmp test_pass

; Command and event queues fail closed at the exact configured capacity; failed
; enqueue attempts do not mutate sequence/count, and all accepted items drain.
scenario_queue_exhaustion:
    mov qword [rel failure_stage], 51
    call setup_default_domain
    test eax, eax
    jnz test_fail
    mov rbx, [rel domain_ptr]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET]
    mov [rel baseline_commands], rax
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    mov [rel baseline_events], rax
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    mov [rel baseline_command_enqueue_sequence], rax
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    mov [rel baseline_event_enqueue_sequence], rax
    mov rax, [rel platform+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    mov [rel baseline_event_sequence], rax

    ; Fill the command queue to its exact configured capacity.
    mov qword [rel failure_stage], 52
    xor r14d, r14d
.queue_command_loop:
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_INT
    mov esi, r14d
    inc esi
    call send_command
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, QUEUE_CAP
    jb .queue_command_loop

    ; The next command must fail closed without changing queue metadata.
    mov qword [rel failure_stage], 53
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_INT
    mov esi, 99
    call send_command
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne test_fail

    mov qword [rel failure_stage], 54
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], QUEUE_CAP
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    sub rax, [rel baseline_command_enqueue_sequence]
    cmp rax, QUEUE_CAP
    jne test_fail
    mov rdi, rbx
    add rdi, NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail

    ; Fill the event queue. Every successful platform injection must be visible
    ; in both the bounded queue and the fake-platform sequence.
    mov qword [rel failure_stage], 55
    xor r14d, r14d
.queue_event_loop:
    lea rdi, [rel platform]
    mov rsi, [rel domain_ptr]
    mov edx, NEBO_CONSOLE_EVENT_TIMER_TICK
    mov rcx, r14
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    test eax, eax
    jnz test_fail
    inc r14d
    cmp r14d, QUEUE_CAP
    jb .queue_event_loop

    ; Capture the exact accepted state immediately before the rejected enqueue.
    ; These snapshots make the contract direct: QUEUE_FULL may change status,
    ; but it must not mutate queue depth, queue sequence or platform sequence.
    mov qword [rel failure_stage], 56
    mov rbx, [rel domain_ptr]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    cmp rax, QUEUE_CAP
    jne test_fail
    mov [rel snapshot_event_count], rax

    mov qword [rel failure_stage], 57
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    mov [rel snapshot_event_enqueue_sequence], rax
    sub rax, [rel baseline_event_enqueue_sequence]
    cmp rax, QUEUE_CAP
    jne test_fail

    mov qword [rel failure_stage], 58
    mov rax, [rel platform+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    mov [rel snapshot_platform_event_sequence], rax
    sub rax, [rel baseline_event_sequence]
    cmp rax, QUEUE_CAP
    jne test_fail

    mov qword [rel failure_stage], 59
    mov rdi, rbx
    add rdi, NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail

    ; Rejected event enqueue.
    mov qword [rel failure_stage], 60
    lea rdi, [rel platform]
    mov rsi, [rel domain_ptr]
    mov edx, NEBO_CONSOLE_EVENT_TIMER_TICK
    mov ecx, 99
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    cmp eax, NEBO_CONSOLE_STATUS_QUEUE_FULL
    jne test_fail

    ; Prove the failure was transactional using the pre-failure snapshots.
    mov qword [rel failure_stage], 61
    mov rbx, [rel domain_ptr]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET]
    cmp rax, [rel snapshot_event_count]
    jne test_fail

    mov qword [rel failure_stage], 62
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    cmp rax, [rel snapshot_event_enqueue_sequence]
    jne test_fail

    mov qword [rel failure_stage], 63
    mov rax, [rel platform+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    cmp rax, [rel snapshot_platform_event_sequence]
    jne test_fail

    mov qword [rel failure_stage], 64
    mov rdi, rbx
    add rdi, NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail

    ; Drain both full queues.
    mov qword [rel failure_stage], 65
    mov esi, 32
    call run_scheduler
    test eax, eax
    jnz test_fail

    mov qword [rel failure_stage], 66
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    mov rdi, rbx
    add rdi, NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail
    mov rdi, [rel domain_ptr]
    add rdi, NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET
    call nebo_console_queue_validate
    test eax, eax
    jnz test_fail

    mov qword [rel failure_stage], 67
    mov rbx, [rel domain_ptr]
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET]
    sub rax, [rel baseline_commands]
    cmp rax, QUEUE_CAP
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    sub rax, [rel baseline_events]
    cmp rax, QUEUE_CAP
    jne test_fail

    ; Prove both queues accept work again after exhaustion.
    mov qword [rel failure_stage], 68
    mov edi, NEBO_CONSOLE_COMMAND_APPEND_BOOL
    mov esi, 1
    call send_command
    test eax, eax
    jnz test_fail
    lea rdi, [rel platform]
    mov rsi, [rel domain_ptr]
    mov edx, NEBO_CONSOLE_EVENT_TIMER_TICK
    xor ecx, ecx
    xor r8d, r8d
    call nebo_fake_platform_inject_event
    test eax, eax
    jnz test_fail

    mov qword [rel failure_stage], 69
    mov esi, 8
    call run_scheduler
    test eax, eax
    jnz test_fail

    mov qword [rel failure_stage], 70
    mov rbx, [rel domain_ptr]
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    cmp qword [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_COUNT_OFFSET], 0
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_COMMANDS_OFFSET]
    sub rax, [rel baseline_commands]
    cmp rax, QUEUE_CAP+1
    jne test_fail
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_PROCESSED_EVENTS_OFFSET]
    sub rax, [rel baseline_events]
    cmp rax, QUEUE_CAP+1
    jne test_fail

    mov qword [rel failure_stage], 71
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_COMMAND_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    sub rax, [rel baseline_command_enqueue_sequence]
    cmp rax, QUEUE_CAP+1
    jne test_fail

    ; The post-exhaustion event must advance both exact snapshots by one.
    mov qword [rel failure_stage], 72
    mov rax, [rbx+NEBO_CONSOLE_DOMAIN_EVENT_QUEUE_OFFSET+NEBO_CONSOLE_QUEUE_ENQUEUE_SEQUENCE_OFFSET]
    sub rax, [rel snapshot_event_enqueue_sequence]
    cmp rax, 1
    jne test_fail

    mov qword [rel failure_stage], 73
    mov rax, [rel platform+NEBO_FAKE_PLATFORM_EVENT_SEQUENCE_OFFSET]
    sub rax, [rel snapshot_platform_event_sequence]
    cmp rax, 1
    jne test_fail

    mov qword [rel failure_stage], 0
    jmp test_pass

setup_runtime:
    sub rsp, 8
    lea rdi, [rel context]
    lea rsi, [rel slots]
    mov edx, CONSOLE_CAP
    mov ecx, NEBO_CONSOLE_RUNTIME_ABI_VERSION
    call nebo_console_runtime_context_init
    test eax, eax
    jnz .setup_runtime_done
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
.setup_runtime_done:
    add rsp, 8
    ret

setup_default_domain:
    sub rsp, 8
    call setup_runtime
    test eax, eax
    jnz .setup_default_done
    lea rdi, [rel context]
    lea rsi, [rel handle]
    call nebo_console_manager_default_get_or_create
    test eax, eax
    jnz .setup_default_done
    lea rdi, [rel context]
    mov rsi, [rel handle]
    lea rdx, [rel domain_ptr]
    call nebo_console_domain_from_handle
    test eax, eax
    jnz .setup_default_done
    mov esi, 8
    call run_scheduler
.setup_default_done:
    add rsp, 8
    ret

; ESI=max scheduler rounds.
run_scheduler:
    sub rsp, 8
    lea rdi, [rel context]
    lea rdx, [rel progress]
    call nebo_console_scheduler_run
    add rsp, 8
    ret

; EDI=kind, ESI=source order.
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

prng_next:
    mov rax, [rel seed]
    mov rdx, rax
    shl rdx, 13
    xor rax, rdx
    mov rdx, rax
    shr rdx, 7
    xor rax, rdx
    mov rdx, rax
    shl rdx, 17
    xor rax, rdx
    mov [rel seed], rax
    ret

test_pass:
    xor edi, edi
    call neboc_host_process_exit
    hlt

test_fail:
    mov rdi, [rel failure_stage]
    test rdi, rdi
    jnz .test_fail_exit
    mov edi, 1
.test_fail_exit:
    call neboc_host_process_exit
    hlt

test_usage:
    mov edi, 2
    call neboc_host_process_exit
    hlt

section .note.GNU-stack noalloc noexec nowrite progbits
