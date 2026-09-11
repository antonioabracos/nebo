; G094 source-to-effect probes over bounded structured-view owners.
bits 64
default rel
%define NEBO_G094_SOURCE_PROBE_IMPLEMENTATION 1
%include "runtime/structured_views_source_probe.inc"
%include "runtime/structured_views.inc"
%include "runtime/p02_integration.inc"

extern nebo_table_view_build
extern nebo_table_configure
extern nebo_table_query_plan
extern nebo_hierarchy_view_build
extern nebo_record_view_build
extern nebo_inspection_plan
extern nebo_value_marker_build
extern nebo_virtual_window_plan
extern nebo_structured_conformance_scan
extern nebo_p02_render_plan_close

global nebo_g094_source_probe
global nebo_g094_negative_probe

section .rodata align=16
g94_filter: db 'source-filter'
g94_filter_len equ $-g94_filter
g94_metadata: db 'shape:bounded-row'
g94_metadata_len equ $-g94_metadata
g94_label: db 'truncated'
g94_label_len equ $-g94_label

section .bss align=16
g94_request: resb 256
g94_result: resb 256
g94_source: resq 8
g94_columns: resq NEBO_VIEW_MAX_COLUMNS
g94_nodes: resq NEBO_VIEW_MAX_NODES
g94_checked: resb 32
g94_fields: resb 8 * nebo_structured_views_FIELD_SIZE
g94_references: resb NEBO_CONFORMANCE_WINDOW * NEBO_REFERENCE_SIZE
g94_registry: resq 4
g94_document: resq 4
g94_style: resq 4
g94_layout: resq 4
g94_view: resq 4

section .text
g94_clear:
    lea rdi, [rel g94_request]
    mov ecx, 32
    xor eax, eax
    cld
    rep stosq
    lea rdi, [rel g94_result]
    mov ecx, 32
    xor eax, eax
    rep stosq
    ret

; EDI=front 1..10, ESI=source value -> EAX=owner-published observation.
nebo_g094_source_probe:
    push rbx
    push r12
    sub rsp, 8
    mov r12d, edi
    mov ebx, esi
    test ebx, ebx
    jz .failure
    cmp ebx, 255
    ja .failure
    call g94_clear
    cmp r12d, 1
    je .table
    cmp r12d, 2
    je .config
    cmp r12d, 3
    je .query
    cmp r12d, 4
    je .hierarchy
    cmp r12d, 5
    je .record
    cmp r12d, 6
    je .inspect
    cmp r12d, 7
    je .value
    cmp r12d, 8
    je .window
    cmp r12d, 9
    je .conformance
    cmp r12d, 10
    je .closeout
    jmp .failure

.table:
    cmp ebx, NEBO_VIEW_MAX_ROWS
    ja .failure
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_TABLE_SOURCE_OFFSET], rax
    lea rax, [rel g94_columns]
    mov [rel g94_request + NEBO_TABLE_SCHEMA_OFFSET], rax
    mov [rel g94_request + NEBO_TABLE_ROWS_OFFSET], rbx
    mov qword [rel g94_request + NEBO_TABLE_COLUMNS_OFFSET], 1
    mov [rel g94_request + NEBO_TABLE_GENERATION_OFFSET], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_table_view_build
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_TABLE_RECEIPT_GENERATION_OFFSET]
    jmp .verify

