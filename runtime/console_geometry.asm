; Nebo Assembly — POSICAO-SIZING-REGIOES-LAYERS-PANELS-E-WINDOWS bounded ConsoleDocument geometry
bits 64
default rel
%include "runtime/console_geometry.inc"
global nebo_geometry_position
global nebo_geometry_size
global nebo_geometry_surface
global nebo_geometry_panel_layer
global nebo_geometry_update
global nebo_geometry_labels
global nebo_geometry_address
global nebo_geometry_multi_validate
global nebo_geometry_target_map
global nebo_geometry_document_validate
section .text
; .at(x,y): x is horizontal/column and y is vertical/row.
; legacy=1 accepts historical (row,col), swaps once and emits a diagnostic.
nebo_geometry_position:
    test rdi, rdi
    jz .position_invalid
    test rsi, rsi
    jz .position_invalid
    mov rax, [rdi + NEBO_POSITION_LEGACY_OFFSET]
    cmp rax, 1
    ja .position_invalid
    mov rcx, [rdi + NEBO_POSITION_X_OFFSET]
    mov rdx, [rdi + NEBO_POSITION_Y_OFFSET]
    movsxd r8, ecx
    cmp r8, rcx
    jne .position_limit
    movsxd r8, edx
    cmp r8, rdx
    jne .position_limit
    test rax, rax
    jz .position_commit
    xchg rcx, rdx
.position_commit:
    mov [rsi + NEBO_POSITION_RESULT_X_OFFSET], rcx
    mov [rsi + NEBO_POSITION_RESULT_Y_OFFSET], rdx
    mov [rsi + NEBO_POSITION_RESULT_DIAGNOSTIC_OFFSET], rax
    mov qword [rsi + NEBO_POSITION_RESULT_STATE_OFFSET], NEBO_POSITION_READY
    xor eax, eax
    ret
.position_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.position_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; rdi=size request/result fields, rsi=atomic normalized size result.
nebo_geometry_size:
    test rdi, rdi
    jz .size_invalid
    test rsi, rsi
    jz .size_invalid
    mov rcx, [rdi + NEBO_SIZE_WIDTH_OFFSET]
    mov rdx, [rdi + NEBO_SIZE_HEIGHT_OFFSET]
    test rcx, rcx
    jle .size_invalid
    test rdx, rdx
    jle .size_invalid
    mov r8, [rdi + NEBO_SIZE_UNIT_OFFSET]
    cmp r8, NEBO_SIZE_UNIT_CELLS
    jb .size_invalid
    cmp r8, NEBO_SIZE_UNIT_PIXELS
    ja .size_invalid
    mov rax, rcx
    mul rdx
    test rdx, rdx
    jnz .size_limit
    cmp rax, NEBO_GEOMETRY_MAX_AREA
    ja .size_limit
    mov [rsi + NEBO_SIZE_WIDTH_OFFSET], rcx
    mov rdx, [rdi + NEBO_SIZE_HEIGHT_OFFSET]
    mov [rsi + NEBO_SIZE_HEIGHT_OFFSET], rdx
    mov [rsi + NEBO_SIZE_UNIT_OFFSET], r8
    mov [rsi + NEBO_SIZE_AREA_OFFSET], rax
    mov qword [rsi + NEBO_SIZE_STATE_OFFSET], NEBO_SIZE_READY
    xor eax, eax
    ret
