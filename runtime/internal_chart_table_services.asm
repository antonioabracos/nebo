; G112 internal chart/table service adapters.
bits 64
default rel
%define NEBO_G112_CHART_TABLE_IMPLEMENTATION 1
%include "runtime/internal_chart_table_services.inc"
%include "runtime/console/chart_model.inc"
%include "runtime/structured_views.inc"
%include "runtime/console/large_data.inc"

extern nebo_table_view_build
extern nebo_table_query_plan

section .text
global nebo_g112_chart_line
global nebo_g112_chart_bar
global nebo_g112_chart_scatter
global nebo_g112_chart_histogram
global nebo_g112_chart_heatmap
global nebo_g112_chart_matrix
global nebo_g112_chart_confusion
global nebo_g112_chart_time_series
global nebo_g112_chart_aggregate
global nebo_g112_table_preview
global nebo_g112_table_schema
global nebo_g112_table_profile
global nebo_g112_table_sample
global nebo_g112_table_limit_rows
global nebo_g112_table_limit_columns
global nebo_g112_table_redact
global nebo_g112_table_sort
global nebo_g112_table_filter_summary

%macro G112_CHART_ENTRY 2
%1:
    mov edx,%2
    jmp g112_chart_build
%endmacro
G112_CHART_ENTRY nebo_g112_chart_line,NEBO_G112_CHART_LINE
G112_CHART_ENTRY nebo_g112_chart_bar,NEBO_G112_CHART_BAR
G112_CHART_ENTRY nebo_g112_chart_scatter,NEBO_G112_CHART_SCATTER
G112_CHART_ENTRY nebo_g112_chart_histogram,NEBO_G112_CHART_HISTOGRAM
G112_CHART_ENTRY nebo_g112_chart_heatmap,NEBO_G112_CHART_HEATMAP
G112_CHART_ENTRY nebo_g112_chart_matrix,NEBO_G112_CHART_MATRIX
G112_CHART_ENTRY nebo_g112_chart_confusion,NEBO_G112_CHART_CONFUSION
G112_CHART_ENTRY nebo_g112_chart_time_series,NEBO_G112_CHART_TIME_SERIES
G112_CHART_ENTRY nebo_g112_chart_aggregate,NEBO_G112_CHART_AGGREGATE
%undef G112_CHART_ENTRY

; RDI=borrowed G112 chart spec, RSI=caller-owned receipt, EDX=operation.
; A complete receipt is assembled on the stack and copied only after G095 has
; accepted the translated request, preserving failure atomicity.
g112_chart_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,288
    mov r12,rdi
    mov r13,rsi
    mov r14d,edx
    test r12,r12
    jz .invalid
    test r13,r13
    jz .invalid
    test r12,7
    jnz .invalid
    test r13,7
    jnz .invalid
    cmp qword [r12+NEBO_G112_CHART_SPEC_VERSION],NEBO_G112_SPEC_VERSION
    jne .version
    mov rax,[r12+NEBO_G112_CHART_SPEC_TARGET]
    cmp rax,NEBO_G095_TARGET_HEADLESS
    jb .target
    cmp rax,NEBO_G095_TARGET_VISUAL
    ja .target
    cmp qword [r12+NEBO_G112_CHART_SPEC_POINTS],1
    jb .invalid
    cmp qword [r12+NEBO_G112_CHART_SPEC_POINTS],NEBO_G095_MAX_POINTS
    ja .bounds
    cmp qword [r12+NEBO_G112_CHART_SPEC_SERIES],1
    jb .invalid
    cmp qword [r12+NEBO_G112_CHART_SPEC_SERIES],NEBO_G095_MAX_SERIES
    ja .bounds
    cmp qword [r12+NEBO_G112_CHART_SPEC_GENERATION],0
    je .invalid
    cmp qword [r12+NEBO_G112_CHART_SPEC_Y_VALUES],0
    je .invalid

    mov rdi,rsp
    mov ecx,NEBO_G095_REQUEST_SIZE/8
    xor eax,eax
    cld
    rep stosq
    mov eax,[r12+NEBO_G112_CHART_SPEC_TARGET]
    mov [rsp+NEBO_G095_REQUEST_TARGET_OFFSET],eax
    mov rax,[r12+NEBO_G112_CHART_SPEC_POINTS]
    mov [rsp+NEBO_G095_REQUEST_POINTS_OFFSET],rax
    mov [rsp+NEBO_G095_REQUEST_Y_COUNT_OFFSET],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_SERIES]
    mov [rsp+NEBO_G095_REQUEST_SERIES_OFFSET],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_Y_VALUES]
    mov [rsp+NEBO_G095_REQUEST_Y_PTR_OFFSET],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_GENERATION]
    mov [rsp+NEBO_G095_REQUEST_GENERATION_OFFSET],rax

    cmp r14d,NEBO_G112_CHART_LINE
    je .line
    cmp r14d,NEBO_G112_CHART_BAR
    je .bar
    cmp r14d,NEBO_G112_CHART_SCATTER
    je .scatter
    cmp r14d,NEBO_G112_CHART_HISTOGRAM
    je .histogram
    cmp r14d,NEBO_G112_CHART_HEATMAP
    je .heatmap
    cmp r14d,NEBO_G112_CHART_MATRIX
    je .heatmap
    cmp r14d,NEBO_G112_CHART_CONFUSION
    je .heatmap
    cmp r14d,NEBO_G112_CHART_TIME_SERIES
    je .time_series
    cmp r14d,NEBO_G112_CHART_AGGREGATE
    je .bar
    jmp .invalid
