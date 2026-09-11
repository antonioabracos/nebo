; G111 deterministic internal adapters for log, progress and timeline services.
; State and receipts are caller-owned, bounded and pointer-free. The adapters
; reuse the G110 visual host, G100 observability model and G103 headless codec.
bits 64
default rel
%define NEBO_G111_INTERNAL_OBSERVABILITY_IMPLEMENTATION 1
%include "runtime/internal_observability_services.inc"
%include "runtime/internal_visual_console.inc"
%include "runtime/console/observability.inc"
%include "runtime/console/headless_protocol.inc"

global nebo_g111_log_group
global nebo_g111_log_tag
global nebo_g111_log_branch
global nebo_g111_log_trace
global nebo_g111_log_debug
global nebo_g111_log_info
global nebo_g111_log_warn
global nebo_g111_log_error
global nebo_g111_log_flush
global nebo_g111_progress_create
global nebo_g111_progress_update
global nebo_g111_progress_increment
global nebo_g111_progress_message
global nebo_g111_progress_finish
global nebo_g111_progress_fail
global nebo_g111_progress_cancel
global nebo_g111_progress_snapshot
global nebo_g111_timeline_from_events
global nebo_g111_timeline_from_stream
global nebo_g111_timeline_from_parallel
global nebo_g111_timeline_from_training
global nebo_g111_timeline_limit
global nebo_g111_timeline_window
global nebo_g111_timeline_export

section .text

g111_require_console:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G110_CONSOLE_MAGIC
    cmp [rdi+NEBO_G110_CONSOLE_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G110_CONSOLE_STATE],NEBO_G110_STATE_OPEN
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
    ret

g111_require_panel:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G110_PANEL_MAGIC
    cmp [rdi+NEBO_G110_PANEL_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G110_PANEL_STATE],NEBO_G110_PANEL_ACTIVE
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
    ret

g111_require_log:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G111_LOG_MAGIC
    cmp [rdi+NEBO_G111_LOG_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G111_LOG_STATE],NEBO_G111_STATE_ACTIVE
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
    ret

; log.group(console*, log*, group, max_records, max_bytes).
nebo_g111_log_group:
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    call g111_require_console
    test eax,eax
    jnz .done
    test r12,r12
    jz .invalid
    mov rax,NEBO_G111_LOG_MAGIC
    cmp [r12+NEBO_G111_LOG_MAGIC_OFS],rax
    jne .limits
    cmp qword [r12+NEBO_G111_LOG_STATE],NEBO_G111_STATE_ACTIVE
    je .busy
.limits:
    test r13,r13
    jz .range
    test r14,r14
    jz .limit
    cmp r14,NEBO_G111_MAX_LOG_RECORDS
    ja .limit
    test r15,r15
    jz .limit
    cmp r15,NEBO_G111_MAX_LOG_BYTES
    ja .limit
    mov rdi,r12
    mov ecx,NEBO_G111_LOG_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov rax,NEBO_G111_LOG_MAGIC
    mov [r12+NEBO_G111_LOG_MAGIC_OFS],rax
    mov qword [r12+NEBO_G111_LOG_STATE],NEBO_G111_STATE_ACTIVE
    mov [r12+NEBO_G111_LOG_GROUP],r13
    mov [r12+NEBO_G111_LOG_MAX_RECORDS_OFS],r14
    mov [r12+NEBO_G111_LOG_MAX_BYTES_OFS],r15
    mov qword [r12+NEBO_G111_LOG_GENERATION],1
    mov rax,r13
    rol rax,7
    xor rax,r14
    rol rax,7
    xor rax,r15
    mov [r12+NEBO_G111_LOG_DIGEST],rax
    xor eax,eax
    jmp .done
.busy:
    mov eax,-NEBO_G111_ERROR_BUSY
    jmp .done
