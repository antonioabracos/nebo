; Source-to-effect bridge for internal log, progress and timeline services.
bits 64
default rel
%define NEBO_G111_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_lifecycle_source_probe.inc"
%include "runtime/internal_visual_console.inc"
%include "runtime/console/observability.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g111_clear_begin:
g111_console: resb NEBO_G110_CONSOLE_SIZE
g111_limits: resb NEBO_G110_LIMIT_SIZE
g111_panel: resb NEBO_G110_PANEL_SIZE
g111_log: resb NEBO_G111_LOG_SIZE
g111_log_receipt: resb NEBO_G111_LOG_RECEIPT_SIZE
g111_flush_receipt: resb NEBO_G111_FLUSH_SIZE
g111_progress_main: resb NEBO_G111_PROGRESS_SIZE
g111_progress_failed: resb NEBO_G111_PROGRESS_SIZE
g111_progress_cancelled: resb NEBO_G111_PROGRESS_SIZE
g111_progress_snapshot: resb NEBO_G111_PROGRESS_SNAPSHOT_SIZE
g111_timeline_events: resb NEBO_G111_TIMELINE_SIZE
g111_timeline_stream: resb NEBO_G111_TIMELINE_SIZE
g111_timeline_parallel: resb NEBO_G111_TIMELINE_SIZE
g111_timeline_training: resb NEBO_G111_TIMELINE_SIZE
g111_timeline_receipt: resb NEBO_G111_TIMELINE_RECEIPT_SIZE
g111_request: resb NEBO_G100_REQUEST_SIZE
g111_events: resb 9*NEBO_G100_EVENT_SIZE
g111_last_mode: resq 1
g111_last_seed: resq 1
g111_clear_end:

section .text
global nebo_g111_source_probe
global nebo_g111_surface_probe
global nebo_g111_negative_probe

g111_probe_clear:
    lea rdi,[rel g111_clear_begin]
    mov ecx,(g111_clear_end-g111_clear_begin)/8
    xor eax,eax
    cld
    rep stosq
    ret

; EBP contains the source seed. Build the canonical bounded G100 request used
; by every timeline constructor; every event has stable owner/generation data.
g111_prepare_request:
    mov dword [rel g111_request+NEBO_G100_REQUEST_MODE_OFFSET],10
    mov dword [rel g111_request+NEBO_G100_REQUEST_TARGET_OFFSET],NEBO_G100_TARGET_HEADLESS
    mov qword [rel g111_request+NEBO_G100_REQUEST_EVENT_COUNT_OFFSET],9
    lea rax,[rel g111_events]
    mov [rel g111_request+NEBO_G100_REQUEST_EVENTS_PTR_OFFSET],rax
    mov qword [rel g111_request+NEBO_G100_REQUEST_STREAM_CAPACITY_OFFSET],12
    mov qword [rel g111_request+NEBO_G100_REQUEST_WINDOW_ITEMS_OFFSET],6
    mov qword [rel g111_request+NEBO_G100_REQUEST_LAST_ITEMS_OFFSET],3
    mov qword [rel g111_request+NEBO_G100_REQUEST_WINDOW_DURATION_OFFSET],100
    mov qword [rel g111_request+NEBO_G100_REQUEST_WORKER_COUNT_OFFSET],4
    mov qword [rel g111_request+NEBO_G100_REQUEST_PROGRESS_CURRENT_OFFSET],100
    mov qword [rel g111_request+NEBO_G100_REQUEST_PROGRESS_TOTAL_OFFSET],100
    mov qword [rel g111_request+NEBO_G100_REQUEST_PROGRESS_STATE_OFFSET],NEBO_G100_PROGRESS_FINISHED
    mov qword [rel g111_request+NEBO_G100_REQUEST_QUEUE_DEPTH_OFFSET],5
    mov qword [rel g111_request+NEBO_G100_REQUEST_BACKPRESSURE_POLICY_OFFSET],NEBO_G100_BACKPRESSURE_REJECT
    mov qword [rel g111_request+NEBO_G100_REQUEST_COMPLETED_WORKERS_OFFSET],4
    mov qword [rel g111_request+NEBO_G100_REQUEST_OPTIONS_OFFSET],NEBO_G100_OPTION_KNOWN
    mov [rel g111_request+NEBO_G100_REQUEST_SOURCE_GENERATION_OFFSET],rbp
    mov [rel g111_request+NEBO_G100_REQUEST_OWNER_GENERATION_OFFSET],rbp
    mov qword [rel g111_request+NEBO_G100_REQUEST_TIME_FIELD_OFFSET],1
    mov [rel g111_request+NEBO_G100_REQUEST_TIMELINE_GENERATION_OFFSET],rbp
    mov qword [rel g111_request+NEBO_G100_REQUEST_METRIC_ID_OFFSET],7
    mov qword [rel g111_request+NEBO_G100_REQUEST_SPEC_VERSION_OFFSET],NEBO_G100_SPEC_VERSION
    lea r8,[rel g111_events]
    xor ecx,ecx