.line:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_LINE
    jmp .xy
.scatter:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_SCATTER
    jmp .xy
.time_series:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_TIME_SERIES
.xy:
    cmp qword [r12+NEBO_G112_CHART_SPEC_X_VALUES],0
    je .invalid
    mov rax,[r12+NEBO_G112_CHART_SPEC_POINTS]
    mov [rsp+NEBO_G095_REQUEST_X_COUNT_OFFSET],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_X_VALUES]
    mov [rsp+NEBO_G095_REQUEST_X_PTR_OFFSET],rax
    mov qword [rsp+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_X | NEBO_G095_OPTION_Y
    jmp .core
.bar:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_BAR
    mov qword [rsp+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y
    jmp .core
.histogram:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HISTOGRAM
    mov rax,[r12+NEBO_G112_CHART_SPEC_BINS]
    test rax,rax
    jz .bounds
    cmp rax,NEBO_G095_MAX_BINS
    ja .bounds
    cmp rax,[r12+NEBO_G112_CHART_SPEC_POINTS]
    ja .bounds
    mov [rsp+NEBO_G095_REQUEST_BINS_OFFSET],rax
    mov qword [rsp+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y | NEBO_G095_OPTION_BINS
    jmp .core
.heatmap:
    mov dword [rsp+NEBO_G095_REQUEST_KIND_OFFSET],NEBO_G095_KIND_HEATMAP
    mov rax,[r12+NEBO_G112_CHART_SPEC_ROWS]
    test rax,rax
    jz .bounds
    mov [rsp+NEBO_G095_REQUEST_ROWS_OFFSET],rax
    mov rcx,[r12+NEBO_G112_CHART_SPEC_COLUMNS]
    test rcx,rcx
    jz .bounds
    mov [rsp+NEBO_G095_REQUEST_COLUMNS_OFFSET],rcx
    mov qword [rsp+NEBO_G095_REQUEST_OPTIONS_OFFSET],NEBO_G095_OPTION_Y
.core:
    mov rdi,rsp
    lea rsi,[rsp+112]
    call nebo_g095_chart_model
    test eax,eax
    jnz .core_error

    lea r15,[rsp+184]
    mov rdi,r15
    mov ecx,NEBO_G112_CHART_RECEIPT_SIZE/8
    xor eax,eax
    rep stosq
    mov [r15+NEBO_G112_CHART_RECEIPT_OPERATION],r14
    mov eax,[rsp+112+NEBO_G095_RESULT_KIND_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_CORE_KIND],rax
    mov eax,[rsp+112+NEBO_G095_RESULT_TARGET_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_TARGET],rax
    mov rax,[rsp+112+NEBO_G095_RESULT_POINTS_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_POINTS],rax
    mov rax,[rsp+112+NEBO_G095_RESULT_SERIES_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_SERIES],rax
    mov rax,[rsp+112+NEBO_G095_RESULT_BINS_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_BINS],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_ROWS]
    mov [r15+NEBO_G112_CHART_RECEIPT_ROWS],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_COLUMNS]
    mov [r15+NEBO_G112_CHART_RECEIPT_COLUMNS],rax
    mov rax,[rsp+112+NEBO_G095_RESULT_DIGEST_OFFSET]
    mov [r15+NEBO_G112_CHART_RECEIPT_CORE_DIGEST],rax

    mov rax,0x6731313263686172
    xor rax,r14
    rol rax,7
    xor rax,[r12+NEBO_G112_CHART_SPEC_POINTS]
    rol rax,11
    xor rax,[r12+NEBO_G112_CHART_SPEC_SERIES]
    rol rax,13
    xor rax,[r12+NEBO_G112_CHART_SPEC_BINS]
    rol rax,17
    xor rax,[r12+NEBO_G112_CHART_SPEC_ROWS]
    rol rax,19
    xor rax,[r12+NEBO_G112_CHART_SPEC_COLUMNS]
    rol rax,23
    xor rax,[r12+NEBO_G112_CHART_SPEC_GENERATION]
    rol rax,29
    xor rax,NEBO_G112_SPEC_VERSION
    mov [r15+NEBO_G112_CHART_RECEIPT_SERVICE_DIGEST],rax
    mov rax,[r12+NEBO_G112_CHART_SPEC_GENERATION]
    mov [r15+NEBO_G112_CHART_RECEIPT_GENERATION],rax
    mov qword [r15+NEBO_G112_CHART_RECEIPT_MATURITY],NEBO_G112_MATURITY_INTERNAL_CHART_TABLE_SERVICES_GREEN
    mov rdi,r13
    mov rsi,r15
    mov ecx,NEBO_G112_CHART_RECEIPT_SIZE/8
    rep movsq
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_G112_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G112_ERROR_BOUNDS
    jmp .done
.core_error:
    mov eax,NEBO_G112_ERROR_CORE
    jmp .done
.version:
    mov eax,NEBO_G112_ERROR_VERSION
    jmp .done
.target:
    mov eax,NEBO_G112_ERROR_TARGET
.done:
    add rsp,288
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

%macro G112_TABLE_NO_AUX 2
%1:
    mov rdx,rsi
    xor esi,esi
    mov ecx,%2
    jmp g112_table_build
%endmacro
G112_TABLE_NO_AUX nebo_g112_table_preview,NEBO_G112_TABLE_PREVIEW
G112_TABLE_NO_AUX nebo_g112_table_schema,NEBO_G112_TABLE_SCHEMA
G112_TABLE_NO_AUX nebo_g112_table_profile,NEBO_G112_TABLE_PROFILE
%undef G112_TABLE_NO_AUX

%macro G112_TABLE_AUX 2
%1:
    mov ecx,%2
    jmp g112_table_build
%endmacro
G112_TABLE_AUX nebo_g112_table_sample,NEBO_G112_TABLE_SAMPLE
G112_TABLE_AUX nebo_g112_table_limit_rows,NEBO_G112_TABLE_LIMIT_ROWS
G112_TABLE_AUX nebo_g112_table_limit_columns,NEBO_G112_TABLE_LIMIT_COLUMNS
G112_TABLE_AUX nebo_g112_table_redact,NEBO_G112_TABLE_REDACT
G112_TABLE_AUX nebo_g112_table_sort,NEBO_G112_TABLE_SORT
G112_TABLE_AUX nebo_g112_table_filter_summary,NEBO_G112_TABLE_FILTER_SUMMARY
%undef G112_TABLE_AUX

; RDI=table spec, RSI=operation argument, RDX=receipt, ECX=operation.
g112_table_build:
    push rbx
    push r12
    push r13
    push r14
    push r15
    sub rsp,576
    mov r12,rdi
    mov r13,rsi
    mov r14,rdx
    mov r15d,ecx
    test r12,r12
    jz .invalid
    test r14,r14
    jz .invalid
    test r12,7
    jnz .invalid
    test r14,7
    jnz .invalid
    cmp qword [r12+NEBO_G112_TABLE_SPEC_VERSION],NEBO_G112_SPEC_VERSION
    jne .version
    cmp qword [r12+NEBO_G112_TABLE_SPEC_SOURCE],0
    je .invalid
    cmp qword [r12+NEBO_G112_TABLE_SPEC_SCHEMA],0
    je .invalid
    cmp qword [r12+NEBO_G112_TABLE_SPEC_GENERATION],0
    je .invalid
    cmp qword [r12+NEBO_G112_TABLE_SPEC_DATA_DIGEST],0
    je .invalid
    mov rax,[r12+NEBO_G112_TABLE_SPEC_ROWS]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_VIEW_MAX_ROWS
    ja .bounds
    mov rbx,rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_COLUMNS]
    test rax,rax
    jz .invalid
    cmp rax,NEBO_VIEW_MAX_COLUMNS
    ja .bounds

    mov rdi,rsp
    mov ecx,NEBO_G112_TABLE_RECEIPT_SIZE/8
    xor eax,eax
    cld
    rep stosq
    mov [rsp+NEBO_G112_TABLE_RECEIPT_OPERATION],r15
    mov rax,[r12+NEBO_G112_TABLE_SPEC_ROWS]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_ROWS],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_COLUMNS]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_COLUMNS],rax

    cmp r15d,NEBO_G112_TABLE_SAMPLE
    je .sample
    cmp r15d,NEBO_G112_TABLE_LIMIT_ROWS
    je .limit_rows
    cmp r15d,NEBO_G112_TABLE_LIMIT_COLUMNS
    je .limit_columns
    cmp r15d,NEBO_G112_TABLE_REDACT
    je .redact
    cmp r15d,NEBO_G112_TABLE_SORT
    je .sort
    cmp r15d,NEBO_G112_TABLE_FILTER_SUMMARY
    je .filter
    cmp r15d,NEBO_G112_TABLE_PREVIEW
    jb .invalid
    cmp r15d,NEBO_G112_TABLE_PROFILE
    ja .invalid
    jmp .table_core
