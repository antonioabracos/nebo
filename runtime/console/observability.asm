; G100 bounded logical observability owner. It performs no I/O and publishes
; a result only after the whole stream, lifecycle and target contract passes.
bits 64
default rel
%define NEBO_G100_OBSERVABILITY_IMPLEMENTATION 1
%include "runtime/console/observability.inc"

global nebo_g100_observability_model

section .text
; RDI=request, RSI=result -> EAX=0 or stable NEBO_G100_ERROR_*.
nebo_g100_observability_model:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,NEBO_G100_RESULT_SIZE
    mov r12,rdi
    mov r13,rsi
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid
    mov r15,rsp
    mov rdi,r15
    mov ecx,NEBO_G100_RESULT_SIZE/8
    xor eax,eax
    cld
    rep stosq

    mov eax,[r12+NEBO_G100_REQUEST_MODE_OFFSET]
    cmp eax,1
    jb .bounds
    cmp eax,10
    ja .bounds
    mov eax,[r12+NEBO_G100_REQUEST_TARGET_OFFSET]
    cmp eax,NEBO_G100_TARGET_HEADLESS
    jb .target
    cmp eax,NEBO_G100_TARGET_LIVE
    ja .target
    mov r14,[r12+NEBO_G100_REQUEST_EVENT_COUNT_OFFSET]
    test r14,r14
    jz .bounds
    cmp r14,NEBO_G100_MAX_EVENTS
    ja .bounds
    mov rbx,[r12+NEBO_G100_REQUEST_EVENTS_PTR_OFFSET]
    test rbx,rbx
    jz .invalid
    test rbx,7
    jnz .invalid

    mov rax,[r12+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET]
    test rax,rax
    jz .unbounded
    cmp rax,NEBO_G100_MAX_CAPACITY
    ja .bounds
    mov rcx,[r12+NEBO_G100_REQUEST_BACKPRESSURE_POLICY_OFFSET]
    cmp rcx,NEBO_G100_BACKPRESSURE_REJECT
    jb .backpressure
    cmp rcx,NEBO_G100_BACKPRESSURE_PAUSE
    ja .backpressure
    mov rdx,[r12+NEBO_G100_REQUEST_QUEUE_DEPTH_OFFSET]
    cmp rdx,rax
    ja .backpressure
    cmp rcx,NEBO_G100_BACKPRESSURE_REJECT
    jne .capacity_ready
    cmp r14,rax
    ja .backpressure
.capacity_ready:
    mov rcx,r14
    cmp rcx,rax
    cmova rcx,rax
    mov [r15+NEBO_G100_RESULT_ACCEPTED_EVENTS_OFFSET],rcx
    cmp rdx,rcx
    cmovb rdx,rcx
    mov [r15+NEBO_G100_RESULT_QUEUE_PEAK_OFFSET],rdx

    mov rax,[r12+NEBO_G100_REQUEST_WINDOW_ITEMS_OFFSET]
    test rax,rax
    jz .time
    cmp rax,r14
    ja .time
    mov [r15+NEBO_G100_RESULT_WINDOW_COUNT_OFFSET],rax
    mov rcx,r14
    sub rcx,rax
    mov [r15+NEBO_G100_RESULT_WINDOW_START_OFFSET],rcx
    mov rdx,[r12+NEBO_G100_REQUEST_LAST_ITEMS_OFFSET]
    test rdx,rdx
    jz .time
    cmp rdx,rax
    ja .time
    mov [r15+NEBO_G100_RESULT_LAST_COUNT_OFFSET],rdx
    mov rdx,[r12+NEBO_G100_REQUEST_WINDOW_DURATION_OFFSET]
    test rdx,rdx
    jz .time
    cmp rdx,NEBO_G100_MAX_DURATION
    ja .time

    mov rax,[r12+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET]
    test rax,rax
    jz .worker
    cmp rax,NEBO_G100_MAX_WORKERS
    ja .worker
    mov rcx,[r12+NEBO_G100_REQUEST_CANCELLED_WORKERS_OFFSET]
    mov rdx,[r12+NEBO_G100_REQUEST_COMPLETED_WORKERS_OFFSET]
    mov rdi,rcx
    add rdi,rdx
    jc .worker
    cmp rdi,rax
    jne .worker
    mov [r15+NEBO_G100_RESULT_CANCELLED_WORKERS_OFFSET],rcx
    mov [r15+NEBO_G100_RESULT_COMPLETED_WORKERS_OFFSET],rdx

    mov rax,[r12+NEBO_G100_REQUEST_PROGRESS_TOTAL_OFFSET]
    test rax,rax
    jz .progress
    mov rcx,[r12+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET]
    cmp rcx,rax
    ja .progress
    mov rdx,[r12+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET]
    cmp rdx,NEBO_G100_PROGRESS_ACTIVE
    jb .progress
    cmp rdx,NEBO_G100_PROGRESS_CANCELLED
    ja .progress
    cmp rdx,NEBO_G100_PROGRESS_ACTIVE
    jne .terminal_state
    cmp rcx,rax
    jae .progress
    cmp qword [r12+NEBO_G100_REQUEST_POST_TERMINAL_UPDATES_OFFSET],0
    jne .terminal
    jmp .progress_ready