.event:
    imul rax,rcx,NEBO_G100_EVENT_SIZE
    mov rdx,rcx
    imul rdx,10
    add rdx,rbp
    mov [r8+rax+NEBO_G100_EVENT_TIME_OFFSET],rdx
    mov edx,ecx
    inc edx
    mov [r8+rax+NEBO_G100_EVENT_KIND_OFFSET],edx
    mov edx,ecx
    and edx,3
    mov [r8+rax+NEBO_G100_EVENT_WORKER_OFFSET],edx
    mov rdx,rbp
    imul rdx,17
    add rdx,rcx
    inc rdx
    mov [r8+rax+NEBO_G100_EVENT_VALUE_OFFSET],rdx
    mov qword [r8+rax+NEBO_G100_EVENT_METRIC_OFFSET],7
    mov [r8+rax+NEBO_G100_EVENT_GENERATION_OFFSET],rbp
    inc ecx
    cmp ecx,9
    jb .event
    ret

; EDI=subgroup mode 1..9, ESI=source seed 3101..3109.
nebo_g111_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov ebx,edi
    mov ebp,esi
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G111_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G111_SOURCE_MIN_SEED
    jb .invalid
    cmp ebp,NEBO_G111_SOURCE_MAX_SEED
    ja .invalid
    mov eax,ebp
    sub eax,3100
    cmp eax,ebx
    jne .invalid
    call g111_probe_clear
    mov [rel g111_last_mode],rbx
    mov [rel g111_last_seed],rbp

    mov qword [rel g111_limits+NEBO_G110_LIMIT_LINES],64
    mov qword [rel g111_limits+NEBO_G110_LIMIT_BYTES],4096
    mov qword [rel g111_limits+NEBO_G110_LIMIT_PANELS],4
    lea rdi,[rel g111_console]
    mov esi,NEBO_G110_MODE_HEADLESS
    mov edx,NEBO_G110_THEME_DEFAULT
    lea rcx,[rel g111_limits]
    mov r8d,NEBO_G110_CAP_ALL
    call nebo_g110_console_open
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_panel]
    lea edx,[rbp+50]
    mov ecx,NEBO_G110_PANEL_TIMELINE
    lea r8d,[rbp+60]
    call nebo_g110_panel_create
    test eax,eax
    jnz .effect

    lea rdi,[rel g111_console]
    lea rsi,[rel g111_log]
    lea edx,[rbp+100]
    mov ecx,16
    mov r8d,512
    call nebo_g111_log_group
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_log]
    lea esi,[rbp+200]
    call nebo_g111_log_tag
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_log]
    lea esi,[rbp+300]
    call nebo_g111_log_branch
    test eax,eax
    jnz .effect

%macro G111_EMIT 3
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_log]
    lea edx,[rbp+%2]
    mov ecx,%3
    lea r8,[rel g111_log_receipt]
    call %1
    test eax,eax
    jnz .effect
