; G100 source-to-effect probe for bounded logs/progress/stream/timeline records.
bits 64
default rel
%define NEBO_G100_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/observability_source_probe.inc"
%include "runtime/console/observability.inc"

global nebo_g100_source_probe
global nebo_g100_observation_probe
global nebo_g100_counter_probe
global nebo_g100_negative_probe

section .bss align=16
g100_request: resb NEBO_G100_REQUEST_SIZE
g100_headless: resb NEBO_G100_RESULT_SIZE
g100_live: resb NEBO_G100_RESULT_SIZE
g100_events: resb NEBO_G100_MAX_EVENTS*NEBO_G100_EVENT_SIZE

section .text
g100_clear:
    lea rdi,[rel g100_request]
    mov ecx,NEBO_G100_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    lea rdi,[rel g100_headless]
    mov ecx,NEBO_G100_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g100_live]
    mov ecx,NEBO_G100_RESULT_SIZE/8
    rep stosq
    lea rdi,[rel g100_events]
    mov ecx,(NEBO_G100_MAX_EVENTS*NEBO_G100_EVENT_SIZE)/8
    rep stosq
    ret

; R12D=profile 1..10, R13D=source generation 1..255.
g100_prepare:
    call g100_clear
    mov [rel g100_request+NEBO_G100_REQUEST_MODE_OFFSET],r12d
    mov qword [rel g100_request+NEBO_G100_REQUEST_EVENT_COUNT_OFFSET],9
    lea rax,[rel g100_events]
    mov [rel g100_request+NEBO_G100_REQUEST_EVENTS_PTR_OFFSET],rax
    mov qword [rel g100_request+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET],12
    mov qword [rel g100_request+NEBO_G100_REQUEST_WINDOW_ITEMS_OFFSET],6
    mov qword [rel g100_request+NEBO_G100_REQUEST_LAST_ITEMS_OFFSET],3
    mov qword [rel g100_request+NEBO_G100_REQUEST_WINDOW_DURATION_OFFSET],80
    mov qword [rel g100_request+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET],4
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET],40
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_TOTAL_OFFSET],100
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_ACTIVE
    mov qword [rel g100_request+NEBO_G100_REQUEST_QUEUE_DEPTH_OFFSET],5
    mov qword [rel g100_request+NEBO_G100_REQUEST_BACKPRESSURE_POLICY_OFFSET],NEBO_G100_BACKPRESSURE_REJECT
    mov qword [rel g100_request+NEBO_G100_REQUEST_COMPLETED_WORKERS_OFFSET],4
    mov qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_SOURCE
    mov [rel g100_request+NEBO_G100_REQUEST_SOURCE_GENERATION_OFFSET],r13
    mov [rel g100_request+NEBO_G100_REQUEST_OWNER_GENERATION_OFFSET],r13
    mov qword [rel g100_request+NEBO_G100_REQUEST_TIME_FIELD_OFFSET],1
    mov [rel g100_request+NEBO_G100_REQUEST_TIMELINE_GENERATION_OFFSET],r13
    mov qword [rel g100_request+NEBO_G100_REQUEST_METRIC_ID_OFFSET],7
    mov qword [rel g100_request+NEBO_G100_REQUEST_SPEC_VERSION_OFFSET],NEBO_G100_SPEC_VERSION

    cmp r12d,1
    je .logs
    cmp r12d,2
    je .progress
    cmp r12d,3
    je .stream
    cmp r12d,4
    je .parallel
    cmp r12d,5
    je .timeline
    cmp r12d,6
    je .reactive
    cmp r12d,7
    je .window
    cmp r12d,8
    je .metrics
    cmp r12d,9
    je .recovery
    jmp .closeout
.logs:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_STREAM | NEBO_G100_OPTION_TIME | NEBO_G100_OPTION_METRIC
    jmp .fill
.progress:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_METRIC | NEBO_G100_OPTION_TIME
    jmp .fill
.stream:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_STREAM | NEBO_G100_OPTION_WINDOW | NEBO_G100_OPTION_LAST
    jmp .fill
.parallel:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_STREAM | NEBO_G100_OPTION_TIMELINE
    jmp .fill