.terminal_state:
    cmp qword [r12+NEBO_G100_REQUEST_POST_TERMINAL_UPDATES_OFFSET],0
    jne .terminal
    cmp rdx,NEBO_G100_PROGRESS_FINISHED
    jne .progress_ready
    cmp rcx,rax
    jne .progress
.progress_ready:
    mov [r15+NEBO_G100_RESULT_STATUS_OFFSET],rdx

    mov rax,[r12+NEBO_G100_REQUEST_OPTIONS_OFFSET]
    mov rcx,rax
    and rcx,~NEBO_G100_OPTION_KNOWN
    jnz .options
    test rax,NEBO_G100_OPTION_SOURCE
    jz .options
    mov rcx,[r12+NEBO_G100_REQUEST_SOURCE_GENERATION_OFFSET]
    test rcx,rcx
    jz .source
    cmp rcx,[r12+NEBO_G100_REQUEST_OWNER_GENERATION_OFFSET]
    jne .lifetime
    cmp rcx,[r12+NEBO_G100_REQUEST_TIMELINE_GENERATION_OFFSET]
    jne .lifetime
    cmp qword [r12+NEBO_G100_REQUEST_TIME_FIELD_OFFSET],0
    je .time
    mov rdx,[r12+NEBO_G100_REQUEST_METRIC_ID_OFFSET]
    test rdx,rdx
    jz .source
    cmp rdx,64
    ja .source
    cmp qword [r12+NEBO_G100_REQUEST_SPEC_VERSION_OFFSET],NEBO_G100_SPEC_VERSION
    jne .version

    ; Validate stable time order, worker ownership and all logical event kinds.
    xor r10d,r10d
    xor r8d,r8d
    xor r11d,r11d
    mov r9,0xcbf29ce484222325
.event_loop:
    cmp r10,r14
    jae .events_ready
    imul rax,r10,NEBO_G100_EVENT_SIZE
    mov rdx,[rbx+rax+NEBO_G100_EVENT_TIME_OFFSET]
    test r10,r10
    jz .time_ordered
    cmp rdx,r8
    jb .order
.time_ordered:
    mov r8,rdx
    mov ecx,[rbx+rax+NEBO_G100_EVENT_KIND_OFFSET]
    cmp ecx,NEBO_G100_EVENT_LOG
    jb .event
    cmp ecx,NEBO_G100_EVENT_RECOVER
    ja .event
    mov edx,[rbx+rax+NEBO_G100_EVENT_WORKER_OFFSET]
    cmp rdx,[r12+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET]
    jae .worker
    bts r11,rdx
    mov rdx,[rbx+rax+NEBO_G100_EVENT_GENERATION_OFFSET]
    cmp rdx,[r12+NEBO_G100_REQUEST_SOURCE_GENERATION_OFFSET]
    jne .source
    cmp ecx,NEBO_G100_EVENT_METRIC
    jne .kind_count
    mov rdx,[rbx+rax+NEBO_G100_EVENT_METRIC_OFFSET]
    cmp rdx,[r12+NEBO_G100_REQUEST_METRIC_ID_OFFSET]
    jne .source
