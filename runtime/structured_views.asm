; Nebo Assembly — TABLES-LISTS-TREES-OBJECTS-SCHEMA-E-INSPECTION-VIEWS bounded structured views
bits 64
default rel
%include "runtime/structured_views.inc"
global nebo_table_view_build
global nebo_table_configure
global nebo_table_query_plan
global nebo_hierarchy_view_build
global nebo_record_view_build
global nebo_inspection_plan
global nebo_value_marker_build
global nebo_virtual_window_plan
global nebo_structured_conformance_scan
section .text
; Builds only a bounded table plan; source rows are never materialized here.
nebo_table_view_build:
    test rdi, rdi
    jz .table_invalid
    test rsi, rsi
    jz .table_invalid
    cmp qword [rdi + NEBO_TABLE_SOURCE_OFFSET], 0
    je .table_invalid
    cmp qword [rdi + NEBO_TABLE_SCHEMA_OFFSET], 0
    je .table_schema
    mov rcx, [rdi + NEBO_TABLE_ROWS_OFFSET]
    mov rdx, [rdi + NEBO_TABLE_COLUMNS_OFFSET]
    test rcx, rcx
    jz .table_invalid
    test rdx, rdx
    jz .table_invalid
    cmp rcx, NEBO_VIEW_MAX_ROWS
    ja .table_limit
    cmp rdx, NEBO_VIEW_MAX_COLUMNS
    ja .table_limit
    mov rax, rcx
    mul rdx
    test rdx, rdx
    jnz .table_limit
    cmp rax, NEBO_VIEW_MAX_CELLS
    ja .table_limit
    mov [rsi + NEBO_TABLE_RECEIPT_ROWS_OFFSET], rcx
    mov rdx, [rdi + NEBO_TABLE_COLUMNS_OFFSET]
    mov [rsi + NEBO_TABLE_RECEIPT_COLUMNS_OFFSET], rdx
    mov [rsi + NEBO_TABLE_RECEIPT_CELLS_OFFSET], rax
    mov rax, [rdi + NEBO_TABLE_GENERATION_OFFSET]
    mov [rsi + NEBO_TABLE_RECEIPT_GENERATION_OFFSET], rax
    mov qword [rsi + NEBO_TABLE_RECEIPT_STATE_OFFSET], NEBO_TABLE_READY
    xor eax, eax
    ret
.table_schema:
    mov eax, NEBO_VIEW_SCHEMA
    ret
.table_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.table_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Validates ordered column IDs and derives bounded pagination metadata.
nebo_table_configure:
    test rdi, rdi
    jz .config_invalid
    test rsi, rsi
    jz .config_invalid
    mov rdx, [rdi + NEBO_TABLE_CONFIG_COLUMNS_OFFSET]
    mov rcx, [rdi + NEBO_TABLE_CONFIG_COLUMN_COUNT_OFFSET]
    test rdx, rdx
    jz .config_invalid
    test rcx, rcx
    jz .config_invalid
    cmp rcx, NEBO_VIEW_MAX_COLUMNS
    ja .config_limit
    xor r8d, r8d
    xor r9d, r9d
.config_column_loop:
    cmp r8, rcx
    jae .config_page
    mov r10, [rdx + r8 * 8]
    test r10, r10
    jz .config_schema
    cmp r10, r9
    jbe .config_conflict
    mov r9, r10
    inc r8
    jmp .config_column_loop
.config_page:
    mov r8, [rdi + NEBO_TABLE_CONFIG_PAGE_SIZE_OFFSET]
    test r8, r8
    jz .config_invalid
    cmp r8, NEBO_VIEW_MAX_ROWS
    ja .config_limit
    mov rax, [rdi + NEBO_TABLE_CONFIG_TOTAL_ROWS_OFFSET]
    test rax, rax
    jz .config_invalid
    mov r9, [rdi + NEBO_TABLE_CONFIG_FREEZE_HEADER_OFFSET]
    cmp r9, 1
    ja .config_invalid
    xor edx, edx
    div r8
    test rdx, rdx
    jz .config_commit
    inc rax