.config:
    cmp ebx, NEBO_VIEW_MAX_ROWS
    ja .failure
    mov qword [rel g94_columns], 1
    mov qword [rel g94_columns + 8], 2
    mov qword [rel g94_columns + 16], 3
    lea rax, [rel g94_columns]
    mov [rel g94_request + NEBO_TABLE_CONFIG_COLUMNS_OFFSET], rax
    mov qword [rel g94_request + NEBO_TABLE_CONFIG_COLUMN_COUNT_OFFSET], 3
    mov [rel g94_request + NEBO_TABLE_CONFIG_PAGE_SIZE_OFFSET], rbx
    mov rax, rbx
    imul rax, 3
    mov [rel g94_request + NEBO_TABLE_CONFIG_TOTAL_ROWS_OFFSET], rax
    mov qword [rel g94_request + NEBO_TABLE_CONFIG_FREEZE_HEADER_OFFSET], 1
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_table_configure
    test eax, eax
    jnz .failure
    cmp qword [rel g94_result + NEBO_TABLE_CONFIG_RECEIPT_COLUMNS_OFFSET], 3
    jne .failure
    cmp qword [rel g94_result + NEBO_TABLE_CONFIG_RECEIPT_FREEZE_HEADER_OFFSET], 1
    jne .failure
    mov eax, [rel g94_result + NEBO_TABLE_CONFIG_RECEIPT_PAGE_SIZE_OFFSET]
    jmp .verify

.query:
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_QUERY_SOURCE_OFFSET], rax
    mov [rel g94_request + NEBO_QUERY_GENERATION_OFFSET], rbx
    mov qword [rel g94_request + NEBO_QUERY_COLUMN_COUNT_OFFSET], 3
    mov qword [rel g94_request + NEBO_QUERY_SORT_COLUMN_OFFSET], 1
    lea rax, [rel g94_filter]
    mov [rel g94_request + NEBO_QUERY_FILTER_OFFSET], rax
    mov qword [rel g94_request + NEBO_QUERY_FILTER_LENGTH_OFFSET], g94_filter_len
    mov qword [rel g94_request + NEBO_QUERY_SELECT_ROW_OFFSET], 2
    mov qword [rel g94_request + NEBO_QUERY_SELECT_COLUMN_OFFSET], 1
    mov qword [rel g94_request + NEBO_QUERY_FLAGS_OFFSET], NEBO_QUERY_FLAG_SORT | NEBO_QUERY_FLAG_FILTER | NEBO_QUERY_FLAG_SELECT
    mov [rel g94_source], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_table_query_plan
    test eax, eax
    jnz .failure
    cmp [rel g94_source], rbx
    jne .failure
    mov eax, [rel g94_result + NEBO_QUERY_RECEIPT_GENERATION_OFFSET]
    jmp .verify

.hierarchy:
    cmp ebx, NEBO_VIEW_MAX_NODES
    ja .failure
    lea rdi, [rel g94_nodes]
    xor ecx, ecx
.hierarchy_fill:
    inc ecx
    mov [rdi + rcx * 8 - 8], rcx
    cmp ecx, ebx
    jb .hierarchy_fill
    mov qword [rel g94_checked], -1
    mov qword [rel g94_checked + 8], -1
    mov qword [rel g94_checked + 16], -1
    mov qword [rel g94_checked + 24], -1
    lea rax, [rel g94_nodes]
    mov [rel g94_request + NEBO_HIERARCHY_NODES_OFFSET], rax
    mov qword [rel g94_request + NEBO_HIERARCHY_KIND_OFFSET], NEBO_HIERARCHY_CHECKLIST
    mov [rel g94_request + NEBO_HIERARCHY_COUNT_OFFSET], rbx
    mov qword [rel g94_request + NEBO_HIERARCHY_DEPTH_OFFSET], 3
    lea rax, [rel g94_checked]
    mov [rel g94_request + NEBO_HIERARCHY_CHECKED_OFFSET], rax
    mov rax, rbx
    add rax, 7
    shr rax, 3
    mov [rel g94_request + NEBO_HIERARCHY_CHECKED_BYTES_OFFSET], rax
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_hierarchy_view_build
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_HIERARCHY_RECEIPT_COUNT_OFFSET]
    jmp .verify

