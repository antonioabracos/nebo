; IMPORTS-MODULOS-NAMESPACES-E-API-PUBLICA-F06 bounded observability lifecycle tests.
bits 64
default rel
%include "runtime/observability/observability.inc"

extern nebo_capability_authority_init
extern nebo_capability_grant
extern nebo_observability_init
extern nebo_observability_log
extern nebo_observability_counter_add
extern nebo_observability_histogram_observe
extern nebo_observability_span_start
extern nebo_observability_span_close

section .rodata
secret: times 32 db 0x62

section .bss
align 16
authority resb NEBO_AUTHORITY_SIZE
capability resb NEBO_CAPABILITY_SIZE
grant_request resb NEBO_CAPABILITY_GRANT_SIZE
init_request resb NEBO_OBS_INIT_SIZE
state resb NEBO_OBS_STATE_SIZE
events resb NEBO_OBS_EVENT_SIZE*4
spans resb NEBO_OBS_SPAN_SIZE*4
request resb NEBO_OBS_REQUEST_SIZE
metric resb NEBO_OBS_METRIC_SIZE
span_request resb NEBO_OBS_SPAN_REQUEST_SIZE
root_id resq 1
child_id resq 1

section .text
grant_console:
    lea rdi,[grant_request]
    mov ecx,NEBO_CAPABILITY_GRANT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[authority]
    mov [grant_request+NEBO_CAPABILITY_GRANT_AUTHORITY_OFFSET],rax
    lea rax,[capability]
    mov [grant_request+NEBO_CAPABILITY_GRANT_DESTINATION_OFFSET],rax
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_KIND_OFFSET],NEBO_CAPABILITY_CONSOLE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_EFFECTS_OFFSET],NEBO_EFFECT_CONSOLE_WRITE
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_CONSTRAINT_OFFSET],1
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_BUDGET_OFFSET],100
    mov qword [grant_request+NEBO_CAPABILITY_GRANT_SCOPE_OFFSET],6
    lea rdi,[grant_request]
    jmp nebo_capability_grant

prepare_init:
    lea rdi,[init_request]
    mov ecx,NEBO_OBS_INIT_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [init_request+NEBO_OBS_INIT_STATE],rax
    lea rax,[events]
    mov [init_request+NEBO_OBS_INIT_EVENTS],rax
    mov qword [init_request+NEBO_OBS_INIT_EVENT_CAPACITY],4
    lea rax,[spans]
    mov [init_request+NEBO_OBS_INIT_SPANS],rax
    mov qword [init_request+NEBO_OBS_INIT_SPAN_CAPACITY],4
    lea rax,[authority]
    mov [init_request+NEBO_OBS_INIT_AUTHORITY],rax
    lea rax,[capability]
    mov [init_request+NEBO_OBS_INIT_CAPABILITY],rax
    mov qword [init_request+NEBO_OBS_INIT_SCOPE],6
    ret

prepare_log:
    lea rdi,[request]
    mov ecx,NEBO_OBS_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [request+NEBO_OBS_REQUEST_STATE],rax
    mov qword [request+NEBO_OBS_REQUEST_NAME],0x1001
    mov qword [request+NEBO_OBS_REQUEST_TIME],10
    mov qword [request+NEBO_OBS_REQUEST_VALUE],77
    mov qword [request+NEBO_OBS_REQUEST_FIELDS],3
    mov qword [request+NEBO_OBS_REQUEST_LABELS],2
    ret

prepare_metric:
    lea rdi,[metric]
    mov ecx,NEBO_OBS_METRIC_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [metric+NEBO_OBS_METRIC_STATE],rax
    mov qword [metric+NEBO_OBS_METRIC_NAME],0x2001
    mov qword [metric+NEBO_OBS_METRIC_VALUE],2
    mov qword [metric+NEBO_OBS_METRIC_TIME],20
    mov qword [metric+NEBO_OBS_METRIC_LABELS],1
    ret

prepare_span:
    lea rdi,[span_request]
    mov ecx,NEBO_OBS_SPAN_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    lea rax,[state]
    mov [span_request+NEBO_OBS_SPAN_REQUEST_STATE],rax
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_NAME],0x3001
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_TIME],30
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_FIELDS],2
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_LABELS],1
    ret