.config_commit:
    mov [rsi + NEBO_TABLE_CONFIG_RECEIPT_COLUMNS_OFFSET], rcx
    mov [rsi + NEBO_TABLE_CONFIG_RECEIPT_PAGE_SIZE_OFFSET], r8
    mov [rsi + NEBO_TABLE_CONFIG_RECEIPT_PAGE_COUNT_OFFSET], rax
    mov [rsi + NEBO_TABLE_CONFIG_RECEIPT_FREEZE_HEADER_OFFSET], r9
    mov qword [rsi + NEBO_TABLE_CONFIG_RECEIPT_STATE_OFFSET], NEBO_TABLE_CONFIG_READY
    xor eax, eax
    ret
.config_schema:
    mov eax, NEBO_VIEW_SCHEMA
    ret
.config_conflict:
    mov eax, NEBO_VIEW_CONFLICT
    ret
.config_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.config_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Plans sort/filter/selection without writing to the source collection.
nebo_table_query_plan:
    test rdi, rdi
    jz .query_invalid
    test rsi, rsi
    jz .query_invalid
    cmp qword [rdi + NEBO_QUERY_SOURCE_OFFSET], 0
    je .query_invalid
    cmp qword [rdi + NEBO_QUERY_GENERATION_OFFSET], 0
    je .query_invalid
    mov rcx, [rdi + NEBO_QUERY_COLUMN_COUNT_OFFSET]
    test rcx, rcx
    jz .query_invalid
    cmp rcx, NEBO_VIEW_MAX_COLUMNS
    ja .query_limit
    mov rdx, [rdi + NEBO_QUERY_FLAGS_OFFSET]
    test rdx, ~7
    jnz .query_invalid
    xor r8d, r8d
    test rdx, NEBO_QUERY_FLAG_SORT
    jz .query_filter
    mov r8, [rdi + NEBO_QUERY_SORT_COLUMN_OFFSET]
    cmp r8, rcx
    jae .query_limit
.query_filter:
    mov rax, 0xcbf29ce484222325
    test rdx, NEBO_QUERY_FLAG_FILTER
    jz .query_select
    mov r9, [rdi + NEBO_QUERY_FILTER_LENGTH_OFFSET]
    test r9, r9
    jz .query_invalid
    cmp r9, NEBO_QUERY_MAX_FILTER_BYTES
    ja .query_limit
    mov r10, [rdi + NEBO_QUERY_FILTER_OFFSET]
    test r10, r10
    jz .query_invalid
    xor r11d, r11d
.query_filter_loop:
    cmp r11, r9
    jae .query_select
    movzx r9d, byte [r10 + r11]
    xor rax, r9
    mov r9, 0x100000001b3
    imul rax, r9
    inc r11
    mov r9, [rdi + NEBO_QUERY_FILTER_LENGTH_OFFSET]
    jmp .query_filter_loop
.query_select:
    xor r9d, r9d
    test rdx, NEBO_QUERY_FLAG_SELECT
    jz .query_commit
    mov r10, [rdi + NEBO_QUERY_SELECT_ROW_OFFSET]
    cmp r10, NEBO_VIEW_MAX_ROWS
    jae .query_limit
    mov r11, [rdi + NEBO_QUERY_SELECT_COLUMN_OFFSET]
    cmp r11, rcx
    jae .query_limit
    mov r9, r10
    imul r9, rcx
    add r9, r11
.query_commit:
    mov r10, [rdi + NEBO_QUERY_GENERATION_OFFSET]
    mov [rsi + NEBO_QUERY_RECEIPT_GENERATION_OFFSET], r10
    mov [rsi + NEBO_QUERY_RECEIPT_SORT_COLUMN_OFFSET], r8
    mov [rsi + NEBO_QUERY_RECEIPT_FILTER_DIGEST_OFFSET], rax
    mov [rsi + NEBO_QUERY_RECEIPT_SELECTED_CELL_OFFSET], r9
    mov qword [rsi + NEBO_QUERY_RECEIPT_STATE_OFFSET], NEBO_QUERY_READY
    xor eax, eax
    ret