.sample:
    cmp r13,3
    jb .bounds
    cmp r13,NEBO_G101_MAX_SAMPLE
    ja .bounds
    cmp r13,rbx
    ja .bounds
    cmp qword [r12+NEBO_G112_TABLE_SPEC_SAMPLE_VALUES],0
    je .invalid
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13
    jmp .table_core
.limit_rows:
    test r13,r13
    jz .bounds
    cmp r13,rbx
    ja .bounds
    mov [rsp+NEBO_G112_TABLE_RECEIPT_ROWS],r13
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13
    jmp .table_core
.limit_columns:
    test r13,r13
    jz .bounds
    cmp r13,[r12+NEBO_G112_TABLE_SPEC_COLUMNS]
    ja .bounds
    mov [rsp+NEBO_G112_TABLE_RECEIPT_COLUMNS],r13
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13
    jmp .table_core
.redact:
    cmp r13,1
    jb .policy
    cmp r13,3
    ja .policy
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13
    jmp .table_core
.sort:
    cmp r13,[r12+NEBO_G112_TABLE_SPEC_COLUMNS]
    jae .bounds
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13
    jmp .table_core
.filter:
    test r13,r13
    jz .policy
    mov [rsp+NEBO_G112_TABLE_RECEIPT_AUX],r13