.limit:
    mov eax,-NEBO_G111_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_g111_log_tag:
    push rbx
    mov rbx,rdi
    test rsi,rsi
    jz .range
    call g111_require_log
    test eax,eax
    jnz .done
    mov [rbx+NEBO_G111_LOG_TAG],rsi
    rol qword [rbx+NEBO_G111_LOG_DIGEST],7
    xor [rbx+NEBO_G111_LOG_DIGEST],rsi
    inc qword [rbx+NEBO_G111_LOG_GENERATION]
    xor eax,eax
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
.done:
    pop rbx
    ret

nebo_g111_log_branch:
    push rbx
    mov rbx,rdi
    test rsi,rsi
    jz .range
    call g111_require_log
    test eax,eax
    jnz .done
    mov [rbx+NEBO_G111_LOG_BRANCH],rsi
    rol qword [rbx+NEBO_G111_LOG_DIGEST],7
    xor [rbx+NEBO_G111_LOG_DIGEST],rsi
    inc qword [rbx+NEBO_G111_LOG_GENERATION]
    xor eax,eax
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
.done:
    pop rbx
    ret

; Shared log adapter. RDI=console, RSI=log, RDX=message, RCX=bytes,
; R8=receipt, R9=level.
g111_log_emit:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    mov rbp,r9
    test r15,r15
    jz .invalid
    test r13,r13
    jz .range
    test r14,r14
    jz .range
    cmp r14,256
    ja .limit
    mov rdi,rbx
    call g111_require_console
    test eax,eax
    jnz .done
    mov rdi,r12
    call g111_require_log
    test eax,eax
    jnz .done
    cmp rbp,NEBO_G111_LOG_TRACE
    jb .range
    cmp rbp,NEBO_G111_LOG_LEVEL_MAX
    ja .range
    cmp qword [r12+NEBO_G111_LOG_TAG],0
    je .state
    cmp qword [r12+NEBO_G111_LOG_BRANCH],0
    je .state
    mov rax,[r12+NEBO_G111_LOG_RECORDS]
    cmp rax,[r12+NEBO_G111_LOG_MAX_RECORDS_OFS]
    jae .limit
    mov rax,[r12+NEBO_G111_LOG_BYTES]
    add rax,r14
    jc .limit
    cmp rax,[r12+NEBO_G111_LOG_MAX_BYTES_OFS]
    ja .limit
    mov rdi,rbx
    mov rsi,r13
    lea rdx,[rsp]
    call nebo_g110_console_show
    test eax,eax
    jnz .dependency
    mov rax,[r12+NEBO_G111_LOG_DIGEST]
    rol rax,11
    xor rax,r13
    rol rax,7
    xor rax,r14
    rol rax,5
    xor rax,[r12+NEBO_G111_LOG_GROUP]
    rol rax,3
    xor rax,[r12+NEBO_G111_LOG_TAG]
    rol rax,3
    xor rax,[r12+NEBO_G111_LOG_BRANCH]
    mov rcx,rbp
    shl rcx,56
    xor rax,rcx
    mov [r12+NEBO_G111_LOG_DIGEST],rax
    inc qword [r12+NEBO_G111_LOG_RECORDS]
    add [r12+NEBO_G111_LOG_BYTES],r14
    inc qword [r12+NEBO_G111_LOG_GENERATION]
    lea rdx,[r12+NEBO_G111_LOG_TRACE_COUNT]
    mov rcx,rbp
    dec rcx
    inc qword [rdx+rcx*8]
    mov rcx,[r12+NEBO_G111_LOG_RECORDS]
    mov [r15+NEBO_G111_LOG_RECEIPT_SEQUENCE],rcx
    mov [r15+NEBO_G111_LOG_RECEIPT_LEVEL],rbp
    mov rcx,[r12+NEBO_G111_LOG_GROUP]
    mov [r15+NEBO_G111_LOG_RECEIPT_GROUP],rcx
    mov rcx,[r12+NEBO_G111_LOG_TAG]
    mov [r15+NEBO_G111_LOG_RECEIPT_TAG],rcx
    mov rcx,[r12+NEBO_G111_LOG_BRANCH]
    mov [r15+NEBO_G111_LOG_RECEIPT_BRANCH],rcx
    mov [r15+NEBO_G111_LOG_RECEIPT_MESSAGE],r13
    mov [r15+NEBO_G111_LOG_RECEIPT_BYTES],r14
    mov [r15+NEBO_G111_LOG_RECEIPT_DIGEST],rax
    xor eax,eax
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    jmp .done
.limit:
    mov eax,-NEBO_G111_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