.size_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.size_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Region/viewport/headless/live windows share geometry but not maturity claims.
nebo_geometry_surface:
    test rdi, rdi
    jz .surface_invalid
    test rsi, rsi
    jz .surface_invalid
    mov rcx, [rdi + NEBO_SURFACE_KIND_OFFSET]
    cmp rcx, NEBO_SURFACE_REGION
    jb .surface_invalid
    cmp rcx, NEBO_SURFACE_LIVE_WINDOW
    ja .surface_invalid
    cmp qword [rdi + NEBO_SURFACE_ID_OFFSET], 0
    je .surface_invalid
    mov r8, [rdi + NEBO_SURFACE_WIDTH_OFFSET]
    mov r9, [rdi + NEBO_SURFACE_HEIGHT_OFFSET]
    test r8, r8
    jle .surface_invalid
    test r9, r9
    jle .surface_invalid
    mov rax, r8
    mul r9
    test rdx, rdx
    jnz .surface_limit
    cmp rax, NEBO_GEOMETRY_MAX_AREA
    ja .surface_limit
    cmp rcx, NEBO_SURFACE_LIVE_WINDOW
    je .surface_live
    cmp qword [rdi + NEBO_SURFACE_HANDLE_OFFSET], 0
    jne .surface_target
    jmp .surface_commit
