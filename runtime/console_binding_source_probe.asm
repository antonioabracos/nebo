; Source-to-effect bridge for G112 internal chart/table services.
bits 64
default rel
%define NEBO_G112_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/console_binding_source_probe.inc"
%include "runtime/console/chart_model.inc"

section .note.GNU-stack noalloc noexec nowrite progbits

section .bss align=16
g112_clear_begin:
g112_chart_spec: resb NEBO_G112_CHART_SPEC_SIZE
g112_table_spec: resb NEBO_G112_TABLE_SPEC_SIZE
g112_chart_receipts: resb 9*NEBO_G112_CHART_RECEIPT_SIZE
g112_visual_receipt: resb NEBO_G112_CHART_RECEIPT_SIZE
g112_table_receipts: resb 9*NEBO_G112_TABLE_RECEIPT_SIZE
g112_x_values: resq 16
g112_y_values: resq 16
g112_sample_values: resq 32
g112_last_mode: resq 1
g112_last_seed: resq 1
g112_clear_end:

section .text
global nebo_g112_source_probe
global nebo_g112_surface_probe
global nebo_g112_negative_probe

g112_probe_clear:
    lea rdi,[rel g112_clear_begin]
    mov ecx,(g112_clear_end-g112_clear_begin)/8
    xor eax,eax
    cld
    rep stosq
    ret

; EBP is the source seed. The same non-uniform data reaches every chart
; adapter and the G101-backed table sample operation.
g112_prepare:
    lea r8,[rel g112_x_values]
    lea r9,[rel g112_y_values]
    lea r10,[rel g112_sample_values]
    xor ecx,ecx
.values:
    mov eax,ecx
    add eax,ebp
    cvtsi2sd xmm0,eax
    movsd [r8+rcx*8],xmm0
    mov eax,ecx
    imul eax,eax
    lea eax,[rax+rbp*2+7]
    cvtsi2sd xmm0,eax
    movsd [r9+rcx*8],xmm0
    mov rdx,rcx
    shl rdx,4
    mov eax,ecx
    mov [r10+rdx],rax
    imul eax,eax
    lea eax,[rax+rbp*4+11]
    mov [r10+rdx+8],rax
    inc ecx
    cmp ecx,16
    jb .values

    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_VERSION],NEBO_G112_SPEC_VERSION
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_TARGET],NEBO_G095_TARGET_HEADLESS
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_POINTS],16
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_SERIES],2
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_BINS],4
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_ROWS],4
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_COLUMNS],4
    lea rax,[rel g112_x_values]
    mov [rel g112_chart_spec+NEBO_G112_CHART_SPEC_X_VALUES],rax
    lea rax,[rel g112_y_values]
    mov [rel g112_chart_spec+NEBO_G112_CHART_SPEC_Y_VALUES],rax
    mov [rel g112_chart_spec+NEBO_G112_CHART_SPEC_GENERATION],rbp

    mov qword [rel g112_table_spec+NEBO_G112_TABLE_SPEC_VERSION],NEBO_G112_SPEC_VERSION
    lea rax,[rbp+100]
    mov [rel g112_table_spec+NEBO_G112_TABLE_SPEC_SOURCE],rax
    lea rax,[rbp+200]
    mov [rel g112_table_spec+NEBO_G112_TABLE_SPEC_SCHEMA],rax
    mov qword [rel g112_table_spec+NEBO_G112_TABLE_SPEC_ROWS],16
    mov qword [rel g112_table_spec+NEBO_G112_TABLE_SPEC_COLUMNS],4
    mov [rel g112_table_spec+NEBO_G112_TABLE_SPEC_GENERATION],rbp
    mov eax,ebp
    imul rax,rax,17
    add rax,41
    mov [rel g112_table_spec+NEBO_G112_TABLE_SPEC_DATA_DIGEST],rax
    lea rax,[rel g112_sample_values]
    mov [rel g112_table_spec+NEBO_G112_TABLE_SPEC_SAMPLE_VALUES],rax
    ret