nebo_g111_log_trace:
    mov r9d,NEBO_G111_LOG_TRACE
    jmp g111_log_emit
nebo_g111_log_debug:
    mov r9d,NEBO_G111_LOG_DEBUG
    jmp g111_log_emit
nebo_g111_log_info:
    mov r9d,NEBO_G111_LOG_INFO
    jmp g111_log_emit
nebo_g111_log_warn:
    mov r9d,NEBO_G111_LOG_WARN
    jmp g111_log_emit
nebo_g111_log_error:
    mov r9d,NEBO_G111_LOG_ERROR
    jmp g111_log_emit

; log.flush(console*, log*, receipt*) emits one bounded fallback marker.
nebo_g111_log_flush:
    push rbx
    push r12
    push r13
    sub rsp,16
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    test r13,r13
    jz .invalid
    mov rdi,rbx
    call g111_require_console
    test eax,eax
    jnz .done
    mov rdi,r12
    call g111_require_log
    test eax,eax
    jnz .done
    cmp qword [r12+NEBO_G111_LOG_RECORDS],0
    je .state
    mov rdi,rbx
    mov rsi,[r12+NEBO_G111_LOG_DIGEST]
    lea rdx,[rsp]
    call nebo_g110_console_fallback_text
    test eax,eax
    jnz .dependency
    inc qword [r12+NEBO_G111_LOG_FLUSHES]
    inc qword [r12+NEBO_G111_LOG_GENERATION]
    mov rax,[r12+NEBO_G111_LOG_RECORDS]
    mov [r13+NEBO_G111_FLUSH_RECORDS],rax
    mov rax,[r12+NEBO_G111_LOG_BYTES]
    mov [r13+NEBO_G111_FLUSH_BYTES],rax
    mov rax,[r12+NEBO_G111_LOG_DIGEST]
    mov [r13+NEBO_G111_FLUSH_DIGEST],rax
    mov rax,[r12+NEBO_G111_LOG_FLUSHES]
    mov [r13+NEBO_G111_FLUSH_COUNT],rax
    mov rax,[r12+NEBO_G111_LOG_GENERATION]
    mov [r13+NEBO_G111_FLUSH_GENERATION],rax
    mov qword [r13+NEBO_G111_FLUSH_MATURITY],NEBO_G111_MATURITY_INTERNAL_OBSERVABILITY_SERVICES_GREEN
    xor eax,eax
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,16
    pop r13
    pop r12
    pop rbx
    ret

g111_require_progress:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G111_PROGRESS_MAGIC
    cmp [rdi+NEBO_G111_PROGRESS_MAGIC_OFS],rax
    jne .invalid
    mov rax,[rdi+NEBO_G111_PROGRESS_STATE]
    cmp rax,NEBO_G111_PROGRESS_ACTIVE
    jb .state
    cmp rax,NEBO_G111_PROGRESS_CANCELLED
    ja .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
    ret

g111_require_progress_active:
    call g111_require_progress
    test eax,eax
    jnz .done
    cmp qword [rdi+NEBO_G111_PROGRESS_STATE],NEBO_G111_PROGRESS_ACTIVE
    jne .terminal
    xor eax,eax
    ret
.terminal:
    mov eax,-NEBO_G111_ERROR_TERMINAL
.done:
    ret

; progress.create(console*, panel*, progress*, id, total, label).
nebo_g111_progress_create:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    mov rbp,r9
    mov rdi,rbx
    call g111_require_console
    test eax,eax
    jnz .done
    mov rdi,r12
    call g111_require_panel
    test eax,eax
    jnz .done
    test r13,r13
    jz .invalid
    mov rax,NEBO_G111_PROGRESS_MAGIC
    cmp [r13+NEBO_G111_PROGRESS_MAGIC_OFS],rax
    jne .values
    mov rax,[r13+NEBO_G111_PROGRESS_STATE]
    cmp rax,NEBO_G111_PROGRESS_ACTIVE
    jb .values
    cmp rax,NEBO_G111_PROGRESS_CANCELLED
    jbe .busy