.table_core:
    lea rdi,[rsp+72]
    mov ecx,NEBO_TABLE_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,[r12+NEBO_G112_TABLE_SPEC_SOURCE]
    mov [rsp+72+NEBO_TABLE_SOURCE_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_SCHEMA]
    mov [rsp+72+NEBO_TABLE_SCHEMA_OFFSET],rax
    mov rax,[rsp+NEBO_G112_TABLE_RECEIPT_ROWS]
    mov [rsp+72+NEBO_TABLE_ROWS_OFFSET],rax
    mov rax,[rsp+NEBO_G112_TABLE_RECEIPT_COLUMNS]
    mov [rsp+72+NEBO_TABLE_COLUMNS_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_GENERATION]
    mov [rsp+72+NEBO_TABLE_GENERATION_OFFSET],rax
    lea rdi,[rsp+72]
    lea rsi,[rsp+112]
    call nebo_table_view_build
    test eax,eax
    jnz .core_error
    mov rax,[rsp+112+NEBO_TABLE_RECEIPT_CELLS_OFFSET]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_CELLS],rax
    xor rax,[rsp+112+NEBO_TABLE_RECEIPT_GENERATION_OFFSET]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_CORE_DIGEST],rax

    cmp r15d,NEBO_G112_TABLE_SAMPLE
    je .sample_core
    cmp r15d,NEBO_G112_TABLE_SORT
    je .sort_core
    cmp r15d,NEBO_G112_TABLE_FILTER_SUMMARY
    je .filter_core
    jmp .service_digest