.surface_live:
    cmp qword [rdi + NEBO_SURFACE_HANDLE_OFFSET], 0
    je .surface_lifecycle
    test qword [rdi + NEBO_SURFACE_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    jz .surface_target
.surface_commit:
    mov rax, [rdi + 0]
    mov [rsi + 0], rax
    mov rax, [rdi + 8]
    mov [rsi + 8], rax
    mov rax, [rdi + 16]
    mov [rsi + 16], rax
    mov rax, [rdi + 24]
    mov [rsi + 24], rax
    mov rax, [rdi + 32]
    mov [rsi + 32], rax
    mov rax, [rdi + 40]
    mov [rsi + 40], rax
    mov rax, [rdi + 48]
    mov [rsi + 48], rax
    mov rax, [rdi + 56]
    mov [rsi + 56], rax
    mov qword [rsi + NEBO_SURFACE_STATE_OFFSET], NEBO_SURFACE_READY
    xor eax, eax
    ret
.surface_lifecycle:
    mov eax, NEBO_GEOMETRY_LIFECYCLE
    ret
.surface_target:
    mov eax, NEBO_GEOMETRY_TARGET
    ret
.surface_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.surface_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Panel/layer association is explicit and bounded; z is a signed 32-bit value.
nebo_geometry_panel_layer:
    test rdi, rdi
    jz .panel_invalid
    test rsi, rsi
    jz .panel_invalid
    mov rax, [rdi + NEBO_PANEL_PARENT_OFFSET]
    test rax, rax
    jz .panel_invalid
    mov rcx, [rdi + NEBO_PANEL_ID_OFFSET]
    test rcx, rcx
    jz .panel_invalid
    cmp rax, rcx
    je .panel_conflict
    mov rdx, [rdi + NEBO_PANEL_LAYER_OFFSET]
    cmp rdx, NEBO_GEOMETRY_MAX_INSTANCES
    jae .panel_limit
    mov r8, [rdi + NEBO_PANEL_INSTANCE_COUNT_OFFSET]
    test r8, r8
    jz .panel_invalid
    cmp r8, NEBO_GEOMETRY_MAX_INSTANCES
    ja .panel_limit
    cmp rdx, r8
    jae .panel_limit
    mov r9, [rdi + NEBO_PANEL_Z_OFFSET]
    movsxd r10, r9d
    cmp r10, r9
    jne .panel_limit
    mov [rsi + NEBO_PANEL_PARENT_OFFSET], rax
    mov [rsi + NEBO_PANEL_ID_OFFSET], rcx
    mov [rsi + NEBO_PANEL_LAYER_OFFSET], rdx
    mov [rsi + NEBO_PANEL_Z_OFFSET], r9
    mov [rsi + NEBO_PANEL_INSTANCE_COUNT_OFFSET], r8
    mov qword [rsi + NEBO_PANEL_STATE_OFFSET], NEBO_PANEL_READY
    xor eax, eax
    ret
.panel_conflict:
    mov eax, NEBO_GEOMETRY_CONFLICT
    ret
.panel_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.panel_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Clear and refresh always name a scope; refresh accepts one next generation.
nebo_geometry_update:
    test rdi, rdi
    jz .update_invalid
    test rsi, rsi
    jz .update_invalid
    mov rcx, [rdi + NEBO_UPDATE_OPERATION_OFFSET]
    cmp rcx, NEBO_UPDATE_CLEAR
    jb .update_invalid
    cmp rcx, NEBO_UPDATE_REFRESH
    ja .update_invalid
    mov rdx, [rdi + NEBO_UPDATE_SCOPE_OFFSET]
    cmp rdx, NEBO_SCOPE_DOCUMENT
    jb .update_invalid
    cmp rdx, NEBO_SCOPE_LAYER
    ja .update_invalid
    cmp qword [rdi + NEBO_UPDATE_SCOPE_ID_OFFSET], 0
    je .update_invalid
    mov r8, [rdi + NEBO_UPDATE_CURRENT_GENERATION_OFFSET]
    cmp r8, -1
    je .update_limit
    lea r9, [r8 + 1]
    cmp rcx, NEBO_UPDATE_CLEAR
    je .update_clear
    cmp [rdi + NEBO_UPDATE_SOURCE_GENERATION_OFFSET], r9
    jne .update_lifecycle
    jmp .update_commit
.update_clear:
    cmp qword [rdi + NEBO_UPDATE_SOURCE_GENERATION_OFFSET], 0
    jne .update_conflict
.update_commit:
    mov [rsi + NEBO_UPDATE_OPERATION_OFFSET], rcx
    mov [rsi + NEBO_UPDATE_SCOPE_OFFSET], rdx
    mov rax, [rdi + NEBO_UPDATE_SCOPE_ID_OFFSET]
    mov [rsi + NEBO_UPDATE_SCOPE_ID_OFFSET], rax
    mov [rsi + NEBO_UPDATE_CURRENT_GENERATION_OFFSET], r8
    mov rax, [rdi + NEBO_UPDATE_SOURCE_GENERATION_OFFSET]
    mov [rsi + NEBO_UPDATE_SOURCE_GENERATION_OFFSET], rax
    mov [rsi + NEBO_UPDATE_RESULT_GENERATION_OFFSET], r9
    mov qword [rsi + NEBO_UPDATE_STATE_OFFSET], NEBO_UPDATE_READY
    xor eax, eax
    ret
.update_lifecycle:
    mov eax, NEBO_GEOMETRY_LIFECYCLE
    ret
.update_conflict:
    mov eax, NEBO_GEOMETRY_CONFLICT
    ret
.update_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.update_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Title, suffix and positional label remain borrowed bounded slices.
nebo_geometry_labels:
    test rdi, rdi
    jz .label_invalid
    test rsi, rsi
    jz .label_invalid
    test qword [rdi + NEBO_LABEL_FLAGS_OFFSET], NEBO_LABEL_SENSITIVE
    jnz .label_privacy
    mov rcx, [rdi + NEBO_LABEL_ANCHOR_OFFSET]
    cmp rcx, NEBO_LABEL_ANCHOR_MIN
    jb .label_invalid
    cmp rcx, NEBO_LABEL_ANCHOR_MAX
    ja .label_invalid
    mov r8, [rdi + NEBO_LABEL_TITLE_LENGTH_OFFSET]
    mov r9, [rdi + NEBO_LABEL_SUFFIX_LENGTH_OFFSET]
    mov r10, [rdi + NEBO_LABEL_TEXT_LENGTH_OFFSET]
    mov rax, r8
    add rax, r9
    jc .label_limit
    add rax, r10
    jc .label_limit
    cmp rax, NEBO_GEOMETRY_MAX_LABEL_BYTES
    ja .label_limit
    test r8, r8
    jz .label_suffix
    cmp qword [rdi + NEBO_LABEL_TITLE_OFFSET], 0
    je .label_invalid
.label_suffix:
    test r9, r9
    jz .label_text
    cmp qword [rdi + NEBO_LABEL_SUFFIX_OFFSET], 0
    je .label_invalid
.label_text:
    test r10, r10
    jz .label_commit
    cmp qword [rdi + NEBO_LABEL_TEXT_OFFSET], 0
    je .label_invalid
.label_commit:
    mov rax, [rdi + 0]
    mov [rsi + 0], rax
    mov rax, [rdi + 8]
    mov [rsi + 8], rax
    mov rax, [rdi + 16]
    mov [rsi + 16], rax
    mov rax, [rdi + 24]
    mov [rsi + 24], rax
    mov rax, [rdi + 32]
    mov [rsi + 32], rax
    mov rax, [rdi + 40]
    mov [rsi + 40], rax
    mov [rsi + NEBO_LABEL_ANCHOR_OFFSET], rcx
    mov qword [rsi + NEBO_LABEL_FLAGS_OFFSET], 0
    mov qword [rsi + NEBO_LABEL_STATE_OFFSET], NEBO_LABEL_READY
    xor eax, eax
    ret
.label_privacy:
    mov eax, NEBO_GEOMETRY_PRIVACY
    ret
.label_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.label_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Selection/focus/cell addressing is zero-based and bounded by view shape.
nebo_geometry_address:
    test rdi, rdi
    jz .address_invalid
    test rsi, rsi
    jz .address_invalid
    mov rcx, [rdi + NEBO_ADDRESS_SCOPE_OFFSET]
    cmp rcx, NEBO_SCOPE_REGION
    jb .address_invalid
    cmp rcx, NEBO_SCOPE_PANEL
    ja .address_invalid
    cmp qword [rdi + NEBO_ADDRESS_SCOPE_ID_OFFSET], 0
    je .address_invalid
    mov r8, [rdi + NEBO_ADDRESS_ROWS_OFFSET]
    mov r9, [rdi + NEBO_ADDRESS_COLUMNS_OFFSET]
    test r8, r8
    jz .address_invalid
    test r9, r9
    jz .address_invalid
    cmp r8, NEBO_ADDRESS_MAX_ROWS
    ja .address_limit
    cmp r9, NEBO_ADDRESS_MAX_COLUMNS
    ja .address_limit
    mov r10, [rdi + NEBO_ADDRESS_ROW_OFFSET]
    mov r11, [rdi + NEBO_ADDRESS_COLUMN_OFFSET]
    cmp r10, r8
    jae .address_limit
    cmp r11, r9
    jae .address_limit
    mov rax, [rdi + NEBO_ADDRESS_FLAGS_OFFSET]
    test rax, rax
    jz .address_invalid
    test rax, ~3
    jnz .address_invalid
    mov rax, r10
    imul rax, r9
    add rax, r11
    mov rdx, [rdi + NEBO_ADDRESS_SCOPE_OFFSET]
    mov [rsi + NEBO_ADDRESS_SCOPE_OFFSET], rdx
    mov rdx, [rdi + NEBO_ADDRESS_SCOPE_ID_OFFSET]
    mov [rsi + NEBO_ADDRESS_SCOPE_ID_OFFSET], rdx
    mov [rsi + NEBO_ADDRESS_ROW_OFFSET], r10
    mov [rsi + NEBO_ADDRESS_COLUMN_OFFSET], r11
    mov [rsi + NEBO_ADDRESS_ROWS_OFFSET], r8
    mov [rsi + NEBO_ADDRESS_COLUMNS_OFFSET], r9
    mov rdx, [rdi + NEBO_ADDRESS_FLAGS_OFFSET]
    mov [rsi + NEBO_ADDRESS_FLAGS_OFFSET], rdx
    mov [rsi + NEBO_ADDRESS_LINEAR_OFFSET], rax
    mov qword [rsi + NEBO_ADDRESS_STATE_OFFSET], NEBO_ADDRESS_READY
    xor eax, eax
    ret
.address_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    ret
.address_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Validates bounded window/panel/layer identity sets and hashes stable IDs.
nebo_geometry_multi_validate:
    push rbx
    mov rbx, rsi
    test rdi, rdi
    jz .multi_invalid
    test rsi, rsi
    jz .multi_invalid
    mov rcx, [rdi + NEBO_MULTI_WINDOW_COUNT_OFFSET]
    mov rdx, [rdi + NEBO_MULTI_PANEL_COUNT_OFFSET]
    mov r8, [rdi + NEBO_MULTI_LAYER_COUNT_OFFSET]
    cmp rcx, NEBO_GEOMETRY_MAX_INSTANCES
    ja .multi_limit
    cmp rdx, NEBO_GEOMETRY_MAX_INSTANCES
    ja .multi_limit
    cmp r8, NEBO_GEOMETRY_MAX_INSTANCES
    ja .multi_limit
    mov r9, rcx
    add r9, rdx
    jc .multi_limit
    add r9, r8
    jc .multi_limit
    cmp r9, NEBO_GEOMETRY_MAX_INSTANCES
    ja .multi_limit
    test r9, r9
    jz .multi_invalid
    test rcx, rcx
    jz .multi_panels
    cmp qword [rdi + NEBO_MULTI_WINDOWS_OFFSET], 0
    je .multi_invalid
.multi_panels:
    test rdx, rdx
    jz .multi_layers
    cmp qword [rdi + NEBO_MULTI_PANELS_OFFSET], 0
    je .multi_invalid
.multi_layers:
    test r8, r8
    jz .multi_target
    cmp qword [rdi + NEBO_MULTI_LAYERS_OFFSET], 0
    je .multi_invalid
.multi_target:
    mov r10, [rdi + NEBO_MULTI_TARGET_OFFSET]
    cmp r10, NEBO_TARGET_HEADLESS
    jb .multi_target_error
    cmp r10, NEBO_TARGET_LIVE
    ja .multi_target_error
    cmp r10, NEBO_TARGET_LIVE
    jne .multi_hash
    test qword [rdi + NEBO_MULTI_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    jz .multi_target_error
.multi_hash:
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor r10d, r10d
.multi_hash_windows:
    cmp r10, rcx
    jae .multi_hash_panels_start
    mov rsi, [rdi + NEBO_MULTI_WINDOWS_OFFSET]
    mov rsi, [rsi + r10 * 8]
    test rsi, rsi
    jz .multi_invalid
    xor rax, rsi
    imul rax, r11
    inc r10
    jmp .multi_hash_windows
.multi_hash_panels_start:
    xor r10d, r10d
.multi_hash_panels:
    cmp r10, rdx
    jae .multi_hash_layers_start
    mov rsi, [rdi + NEBO_MULTI_PANELS_OFFSET]
    mov rsi, [rsi + r10 * 8]
    test rsi, rsi
    jz .multi_invalid
    xor rax, rsi
    imul rax, r11
    inc r10
    jmp .multi_hash_panels
.multi_hash_layers_start:
    xor r10d, r10d
.multi_hash_layers:
    cmp r10, r8
    jae .multi_commit
    mov rsi, [rdi + NEBO_MULTI_LAYERS_OFFSET]
    mov rsi, [rsi + r10 * 8]
    test rsi, rsi
    jz .multi_invalid
    xor rax, rsi
    imul rax, r11
    inc r10
    jmp .multi_hash_layers
.multi_commit:
    mov [rbx + NEBO_MULTI_TOTAL_OFFSET], r9
    mov [rbx + NEBO_MULTI_DIGEST_OFFSET], rax
    mov qword [rbx + NEBO_MULTI_STATE_OFFSET], NEBO_MULTI_READY
    xor eax, eax
    pop rbx
    ret
.multi_target_error:
    mov eax, NEBO_GEOMETRY_TARGET
    pop rbx
    ret
.multi_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    pop rbx
    ret
.multi_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
    pop rbx
    ret

; Maps logical coordinates with an explicit target scale. Headless is 1:1;
; live mapping requires the live capability and is not evidence of a live window.
nebo_geometry_target_map:
    test rdi, rdi
    jz .target_map_invalid_pre
    test rsi, rsi
    jz .target_map_invalid_pre
    push rbx
    push r12
    push r13
    push r14
    push r15
    mov rbx, rsi
    mov r12, rdi
    mov r15, [r12 + NEBO_TARGET_MAP_TARGET_OFFSET]
    cmp r15, NEBO_TARGET_HEADLESS
    jb .target_map_target
    cmp r15, NEBO_TARGET_LIVE
    ja .target_map_target
    mov r13, [r12 + NEBO_TARGET_MAP_SCALE_NUMERATOR_OFFSET]
    mov r14, [r12 + NEBO_TARGET_MAP_SCALE_DENOMINATOR_OFFSET]
    test r13, r13
    jz .target_map_invalid
    test r14, r14
    jz .target_map_invalid
    cmp r15, NEBO_TARGET_HEADLESS
    jne .target_map_live
    cmp r13, 1
    jne .target_map_target
    cmp r14, 1
    jne .target_map_target
    jmp .target_map_values
.target_map_live:
    test qword [r12 + NEBO_TARGET_MAP_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    jz .target_map_target
.target_map_values:
    mov rax, [r12 + NEBO_TARGET_MAP_WIDTH_OFFSET]
    test rax, rax
    jle .target_map_invalid
    mov rdx, [r12 + NEBO_TARGET_MAP_HEIGHT_OFFSET]
    test rdx, rdx
    jle .target_map_invalid
    mov rax, [r12 + NEBO_TARGET_MAP_X_OFFSET]
    imul r13
    idiv r14
    mov r8, rax
    mov rax, [r12 + NEBO_TARGET_MAP_Y_OFFSET]
    imul r13
    idiv r14
    mov r9, rax
    mov rax, [r12 + NEBO_TARGET_MAP_WIDTH_OFFSET]
    imul r13
    idiv r14
    test rax, rax
    jle .target_map_limit
    mov r10, rax
    mov rax, [r12 + NEBO_TARGET_MAP_HEIGHT_OFFSET]
    imul r13
    idiv r14
    test rax, rax
    jle .target_map_limit
    mov r11, rax
    mov [rbx + NEBO_TARGET_MAP_RESULT_X_OFFSET], r8
    mov [rbx + NEBO_TARGET_MAP_RESULT_Y_OFFSET], r9
    mov [rbx + NEBO_TARGET_MAP_RESULT_WIDTH_OFFSET], r10
    mov [rbx + NEBO_TARGET_MAP_RESULT_HEIGHT_OFFSET], r11
    mov qword [rbx + NEBO_TARGET_MAP_STATE_OFFSET], NEBO_TARGET_MAP_READY
    xor eax, eax
    jmp .target_map_done
.target_map_target:
    mov eax, NEBO_GEOMETRY_TARGET
    jmp .target_map_done
.target_map_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    jmp .target_map_done
.target_map_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
.target_map_done:
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbx
    ret
.target_map_invalid_pre:
    mov eax, NEBO_GEOMETRY_INVALID
    ret

; Closes a bounded ConsoleDocument from already validated geometry records.
nebo_geometry_document_validate:
    test rdi, rdi
    jz .document_invalid_pre
    test rsi, rsi
    jz .document_invalid_pre
    push rbx
    push r12
    mov rbx, rsi
    mov r12, rdi
    mov rcx, [r12 + NEBO_DOCUMENT_SURFACE_COUNT_OFFSET]
    mov rdx, [r12 + NEBO_DOCUMENT_PANEL_COUNT_OFFSET]
    mov r8, [r12 + NEBO_DOCUMENT_LABEL_COUNT_OFFSET]
    mov r9, rcx
    add r9, rdx
    jc .document_limit
    add r9, r8
    jc .document_limit
    test r9, r9
    jz .document_invalid
    cmp r9, NEBO_GEOMETRY_MAX_INSTANCES
    ja .document_limit
    test rcx, rcx
    jz .document_panels
    cmp qword [r12 + NEBO_DOCUMENT_SURFACES_OFFSET], 0
    je .document_invalid
.document_panels:
    test rdx, rdx
    jz .document_labels
    cmp qword [r12 + NEBO_DOCUMENT_PANELS_OFFSET], 0
    je .document_invalid
.document_labels:
    test r8, r8
    jz .document_target
    cmp qword [r12 + NEBO_DOCUMENT_LABELS_OFFSET], 0
    je .document_invalid
.document_target:
    mov r10, [r12 + NEBO_DOCUMENT_TARGET_OFFSET]
    cmp r10, NEBO_TARGET_HEADLESS
    jb .document_target_error
    cmp r10, NEBO_TARGET_LIVE
    ja .document_target_error
    cmp r10, NEBO_TARGET_LIVE
    jne .document_hash_start
    test qword [r12 + NEBO_DOCUMENT_CAPABILITIES_OFFSET], NEBO_SURFACE_CAP_LIVE
    jz .document_target_error
.document_hash_start:
    mov rax, 0xcbf29ce484222325
    mov r11, 0x100000001b3
    xor esi, esi
.document_surface_loop:
    cmp rsi, rcx
    jae .document_panel_start
    mov rdi, [r12 + NEBO_DOCUMENT_SURFACES_OFFSET]
    imul r10, rsi, NEBO_SURFACE_SIZE
    add rdi, r10
    cmp qword [rdi + NEBO_SURFACE_STATE_OFFSET], NEBO_SURFACE_READY
    jne .document_lifecycle
    xor rax, [rdi + NEBO_SURFACE_ID_OFFSET]
    imul rax, r11
    inc rsi
    jmp .document_surface_loop
.document_panel_start:
    xor esi, esi
.document_panel_loop:
    cmp rsi, rdx
    jae .document_label_start
    mov rdi, [r12 + NEBO_DOCUMENT_PANELS_OFFSET]
    imul r10, rsi, NEBO_PANEL_SIZE
    add rdi, r10
    cmp qword [rdi + NEBO_PANEL_STATE_OFFSET], NEBO_PANEL_READY
    jne .document_lifecycle
    xor rax, [rdi + NEBO_PANEL_ID_OFFSET]
    imul rax, r11
    inc rsi
    jmp .document_panel_loop
.document_label_start:
    xor esi, esi
.document_label_loop:
    cmp rsi, r8
    jae .document_commit
    mov rdi, [r12 + NEBO_DOCUMENT_LABELS_OFFSET]
    imul r10, rsi, NEBO_LABEL_SIZE
    add rdi, r10
    cmp qword [rdi + NEBO_LABEL_STATE_OFFSET], NEBO_LABEL_READY
    jne .document_lifecycle
    xor rax, [rdi + NEBO_LABEL_ANCHOR_OFFSET]
    imul rax, r11
    xor rax, [rdi + NEBO_LABEL_TEXT_LENGTH_OFFSET]
    imul rax, r11
    inc rsi
    jmp .document_label_loop
.document_commit:
    mov [rbx + NEBO_DOCUMENT_RECEIPT_COUNT_OFFSET], r9
    mov [rbx + NEBO_DOCUMENT_RECEIPT_DIGEST_OFFSET], rax
    mov rax, [r12 + NEBO_DOCUMENT_TARGET_OFFSET]
    mov [rbx + NEBO_DOCUMENT_RECEIPT_TARGET_OFFSET], rax
    mov qword [rbx + NEBO_DOCUMENT_RECEIPT_STATE_OFFSET], NEBO_DOCUMENT_READY
    xor eax, eax
    jmp .document_done
.document_lifecycle:
    mov eax, NEBO_GEOMETRY_LIFECYCLE
    jmp .document_done
.document_target_error:
    mov eax, NEBO_GEOMETRY_TARGET
    jmp .document_done
.document_limit:
    mov eax, NEBO_GEOMETRY_LIMIT
    jmp .document_done
.document_invalid:
    mov eax, NEBO_GEOMETRY_INVALID
.document_done:
    pop r12
    pop rbx
    ret
.document_invalid_pre:
    mov eax, NEBO_GEOMETRY_INVALID
    ret
section .note.GNU-stack noalloc noexec nowrite progbits