; EDI=subgroup 1..9, ESI=source seed 3201..3209.
nebo_g112_source_probe:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    sub rsp,8
    mov ebx,edi
    mov ebp,esi
    cmp ebx,1
    jb .invalid
    cmp ebx,NEBO_G112_SOURCE_MAX_MODE
    ja .invalid
    cmp ebp,NEBO_G112_SOURCE_MIN_SEED
    jb .invalid
    cmp ebp,NEBO_G112_SOURCE_MAX_SEED
    ja .invalid
    mov eax,ebp
    sub eax,3200
    cmp eax,ebx
    jne .invalid
    call g112_probe_clear
    mov [rel g112_last_mode],rbx
    mov [rel g112_last_seed],rbp
    call g112_prepare

    lea r12,[rel g112_chart_receipts]
    lea r13,[rel g112_chart_spec]
%macro G112_CHART_CALL 2
    mov rdi,r13
    lea rsi,[r12+(%2-1)*NEBO_G112_CHART_RECEIPT_SIZE]
    call %1
    test eax,eax
    jnz .effect
    cmp qword [r12+(%2-1)*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_OPERATION],%2
    jne .effect
    cmp qword [r12+(%2-1)*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_MATURITY],NEBO_G112_MATURITY_INTERNAL_CHART_TABLE_SERVICES_GREEN
    jne .effect
%endmacro
    G112_CHART_CALL nebo_g112_chart_line,NEBO_G112_CHART_LINE
    G112_CHART_CALL nebo_g112_chart_bar,NEBO_G112_CHART_BAR
    G112_CHART_CALL nebo_g112_chart_scatter,NEBO_G112_CHART_SCATTER
    G112_CHART_CALL nebo_g112_chart_histogram,NEBO_G112_CHART_HISTOGRAM
    G112_CHART_CALL nebo_g112_chart_heatmap,NEBO_G112_CHART_HEATMAP
    G112_CHART_CALL nebo_g112_chart_matrix,NEBO_G112_CHART_MATRIX
    G112_CHART_CALL nebo_g112_chart_confusion,NEBO_G112_CHART_CONFUSION
    G112_CHART_CALL nebo_g112_chart_time_series,NEBO_G112_CHART_TIME_SERIES
    G112_CHART_CALL nebo_g112_chart_aggregate,NEBO_G112_CHART_AGGREGATE
%undef G112_CHART_CALL

    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_TARGET],NEBO_G095_TARGET_VISUAL