.sample_core:
    lea rdi,[rsp+152]
    mov ecx,NEBO_G101_REQUEST_SIZE/8
    xor eax,eax
    rep stosq
    mov dword [rsp+152+NEBO_G101_REQUEST_MODE_OFFSET],3
    mov dword [rsp+152+NEBO_G101_REQUEST_TARGET_OFFSET],NEBO_G101_TARGET_HEADLESS
    mov rax,[r12+NEBO_G112_TABLE_SPEC_SAMPLE_VALUES]
    mov [rsp+152+NEBO_G101_REQUEST_POINTS_PTR_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_ROWS]
    mov [rsp+152+NEBO_G101_REQUEST_POINT_COUNT_OFFSET],rax
    mov [rsp+152+NEBO_G101_REQUEST_TARGET_POINTS_OFFSET],r13
    mov [rsp+152+NEBO_G101_REQUEST_SAMPLE_COUNT_OFFSET],r13
    mov qword [rsp+152+NEBO_G101_REQUEST_CHUNK_SIZE_OFFSET],4
    mov qword [rsp+152+NEBO_G101_REQUEST_CACHE_CAPACITY_OFFSET],8
    mov qword [rsp+152+NEBO_G101_REQUEST_MEMORY_BUDGET_OFFSET],65536
    mov qword [rsp+152+NEBO_G101_REQUEST_FRAME_BUDGET_OFFSET],16
    mov qword [rsp+152+NEBO_G101_REQUEST_QUALITY_OFFSET],2
    mov rax,[r12+NEBO_G112_TABLE_SPEC_DATA_DIGEST]
    mov [rsp+152+NEBO_G101_REQUEST_SEED_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_GENERATION]
    mov [rsp+152+NEBO_G101_REQUEST_GENERATION_OFFSET],rax
    mov [rsp+152+NEBO_G101_REQUEST_CACHE_GENERATION_OFFSET],rax
    mov qword [rsp+152+NEBO_G101_REQUEST_OPTIONS_OFFSET],NEBO_G101_OPTION_DECIMATE | NEBO_G101_OPTION_SAMPLE
    mov qword [rsp+152+NEBO_G101_REQUEST_SPEC_VERSION_OFFSET],NEBO_G101_SPEC_VERSION
    mov qword [rsp+152+NEBO_G101_REQUEST_POINT_STRIDE_OFFSET],NEBO_G101_POINT_SIZE
    mov qword [rsp+152+NEBO_G101_REQUEST_DECIMATION_POLICY_OFFSET],NEBO_G101_DECIMATE_LTTB
    mov qword [rsp+152+NEBO_G101_REQUEST_AGGREGATION_POLICY_OFFSET],NEBO_G101_AGGREGATE_MEAN
    lea rdi,[rsp+152]
    lea rsi,[rsp+296]
    call nebo_g101_large_data_model
    test eax,eax
    jnz .core_error
    mov rax,[rsp+296+NEBO_G101_RESULT_SAMPLE_DIGEST_OFFSET]
    test rax,rax
    jz .core_error
    mov [rsp+NEBO_G112_TABLE_RECEIPT_CORE_DIGEST],rax
    jmp .service_digest