.values:
    test r14,r14
    jz .range
    test r15,r15
    jz .range
    test rbp,rbp
    jz .range
    mov rdi,r13
    mov ecx,NEBO_G111_PROGRESS_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov rax,NEBO_G111_PROGRESS_MAGIC
    mov [r13+NEBO_G111_PROGRESS_MAGIC_OFS],rax
    mov qword [r13+NEBO_G111_PROGRESS_STATE],NEBO_G111_PROGRESS_ACTIVE
    mov [r13+NEBO_G111_PROGRESS_ID],r14
    mov [r13+NEBO_G111_PROGRESS_TOTAL],r15
    mov [r13+NEBO_G111_PROGRESS_LABEL],rbp
    mov rax,[r12+NEBO_G110_PANEL_ID]
    mov [r13+NEBO_G111_PROGRESS_PANEL_ID],rax
    mov qword [r13+NEBO_G111_PROGRESS_GENERATION],1
    mov rax,r14
    rol rax,11
    xor rax,r15
    rol rax,11
    xor rax,rbp
    mov [r13+NEBO_G111_PROGRESS_DIGEST],rax
    xor eax,eax
    jmp .done
.busy:
    mov eax,-NEBO_G111_ERROR_BUSY
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; Publish a pointer-free progress snapshot. RDI=progress, RSI=receipt.
g111_progress_publish:
    mov rax,[rdi+NEBO_G111_PROGRESS_ID]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_ID],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_STATE]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_STATE],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_TOTAL]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_TOTAL],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_CURRENT]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_CURRENT],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_LABEL]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_LABEL],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_MESSAGE]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_MESSAGE],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_DIGEST]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_DIGEST],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_GENERATION]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_GENERATION],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_UPDATES]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_UPDATES],rax
    mov rax,[rdi+NEBO_G111_PROGRESS_TERMINALS]
    mov [rsi+NEBO_G111_PROGRESS_SNAPSHOT_TERMINALS],rax
    mov qword [rsi+NEBO_G111_PROGRESS_SNAPSHOT_MATURITY],NEBO_G111_MATURITY_INTERNAL_OBSERVABILITY_SERVICES_GREEN
    xor eax,eax
    ret

nebo_g111_progress_snapshot:
    push rbx
    mov rbx,rsi
    test rbx,rbx
    jz .invalid
    call g111_require_progress
    test eax,eax
    jnz .done
    mov rsi,rbx
    call g111_progress_publish
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    pop rbx
    ret

; Shared active mutation. RDI=panel, RSI=progress, RDX=value, RCX=receipt,
; R8=operation (1 update, 2 increment, 3 message).
g111_progress_mutate:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    test r14,r14
    jz .invalid
    mov rdi,rbx
    call g111_require_panel
    test eax,eax
    jnz .done
    mov rdi,r12
    call g111_require_progress_active
    test eax,eax
    jnz .done
    mov rax,[rbx+NEBO_G110_PANEL_ID]
    cmp [r12+NEBO_G111_PROGRESS_PANEL_ID],rax
    jne .state
    cmp r15,1
    je .update
    cmp r15,2
    je .increment
    cmp r15,3
    jne .invalid
    test r13,r13
    jz .range
    mov rbp,r13
    jmp .panel_append
.update:
    cmp r13,[r12+NEBO_G111_PROGRESS_CURRENT]
    jbe .order
    cmp r13,[r12+NEBO_G111_PROGRESS_TOTAL]
    jae .range
    mov rbp,r13
    jmp .panel_replace
.increment:
    test r13,r13
    jz .range
    mov rbp,[r12+NEBO_G111_PROGRESS_CURRENT]
    add rbp,r13
    jc .range
    cmp rbp,[r12+NEBO_G111_PROGRESS_TOTAL]
    jae .range
.panel_append:
    mov rdi,rbx
    mov rsi,rbp
    mov edx,8
    lea rcx,[rsp]
    call nebo_g110_panel_append
    jmp .panel_result