.query_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.query_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Builds list/tree/checklist metadata from stable ordered node IDs.
nebo_hierarchy_view_build:
    test rdi, rdi
    jz .hierarchy_invalid
    test rsi, rsi
    jz .hierarchy_invalid
    mov r8, [rdi + NEBO_HIERARCHY_KIND_OFFSET]
    cmp r8, NEBO_HIERARCHY_LIST
    jb .hierarchy_invalid
    cmp r8, NEBO_HIERARCHY_CHECKLIST
    ja .hierarchy_invalid
    mov rdx, [rdi + NEBO_HIERARCHY_NODES_OFFSET]
    mov rcx, [rdi + NEBO_HIERARCHY_COUNT_OFFSET]
    test rdx, rdx
    jz .hierarchy_invalid
    test rcx, rcx
    jz .hierarchy_invalid
    cmp rcx, NEBO_VIEW_MAX_NODES
    ja .hierarchy_limit
    mov r9, [rdi + NEBO_HIERARCHY_DEPTH_OFFSET]
    test r9, r9
    jz .hierarchy_invalid
    cmp r9, NEBO_VIEW_MAX_DEPTH
    ja .hierarchy_limit
    cmp r8, NEBO_HIERARCHY_LIST
    jne .hierarchy_checked
    cmp r9, 1
    jne .hierarchy_conflict
.hierarchy_checked:
    xor r10d, r10d
    cmp r8, NEBO_HIERARCHY_CHECKLIST
    jne .hierarchy_scan
    cmp qword [rdi + NEBO_HIERARCHY_CHECKED_OFFSET], 0
    je .hierarchy_invalid
    mov r10, rcx
    add r10, 7
    shr r10, 3
    cmp r10, [rdi + NEBO_HIERARCHY_CHECKED_BYTES_OFFSET]
    jne .hierarchy_conflict
.hierarchy_scan:
    xor r11d, r11d
    xor eax, eax
.hierarchy_loop:
    cmp r11, rcx
    jae .hierarchy_commit
    mov rdi, [rdx + r11 * 8]
    test rdi, rdi
    jz .hierarchy_schema
    test r11, r11
    jz .hierarchy_hash
    cmp rdi, [rdx + r11 * 8 - 8]
    jbe .hierarchy_conflict
.hierarchy_hash:
    rol rax, 11
    xor rax, rdi
    inc r11
    jmp .hierarchy_loop
.hierarchy_commit:
    mov [rsi + NEBO_HIERARCHY_RECEIPT_KIND_OFFSET], r8
    mov [rsi + NEBO_HIERARCHY_RECEIPT_COUNT_OFFSET], rcx
    mov [rsi + NEBO_HIERARCHY_RECEIPT_DEPTH_OFFSET], r9
    mov [rsi + NEBO_HIERARCHY_RECEIPT_CHECKED_BYTES_OFFSET], r10
    mov [rsi + NEBO_HIERARCHY_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_HIERARCHY_RECEIPT_STATE_OFFSET], NEBO_HIERARCHY_READY
    xor eax, eax
    ret
.hierarchy_schema:
    mov eax, NEBO_VIEW_SCHEMA
    ret
.hierarchy_conflict:
    mov eax, NEBO_VIEW_CONFLICT
    ret
.hierarchy_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.hierarchy_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Builds object/tuple/schema metadata from typed, stable field descriptors.
nebo_record_view_build:
    test rdi, rdi
    jz .record_invalid_pre
    test rsi, rsi
    jz .record_invalid_pre
    push rbx
    mov rbx, rsi
    mov r8, [rdi + NEBO_RECORD_KIND_OFFSET]
    cmp r8, NEBO_RECORD_OBJECT
    jb .record_invalid
    cmp r8, NEBO_RECORD_SCHEMA
    ja .record_invalid
    mov rdx, [rdi + NEBO_RECORD_FIELDS_OFFSET]
    mov rcx, [rdi + NEBO_RECORD_FIELD_COUNT_OFFSET]
    test rdx, rdx
    jz .record_invalid
    test rcx, rcx
    jz .record_invalid
    cmp rcx, NEBO_VIEW_MAX_ROWS
    ja .record_limit
    mov r9, [rdi + NEBO_RECORD_SCHEMA_ID_OFFSET]
    mov r10, [rdi + NEBO_RECORD_SCHEMA_VERSION_OFFSET]
    test r9, r9
    jz .record_schema
    test r10, r10
    jz .record_schema
    mov rax, 0xcbf29ce484222325
    xor r11d, r11d
