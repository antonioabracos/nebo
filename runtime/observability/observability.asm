; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F06 bounded local structured observability.
bits 64
default rel
%include "compiler/abi/internal/x86_64/neboc_internal_abi.inc"
%include "runtime/observability/observability.inc"

extern nebo_capability_precheck

section .text

; rdi=state. Capability consumption is the last check before mutation.
obs_authorize:
    sub rsp,8
    mov rsi,[rdi+NEBO_OBS_STATE_CAPABILITY]
    mov r8,[rdi+NEBO_OBS_STATE_SCOPE]
    mov rdi,[rdi+NEBO_OBS_STATE_AUTHORITY]
    mov edx,NEBO_EFFECT_CONSOLE_WRITE
    mov ecx,1
    mov r9d,1
    call nebo_capability_precheck
    add rsp,8
    ret

; rdi=state,rsi=kind,rdx=name,rcx=time,r8=value -> rax=sequence.
; Capacity has already been checked and there are no failure paths.
obs_record_basic:
    mov r10,[rdi+NEBO_OBS_STATE_EVENT_COUNT]
    imul r11,r10,NEBO_OBS_EVENT_SIZE
    add r11,[rdi+NEBO_OBS_STATE_EVENTS]
    inc qword [rdi+NEBO_OBS_STATE_SEQUENCE]
    mov rax,[rdi+NEBO_OBS_STATE_SEQUENCE]
    mov [r11+NEBO_OBS_EVENT_SEQUENCE],rax
    mov [r11+NEBO_OBS_EVENT_KIND],rsi
    mov [r11+NEBO_OBS_EVENT_NAME],rdx
    mov [r11+NEBO_OBS_EVENT_TIMESTAMP],rcx
    mov qword [r11+NEBO_OBS_EVENT_TRACE],0
    mov qword [r11+NEBO_OBS_EVENT_SPAN],0
    mov [r11+NEBO_OBS_EVENT_VALUE],r8
    mov qword [r11+NEBO_OBS_EVENT_FIELDS],0
    mov qword [r11+NEBO_OBS_EVENT_LABELS],0
    mov qword [r11+NEBO_OBS_EVENT_FLAGS],0
    inc qword [rdi+NEBO_OBS_STATE_EVENT_COUNT]
    ret

; rdi=64-byte init request. All storage is caller-owned.
NEBOC_ABI_FUNCTION nebo_observability_init
    test rdi,rdi
    jz .init_invalid
    test rdi,7
    jnz .init_invalid
    push r12
    push r13
    mov r12,rdi
    mov r13,[r12+NEBO_OBS_INIT_STATE]
    test r13,r13
    jz .init_invalid_saved
    test r13,7
    jnz .init_invalid_saved
    mov rax,[r12+NEBO_OBS_INIT_EVENTS]
    test rax,rax
    jz .init_invalid_saved
    mov rcx,[r12+NEBO_OBS_INIT_EVENT_CAPACITY]
    test rcx,rcx
    jz .init_invalid_saved
    cmp rcx,NEBO_OBS_MAX_EVENTS
    ja .init_limit
    mov rdx,[r12+NEBO_OBS_INIT_SPANS]
    test rdx,rdx
    jz .init_invalid_saved
    mov r8,[r12+NEBO_OBS_INIT_SPAN_CAPACITY]
    test r8,r8
    jz .init_invalid_saved
    cmp r8,NEBO_OBS_MAX_SPANS
    ja .init_limit
    cmp qword [r12+NEBO_OBS_INIT_AUTHORITY],0
    je .init_invalid_saved
    cmp qword [r12+NEBO_OBS_INIT_CAPABILITY],0
    je .init_invalid_saved
    mov rdi,r13
    mov ecx,NEBO_OBS_STATE_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,NEBO_OBS_MAGIC
    mov [r13+NEBO_OBS_STATE_MAGIC],rax
    mov rax,[r12+NEBO_OBS_INIT_EVENTS]
    mov [r13+NEBO_OBS_STATE_EVENTS],rax
    mov rax,[r12+NEBO_OBS_INIT_EVENT_CAPACITY]
    mov [r13+NEBO_OBS_STATE_EVENT_CAPACITY],rax
    mov rax,[r12+NEBO_OBS_INIT_SPANS]
    mov [r13+NEBO_OBS_STATE_SPANS],rax
    mov rax,[r12+NEBO_OBS_INIT_SPAN_CAPACITY]
    mov [r13+NEBO_OBS_STATE_SPAN_CAPACITY],rax
    mov rax,[r12+NEBO_OBS_INIT_AUTHORITY]
    mov [r13+NEBO_OBS_STATE_AUTHORITY],rax
    mov rax,[r12+NEBO_OBS_INIT_CAPABILITY]
    mov [r13+NEBO_OBS_STATE_CAPABILITY],rax
    mov rax,[r12+NEBO_OBS_INIT_SCOPE]
    mov [r13+NEBO_OBS_STATE_SCOPE],rax
    xor eax,eax
    jmp .init_done