.timeline:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_TIME | NEBO_G100_OPTION_TIMELINE
    jmp .fill
.reactive:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_STREAM | NEBO_G100_OPTION_WINDOW
    mov qword [rel g100_request+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET],8
    mov qword [rel g100_request+NEBO_G100_REQUEST_QUEUE_DEPTH_OFFSET],8
    mov qword [rel g100_request+NEBO_G100_REQUEST_BACKPRESSURE_POLICY_OFFSET],NEBO_G100_BACKPRESSURE_PAUSE
    jmp .fill
.window:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_WINDOW | NEBO_G100_OPTION_LAST | NEBO_G100_OPTION_TIME
    mov qword [rel g100_request+NEBO_G100_REQUEST_WINDOW_ITEMS_OFFSET],5
    mov qword [rel g100_request+NEBO_G100_REQUEST_LAST_ITEMS_OFFSET],2
    jmp .fill
.metrics:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_METRIC | NEBO_G100_OPTION_TIME
    mov qword [rel g100_request+NEBO_G100_REQUEST_METRIC_ID_OFFSET],11
    jmp .fill
.recovery:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_STREAM | NEBO_G100_OPTION_TIMELINE
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_CANCELLED
    mov qword [rel g100_request+NEBO_G100_REQUEST_CANCELLED_WORKERS_OFFSET],1
    mov qword [rel g100_request+NEBO_G100_REQUEST_COMPLETED_WORKERS_OFFSET],3
    jmp .fill
.closeout:
    or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_KNOWN
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET],100
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_FINISHED

.fill:
    lea r8,[rel g100_events]
    xor ecx,ecx
.fill_loop:
    cmp rcx,9
    jae .prepared
    imul rax,rcx,NEBO_G100_EVENT_SIZE
    mov rdx,rcx
    imul rdx,10
    add rdx,r13
    mov [r8+rax+NEBO_G100_EVENT_TIME_OFFSET],rdx
    mov edx,ecx
    inc edx
    mov [r8+rax+NEBO_G100_EVENT_KIND_OFFSET],edx
    mov edx,ecx
    and edx,3
    mov [r8+rax+NEBO_G100_EVENT_WORKER_OFFSET],edx
    mov rdx,r13
    imul rdx,rdx,17
    add rdx,rcx
    inc rdx
    mov [r8+rax+NEBO_G100_EVENT_VALUE_OFFSET],rdx
    mov rdx,[rel g100_request+NEBO_G100_REQUEST_METRIC_ID_OFFSET]
    mov [r8+rax+NEBO_G100_EVENT_METRIC_OFFSET],rdx
    mov [r8+rax+NEBO_G100_EVENT_GENERATION_OFFSET],r13
    inc rcx
    jmp .fill_loop
.prepared:
    ret

; EDI=profile, ESI=source generation -> EAX=source-derived generation or -1.
nebo_g100_source_probe:
    push rbx
    push r12
    push r13
    push r14
    mov r12d,edi
    mov r13d,esi
    cmp r12d,1
    jb .source_failure
    cmp r12d,10
    ja .source_failure
    test r13d,r13d
    jz .source_failure
    cmp r13d,255
    ja .source_failure
    call g100_prepare
    mov dword [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],NEBO_G100_TARGET_HEADLESS
    lea rdi,[rel g100_request]
    lea rsi,[rel g100_headless]
    call nebo_g100_observability_model
    test eax,eax
    jnz .source_failure
    mov dword [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],NEBO_G100_TARGET_LIVE
    lea rdi,[rel g100_request]
    lea rsi,[rel g100_live]
    call nebo_g100_observability_model
    test eax,eax
    jnz .source_failure
    xor ebx,ebx
    lea r10,[rel g100_headless]
    lea r11,[rel g100_live]
.compare:
    cmp ebx,NEBO_G100_RESULT_TARGET_OFFSET
    je .skip_target
    mov rax,[r10+rbx]
    cmp rax,[r11+rbx]
    jne .source_failure