.record:
    mov [rel g94_fields + NEBO_FIELD_NAME_ID_OFFSET], rbx
    mov qword [rel g94_fields + NEBO_FIELD_TYPE_ID_OFFSET], 10
    mov qword [rel g94_fields + NEBO_FIELD_FLAGS_OFFSET], 0
    mov rax, rbx
    inc rax
    mov [rel g94_fields + nebo_structured_views_FIELD_SIZE + NEBO_FIELD_NAME_ID_OFFSET], rax
    mov qword [rel g94_fields + nebo_structured_views_FIELD_SIZE + NEBO_FIELD_TYPE_ID_OFFSET], 11
    mov qword [rel g94_fields + nebo_structured_views_FIELD_SIZE + NEBO_FIELD_FLAGS_OFFSET], 1
    mov qword [rel g94_request + NEBO_RECORD_KIND_OFFSET], NEBO_RECORD_SCHEMA
    lea rax, [rel g94_fields]
    mov [rel g94_request + NEBO_RECORD_FIELDS_OFFSET], rax
    mov qword [rel g94_request + NEBO_RECORD_FIELD_COUNT_OFFSET], 2
    mov [rel g94_request + NEBO_RECORD_SCHEMA_ID_OFFSET], rbx
    mov qword [rel g94_request + NEBO_RECORD_SCHEMA_VERSION_OFFSET], 1
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_record_view_build
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_RECORD_RECEIPT_SCHEMA_ID_OFFSET]
    jmp .verify

.inspect:
    cmp ebx, NEBO_VIEW_MAX_ROWS
    ja .failure
    mov qword [rel g94_request + NEBO_INSPECT_KIND_OFFSET], NEBO_INSPECT_PREVIEW
    mov qword [rel g94_request + NEBO_INSPECT_SOURCE_KIND_OFFSET], 7
    lea rax, [rel g94_metadata]
    mov [rel g94_request + NEBO_INSPECT_METADATA_OFFSET], rax
    mov qword [rel g94_request + NEBO_INSPECT_METADATA_LENGTH_OFFSET], g94_metadata_len
    mov qword [rel g94_request + NEBO_INSPECT_FLAGS_OFFSET], NEBO_INSPECT_FLAG_PUBLIC_METADATA
    mov [rel g94_request + NEBO_INSPECT_MAX_ITEMS_OFFSET], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_inspection_plan
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_INSPECT_RECEIPT_MAX_ITEMS_OFFSET]
    jmp .verify

.value:
    mov qword [rel g94_request + NEBO_VALUE_STATE_OFFSET], NEBO_VALUE_PRESENT
    mov [rel g94_request + NEBO_VALUE_TOTAL_OFFSET], rbx
    mov rax, rbx
    cmp rax, NEBO_VIEW_MAX_ROWS
    jbe .value_visible
    mov rax, NEBO_VIEW_MAX_ROWS
.value_visible:
    mov [rel g94_request + NEBO_VALUE_VISIBLE_OFFSET], rax
    lea rax, [rel g94_label]
    mov [rel g94_request + NEBO_VALUE_LABEL_OFFSET], rax
    mov qword [rel g94_request + NEBO_VALUE_LABEL_LENGTH_OFFSET], g94_label_len
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_value_marker_build
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_VALUE_RECEIPT_TOTAL_OFFSET]
    jmp .verify

.window:
    cmp ebx, NEBO_WINDOW_MAX_ITEMS
    ja .failure
    ; The named maxRows/table values drive this bounded plan; maxColumns is
    ; validated by the source vertical and by the table preflight below.
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_TABLE_SOURCE_OFFSET], rax
    lea rax, [rel g94_columns]
    mov [rel g94_request + NEBO_TABLE_SCHEMA_OFFSET], rax
    mov [rel g94_request + NEBO_TABLE_ROWS_OFFSET], rbx
    mov qword [rel g94_request + NEBO_TABLE_COLUMNS_OFFSET], NEBO_VIEW_MAX_COLUMNS
    mov [rel g94_request + NEBO_TABLE_GENERATION_OFFSET], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_table_view_build
    test eax, eax
    jnz .failure
    call g94_clear
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_WINDOW_SOURCE_OFFSET], rax
    mov qword [rel g94_request + NEBO_WINDOW_TOTAL_OFFSET], 100
    mov qword [rel g94_request + NEBO_WINDOW_OFFSET_OFFSET], 40
    mov [rel g94_request + NEBO_WINDOW_SIZE_OFFSET], rbx
    mov qword [rel g94_request + NEBO_WINDOW_OVERSCAN_OFFSET], 3
    mov [rel g94_request + nebo_structured_views_WINDOW_GENERATION_OFFSET], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_virtual_window_plan
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_WINDOW_RECEIPT_GENERATION_OFFSET]
    jmp .verify