reset_observability:
    sub rsp,8
    call grant_console
    call prepare_init
    lea rdi,[init_request]
    call nebo_observability_init
    add rsp,8
    ret

global _start
_start:
    ; 1-4. Initialize authenticated local sink and fixed caller storage.
    lea rdi,[authority]
    mov esi,0x2506
    lea rdx,[secret]
    call nebo_capability_authority_init
    test eax,eax
    jnz .fail1
    call grant_console
    test eax,eax
    jnz .fail2
    call prepare_init
    lea rdi,[init_request]
    call nebo_observability_init
    test eax,eax
    jnz .fail3
    mov rax,NEBO_OBS_MAGIC
    cmp [state+NEBO_OBS_STATE_MAGIC],rax
    jne .fail4

    ; 5-9. Structured public log preserves bounded metadata and sequence.
    call prepare_log
    lea rdi,[request]
    call nebo_observability_log
    test eax,eax
    jnz .fail5
    cmp qword [request+NEBO_OBS_REQUEST_SEQUENCE],1
    jne .fail6
    cmp qword [events+NEBO_OBS_EVENT_KIND],NEBO_OBS_KIND_LOG
    jne .fail7
    cmp qword [events+NEBO_OBS_EVENT_FIELDS],3
    jne .fail8
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],99
    jne .fail9

    ; 10-13. Sensitive metadata requires redaction before sink; denial is atomic.
    call prepare_log
    mov qword [request+NEBO_OBS_REQUEST_CLASS],nebo_privacy_PRIVACY_SECRET
    mov qword [request+NEBO_OBS_REQUEST_PURPOSE],42
    lea rdi,[request]
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_PRIVACY
    jne .fail10
    cmp qword [state+NEBO_OBS_STATE_EVENT_COUNT],1
    jne .fail11
    mov qword [request+NEBO_OBS_REQUEST_REDACTED],1
    lea rdi,[request]
    call nebo_observability_log
    test eax,eax
    jnz .fail12
    cmp qword [events+NEBO_OBS_EVENT_SIZE+NEBO_OBS_EVENT_FLAGS],1
    jne .fail13

    ; 14-15. Field and label limits reject before capability consumption.
    call prepare_log
    mov qword [request+NEBO_OBS_REQUEST_FIELDS],33
    lea rdi,[request]
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_LIMIT
    jne .fail14
    mov qword [request+NEBO_OBS_REQUEST_FIELDS],1
    mov qword [request+NEBO_OBS_REQUEST_LABELS],9
    lea rdi,[request]
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_LIMIT
    jne .fail15

    ; 16-20. Counters and histograms update exact bounded cells.
    call prepare_metric
    lea rdi,[metric]
    call nebo_observability_counter_add
    test eax,eax
    jnz .fail16
    cmp qword [metric+NEBO_OBS_METRIC_RESULT],2
    jne .fail17
    mov qword [metric+NEBO_OBS_METRIC_VALUE],3
    lea rdi,[metric]
    call nebo_observability_counter_add
    test eax,eax
    jnz .fail18
    cmp qword [metric+NEBO_OBS_METRIC_RESULT],5
    jne .fail19
    ; Four event slots are now full; resetting exercises histogram separately.
    call reset_observability
    call prepare_metric
    mov qword [metric+NEBO_OBS_METRIC_VALUE],3
    lea rdi,[metric]
    call nebo_observability_histogram_observe
    test eax,eax
    jnz .fail20
    lea rdi,[metric]
    call nebo_observability_histogram_observe
    test eax,eax
    jnz .fail21
    cmp qword [metric+NEBO_OBS_METRIC_RESULT],2
    jne .fail22
    mov qword [metric+NEBO_OBS_METRIC_VALUE],16
    lea rdi,[metric]
    call nebo_observability_histogram_observe
    cmp eax,NEBO_OBS_STATUS_LIMIT
    jne .fail23

    ; 24-30. Nested spans close once and reject invalid lifecycle transitions.
    call reset_observability
    call prepare_span
    lea rdi,[span_request]
    call nebo_observability_span_start
    test eax,eax
    jnz .fail24
    mov rax,[span_request+NEBO_OBS_SPAN_REQUEST_ID]
    mov [root_id],rax
    call prepare_span
    mov rax,[root_id]
    mov [span_request+NEBO_OBS_SPAN_REQUEST_PARENT],rax
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_TIME],31
    lea rdi,[span_request]
    call nebo_observability_span_start
    test eax,eax
    jnz .fail25
    mov rax,[span_request+NEBO_OBS_SPAN_REQUEST_ID]
    mov [child_id],rax
    call prepare_span
    mov rax,[child_id]
    mov [span_request+NEBO_OBS_SPAN_REQUEST_ID],rax
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_TIME],40
    lea rdi,[span_request]
    call nebo_observability_span_close
    test eax,eax
    jnz .fail26
    lea rdi,[span_request]
    call nebo_observability_span_close
    cmp eax,NEBO_OBS_STATUS_SPAN_STATE
    jne .fail27
    call prepare_span
    mov qword [span_request+NEBO_OBS_SPAN_REQUEST_PARENT],999
    lea rdi,[span_request]
    call nebo_observability_span_start
    cmp eax,NEBO_OBS_STATUS_SPAN_STATE
    jne .fail28
    cmp qword [state+NEBO_OBS_STATE_EVENT_COUNT],3
    jne .fail29
    cmp qword [capability+NEBO_CAPABILITY_BUDGET_OFFSET],97
    jne .fail30

    ; 31-35. Overflow, full sink and capability failures remain atomic.
    mov qword [state+NEBO_OBS_COUNTER_KEYS],0x4001
    mov qword [state+NEBO_OBS_COUNTER_VALUES],-1
    call prepare_metric
    mov qword [metric+NEBO_OBS_METRIC_NAME],0x4001
    mov qword [metric+NEBO_OBS_METRIC_VALUE],1
    lea rdi,[metric]
    call nebo_observability_counter_add
    cmp eax,NEBO_OBS_STATUS_OVERFLOW
    jne .fail31
    mov qword [state+NEBO_OBS_STATE_EVENT_COUNT],4
    call prepare_log
    lea rdi,[request]
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_LIMIT
    jne .fail32
    cmp qword [state+NEBO_OBS_STATE_DROPS],1
    jne .fail33
    mov qword [state+NEBO_OBS_STATE_EVENT_COUNT],3
    mov qword [state+NEBO_OBS_STATE_SCOPE],7
    lea rdi,[request]
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_CAPABILITY
    jne .fail34
    cmp qword [state+NEBO_OBS_STATE_EVENT_COUNT],3
    jne .fail35

    ; 36-38. Cardinality and initialization limits are typed and deterministic.
    mov qword [state+NEBO_OBS_STATE_SCOPE],6
    xor ecx,ecx
.fill_metrics:
    lea rax,[rcx+1]
    mov [state+NEBO_OBS_COUNTER_KEYS+rcx*8],rax
    inc rcx
    cmp rcx,NEBO_OBS_MAX_METRICS
    jb .fill_metrics
    call prepare_metric
    mov qword [metric+NEBO_OBS_METRIC_NAME],0x9999
    lea rdi,[metric]
    call nebo_observability_counter_add
    cmp eax,NEBO_OBS_STATUS_CARDINALITY
    jne .fail36
    call prepare_init
    mov qword [init_request+NEBO_OBS_INIT_EVENT_CAPACITY],4097
    lea rdi,[init_request]
    call nebo_observability_init
    cmp eax,NEBO_OBS_STATUS_LIMIT
    jne .fail37
    xor edi,edi
    call nebo_observability_log
    cmp eax,NEBO_OBS_STATUS_INVALID_ARGUMENT
    jne .fail38

    xor edi,edi
    mov eax,60
    syscall

%macro FAIL_LABEL 1
.fail%1:
    mov edi,%1
    mov eax,60
    syscall
%endmacro
%assign i 1
%rep 38
FAIL_LABEL i
%assign i i+1
%endrep

section .note.GNU-stack noalloc noexec nowrite progbits