.sort_core:
    xor ebx,ebx
    mov ebx,NEBO_QUERY_FLAG_SORT
    jmp .query_core
.filter_core:
    mov [rsp+568],r13
    mov ebx,NEBO_QUERY_FLAG_FILTER
.query_core:
    lea rdi,[rsp+456]
    mov ecx,NEBO_QUERY_SIZE/8
    xor eax,eax
    rep stosq
    mov rax,[r12+NEBO_G112_TABLE_SPEC_SOURCE]
    mov [rsp+456+NEBO_QUERY_SOURCE_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_GENERATION]
    mov [rsp+456+NEBO_QUERY_GENERATION_OFFSET],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_COLUMNS]
    mov [rsp+456+NEBO_QUERY_COLUMN_COUNT_OFFSET],rax
    mov [rsp+456+NEBO_QUERY_FLAGS_OFFSET],rbx
    cmp r15d,NEBO_G112_TABLE_SORT
    jne .query_filter
    mov [rsp+456+NEBO_QUERY_SORT_COLUMN_OFFSET],r13
    jmp .query_call
.query_filter:
    lea rax,[rsp+568]
    mov [rsp+456+NEBO_QUERY_FILTER_OFFSET],rax
    mov qword [rsp+456+NEBO_QUERY_FILTER_LENGTH_OFFSET],8
.query_call:
    lea rdi,[rsp+456]
    lea rsi,[rsp+528]
    call nebo_table_query_plan
    test eax,eax
    jnz .core_error
    cmp r15d,NEBO_G112_TABLE_SORT
    jne .query_digest
    mov rax,[rsp+528+NEBO_QUERY_RECEIPT_SORT_COLUMN_OFFSET]
    rol rax,17
    xor rax,[rsp+528+NEBO_QUERY_RECEIPT_GENERATION_OFFSET]
    jmp .query_store
.query_digest:
    mov rax,[rsp+528+NEBO_QUERY_RECEIPT_FILTER_DIGEST_OFFSET]
.query_store:
    mov [rsp+NEBO_G112_TABLE_RECEIPT_CORE_DIGEST],rax

.service_digest:
    mov rax,0x673131327461626c
    xor rax,[r12+NEBO_G112_TABLE_SPEC_SOURCE]
    rol rax,7
    xor rax,[r12+NEBO_G112_TABLE_SPEC_SCHEMA]
    rol rax,11
    xor rax,r15
    rol rax,13
    xor rax,[rsp+NEBO_G112_TABLE_RECEIPT_ROWS]
    rol rax,17
    xor rax,[rsp+NEBO_G112_TABLE_RECEIPT_COLUMNS]
    rol rax,19
    xor rax,[rsp+NEBO_G112_TABLE_RECEIPT_AUX]
    rol rax,23
    xor rax,[r12+NEBO_G112_TABLE_SPEC_DATA_DIGEST]
    rol rax,29
    xor rax,[r12+NEBO_G112_TABLE_SPEC_GENERATION]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_SERVICE_DIGEST],rax
    mov rax,[r12+NEBO_G112_TABLE_SPEC_GENERATION]
    mov [rsp+NEBO_G112_TABLE_RECEIPT_GENERATION],rax
    mov qword [rsp+NEBO_G112_TABLE_RECEIPT_MATURITY],NEBO_G112_MATURITY_INTERNAL_CHART_TABLE_SERVICES_GREEN
    mov rdi,r14
    mov rsi,rsp
    mov ecx,NEBO_G112_TABLE_RECEIPT_SIZE/8
    rep movsq
    xor eax,eax
    jmp .done
.invalid:
    mov eax,NEBO_G112_ERROR_INVALID
    jmp .done
.bounds:
    mov eax,NEBO_G112_ERROR_BOUNDS
    jmp .done
.core_error:
    mov eax,NEBO_G112_ERROR_CORE
    jmp .done
.version:
    mov eax,NEBO_G112_ERROR_VERSION
    jmp .done
.policy:
    mov eax,NEBO_G112_ERROR_POLICY
.done:
    add rsp,576
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