.record_loop:
    cmp r11, rcx
    jae .record_commit
    mov rdi, r11
    imul rdi, nebo_structured_views_FIELD_SIZE
    add rdi, rdx
    mov rsi, [rdi + NEBO_FIELD_NAME_ID_OFFSET]
    test rsi, rsi
    jz .record_schema
    cmp qword [rdi + NEBO_FIELD_TYPE_ID_OFFSET], 0
    je .record_schema
    test r11, r11
    jz .record_hash
    cmp rsi, [rdi - nebo_structured_views_FIELD_SIZE + NEBO_FIELD_NAME_ID_OFFSET]
    jbe .record_conflict
.record_hash:
    xor rax, rsi
    rol rax, 13
    xor rax, [rdi + NEBO_FIELD_TYPE_ID_OFFSET]
    rol rax, 17
    xor rax, [rdi + NEBO_FIELD_FLAGS_OFFSET]
    inc r11
    jmp .record_loop
.record_commit:
    mov [rbx + NEBO_RECORD_RECEIPT_KIND_OFFSET], r8
    mov [rbx + NEBO_RECORD_RECEIPT_FIELD_COUNT_OFFSET], rcx
    mov [rbx + NEBO_RECORD_RECEIPT_SCHEMA_ID_OFFSET], r9
    mov [rbx + NEBO_RECORD_RECEIPT_SCHEMA_VERSION_OFFSET], r10
    mov [rbx + NEBO_RECORD_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rbx + NEBO_RECORD_RECEIPT_STATE_OFFSET], NEBO_RECORD_READY
    xor eax, eax
    jmp .record_done
.record_conflict:
    mov eax, NEBO_VIEW_CONFLICT
    jmp .record_done
.record_limit:
    mov eax, NEBO_VIEW_LIMIT
    jmp .record_done
.record_schema:
    mov eax, NEBO_VIEW_SCHEMA
    jmp .record_done
.record_invalid:
    mov eax, NEBO_VIEW_INVALID
.record_done:
    pop rbx
    ret
.record_invalid_pre:
    mov eax, NEBO_VIEW_INVALID
    ret

; Produces pre-render inspection metadata with no sensitive bytes or addresses.
nebo_inspection_plan:
    test rdi, rdi
    jz .inspect_invalid
    test rsi, rsi
    jz .inspect_invalid
    mov r8, [rdi + NEBO_INSPECT_KIND_OFFSET]
    cmp r8, NEBO_INSPECT_FULL
    jb .inspect_invalid
    cmp r8, NEBO_INSPECT_SHAPE
    ja .inspect_invalid
    mov r9, [rdi + NEBO_INSPECT_SOURCE_KIND_OFFSET]
    test r9, r9
    jz .inspect_schema
    mov r10, [rdi + NEBO_INSPECT_FLAGS_OFFSET]
    test r10, NEBO_INSPECT_FLAG_SENSITIVE | NEBO_INSPECT_FLAG_ADDRESS
    jnz .inspect_privacy
    test r10, ~NEBO_INSPECT_FLAG_PUBLIC_METADATA
    jnz .inspect_invalid
    mov rcx, [rdi + NEBO_INSPECT_METADATA_LENGTH_OFFSET]
    cmp rcx, NEBO_INSPECT_MAX_METADATA_BYTES
    ja .inspect_limit
    test rcx, rcx
    jz .inspect_items
    mov rdx, [rdi + NEBO_INSPECT_METADATA_OFFSET]
    test rdx, rdx
    jz .inspect_invalid
    mov rax, 0xcbf29ce484222325
    xor r11d, r11d
.inspect_metadata_loop:
    cmp r11, rcx
    jae .inspect_items
    rol rax, 7
    xor al, [rdx + r11]
    inc r11
    jmp .inspect_metadata_loop
.inspect_items:
    test rcx, rcx
    jnz .inspect_items_ready
    xor eax, eax