.kind_count:
    cmp ecx,NEBO_G100_EVENT_LOG
    je .count_log
    cmp ecx,NEBO_G100_EVENT_PROGRESS
    je .count_progress
    cmp ecx,NEBO_G100_EVENT_STREAM
    je .count_stream
    cmp ecx,NEBO_G100_EVENT_PARALLEL
    je .count_parallel
    cmp ecx,NEBO_G100_EVENT_TIMELINE
    je .count_timeline
    cmp ecx,NEBO_G100_EVENT_METRIC
    je .count_metric
    cmp ecx,NEBO_G100_EVENT_CANCEL
    je .count_cancel
    cmp ecx,NEBO_G100_EVENT_ERROR
    je .count_error
    inc qword [r15+NEBO_G100_RESULT_RECOVER_COUNT_OFFSET]
    jmp .digest
.count_log: inc qword [r15+NEBO_G100_RESULT_LOG_COUNT_OFFSET]
    jmp .digest
.count_progress: inc qword [r15+NEBO_G100_RESULT_PROGRESS_COUNT_OFFSET]
    jmp .digest
.count_stream: inc qword [r15+NEBO_G100_RESULT_STREAM_COUNT_OFFSET]
    jmp .digest
.count_parallel: inc qword [r15+NEBO_G100_RESULT_PARALLEL_COUNT_OFFSET]
    jmp .digest
.count_timeline: inc qword [r15+NEBO_G100_RESULT_TIMELINE_COUNT_OFFSET]
    jmp .digest
.count_metric:
    inc qword [r15+NEBO_G100_RESULT_METRIC_COUNT_OFFSET]
    mov rdx,[rbx+rax+NEBO_G100_EVENT_VALUE_OFFSET]
    xor [r15+NEBO_G100_RESULT_METRIC_DIGEST_OFFSET],rdx
    rol qword [r15+NEBO_G100_RESULT_METRIC_DIGEST_OFFSET],13
    jmp .digest
.count_cancel: inc qword [r15+NEBO_G100_RESULT_CANCEL_COUNT_OFFSET]
    jmp .digest
.count_error: inc qword [r15+NEBO_G100_RESULT_ERROR_COUNT_OFFSET]
.digest:
    mov rdx,[rbx+rax+NEBO_G100_EVENT_TIME_OFFSET]
    xor r9,rdx
    rol r9,7
    mov rdx,[rbx+rax+NEBO_G100_EVENT_KIND_OFFSET]
    xor r9,rdx
    rol r9,11
    mov rdx,[rbx+rax+NEBO_G100_EVENT_VALUE_OFFSET]
    xor r9,rdx
    rol r9,17
    mov rdx,[rbx+rax+NEBO_G100_EVENT_METRIC_OFFSET]
    xor r9,rdx
    rol r9,23
    mov rdx,[rbx+rax+NEBO_G100_EVENT_GENERATION_OFFSET]
    xor r9,rdx
    rol r9,29
    inc r10
    jmp .event_loop
.events_ready:
    mov [r15+NEBO_G100_RESULT_SEQUENCE_DIGEST_OFFSET],r9
    mov ecx,[r12+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET]
    mov rax,1
    shl rax,cl
    dec rax
    cmp r11,rax
    jne .worker

    ; The selected time window must fit its explicit duration budget.
    mov rcx,[r15+NEBO_G100_RESULT_WINDOW_START_OFFSET]
    imul rcx,rcx,NEBO_G100_EVENT_SIZE
    mov rdx,[rbx+rcx+NEBO_G100_EVENT_TIME_OFFSET]
    mov rcx,r14
    dec rcx
    imul rcx,rcx,NEBO_G100_EVENT_SIZE
    mov rax,[rbx+rcx+NEBO_G100_EVENT_TIME_OFFSET]
    sub rax,rdx
    cmp rax,[r12+NEBO_G100_REQUEST_WINDOW_DURATION_OFFSET]
    ja .time

    ; Option and subgroup contracts are checked against independently counted effects.
    mov rax,[r12+NEBO_G100_REQUEST_OPTIONS_OFFSET]
    test rax,NEBO_G100_OPTION_STREAM
    jnz .stream_result_selected
    mov qword [r15+NEBO_G100_RESULT_ACCEPTED_EVENTS_OFFSET],0
    mov qword [r15+NEBO_G100_RESULT_QUEUE_PEAK_OFFSET],0
.stream_result_selected:
    test rax,NEBO_G100_OPTION_WINDOW
    jnz .window_result_selected
    mov qword [r15+NEBO_G100_RESULT_WINDOW_START_OFFSET],0
    mov qword [r15+NEBO_G100_RESULT_WINDOW_COUNT_OFFSET],0