.conformance:
    cmp ebx, NEBO_CONFORMANCE_WINDOW
    jne .failure
    lea rdi, [rel g94_references]
    xor ecx, ecx
.reference_fill:
    inc ecx
    mov rax, rcx
    mov [rdi + NEBO_REFERENCE_KIND_OFFSET], rax
    mov qword [rdi + NEBO_REFERENCE_STATE_OFFSET], 1
    mov [rdi + NEBO_REFERENCE_EXTENT_OFFSET], rbx
    add rax, rbx
    mov [rdi + NEBO_REFERENCE_DIGEST_OFFSET], rax
    add rdi, NEBO_REFERENCE_SIZE
    cmp ecx, NEBO_CONFORMANCE_WINDOW
    jb .reference_fill
    lea rax, [rel g94_references]
    mov [rel g94_request + NEBO_CONFORMANCE_REFERENCES_OFFSET], rax
    mov [rel g94_request + NEBO_CONFORMANCE_COUNT_OFFSET], rbx
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_structured_conformance_scan
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_CONFORMANCE_RECEIPT_COUNT_OFFSET]
    jmp .verify

.closeout:
    mov qword [rel g94_registry + NEBO_P02_REGISTRY_DIGEST_OFFSET], 0x11
    mov qword [rel g94_registry + NEBO_P02_REGISTRY_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_document + NEBO_P02_DOCUMENT_DIGEST_OFFSET], 0x22
    mov qword [rel g94_document + NEBO_P02_DOCUMENT_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    mov qword [rel g94_document + NEBO_P02_DOCUMENT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_style + NEBO_P02_STYLE_DIGEST_OFFSET], 0x33
    mov qword [rel g94_style + NEBO_P02_STYLE_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    mov qword [rel g94_style + NEBO_P02_STYLE_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_layout + NEBO_P02_LAYOUT_DIGEST_OFFSET], 0x44
    mov qword [rel g94_layout + NEBO_P02_LAYOUT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_view + NEBO_P02_VIEW_DIGEST_OFFSET], 0x55
    mov qword [rel g94_view + NEBO_P02_VIEW_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    lea rax, [rel g94_registry]
    mov [rel g94_request + NEBO_P02_REQUEST_REGISTRY_OFFSET], rax
    lea rax, [rel g94_document]
    mov [rel g94_request + NEBO_P02_REQUEST_DOCUMENT_OFFSET], rax
    lea rax, [rel g94_style]
    mov [rel g94_request + NEBO_P02_REQUEST_STYLE_OFFSET], rax
    lea rax, [rel g94_layout]
    mov [rel g94_request + NEBO_P02_REQUEST_LAYOUT_OFFSET], rax
    lea rax, [rel g94_view]
    mov [rel g94_request + NEBO_P02_REQUEST_VIEW_OFFSET], rax
    mov [rel g94_request + NEBO_P02_REQUEST_GENERATION_OFFSET], rbx
    mov qword [rel g94_request + NEBO_P02_REQUEST_FLAGS_OFFSET], NEBO_P02_REQUIRED_FLAGS
    lea rdi, [rel g94_request]
    lea rsi, [rel g94_result]
    call nebo_p02_render_plan_close
    test eax, eax
    jnz .failure
    mov eax, [rel g94_result + NEBO_P02_RECEIPT_GENERATION_OFFSET]
.verify:
    cmp eax, ebx
    jne .failure
    add rsp, 8
    pop r12
    pop rbx
    ret
.failure:
    xor eax, eax
    add rsp, 8
    pop r12
    pop rbx
    ret

; EDI=front -> EAX=stable owner error.  Receipts stay untouched by owners.
nebo_g094_negative_probe:
    push rbx
    mov ebx, edi
    call g94_clear
    lea rsi, [rel g94_result]
    cmp ebx, 1
    je .neg_table
    cmp ebx, 2
    je .neg_config
    cmp ebx, 3
    je .neg_query
    cmp ebx, 4
    je .neg_hierarchy
    cmp ebx, 5
    je .neg_record
    cmp ebx, 6
    je .neg_inspect
    cmp ebx, 7
    je .neg_value
    cmp ebx, 8
    je .neg_window
    cmp ebx, 9
    je .neg_conformance
    cmp ebx, 10
    je .neg_closeout
    mov eax, NEBO_VIEW_INVALID
    pop rbx
    ret
.neg_table:
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_TABLE_SOURCE_OFFSET], rax
    mov [rel g94_request + NEBO_TABLE_SCHEMA_OFFSET], rax
    mov qword [rel g94_request + NEBO_TABLE_ROWS_OFFSET], NEBO_VIEW_MAX_ROWS + 1
    mov qword [rel g94_request + NEBO_TABLE_COLUMNS_OFFSET], 1
    lea rdi, [rel g94_request]
    call nebo_table_view_build
    jmp .neg_done
.neg_config:
    lea rax, [rel g94_columns]
    mov [rel g94_request + NEBO_TABLE_CONFIG_COLUMNS_OFFSET], rax
    mov qword [rel g94_request + NEBO_TABLE_CONFIG_COLUMN_COUNT_OFFSET], 1
    mov qword [rel g94_columns], 1
    mov qword [rel g94_request + NEBO_TABLE_CONFIG_PAGE_SIZE_OFFSET], NEBO_VIEW_MAX_ROWS + 1
    mov qword [rel g94_request + NEBO_TABLE_CONFIG_TOTAL_ROWS_OFFSET], 100
    lea rdi, [rel g94_request]
    call nebo_table_configure
    jmp .neg_done
.neg_query:
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_QUERY_SOURCE_OFFSET], rax
    mov qword [rel g94_request + NEBO_QUERY_GENERATION_OFFSET], 1
    mov qword [rel g94_request + NEBO_QUERY_COLUMN_COUNT_OFFSET], 2
    mov qword [rel g94_request + NEBO_QUERY_SORT_COLUMN_OFFSET], 2
    mov qword [rel g94_request + NEBO_QUERY_FLAGS_OFFSET], NEBO_QUERY_FLAG_SORT
    lea rdi, [rel g94_request]
    call nebo_table_query_plan
    jmp .neg_done
.neg_hierarchy:
    lea rax, [rel g94_nodes]
    mov [rel g94_request + NEBO_HIERARCHY_NODES_OFFSET], rax
    mov qword [rel g94_nodes], 1
    mov qword [rel g94_request + NEBO_HIERARCHY_KIND_OFFSET], NEBO_HIERARCHY_TREE
    mov qword [rel g94_request + NEBO_HIERARCHY_COUNT_OFFSET], 1
    mov qword [rel g94_request + NEBO_HIERARCHY_DEPTH_OFFSET], NEBO_VIEW_MAX_DEPTH + 1
    lea rdi, [rel g94_request]
    call nebo_hierarchy_view_build
    jmp .neg_done
.neg_record:
    lea rax, [rel g94_fields]
    mov [rel g94_request + NEBO_RECORD_FIELDS_OFFSET], rax
    mov qword [rel g94_request + NEBO_RECORD_KIND_OFFSET], NEBO_RECORD_OBJECT
    mov qword [rel g94_request + NEBO_RECORD_FIELD_COUNT_OFFSET], 1
    mov qword [rel g94_request + NEBO_RECORD_SCHEMA_VERSION_OFFSET], 1
    lea rdi, [rel g94_request]
    call nebo_record_view_build
    jmp .neg_done
.neg_inspect:
    mov qword [rel g94_request + NEBO_INSPECT_KIND_OFFSET], NEBO_INSPECT_FULL
    mov qword [rel g94_request + NEBO_INSPECT_SOURCE_KIND_OFFSET], 1
    mov qword [rel g94_request + NEBO_INSPECT_FLAGS_OFFSET], NEBO_INSPECT_FLAG_SENSITIVE
    mov qword [rel g94_request + NEBO_INSPECT_MAX_ITEMS_OFFSET], 1
    lea rdi, [rel g94_request]
    call nebo_inspection_plan
    jmp .neg_done
.neg_value:
    lea rax, [rel g94_label]
    mov [rel g94_request + NEBO_VALUE_LABEL_OFFSET], rax
    mov qword [rel g94_request + NEBO_VALUE_LABEL_LENGTH_OFFSET], g94_label_len
    mov qword [rel g94_request + NEBO_VALUE_STATE_OFFSET], NEBO_VALUE_MISSING
    mov qword [rel g94_request + NEBO_VALUE_TOTAL_OFFSET], 1
    lea rdi, [rel g94_request]
    call nebo_value_marker_build
    jmp .neg_done
.neg_window:
    lea rax, [rel g94_source]
    mov [rel g94_request + NEBO_WINDOW_SOURCE_OFFSET], rax
    mov qword [rel g94_request + NEBO_WINDOW_TOTAL_OFFSET], 100
    mov qword [rel g94_request + NEBO_WINDOW_OFFSET_OFFSET], 10
    mov qword [rel g94_request + NEBO_WINDOW_SIZE_OFFSET], NEBO_WINDOW_MAX_ITEMS + 1
    lea rdi, [rel g94_request]
    call nebo_virtual_window_plan
    jmp .neg_done
.neg_conformance:
    mov qword [rel g94_references + NEBO_REFERENCE_KIND_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_STATE_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_EXTENT_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_DIGEST_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_SIZE + NEBO_REFERENCE_KIND_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_SIZE + NEBO_REFERENCE_STATE_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_SIZE + NEBO_REFERENCE_EXTENT_OFFSET], 1
    mov qword [rel g94_references + NEBO_REFERENCE_SIZE + NEBO_REFERENCE_DIGEST_OFFSET], 2
    lea rax, [rel g94_references]
    mov [rel g94_request + NEBO_CONFORMANCE_REFERENCES_OFFSET], rax
    mov qword [rel g94_request + NEBO_CONFORMANCE_COUNT_OFFSET], 2
    lea rdi, [rel g94_request]
    call nebo_structured_conformance_scan
    jmp .neg_done
.neg_closeout:
    lea rax, [rel g94_registry]
    mov [rel g94_request + NEBO_P02_REQUEST_REGISTRY_OFFSET], rax
    lea rax, [rel g94_document]
    mov [rel g94_request + NEBO_P02_REQUEST_DOCUMENT_OFFSET], rax
    lea rax, [rel g94_style]
    mov [rel g94_request + NEBO_P02_REQUEST_STYLE_OFFSET], rax
    lea rax, [rel g94_layout]
    mov [rel g94_request + NEBO_P02_REQUEST_LAYOUT_OFFSET], rax
    lea rax, [rel g94_view]
    mov [rel g94_request + NEBO_P02_REQUEST_VIEW_OFFSET], rax
    mov qword [rel g94_request + NEBO_P02_REQUEST_GENERATION_OFFSET], 1
    mov qword [rel g94_request + NEBO_P02_REQUEST_FLAGS_OFFSET], NEBO_P02_REQUIRED_FLAGS
    mov qword [rel g94_registry + NEBO_P02_REGISTRY_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_document + NEBO_P02_DOCUMENT_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    mov qword [rel g94_document + NEBO_P02_DOCUMENT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_style + NEBO_P02_STYLE_TARGET_OFFSET], NEBO_P02_TARGET_HEADLESS
    mov qword [rel g94_style + NEBO_P02_STYLE_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_layout + NEBO_P02_LAYOUT_STATE_OFFSET], NEBO_P02_COMPONENT_READY
    mov qword [rel g94_view + NEBO_P02_VIEW_STATE_OFFSET], 0
    lea rdi, [rel g94_request]
    call nebo_p02_render_plan_close
.neg_done:
    pop rbx
    ret

section .note.GNU-stack noalloc noexec nowrite progbits