.inspect_items_ready:
    mov r11, [rdi + NEBO_INSPECT_MAX_ITEMS_OFFSET]
    test r11, r11
    jz .inspect_invalid
    cmp r11, NEBO_VIEW_MAX_ROWS
    ja .inspect_limit
    mov [rsi + NEBO_INSPECT_RECEIPT_KIND_OFFSET], r8
    mov [rsi + NEBO_INSPECT_RECEIPT_SOURCE_KIND_OFFSET], r9
    mov [rsi + NEBO_INSPECT_RECEIPT_METADATA_DIGEST_OFFSET], rax
    mov [rsi + NEBO_INSPECT_RECEIPT_MAX_ITEMS_OFFSET], r11
    mov [rsi + NEBO_INSPECT_RECEIPT_SAFE_FLAGS_OFFSET], r10
    mov qword [rsi + NEBO_INSPECT_RECEIPT_STATE_OFFSET], NEBO_INSPECT_READY
    xor eax, eax
    ret
.inspect_privacy:
    mov eax, NEBO_VIEW_PRIVACY
    ret
.inspect_schema:
    mov eax, NEBO_VIEW_SCHEMA
    ret
.inspect_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.inspect_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Distinguishes present, missing and null while deriving truncation explicitly.
nebo_value_marker_build:
    test rdi, rdi
    jz .value_invalid
    test rsi, rsi
    jz .value_invalid
    mov r8, [rdi + NEBO_VALUE_STATE_OFFSET]
    cmp r8, NEBO_VALUE_NULL
    ja .value_invalid
    mov r9, [rdi + NEBO_VALUE_TOTAL_OFFSET]
    mov r10, [rdi + NEBO_VALUE_VISIBLE_OFFSET]
    cmp r10, r9
    ja .value_conflict
    cmp r8, NEBO_VALUE_PRESENT
    je .value_present
    test r9, r9
    jnz .value_conflict
    test r10, r10
    jnz .value_conflict
.value_present:
    mov rcx, [rdi + NEBO_VALUE_LABEL_LENGTH_OFFSET]
    test rcx, rcx
    jz .value_invalid
    cmp rcx, NEBO_VALUE_MAX_LABEL_BYTES
    ja .value_limit
    mov rdx, [rdi + NEBO_VALUE_LABEL_OFFSET]
    test rdx, rdx
    jz .value_invalid
    xor eax, eax
    xor r11d, r11d
.value_label_loop:
    cmp r11, rcx
    jae .value_truncation
    rol rax, 5
    xor al, [rdx + r11]
    inc r11
    jmp .value_label_loop
.value_truncation:
    xor edx, edx
    cmp r10, r9
    je .value_commit
    mov edx, 1
.value_commit:
    mov [rsi + NEBO_VALUE_RECEIPT_STATE_KIND_OFFSET], r8
    mov [rsi + NEBO_VALUE_RECEIPT_TOTAL_OFFSET], r9
    mov [rsi + NEBO_VALUE_RECEIPT_VISIBLE_OFFSET], r10
    mov [rsi + NEBO_VALUE_RECEIPT_TRUNCATED_OFFSET], rdx
    mov [rsi + NEBO_VALUE_RECEIPT_LABEL_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_VALUE_RECEIPT_STATE_OFFSET], NEBO_VALUE_READY
    xor eax, eax
    ret
.value_conflict:
    mov eax, NEBO_VIEW_CONFLICT
    ret
.value_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.value_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Derives a bounded virtual window; no source item is materialized by this ABI.
nebo_virtual_window_plan:
    test rdi, rdi
    jz .window_invalid
    test rsi, rsi
    jz .window_invalid
    cmp qword [rdi + NEBO_WINDOW_SOURCE_OFFSET], 0
    je .window_invalid
    mov r8, [rdi + NEBO_WINDOW_TOTAL_OFFSET]
    mov r9, [rdi + NEBO_WINDOW_OFFSET_OFFSET]
    test r8, r8
    jz .window_invalid
    cmp r9, r8
    jae .window_limit
    mov r10, [rdi + NEBO_WINDOW_SIZE_OFFSET]
    test r10, r10
    jz .window_invalid
    cmp r10, NEBO_WINDOW_MAX_ITEMS
    ja .window_limit
    mov r11, [rdi + NEBO_WINDOW_OVERSCAN_OFFSET]
    cmp r11, NEBO_WINDOW_MAX_OVERSCAN
    ja .window_limit
    mov rcx, r9
    cmp rcx, r11
    jae .window_subtract
    xor ecx, ecx
    jmp .window_end