%endmacro
    G111_EMIT nebo_g111_log_trace,401,3
    G111_EMIT nebo_g111_log_debug,402,4
    G111_EMIT nebo_g111_log_info,403,5
    G111_EMIT nebo_g111_log_warn,404,6
    G111_EMIT nebo_g111_log_error,405,7
%undef G111_EMIT
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_log]
    lea rdx,[rel g111_flush_receipt]
    call nebo_g111_log_flush
    test eax,eax
    jnz .effect

%macro G111_PROGRESS_CREATE 4
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_panel]
    lea rdx,[rel %1]
    lea ecx,[rbp+%2]
    mov r8d,%3
    lea r9d,[rbp+%4]
    call nebo_g111_progress_create
    test eax,eax
    jnz .effect
%endmacro
    G111_PROGRESS_CREATE g111_progress_main,500,100,600
    G111_PROGRESS_CREATE g111_progress_failed,501,50,601
    G111_PROGRESS_CREATE g111_progress_cancelled,502,70,602
%undef G111_PROGRESS_CREATE

    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    mov edx,25
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_update
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    mov edx,10
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_increment
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    lea edx,[rbp+700]
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_message
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    lea rdx,[rel g111_progress_snapshot]
    call nebo_g111_progress_finish
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_failed]
    lea edx,[rbp+800]
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_fail
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_cancelled]
    lea edx,[rbp+900]
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_cancel
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_progress_main]
    lea rsi,[rel g111_progress_snapshot]
    call nebo_g111_progress_snapshot
    test eax,eax
    jnz .effect

    call g111_prepare_request
    lea rdi,[rel g111_timeline_events]
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_events
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_timeline_stream]
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_stream
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_timeline_parallel]
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_parallel
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_timeline_training]
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_training
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_timeline_events]
    mov esi,4
    call nebo_g111_timeline_limit
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_timeline_events]
    mov esi,1
    mov edx,3
    call nebo_g111_timeline_window
    test eax,eax
    jnz .effect
    mov eax,ebx
    dec eax
    xor edx,edx
    mov ecx,3
    div ecx
    inc edx
    lea rdi,[rel g111_timeline_events]
    mov esi,edx
    lea rdx,[rel g111_timeline_receipt]
    call nebo_g111_timeline_export
    test eax,eax
    jnz .effect

    lea rdi,[rel g111_console]
    lea rsi,[rel g111_panel]
    call nebo_g110_panel_remove
    test eax,eax
    jnz .effect
    lea rdi,[rel g111_console]
    call nebo_g110_console_close
    test eax,eax
    jnz .effect
    mov eax,ebp
    jmp .done
.invalid:
    mov eax,-1
    jmp .done
.effect:
    mov eax,-2
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI=field 1..20. Return an independently testable service observation.
nebo_g111_surface_probe:
    cmp edi,1
    jb .zero
    cmp edi,20
    ja .zero
    lea rdx,[rel .table]
    movsxd rax,dword [rdx+rdi*4-4]
    add rax,rdx
    jmp rax
.table:
    dd .records-.table,.trace-.table,.error-.table,.group-.table
    dd .flushes-.table,.main_state-.table,.main_current-.table
    dd .failed_state-.table,.cancelled_state-.table,.progress_generation-.table
    dd .timeline_source-.table,.timeline_count-.table,.timeline_window-.table
    dd .timeline_format-.table,.log_digest-.table,.progress_digest-.table
    dd .timeline_digest-.table,.console_state-.table,.panel_cleanup-.table
    dd .maturity-.table
.records: mov rax,[rel g111_log+NEBO_G111_LOG_RECORDS]
    ret
.trace: mov rax,[rel g111_log+NEBO_G111_LOG_TRACE_COUNT]
    ret
.error: mov rax,[rel g111_log+NEBO_G111_LOG_ERROR_COUNT]
    ret