.init_limit:
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .init_done
.init_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.init_done:
    pop r13
    pop r12
    ret
.init_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

; rdi=112-byte request. Events contain metadata only, never raw field bytes.
NEBOC_ABI_FUNCTION nebo_observability_log
    test rdi,rdi
    jz .log_invalid
    test rdi,7
    jnz .log_invalid
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov qword [r12+NEBO_OBS_REQUEST_SEQUENCE],0
    mov qword [r12+NEBO_OBS_REQUEST_RESULT],0
    mov r13,[r12+NEBO_OBS_REQUEST_STATE]
    test r13,r13
    jz .log_invalid_saved
    mov rax,NEBO_OBS_MAGIC
    cmp [r13+NEBO_OBS_STATE_MAGIC],rax
    jne .log_invalid_saved
    cmp qword [r12+NEBO_OBS_REQUEST_NAME],0
    je .log_invalid_saved
    cmp qword [r12+NEBO_OBS_REQUEST_FIELDS],NEBO_OBS_MAX_FIELDS
    ja .log_limit
    cmp qword [r12+NEBO_OBS_REQUEST_LABELS],NEBO_OBS_MAX_LABELS
    ja .log_limit
    cmp qword [r12+NEBO_OBS_REQUEST_REDACTED],1
    ja .log_invalid_saved
    mov rax,[r12+NEBO_OBS_REQUEST_CLASS]
    test rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .log_invalid_saved
    test rax,rax
    jz .log_privacy_ok
    cmp qword [r12+NEBO_OBS_REQUEST_REDACTED],1
    jne .log_privacy
    cmp qword [r12+NEBO_OBS_REQUEST_PURPOSE],0
    je .log_privacy
.log_privacy_ok:
    mov rax,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_EVENT_CAPACITY]
    jae .log_drop
    mov rdi,r13
    call obs_authorize
    test eax,eax
    jnz .log_capability
    mov rdi,r13
    mov esi,NEBO_OBS_KIND_LOG
    mov rdx,[r12+NEBO_OBS_REQUEST_NAME]
    mov rcx,[r12+NEBO_OBS_REQUEST_TIME]
    mov r8,[r12+NEBO_OBS_REQUEST_VALUE]
    call obs_record_basic
    mov [r12+NEBO_OBS_REQUEST_SEQUENCE],rax
    mov rbx,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    dec rbx
    imul rbx,NEBO_OBS_EVENT_SIZE
    add rbx,[r13+NEBO_OBS_STATE_EVENTS]
    mov rax,[r12+NEBO_OBS_REQUEST_TRACE]
    mov [rbx+NEBO_OBS_EVENT_TRACE],rax
    mov rax,[r12+NEBO_OBS_REQUEST_SPAN]
    mov [rbx+NEBO_OBS_EVENT_SPAN],rax
    mov rax,[r12+NEBO_OBS_REQUEST_FIELDS]
    mov [rbx+NEBO_OBS_EVENT_FIELDS],rax
    mov rax,[r12+NEBO_OBS_REQUEST_LABELS]
    mov [rbx+NEBO_OBS_EVENT_LABELS],rax
    mov rax,[r12+NEBO_OBS_REQUEST_REDACTED]
    mov [rbx+NEBO_OBS_EVENT_FLAGS],rax
    mov qword [r12+NEBO_OBS_REQUEST_RESULT],1
    xor eax,eax
    jmp .log_done