.window_result_selected:
    test rax,NEBO_G100_OPTION_LAST
    jnz .last_result_selected
    mov qword [r15+NEBO_G100_RESULT_LAST_COUNT_OFFSET],0
.last_result_selected:
    test rax,NEBO_G100_OPTION_METRIC
    jnz .metric_result_selected
    mov qword [r15+NEBO_G100_RESULT_METRIC_DIGEST_OFFSET],0
.metric_result_selected:
    test rax,NEBO_G100_OPTION_STREAM
    jz .no_stream_option
    cmp qword [r15+NEBO_G100_RESULT_STREAM_COUNT_OFFSET],0
    je .options
.no_stream_option:
    test rax,NEBO_G100_OPTION_TIMELINE
    jz .no_timeline_option
    cmp qword [r15+NEBO_G100_RESULT_TIMELINE_COUNT_OFFSET],0
    je .options
.no_timeline_option:
    test rax,NEBO_G100_OPTION_METRIC
    jz .profile_check
    cmp qword [r15+NEBO_G100_RESULT_METRIC_COUNT_OFFSET],0
    je .options
.profile_check:
    mov eax,[r12+NEBO_G100_REQUEST_MODE_OFFSET]
    cmp eax,1
    jne .not_log_profile
    cmp qword [r15+NEBO_G100_RESULT_LOG_COUNT_OFFSET],0
    je .event
.not_log_profile:
    cmp eax,2
    jne .not_progress_profile
    cmp qword [r15+NEBO_G100_RESULT_PROGRESS_COUNT_OFFSET],0
    je .event
.not_progress_profile:
    cmp eax,4
    jne .not_parallel_profile
    cmp qword [r15+NEBO_G100_RESULT_PARALLEL_COUNT_OFFSET],0
    je .event
.not_parallel_profile:
    cmp eax,9
    jne .publish
    mov rcx,[r15+NEBO_G100_RESULT_CANCEL_COUNT_OFFSET]
    add rcx,[r15+NEBO_G100_RESULT_ERROR_COUNT_OFFSET]
    add rcx,[r15+NEBO_G100_RESULT_RECOVER_COUNT_OFFSET]
    cmp rcx,3
    jb .event

.publish:
    mov [r15+NEBO_G100_RESULT_EVENT_COUNT_OFFSET],r14
    mov rax,[r12+NEBO_G100_REQUEST_SOURCE_GENERATION_OFFSET]
    mov [r15+NEBO_G100_RESULT_SOURCE_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G100_REQUEST_SPEC_VERSION_OFFSET]
    mov [r15+NEBO_G100_RESULT_SPEC_VERSION_OFFSET],rax
    mov eax,[r12+NEBO_G100_REQUEST_TARGET_OFFSET]
    mov [r15+NEBO_G100_RESULT_TARGET_OFFSET],rax
    mov rdi,r13
    mov rsi,r15
    mov ecx,NEBO_G100_RESULT_SIZE/8
    cld
    rep movsq
    xor eax,eax
    jmp .done

.invalid: mov eax,NEBO_G100_ERROR_INVALID
    jmp .done
.bounds: mov eax,NEBO_G100_ERROR_BOUNDS
    jmp .done
.unbounded: mov eax,NEBO_G100_ERROR_UNBOUNDED
    jmp .done
.order: mov eax,NEBO_G100_ERROR_ORDER
    jmp .done
.backpressure: mov eax,NEBO_G100_ERROR_BACKPRESSURE
    jmp .done
.progress: mov eax,NEBO_G100_ERROR_PROGRESS
    jmp .done
.terminal: mov eax,NEBO_G100_ERROR_TERMINAL
    jmp .done
.worker: mov eax,NEBO_G100_ERROR_WORKER
    jmp .done
.time: mov eax,NEBO_G100_ERROR_TIME
    jmp .done
.lifetime: mov eax,NEBO_G100_ERROR_LIFETIME
    jmp .done
.options: mov eax,NEBO_G100_ERROR_OPTIONS
    jmp .done
.version: mov eax,NEBO_G100_ERROR_VERSION
    jmp .done
.source: mov eax,NEBO_G100_ERROR_SOURCE
    jmp .done
.target: mov eax,NEBO_G100_ERROR_TARGET
    jmp .done
.event: mov eax,NEBO_G100_ERROR_EVENT
.done:
    add rsp,NEBO_G100_RESULT_SIZE
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