.group: mov rax,[rel g111_log+NEBO_G111_LOG_GROUP]
    ret
.flushes: mov rax,[rel g111_log+NEBO_G111_LOG_FLUSHES]
    ret
.main_state: mov rax,[rel g111_progress_main+NEBO_G111_PROGRESS_STATE]
    ret
.main_current: mov rax,[rel g111_progress_main+NEBO_G111_PROGRESS_CURRENT]
    ret
.failed_state: mov rax,[rel g111_progress_failed+NEBO_G111_PROGRESS_STATE]
    ret
.cancelled_state: mov rax,[rel g111_progress_cancelled+NEBO_G111_PROGRESS_STATE]
    ret
.progress_generation: mov rax,[rel g111_progress_snapshot+NEBO_G111_PROGRESS_SNAPSHOT_GENERATION]
    ret
.timeline_source: mov rax,[rel g111_timeline_events+NEBO_G111_TIMELINE_SOURCE]
    ret
.timeline_count: mov rax,[rel g111_timeline_events+NEBO_G111_TIMELINE_EVENT_COUNT]
    ret
.timeline_window: mov rax,[rel g111_timeline_events+NEBO_G111_TIMELINE_WINDOW_COUNT]
    ret
.timeline_format: mov rax,[rel g111_timeline_events+NEBO_G111_TIMELINE_EXPORT_FORMAT]
    ret
.log_digest: mov rax,[rel g111_log+NEBO_G111_LOG_DIGEST]
    ret
.progress_digest: mov rax,[rel g111_progress_main+NEBO_G111_PROGRESS_DIGEST]
    ret
.timeline_digest: mov rax,[rel g111_timeline_receipt+NEBO_G111_TIMELINE_RECEIPT_DIGEST]
    ret
.console_state: mov rax,[rel g111_console+NEBO_G110_CONSOLE_STATE]
    ret
.panel_cleanup: mov rax,[rel g111_panel+NEBO_G110_PANEL_CLEANUPS]
    ret
.maturity: mov rax,[rel g111_timeline_receipt+NEBO_G111_TIMELINE_RECEIPT_MATURITY]
    ret
.zero:
    xor eax,eax
    ret

; EDI=case 1..16. Each case proves a typed rejection and unchanged state.
nebo_g111_negative_probe:
    push rbx
    push r12
    mov ebx,edi
    cmp ebx,1
    jb .bad
    cmp ebx,NEBO_G111_SOURCE_NEGATIVE_COUNT
    ja .bad
    mov edi,1
    mov esi,3101
    call nebo_g111_source_probe
    cmp eax,3101
    jne .bad
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_seed
    cmp ebx,3
    je .tag_zero
    cmp ebx,4
    je .closed_emit
    cmp ebx,5
    je .flush_null
    cmp ebx,6
    je .removed_panel
    cmp ebx,7
    je .snapshot_null
    cmp ebx,8
    je .terminal_again
    cmp ebx,9
    je .limit_zero
    cmp ebx,10
    je .limit_large
    cmp ebx,11
    je .window_zero
    cmp ebx,12
    je .window_large
    cmp ebx,13
    je .format_zero
    cmp ebx,14
    je .export_null
    cmp ebx,15
    je .timeline_busy
    jmp .timeline_null
.bad_mode:
    xor edi,edi
    mov esi,3101
    call nebo_g111_source_probe
    cmp eax,-1
    jne .bad
    jmp .ok
.bad_seed:
    mov edi,1
    mov esi,3102
    call nebo_g111_source_probe
    cmp eax,-1
    jne .bad
    jmp .ok
.tag_zero:
    mov r12,[rel g111_log+NEBO_G111_LOG_DIGEST]
    lea rdi,[rel g111_log]
    xor esi,esi
    call nebo_g111_log_tag
    cmp eax,-NEBO_G111_ERROR_RANGE
    jne .bad
    cmp [rel g111_log+NEBO_G111_LOG_DIGEST],r12
    jne .bad
    jmp .ok