.log_drop:
    inc qword [r13+NEBO_OBS_STATE_DROPS]
.log_limit:
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .log_done
.log_privacy:
    mov eax,NEBO_OBS_STATUS_PRIVACY
    jmp .log_done
.log_capability:
    mov eax,NEBO_OBS_STATUS_CAPABILITY
    jmp .log_done
.log_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.log_done:
    pop r13
    pop r12
    pop rbx
    ret
.log_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

; rdi=80-byte metric request. Unsigned counter increments are exact.
NEBOC_ABI_FUNCTION nebo_observability_counter_add
    test rdi,rdi
    jz .counter_invalid
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov qword [r12+NEBO_OBS_METRIC_RESULT],0
    mov qword [r12+NEBO_OBS_METRIC_SEQUENCE],0
    mov r13,[r12+NEBO_OBS_METRIC_STATE]
    test r13,r13
    jz .counter_invalid_saved
    mov rax,NEBO_OBS_MAGIC
    cmp [r13+NEBO_OBS_STATE_MAGIC],rax
    jne .counter_invalid_saved
    mov rdx,[r12+NEBO_OBS_METRIC_NAME]
    test rdx,rdx
    jz .counter_invalid_saved
    cmp qword [r12+NEBO_OBS_METRIC_VALUE],0
    je .counter_invalid_saved
    cmp qword [r12+NEBO_OBS_METRIC_LABELS],NEBO_OBS_MAX_LABELS
    ja .counter_limit
    mov rax,[r12+NEBO_OBS_METRIC_CLASS]
    test rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .counter_invalid_saved
    test rax,rax
    jz .counter_privacy_ok
    cmp qword [r12+NEBO_OBS_METRIC_REDACTED],1
    jne .counter_privacy
    cmp qword [r12+NEBO_OBS_METRIC_PURPOSE],0
    je .counter_privacy
.counter_privacy_ok:
    xor ecx,ecx
.counter_find:
    mov rax,[r13+NEBO_OBS_COUNTER_KEYS+rcx*8]
    test rax,rax
    jz .counter_slot
    cmp rax,rdx
    je .counter_slot
    inc rcx
    cmp rcx,NEBO_OBS_MAX_METRICS
    jb .counter_find
    mov eax,NEBO_OBS_STATUS_CARDINALITY
    jmp .counter_done
.counter_slot:
    lea rbx,[r13+NEBO_OBS_COUNTER_VALUES+rcx*8]
    mov r8,[rbx]
    add r8,[r12+NEBO_OBS_METRIC_VALUE]
    jc .counter_overflow
    mov rax,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_EVENT_CAPACITY]
    jae .counter_drop
    push rcx
    push rdx
    push r8
    sub rsp,8
    mov rdi,r13
    call obs_authorize
    add rsp,8
    pop r8
    pop rdx
    pop rcx
    test eax,eax
    jnz .counter_capability
    mov [r13+NEBO_OBS_COUNTER_KEYS+rcx*8],rdx
    mov [rbx],r8
    mov [r12+NEBO_OBS_METRIC_RESULT],r8
    mov rdi,r13
    mov esi,NEBO_OBS_KIND_COUNTER
    mov rcx,[r12+NEBO_OBS_METRIC_TIME]
    call obs_record_basic
    mov [r12+NEBO_OBS_METRIC_SEQUENCE],rax
    xor eax,eax
    jmp .counter_done
.counter_drop:
    inc qword [r13+NEBO_OBS_STATE_DROPS]
.counter_limit:
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .counter_done
.counter_overflow:
    mov eax,NEBO_OBS_STATUS_OVERFLOW
    jmp .counter_done