.skip_target:
    add ebx,8
    cmp ebx,NEBO_G100_RESULT_SIZE
    jb .compare
    cmp qword [rel g100_headless+NEBO_G100_RESULT_SEQUENCE_DIGEST_OFFSET],0
    je .source_failure
    mov eax,r13d
    jmp .source_done
.source_failure:
    mov eax,-1
.source_done:
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

; EDI=profile, ESI=source generation, EDX=target -> RAX=sequence digest or 0.
nebo_g100_observation_probe:
    push r12
    push r13
    push r14
    mov r12d,edi
    mov r13d,esi
    mov r14d,edx
    cmp r12d,1
    jb .observation_failure
    cmp r12d,10
    ja .observation_failure
    test r13d,r13d
    jz .observation_failure
    cmp r14d,NEBO_G100_TARGET_HEADLESS
    jb .observation_failure
    cmp r14d,NEBO_G100_TARGET_LIVE
    ja .observation_failure
    call g100_prepare
    mov [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],r14d
    lea rdi,[rel g100_request]
    lea rsi,[rel g100_headless]
    call nebo_g100_observability_model
    test eax,eax
    jnz .observation_failure
    mov rax,[rel g100_headless+NEBO_G100_RESULT_SEQUENCE_DIGEST_OFFSET]
    jmp .observation_done
.observation_failure:
    xor eax,eax
.observation_done:
    pop r14
    pop r13
    pop r12
    ret

; EDI=profile, ESI=generation, EDX=field 1..8 -> selected observed counter.
nebo_g100_counter_probe:
    push r12
    push r13
    push r14
    mov r12d,edi
    mov r13d,esi
    mov r14d,edx
    cmp r12d,1
    jb .counter_failure
    cmp r12d,10
    ja .counter_failure
    test r13d,r13d
    jz .counter_failure
    cmp r14d,1
    jb .counter_failure
    cmp r14d,8
    ja .counter_failure
    call g100_prepare
    mov dword [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],NEBO_G100_TARGET_HEADLESS
    lea rdi,[rel g100_request]
    lea rsi,[rel g100_headless]
    call nebo_g100_observability_model
    test eax,eax
    jnz .counter_failure
    cmp r14d,1
    je .counter_accepted
    cmp r14d,2
    je .counter_window
    cmp r14d,3
    je .counter_last
    cmp r14d,4
    je .counter_status
    cmp r14d,5
    je .counter_completed
    cmp r14d,6
    je .counter_cancelled
    cmp r14d,7
    je .counter_queue
    mov rax,[rel g100_headless+NEBO_G100_RESULT_EVENT_COUNT_OFFSET]
    jmp .counter_done
.counter_accepted: mov rax,[rel g100_headless+NEBO_G100_RESULT_ACCEPTED_EVENTS_OFFSET]
    jmp .counter_done
.counter_window: mov rax,[rel g100_headless+NEBO_G100_RESULT_WINDOW_COUNT_OFFSET]
    jmp .counter_done
.counter_last: mov rax,[rel g100_headless+NEBO_G100_RESULT_LAST_COUNT_OFFSET]
    jmp .counter_done
.counter_status: mov rax,[rel g100_headless+NEBO_G100_RESULT_STATUS_OFFSET]
    jmp .counter_done
.counter_completed: mov rax,[rel g100_headless+NEBO_G100_RESULT_COMPLETED_WORKERS_OFFSET]
    jmp .counter_done
.counter_cancelled: mov rax,[rel g100_headless+NEBO_G100_RESULT_CANCELLED_WORKERS_OFFSET]
    jmp .counter_done
.counter_queue: mov rax,[rel g100_headless+NEBO_G100_RESULT_QUEUE_PEAK_OFFSET]
    jmp .counter_done
.counter_failure:
    mov rax,-1
.counter_done:
    pop r14
    pop r13
    pop r12
    ret