.panel_replace:
    mov rdi,rbx
    mov rsi,rbp
    mov edx,8
    lea rcx,[rsp]
    call nebo_g110_panel_replace
.panel_result:
    test eax,eax
    jnz .dependency
    cmp r15,3
    je .store_message
    mov [r12+NEBO_G111_PROGRESS_CURRENT],rbp
    jmp .digest
.store_message:
    mov [r12+NEBO_G111_PROGRESS_MESSAGE],rbp
.digest:
    mov rax,[r12+NEBO_G111_PROGRESS_DIGEST]
    rol rax,13
    xor rax,rbp
    mov rcx,r15
    shl rcx,56
    xor rax,rcx
    mov [r12+NEBO_G111_PROGRESS_DIGEST],rax
    inc qword [r12+NEBO_G111_PROGRESS_GENERATION]
    inc qword [r12+NEBO_G111_PROGRESS_UPDATES]
    mov rdi,r12
    mov rsi,r14
    call g111_progress_publish
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    jmp .done
.order:
    mov eax,-NEBO_G111_ERROR_ORDER
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

nebo_g111_progress_update:
    mov r8d,1
    jmp g111_progress_mutate
nebo_g111_progress_increment:
    mov r8d,2
    jmp g111_progress_mutate
nebo_g111_progress_message:
    mov r8d,3
    jmp g111_progress_mutate

; Shared terminal transition. R8=state, R9=operation, RDX=reason or zero.
g111_progress_terminal:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,16
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    mov r14,rcx
    mov r15,r8
    mov rbp,r9
    test r14,r14
    jz .invalid
    mov rdi,rbx
    call g111_require_panel
    test eax,eax
    jnz .done
    mov rdi,r12
    call g111_require_progress_active
    test eax,eax
    jnz .done
    mov rax,[rbx+NEBO_G110_PANEL_ID]
    cmp [r12+NEBO_G111_PROGRESS_PANEL_ID],rax
    jne .state
    cmp r15,NEBO_G111_PROGRESS_FINISHED
    je .finish_value
    test r13,r13
    jz .range
    mov rdi,rbx
    mov rsi,r13
    mov edx,8
    lea rcx,[rsp]
    call nebo_g110_panel_append
    jmp .panel_result
.finish_value:
    mov r13,[r12+NEBO_G111_PROGRESS_TOTAL]
    mov rdi,rbx
    mov rsi,r13
    mov edx,8
    lea rcx,[rsp]
    call nebo_g110_panel_replace
.panel_result:
    test eax,eax
    jnz .dependency
    mov [r12+NEBO_G111_PROGRESS_STATE],r15
    cmp r15,NEBO_G111_PROGRESS_FINISHED
    jne .reason
    mov [r12+NEBO_G111_PROGRESS_CURRENT],r13
    jmp .digest
.reason:
    mov [r12+NEBO_G111_PROGRESS_MESSAGE],r13
.digest:
    mov rax,[r12+NEBO_G111_PROGRESS_DIGEST]
    rol rax,13
    xor rax,r13
    mov rcx,rbp
    shl rcx,56
    xor rax,rcx
    mov [r12+NEBO_G111_PROGRESS_DIGEST],rax
    inc qword [r12+NEBO_G111_PROGRESS_GENERATION]
    inc qword [r12+NEBO_G111_PROGRESS_TERMINALS]
    mov rdi,r12
    mov rsi,r14
    call g111_progress_publish
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,16
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

nebo_g111_progress_finish:
    mov rcx,rdx
    xor edx,edx
    mov r8d,NEBO_G111_PROGRESS_FINISHED
    mov r9d,4
    jmp g111_progress_terminal
nebo_g111_progress_fail:
    mov r8d,NEBO_G111_PROGRESS_FAILED
    mov r9d,5
    jmp g111_progress_terminal
nebo_g111_progress_cancel:
    mov r8d,NEBO_G111_PROGRESS_CANCELLED
    mov r9d,6
    jmp g111_progress_terminal