.counter_privacy:
    mov eax,NEBO_OBS_STATUS_PRIVACY
    jmp .counter_done
.counter_capability:
    mov eax,NEBO_OBS_STATUS_CAPABILITY
    jmp .counter_done
.counter_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.counter_done:
    pop r13
    pop r12
    pop rbx
    ret
.counter_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

; rdi=80-byte metric request; VALUE is an exact bucket index 0..15.
NEBOC_ABI_FUNCTION nebo_observability_histogram_observe
    test rdi,rdi
    jz .hist_invalid
    push rbx
    push r12
    push r13
    mov r12,rdi
    mov qword [r12+NEBO_OBS_METRIC_RESULT],0
    mov qword [r12+NEBO_OBS_METRIC_SEQUENCE],0
    mov r13,[r12+NEBO_OBS_METRIC_STATE]
    test r13,r13
    jz .hist_invalid_saved
    mov rax,NEBO_OBS_MAGIC
    cmp [r13+NEBO_OBS_STATE_MAGIC],rax
    jne .hist_invalid_saved
    mov rdx,[r12+NEBO_OBS_METRIC_NAME]
    test rdx,rdx
    jz .hist_invalid_saved
    mov r8,[r12+NEBO_OBS_METRIC_VALUE]
    cmp r8,NEBO_OBS_HIST_BUCKETS
    jae .hist_limit
    cmp qword [r12+NEBO_OBS_METRIC_LABELS],NEBO_OBS_MAX_LABELS
    ja .hist_limit
    mov rax,[r12+NEBO_OBS_METRIC_CLASS]
    test rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .hist_invalid_saved
    test rax,rax
    jz .hist_privacy_ok
    cmp qword [r12+NEBO_OBS_METRIC_REDACTED],1
    jne .hist_privacy
    cmp qword [r12+NEBO_OBS_METRIC_PURPOSE],0
    je .hist_privacy
.hist_privacy_ok:
    xor ecx,ecx
.hist_find:
    mov rax,[r13+NEBO_OBS_HIST_KEYS+rcx*8]
    test rax,rax
    jz .hist_slot
    cmp rax,rdx
    je .hist_slot
    inc rcx
    cmp rcx,NEBO_OBS_MAX_METRICS
    jb .hist_find
    mov eax,NEBO_OBS_STATUS_CARDINALITY
    jmp .hist_done
.hist_slot:
    mov r9,rcx
    shl r9,7
    lea rbx,[r13+NEBO_OBS_HIST_VALUES+r9]
    lea rbx,[rbx+r8*8]
    cmp qword [rbx],-1
    je .hist_overflow
    mov rax,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_EVENT_CAPACITY]
    jae .hist_drop
    push rcx
    push rdx
    push r8
    sub rsp,8
    mov rdi,r13
    call obs_authorize
    add rsp,8
    pop r8
    pop rdx
    pop rcx
    test eax,eax
    jnz .hist_capability
    mov [r13+NEBO_OBS_HIST_KEYS+rcx*8],rdx
    inc qword [rbx]
    mov rax,[rbx]
    mov [r12+NEBO_OBS_METRIC_RESULT],rax
    mov rdi,r13
    mov esi,NEBO_OBS_KIND_HISTOGRAM
    mov rcx,[r12+NEBO_OBS_METRIC_TIME]
    call obs_record_basic
    mov [r12+NEBO_OBS_METRIC_SEQUENCE],rax
    xor eax,eax
    jmp .hist_done
.hist_drop:
    inc qword [r13+NEBO_OBS_STATE_DROPS]
.hist_limit:
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .hist_done
.hist_overflow:
    mov eax,NEBO_OBS_STATUS_OVERFLOW
    jmp .hist_done
.hist_privacy:
    mov eax,NEBO_OBS_STATUS_PRIVACY
    jmp .hist_done
.hist_capability:
    mov eax,NEBO_OBS_STATUS_CAPABILITY
    jmp .hist_done
.hist_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.hist_done:
    pop r13
    pop r12
    pop rbx
    ret