; EDI=case 1..17 -> EAX=stable error; also verifies failure atomicity.
nebo_g100_negative_probe:
    push rbx
    push r12
    push r13
    mov ebx,edi
    mov r13d,47
    mov r12d,10
    call g100_prepare
    mov r12d,ebx
    mov dword [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],NEBO_G100_TARGET_HEADLESS
    cmp r12d,1
    je .bad_target
    cmp r12d,2
    je .null_events
    cmp r12d,3
    je .zero_count
    cmp r12d,4
    je .zero_capacity
    cmp r12d,5
    je .overflow
    cmp r12d,6
    je .bad_order
    cmp r12d,7
    je .terminal_update
    cmp r12d,8
    je .bad_progress
    cmp r12d,9
    je .zero_workers
    cmp r12d,10
    je .worker_sum
    cmp r12d,11
    je .bad_window
    cmp r12d,12
    je .bad_lifetime
    cmp r12d,13
    je .bad_options
    cmp r12d,14
    je .bad_version
    cmp r12d,15
    je .bad_event
    cmp r12d,16
    je .failed_terminal_update
    cmp r12d,17
    je .cancelled_terminal_update
    mov eax,NEBO_G100_ERROR_INVALID
    jmp .negative_done
.bad_target: mov dword [rel g100_request+NEBO_G100_REQUEST_TARGET_OFFSET],3
    jmp .invoke
.null_events: mov qword [rel g100_request+NEBO_G100_REQUEST_EVENTS_PTR_OFFSET],0
    jmp .invoke
.zero_count: mov qword [rel g100_request+NEBO_G100_REQUEST_EVENT_COUNT_OFFSET],0
    jmp .invoke
.zero_capacity: mov qword [rel g100_request+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET],0
    jmp .invoke
.overflow:
    mov qword [rel g100_request+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET],4
    mov qword [rel g100_request+NEBO_G100_REQUEST_QUEUE_DEPTH_OFFSET],4
    jmp .invoke
.bad_order:
    mov qword [rel g100_events+NEBO_G100_EVENT_SIZE+NEBO_G100_EVENT_TIME_OFFSET],1
    jmp .invoke
.terminal_update:
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET],100
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_FINISHED
    mov qword [rel g100_request+NEBO_G100_REQUEST_POST_TERMINAL_UPDATES_OFFSET],1
    jmp .invoke
.bad_progress: mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET],101
    jmp .invoke
.zero_workers: mov qword [rel g100_request+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET],0
    jmp .invoke
.worker_sum: mov qword [rel g100_request+NEBO_G100_REQUEST_COMPLETED_WORKERS_OFFSET],3
    jmp .invoke
.bad_window: mov qword [rel g100_request+NEBO_G100_REQUEST_LAST_ITEMS_OFFSET],7
    jmp .invoke
.bad_lifetime:
    inc qword [rel g100_request+NEBO_G100_REQUEST_OWNER_GENERATION_OFFSET]
    jmp .invoke
.bad_options: or qword [rel g100_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],1 << 20
    jmp .invoke
.bad_version: mov qword [rel g100_request+NEBO_G100_REQUEST_SPEC_VERSION_OFFSET],2
    jmp .invoke
.bad_event: mov dword [rel g100_events+NEBO_G100_EVENT_KIND_OFFSET],10
    jmp .invoke
.failed_terminal_update:
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_FAILED
    mov qword [rel g100_request+NEBO_G100_REQUEST_POST_TERMINAL_UPDATES_OFFSET],1
    jmp .invoke
.cancelled_terminal_update:
    mov qword [rel g100_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_CANCELLED
    mov qword [rel g100_request+NEBO_G100_REQUEST_POST_TERMINAL_UPDATES_OFFSET],1
.invoke:
    mov rbx,0x6b6b6b6b6b6b6b6b
    lea rdi,[rel g100_headless]
    mov rax,rbx
    mov ecx,NEBO_G100_RESULT_SIZE/8
    cld
    rep stosq
    lea rdi,[rel g100_request]
    lea rsi,[rel g100_headless]
    call nebo_g100_observability_model
    mov r13d,eax
    lea rsi,[rel g100_headless]
    mov ecx,NEBO_G100_RESULT_SIZE/8
.sentinel:
    cmp [rsi],rbx
    jne .atomicity_failure
    add rsi,8
    dec ecx
    jnz .sentinel
    mov eax,r13d
    jmp .negative_done
.atomicity_failure:
    mov eax,-99
.negative_done:
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