.closed_emit:
    mov r12,[rel g111_log+NEBO_G111_LOG_DIGEST]
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_log]
    mov edx,1
    mov ecx,1
    lea r8,[rel g111_log_receipt]
    call nebo_g111_log_trace
    cmp eax,-NEBO_G111_ERROR_STATE
    jne .bad
    cmp [rel g111_log+NEBO_G111_LOG_DIGEST],r12
    jne .bad
    jmp .ok
.flush_null:
    mov r12,[rel g111_log+NEBO_G111_LOG_FLUSHES]
    lea rdi,[rel g111_console]
    lea rsi,[rel g111_log]
    xor edx,edx
    call nebo_g111_log_flush
    cmp eax,-NEBO_G111_ERROR_INVALID
    jne .bad
    cmp [rel g111_log+NEBO_G111_LOG_FLUSHES],r12
    jne .bad
    jmp .ok
.removed_panel:
    mov r12,[rel g111_progress_main+NEBO_G111_PROGRESS_DIGEST]
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    mov edx,10
    lea rcx,[rel g111_progress_snapshot]
    call nebo_g111_progress_increment
    cmp eax,-NEBO_G111_ERROR_STATE
    jne .bad
    cmp [rel g111_progress_main+NEBO_G111_PROGRESS_DIGEST],r12
    jne .bad
    jmp .ok
.snapshot_null:
    lea rdi,[rel g111_progress_main]
    xor esi,esi
    call nebo_g111_progress_snapshot
    cmp eax,-NEBO_G111_ERROR_INVALID
    jne .bad
    jmp .ok
.terminal_again:
    mov r12,[rel g111_progress_main+NEBO_G111_PROGRESS_DIGEST]
    lea rdi,[rel g111_panel]
    lea rsi,[rel g111_progress_main]
    lea rdx,[rel g111_progress_snapshot]
    call nebo_g111_progress_finish
    cmp eax,-NEBO_G111_ERROR_STATE
    jne .bad
    cmp [rel g111_progress_main+NEBO_G111_PROGRESS_DIGEST],r12
    jne .bad
    jmp .ok
.limit_zero:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    xor esi,esi
    call nebo_g111_timeline_limit
    cmp eax,-NEBO_G111_ERROR_RANGE
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.limit_large:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    mov esi,10
    call nebo_g111_timeline_limit
    cmp eax,-NEBO_G111_ERROR_LIMIT
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.window_zero:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    xor esi,esi
    xor edx,edx
    call nebo_g111_timeline_window
    cmp eax,-NEBO_G111_ERROR_RANGE
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.window_large:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    mov esi,8
    mov edx,3
    call nebo_g111_timeline_window
    cmp eax,-NEBO_G111_ERROR_RANGE
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.format_zero:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    xor esi,esi
    lea rdx,[rel g111_timeline_receipt]
    call nebo_g111_timeline_export
    cmp eax,-NEBO_G111_ERROR_FORMAT
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.export_null:
    lea rdi,[rel g111_timeline_events]
    mov esi,NEBO_G111_FORMAT_JSONL
    xor edx,edx
    call nebo_g111_timeline_export
    cmp eax,-NEBO_G111_ERROR_INVALID
    jne .bad
    jmp .ok
.timeline_busy:
    mov r12,[rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST]
    lea rdi,[rel g111_timeline_events]
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_events
    cmp eax,-NEBO_G111_ERROR_BUSY
    jne .bad
    cmp [rel g111_timeline_events+NEBO_G111_TIMELINE_DIGEST],r12
    jne .bad
    jmp .ok
.timeline_null:
    xor edi,edi
    lea rsi,[rel g111_request]
    call nebo_g111_timeline_from_events
    cmp eax,-NEBO_G111_ERROR_INVALID
    jne .bad
.ok:
    xor eax,eax
    jmp .done
.bad:
    mov eax,-1
.done:
    pop r12
    pop rbx
    ret