.window_subtract:
    sub rcx, r11
.window_end:
    mov rdx, r9
    add rdx, r10
    jc .window_limit
    add rdx, r11
    jc .window_limit
    cmp rdx, r8
    jbe .window_cap
    mov rdx, r8
.window_cap:
    mov rax, rcx
    add rax, NEBO_WINDOW_MAX_ITEMS
    jc .window_limit
    cmp rdx, rax
    jbe .window_commit
    mov rdx, rax
.window_commit:
    mov [rsi + NEBO_WINDOW_RECEIPT_START_OFFSET], rcx
    mov [rsi + NEBO_WINDOW_RECEIPT_END_OFFSET], rdx
    sub rdx, rcx
    mov [rsi + NEBO_WINDOW_RECEIPT_MATERIALIZED_OFFSET], rdx
    mov rax, [rdi + nebo_structured_views_WINDOW_GENERATION_OFFSET]
    mov [rsi + NEBO_WINDOW_RECEIPT_GENERATION_OFFSET], rax
    mov qword [rsi + NEBO_WINDOW_RECEIPT_STATE_OFFSET], NEBO_WINDOW_READY
    xor eax, eax
    ret
.window_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.window_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret

; Scans one canonical reference per structured-view surface deterministically.
nebo_structured_conformance_scan:
    test rdi, rdi
    jz .conformance_invalid
    test rsi, rsi
    jz .conformance_invalid
    mov rdx, [rdi + NEBO_CONFORMANCE_REFERENCES_OFFSET]
    mov rcx, [rdi + NEBO_CONFORMANCE_COUNT_OFFSET]
    test rdx, rdx
    jz .conformance_invalid
    test rcx, rcx
    jz .conformance_invalid
    cmp rcx, NEBO_CONFORMANCE_WINDOW
    ja .conformance_limit
    mov rax, 0xcbf29ce484222325
    xor r8d, r8d
    xor r9d, r9d
.conformance_loop:
    cmp r8, rcx
    jae .conformance_commit
    mov r10, r8
    shl r10, 5
    add r10, rdx
    mov r11, [r10 + NEBO_REFERENCE_KIND_OFFSET]
    cmp r11, NEBO_CONFORMANCE_TABLE
    jb .conformance_schema
    cmp r11, NEBO_CONFORMANCE_WINDOW
    ja .conformance_schema
    cmp r11, r9
    jbe .conformance_conflict
    mov r9, r11
    cmp qword [r10 + NEBO_REFERENCE_STATE_OFFSET], 1
    jne .conformance_schema
    cmp qword [r10 + NEBO_REFERENCE_EXTENT_OFFSET], NEBO_VIEW_MAX_CELLS
    ja .conformance_limit
    cmp qword [r10 + NEBO_REFERENCE_DIGEST_OFFSET], 0
    je .conformance_schema
    xor rax, r11
    rol rax, 11
    xor rax, [r10 + NEBO_REFERENCE_EXTENT_OFFSET]
    rol rax, 17
    xor rax, [r10 + NEBO_REFERENCE_DIGEST_OFFSET]
    inc r8
    jmp .conformance_loop
.conformance_commit:
    mov [rsi + NEBO_CONFORMANCE_RECEIPT_COUNT_OFFSET], rcx
    mov [rsi + NEBO_CONFORMANCE_RECEIPT_DIGEST_OFFSET], rax
    mov qword [rsi + NEBO_CONFORMANCE_RECEIPT_STATE_OFFSET], NEBO_CONFORMANCE_READY
    xor eax, eax
    ret
.conformance_schema:
    mov eax, NEBO_VIEW_SCHEMA
    ret
.conformance_conflict:
    mov eax, NEBO_VIEW_CONFLICT
    ret
.conformance_limit:
    mov eax, NEBO_VIEW_LIMIT
    ret
.conformance_invalid:
    mov eax, NEBO_VIEW_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