.hist_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

; rdi=96-byte span request. Parent must be zero or an open local span.
NEBOC_ABI_FUNCTION nebo_observability_span_start
    test rdi,rdi
    jz .span_start_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_ID],0
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_SEQUENCE],0
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_RESULT],0
    mov r13,[r12+NEBO_OBS_SPAN_REQUEST_STATE]
    test r13,r13
    jz .span_start_invalid_saved
    mov rax,NEBO_OBS_MAGIC
    cmp [r13+NEBO_OBS_STATE_MAGIC],rax
    jne .span_start_invalid_saved
    cmp qword [r12+NEBO_OBS_SPAN_REQUEST_NAME],0
    je .span_start_invalid_saved
    cmp qword [r12+NEBO_OBS_SPAN_REQUEST_FIELDS],NEBO_OBS_MAX_FIELDS
    ja .span_start_limit
    cmp qword [r12+NEBO_OBS_SPAN_REQUEST_LABELS],NEBO_OBS_MAX_LABELS
    ja .span_start_limit
    mov rax,[r12+NEBO_OBS_SPAN_REQUEST_CLASS]
    test rax,~NEBO_PRIVACY_CLASS_MASK
    jnz .span_start_invalid_saved
    test rax,rax
    jz .span_start_privacy_ok
    cmp qword [r12+NEBO_OBS_SPAN_REQUEST_REDACTED],1
    jne .span_start_privacy
    cmp qword [r12+NEBO_OBS_SPAN_REQUEST_PURPOSE],0
    je .span_start_privacy
.span_start_privacy_ok:
    mov rax,[r13+NEBO_OBS_STATE_SPAN_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_SPAN_CAPACITY]
    jae .span_start_limit
    mov rax,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_EVENT_CAPACITY]
    jae .span_start_drop
    mov r14,[r12+NEBO_OBS_SPAN_REQUEST_PARENT]
    test r14,r14
    jz .span_start_parent_ok
    xor ebx,ebx
    mov r15,[r13+NEBO_OBS_STATE_SPANS]
.span_start_parent_scan:
    cmp rbx,[r13+NEBO_OBS_STATE_SPAN_COUNT]
    jae .span_start_state
    cmp [r15+NEBO_OBS_SPAN_ID],r14
    jne .span_start_parent_next
    cmp qword [r15+NEBO_OBS_SPAN_STATE],NEBO_OBS_SPAN_OPEN
    je .span_start_parent_ok
    jmp .span_start_state
.span_start_parent_next:
    add r15,NEBO_OBS_SPAN_SIZE
    inc rbx
    jmp .span_start_parent_scan
.span_start_parent_ok:
    mov rdi,r13
    call obs_authorize
    test eax,eax
    jnz .span_start_capability
    mov rdi,r13
    mov esi,NEBO_OBS_KIND_SPAN_START
    mov rdx,[r12+NEBO_OBS_SPAN_REQUEST_NAME]
    mov rcx,[r12+NEBO_OBS_SPAN_REQUEST_TIME]
    xor r8d,r8d
    call obs_record_basic
    mov [r12+NEBO_OBS_SPAN_REQUEST_ID],rax
    mov [r12+NEBO_OBS_SPAN_REQUEST_SEQUENCE],rax
    mov rbx,[r13+NEBO_OBS_STATE_SPAN_COUNT]
    imul rbx,NEBO_OBS_SPAN_SIZE
    add rbx,[r13+NEBO_OBS_STATE_SPANS]
    mov [rbx+NEBO_OBS_SPAN_ID],rax
    mov rdx,[r12+NEBO_OBS_SPAN_REQUEST_PARENT]
    mov [rbx+NEBO_OBS_SPAN_PARENT],rdx
    mov rdx,[r12+NEBO_OBS_SPAN_REQUEST_NAME]
    mov [rbx+NEBO_OBS_SPAN_NAME],rdx
    mov rdx,[r12+NEBO_OBS_SPAN_REQUEST_TIME]
    mov [rbx+NEBO_OBS_SPAN_START],rdx
    mov qword [rbx+NEBO_OBS_SPAN_END],0
    mov qword [rbx+NEBO_OBS_SPAN_STATE],NEBO_OBS_SPAN_OPEN
    inc qword [r13+NEBO_OBS_STATE_SPAN_COUNT]
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_RESULT],1
    xor eax,eax
    jmp .span_start_done