g111_require_timeline:
    test rdi,rdi
    jz .invalid
    mov rax,NEBO_G111_TIMELINE_MAGIC
    cmp [rdi+NEBO_G111_TIMELINE_MAGIC_OFS],rax
    jne .invalid
    cmp qword [rdi+NEBO_G111_TIMELINE_STATE],NEBO_G111_STATE_ACTIVE
    jne .state
    xor eax,eax
    ret
.state:
    mov eax,-NEBO_G111_ERROR_STATE
    ret
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
    ret

; Shared timeline adapter. RDI=timeline, RSI=canonical G100 request,
; EDX=source class. G100 remains the ordering/backpressure/lifecycle owner.
g111_timeline_create:
    push rbx
    push r12
    push r13
    push r14
    sub rsp,NEBO_G100_RESULT_SIZE
    mov rbx,rdi
    mov r12,rsi
    mov r13d,edx
    test rbx,rbx
    jz .invalid
    test r12,r12
    jz .invalid
    mov rax,NEBO_G111_TIMELINE_MAGIC
    cmp [rbx+NEBO_G111_TIMELINE_MAGIC_OFS],rax
    jne .source
    cmp qword [rbx+NEBO_G111_TIMELINE_STATE],NEBO_G111_STATE_ACTIVE
    je .busy
.source:
    cmp r13d,NEBO_G111_TIMELINE_EVENTS
    jb .range
    cmp r13d,NEBO_G111_TIMELINE_TRAINING
    ja .range
    mov rdi,r12
    mov rsi,rsp
    call nebo_g100_observability_model
    test eax,eax
    jnz .dependency
    cmp r13d,NEBO_G111_TIMELINE_STREAM
    jne .parallel
    cmp qword [rsp+NEBO_G100_RESULT_STREAM_COUNT_OFFSET],0
    je .dependency
    jmp .publish
.parallel:
    cmp r13d,NEBO_G111_TIMELINE_PARALLEL
    jne .training
    cmp qword [rsp+NEBO_G100_RESULT_PARALLEL_COUNT_OFFSET],0
    je .dependency
    jmp .publish
.training:
    cmp r13d,NEBO_G111_TIMELINE_TRAINING
    jne .publish
    cmp qword [rsp+NEBO_G100_RESULT_PROGRESS_COUNT_OFFSET],0
    je .dependency
.publish:
    mov rdi,rbx
    mov ecx,NEBO_G111_TIMELINE_QWORDS
    xor eax,eax
    cld
    rep stosq
    mov rax,NEBO_G111_TIMELINE_MAGIC
    mov [rbx+NEBO_G111_TIMELINE_MAGIC_OFS],rax
    mov qword [rbx+NEBO_G111_TIMELINE_STATE],NEBO_G111_STATE_ACTIVE
    mov [rbx+NEBO_G111_TIMELINE_SOURCE],r13
    mov r14,[rsp+NEBO_G100_RESULT_EVENT_COUNT_OFFSET]
    mov [rbx+NEBO_G111_TIMELINE_EVENT_COUNT],r14
    mov [rbx+NEBO_G111_TIMELINE_LIMIT],r14
    mov rax,[rsp+NEBO_G100_RESULT_WINDOW_START_OFFSET]
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_START],rax
    mov rax,[rsp+NEBO_G100_RESULT_WINDOW_COUNT_OFFSET]
    test rax,rax
    cmovz rax,r14
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_COUNT],rax
    mov rax,[rsp+NEBO_G100_RESULT_SOURCE_GENERATION_OFFSET]
    mov [rbx+NEBO_G111_TIMELINE_SOURCE_GENERATION],rax
    rol rax,7
    xor rax,r14
    rol rax,9
    xor rax,r13
    mov [rbx+NEBO_G111_TIMELINE_DIGEST],rax
    mov qword [rbx+NEBO_G111_TIMELINE_GENERATION],1
    mov qword [rbx+NEBO_G111_TIMELINE_DEPENDENCY_STATUS],0
    xor eax,eax
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.busy:
    mov eax,-NEBO_G111_ERROR_BUSY
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,NEBO_G100_RESULT_SIZE
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