%macro G112_CHART_PARITY 2
    mov rdi,r13
    lea rsi,[rel g112_visual_receipt]
    call %1
    test eax,eax
    jnz .effect
    mov rax,[rel g112_visual_receipt+NEBO_G112_CHART_RECEIPT_CORE_DIGEST]
    cmp rax,[r12+(%2-1)*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_CORE_DIGEST]
    jne .effect
    mov rax,[rel g112_visual_receipt+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    cmp rax,[r12+(%2-1)*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    jne .effect
%endmacro
    G112_CHART_PARITY nebo_g112_chart_line,NEBO_G112_CHART_LINE
    G112_CHART_PARITY nebo_g112_chart_bar,NEBO_G112_CHART_BAR
    G112_CHART_PARITY nebo_g112_chart_scatter,NEBO_G112_CHART_SCATTER
    G112_CHART_PARITY nebo_g112_chart_histogram,NEBO_G112_CHART_HISTOGRAM
    G112_CHART_PARITY nebo_g112_chart_heatmap,NEBO_G112_CHART_HEATMAP
    G112_CHART_PARITY nebo_g112_chart_matrix,NEBO_G112_CHART_MATRIX
    G112_CHART_PARITY nebo_g112_chart_confusion,NEBO_G112_CHART_CONFUSION
    G112_CHART_PARITY nebo_g112_chart_time_series,NEBO_G112_CHART_TIME_SERIES
    G112_CHART_PARITY nebo_g112_chart_aggregate,NEBO_G112_CHART_AGGREGATE
%undef G112_CHART_PARITY
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_TARGET],NEBO_G095_TARGET_HEADLESS

    lea r12,[rel g112_table_receipts]
    lea r13,[rel g112_table_spec]
%macro G112_TABLE_CALL 2
    mov rdi,r13
    lea rsi,[r12+(%2-NEBO_G112_TABLE_PREVIEW)*NEBO_G112_TABLE_RECEIPT_SIZE]
    call %1
    test eax,eax
    jnz .effect
    cmp qword [r12+(%2-NEBO_G112_TABLE_PREVIEW)*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_OPERATION],%2
    jne .effect
%endmacro
    G112_TABLE_CALL nebo_g112_table_preview,NEBO_G112_TABLE_PREVIEW
    G112_TABLE_CALL nebo_g112_table_schema,NEBO_G112_TABLE_SCHEMA
    G112_TABLE_CALL nebo_g112_table_profile,NEBO_G112_TABLE_PROFILE
%undef G112_TABLE_CALL

%macro G112_TABLE_AUX_CALL 3
    mov rdi,r13
    mov esi,%3
    lea rdx,[r12+(%2-NEBO_G112_TABLE_PREVIEW)*NEBO_G112_TABLE_RECEIPT_SIZE]
    call %1
    test eax,eax
    jnz .effect
    cmp qword [r12+(%2-NEBO_G112_TABLE_PREVIEW)*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_OPERATION],%2
    jne .effect
%endmacro
    G112_TABLE_AUX_CALL nebo_g112_table_sample,NEBO_G112_TABLE_SAMPLE,5
    G112_TABLE_AUX_CALL nebo_g112_table_limit_rows,NEBO_G112_TABLE_LIMIT_ROWS,8
    G112_TABLE_AUX_CALL nebo_g112_table_limit_columns,NEBO_G112_TABLE_LIMIT_COLUMNS,3
    G112_TABLE_AUX_CALL nebo_g112_table_redact,NEBO_G112_TABLE_REDACT,2
    G112_TABLE_AUX_CALL nebo_g112_table_sort,NEBO_G112_TABLE_SORT,1
    mov eax,ebp
    add eax,300
    mov rdi,r13
    mov esi,eax
    lea rdx,[r12+(NEBO_G112_TABLE_FILTER_SUMMARY-NEBO_G112_TABLE_PREVIEW)*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_filter_summary
    test eax,eax
    jnz .effect
%undef G112_TABLE_AUX_CALL

    mov eax,ebp
    jmp .done
.invalid:
    mov eax,NEBO_G112_ERROR_INVALID
    jmp .done
.effect:
    mov eax,-99
.done:
    add rsp,8
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret

; EDI=field 1..24. Observations are deliberately source-independent addresses.
nebo_g112_surface_probe:
    cmp edi,1
    je .mode
    cmp edi,2
    je .seed
    cmp edi,3
    je .line_digest
    cmp edi,4
    je .bar_operation
    cmp edi,5
    je .scatter_kind
    cmp edi,6
    je .histogram_bins
    cmp edi,7
    je .heatmap_rows
    cmp edi,8
    je .matrix_operation
    cmp edi,9
    je .confusion_operation
    cmp edi,10
    je .time_kind
    cmp edi,11
    je .aggregate_digest
    cmp edi,12
    je .preview_cells
    cmp edi,13
    je .schema_operation
    cmp edi,14
    je .profile_operation
    cmp edi,15
    je .sample_count
    cmp edi,16
    je .sample_digest
    cmp edi,17
    je .row_limit
    cmp edi,18
    je .column_limit
    cmp edi,19
    je .redact_policy
    cmp edi,20
    je .sort_column
    cmp edi,21
    je .filter_digest
    cmp edi,22
    je .filter_service_digest
    cmp edi,23
    je .generation
    cmp edi,24
    je .maturity
    xor eax,eax
    ret
.mode: mov rax,[rel g112_last_mode]
    ret
.seed: mov rax,[rel g112_last_seed]
    ret
.line_digest: mov rax,[rel g112_chart_receipts+0*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    ret
.bar_operation: mov rax,[rel g112_chart_receipts+1*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_OPERATION]
    ret
.scatter_kind: mov rax,[rel g112_chart_receipts+2*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_CORE_KIND]
    ret
.histogram_bins: mov rax,[rel g112_chart_receipts+3*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_BINS]
    ret
.heatmap_rows: mov rax,[rel g112_chart_receipts+4*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_ROWS]
    ret
.matrix_operation: mov rax,[rel g112_chart_receipts+5*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_OPERATION]
    ret
.confusion_operation: mov rax,[rel g112_chart_receipts+6*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_OPERATION]
    ret
.time_kind: mov rax,[rel g112_chart_receipts+7*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_CORE_KIND]
    ret
.aggregate_digest: mov rax,[rel g112_chart_receipts+8*NEBO_G112_CHART_RECEIPT_SIZE+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    ret
.preview_cells: mov rax,[rel g112_table_receipts+0*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_CELLS]
    ret
.schema_operation: mov rax,[rel g112_table_receipts+1*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_OPERATION]
    ret
.profile_operation: mov rax,[rel g112_table_receipts+2*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_OPERATION]
    ret
.sample_count: mov rax,[rel g112_table_receipts+3*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_AUX]
    ret
.sample_digest: mov rax,[rel g112_table_receipts+3*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_CORE_DIGEST]
    ret
.row_limit: mov rax,[rel g112_table_receipts+4*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_ROWS]
    ret
.column_limit: mov rax,[rel g112_table_receipts+5*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_COLUMNS]
    ret
.redact_policy: mov rax,[rel g112_table_receipts+6*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_AUX]
    ret
.sort_column: mov rax,[rel g112_table_receipts+7*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_AUX]
    ret
.filter_digest: mov rax,[rel g112_table_receipts+8*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_CORE_DIGEST]
    ret
.filter_service_digest: mov rax,[rel g112_table_receipts+8*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_SERVICE_DIGEST]
    ret
.generation: mov rax,[rel g112_table_receipts+8*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_GENERATION]
    ret
.maturity: mov rax,[rel g112_table_receipts+8*NEBO_G112_TABLE_RECEIPT_SIZE+NEBO_G112_TABLE_RECEIPT_MATURITY]
    ret

; EDI=case 1..20. Every service failure leaves its prior receipt unchanged.
nebo_g112_negative_probe:
    push rbx
    push r12
    sub rsp,8
    mov ebx,edi
    cmp ebx,1
    jb .bad
    cmp ebx,NEBO_G112_SOURCE_NEGATIVE_COUNT
    ja .bad
    mov edi,1
    mov esi,3201
    call nebo_g112_source_probe
    cmp eax,3201
    jne .bad
    cmp ebx,1
    je .bad_mode
    cmp ebx,2
    je .bad_seed
    lea r12,[rel g112_chart_receipts]
    cmp ebx,3
    je .chart_null
    cmp ebx,4
    je .chart_receipt_null
    cmp ebx,5
    je .chart_version
    cmp ebx,6
    je .chart_target
    cmp ebx,7
    je .chart_points
    cmp ebx,8
    je .chart_nonfinite
    cmp ebx,9
    je .hist_bins
    cmp ebx,10
    je .heat_shape
    lea r12,[rel g112_table_receipts]
    cmp ebx,11
    je .table_null
    cmp ebx,12
    je .table_receipt_null
    cmp ebx,13
    je .table_version
    cmp ebx,14
    je .table_rows
    cmp ebx,15
    je .sample_small
    cmp ebx,16
    je .rows_zero
    cmp ebx,17
    je .columns_large
    cmp ebx,18
    je .redact_zero
    cmp ebx,19
    je .sort_large
    jmp .filter_zero
.bad_mode:
    xor edi,edi
    mov esi,3201
    call nebo_g112_source_probe
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.bad_seed:
    mov edi,1
    mov esi,3202
    call nebo_g112_source_probe
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.chart_null:
    xor edi,edi
    mov rsi,r12
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.chart_receipt_null:
    lea rdi,[rel g112_chart_spec]
    xor esi,esi
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.chart_version:
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_VERSION],2
    mov rax,[r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    mov [rsp],rax
    lea rdi,[rel g112_chart_spec]
    mov rsi,r12
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_VERSION
    jne .bad
    mov rdx,[rsp]
    cmp [r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST],rdx
    jne .bad
    jmp .ok
.chart_target:
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_TARGET],3
    mov rax,[r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    mov [rsp],rax
    lea rdi,[rel g112_chart_spec]
    mov rsi,r12
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_TARGET
    jne .bad
    mov rdx,[rsp]
    cmp [r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST],rdx
    jne .bad
    jmp .ok
.chart_points:
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_POINTS],0
    mov rax,[r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    mov [rsp],rax
    lea rdi,[rel g112_chart_spec]
    mov rsi,r12
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    mov rdx,[rsp]
    cmp [r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST],rdx
    jne .bad
    jmp .ok
.chart_nonfinite:
    mov rax,0x7ff8000000000001
    mov [rel g112_y_values],rax
    mov rax,[r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST]
    mov [rsp],rax
    lea rdi,[rel g112_chart_spec]
    mov rsi,r12
    call nebo_g112_chart_line
    cmp eax,NEBO_G112_ERROR_CORE
    jne .bad
    mov rdx,[rsp]
    cmp [r12+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST],rdx
    jne .bad
    jmp .ok
.hist_bins:
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_BINS],0
    lea rdi,[rel g112_chart_spec]
    lea rsi,[r12+3*NEBO_G112_CHART_RECEIPT_SIZE]
    call nebo_g112_chart_histogram
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.heat_shape:
    mov qword [rel g112_chart_spec+NEBO_G112_CHART_SPEC_COLUMNS],3
    lea rdi,[rel g112_chart_spec]
    lea rsi,[r12+4*NEBO_G112_CHART_RECEIPT_SIZE]
    call nebo_g112_chart_heatmap
    cmp eax,NEBO_G112_ERROR_CORE
    jne .bad
    jmp .ok
.table_null:
    xor edi,edi
    mov rsi,r12
    call nebo_g112_table_preview
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.table_receipt_null:
    lea rdi,[rel g112_table_spec]
    xor esi,esi
    call nebo_g112_table_preview
    cmp eax,NEBO_G112_ERROR_INVALID
    jne .bad
    jmp .ok
.table_version:
    mov qword [rel g112_table_spec+NEBO_G112_TABLE_SPEC_VERSION],2
    mov rax,[r12+NEBO_G112_TABLE_RECEIPT_SERVICE_DIGEST]
    mov [rsp],rax
    lea rdi,[rel g112_table_spec]
    mov rsi,r12
    call nebo_g112_table_preview
    cmp eax,NEBO_G112_ERROR_VERSION
    jne .bad
    mov rdx,[rsp]
    cmp [r12+NEBO_G112_TABLE_RECEIPT_SERVICE_DIGEST],rdx
    jne .bad
    jmp .ok
.table_rows:
    mov qword [rel g112_table_spec+NEBO_G112_TABLE_SPEC_ROWS],33
    lea rdi,[rel g112_table_spec]
    mov rsi,r12
    call nebo_g112_table_preview
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.sample_small:
    lea rdi,[rel g112_table_spec]
    mov esi,2
    lea rdx,[r12+3*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_sample
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.rows_zero:
    lea rdi,[rel g112_table_spec]
    xor esi,esi
    lea rdx,[r12+4*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_limit_rows
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.columns_large:
    lea rdi,[rel g112_table_spec]
    mov esi,5
    lea rdx,[r12+5*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_limit_columns
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.redact_zero:
    lea rdi,[rel g112_table_spec]
    xor esi,esi
    lea rdx,[r12+6*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_redact
    cmp eax,NEBO_G112_ERROR_POLICY
    jne .bad
    jmp .ok
.sort_large:
    lea rdi,[rel g112_table_spec]
    mov esi,4
    lea rdx,[r12+7*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_sort
    cmp eax,NEBO_G112_ERROR_BOUNDS
    jne .bad
    jmp .ok
.filter_zero:
    lea rdi,[rel g112_table_spec]
    xor esi,esi
    lea rdx,[r12+8*NEBO_G112_TABLE_RECEIPT_SIZE]
    call nebo_g112_table_filter_summary
    cmp eax,NEBO_G112_ERROR_POLICY
    jne .bad
    jmp .ok
.bad:
    mov eax,1
    jmp .done
.ok:
    xor eax,eax
.done:
    add rsp,8
    pop r12
    pop rbx
    ret