.span_start_drop:
    inc qword [r13+NEBO_OBS_STATE_DROPS]
.span_start_limit:
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .span_start_done
.span_start_privacy:
    mov eax,NEBO_OBS_STATUS_PRIVACY
    jmp .span_start_done
.span_start_state:
    mov eax,NEBO_OBS_STATUS_SPAN_STATE
    jmp .span_start_done
.span_start_capability:
    mov eax,NEBO_OBS_STATUS_CAPABILITY
    jmp .span_start_done
.span_start_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.span_start_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.span_start_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

; rdi=96-byte span request. A span closes exactly once.
NEBOC_ABI_FUNCTION nebo_observability_span_close
    test rdi,rdi
    jz .span_close_invalid
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov r12,rdi
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_SEQUENCE],0
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_RESULT],0
    mov r13,[r12+NEBO_OBS_SPAN_REQUEST_STATE]
    test r13,r13
    jz .span_close_invalid_saved
    mov rax,NEBO_OBS_MAGIC
    cmp [r13+NEBO_OBS_STATE_MAGIC],rax
    jne .span_close_invalid_saved
    mov r14,[r12+NEBO_OBS_SPAN_REQUEST_ID]
    test r14,r14
    jz .span_close_invalid_saved
    xor ebx,ebx
    mov r15,[r13+NEBO_OBS_STATE_SPANS]
.span_close_scan:
    cmp rbx,[r13+NEBO_OBS_STATE_SPAN_COUNT]
    jae .span_close_state
    cmp [r15+NEBO_OBS_SPAN_ID],r14
    je .span_close_found
    add r15,NEBO_OBS_SPAN_SIZE
    inc rbx
    jmp .span_close_scan
.span_close_found:
    cmp qword [r15+NEBO_OBS_SPAN_STATE],NEBO_OBS_SPAN_OPEN
    jne .span_close_state
    mov rax,[r12+NEBO_OBS_SPAN_REQUEST_TIME]
    cmp rax,[r15+NEBO_OBS_SPAN_START]
    jb .span_close_invalid_saved
    mov rax,[r13+NEBO_OBS_STATE_EVENT_COUNT]
    cmp rax,[r13+NEBO_OBS_STATE_EVENT_CAPACITY]
    jae .span_close_drop
    mov rdi,r13
    call obs_authorize
    test eax,eax
    jnz .span_close_capability
    mov rax,[r12+NEBO_OBS_SPAN_REQUEST_TIME]
    mov [r15+NEBO_OBS_SPAN_END],rax
    mov qword [r15+NEBO_OBS_SPAN_STATE],NEBO_OBS_SPAN_CLOSED
    mov rdi,r13
    mov esi,NEBO_OBS_KIND_SPAN_CLOSE
    mov rdx,[r15+NEBO_OBS_SPAN_NAME]
    mov rcx,rax
    mov r8,r14
    call obs_record_basic
    mov [r12+NEBO_OBS_SPAN_REQUEST_SEQUENCE],rax
    mov qword [r12+NEBO_OBS_SPAN_REQUEST_RESULT],1
    xor eax,eax
    jmp .span_close_done
.span_close_drop:
    inc qword [r13+NEBO_OBS_STATE_DROPS]
    mov eax,NEBO_OBS_STATUS_LIMIT
    jmp .span_close_done
.span_close_state:
    mov eax,NEBO_OBS_STATUS_SPAN_STATE
    jmp .span_close_done
.span_close_capability:
    mov eax,NEBO_OBS_STATUS_CAPABILITY
    jmp .span_close_done
.span_close_invalid_saved:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
.span_close_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.span_close_invalid:
    mov eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