nebo_g111_timeline_from_events:
    mov edx,NEBO_G111_TIMELINE_EVENTS
    jmp g111_timeline_create
nebo_g111_timeline_from_stream:
    mov edx,NEBO_G111_TIMELINE_STREAM
    jmp g111_timeline_create
nebo_g111_timeline_from_parallel:
    mov edx,NEBO_G111_TIMELINE_PARALLEL
    jmp g111_timeline_create
nebo_g111_timeline_from_training:
    mov edx,NEBO_G111_TIMELINE_TRAINING
    jmp g111_timeline_create

nebo_g111_timeline_limit:
    push rbx
    mov rbx,rdi
    test rsi,rsi
    jz .range
    call g111_require_timeline
    test eax,eax
    jnz .done
    cmp rsi,[rbx+NEBO_G111_TIMELINE_EVENT_COUNT]
    ja .limit
    mov [rbx+NEBO_G111_TIMELINE_LIMIT],rsi
    mov rax,[rbx+NEBO_G111_TIMELINE_WINDOW_COUNT]
    cmp rax,rsi
    jbe .digest
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_COUNT],rsi
    mov rax,[rbx+NEBO_G111_TIMELINE_EVENT_COUNT]
    sub rax,rsi
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_START],rax
.digest:
    rol qword [rbx+NEBO_G111_TIMELINE_DIGEST],5
    xor [rbx+NEBO_G111_TIMELINE_DIGEST],rsi
    inc qword [rbx+NEBO_G111_TIMELINE_GENERATION]
    xor eax,eax
    jmp .done
.limit:
    mov eax,-NEBO_G111_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
.done:
    pop rbx
    ret

; timeline.window(timeline*, start, count).
nebo_g111_timeline_window:
    push rbx
    mov rbx,rdi
    test rdx,rdx
    jz .range
    call g111_require_timeline
    test eax,eax
    jnz .done
    cmp rdx,[rbx+NEBO_G111_TIMELINE_LIMIT]
    ja .limit
    mov rax,rsi
    add rax,rdx
    jc .range
    cmp rax,[rbx+NEBO_G111_TIMELINE_EVENT_COUNT]
    ja .range
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_START],rsi
    mov [rbx+NEBO_G111_TIMELINE_WINDOW_COUNT],rdx
    rol qword [rbx+NEBO_G111_TIMELINE_DIGEST],7
    xor [rbx+NEBO_G111_TIMELINE_DIGEST],rsi
    mov rax,rdx
    shl rax,32
    xor [rbx+NEBO_G111_TIMELINE_DIGEST],rax
    inc qword [rbx+NEBO_G111_TIMELINE_GENERATION]
    xor eax,eax
    jmp .done
.limit:
    mov eax,-NEBO_G111_ERROR_LIMIT
    jmp .done
.range:
    mov eax,-NEBO_G111_ERROR_RANGE
.done:
    pop rbx
    ret

; timeline.export(timeline*, authorized_format, receipt*). No file is written;
; G103 authenticates the deterministic headless event before publication.
nebo_g111_timeline_export:
    push rbx
    push r12
    push r13
    sub rsp,64
    mov rbx,rdi
    mov r12,rsi
    mov r13,rdx
    test r13,r13
    jz .invalid
    cmp r12,NEBO_G111_FORMAT_JSONL
    jb .format
    cmp r12,NEBO_G111_FORMAT_MAX
    ja .format
    call g111_require_timeline
    test eax,eax
    jnz .done
    mov rdi,rsp
    mov ecx,NEBO_G103_EVENT_SIZE/8
    xor eax,eax
    cld
    rep stosq
    mov qword [rsp+NEBO_G103_EVENT_VERSION_OFFSET],NEBO_G103_SCHEMA_VERSION
    mov rax,[rbx+NEBO_G111_TIMELINE_GENERATION]
    mov [rsp+NEBO_G103_EVENT_SEQUENCE_OFFSET],rax
    mov qword [rsp+NEBO_G103_EVENT_KIND_OFFSET],NEBO_G103_EVENT_EMIT
    mov rax,[rbx+NEBO_G111_TIMELINE_SOURCE]
    mov [rsp+NEBO_G103_EVENT_REGION_OFFSET],rax
    mov rax,[rbx+NEBO_G111_TIMELINE_DIGEST]
    mov [rsp+NEBO_G103_EVENT_VALUE_OFFSET],rax
    mov qword [rsp+NEBO_G103_EVENT_FLAGS_OFFSET],0
    mov qword [rsp+NEBO_G103_EVENT_CAPABILITIES_OFFSET],NEBO_G103_CAP_EMIT
    mov rdi,rsp
    call nebo_g103_roundtrip_event
    test eax,eax
    jnz .dependency
    mov rax,[rbx+NEBO_G111_TIMELINE_DIGEST]
    rol rax,17
    xor rax,r12
    rol rax,7
    xor rax,[rbx+NEBO_G111_TIMELINE_WINDOW_START]
    rol rax,7
    xor rax,[rbx+NEBO_G111_TIMELINE_WINDOW_COUNT]
    rol rax,7
    xor rax,[rbx+NEBO_G111_TIMELINE_SOURCE_GENERATION]
    mov [rbx+NEBO_G111_TIMELINE_DIGEST],rax
    mov [rbx+NEBO_G111_TIMELINE_EXPORT_FORMAT],r12
    inc qword [rbx+NEBO_G111_TIMELINE_GENERATION]
    mov rcx,[rbx+NEBO_G111_TIMELINE_SOURCE]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_SOURCE],rcx
    mov rcx,[rbx+NEBO_G111_TIMELINE_EVENT_COUNT]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_TOTAL],rcx
    mov rcx,[rbx+NEBO_G111_TIMELINE_LIMIT]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_LIMIT],rcx
    mov rcx,[rbx+NEBO_G111_TIMELINE_WINDOW_START]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_WINDOW_START],rcx
    mov rcx,[rbx+NEBO_G111_TIMELINE_WINDOW_COUNT]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_WINDOW_COUNT],rcx
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_FORMAT],r12
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_DIGEST],rax
    mov rcx,[rbx+NEBO_G111_TIMELINE_GENERATION]
    mov [r13+NEBO_G111_TIMELINE_RECEIPT_GENERATION],rcx
    mov qword [r13+NEBO_G111_TIMELINE_RECEIPT_MATURITY],NEBO_G111_MATURITY_INTERNAL_OBSERVABILITY_SERVICES_GREEN
    xor eax,eax
    jmp .done
.dependency:
    mov eax,-NEBO_G111_ERROR_DEPENDENCY
    jmp .done
.format:
    mov eax,-NEBO_G111_ERROR_FORMAT
    jmp .done
.invalid:
    mov eax,-NEBO_G111_ERROR_INVALID
.done:
    add rsp,64
    pop r13
    pop r12
    pop rbx
    ret

; Baseline generated-front validators remain linkable but are not proof for
; G111. They retain the historical scalar contract only.
%macro G111_LEGACY_VALIDATOR 1
global %1
%1:
    test rdx,rdx
    jz %%invalid
    cmp rdi,1
    jl %%invalid
    cmp rdi,4096
    jg %%bounds
    cmp rsi,0
    jl %%invalid
    cmp rsi,64
    jg %%bounds
    lea rax,[rdi+rsi]
    mov [rdx],rax
    xor eax,eax
    ret
%%invalid:
    mov eax,NEBO_INTERNAL_ERR_INVALID
    ret
%%bounds:
    mov eax,NEBO_INTERNAL_ERR_BOUNDS
    ret
%endmacro

G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_log_levels_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_group_tag_branch_flush_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_create_update_increment_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_message_finish_fail_cancel_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_progress_snapshot_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_timeline_fromevents_fromstream_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_fromparallel_fromtraining_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_limit_window_export_contract_validate
G111_LEGACY_VALIDATOR nebo_servicos_internos_visual_log_visual_progress_e_visual_timeline_closeout_contract_validate

%undef G111_LEGACY_VALIDATOR

section .note.GNU-stack noalloc noexec nowrite progbits
